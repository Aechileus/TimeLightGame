@tool
extends Node3D

@export var sync_enabled: bool = true
@export var kill_area_padding: float = 0.3

@onready var _mesh: MeshInstance3D = $MeshInstance3D
@onready var _body_shape: CollisionShape3D = $StaticBody3D/CollisionShape3D
@onready var _area_shape: CollisionShape3D = $KillArea/CollisionShape3D


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		set_process(false)
		return
	if sync_enabled:
		_sync()


func _sync() -> void:
	if _mesh == null or _mesh.mesh == null:
		return
	var aabb := _mesh.mesh.get_aabb()
	var box_size := aabb.size * _mesh.scale
	var centre := _mesh.position + aabb.get_center() * _mesh.scale
	_fit(_body_shape, box_size, centre)
	# pad the kill area out a touch so brushing the wall counts as a hit
	_fit(_area_shape, box_size + Vector3.ONE * kill_area_padding, centre)


func _fit(cs: CollisionShape3D, box_size: Vector3, centre: Vector3) -> void:
	if cs == null or not (cs.shape is BoxShape3D):
		return
	cs.shape.size = box_size
	cs.position = centre
