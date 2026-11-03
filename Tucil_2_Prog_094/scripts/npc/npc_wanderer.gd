extends CharacterBody2D

enum State { IDLE, WANDER, FLEE }
enum AnimState {
	IDLE_UP, IDLE_BACK, IDLE_LEFT, IDLE_RIGHT,
	RUN_UP, RUN_BACK, RUN_LEFT, RUN_RIGHT
}

@export var speed: float = 80.0
@export var flee_speed: float = 130.0

@export_category("Wander Settings")
@export var wander_radius: float = 120.0
@export var idle_time_min: float = 1.5
@export var idle_time_max: float = 4.0

@export_category("Avoidance Thresholds")
@export var flee_distance: float = 75.0

var current_state: State = State.IDLE
var anim_state: AnimState = AnimState.IDLE_BACK
var last_direction: Vector2 = Vector2.DOWN
var wait_timer: float = 0.0

var stuck_timer: float = 0.0
var last_stuck_position: Vector2 = Vector2.ZERO

var player: Node2D
var follower_npc: Node2D

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var ray_cast: RayCast2D = $RayCast2D
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_playback: AnimationNodeStateMachinePlayback = $AnimationTree["parameters/playback"]

func _ready() -> void:
	if animation_tree:
		animation_tree.active = true
	
	nav_agent.avoidance_enabled = true
	nav_agent.path_desired_distance = 16.0
	nav_agent.target_desired_distance = 20.0
	
	if not nav_agent.velocity_computed.is_connected(_on_velocity_computed):
		nav_agent.velocity_computed.connect(_on_velocity_computed)
	
	call_deferred("actor_setup")

func actor_setup() -> void:
	await get_tree().physics_frame
	player = get_tree().get_first_node_in_group("player")
	follower_npc = get_tree().get_first_node_in_group("follower")
	
	pick_new_wander_target()

func _physics_process(delta: float) -> void:
	check_if_stuck(delta)
	
	var threat_position: Vector2 = check_for_threats()

	if threat_position != Vector2.INF and current_state != State.FLEE:
		current_state = State.FLEE
		trigger_flee_from(threat_position)
	elif current_state == State.FLEE and nav_agent.is_navigation_finished():
		current_state = State.IDLE
		wait_timer = randf_range(idle_time_min, idle_time_max)

	match current_state:
		State.IDLE:
			wait_timer -= delta
			if wait_timer <= 0.0:
				pick_new_wander_target()
			nav_agent.set_velocity(Vector2.ZERO)

		State.WANDER:
			move_towards_target(speed)

		State.FLEE:
			move_towards_target(flee_speed)

func check_if_stuck(delta: float) -> void:
	if current_state == State.IDLE:
		stuck_timer = 0.0
		return

	if global_position.distance_to(last_stuck_position) < 3.0:
		stuck_timer += delta
		if stuck_timer >= 0.8:
			stuck_timer = 0.0
			pick_new_wander_target()
	else:
		stuck_timer = 0.0
		last_stuck_position = global_position

func move_towards_target(move_speed: float) -> void:
	if nav_agent.is_navigation_finished():
		current_state = State.IDLE
		wait_timer = randf_range(idle_time_min, idle_time_max)
		nav_agent.set_velocity(Vector2.ZERO)
		return

	var next_pos: Vector2 = nav_agent.get_next_path_position()
	var move_dir: Vector2 = (next_pos - global_position).normalized()
	nav_agent.set_velocity(move_dir * move_speed)

func check_for_threats() -> Vector2:
	var closest_pos: Vector2 = Vector2.INF
	var min_dist: float = flee_distance

	if is_instance_valid(player):
		var dist_p: float = global_position.distance_to(player.global_position)
		if dist_p < min_dist and has_line_of_sight_to(player.global_position):
			min_dist = dist_p
			closest_pos = player.global_position

	if is_instance_valid(follower_npc):
		var dist_f: float = global_position.distance_to(follower_npc.global_position)
		if dist_f < min_dist and has_line_of_sight_to(follower_npc.global_position):
			min_dist = dist_f
			closest_pos = follower_npc.global_position

	return closest_pos

