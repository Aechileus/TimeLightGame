extends Node3D

# drops monsters into the level. idle mode scatters them around itself in a
# radius so they just stand there until you get close, attack mode spawns them
# already aggroed so they come running the second they exist.

enum Mode { IDLE, ATTACK_RUN }

@export var monster_scene: PackedScene
@export var count: int = 3
@export var radius: float = 8.0
@export var mode: Mode = Mode.IDLE

@export var spawn_on_ready: bool = false
# spawn the batch as soon as the level loads ^

func _ready() -> void:
	if spawn_on_ready:
		spawn_all()


func spawn_all() -> void:
	for i in count:
		spawn_one()


func spawn_one() -> void:
	if monster_scene == null:
		return
	var monster := monster_scene.instantiate()

	if mode == Mode.ATTACK_RUN:
		monster.start_aggroed = true

	var angle := randf() * TAU
	var dist := sqrt(randf()) * radius
	var offset := Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)

	var target_pos := global_position + offset
	monster.position = target_pos 

	# 3. Defer the addition to avoid scene locks
	### SNAKE DO NOT TOUCH THIS, IT IS SO STUPIDLY FRAGILE, I HAD TO DO SO MUCH GOOGLE FU
	# ...noted XD
	get_tree().current_scene.add_child.call_deferred(monster)
