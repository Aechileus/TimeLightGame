extends Area3D

@export_range(0.0, 50.0, 1.0) var damage: float = 1.0
@export var affected_groups: Array[String] = ["player", "enemy"]

func _enter_tree() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	# ignore anything thats not in an affected group, specifically CSGs were a issue
	if not _in_affected_group(body):
		return
	var node := body as Node
	while node:
		if node.has_method("take_damage"):
			node.take_damage(damage)
			return
		node = node.get_parent()


func _in_affected_group(body: Node) -> bool:
	var node := body
	while node:
		for g in affected_groups:
			if node.is_in_group(g):
				return true
		node = node.get_parent()
	return false
