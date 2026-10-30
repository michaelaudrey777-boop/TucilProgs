extends CharacterBody2D

enum State {
	IDLE_UP,
	IDLE_BACK,
	IDLE_LEFT,
	IDLE_RIGHT,
	RUN_UP,
	RUN_BACK,
	RUN_LEFT,
	RUN_RIGHT,
	ATTACK,
	DEAD
}

@export_category("Stats")
@export var speed: int = 150

@export_category("Camera Controls")
@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.5
@export var max_zoom: float = 3.0

var state: State = State.IDLE_BACK
var last_direction: Vector2 = Vector2.DOWN

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_playback: AnimationNodeStateMachinePlayback = $AnimationTree["parameters/playback"]
@onready var camera: Camera2D = $Camera2D

# AUDIO
@onready var audio_manager = get_node_or_null("../AudioManager")

var footstep_timer: float = 0.0
@export var footstep_interval: float = 0.4

func _ready() -> void:
	animation_tree.active = true
	if camera:
		camera.zoom = Vector2(2.0, 2.0)

func _unhandled_input(event: InputEvent) -> void:
	if camera and event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			var new_zoom = camera.zoom + Vector2(zoom_speed, zoom_speed)
			camera.zoom = new_zoom.clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var new_zoom = camera.zoom - Vector2(zoom_speed, zoom_speed)
			camera.zoom = new_zoom.clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))

func _physics_process(delta: float) -> void:
	movement_loop()
	update_footsteps(delta)

func movement_loop() -> void:
	var move_direction: Vector2 = Input.get_vector("Left", "Right", "Up", "Down")
	
	velocity = move_direction * speed
	move_and_slide()
	
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
		update_animation()

func update_animation() -> void:
	match state:
		# Swapped up/down animation strings so facing up plays back-facing animations
		State.IDLE_UP: animation_playback.travel("idle_back")
		State.IDLE_BACK: animation_playback.travel("idle")
		State.IDLE_LEFT: animation_playback.travel("idle_left")
		State.IDLE_RIGHT: animation_playback.travel("idle_right")
		State.RUN_UP: animation_playback.travel("run_back")
		State.RUN_BACK: animation_playback.travel("run")
		State.RUN_LEFT: animation_playback.travel("run_left")
		State.RUN_RIGHT: animation_playback.travel("run_right")
		State.ATTACK: animation_playback.travel("attack")


func get_surface_type() -> String:
	var layer_names = [
		"misc_ground",
		"misc_water",
		"plateau",
		"water",
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

var was_moving: bool = false

func update_footsteps(delta: float) -> void:
	var is_moving = velocity.length_squared() > 1.0

	if not is_moving:
		footstep_timer = 0.0
		was_moving = false
		return

	if not was_moving:
		was_moving = true
		footstep_timer = 0.0

		if audio_manager != null:
			audio_manager.play_step(get_surface_type())
		return

	footstep_timer += delta

	if footstep_timer >= footstep_interval:
		footstep_timer = 0.0

		if audio_manager != null:
			audio_manager.play_step(get_surface_type())
