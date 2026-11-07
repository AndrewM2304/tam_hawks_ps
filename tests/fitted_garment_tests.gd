extends RefCounted
## Source-authenticated native fitted rig and bounded contact-cache regressions.
## Original BodyAttachment/WallManual/ObstacleArm trajectories run separately.
## Numeric agreement does not accept visual realism or target-Mac performance.
const Classic=preload("res://tests/classic_tricks_integration_tests.gd")
const Adapter=preload("res://tests/fitted_adapter.gd")
const ArmFit=preload("res://game/player/skater_obstacle_arm_fit.gd")
const Hull=preload("res://game/player/shoe_support_hull.gd")

static func run(tree:SceneTree,check:Callable)->void:
	_math(check)
	var metrics:Dictionary={}
	Classic.Setup.register_actions()
	var reference:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fitted-reference.json"))
	check.call(FileAccess.get_sha256("res://game/art/rider/fitted_outfit.glb")==reference.asset_sha256,"exact selected GLB hash")
	check.call(FileAccess.get_sha256("res://game/art/rider/fitted_landmarks.json")==reference.metadata_sha256,"exact source semantic metadata hash")
	check.call(FileAccess.get_sha256("res://game/art/rider/fitted_head.obj")==reference.head_asset_sha256,"exact original source-authenticated Head hash")
	var fixture:Dictionary=await Classic._fixture(tree)
	var rider:CharacterBody3D=fixture.rider
	rider.set_physics_process(false)
	var rig:RefCounted=rider._visual_rig
	var data:Dictionary=Adapter.prepare(rig,reference)
	metrics.mapping_errors=data.errors
	if data.head.has("identity_position_bound_m"):metrics.head_import={"compressed":data.head.import_compressed,"position_identity_bound_m":data.head.identity_position_bound_m,"uv_identity_bound":data.head.identity_uv_bound}
	check.call(data.errors.is_empty(),"all actual native arrays/bindings/topology authenticate source identity")
	if not data.errors.is_empty():
		print("MAPPING_DIAGNOSTIC ",data.errors)
		await Classic._dispose(tree,fixture)
		return
	check.call(data.waist_edges.size()==100 and data.neck_ids.size()==46 and data.head.authenticated_uv_records==47 and data.head.native_boundary_edges.size()==46,"all100 actual waist edges and46 neck identities complete")
	for name:String in ["SkinnedJacket","SkinnedTrousers","UpperChest"]:
		metrics[name]={"native_vertices":data.parts[name].records.size(),"source_vertices":data.parts[name].by_source.size(),"triangles":data.parts[name].triangles.size()}
	var state:Dictionary={"airborne":false,"grab":false,"flip":false,"manual":false,"grind":false,"speed":0.0,"push":false,"brake":false}
	var peak_waist:=0.0
	var peak_neck:=0.0
	for pose:Dictionary in [{},{"look_direction":Vector3.LEFT},{"look_direction":Vector3.RIGHT},{"speed":7.0,"push":true},{"crouch":1.0},{"airborne":true,"grab":true,"grab_id":"melon_grab"},{"airborne":true,"grab":true,"grab_id":"method_grab"},{"manual":true,"manual_balance":0.9},{"bail":1.0}]:
		var active:Dictionary=state.duplicate()
		active.merge(pose,true)
		for tick:int in 30:rig.animate(1.0/60.0,active)
		var sample:Dictionary=Adapter.sample(data)
		peak_waist=maxf(peak_waist,sample.maximum_waist_m)
		peak_neck=maxf(peak_neck,sample.maximum_neck_m)
		check.call(sample.finite and sample.maximum_waist_m<.08 and sample.maximum_neck_m<.05,"actual multi-bone source seam remains within original limits "+str(pose))
	metrics.pose_peaks={"waist_m":peak_waist,"neck_m":peak_neck,"source":"direct visual-pose diagnostics; not controller trajectory or moving review"}
	for tick:int in 30:rig.animate(1.0/60.0,state)
	var neutral:Dictionary=Adapter.sample(data)
	var jacket:MeshInstance3D=data.parts.SkinnedJacket.mesh
	var original:Skin=jacket.skin
	var skeleton:Skeleton3D=data.skeleton
	var torso_bind:=-1
	for bind:int in original.get_bind_count():
		if skeleton.get_bone_name(Adapter._bone(original,skeleton,bind))==&"torso":torso_bind=bind
	check.call(torso_bind>=0,"actual named torso binding exists")
	var corrupt:Skin=original.duplicate(true) as Skin
	var wrong:Transform3D=corrupt.get_bind_pose(torso_bind)
	wrong.origin.y-=.8
	corrupt.set_bind_pose(torso_bind,wrong)
	var before:Array[Vector3]=[]
	for record:Dictionary in data.parts.SkinnedJacket.records:before.append(Adapter.point(jacket,skeleton,record))
	jacket.skin=corrupt
	var detached:Dictionary=Adapter.sample(data)
	var upper_shift:=0.0
	for i:int in data.parts.SkinnedJacket.records.size():
		var record:Dictionary=data.parts.SkinnedJacket.records[i]
		var torso_weight:=0.0
		for k:int in record.bones.size():
			if record.bones[k]==torso_bind:torso_weight+=record.weights[k]
		if torso_weight>.999:upper_shift=maxf(upper_shift,before[i].distance_to(Adapter.point(jacket,skeleton,record)))
	check.call(detached.maximum_waist_m>.08 and detached.joint_gap_m==neutral.joint_gap_m,"same800mm torso corruption exceeds original80mm limit without node joint change")
	check.call(upper_shift>.5,"same800mm corruption retains pure upper-shirt over500mm sentinel")
	metrics.detachment800={"waist_m":detached.maximum_waist_m,"pure_upper_shift_m":upper_shift,"joint_gap_unchanged":detached.joint_gap_m==neutral.joint_gap_m}
	jacket.skin=original
	corrupt=original.duplicate(true) as Skin
	for bind:int in corrupt.get_bind_count():
		var pose:Transform3D=skeleton.get_bone_global_pose(Adapter._bone(corrupt,skeleton,bind))
		# Every weighted LOCAL palette receives the same250mm translation.
		# Preserve raw native sums; displacement is250mm times decoded mass.
		wrong=pose.affine_inverse()*Transform3D(Basis.IDENTITY,Vector3(.25,0,0))*pose*corrupt.get_bind_pose(bind)
		corrupt.set_bind_pose(bind,wrong)
	jacket.skin=corrupt
	var translated:Dictionary=Adapter.sample(data)
	check.call(absf(translated.maximum_waist_m-.25)<.00002 and translated.joint_gap_m==neutral.joint_gap_m,"uniform250mm all-bind translation detected despite healthy control nodes")
	jacket.skin=original
	var invalid:Dictionary=reference.duplicate(true)
	invalid.waist_edges.pop_back()
	check.call(not Adapter.prepare(rig,invalid).errors.is_empty(),"missing authenticated seam edge fails closed")
	invalid=reference.duplicate(true)
	invalid.waist_edges[0][0]=999999
	check.call(not Adapter.prepare(rig,invalid).errors.is_empty(),"wrong authenticated seam source identity fails closed")
	corrupt=original.duplicate(true) as Skin
	corrupt.set_bind_name(torso_bind,"")
	corrupt.set_bind_bone(torso_bind,999999)
	jacket.skin=corrupt
	check.call(not Adapter.prepare(rig,reference).errors.is_empty(),"out-of-range actual native Skin binding fails before bone reads")
	jacket.skin=original
	var selected:Dictionary={}
	for record:Dictionary in data.parts.SkinnedJacket.records:
		var sum:=0.0
		for w:float in record.weights:sum+=w
		if sum<.999999:
			selected=record
			break
	check.call(not selected.is_empty(),"actual decoded native nonunit UNORM16 witness exists")
	if not selected.is_empty():
		var model:Transform3D=jacket.global_transform
		var initial:=Adapter.point(jacket,skeleton,selected)
		jacket.global_position+=Vector3(137,0,-106)
		var moved:=Adapter.point(jacket,skeleton,selected)
		check.call(moved.distance_to(initial+Vector3(137,0,-106))<.00003,"far-origin unequal mesh/skeleton model translation applied once with raw native weights")
		jacket.global_transform=model
	var fit:=ArmFit.new()
	fit.prepare(rider)
	check.call(fit.supported and fit.arms.size()==2 and fit.cache_bytes<=512*1024,"fresh fitted actual arm cache supports source geometry within512KiB")
	var outside:=0
	var counts:Array=[]
	for arm:Dictionary in fit.arms:
		var bounds:AABB=fit._bounds(arm,{},arm.hand.global_transform)
		var vertices:int=arm.points.size()
		counts.append(vertices)
		for i:int in vertices:
			var record:Dictionary={"point":arm.points[i],"bones":arm.binds.slice(arm.offsets[i],arm.offsets[i+1]),"weights":arm.weights.slice(arm.offsets[i],arm.offsets[i+1])}
			if not bounds.grow(.00001).has_point(Adapter.point(jacket,skeleton,record)):outside+=1
	check.call(outside==0,"actual fitted arm incident endpoints remain inside native cached LBS envelopes")
	metrics.contact_cache={"vertices":counts,"packed_bytes":fit.cache_bytes,"outside":outside,"scope":"cache geometry only; real wall trajectories and12query limits remain separate"}
	await load("res://tests/per_leg_sole_contract.gd").run(tree,check)
	await load("res://tests/full_shoe_support_contract.gd").run(tree,check)
	_topology_negatives(rig,reference,check)
	await Classic._dispose(tree,fixture)
	DirAccess.make_dir_recursive_absolute("res://.local")
	var file:=FileAccess.open("res://.local/fitted-rig-metrics.json",FileAccess.WRITE)
	if file==null:
		push_error("Could not open fitted native metrics output")
		return
	file.store_string(JSON.stringify(metrics,"\t",true,true))
	file.close()
	print("FITTED_GARMENT_METRICS ",JSON.stringify(metrics))

