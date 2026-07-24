extends Node

# ENUM Library

# examples, we dont have to use
enum GAME_SPEEDS {NORMAL, FAST}
enum GAME_TIME_STATES {PAUSED, PLAY}

# USED BY SCENE CHANGER, we should use the scene changer global that way we can't accidentally
# queue_free a scene change in progress.
enum GAME_SCENES {GAME, MAIN_MENU, PLAYGROUND}

var GAME_PATH = "res://GameScenes/GameplayScenes/test_scene.tscn"
var MAIN_MENU_PATH = "res://GameScenes/UI/MainMenu.tscn"
var PLAYGROUND_PATH = "res://GameScenes/GameplayScenes/playground.tscn"

# FOOTSTEP NOISES
enum FLOOR_MATERIAL {CONCRETE, GRASS, CARPET, WOOD, METAL}
