extends CanvasLayer

# Level clock. The level has to be done before this hits zero or it resets.
# It only ticks while time is flowing because the tree pause stops _process,
# which means stopping time literally stops the deadline too. Abilities pay
# their cost straight out of this through the signal bus.

@export_range(5.0, 600.0, 5.0) var level_time: float = 60.0
@export var infinite_time: bool = false
@export var paused: bool = false

var time_left: float = 0.0

@onready var label: RichTextLabel = $TimerLabel


func _ready() -> void:
	if !infinite_time:
		time_left = level_time
		SignalBus.change_level_time.connect(change_level_time)
	update_label()


func _process(delta: float) -> void:
	if infinite_time or paused: # If the time is infinite, just update the label
		update_label()
		return
		
	time_left -= delta
	update_label()
	if time_left <= 0.0:
		# out of time, run it back
		SignalBus.out_of_time.emit()


func change_level_time(seconds: float) -> void:
	time_left += seconds
	update_label()


func update_label() -> void:
	if infinite_time:
		label.text = "XXX:XXX"
		return
	var time_left: float = maxf(time_left, 0.0)
	var secs: int = floori(time_left)
	var milis: int = floori((time_left - secs) * 1000)
	label.text = String.num(secs, 0) + ":" + String.num(milis, 0).pad_zeros(3)
