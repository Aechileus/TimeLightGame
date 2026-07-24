extends CanvasLayer

# Level clock. The level has to be done before this hits zero or it resets.
# It only ticks while time is flowing because the tree pause stops _process,
# which means stopping time literally stops the deadline too. Abilities pay
# their cost straight out of this through the signal bus.

@export_range(5.0, 600.0, 5.0) var level_time: float = 60.0
@export var infinite_time: bool = false
@export var paused: bool = false

var _time_left: float = 0.0


@onready var _label: Label = $TimerLabel


func _ready() -> void:
	if !infinite_time:
		_time_left = level_time
		SignalBus.ability_time_spent.connect(_on_ability_time_spent)
	_update_label()


func _process(delta: float) -> void:
	if infinite_time or paused: # If the time is infinite, just update the label
		_update_label()
		return
		
	_time_left -= delta
	_update_label()
	if _time_left <= 0.0:
		# out of time, run it back
		get_tree().reload_current_scene()


func _on_ability_time_spent(seconds: float) -> void:
	_time_left = maxf(_time_left - seconds, 0.0)
	_update_label()


func _update_label() -> void:
	if infinite_time:
		_label.text = "XXX:XXX"
		return
	var time_left: float = maxf(_time_left, 0.0)
	var secs: int = floori(time_left)
	var milis: int = floori((time_left - secs) * 1000)
	_label.text = String.num(secs, 0) + ":" + String.num(milis, 0).pad_zeros(3)
