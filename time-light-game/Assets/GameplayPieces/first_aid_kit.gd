extends Node3D

# how far up and down it bobs from where it was placed
@export var bob_height: float = 0.5
# how quick the bob cycle is
@export var bob_speed: float = 2.0
# how fast it spins around its y
@export var spin_speed: float = 1.5

@onready var _pickup: Area3D = $Pickup

var _base_y: float = 0.0
var _time: float = 0.0


func _ready() -> void:
	_base_y = position.y
	_pickup.body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	# bob around the placed height, spin keeps ticking on top of it
	position.y = _base_y + sin(_time * bob_speed) * bob_height
	rotate_y(spin_speed * delta)


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	var node := body as Node
	while node:
		if node.has_method("heal_to_full"):
			node.heal_to_full()
			queue_free()
			return
		node = node.get_parent()
