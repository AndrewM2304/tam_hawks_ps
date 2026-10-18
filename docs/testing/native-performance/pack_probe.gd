extends SceneTree
## Current performance/classic-mechanics construction; reuses the gallery probe.
## Linux engine reads each PCK;
## this is not a launch of the macOS executable or a rendered gameplay test.

const REQUIRED_MODULES: Array[String] = [
	"res://game/characters/market_encounter.gd",
	"res://game/characters/market_actor.gd",
	"res://game/levels/art/barras_market.gd",
	"res://game/levels/art/clyde_landmarks.gd",
	"res://game/levels/art/exchange_gallery.gd",
]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var report: Dictionary = {}
	for path: String in REQUIRED_MODULES:
		if not load(path) is GDScript:
			_fail("Missing packaged district script: " + path)
			return
	var main_scene := load("res://game/main.tscn") as PackedScene
	if main_scene == null:
		_fail("Missing main scene")
		return
	var instance := main_scene.instantiate()
	if instance.get_script() == null:
		instance.free()
		_fail("Missing main script")
		return
	# _ready constructs the ordinary world, actors and carried-bag attachment.
	# Developer-script runs already disable persistence; require that contract.
	root.add_child(instance)
	if instance.persistence_enabled:
		instance.free()
		_fail("Unexpected profile persistence in package probe")
		return
	report.main_scene_loaded = true
	var resources: Dictionary = {"loaded_scripts": REQUIRED_MODULES, "constructed_nodes": {}}
	for label: String in ["BarrasCoveredMarket", "BarrowlandLandmark", "ClydeLandmarks", "MarketStallholder", "DeliveryCounter", "MarketGull", "CourierBag", "ExchangeGalleryArchitecture", "GalleryEntranceTerrace", "GalleryEntranceWestBank", "GalleryEntranceEastBank", "GalleryEntranceFrontBank", "GalleryDoorThreshold", "ExchangeWestShopTerrace", "ExchangeWestShopBank", "ExchangeWestShopNorthCorner", "ExchangeWestShopSouthCorner"]:
		var node := instance.find_child(label, true, false)
		if node == null:
			instance.free()
			_fail("Main did not construct " + label)
			return
		var geometry_count := node.find_children("*", "GeometryInstance3D", true, false).size()
		if geometry_count < 1:
			instance.free()
			_fail("Constructed node has no renderable geometry: " + label)
			return
		resources.constructed_nodes[label] = {"child_count": node.get_child_count(), "geometry_descendants": geometry_count}
	var encounter: Node = instance.get_node("MarketEncounter")
	var state: Dictionary = encounter.status_snapshot()
	if state.id != "gull_proof_delivery" or state.state != "idle" or state.required_gap != "market_hop":
		instance.free()
		_fail("Market encounter did not configure its ordinary idle state")
		return
	var actor: Node = encounter.get_node("MarketStallholder")
	if actor.get_script() != load(REQUIRED_MODULES[1]) or encounter.get_script() != load(REQUIRED_MODULES[0]):
		instance.free()
		_fail("Constructed market nodes use unexpected scripts")
		return
	var bag: Node = instance.get_node_or_null("Skater/SkaterVisual/Rider/TorsoRig/CourierBag")
	if bag == null or bag.visible:
		instance.free()
		_fail("Courier bag was not attached hidden to the rider torso")
		return
	var route_ids: Array[String] = []
	for definition: Dictionary in instance.world.get_encounter_definitions():
		if definition.id == "gull_proof_delivery":
			for route: Dictionary in definition.routes:
				route_ids.append(String(route.id))
	route_ids.sort()
	if route_ids.size() != 2:
		instance.free()
		_fail("Expected both configured market route choices")
		return
	resources.market = {"id":state.id,"state":state.state,"required_gap":state.required_gap,"route_ids":route_ids,"courier_bag_attached_hidden":true}
	resources.checkpoint_count = instance.world.get_district_checkpoints().size()
	if resources.checkpoint_count != 6:
		instance.free()
		_fail("Expected six ordinary district checkpoints")
		return
	var exchange := _inspect_exchange(instance)
	if exchange.is_empty():
		instance.free()
		return
	resources.exchange_gallery = exchange
	var performance := _inspect_performance(instance)
	if performance.is_empty():
		instance.free()
		return
	resources.performance = performance
	report.district_resources = resources
	instance.free()

	# Retain the earlier deterministic sound/resource regression independently
	# of the new visual construction, with no real audio driver or listening claim.
	var script := load("res://game/characters/bin_percussion.gd") as GDScript
	if script == null:
		_fail("Missing retained original bin percussion")
		return
	var stream: AudioStreamWAV = script.stream()
	var cached: AudioStreamWAV = script.stream()
	var pcm: PackedByteArray = stream.data
	var minimum := 32767
	var maximum := -32768
	for index in range(0, pcm.size(), 2):
		var value := pcm.decode_s16(index)
		minimum = mini(minimum, value)
		maximum = maxi(maximum, value)
	if stream.format != AudioStreamWAV.FORMAT_16_BITS or stream.mix_rate != 22050 or stream.stereo or pcm.size() != 352800 or absf(stream.get_length()-8.0)>0.001 or stream.loop_mode != AudioStreamWAV.LOOP_FORWARD or stream.loop_begin != 0 or stream.loop_end != 176400 or stream != cached or minimum >= 0 or maximum <= 0:
		_fail("Unexpected percussion stream/cache/loop parameters")
		return
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(pcm)
	var pcm_sha256 := context.finish().hex_encode()
	report.bin_percussion = {"resource":"res://game/characters/bin_percussion.gd","pcm_sha256":pcm_sha256,"pcm_bytes":pcm.size(),"mix_rate":stream.mix_rate,"seconds":stream.get_length(),"format":"PCM16","stereo":stream.stereo,"loop_begin":stream.loop_begin,"loop_end":stream.loop_end,"cached_identity":stream==cached,"minimum_sample":minimum,"maximum_sample":maximum}
	var output := FileAccess.open(OS.get_cmdline_user_args()[0], FileAccess.WRITE)
	if output == null:
		_fail("Cannot write audit report")
		return
	output.store_string(JSON.stringify(report, "\t")+"\n")
	output.close()
	print("INDEPENDENT PACK PROBE PASS: Main constructed current performance/classic mechanics and retained districts; original percussion")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)

