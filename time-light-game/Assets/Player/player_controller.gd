extends Node3D

@export_group("Movement")
@export_range(0.1, 30.0, 0.1) var walk_speed: float = 5.0
@export_range(0.1, 40.0, 0.1) var sprint_speed: float = 8.0
@export_range(0.1, 100.0, 0.1) var ground_acceleration: float = 28.0
@export_range(0.1, 100.0, 0.1) var ground_deceleration: float = 34.0
@export_range(0.1, 50.0, 0.1) var air_acceleration: float = 8.0
@export_range(0.0, 5.0, 0.05) var gravity_multiplier: float = 1.0
@export_range(0.1, 20.0, 0.1) var jump_velocity: float = 5.5

@export_group("Sprint Momentum")
@export_range(0.0, 1.0, 0.01) var sprint_release_grace_time: float = 0.2
@export_range(0.1, 50.0, 0.1) var sprint_deceleration: float = 8.0
@export_range(0.1, 50.0, 0.1) var overspeed_deceleration: float = 2.0
@export_range(0.0, 20.0, 0.1) var momentum_steering: float = 3.0

@export_group("Camera")
@export_range(0.2, 1.5, 0.05) var crouch_camera_height: float = 0.6
@export_range(0.1, 20.0, 0.1) var crouch_camera_speed: float = 5.0
@export_range(0.1, 20.0, 0.1) var step_camera_smoothing: float = 8.0
@export_range(0.0001, 0.02, 0.0001) var mouse_sensitivity: float = 0.0025
@export_range(-89.0, 0.0, 1.0) var minimum_look_angle: float = -85.0
@export_range(0.0, 89.0, 1.0) var maximum_look_angle: float = 85.0
var capture_mouse_on_start: bool = true
var click_to_capture_mouse: bool = true

@export_group("Time Stop")
# per scene choice for whether the player wakes up frozen
@export var start_time_stopped: bool = true
# what pixel_size settles back to after a resume, 3 or 4 both look decent
@export_range(1.0, 8.0, 0.5) var normal_pixel_size: float = 3.0
@export var frozen_tint: Color = Color(1.0, 0.302, 0.302, 0.38)
@export var resume_flash_tint: Color = Color(0.349, 1.0, 0.4, 0.318)

@onready var character_body: CharacterBody3D = $PlayerCharacterBody3D
@onready var player_camera: Camera3D = $PlayerCharacterBody3D/PlayerCamera
@onready var footstep_checker: RayCast3D = $PlayerCharacterBody3D/FootStepChecker
@onready var footstep_audio: AudioStreamPlayer3D = $PlayerCharacterBody3D/PlayerSFXs
@onready var wall_movement: PlayerWallMovementComponent = $Components/WallMovement
@onready var crouch_slide: PlayerCrouchSlideComponent = $Components/CrouchSlide
@onready var stair_step: PlayerStairStepComponent = $Components/StairStep
@onready var footsteps: PlayerFootstepComponent = $Components/Footsteps
@onready var time_manipulation: PlayerTimeManipulationComponent = $Components/TimeManipulation
@onready var abilities: PlayerAbilitiesComponent = $Components/Abilities
@onready var overlay_mesh: MeshInstance3D = $PlayerCharacterBody3D/PlayerCamera/MeshInstance3D
@onready var arms_animation_player: AnimationPlayer = $PlayerCharacterBody3D/PlayerCamera/arms_rig/AnimationPlayer
@onready var arms_rig = $PlayerCharacterBody3D/PlayerCamera/arms_rig

@export var _gravity: float = 9.8
var _is_sprinting: bool = false
var _sprint_grace_time_left: float = 0.0
var _camera_base_height: float = 0.0
var _camera_current_height: float = 0.0
var _camera_step_offset: float = 0.0
var _overlay_material: ShaderMaterial
var _overlay_was_visible: bool = false
var _overlay_tween: Tween
var _flash_tween: Tween

func _ready() -> void:
	# player keeps processing while the tree is paused so the camera still works
	# during time stop, movement gets gated in _physics_process instead
	process_mode = Node.PROCESS_MODE_ALWAYS

	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	_camera_base_height = player_camera.position.y
	_camera_current_height = _camera_base_height

	_overlay_material = overlay_mesh.mesh.material as ShaderMaterial
	# start from no tint, alpha 0 is the off state now that alpha is strength
	_overlay_material.set_shader_parameter("tint", Color(1, 1, 1, 0))
	_overlay_was_visible = overlay_mesh.visible
	SignalBus.game_speed_state_changed.connect(_on_game_speed_state_changed)
	SignalBus.time_stop_winding_up.connect(_on_time_stop_winding_up)

	wall_movement.setup(character_body)
	footsteps.setup(character_body, footstep_checker, footstep_audio)

	if capture_mouse_on_start:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# deferred so every node is settled before the freeze signal goes out
	if start_time_stopped:
		Global.force_time_stop.call_deferred()
	elif Global.is_time_stopped():
		# stale stop hanging around from a previous scene, clear it
		Global.force_time_flow.call_deferred()


