extends RefCounted
## Real unchanged 60Hz rider physics; only camera observation cadence varies.
const Fixtures = preload("res://tests/camera_turn_review_tests.gd")
const Chase = preload("res://game/player/chase_camera.gd")
const Setup = preload("res://game/core/input_setup.gd")

static func run(tree: SceneTree,check: Callable) -> void:
	Setup.register_actions()
	var reports: Array[Dictionary] = []
	for cadence: int in [1,2,4,8]:
		var fixture: Dictionary = await Fixtures._fixture(tree)
		var rider: CharacterBody3D = fixture.rider
		# Avoid an extra hidden camera update between the declared observations.
		# Native rider physics/visual contacts and ordinary push remain active.
		rider.set_process(false)
		var camera: Camera3D = rider._camera
		var solver := Chase.new()
		var maximum_arm := 0.0
		var supported := true
		var framed := true
		var initial: Vector3 = rider.global_position
		var rows: Array[Dictionary] = []
		Input.action_press("push")
		for tick in 360:
			await Fixtures._frames(tree,1)
			if (tick+1)%cadence==0:
				solver.update(rider,camera,float(cadence)/60.0,1.0,false)
				if tick>=180:
					var arm: float = camera.global_position.distance_to(rider.get_global_transform_interpolated().origin+Vector3.UP*1.05)
					maximum_arm=maxf(maximum_arm,arm)
					framed=framed and Fixtures._framed(rider)
				supported=supported and rider.is_on_floor() and not rider.bailing
			rows.append({"body":rider.global_transform,"velocity":rider.velocity,"speed":rider.speed,
				"camera":camera.global_transform,"camera_update":(tick+1)%cadence==0})
		Input.action_release("push")
		check.call(supported and rider.global_position.distance_to(initial)>10.0 and rider.speed>8.0,
			"camera cadence: ordinary push remains supported and advances at60Hz with camera every%d ticks"%cadence)
		check.call(framed,"camera cadence: actual head/feet/native sightlines remain clear at%.1fHz"%(60.0/cadence))
		check.call(maximum_arm<12.0,"camera cadence: open-lane camera keeps a readable bounded arm at%.1fHz"%(60.0/cadence))
		reports.append({"cadence_ticks":cadence,"maximum_arm_m":maximum_arm,"supported":supported,"framed":framed,"rows":rows})
		print("CAMERA_CADENCE ticks=",cadence," max_arm_m=",maximum_arm," supported=",supported," framed=",framed)
		await Fixtures._dispose(tree,fixture)
	var destination := OS.get_environment("TAM_CAMERA_CADENCE_OUTPUT")
	if not destination.is_empty():
		var file := FileAccess.open(destination,FileAccess.WRITE)
		file.store_string(JSON.stringify({"cases":reports,"scope":"Native unchanged rider physics; camera updates sampled at60/30/15/7.5Hz. No rendering/hardware/performance claim."},"\t")+"\n")
		file.close()
