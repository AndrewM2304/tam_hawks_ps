extends RefCounted
## Semantic coverage/resource checks. Real mapped-input captures remain QE's job.
const Edges = preload("res://game/levels/skate_edges.gd")

static func run(world: Node3D,check: Callable) -> void:
	await world.get_tree().physics_frame
	await world.get_tree().process_frame
	var before_nodes := _node_count(world)
	var routes: Array=world.get_route_definitions()
	var existing: Array=world.get_grind_lines()
	var lines: Array=Edges.build(world)
	check.call(_node_count(world)==before_nodes,"skate edges: startup authoring adds no render nodes or colliders")
	check.call(world.get_route_definitions().size()==routes.size() and routes.size()==48,"skate edges: all48existing navigation routes remain intact")
	var ids: Array[String]=[]
	var unique := true
	var valid := true
	for line in lines:
		unique=unique and not ids.has(line.id)
		ids.append(line.id)
		valid=valid and line.is_valid and line.length>=Edges.MIN_LENGTH and line.points.size()>=2
	check.call(lines.size()>=90 and unique and valid,"skate edges: finite unique usable lines cover selected existing skate architecture")
	var second: Array=Edges.build(world)
	var stable := second.size()==lines.size()
	if stable:
		for index: int in range(lines.size()):
			stable=stable and second[index].id==lines[index].id and second[index].points==lines[index].points
	check.call(stable,"skate edges: rebuilding snapshots is deterministic without registering duplicate nodes")
	for family: String in ["Planter_","CourtSeat_","WorkshopSeat_","MarketCounter_","Bench_","StreetBenchSeat_","StreetBenchBack_","CivicGarden_","PlatformNorthGap_","ServiceWalkFront_","BridgeRail_","NorthEmbankment_","SouthEmbankment_","ParkGranite_"]:
		check.call(ids.any(func(id: String) -> bool: return id.begins_with(Edges.PREFIX+family)),"skate edges: registered visible feature family "+family)
	var counter_edges := 0
	var planter_edges := 0
	for id: String in ids:
		counter_edges+=int(id.begins_with(Edges.PREFIX+"MarketCounter_"))
		planter_edges+=int(id.begins_with(Edges.PREFIX+"Planter_"))
	check.call(counter_edges==16 and planter_edges==16,"skate edges: all four counters and four small planters expose each physical top edge")
	# A rotated/scaled prop must produce actual world geometry, not an unrotated
	# authoring rectangle that happens to work in the current identity-level map.
	var frame := Transform3D(Basis(Vector3.UP,PI/2)*Basis.from_scale(Vector3(2,1.5,3)),Vector3(11,4,-8))
	var corners: PackedVector3Array=Edges.box_top(frame,Vector3(4,2,6))
	check.call(corners.size()==4 and corners[0].distance_to(frame*Vector3(-2,1,-3)+Vector3.UP*Edges.SKIN)<0.00001 and absf(corners[0].distance_to(corners[1])-8)<0.00001 and absf(corners[1].distance_to(corners[2])-18)<0.00001,"skate edges: physical box transform preserves orientation scale and world-up contact skin")
	# Preserve pre-existing special/challenge rails; extra optional edges do not
	# replace IDs used by career fixtures or the ordered busking challenge.
	var preserved := true
	var after: Array=world.get_grind_lines()
	for old in existing:
		var found := false
		for current in after:
			if current.id==old.id and current.points==old.points:
				found=true
				break
		preserved=preserved and found
	check.call(preserved,"skate edges: previous authored tracks and challenge IDs are unchanged")
	_physical_contacts(world,lines,check)

static func _node_count(parent: Node) -> int:
	var count := 1
	for child: Node in parent.get_children(): count+=_node_count(child)
	return count