func _physics_process(delta: float) -> void:
	# frozen in time, no moving around. queueing ended up living in the
	# abilities component instead so this just gates movement now. Oh well, composition wins.
	if Global.is_time_stopped():
		return

	wall_movement.begin_frame(delta)

	var input_vector := Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")
	var move_direction := character_body.global_transform.basis * Vector3(input_vector.x, 0.0, input_vector.y)
	move_direction.y = 0.0
	move_direction = move_direction.normalized()

	var was_on_floor := character_body.is_on_floor()
	_update_sprint_state(delta, input_vector)
	crouch_slide.update_input(delta, was_on_floor, move_direction, _is_sprinting)
	_update_horizontal_movement(delta, move_direction, was_on_floor)

	var jumped := _update_jump_and_gravity(delta, was_on_floor)
	var horizontal_motion := Vector3(character_body.velocity.x, 0.0, character_body.velocity.z) * delta
	var step_height := 0.0
	if was_on_floor and not jumped:
		step_height = stair_step.try_step_up(horizontal_motion)

	var saved_floor_snap := character_body.floor_snap_length
	if step_height > 0.0:
		_camera_step_offset -= step_height
		character_body.floor_snap_length = 0.0

	character_body.move_and_slide()
	character_body.floor_snap_length = saved_floor_snap

	wall_movement.refresh_contact()
	var horizontal_speed := Vector2(character_body.velocity.x, character_body.velocity.z).length()
	footsteps.post_move_update(delta, horizontal_speed > 0.1, _is_sprinting)
	_update_camera_height(delta)


func _update_sprint_state(delta: float, input_vector: Vector2) -> void:
	var has_movement_input := input_vector.length_squared() > 0.0
	var sprint_pressed := Input.is_physical_key_pressed(KEY_SHIFT) and has_movement_input
	if sprint_pressed and not crouch_slide.is_crouching():
		_sprint_grace_time_left = sprint_release_grace_time
	else:
		_sprint_grace_time_left = maxf(_sprint_grace_time_left - delta, 0.0)

	_is_sprinting = has_movement_input and not crouch_slide.is_crouching() and (
		sprint_pressed or _sprint_grace_time_left > 0.0
	)


func _update_horizontal_movement(delta: float, move_direction: Vector3, was_on_floor: bool) -> void:
	if crouch_slide.apply_slide_motion(delta, move_direction):
		return
	if wall_movement.controls_locked():
		return

	# crouch speed only matters on the ground, airborne crouching keeps momentum
	# so the slam actually carries into the landing
	var target_speed := crouch_slide.movement_speed if (crouch_slide.is_crouching() and was_on_floor) else walk_speed
	if _is_sprinting:
		target_speed = sprint_speed

	var horizontal_velocity := Vector3(character_body.velocity.x, 0.0, character_body.velocity.z)
	var current_speed := horizontal_velocity.length()
	if current_speed > sprint_speed + 0.001:
		_apply_preserved_speed(horizontal_velocity, move_direction, sprint_speed, overspeed_deceleration, delta)
		return

	# Sprint speed eases back to the active movement speed after the grace window.
	if not move_direction.is_zero_approx() and current_speed > target_speed + 0.001:
		_apply_preserved_speed(horizontal_velocity, move_direction, target_speed, sprint_deceleration, delta)
		return

	var target_velocity := move_direction * target_speed
	var acceleration := ground_acceleration if was_on_floor else air_acceleration
	if move_direction.is_zero_approx():
		acceleration = ground_deceleration if was_on_floor else air_acceleration

	character_body.velocity.x = move_toward(character_body.velocity.x, target_velocity.x, acceleration * delta)
	character_body.velocity.z = move_toward(character_body.velocity.z, target_velocity.z, acceleration * delta)


func _apply_preserved_speed(
	current_velocity: Vector3,
	move_direction: Vector3,
	target_speed: float,
	deceleration: float,
	delta: float
) -> void:
	var preserved_direction := current_velocity.normalized()
	if not move_direction.is_zero_approx() and momentum_steering > 0.0:
		var steer_amount := clampf(momentum_steering * delta, 0.0, 1.0)
		preserved_direction = preserved_direction.lerp(move_direction, steer_amount).normalized()

	var preserved_speed := move_toward(current_velocity.length(), target_speed, deceleration * delta)
	character_body.velocity.x = preserved_direction.x * preserved_speed
	character_body.velocity.z = preserved_direction.z * preserved_speed

