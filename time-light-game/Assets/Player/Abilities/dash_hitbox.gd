extends Area3D

@export var active_time: float = 0.3

var _damage: float = 0.0
var _hit: Array = []


func _ready() -> void:
	# off until a dash turns it on
	monitoring = false
	area_entered.connect(_on_touch)
	body_entered.connect(_on_touch)


# Called by the dash effect right as the shove goes off.
func activate(damage: float) -> void:
	_damage = damage
	_hit.clear()
	monitoring = true
	# let the physics settle a frame then grab anyone were already inside of
	# if we dont do this it would miss the whole enemy, dont ask, idk why it fixes
	# this either
	await get_tree().physics_frame
	for a in get_overlapping_areas():
		_on_touch(a)
	for b in get_overlapping_bodies():
		_on_touch(b)
	await get_tree().create_timer(active_time).timeout
	monitoring = false


func _on_touch(other: Node) -> void:
	var node := other as Node
	while node:
		if node.is_in_group("enemy") and node.has_method("take_damage") and not _hit.has(node):
			_hit.append(node)
			node.take_damage(_damage)
			return
		node = node.get_parent()
