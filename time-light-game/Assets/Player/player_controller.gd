extends Node3D

@export var _gravity: float = 9.8

@export_group("UI")
@export var _hide_reticle: bool = false
@onready var _reticle: CanvasLayer = $Reticle
@export var _hide_level_timer: bool = false
@onready var _level_timer: CanvasLayer = $"../LevelTimer"
@export var _hide_health: bool = false
@onready var _health_label: Label = $PlayerHealthUI/HealthLabel
@export var _hide_abilities: bool = false
@onready var _abilities_ui: CanvasLayer = $Components/Abilities/AbilitiesUI
@export var _hide_time_manipulation: bool = false
@onready var _time_manipulation_ui: CanvasLayer = $Components/TimeManipulation/TimeUI

signal update_show_hide_ui


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
## how much of your up the ramp speed gets turned into launch when you jump off it
@export_range(0.0, 3.0, 0.05) var ramp_launch_boost: float = 1.0

@export_group("Sprint Momentum")
## No idea
@export_range(0.0, 1.0, 0.01) var sprint_release_grace_time: float = 0.2
## How fast the player decelerates to walking speed after stopping sprinting
@export_range(0.1, 50.0, 0.1) var sprint_deceleration: float = 8.0
## Starting coast deceleration while overspeed with no movement key held. Stays
## gentle at first then ramps up exponentially the longer you hold nothing
@export_range(0.1, 50.0, 0.1) var overspeed_deceleration: float = 8.0
## How fast the coast deceleration ramps up per second of holding no input
@export_range(0.0, 6.0, 0.1) var overspeed_decel_growth: float = 2.5
## How fast walking bleeds off extra momentum toward walk speed
@export_range(0.0, 50.0, 0.5) var walk_momentum_bleed: float = 50.0
## How fast sprinting bleeds off extra momentum toward sprint speed. Keep it
## lower than the walk bleed so sprinting holds momentum longer
@export_range(0.0, 50.0, 0.5) var sprint_momentum_bleed: float = 50.0
## Degrees per second you can freely curve your momentum. Turn within this and
## you keep all your speed, whip the camera faster than this and youre fighting
## the "inertia" so it bleeds the speedW
@export_range(30.0, 720.0, 5.0) var momentum_turn_rate: float = 135
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
## Fall speed you have to hit the ground at before the camera bobs on landing
@export_range(0.0, 30.0, 0.5) var land_bob_min_speed: float = 6.0
## How much the camera dips per unit of fall speed past the minimum
@export_range(0.0, 0.1, 0.001) var land_bob_scale: float = 0.02
## Cap on the landing dip so a big fall stays a small bob
@export_range(0.0, 1.0, 0.01) var land_bob_max: float = 0.2
## How fast the camera settles back up after a landing bob
@export_range(1.0, 30.0, 0.5) var land_bob_recovery: float = 9.0
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
## Arms drop back to this animation after sitting idle for a bit
@export var arms_idle_animation: String = "relax"
## Seconds without a new arm animation before returning to idle
@export_range(0.0, 5.0, 0.1) var arms_idle_delay: float = 1.5
var _arms_idle_timer: float = 0.0
## Drawn up when the player crouches, slides or crouch slams, then held on guard_idle
@export var guard_draw_animation: String = "guard_draw"
## Held pose after the guard draw finishes
@export var guard_idle_animation: String = "guard_idle"
# true while a crouch, slide or slam has the guard up
var _guarding: bool = false
## how far the arms bob up and down while running on the idle pose
@export_range(0.0, 0.2, 0.001) var arms_bob_amount: float = 0.03
## how fast that running bob cycles
@export_range(0.1, 30.0, 0.1) var arms_bob_speed: float = 11.0
var _arms_bob_phase: float = 0.0
var _arms_rig_base_y: float = 0.0
# the vhs post effect handles the screen tint and flashes now
@onready var _vhs_material: ShaderMaterial = $PlayerCharacterBody3D/PlayerCamera/CanvasLayer/ColorRect.material
@onready var _hurt_audio: AudioStreamPlayer3D = $PlayerCharacterBody3D/HurtSFX

var _health: int = 0
var _hit_flash_tween: Tween
# counts down while a dash is making the player untouchable
var _invuln_time: float = 0.0
## How far the aim ray reaches to interact with things youre looking at
@export var interact_range: float = 1.5
@onready var _aim_ray: RayCast3D = $PlayerCharacterBody3D/PlayerCamera/AimRay

