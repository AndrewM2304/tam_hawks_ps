extends SceneTree
const Basin = preload("res://game/levels/art/fountain_basin_mesh.gd")
var checks:=0
var failures:=0
func _initialize() -> void: _run.call_deferred()
func _check(ok: bool,label: String) -> void:
	checks+=1
	if ok:return
	failures+=1
	push_error(label)

func _run() -> void:
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
	var old_positions: PackedVector3Array=original[Mesh.ARRAY_VERTEX]
	var old_normals: PackedVector3Array=original[Mesh.ARRAY_NORMAL]
	var old_tangents: PackedFloat32Array=original[Mesh.ARRAY_TANGENT]
	var old_uv: PackedVector2Array=original[Mesh.ARRAY_TEX_UV]
	var old_indices: PackedInt32Array=original[Mesh.ARRAY_INDEX]
	_check(source.get_faces().size()/3==256 and indices.size()/3==320,"exact native topology is256 to320triangles: declared+64")
	_check(candidate.get_surface_count()==1 and candidate.surface_get_material(0)==material,"one surface and exact existing material object retained")
	_check(candidate.get_aabb()==source.get_aabb(),"exact exterior bounds remain identical")
	_check(original==source.surface_get_arrays(0),"source native resource streams are not mutated")
	var source_prefix_unchanged:=true
	for index: int in old_positions.size():
		source_prefix_unchanged=source_prefix_unchanged and positions[index]==old_positions[index] and normals[index]==old_normals[index] and uv[index]==old_uv[index]
		for component: int in 4:source_prefix_unchanged=source_prefix_unchanged and tangents[index*4+component]==old_tangents[index*4+component]
	_check(source_prefix_unchanged,"all original positions/normals/tangents/UV remain byte-value identical")
	var retained:=PackedInt32Array()
	var removed_top:=0
	for offset: int in range(0,old_indices.size(),3):
		var a:=old_indices[offset]
		var b:=old_indices[offset+1]
		var c:=old_indices[offset+2]
		if old_normals[a].y>0.9999 and old_normals[b].y>0.9999 and old_normals[c].y>0.9999:removed_top+=1
		else:retained.append_array(PackedInt32Array([a,b,c]))
	_check(removed_top==64 and retained.size()/3==192 and indices.slice(0,retained.size())==retained,"all192outer side/bottom triangles retain exact indices; only64hidden top sectors removed")
	_check(positions.size()-old_positions.size()==128 and uv.size()==positions.size() and tangents.size()==positions.size()*4,"exact128annular vertices retain UV/tangent streams")
	var minimum_area:=INF
	var maximum_normal_error:=0.0
	var maximum_tangent_dot:=0.0
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
		if normals[a].y>0.9999 and normals[b].y>0.9999 and normals[c].y>0.9999:
			upward+=1
			top_triangles.append(PackedVector2Array([Vector2(positions[a].x,positions[a].z),Vector2(positions[b].x,positions[b].z),Vector2(positions[c].x,positions[c].z)]))
	for index: int in positions.size():
		maximum_normal_error=maxf(maximum_normal_error,absf(normals[index].length()-1.0))
		var tangent:=Vector3(tangents[index*4],tangents[index*4+1],tangents[index*4+2])
		maximum_tangent_dot=maxf(maximum_tangent_dot,absf(tangent.dot(normals[index])))
	_check(upward==128 and minimum_area>0.00001 and clockwise,"all128annular top triangles are finite nondegenerate clockwise faces; no interior fan remains")
	_check(maximum_normal_error<0.00001 and maximum_tangent_dot<0.00001,"native unit normals and tangent frames remain valid")
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
	_check(water_boundary.size()==64 and maximum_seam_error<=0.000002,"actual64sector water/rim boundary matches within2micrometres")
	_check(overlapping_area<=0.0001,"annular top has no meaningful hidden surface across opaque water footprint (≤0.0001squaremetres)")
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
	_check(shape.shape.get_instance_id()==collider_id and shape.transform==collider_transform and solid.height==collider_height and solid.radius==collider_radius,"mesh-only replacement retains exact authoritative collider identity/transform/dimensions")
	_check(visual.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_ON and visual.material_override==material,"basin remains casting with original native material")
	var report: Dictionary={"engine":Engine.get_version_info(),"checks":checks,"failures":failures,"baseline_triangles":old_indices.size()/3,"candidate_triangles":indices.size()/3,"removed_hidden_top":removed_top,"retained_side_bottom":retained.size()/3,"annular_top_triangles":upward,"new_vertices":positions.size()-old_positions.size(),"maximum_seam_error_m":maximum_seam_error,"top_water_footprint_overlap_square_m":overlapping_area,"minimum_triangle_area_square_m":minimum_area,"maximum_normal_error":maximum_normal_error,"maximum_tangent_dot":maximum_tangent_dot,"bounds":str(candidate.get_aabb()),"water_top_above_rim_m":0.005,"limits":"Native component topology/stream/seam and mesh-only collision guards. Production unchanged; actual Main shadows/appearance and full regression remain separate. Water side and rim meet on a shared64sector boundary; pre-existing water top remains5mmabove rim, explicitly not a new coplanar hidden backer."}
	var file:=FileAccess.open("res://.local/basin-topology-guard.json",FileAccess.WRITE)
	if file:file.store_string(JSON.stringify(report,"\t")+"\n");file.close()
	print("BASIN_GEOMETRY_GUARD checks=",checks," failures=",failures," seam_m=",maximum_seam_error," overlap_m2=",overlapping_area)
	body.free()
	quit(1 if failures else 0)

func _area(polygon: PackedVector2Array) -> float:
	var twice:=0.0
	for index: int in polygon.size():
		var next: int=(index+1)%polygon.size()
		twice+=polygon[index].cross(polygon[next])
	return twice*0.5
