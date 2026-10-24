extends RefCounted
## Original connected skate lines within the six existing districts. Native
## terrain construction keeps visible bank, support query and collision aligned.

const Bowl = preload("res://game/levels/bowl_feature.gd")
const Halfpipe = preload("res://game/levels/halfpipe_feature.gd")
const Spine = preload("res://game/levels/spine_feature.gd")
var features: Array[Dictionary] = []
var routes: Array[Dictionary] = []
var _transitions: Array[Node3D] = []
var _world: Node3D


func build(world: Node3D) -> void:
	_world = world
	_bank_line("exchange_south_line", "royal_exchange", Vector3(0,0,34), 6,4,4,0.55)
	_seat("exchange_south_return", "royal_exchange",Vector3(12,0,34),Vector3(18,0,34),0.48)
	_bank_line("civic_lower_island", "george_square",Vector3(0,4,-64),6,4,5,0.50)
	_seat("civic_island_return", "george_square",Vector3(13,4,-68),Vector3(13,4,-60),0.46)
	_climbing_rail("east_climbing_handrail",90.5)
	_climbing_rail("west_climbing_handrail",-91.5)
	_seat("merchant_low_return","central_station",Vector3(-81,1,-66.5),Vector3(-76,1,-66.5),0.45)
	_bank_line("station_low_manual", "central_station",Vector3(-114,2,-13.5),6,2.2,2.2,0.36)
	_bank_line("barras_forecourt_line", "barras",Vector3(65,0,35),6,4,4,0.55)
	_seat("barras_forecourt_return", "barras",Vector3(74,0,36),Vector3(84,0,36),0.48)
	_bank_line("clyde_south_link", "clyde",Vector3(-60,2,123),6,3.5,4,0.48)
	_seat("clyde_south_return", "clyde",Vector3(-47,2,123),Vector3(-38,2,123),0.48)
	_south_quay_relay()
	_graded_seat("park_lower_carve",Rect2(-187,-90,10,1.2),0.48)
	_graded_seat("park_upper_return",Rect2(-194,-172,11,1.2),0.46)
	_graded_seat("park_east_carve",Rect2(-159,-155,7,1.2),0.46)
	_graded_seat("park_station_lower",Rect2(-160,-32,1.2,11),0.46)
	_graded_seat("park_station_upper",Rect2(-138,-61,1.2,9),0.46)
	_graded_seat("park_east_lower",Rect2(-155,-140,1.2,8),0.46)
	_graded_seat("park_east_gateway",Rect2(-154,-116,1.2,8),0.46)
	_graded_seat("park_civic_gateway",Rect2(-68,-129.7,12,1.0),0.46)
	var bowl := Bowl.new()
	bowl.radius = 2.4
	bowl.floor_radius = 3.5
	bowl.deck_length = 1.8
	_transition(bowl,"ClydeEastBowl",Vector3(122,2,66),PI*0.5,"clyde")
	var halfpipe := Halfpipe.new()
	halfpipe.radius = 2.2
	halfpipe.width = 8.0
	halfpipe.flat_length = 6.0
	halfpipe.deck_length = 2.5
	_transition(halfpipe,"StationConcourseHalfpipe",Vector3(-60,2,35),PI*0.5,"central_station")
	var spine := Spine.new()
	spine.radius = 2.2
	spine.width = 8.0
	spine.cap_width = 0.6
	_transition(spine,"StationWestSpine",Vector3(-110,2,30),0,"central_station")


func get_grind_lines() -> Array:
	var lines: Array = []
	for feature: Node3D in _transitions: lines.append_array(feature.get_grind_lines())
	return lines


func get_features() -> Array[Dictionary]:
	var result := features.duplicate(true)
	for feature: Node3D in _transitions:
		for definition: Dictionary in feature.get_feature_definitions():
			definition = definition.duplicate(true)
			definition.district = feature.get_meta("district")
			definition.position = feature.global_position
			var ids: Array[String] = []
			for line in feature.get_grind_lines(): ids.append(line.id)
			definition.grind_ids = ids
			definition.review_from = feature.global_position + Vector3(12,3.0,12)
			definition.review_target = feature.global_position + Vector3.UP
			result.append(definition)
	return result