func _update_jump_and_gravity(delta: float, was_on_floor: bool) -> bool:
	var jump_pressed := Input.is_action_just_pressed(&"ui_accept")
	if jump_pressed and was_on_floor:
		# hopping out of a slide keeps the speed and stacks a little extra on top
		if crouch_slide.is_sliding():
			crouch_slide.apply_slide_jump_boost()
		crouch_slide.stop_slide()
		character_body.velocity.y = jump_velocity
		return true

	if wall_movement.try_wall_jump(jump_pressed):
		crouch_slide.stop_slide()
		var wallkicknoise = preload("res://Resources/SFX/Footsteps/wallkick.wav")
		footstep_audio.stream = wallkicknoise
		footstep_audio.play()
		return true

	if was_on_floor:
		return false

	var active_gravity := wall_movement.get_gravity_multiplier(gravity_multiplier)
	character_body.velocity.y -= _gravity * active_gravity * delta
	# the wall slide fall cap would eat the slam, so the slam wins while its active
	if not crouch_slide.is_slamming():
		wall_movement.clamp_fall_speed()
	return false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"time_stop"):
		# Time can always stop if free_time_control is on, and we can stop the countdown too
		#if time_manipulation._free_time_control: # !! Doesn't work, seems to immediately unpause
			#Global.force_time_stop()
		# resuming is always fine, stopping needs a charge left in the tank
		if Global.is_time_stopped() or time_manipulation.can_pause():
			Global.toggle_time_stop()
		return
	if event.is_action_pressed(&"ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		character_body.rotate_y(-event.relative.x * mouse_sensitivity)
		player_camera.rotation.x = clampf(
			player_camera.rotation.x - event.relative.y * mouse_sensitivity,
			deg_to_rad(minimum_look_angle),
			deg_to_rad(maximum_look_angle)
		)
		return
	if event is InputEventMouseButton and event.pressed and click_to_capture_mouse:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func get_floor_material() -> Util.FLOOR_MATERIAL:
	return footsteps.get_floor_material()


func _update_camera_height(delta: float) -> void:
	_camera_step_offset = move_toward(_camera_step_offset, 0.0, step_camera_smoothing * delta)
	var target_height := crouch_camera_height if crouch_slide.is_crouching() else _camera_base_height
	_camera_current_height = move_toward(_camera_current_height, target_height, crouch_camera_speed * delta)
	var camera_position := player_camera.position
	camera_position.y = _camera_current_height + _camera_step_offset
	player_camera.position = camera_position


func _on_game_speed_state_changed(new_state) -> void:
	if _overlay_tween:
		_overlay_tween.kill()
	if _flash_tween:
		_flash_tween.kill()

	if new_state == Global.TimeState.STOPPED:
		_overlay_tween = create_tween().set_parallel()
		_overlay_tween.tween_property(_overlay_material, "shader_parameter/tint", frozen_tint, 0.15)
		_overlay_tween.tween_property(_overlay_material, "shader_parameter/pixel_size", 2, 0.15)
	else:
		# ease the pixelization back out while a quick green flash fades to normal
		_overlay_tween = create_tween()
		_overlay_tween.tween_property(_overlay_material, "shader_parameter/pixel_size", normal_pixel_size, 0.4)

		_flash_tween = create_tween()
		_flash_tween.tween_property(_overlay_material, "shader_parameter/tint", resume_flash_tint, 0.08)
		_flash_tween.tween_property(_overlay_material, "shader_parameter/tint", Color(1, 1, 1, 0), 0.35)
		_flash_tween.tween_callback(func() -> void:
			overlay_mesh.visible = _overlay_was_visible
		)


func _on_time_stop_winding_up(_stopping: bool) -> void:
	# arms swing during the last two beeps so the push lands right as the state flips,
	# the shader tweens run on their own now so nothing waits on this animation
	if Global.is_time_stopped() == false:
		arms_rig.visible = true
		arms_animation_player.play("push_R")
		await arms_animation_player.animation_finished
		arms_rig.visible = false
		return
	if Global.is_time_stopped() == true:
		# a queued ability with its own animation will override the time push/wave thing
		var anim := "push_L"
		if abilities.get_queued_animation() != "":
			anim = abilities.get_queued_animation()
		arms_rig.visible = true
		# DO NOT CHANGE THIS, WE PLAY THE ANIMATION OF ABILITIES IN TIME STOP BASED OFF OF THE RESOURCE!
		arms_animation_player.play(anim)
		await arms_animation_player.animation_finished
		arms_rig.visible = false
		return
