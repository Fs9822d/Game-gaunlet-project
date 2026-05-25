extends CharacterBody3D
class_name Item

@export var picked: bool = false

func _physics_process(delta: float) -> void:
	if picked:
		velocity = Vector3.ZERO
		return

	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity = Vector3.ZERO

	move_and_slide()