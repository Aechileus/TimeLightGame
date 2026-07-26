extends Node3D

## how many units it moves along x each second
@export var speed: float = 1.0
@onready var roar = $Fleshwall/roar


func _ready() -> void:
	pass


func _on_button_level_1_pressed():
	if speed <= 0.0:
		return
	var distance := 100000.0
	var tween := create_tween()
	tween.tween_property(self, "position:x", position.x + distance, distance / speed)
	tween.set_trans(Tween.TRANS_LINEAR)


func _on_press_sfx_finished():
	roar.play()
	speed += 1.0


func _on_button_2_pressed():
	speed += 2.0


func _on_button_6_pressed():
	speed += 2.0
