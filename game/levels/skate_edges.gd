extends RefCounted
const ClydeLayout = preload("res://game/levels/clyde_layout.gd")
## Startup-only semantic edge authoring. No display nodes/collision/process work.
## Selected real props supply exact shape transforms; arbitrary decorative mesh
## edges, building windows and out-of-bounds fence kilometres are not scanned.

const GrindLineSource = preload("res://game/tricks/grind_line.gd")
const SKIN := 0.04
const END_MARGIN := 0.12
const MIN_LENGTH := 0.25
const PREFIX := "Grind_Edge_"


static func build(world: Node3D) -> Array:
	var sources: Array[Node3D] = []
	_collect(world,sources)
	var original: Array = []
	for line in world.get_grind_lines():
		if not String(line.id).begins_with(PREFIX): original.append(line)
	var lines: Array = []
	var boxes := {
		"Planter":"Planter", "CourtPlanterSeat":"CourtSeat",
		"WorkshopBackSeat":"WorkshopSeat", "ClosePocketPlanter":"ClosePocket",
		"PrintYardPlanter":"PrintYard", "StallCounter":"MarketCounter",
		"QuayBenchSeat":"Bench", "GalleryStairCheek":"StairCheek",
		"StreetBenchSeat":"StreetBenchSeat", "StreetBenchBack":"StreetBenchBack"
	}
	for body: Node3D in sources:
		var label := _label(body)
		if boxes.has(label) and body is StaticBody3D:
			var collision := _box_shape(body)
			if collision == null: continue
			var size: Vector3 = collision.shape.size
			var frame := collision.global_transform
			if body.has_meta("skate_edge_box_size"):
				size=body.get_meta("skate_edge_box_size")
				frame=body.global_transform*Transform3D(Basis.IDENTITY,body.get_meta("skate_edge_box_center"))
			var top_extra := 0.0
			if label == "CourtPlanterSeat":
				# The existing visible cut-stone cap overhangs the solid low seat.
				size.x=1.25
				size.z=8.1
				top_extra=0.06
			var stamp := _stamp(world.to_local(body.global_position))
			var points := box_top(frame,size,top_extra)
			for index: int in range(4):
				_add_segment(world,lines,original,String(boxes[label])+"_"+stamp+"_"+str(index),points[index],points[(index+1)%4],"ledge")
		elif label.begins_with("Grind_Cat_") and label.ends_with("Plinth") and body is StaticBody3D:
			# Existing marked centre copings keep their exact IDs. The other visible
			# plinth edges are ordinary optional ledges, ignored by the sequence.
			var collision := _box_shape(body)
			if collision == null: continue
			var points := box_top(collision.global_transform,collision.shape.size)
			for index: int in range(4):
				_add_segment(world,lines,original,"BuskingPlinth_"+_stamp(world.to_local(body.global_position))+"_"+str(index),points[index],points[(index+1)%4],"ledge")
		elif label == "BridgeHandrail":
			# Safe bridge bars are solid; the optional broken bridge bars already
			# supply visible rail-only geometry. Both use their actual tube boxes.
			var shape := _box_shape(body)
			var size := Vector3.ZERO
			var frame := body.global_transform
			if shape != null:
				size=shape.shape.size
				frame=shape.global_transform
			else:
				for child: Node in body.get_children():
					if child is MeshInstance3D and child.mesh is BoxMesh:
						size=child.mesh.size
						frame=child.global_transform
			if size.z>MIN_LENGTH:
				_add_segment(world,lines,original,"BridgeRail_"+_stamp(world.to_local(body.global_position)),frame*Vector3(0,size.y/2,-size.z/2)+Vector3.UP*SKIN,frame*Vector3(0,size.y/2,size.z/2)+Vector3.UP*SKIN,"rail")
		elif String(body.get_meta("geometry_id","")) == "ParkGranitePathEdge":
			_ribbon_edges(world,body,lines,original)
	_civic_gardens(world,lines,original)
	_station_edges(world,lines,original)
	_quay_edges(world,sources,lines,original)
	return lines


