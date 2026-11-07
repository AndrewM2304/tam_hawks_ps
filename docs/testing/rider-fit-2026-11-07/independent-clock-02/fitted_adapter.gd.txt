extends RefCounted
## Private admission observer; not runtime code and not an accepted test adapter.
## Format bounds authenticate imported identity. Contact limits remain unchanged.
const POSITION_BOUND := 0.000001
const UV_BOUND := 0.000002
const NORMAL_BOUND := 0.0002
const WEIGHT_BOUND := 1.0 / 65535.0 + 0.000001
static var largest_neck_witness: Dictionary={"current":{},"rendered":{}}

static func prepare(rig: RefCounted, reference: Dictionary) -> Dictionary:
	var data := {"rig":rig,"reference":reference,"skeleton":rig._garments.skeleton,
		"parts":{},"errors":[],"head":{},"waist_edges":{},"neck_ids":{}}
	var skeleton: Skeleton3D = data.skeleton
	if skeleton.get_bone_count()!=reference.bone_names.size():
		data.errors.append("bone count")
	for i: int in reference.bone_names.size():
		if i>=skeleton.get_bone_count() or skeleton.get_bone_name(i)!=StringName(reference.bone_names[i]):
			data.errors.append("bone order "+str(i))
	for name: String in ["SkinnedJacket","SkinnedTrousers","UpperChest"]:
		var mesh: MeshInstance3D = rig._rider.get_node_or_null(name)
		if mesh==null:
			data.errors.append("missing native mesh "+name)
			continue
		data.parts[name]=_index(mesh,skeleton,reference.parts[name],reference,data.errors)
	if data.errors.is_empty():
		_validate_edges(data)
		_index_head(data)
	return data

