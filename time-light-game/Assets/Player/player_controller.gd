extends Node3D

@export var _gravity: float = 9.8
@export_group("Movement")
## Hard ceiling on horizontal speed no matter how much momentum you build
@export_range(1.0, 200.0, 1.0) var max_horizontal_speed: float = 50.0
## How far the body snaps down to the floor while sliding. Bigger keeps you stuck
## to ramps at high speed so you dont skip
## fixes that dumbass bug we had earlier with ramps
@export_range(0.1, 4.0, 0.1) var slide_floor_snap_length: float = 1.5
## The maximum speed that the player reaches while walking
@export_range(0.1, 30.0, 0.1) var walk_speed: float = 5.0
## The maximum speed that the player reaches while sprinting
@export_range(0.1, 40.0, 0.1) var sprint_speed: float = 8.0
## How fast the player accelerates to their max speed while grounded
@export_range(0.1, 100.0, 0.1) var ground_acceleration: float = 28.0
## How fast the player decelerates while grounded
@export_range(0.1, 100.0, 0.1) var ground_deceleration: float = 34.0
## How fast the player accelerates to their max speed while airbourne
@export_range(0.1, 50.0, 0.1) var air_acceleration: float = 8.0
## A simple multiplier for the gravity
@export_range(0.0, 5.0, 0.05) var gravity_multiplier: float = 1.0
## How much upward velocity is instantly applied when jumping
@export_range(0.1, 20.0, 0.1) var jump_velocity: float = 5.5

@export_group("Sprint Momentum")
## No idea
@export_range(0.0, 1.0, 0.01) var sprint_release_grace_time: float = 0.2
## How fast the player decelerates to walking speed after stopping sprinting
@export_range(0.1, 50.0, 0.1) var sprint_deceleration: float = 8.0
## Starting coast deceleration while overspeed with no movement key held. Stays
## gentle at first then ramps up exponentially the longer you hold nothing
@export_range(0.1, 50.0, 0.1) var overspeed_deceleration: float = 3.0
## How fast the coast deceleration ramps up per second of holding no input
@export_range(0.0, 6.0, 0.1) var overspeed_decel_growth: float = 2.5
## Degrees per second you can freely curve your momentum. Turn within this and
## you keep all your speed, whip the camera faster than this and youre fighting
## the "inertia" so it bleeds the speed
@export_range(30.0, 720.0, 5.0) var momentum_turn_rate: float = 200.0
## Speed lost per radian you over force the turn past the free rate. Higher means
## hard whip turns kill your speed faster
@export_range(0.0, 40.0, 0.5) var turn_scrub: float = 8.0

@export_group("Camera")
## How high the camera should be while crouching
@export_range(0.2, 1.5, 0.05) var crouch_camera_height: float = 0.6
## No idea
@export_range(0.1, 20.0, 0.1) var crouch_camera_speed: float = 5.0
## No idea
@export_range(0.1, 20.0, 0.1) var step_camera_smoothing: float = 8.0
## It's the mouse sensitivity. What did you think it was gonna be?
@export_range(0.0001, 0.02, 0.0001) var mouse_sensitivity: float = 0.0025
## The minimum you're able to look..?
@export_range(-89.0, 0.0, 1.0) var minimum_look_angle: float = -85.0
## The maximum you're able to look..?
@export_range(0.0, 89.0, 1.0) var maximum_look_angle: float = 85.0
var capture_mouse_on_start: bool = true
var click_to_capture_mouse: bool = true

@export_group("Health")
# changed this to 5 because 3 felt bad
@export var max_health: int = 5
# invulnerable window after a hit
@export_range(0.0, 3.0, 0.05) var hit_invuln_time: float = 0.6

@export_group("Hurt SFX")
# played when the player takes a hit
@export var hurt_sfx: AudioStream
@export_range(0.5, 1.5, 0.01) var hurt_pitch_min: float = 0.95
@export_range(0.5, 1.5, 0.01) var hurt_pitch_max: float = 1.05

@export_group("Action Economy")
# when on, abilities can only be used while time is paused, and each pause hands
# out this many action points that abilities spend by their economy_cost
@export var economy_enabled: bool = false
@export_range(1, 50, 1) var economy_amount: int = 3

