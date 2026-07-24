extends Node
class_name PlayerTimeManipulationComponent

# How the flow clock works: the player scrolls to dial in how long time should
# run for, then when they unpause, this counts up with a tick beep every second
# and slams time back to a stop right when the clock hits the dialed number.

@export_range(0.25, 60.0, 0.25) var max_flow_time: float = 10.0
@export_range(0.25, 5.0, 0.25) var min_flow_time: float = 0.25
@export_range(0.25, 60.0, 0.25) var starting_flow_time: float = 3.0
# how many times time gets to lock back up, runs out and the world just keeps going
@export_range(0, 99, 1) var pause_charges: int = 3

@export_group("UI")
# readout starts green with a full clock and drains toward red as it ticks down
@export var countdown_full_color: Color = Color(0.35, 1.0, 0.4)
@export var countdown_empty_color: Color = Color(1.0, 0.25, 0.25)

const _TICK_BEEP := preload("res://Resources/SFX/PlaceholderSFX/lowpitchbeep.wav")

var flow_time: float = 3.0

var _charges_left: int = 0
var _flow_window_active: bool = false
var _flow_elapsed: float = 0.0
var _flow_target: float = 0.0
var _next_tick: float = 1.0
@export var _free_time_control: bool = false

var _tick_player: AudioStreamPlayer

@onready var _flowtime_label: Label = $TimeUI/FlowTimeLabel
@onready var _pauses_remain_label: RichTextLabel = $TimeUI/PausesRemainLabel


func _ready() -> void:
	_pauses_remain_label.text = "[wave=1] Pauses Remaining: " + str(pause_charges)
	flow_time = clampf(starting_flow_time, min_flow_time, max_flow_time)
	_charges_left = pause_charges

	_tick_player = AudioStreamPlayer.new()
	_tick_player.stream = _TICK_BEEP
	_tick_player.bus = &"SFX"
	add_child(_tick_player)

	_update_label()
	SignalBus.game_speed_state_changed.connect(_on_game_speed_state_changed)


func _physics_process(delta: float) -> void:
	# the clock only runs while time is actually flowing
	if not _flow_window_active or Global.is_time_stopped() or _free_time_control:
		return

	_flow_elapsed += delta

	# tick beep on every whole second the clock passes, each one pitched a
	# little lower so you can hear the window draining
	if _next_tick <= _flow_target and _flow_elapsed >= _next_tick:
		_tick_player.pitch_scale = maxf(1.0 - 0.1 * (_next_tick - 1.0), 0.1)
		_tick_player.play()
		_next_tick += 1.0

	if _flow_elapsed >= _flow_target:
		if _charges_left > 0:
			# clock ran out, pause everything
			# the signal handler below takes care of spending the charge
			Global.force_time_stop()
		else:
			# no charges left no longer allows pauses,
			### WE CAN SET FAILURE HERE OR RESTART THE LEVEL, UP TO YOU
			_flow_window_active = false

	# this just updates the UI timer
	_update_label()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_adjust_flow_time(1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_adjust_flow_time(-1)


# Lets the controller check if stopping time is still on the table.
func can_pause() -> bool:
	return _charges_left > 0 or _free_time_control


func _adjust_flow_time(direction: int) -> void:
	# half second steps normally, quarter steps once youre down at 1 or below
	var step := 0.5
	if flow_time < 1.0 or (is_equal_approx(flow_time, 1.0) and direction < 0):
		step = 0.25
	flow_time = clampf(flow_time + step * float(direction), min_flow_time, max_flow_time)
	_update_label()


func _on_game_speed_state_changed(new_state) -> void:
	if new_state == Global.TimeState.FLOWING:
		# lock in whatever the player commited to, this prevents a exploit where they could scroll up during movement
		_flow_window_active = true
		_flow_target = flow_time
		_flow_elapsed = 0.0
		_next_tick = 1.0
	else:
		# a window that ends in a stop costs a charge, covers both the clock running out and the player slamming the brakes early.
		#  the scene start freeze never had a window so it stays free
		if _flow_window_active:
			_flow_window_active = false
			_charges_left = maxi(_charges_left - 1, 0)
	_update_label()


func _update_label() -> void:
	if _pauses_remain_label == null:
		return
	if _flowtime_label == null:
		return
	if _free_time_control:
		_pauses_remain_label.hide()
		_flowtime_label.hide()
	else:
		_pauses_remain_label.show()
		_flowtime_label.show()
		

	if _flow_window_active and not Global.is_time_stopped():
		# live countdown, drains from green to red as the window runs out
		var remaining := maxf(_flow_target - _flow_elapsed, 0.0)
		var fill := remaining / _flow_target if _flow_target > 0.0 else 0.0
		_flowtime_label.text = "%ss" % String.num(remaining, 2)
		_flowtime_label.add_theme_color_override("font_color", countdown_empty_color.lerp(countdown_full_color, fill))
		_pauses_remain_label.text = "[wave=1] Pauses Remaining: " + str(_charges_left)
	else:
		# idle readout just shows whatever the player has dialed in
		_flowtime_label.text = "%ss" % String.num(flow_time, 2)
		_flowtime_label.add_theme_color_override("font_color", countdown_full_color)
