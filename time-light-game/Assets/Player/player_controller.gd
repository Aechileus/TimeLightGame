extends Node3D

@export_group("Movement")
@export_range(0.1, 30.0, 0.1) var walk_speed: float = 5.0
@export_range(0.1, 40.0, 0.1) var sprint_speed: float = 8.0
@export_range(0.1, 100.0, 0.1) var ground_acceleration: float = 28.0
@export_range(0.1, 100.0, 0.1) var ground_deceleration: float = 34.0
@export_range(0.1, 50.0, 0.1) var air_acceleration: float = 8.0
@export_range(0.0, 5.0, 0.05) var gravity_multiplier: float = 1.0
@export_range(0.1, 20.0, 0.1) var jump_velocity: float = 5.5

@export_group("Stairs")
@export_range(0.0, 1.0, 0.01) var max_step_height: float = 0.35
@export_range(0.001, 0.1, 0.001) var minimum_step_height: float = 0.02
@export_range(0.1, 20.0, 0.1) var step_camera_smoothing: float = 8.0

@export_group("Camera")
var capture_mouse_on_start: bool = true
var click_to_capture_mouse: bool = true
@export_range(0.0001, 0.02, 0.0001) var mouse_sensitivity: float = 0.0025
@export_range(-89.0, 0.0, 1.0) var minimum_look_angle: float = -85.0
@export_range(0.0, 89.0, 1.0) var maximum_look_angle: float = 85.0

@export_group("Footsteps")
@export var footsteps_enabled: bool = true
@export_range(0.1, 2.0, 0.05) var walk_footstep_interval: float = 0.5
@export_range(0.1, 2.0, 0.05) var sprint_footstep_interval: float = 0.32
@export_range(0.1, 3.0, 0.05) var footstep_check_distance: float = 1.2
@export var default_floor_material: Util.FLOOR_MATERIAL = Util.FLOOR_MATERIAL.CONCRETE
@export var material_footstep_streams: Dictionary[Util.FLOOR_MATERIAL, AudioStream] = {}
@export_range(0.5, 1.5, 0.01) var min_pitch: float = 0.9
@export_range(0.5, 1.5, 0.01) var max_pitch: float = 1.12

@onready var character_body: CharacterBody3D = $PlayerCharacterBody3D
@onready var player_collision: CollisionShape3D = $PlayerCharacterBody3D/PlayerCollisionShape
@onready var player_camera: Camera3D = $PlayerCharacterBody3D/PlayerCamera
@onready var footstep_checker: RayCast3D = $PlayerCharacterBody3D/FootStepChecker
@onready var footstep_audio: AudioStreamPlayer3D = $PlayerCharacterBody3D/PlayerSFXs

var current_floor_material: Util.FLOOR_MATERIAL = Util.FLOOR_MATERIAL.CONCRETE
var _gravity: float = 9.8
var _footstep_time: float = 0.0
var _is_sprinting: bool = false
var _camera_base_height: float = 0.0
var _camera_step_offset: float = 0.0


func _ready() -> void:
	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	current_floor_material = default_floor_material
	_camera_base_height = player_camera.position.y

	# A longer floor snap keeps the body attached while walking down short steps.
	character_body.floor_snap_length = maxf(character_body.floor_snap_length, max_step_height + 0.05)
	footstep_checker.enabled = true
	footstep_checker.target_position = Vector3.DOWN * footstep_check_distance
	footstep_audio.bus = &"SFX"

	if capture_mouse_on_start:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	var input_vector := Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")
	_is_sprinting = Input.is_physical_key_pressed(KEY_SHIFT) and input_vector.length_squared() > 0.0
	var speed := sprint_speed if _is_sprinting else walk_speed

	# Movement follows the body's yaw, so forward always matches the camera heading.
	var move_direction := character_body.global_transform.basis * Vector3(input_vector.x, 0.0, input_vector.y)
	move_direction.y = 0.0
	move_direction = move_direction.normalized()

	var target_velocity := move_direction * speed
	var was_on_floor := character_body.is_on_floor()
	var acceleration := ground_acceleration if was_on_floor else air_acceleration
	if move_direction.is_zero_approx():
		acceleration = ground_deceleration if was_on_floor else air_acceleration

	character_body.velocity.x = move_toward(character_body.velocity.x, target_velocity.x, acceleration * delta)
	character_body.velocity.z = move_toward(character_body.velocity.z, target_velocity.z, acceleration * delta)

	var jumped := false
	if was_on_floor:
		if Input.is_action_just_pressed(&"ui_accept"):
			character_body.velocity.y = jump_velocity
			jumped = true
	else:
		character_body.velocity.y -= _gravity * gravity_multiplier * delta

	var horizontal_motion := Vector3(character_body.velocity.x, 0.0, character_body.velocity.z) * delta
	var step_height := 0.0
	if was_on_floor and not jumped:
		step_height = _try_step_up(horizontal_motion)

	if step_height > 0.0:
		# The body moves onto the step at once while this offset keeps the view smooth.
		_camera_step_offset -= step_height
	else:
		character_body.move_and_slide()

	var material_changed := _update_floor_material()
	_update_footsteps(delta, move_direction.length_squared() > 0.0, material_changed)
	_update_step_camera(delta)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_rotate_view(event.relative)
		return

	if event is InputEventMouseButton and event.pressed and click_to_capture_mouse:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func get_floor_material() -> Util.FLOOR_MATERIAL:
	return current_floor_material


