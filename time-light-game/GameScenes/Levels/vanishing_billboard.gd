extends Node

@onready var board = $BillboardSign

func _ready() -> void:
	SignalBus.game_speed_state_changed.connect(do)
	
func do(_x):
	board.hide()
	queue_free()