static func _index(mesh: MeshInstance3D,skeleton: Skeleton3D,expected: Dictionary,reference: Dictionary,errors: Array) -> Dictionary:
	var result := {"mesh":mesh,"records":[],"by_source":{},"triangles":[],"source_triangles":{},"expected_seen":{},"weight_max_delta":0.0}
	if mesh.skin==null or mesh.mesh==null or mesh.get_node_or_null(mesh.skeleton)!=skeleton:
		errors.append("missing native Skin/Mesh or foreign skeleton "+str(mesh.name))
		return result
	if mesh.skin.get_bind_count()!=reference.bone_names.size():
		errors.append("bind count "+str(mesh.name))
		return result
	for bind: int in mesh.skin.get_bind_count():
		var bone := _bone(mesh.skin,skeleton,bind)
		if bone<0 or skeleton.get_bone_name(bone)!=StringName(reference.bone_names[bind]):
			errors.append("invalid binding "+str(mesh.name)+" "+str(bind))
			return result
		if _transform_error(mesh.skin.get_bind_pose(bind),_matrix(reference.binds[bind]))>POSITION_BOUND:
			errors.append("unexpected original inverse bind "+str(mesh.name)+" "+str(bind))
			return result
	var buckets: Dictionary = {}
	for i: int in expected.source_ids.size():
		var key := int(floor(float(expected.attributes.POSITION[i][0])*10000.0))
		if not buckets.has(key):buckets[key]=[]
		buckets[key].append(i)
	for surface: int in mesh.mesh.get_surface_count():
		if mesh.mesh.surface_get_primitive_type(surface)!=Mesh.PRIMITIVE_TRIANGLES:
			errors.append("nontriangle native source")
			return result
		var arrays: Array = mesh.mesh.surface_get_arrays(surface)
		var points: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
		var uv: PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV]
		var bones: PackedInt32Array=arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array=arrays[Mesh.ARRAY_WEIGHTS]
		var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
		if points.is_empty() or bones.size()%points.size()!=0 or weights.size()!=bones.size() or normals.size()!=points.size() or uv.size()!=points.size():
			errors.append("malformed native arrays")
			return result
		var stride: int=bones.size()/points.size()
		if stride not in [4,8] or indices.is_empty() or indices.size()%3!=0:
			errors.append("malformed native stride/indices")
			return result
		var offset: int=result.records.size()
		for i: int in points.size():
			var actual_weights := _weights(mesh.skin,skeleton,bones,weights,i,stride)
			if actual_weights.is_empty() or not points[i].is_finite() or not normals[i].is_finite() or not uv[i].is_finite():
				errors.append("invalid native weighted vertex "+str(i))
				return result
			var candidates: Array[int]=[]
			var bucket := int(floor(points[i].x*10000.0))
			for adjacent: int in [-1,0,1]:
				for j: int in buckets.get(bucket+adjacent,[]):
					if points[i].distance_to(_v(expected.attributes.POSITION[j]))>POSITION_BOUND:continue
					var tex: Array=expected.attributes.TEXCOORD_0[j]
					if uv[i].distance_to(Vector2(float(tex[0]),float(tex[1])))>UV_BOUND:continue
					if normals[i].distance_to(_v(expected.attributes.NORMAL[j]))>NORMAL_BOUND:continue
					var authored: Dictionary={}
					for k: int in expected.attributes.JOINTS_0[j].size():
						var w: float=expected.attributes.WEIGHTS_0[j][k]
						if w>0.0:
							var name: String=reference.bone_names[int(expected.attributes.JOINTS_0[j][k])]
							authored[name]=float(authored.get(name,0.0))+w
					if _weights_delta(actual_weights,authored)>WEIGHT_BOUND:continue
					candidates.append(j)
			if candidates.is_empty():
				errors.append("unmapped native vertex "+str(mesh.name)+" "+str(surface)+":"+str(i))
				return result
			var source: int=expected.source_ids[candidates[0]]
			for candidate: int in candidates:
				if int(expected.source_ids[candidate])!=source:
					errors.append("ambiguous source identity")
					return result
				result.expected_seen[candidate]=true
			var record := {"point":points[i],"normal":normals[i],"uv":uv[i],"source":source,
				"bones":bones.slice(i*stride,(i+1)*stride),"weights":weights.slice(i*stride,(i+1)*stride)}
			result.records.append(record)
			if not result.by_source.has(source):result.by_source[source]=[]
			result.by_source[source].append(offset+i)
		for i: int in range(0,indices.size(),3):
			var triangle: Array[int]=[]
			var ids: Array[int]=[]
			for k: int in 3:
				var index: int=indices[i+k]
				if index<0 or index>=points.size():
					errors.append("out of range native triangle")
					return result
				triangle.append(offset+index)
				ids.append(result.records[offset+index].source)
			result.triangles.append(triangle)
			var key := _triangle_key(ids)
			result.source_triangles[key]=int(result.source_triangles.get(key,0))+1
	var authored_triangles: Dictionary={}
	for triangle: Array in expected.source_triangles:
		var key := _triangle_key([triangle[2],triangle[1],triangle[0]])
		authored_triangles[key]=int(authored_triangles.get(key,0))+1
	if result.source_triangles!=authored_triangles or result.expected_seen.size()!=expected.source_ids.size():
		errors.append("incomplete native source topology "+str(mesh.name))
	return result

