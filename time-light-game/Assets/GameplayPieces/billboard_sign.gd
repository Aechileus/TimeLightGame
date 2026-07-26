extends Sprite3D

func _ready() -> void:
	var viewport: Viewport = get_child(0) as Viewport
	self.texture = viewport.get_texture()
	# show from both sides so it doesnt vanish when youre looking at the back
	double_sided = true
