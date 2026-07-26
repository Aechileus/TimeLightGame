extends CanvasLayer

# Level clock. The level has to be done before this hits zero or it resets.
# It only ticks while time is flowing because the tree pause stops _process,
# which means stopping time literally stops the deadline too. Abilities pay
# their cost straight out of this through the signal bus.

const TICK := preload("res://Resources/SFX/Tick.mp3")
const TOCK := preload("res://Resources/SFX/Tock.mp3")
const COUNTDOWN := preload("res://Resources/SFX/Countdown.mp3")

@export_range(5.0, 600.0, 5.0) var level_time: float = 60.0
@export var infinite_time: bool = false
@export var paused: bool = false
## once the clock hits this many seconds left it drops the ticks for the countdown track
@export_range(1.0, 120.0, 1.0) var countdown_threshold: float = 32.0

var time_left: float = 0.0

var _last_second: int = -1
var _countdown_started: bool = false

@onready var label: RichTextLabel = $TimerLabel
@onready var audio: AudioStreamPlayer = $Audio


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
	_update_ticks()
	if time_left <= 0.0:
		# out of time, run it back
		SignalBus.out_of_time.emit()


func _update_ticks() -> void:
	# a clock pickup can shove time back over the threshold, if that happens bail
	# out of the countdown track and go back to the tick tock
	if _countdown_started and time_left > countdown_threshold:
		_countdown_started = false
		_last_second = -1
		audio.stop()

	if not _countdown_started and time_left <= countdown_threshold:
		_countdown_started = true
		audio.stream = COUNTDOWN
		# if the timer was enabled already under the threshold, scrub into the track
		# so its position lines up with however much time is actually left
		audio.play(maxf(countdown_threshold - time_left, 0.0))
		return
	if _countdown_started:
		return
	var current_second := ceili(time_left)
	if current_second == _last_second:
		return
	_last_second = current_second
	audio.stream = TICK if current_second % 2 == 0 else TOCK
	audio.play()


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
	
	if time_left <= 15.0:
		var colour_lerp = inverse_lerp(0.0, 15.0, time_left)
		label.add_theme_color_override("default_color", Color.from_rgba8(255, 255 * colour_lerp, 355 * colour_lerp, 255))
	else:
		label.remove_theme_color_override("default_color")
