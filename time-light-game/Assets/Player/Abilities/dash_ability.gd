extends Node

# The actual dash effect. The abilities component handles aiming, queueing, cost, sfx and animation
#  then hands the landing spot to us. All we do is the shove.
# We could put this in ability component if we really want, but I figured this will help keep everything cleaner if
# we want to specialize a ability

@onready var _body: CharacterBody3D = $"../../../PlayerCharacterBody3D"


func cast(ability: Ability, point: Vector3) -> void:
	# shove scales with distance so short dashes dont overshoot, the 4 just
	# means the trip takes about a quarter second, capped by ability speed
	var to_point := point - _body.global_position
	_body.velocity = to_point.normalized() * minf(ability.speed, to_point.length() * 4.0)