func density_snapshot() -> Dictionary:
	var districts: Dictionary = {}
	var tracks: Array = _world.get_grind_lines()
	var anchors := get_features()
	for feature: Dictionary in _world._outdoors.get_skate_feature_definitions():
		var center: Vector2 = feature.bounds.get_center()
		anchors.append({"position":Vector3(center.x,feature.floor_y,center.y)})
	for route: Dictionary in _world.get_route_definitions():
		if route.get("requires_jump",false): continue
		var points: PackedVector3Array = route.points
		for segment in range(points.size()-1):
			var count := maxi(1,ceili(points[segment].distance_to(points[segment+1])/6.0))
			for step in count:
				var at := points[segment].lerp(points[segment+1],float(step)/count)
				var district: String = _world.get_district_id(at)
				if not districts.has(district): districts[district] = {"samples":0,"within_20m":0,"within_35m":0,"max_distance_m":0.0,"farthest_at":at}
				var distance := INF
				for line in tracks:
					var near: Dictionary = line.closest(at)
					if absf(near.point.y-at.y) <= 2.5:
						distance = minf(distance,Vector2(at.x,at.z).distance_to(Vector2(near.point.x,near.point.z)))
				for anchor: Dictionary in anchors:
					if absf(anchor.position.y-at.y) <= 2.5:
						distance = minf(distance,Vector2(at.x,at.z).distance_to(Vector2(anchor.position.x,anchor.position.z)))
				var record: Dictionary = districts[district]
				record.samples += 1
				if distance <= 20.0: record.within_20m += 1
				if distance <= 35.0: record.within_35m += 1
				if distance > record.max_distance_m:
					record.max_distance_m = distance
					record.farthest_at = at
	var quay_span := {"samples":0,"within_15m":0,"max_distance_m":0.0,"bounds":Rect2(-38,116,73,14)}
	# Review found a real quiet strip missed by navigation-only sampling.
	# Cover the explorable quay width as well as the new through route.
	for column in 14:
		for z: float in [118.5,123.0,127.5]:
			var at := Vector3(lerpf(-38,35,float(column)/13.0),2,z)
			var distance := INF
			for track in tracks:
				var near: Dictionary = track.closest(at)
				if absf(near.point.y-at.y)<=2.5:
					distance = minf(distance,Vector2(at.x,at.z).distance_to(Vector2(near.point.x,near.point.z)))
			quay_span.samples += 1
			if distance<=15.0: quay_span.within_15m += 1
			quay_span.max_distance_m = maxf(quay_span.max_distance_m,distance)
	return {"districts":districts,"sample_spacing_m":6.0,"new_line_count":routes.size(),
		"explorable_spans":{"clyde_south_quay":quay_span},
		"method":"Horizontal proximity from non-jump navigation samples to a real grind track or authored feature within 2.5m vertical difference; not pathfinding or a claim every approach is reachable."}


func _transition(feature: Node3D,id: String,at: Vector3,yaw: float,district: String) -> void:
	feature.name = id
	feature.feature_id = id
	feature.position = at
	feature.rotation.y = yaw
	feature.set_meta("district",district)
	_world.add_child(feature)
	_transitions.append(feature)


func _bank_line(id: String,district: String,at: Vector3,pad_width: float,run: float,depth: float,rise: float) -> void:
	var west := at.x-pad_width*0.5-run
	var east := at.x+pad_width*0.5+run
	var top := at.y+rise
	var pad_bounds := Rect2(at.x-pad_width*0.5,at.z-depth*0.5,pad_width,depth)
	var body: StaticBody3D = _world._flat(id+"ManualDeck",pad_bounds,top,"cut_stone")
	_world._perimeter_grind(body,"Grind_Ledge_"+id)
	_world._slope(id+"WestBank",Rect2(west,pad_bounds.position.y,run,depth),Vector4(at.y,top,top,at.y),"paving")
	_world._slope(id+"EastBank",Rect2(pad_bounds.end.x,pad_bounds.position.y,run,depth),Vector4(top,at.y,at.y,top),"paving")
	# Stone top joints and flush metal edges give the small manual decks an
	# authored civic construction treatment without adding landing obstacles.
	for side: float in [-1.0,1.0]:
		_world._box(_world,id+"Edge",Vector3(at.x,top+0.006,at.z+side*depth*0.5),Vector3(pad_width,0.012,0.045),"iron")
	var points := PackedVector3Array([Vector3(west-4,at.y,at.z),Vector3(west,at.y,at.z),
		Vector3(pad_bounds.position.x,top,at.z),Vector3(pad_bounds.end.x,top,at.z),
		Vector3(east,at.y,at.z),Vector3(east+4,at.y,at.z)])
	routes.append({"id":id,"label":id.replace("_"," "),"points":points,"requires_jump":false})
	features.append({"id":id,"district":district,"kind":"bank_manual_ledge_line","position":at,
		"bounds":Rect2(west,pad_bounds.position.y,east-west,depth),"floor_y":at.y,
		"approach":PackedVector3Array([points[0],points[1]]),"landing":PackedVector3Array([points[4],points[5]]),
		"line":points,"grind_ids":["Grind_Ledge_"+id],"rise":rise,
		"review_from":at+Vector3(11,2.6,9),"review_target":at+Vector3.UP*0.7})


func _seat(id: String,district: String,start: Vector3,end: Vector3,height: float) -> void:
	var points := PackedVector3Array([start+Vector3.UP*(height+0.12),end+Vector3.UP*(height+0.12)])
	_world._build_seating_ledge("Grind_Ledge_"+id,points,start.y,height)
	var center := (start+end)*0.5
	features.append({"id":id,"district":district,"kind":"return_ledge","position":center,
		"floor_y":start.y,"line":points,"grind_ids":["Grind_Ledge_"+id],
		"review_from":center+Vector3(7,2.2,7),"review_target":center+Vector3.UP*0.6})


