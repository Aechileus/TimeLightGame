extends Node3D

enum Axis { X, Y, Z }

## how many units it moves each second
@export var speed: float = 1.0
@export var axis: Axis = Axis.X
@onready var roar = $Fleshwall/roar


func _ready() -> void:
	pass


func _on_button_level_1_pressed():
	if speed <= 0.0:
		return
	var distance := 100000.0
	var prop := "position:x"
	var start := position.x
	match axis:
		Axis.Y:
			prop = "position:y"
			start = position.y
		Axis.Z:
			prop = "position:z"
			start = position.z
	var tween := create_tween()
	tween.tween_property(self, prop, start + distance, distance / speed)
	tween.set_trans(Tween.TRANS_LINEAR)


func _on_press_sfx_finished():
	roar.play()
	speed += 1.0


func _on_button_2_pressed():
	speed += 2.0


func _on_button_6_pressed():
	speed += 2.0


func _on_target_hit():
	if speed <= 0.0:
		return
	var distance := 100000.0
	var prop := "position:x"
	var start := position.x
	match axis:
		Axis.Y:
			prop = "position:y"
			start = position.y
		Axis.Z:
			prop = "position:z"
			start = position.z
	var tween := create_tween()
	tween.tween_property(self, prop, start + distance, distance / speed)
	tween.set_trans(Tween.TRANS_LINEAR)
