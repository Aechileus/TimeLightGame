extends Node3D

signal hit

@export var one_shot: bool = true
@onready var audio_stream_player_3d = $AudioStreamPlayer3D

var _used: bool = false


func _ready() -> void:
	add_to_group("enemy")


func take_damage(_amount: float = 0.0) -> void:
	if one_shot and _used:
		return
	_used = true
	audio_stream_player_3d.play()
	hit.emit()