@export_group("Time Stop")
# per scene choice for whether the player wakes up frozen
@export var start_time_stopped: bool = true
# what pixel_size settles back to after a resume, 3 or 4 both look decent
@export_range(1.0, 8.0, 0.5) var normal_pixel_size: float = 3.0
@export var frozen_tint: Color = Color(1.0, 0.302, 0.302, 0.38)
@export var resume_flash_tint: Color = Color(0.349, 1.0, 0.4, 0.318)
@export var free_time_control: bool = false

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
@onready var _health_label: Label = $PlayerHealthUI/HealthLabel
# the vhs post effect handles the screen tint and flashes now
@onready var _vhs_material: ShaderMaterial = $PlayerCharacterBody3D/PlayerCamera/CanvasLayer/ColorRect.material
@onready var _hurt_audio: AudioStreamPlayer3D = $PlayerCharacterBody3D/HurtSFX

var _health: int = 0
var _hit_flash_tween: Tween
# counts down while a dash is making the player untouchable
var _invuln_time: float = 0.0

var _is_sprinting: bool = false
var _sprint_grace_time_left: float = 0.0
# how long youve been coasting overspeed with no input, drives the exponential decel
var _overspeed_coast_time: float = 0.0
var _base_floor_snap: float = 0.1
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

	#_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	_base_floor_snap = character_body.floor_snap_length
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

	_health = max_health
	_update_health_label()
	
	time_manipulation._free_time_control = free_time_control

	if capture_mouse_on_start:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# deferred so every node is settled before the freeze signal goes out
	if start_time_stopped:
		Global.force_time_stop.call_deferred()
	elif Global.is_time_stopped():
		# stale stop hanging around from a previous scene, clear it
		Global.force_time_flow.call_deferred()


func _physics_process(delta: float) -> void:
	# tick the dash immunity down here so it always drains
	# !! See below

	# frozen in time, no moving around. queueing ended up living in the
	# abilities component instead so this just gates movement now. Oh well, composition wins.
	if Global.is_time_stopped():
		return
	
	# I don't think it makes sense for the dash invuln to be canceled by time stop?
	_invuln_time = maxf(_invuln_time - delta, 0.0)

	wall_movement.begin_frame(delta)

	var input_vector := Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")
	var move_direction := character_body.global_transform.basis * Vector3(input_vector.x, 0.0, input_vector.y)
	move_direction.y = 0.0
	move_direction = move_direction.normalized()

	var was_on_floor := character_body.is_on_floor() # <- so is it or was it, huh?
	_update_sprint_state(delta, input_vector)
	crouch_slide.update_input(delta, was_on_floor, move_direction, _is_sprinting)
	_update_horizontal_movement(delta, move_direction, was_on_floor)
	_clamp_horizontal_speed()

	var jumped := _update_jump_and_gravity(delta, was_on_floor)
	var horizontal_motion := Vector3(character_body.velocity.x, 0.0, character_body.velocity.z) * delta
	var step_height := 0.0
	if was_on_floor and not jumped:
		step_height = stair_step.try_step_up(horizontal_motion)

	# a longer snap while sliding keeps you glued to ramps at high speed instead
	# of skipping off the lip, normal movement uses the base snap
	character_body.floor_snap_length = slide_floor_snap_length if crouch_slide.is_sliding() else _base_floor_snap

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


