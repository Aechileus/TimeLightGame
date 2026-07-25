extends Node3D

# drops monsters into the level. idle mode scatters them around itself in a
# radius so they just stand there until you get close, attack mode spawns them
# already aggroed so they come running the second they exist.

enum Mode { IDLE, ATTACK_RUN }

@export var monster_scene: PackedScene
## drag an existing monster from the level here to spawn copies of that exact one,
## keeps whatever tweaks it has in the inspector. takes priority over monster_scene
@export var monster_template: Node3D
@export var count: int = 3
@export var radius: float = 8.0
@export var mode: Mode = Mode.IDLE

@export var spawn_on_ready: bool = false
# spawn the batch as soon as the level loads ^

## walk into the selected area and it fires the spawner, leave empty to only spawn manually
@export var trigger_area: Area3D
## only let the trigger area fire the batch once
@export var trigger_once: bool = true

var _triggered: bool = false

func _ready() -> void:
	if trigger_area != null:
		trigger_area.body_entered.connect(_on_trigger_body_entered)
	if spawn_on_ready:
		spawn_all()


func _on_trigger_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	if trigger_once and _triggered:
		return
	_triggered = true
	spawn_all()


func spawn_all() -> void:
	for i in count:
		spawn_one()


func spawn_one() -> void:
	# a dragged in template wins, otherwise fall back to the packed scene
	var monster: Node3D
	if monster_template != null:
		monster = monster_template.duplicate() as Node3D
	elif monster_scene != null:
		monster = monster_scene.instantiate() as Node3D
	else:
		return

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
