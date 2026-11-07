extends SceneTree
## Read-only ordinary-Main guide inventory. Contact metadata is not a ride proof.
const Main=preload("res://game/main.gd")
var destination:="res://.local/grind-contact-audit.json"
func _initialize()->void:_run.call_deferred()
func _run()->void:
	var arguments:=OS.get_cmdline_user_args()
	if not arguments.is_empty():destination=arguments[0]
	if not destination.is_absolute_path():destination="res://"+destination
	destination=ProjectSettings.globalize_path(destination)
	var game=Main.new()
	game.level_id = "glasgow_legacy_v1" # Historical City Tour coordinates/workload.
	game.persistence_enabled=false
	root.add_child(game)
	game.start_mode(true)
	for tick in 2:
		await physics_frame
		await process_frame
	var owners:Dictionary={}
	for surface:Dictionary in game.world.get_surface_audit().surfaces:
		for identity:String in surface.grind_ids:
			if not owners.has(identity):owners[identity]=[]
			owners[identity].append({"path":surface.path,"label":surface.label,
				"shape_type":surface.shape_type,"shape_count":surface.shape_count,
				"collision_layer":surface.collision_layer,"position":_v(surface.position),
				"box_size":_v(surface.box_size)})
	var groups:Dictionary={}
	var records:Array[Dictionary]=[]
	var seen:Dictionary={}
	var duplicates:Array[String]=[]
	var verified:=0
	var body_only:=0
	for line in game.world.get_grind_lines():
		var identity:=String(line.id)
		if seen.has(identity):duplicates.append(identity)
		seen[identity]=true
		var source:=String(line.contact_source) if line.contact_verified else "legacy.unverified"
		if not line.contact_verified and identity.begins_with("Grind_Edge_"):source="legacy.semantic_edges"
		elif not line.contact_verified and line.body_profile_radius>0.0:source="legacy.body_profile_only"
		if not groups.has(source):groups[source]={"count":0,"length_m":0.0,"ids":[]}
		groups[source].count+=1
		groups[source].length_m+=line.length
		groups[source].ids.append(identity)
		if line.contact_verified:verified+=1
		elif line.body_profile_radius>0.0:body_only+=1
		var points:Array=[]
		var min_y:=INF
		var max_y:=-INF
		for point:Vector3 in line.points:
			points.append(_v(point))
			min_y=minf(min_y,point.y)
			max_y=maxf(max_y,point.y)
		records.append({"id":identity,"kind":String(line.kind),"is_valid":line.is_valid,
			"is_loop":line.is_loop,"length_m":line.length,"points":points,"height_range_m":max_y-min_y,
			"contact_verified":line.contact_verified,"contact_source":line.contact_source,
			"neutral_generic_fallback_eligible":not line.contact_verified or line.contact_edge_outward==Vector3.ZERO,
			"contact_vertical_offset_m":line.contact_vertical_offset,"contact_normal_offset_m":line.contact_normal_offset,
			"contact_edge_outward":_v(line.contact_edge_outward),"native_support_rid_count":line.native_support_rids.size(),
			"body_profile_radius_m":line.body_profile_radius,"body_profile_source":line.body_profile_source,
			"source_group":source,"associated_native_owners":owners.get(identity,[])})
	records.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return String(a.id)<String(b.id))
	var result:={"version":1,"engine":Engine.get_version_info().string,"production_main":true,
		"profile_writes_enabled":game.persistence_enabled,
		"scope":"Runtime metadata and native-owner association inventory only; no pose injection, ride acceptance, visual certification or automatic contact reconfiguration.",
		"total":records.size(),"verified_metadata":verified,"unverified_metadata":records.size()-verified,
		"unverified_with_body_profile":body_only,"duplicate_ids":duplicates,"source_groups":groups,"guides":records}
	DirAccess.make_dir_recursive_absolute(destination.get_base_dir())
	var output:=FileAccess.open(destination,FileAccess.WRITE)
	if output==null:
		push_error("Could not write guide contact inventory: "+destination)
		game.queue_free()
		quit(1)
		return
	output.store_string(JSON.stringify(result,"\t")+"\n")
	output.close()
	print("GRIND_CONTACT_AUDIT total=",records.size()," verified_metadata=",verified,
		" unverified_metadata=",records.size()-verified," body_profile_only=",body_only," duplicate_ids=",duplicates)
	game.queue_free()
	await process_frame
	quit(0 if duplicates.is_empty() else 1)
func _v(value:Vector3)->Array:return [value.x,value.y,value.z]
