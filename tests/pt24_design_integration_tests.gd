extends RefCounted
## Candidate construction is explicit. Ordinary play admission is checked
## separately; these witnesses exercise the complete real Main integration.
const Main = preload("res://game/main.gd")
const Green = preload("res://tests/pt24_central_green_tests.gd")
const Pond = preload("res://tests/park_pond_tests.gd")
const Layout = preload("res://tests/pt24_connected_runs_tests.gd")
const Routes = preload("res://tests/world_routes_tests.gd")

static func run(tree: SceneTree,check: Callable) -> void:
	for action: String in InputMap.get_actions(): Input.action_release(action)
	var game := Main.new()
	game.persistence_enabled = false
	game.set_meta("pt24_design_preview",true)
	tree.root.add_child(game)
	game.start_mode(true)
	for frame in 25:
		await tree.physics_frame
		await tree.process_frame
	var railway: Node3D = game.world.get_node_or_null("StationRailway")
	check.call(railway != null and railway.built and railway.report.budget_pass,
		"PT24 candidate integration: real Main constructs the complete bounded railway")
	for span: Array in [[Vector3(-126,2,0),Vector3(-145,2,0)],
		[Vector3(-82,2,34),Vector3(-82,2,-34)],
		[Vector3(-42,6,-122),Vector3(-34,6,-122)]]:
		check.call(Routes._clear_sweep(game.world,span[0],span[1])
			and Routes._clear_sweep(game.world,span[1],span[0]),
			"PT24 candidate integration: actual railway and civic return preserve two-way route "+str(span))
	await Green.run(tree,game.world,check)
	await Pond.run_installed(tree,game,check)
	await Pond.run_player(tree,game,check)
	await Layout._civic_port(tree,game,check)
	for action: String in InputMap.get_actions(): Input.action_release(action)
	game.queue_free()
	await tree.process_frame
	await tree.physics_frame
	await tree.process_frame
