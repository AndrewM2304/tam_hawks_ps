extends SceneTree
const Main=preload("res://game/main.gd")
const Checks=preload("res://tests/horizon_background_tests.gd")
func _initialize()->void:_run.call_deferred()
func _run()->void:
 var output:String=OS.get_cmdline_user_args()[0]
 root.size=Vector2i(1280,800)
 root.content_scale_size=root.size
 var game=Main.new()
 game.persistence_enabled=false
 root.add_child(game)
 game.apply_settings({"graphics_quality":"balanced"},false)
 game.skater.set_controls_enabled(false)
 await physics_frame
 game.start_mode(true)
 game.skater.set_controls_enabled(false)
 for warm:int in 4:await RenderingServer.frame_post_draw
 var material:ShaderMaterial=game.world.get_node("HorizonContext").get_meta("panorama_material")
 var cube:TextureLayered=material.get_shader_parameter("context_sky")
 var imported:Dictionary=Checks._imported_cube(cube)
 var pixels:Array=[]
 for face:int in range(6):
  var gpu:Image=cube.get_layer_data(face)
  var cpu:Image=imported.faces[face]
  cpu.decompress()
  if gpu.is_compressed():gpu.decompress()
  var row:Dictionary={"face":face,"format":gpu.get_format(),"mips":gpu.get_mipmap_count(),"samples":[]}
  for point:Vector2i in [Vector2i(512,512),Vector2i(0,0),Vector2i(1023,1023),Vector2i(512,1023)]:
   row.samples.append({"at":[point.x,point.y],"gpu":str(gpu.get_pixelv(point)),"import":str(cpu.get_pixelv(point))})
  pixels.append(row)
 var camera:=Camera3D.new()
 root.add_child(camera)
 camera.fov=66
 camera.far=220
 camera.global_transform=Transform3D(Basis(Vector3(1,0,0),Vector3(0,.965838,-.259146),Vector3(0,.259146,.965838)),Vector3(-52,8.699185,-116.2))
 camera.make_current()
 for frame:int in 3:await RenderingServer.frame_post_draw
 var rays:Array=[]
 for pixel:Vector2 in [Vector2(1240,280),Vector2(1240,315),Vector2(1240,350),Vector2(1220,385),Vector2(300,330)]:
  var origin:Vector3=camera.project_ray_origin(pixel)
  var end:Vector3=origin+camera.project_ray_normal(pixel)*150
  var hit:Dictionary=game.world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(origin,end,1))
  rays.append({"pixel":str(pixel),"hit":str(hit.get("position","")),"body":str(hit.collider.get_path()) if hit.has("collider") else "none"})
 root.get_texture().get_image().save_png(output.path_join("connector-probe.png"))
 var result:Dictionary={"valid":true,"purpose":"Native readbackAPI and actual connector-body identification; no performance or acceptance claim","pixels":pixels,"rays":rays}
 var file:=FileAccess.open(output.path_join("capture.json"),FileAccess.WRITE)
 file.store_string(JSON.stringify(result,"\t")+"\n")
 print(JSON.stringify(result))
 quit(0)
