class_name Ability
extends Resource

# Template for any ability. Make a new .tres from this, fill in the fields,
# and drop it into a slot on the players Abilities component.

@export var display_name: String = ""
@export var icon: Texture2D
# name of the child node under the Abilities component that runs the effect
@export var effect_node: String = ""
# whether this ability aims with the circle marker, self cast stuff should
# turn this off so right click just fires it
@export var needs_target: bool = true
# fires right away even while time is frozen instead of queueing for the unpause.
# the shoot uses this since its projectiles freeze on their own and go at once
@export var cast_while_frozen: bool = false

# seconds pulled off the level clock when this gets cast
@export_range(0.0, 30.0, 0.25) var time_cost: float = 1.0
# how many action points this eats from the per pause economy, if its enabled
@export_range(1, 20, 1) var economy_cost: int = 1

# movement style abilities like the dash use these two
@export_range(1.0, 100.0, 0.5) var speed: float = 18.0
@export_range(1.0, 60.0, 0.5) var cast_range: float = 12.0

# how much hp damaging abilities like the shoot take off a target
@export_range(0.0, 200.0, 1.0) var damage: float = 25.0

# played the moment the cast goes off
@export var cast_sfx: AudioStream
# animation name on the arms rig AnimationPlayer, leave empty for none
@export var cast_animation: String = ""
