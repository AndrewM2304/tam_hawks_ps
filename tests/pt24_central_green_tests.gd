extends RefCounted
## Independent fixed planting sites, real native support and unchanged riding
## envelopes. These checks do not certify landscape art or human route choice.

const Green = preload("res://game/levels/pt24_central_green.gd")
const Routes = preload("res://tests/world_routes_tests.gd")


static func run(tree: SceneTree,world: Node3D,check: Callable) -> void:
	await tree.physics_frame
	await tree.process_frame
	if not bool(world.get_meta("pt24_design_preview",false)):
		check.call(not world.has_meta("pt24_central_green_report"),
			"PT24-17: changed tree-batch bounds stay behind the explicit design admission gate")
		return
	var trunks: MultiMeshInstance3D=world.get_node("OutdoorRoutes/ParkTreeTrunks")
	var crowns: MultiMeshInstance3D=world.get_node("OutdoorRoutes/ParkTreeCanopies")
	var lower: Array=trunks.get_meta("authored_tree_transforms",[])
	var upper: Array=crowns.get_meta("authored_tree_transforms",[])
	var sites := [Vector3(-120,.5,-101),Vector3(-111,.5,-96),Vector3(-103,.5,-102),
		Vector3(-65,.5,-101),Vector3(-60,.5,-94),Vector3(-57,.5,-102)]
	var found: Array[int] = []
	for site: Vector3 in sites:
		var count := 0
		var paired := true
		for i: int in lower.size():
			var origin: Vector3=world.to_local(trunks.to_global(lower[i].origin))
			if origin.distance_to(site)>0.001: continue
			count+=1
			found.append(i)
			paired=paired and i<upper.size() and lower[i]==upper[i]
		var at:=world.to_global(site)
		var hit:=world.get_world_3d().direct_space_state.intersect_ray(
			PhysicsRayQueryParameters3D.create(at+Vector3.UP*0.15,at-Vector3.UP*0.15,1))
		check.call(count==1 and paired and not hit.is_empty() and hit.position.distance_to(at)<0.001,
			"PT24-17: one paired tree is grounded in the actual enclosed low lawn "+str(site))
	var report: Dictionary=world.get_meta("pt24_central_green_report",{})
	var relocations: Array=report.get("relocated_trees",[])
	var preserved := relocations.size()==6 and found.size()==6 and lower==upper \
		and lower.size()==trunks.multimesh.instance_count and lower.size()==crowns.multimesh.instance_count
	for row: Dictionary in relocations:
		var original: Transform3D=row.before
		var current: Transform3D=row.after
		var source: Vector3=world.to_local(trunks.to_global(original.origin))
		preserved=preserved and found.has(row.index) and current.basis==original.basis \
			and source.x < -238 and source.z > -150 and source.z < -60
	check.call(preserved,"PT24-17: six outer park trees retain their paired crown/trunk transforms, original scale and yaw")
	var clear_view := true
	var central_slot := Rect2(-96,-108,24,22)
	for index: int in found:
		var frame: Transform3D=lower[index]
		var envelope: AABB=(world.global_transform.affine_inverse()*crowns.global_transform*frame)*crowns.multimesh.mesh.get_aabb()
		var footprint:=Rect2(Vector2(envelope.position.x,envelope.position.z),Vector2(envelope.size.x,envelope.size.z))
		clear_view=clear_view and not central_slot.intersects(footprint) \
			and envelope.end.z < -86 and envelope.end.x < -52 and envelope.position.z > -108
	check.call(clear_view,"PT24-17: two actual groves keep the central view slot, civic edge and lower service court clear")
	# Query whole mesh envelopes natively, not just points or ground rays. An
	# inside-building ray can miss; a volume query must still reject overlap.
	var ground_rids: Array[RID]=[]
	for body: Node in world.find_children("*","StaticBody3D",true,false):
		if bool(body.get_meta("terrain_surface",false)) or body.is_in_group("outdoor_surfaces"):
			ground_rids.append((body as StaticBody3D).get_rid())
	var native_clear := true
	for index: int in found:
		for batch: MultiMeshInstance3D in [trunks,crowns]:
			var envelope: AABB=(batch.global_transform*lower[index])*batch.multimesh.mesh.get_aabb()
			var shape:=BoxShape3D.new()
			shape.size=envelope.size
			var query:=PhysicsShapeQueryParameters3D.new()
			query.shape=shape
			query.transform=Transform3D(Basis.IDENTITY,envelope.get_center())
			query.collision_mask=1
			query.margin=0.0
			query.exclude=ground_rids
			native_clear=native_clear and world.get_world_3d().direct_space_state.intersect_shape(query,64).is_empty()
	check.call(native_clear,"PT24-17: twelve complete trunk/crown native volume probes exclude only authored terrain and enter no architecture")
	for fixed: Array in [[Vector3(-42,6,-122),Vector3(-145,6,-125)],
		[Vector3(-126,2,0),Vector3(-145,2,0)],
		[Vector3(-78,1,-66),Vector3(-78,4,-74)],
		[Vector3(-88,4,-80),Vector3(-35,4,-80)]]:
		check.call(Routes._clear_sweep(world,fixed[0],fixed[1]) and Routes._clear_sweep(world,fixed[1],fixed[0]),
			"PT24-17: protected promenade, station port or lower-court route stays clear "+str(fixed))
	var before_nodes := world.find_children("*","Node",true,false).size()
	var before_bodies := world.find_children("*","StaticBody3D",true,false).size()
	var trunk_mesh := trunks.multimesh.mesh
	var crown_mesh := crowns.multimesh.mesh
	var repeated:=Green.build(world)
	check.call(repeated==report and trunks.multimesh.mesh==trunk_mesh and crowns.multimesh.mesh==crown_mesh \
		and before_nodes==world.find_children("*","Node",true,false).size() \
		and before_bodies==world.find_children("*","StaticBody3D",true,false).size() \
		and trunks.get_meta("authored_tree_transforms")==lower,
		"PT24-17: startup relocation is idempotent and retains the resident meshes, instances and native geometry")
