extends RayCast3D

@onready var player_controller = $"../../.."

func _ready() -> void:
	self.add_exception(player_controller)


	
	
