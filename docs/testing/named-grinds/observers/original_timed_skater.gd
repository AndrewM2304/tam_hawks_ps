extends "res://docs/testing/named-grinds/observers/baseline_skater.gd"
var audit:SceneTree
func _tick_grind(delta:float)->void:
	var start:=Time.get_ticks_usec()
	super._tick_grind(delta)
	if is_instance_valid(audit) and audit.active:audit.grind_times.append(Time.get_ticks_usec()-start)
func _try_grind(previous_position:Vector3=Vector3.ZERO,swept:bool=false)->bool:
	var start:=Time.get_ticks_usec()
	var result:=super._try_grind(previous_position,swept)
	if is_instance_valid(audit) and audit.active:
		var elapsed:=Time.get_ticks_usec()-start
		audit.entry_times.append(elapsed)
		if result:audit.capture_times.append(elapsed)
	return result
