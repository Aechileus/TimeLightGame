extends Area3D

@export var use_beeps: bool = false
@export var one_shot: bool = false

var _used: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player") or Global.is_time_stopped():
		return
	if one_shot and _used:
		return
	_used = true

	if use_beeps:
		Global.toggle_time_stop()
	else:
		Global.force_time_stop()
