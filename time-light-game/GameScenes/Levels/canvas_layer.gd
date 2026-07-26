extends CanvasLayer

@onready var t1 = $MainMenu/VBoxContainer/RichTextLabel
@onready var t2 = $MainMenu/VBoxContainer/RichTextLabel2
@onready var t3 = $MainMenu/VBoxContainer/RichTextLabel3
@onready var t4 = $MainMenu/VBoxContainer/RichTextLabel4
@onready var sound = $"../Button/PressSFX"
@onready var player = $"../PlayerController"

var animation_started = false
var animation_timer = 0.0

func _ready() -> void:
	t2.hide()
	t3.hide()
	t4.hide()
	sound.finished.connect(sound_finished)
		
func sound_finished():
	
	animation_started = true
	player._hide_reticle = true
	player._hide_level_timer = true
	player._hide_health = true
	player._hide_abilities = true
	player._hide_time_manipulation = true
	player.show_hide_ui()
	show()
	
func _process(delta: float) -> void:
	if animation_started:
		animation_timer += delta
		if animation_timer >= 2.0:
			t2.show()
		if animation_timer >= 4.0:
			t3.show()
		if animation_timer >= 10.0:
			t4.show()
			animation_started = false