static func _topology_negatives(rig:RefCounted,reference:Dictionary,check:Callable)->void:
	var findings:Dictionary={}
	var data:Dictionary=Adapter.prepare(rig,reference)
	check.call(data.errors.is_empty(),"actual source-authenticated positive11bone mesh/Head/edges")
	if data.errors.is_empty():
		for orphan:bool in [false,true]:
			var head:MeshInstance3D=data.head.mesh
			var original:Mesh=head.mesh
			var changed:=ArrayMesh.new()
			var removed:=0
			var edge:Array=reference.head_edges[0]
			for surface:int in original.get_surface_count():
				var arrays:Array=original.surface_get_arrays(surface)
				var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
				var retained:=PackedInt32Array()
				var mapping:Dictionary=data.head.surfaces[surface].source
				for i:int in range(0,indices.size(),3):
					var sources:Array=[]
					for k:int in 3:sources.append(int(mapping.get(indices[i+k],-1)))
					var omit:bool=sources.has(int(edge[0])) if orphan else (sources.has(int(edge[0])) and sources.has(int(edge[1])))
					if omit:removed+=1
					else:
						for k:int in 3:retained.append(indices[i+k])
				arrays[Mesh.ARRAY_INDEX]=retained
				changed.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
			head.mesh=changed
			var rejected:Dictionary=Adapter.prepare(rig,reference)
			var label:String="orphan" if orphan else "missing_edge"
			findings[label]={"removed_native_triangles":removed,"errors":rejected.errors,"all_original_vertex_arrays_retained":true}
			check.call(removed>0 and not rejected.errors.is_empty(),"actual indexed Head "+label+" fails despite retained matching orphan vertex arrays")
			head.mesh=original
		var chest:MeshInstance3D=data.parts.UpperChest.mesh
		var original:Mesh=chest.mesh
		var clone:=ArrayMesh.new()
		for surface:int in original.get_surface_count():clone.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,original.surface_get_arrays(surface))
		chest.mesh=clone
		var cloned:Dictionary=Adapter.prepare(rig,reference)
		findings.clone_errors=cloned.errors
		check.call(cloned.errors.is_empty(),"native buffer reconstruction control preserves source admission before winding change")
		chest.mesh=original
		var flipped:=ArrayMesh.new()
		for surface:int in original.get_surface_count():
			var arrays:Array=original.surface_get_arrays(surface)
			var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
			var first:int=indices[0]
			indices[0]=indices[1]
			indices[1]=first
			arrays[Mesh.ARRAY_INDEX]=indices
			flipped.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		chest.mesh=flipped
		var winding:Dictionary=Adapter.prepare(rig,reference)
		findings.winding_errors=winding.errors
		check.call("incomplete native source topology UpperChest" in winding.errors,"actual reversed native triangle winding fails directed source topology")
		chest.mesh=original
		check.call(Adapter.prepare(rig,reference).errors.is_empty(),"restored actual native resources authenticate again")

