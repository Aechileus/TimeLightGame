extends Area3D

@onready var level_timer = $"../LevelTimer"

func _ready() -> void:
	body_entered.connect(toggle_level_timer)
	pass

func toggle_level_timer(body: Node3D):
	if !body.is_in_group("player"):
		return

	# grant the timer ui through the unlock system, this only ever flips it on so
	# no later unlock area can hide it again
	Global.grant_ui_level_timer()

	level_timer.level_time = 30.0
	level_timer.paused = false
	body_entered.disconnect(toggle_level_timer)
