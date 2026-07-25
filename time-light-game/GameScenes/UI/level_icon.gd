@tool
extends Control

## Text shown on the icon
@export var label_text: String = "I":
	set(value):
		label_text = value
		_update_label()

## Level scene to load when this icon is clicked
@export var level_scene: PackedScene

@onready var _label: RichTextLabel = $NinePatchRect/MarginContainer/RichTextLabel
@onready var _button: Button = $Button


func _ready() -> void:
	_update_label()
	# prevents editing shenanigans if clicked since this is a tool script
	if not Engine.is_editor_hint():
		_button.pressed.connect(_on_pressed)


func _update_label() -> void:
	if _label:
		_label.text = label_text


func _on_pressed() -> void:
	if level_scene:
		get_tree().change_scene_to_packed(level_scene)
	else:
		push_warning("level icon has no level_scene assigned")
