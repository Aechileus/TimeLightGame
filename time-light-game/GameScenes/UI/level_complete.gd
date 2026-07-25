extends NinePatchRect

# Popped up by the finish line when the level is cleared. Next level button loads
# whatever the finish line handed us, main menu bails back out.

# set by the finish line before this gets added to the tree
var next_level: PackedScene
var time_left: float

@onready var _time_left_label: RichTextLabel = $VBoxContainer/RichTextLabel2
@onready var _next_button: Button = $VBoxContainer/NextLevelButton
@onready var _retry_button: Button = $VBoxContainer/RetryButton
@onready var _menu_button: Button = $VBoxContainer/MainMenuButton



func _ready() -> void:
	_next_button.pressed.connect(_on_next_pressed)
	_retry_button.pressed.connect(_on_retry_pressed)
	_menu_button.pressed.connect(_on_menu_pressed)
	# nothing to go to means this was the last level, or we fucked up and forgot to set it, hide the button
	_next_button.visible = next_level != null
	var secs: int = floori(time_left)
	var milis: int = floori((time_left - secs) * 1000)
	_time_left_label.append_text(String.num(secs, 0) + ":" + String.num(milis, 0).pad_zeros(3))


func _on_next_pressed() -> void:
	if next_level == null:
		return
	# drop the pause the finish line put up before we swap scenes
	get_tree().paused = false
	get_tree().change_scene_to_packed(next_level)


func _on_retry_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
	
func _on_menu_pressed() -> void:
	get_tree().paused = false
	SceneChanger.change_to(Util.GAME_SCENES.MAIN_MENU)
