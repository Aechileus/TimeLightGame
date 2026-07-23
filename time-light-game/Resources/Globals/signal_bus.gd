extends Node


# This Global Signal "Bus" should be used for us to globally declare signals
# so we can call them anywhere

signal game_state_changed(new_state)
signal game_speed_state_changed(new_state)


# fires when the second beep of a time stop countdown starts, so stuff like the
# arm animation can wind up and land right as the state actually flips
signal time_stop_winding_up(stopping)


# abilities pay their cost in seconds via this signal, the level timer listens for this to subtract
signal ability_time_spent(seconds)
