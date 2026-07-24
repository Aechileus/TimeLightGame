extends Control

@onready var play_button = $VBoxContainer/PlayButton
@onready var playground_button = $VBoxContainer/PlaygroundButton

func _ready() -> void:
	play_button.pressed.connect(play_button_pressed)
	playground_button.pressed.connect(playground_button_pressed)
	
func play_button_pressed():
	SceneChanger.change_to(Util.GAME_SCENES.GAME)
	
func playground_button_pressed():
	SceneChanger.change_to(Util.GAME_SCENES.PLAYGROUND)
	
