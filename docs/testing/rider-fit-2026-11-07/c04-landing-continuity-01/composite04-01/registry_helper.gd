extends RefCounted
## Read-only one-shot data collection from an already-created ordinary Main.
## Caller owns source freeze/engine lease. This file does not create/reset/drive
## a rider, configure an activity, add geometry or issue physics queries.

static func capture(game: Node) -> Dictionary:
	var world: Node3D=game.world
	var lines: Array[Dictionary]=[]
	for line: RefCounted in world.get_grind_lines():
		var fields: Dictionary={}
		for property: Dictionary in line.get_property_list():fields[String(property.name)]=true
		var record: Dictionary={"id":line.id,"kind":line.kind,"points":line.points,"length":line.length,
			"valid":line.is_valid,"loop":line.is_loop}
		for key: String in ["contact_verified","contact_source","contact_vertical_offset","contact_normal_offset",
			"contact_edge_outward","body_profile_radius","body_profile_source","contact_round_declared",
			"contact_round_radius","contact_round_deck_reveal","contact_round_outward","contact_round_shape"]:
			if fields.has(key):record[key]=line.get(key)
		lines.append(record)
	var world_routes: Array=world.get_route_definitions()
	var hud_routes: Array=world_routes.duplicate(true)
	if is_instance_valid(game.feature_hub):hud_routes.append_array(game.feature_hub.get_route_definitions())
	return _plain({"schema":"actual-main-public-registry-v1","engine":Engine.get_version_info(),
		"physics_frame":Engine.get_physics_frames(),"world_frame":world.global_transform,
		"normal_main_preview_content_enabled":world.get_meta("pt24_design_preview",false),
		"gap_trigger_authority":"Main passes skater.global_position and skater.airborne",
		"gaps":world.get_gap_definitions(),"world_routes":world_routes,"hud_routes":hud_routes,
		"features":world.get_skate_feature_definitions(),"grind_lines":lines,
		"encounters":world.get_encounter_definitions(),"checkpoints":world.get_district_checkpoints(),
		"surface_audit":world.get_surface_audit()})

static func _plain(value: Variant) -> Variant:
	if value is float and not is_finite(value):return {"nonfinite":str(value)}
	if value is Vector3:return [value.x,value.y,value.z]
	if value is Vector2:return [value.x,value.y]
	if value is Vector4:return [value.x,value.y,value.z,value.w]
	if value is Rect2:return {"position":_plain(value.position),"size":_plain(value.size)}
	if value is AABB:return {"position":_plain(value.position),"size":_plain(value.size)}
	if value is Transform3D:return {"basis":[_plain(value.basis.x),_plain(value.basis.y),_plain(value.basis.z)],"origin":_plain(value.origin)}
	if value is Dictionary:
		var result: Dictionary={}
		for key: Variant in value:result[str(key)]=_plain(value[key])
		return result
	if value is Array or value is PackedVector3Array or value is PackedVector2Array or value is PackedStringArray:
		var result: Array=[]
		for item: Variant in value:result.append(_plain(item))
		return result
	if value is Object or value is RID:return str(value)
	return value
