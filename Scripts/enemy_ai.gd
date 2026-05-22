@tool
extends CharacterBody3D

@export var navigateA3D: NavigationAgent3D
@export var Speed = 5.0
@export var rotation_speed = 5.0
@export var patrol_radius: float = 15.0
@export var patrol_near_player: bool = false

var patrol_target: Vector3 = Vector3.ZERO
var player_node: Node3D = null

@export_group("Vision Cone")
@export var vision_range: float = 10.0
@export var vision_half_angle_deg: float = 45.0

enum State {
	Idle,
	Chase,
	Patrol
}

var current_state: State = State.Idle
var target_player: Node3D

func _ready() -> void:
	if not navigateA3D:
		push_warning("navigateA3D is null!")
		
	var players = get_tree().get_nodes_in_group("Player")
	if players.is_empty():
		push_warning("Player node not found in group 'Player'!")
	else:
		player_node = players[0]
		
	if not Engine.is_editor_hint():
		_start_ai_loop()

func _physics_process(delta: float) -> void:
	if not Engine.is_editor_hint():
		_process_state(delta)

func _process_state(delta: float) -> void:
	match current_state:
		State.Idle:
			_handle_idle(delta)
		State.Chase:
			_handle_chase(delta)
		State.Patrol:
			_handle_patrol(delta)

func _handle_idle(_delta: float) -> void:
	velocity = Vector3.ZERO

func _handle_chase(delta: float) -> void:
	if target_player:
		_rotate_towards(target_player.global_position, delta)
		_move_towards_target()

func _handle_patrol(delta: float) -> void:
	if navigateA3D and not navigateA3D.is_navigation_finished():
		var next_pos := navigateA3D.get_next_path_position()
		_rotate_towards(next_pos, delta)
		_move_towards(next_pos)
	else:
		_change_state(State.Idle)

func _change_state(new_state: State) -> void:
	if current_state == new_state:
		return
	current_state = new_state
	match current_state:
		State.Idle:
			_start_idle_timer()
		State.Patrol:
			_start_patrol()

func _rotate_towards(target_pos: Vector3, delta: float) -> void:
	var local_target := target_pos
	local_target.y = global_position.y
	if global_position.is_equal_approx(local_target):
		return
	var target_dir := global_position.direction_to(local_target)
	var right := Vector3.UP.cross(target_dir).normalized()
	var target_basis := Basis(right, target_dir.cross(right).normalized(), target_dir)
	global_transform.basis = global_transform.basis.slerp(target_basis, rotation_speed * delta).orthonormalized()

func _start_ai_loop() -> void:
	if not _dot_vision_cone("Player"):
		_change_state(State.Patrol)
	while is_inside_tree():
		target_player = _dot_vision_cone("Player")
		if target_player:
			_change_state(State.Chase)
			if navigateA3D:
				navigateA3D.target_position = target_player.global_position
		elif current_state == State.Chase:
			_change_state(State.Patrol)
		await get_tree().create_timer(0.1).timeout

func _move_towards(target_pos: Vector3) -> void:
	velocity = global_position.direction_to(target_pos) * Speed
	move_and_slide()

func _move_towards_target() -> void:
	if navigateA3D and not navigateA3D.is_navigation_finished():
		_move_towards(navigateA3D.get_next_path_position())
	else:
		velocity = Vector3.ZERO

func _start_idle_timer() -> void:
	velocity = Vector3.ZERO
	await get_tree().create_timer(2.0).timeout
	if current_state == State.Idle:
		_change_state(State.Patrol)

func _start_patrol() -> void:
	var origin := global_position
	if patrol_near_player and player_node:
		origin = player_node.global_position
	patrol_target = randPointNav(origin, patrol_radius)
	if navigateA3D:
		navigateA3D.target_position = patrol_target

func detect_player() -> bool:
	return _dot_vision_cone("Player") != null

func _dot_vision_cone(group: String) -> Node3D:
	var cos_threshold: float = cos(deg_to_rad(vision_half_angle_deg))

	var forward: Vector3 = global_transform.basis.z.normalized()

	for node in get_tree().get_nodes_in_group(group):
		if node is not Node3D:
			continue
		var target := node as Node3D
		var to_target: Vector3 = (target.global_position - global_position)
		var dist: float = to_target.length()

		if dist > vision_range:
			continue

		var dot: float = forward.dot(to_target / dist)
		if dot >= cos_threshold:
			return target

	return null

func randPointNav(from: Vector3, Radius: float) -> Vector3:
	var dir := Vector3.FORWARD.rotated(Vector3.UP, randf() * TAU)
	return NavigationServer3D.map_get_closest_point(get_world_3d().navigation_map, from + dir * randf() * Radius)
