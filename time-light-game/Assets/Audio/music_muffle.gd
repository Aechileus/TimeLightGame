extends AudioStreamPlayer3D

# Slides the music onto the Muffled bus and slows it down while time is frozen,
# then back to normal once it flows again.

@export var muffled_bus: StringName = &"Muffled"
# playback rate while frozen, under 1 slows it and drops the pitch like a tape
@export_range(0.2, 1.0, 0.01) var muffled_pitch: float = 0.8
# playback rate while frozen, under 1 slows it and drops the pitch like a tape
@export_range(20.0, 20500.0, 10.0) var muffled_filter_cutoff: float = 440.0
# how long the slowdown and speed up take
@export_range(0.0, 2.0, 0.05) var fade_time: float = 0.4

@onready var muffled_bus_idx = AudioServer.get_bus_index("Muffled")
@onready var filter: AudioEffectLowPassFilter = AudioServer.get_bus_effect(muffled_bus_idx, 0)

var _normal_bus: StringName
var _normal_pitch: float
var _pitch_tween: Tween
var _filter_cutoff_tween: Tween


func _ready() -> void:
	# keep processing while the tree is paused so the pitch tween still runs
	process_mode = Node.PROCESS_MODE_ALWAYS
	_normal_bus = bus
	_normal_pitch = pitch_scale
	SignalBus.game_speed_state_changed.connect(_on_game_speed_state_changed)
	# catch the case where the level starts already paused
	_apply(Global.is_time_stopped())


func _on_game_speed_state_changed(new_state) -> void:
	_apply(new_state == Global.TimeState.STOPPED)


func _apply(stopped: bool) -> void:
	# the bus swap is instant, the pitch eases so it sounds like it winds down
	bus = muffled_bus if stopped else _normal_bus
	var pitch_target := muffled_pitch if stopped else _normal_pitch
	if _pitch_tween:
		_pitch_tween.kill()
	_pitch_tween = create_tween()
	_pitch_tween.tween_property(self, "pitch_scale", pitch_target, fade_time)
	
	var cutoff_target := muffled_filter_cutoff if stopped else 20500.0
	var cutoff_start = filter.cutoff_hz
	if _filter_cutoff_tween:
		_filter_cutoff_tween.kill()
	_filter_cutoff_tween = create_tween()
	_filter_cutoff_tween.tween_method(
		# Function to simulate an exponential lerp
		func(hz): set_filter_cutoff(cutoff_start * pow(cutoff_target/cutoff_start, inverse_lerp(cutoff_start, cutoff_target, hz))),
		cutoff_start,
		cutoff_target,
		fade_time
	)
	

func set_filter_cutoff(hz: float):
	filter.cutoff_hz = clampf(hz, 0.0, 20500.0)
	if hz >= 20000.0:
		AudioServer.set_bus_bypass_effects(muffled_bus_idx, true)
	else:
		AudioServer.set_bus_bypass_effects(muffled_bus_idx, false)
