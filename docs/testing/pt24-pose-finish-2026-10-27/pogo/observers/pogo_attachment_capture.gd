extends SceneTree
const Current = preload("res://game/player/skater.gd")
const Legacy = preload("res://.local/pogo_attachment_legacy_skater.gd")
const Authentic = preload("res://tests/authentic_pose_tests.gd")
const Attachment = preload("res://tests/skater_body_attachment_tests.gd")
const Catalog = preload("res://game/tricks/trick_catalog.gd")
const SIZE := Vector2i(960,800)
var output := "res://.local/pogo-attachment-captures"
var camera: Camera3D
var actor: CharacterBody3D
var records: Array[Dictionary]=[]
var failures:=0
func _initialize():_run.call_deferred()
func _run():
	if DisplayServer.get_name()=="headless":quit(2);return
	DirAccess.make_dir_recursive_absolute(output)
	root.size=SIZE;root.content_scale_size=SIZE
	var env:=WorldEnvironment.new()
	var settings:=Environment.new();settings.background_mode=Environment.BG_COLOR;settings.background_color=Color("9aaebd")
	settings.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;settings.ambient_light_color=Color.WHITE;settings.ambient_light_energy=.8
	env.environment=settings;root.add_child(env)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-55,-25,0);sun.light_energy=1.6;sun.shadow_enabled=true;root.add_child(sun)
	var floor:=StaticBody3D.new();root.add_child(floor)
	var shape:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(20,.2,20);shape.shape=box;shape.position.y=-.1;floor.add_child(shape)
	var mesh:=MeshInstance3D.new();var displayed:=BoxMesh.new();displayed.size=box.size;mesh.mesh=displayed;mesh.position.y=-.1
	var mat:=StandardMaterial3D.new();mat.albedo_color=Color("777d7b");mesh.material_override=mat;floor.add_child(mesh)
	camera=Camera3D.new();camera.position=Vector3(2.7,1.6,3.4);camera.fov=36;root.add_child(camera);camera.look_at(Vector3(0,.82,0))
	var start:=_sources()
	for rest: float in [0.0,PI]:
		var peak_tick:=0
		for old: bool in [true,false]:
			actor=Legacy.new() if old else Current.new();root.add_child(actor)
			actor.set_physics_process(false);actor.set_process(false);actor.global_position=Vector3.ZERO
			actor._visual.transform=Transform3D.IDENTITY
			camera.make_current()
			await physics_frame;await process_frame
			var fixture: Dictionary={"body":actor,"rider":actor._rider_visual,"board":actor._board_visual,"rig":actor._visual_rig,"rest_yaw":rest}
			var state:=Authentic._neutral()
			state.merge({"manual":true,"manual_definition":Catalog.definition("manual"),"deck_yaw":rest,"rest_deck_yaw":rest},true)
			var data:=Attachment._prepare(fixture.rig)
			_reset_pose(fixture,rest)
			for tick: int in 40:Authentic._manual_frame(fixture,state)
			state.manual_definition=Catalog.definition("pogo")
			if old:
				var largest:=0.0
				for tick: int in 40:
					Authentic._manual_frame(fixture,state)
					var sample:=Attachment._sample(actor,data)
					if sample.seam>largest:largest=sample.seam;peak_tick=tick
				_reset_pose(fixture,rest)
				state.manual_definition=Catalog.definition("manual")
				for tick: int in 40:Authentic._manual_frame(fixture,state)
				state.manual_definition=Catalog.definition("pogo")
			for tick: int in peak_tick+1:Authentic._manual_frame(fixture,state)
			var sample:=Attachment._sample(actor,data)
			var label: String=("before" if old else "after")+("-regular-entry" if rest==0.0 else "-reversed-entry")
			await _capture(label,fixture.rig,{"rest_yaw":rest,"ordinary_manual_prelude_calls":40,"pogo_entry_calls":peak_tick+1,"attachment":sample})
			actor.queue_free();await process_frame;await physics_frame
	var end:=_sources()
	if start!=end:failures+=1
	var report: Dictionary={"frames":records,"failures":failures,"source_stable":start==end,"source_before":start,"source_after":end,
		"method":"Two real native Skaters, immutable previous visual versus current visual, with identical controller source except visual preload. Original garments/Skin binds/assets unchanged. Automatic controller processing is disabled; explicit AuthenticPose manual-frame calls construct the declared Pogo entry at both rest yaws. The old-source largest cloth opening chooses the exact tick; both sources replay that identical entry call count. Completed native frame_post_draw readback. Static causal pose controls, not real input flight, ordinary camera acceptance or performance measurement."}
	var f:=FileAccess.open(output+"/manifest.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"\t")+"\n");f.close()
	print("POGO_CAPTURE frames=",records.size()," failures=",failures," source_stable=",start==end);quit(1 if failures else 0)
func _reset_pose(fixture: Dictionary,rest: float):
	fixture.board.rotation=Vector3(0,rest,0)
	fixture.rider.transform=Transform3D(Basis(Vector3.UP,-PI/2.0+.28),Vector3.ZERO)
	fixture.rig.reset()
func _capture(label: String,rig: RefCounted,info: Dictionary):
	actor.reset_physics_interpolation();await process_frame;await process_frame;await RenderingServer.frame_post_draw
	var frame:=root.get_texture().get_image();var path:=output+"/"+label+".png"
	if frame.get_size()!=SIZE or frame.save_png(path)!=OK:failures+=1
	info.merge({"file":label+".png","sha256":FileAccess.get_sha256(path),"size":[frame.get_width(),frame.get_height()],"torso":var_to_str(rig._upper.global_transform),"pogo_blend":rig._pogo_blend,"physics_enabled":actor.is_physics_processing(),"automatic_process":actor.is_processing(),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"video_memory_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),"texture_memory_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)})
	records.append(info)
	print("POGO_CAPTURE_FRAME ",label," ",info)
func _sources() -> Dictionary:
	var paths:=PackedStringArray(["res://project.godot","res://.local/pogo_attachment_capture.gd","res://.local/pogo_attachment_legacy_visual.gd","res://.local/pogo_attachment_legacy_skater.gd"])
	_collect("res://game",paths);paths.sort();var result: Dictionary={}
	for p: String in paths:result[p]=FileAccess.get_sha256(p)
	return result
func _collect(path: String,paths: PackedStringArray):
	var dir:=DirAccess.open(path)
	for f: String in dir.get_files():paths.append(path.path_join(f))
	for d: String in dir.get_directories():_collect(path.path_join(d),paths)