# the pause menu, spawned on escape while in a level. its own layer so it sits
# on top of everything and keeps working while the tree is paused
const PAUSE_MENU := preload("res://GameScenes/UI/pause_menu.tscn")
const DEATH_SCREEN := preload("res://GameScenes/UI/death_screen.tscn")
var _pause_layer: CanvasLayer = null
var _dead: bool = false

var _is_sprinting: bool = false
var _sprint_grace_time_left: float = 0.0
# how long youve been coasting overspeed with no input, drives the exponential decel
var _overspeed_coast_time: float = 0.0
var _base_floor_snap: float = 0.1
var _camera_base_height: float = 0.0
var _camera_current_height: float = 0.0
var _camera_step_offset: float = 0.0
# downward camera dip from a hard landing, eases back to 0
var _camera_land_offset: float = 0.0
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
	SignalBus.out_of_time.connect(die)

	wall_movement.setup(character_body)
	footsteps.setup(character_body, footstep_checker, footstep_audio)

	_health = max_health
	_update_health_label()
	
	time_manipulation._free_time_control = free_time_control
	
	# Listen for UI changes and update them when needed
	update_show_hide_ui.connect(show_hide_ui)
	show_hide_ui()

	# once the guard draw lands, settle onto the held guard idle pose
	arms_animation_player.animation_finished.connect(_on_arms_animation_finished)
	# remember where the arms sit so the running bob can offset from it
	_arms_rig_base_y = arms_rig.position.y

	# progression unlocks. a level thats also tagged tutorial starts everything
	# locked, if the level isnt tagged tutorial you can use anything
	SignalBus.unlocks_changed.connect(_on_unlocks_changed)
	var scene_root := get_tree().current_scene
	if scene_root != null and scene_root.is_in_group("level") and scene_root.is_in_group("tutorial"):
		Global.lock_all_unlocks()
	else:
		Global.unlock_all()

	if capture_mouse_on_start:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# deferred so every node is settled before the freeze signal goes out
	if start_time_stopped:
		Global.force_time_stop.call_deferred()
	elif Global.is_time_stopped():
		# stale stop hanging around from a previous scene, clear it
		Global.force_time_flow.call_deferred()


func _process(delta: float) -> void:
	if _dead or _pause_layer != null:
		return
	# no relaxing to idle mid freeze
	if Global.is_time_stopped():
		return
	if not arms_rig.visible:
		return

	_update_guard_animation()
	_update_arm_bob(delta)
	# while the guard is up the crouch anims own the arms
	if _guarding:
		return

	var current := arms_animation_player.current_animation
	# a non idle animation is actively playing, wait
	if arms_animation_player.is_playing() and current != arms_idle_animation:
		_arms_idle_timer = 0.0
		return
	# already idle, nothing to do
	if current == arms_idle_animation:
		return

	_arms_idle_timer += delta
	if _arms_idle_timer >= arms_idle_delay:
		_arms_idle_timer = 0.0
		arms_animation_player.play(arms_idle_animation)


# Little vertical bob on the arms while running with the plain idle pose out, so
# they dont just sit dead still. eases back to rest when youre not running.
func _update_arm_bob(delta: float) -> void:
	var horizontal_speed := Vector2(character_body.velocity.x, character_body.velocity.z).length()
	var bobbing := character_body.is_on_floor() and horizontal_speed > 5.1 \
		and arms_animation_player.current_animation == arms_idle_animation
	if bobbing:
		_arms_bob_phase += delta * arms_bob_speed
		arms_rig.position.y = _arms_rig_base_y + sin(_arms_bob_phase) * arms_bob_amount
	else:
		arms_rig.position.y = move_toward(arms_rig.position.y, _arms_rig_base_y, arms_bob_amount * 8.0 * delta)


# Crouch, slide and slam all raise the guard, dropping slide or crouch reverses the raise
func _update_guard_animation() -> void:
	var guard_now := crouch_slide.is_crouching or crouch_slide.is_sliding or crouch_slide.is_slamming

	if guard_now and not _guarding:
		_guarding = true
		if arms_animation_player.has_animation(guard_draw_animation):
			arms_animation_player.play(guard_draw_animation)
		return

	if not guard_now and _guarding:
		_guarding = false
		# reverse the draw
		if arms_animation_player.has_animation(guard_draw_animation):
			arms_animation_player.play_backwards(guard_draw_animation)
		return


