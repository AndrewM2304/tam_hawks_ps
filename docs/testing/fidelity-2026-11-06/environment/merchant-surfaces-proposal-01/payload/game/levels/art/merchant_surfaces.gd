extends RefCounted
## PRIVATE surface-only proposal. No support/collision/guide/position edits.
const LIBRARY = preload("res://game/levels/art/material_library.gd")
const MAPS := "res://game/art/assets/merchant_pbr/manifest.json"
const ZONES: Array[String] = ["road","footway","market","industrial"]

static func materials(shared: Dictionary) -> Dictionary:
	var sources: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(MAPS)).materials
	var concrete:=StandardMaterial3D.new()
	LIBRARY._apply(concrete,sources.concrete_floor_worn_001,Color.WHITE,.12)
	concrete.metallic_specular=.4
	concrete.resource_name="MerchantPouredConcrete3m"
	var bowl: StandardMaterial3D=concrete.duplicate(false)
	bowl.roughness=.88
	bowl.normal_scale=.10
	bowl.resource_name="MerchantSkateConcrete3m"
	var flags:=StandardMaterial3D.new()
	LIBRARY._apply(flags,sources.granite_tile,Color.WHITE,.13)
	flags.metallic_specular=.32
	flags.resource_name="MerchantGraniteFlags2_3m"
	return {"road":shared.asphalt,"footway":shared.path,"market":flags,"industrial":concrete,"bowl":bowl}

static func zones() -> Dictionary:
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://game/levels/art/merchant_surface_zones.json"))
	var court: Array=data.court_xz;var depot: Array=data.depot_xz
	return {"court":Rect2(court[0],court[1],court[2]-court[0],court[3]-court[1]),"depot":Rect2(depot[0],depot[1],depot[2]-depot[0],depot[3]-depot[1]),"maximum_road_width":float(data.maximum_road_width_m),"grid":data.terrain_grid}

