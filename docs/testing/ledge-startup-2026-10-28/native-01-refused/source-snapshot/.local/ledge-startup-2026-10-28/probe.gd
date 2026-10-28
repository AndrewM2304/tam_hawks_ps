extends SceneTree
## Isolated startup attribution. Production source is never changed.
const Audit = preload("res://game/levels/surface_audit.gd")
const Main = preload("res://game/main.gd")

class CachedAudit extends "res://game/levels/surface_audit.gd":
	var exact_ground: Dictionary = {}
	var cache_hits := 0
	func _native_ledge_nearby(a: Vector3,b: Vector3,support: CollisionShape3D) -> Array[AABB]:
		# This hook is called once immediately before each synchronous edge scan.
		exact_ground.clear()
		return super(a,b,support)
	func _native_ledge_drop(a: Vector3,b: Vector3,outward: Vector3) -> bool:
		_ledge_work.intervals += 1
		for at: Vector3 in [a,(a+b)*0.5,b]:
			var point := at+outward*0.12
			var ground: float
			if exact_ground.has(point):
				ground = exact_ground[point]
				cache_hits += 1
			else:
				_ledge_work.terrain_query_count += 1
				ground = _world.get_ground_height(point)
				exact_ground[point] = ground
			var drop := at.y-NATIVE_LEDGE_SKIN-ground
			if not is_finite(ground) or drop<0.04 or drop>NATIVE_LEDGE_MAX_RISE: return false
		return true

class PointProofAudit extends "res://game/levels/surface_audit.gd":
	var proved_first_failures := 0
	func _native_ledge_drop(a: Vector3,b: Vector3,outward: Vector3) -> bool:
		# Reuse only the existing exact-provider conservative terrain proof.
		# Proving the original first sample is buried is enough to reject it.
		if _native_ledge_buried(a,a,outward):
			_ledge_work.intervals += 1
			proved_first_failures += 1
			return false
		return super(a,b,outward)

var _passes := 0
var _failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _check(value: bool,label: String) -> void:
	if value:
		_passes += 1
		print("PASS: ",label)
	else:
		_failures += 1
		push_error("FAIL: "+label)

func _line_snapshot(line) -> Dictionary:
	# All published script-variable fields, not only IDs/endpoints.
	var result: Dictionary = {}
	for property: Dictionary in line.get_property_list():
		if int(property.usage)&PROPERTY_USAGE_SCRIPT_VARIABLE == 0: continue
		var name: String = property.name
		if name == "curve":
			var curve: Curve3D = line.curve
			var points: Array = []
			for index: int in curve.point_count:
				points.append([curve.get_point_position(index),curve.get_point_in(index),curve.get_point_out(index),curve.get_point_tilt(index)])
			result[name] = {"bake_interval":curve.bake_interval,"points":points,"baked_length":curve.get_baked_length()}
		elif name == "native_support_rids":
			var owners: Array[int] = []
			for rid: RID in line.native_support_rids: owners.append(rid.get_id())
			result[name] = owners
		else:
			result[name] = line.get(name)
	return result

func _published(audit) -> Dictionary:
	var report: Dictionary = audit.snapshot()
	report.erase("native_ledge_fallback")
	var guides: Array[Dictionary] = []
	for line in audit.lines: guides.append(_line_snapshot(line))
	return {"surface_inventory":report,"ordered_guides":guides}

func _write(path: String,value: Variant) -> void:
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file == null:
		_check(false,"artifact write "+path)
		return
	file.store_string(JSON.stringify(value,"\t",false,true)+"\n")

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		quit(2);return
	var output := ProjectSettings.globalize_path(args[0]).simplify_path()
	var allowed := ProjectSettings.globalize_path("res://.local/ledge-startup-2026-10-28/").simplify_path().trim_suffix("/")+"/"
	if not (output+"/").begins_with(allowed) or FileAccess.file_exists(output+"/RESULTS.json"):
		quit(2);return
	if DirAccess.make_dir_recursive_absolute(output) != OK:
		quit(2);return
	var game = Main.new()
	game.persistence_enabled = false
	root.add_child(game)
	game.skater.set_physics_process(false)
	game.skater.set_process(false)
	# No input route, moving renderer or frame-rate measurement is performed.
	await process_frame
	_check(not game.persistence_enabled,"personal profile and Music isolated before tree entry")
	var defaults := {"main_default":bool(game.get_meta("pt24_design_preview",false)),
		"world_default":bool(game.world.get_meta("pt24_design_preview",false)),
		"station":game.world.find_child("StationRailway",true,false)!=null,
		"train":game.world.find_child("ScenicTwoCoachTrain",true,false)!=null,
		"pond":game.world.find_child("KelvingrovePond",true,false)!=null,
		"civic_return":game.world.find_child("CivicPortReturn",true,false)!=null,
		"central_green":game.world.has_meta("pt24_central_green_report")}
	_check(not defaults.values().has(false),"ordinary Main default trial content present")
	# Reuse the ORIGINAL startup authored set, excluding this audit's own derived lines.
	var authored: Array = game.world._surface_audit._authored.duplicate()
	var original_published := _published(game.world._surface_audit)
	var reference: Dictionary = {}
	var cases: Array[Dictionary] = []
	for kind: String in ["production-a1","exact-edge-cache","point-buried-proof","production-a2"]:
		var audit
		if kind == "exact-edge-cache": audit = CachedAudit.new()
		elif kind == "point-buried-proof": audit = PointProofAudit.new()
		else: audit = Audit.new()
		var started := Time.get_ticks_usec()
		audit.build(game.world,authored)
		var elapsed: int = Time.get_ticks_usec()-started
		var published := _published(audit)
		if kind == "production-a1": reference = published
		var exact: bool = published == reference
		_check(exact,"complete ordered guide and surface parity "+kind)
		_check(published == original_published,"ordinary initial startup parity "+kind)
		var work: Dictionary = audit.snapshot().native_ledge_fallback
		_check(int(work.native_space_queries)==0,"no native-physics construction queries "+kind)
		var record := {"kind":kind,"elapsed_us":elapsed,"work":work,
			"exact_full_published_parity":exact,"initial_startup_parity":published==original_published,
			"cache_hits":audit.cache_hits if kind=="exact-edge-cache" else 0,
			"proved_first_failures":audit.proved_first_failures if kind=="point-buried-proof" else 0}
		_write(output+"/"+kind+"-published.json",published)
		_write(output+"/"+kind+"-work.json",record)
		cases.append(record)
		print("LEDGE_STARTUP_CASE ",JSON.stringify(record))
	var report := {"scope":"same ordinary Mainworld startup attribution; no FPS, Mac or production admission",
		"defaults":defaults,"original_authored_count":authored.size(),"cases":cases,
		"passes":_passes,"failures":_failures,"production_source_changed":false,
		"candidate_scope":"local subclass only; no gameplay or runtime activation"}
	_write(output+"/RESULTS.json",report)
	game.queue_free()
	await process_frame
	await physics_frame
	print("RESULT: ",_passes," passed, ",_failures," failed")
	quit(0 if _failures==0 else 1)
