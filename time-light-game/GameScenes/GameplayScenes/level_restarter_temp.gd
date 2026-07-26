extends Node

func _input(event: InputEvent):
	if event.is_action_pressed("restart"):
		get_tree().paused = false
		get_tree().reload_current_scene()
