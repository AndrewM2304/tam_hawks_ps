extends SceneTree
const Main=preload('res://game/main.gd')
func _initialize():run.call_deferred()
func run():
 root.size=Vector2i(1280,800)
 root.content_scale_size=root.size
 var frozen:Dictionary=JSON.parse_string(FileAccess.get_file_as_string('res://.local/pt24-capture/manifest.json')).source_sha256
 var game=Main.new()
 game.persistence_enabled=false
 root.add_child(game)
 game.start_mode(true)
 await process_frame
 await RenderingServer.frame_post_draw
 var frame:Image=root.get_texture().get_image()
 var result:int=frame.save_png('res://.local/pt24-capture/startup-normal-frame.png')
 var stable:=true
 for path:String in frozen:stable=stable and FileAccess.get_sha256(path)==frozen[path]
 var camera:Camera3D=game.skater._camera
 var data={'source_stable':stable,'source_sha256':frozen,'engine':Engine.get_version_info().string,'file':'startup-normal-frame.png','sha256':FileAccess.get_sha256('res://.local/pt24-capture/startup-normal-frame.png'),'process_frame':Engine.get_process_frames(),'physics_frame':Engine.get_physics_frames(),'rendered_frame':Engine.get_frames_drawn(),'camera_position':[camera.global_position.x,camera.global_position.y,camera.global_position.z],'method':'Unchanged Main start, one normal process frame then completed native frame_post_draw. No early force_draw; no profile persistence.'}
 var output:=FileAccess.open('res://.local/pt24-capture/startup-normal-frame.json',FileAccess.WRITE)
 output.store_string(JSON.stringify(data,'\t')+'\n')
 print('PT24_NORMAL_STARTUP saved=',result==OK,' source_stable=',stable,' process_frame=',Engine.get_process_frames())
 quit(0 if result==OK and stable else 1)
