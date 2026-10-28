extends "res://.local/park-route-repair/bend_probe.gd"
var proof_metrics:Dictionary={"grinding_updates":0,"maximum_certificates_per_check":0,"maximum_vertex_tests_per_check":0,"minimum_proved_gap_m":INF,"maximum_native_queries_per_check":0,"hit_cap":false,"vertex_cap":false}
func _run()->void:
	var game=Main.new();game.persistence_enabled=false;root.add_child(game);game.start_mode(true)
	var inverse:Transform3D=game.skater._board_visual.global_transform.affine_inverse()
	for mesh:MeshInstance3D in game.skater._visual_rig.board_contact_geometry().meshes:
		cached_meshes.append({"path":str(mesh.get_path()),"faces":mesh.mesh.get_faces(),"local":inverse*mesh.global_transform})
	await Density._actual_ledge_admission(self,game,_check,_observe,"Grind_Park_FiveStepHubba")
	print("HUBBA_PROOF_METRICS ",JSON.stringify(proof_metrics))
	Driver._release();game.queue_free();await process_frame
	print("RESULT: ",passed," passed, ",failed," failed");quit(1 if failed else 0)

func _observe(phase:String,game:Node,tick:int)->void:
	var rider:CharacterBody3D=game.skater
	if rider.grinding:
		var cache=rider._grind_clearance
		proof_metrics.grinding_updates+=1
		proof_metrics.maximum_certificates_per_check=maxi(proof_metrics.maximum_certificates_per_check,cache.last_support_certificates)
		proof_metrics.maximum_vertex_tests_per_check=maxi(proof_metrics.maximum_vertex_tests_per_check,cache.last_support_vertex_tests)
		if cache.last_support_certificates>0:proof_metrics.minimum_proved_gap_m=minf(proof_metrics.minimum_proved_gap_m,cache.last_support_minimum_gap)
		proof_metrics.maximum_native_queries_per_check=maxi(proof_metrics.maximum_native_queries_per_check,cache.last_path_queries)
		proof_metrics.hit_cap=proof_metrics.hit_cap or cache.last_support_hit_cap
		proof_metrics.vertex_cap=proof_metrics.vertex_cap or cache.last_support_vertex_cap
	super._observe(phase,game,tick)
