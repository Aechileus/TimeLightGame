extends MeshInstance3D


@export_range(0.0, 0.5, 0.01) var uv_writhe: float = 0.5
@export_range(0.1, 20.0, 0.1) var writhe_speed: float = 20

var _material: StandardMaterial3D
var _base_uv: Vector3
var _time: float = 0.0
var _noise_x := FastNoiseLite.new()
var _noise_z := FastNoiseLite.new()


func _ready() -> void:
	var mat := get_active_material(0)
	if mat == null or not (mat is StandardMaterial3D):
		return
	_material = mat.duplicate()
	set_surface_override_material(0, _material)
	_base_uv = _material.uv1_scale
	_noise_x.seed = randi()
	_noise_z.seed = randi()


func _process(delta: float) -> void:
	if _material == null:
		return
	_time += delta
	var uv := _base_uv
	uv.x += _noise_x.get_noise_1d(_time * writhe_speed) * uv_writhe
	uv.z += _noise_z.get_noise_1d(_time * writhe_speed) * uv_writhe
	_material.uv1_scale = uv
