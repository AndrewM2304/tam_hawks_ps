extends SceneTree
## Isolated asset presentation fixture; no gameplay or performance certification.
var records:Array[Dictionary]=[]
func _initialize(): _run.call_deferred()
func _run():
	if DisplayServer.get_name()=="headless": quit(2); return
	root.size=Vector2i(1280,800)
	root.content_scale_size=root.size
	root.msaa_3d=Viewport.MSAA_2X
	var world:=Node3D.new()
	root.add_child(world)
	var environment:=Environment.new()
	environment.background_mode=Environment.BG_COLOR
	environment.background_color=Color("b4bec3")
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color=Color("c7dfeb")
	environment.ambient_light_energy=0.44
	environment.tonemap_mode=Environment.TONE_MAPPER_ACES
	var env:=WorldEnvironment.new()
	env.environment=environment
	world.add_child(env)
	var sun:=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-42,-32,0)
	sun.light_color=Color("ffe8d1")
	sun.light_energy=0.8
	sun.shadow_enabled=true
	sun.shadow_opacity=0.65
	sun.directional_shadow_max_distance=45
	world.add_child(sun)
	var ground:=MeshInstance3D.new()
	var plane:=PlaneMesh.new()
	plane.size=Vector2(50,50)
	ground.mesh=plane
	var material:=StandardMaterial3D.new()
	material.albedo_color=Color("64706b")
	material.roughness=0.9
	ground.material_override=material
	ground.position.y=-0.015
	world.add_child(ground)
	var camera:=Camera3D.new()
	camera.near=0.2
	camera.far=220
	world.add_child(camera)
	camera.make_current()
	for id:String in ["near","mid","far"]:
		var resource:PackedScene=load("res://glasgow_bay_"+id+".glb")
		if resource==null: quit(1); return
		var model:=resource.instantiate()
		world.add_child(model)
		var meshes:=model.find_children("*","MeshInstance3D",true,false)
		if meshes.size()!=1 or meshes[0].mesh.get_surface_count()!=4: quit(1); return
		for view:Dictionary in [{"id":"front","at":Vector3(0,8,20),"target":Vector3(0,8,0),"fov":55.0},{"id":"detail","at":Vector3(3.8,3.2,6.5),"target":Vector3(0,4.2,0),"fov":60.0}]:
			camera.position=view.at
			camera.fov=view.fov
			camera.look_at(view.target)
			for tick in 4: await process_frame
			RenderingServer.force_draw(true,1.0/60.0)
			var name:String=id+"-"+view.id+".png"
			if root.get_texture().get_image().save_png("res://"+name)!=OK: quit(1); return
			records.append({"image":name,"lod":id,"view":view.id,"surfaces":meshes[0].mesh.get_surface_count(),"bounds":str(meshes[0].mesh.get_aabb()),"asset_sha256":FileAccess.get_sha256("res://glasgow_bay_"+id+".glb"),"camera":str(camera.transform),"fov":camera.fov})
		world.remove_child(model)
		model.free()
	var output:=FileAccess.open("res://report.json",FileAccess.WRITE)
	output.store_string(JSON.stringify({"engine":Engine.get_version_info().string,"adapter":RenderingServer.get_video_adapter_name(),"renderer":RenderingServer.get_current_rendering_method(),"images":records,"errors":0,"performance_measurement":false,"limits":"Isolated GLB import and static front/detail presentation. Matches production ambient/light/ACES values, with neutral background/ground and no scene fog. Not live placement, LOD switching, before/after fidelity, Mac, physics or performance acceptance."},"\t")+"\n")
	print("BAY_PREVIEW images=",records.size()," errors=0")
	quit(0)