func _clamp_horizontal_speed() -> void:
	var flat := Vector2(character_body.velocity.x, character_body.velocity.z)
	if flat.length() > max_horizontal_speed:
		flat = flat.normalized() * max_horizontal_speed
		character_body.velocity.x = flat.x
		character_body.velocity.z = flat.y


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
		_apply_preserved_speed(horizontal_velocity, move_direction, sprint_speed, delta)
		return

	# Sprint speed eases back to the active movement speed after the grace window.
	if not move_direction.is_zero_approx() and current_speed > target_speed + 0.001:
		_apply_preserved_speed(horizontal_velocity, move_direction, target_speed, delta)
		return

	_overspeed_coast_time = 0.0

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
	delta: float
) -> void:
	var speed := current_velocity.length()
	var vel_dir := current_velocity.normalized()
	var preserved_direction := vel_dir

	if move_direction.is_zero_approx():
		# no input, so the momentum coasts. deceleration starts gentle and ramps
		# up exponentially the longer you hold nothing, so a light tap of speed
		# lingers but a long coast winds down hard
		_overspeed_coast_time += delta
		var decel := overspeed_deceleration * exp(overspeed_decel_growth * _overspeed_coast_time)
		speed = move_toward(speed, target_speed, decel * delta)
	else:
		# if you are moving this will just reset preventing intertia loss
		_overspeed_coast_time = 0.0
		# how far you want to swing your momentum this frame vs how far you can
		# swing it for free. curving within the free rate keeps all your speed,
		# whipping the camera harder than that means youre fighting the inertia
		var turn := vel_dir.signed_angle_to(move_direction, Vector3.UP)
		var wanted := absf(turn)
		var free_turn := deg_to_rad(momentum_turn_rate) * delta
		# rotate the velocity toward your input, but only as fast as the free rate,
		# so heavy momentum actually resists a hard snap instead of following instantly
		preserved_direction = vel_dir.rotated(Vector3.UP, signf(turn) * minf(wanted, free_turn))
		# every radian you tried to force past the free rate scrubs speed
		var excess := wanted - free_turn
		if excess > 0.0:
			speed = maxf(speed - turn_scrub * excess, target_speed)

	character_body.velocity.x = preserved_direction.x * speed
	character_body.velocity.z = preserved_direction.z * speed

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


# Monsters call this when a swing connects. Flashes the screen red so you can
# actually feel the hit, and reloads the level when you run out.
# Dashing sets an immunity window, so blasting through a monster shrugs off hits.
func start_dash_immunity(duration: float) -> void:
	_invuln_time = maxf(_invuln_time, duration)


func take_damage(amount) -> void:
	# untouchable mid dash or mid i frames, or already down
	if _invuln_time > 0.0 or _health <= 0:
		return
	_health = maxi(_health - int(amount), 0)
	# i frames so a swarm cant chain hits in one instant
	_invuln_time = maxf(_invuln_time, hit_invuln_time)
	_update_health_label()
	_flash_hit()
	_play_hurt_sfx()
	if _health <= 0:
		_die()


func _play_hurt_sfx() -> void:
	if hurt_sfx == null:
		return
	_hurt_audio.stream = hurt_sfx
	_hurt_audio.pitch_scale = randf_range(hurt_pitch_min, hurt_pitch_max)
	_hurt_audio.play()


func _die() -> void:
	# make sure time isnt frozen on the reload, then run the level back. deferred
	# since a hit can land during a physics callback and you cant free bodies then
	Global.force_time_flow()
	get_tree().reload_current_scene.call_deferred()


# Punch a quick red flash through the vhs effect so a hit reads.
func _flash_hit() -> void:
	if _hit_flash_tween:
		_hit_flash_tween.kill()
	_vhs_material.set_shader_parameter("flash", Color(0.8, 0.0, 0.0, 0.45))
	_hit_flash_tween = create_tween()
	_hit_flash_tween.tween_property(_vhs_material, "shader_parameter/flash", Color(0.8, 0.0, 0.0, 0.0), 0.35)


func _update_health_label() -> void:
	if _health_label != null:
		_health_label.text = "HP: %d" % _health


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
		# pixelization stays on the overlay quad, the red tint rides the vhs now
		_overlay_tween = create_tween().set_parallel()
		_overlay_tween.tween_property(_overlay_material, "shader_parameter/pixel_size", 2, 0.15)
		_overlay_tween.tween_property(_vhs_material, "shader_parameter/tint", frozen_tint, 0.15)
	else:
		# ease the pixelization back out while the vhs clears its tint and pops a
		# quick green flash on resume
		_overlay_tween = create_tween().set_parallel()
		_overlay_tween.tween_property(_overlay_material, "shader_parameter/pixel_size", normal_pixel_size, 0.4)
		_overlay_tween.tween_property(_vhs_material, "shader_parameter/tint", Color(1, 1, 1, 0), 0.3)

		var flash_clear := Color(resume_flash_tint.r, resume_flash_tint.g, resume_flash_tint.b, 0.0)
		_flash_tween = create_tween()
		_flash_tween.tween_property(_vhs_material, "shader_parameter/flash", resume_flash_tint, 0.08)
		_flash_tween.tween_property(_vhs_material, "shader_parameter/flash", flash_clear, 0.35)


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
