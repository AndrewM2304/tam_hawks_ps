extends "res://.local/park-route-repair/bend_probe.gd"
func _run()->void:
	var game=Main.new();game.persistence_enabled=false;root.add_child(game);game.start_mode(true)
	var inverse:Transform3D=game.skater._board_visual.global_transform.affine_inverse()
	for mesh:MeshInstance3D in game.skater._visual_rig.board_contact_geometry().meshes:
		cached_meshes.append({"path":str(mesh.get_path()),"faces":mesh.mesh.get_faces(),"local":inverse*mesh.global_transform})
	await Density._actual_ledge_admission(self,game,_check,_observe,"Grind_Park_FiveStepHubba")
	Driver._release();game.queue_free();await process_frame
	print("RESULT: ",passed," passed, ",failed," failed");quit(1 if failed else 0)
