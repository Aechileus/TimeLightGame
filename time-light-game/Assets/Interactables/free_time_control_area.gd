extends Area3D

## what to force free time control to when the player enters
@export var free_time_control: bool = true
## only fire the first time
@export var one_shot: bool = true

var _used: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	if one_shot and _used:
		return
	# climb up to the controller that actually owns free_time_control
	var node: Node = body
	while node:
		if "free_time_control" in node:
			node.free_time_control = free_time_control
			if "time_manipulation" in node and node.time_manipulation != null:
				node.time_manipulation._free_time_control = free_time_control
			_used = true
			return
		node = node.get_parent()