# The guard draw finishing forward means we settle onto the held pose. The reverse
# sheath also fires this time * bob_speed) * bob_height
	#rotate_y(spin_speed * delta)but guarding is already off by then so it gets ignored.
func _on_arms_animation_finished(anim_name: StringName) -> void:
	if anim_name == guard_draw_animation and _guarding:
		if arms_animation_player.has_animation(guard_idle_animation):
			arms_animation_player.play(guard_idle_animation)


func _physics_process(delta: float) -> void:

	# Pause player physics if the pause menu is up, time is stopped, or they're dead
	if _pause_layer != null or _dead or Global.is_time_stopped():
		return
	
	var input_vector := Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")
	
	# Sets sprint state and updates sprint grace
	_update_sprint_state(delta, input_vector)

	# Get a vector representing the direction the player's currently moving in
	# TODO: this could be cached?
	var current_move_direction := character_body.global_transform.basis * Vector3(input_vector.x, 0.0, input_vector.y)
	current_move_direction = current_move_direction.normalized()
	
	var is_on_floor := character_body.is_on_floor()
	
	crouch_slide.update_input(delta, is_on_floor, current_move_direction, _is_sprinting)

	# ---------------------------------------------------------------------- #
	
	# Decrement i-time
	_invuln_time = maxf(_invuln_time - delta, 0.0)

	wall_movement.begin_frame(delta)
	
	# ---------------------------------------------------------------------- #
	
	_update_horizontal_movement(delta, current_move_direction, is_on_floor)
	_clamp_horizontal_speed()

	var jumped := _update_jump_and_gravity(delta, is_on_floor)
	var horizontal_motion := Vector3(character_body.velocity.x, 0.0, character_body.velocity.z) * delta
	var step_height := 0.0
	if is_on_floor and not jumped:
		step_height = stair_step.try_step_up(horizontal_motion)

	# a longer snap while sliding keeps you glued to ramps at high speed instead
	# of skipping off the lip, normal movement uses the base snap
	character_body.floor_snap_length = slide_floor_snap_length if crouch_slide.is_sliding else _base_floor_snap

	var saved_floor_snap := character_body.floor_snap_length
	if step_height > 0.0:
		_camera_step_offset -= step_height
		character_body.floor_snap_length = 0.0

	# how fast we were dropping right before the move, used to sense hard landings
	var impact_speed := maxf(-character_body.velocity.y, 0.0)
	character_body.move_and_slide()
	character_body.floor_snap_length = saved_floor_snap

	# landing mpact camera bob, dip the camera a bit if it was a
	# real drop. scaled by how hard we hit and capped so it stays subtle
	if not is_on_floor and character_body.is_on_floor() and impact_speed > land_bob_min_speed: # <- this is never true 
		var dip := minf((impact_speed - land_bob_min_speed) * land_bob_scale, land_bob_max)
		_camera_land_offset = -dip

	var horizontal_speed := Vector2(character_body.velocity.x, character_body.velocity.z).length()
	footsteps.post_move_update(delta, horizontal_speed > 0.1, _is_sprinting)
	_update_camera_height(delta)


## Increments/resets sprint grace, and sets whether or not the player is sprinting
## REFERENCES CROUCH_SLIDE
func _update_sprint_state(delta: float, input_vector: Vector2) -> void:
	var has_movement_input := input_vector.length_squared() > 0.0
	var sprint_pressed := Input.is_physical_key_pressed(KEY_SHIFT) and has_movement_input
	
	# Handle sprint grace
	if sprint_pressed and not crouch_slide.is_crouching:
		_sprint_grace_time_left = sprint_release_grace_time
	else:
		_sprint_grace_time_left = maxf(_sprint_grace_time_left - delta, 0.0)

	_is_sprinting = (Input.is_physical_key_pressed(KEY_SHIFT) or _sprint_grace_time_left > 0.0) and !crouch_slide.is_crouching



func _clamp_horizontal_speed() -> void:
	var flat := Vector2(character_body.velocity.x, character_body.velocity.z)
	if flat.length() > max_horizontal_speed:
		flat = flat.normalized() * max_horizontal_speed
		character_body.velocity.x = flat.x
		character_body.velocity.z = flat.y


