extends OmniLight3D

# Drop this straight onto an OmniLight3D and it randomly flickers the light dimmer
# and back to whatever energy you set it to, with a rare chance to play a sound.

## roughly how many flicker bursts happen per second on average
@export_range(0.0, 10.0, 0.05) var flickers_per_second: float = 0.4
## how dim the light drops to during a flicker, as a fraction of its normal energy
@export_range(0.0, 1.0, 0.01) var dim_factor: float = 0.3
## how long a single dim and restore takes
@export_range(0.01, 1.0, 0.01) var flicker_time: float = 0.07
## most quick dips a single flicker burst can do
@export_range(1, 8, 1) var max_dips: int = 3
## chance from 0 to 1 that a flicker also plays the sound
@export_range(0.0, 1.0, 0.01) var sfx_chance: float = 0.15
@export var sfx: AudioStream

var _base_energy: float = 1.0
var _flickering: bool = false
var _audio: AudioStreamPlayer3D


func _ready() -> void:
	# remember the energy it was set to so we always restore back to it
	_base_energy = light_energy
	# reuse a child audio player if theres one, otherwise make a simple one
	_audio = get_node_or_null("FlickerSFX")
	if _audio == null:
		_audio = AudioStreamPlayer3D.new()
		_audio.bus = &"SFX"
		add_child(_audio)


func _process(delta: float) -> void:
	if _flickering:
		return
	# chance to kick off a flicker this frame, scaled by frame time so the rate
	# stays consistent no matter the framerate
	if randf() < flickers_per_second * delta:
		_do_flicker()


func _do_flicker() -> void:
	_flickering = true

	if sfx != null and randf() < sfx_chance:
		_audio.stream = sfx
		_audio.play()

	var dips := randi_range(1, max_dips)
	var tween := create_tween()
	for i in dips:
		var dim := _base_energy * dim_factor * randf_range(0.4, 1.0)
		tween.tween_property(self, "light_energy", dim, flicker_time)
		tween.tween_property(self, "light_energy", _base_energy, flicker_time)
	tween.tween_callback(func() -> void: _flickering = false)
