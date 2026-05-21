@tool
extends CharacterBody3D

@export var navigateA3D: NavigationAgent3D
@export var Speed = 5.0

## -- Dot-product Vision Cone (no Area3D) --
@export_group("Vision Cone")
@export var vision_range: float = 10.0
@export var vision_half_angle_deg: float = 45.0

func detect_player() -> bool:
	return _dot_vision_cone("Player") != null

func _dot_vision_cone(group: String) -> Node3D:
	var cos_threshold: float = cos(deg_to_rad(vision_half_angle_deg))

	var forward: Vector3 = - global_transform.basis.z.normalized()

	for node in get_tree().get_nodes_in_group(group):
		if node is not Node3D:
			continue
		var target := node as Node3D
		var to_target: Vector3 = (target.global_position - global_position)
		var dist: float = to_target.length()

		# Skip if out of range
		if dist > vision_range:
			continue

		# Dot product check – angle between forward and direction-to-target
		var dot: float = forward.dot(to_target / dist) # normalised
		if dot >= cos_threshold:
			return target # visible

	return null