extends "res://tools/full_fidelity_capture.gd"
## Actual Main dynamic snapshot check before a costly native render capture.
## Parser-only checks cannot validate properties reached through an untyped Node.

func _run() -> void:
	game=Main.new()
	game.level_id = "glasgow_legacy_v1" # Historical City Tour coordinates/workload.
	game.persistence_enabled=false
	root.add_child(game)
	game.start_mode(true)
	for tick in 40:
		await physics_frame
		await process_frame
	var state:=_snapshot(game)
	_check(state.transition_state==game.skater._feature_transition.state,
		"capture snapshot: actual Main authored-feature state uses its real transition helper")
	_check(state.cylindrical_transition_active==game.skater._transition.active \
		and state.cylindrical_transition_feature_id==str(game.skater._transition.feature.get("id","")),
		"capture snapshot: actual Main cylindrical transition records its real Dictionary identity and active flag")
	print("FULL_FIDELITY_SNAPSHOT_SMOKE checks=",checks," failures=",failures,
		" feature_state=",state.transition_state," cylindrical_active=",state.cylindrical_transition_active)
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
