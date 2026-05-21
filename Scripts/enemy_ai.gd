@tool
extends CharacterBody3D

@export var navigateA3D: NavigationAgent3D
@export var Speed = 5.0
@export var rotation_speed = 5.0

@export_group("Vision Cone")
@export var vision_range: float = 10.0
@export var vision_half_angle_deg: float = 45.0

var target_player: Node3D

func _ready() -> void:
	if not Engine.is_editor_hint():
		_start_ai_loop()

func _physics_process(delta: float) -> void:
	if not Engine.is_editor_hint():
		_rotate_towards_player(delta)
		_move_towards_player()

func _rotate_towards_player(delta: float) -> void:
	if not target_player:
		return
	var target_pos := target_player.global_position
	target_pos.y = global_position.y
	if global_position.is_equal_approx(target_pos):
		return
	var target_dir := global_position.direction_to(target_pos)
	var right := Vector3.UP.cross(target_dir).normalized()
	var target_basis := Basis(right, target_dir.cross(right).normalized(), target_dir)
	global_transform.basis = global_transform.basis.slerp(target_basis, rotation_speed * delta).orthonormalized()

func _start_ai_loop() -> void:
	while is_inside_tree():
		target_player = _dot_vision_cone("Player")
		if target_player and navigateA3D:
			navigateA3D.target_position = target_player.global_position
		await get_tree().create_timer(0.1).timeout

func _move_towards_player() -> void:
	if target_player and navigateA3D and not navigateA3D.is_navigation_finished():
		velocity = global_position.direction_to(navigateA3D.get_next_path_position()) * Speed
		move_and_slide()
	else:
		velocity = Vector3.ZERO

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
