extends Node

func _input(_event: InputEvent):
	if Input.is_action_pressed("restart"):
		get_tree().reload_current_scene()
