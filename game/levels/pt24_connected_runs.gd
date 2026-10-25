extends RefCounted
## Startup-only placement pass. Existing bodies, finishes and guide identities
## move together before edge snapshots/batching; no world processing is added.

const Grind = preload("res://game/tricks/grind_line.gd")
const Quarter = preload("res://game/levels/transition_feature.gd")
var routes: Array[Dictionary] = []
var _features: Array[Dictionary] = []
var _lines: Array = []
var _quarter: Node3D
var _built := false


func build(world: Node3D) -> void:
	if _built: return
	_built = true
	# This seat now releases into the real east quay close. The teaching rail,
	# fountain and the Z28 cross-court beginner route retain their exact positions.
	_move_feature(world,"exchange_south_return",Vector3(15,0,34),Vector3(12,0,35),-PI*0.5)
	# Reuse the civic return seat as the missing back-street continuation. Its
	# long edge follows the street, outside the protected Z-80 through lane.
	_move_feature(world,"civic_island_return",Vector3(13,4,-64),Vector3(66,4,-84.7),PI*0.5)
	# A low existing bank belongs between the two station transition pockets,
	# rather than beneath the service walk. The old high/low routes stay open.
	_move_feature(world,"station_low_manual",Vector3(-114,2,-13.5),Vector3(-80,2,40),0.0)
	# The safe bridge's west return gets an edge aligned with its arrival heading;
	# it does not send the through lane across the bowl mouth or technical relay.
	_move_feature(world,"clyde_south_return",Vector3(-18.5,2,140),Vector3(-32.2,2,134.5),-PI*0.5)
	_recording_court(world)
	_gate_alley_frame(world)
	if bool(world.get_meta("pt24_design_preview",false)):
		_civic_port_return(world)
	_add_route(world,"exchange_east_quay_handoff","Exchange south ledge to east quay close",[
		Vector3(16,0,29),Vector3(16,0,39),Vector3(12,0,39),Vector3(12,0,42),Vector3(12,2,55),Vector3(12,2,59)])
	_add_route(world,"civic_backstreet_ledge_return","Civic back-street ledge and clear return",[
		Vector3(57,4,-80),Vector3(75,4,-80),Vector3(75,4,-83),Vector3(57,4,-83),Vector3(57,4,-80)])
	_add_route(world,"station_transition_handoff","Station spine to manual bank and halfpipe return",[
		Vector3(-98,2,40),Vector3(-89.2,2,40),Vector3(-85.2,2,40),Vector3(-83,2.36,40),
		Vector3(-77,2.36,40),Vector3(-74.8,2,40),Vector3(-70.8,2,40),Vector3(-68,2,40)])
	_add_route(world,"clyde_west_landing_return","Safe bridge west ledge return",[
		Vector3(-25,2,124),Vector3(-36,2,124),Vector3(-36,2,140),Vector3(-30,2,140)])
	world.set_meta("pt24_connected_runs_built",true)


func get_grind_lines() -> Array:
	var result := _lines.duplicate()
	if is_instance_valid(_quarter): result.append_array(_quarter.get_grind_lines())
	return result


func get_features() -> Array[Dictionary]:
	var result: Array[Dictionary]=_features.duplicate(true)
	if is_instance_valid(_quarter):
		for raw: Dictionary in _quarter.get_feature_definitions():
			var feature:=raw.duplicate(true)
			feature.position=_quarter.global_position
			feature.district="george_square"
			feature.grind_ids=["Grind_CivicPortReturn_Coping"]
			result.append(feature)
	return result


func _move_feature(world: Node3D,id: String,old_origin: Vector3,new_origin: Vector3,yaw: float) -> void:
	var frame := Transform3D(Basis(Vector3.UP,yaw),new_origin-Basis(Vector3.UP,yaw)*old_origin)
	var guide_id := "Grind_Ledge_"+id
	for child: Node in world.get_children():
		if not child is Node3D: continue
		var label := String(child.get_meta("art_label",String(child.name)))
		if label.begins_with(id) or String(child.get_meta("grind_id",""))==guide_id \
				or label.begins_with(guide_id+"Masonry") or label.begins_with(guide_id+"SeatCap"):
			child.transform=frame*child.transform
			if child.has_meta("support_probe"):
				child.set_meta("support_probe",frame*Vector3(child.get_meta("support_probe")))
	# Only the station bank has terrain support records. Translation preserves
	# its plane diagonals and underside; the other changes are ordinary props.
	for patch: Dictionary in world._terrain.patches:
		if String(patch.id).begins_with(id):
			var bounds: Rect2=patch.bounds
			bounds.position+=Vector2(new_origin.x-old_origin.x,new_origin.z-old_origin.z)
			patch.bounds=bounds
	for feature: Dictionary in world._fidelity_infill.features:
		if String(feature.id)==id: _transform_record(feature,frame)
	for route: Dictionary in world._fidelity_infill.routes:
		if String(route.id)==id: _transform_record(route,frame)


