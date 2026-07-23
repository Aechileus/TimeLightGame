extends Node
class_name PlayerFootstepComponent

@export var enabled: bool = true
@export_range(0.1, 2.0, 0.05) var walk_interval: float = 0.5
@export_range(0.1, 2.0, 0.05) var sprint_interval: float = 0.32
@export_range(0.1, 3.0, 0.05) var check_distance: float = 1.2
@export var default_material: Util.FLOOR_MATERIAL = Util.FLOOR_MATERIAL.CONCRETE
@export var material_streams: Dictionary[Util.FLOOR_MATERIAL, AudioStream] = {}
@export_range(0.5, 1.5, 0.01) var min_pitch: float = 0.9
@export_range(0.5, 1.5, 0.01) var max_pitch: float = 1.12

var current_material: Util.FLOOR_MATERIAL = Util.FLOOR_MATERIAL.CONCRETE
var _body: CharacterBody3D
var _checker: RayCast3D
var _audio: AudioStreamPlayer3D
var _time: float = 0.0


# Store the shared player nodes and finish the small amount of ray and audio setup
# this component needs before the first physics frame.
func setup(body: CharacterBody3D, checker: RayCast3D, audio: AudioStreamPlayer3D) -> void:
	_body = body
	_checker = checker
	_audio = audio
	current_material = default_material
	_checker.enabled = true
	_checker.target_position = Vector3.DOWN * check_distance
	_audio.bus = &"SFX"


# Let the controller and any gameplay code read the material found by the floor ray.
func get_floor_material() -> Util.FLOOR_MATERIAL:
	return current_material


# Run after player movement so the ray sees the floor from the latest position.
# Material detection goes first so a surface change can play immediately.
func post_move_update(delta: float, is_moving: bool, is_sprinting: bool) -> void:
	var material_changed := _update_floor_material()
	_update_footsteps(delta, is_moving, is_sprinting, material_changed)


# Find the material group on the collider or one of its parents. Imported scenes
# often keep their group on the scene root while the ray hits a child physics body.
func _update_floor_material() -> bool:
	_checker.force_raycast_update()
	if not _checker.is_colliding():
		return false

	var previous_material := current_material
	var floor_node := _checker.get_collider() as Node
	while floor_node:
		for material_name: String in Util.FLOOR_MATERIAL.keys():
			if floor_node.is_in_group(StringName(material_name.to_lower())):
				current_material = Util.FLOOR_MATERIAL[material_name]
				return current_material != previous_material
		floor_node = floor_node.get_parent()

	current_material = default_material
	return current_material != previous_material


# Keep the footstep timer in sync with grounded movement. Surface changes get a
# sound right away, then the normal walk or sprint interval takes over.
func _update_footsteps(delta: float, is_moving: bool, is_sprinting: bool, material_changed: bool) -> void:
	if not enabled:
		return

	var is_grounded := _body.is_on_floor() and _checker.is_colliding()
	if not is_grounded:
		_time = 0.0
		return

	if material_changed:
		_time = 0.1
		_play_footstep()

	if not is_moving:
		_time = 0.0
		return

	_time += delta
	var interval := sprint_interval if is_sprinting else walk_interval
	if _time < interval:
		return

	_time = 0.0
	_play_footstep()


# Pick the stream assigned to the current material and add a small pitch change
# before playing it. The pitch variation keeps repeated steps from sounding flat.
### TODO we should probably adjust this to have it be able to play different types of streams for the same material for additional 
### sound playback variance.
func _play_footstep() -> void:
	var selected_stream := material_streams.get(current_material) as AudioStream
	if selected_stream:
		_audio.stream = selected_stream
	elif not material_streams.is_empty():
		return

	if _audio.stream:
		_audio.pitch_scale = randf_range(min_pitch, max_pitch)
		_audio.play()
