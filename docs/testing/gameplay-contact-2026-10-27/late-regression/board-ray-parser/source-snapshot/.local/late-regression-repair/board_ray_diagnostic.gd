extends SceneTree
const Checks=preload("res://tests/board_floor_ray_reuse_tests.gd")
const BowlChecks=preload("res://tests/pt24_bowl_contact_tests.gd")
const Clearance=preload("res://game/tricks/grind_clearance.gd")
class Spy extends Clearance:
	var proposed:=Transform3D.IDENTITY
	var up:=Vector3.UP
	var was_called:=false
	func allows_frame(frame:Transform3D,normal:Vector3)->bool:
		proposed=frame;up=normal;was_called=true
		return super.allows_frame(frame,normal)
func _initialize()->void:_run.call_deferred()
func _run()->void:
	var fixture:Dictionary=await Checks._fixture(self)
	var rider=fixture.rider
	var spy:=Spy.new();rider._grind_clearance=spy
	var ready:bool=spy.rebuild(rider._board_visual,rider._visual_rig.board_contact_geometry(),rider.get_rid())
	var rows:Array[Dictionary]=[]
	for x:float in [20.01,19.94]:
		rider.global_position=Vector3(x,.14,0);rider.rotation=Vector3.ZERO
		spy.was_called=false
		var pair:Dictionary=Checks._pair(rider)
		var fit:Dictionary=pair.fit
		var proposed:Transform3D=spy.proposed
		if not fit.is_empty():proposed=BowlChecks._presentation_pose(rider,fit)
		var full_clear:bool=spy.allows_frame(proposed,spy.up if fit.is_empty() else Vector3(fit.normal))
		var obstruction:Dictionary=spy.last_obstruction.duplicate()
		var component:Dictionary={}
		for part:Dictionary in spy._parts:
			if part.shape==spy._query.shape:component=part;break
		var minimum_gap:=INF
		var worst:Dictionary={}
		if not component.is_empty():
			for p:Vector3 in component.points:
				var actual:Vector3=spy._query.transform*p
				var q:=PhysicsRayQueryParameters3D.create(actual+Vector3.UP*.2,actual-Vector3.UP*.2,1|8,[rider.get_rid()])
				var hit:Dictionary=rider.get_world_3d().direct_space_state.intersect_ray(q)
				if hit.is_empty() or Vector3(hit.normal).y<.99:continue
				var gap:float=(actual-Vector3(hit.position)).dot(Vector3(hit.normal))
				if gap<minimum_gap:
					minimum_gap=gap;worst={"vertex":str(actual),"floor":str(hit.position),"native_body":str(hit.collider.get_path()),"gap":gap}
		var row:Dictionary={"x":x,"ready":ready,"riders":fixture.root.find_children("*","CharacterBody3D",true,false).size(),"equal":pair.equal,"rays":pair.rays,"fit":str(fit),"proposed":str(proposed),"full_model_clear":full_clear,"obstruction":str(obstruction),"obstruction_path":str(obstruction.collider.get_path()) if obstruction.has("collider") and is_instance_valid(obstruction.collider) else "","worst_actual_vertex":worst,"mask":spy._query.collision_mask,"exclude":str(spy._query.exclude)}
		rows.append(row);print("BOARD_NATIVE_DIAGNOSTIC ",JSON.stringify(row))
	var args:=OS.get_cmdline_user_args()
	if args.size()==1:
		var path:String=ProjectSettings.globalize_path(args[0])
		if path.begins_with(ProjectSettings.globalize_path("res://.local/")):
			var file:=FileAccess.open(path,FileAccess.WRITE);file.store_string(JSON.stringify(rows,"  ")+"\n");file.close()
	fixture.viewport.queue_free();await process_frame
	print("RESULT: ",1 if ready else 0," passed, ",0 if ready else 1," failed")
	quit(0 if ready else 1)
