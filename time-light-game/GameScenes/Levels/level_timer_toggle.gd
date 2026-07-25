extends Area3D

@onready var player_controler = $"../PlayerController"
@onready var level_timer = $"../LevelTimer"

func _ready() -> void:
	body_entered.connect(toggle_level_timer)
	pass

func toggle_level_timer(body: Node3D):
	if !body.is_in_group("player"):
		return
	
	player_controler._hide_level_timer = false
	player_controler.update_show_hide_ui.emit()
	
	level_timer.level_time = 30.0
	level_timer.paused = false
	body_entered.disconnect(toggle_level_timer)