## Returned world points follow the exact collision-shape transform, including
## translation, yaw and authored scale. The skin follows world up for the rider.
static func box_top(frame: Transform3D,size: Vector3,extra_height: float=0.0) -> PackedVector3Array:
	var result := PackedVector3Array()
	for corner: Vector2 in [Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,1)]:
		result.append(frame*Vector3(corner.x*size.x/2,size.y/2+extra_height,corner.y*size.z/2)+Vector3.UP*SKIN)
	return result


static func _collect(parent: Node,sources: Array[Node3D]) -> void:
	for child: Node in parent.get_children():
		if child is Node3D: sources.append(child)
		_collect(child,sources)


static func _label(body: Node3D) -> String:
	return String(body.get_meta("art_label",body.get_meta("geometry_id",String(body.name))))


static func _box_shape(body: Node3D) -> CollisionShape3D:
	for child: Node in body.get_children():
		if child is CollisionShape3D and child.shape is BoxShape3D: return child
	return null


static func _stamp(at: Vector3) -> String:
	return "x%dy%dz%d" % [roundi(at.x*100),roundi(at.y*100),roundi(at.z*100)]


static func _add_segment(world: Node3D,lines: Array,original: Array,id: String,a: Vector3,b: Vector3,kind: String) -> void:
	var run := a.distance_to(b)
	if run<MIN_LENGTH: return
	var margin := minf(END_MARGIN,run*0.12)
	var direction := (b-a)/run
	_add_supported(world,lines,original,id,PackedVector3Array([a+direction*margin,b-direction*margin]),kind)


static func _add_supported(world: Node3D,lines: Array,original: Array,id: String,points: PackedVector3Array,kind: String) -> void:
	if points.size()<2: return
	# Crop buried pieces (e.g. a stair cheek meeting the upper landing). No
	# points are fabricated beyond the physical source or below adjacent ground.
	var part := PackedVector3Array()
	var part_id := 0
	for segment: int in range(points.size()-1):
		var steps := maxi(1,ceili(points[segment].distance_to(points[segment+1])/0.5))
		for step: int in range(steps+1):
			if segment>0 and step==0: continue
			var at := points[segment].lerp(points[segment+1],float(step)/steps)
			var height: float=world.get_ground_height(at)
			if is_finite(height) and height<=at.y-SKIN*0.5:
				_append_corner(part,at)
			else:
				_commit(lines,original,id+"_"+str(part_id),part,kind)
				part_id+=1
				part=PackedVector3Array()
	_commit(lines,original,id+"_"+str(part_id),part,kind)


static func _append_corner(points: PackedVector3Array,at: Vector3) -> void:
	if points.size()>=2:
		var previous := points[-1]-points[-2]
		var next := at-points[-1]
		if previous.length_squared()>0.000001 and next.length_squared()>0.000001 and previous.normalized().dot(next.normalized())>0.999999:
			points[-1]=at
			return
	points.append(at)


static func _commit(lines: Array,original: Array,id: String,points: PackedVector3Array,kind: String) -> void:
	if points.size()<2: return
	var total := 0.0
	for index: int in range(points.size()-1): total+=points[index].distance_to(points[index+1])
	if total<MIN_LENGTH: return
	# Keep older authored/challenge IDs wherever a new selected edge coincides.
	for line in original:
		var coincident := true
		for at: Vector3 in [points[0],points[floori(points.size()*0.5)],points[-1]]:
			var closest: Dictionary=line.closest(at)
			if closest.is_empty() or float(closest.gap)>0.15:
				coincident=false
				break
		if coincident: return
	var candidate=GrindLineSource.new(PREFIX+id,points,kind)
	if candidate.is_valid: lines.append(candidate)


