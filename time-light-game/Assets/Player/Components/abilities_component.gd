extends Node
class_name PlayerAbilitiesComponent

# Keys 1 to 4 pick an ability. Hold right click and the circle pushes out from
# the player along the camera, slow while time is frozen and fast while its
# running. The circle freezes in place when it touches something or when the
# button is let go. Release while frozen queues the cast for the unpause,
# release while time is running fires it right away. Left click scraps a
# queued cast.

@export var slot_1: Ability
@export var slot_2: Ability
@export var slot_3: Ability
@export var slot_4: Ability

@export_group("Aiming")
# how fast the circle crawls out while time is stopped
@export var frozen_push_speed: float = 3.0
# and how fast it flies out while time is running
@export var flowing_push_speed: float = 10.0

@export_group("Marker Colors")
@export var aiming_color: Color = Color(0.26, 0.585, 0.65, 1.0)
@export var aiming_miss_color: Color = Color(0.26, 0.585, 0.65, 0.502)
@export var queued_color: Color = Color(0.4, 1.0, 0.55)

@onready var _body: CharacterBody3D = $"../../PlayerCharacterBody3D"
@onready var _camera: Camera3D = $"../../PlayerCharacterBody3D/PlayerCamera"
@onready var _aim_ray: RayCast3D = $"../../PlayerCharacterBody3D/PlayerCamera/AimRay"
@onready var _marker: MeshInstance3D = $"../../BlinkMarker"
@onready var _marker_material: StandardMaterial3D = _marker.material_override
@onready var _cast_audio: AudioStreamPlayer3D = $"../../PlayerCharacterBody3D/CastSFX"
@onready var _arms: Node3D = $"../../PlayerCharacterBody3D/PlayerCamera/arms_rig"
@onready var _arms_anim: AnimationPlayer = $"../../PlayerCharacterBody3D/PlayerCamera/arms_rig/AnimationPlayer"
@onready var _slot_boxes: Array[HBoxContainer] = [
	$AbilitiesUI/SlotList/Slot1,
	$AbilitiesUI/SlotList/Slot2,
	$AbilitiesUI/SlotList/Slot3,
	$AbilitiesUI/SlotList/Slot4,
]

var _abilities: Array[Ability] = []
var _selected: int = 0
var _aiming: bool = false
var _stuck: bool = false
var _aim_distance: float = 0.0
var _queued: bool = false
var _queued_point: Vector3 = Vector3.ZERO
var _queued_ability: Ability

# the player controller holds the economy toggle and size, we just spend from it here
@onready var _controller = $"../.."
@onready var _ap_label: Label = $AbilitiesUI/ActionPointsLabel
var _economy_left: int = 0


func _ready() -> void:
	_abilities = [slot_1, slot_2, slot_3, slot_4]
	_economy_left = _controller.economy_amount
	_update_ui()
	SignalBus.game_speed_state_changed.connect(_on_game_speed_state_changed)


func _physics_process(delta: float) -> void:
	if _aiming:
		_push_marker_out(delta)
		if _aim_ray.is_colliding(): 
			_marker_material.albedo_color = aiming_color 
		else: 
			_marker_material.albedo_color = aiming_miss_color
		_marker.visible = true
	elif _queued and _queued_ability.needs_target:
		# untargeted queued casts dont get a circle, the slot going green
		# in the ui covers those
		_marker_material.albedo_color = queued_color
		_marker.visible = true
	else:
		_marker.visible = false


# The circle crawls out along wherever the camera points and stops on the
# first thing it touches.
### TODO might want to consider a refactor here so it just casts it faster but invisibly at the same time repeatedly and
### if it escapes and gets through on the invisible recast it moves the circle through and to the new location.
func _push_marker_out(delta: float) -> void:
	var x = aim_or_max_distance(_abilities[_selected].cast_range)
	print(x)
	_marker.global_position = x

func aim_or_max_distance(max_distance: float) -> Vector3:
	var position = _aim_ray.global_position
	var target = _aim_ray.get_collision_point()
	var distance = position.distance_to(target)
	
	if !_aim_ray.is_colliding():
		var basis = -_aim_ray.global_transform.basis.z # This is the basis vector for the -z direction (forwards) wrt translation
		return position + basis.normalized() * max_distance
	elif distance > max_distance:
		return position + (target - position).normalized() * max_distance
	else:
		return target
	
	
	#if _stuck:
		#return
#
	#var speed := frozen_push_speed if Global.is_time_stopped() else flowing_push_speed
	#_aim_distance = minf(_aim_distance + speed * delta, _abilities[_selected].cast_range)
#
	#var from := _camera.global_position
	#var direction := -_camera.global_transform.basis.z
	#var query := PhysicsRayQueryParameters3D.create(from, from + direction * _aim_distance)
	#query.exclude = [_body.get_rid()]
	#var hit := _body.get_world_3d().direct_space_state.intersect_ray(query)
	#if hit:
		#_stuck = true
		#_marker.global_position = hit.position - direction * 0.1
	#else:
		#_marker.global_position = from + direction * _aim_distance


