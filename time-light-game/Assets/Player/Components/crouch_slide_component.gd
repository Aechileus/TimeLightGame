extends Node
class_name PlayerCrouchSlideComponent

@export_range(0.1, 15.0, 0.1) var movement_speed: float = 3.0
@export_range(0.3, 1.5, 0.05) var crouch_height: float = 0.6
@export_range(0.1, 10.0, 0.1) var resize_speed: float = 5.0
## The minimum speed needed to start sliding (m/s)
@export_range(0.1, 20.0, 0.1) var slide_minimum_entry_speed: float = 5.5
## The speed you get set to when you start sliding (m/s)
@export_range(0.1, 30.0, 0.1) var slide_start_speed: float = 8.0
@export_range(0.1, 30.0, 0.1) var slide_friction: float = 4.0
@export_range(0.1, 10.0, 0.1) var slide_exit_speed: float = 2.5
@export_range(0.0, 10.0, 0.1) var slide_steering: float = 2.5

@export_group("Ramp Slide")
## how hard a downhill slide pulls you along the slope, bigger means it builds
## speed faster. gets scaled by how steep the ramp is
@export_range(0.0, 40.0, 0.5) var ramp_acceleration: float = 14.0
## ceiling on slide speed so a long ramp doesnt fling you to the moon
@export_range(1.0, 60.0, 0.5) var max_slide_speed: float = 30.0
## how long the slide survives brief airtime, otherwise skipping off a ramp
## lip instantly cancels the slide
@export_range(0.0, 0.5, 0.01) var slide_coyote_time: float = 0.15
## lets a slide keep going in the air instead of the coyote window ending it,
## we can turn this off here if it feels bad or causes issues
@export var allow_air_slide: bool = false

@export_group("Air Slam")
## how hard crouching in the air *INITIALLY* yanks you down
@export_range(0.0, 40.0, 0.5) var slam_speed: float = 14.0
## How fast you accelerate vertically while slamming (m/s^2)
@export_range(0.0, 120.0, 1.0) var slam_acceleration: float = 5.0
## ceiling on the slam pull so it doesnt grow forever
@export_range(1.0, 120.0, 1.0) var slam_max_speed: float = 60.0
## How much horizontal speed is multiplied by when slamming into the floor
@export_range(1.0, 2.0, 0.05) var slam_landing_speed_multiplier: float = 1.05

@export_group("Slide Jump")
## horizontal speed multiplier when jumping out of a slide
@export_range(1.0, 2.0, 0.05) var slide_jump_boost: float = 1.15

@onready var body: CharacterBody3D = $"../../PlayerCharacterBody3D"
@onready var collision: CollisionShape3D = $"../../PlayerCharacterBody3D/PlayerCollisionShape"

var capsule: CapsuleShape3D
var standing_height: float
var collision_bottom: float
var is_crouching: bool = false
var is_sliding: bool = false
var slide_air_time: float = 0.0
var is_slamming: bool = false
var slam_time: float = 0.0


## Duplicates the capsule so we can remember the bottom position. Keeping that bottom fixed
## lets the collider change height without making the player's feet jump when done crouching.
func _ready() -> void:
	capsule = collision.shape.duplicate() as CapsuleShape3D
	collision.shape = capsule
	standing_height = capsule.height
	collision_bottom = collision.position.y - (standing_height * 0.5)


## Read crouch input before the controller applies horizontal movement. This starts or
## stops a slide, updates crouch state, and eases the capsule toward its target height.
func update_input(delta: float, is_on_floor: bool, move_direction: Vector3, is_sprinting: bool) -> void:
	var crouch_held := Input.is_action_pressed(&"crouch")
	var horizontal_speed := Vector2(body.velocity.x, body.velocity.z).length()

	if Input.is_action_just_pressed(&"crouch"):
		# Start a slide if you have enough speed, or are moving on a ramp
		if is_on_floor:
			if horizontal_speed >= slide_minimum_entry_speed or (_is_on_ramp() and horizontal_speed > 0.1):
				_start_slide(move_direction, horizontal_speed)
		else:
			# crouching in the air starts a slam, no more floaty crouch drag
			start_slam()

	# letting go of crouch bails out of the slam early
	if is_slamming and not crouch_held:
		is_slamming = false

	if is_slamming:
		if is_on_floor:
			# Enter a slide with a horizontal speed boost if you reach the ground
			is_slamming = false
			_start_slide(move_direction, horizontal_speed * slam_landing_speed_multiplier)
		else:
			# Increment the slam time counter and apply the acceleration
			slam_time += delta
			body.velocity.y -= slam_acceleration * delta

	# STUPID ASS BUG WHERE IT COUNTS US AS NOT ON THE GROUND WHEN SLIDING ONRAMP
	# THIS FIXES IT BY GIVING TEENY TINY AIR TIME ALLOWS
	if is_sliding:
		if not crouch_held:
			stop_slide()
		elif not is_on_floor and not allow_air_slide:
			slide_air_time += delta
			if slide_air_time > slide_coyote_time:
				stop_slide()
		else:
			slide_air_time = 0.0

	# Update the crouching flag
	if crouch_held or is_sliding:
		is_crouching = true
	elif _can_stand():
		is_crouching = false

	# Reposition the camera 
	var target_height := maxf(crouch_height, capsule.radius * 2.0) if is_crouching else standing_height
	_set_height(move_toward(capsule.height, target_height, resize_speed * delta))

