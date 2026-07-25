extends Area3D

@export_range(0.0, 50.0, 1.0) var damage: float = 1.0
@export var affected_groups: Array[String] = ["player", "enemy"]

func _enter_tree() -> void:
	body_entered.connect(_on_body_entered)

## We need to check that its a player entering otherwise we just reload constantly if its 
## anything else entering including its own taurus ring
func _on_body_entered(body: Node3D) -> void:
	var groups: Array[StringName] = []
	var current_node = body
	# Search up the tree for the first parent node with a group
	# I implemented this to try and fix the enemies not dying but it didn't help
	# Leaving this here because it might still be needed?
	while groups.is_empty():
		var current_groups = current_node.get_groups()
		if !current_groups.is_empty():
			groups = current_groups
		else:
			print(current_node.name)
			current_node = current_node.get_parent()
			if !current_node: 
				push_error("Hurtbox intersected with a body that had no parent in any group!")
				return
	
	
	if !body.get_groups().any(func (x: StringName): return (x as String) in affected_groups):
		print("Body enetered with groups ", body.get_groups())
		return
	var node := body as Node
	while node:
		if node.has_method("take_damage"):
			node.take_damage(damage)
			return
		node = node.get_parent()
