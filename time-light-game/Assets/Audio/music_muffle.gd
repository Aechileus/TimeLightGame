extends AudioStreamPlayer3D

# Slides the music onto the Muffled bus and slows it down while time is frozen,
# then back to normal once it flows again.

@export var muffled_bus: StringName = &"Muffled"
# playback rate while frozen, under 1 slows it and drops the pitch like a tape
@export_range(0.2, 1.0, 0.01) var muffled_pitch: float = 0.8
# how long the slowdown and speed up take
@export_range(0.0, 2.0, 0.05) var fade_time: float = 0.4

var _normal_bus: StringName
var _normal_pitch: float
var _pitch_tween: Tween


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
	var target := muffled_pitch if stopped else _normal_pitch
	if _pitch_tween:
		_pitch_tween.kill()
	_pitch_tween = create_tween()
	_pitch_tween.tween_property(self, "pitch_scale", target, fade_time)