static func apply(world: Node3D,shared: Dictionary,layout: Dictionary) -> Dictionary:
	var look:=materials(shared)
	var state: Dictionary={"meshes":[],"report":{"source_triangles":0,"output_triangles":0,"surface_counts":{},"used_vertices":{},"source_vertices":0,"packed_vertex_bytes_verified":0,"concrete_visuals":0,"rebound_patches":0,"positions_collision_guides_edited":false}}
	var ground:=world.get_node("NeighbourhoodGround")
	var visual: MeshInstance3D
	for child: Node in ground.get_children():
		if child is MeshInstance3D:visual=child;break
	assert(visual!=null and visual.mesh is ArrayMesh and visual.mesh.get_surface_count()==1)
	assert(visual.material_overlay==null and visual.get_surface_override_material(0)==null)
	var original: ArrayMesh=visual.mesh
	var arrays:=original.surface_get_arrays(0)
	for slot: int in range(Mesh.ARRAY_MAX):
		if not slot in [Mesh.ARRAY_VERTEX,Mesh.ARRAY_NORMAL,Mesh.ARRAY_TANGENT,Mesh.ARRAY_TEX_UV,Mesh.ARRAY_INDEX]:assert(arrays[slot]==null or arrays[slot].size()==0,"Unexpected nonempty vertex stream must be preserved explicitly")
	var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array=_factory_normals(vertices,zones().grid)
	var uv: PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV]
	var tangents: PackedFloat32Array=arrays[Mesh.ARRAY_TANGENT] if arrays[Mesh.ARRAY_TANGENT]!=null else PackedFloat32Array()
	assert(tangents.is_empty() or tangents.size()==vertices.size()*4)
	var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
	assert(not indices.is_empty() and normals.size()==vertices.size() and uv.size()==vertices.size())
	var buckets: Dictionary={}
	for key: String in ZONES:buckets[key]={"ids":PackedInt32Array(),"triangles":PackedInt32Array()}
	var segments: Array[Dictionary]=[]
	var zone_policy:=zones()
	for corridor: Dictionary in layout.street_corridors:
		for i: int in range(corridor.points.size()-1):
			var a: Array=corridor.points[i];var b: Array=corridor.points[i+1]
			segments.append({"a":Vector2(a[0],a[2]),"b":Vector2(b[0],b[2]),"road":minf(float(corridor.width),float(zone_policy.maximum_road_width))*.5,"shoulder":float(corridor.width)*.5})
	for i: int in range(0,indices.size(),3):
		var center:=visual.global_transform*((vertices[indices[i]]+vertices[indices[i+1]]+vertices[indices[i+2]])/3.0)
		var key:=_zone(Vector2(center.x,center.z),segments,zone_policy)
		buckets[key].ids.append_array(PackedInt32Array([indices[i],indices[i+1],indices[i+2]]))
		buckets[key].triangles.append(i/3)
	var mesh:=ArrayMesh.new()
	state.report.source_vertices=vertices.size()
	state.report.source_triangles=indices.size()/3
	var mappings: Array[Dictionary]=[]
	for key: String in ZONES:
		var old_ids: PackedInt32Array=buckets[key].ids
		if old_ids.is_empty():continue
		var remap: Dictionary={};var used:=PackedInt32Array();var out_indices:=PackedInt32Array()
		var out_vertices:=PackedVector3Array();var out_normals:=PackedVector3Array();var out_uv:=PackedVector2Array();var out_tangents:=PackedFloat32Array()
		for old: int in old_ids:
			if not remap.has(old):
				remap[old]=used.size();used.append(old)
				out_vertices.append(vertices[old]);out_normals.append(normals[old]);out_uv.append(uv[old])
				pass # Original terrain factory supplies normals only; server derives its tangents.
			out_indices.append(remap[old])
		var output:=[];output.resize(Mesh.ARRAY_MAX)
		output[Mesh.ARRAY_VERTEX]=out_vertices;output[Mesh.ARRAY_NORMAL]=out_normals;output[Mesh.ARRAY_TEX_UV]=out_uv;output[Mesh.ARRAY_INDEX]=out_indices
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,output)
		var surface:=mesh.get_surface_count()-1
		mesh.surface_set_material(surface,look[key]);mesh.surface_set_name(surface,key)
		# Public native buffer update avoids a second oct-normal quantisation.
		# Only already-authored referenced vertex bytes are copied; no new vertex.
		state.report.packed_vertex_bytes_verified+=_verify_vertex_bytes(original,mesh,surface,used)
		state.report.surface_counts[key]=out_indices.size()/3
		state.report.used_vertices[key]=used.size()
		state.report.output_triangles+=out_indices.size()/3
		mappings.append({"zone":key,"surface":surface,"original_vertices":used,"original_triangles":buckets[key].triangles})
	state.meshes.append({"node":visual,"mesh":original,"material":visual.material_override})
	visual.mesh=mesh;visual.material_override=null
	var placeholder: Material=shared.skate_concrete
	for item: Node in world.find_children("*","MeshInstance3D",true,false):
		var instance:=item as MeshInstance3D
		if instance==visual:continue
		var replace: Material
		if instance.material_override==placeholder:replace=look.bowl
		elif instance.material_override in [shared.paving,shared.path]:
			var id:=str(instance.get_parent().name)
			if id=="MD_Foundry_Lower_Street":replace=look.road
			elif id.begins_with("MD_Loading_") or id in ["MD_Depot_Bridge","MD_Roof_To_Bridge","MD_Dock_Kicker"]:replace=look.industrial
			elif id.begins_with("MD_Foundry_") and not id.contains("Retaining"):replace=look.bowl
			elif id.begins_with("MD_Market_"):replace=look.market
		if replace!=null:
			state.meshes.append({"node":instance,"mesh":instance.mesh,"material":instance.material_override})
			instance.material_override=replace
			if replace==look.bowl:state.report.concrete_visuals+=1
			else:state.report.rebound_patches+=1
	state["mappings"]=mappings
	state["look"]=look
	return state

