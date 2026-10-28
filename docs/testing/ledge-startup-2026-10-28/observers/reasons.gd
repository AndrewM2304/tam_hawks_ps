extends "res://.local/ledge-startup-2026-10-28/probe.gd"
## Exact original drop algorithm plus observation only; no candidate rejection.
class ReasonAudit extends "res://game/levels/surface_audit.gd":
	var outcomes: Dictionary = {"accepted":0,"low":0,"high":0,"nonfinite":0}
	var first_failures: Dictionary = {"low":0,"high":0,"nonfinite":0}
	var later_failures: Dictionary = {"low":0,"high":0,"nonfinite":0}
	var examples: Dictionary = {"accepted":[],"low":[],"high":[],"nonfinite":[]}
	var edges: Array[Dictionary] = []
	var edge: Dictionary = {}
	func _native_ledge_nearby(a: Vector3,b: Vector3,support: CollisionShape3D) -> Array[AABB]:
		var owner := support.get_parent()
		edge = {"body_path":str(_world.get_path_to(owner)),"label":str(owner.get_meta("art_label",owner.name)),
			"shape_path":str(_world.get_path_to(support)),"a":a,"b":b,"edge_y":a.y,
			"intervals":0,"accepted":0,"low":0,"high":0,"nonfinite":0,
			"first_low":0,"first_high":0,"first_nonfinite":0,
			"finite_ground_min":INF,"finite_ground_max":-INF,"drop_min":INF,"drop_max":-INF}
		edges.append(edge)
		return super(a,b,support)
	func _native_ledge_drop(a: Vector3,b: Vector3,outward: Vector3) -> bool:
		_ledge_work.intervals += 1
		edge.intervals += 1
		var sample_index := 0
		var first: Dictionary = {}
		for at: Vector3 in [a,(a+b)*0.5,b]:
			_ledge_work.terrain_query_count += 1
			var point := at+outward*0.12
			var ground: float = _world.get_ground_height(point)
			var drop := at.y-NATIVE_LEDGE_SKIN-ground
			if sample_index==0: first={"at":at,"point":point,"ground":ground,"drop":drop}
			if is_finite(ground):
				edge.finite_ground_min=minf(edge.finite_ground_min,ground)
				edge.finite_ground_max=maxf(edge.finite_ground_max,ground)
				edge.drop_min=minf(edge.drop_min,drop)
				edge.drop_max=maxf(edge.drop_max,drop)
			var reason := ""
			if not is_finite(ground):reason="nonfinite"
			elif drop<0.04:reason="low"
			elif drop>NATIVE_LEDGE_MAX_RISE:reason="high"
			if not reason.is_empty():
				outcomes[reason]+=1;edge[reason]+=1
				if sample_index==0:
					first_failures[reason]+=1;edge["first_"+reason]+=1
				else:later_failures[reason]+=1
				if examples[reason].size()<20:
					examples[reason].append({"body_path":edge.body_path,"label":edge.label,
						"edge_a":edge.a,"edge_b":edge.b,"sample_index":sample_index,
						"point":point,"at":at,"ground":ground,"drop":drop,"first":first})
				return false
			sample_index+=1
		outcomes.accepted+=1;edge.accepted+=1
		if examples.accepted.size()<20:
			examples.accepted.append({"body_path":edge.body_path,"label":edge.label,"first":first})
		return true

func _provider_values(world,point: Vector3) -> Dictionary:
	# Supplementary provider queries happen AFTER the observed audit, not in its counters.
	var local: Vector3=world.to_local(point)
	var core: float=world._terrain.height_at(local.x,local.z)
	if is_finite(core):core=world.to_global(Vector3(local.x,core,local.z)).y
	var pond := NAN
	if is_instance_valid(world._park_pond):pond=world._park_pond.get_ground_height(point)
	var outdoor := NAN
	if is_instance_valid(world._outdoors):outdoor=world._outdoors.get_ground_height(point.x,point.z)
	var winner := "pond" if is_finite(pond) else "core" if is_finite(core) and (not is_finite(outdoor) or core>=outdoor) else "outdoor" if is_finite(outdoor) else "none"
	return {"point":point,"pond":pond,"core":core,"outdoor":outdoor,"precedence_winner":winner}

func _run() -> void:
	var args:=OS.get_cmdline_user_args()
	if args.size()!=2 or args[1]!=".local/ledge-startup-2026-10-28/probe.gd":quit(2);return
	var output:=ProjectSettings.globalize_path(args[0]).simplify_path()
	var allowed:=ProjectSettings.globalize_path("res://.local/ledge-startup-2026-10-28/").simplify_path().trim_suffix("/")+"/"
	if not (output+"/").begins_with(allowed) or FileAccess.file_exists(output+"/RESULTS.json"):quit(2);return
	if DirAccess.make_dir_recursive_absolute(output)!=OK:quit(2);return
	var game=Main.new();game.persistence_enabled=false;root.add_child(game)
	game.skater.set_physics_process(false);game.skater.set_process(false)
	await process_frame
	_check(not game.persistence_enabled,"personal profile and Music isolated before tree entry")
	_check(bool(game.get_meta("pt24_design_preview",false)) and bool(game.world.get_meta("pt24_design_preview",false)),"ordinary Main default trial content enabled")
	var original:=_published(game.world._surface_audit)
	var original_work: Dictionary=game.world._surface_audit.snapshot().native_ledge_fallback
	var authored: Array=game.world._surface_audit._authored.duplicate()
	var audit:=ReasonAudit.new()
	var started:=Time.get_ticks_usec();audit.build(game.world,authored)
	var elapsed:=Time.get_ticks_usec()-started
	var published:=_published(audit)
	var work: Dictionary=audit.snapshot().native_ledge_fallback
	_check(published==original,"complete original ordered guides, support RIDs and surface inventory unchanged")
	var original_counts:=original_work.duplicate();original_counts.erase("audit_startup_us")
	var observed_counts:=work.duplicate();observed_counts.erase("audit_startup_us")
	_check(observed_counts==original_counts,"all original algorithm work counters unchanged")
	var total:=0
	for count: int in audit.outcomes.values():total+=count
	_check(total==int(work.intervals),"every actual drop interval has exactly one observed outcome")
	_check(int(work.native_space_queries)==0,"native physics construction queries remain zero")
	for reason: String in audit.examples:
		for example: Dictionary in audit.examples[reason]:
			var point: Vector3=example.get("point",example.first.point)
			example["provider_values"]=_provider_values(game.world,point)
	_write(output+"/observed-published.json",published)
	var report: Dictionary={"scope":"read-only startup first-failure attribution; unchanged original algorithm and complete parity; no FPS/Mac claim",
		"elapsed_us":elapsed,"work":work,"outcomes":audit.outcomes,"first_failures":audit.first_failures,
		"later_failures":audit.later_failures,"edges":audit.edges,"examples":audit.examples,
		"full_published_parity":published==original,"all_work_counts_equal":observed_counts==original_counts,
		"passes":_passes,"failures":_failures}
	_write(output+"/RESULTS.json",report)
	print("LEDGE_FIRST_FAILURES ",JSON.stringify({"outcomes":audit.outcomes,"first_failures":audit.first_failures,"later_failures":audit.later_failures,"work":work}))
	game.queue_free();await process_frame;await physics_frame
	print("RESULT: ",_passes," passed, ",_failures," failed")
	quit(0 if _failures==0 else 1)
