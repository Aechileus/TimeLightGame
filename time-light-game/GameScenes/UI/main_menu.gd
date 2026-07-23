extends Control

@onready var play_button = $VBoxContainer/Button

func _ready() -> void:
	play_button.pressed.connect(play_button_pressed)
	
func play_button_pressed():
	SceneChanger.change_to(Util.GAME_SCENES.GAME)
	

