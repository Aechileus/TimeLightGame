extends Area3D

@export var speed: float = 40.0
@export var damage: float = 25.0
@export var lifetime: float = 4.0

var _life: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	body_entered.connect(_on_hit)
	area_entered.connect(_on_hit)


func _physics_process(delta: float) -> void:
	if Global.is_time_stopped():
		return

	global_position += -global_transform.basis.z * speed * delta
	_life += delta
	if _life >= lifetime:
		queue_free()


func _on_hit(other: Node) -> void:
	# walk up in case we hit a hurtbox child instead of the thing holding the hp.
	# only enemies take the hit so a frozen bolt cant tag the player on resume
	var node := other as Node
	while node:
		if node.is_in_group("enemy") and node.has_method("take_damage"):
			node.take_damage(damage)
			queue_free()
			return
		node = node.get_parent()

	if other is StaticBody3D:
		queue_free()
