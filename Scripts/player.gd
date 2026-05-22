extends CharacterBody3D

@export_group("Camera settings")
@export var camera: Camera3D
@export var sensitivity: float = 0.002
@export var bob_height: float = 0.05
@export var bob_speed: float = 5.0

@export_group("Movement settings")
@export var move_speed: float = 5.0
@export var jump_velocity: float = 4.5
@export var sprintMultiplier: float = 1.25

enum State {
	Moving,
	Jumping,
	Falling,
	Sprint,
	Idle
}

var current_state: State = State.Idle
var default_camera_y: float = 1.6
var default_camera_x: float = 0.0
var bob_tween_y: Tween
var bob_tween_x: Tween
var fov_tween: Tween
var is_bobbing: bool = false
var active_bob_speed: float = 0.0
var default_fov: float = 70.0
var base_move_speed: float = move_speed

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if camera:
		default_camera_y = camera.position.y
		default_camera_x = camera.position.x
		default_fov = camera.fov
		base_move_speed = move_speed

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		camera_move(event.relative)
	
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	move(delta)
	sprint(delta)

func _tween_fov(target_fov: float) -> void:
	if camera:
		if fov_tween and fov_tween.is_valid():
			fov_tween.kill()
		fov_tween = create_tween()
		fov_tween.tween_property(camera, "fov", target_fov, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func sprint(delta: float) -> void:
	if current_state == State.Sprint:
		if move_speed == base_move_speed:
			move_speed = base_move_speed * sprintMultiplier
			_tween_fov(default_fov * 1.1)
	else:
		if move_speed != base_move_speed:
			move_speed = base_move_speed
			_tween_fov(default_fov)

func jump() -> void:
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = jump_velocity
	
	if current_state == State.Jumping and Input.is_action_just_released("Jump"):
		if velocity.y > 0:
			velocity.y /= 2.0

func move(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	jump()

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
			if Input.is_action_pressed("Sprint"):
				current_state = State.Sprint
			else:
				current_state = State.Moving
		else:
			current_state = State.Idle

	if current_state != prev_state:
		print("Player state: ", State.keys()[current_state])
	
	camera_bob()

func camera_move(relative: Vector2) -> void:
	if camera:
		var delta := get_process_delta_time()
		rotate_y(-relative.x * sensitivity * delta)
		camera.rotate_x(-relative.y * sensitivity * delta)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))

func camera_bob() -> void:
	if not camera:
		return

	if current_state == State.Moving or current_state == State.Sprint:
		var target_bob_speed := bob_speed * (1.5 if current_state == State.Sprint else 1.0)
		if not is_bobbing or active_bob_speed != target_bob_speed:
			is_bobbing = true
			active_bob_speed = target_bob_speed
			_kill_bob_tweens()
			
			var step := 0.25 / target_bob_speed
			var bob_x := bob_height
			
			# Y axis: up -> down -> origin (1 cycle = 4 steps), loops forever
			bob_tween_y = create_tween().set_loops()
			bob_tween_y.tween_property(camera, "position:y", default_camera_y + bob_height, step).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			bob_tween_y.tween_property(camera, "position:y", default_camera_y - bob_height, step * 2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			bob_tween_y.tween_property(camera, "position:y", default_camera_y, step).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			
			# X axis: left -> origin -> right -> origin (spans 2 Y cycles = 8 steps), loops forever
			bob_tween_x = create_tween().set_loops()
			bob_tween_x.tween_property(camera, "position:x", default_camera_x - bob_x, step * 2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			bob_tween_x.tween_property(camera, "position:x", default_camera_x, step * 2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			bob_tween_x.tween_property(camera, "position:x", default_camera_x + bob_x, step * 2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			bob_tween_x.tween_property(camera, "position:x", default_camera_x, step * 2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		if is_bobbing:
			is_bobbing = false
			active_bob_speed = 0.0
			_kill_bob_tweens()
			
			# Smoothly return camera to default position
			bob_tween_y = create_tween()
			bob_tween_y.tween_property(camera, "position:y", default_camera_y, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			bob_tween_x = create_tween()
			bob_tween_x.tween_property(camera, "position:x", default_camera_x, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _kill_bob_tweens() -> void:
	if bob_tween_y and bob_tween_y.is_valid():
		bob_tween_y.kill()
	if bob_tween_x and bob_tween_x.is_valid():
		bob_tween_x.kill()

func cameraBob() -> void:
	camera_bob()