static func _civic_gardens(world: Node3D,lines: Array,original: Array) -> void:
	var terrain: Variant=world.get("_terrain")
	if terrain==null: return
	for polygon: Dictionary in terrain.polygons:
		var points: PackedVector3Array=polygon.points
		if points.size()!=5: continue
		var bounds := Rect2(Vector2(points[0].x,points[0].z),Vector2.ZERO)
		var eligible := true
		for at: Vector3 in points:
			bounds=bounds.expand(Vector2(at.x,at.z))
			eligible=eligible and absf(at.y-4.55)<0.01
		if not eligible or bounds.position.y< -89 or bounds.end.y> -79 or absf(bounds.size.x-11)>0.01: continue
		for index: int in range(points.size()):
			_add_segment(world,lines,original,"CivicGarden_"+_stamp(points[0])+"_"+str(index),world.to_global(points[index])+Vector3.UP*SKIN,world.to_global(points[(index+1)%points.size()])+Vector3.UP*SKIN,"ledge")


static func _station_edges(world: Node3D,lines: Array,original: Array) -> void:
	# Explicit real drop faces only. Flush north/south bank mouths remain floor,
	# and the service deck's stair-connected southeast mouth stays unregistered.
	for source: Dictionary in [
		{"id":"PlatformNorthWest","a":Vector3(-101,5,-20),"b":Vector3(-101,5,-5)},
		{"id":"PlatformNorthEast","a":Vector3(-87,5,-20),"b":Vector3(-87,5,-5)},
		{"id":"PlatformNorthGap","a":Vector3(-101,5,-5),"b":Vector3(-87,5,-5)},
		{"id":"PlatformSouthWest","a":Vector3(-101,5,-1),"b":Vector3(-101,5,14)},
		{"id":"PlatformSouthEast","a":Vector3(-87,5,-1),"b":Vector3(-87,5,14)},
		{"id":"PlatformSouthGap","a":Vector3(-101,5,-1),"b":Vector3(-87,5,-1)},
		{"id":"ServiceWalkWest","a":Vector3(-122,5,-20),"b":Vector3(-122,5,4)},
		{"id":"ServiceWalkEast","a":Vector3(-105,5,-20),"b":Vector3(-105,5,4)},
		{"id":"ServiceWalkFront","a":Vector3(-122,5,4),"b":Vector3(-117,5,4)}
	]: _add_segment(world,lines,original,source.id,world.to_global(source.a)+Vector3.UP*SKIN,world.to_global(source.b)+Vector3.UP*SKIN,"ledge")


static func _ribbon_edges(world: Node3D,body: Node3D,lines: Array,original: Array) -> void:
	for child: Node in body.get_children():
		if not child is MeshInstance3D or not child.mesh is ArrayMesh: continue
		var arrays: Array=child.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		if vertices.size()<4: continue
		for side: int in range(2):
			var points:=PackedVector3Array()
			for index: int in range(side,vertices.size(),2): points.append(child.to_global(vertices[index])+Vector3.UP*SKIN)
			_add_supported(world,lines,original,"ParkGranite_"+_stamp(world.to_local(points[0]))+"_"+str(side),points,"curb")


static func _quay_edges(world: Node3D,sources: Array[Node3D],lines: Array,original: Array) -> void:
	for body: Node3D in sources:
		var label := _label(body)
		if label not in ["NorthEmbankment","SouthEmbankment"]: continue
		var collision:=_box_shape(body)
		if collision==null: continue
		var size: Vector3=collision.shape.size
		var side := 1.0 if label=="NorthEmbankment" else -1.0
		for span: Vector2 in ClydeLayout.quay_edge_spans(label=="NorthEmbankment"):
			# Contract spans are world-local; the south wall has a new centre.
			span-=Vector2.ONE*body.position.x
			# Leave safe/broken bridge mouths open; these are visible water-facing
			# curb tops, not virtual grind tracks across a flush bridge entrance.
			var a:=collision.to_global(Vector3(span.x,size.y/2,side*(size.z/2-0.02)))+Vector3.UP*SKIN
			var b:=collision.to_global(Vector3(span.y,size.y/2,side*(size.z/2-0.02)))+Vector3.UP*SKIN
			_add_segment(world,lines,original,label+"_"+str(roundi(span.x*10)),a,b,"curb")
