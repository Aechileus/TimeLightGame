extends Node3D

# A pushable button. Interacting with it dips the button mesh down and back,
# plays a click, optionally recolors its light, then fires the pressed signal. Hook pressed
# up to a door or whatever you want it to trigger.

signal pressed

## how far the button mesh sinks down when pressed
@export var press_depth: float = 0.01
## how long the whole down and back up takes
@export var press_time: float = 0.5
## click sound played on a press
@export var press_sfx: AudioStream
## when on, the button can only be pressed a single time
@export var one_shot: bool = false

@export_group("Light")
## when on, the omni light swaps to the color below on a press
@export var change_light_on_interact: bool = false
## color the omni light becomes when interacted with
@export var interact_light_color: Color = Color(1, 1, 1, 1)

@onready var _button_mesh := $button_etx_blue_1/button_etx_blue_1_child
@onready var _area: InteractionArea = $InteractionArea
@onready var _audio: AudioStreamPlayer3D = $PressSFX
@onready var _light: OmniLight3D = get_node_or_null("OmniLight3D")

var _base_y: float = 0.0
var _pressing: bool = false
var _used: bool = false


func _ready() -> void:
	if _button_mesh != null:
		_base_y = _button_mesh.position.y
	else:
		push_warning("interactable button couldnt find button child to animate")
	_area.interacted.connect(_on_interacted)


func _on_interacted() -> void:
	# ignore spam while a press is still active, stay dead if one shot
	if _pressing:
		return
	if one_shot and _used:
		return
	_used = true
	_pressing = true

	if change_light_on_interact and _light != null:
		_light.light_color = interact_light_color

	if press_sfx != null:
		_audio.stream = press_sfx
		_audio.play()

	# dip down then spring back, half the time each way
	if _button_mesh != null:
		var tween := create_tween()
		tween.tween_property(_button_mesh, "position:y", _base_y - press_depth, press_time * 0.5)
		tween.tween_property(_button_mesh, "position:y", _base_y, press_time * 0.5)
		tween.tween_callback(func() -> void: _pressing = false)
	else:
		_pressing = false

	# whatever this button controls hangs off this signal
	pressed.emit()