static func _validate_edges(data: Dictionary) -> void:
	var edges: Array=data.reference.waist_edges
	if edges.size()!=100 or data.reference.waist_positions.size()!=100:
		data.errors.append("missing complete100edge declaration")
		return
	for part_name: String in ["SkinnedJacket","SkinnedTrousers"]:
		var part: Dictionary=data.parts[part_name]
		var counts: Dictionary={}
		for triangle: Array in part.triangles:
			for k: int in 3:
				var a: int=part.records[triangle[k]].source
				var b: int=part.records[triangle[(k+1)%3]].source
				var key := _key([a,b])
				counts[key]=int(counts.get(key,0))+1
		for i: int in edges.size():
			var edge: Array=edges[i]
			var key := _key(edge)
			if data.waist_edges.has(key) and part_name=="SkinnedJacket":
				data.errors.append("duplicate waist edge")
			if int(counts.get(key,0))!=1:
				data.errors.append("missing/wrong actual boundary edge "+part_name+" "+key)
			for k: int in 2:
				var id: int=edge[k]
				if not part.by_source.has(id):
					data.errors.append("missing waist source endpoint")
					continue
				for index: int in part.by_source[id]:
					if part.records[index].point.distance_to(_v(data.reference.waist_positions[i][k]))>POSITION_BOUND:
						data.errors.append("wrong waist source position")
			data.waist_edges[key]=edge
	if data.waist_edges.size()!=100:data.errors.append("waist edge completeness")
	# Both draws must retain every source seam's native weights and normals.
	var jacket: Dictionary=data.parts.SkinnedJacket
	var trousers: Dictionary=data.parts.SkinnedTrousers
	for edge: Array in data.waist_edges.values():
		for id: int in edge:
			if not jacket.by_source.has(id) or not trousers.by_source.has(id):continue
			for a: int in jacket.by_source[id]:
				for b: int in trousers.by_source[id]:
					var one: Dictionary=jacket.records[a]
					var two: Dictionary=trousers.records[b]
					if one.normal.distance_to(two.normal)>0.000001 or _weights_delta(_record_weights(jacket.mesh,data.skeleton,one),_record_weights(trousers.mesh,data.skeleton,two))>0.0000001:
						data.errors.append("native cross-draw seam normal/weight mismatch "+str(id))

static func _index_head(data: Dictionary) -> void:
	var head: MeshInstance3D=data.rig._head.get_node("AnatomicalHead")
	var imported: Mesh=load("res://game/art/rider/fitted_head.obj")
	var compressed: bool=(imported.surface_get_format(0)&Mesh.ARRAY_FLAG_COMPRESS_ATTRIBUTES)!=0
	var position_bound: float=maxf(POSITION_BOUND,imported.get_aabb().size.length()/65535.0+0.0000002) if compressed else POSITION_BOUND
	var uv_bound: float=sqrt(2.0)/65535.0+0.0000002 if compressed else UV_BOUND
	data.head={"mesh":head,"by_source":{},"import_compressed":compressed,"identity_position_bound_m":position_bound,"identity_uv_bound":uv_bound,"surfaces":[],"authenticated_uv_records":0,"native_boundary_edges":{}}
	var chest: Dictionary=data.parts.UpperChest
	for surface: int in head.mesh.get_surface_count():
		if head.mesh.surface_get_primitive_type(surface)!=Mesh.PRIMITIVE_TRIANGLES:
			data.errors.append("nontriangle native Head")
			return
		var arrays: Array=head.mesh.surface_get_arrays(surface)
		var points: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var tex: PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV]
		var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
		var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
		if points.is_empty() or tex.size()!=points.size() or normals.size()!=points.size() or indices.is_empty() or indices.size()%3!=0:
			data.errors.append("malformed native Head arrays")
			return
		var used: Dictionary={}
		for index: int in indices:
			if index<0 or index>=points.size() or not points[index].is_finite() or not tex[index].is_finite() or not normals[index].is_finite():
				data.errors.append("invalid native Head index/finite attribute")
				return
			used[index]=true
		data.head.surfaces.append({"points":points,"uv":tex,"indices":indices,"used":used,"source":{}})
	for item: Dictionary in data.reference.head_rim:
		var id: int=item.source_id
		var local:=_v(item.local)
		var found:=false
		for surface: Dictionary in data.head.surfaces:
			for index: int in surface.used:
				if surface.points[index].distance_to(local)<=position_bound and surface.uv[index].distance_to(Vector2(float(item.uv[0]),1.0-float(item.uv[1])))<=uv_bound:
					if surface.source.has(index) and int(surface.source[index])!=id:
						data.errors.append("ambiguous native Head seam source")
						return
					surface.source[index]=id
					if not data.head.by_source.has(id):data.head.by_source[id]=[]
					data.head.by_source[id].append(surface.points[index])
					found=true
		if not found or not chest.by_source.has(id):
			data.errors.append("missing INDEXED native Head/chest seam identity "+str(id))
		else:
			data.neck_ids[id]=true
			data.head.authenticated_uv_records+=1
	var counts: Dictionary={}
	for surface: Dictionary in data.head.surfaces:
		for i: int in range(0,surface.indices.size(),3):
			for k: int in 3:
				var first: int=surface.indices[i+k]
				var second: int=surface.indices[i+(k+1)%3]
				if surface.source.has(first) and surface.source.has(second):
					var key:=_key([surface.source[first],surface.source[second]])
					counts[key]=int(counts.get(key,0))+1
	for key: String in counts:
		if counts[key]==1:data.head.native_boundary_edges[key]=true
	var expected: Dictionary={}
	for edge: Array in data.reference.head_edges:expected[_key(edge)]=true
	if data.head.native_boundary_edges!=expected or expected.size()!=46 or data.neck_ids.size()!=46 or data.head.authenticated_uv_records!=47:
		data.errors.append("incomplete actual46edge/47UV native Head boundary")
	var chest_edges: Dictionary={}
	for triangle: Array in chest.triangles:
		for k: int in 3:
			var key:=_key([chest.records[triangle[k]].source,chest.records[triangle[(k+1)%3]].source])
			chest_edges[key]=int(chest_edges.get(key,0))+1
	for key: String in expected:
		if int(chest_edges.get(key,0))!=1:data.errors.append("missing actual matching UpperChest boundary edge "+key)

