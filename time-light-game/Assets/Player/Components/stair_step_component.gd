extends Node
class_name PlayerStairStepComponent

@export_range(0.0, 1.0, 0.01) var max_step_height: float = 0.35
@export_range(0.001, 0.1, 0.001) var minimum_step_height: float = 0.02

@onready var _body: CharacterBody3D = $"../../PlayerCharacterBody3D"
@onready var _collision: CollisionShape3D = $"../../PlayerCharacterBody3D/PlayerCollisionShape"
@onready var _step_ray: RayCast3D = $"../../PlayerCharacterBody3D/StairStepRay"

var _capsule: CapsuleShape3D


# Get the capsule heigh and make ensure the raycast is on for the stepup/movement smoother.
func _ready() -> void:
	_capsule = _collision.shape as CapsuleShape3D
	_step_ray.enabled = true


# Check the ray while the player is trying to move. Valid staisr raises the
# collision body instantly, and the controller smooths that change for the camera.
func try_step_up(horizontal_motion: Vector3) -> float:
	if horizontal_motion.is_zero_approx():
		return 0.0

	_step_ray.force_raycast_update()
	if not _step_ray.is_colliding():
		return 0.0
	# ramps handle their own slope, stepping up on them just jitters the player
	if _is_in_ramp_group(_step_ray.get_collider()):
		return 0.0
	if _step_ray.get_collision_normal().dot(_body.up_direction) < cos(_body.floor_max_angle):
		return 0.0

	var foot_height := _collision.global_position.y - (_capsule.height * 0.5)
	var step_height := _step_ray.get_collision_point().y - foot_height
	if step_height < minimum_step_height or step_height > max_step_height:
		return 0.0
	if _body.test_move(_body.global_transform, Vector3.UP * step_height):
		return 0.0

	_body.global_position.y += step_height
	_body.velocity.y = 0.0
	return step_height


# ITS A RAMP (the identifier of ramps)
func _is_in_ramp_group(collider: Object) -> bool:
	var node := collider as Node
	while node:
		if node.is_in_group("ramp"):
			return true
		node = node.get_parent()
	return false
