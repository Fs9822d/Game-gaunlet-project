extends CharacterBody3D

@export var navigateA3D: NavigationAgent3D
@export var Speed = 5.0
@export var visionCone: Area3D

func detect_player() -> bool:
	return vision_cone("Player") != null

func vision_cone(group: String) -> Node3D:
	if not visionCone:
		return null
	for body in visionCone.get_overlapping_bodies():
		if body.is_in_group(group):
			return body
	for area in visionCone.get_overlapping_areas():
		if area.is_in_group(group):
			return area
	return null