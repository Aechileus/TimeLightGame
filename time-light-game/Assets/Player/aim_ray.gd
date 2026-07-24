extends RayCast3D

@export var player_controller: CollisionObject3D

func _ready() -> void:
	if player_controller:
		add_exception(player_controller)