static func sample(data: Dictionary,rendered: bool=false) -> Dictionary:
	var result := {"finite":data.errors.is_empty(),"maximum_waist_m":0.0,"maximum_neck_m":0.0,"waist_edges":data.waist_edges.size(),"neck_ids":data.neck_ids.size(),"joint_gap_m":0.0}
	if not result.finite:return result
	var jacket: Dictionary=data.parts.SkinnedJacket
	var trousers: Dictionary=data.parts.SkinnedTrousers
	for edge: Array in data.waist_edges.values():
		for id: int in edge:
			for a: int in jacket.by_source[id]:
				for b: int in trousers.by_source[id]:
					var pa := point(jacket.mesh,data.skeleton,jacket.records[a],rendered)
					var pb := point(trousers.mesh,data.skeleton,trousers.records[b],rendered)
					result.finite=result.finite and pa.is_finite() and pb.is_finite()
					result.maximum_waist_m=maxf(result.maximum_waist_m,pa.distance_to(pb))
	var chest: Dictionary=data.parts.UpperChest
	var head: MeshInstance3D=data.head.mesh
	var head_frame := _frame(head,rendered)
	var worst: Dictionary={}
	for id: int in data.neck_ids:
		for a: int in chest.by_source[id]:
			for q: Vector3 in data.head.by_source[id]:
				var p := point(chest.mesh,data.skeleton,chest.records[a],rendered)
				var distance:=p.distance_to(head_frame*q)
				if distance>result.maximum_neck_m:
					result.maximum_neck_m=distance
					worst={"source_id":id,"chest_point":p,"head_point":head_frame*q,"local_head":q,"chest_record":chest.records[a]}
	var skeleton: Skeleton3D=data.skeleton
	var torso := skeleton.global_transform*skeleton.get_bone_global_pose(skeleton.find_bone("torso")).origin
	var hips := skeleton.global_transform*skeleton.get_bone_global_pose(skeleton.find_bone("hips")).origin
	result.joint_gap_m=torso.distance_to(hips)
	var mode: String="rendered" if rendered else "current"
	if result.maximum_neck_m>float(largest_neck_witness[mode].get("separation_m",-1.0)) and not worst.is_empty():
		_record_interpolation_witness(data,worst,result.maximum_neck_m,mode)
	return result