func _transform_record(record: Dictionary,frame: Transform3D) -> void:
	for key: String in record.keys():
		var value: Variant=record[key]
		if value is Vector3:
			record[key]=frame*value
		elif value is PackedVector3Array:
			# Infill publishes the same packed array to its guide/feature/route.
			# Detach it before editing metadata, or the physical guide is rotated
			# a second time when its already-moved author snapshots the points.
			var points: PackedVector3Array=value.duplicate()
			for index: int in points.size(): points[index]=frame*points[index]
			record[key]=points
		elif value is Rect2:
			var bounds: Rect2=value
			var transformed := Rect2(Vector2.ZERO,Vector2.ZERO)
			var first := true
			for corner: Vector2 in [bounds.position,Vector2(bounds.end.x,bounds.position.y),bounds.end,Vector2(bounds.position.x,bounds.end.y)]:
				var at := frame*Vector3(corner.x,0,corner.y)
				if first:
					transformed=Rect2(Vector2(at.x,at.z),Vector2.ZERO)
					first=false
				else: transformed=transformed.expand(Vector2(at.x,at.z))
			record[key]=transformed


func _recording_court(world: Node3D) -> void:
	var side: StaticBody3D=world.get_node("RecordingAlcoveSide")
	var back: StaticBody3D=world.get_node("RecordingAlcoveBack")
	# A long low loading-yard kerb meets the venue instead of two tall blockers.
	# Reuse the redundant rear-wall body/mesh for an actual steel bearing on the
	# kerb. Its raised native top keeps parallel tyres clear of broad masonry.
	# The venue and existing north boundary already enclose the rear of the yard.
	_resize_box(side,Vector3(113,1.8,-32.875),Vector3(0.5,0.6,17.75))
	_resize_box(back,Vector3(113,2.17,-32.875),Vector3(0.14,0.14,17.75))
	back.collision_layer=2
	back.collision_mask=0
	back.set_meta("surface_audio","metal")
	back.set_meta("authored_grind_ids",["Grind_Ledge_RecordingCourt"])
	back.set_meta("audit_capture_ids",["Grind_Ledge_RecordingCourt"])
	for mesh: Node in back.get_children():
		if mesh is MeshInstance3D: mesh.material_override=world._materials["iron"]
	var local := PackedVector3Array([Vector3(113,2.24,-24.2),Vector3(113,2.24,-39.8)])
	var points := PackedVector3Array()
	for at: Vector3 in local: points.append(world.to_global(at))
	var line=Grind.new("Grind_Ledge_RecordingCourt",points,"ledge")
	line.configure_contact(0.0,0.0,"pt24.recording_court_steel_top")
	_lines.append(line)
	_features.append({"id":"recording_court_loading_edge","kind":"loading_yard_ledge","district":"barras",
		"position":world.to_global(Vector3(113,1.5,-31)),"floor_y":1.5,"grind_ids":[line.id],
		"approach":PackedVector3Array([world.to_global(Vector3(113,1.5,-20)),world.to_global(Vector3(113,1.5,-23))]),
		"landing":PackedVector3Array([world.to_global(Vector3(116,1.5,-36)),world.to_global(Vector3(120,1.5,-33))])})
	_add_route(world,"recording_court_return","Loading court collectible and supported return",[
		Vector3(116,1.5,-22),Vector3(116,1.5,-33),Vector3(120,1.5,-33),Vector3(120,1.5,-24),Vector3(116,1.5,-22)])


func _resize_box(body: StaticBody3D,at: Vector3,size: Vector3) -> void:
	body.position=at
	for child: Node in body.get_children():
		if child is CollisionShape3D and child.shape is BoxShape3D:
			child.shape=child.shape.duplicate()
			child.shape.size=size
		elif child is MeshInstance3D and child.mesh is BoxMesh:
			child.mesh=child.mesh.duplicate()
			child.mesh.size=size


