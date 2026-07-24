extends Node

func cast(_ability: Ability, _point: Vector3, strength: float) -> void:
	print("test ability used with strength " + String.num(strength))
