extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_button_pressed():
	var distance = 20
	var tween = create_tween()
	# Calculate the new absolute target position
	var target_position_y = position.y - distance
	
	# Smoothly animate down
	tween.tween_property(self, "position:y", target_position_y, 1.5)
