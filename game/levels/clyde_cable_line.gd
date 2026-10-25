extends Node3D
## PT24-25 candidate: finite playable crowns of the EXISTING red cable beams.
## Native boxes copy the art transforms. No visible geometry, forced transfer,
## global ollie boost or guide across the high tower sections is introduced.

const Layout = preload("res://game/levels/clyde_layout.gd")
const Line = preload("res://game/tricks/grind_line.gd")
const StaticBatches = preload("res://game/levels/static_batches.gd")
const FIRST_SEGMENT := 12
const LAST_SEGMENT := 19
const CABLE_RADIUS := 0.075
const SEGMENT_Z := 50.0/32.0
const BUDGET := {"resident_surfaces":0,"new_triangles":0,"bodies":1,
	"shapes":16,"textures":0,"lights":0}

var _built := false
var _lines: Array = []
var _world: Node3D


func build(world: Node3D) -> void:
	if _built: return
	_world = world
	name = "ClydeCableContacts"
	if get_parent() == null: world.add_child(self)
	assert(transform.is_equal_approx(Transform3D.IDENTITY))
	var outdoors: Node3D = world.get_node("OutdoorRoutes")
	var art: MultiMeshInstance3D = outdoors.get_node("ClydeLandmarks/Clyde_box_clyde_red")
	var authored: Array = StaticBatches.authored_transforms(art)
	assert(not authored.is_empty(),"Cable contact requires the original CPU authoring records, not GPU readback")
	var native := StaticBody3D.new()
	native.name = "ExistingCableNativeCrowns"
	native.collision_layer = 2
	native.collision_mask = 0
	native.set_meta("surface_audio","metal")
	native.set_meta("authored_grind_ids",["clyde_cable_west","clyde_cable_east"])
	native.set_meta("audit_capture_ids",["clyde_cable_west","clyde_cable_east"])
	add_child(native)
	var selected := 0
	for side: float in [-1.0,1.0]:
		var cable_x := _strand_x(side)
		for value: Transform3D in authored:
			var frame := value
			if absf(frame.origin.x-cable_x)>0.001: continue
			if frame.origin.z<_z(FIRST_SEGMENT) or frame.origin.z>_z(LAST_SEGMENT+1): continue
			# The original red batch also contains thin hangers. Only the long,
			# 15cm square cable facets define this native crown.
			var size := frame.basis.get_scale()
			if absf(size.x-CABLE_RADIUS*2)>0.001 or absf(size.z-CABLE_RADIUS*2)>0.001: continue
			var world_frame := art.global_transform*frame
			var local_frame := global_transform.affine_inverse()*world_frame
			var shape := BoxShape3D.new()
			shape.size = local_frame.basis.get_scale()
			var collision := CollisionShape3D.new()
			collision.shape = shape
			collision.transform = Transform3D(local_frame.basis.orthonormalized(),local_frame.origin)
			native.add_child(collision)
			selected += 1
		var crown := PackedVector3Array()
		for index: int in range(FIRST_SEGMENT,LAST_SEGMENT+2):
			var steepest := 0.0
			for segment: int in [maxi(FIRST_SEGMENT,index-1),mini(LAST_SEGMENT,index)]:
				steepest = maxf(steepest,absf((_height(segment+1)-_height(segment))/SEGMENT_Z))
			# This is the actual upper plane of a square beam at fixed world X/Z,
			# not a guessed radial offset across a changing-grade polyline.
			var at := Vector3(cable_x,_height(index)+CABLE_RADIUS*sqrt(1.0+steepest*steepest),_z(index))
			crown.append(at)
		var id := "clyde_cable_west" if side<0.0 else "clyde_cable_east"
		var line := Line.from_local_points(id,crown,global_transform,"rail")
		line.configure_contact(0.0,0.0,"clyde.existing_red_cable_native_crown")
		_lines.append(line)
	assert(selected==16,"The exact existing cable facets must be present before installing contacts")
	_built = true
	set_meta("construction_budget",BUDGET.duplicate())
	set_meta("native_source","ClydeLandmarks/Clyde_box_clyde_red: exact existing transforms")


func get_grind_lines() -> Array:
	return _lines.duplicate()


func get_gap_definitions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for side: float in [-1.0,1.0]:
		var suffix := "west" if side<0.0 else "east"
		result.append({"id":"clyde_handrail_to_cable_"+suffix,"name":"Suspension Cable Transfer",
			"start":to_global(Vector3(Layout.SAFE_X+side*3.85,4.5,92.0)),
			"end":to_global(_crown_at(side,95.0)),"radius":0.7,"points":500,"airborne_required":true})
		result.append({"id":"clyde_cable_to_handrail_"+suffix,"name":"Back To The Bridge",
			"start":to_global(_crown_at(side,99.0)),
			"end":to_global(Vector3(Layout.SAFE_X+side*3.85,4.5,102.0)),
			"radius":0.7,"points":500,"airborne_required":true})
	return result


func get_route_definitions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for side: float in [-1.0,1.0]:
		var points := PackedVector3Array()
		for at: Vector3 in [Vector3(Layout.SAFE_X+side*3.85,4.5,90.0),
			Vector3(Layout.SAFE_X+side*3.85,4.5,92.0),_crown_at(side,95.0),
			_crown_at(side,99.0),Vector3(Layout.SAFE_X+side*3.85,4.5,102.0),
			Vector3(Layout.SAFE_X+side*3.85,4.5,104.0)]: points.append(to_global(at))
		result.append({"id":"clyde_cable_transfer_"+("west" if side<0.0 else "east"),
			"label":"Optional handrail / suspension cable / handrail line",
			"points":points,"requires_jump":true})
	return result


func _crown_at(side: float, z: float) -> Vector3:
	var at := clampf((z-72.0)/SEGMENT_Z,float(FIRST_SEGMENT),float(LAST_SEGMENT+1))
	var before := mini(floori(at),LAST_SEGMENT)
	var fraction := at-before
	var height := lerpf(_height(before),_height(before+1),fraction)
	var slope := (_height(before+1)-_height(before))/SEGMENT_Z
	return Vector3(_strand_x(side),height+CABLE_RADIUS*sqrt(1.0+slope*slope),z)


func _strand_x(side: float) -> float:
	# Inner of the paired art strands; 0.50m beyond the existing handrail.
	return Layout.SAFE_X+side*(4.45-0.10)


func _z(index: int) -> float:
	return 72.0+SEGMENT_Z*index


func _height(index: int) -> float:
	var t := float(index)/32.0
	return 4.85+4.75*pow(2.0*t-1.0,2.0)
