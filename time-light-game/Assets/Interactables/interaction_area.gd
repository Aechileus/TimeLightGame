extends Area3D
class_name InteractionArea

# Drop this on anything the player can interact with. The player aims at it and
# hits interact, which calls interact() here and fires the interacted signal.
# Whatever owns this area (a button, a lever, a door) listens for that.

signal interacted

## optional label you could show in a prompt ui down the line
######### @export var prompt: String = "Interact"
# currently commented out



# Called by the player when they interact while looking at this area.
func interact() -> void:
	interacted.emit()
