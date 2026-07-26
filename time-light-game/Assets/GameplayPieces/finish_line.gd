extends Area3D

## the level complete screen that pops up when the player crosses
@export var level_complete_scene: PackedScene
## the level to load from the next level button, leave empty if this is the last one
@export var next_level: PackedScene
@export var level_timer: CanvasLayer

var _used: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


## We need to check that its a player entering otherwise we just reload constantly if its 
## anything else entering including its own taurus ring
func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	if _used:
		return
	_used = true
	_show_level_complete.call_deferred()


func _show_level_complete() -> void:
	if level_complete_scene == null:
		push_warning("finish line has no level complete scene assigned")
		return

	var layer := CanvasLayer.new()
	layer.layer = 100
	# always so the buttons still work once the world is paused
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	# parent it to the scene root so it sticks around while we get paused
	get_tree().current_scene.add_child(layer)

	var screen := level_complete_scene.instantiate()
	screen.next_level = next_level
	# only hand over a time if a timer was actually wired up
	if level_timer != null:
		screen.time_left = level_timer.time_left
	layer.add_child(screen)

	# freeze the world, and disable the player root since it runs at process always
	get_tree().paused = true
	for node in get_tree().get_nodes_in_group("player"):
		if not node is CharacterBody3D:
			node.process_mode = Node.PROCESS_MODE_DISABLED
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