func _inspect_exchange(instance: Node) -> Dictionary:
	var architecture := instance.find_child("ExchangeGalleryArchitecture", true, false)
	var columns := get_nodes_in_group("gallery_portico_columns")
	if architecture == null or int(architecture.get_meta("column_count", 0)) != 8 or columns.size() != 8:
		_fail("Expected the new eight-column gallery architecture")
		return {}
	var helper := load("res://game/levels/art/exchange_gallery.gd") as GDScript
	var expected_positions: PackedVector3Array = helper.column_positions()
	if expected_positions.size() != 8:
		_fail("Shared portico helper does not supply eight column positions")
		return {}
	var column_report: Array[Dictionary] = []
	for index in range(8):
		var column: Node3D = instance.world.get_node_or_null("GalleryPorticoColumn%d" % (index+1))
		if column == null or not column is StaticBody3D or column.position.distance_to(expected_positions[index]) > 0.0001:
			_fail("Missing/misaligned packaged gallery column")
			return {}
		var shape_count := column.find_children("*", "CollisionShape3D", true, false).size()
		if shape_count != 3:
			_fail("Packaged gallery column lacks its base, shaft or capital solid")
			return {}
		column_report.append({"name":String(column.name),"position":[column.position.x,column.position.y,column.position.z],"collision_shapes":shape_count})
	var expected_routes: Array[String] = ["gallery_entrance_bank_loop", "gallery_entrance_front_return", "gallery_entrance_bypass", "exchange_west_bank_loop", "exchange_west_bypass"]
	var available_routes: Dictionary = {}
	for route: Dictionary in instance.world.get_route_definitions():
		available_routes[String(route.id)] = route.points.size()
	if available_routes.size() != 48:
		_fail("Expected the current 48 authored route definitions")
		return {}
	var route_report: Dictionary = {}
	for route_id: String in expected_routes:
		if not available_routes.has(route_id) or int(available_routes[route_id]) < 2:
			_fail("Missing packaged Exchange route: " + route_id)
			return {}
		route_report[route_id] = available_routes[route_id]
	var found_grinds: Array[String] = []
	for line in instance.world.get_grind_lines():
		if String(line.id) in ["Grind_Ledge_GalleryEntrance", "Grind_Ledge_ExchangeShops"]:
			found_grinds.append(String(line.id))
	found_grinds.sort()
	if found_grinds.size() != 2:
		_fail("Missing new packaged gallery/shop seating ledge")
		return {}
	return {"architecture_column_count":8,"columns":column_report,"route_count":available_routes.size(),"new_routes":route_report,"new_grind_ids":found_grinds,"construction_only":true,"physical_route_or_art_acceptance_claim":false}

