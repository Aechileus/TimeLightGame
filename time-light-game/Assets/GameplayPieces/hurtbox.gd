extends Area3D

@export_range(0.0, 50.0, 1.0) var damage: float = 1.0

signal hurt_player

func _enter_tree() -> void:
	body_entered.connect(_on_body_entered)

## We need to check that its a player entering otherwise we just reload constantly if its 
## anything else entering including its own taurus ring
func _on_body_entered(body: Node3D) -> void:
			if not body.is_in_group("player"):
				return
			var node := body as Node
			while node:
				if node.has_method("take_damage"):
					node.take_damage(damage)
					hurt_player.emit()
					return
				node = node.get_parent()
