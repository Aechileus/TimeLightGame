extends Node3D

@onready var clickybutton = $Clickybutton

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_interaction_area_interacted():
	if clickybutton.playing == true:
		return
	clickybutton.play()
	
