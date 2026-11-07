extends SceneTree
const Tests=preload("res://tests/pt24_bowl_contact_tests.gd")
const Setup=preload("res://game/core/input_setup.gd")
func _initialize():call_deferred("_run")
func _crown_probe(rider:CharacterBody3D,bowl:Node3D,center:Dictionary)->void:
	var point:Vector3=rider.global_position-Vector3.UP*(rider.global_position.y-Vector3(center.position).y)
	var pose:=Transform3D(rider.global_basis,point+Vector3.UP*.008+rider.global_basis*rider._visual_rig._board_rest_position)
	var space:=rider.get_world_3d().direct_space_state
	var part_hits:Array=[]
	var query:=PhysicsShapeQueryParameters3D.new()
	query.transform=pose
	query.collision_mask=1|2|8
	query.exclude=[rider.get_rid()]
	query.margin=0
	for index:int in rider._grind_clearance._parts.size():
		query.shape=rider._grind_clearance._parts[index].shape
		var hits:=space.intersect_shape(query,8)
		if not hits.is_empty():part_hits.append({"part":index,"hits":hits})
	var inside:Array=[]
	var tested:=0
	var unique:Dictionary={}
	var body:StaticBody3D=bowl._native_steel_coping
	var crown:float=bowl.radius+.025
	var radial:float=bowl.floor_radius+bowl.radius
	for mesh:MeshInstance3D in rider._visual_rig.board_contact_geometry().meshes:
		var local:Transform3D=rider._board_visual.global_transform.affine_inverse()*mesh.global_transform
		for vertex:Vector3 in mesh.mesh.get_faces():
			var at:Vector3=pose*local*vertex
			if unique.has(at):continue
			unique[at]=true
			var relative:Vector3=bowl.to_local(at)
			if absf(Vector2(relative.x,relative.z).length()-radial)>.046 or absf(relative.y-crown)>.046:continue
			tested+=1
			# Diagnostic mask2 isolates actual steel, not authored analytic tube.
			var ray:=PhysicsRayQueryParameters3D.create(at+Vector3.UP*.10,at-Vector3.UP*.10,2,[rider.get_rid()])
			var top:Dictionary=space.intersect_ray(ray)
			ray.from=at-Vector3.UP*.10
			ray.to=at+Vector3.UP*.10
			var bottom:Dictionary=space.intersect_ray(ray)
			if top.is_empty() or bottom.is_empty() or top.rid!=body.get_rid() or bottom.rid!=body.get_rid() \
				or int(top.shape)!=0 or int(bottom.shape)!=0 or Vector3(top.normal).y<=0 or Vector3(bottom.normal).y>=0:continue
			if at.y>Vector3(bottom.position).y+.00001 and at.y<Vector3(top.position).y-.00001:
				inside.append({"at":at,"mesh":str(mesh.get_path()),"local":vertex,"top":top.position,"bottom":bottom.position,"depth":minf(at.y-Vector3(bottom.position).y,Vector3(top.position).y-at.y)})
	var lift_clear:=INF
	for millimetres:int in range(0,101):
		var candidate:=pose
		candidate.origin.y+=millimetres*.001
		if rider._native_rim_frame_clear(candidate,0):
			lift_clear=millimetres*.001
			break
	print("CROWN_MATERIAL_PROBE ",{"at":rider.global_position,"pose":pose,"parts":part_hits,"tested_vertices":tested,"inside_native_vertices":inside,"minimum_clear_planar_lift_1mm_resolution":lift_clear})

func _run():
	Setup.register_actions()
	var f:=await Tests._fixture(self)
	var original:StaticBody3D=f.bowl._native_annular_deck
	var paving:=StaticBody3D.new()
	paving.name="ForeignCoincidentAnnularFloor"
	for node in original.get_children():
		if not node is CollisionShape3D:continue
		var collision:=CollisionShape3D.new()
		collision.shape=node.shape
		collision.transform=node.transform
		paving.add_child(collision)
	f.root.add_child(paving)
	paving.global_transform=original.global_transform
	# Explicit2um height separates coincident native ray tie winners. The
	# actual finite source triangles/annular aperture are unchanged.
	paving.global_position.y+=.000002
	await physics_frame
	await process_frame
	var rider:CharacterBody3D=f.rider
	for at:Vector3 in [Vector3(-10.601124,2.0138104,139.50015),Vector3(-10.391407,2.0489893,139.51155),Vector3(-10.19133,2.063749,139.5394)]:
		rider.global_transform=Transform3D(Basis(Vector3.UP,-PI*.5),at)
		var center:Dictionary=rider._native_floor_hit(Vector3.UP)
		_crown_probe(rider,f.bowl,center)
		var fit:Dictionary=rider._native_board_floor()
		var clear:=false
		if not fit.is_empty():clear=rider._native_rim_frame_clear(Tests._presentation_pose(rider,fit),0.0)
		print("TINY_MIXED_OWNER ",{"at":at,"center":rider._native_floor_hit(Vector3.UP),"fit":fit,"clear":clear})
	f.viewport.free()
	quit()