static func _record_interpolation_witness(data: Dictionary,worst: Dictionary,separation: float,mode: String) -> void:
	var skeleton: Skeleton3D=data.skeleton
	var chest: MeshInstance3D=data.parts.UpperChest.mesh
	var head: MeshInstance3D=data.head.mesh
	var neck:=skeleton.find_bone("neck")
	var bind:=-1
	for i: int in chest.skin.get_bind_count():
		if _bone(chest.skin,skeleton,i)==neck:bind=i
	var palette: Variant=null
	if DisplayServer.get_name()!="headless":
		var reference: SkinReference=skeleton.register_skin(chest.skin)
		palette=_rows(RenderingServer.skeleton_bone_get_transform(reference.get_skeleton(),bind))
	var frames: Dictionary={}
	for pair: Array in [["head",head],["chest_model",chest],["skeleton",skeleton],["rider",data.rig._rider],["board",data.rig._board]]:
		var node: Node3D=pair[1]
		frames[pair[0]]={"current":_rows(node.global_transform),"model_interpolated":_rows(node.get_global_transform_interpolated()),"interpolation_mode":node.physics_interpolation_mode,"interpolation_enabled":node.is_physics_interpolated_and_enabled()}
	largest_neck_witness[mode]={"separation_m":separation,"source_id":worst.source_id,"chest_point":_xyz(worst.chest_point),"head_point":_xyz(worst.head_point),"local_head":_xyz(worst.local_head),"physics_frame":Engine.get_physics_frames(),"process_frame":Engine.get_process_frames(),"interpolation_fraction":Engine.get_physics_interpolation_fraction(),"inside_physics_frame":Engine.is_in_physics_frame(),"frames":frames,"current_neck_pose":_rows(skeleton.get_bone_global_pose(neck)),"neck_inverse_bind":_rows(chest.skin.get_bind_pose(bind)),"RenderingServer_skin_palette":palette,"display":DisplayServer.get_name(),"grab_blend":data.rig._grab_blend,"push_blend":data.rig._push_blend,"scope":"same-readback model-interpolated CPU estimate; actual palette backend and native pixel proof must be assessed separately"}

static func _rows(transform: Transform3D) -> Array:
	return [[transform.basis.x.x,transform.basis.y.x,transform.basis.z.x,transform.origin.x],[transform.basis.x.y,transform.basis.y.y,transform.basis.z.y,transform.origin.y],[transform.basis.x.z,transform.basis.y.z,transform.basis.z.z,transform.origin.z],[0,0,0,1]]

static func _xyz(value: Vector3) -> Array:
	return [value.x,value.y,value.z]

static func point(mesh: MeshInstance3D,skeleton: Skeleton3D,record: Dictionary,rendered: bool=false) -> Vector3:
	# Match GLES/RD weighted-local-MATRIX semantics before one actual mesh model.
	var x := Vector3.ZERO
	var y := Vector3.ZERO
	var z := Vector3.ZERO
	var origin := Vector3.ZERO
	for i: int in record.bones.size():
		var w: float=record.weights[i]
		if w<=0.0:continue
		var bind: int=record.bones[i]
		var bone := _bone(mesh.skin,skeleton,bind)
		if bone<0:return Vector3(INF,INF,INF)
		var transform := skeleton.get_bone_global_pose(bone)*mesh.skin.get_bind_pose(bind)
		x+=transform.basis.x*w
		y+=transform.basis.y*w
		z+=transform.basis.z*w
		origin+=transform.origin*w
	var p: Vector3=record.point
	return _frame(mesh,rendered)*(x*p.x+y*p.y+z*p.z+origin)

static func _frame(mesh: MeshInstance3D,rendered: bool) -> Transform3D:
	return mesh.get_global_transform_interpolated() if rendered else mesh.global_transform

static func _weights(skin: Skin,skeleton: Skeleton3D,bones: PackedInt32Array,weights: PackedFloat32Array,index: int,stride: int) -> Dictionary:
	var result: Dictionary={}
	var sum := 0.0
	for k: int in stride:
		var w: float=weights[index*stride+k]
		if not is_finite(w) or w<0.0:return {}
		if w==0.0:continue
		var bone := _bone(skin,skeleton,bones[index*stride+k])
		if bone<0:return {}
		var name := String(skeleton.get_bone_name(bone))
		result[name]=float(result.get(name,0.0))+w
		sum+=w
	if absf(sum-1.0)>stride/65535.0+0.000001:return {}
	return result

