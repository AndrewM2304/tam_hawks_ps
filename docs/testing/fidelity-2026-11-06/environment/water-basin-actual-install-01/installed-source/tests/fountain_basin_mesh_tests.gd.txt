extends RefCounted
const Basin = preload("res://game/levels/art/fountain_basin_mesh.gd")

static func run(_tree: SceneTree,check: Callable) -> void:
	var source:=CylinderMesh.new()
	source.top_radius=6.2
	source.bottom_radius=6.2
	source.height=0.55
	source.radial_segments=64
	source.rings=0
	var material:=StandardMaterial3D.new()
	source.material=material
	var original:=source.surface_get_arrays(0)
	var candidate:=Basin.create(source,5.96)
	var arrays:=candidate.surface_get_arrays(0)
	var positions: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
	var tangents: PackedFloat32Array=arrays[Mesh.ARRAY_TANGENT]
	var uv: PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV]
	var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
	var rendered_original: Array=RenderingServer.mesh_surface_get_arrays(source.get_rid(),0)
	var old_positions: PackedVector3Array=rendered_original[Mesh.ARRAY_VERTEX]
	var old_normals: PackedVector3Array=rendered_original[Mesh.ARRAY_NORMAL]
	var old_tangents: PackedFloat32Array=rendered_original[Mesh.ARRAY_TANGENT]
	var old_uv: PackedVector2Array=rendered_original[Mesh.ARRAY_TEX_UV]
	var old_indices: PackedInt32Array=original[Mesh.ARRAY_INDEX]
	check.call(source.get_faces().size()/3==256 and indices.size()/3==512,"exact native topology is256to512triangles: declared+256maximum")
	check.call(candidate.get_surface_count()==1 and candidate.surface_get_material(0)==material,"one surface and exact existing material object retained")
	check.call(candidate.custom_aabb==source.get_aabb() and candidate.get_aabb().is_equal_approx(source.get_aabb()),"exact documented custom render bounds retain original exterior; computed bounds agree within native rounding")
	check.call(original==source.surface_get_arrays(0),"source native resource streams are not mutated")
	var source_prefix_unchanged:=true
	var maximum_position_delta:=0.0
	var maximum_uv_delta:=0.0
	var maximum_normal_angle:=0.0
	var maximum_tangent_angle:=0.0
	var tangent_signs_match:=true
	for index: int in old_positions.size():
		maximum_position_delta=maxf(maximum_position_delta,positions[index].distance_to(old_positions[index]))
		maximum_uv_delta=maxf(maximum_uv_delta,uv[index].distance_to(old_uv[index]))
		maximum_normal_angle=maxf(maximum_normal_angle,2.0*atan2((normals[index]-old_normals[index]).length(),(normals[index]+old_normals[index]).length()))
		var actual_tangent:=Vector3(tangents[index*4],tangents[index*4+1],tangents[index*4+2])
		var expected_tangent:=Vector3(old_tangents[index*4],old_tangents[index*4+1],old_tangents[index*4+2])
		maximum_tangent_angle=maxf(maximum_tangent_angle,2.0*atan2((actual_tangent-expected_tangent).length(),(actual_tangent+expected_tangent).length()))
		tangent_signs_match=tangent_signs_match and tangents[index*4+3]==old_tangents[index*4+3]
		source_prefix_unchanged=source_prefix_unchanged and positions[index]==old_positions[index] and normals[index]==old_normals[index] and uv[index]==old_uv[index]
		for component: int in 4:source_prefix_unchanged=source_prefix_unchanged and tangents[index*4+component]==old_tangents[index*4+component]
	check.call(maximum_position_delta==0.0 and maximum_uv_delta==0.0 and tangent_signs_match and maximum_normal_angle<=deg_to_rad(0.005) and maximum_tangent_angle<=deg_to_rad(0.005),"all original positions/UV/handedness remain exact; native packed normal/tangent deviation≤0.005degree")
	var retained:=PackedInt32Array()
	var removed_top:=0
	for offset: int in range(0,old_indices.size(),3):
		var a:=old_indices[offset]
		var b:=old_indices[offset+1]
		var c:=old_indices[offset+2]
		if old_normals[a].y>0.9999 and old_normals[b].y>0.9999 and old_normals[c].y>0.9999:removed_top+=1
		else:retained.append_array(PackedInt32Array([a,b,c]))
	check.call(removed_top==64 and retained.size()/3==192 and indices.slice(0,retained.size())==retained,"all192outer side/bottom triangles retain exact indices; only64hidden top sectors removed")
	check.call(positions.size()-old_positions.size()==323 and uv.size()==positions.size() and tangents.size()==positions.size()*4,"exact323annulus/innerwall/floor vertices retain UV/tangent streams")
	var minimum_area:=INF
	var maximum_normal_error:=0.0
	var maximum_tangent_dot:=0.0
	var baseline_maximum_tangent_dot:=0.0
	var upward:=0
	var clockwise:=true
	var top_triangles: Array[PackedVector2Array]=[]
	for offset: int in range(0,indices.size(),3):
		var a:=indices[offset]
		var b:=indices[offset+1]
		var c:=indices[offset+2]
		var cross: Vector3=(positions[b]-positions[a]).cross(positions[c]-positions[a])
		minimum_area=minf(minimum_area,cross.length()*0.5)
		clockwise=clockwise and cross.dot(normals[a]+normals[b]+normals[c])<0.0
		if normals[a].y>0.9999 and normals[b].y>0.9999 and normals[c].y>0.9999 and positions[a].y>0.27 and positions[b].y>0.27 and positions[c].y>0.27:
			upward+=1
			top_triangles.append(PackedVector2Array([Vector2(positions[a].x,positions[a].z),Vector2(positions[b].x,positions[b].z),Vector2(positions[c].x,positions[c].z)]))
	for index: int in positions.size():
		maximum_normal_error=maxf(maximum_normal_error,absf(normals[index].length()-1.0))
		var tangent:=Vector3(tangents[index*4],tangents[index*4+1],tangents[index*4+2])
		maximum_tangent_dot=maxf(maximum_tangent_dot,absf(tangent.dot(normals[index])))
	check.call(upward==128 and minimum_area>0.00001 and clockwise,"all128annular top triangles are finite nondegenerate clockwise faces; no interior fan remains")
	for index: int in old_positions.size():
		var tangent:=Vector3(old_tangents[index*4],old_tangents[index*4+1],old_tangents[index*4+2])
		baseline_maximum_tangent_dot=maxf(baseline_maximum_tangent_dot,absf(tangent.dot(old_normals[index])))
	check.call(maximum_normal_error<0.00001 and maximum_tangent_dot<=sin(deg_to_rad(0.02)),"native unit normals and packed tangent frames stay within existing0.02degree precision")
	var water:=CylinderMesh.new()
	water.top_radius=5.96
	water.bottom_radius=5.96
	water.height=0.01
	water.radial_segments=64
	water.rings=0
	var water_boundary:=Basin.top_boundary(water)
	var water_polygon:=PackedVector2Array()
	for point: Vector3 in water_boundary:water_polygon.append(Vector2(point.x,point.z))
	var maximum_seam_error:=0.0
	for index: int in range(old_positions.size()+1,positions.size(),2):
		var best:=INF
		for point: Vector3 in water_boundary:best=minf(best,Vector2(positions[index].x-point.x,positions[index].z-point.z).length())
		maximum_seam_error=maxf(maximum_seam_error,best)
	var overlapping_area:=0.0
	for triangle: PackedVector2Array in top_triangles:
		for overlap: PackedVector2Array in Geometry2D.intersect_polygons(triangle,water_polygon):overlapping_area+=absf(_area(overlap))
	check.call(water_boundary.size()==64 and maximum_seam_error<=0.000002,"actual64sector water/rim boundary matches within2micrometres")
	check.call(overlapping_area<=0.0001,"annular top has no meaningful hidden surface across opaque water footprint (≤0.0001squaremetres)")
	var closed:=_inspect_closed_mesh(candidate,old_positions.size(),source.height*0.5,source.get_aabb().position.y+Basin.FLOOR_THICKNESS)
	check.call(closed.nonmanifold_edges==0 and closed.euler==2 and closed.welded_vertices==258,"actual welded faces form one closed genuszero basin with no open/nonmanifold edges")
	check.call(closed.parts=={"annulus":128,"inner_wall":128,"floor":64,"outer_side":128,"bottom":64},"actual triangle partitions retain exterior and build a real inward wall/upward floor")
	check.call(closed.wall_uv_handedness and closed.floor_uv_handedness,"innerwall Uaround/Vup hasW+1 and upwardfloor UVXZ hasW−1 after native packing")
	check.call(0.555-(source.get_aabb().position.y+Basin.FLOOR_THICKNESS+0.275)>0.5,"actual inner floor is over0.5m below water, replacing the5mmhidden backer")
	var body:=StaticBody3D.new()
	var shape:=CollisionShape3D.new()
	var solid:=CylinderShape3D.new()
	solid.radius=6.2
	solid.height=0.55
	shape.shape=solid
	shape.position.y=0.275
	body.add_child(shape)
	var collider_id:=solid.get_instance_id()
	var collider_height:=solid.height
	var collider_radius:=solid.radius
	var collider_transform:=shape.transform
	var visual:=MeshInstance3D.new()
	visual.mesh=source
	visual.material_override=material
	visual.position.y=0.275
	body.add_child(visual)
	visual.mesh=candidate
	check.call(shape.shape.get_instance_id()==collider_id and shape.transform==collider_transform and solid.height==collider_height and solid.radius==collider_radius,"mesh-only replacement retains exact authoritative collider identity/transform/dimensions")
	check.call(visual.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_ON and visual.material_override==material,"basin remains casting with original native material")
	print("FID_ENV_BASIN ",{"triangles":indices.size()/3,"seam_m":maximum_seam_error,"overlap_m2":overlapping_area,"closed":closed})
	body.free()