static func _physical_contacts(world: Node3D,lines: Array,check: Callable) -> void:
	var space := world.get_world_3d().direct_space_state
	var support_bad: Array[String]=[]
	var outside_bad: Array[String]=[]
	var ray_samples := 0
	var rail_only_samples := 0
	for line in lines:
		var samples := maxi(2,ceili(line.length/2.0))
		for index: int in range(samples+1):
			var at: Vector3=line.point_at(line.length*float(index)/samples)
			# The optional broken-bridge bars were already decorative rail-only
			# geometry. Ordinary supported props must pass actual floor/top rays.
			var rail_only: bool=String(line.id).begins_with(Edges.PREFIX+"BridgeRail_") and world.to_local(at).x>0
			if rail_only: rail_only_samples+=1
			else:
				ray_samples+=1
				if not _top_support(space,at): support_bad.append(line.id+" "+str(at))
			# Prove nearby live terrain below every selected edge; ground queries
			# alone cannot pass this broad off-centre contact assertion.
			var ground:=space.intersect_ray(PhysicsRayQueryParameters3D.create(at+Vector3.UP*0.08,at-Vector3.UP*5.0,1))
			if ground.is_empty() and not rail_only: outside_bad.append(line.id+" "+str(at))
	check.call(support_bad.is_empty(),"skate edges: actual short top rays support registered physical edges: "+str(support_bad.slice(0,8)))
	check.call(outside_bad.is_empty(),"skate edges: physical registrations stay above existing world support: "+str(outside_bad.slice(0,8)))
	for family: String in ["Planter_","CourtSeat_","WorkshopSeat_","ClosePocket_","PrintYard_","MarketCounter_","Bench_","StreetBenchSeat_","StreetBenchBack_","StairCheek_","BuskingPlinth_","CivicGarden_","PlatformNorthGap_","ServiceWalkFront_","BridgeRail_","NorthEmbankment_","SouthEmbankment_","ParkGranite_"]:
		var tested := false
		var clear := false
		for line in lines:
			if not String(line.id).begins_with(Edges.PREFIX+family): continue
			var a: Vector3=line.point_at(line.length*0.5)
			var b: Vector3=line.point_at(minf(line.length,line.length*0.5+0.2))
			tested=true
			clear=_capsule_clear(space,a,b)
			if clear: break
		check.call(tested and clear,"skate edges: real upright rider skin and short sweep clear representative "+family)
	print("SKATE EDGE CONTACTS rays=%d rail_only=%d top_failures=%d outside_failures=%d" % [ray_samples,rail_only_samples,support_bad.size(),outside_bad.size()])


static func _top_support(space: PhysicsDirectSpaceState3D,at: Vector3) -> bool:
	# Sample the actual bounded sole patch. A ray exactly on a thin back-slat
	# boundary can miss through precision; a seat end can also lie over a2cm
	# slat gap. Offsets include diagonals and stay within0.142m (<.28m capsule
	# radius); the strict20cm drop limit cannot accept the floor far below.
	var offsets: Array[Vector3]=[Vector3.ZERO]
	for radius: float in [.005,.02,.06,.1]:
		for x: float in [-1.0,0.0,1.0]:
			for z: float in [-1.0,0.0,1.0]:
				if x!=0.0 or z!=0.0: offsets.append(Vector3(x*radius,0,z*radius))
	for offset: Vector3 in offsets:
		var hit:=space.intersect_ray(PhysicsRayQueryParameters3D.create(at+offset+Vector3.UP*.08,at+offset-Vector3.UP*.2,3))
		if not hit.is_empty() and hit.normal.y>.25 and hit.position.y<=at.y+.02 and at.y-hit.position.y<=.2: return true
	return false


static func _capsule_clear(space: PhysicsDirectSpaceState3D,a: Vector3,b: Vector3) -> bool:
	var shape:=CapsuleShape3D.new()
	shape.radius=.28
	shape.height=1.7
	var query:=PhysicsShapeQueryParameters3D.new()
	query.shape=shape
	query.collision_mask=1
	query.margin=.002
	query.transform=Transform3D(Basis.IDENTITY,a+Vector3.UP*.85)
	if not space.intersect_shape(query,1).is_empty(): return false
	query.motion=b-a
	var motion:=space.cast_motion(query)
	return motion.size()==2 and motion[0]>.999
