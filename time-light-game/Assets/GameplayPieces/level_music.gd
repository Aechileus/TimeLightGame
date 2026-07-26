extends AudioStreamPlayer3D

const SILENT_DB := -60.0

## how long the crossfades take
@export_range(0.0, 5.0, 0.05) var crossfade_time: float = 0.3

enum State { INTRO, MAIN, PAUSE }

var intro: AudioStream
var main: AudioStream
var intro_pause: AudioStream
var pauses: Array[AudioStream] = []

var players: Array[AudioStreamPlayer3D] = []
var active: int = 1
var base_volume: float = 0.0
var fade_tween: Tween

var state: int = State.INTRO
var return_state: int = State.MAIN
var intro_position: float = 0.0
var intro_length: float = 0.0
var intro_handoff: bool = false
var was_paused: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	base_volume = volume_db

	var interactive := stream as AudioStreamInteractive
	for i in interactive.get_clip_count():
		var clip_name := String(interactive.get_clip_name(i))
		var clip_stream := interactive.get_clip_stream(i)
		match clip_name:
			"Level Intro":
				intro = clip_stream
			"Level Main":
				main = clip_stream
			"Level Intro Pause":
				intro_pause = clip_stream
			_:
				pauses.append(clip_stream)

	set_loop(intro, false)
	set_loop(main, true)
	set_loop(intro_pause, true)
	for p in pauses:
		set_loop(p, true)

	intro_length = intro.get_length()

	stream = null
	players.append(self)
	var second := AudioStreamPlayer3D.new()
	second.bus = bus
	second.unit_size = unit_size
	second.max_distance = max_distance
	second.attenuation_model = attenuation_model
	second.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(second)
	players.append(second)

	for p in players:
		p.finished.connect(on_player_finished)

	state = State.INTRO
	play_clip(intro, 0.0, 0.0)


func _process(_delta: float) -> void:
	var paused := get_tree().paused
	if paused and not was_paused:
		enter_pause()
	elif not paused and was_paused:
		exit_pause()
	was_paused = paused

	if state == State.INTRO and not paused and not intro_handoff and intro_length > 0.0:
		if active_player().get_playback_position() >= intro_length - crossfade_time:
			handoff_to_main()


func enter_pause() -> void:
	if state == State.PAUSE:
		return
	return_state = state
	if state == State.MAIN:
		if pauses.is_empty():
			return
		var pos := active_player().get_playback_position()
		state = State.PAUSE
		play_clip(pauses.pick_random(), pos, crossfade_time)
	else:
		intro_position = active_player().get_playback_position()
		state = State.PAUSE
		play_clip(intro_pause, intro_position, crossfade_time)


func exit_pause() -> void:
	if state != State.PAUSE:
		return
	if return_state == State.INTRO:
		state = State.INTRO
		intro_handoff = false
		play_clip(intro, intro_position, crossfade_time)
	else:
		var pos := active_player().get_playback_position()
		state = State.MAIN
		play_clip(main, pos, crossfade_time)


func on_player_finished() -> void:
	if state == State.INTRO and not intro_handoff:
		handoff_to_main()


func handoff_to_main() -> void:
	intro_handoff = true
	state = State.MAIN
	play_clip(main, 0.0, crossfade_time)


func active_player() -> AudioStreamPlayer3D:
	return players[active]


func play_clip(clip: AudioStream, from_position: float, fade: float) -> void:
	var incoming := players[1 - active]
	var outgoing := players[active]

	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()

	incoming.stream = clip
	incoming.play(from_position)

	if fade <= 0.0:
		incoming.volume_db = base_volume
		outgoing.stop()
	else:
		incoming.volume_db = SILENT_DB
		fade_tween = create_tween()
		fade_tween.tween_property(incoming, "volume_db", base_volume, fade)
		fade_tween.parallel().tween_property(outgoing, "volume_db", SILENT_DB, fade)
		fade_tween.chain().tween_callback(outgoing.stop)

	active = 1 - active


func set_loop(s: AudioStream, value: bool) -> void:
	if s is AudioStreamMP3:
		s.loop = value
	elif s is AudioStreamOggVorbis:
		s.loop = value
	elif s is AudioStreamWAV:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD if value else AudioStreamWAV.LOOP_DISABLED