static func _area(polygon: PackedVector2Array) -> float:
	var twice:=0.0
	for index: int in polygon.size():
		var next: int=(index+1)%polygon.size()
		twice+=polygon[index].cross(polygon[next])
	return twice*0.5

static func _inspect_closed_mesh(mesh: ArrayMesh,old_vertex_count: int,top_y: float,floor_y: float) -> Dictionary:
	var arrays:=mesh.surface_get_arrays(0)
	var positions: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
	var tangents: PackedFloat32Array=arrays[Mesh.ARRAY_TANGENT]
	var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
	var welded: Array[Vector3]=[]
	var welded_faces: Array[int]=[]
	var edges: Dictionary={}
	var parts: Dictionary={"annulus":0,"inner_wall":0,"floor":0,"outer_side":0,"bottom":0}
	var volume:=0.0
	for offset: int in range(0,indices.size(),3):
		var triangle: Array[int]=[indices[offset],indices[offset+1],indices[offset+2]]
		var a:=positions[triangle[0]]
		var b:=positions[triangle[1]]
		var c:=positions[triangle[2]]
		volume+=float(a.dot(b.cross(c)))/6.0
		var centre_y: float=(a.y+b.y+c.y)/3.0
		if normals[triangle[0]].y>0.9999:
			if absf(centre_y-top_y)<0.00001:parts.annulus+=1
			elif absf(centre_y-floor_y)<0.00001:parts.floor+=1
		elif normals[triangle[0]].y< -0.9999:parts.bottom+=1
		elif normals[triangle[0]].dot(Vector3(a.x,0.0,a.z).normalized())< -0.999:parts.inner_wall+=1
		else:parts.outer_side+=1
		for vertex: int in triangle:
			var id: int=-1
			for existing: int in welded.size():
				if welded[existing].distance_squared_to(positions[vertex])<=0.000000000004:id=existing;break
			if id<0:id=welded.size();welded.append(positions[vertex])
			welded_faces.append(id)
	for offset: int in range(0,welded_faces.size(),3):
		for side: int in 3:
			var first: int=welded_faces[offset+side]
			var last: int=welded_faces[offset+(side+1)%3]
			var key: String=str(mini(first,last))+":"+str(maxi(first,last))
			edges[key]=int(edges.get(key,0))+1
	var nonmanifold:=0
	for count: int in edges.values():
		if count!=2:nonmanifold+=1
	var wall_frames:=true
	var floor_frames:=true
	for index: int in range(old_vertex_count+128,positions.size()):
		var tangent:=Vector3(tangents[index*4],tangents[index*4+1],tangents[index*4+2])
		var handedness: float=tangents[index*4+3]
		var bitangent: Vector3=normals[index].cross(tangent)*handedness
		if index<old_vertex_count+258:wall_frames=wall_frames and handedness==1.0 and bitangent.dot(Vector3.UP)>0.9999
		else:floor_frames=floor_frames and handedness== -1.0 and bitangent.dot(Vector3.BACK)>0.9999
	return {"welded_vertices":welded.size(),"edges":edges.size(),"faces":indices.size()/3,"euler":welded.size()-edges.size()+indices.size()/3,"nonmanifold_edges":nonmanifold,"signed_volume_m3":volume,"parts":parts,"wall_uv_handedness":wall_frames,"floor_uv_handedness":floor_frames,"weld_tolerance_m":0.000002}
