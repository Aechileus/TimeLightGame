extends Control

signal resume_pressed
signal restart_pressed

const SETTINGS_MENU := preload("res://GameScenes/UI/settings_menu.tscn")

@onready var _resume_button: Button = $VBoxContainer2/VBoxContainer/ResumeButton
@onready var _restart_button: Button = $VBoxContainer2/VBoxContainer/RestartButton
@onready var _settings_button: Button = $VBoxContainer2/VBoxContainer/SettingsButton
@onready var _main_menu_button: Button = $VBoxContainer2/VBoxContainer/MainMenuButton

var _settings: Control = null


func _ready() -> void:
	# keep working while the tree is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	_resume_button.pressed.connect(func() -> void: resume_pressed.emit())
	_restart_button.pressed.connect(func() -> void: restart_pressed.emit())
	_settings_button.pressed.connect(_open_settings)
	_main_menu_button.pressed.connect(_main_menu_button_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		# back out of settings first if its up, otherwise resume
		if _settings != null:
			_close_settings()
		else:
			resume_pressed.emit()
		get_viewport().set_input_as_handled()


func _open_settings() -> void:
	if _settings != null:
		return
	_settings = SETTINGS_MENU.instantiate()
	_settings.closed.connect(_close_settings)
	add_child(_settings)


func _close_settings() -> void:
	if _settings != null:
		_settings.queue_free()
		_settings = null


func _main_menu_button_pressed() -> void:
	# unpause before leaving so the main menu isnt stuck frozen
	get_tree().paused = false
	SceneChanger.change_to(Util.GAME_SCENES.MAIN_MENU)
