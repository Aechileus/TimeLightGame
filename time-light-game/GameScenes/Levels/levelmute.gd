extends Node3D


## the music player to pause, all its audio players get paused with it
@export var music: Node
## drag every button that should duck the music in here, they auto connect
@export var buttons: Array[Node] = []
## walk this far from the saved spot and the music comes back
@export_range(1.0, 50.0, 0.5) var move_distance: float = 10.0
## used if a button or its sfx cant be read
@export_range(0.1, 30.0, 0.1) var fallback_duration: float = 3.0

var _active: bool = false
var _remaining: float = 0.0
var _saved_pos: Vector3 = Vector3.ZERO
var _player: Node3D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for button in buttons:
		if button != null and button.has_signal("pressed"):
			var cb := _on_duck_button.bind(button)
			if not button.pressed.is_connected(cb):
				button.pressed.connect(cb)


func _process(delta: float) -> void:
	if not _active:
		return
	_set_music_paused(true)
	_remaining -= delta
	var moved_far := false
	if is_instance_valid(_player):
		moved_far = _player.global_position.distance_to(_saved_pos) >= move_distance
	if _remaining <= 0.0 or moved_far:
		_resume()


func _on_duck_button(button: Node) -> void:
	duck_for(_sfx_length(button))


func duck_for(seconds: float) -> void:
	if seconds <= 0.0:
		return
	_player = _find_player()
	if is_instance_valid(_player):
		_saved_pos = _player.global_position
	_remaining = seconds
	_active = true
	_set_music_paused(true)


func _resume() -> void:
	_active = false
	_set_music_paused(false)


func _set_music_paused(paused: bool) -> void:
	if music != null:
		_apply_pause(music, paused)


func _apply_pause(node: Node, paused: bool) -> void:
	if node is AudioStreamPlayer or node is AudioStreamPlayer2D or node is AudioStreamPlayer3D:
		node.stream_paused = paused
	for child in node.get_children():
		_apply_pause(child, paused)


func _find_player() -> Node3D:
	for n in get_tree().get_nodes_in_group("player"):
		if n is CharacterBody3D:
			return n
	return get_tree().get_first_node_in_group("player")


func _sfx_length(button: Node) -> float:
	if button != null and "press_sfx" in button and button.press_sfx != null:
		return button.press_sfx.get_length()
	return fallback_duration
