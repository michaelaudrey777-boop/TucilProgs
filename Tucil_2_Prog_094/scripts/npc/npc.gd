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

@onready var line_2d: Line2D = $Line2D
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var ray_cast: RayCast2D = $RayCast2D
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_playback: AnimationNodeStateMachinePlayback = $AnimationTree["parameters/playback"]

func _ready() -> void:
	animation_tree.active = true
	nav_agent.path_desired_distance = 10.0
	nav_agent.target_desired_distance = stop_distance
	
	nav_agent.velocity_computed.connect(_on_velocity_computed)
	
	call_deferred("actor_setup")

func actor_setup() -> void:
	await get_tree().physics_frame
	if not player:
		player = get_tree().get_first_node_in_group("player") as CharacterBody2D

func _physics_process(delta: float) -> void:
	if not player:
		return

	var distance_to_player: float = global_position.distance_to(player.global_position)
	var move_direction: Vector2 = Vector2.ZERO

	if distance_to_player < flee_distance:
		line_2d.clear_points()
		move_direction = (global_position - player.global_position).normalized()
		nav_agent.set_velocity(move_direction * speed)
		delay_timer = 0.0
		return

	if distance_to_player <= stop_distance:
		line_2d.clear_points()
		nav_agent.set_velocity(Vector2.ZERO)
		delay_timer = 0.0
		return

	if delay_timer < follow_delay:
		delay_timer += delta
		nav_agent.set_velocity(Vector2.ZERO)
		return

	ray_cast.target_position = ray_cast.to_local(player.global_position)
	ray_cast.force_raycast_update()

	if ray_cast.is_colliding():
		nav_agent.target_position = player.global_position
		
		line_2d.clear_points()
		for point in nav_agent.get_current_navigation_path():
			line_2d.add_point(to_local(point))

		if not nav_agent.is_navigation_finished():
			var next_path_position: Vector2 = nav_agent.get_next_path_position()
			move_direction = (next_path_position - global_position).normalized()
		else:
			move_direction = (player.global_position - global_position).normalized()
	else:
		line_2d.clear_points()
		move_direction = (player.global_position - global_position).normalized()

	nav_agent.set_velocity(move_direction * speed)

func _on_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	move_and_slide()
	update_state_and_animation(safe_velocity.normalized())

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
