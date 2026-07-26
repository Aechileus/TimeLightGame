extends Node3D

@onready var floor = $"."
@onready var press_sfx = get_node_or_null("../Button/PressSFX")
@onready var press_sfx_alt = get_node_or_null("../Button3/PressSFX")

@export var animation_length: float = 1.0
@export var target_offset: Vector3 

func _ready():
	
	pass # Replace with function body.

func _on_button_pressed():
	var target_position = floor.position + target_offset

	if press_sfx != null and press_sfx.playing:
		await press_sfx.finished
	var tween = create_tween()
	tween.tween_property(floor, "position", target_position, animation_length)


func _on_target_hit():
	var target_position = floor.position + target_offset

	var tween = create_tween()
	tween.tween_property(floor, "position", target_position, animation_length)


func _on_button_3_pressed():
	var target_position = floor.position + target_offset

	if press_sfx_alt != null and press_sfx_alt.playing:
		await press_sfx_alt.finished
	var tween = create_tween()
	tween.tween_property(floor, "position", target_position, animation_length)



