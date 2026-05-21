extends Node

@export var player: CharacterBody3D
@export var move_sfx: AudioStreamPlayer3D

func _process(_delta: float) -> void:
	if player == null or move_sfx == null:
		return

	var is_moving = (
		player.current_state == player.State.Moving
		or player.current_state == player.State.Sprint
	)

	if is_moving:
		if not move_sfx.playing:
			move_sfx.play()
	else:
		if move_sfx.playing:
			move_sfx.stop()
