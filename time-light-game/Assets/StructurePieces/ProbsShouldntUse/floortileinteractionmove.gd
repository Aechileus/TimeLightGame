extends Node3D

@onready var floor = $"."
@onready var press_sfx = $"../Button/PressSFX"
@onready var press_sfx_alt = $"../Button3/PressSFX"

func _ready():
	pass # Replace with function body.

func _on_button_pressed():
	var target_position = floor.position
	target_position.z += 10

	await press_sfx.finished
	var tween = create_tween()
	tween.tween_property(floor, "position", target_position, 2.0)


func _on_target_hit():
	var target_position = floor.position
	target_position.z += 10

	var tween = create_tween()
	tween.tween_property(floor, "position", target_position, 2.0)


func _on_button_3_pressed():
	var target_position = floor.position
	target_position.x += 10
	if press_sfx_alt != null and press_sfx_alt.playing:
		await press_sfx_alt.finished
	var tween = create_tween()
	tween.tween_property(floor, "position", target_position, 2.0)
