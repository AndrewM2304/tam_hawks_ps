extends SceneTree
const Current = preload("res://game/player/skater.gd")
const Legacy = preload("res://.local/skitch_attachment_capture_before_skater.gd")
const Authentic = preload("res://tests/authentic_pose_tests.gd")
const Attachment = preload("res://tests/skater_body_attachment_tests.gd")
const SIZE:=Vector2i(960,800)
var output:="res://.local/skitch-attachment-captures"
var actor: CharacterBody3D
var camera: Camera3D
var records: Array[Dictionary]=[]
var failures:=0
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	if DisplayServer.get_name()=="headless":quit(2);return
	DirAccess.make_dir_recursive_absolute(output)
	root.size=SIZE;root.content_scale_size=SIZE
	var environment:=WorldEnvironment.new()
	var settings:=Environment.new();settings.background_mode=Environment.BG_COLOR;settings.background_color=Color("9aaebd")
	settings.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;settings.ambient_light_color=Color.WHITE;settings.ambient_light_energy=.8
	environment.environment=settings;root.add_child(environment)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-55,-25,0);sun.light_energy=1.6;sun.shadow_enabled=true;root.add_child(sun)
	var floor:=StaticBody3D.new();root.add_child(floor)
	var collision:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=Vector3(20,.2,20);collision.shape=shape;collision.position.y=-.1;floor.add_child(collision)
	var ground:=MeshInstance3D.new();var box:=BoxMesh.new();box.size=shape.size;ground.mesh=box;ground.position.y=-.1
	var material:=StandardMaterial3D.new();material.albedo_color=Color("777d7b");ground.material_override=material;floor.add_child(ground)
	var bar:=MeshInstance3D.new();var beam:=BoxMesh.new();beam.size=Vector3(1.04,.08,.08);bar.mesh=beam;bar.position=Vector3(0,.93,-.545)
	var iron:=StandardMaterial3D.new();iron.albedo_color=Color("485963");bar.material_override=iron;root.add_child(bar)
	camera=Camera3D.new();camera.position=Vector3(2.8,1.5,2.6);camera.fov=36;root.add_child(camera);camera.look_at(Vector3(0,.8,-.15))
	var before:=_sources()
	for released: bool in [false,true]:
		for old: bool in [true,false]:
			actor=Legacy.new() if old else Current.new();root.add_child(actor)
			actor.set_physics_process(false);actor.set_process(false);actor.global_position=Vector3.ZERO
			actor._visual.transform=Transform3D.IDENTITY
			actor._visual_rig.reset()
			camera.make_current();await physics_frame;await process_frame
			var rig: RefCounted=actor._visual_rig
			var data:=Attachment._prepare(rig)
			var state:=Authentic._neutral()
			for tick in 60:rig.animate(1.0/60.0,state)
			var grips: Array[Vector3]=[Vector3(-.40,.93,-.505),Vector3(.40,.93,-.505)]
			state.merge({"skitching":true,"skitch_grips":grips,"skitch_normal":Vector3.BACK},true)
			for tick in 60:rig.animate(1.0/60.0,state)
			if released:
				state.skitching=false;state.skitch_grips=[]
				for tick in 6:rig.animate(1.0/60.0,state)
			var label: String=("before" if old else "after")+("-released" if released else "-held")
			var info:=Attachment._sample(actor,data)
			actor.reset_physics_interpolation();await process_frame;await process_frame;await RenderingServer.frame_post_draw
			var frame:=root.get_texture().get_image();var path:=output+"/"+label+".png"
			if frame.get_size()!=SIZE or frame.save_png(path)!=OK:failures+=1
			info.merge({"file":label+".png","sha256":FileAccess.get_sha256(path),"size":[frame.get_width(),frame.get_height()],"neutral_calls":60,"tow_calls":60,"release_calls":6 if released else 0,"tow_blend":rig._skitch_blend,"physics_enabled":actor.is_physics_processing(),"automatic_process":actor.is_processing(),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"video_memory_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),"texture_memory_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)})
			records.append(info);print("SKITCH_CAPTURE_FRAME ",label," ",info)
			actor.queue_free();await process_frame;await physics_frame
	var after:=_sources()
	if before!=after:failures+=1
	var report: Dictionary={"frames":records,"failures":failures,"source_stable":before==after,"source_before":before,"source_after":after,"method":"Two real native Skaters with the same frozen current controller except a preload-only before-visual redirect. The before visual reverses only the three skitch attachment hunks, preserving the current grab fallback cache and all other changes. Original garments/Skin binds/assets unchanged. Automatic controller processing is disabled; declared Rig.animate calls construct the existing authentic Skitch handle fixture:60neutral,60tow and optionally6release calls. An authored visible bar marks the same palm targets; this is not a running vehicle. Identical lighting/camera/environment, completed native frame_post_draw readbacks. Static causal garment views, not ordinary input, moving-cart, physical feel or performance acceptance; the separate ordinary-Main native case supplies input/contact/score evidence."}
	var file:=FileAccess.open(output+"/manifest.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t")+"\n");file.close()
	print("SKITCH_CAPTURE frames=",records.size()," failures=",failures," source_stable=",before==after)
	quit(1 if failures else 0)
func _sources() -> Dictionary:
	var paths:=PackedStringArray(["res://project.godot","res://.local/skitch_attachment_capture.gd","res://.local/skitch_attachment_capture.sh","res://.local/skitch_attachment_capture_before_visual.gd","res://.local/skitch_attachment_capture_before_skater.gd"])
	_collect("res://game",paths);paths.sort();var hashes: Dictionary={}
	for path: String in paths:hashes[path]=FileAccess.get_sha256(path)
	return hashes
func _collect(path: String,paths: PackedStringArray) -> void:
	var directory:=DirAccess.open(path)
	for file: String in directory.get_files():paths.append(path.path_join(file))
	for child: String in directory.get_directories():_collect(path.path_join(child),paths)