func _update_horizontal_movement(delta: float, current_move_direction: Vector3, was_on_floor: bool) -> void:
	
	# ---------------------------------------------------------------------- #
	
	if crouch_slide.is_sliding:
		crouch_slide.apply_slide_motion(delta, current_move_direction)
		return
	if wall_movement.controls_locked():
		return

	# crouch speed only matters on the ground, airborne crouching keeps momentum
	# so the slam actually carries into the landing
	var target_speed := crouch_slide.movement_speed if (crouch_slide.is_crouching and was_on_floor) else walk_speed
	if _is_sprinting:
		target_speed = sprint_speed

	var horizontal_velocity := Vector3(character_body.velocity.x, 0.0, character_body.velocity.z)
	var current_speed := horizontal_velocity.length()
	if current_speed > sprint_speed + 0.001:
		# momentum bleed for sprint and walk
		var bleed := 0.0
		if was_on_floor:
			bleed = sprint_momentum_bleed if _is_sprinting else walk_momentum_bleed
		_apply_preserved_speed(horizontal_velocity, current_move_direction, target_speed, bleed, was_on_floor, delta)
		return

	# Sprint speed eases back to the active movement speed after the grace window,
	# again only on the ground so air momentum sticks
	if not current_move_direction.is_zero_approx() and current_speed > target_speed + 0.001:
		var ease_bleed := sprint_deceleration if was_on_floor else 0.0
		_apply_preserved_speed(horizontal_velocity, current_move_direction, target_speed, ease_bleed, was_on_floor, delta)
		return

	_overspeed_coast_time = 0.0

	var target_velocity := current_move_direction * target_speed
	var acceleration := ground_acceleration if was_on_floor else air_acceleration
	if current_move_direction.is_zero_approx():
		# no input in the air keeps your momentum, on the ground it decelerates
		acceleration = ground_deceleration if was_on_floor else 0.0

	character_body.velocity.x = move_toward(character_body.velocity.x, target_velocity.x, acceleration * delta)
	character_body.velocity.z = move_toward(character_body.velocity.z, target_velocity.z, acceleration * delta)


func _apply_preserved_speed(
	current_velocity: Vector3,
	move_direction: Vector3,
	target_speed: float,
	bleed: float,
	grounded: bool,
	delta: float
) -> void:
	var speed := current_velocity.length()
	var vel_dir := current_velocity.normalized()
	var preserved_direction := vel_dir

	if move_direction.is_zero_approx():
		if grounded:
			# no input on the ground, so the momentum coasts. deceleration starts
			# gentle and ramps up exponentially the longer you hold nothing
			_overspeed_coast_time += delta
			var decel := overspeed_deceleration * exp(overspeed_decel_growth * _overspeed_coast_time)
			speed = move_toward(speed, target_speed, decel * delta)
		else:
			# airborne with no input keeps flying, no drag in the air
			_overspeed_coast_time = 0.0
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

		# gentle bleed toward your movement target while holding input. zero while
		# sprinting so momentum is kept, positive while walking so it winds down
		speed = move_toward(speed, target_speed, bleed * delta)

	character_body.velocity.x = preserved_direction.x * speed
	character_body.velocity.z = preserved_direction.z * speed

func _update_jump_and_gravity(delta: float, was_on_floor: bool) -> bool:
	var jump_pressed := Input.is_action_just_pressed(&"ui_accept")
	if jump_pressed and was_on_floor:
		# hopping out of a slide keeps the speed and stacks a little extra on top
		if crouch_slide.is_sliding:
			crouch_slide.apply_slide_jump_boost()
		crouch_slide.stop_slide()
		character_body.velocity.y = jump_velocity
		_apply_ramp_launch()
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
	if not crouch_slide.is_slamming:
		wall_movement.clamp_fall_speed()
	return false


func _apply_ramp_launch() -> void:
	if not character_body.is_on_floor():
		return
	var normal := character_body.get_floor_normal()
	if normal.y >= 0.999 or normal.y <= 0.01:
		return
	var uphill := Vector3(-normal.x, 0.0, -normal.z)
	if uphill.length() < 0.001:
		return
	uphill = uphill.normalized()
	var horizontal_vel := Vector3(character_body.velocity.x, 0.0, character_body.velocity.z)
	var up_slope_speed := horizontal_vel.dot(uphill)
	if up_slope_speed <= 0.0:
		return
	var slope_tan := sqrt(1.0 - normal.y * normal.y) / normal.y
	character_body.velocity.y += up_slope_speed * slope_tan * ramp_launch_boost


