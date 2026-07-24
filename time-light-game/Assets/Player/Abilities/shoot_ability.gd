extends Node

const PROJECTILE := preload("res://Assets/Player/Abilities/projectile.tscn")

@onready var _camera: Camera3D = $"../../../PlayerCharacterBody3D/PlayerCamera"


func cast(ability: Ability, _point: Vector3, strength: float = 0.0) -> void:
	var bolt := PROJECTILE.instantiate()
	get_tree().current_scene.add_child(bolt)
	# nudge it out in front of the camera
	bolt.global_transform.basis = _camera.global_transform.basis
	bolt.global_position = _camera.global_position - _camera.global_transform.basis.z
	bolt.damage = ability.damage
	bolt.speed = ability.speed
