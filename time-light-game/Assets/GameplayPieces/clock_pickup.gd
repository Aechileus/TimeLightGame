extends Node3D

## The bonus time added when picking the clock up
@export var bonus_time: float = 10.0
@export_category("Animation")
## how far up and down it bobs from where it was placed
@export var bob_height: float = 0.5
## how quick the bob cycle is
@export var bob_speed: float = 2.0
## how fast it spins around its y
@export var spin_speed: float = 1.5
## how fast the hands spin (rotations per second)
@export var hand_spin_speed: float = 0.75



@onready var pickup: Area3D = $Pickup
@onready var minutes_hand: MeshInstance3D = $clock_2/clock_2_arm_minutes
@onready var hours_hand: MeshInstance3D = $clock_2/clock_2_arm_hours

var base_y: float = 0.0
var time: float = 0.0


func _ready() -> void:
	base_y = position.y
	pickup.body_entered.connect(on_body_entered)


func _physics_process(delta: float) -> void:
	time += delta
	# bob around the placed height, spin keeps ticking on top of it
	#position.y = _base_y + sin(_time * bob_speed) * bob_height
	#rotate_y(spin_speed * delta)
	minutes_hand.rotate_z(2 * PI * hand_spin_speed * delta)
	hours_hand.rotate_z(-2 * PI * hand_spin_speed/3.0 * delta)


func on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	SignalBus.change_level_time.emit(bonus_time)
