extends "res://.local/park-route-repair/hubba_precision.gd"
const Variants=preload("res://tests/grind_variant_contact_tests.gd")
func _run()->void:
	var game=Main.new();game.persistence_enabled=false;root.add_child(game);game.start_mode(true)
	var inverse:Transform3D=game.skater._board_visual.global_transform.affine_inverse()
	for mesh:MeshInstance3D in game.skater._visual_rig.board_contact_geometry().meshes:
		cached_meshes.append({"path":str(mesh.get_path()),"faces":mesh.mesh.get_faces(),"local":inverse*mesh.global_transform})
	await Density._actual_ledge_admission(self,game,_check,_observe,"Grind_Park_FiveStepHubba")
	print("HUBBA_PROOF_METRICS ",JSON.stringify(proof_metrics))
	Driver._release();game.queue_free();await physics_frame;await process_frame;await physics_frame;await process_frame
	await Variants.run(self,_check)
	print("RESULT: ",passed," passed, ",failed," failed");quit(1 if failed else 0)
