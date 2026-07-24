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

@export_group("Ramp Slide")
# how hard a downhill slide pulls you along the slope, bigger means it builds
# speed faster. gets scaled by how steep the ramp is
@export_range(0.0, 40.0, 0.5) var ramp_acceleration: float = 14.0
# ceiling on slide speed so a long ramp doesnt fling you to the moon
@export_range(1.0, 60.0, 0.5) var max_slide_speed: float = 30.0
# how long the slide survives brief airtime, otherwise skipping off a ramp
# lip instantly cancels the slide
@export_range(0.0, 0.5, 0.01) var slide_coyote_time: float = 0.15
# lets a slide keep going in the air instead of the coyote window ending it,
# we can turn this off here if it feels bad or causes issues
@export var allow_air_slide: bool = false

@export_group("Air Slam")
# how hard crouching in the air yanks you down
@export_range(1.0, 40.0, 0.5) var slam_speed: float = 14.0
# how much faster the slam yanks you down per second you keep holding it
@export_range(0.0, 120.0, 1.0) var slam_ramp: float = 20.0
# ceiling on the slam pull so it doesnt grow forever
@export_range(1.0, 120.0, 1.0) var slam_max_speed: float = 60.0
# little reward for slamming into a slide, multiplies landing speed
@export_range(1.0, 2.0, 0.05) var slam_landing_boost: float = 1.05

@export_group("Slide Jump")
# horizontal speed multiplier when jumping out of a slide
@export_range(1.0, 2.0, 0.05) var slide_jump_boost: float = 1.15

@onready var _body: CharacterBody3D = $"../../PlayerCharacterBody3D"
@onready var _collision: CollisionShape3D = $"../../PlayerCharacterBody3D/PlayerCollisionShape"

var _capsule: CapsuleShape3D
var _standing_height: float
var _collision_bottom: float
var _is_crouching: bool = false
var _is_sliding: bool = false
var _slide_air_time: float = 0.0
var _is_slamming: bool = false
# how long the current slam has been held, ramps the downward pull
var _slam_time: float = 0.0


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

	if Input.is_action_just_pressed(&"crouch"):
		if was_on_floor:
			# on a ramp any bit of movement kicks off a slide, otherwise you
			# need some speed to start
			var ramp_slide := _is_on_ramp() and horizontal_speed > 0.1
			if horizontal_speed >= slide_minimum_entry_speed or is_sprinting or ramp_slide:
				_start_slide(move_direction, horizontal_speed)
		else:
			# crouching in the air starts a slam, no more floaty crouch drag
			_is_slamming = true
			_slam_time = 0.0

	# letting go of crouch bails out of the slam early
	if _is_slamming and not crouch_held:
		_is_slamming = false

	if _is_slamming:
		if was_on_floor:
			# touchdown always drops you into a slide now, no speed needed
			_is_slamming = false
			_start_slide(move_direction, horizontal_speed * slam_landing_boost)
		else:
			# the pull ramps up the longer you hold it, capped so it stays sane.
			# reapplied every frame so gravity tweaks cant soften it
			_slam_time += delta
			var pull := minf(slam_speed + slam_ramp * _slam_time, slam_max_speed)
			_body.velocity.y = minf(_body.velocity.y, -pull)

	# STUPID ASS BUG WHERE IT COUNTS US AS NOT ON THE GROUND WHEN SLIDING ONRAMP
	# THIS FIXES IT BY GIVING TEENY TINY AIR TIME ALLOWS
	if _is_sliding:
		if not crouch_held:
			stop_slide()
		elif not was_on_floor and not allow_air_slide:
			_slide_air_time += delta
			if _slide_air_time > slide_coyote_time:
				stop_slide()
		else:
			_slide_air_time = 0.0

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
	
	var normal := _body.get_floor_normal() if _body.is_on_floor() else Vector3.UP
	var downhill := Vector3(normal.x, 0.0, normal.z)
	var slope_pull := ramp_acceleration * direction.dot(downhill)

	# gravity feeds speed downhill and bleeds it uphill, friction stays gentle
	# both ways so sliding upwards is still slightly possible, just not for long
	speed = maxf(speed + slope_pull * delta, 0.0)
	speed = move_toward(speed, 0.0, slide_friction * delta)
	speed = minf(speed, max_slide_speed)

	_body.velocity.x = direction.x * speed
	_body.velocity.z = direction.z * speed
	# dont bail while a downhill is still feeding us that good speed
	if speed <= slide_exit_speed and slope_pull <= 0.0:
		stop_slide()
	return true


# Lets the player controller figure out crouch state.
func is_crouching() -> bool:
	return _is_crouching

# Lets the footstepper figure out slide state.
func is_sliding() -> bool:
	return _is_sliding

# Lets the controller know a slam is pulling the player down, mostly so the
# wall slide fall cap knows to stay out of the way.
func is_slamming() -> bool:
	return _is_slamming


# Called by the controller when the player jumps out of a slide.
# Scales horizontal velocity so slide hopping is a real way to build speed.
func apply_slide_jump_boost() -> void:
	_body.velocity.x *= slide_jump_boost
	_body.velocity.z *= slide_jump_boost


# Clear the slide state. Crouching can stay active as long as the input is held.
func stop_slide() -> void:
	_is_sliding = false


# Scan the floor contacts from the last move for anything in the ramp group.
# The rest of it just makes sure the parents might also be ramp since sometimes I set it
# as the parent for group, (keeps it simple since we can just set a tscn as it
func _is_on_ramp() -> bool:
	for i in _body.get_slide_collision_count():
		var node := _body.get_slide_collision(i).get_collider() as Node
		while node:
			if node.is_in_group("ramp"):
				return true
			node = node.get_parent()
	return false


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
	_slide_air_time = 0.0


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
