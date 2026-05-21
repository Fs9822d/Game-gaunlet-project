extends Node

@export var player: CharacterBody3D
@export var move_sfx: AudioStreamPlayer3D

func _ready() -> void:
	if player == null:
		push_warning("Player is null!")
	if move_sfx == null:
		push_warning("MoveSFX is null!")

func _process(_delta: float) -> void:
	if player == null or move_sfx == null:
		return

	var is_moving = (
		player.current_state == player.State.Moving
		or player.current_state == player.State.Sprint
	)

	if is_moving:
		update_sfx_speed()
		if not move_sfx.playing:
			move_sfx.play()
	else:
		if move_sfx.playing:
			move_sfx.stop()

func update_sfx_speed() -> void:
	if player.current_state == player.State.Sprint:
		move_sfx.pitch_scale = player.sprintMultiplier
	else:
		move_sfx.pitch_scale = 1.0