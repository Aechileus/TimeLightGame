extends Node3D


const MUSIC_BUS := "Music"
const MUTED_DB := -80.0

@export var audio: AudioStreamPlayer3D

var _music_bus_idx: int = -1
var _saved_db: float = 0.0
var _ducked: bool = false


func _ready() -> void:
	_music_bus_idx = AudioServer.get_bus_index(MUSIC_BUS)
	if _music_bus_idx >= 0:
		_saved_db = AudioServer.get_bus_volume_db(_music_bus_idx)
	if audio != null:
		audio.finished.connect(_restore_music)


func duck_music() -> void:
	if _ducked or _music_bus_idx < 0:
		return
	_ducked = true
	var current := AudioServer.get_bus_volume_db(_music_bus_idx)
	if not is_zero_approx(current) and current > MUTED_DB:
		_saved_db = current
	AudioServer.set_bus_volume_db(_music_bus_idx, MUTED_DB)
	if audio != null:
		audio.play()


func _restore_music() -> void:
	if not _ducked:
		return
	_ducked = false
	if _music_bus_idx >= 0:
		AudioServer.set_bus_volume_db(_music_bus_idx, _saved_db)

func _on_button_2_pressed():
	duck_music()


func _on_button_pressed():
	duck_music()


func _on_button_3_pressed():
	duck_music()
