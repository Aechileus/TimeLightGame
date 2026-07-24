extends Node

# The actual dash effect. The abilities component handles aiming, queueing, cost, sfx and animation
#  then hands the landing spot to us. All we do is the shove.
# We could put this in ability component if we really want, but I figured this will help keep everything cleaner if
# we want to specialize a ability

@onready var _body: CharacterBody3D = $"../../../PlayerCharacterBody3D"
@onready var _hitbox: Area3D = $"../../../PlayerCharacterBody3D/DashHitbox"
@onready var _controller: Node = $"../../.."


func cast(ability: Ability, point: Vector3, strength: float) -> void:
	# shove scales with distance so short dashes dont overshoot, the 4 just
	# means the trip takes about a quarter second, capped by ability speed
	# ^ this no longer applies since you changed it to not push
	var to_point := point - _body.global_position
	_body.velocity = to_point.normalized() * minf(ability.speed, to_point.length() * 4.0)

	# turn on the pass through damage for the length of the dash
	_hitbox.activate(ability.damage)
	# make the player untouchable for that same window
	if _controller.has_method("start_dash_immunity"):
		_controller.start_dash_immunity(_hitbox.active_time)
