## A small script to move the billboard to always be underneath the player

extends Node

@onready var board: Sprite3D = $BillboardSign3
@onready var timestop: Area3D = $"../Trigger Areas/TimeStopZone2"

func _ready() -> void:
	timestop.body_entered.connect(move)

func move(body: Node3D):
	if body.is_in_group("player"):
		board.global_position.x = body.global_position.x
		board.global_position.z = body.global_position.z
