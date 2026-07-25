extends Area3D

# For tutorial level ability granting
@export_group("UI Unlocks")
## turns the abilities hud back on
@export var grant_abilities_ui: bool = false
## turns the time manipulation / pause hud back on
@export var grant_time_ui: bool = false
## turns the level timer back on
@export var grant_level_timer_ui: bool = false

@export_group("Ability Unlocks")
## lets the player resume time again
@export var grant_resume_time: bool = false
## lets the player stop time again
@export var grant_stop_time: bool = false
## gives the dash back
@export var grant_dash: bool = false
## gives the shoot back
@export var grant_shoot: bool = false

## only fire the first time the player walks in
@export var one_shot: bool = true

var _used: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	if one_shot and _used:
		return
	_used = true
	Global.grant_unlocks(grant_abilities_ui, grant_time_ui, grant_level_timer_ui, grant_resume_time, grant_stop_time, grant_dash, grant_shoot)
