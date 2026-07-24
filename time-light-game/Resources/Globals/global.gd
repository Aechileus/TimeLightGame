extends Node


# Global Globals, should be pretty self explanatory

var game_speed: float = 1.0

# Time stop stuff. Global owns the actual pause state and the beep countdown,
# anything that cares about visuals or gameplay reactions should listen to
# SignalBus.game_speed_state_changed instead of polling this.
enum TimeState { FLOWING, STOPPED }

var time_state: TimeState = TimeState.FLOWING
var _time_toggle_busy: bool = false

const _HIGH_BEEP := preload("res://Resources/SFX/PlaceholderSFX/highpitchbeep.wav")
const _LOW_BEEP := preload("res://Resources/SFX/PlaceholderSFX/lowpitchbeep.wav")
const _ONE_BEEP := preload("res://Resources/SFX/PlaceholderSFX/One.wav")
const _TWO_BEEP := preload("res://Resources/SFX/PlaceholderSFX/Two.wav")
const _THREE_BEEP := preload("res://Resources/SFX/PlaceholderSFX/Three.wav")
const _THREE_ALT_BEEP := preload("res://Resources/SFX/PlaceholderSFX/ThreeAlt.wav")
const _TIMESTOPSTART := preload("res://Resources/SFX/PlaceholderSFX/timestopstart.wav")
const _TIMESTOPSTARTALT : AudioStream = preload("res://Resources/SFX/PlaceholderSFX/timestopstartalt.wav")


var _beep_player: AudioStreamPlayer


func _ready() -> void:
	# has to keep running while the tree is paused, otherwise we could never resume
	process_mode = Node.PROCESS_MODE_ALWAYS
	_beep_player = AudioStreamPlayer.new()
	_beep_player.bus = &"SFX"
	add_child(_beep_player)


func is_time_stopped() -> bool:
	return time_state == TimeState.STOPPED


# Instant versions with no countdown beeps. Scene setup and the flow clock
# use these so the freeze lands exactly when it should.
func force_time_stop() -> void:
	_set_time_stopped(true)


func force_time_flow() -> void:
	_set_time_stopped(false)


func toggle_time_stop() -> void:
	# ignore spam while a beep sequence is already going
	if _time_toggle_busy:
		return
	_time_toggle_busy = true

	if time_state == TimeState.FLOWING:
		# high, high, then the freeze lands right on the low beep
		#await _play_beep_and_wait(_LOW_BEEP)
		# heads up for anything that wants to animate before the freeze lands
		SignalBus.time_stop_winding_up.emit(true)
		#await _play_beep_and_wait(_LOW_BEEP)
	#	_play_beep(_THREE_BEEP)
	#	await _play_beep_and_wait(_HIGH_BEEP)
	#	await _play_beep_and_wait(_HIGH_BEEP)
		_play_beep(_TIMESTOPSTART)
		_set_time_stopped(true)
	else:
		# low, low, then the resume lands right on the high beep
		#await _play_beep_and_wait(_HIGH_BEEP)
		# same heads up on the way back out
		SignalBus.time_stop_winding_up.emit(false)
		#await _play_beep_and_wait(_HIGH_BEEP)
	#	_play_beep(_ONE_BEEP)
	#	await _play_beep_and_wait(_LOW_BEEP)
	#	await _play_beep_and_wait(_LOW_BEEP)
		_play_beep(_TIMESTOPSTARTALT)
		_set_time_stopped(false)

	_time_toggle_busy = false


func _set_time_stopped(stopped: bool) -> void:
	time_state = TimeState.STOPPED if stopped else TimeState.FLOWING
	game_speed = 0.0 if stopped else 1.0
	get_tree().paused = stopped
	SignalBus.game_speed_state_changed.emit(time_state)


func _play_beep(stream: AudioStream) -> void:
	_beep_player.stream = stream
	_beep_player.play()


func _play_beep_and_wait(stream: AudioStream) -> void:
	_play_beep(stream)
	await _beep_player.finished
