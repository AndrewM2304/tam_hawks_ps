extends RefCounted
## Compose the existing enclosed low lawn as a deliberate planted city edge.
## Relocate six existing, paired park-tree instances once; no new resources,
## collision, riding surfaces, routes or runtime callbacks are introduced.

const RECORDS := &"authored_tree_transforms"
const REPORT := &"pt24_central_green_report"
const PLANTING := [Vector2(-120,-101),Vector2(-111,-96),Vector2(-103,-102),
	Vector2(-65,-101),Vector2(-60,-94),Vector2(-57,-102)]
const VIEW_CORRIDOR := Rect2(-96,-108,24,22)


static func build(world: Node3D) -> Dictionary:
	if world.has_meta(REPORT): return world.get_meta(REPORT)
	var outdoors := world.get_node_or_null("OutdoorRoutes") as Node3D
	if outdoors == null: return {}
	var trunks := outdoors.get_node_or_null("ParkTreeTrunks") as MultiMeshInstance3D
	var crowns := outdoors.get_node_or_null("ParkTreeCanopies") as MultiMeshInstance3D
	if trunks == null or crowns == null: return {}
	var before: Array = trunks.get_meta(RECORDS,[])
	var crown_before: Array = crowns.get_meta(RECORDS,[])
	# Headless rendering backends can return dummy MultiMesh transforms.
	# Only author-owned CPU records can support a deterministic relocation.
	if before.size()!=trunks.multimesh.instance_count or before.size()!=crowns.multimesh.instance_count \
		or before.size()!=crown_before.size(): return {}
	var donors: Array[int] = []
	for i: int in before.size():
		if not before[i] is Transform3D or before[i]!=crown_before[i]: return {}
		var source: Vector3 = world.to_local(outdoors.to_global(before[i].origin))
		# A few outer planting-row trees, away from the actual riding paths,
		# supply the groves. Keep the park's route-side and summit planting.
		if source.x < -238.0 and source.z > -150.0 and source.z < -60.0:
			donors.append(i)
	if donors.size()<PLANTING.size(): return {}
	var after := before.duplicate()
	var moved: Array[Dictionary] = []
	for i: int in PLANTING.size():
		var target := world.to_global(Vector3(PLANTING[i].x,0.5,PLANTING[i].y))
		var height: float = world.get_ground_height(target)
		# Keep this an enclosed, grounded landscape rather than putting trees
		# on a road, lower service court, unsupported lawn or an upper deck.
		if not is_finite(height) or absf(height-target.y)>0.01: return {}
		var index := donors[i]
		var relocated: Transform3D = before[index]
		relocated.origin = outdoors.to_local(target)
		if not _clear_architecture(world,trunks,relocated) or not _clear_architecture(world,crowns,relocated): return {}
		after[index] = relocated
		moved.append({"index":index,"before":before[index],"after":relocated})
	# Complete all validation before touching either resident batch.
	for row: Dictionary in moved:
		trunks.multimesh.set_instance_transform(row.index,row.after)
		crowns.multimesh.set_instance_transform(row.index,row.after)
	trunks.set_meta(RECORDS,after.duplicate())
	crowns.set_meta(RECORDS,after.duplicate())
	var report := {"kind":"enclosed_landscaped_edge","relocated_trees":moved,
		"instances_before":before.size(),"instances_after":after.size(),
		"view_corridor":VIEW_CORRIDOR,"added_surfaces":0,"added_triangles":0,
		"added_bodies":0,"added_shapes":0,"added_textures":0,"added_lights":0}
	world.set_meta(REPORT,report)
	return report


## Startup physics may not yet have synchronized the new world. Check actual
## native closed-facade boxes against the complete transformed source meshes,
## rather than accepting a ground ray that starts inside a building.
static func _clear_architecture(world: Node3D,batch: MultiMeshInstance3D,frame: Transform3D) -> bool:
	var tree_bounds: AABB=(batch.global_transform*frame)*batch.multimesh.mesh.get_aabb()
	for body: Node in world.find_children("*","StaticBody3D",true,false):
		if not bool(body.get_meta("tam_closed_facade_wall",false)): continue
		for child: Node in body.get_children():
			if child is CollisionShape3D and child.shape is BoxShape3D:
				var size: Vector3=child.shape.size
				var facade: AABB=child.global_transform*AABB(-size*0.5,size)
				if tree_bounds.intersects(facade): return false
	return true
