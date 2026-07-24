extends CharacterBody3D

@export var health: float = 100.0
@export var move_speed: float = 13.0       # very fast on purpose, dont go too much slower than this
@export var chase_range: float = 1000.0    # aggro distance
@export var attack_range: float = 2.0      # how close before it starts a swing
# it keeps walking into you until this close, so the hand hitboxes actually reach
@export var melee_stop_distance: float = 0.8
@export var attack_cooldown: float = 0.35
@export var attack_anim_speed: float = 2.0 # plays the swing faster so it snaps
@export var turn_speed: float = 16.0
@export var attack_damage: float = 1.0
# spawners flip this on, though with the huge chase range it charges either way
@export var start_aggroed: bool = false
# how long the dissolve takes when it dies
@export var death_dissolve_time: float = 1.2

const ANIM_IDLE := "mutant breathing idle/mixamo_com"
const ANIM_RUN := "Fast Run/mixamo_com"
const ANIM_SWIPE := "mutant swiping/mixamo_com"
const ANIM_JUMP := "mutant jumping/mixamo_com"
const ANIM_DIE := "mutant dying/mixamo_com"

enum State { IDLE, AGGRO, DEAD }

@onready var _anim: AnimationPlayer = $AnimationPlayer
@onready var _mesh: MeshInstance3D = $Skeleton3D/Character_Monster
@onready var _footsteps: MonsterFootstepComponent = $Footsteps
# every hitbox riding the hands, grabbed by name so it works no matter which
# bone attachment they hang off of. a swing only lands if one overlaps you
# ready sets this
var _damage_areas: Array = []

# how far into a swing the hit lands
const _HIT_AT := 0.15

var _state: int = State.IDLE
var _player: Node3D
var _attack_cd: float = 0.0        # gap timer before it can swing again
var _swinging: bool = false        # mid swing right now
var _swing_time_left: float = 0.0  # time left in the current swing anim
var _attack_elapsed: float = 0.0
var _hit_landed: bool = false
var _dissolve_mat: ShaderMaterial
var _hit_tween: Tween
var _gravity: float = 9.8


func _ready() -> void:
	add_to_group("enemy")
	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	floor_snap_length = 0.6
	_player = _find_player_body()
	_damage_areas = find_children("DamagingArea", "Area3D", true, false)

	# own copy of the dissolve material so dying doesnt melt every other monster
	var mat := _mesh.get_surface_override_material(0)
	if mat != null:
		_dissolve_mat = mat.duplicate()
		_dissolve_mat.set_shader_parameter("t", 0.0)
		_mesh.set_surface_override_material(0, _dissolve_mat)

	if start_aggroed:
		_state = State.AGGRO
		_play(ANIM_RUN)
	else:
		_play(ANIM_IDLE)


func _physics_process(delta: float) -> void:
	# is_instance_valid covers the player getting freed on a level reload
	if _state == State.DEAD or not is_instance_valid(_player):
		return

	_attack_cd = maxf(_attack_cd - delta, 0.0)

	# recomputed every frame so it always retargets wherever you moved
	var to_player := _player.global_position - global_position
	to_player.y = 0.0
	var distance := to_player.length()

	# This will cause them to chase and never stop unless you somehow break the range.
	#consider changing this, maybe its fun, idk
	if _state == State.IDLE:
		if distance <= chase_range:
			_state = State.AGGRO
		else:
			return

	# always face you and keep closing the gap, even mid swing, so it stays
	# glued and the hand hitboxes can reach
	_face(to_player, delta)
	var horizontal := to_player.normalized() * move_speed
	if distance <= melee_stop_distance:
		# right on top of you, hold position so it doesnt jitter into you
		horizontal = Vector3.ZERO
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0.0
	move_and_slide()

	var moving := Vector2(velocity.x, velocity.z).length() > 0.5
	_footsteps.update(delta, is_on_floor(), moving)

	# swing handling runs alongside the movement instead of freezing it. the
	# swing owns its full anim length so the clip actually plays out, then the
	# cooldown gap starts once its done
	if _swinging:
		_attack_elapsed += delta
		_swing_time_left -= delta
		if not _hit_landed and _attack_elapsed >= _HIT_AT and _try_hit_player():
			_hit_landed = true
		if _swing_time_left <= 0.0:
			_swinging = false
			_attack_cd = attack_cooldown
	elif distance <= attack_range and _attack_cd <= 0.0:
		_start_swing()

	_update_anim(distance)


func _start_swing() -> void:
	_swinging = true
	_attack_elapsed = 0.0
	_hit_landed = false
	var anim := ANIM_JUMP if randf() < 0.3 else ANIM_SWIPE
	var speed := maxf(attack_anim_speed, 0.1)
	if _anim.has_animation(anim):
		_anim.play(anim, -1.0, speed)
	# swing lasts the sped up clip length so it plays out without restarting
	_swing_time_left = _anim_length(anim) / speed


func _anim_length(anim: String) -> float:
	if _anim.has_animation(anim):
		return _anim.get_animation(anim).length
	return 0.5


func _update_anim(_distance: float) -> void:
	if _swinging:
		return
	if _anim.current_animation != ANIM_RUN:
		_play(ANIM_RUN)


# True only if one of the hand hitboxes is overlapping the player right now.
# Walks up from the body since take_damage lives on the player root.
func _try_hit_player() -> bool:
	for area in _damage_areas:
		for body in area.get_overlapping_bodies():
			if not body.is_in_group("player"):
				continue
			var node := body as Node
			while node:
				if node.has_method("take_damage"):
					node.take_damage(attack_damage)
					return true
				node = node.get_parent()
	return false


# Called by the players shoot and dash.
func take_damage(amount: float) -> void:
	if _state == State.DEAD:
		return
	health -= amount
	if health <= 0.0:
		_die()
	else:
		_flash_dissolve()


# Quick pop of the dissolve on a hit, kick t up to 0.5 then straight back down.
func _flash_dissolve() -> void:
	if _dissolve_mat == null:
		return
	if _hit_tween:
		_hit_tween.kill()
	_dissolve_mat.set_shader_parameter("enabled", true)
	_hit_tween = create_tween()
	_hit_tween.tween_property(_dissolve_mat, "shader_parameter/t", 0.5, 0.05)
	_hit_tween.tween_property(_dissolve_mat, "shader_parameter/t", 0.0, 0.12)
	_hit_tween.tween_callback(func() -> void:
		_dissolve_mat.set_shader_parameter("enabled", false)
	)


func _die() -> void:
	_state = State.DEAD
	_play(ANIM_DIE)
	# flip the dissolve on now
	if _dissolve_mat != null:
		_dissolve_mat.set_shader_parameter("enabled", true)
		var tween := create_tween()
		tween.tween_property(_dissolve_mat, "shader_parameter/t", 1.0, death_dissolve_time)
		await tween.finished
	else:
		await get_tree().create_timer(death_dissolve_time).timeout
	queue_free()


func _face(to_player: Vector3, delta: float) -> void:
	if to_player.length() < 0.01:
		return
	var target_yaw := atan2(to_player.x, to_player.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, clampf(turn_speed * delta, 0.0, 1.0))


func _find_player_body() -> Node3D:
	for node in get_tree().get_nodes_in_group("player"):
		if node is CharacterBody3D:
			return node
	# fallback, better than nothing if the setup ever changes
	return get_tree().get_first_node_in_group("player")


func _play(anim: String) -> void:
	if _anim.has_animation(anim):
		_anim.play(anim)
	else:
		push_warning("monster missing anim " + anim)
