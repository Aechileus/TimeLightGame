extends Node3D

@onready var floor_ceiling_tiled = $"."
@onready var press_sfx = $"../Button/PressSFX"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _on_button_pressed():
	var target_position = floor_ceiling_tiled.position
	target_position.z += 10

	await press_sfx.finished
	var tween = create_tween()
	tween.tween_property(floor_ceiling_tiled, "position", target_position, 2.0)
