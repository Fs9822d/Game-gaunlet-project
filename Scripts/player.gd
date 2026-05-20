extends CharacterBody3D

@export_group("Camera settings")
@export var camera: Camera3D
@export var sensitivity: float = 0.002

@export_group("Movement settings")
@export var move_speed: float = 5.0
@export var jump_velocity: float = 4.5

enum State {
	Moving,
	Jumping,
	Falling,
	Idle
}

var current_state: State = State.Idle

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		camera_move(event.relative)
	
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	move(delta)

func move(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	var input_dir := Input.get_vector("Left", "Right", "Front", "Back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)

	move_and_slide()

	update_state()

func update_state() -> void:
	var prev_state := current_state
	if not is_on_floor():
		if velocity.y > 0:
			current_state = State.Jumping
		else:
			current_state = State.Falling
	else:
		var horizontal_velocity := Vector2(velocity.x, velocity.z)
		if horizontal_velocity.length() > 0.1:
			current_state = State.Moving
		else:
			current_state = State.Idle

	if current_state != prev_state:
		print("Player state: ", State.keys()[current_state])

func camera_move(relative: Vector2) -> void:
	if camera:
		var delta := get_process_delta_time()
		rotate_y(-relative.x * sensitivity * delta)
		camera.rotate_x(-relative.y * sensitivity * delta)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))
