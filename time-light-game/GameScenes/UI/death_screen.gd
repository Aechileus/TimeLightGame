extends Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene.call_deferred()


func _on_main_menu_button_pressed() -> void:
	get_tree().paused = false
	SceneChanger.change_to(Util.GAME_SCENES.MAIN_MENU)
