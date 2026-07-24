extends Control

@onready var _resume_button: Button = $VBoxContainer2/VBoxContainer/ResumeButton
@onready var _main_menu_button: Button = $VBoxContainer2/VBoxContainer/MainMenuButton

func _ready() -> void:
	_resume_button.pressed.connect(resume_button_pressed)
	_main_menu_button.pressed.connect(main_menu_button_pressed)
	
func resume_button_pressed():
	pass
	
func main_menu_button_pressed():
	SceneChanger.change_to(Util.GAME_SCENES.MAIN_MENU)