func _unhandled_input(event: InputEvent) -> void:
	# no swapping slots mid aim, finish or cancel the cast first
	if not _aiming:
		for i in _abilities.size():
			if event.is_action_pressed("ability_" + str(i + 1)):
				_selected = i
				_update_ui()
				return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				_start_aiming()
			else:
				_release_cast()
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed and _queued:
			# changed their mind, scrap the queued cast, this now also refunds the ap points here
			if _controller.economy_enabled and _queued_ability != null:
				_economy_left = mini(_economy_left + _queued_ability.economy_cost, _controller.economy_amount)
			_queued = false
			_update_ui()


func _start_aiming() -> void:
	var ability := _abilities[_selected]
	if ability == null:
		return
	# with the economy on, abilities are pause only and cost action points
	if not _can_use(ability):
		return
	if not ability.needs_target:
		# no circle for this one, it just casts on the spot
		_cast_at(ability, _body.global_position)
		return
	_aiming = true
	_stuck = false
	_aim_distance = 0.0
	_queued = false


# Whether the selected ability can be started right now. cast as much as timer allows when the
# economy is off, otherwise it has to be paused with available AP (ACTION POINTS)
func _can_use(ability: Ability) -> bool:
	if not _controller.economy_enabled:
		return true
	if not Global.is_time_stopped():
		return false
	return _economy_left >= ability.economy_cost


func _release_cast() -> void:
	if not _aiming:
		return
	_aiming = false
	_cast_at(_abilities[_selected], _marker.global_position)


func _cast_at(ability: Ability, point: Vector3) -> void:
	# spend the action points at the commit, if not enough, just return
	if _controller.economy_enabled:
		if _economy_left < ability.economy_cost:
			return
		_economy_left -= ability.economy_cost

	if Global.is_time_stopped() and not ability.cast_while_frozen:
		# frozen, the cast waits until time comes back
		_queued = true
		_queued_point = point
		_queued_ability = ability
	else:
		# fires now, even mid freeze for stuff that handles the freeze itself
		_fire(ability, point)
	_update_ui()


func _on_game_speed_state_changed(new_state) -> void:
	if new_state == Global.TimeState.STOPPED:
		# fresh pause hands out a new batch of action points
		_economy_left = _controller.economy_amount
		_update_ui()
	if new_state == Global.TimeState.FLOWING and _queued:
		_queued = false
		_update_ui()
		_fire(_queued_ability, _queued_point)


# Lets the controller swap the resume push for the queued abilitys animation.
func get_queued_animation() -> String:
	if _queued and _queued_ability != null:
		return _queued_ability.cast_animation
	return ""


func _fire(ability: Ability, point: Vector3) -> void:
	# time is taken away every cast pulls its cost off the level clock
	SignalBus.ability_time_spent.emit(ability.time_cost)

	# the actual effect lives on a child node named in the tres, this component
	# only deals with aiming and queueing
	var effect := get_node_or_null(ability.effect_node)
	if effect != null:
		effect.cast(ability, point)
	else:
		print("no effect node called '", ability.effect_node, "' under Abilities")

	# sfx and animation both come straight from the tres
	if ability.cast_sfx != null:
		_cast_audio.stream = ability.cast_sfx
		_cast_audio.play()
	# the resume wind up may already be playing this one, dont restart it
	if ability.cast_animation != "" and _arms_anim.current_animation != ability.cast_animation:
		_arms.visible = true
		_arms_anim.play(ability.cast_animation)
		await _arms_anim.animation_finished
		_arms.visible = false


func _update_ui() -> void:
	# only show the action points readout while the economy is actually on
	_ap_label.visible = _controller.economy_enabled
	_ap_label.text = "AP: %d" % _economy_left

	for i in _slot_boxes.size():
		var box := _slot_boxes[i]
		var ability := _abilities[i]
		var icon: TextureRect = box.get_node("Icon")
		var slot_name: Label = box.get_node("SlotName")
		icon.texture = ability.icon if ability else null
		# show the action point cost right after the name, like "1  Dash (2)"
		var cost_text := " (%d AP)" % ability.economy_cost if ability else ""
		slot_name.text = str(i + 1) + "  " + (ability.display_name if ability else "----") + cost_text
		# selected slot pops, everything else sits dim, queued goes green
		var tint := Color.WHITE if i == _selected and ability != null else Color(1.0, 1.0, 1.0, 0.35)
		if _queued and ability == _queued_ability:
			tint = queued_color
		# if you cant afford it this pause, grey out the ability
		if ability != null and _controller.economy_enabled and _economy_left < ability.economy_cost:
			tint = Color(1.0, 1.0, 1.0, 0.15)
		box.modulate = tint
