extends "res://docs/testing/camera-flow/observers/motion.gd"
class Probe extends "res://game/player/chase_camera.gd":
	var seen:Dictionary={}
	func _choose(space:PhysicsDirectSpaceState3D,anchor:Vector3,board:Vector3,rear:Vector3,distance:float,excluded:Array[RID],delta:float)->Dictionary:
		var result:=super._choose(space,anchor,board,rear,distance,excluded,delta)
		var key:=roundi(_body_up.y*10)
		if _ramp_mode and not is_zero_approx(_selected_angle) and not seen.has(key):
			seen[key]=true
			var direct:=_best_height(space,anchor,board,rear,distance,0.0,excluded)
			var obstructions:Array=[]
			for h:float in [.12,1.05,1.8]:
				var q:=PhysicsRayQueryParameters3D.create(direct.position,board+_body_up*h,1,excluded)
				var hit:=space.intersect_ray(q)
				obstructions.append(str(hit.get("collider","clear")))
			print("REAR_DIAG ",JSON.stringify({"up":str(_body_up),"rear":str(rear),"board":str(board),"anchor":str(anchor),"direct":str(direct),"obstructions":obstructions,"selected":_selected_angle}))
		return result
func _sample_pipe(delta:float)->void:
	if not timed.inner is Probe:
		timed.inner=Probe.new()
	super._sample_pipe(delta)
