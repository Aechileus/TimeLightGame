extends Area3D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	var node: Node = body
	while node:
		if node.has_method("die"):
			node.die()
			return
		node = node.get_parent()