func _unhandled_input(event: InputEvent) -> void:
	# no input while playing out the death sequence
	if _dead:
		return
	if event.is_action_pressed(&"interact"):
		_try_interact()
		return
	if event.is_action_pressed(&"time_stop"):
		# Time can always stop if free_time_control is on, and we can stop the countdown too
		#if time_manipulation._free_time_control: # !! Doesn't work, seems to immediately unpause
			#Global.force_time_stop()
		# resuming needs the resume unlock, stopping needs the stop unlock plus a charge
		if Global.is_time_stopped():
			if Global.can_resume_time:
				Global.toggle_time_stop()
		elif Global.can_stop_time and time_manipulation.can_pause():
			Global.toggle_time_stop()
		return
	if event.is_action_pressed(&"ui_cancel"):
		if _pause_layer != null:
			_close_pause_menu()
		elif _level_is_pausable():
			_open_pause_menu()
		else:
			# not in a level, just free the mouse like before
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	# swallow everything else while the pause menu is up
	if _pause_layer != null:
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


# The pause menu only works inside an actual level, gated by the scene root being
# in the "level" group.
func _level_is_pausable() -> bool:
	var scene := get_tree().current_scene
	return scene != null and scene.is_in_group("level")


func _open_pause_menu() -> void:
	_pause_layer = CanvasLayer.new()
	_pause_layer.layer = 100
	# always so its buttons work while the tree is paused
	_pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_pause_layer)

	var menu := PAUSE_MENU.instantiate()
	menu.resume_pressed.connect(_close_pause_menu)
	menu.restart_pressed.connect(_restart_level)
	_pause_layer.add_child(menu)

	# freeze the whole world, and disable the player itself since it runs at
	# process always
	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_DISABLED
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _close_pause_menu() -> void:
	if _pause_layer != null:
		_pause_layer.queue_free()
		_pause_layer = null
	# back to running always so time stop camera works again
	process_mode = Node.PROCESS_MODE_ALWAYS
	# hand pause back to whatever time stop wants, so unpausing here doesnt undo
	# a frozen world
	get_tree().paused = Global.is_time_stopped()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _restart_level() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene.call_deferred()


func get_floor_material() -> Util.FLOOR_MATERIAL:
	return footsteps.get_floor_material()


# Monsters call this when a swing connects. Flashes the screen red so you can
# actually feel the hit, and reloads the level when you run out.
# Dashing sets an immunity window, so blasting through a monster shrugs off hits.
func start_dash_immunity(duration: float) -> void:
	_invuln_time = maxf(_invuln_time, duration)


# Casts the aim ray out to interact_range and interacts with the first thing that
# has an interact method. Walls block it since bodies count too.
func _try_interact() -> void:
	var from := _aim_ray.global_position
	var to := from - _aim_ray.global_transform.basis.z * interact_range
	var query := PhysicsRayQueryParameters3D.create(from, to)
	# see interaction areas as well as solid geometry that would block the look
	query.collide_with_areas = true
	query.exclude = [character_body.get_rid()]
	var hit := character_body.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return

	# walk up from what we hit in case its a child collider of the interactable
	var node := hit.collider as Node
	while node:
		if node.has_method("interact"):
			node.interact()
			return
		node = node.get_parent()


const HEAL_SFX := preload("res://Resources/SFX/PlaceholderSFX/heal.wav")

# Pickups like the first aid kit call this to top the player back up.
func heal_to_full() -> void:
	_health = max_health
	_update_health_label()
	_flash_heal()
	_hurt_audio.stream = HEAL_SFX
	_hurt_audio.pitch_scale = 1.0
	_hurt_audio.play()


# Quick green pulse through the vhs effect on a heal.
func _flash_heal() -> void:
	if _hit_flash_tween:
		_hit_flash_tween.kill()
	_vhs_material.set_shader_parameter("flash", Color(0.2, 1.0, 0.3, 0.45))
	_hit_flash_tween = create_tween()
	_hit_flash_tween.tween_property(_vhs_material, "shader_parameter/flash", Color(0.2, 1.0, 0.3, 0.0), 0.35)


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
		die()


func _play_hurt_sfx() -> void:
	if hurt_sfx == null:
		return
	_hurt_audio.stream = hurt_sfx
	_hurt_audio.pitch_scale = randf_range(hurt_pitch_min, hurt_pitch_max)
	_hurt_audio.play()


