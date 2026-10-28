extends SceneTree
const Audit=preload("res://game/levels/surface_audit.gd")
const Main=preload("res://game/main.gd")
class Flat extends Node3D:
	func get_ground_height(_point: Vector3) -> float:return global_position.y
func _initialize() -> void:_run.call_deferred()
func _box(parent: Node3D,size: Vector3,at: Vector3) -> CollisionShape3D:
	var body:=StaticBody3D.new();body.position=at;parent.add_child(body)
	var shape:=BoxShape3D.new();shape.size=size
	var collision:=CollisionShape3D.new();collision.shape=shape;body.add_child(collision)
	return collision
func _run() -> void:
	var fixture:=Flat.new();fixture.position=Vector3(2700,300,2700);root.add_child(fixture)
	var support:=_box(fixture,Vector3(3,0.1,0.6),Vector3(0,0.5,0))
	_box(fixture,Vector3(30,0.2,30),Vector3(0,-0.1,0))
	var audit:=Audit.new();audit.build(fixture,[])
	var frame:=support.global_transform
	var a:=frame*Vector3(-1.38,0.05,-0.3)+Vector3.UP*0.02
	var b:=frame*Vector3(1.38,0.05,-0.3)+Vector3.UP*0.02
	var volume:AABB=audit._native_ledge_volume(a,b)
	print("OWN_BOX ",{"a":a,"b":b,"top":a.y-0.02,"volume":volume,"drop":audit._native_ledge_drop(a,b,Vector3.FORWARD),"lines":audit.lines.size(),"work":audit.snapshot().native_ledge_fallback})
	for bounds:AABB in audit._ledge_obstacles:print("OWN_BOUNDS ",{"bounds":bounds,"top":bounds.end.y,"below":bounds.end.y<=a.y-0.02+0.000001,"intersect":volume.intersects(bounds)})
	# build() intentionally releases its scratch bounds; rebuild them only for this diagnostic.
	audit._collect_ledge_obstacles(fixture)
	for bounds:AABB in audit._ledge_obstacles:print("OWN_BOUNDS ",{"bounds":bounds,"top":bounds.end.y,"below":bounds.end.y<=a.y-0.02+0.000001,"intersect":volume.intersects(bounds)})
	fixture.queue_free();await process_frame
	var game=Main.new();game.persistence_enabled=false;root.add_child(game);game.start_mode(true)
	game.skater.set_physics_process(false);game.skater.set_process(false)
	await physics_frame;await process_frame
	var report:Dictionary=game.world.get_surface_audit()
	for record:Dictionary in report.surfaces:
		if record.label=="NorthStreetRetaining":print("NORTH_RECORD ",record)
	for line in game.world._surface_audit.lines:
		if not line.id.contains("_Native_"):continue
		var native:Array=[]
		for fraction:float in [.2,.5,.8]:
			var distance:float=line.length*fraction
			var at:Vector3=game.skater._grind._body_point(line,distance)
			native.append(game.skater._rail_path_clear(at+Vector3.UP*.15,at))
		print("ACTUAL_GENERIC ",{"id":line.id,"points":line.points,"native":native})
	print("ACTUAL_WORK ",report.native_ledge_fallback)
	game.queue_free();await process_frame
	quit()
