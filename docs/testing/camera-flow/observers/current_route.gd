extends "res://docs/testing/map-flow/observers/approach.gd"
## Current-source route review; visible window and real mapped input only.
func _initialize()->void:
	root.title="CURRENT CAMERA — spawn / Kelvingrove / spawn"
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP,true)
	super._initialize()

func _key(code:Key,down:bool)->void:
	var action:StringName={KEY_W:&"push",KEY_S:&"brake",KEY_A:&"steer_left",KEY_D:&"steer_right"}.get(code,&"")
	if down and bool(key_states.get(code,false)) and action!=&"" and not Input.is_action_pressed(action):
		key_states[code]=false
		print("HELD_ROUTE_KEY_REASSERT ",code," at ",seconds)
	super._key(code,down)
