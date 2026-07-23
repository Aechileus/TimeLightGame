extends Area3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

# We need to check that its a player entering otherwise we just reload constantly if its 
# anything else entering including its own taurus ring
func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		get_tree().reload_current_scene()
