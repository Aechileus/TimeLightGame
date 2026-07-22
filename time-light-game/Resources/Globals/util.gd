extends Node

# ENUM Library

# examples, we dont have to use
enum GAME_SPEEDS {NORMAL, FAST}
enum GAME_TIME_STATES {PAUSED, PLAY}

# USED BY SCENE CHANGER, we should use the scene changer global that way we can't accidentally
# queue_free a scene change in progress.
enum GAME_SCENES {GAME, MENU}

var GAME_PATH = "res://Main.tscn"
var MENU_PATH = "res://Menu.tscn"
