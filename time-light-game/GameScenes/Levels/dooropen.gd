extends MeshInstance3D

@onready var press_sfx = $"../../../ButtonLevel1/PressSFX"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_button_pressed():
	var tween = create_tween()
	var target_rotation_y = deg_to_rad(88.9) 
	tween.tween_property(self, "rotation:y", target_rotation_y, 1.0)


func _on_press_sfx_finished():
	var tween = create_tween()
	var target_rotation_y = deg_to_rad(88.9) 
	tween.tween_property(self, "rotation:y", target_rotation_y, 1.0)
	
