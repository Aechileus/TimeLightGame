extends CanvasLayer

var new_scene_path : String

func change_to(new_scene : Util.GAME_SCENES):
	print("change_to ", new_scene)
	match new_scene:
		Util.GAME_SCENES.GAME:
			new_scene_path = Util.GAME_PATH
		Util.GAME_SCENES.MAIN_MENU:
			new_scene_path = Util.MAIN_MENU_PATH
		Util.GAME_SCENES.PLAYGROUND:
			new_scene_path = Util.PLAYGROUND_PATH
		Util.GAME_SCENES.LEVELSELECT:
			new_scene_path = Util.LEVELSELECT_PATH
		Util.GAME_SCENES.TUTORIALONE:
			new_scene_path = Util.TUTORIAL_PATH
		Util.GAME_SCENES.INTRO:
			new_scene_path = Util.INTRO_PATH
	_new_scene()

func _new_scene():
	get_tree().call_deferred("change_scene_to_file", new_scene_path)