func _gate_alley_frame(world: Node3D) -> void:
	# The service shutter now controls an actual alley. Its east side already
	# belongs to the shop's native facade; this western service wall leaves both
	# street mouths open. It shares the station's mineral finish and one resident
	# mesh, adding twelve triangles and one shape, no body or draw submission.
	var floor: StaticBody3D=world.get_node("CentralStationFloor")
	var at := Vector3(-50.1,3.5,-2.5)
	var size := Vector3(0.3,3,25)
	var collision := CollisionShape3D.new()
	collision.name="ServiceAlleyFrame"
	var shape := BoxShape3D.new()
	shape.size=size
	collision.shape=shape
	collision.transform=floor.transform.affine_inverse()*Transform3D(Basis.IDENTITY,at)
	floor.add_child(collision)
	for child: Node in floor.get_children():
		if not child is MeshInstance3D or child.mesh==null: continue
		var surface:=SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		surface.set_smooth_group(-1)
		for vertex: Vector3 in child.mesh.get_faces(): surface.add_vertex(vertex)
		var wall:=BoxMesh.new()
		wall.size=size
		for vertex: Vector3 in wall.get_faces():
			surface.add_vertex(child.transform.affine_inverse()*(collision.transform*vertex))
		surface.generate_normals()
		child.mesh=surface.commit()
		break
	floor.set_meta("pt24_service_alley_frame",true)


func _civic_port_return(world: Node3D) -> void:
	# The reported south-facing port now meets an intentional return transition.
	# Keep this additional construction behind the shared performance admission
	# gate. The original west-going Z-122 route is six metres before its toe.
	# Extend the retained landing to the real frontage. The narrower transition
	# leaves two1.25m shoulders, so an overshoot has supported routes back out.
	var foundation: StaticBody3D=world._terrain.add_patch(world,"CivicPortReturnFoundation",Rect2(-42,-116,7,7.2),
		Vector4.ONE*6.0,world._materials["stone"],"stone")
	_civic_frontage_return(foundation)
	_quarter=Quarter.new()
	_quarter.name="CivicPortReturn"
	_quarter.feature_id="CivicPortReturn"
	_quarter.position=Vector3(-38.5,6,-116)
	_quarter.rotation.y=PI
	_quarter.radius=2.4
	_quarter.minimum_width=4.5
	_quarter.width=4.5
	_quarter.deck_length=2.0
	_quarter.build_access=false
	world.add_child(_quarter)
	# Reuse the existing mineral/steel finishes; no extra texture set or light.
	for mesh: Node in _quarter.find_children("*","MeshInstance3D",true,false):
		mesh.material_override=world._materials["iron" if String(mesh.name) in ["ContinuousSteelCoping","EdgeTrim"] else "skate_concrete"]
	world.set_meta("pt24_civic_port_return",true)


func _civic_frontage_return(foundation: StaticBody3D) -> void:
	# The existing facade ends at X-36. Close the remaining east gutter to the
	# civic fence, before the retained landing ends. Both north-going recovery
	# shoulders remain open. Its foot rests on this foundation and the adjoining
	# Y6 civic forecourt; no catch floor extends into the lower lawn.
	var collision:=CollisionShape3D.new()
	collision.name="CivicPortFrontageReturn"
	var shape:=BoxShape3D.new()
	shape.size=Vector3(1.5,2.4,0.4)
	collision.shape=shape
	collision.transform=foundation.transform.affine_inverse()*Transform3D(Basis.IDENTITY,Vector3(-35.55,7.2,-109))
	foundation.add_child(collision)
	for child: Node in foundation.get_children():
		if not child is MeshInstance3D or child.mesh==null: continue
		var surface:=SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		surface.set_smooth_group(-1)
		for vertex: Vector3 in child.mesh.get_faces(): surface.add_vertex(vertex)
		var box:=BoxMesh.new()
		box.size=shape.size
		for vertex: Vector3 in box.get_faces():
			surface.add_vertex(child.transform.affine_inverse()*(collision.transform*vertex))
		surface.generate_normals()
		child.mesh=surface.commit()
		break
	foundation.set_meta("pt24_frontage_return",{
		"bounds":AABB(Vector3(-36.3,6,-109.2),Vector3(1.5,2.4,0.4)),
		"added_triangles":12,"added_shapes":1,"added_bodies":0,
		"added_draw_surfaces":0,"added_textures":0,"added_lights":0})


func _add_route(world: Node3D,id: String,label: String,local_points: Array) -> void:
	var points := PackedVector3Array()
	for at: Vector3 in local_points: points.append(world.to_global(at))
	routes.append({"id":id,"label":label,"points":points,"requires_jump":false})