func _rotate_view(mouse_delta: Vector2) -> void:
	character_body.rotate_y(-mouse_delta.x * mouse_sensitivity)
	player_camera.rotation.x = clampf(
		player_camera.rotation.x - mouse_delta.y * mouse_sensitivity,
		deg_to_rad(minimum_look_angle),
		deg_to_rad(maximum_look_angle)
	)

# SMOOTHING for small steps and stuff

func _try_step_up(horizontal_motion: Vector3) -> float:
	if max_step_height <= 0.0 or horizontal_motion.is_zero_approx():
		return 0.0

	var starting_transform := character_body.global_transform
	var raised_transform := starting_transform
	var up_motion := PhysicsTestMotionParameters3D.new()
	up_motion.from = starting_transform
	up_motion.motion = Vector3.UP * max_step_height
	var up_result := PhysicsTestMotionResult3D.new()

	# There needs to be enough room above the player before trying the step.
	if PhysicsServer3D.body_test_motion(character_body.get_rid(), up_motion, up_result):
		return 0.0

	raised_transform.origin += Vector3.UP * max_step_height
	var forward_motion := PhysicsTestMotionParameters3D.new()
	forward_motion.from = raised_transform
	forward_motion.motion = horizontal_motion
	var forward_result := PhysicsTestMotionResult3D.new()

	# A collision at the raised height means this is a wall, not a small step.
	if PhysicsServer3D.body_test_motion(character_body.get_rid(), forward_motion, forward_result):
		return 0.0

	var down_start := raised_transform
	down_start.origin += horizontal_motion
	var down_motion := PhysicsTestMotionParameters3D.new()
	down_motion.from = down_start
	down_motion.motion = Vector3.DOWN * (max_step_height + character_body.floor_snap_length)
	var down_result := PhysicsTestMotionResult3D.new()
	if not PhysicsServer3D.body_test_motion(character_body.get_rid(), down_motion, down_result):
		return 0.0

	var floor_limit := cos(character_body.floor_max_angle)
	if down_result.get_collision_normal().dot(character_body.up_direction) < floor_limit:
		return 0.0

	var landing_transform := down_start
	landing_transform.origin += down_result.get_travel()
	var height_gained := landing_transform.origin.y - starting_transform.origin.y
	if height_gained < minimum_step_height or height_gained > max_step_height + character_body.safe_margin:
		return 0.0

	character_body.global_transform = landing_transform
	character_body.velocity.y = 0.0
	character_body.apply_floor_snap()
	return height_gained


func _update_step_camera(delta: float) -> void:
	_camera_step_offset = move_toward(_camera_step_offset, 0.0, step_camera_smoothing * delta)
	var camera_position := player_camera.position
	camera_position.y = _camera_base_height + _camera_step_offset
	player_camera.position = camera_position



# Footstep Player

# The ray hits collision bodies, while material groups may live on a parent scene node.
func _update_floor_material() -> bool:
	footstep_checker.force_raycast_update()
	if not footstep_checker.is_colliding():
		return false

	var previous_material := current_floor_material
	var floor_node := footstep_checker.get_collider() as Node
	while floor_node:
		for material_name: String in Util.FLOOR_MATERIAL.keys():
			if floor_node.is_in_group(StringName(material_name.to_lower())):
				current_floor_material = Util.FLOOR_MATERIAL[material_name]
				return current_floor_material != previous_material
		floor_node = floor_node.get_parent()

	current_floor_material = default_floor_material
	return current_floor_material != previous_material


func _update_footsteps(delta: float, is_moving: bool, material_changed: bool) -> void:
	if not footsteps_enabled:
		return

	var is_grounded := character_body.is_on_floor() and footstep_checker.is_colliding()
	if not is_grounded:
		_footstep_time = 0.0
		return

	if material_changed:
		_footstep_time = 0.1
		_play_footstep()

	if not is_moving:
		_footstep_time = 0.0
		return

	_footstep_time += delta
	var interval := sprint_footstep_interval if _is_sprinting else walk_footstep_interval
	if _footstep_time < interval:
		return

	_footstep_time = 0.0
	_play_footstep()


func _play_footstep() -> void:
	#if footstep_audio.playing == true:
	#	return
	var selected_stream := material_footstep_streams.get(current_floor_material) as AudioStream
	if selected_stream:
		footstep_audio.stream = selected_stream
	elif not material_footstep_streams.is_empty():
		return

	# PlayerSFXs can still provide one shared stream when the material dictionary is empty.
	if footstep_audio.stream:
		footstep_audio.pitch_scale = randf_range(min_pitch, max_pitch)
		footstep_audio.play()
