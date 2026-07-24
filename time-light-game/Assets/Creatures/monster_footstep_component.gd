extends Node3D
class_name MonsterFootstepComponent


@export_range(0.1, 2.0, 0.05) var step_interval: float = 0.28
@export var default_material: Util.FLOOR_MATERIAL = Util.FLOOR_MATERIAL.CONCRETE
@export var material_streams: Dictionary[Util.FLOOR_MATERIAL, AudioStream] = {}
@export_range(0.5, 1.5, 0.01) var min_pitch: float = 0.8
@export_range(0.5, 1.5, 0.01) var max_pitch: float = 1.0

@onready var _checker: RayCast3D = $FootChecker
@onready var _audio: AudioStreamPlayer3D = $StepAudio

var _current_material: Util.FLOOR_MATERIAL = Util.FLOOR_MATERIAL.CONCRETE
var _time: float = 0.0




func _ready() -> void:
	_current_material = default_material
	_checker.enabled = true

func update(delta: float, is_grounded: bool, is_moving: bool) -> void:
	if not is_grounded or not is_moving:
		_time = 0.0
		return


	_update_material()
	_time += delta
	if _time < step_interval:
		return
	_time = 0.0
	_play_step()

func _update_material() -> void:
	_checker.force_raycast_update()
	if not _checker.is_colliding():
		_current_material = default_material
		return
		
		

	var node := _checker.get_collider() as Node
	while node:
		for material_name: String in Util.FLOOR_MATERIAL.keys():
			if node.is_in_group(StringName(material_name.to_lower())):
				_current_material = Util.FLOOR_MATERIAL[material_name]
				return
		node = node.get_parent()

	_current_material = default_material


func _play_step() -> void:
	var stream := material_streams.get(_current_material) as AudioStream
	if stream == null:
		return
	_audio.stream = stream
	_audio.pitch_scale = randf_range(min_pitch, max_pitch)
	_audio.play()
