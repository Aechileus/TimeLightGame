extends Node3D

@export var particles: GPUParticles3D
@export var body: Node
@export var health: int = 1

func _ready() -> void:
	pass

func take_damage(damage: int):
	print("Crate was hit!")
	health -= damage
	if health <= 0:
		destroy()

func destroy():
	body.queue_free()
	particles.emitting = true
	particles.finished.connect(remove_particles)
	
func remove_particles():
	queue_free()
