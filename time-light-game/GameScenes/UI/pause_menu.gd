extends Control

signal resume_pressed
signal restart_pressed

@onready var _resume_button: Button = $VBoxContainer2/VBoxContainer/ResumeButton
@onready var _restart_button: Button = $VBoxContainer2/VBoxContainer/RestartButton
@onready var _main_menu_button: Button = $VBoxContainer2/VBoxContainer/MainMenuButton


func _ready() -> void:
	# keep working while the tree is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	_resume_button.pressed.connect(func() -> void: resume_pressed.emit())
	_restart_button.pressed.connect(func() -> void: restart_pressed.emit())
	_main_menu_button.pressed.connect(_main_menu_button_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		resume_pressed.emit()
		get_viewport().set_input_as_handled()


func _main_menu_button_pressed() -> void:
	# unpause before leaving so the main menu isnt stuck frozen
	get_tree().paused = false
	SceneChanger.change_to(Util.GAME_SCENES.MAIN_MENU)
