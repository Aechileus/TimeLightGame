extends Area3D

func _physics_process(delta: float) -> void:
	if self.has_overlapping_bodies():
		get_tree().reload_current_scene()
	


