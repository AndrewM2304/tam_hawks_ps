extends "res://game/player/skater_visual.gd"
## Ignored instrumentation: native contact helper still runs exactly once.
var mode := "baseline"
var reported_speed := 0.0
var trace: Dictionary = {}
var drag: Dictionary = {}
func animate(delta: float,state: Dictionary) -> void:
	drag={}
	var original_sign: float=state.get("travel_sign",1.0)
	if mode=="push-policy":state.travel_sign=-1.0 if reported_speed< -0.5 else 1.0
	var input_sign: float=state.get("travel_sign",1.0)
	super.animate(delta,state)
	trace={"speed":reported_speed,"input_sign":input_sign,"original_sign":original_sign,
		"effective_sign":-1.0 if input_sign<0.0 else 1.0,"push_blend":_push_blend,
		"brake_blend":_brake_blend,"push_phase":_push_phase,"manual_blend":_manual_blend,"drag":drag}
func _drag_foot_contact(target: Vector3,shoe_basis: Basis,loaded: float) -> Dictionary:
	var result: Dictionary=super._drag_foot_contact(target,shoe_basis,loaded)
	drag={"loaded":loaded,"target_before":_rider.to_global(target),"target_after":_rider.to_global(result.target),
		"basis_before":shoe_basis,"basis_after":result.basis,"supported":result.supported}
	return result