func _graded_seat(id: String,bounds: Rect2,rise: float) -> void:
	var corners := [Vector3(bounds.position.x,0,bounds.position.y),Vector3(bounds.end.x,0,bounds.position.y),
		Vector3(bounds.end.x,0,bounds.end.y),Vector3(bounds.position.x,0,bounds.end.y)]
	var heights := Vector4.ZERO
	for index in 4: heights[index] = _world.get_ground_height(corners[index])+rise
	# Follow the hill along the bench, while keeping its narrow seat level
	# across the slope. The lower side becomes a visible retaining face rather
	# than a twisted strip or a top edge buried inside the grass.
	if bounds.size.x >= bounds.size.y:
		var west := maxf(heights.x,heights.w)
		var east := maxf(heights.y,heights.z)
		heights = Vector4(west,east,east,west)
	else:
		var north := maxf(heights.x,heights.y)
		var south := maxf(heights.z,heights.w)
		heights = Vector4(north,north,south,south)
	var body: StaticBody3D = _world._slope(id,bounds,heights,"cut_stone")
	_world._perimeter_grind(body,"Grind_Ledge_"+id)
	var center := Vector3(bounds.get_center().x,0,bounds.get_center().y)
	center.y = minf(minf(heights.x,heights.y),minf(heights.z,heights.w))-rise
	features.append({"id":id,"district":"kelvingrove","kind":"graded_park_ledge","position":center,
		"bounds":bounds,"floor_y":center.y,"grind_ids":["Grind_Ledge_"+id],
		"review_from":center+Vector3(8,2.6,7),"review_target":center+Vector3.UP*0.5})


func _climbing_rail(id: String,x: float) -> void:
	var points := PackedVector3Array()
	for z: float in [-72.0,-68.0,-64.0,-60.0,-56.0,-52.0,-48.0]:
		var at := Vector3(x,0,z)
		at.y = _world.get_ground_height(at)+0.78
		points.append(at)
	_world._grind_path("Grind_Rail_"+id,points,"rail")
	var at := points[points.size()/2] - Vector3.UP*0.78
	features.append({"id":id,"district":"barras" if x>0 else "central_station","kind":"climbing_handrail","position":at,
		"line":points,"floor_y":at.y,"grind_ids":["Grind_Rail_"+id],
		"review_from":at+Vector3(-5 if x>0 else 5,2.4,7),"review_target":at+Vector3.UP*0.8})


func _south_quay_relay() -> void:
	_bank_line("clyde_south_middle","clyde",Vector3(-20,2,125),5.5,3.5,3.4,0.48)
	var points := PackedVector3Array([Vector3(-7,2.56,127.5),Vector3(-1,2.56,127.5)])
	for i in range(1,9):
		var t := float(i)/8.0
		points.append(Vector3(-1+10*t,2.56,127.5-1.5*smoothstep(0,1,t)))
	points.append(Vector3(15,2.56,126))
	var ledge_id := "Grind_Ledge_ClydeSouthRelay"
	_world._build_seating_ledge(ledge_id,points,2.0,0.44)
	features.append({"id":"clyde_south_curved_seat","district":"clyde","kind":"curved_return_ledge",
		"position":Vector3(4,2,126.75),"floor_y":2.0,"line":points,"grind_ids":[ledge_id],
		"review_from":Vector3(-9,4.4,120),"review_target":Vector3(7,2.5,126.5)})
	var rail_id := "Grind_Rail_ClydeSouthRelay"
	_world._rail(rail_id,Vector3(22.5,2,126),8.0)
	var author: Node3D = _world._rail_authors.back()
	author.rotation.y = PI*0.5
	for child: Node in author.get_children():
		if child is StaticBody3D:
			child.set_meta("authored_grind_ids",[rail_id])
			child.set_meta("audit_capture_ids",[rail_id])
	for x: float in [18.92,26.08]:
		_world._box(_world,"QuayRelayRailFoot",Vector3(x,2.018,126),Vector3(0.3,0.036,0.3),"iron")
	features.append({"id":"clyde_south_relay_rail","district":"clyde","kind":"quay_flatbar",
		"position":Vector3(22.5,2,126),"floor_y":2.0,"grind_ids":[rail_id],
		"review_from":Vector3(15,4.2,120),"review_target":Vector3(22.5,2.7,126)})
	_world._label(_world,"SouthQuaySeatPlaque","SOUTH QUAY / PRINT YARD",Vector3(12,2.27,125.68),18,"cream",Vector3(0,180,0),0.006)
	routes.append({"id":"clyde_south_east_west","label":"South quay linked-feature through lane",
		"points":PackedVector3Array([Vector3(-38,2,120),Vector3(-12,2,120),Vector3(12,2,120),Vector3(35,2,120)]),"requires_jump":false})