static func _math(check:Callable)->void:
	var product:Array[float]=Hull._product(1.5,1.25)
	check.call(product.size()>0 and product[-1]==1.875,"shoe math: actual typed expansion return executes")
	var grown:Array[float]=Hull._grow(product,0.125)
	check.call(grown.size()>0 and grown[-1]==2.0,"shoe math: actual typed expansion sum executes")
	var a:=Vector3.ZERO;var b:=Vector3.RIGHT;var c:=Vector3.UP
	check.call(Hull._side(a,b,c,Vector3(0.25,0.25,0.0))==0.0,"shoe math: exact coplanar adaptive path executes")
	check.call(Hull._side(a,b,c,Vector3(0.25,0.25,0.00000000001))>0.0,"shoe math: positive subnanometre source side retained")
	check.call(Hull._side(a,c,b,Vector3(0.25,0.25,0.00000000001))<0.0,"shoe math: reversed plane reverses exact sign")
	var points:=PackedVector3Array([a,b,c,Vector3.BACK,Vector3(.25,.25,0),Vector3(.25,0,.25),Vector3(0,.25,.25),Vector3(.25,.25,.25)])
	var built:Dictionary=Hull.build(points)
	check.call(built.valid and built.indices.size()==4 and built.faces.size()==12,"shoe math: tetra plus coplanar/interior source returns four exact support vertices")
	var exact_sources:bool=true
	for index:int in built.indices:exact_sources=exact_sources and index>=0 and index<4
	check.call(exact_sources,"shoe math: retained tetra extrema preserve source index provenance")
	var outside:int=0
	for index:int in range(0,built.faces.size(),3):
		var fa:Vector3=points[built.indices[built.faces[index]]]
		var fb:Vector3=points[built.indices[built.faces[index+1]]]
		var fc:Vector3=points[built.indices[built.faces[index+2]]]
		for point:Vector3 in points:
			if Hull._side(fa,fb,fc,point)>0.0:outside+=1
	check.call(outside==0,"shoe math: all actual tetra/interior/coplanar points inside oriented support faces")
	var flat:Dictionary=Hull.build(PackedVector3Array([a,b,c,Vector3(.5,.5,0)]))
	check.call(not flat.valid,"shoe math: zero-volume source is refused")
	var malformed:Dictionary=Hull.build(PackedVector3Array([a,b,c,Vector3(NAN,0,1)]))
	check.call(not malformed.valid,"shoe math: nonfinite source is refused")
	var extreme:Dictionary=Hull.build(PackedVector3Array([a,b,c,Vector3(1e-30,0,1)]))
	check.call(not extreme.valid and not extreme.coordinate_guard.supported and extreme.indices.is_empty(),"shoe math: unsupported finite exponent span earns no compact support authority")
	var huge_points:=PackedVector3Array([Vector3(2e38,2e38,2e38),Vector3(3e38,2e38,2e38),Vector3(2e38,3e38,2e38),Vector3(2e38,2e38,3e38)])
	var huge:Dictionary=Hull.build(huge_points)
	check.call(huge.coordinate_guard.supported and not huge.valid and huge.indices.is_empty() and huge.get("refusal","")=="nonfinite_tetra_centre","shoe math: finite narrow-exponent source with overflowing float32 tetra centre earns no compact authority")