static func _weights_delta(a: Dictionary,b: Dictionary) -> float:
	var delta := 0.0
	for name: String in a:delta=maxf(delta,absf(float(a[name])-float(b.get(name,0.0))))
	for name: String in b:delta=maxf(delta,absf(float(b[name])-float(a.get(name,0.0))))
	return delta

static func _record_weights(mesh: MeshInstance3D,skeleton: Skeleton3D,record: Dictionary) -> Dictionary:
	return _weights(mesh.skin,skeleton,record.bones,record.weights,0,record.bones.size())

static func legacy_prepare(rig: RefCounted,reference: Dictionary) -> Dictionary:
	var data := prepare(rig,reference)
	data["fitted"]=true
	data["jacket"]=rig._rider.get_node("SkinnedJacket")
	data["trousers"]=rig._rider.get_node("SkinnedTrousers")
	data["hem"]=[]
	data["waist"]=[]
	data["thigh"]=[]
	data["surface_triangles_by_source"]={}
	if not data.errors.is_empty():return data
	var shirt: Dictionary=data.parts.SkinnedJacket
	var pants: Dictionary=data.parts.SkinnedTrousers
	var ids: Dictionary={}
	for edge: Array in data.waist_edges.values():
		for id: int in edge:ids[id]=true
	for id: int in ids:
		for index: int in shirt.by_source[id]:data.hem.append(shirt.records[index])
		for index: int in pants.by_source[id]:data.waist.append(pants.records[index])
		data.surface_triangles_by_source[id]=[]
	for triangle: Array in pants.triangles:
		var incident: Dictionary={}
		for index: int in triangle:
			var id: int=pants.records[index].source
			if ids.has(id):incident[id]=true
		for id: int in incident:data.surface_triangles_by_source[id].append(triangle)
	# The legacy thigh centre was only a finite-geometry witness. Preserve it
	# using actual source vertices with strongest native left/right thigh weight.
	for name: String in ["left_thigh","right_thigh"]:
		var largest:=-1.0
		var selected: Dictionary={}
		for record: Dictionary in pants.records:
			var weights := _record_weights(pants.mesh,data.skeleton,record)
			var weight: float=weights.get(name,0.0)
			if weight>largest:
				largest=weight
				selected=record
		if largest>0.0:data.thigh.append(selected)
	for id: int in ids:
		if data.surface_triangles_by_source[id].is_empty():data.errors.append("missing incident native trouser surface "+str(id))
	return data

static func legacy_sample(rider: Node3D,data: Dictionary,rendered: bool) -> Dictionary:
	var current := sample(data,rendered)
	var hem := _centre(data.jacket,data.skeleton,data.hem,rendered)
	var waist := _centre(data.trousers,data.skeleton,data.waist,rendered)
	var thigh := _centre(data.trousers,data.skeleton,data.thigh,rendered)
	var head: MeshInstance3D=data.rig._head.get_node("AnatomicalHead")
	var gap:=surface_gap(data,rendered) if rider is CharacterBody3D and rider.bailing and current.finite else 0.0
	return {"hem":hem,"waist":waist,"thigh":thigh,"seam":current.maximum_waist_m,"joint_gap":current.joint_gap_m,
		"neck_gap":current.maximum_neck_m,"anatomical_neck_vertices":data.reference.head_rim.size(),"surface_gap":gap,
		"head":_frame(head,rendered)*head.mesh.get_aabb().get_center(),"finite":current.finite and hem.is_finite() and waist.is_finite() and thigh.is_finite(),
		"grab_blend":data.rig._grab_blend,"body":rider.global_position,"bail":rider.bail_phase if rider is CharacterBody3D else "rig_fixture","rendered":rendered}

static func _centre(mesh: MeshInstance3D,skeleton: Skeleton3D,records: Array,rendered: bool) -> Vector3:
	var centre:=Vector3.ZERO
	for record: Dictionary in records:centre+=point(mesh,skeleton,record,rendered)
	return centre/maxi(1,records.size())