func has_line_of_sight_to(target_pos: Vector2) -> bool:
	ray_cast.target_position = ray_cast.to_local(target_pos)
	ray_cast.force_raycast_update()
	return not ray_cast.is_colliding()

func pick_new_wander_target() -> void:
	current_state = State.WANDER
	var random_offset: Vector2 = Vector2(
		randf_range(-wander_radius, wander_radius),
		randf_range(-wander_radius, wander_radius)
	)
	var raw_target: Vector2 = global_position + random_offset
	
	var map_rid: RID = get_world_2d().navigation_map
	var closest_point: Vector2 = NavigationServer2D.map_get_closest_point(map_rid, raw_target)
	
	var target_destination: Vector2 = closest_point if closest_point != Vector2.ZERO else raw_target
	nav_agent.target_position = target_destination

func trigger_flee_from(source_position: Vector2) -> void:
	current_state = State.FLEE
	var flee_dir: Vector2 = (global_position - source_position).normalized()
	
	if flee_dir == Vector2.ZERO:
		flee_dir = -last_direction
		
	var raw_flee_target: Vector2 = global_position + flee_dir * wander_radius
	var map_rid: RID = get_world_2d().navigation_map
	var target_pos: Vector2 = NavigationServer2D.map_get_closest_point(map_rid, raw_flee_target)
	
	nav_agent.target_position = target_pos if target_pos != Vector2.ZERO else raw_flee_target

func check_bump_collisions() -> void:
	for i in range(get_slide_collision_count()):
		var collision: KinematicCollision2D = get_slide_collision(i)
		var collider: Object = collision.get_collider()
		
		if collider is Node and (collider.is_in_group("player") or collider.is_in_group("follower")):
			trigger_flee_from(collider.global_position)
			stuck_timer = 0.0
			break

func _on_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	move_and_slide()
	check_bump_collisions()
	update_state_and_animation(safe_velocity)

func update_state_and_animation(move_velocity: Vector2) -> void:
	if move_velocity.length_squared() > 1.0:
		var move_dir: Vector2 = move_velocity.normalized()
		if abs(move_dir.x) > abs(move_dir.y):
			last_direction = Vector2.RIGHT if move_dir.x > 0 else Vector2.LEFT
		else:
			last_direction = Vector2.DOWN if move_dir.x > 0 else Vector2.UP

	var new_anim: AnimState = anim_state

	if velocity.length_squared() > 1.0:
		match last_direction:
			Vector2.UP: new_anim = AnimState.RUN_UP
			Vector2.DOWN: new_anim = AnimState.RUN_BACK
			Vector2.LEFT: new_anim = AnimState.RUN_LEFT
			Vector2.RIGHT: new_anim = AnimState.RUN_RIGHT
	else:
		match last_direction:
			Vector2.UP: new_anim = AnimState.IDLE_UP
			Vector2.DOWN: new_anim = AnimState.IDLE_BACK
			Vector2.LEFT: new_anim = AnimState.IDLE_LEFT
			Vector2.RIGHT: new_anim = AnimState.IDLE_RIGHT

	if new_anim != anim_state:
		anim_state = new_anim
		play_animation()

func play_animation() -> void:
	if not animation_playback:
		return

	match anim_state:
		AnimState.IDLE_UP: animation_playback.travel("idle_back")
		AnimState.IDLE_BACK: animation_playback.travel("idle")
		AnimState.IDLE_LEFT: animation_playback.travel("idle_left")
		AnimState.IDLE_RIGHT: animation_playback.travel("idle_right")
		AnimState.RUN_UP: animation_playback.travel("run_back")
		AnimState.RUN_BACK: animation_playback.travel("run")
		AnimState.RUN_LEFT: animation_playback.travel("run_left")
		AnimState.RUN_RIGHT: animation_playback.travel("run_right")