func _inspect_performance(instance: Node) -> Dictionary:
	for path: String in ["res://game/levels/static_batches.gd", "res://game/levels/city_visibility.gd", "res://game/core/graphics_quality.gd", "res://game/levels/transition_park.gd", "res://game/tricks/directional_tricks.gd", "res://game/player/trick_animation.gd"]:
		if not load(path) is GDScript:
			_fail("Missing current performance/classic script: " + path)
			return {}
	var camera: Camera3D = instance.skater.get_node("ChaseCamera")
	var viewport: Viewport = instance.get_viewport()
	var sun: DirectionalLight3D = instance.world.get_node("LateAfternoonSun")
	if not is_equal_approx(camera.near, 0.2) or not is_equal_approx(camera.far, 220.0) or viewport.msaa_3d != Viewport.MSAA_2X or not is_equal_approx(viewport.scaling_3d_scale, 1.0) or not is_equal_approx(sun.directional_shadow_max_distance, 45.0) or viewport.use_occlusion_culling:
		_fail("Current Balanced graphics budgets/native-occlusion state differ")
		return {}
	if not bool(ProjectSettings.get_setting("physics/common/physics_interpolation", false)) or instance.physics_interpolation_mode != Node.PHYSICS_INTERPOLATION_MODE_OFF or instance.skater.physics_interpolation_mode != Node.PHYSICS_INTERPOLATION_MODE_ON or camera.physics_interpolation_mode != Node.PHYSICS_INTERPOLATION_MODE_OFF:
		_fail("Current native displayed-rider/chase interpolation is absent")
		return {}
	var batches: Dictionary = instance.world.static_batch_report
	if not batches.get("valid_configuration", false) or not is_equal_approx(float(batches.cell_size), 64.0) or batches.validation_failures != 0 or batches.sources_removed - batches.batches_created != 234 or batches.instances_preserved != 17387:
		_fail("Current selected static-batch construction differs")
		return {}
	var bodies: int = instance.world.find_children("*", "StaticBody3D", true, false).size()
	var shapes: int = instance.world.find_children("*", "CollisionShape3D", true, false).size()
	if bodies != 351 or shapes != 1863:
		_fail("Current world collision inventory differs")
		return {}
	var transition_ids: Array[String] = []
	for feature: Dictionary in instance.world.get_transition_features():
		transition_ids.append(String(feature.id))
	transition_ids.sort()
	if transition_ids != ["clyde_half_east", "clyde_half_west", "clyde_quarter"]:
		_fail("Missing current quarter/half-pipe transition features")
		return {}
	var catalog: GDScript = load("res://game/tricks/trick_catalog.gd")
	var ids: Array[String] = catalog.ids()
	for id: String in ["kickflip", "heelflip", "frontside_shuvit", "pop_shuvit", "varial_flip", "hardflip", "melon_grab", "indy_grab", "nose_grab", "tail_grab", "method_grab", "manual", "nose_manual", "axle_stall", "nose_stall", "tail_stall", "disaster"]:
		if not ids.has(id):
			_fail("Missing current packaged trick: " + id)
			return {}
	# Engine-owned --main-pack is consumed before get_cmdline_args(). Use the
	# actual virtual project file to establish pack context and prove the check ran.
	if FileAccess.file_exists("res://project.binary"):
		if DirAccess.dir_exists_absolute("res://art_source"):
			_fail("Isolated art prototype was unexpectedly exported")
			return {}
		print("PACK ART EXCLUSION CHECK: art_source absent")
	elif not FileAccess.file_exists("res://project.godot"):
		_fail("Probe could not identify source or exported project")
		return {}
	return {"graphics_quality":"balanced", "scale_3d":viewport.scaling_3d_scale, "msaa_3d":viewport.msaa_3d, "far_m":camera.far, "near_m":camera.near, "shadow_distance_m":sun.directional_shadow_max_distance, "occlusion_enabled":viewport.use_occlusion_culling, "native_interpolation":true, "static_batches":batches, "static_bodies":bodies, "collision_shapes":shapes, "transition_ids":transition_ids, "trick_ids":ids, "construction_only":true}
