extends Node3D


@export var buttons: Array[Node] = []
@export var open_angle: float = 88.9
@export_range(0.05, 10.0, 0.05) var open_time: float = 1.0

# which buttons have been pressed so far
var _pressed: Dictionary = {}
var _opened: bool = false


func _ready() -> void:
	for button in buttons:
		if button != null and button.has_signal("pressed"):
			var cb := _on_button_pressed.bind(button)
			if not button.pressed.is_connected(cb):
				button.pressed.connect(cb)


func _on_button_pressed(button: Node) -> void:
	_pressed[button] = true
	if _opened:
		return
	if _all_pressed():
		_open()


func _all_pressed() -> bool:
	for button in buttons:
		if not _pressed.get(button, false):
			return false
	return true


func _open() -> void:
	_opened = true
	var tween = create_tween()
	var target_rotation_y = deg_to_rad(open_angle)
	tween.tween_property(self, "rotation:y", target_rotation_y, open_time)