func die() -> void:
	if _dead:
		return
	_dead = true
	Global.force_time_flow()

	if _hit_flash_tween:
		_hit_flash_tween.kill()
	if _flash_tween:
		_flash_tween.kill()
	if _overlay_tween:
		_overlay_tween.kill()

	# collapse into a crouch, camera drops to crouch height. if already crouched
	# the tween just holds there
	var collapse := create_tween()
	collapse.tween_property(player_camera, "position:y", crouch_camera_height, 0.15)

	# blood filter
	_vhs_material.set_shader_parameter("tint", Color(1, 1, 1, 0))
	_vhs_material.set_shader_parameter("flash", Color(0.75, 0.0, 0.0, 0.6))

	# tiny timeout so players have feedback for their mistake
	await get_tree().create_timer(0.6).timeout
	if is_instance_valid(self):
		_show_death_screen()


func _show_death_screen() -> void:
	# reuse the pause layer slot, same always process trick so it works while the
	# tree is paused and the player is disabled
	if _pause_layer != null:
		return
	# clear the screen effects now, otherwise their tweens freeze when the player
	# gets disabled below and the red hit flash stays stuck over the death screen
	if _hit_flash_tween:
		_hit_flash_tween.kill()
	if _flash_tween:
		_flash_tween.kill()
	if _overlay_tween:
		_overlay_tween.kill()
	_vhs_material.set_shader_parameter("flash", Color(1, 1, 1, 0))
	_vhs_material.set_shader_parameter("tint", Color(1, 1, 1, 0))

	_pause_layer = CanvasLayer.new()
	_pause_layer.layer = 100
	_pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_pause_layer)
	_pause_layer.add_child(DEATH_SCREEN.instantiate())

	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_DISABLED
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


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
	# impact bob for landing
	_camera_land_offset = lerp(_camera_land_offset, 0.0, clampf(land_bob_recovery * delta, 0.0, 1.0))
	var target_height := crouch_camera_height if crouch_slide.is_crouching else _camera_base_height
	_camera_current_height = move_toward(_camera_current_height, target_height, crouch_camera_speed * delta)
	var camera_position := player_camera.position
	camera_position.y = _camera_current_height + _camera_step_offset + _camera_land_offset
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
		# arms stay up now, the idle timeout eases them back to idle after
		return
	if Global.is_time_stopped() == true:
		# a queued ability with its own animation will override the time push/wave thing
		var anim := "push_L"
		if abilities.get_queued_animation() != "":
			anim = abilities.get_queued_animation()
		arms_rig.visible = true
		# DO NOT CHANGE THIS, WE PLAY THE ANIMATION OF ABILITIES IN TIME STOP BASED OFF OF THE RESOURCE!
		arms_animation_player.play(anim)
		return
		
# What pieces of UI are unlocked are decided here
func _on_unlocks_changed() -> void:
	_hide_abilities = not Global.ui_abilities
	_hide_time_manipulation = not Global.ui_time
	_hide_level_timer = not Global.ui_level_timer
	show_hide_ui()


func show_hide_ui():
	if !_reticle:
		print("Couldn't find reticle ui")
		pass
	elif _hide_reticle and _reticle.visible:
		_reticle.hide()
	elif !_hide_reticle and !_reticle.visible:
		_reticle.show()
		
	if !_level_timer:
		print("Couldn't find level timer ui")
		pass
	elif _hide_level_timer and _level_timer.visible:
		_level_timer.hide()
	elif !_hide_level_timer and !_level_timer.visible:
		_level_timer.show()
	
	if !_health_label:
		print("Couldn't find health ui")
		pass
	elif _hide_health and _health_label.visible:
		_health_label.hide()
	elif !_hide_health and !_health_label.visible:
		_health_label.show()
		
	if !_time_manipulation_ui:
		print("Couldn't find time manipulation ui")
		pass
	elif _hide_time_manipulation and _time_manipulation_ui.visible:
		_time_manipulation_ui.hide()
	elif !_hide_time_manipulation and !_time_manipulation_ui.visible:
		_time_manipulation_ui.show()
	
	if 	!_abilities_ui:
		print("Couldn't find abilities ui")
		pass
	elif _hide_abilities and _abilities_ui.visible:
		_abilities_ui.hide()
	elif !_hide_abilities and !_abilities_ui.visible:
		_abilities_ui.show()
