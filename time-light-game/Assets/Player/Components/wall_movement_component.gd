extends Node
class_name PlayerWallMovementComponent

@export_range(0.0, 1.0, 0.05) var gravity_multiplier: float = 0.25
@export_range(0.1, 20.0, 0.1) var max_fall_speed: float = 2.5
@export_range(0.1, 20.0, 0.1) var jump_vertical_velocity: float = 5.5
@export_range(0.1, 20.0, 0.1) var jump_horizontal_velocity: float = 6.5
@export_range(0.0, 0.5, 0.01) var contact_grace_time: float = 0.12
@export_range(0.0, 0.5, 0.01) var control_lock_time: float = 0.15

var _body: CharacterBody3D
var _contact_time_left: float = 0.0
var _control_time_left: float = 0.0
var _last_wall_normal: Vector3 = Vector3.ZERO


# The controller owns the CharacterBody3D reference, so it passes that in once
# when the player scene is ready.
func setup(body: CharacterBody3D) -> void:
	_body = body


# Tick the two short grace timers before movement and remember wall contact from
# the previous move_and_slide call. This gives players a little bit of coyote time incase theyre delayed jumping
func begin_frame(delta: float) -> void:
	_contact_time_left = maxf(_contact_time_left - delta, 0.0)
	_control_time_left = maxf(_control_time_left - delta, 0.0)
	refresh_contact()


# Save the latest vertical wall normal after movement. Floor contact clears the
# wall grace timer so a normal ground jump always gets priority.
func refresh_contact() -> void:
	if _body.is_on_floor():
		_contact_time_left = 0.0
		return
	if not _body.is_on_wall():
		return

	var wall_normal := _body.get_wall_normal()
	if absf(wall_normal.dot(_body.up_direction)) < 0.25:
		_last_wall_normal = wall_normal
		_contact_time_left = contact_grace_time


# Tells the regular air movement to wait briefly after a wall jump. This gives the
# outward push enough time to separate the player from the wall.
func controls_locked() -> bool:
	return _control_time_left > 0.0


# Spend the saved wall contact when jump is pressed and launch away from its normal.
# The return value lets the controller skip regular gravity for this frame.
func try_wall_jump(jump_pressed: bool) -> bool:
	if not jump_pressed or _contact_time_left <= 0.0:
		return false

	var jump_direction := _last_wall_normal
	jump_direction.y = 0.0
	jump_direction = jump_direction.normalized()
	_body.velocity.x += jump_direction.x * jump_horizontal_velocity
	_body.velocity.z += jump_direction.z * jump_horizontal_velocity
	_body.velocity.y = maxf(jump_vertical_velocity, _body.velocity.y + jump_vertical_velocity) 
	# ^ Will still add a boost without cancelling other vertical momentum
	_contact_time_left = 0.0
	_control_time_left = control_lock_time
	return true


# Use gentler gravity while the player is falling against a remembered wall.
# Upward movement keeps the normal gravity value passed in by the controller.
func get_gravity_multiplier(base_multiplier: float) -> float:
	if _contact_time_left > 0.0 and _body.velocity.y < 0.0:
		return gravity_multiplier
	return base_multiplier


# Cap downward velocity during a wall slide so gravity cannot build up a fast fall.
func clamp_fall_speed() -> void:
	if _contact_time_left > 0.0 and _body.velocity.y < 0.0:
		_body.velocity.y = maxf(_body.velocity.y, -max_fall_speed)