static func _zone(point: Vector2,segments: Array[Dictionary],policy: Dictionary) -> String:
	# The civic court remains pedestrian stone; routes here are skating lanes,
	# not a traffic-road painted through the central seating/landing space.
	if policy.court.has_point(point):return "market"
	var shoulder:=false
	for segment: Dictionary in segments:
		var distance:=point.distance_to(Geometry2D.get_closest_point_to_segment(point,segment.a,segment.b))
		if distance<=float(segment.road):return "road"
		shoulder=shoulder or distance<=float(segment.shoulder)
	if shoulder:return "footway"
	if policy.depot.has_point(point):return "industrial"
	return "footway"

static func _factory_normals(vertices: PackedVector3Array,grid: Dictionary) -> PackedVector3Array:
	# Reuse the exact original Surface.terrain normal-input calculation. Reading
	# already oct-packed normals and packing twice can perturb one stored bit.
	# This derives the original inputs from unchanged float32 vertex heights;
	# the final raw vertex/attribute bytes are checked before mesh assignment.
	var b: Array=grid.bounds_xz
	var nx:=ceili((float(b[2])-float(b[0]))/float(grid.spacing_m))
	var nz:=ceili((float(b[3])-float(b[1]))/float(grid.spacing_m))
	var dx: float=(float(b[2])-float(b[0]))/nx;var dz: float=(float(b[3])-float(b[1]))/nz
	assert(vertices.size()==(nx+1)*(nz+1))
	var result:=PackedVector3Array()
	for z: int in range(nz+1):
		for x: int in range(nx+1):
			var left: float=vertices[z*(nx+1)+maxi(0,x-1)].y
			var right: float=vertices[z*(nx+1)+mini(nx,x+1)].y
			var north: float=vertices[maxi(0,z-1)*(nx+1)+x].y
			var south: float=vertices[mini(nz,z+1)*(nx+1)+x].y
			result.append(Vector3((left-right)/dx,2.0,(north-south)/dz).normalized())
	return result

static func _verify_vertex_bytes(original: ArrayMesh,target: ArrayMesh,surface: int,used: PackedInt32Array) -> int:
	var source: Dictionary=RenderingServer.mesh_get_surface(original.get_rid(),0)
	var dest: Dictionary=RenderingServer.mesh_get_surface(target.get_rid(),surface)
	var source_count:=original.surface_get_array_len(0)
	var stride:=RenderingServer.mesh_surface_get_format_vertex_stride(source.format,source_count)
	var nstride:=RenderingServer.mesh_surface_get_format_normal_tangent_stride(source.format,source_count)
	var astride:=RenderingServer.mesh_surface_get_format_attribute_stride(source.format,source_count)
	assert(stride==RenderingServer.mesh_surface_get_format_vertex_stride(dest.format,used.size()))
	assert(nstride==RenderingServer.mesh_surface_get_format_normal_tangent_stride(dest.format,used.size()))
	assert(astride==RenderingServer.mesh_surface_get_format_attribute_stride(dest.format,used.size()))
	var before: PackedByteArray=source.vertex_data;var after: PackedByteArray=dest.vertex_data
	var before_attr: PackedByteArray=source.attribute_data;var after_attr: PackedByteArray=dest.attribute_data
	for i: int in used.size():
		assert(after.slice(i*stride,(i+1)*stride)==before.slice(used[i]*stride,(used[i]+1)*stride),"Position bytes differ")
		assert(after.slice(used.size()*stride+i*nstride,used.size()*stride+(i+1)*nstride)==before.slice(source_count*stride+used[i]*nstride,source_count*stride+(used[i]+1)*nstride),"Original normal/tangent bytes differ")
		assert(after_attr.slice(i*astride,(i+1)*astride)==before_attr.slice(used[i]*astride,(used[i]+1)*astride),"UV/attribute bytes differ")
	return after.size()+after_attr.size()

static func restore(state: Dictionary) -> void:
	for saved: Dictionary in state.meshes:
		saved.node.mesh=saved.mesh;saved.node.material_override=saved.material
