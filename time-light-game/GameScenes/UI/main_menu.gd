extends Control

@onready var play_button = $VBoxContainer/PlayButton
@onready var playground_button = $VBoxContainer/PlaygroundButton

func _ready() -> void:
	play_button.pressed.connect(play_button_pressed)
	playground_button.pressed.connect(playground_button_pressed)
	
func play_button_pressed():
	SceneChanger.change_to(Util.GAME_SCENES.INTRO)
	
func playground_button_pressed():
	get_tree().quit()
	


func _on_level_select_button_pressed():
	SceneChanger.change_to(Util.GAME_SCENES.LEVELSELECT)
