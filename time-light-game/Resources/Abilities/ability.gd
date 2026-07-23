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

# seconds pulled off the level clock when this gets cast
@export_range(0.0, 30.0, 0.25) var time_cost: float = 1.0

# movement style abilities like the dash use these two
@export_range(1.0, 100.0, 0.5) var speed: float = 18.0
@export_range(1.0, 60.0, 0.5) var cast_range: float = 12.0

# played the moment the cast goes off
@export var cast_sfx: AudioStream
# animation name on the arms rig AnimationPlayer, leave empty for none
@export var cast_animation: String = ""
