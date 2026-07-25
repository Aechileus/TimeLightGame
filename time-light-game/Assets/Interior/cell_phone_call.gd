extends Node3D

@onready var johntimeintro = $Johntimeintro

@onready var omni_light_3d = $OmniLight3D

@export_range(0.1, 10.0, 0.1) var fade_time: float = 3.0


func _ready():
	johntimeintro.play()


func _process(delta):
	pass


func _on_johntimeintro_finished():
	var layer := CanvasLayer.new()
	layer.layer = 128
	add_child(layer)

	var black := ColorRect.new()
	black.color = Color(0.0, 0.0, 0.0, 0.0)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(black)

	var tween := create_tween()
	tween.tween_property(black, "color:a", 1.0, fade_time)
	tween.finished.connect(func():
		SceneChanger.change_to(Util.GAME_SCENES.TUTORIALONE)
	)
