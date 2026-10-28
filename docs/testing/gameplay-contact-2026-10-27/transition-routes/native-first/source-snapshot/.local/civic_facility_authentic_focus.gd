extends SceneTree
## Two original route scopes; no copied player or test implementation.
const Main=preload("res://game/main.gd")
const Civic=preload("res://tests/pt24_civic_park_run_tests.gd")
const Facility=preload("res://tests/pt24_facility_connection_tests.gd")
const Authentic=preload("res://tests/authentic_fidelity_integration_tests.gd")
var passed:=0
var failed:=0

func _initialize()->void:_run.call_deferred()

func _run()->void:
	var requested:=OS.get_cmdline_user_args()
	if requested.is_empty():requested=PackedStringArray(["design","authentic"])
	var selected:Dictionary={}
	for scope:String in requested:
		if scope not in ["design","authentic"] or selected.has(scope):
			_check(false,"focused selector must be unique design or authentic")
			_finish()
			return
		selected[scope]=true
	# Preserve the suite's original design-before-historical ordering even when
	# both selectors are requested. Each world is disposed before the next.
	if selected.has("design"):await _design()
	if selected.has("authentic"):await _authentic()
	_finish()

func _design()->void:
	var game:=Main.new()
	game.persistence_enabled=false
	root.add_child(game)
	game.start_mode(true)
	await Civic.Driver._frames(self,25)
	_check(not game.persistence_enabled and not game.music._can_control and game.music._worker==null,
		"focused design Main preserves scripted profile and personal Music isolation")
	_check(bool(game.get_meta("pt24_design_preview",false)),
		"focused design Main uses ordinary default-enabled content")
	print("FOCUS_BEGIN design/civic_park_original_run")
	await Civic.run(self,game,_check)
	print("FOCUS_BEGIN design/facility_connection_original_run_same_actor")
	await Facility.run(self,game,_check)
	await _dispose(game)

func _authentic()->void:
	var game:=Main.new()
	game.persistence_enabled=false
	# Match run_tests.gd's historical Main for this exact source test family.
	game.set_meta("pt24_design_preview",false)
	root.add_child(game)
	await Civic.Driver._frames(self,35)
	_check(not game.persistence_enabled and not game.music._can_control and game.music._worker==null,
		"focused historical Main preserves scripted profile and personal Music isolation")
	_check(not bool(game.get_meta("pt24_design_preview",true)),
		"focused Authentic Main retains the required suite's historical content control")
	print("FOCUS_BEGIN authentic/original_facility_journey_then_deep_and_shallow_skating")
	# Original run() owns timing, phases, camera samples and resets. Its facility
	# cases stay adjacent, and facility_skating itself retains Deep then Shallow.
	await Authentic.run(self,game,_check,Callable(),["facility","facility_skating"])
	await _dispose(game)

func _dispose(game:Node)->void:
	for action:StringName in InputMap.get_actions():Input.action_release(action)
	game.queue_free()
	await process_frame
	await physics_frame
	await process_frame

func _check(ok:bool,label:String)->void:
	if ok:passed+=1;print("PASS: ",label)
	else:failed+=1;push_error("FAIL: "+label)

func _finish()->void:
	print("RESULT: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)
