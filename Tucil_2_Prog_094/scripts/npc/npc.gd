extends CharacterBody2D

enum State {
	IDLE_UP, IDLE_BACK, IDLE_LEFT, IDLE_RIGHT,
	RUN_UP, RUN_BACK, RUN_LEFT, RUN_RIGHT
}

@export var speed: float = 150.0

@export_category("Distance Thresholds")
@export var flee_distance: float = 60.0  
@export var stop_distance: float = 90.0 
@export var follow_delay: float = 0.3 

@export var player: CharacterBody2D

var state: State = State.IDLE_BACK
var last_direction: Vector2 = Vector2.DOWN
var delay_timer: float = 0.0

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_playback: AnimationNodeStateMachinePlayback = $AnimationTree["parameters/playback"]

# AUDIO
@onready var footsteps: AudioStreamPlayer2D = $Footsteps
@onready var rock_step: AudioStreamPlayer2D = $RockStep

@export_category("Footstep Audio")
@export var footstep_interval: float = 0.4

var footstep_timer: float = 0.0
var was_moving: bool = false


func _ready() -> void:
	animation_tree.active = true
	nav_agent.path_desired_distance = 10.0
	nav_agent.target_desired_distance = stop_distance
	call_deferred("actor_setup")

func actor_setup() -> void:
	await get_tree().physics_frame
	if not player:
		player = get_tree().get_first_node_in_group("player") as CharacterBody2D

func _physics_process(delta: float) -> void:
	if not player:
		return
	
	update_npc_movement(delta)
	update_footsteps(delta)

	var distance_to_player: float = global_position.distance_to(player.global_position)
	var move_direction: Vector2 = Vector2.ZERO

	if distance_to_player < flee_distance:
		move_direction = (global_position - player.global_position).normalized()
		velocity = move_direction * speed
		delay_timer = 0.0
		move_and_slide()
		update_state_and_animation(move_direction)
		return

	if distance_to_player <= stop_distance:
		velocity = Vector2.ZERO
		delay_timer = 0.0
		move_and_slide()
		update_state_and_animation(Vector2.ZERO)
		return

	if delay_timer < follow_delay:
		delay_timer += delta
		velocity = Vector2.ZERO
		move_and_slide()
		update_state_and_animation(Vector2.ZERO)
		return

	nav_agent.target_position = player.global_position

	if not nav_agent.is_navigation_finished():
		var next_path_position: Vector2 = nav_agent.get_next_path_position()
		move_direction = (next_path_position - global_position).normalized()

	velocity = move_direction * speed
	move_and_slide()
	update_state_and_animation(move_direction)

func update_state_and_animation(move_direction: Vector2) -> void:
	if move_direction != Vector2.ZERO:
		if abs(move_direction.x) > abs(move_direction.y):
			last_direction = Vector2.RIGHT if move_direction.x > 0 else Vector2.LEFT
		else:
			last_direction = Vector2.DOWN if move_direction.y > 0 else Vector2.UP

	var new_state: State = state

	if velocity.length_squared() > 0:
		match last_direction:
			Vector2.UP: new_state = State.RUN_UP
			Vector2.DOWN: new_state = State.RUN_BACK
			Vector2.LEFT: new_state = State.RUN_LEFT
			Vector2.RIGHT: new_state = State.RUN_RIGHT
	else:
		match last_direction:
			Vector2.UP: new_state = State.IDLE_UP
			Vector2.DOWN: new_state = State.IDLE_BACK
			Vector2.LEFT: new_state = State.IDLE_LEFT
			Vector2.RIGHT: new_state = State.IDLE_RIGHT

	if new_state != state:
		state = new_state
		play_animation()

func play_animation() -> void:
	match state:
		State.IDLE_UP: animation_playback.travel("idle_back")
		State.IDLE_BACK: animation_playback.travel("idle")
		State.IDLE_LEFT: animation_playback.travel("idle_left")
		State.IDLE_RIGHT: animation_playback.travel("idle_right")
		State.RUN_UP: animation_playback.travel("run_back")
		State.RUN_BACK: animation_playback.travel("run")
		State.RUN_LEFT: animation_playback.travel("run_left")
		State.RUN_RIGHT: animation_playback.travel("run_right")


func update_npc_movement(delta: float) -> void:
	var distance_to_player: float = global_position.distance_to(player.global_position)
	var move_direction: Vector2 = Vector2.ZERO

	if distance_to_player < flee_distance:
		move_direction = (global_position - player.global_position).normalized()
		velocity = move_direction * speed
		delay_timer = 0.0
		move_and_slide()
		update_state_and_animation(move_direction)
		return

	if distance_to_player <= stop_distance:
		velocity = Vector2.ZERO
		delay_timer = 0.0
		move_and_slide()
		update_state_and_animation(Vector2.ZERO)
		return

	if delay_timer < follow_delay:
		delay_timer += delta
		velocity = Vector2.ZERO
		move_and_slide()
		update_state_and_animation(Vector2.ZERO)
		return

	nav_agent.target_position = player.global_position

	if not nav_agent.is_navigation_finished():
		var next_path_position: Vector2 = nav_agent.get_next_path_position()
		move_direction = (next_path_position - global_position).normalized()

	velocity = move_direction * speed
	move_and_slide()
	update_state_and_animation(move_direction)

func get_surface_type() -> String:
	var layer_names = [
		"misc_ground",
		"misc_water",
		"plateau",
		"ground"
	]

	for layer_name in layer_names:
		var tile_layer = get_node_or_null("../Map/" + layer_name) as TileMapLayer

		if tile_layer == null:
			continue

		var local_position = tile_layer.to_local(global_position)
		var cell_position = tile_layer.local_to_map(local_position)
		var tile_data = tile_layer.get_cell_tile_data(cell_position)

		if tile_data == null:
			continue

		var surface = str(tile_data.get_custom_data("surface_type"))

		if surface == "rock":
			return "rock"

	return "ground"


func update_footsteps(delta: float) -> void:
	var is_moving = velocity.length_squared() > 1.0

	if not is_moving:
		footstep_timer = 0.0
		was_moving = false
		return

	# Mainkan langkah pertama secara langsung.
	if not was_moving:
		was_moving = true
		footstep_timer = 0.0
		play_npc_step()
		return

	# Mainkan langkah selanjutnya sesuai interval.
	footstep_timer += delta

	if footstep_timer >= footstep_interval:
		footstep_timer = 0.0
		play_npc_step()


func play_npc_step() -> void:
	var surface_type = get_surface_type()

	if surface_type == "rock":
		if rock_step.stream != null:
			rock_step.play()
	else:
		if footsteps.stream != null:
			footsteps.play()
