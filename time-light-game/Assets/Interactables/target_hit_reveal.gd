extends Node


## the shootable target that fires the hit signal
@export var target: Node
## the node whose visibility gets toggled and whose child collision gets enabled
@export var toggled_node: Node3D


func _ready() -> void:
	if target != null and target.has_signal("hit"):
		target.hit.connect(_on_target_hit)


func _on_target_hit() -> void:
	if target is Node3D:
		target.visible = false
	if toggled_node == null:
		return
	toggled_node.visible = not toggled_node.visible
	_enable_collision(toggled_node)


func _enable_collision(node: Node) -> void:
	for child in node.get_children():
		if child is CollisionShape3D or child is CollisionPolygon3D:
			# deferred since this can fire mid physics from the shot landing
			child.set_deferred("disabled", false)
		_enable_collision(child)