static func surface_gap(data: Dictionary,rendered: bool) -> float:
	# Every authenticated hem endpoint against its actual indexed incident pants
	# triangles, deformed per vertex with full native blended skinning.
	var pants: Dictionary=data.parts.SkinnedTrousers
	var vertices: Dictionary={}
	var largest:=0.0
	for record: Dictionary in data.hem:
		var p:=point(data.jacket,data.skeleton,record,rendered)
		var nearest:=INF
		for triangle: Array in data.surface_triangles_by_source[record.source]:
			for index: int in triangle:
				if not vertices.has(index):vertices[index]=point(pants.mesh,data.skeleton,pants.records[index],rendered)
			nearest=minf(nearest,_triangle_distance(p,vertices[triangle[0]],vertices[triangle[1]],vertices[triangle[2]]))
			if nearest<=0.000001:break
		largest=maxf(largest,nearest)
	return largest

static func _triangle_distance(p: Vector3,a: Vector3,b: Vector3,c: Vector3) -> float:
	var normal:=(b-a).cross(c-a)
	if normal.length_squared()<1e-20:
		return minf(p.distance_to(a),minf(p.distance_to(b),p.distance_to(c)))
	normal=normal.normalized()
	var q:=p-normal*(p-a).dot(normal)
	if (b-a).cross(q-a).dot(normal)>=-0.0000001 and (c-b).cross(q-b).dot(normal)>=-0.0000001 and (a-c).cross(q-c).dot(normal)>=-0.0000001:return absf((p-a).dot(normal))
	return minf(p.distance_to(Geometry3D.get_closest_point_to_segment(p,a,b)),minf(p.distance_to(Geometry3D.get_closest_point_to_segment(p,b,c)),p.distance_to(Geometry3D.get_closest_point_to_segment(p,c,a))))

static func pure_torso_points(data: Dictionary) -> Array[Vector3]:
	var result: Array[Vector3]=[]
	for record: Dictionary in data.parts.SkinnedJacket.records:
		var weights:=_record_weights(data.jacket,data.skeleton,record)
		if float(weights.get("torso",0.0))>.999:result.append(point(data.jacket,data.skeleton,record))
	return result

static func pure_torso_shift(data: Dictionary,before: Array[Vector3]) -> float:
	var after:=pure_torso_points(data)
	if after.size()!=before.size() or after.is_empty():return 0.0
	var largest:=0.0
	for i: int in after.size():largest=maxf(largest,after[i].distance_to(before[i]))
	return largest

static func _bone(skin: Skin,skeleton: Skeleton3D,bind: int) -> int:
	if bind<0 or bind>=skin.get_bind_count():return -1
	var name:=String(skin.get_bind_name(bind))
	if not name.is_empty():return skeleton.find_bone(name)
	var bone := skin.get_bind_bone(bind)
	return bone if bone>=0 and bone<skeleton.get_bone_count() else -1

static func _matrix(rows: Array) -> Transform3D:
	return Transform3D(Basis(Vector3(rows[0][0],rows[1][0],rows[2][0]),Vector3(rows[0][1],rows[1][1],rows[2][1]),Vector3(rows[0][2],rows[1][2],rows[2][2])),Vector3(rows[0][3],rows[1][3],rows[2][3]))

static func _transform_error(a: Transform3D,b: Transform3D) -> float:
	return maxf(a.origin.distance_to(b.origin),maxf(a.basis.x.distance_to(b.basis.x),maxf(a.basis.y.distance_to(b.basis.y),a.basis.z.distance_to(b.basis.z))))

static func _triangle_key(values: Array) -> String:
	# Native GLTF importer explicitly reverses CCW to Godot CW; cyclic
	# rotation preserves a face, reversal does not.
	var a:int=values[0]
	var b:int=values[1]
	var c:int=values[2]
	if a<=b and a<=c:return str([a,b,c])
	if b<=a and b<=c:return str([b,c,a])
	return str([c,a,b])

static func _key(values: Array) -> String:
	var sorted: Array[int]=[]
	for value: Variant in values:sorted.append(int(value))
	sorted.sort()
	return str(sorted)

static func _v(a: Array) -> Vector3:
	return Vector3(float(a[0]),float(a[1]),float(a[2]))
