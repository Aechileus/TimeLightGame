extends CanvasLayer

# Level clock. The level has to be done before this hits zero or it resets.
# It only ticks while time is flowing because the tree pause stops _process,
# which means stopping time literally stops the deadline too. Abilities pay
# their cost straight out of this through the signal bus.

@export_range(5.0, 600.0, 5.0) var level_time: float = 60.0

var _time_left: float = 0.0

@onready var _label: Label = $TimerLabel


func _ready() -> void:
	_time_left = level_time
	SignalBus.ability_time_spent.connect(_on_ability_time_spent)
	_update_label()


func _process(delta: float) -> void:
	_time_left -= delta
	_update_label()
	if _time_left <= 0.0:
		# out of time, run it back
		get_tree().reload_current_scene()


func _on_ability_time_spent(seconds: float) -> void:
	_time_left = maxf(_time_left - seconds, 0.0)
	_update_label()


func _update_label() -> void:
	_label.text = String.num(maxf(_time_left, 0.0), 1)