## Resets slam timer and applies initial slam yank
func start_slam():
	is_slamming = true
	slam_time = 0.0
	body.velocity.y -= slam_speed 
	
## Apply steering and friction while a slide is active.
func apply_slide_motion(delta: float, current_move_direction: Vector3) -> bool:
	var velocity := Vector3(body.velocity.x, 0.0, body.velocity.z)
	var speed := velocity.length()
	var direction := velocity.normalized()

	if not current_move_direction.is_zero_approx():
		direction = direction.lerp(current_move_direction, clampf(slide_steering * delta, 0.0, 1.0)).normalized()
	
	var normal := body.get_floor_normal() if body.is_on_floor() else Vector3.UP
	var downhill := Vector3(normal.x, 0.0, normal.z)
	var slope_pull := ramp_acceleration * direction.dot(downhill)

	# gravity feeds speed downhill and bleeds it uphill, friction stays gentle
	# both ways so sliding upwards is still slightly possible, just not for long
	speed = maxf(speed + slope_pull * delta, 0.0)
	speed = move_toward(speed, 0.0, slide_friction * delta)
	speed = minf(speed, max_slide_speed)

	# never hand a non finite value to the physics engine, jolt aborts on nan/inf
	if not is_finite(speed) or not direction.is_finite():
		stop_slide()
		return true

	body.velocity.x = direction.x * speed
	body.velocity.z = direction.z * speed
	# dont bail while a downhill is still feeding us that good speed
	if speed <= slide_exit_speed and slope_pull <= 0.0:
		stop_slide()
	return true

# ## Lets the player controller figure out crouch state.
# func is_crouching() -> bool:
# 	return is_crouching

# ## Lets the footstepper figure out slide state.
# func is_sliding() -> bool:
# 	return is_sliding

# ## Lets the controller know a slam is pulling the player down, mostly so the
# ## wall slide fall cap knows to stay out of the way.
# func is_slamming() -> bool:
# 	return is_slamming

## Called by the controller when the player jumps out of a slide.
## Scales horizontal velocity so slide hopping is a real way to build speed.
func apply_slide_jump_boost() -> void:
	body.velocity *= slide_jump_boost
	#body.velocity.z *= slide_jump_boost

## Clear the slide state. Crouching can stay active as long as the input is held.
func stop_slide() -> void:
	is_sliding = false

## Scan the floor contacts from the last move for anything in the ramp group.
## The rest of it just makes sure the parents might also be ramp since sometimes I set it
## as the parent for group, (keeps it simple since we can just set a tscn as it
func _is_on_ramp() -> bool:
	for i in body.get_slide_collision_count():
		var node := body.get_slide_collision(i).get_collider() as Node
		while node:
			if node.is_in_group("ramp"):
				return true
			node = node.get_parent()
	return false

## Boost the player up to the slide start speed if not already faster than it, 
## set the slide flag and reset slide timer.
func _start_slide(move_direction: Vector3, current_speed: float) -> void:
	var direction := Vector3(body.velocity.x, 0.0, body.velocity.z).normalized() # The direction of their current movement
	if direction.is_zero_approx():
		direction = move_direction # The direction they're inputting
	if direction.is_zero_approx():
		printerr("Attempted to start a slide with no velocity or input direction, should be unreachable")
		return

	# When the slide begins, boost the player up to the minimum slide speed
	if current_speed < slide_start_speed:
		body.velocity.x = direction.x * slide_start_speed
		body.velocity.z = direction.z * slide_start_speed
	is_sliding = true
	slide_air_time = 0.0

## Resize the capsule and move its center so the cached foot position stays planted.
func _set_height(height: float) -> void:
	capsule.height = height
	collision.position.y = collision_bottom + (height * 0.5)

## Checks if you can stand by taking the player height and removing a tiny ammount. A clear sweep
## means the collider can safely go back to normal without getting stuck in a ceiling.
func _can_stand() -> bool:
	if capsule.height >= standing_height - 0.001:
		return true
	var height_needed := standing_height - capsule.height
	return not body.test_move(body.global_transform, Vector3.UP * height_needed)
