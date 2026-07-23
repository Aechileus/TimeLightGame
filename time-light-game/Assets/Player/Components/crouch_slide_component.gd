extends Node
class_name PlayerCrouchSlideComponent

@export_range(0.1, 15.0, 0.1) var movement_speed: float = 3.0
@export_range(0.3, 1.5, 0.05) var crouch_height: float = 0.6
@export_range(0.1, 10.0, 0.1) var resize_speed: float = 5.0
@export_range(0.1, 20.0, 0.1) var slide_minimum_entry_speed: float = 5.5
@export_range(0.1, 30.0, 0.1) var slide_start_speed: float = 8.0
@export_range(0.1, 30.0, 0.1) var slide_friction: float = 4.0
@export_range(0.1, 10.0, 0.1) var slide_exit_speed: float = 2.5
@export_range(0.0, 10.0, 0.1) var slide_steering: float = 2.5

@onready var _body: CharacterBody3D = $"../../PlayerCharacterBody3D"
@onready var _collision: CollisionShape3D = $"../../PlayerCharacterBody3D/PlayerCollisionShape"

var _capsule: CapsuleShape3D
var _standing_height: float
var _collision_bottom: float
var _is_crouching: bool = false
var _is_sliding: bool = false


# Duplicates the capsule so we can remember the bottom position. Keeping that bottom fixed
# lets the collider change height without making the player's feet jump when done crouching.
func _ready() -> void:
	_capsule = _collision.shape.duplicate() as CapsuleShape3D
	_collision.shape = _capsule
	_standing_height = _capsule.height
	_collision_bottom = _collision.position.y - (_standing_height * 0.5)


# Read crouch input before the controller applies horizontal movement. This starts or
# stops a slide, updates crouch state, and eases the capsule toward its target height.
func update_input(delta: float, was_on_floor: bool, move_direction: Vector3, is_sprinting: bool) -> void:
	var crouch_held := Input.is_action_pressed(&"crouch")
	var horizontal_speed := Vector2(_body.velocity.x, _body.velocity.z).length()

	if Input.is_action_just_pressed(&"crouch") and was_on_floor:
		if horizontal_speed >= slide_minimum_entry_speed or is_sprinting:
			_start_slide(move_direction, horizontal_speed)

	if _is_sliding and (not crouch_held or not was_on_floor):
		stop_slide()

	if crouch_held or _is_sliding:
		_is_crouching = true
	elif _can_stand():
		_is_crouching = false

	var target_height := maxf(crouch_height, _capsule.radius * 2.0) if _is_crouching else _standing_height
	_set_height(move_toward(_capsule.height, target_height, resize_speed * delta))


# Apply steering and friction while a slide is active. Returning true tells the
# controller that this component handled horizontal velocity for the current frame.
func apply_slide_motion(delta: float, move_direction: Vector3) -> bool:
	if not _is_sliding:
		return false

	var velocity := Vector3(_body.velocity.x, 0.0, _body.velocity.z)
	var speed := velocity.length()
	var direction := velocity.normalized()
	if not move_direction.is_zero_approx():
		direction = direction.lerp(move_direction, clampf(slide_steering * delta, 0.0, 1.0)).normalized()

	speed = move_toward(speed, 0.0, slide_friction * delta)
	_body.velocity.x = direction.x * speed
	_body.velocity.z = direction.z * speed
	if speed <= slide_exit_speed:
		stop_slide()
	return true


# Lets the player controller figure out crouch state.
func is_crouching() -> bool:
	return _is_crouching


# Clear the slide state. Crouching can stay active as long as the input is held.
func stop_slide() -> void:
	_is_sliding = false


# Take the player's current travel direction and get any useful momentum.
# Input direction is a fallback for the first frame where horizontal speed is tiny.
func _start_slide(move_direction: Vector3, current_speed: float) -> void:
	var direction := Vector3(_body.velocity.x, 0.0, _body.velocity.z).normalized()
	if direction.is_zero_approx():
		direction = move_direction
	if direction.is_zero_approx():
		return

	var speed := maxf(current_speed, slide_start_speed)
	_body.velocity.x = direction.x * speed
	_body.velocity.z = direction.z * speed
	_is_sliding = true


# Resize the capsule and move its center so the cached foot position stays planted.
func _set_height(height: float) -> void:
	_capsule.height = height
	_collision.position.y = _collision_bottom + (height * 0.5)


# Checks if you can stand by taking the player height and removing a tiny ammount. A clear sweep
# means the collider can safely go back to normal without getting stuck in a ceiling.
func _can_stand() -> bool:
	if _capsule.height >= _standing_height - 0.001:
		return true
	var height_needed := _standing_height - _capsule.height
	return not _body.test_move(_body.global_transform, Vector3.UP * height_needed)
