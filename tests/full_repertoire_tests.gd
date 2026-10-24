extends RefCounted
## Reachability and pose contracts for the full repertoire. Main/rig integration
## must additionally prove real contact and scored execution of these selectors.
const Catalog = preload("res://game/tricks/trick_catalog.gd")
const TrickInput = preload("res://game/tricks/trick_input.gd")
const HUD = preload("res://game/ui/hud.gd")
const BoardGeometry = preload("res://tests/board_geometry_tests_support.gd")
static var _playback_observer := Callable()
static var _playback_game: Node
static var _playback_phase := ""
static var _playback_step := 0

static func run(check: Callable) -> void:
	_flip_chains(check)
	_lip_routes(check)
	_manual_routes(check)
	_grab_tweaks(check)
	_special_commands(check)
	_input_lifecycle(check)
	_schema(check)
	_default_compatibility(check)


static func _flip_chains(check: Callable) -> void:
	var reachable: Dictionary = {}
	for direction: String in Catalog.DIRECTIONS:
		var single: Dictionary = Catalog.resolve("flip", direction)
		var double: Dictionary = Catalog.resolve_upgrade(single.id)
		var triple: Dictionary = Catalog.resolve_upgrade(double.id)
		for entry: Dictionary in [single, double, triple]: reachable[entry.id] = true
		check.call(int(single.tap_count) == 1 and int(double.tap_count) == 2
			and int(triple.tap_count) == 3 and triple.base_flip == single.id
			and Catalog.resolve_upgrade(triple.id).is_empty(),
			"full repertoire: %s flip has a finite one-two-three tap upgrade path" % direction)
		check.call(double.duration > single.duration and triple.duration > double.duration
			and double.base_points > single.base_points and triple.base_points > double.base_points,
			"full repertoire: %s upgrades carry distinct execution time and one-entry values" % direction)
		var field := "board_roll" if not is_zero_approx(float(single.board_roll)) else "board_yaw"
		check.call(is_equal_approx(absf(float(double[field])), absf(float(single[field])) * 2.0)
			and is_equal_approx(absf(float(triple[field])), absf(float(single[field])) * 3.0),
			"full repertoire: %s upgrades perform two and three authored board rotations" % direction)
	check.call(reachable.size() == Catalog.family_ids("flip").size() and reachable.size() == 24,
		"full repertoire: every authored flip is reachable from an ordinary direction and bounded taps")
	check.call(Catalog.resolve_upgrade("kickflip", 3).id == "triple_kickflip"
		and Catalog.resolve_upgrade("double_heelflip", 2).id == "double_heelflip"
		and Catalog.resolve_upgrade("triple_heelflip", 2).is_empty(),
		"full repertoire: absolute-stage lookup cannot downgrade a triple or select another family")
	check.call(Catalog.resolve_upgrade("melon_grab").is_empty()
		and Catalog.resolve_upgrade("kickflip", -1).is_empty()
		and Catalog.resolve_upgrade("kickflip", 4).is_empty(),
		"full repertoire: malformed stage and incompatible trick upgrades reject")


static func _lip_routes(check: Callable) -> void:
	var reachable: Dictionary = {}
	var signatures: Dictionary = {}
	var planted := 0
	for direction: String in Catalog.DIRECTIONS:
		var entry: Dictionary = Catalog.resolve("lip", direction)
		reachable[entry.id] = true
		signatures[str([entry.lip_pitch, entry.lip_roll, entry.lip_yaw,
			entry.lip_support, entry.lip_body_pitch, entry.lip_body_roll, entry.lip_hand_side])] = true
		check.call(Catalog.can_perform(entry.id, "lip") and not Catalog.can_perform(entry.id, "air")
			and entry.base_points > 0 and Catalog.LIP_SUPPORTS.has(entry.lip_support),
			"full repertoire: lip %s requires actual supported lip state and an authored contact" % direction)
		if entry.lip_invert:
			planted += 1
			check.call(entry.lip_support == "palms" and is_equal_approx(absf(entry.lip_body_pitch), PI),
				"full repertoire: %s defines inverted body and planted palm support" % entry.id)
	check.call(reachable.size() == 9 and signatures.size() == 9
		and reachable.size() == Catalog.family_ids("lip").size() and planted == 3,
		"full repertoire: all nine lip styles have reachable, distinct deck/truck/palm poses")
	check.call(Catalog.resolve_extension("lip", "flip").id == "handplant"
		and Catalog.resolve_extension("lip", "grab").id == "invert"
		and Catalog.resolve_extension("lip", "revert").id == "rock_and_roll",
		"full repertoire: supported lip face actions select handplant, invert and pivot styles")
	check.call(Catalog.resolve("lip").id == "lip_stall"
		and Catalog.resolve("lip", "north").id == "nose_stall"
		and Catalog.resolve("lip", "south").id == "tail_stall",
		"full repertoire: default lip identity survives while forward/back select actual truck stalls")


static func _manual_routes(check: Callable) -> void:
	var reachable: Dictionary = {"manual": true, "nose_manual": true}
	for action: String in ["flip", "grab", "revert"]:
		for direction: String in Catalog.DIRECTIONS:
			var entry: Dictionary = Catalog.resolve_extension("manual", action, direction)
			reachable[entry.id] = true
			check.call(Catalog.can_perform(entry.id, "manual") and entry.base_points > 0,
				"full repertoire: manual %s/%s resolves a scored supported extension" % [action,direction])
	check.call(reachable.size() == 11 and reachable.size() == Catalog.family_ids("manual").size(),
		"full repertoire: every manual is selected by an actual entry gesture or face-button extension")
	check.call(Catalog.resolve_extension("manual", "flip").id == "one_foot_manual"
		and Catalog.resolve_extension("manual", "grab").id == "spacewalk"
		and Catalog.resolve_extension("manual", "revert").id == "manual_pivot",
		"full repertoire: neutral manual controls preserve previously learned extensions")
	check.call(Catalog.definition("one_foot_nose_manual").manual_sign == -1.0
		and Catalog.definition("hang_ten").manual_foot_shift < -0.15
		and Catalog.definition("crossfoot_manual").manual_cross
		and Catalog.definition("pogo").manual_pogo and Catalog.definition("casper_manual").manual_casper,
		"full repertoire: nose, hang-ten, crossed, vertical and inverted manuals expose distinct rig targets")
	check.call(Catalog.resolve_extension("air", "flip").is_empty()
		and Catalog.resolve_extension("manual", "ollie").is_empty()
		and Catalog.resolve_extension("manual", "flip", "upsideways").is_empty(),
		"full repertoire: unsupported extension family/action/direction cannot silently select a trick")


static func _grab_tweaks(check: Callable) -> void:
	for id: String in Catalog.family_ids("grab"):
		var base: Dictionary = Catalog.definition(id)
		var signatures: Dictionary = {}
		for direction: String in ["north", "south", "east", "west"]:
			var tweak: Dictionary = Catalog.grab_tweak(id, direction)
			signatures[str([tweak.board_pitch,tweak.board_roll,tweak.board_yaw,tweak.tweak_leg_extension])] = true
			check.call(tweak.id == id and tweak.grab_target == base.grab_target
				and tweak.grab_side == base.grab_side and tweak.base_points == base.base_points + 150
				and tweak.tweak_points == 150 and not tweak.grab_tweak.is_empty(),
				"full repertoire: %s/%s tweaks keep hand contact and upgrade one stable scoring identity" % [id,direction])
		check.call(signatures.size() == 4,
			"full repertoire: %s has four distinct boning/tuck/twist/extension poses" % id)
		var edited: Dictionary = Catalog.grab_tweak(id)
		edited.allowed_states.append("ground")
		check.call(not Catalog.definition(id).allowed_states.has("ground"),
			"full repertoire: %s tweak poses cannot mutate canonical contact eligibility" % id)
	check.call(Catalog.grab_tweak("kickflip").is_empty()
		and Catalog.grab_tweak("melon_grab", "invalid").is_empty(),
		"full repertoire: incompatible grab tweaking requests reject")


static func _special_commands(check: Callable) -> void:
	var reachable: Dictionary = {}
	var signatures: Dictionary = {}
	for command: Dictionary in Catalog.special_commands():
		var input = TrickInput.new()
		input.sample_frame(_axis(command.directions[0]), [], 0.016)
		input.sample_frame(Vector2.ZERO, [], 0.03)
		input.sample_frame(_axis(command.directions[1]), [command.action], 0.03)
		var recognized: String = input.consume_special()
		reachable[recognized] = true
		var entry: Dictionary = Catalog.definition(recognized)
		signatures[str([entry.special_board_roll,entry.special_board_yaw,entry.special_body_pitch,
			entry.special_body_yaw,entry.special_body_roll,entry.special_tuck,entry.special_grab])] = true
		check.call(recognized == command.id and Catalog.can_perform(recognized,"air")
			and input.consume_special().is_empty() and input.pop_action(command.action).is_empty(),
			"full repertoire: %s command consumes one fresh directional special and no ordinary face action" % command.id)
		check.call(Catalog.EXISTING_SPECIAL_UNLOCKS.has(entry.required_unlock)
			and Catalog.SPECIAL_POSES.has(entry.special_pose) and entry.duration >= 0.65,
			"full repertoire: %s uses existing saved unlocks and a complete animation-duration contract" % command.id)
	check.call(reachable.size() == 6 and signatures.size() == 6
		and reachable.size() == Catalog.family_ids("special").size(),
		"full repertoire: all six specials have distinct motions and a working input route")
	var copy: Array[Dictionary] = Catalog.special_commands()
	copy[0].directions.clear()
	check.call(Catalog.special_commands()[0].directions.size() == 2,
		"full repertoire: guide/consumer copies cannot alter live special command recognition")


static func _input_lifecycle(check: Callable) -> void:
	var input = TrickInput.new()
	for count in 3:
		input.sample_frame(Vector2(1,0), ["flip"], 0.04)
		var command: Dictionary = input.pop_action("flip") if count == 0 else input.consume_tap_upgrade("flip")
		check.call(command.tap_count == count + 1 and command.direction == "east",
			"full repertoire: tap %d preserves bounded stage and original physical direction" % [count+1])
		input.sample_frame(Vector2.ZERO, [], 0.04)
	check.call(input.queued_action_count() == 0 and input.consume_tap_upgrade("flip").is_empty(),
		"full repertoire: consumed upgrade taps cannot later manufacture extra queued tricks")
	input.sample_frame(Vector2.ZERO, ["flip"], 0.23)
	check.call(input.pop_action("flip").tap_count == 1,
		"full repertoire: a fresh action outside the multi-tap window resets to one ordinary trick")
	input.reset()
	input.sample_frame(Vector2.ZERO,["grab"],0.016)
	input.pop_action("grab")
	input.sample_frame(Vector2(0,-1),[],0.05)
	input.sample_frame(Vector2(0,1),["grab"],0.05)
	# Up-down-grab is deliberately a special and has priority over a grab tweak.
	check.call(input.consume_special() == "special_tenement_tumble"
		and input.consume_tap_upgrade("grab").is_empty(),
		"full repertoire: special command priority consumes the tap instead of duplicating a grab tweak")
	input.reset()
	input.sample_frame(Vector2.ZERO,["grab"],0.016)
	input.pop_action("grab")
	input.sample_frame(Vector2(0,1),[],0.05)
	input.sample_frame(Vector2(0,1),["grab"],0.05)
	var tweak: Dictionary = input.consume_tap_upgrade("grab")
	check.call(tweak.direction == "south" and tweak.tap_count == 2,
		"full repertoire: second grab tap exposes the new direction for an actual tweak pose")
	input.reset()
	input.sample_frame(Vector2.ZERO,["flip"],0.016)
	input.pop_action("flip")
	input.clear_actions()
	input.sample_frame(Vector2.ZERO,[],0.05)
	input.sample_frame(Vector2.ZERO,["flip"],0.05)
	check.call(input.pop_action("flip").tap_count == 1,
		"full repertoire: lifecycle clear cannot turn an old run press into a double/triple")


static func _schema(check: Callable) -> void:
	check.call(Catalog.validate_definitions().is_empty(),
		"full repertoire: all production contact, duration, upgrade and unlock contracts validate")
	check.call(Catalog.can_perform("skitch","skitch") and not Catalog.can_perform("skitch","ground")
		and Catalog.can_transition("ground","skitch") and Catalog.can_transition("skitch","air")
		and not Catalog.can_transition("air","skitch") and Catalog.definition("skitch").base_points == 150,
		"full repertoire: skitch award requires actual grounded cart attachment and has guarded release/bail paths")
	check.call(Catalog.can_perform("grind_pivot","grind") and not Catalog.can_perform("grind_pivot","ground")
		and not Catalog.can_perform("grind_pivot","air") and Catalog.base_points("grind_pivot") == 150
		and Catalog.family_ids("grind").size() == 10 and Catalog.resolve("grind").id == "rail_grind",
		"full repertoire: pivot requires a real existing rail ride while nine directional style bindings stay stable")
	for item: Array in [["handplant","lip_support","air"], ["invert","lip_hand_side",0.5],
		["eggplant","lip_body_pitch",INF], ["hang_ten","manual_foot_shift",-2.0],
		["pogo","manual_pogo","yes"], ["casper_manual","manual_casper",1],
		["special_kelvin_corkscrew","required_unlock","new_save_id"],
		["special_bridge_blender","duration",5.0], ["triple_kickflip","tap_count",4],
		["double_hardflip","upgrade_to","kickflip"]]:
		var entry: Dictionary = Catalog.definition(item[0])
		entry[item[1]] = item[2]
		check.call(not Catalog.validate_definitions([entry]).is_empty(),
			"full repertoire: malformed %s %s rejects before runtime animation" % [item[0],item[1]])


static func run_ui(tree: SceneTree, check: Callable) -> void:
	var viewport := SubViewport.new()
	viewport.process_mode = Node.PROCESS_MODE_ALWAYS
	tree.root.add_child(viewport)
	var hud := HUD.new()
	viewport.add_child(hud)
	var state := {"speed": 8.0, "settings": {"ui_scale": 1.4, "reduced_motion": true},
		"unlocks": ["special_clyde_carousel", "special_tenement_tumble"]}
	for size: Vector2i in [Vector2i(1920,1080),Vector2i(960,600),Vector2i(640,480)]:
		viewport.size = size
		hud.update_display(state)
		hud.show_trick_guide()
		for frame in 5: await tree.process_frame
		var bounds := Rect2(Vector2.ZERO,Vector2(size))
		check.call(bounds.encloses(hud._dialog.get_global_rect()) and hud._scroll.size.y >= 80,
			"full repertoire HUD: expanded guide retains a finite usable viewport at " + str(size))
		var labels := _ui_labels(hud._scroll)
		var complete := true
		var text := ""
		for label: Label in labels:
			var font: Font = label.get_theme_font("font")
			var lines := label.get_line_count()
			var height := font.get_height(label.get_theme_font_size("font_size")) * lines
			height += label.get_theme_constant("line_spacing") * maxi(0,lines-1)
			complete = complete and label.size.y + 1.0 >= height \
				and lines == label.get_visible_line_count() \
				and label.text_overrun_behavior == TextServer.OVERRUN_NO_TRIMMING
			text += label.text + "\n"
		check.call(complete, "full repertoire HUD: every full instruction/directory line is allocated without ellipsis at " + str(size))
		check.call(text.contains("24 flips · 8 grabs · 10 grinds · 11 manuals · 9 lip tricks · 6 specials")
			and text.contains("double or triple") and text.contains("Double-tap")
			and text.contains("Hang Ten") and text.contains("Eggplant") and text.contains("skitch"),
			"full repertoire HUD: honest repertoire counts and new activation routes are visible at " + str(size))
		var all_specials := true
		for id: String in Catalog.family_ids("special"):
			all_specials = all_specials and text.contains(Catalog.definition(id).display_name)
		check.call(all_specials,
			"full repertoire HUD: every original special has a displayed remapped command at " + str(size))
		check.call(hud._focus_first.get_global_rect().position.y >= hud._scroll.get_global_rect().position.y - 1.0,
			"full repertoire HUD: opening a tall guide card keeps its heading visible at " + str(size))
		var down := InputEventAction.new()
		down.action = "ui_down"
		down.pressed = true
		viewport.push_input(down)
		down = InputEventAction.new()
		down.action = "ui_down"
		viewport.push_input(down)
		for frame in 2: await tree.process_frame
		check.call(viewport.gui_get_focus_owner() != hud._focus_first
			and viewport.gui_get_focus_owner() is Label,
			"full repertoire HUD: controller down advances through complete instructional paragraphs at " + str(size))
		hud.hide_menu()
		var recovery := state.duplicate(true)
		recovery.merge({"bail_active":true,"bail_phase":0.2,"recovery_fade":0.72},true)
		hud.update_display(recovery)
		for frame in 3: await tree.process_frame
		check.call(hud._recovery_layer.visible and hud._recovery_caption.text == "BAIL"
			and hud._recovery_overlay.get_global_rect().encloses(bounds)
			and is_equal_approx(hud._recovery_overlay.color.a,0.72),
			"full repertoire HUD: recovery fade covers the actual viewport and keeps the bail caption at " + str(size))
		check.call(hud._recovery_layer.mouse_filter == Control.MOUSE_FILTER_IGNORE
			and hud._recovery_overlay.mouse_filter == Control.MOUSE_FILTER_IGNORE,
			"full repertoire HUD: recovery presentation cannot capture gameplay/menu input at " + str(size))
		recovery.bail_phase = 0.8
		hud.update_display(recovery)
		check.call(hud._recovery_caption.text == "GETTING BACK UP",
			"full repertoire HUD: actual recovery phase presents get-up progress at " + str(size))
		hud.show_controls()
		for frame in 3: await tree.process_frame
		check.call(hud._modal.visible and hud._recovery_layer.get_index() < hud._modal.get_index(),
			"full repertoire HUD: pause controls remain above a recovery fade at " + str(size))
		hud.hide_menu()
		var contextual := state.duplicate(true)
		contextual.merge({"lip_active":true,"lip_name":"Eggplant","lip_balance":0.3},true)
		hud.update_display(contextual)
		check.call(hud._balance_label.text.contains("EGGPLANT") and hud._prompt.text.contains("Eggplant"),
			"full repertoire HUD: current lip style owns the classic status and balance cue at " + str(size))
		contextual = state.duplicate(true)
		contextual.merge({"skitching":true,"skitch_balance":-0.3},true)
		hud.update_display(contextual)
		check.call(hud._balance_panel.visible and hud._balance_label.text.contains("SKITCH")
			and hud._prompt.text.contains("SKITCH") and hud._prompt.text.contains("release"),
			"full repertoire HUD: actual tow state exposes balance and release controls at " + str(size))
		contextual.skitch_caught = false
		hud.update_display(contextual)
		for frame in 2: await tree.process_frame
		check.call(hud._prompt.text.begins_with("REACH FOR BAR") and not hud._balance_panel.visible
			and hud._prompt.text.contains("release") and hud._prompt.get_line_count() <= 2
			and hud._prompt.get_visible_line_count() == hud._prompt.get_line_count()
			and hud._prompt.text_overrun_behavior == TextServer.OVERRUN_NO_TRIMMING,
			"full repertoire HUD: pending reach never pretends a grip and its complete cue fits at " + str(size))
		contextual = state.duplicate(true)
		contextual.merge({"setup_active":true,"setup_id":"no_comply","setup_phase":0.4},true)
		hud.update_display(contextual)
		check.call(hud._prompt.text.begins_with("NO COMPLY") and hud._prompt.text.contains("Plant and pop"),
			"full repertoire HUD: planted setup phase is readable before the actual pop at " + str(size))
	viewport.queue_free()
	await tree.process_frame


static func _ui_labels(node: Node) -> Array[Label]:
	var result: Array[Label] = []
	if node is Label: result.append(node)
	for child: Node in node.get_children(): result.append_array(_ui_labels(child))
	return result


static func _default_compatibility(check: Callable) -> void:
	for id: String in ["pop_shuvit","frontside_shuvit","varial_flip","grind_50_50","disaster"]:
		var entry := Catalog.definition(id)
		check.call(entry.get("id") == id and entry.has("canonical_id")
			and Catalog.validate_definitions([entry]).is_empty(),
			"default integration: live default identity has valid authored motion "+id)
	check.call(Catalog.is_grind_name("50-50") and Catalog.is_grind_name("Boardslide")
		and not Catalog.is_grind_name("Manual") and Catalog.base_points("boardslide") == 200,
		"default integration: named native rail receipts retain default identity and value")
	check.call(Catalog.resolve_extension("grind","flip","east").id == "boardslide"
		and Catalog.resolve_extension("grind","grab","west").id == "lipslide"
		and Catalog.resolve_extension("grind","flip","neutral").id == "rail_grind"
		and Catalog.resolve_extension("grind","revert").id == "grind_pivot",
		"default integration: real rail style and pivot requests resolve to native solver identities")
	check.call(Catalog.definition("frontside_shuvit").board_yaw == -PI
		and Catalog.resolve_upgrade("frontside_shuvit",2).board_yaw == -TAU
		and Catalog.resolve_upgrade("frontside_shuvit",3).board_yaw == -PI*3.0,
		"default integration: Frontside Shuvit and its upgrades keep real negative rotation")
	var input := TrickInput.new()
	input.sample_frame(Vector2.UP,["flip"],0.016)
	var ordinary := input.pop_action("flip")
	check.call(not ordinary.advanced_direction
		and TrickInput.select_action("flip",ordinary,Vector2.ZERO).id == "frontside_shuvit",
		"default integration: a normal direction preserves the default press-time selection")
	input.reset()
	input.sample_frame(Vector2.UP,[],0.016)
	input.sample_frame(Vector2.ZERO,[],0.016)
	input.sample_frame(Vector2.UP,["flip"],0.016)
	var advanced := input.pop_action("flip")
	check.call(advanced.advanced_direction and advanced.special_id.is_empty()
		and TrickInput.select_action("flip",advanced,Vector2.ZERO).id == "hardflip",
		"default integration: real repeated direction and neutral unlock the advanced set once")
	input.reset()
	input.sample_frame(Vector2.UP,[],0.016)
	input.sample_frame(Vector2.ZERO,[],0.31)
	input.sample_frame(Vector2.UP,["flip"],0.016)
	check.call(not input.pop_action("flip").advanced_direction,
		"default integration: stale direction pairs cannot select the advanced set")
	input.reset()
	input.sample_frame(Vector2.UP,[],0.016)
	input.sample_frame(Vector2.RIGHT,[],0.016)
	input.sample_frame(Vector2.UP,["grab"],0.016)
	check.call(not input.pop_action("grab").advanced_direction,
		"default integration: unneutralized axis changes do not masquerade as repeated taps")


static func run_playable(tree: SceneTree, game: Node, check: Callable, observer: Callable = Callable()) -> void:
	# Explicit elevated air fixtures set only position/velocity, never tricks,
	# scores or input history. Production input/controller/physics owns execution
	# and real landing. Actual charged takeoffs are covered by overnight tests.
	var spawn: Vector3 = game.skater.spawn_position
	_playback_observer = observer
	_playback_game = game
	_playback_phase = "fixture"
	_playback_step = 0
	game.skater.spawn_position = Vector3(-22,0.8,28)
	var observed := {"bails": 0}
	var on_bail := func(): observed.bails += 1
	game.skater.bailed.connect(on_bail)
	for direction: String in ["neutral","east","south","north","north_west","north_east","south_west","south_east"]:
		var single: Dictionary = Catalog.resolve("flip",direction)
		for stage in [1,2,3]:
			_playback_phase = "fixture"
			await _air_fixture(tree,game)
			var entry: Dictionary = single if stage == 1 else Catalog.resolve_upgrade(single.id,stage)
			_playback_phase = "flip_" + str(entry.id)
			_playback_step = 0
			var before: int = observed.bails
			await _advanced_direction(tree,direction)
			for tap in stage:
				if tap > 0: await _physics(tree,2)
				_set_direction(direction)
				Input.action_press("flip")
				await _physics(tree,1)
				Input.action_release("flip")
				_set_direction("neutral")
			check.call(game.skater.flip_trick_id == entry.id and game.score.combo_trick_count == 1
				and game.score.combo_base == entry.base_points,
				"full repertoire playable: real %s taps select %s and upgrade exactly one scoring entry" % [stage,entry.id])
			await _settle(tree,game)
			check.call(observed.bails == before and game.skater.is_on_floor()
				and game.score.total_score == entry.base_points and game.score.get_combo_value() == 0,
				"full repertoire playable: %s completes its real board motion and banks once on native landing" % entry.id)
	await _playable_grab_tweaks(tree,game,check)
	await _playable_manuals(tree,game,check)
	await _playable_specials(tree,game,check)
	await _playable_lips(tree,game,check)
	await _playable_rail_pivot(tree,game,check)
	game.skater.bailed.disconnect(on_bail)
	_release_inputs()
	game.skater.spawn_position = spawn
	game.restart_run()
	_playback_observer = Callable()
	_playback_game = null
	_playback_phase = ""


static func _playable_grab_tweaks(tree: SceneTree, game: Node, check: Callable) -> void:
	for direction: String in ["north","south","east","west"]:
		_playback_phase = "fixture"
		await _air_fixture(tree,game)
		_playback_phase = "grab_melon_grab_" + direction
		_playback_step = 0
		Input.action_press("grab")
		await _physics(tree,1)
		Input.action_release("grab")
		await _physics(tree,2)
		_set_direction(direction)
		Input.action_press("grab")
		await _physics(tree,1)
		_set_direction("neutral")
		var expected: Dictionary = Catalog.grab_tweak("melon_grab",direction)
		check.call(game.skater.grab_trick_id == "melon_grab" and game.score.combo_trick_count == 1
			and game.score.combo_base == expected.base_points
			and game.skater._grab_definition.get("grab_tweak","") == expected.grab_tweak,
			"full repertoire playable: second Grab + %s performs its boning pose and one-entry score upgrade" % direction)
		# A third physical press must not farm another tweak or reset hold allowance.
		Input.action_release("grab")
		await _physics(tree,2)
		Input.action_press("grab")
		await _physics(tree,1)
		check.call(game.score.combo_trick_count == 1 and game.score.combo_base == expected.base_points,
			"full repertoire playable: %s grab accepts at most one tweak upgrade" % direction)
		Input.action_release("grab")
		await _settle(tree,game)
		check.call(game.score.total_score == expected.base_points,
			"full repertoire playable: %s tweak banks its actual accepted points" % direction)


static func _playable_manuals(tree: SceneTree, game: Node, check: Callable) -> void:
	for selection: Array in [["flip","neutral"],["grab","neutral"],["revert","neutral"],
		["flip","north"],["flip","south"],["flip","east"],
		["grab","north"],["grab","south"],["revert","north"]]:
		_playback_phase = "fixture"
		_release_inputs()
		game.restart_run()
		await _physics(tree,30)
		Input.action_press("push")
		await _physics(tree,42)
		Input.action_release("push")
		await _physics(tree,13)
		Input.action_press("manual")
		await _physics(tree,1)
		var expected: Dictionary = Catalog.resolve_extension("manual",selection[0],selection[1])
		_playback_phase = "manual_" + str(expected.id)
		_playback_step = 0
		var base: int = game.score.combo_base
		_set_direction(selection[1])
		Input.action_press(selection[0])
		await _physics(tree,1)
		Input.action_release(selection[0])
		_set_direction("neutral")
		check.call(game.skater.manual_active and game.skater.manual_trick_id == expected.id
			and game.score.combo_trick_count == 2 and game.score.combo_base == base + expected.base_points,
			"full repertoire playable: supported %s/%s input performs %s as one new extension" % [selection[0],selection[1],expected.id])
		await _physics(tree,24)
		var expected_sign := signf(float(expected.manual_sign)*cos(float(game.skater._deck_yaw)))
		check.call(absf(game.skater._board_visual.rotation.x) > 0.02
			and signf(game.skater._board_visual.rotation.x) == expected_sign
			and game.skater._manual_base_sign == float(expected.manual_sign),
			"full repertoire playable: %s actual deck pitch follows its authored nose/tail sign" % expected.id)
		if expected.id in ["pogo","casper_manual"]:
			check.call(_manual_orientation(game,expected.id) and _manual_bearing_contact(game,expected.id),
				"full repertoire playable: %s actual deck is %s rather than an ordinary manual pose" % [expected.id,"nearly vertical" if expected.id == "pogo" else "inverted"])
			check.call(_manual_contacts(game,expected.id),
				"full repertoire playable: %s actual shoes and palms meet their intended rendered support surfaces" % expected.id)
		Input.action_release("manual")
		await _settle(tree,game)
		check.call(game.score.total_score == (base + int(expected.base_points)) * 2,
			"full repertoire playable: %s ends its real balance state and banks the two-entry line" % expected.id)
	await _nose_to_tail_extensions(tree,game,check)
	await _shove_to_tail_extensions(tree,game,check)


static func _nose_to_tail_extensions(tree: SceneTree, game: Node, check: Callable) -> void:
	for action: String in ["flip","grab"]:
		_playback_phase = "fixture"
		_release_inputs()
		game.restart_run()
		await _physics(tree,30)
		Input.action_press("push")
		await _physics(tree,42)
		Input.action_release("push")
		await _physics(tree,13)
		Input.action_press("push")
		Input.action_press("manual")
		await _physics(tree,2)
		Input.action_release("push")
		check.call(game.skater.manual_active and game.skater.manual_trick_id == "nose_manual"
			and game.skater._board_visual.rotation.x < -0.02 and game.score.combo_base == Catalog.base_points("nose_manual"),
			"full repertoire playable: reverse extension fixture begins with an actual supported nose-pitched manual")
		var expected: Dictionary = Catalog.resolve_extension("manual",action,"south")
		_playback_phase = "manual_nose_to_"+str(expected.id)
		_playback_step = 0
		_set_direction("south")
		Input.action_press(action)
		await _physics(tree,1)
		Input.action_release(action)
		_set_direction("neutral")
		await _physics(tree,24)
		check.call(game.skater.manual_active and game.skater.manual_trick_id == expected.id
			and game.skater._manual_base_sign == 1.0 and game.skater._board_visual.rotation.x > 0.02
			and _manual_orientation(game,expected.id) and _manual_bearing_contact(game,expected.id)
			and game.score.combo_trick_count == 2 and game.score.combo_base == Catalog.base_points("nose_manual")+int(expected.base_points),
			"full repertoire playable: real Nose Manual to %s changes the deck to its tail-supported pitch without stale nose sign" % expected.id)
		check.call(_manual_contacts(game,expected.id),
			"full repertoire playable: Nose Manual to %s settles actual anatomical contacts on the rendered deck and trucks" % expected.id)
		Input.action_release("manual")
		await _settle(tree,game)
		check.call(game.score.total_score == (Catalog.base_points("nose_manual")+int(expected.base_points))*2,
			"full repertoire playable: Nose Manual to %s keeps native support and banks its exact two-entry value" % expected.id)


static func _manual_orientation(game: Node, id: String) -> bool:
	var up: Vector3 = game.skater.get_floor_normal()
	if up.length_squared() < 0.5: up = Vector3.UP
	if id == "pogo": return absf(game.skater._board_visual.global_basis.z.normalized().dot(up)) > 0.85
	if id == "casper_manual": return game.skater._board_visual.global_basis.y.normalized().dot(up) < -0.75
	return true


static func _shove_to_tail_extensions(tree: SceneTree, game: Node, check: Callable) -> void:
	for action: String in ["flip","grab"]:
		_playback_phase = "fixture"
		_release_inputs()
		game.restart_run()
		await _physics(tree,30)
		Input.action_press("push")
		await _physics(tree,42)
		Input.action_release("push")
		await _physics(tree,13)
		var expected: Dictionary = Catalog.resolve_extension("manual",action,"south")
		_playback_phase = "manual_after_shove_to_"+str(expected.id)
		_playback_step = 0
		Input.action_press("ollie")
		await _physics(tree,2)
		Input.action_release("ollie")
		await _physics(tree,1)
		_set_direction("south")
		await _advanced_direction(tree,"south")
		Input.action_press("flip")
		await _physics(tree,1)
		Input.action_release("flip")
		_set_direction("neutral")
		for frame in 90:
			await _physics(tree,1)
			if game.skater.airborne and game.skater.velocity.y < -1.0 and game.skater.global_position.y < 0.70:
				Input.action_press("push")
				Input.action_press("manual")
				break
		for frame in 40:
			await _physics(tree,1)
			if game.skater.manual_active or game.skater.bail_active: break
		Input.action_release("push")
		var launch_base := Catalog.base_points("ollie")+Catalog.base_points("pop_shove_it")+Catalog.base_points("nose_manual")
		check.call(game.skater.manual_active and game.skater.manual_trick_id == "nose_manual"
			and absf(absf(game.skater._deck_yaw)-PI) < 0.01 and game.score.combo_trick_count == 3
			and game.score.combo_base == launch_base and game.score.trick_history.has("Pop Shove-it"),
			"full repertoire playable: actual Ollie and Pop Shove-it land into Nose Manual with a reversed deck and exact three-entry base")
		_set_direction("south")
		Input.action_press(action)
		await _physics(tree,1)
		Input.action_release(action)
		_set_direction("neutral")
		await _physics(tree,24)
		check.call(game.skater.manual_active and game.skater.manual_trick_id == expected.id
			and game.skater._manual_base_sign == 1.0 and game.skater._board_visual.rotation.x < -0.02
			and _manual_orientation(game,expected.id) and _manual_bearing_contact(game,expected.id)
			and game.score.combo_trick_count == 4 and game.score.combo_base == launch_base+int(expected.base_points),
			"full repertoire playable: %s after a real shove-it uses reversed-deck orientation and native bearing with one extension award" % expected.id)
		check.call(_manual_contacts(game,expected.id),
			"full repertoire playable: %s after a real shove-it preserves anatomical contacts across the reversed deck" % expected.id)
		Input.action_release("manual")
		await _settle(tree,game)
		check.call(game.score.total_score == (launch_base+int(expected.base_points))*4,
			"full repertoire playable: actual shove-it to Nose Manual to %s banks its exact four-entry line" % expected.id)


static func _manual_bearing_contact(game: Node, id: String) -> bool:
	# Inspect the visible meshes independently of the rig's support hull. The
	# lowest curved edge changes during an inverted Casper or committed shove.
	var up: Vector3 = game.skater.get_floor_normal()
	if up.length_squared() < 0.5: up = Vector3.UP
	var lowest := INF
	var bearing := Vector3.ZERO
	for mesh: MeshInstance3D in _board_meshes(game):
		for vertex: Vector3 in mesh.mesh.get_faces():
			var world := mesh.to_global(vertex)
			if world.dot(up) < lowest:
				lowest = world.dot(up)
				bearing = world
	if not is_finite(lowest): return false
	var query := PhysicsRayQueryParameters3D.create(bearing+up*0.12,bearing-up*0.15,1)
	query.exclude = [game.skater.get_rid()]
	var hit: Dictionary = game.skater.get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and absf((bearing-Vector3(hit.position)).dot(hit.normal)) < 0.03


static func _manual_contacts(game: Node, id: String) -> bool:
	var rig = game.skater._visual_rig
	var board: Node3D = game.skater._board_visual
	var inverse_rest := Basis(Vector3.UP,-float(game.skater._deck_yaw))
	var valid := true
	var max_error := 0.0
	var all_meshes := _board_meshes(game)
	for leg: Dictionary in rig._legs:
		var foot: Node3D = leg.foot
		var contact: Vector3
		var target: Vector3
		if id == "pogo":
			contact = foot.to_global(Vector3(0,-0.0605,0))
			target = rig.pogo_foot_contact(float(leg.side),float(game.skater._deck_yaw))
		elif float(leg.side) < 0.0:
			contact = foot.to_global(Vector3(0,0.001,-0.115))
			target = board.to_global(inverse_rest*Vector3(0,0.022,-0.29))
		else:
			contact = foot.to_global(Vector3(0,-0.0605,0))
			target = board.to_global(inverse_rest*Vector3(0,-0.025,0.255))
		var error := contact.distance_to(target)
		max_error = maxf(max_error,error)
		valid = valid and error < 0.008 and foot.global_basis.y.normalized().dot(Vector3.UP) > 0.995 \
			and _surface_distance(contact,all_meshes) < 0.015
	if id == "pogo":
		for arm: Dictionary in rig._arms:
			var palm: Vector3 = arm.hand.to_global(Vector3(0,-0.075,-0.015))
			var target: Vector3 = board.to_global(inverse_rest*rig.pogo_hand_target(float(arm.side)))
			var error := palm.distance_to(target)
			max_error = maxf(max_error,error)
			valid = valid and error < 0.025 and BoardGeometry.grip_distance(rig,palm) < 0.025
	print("PLAYABLE_MANUAL_CONTACT id=%s rest=%.3f max_error=%.4f valid=%s" % [id,game.skater._deck_yaw,max_error,valid])
	return valid


static func _board_meshes(game: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	for child: Node in game.skater._visual_rig.board_contact_geometry().meshes:
		if child is MeshInstance3D and child.mesh != null: result.append(child)
	return result


static func _surface_distance(point: Vector3, meshes: Array) -> float:
	var distance := INF
	for mesh: MeshInstance3D in meshes:
		var vertices := mesh.mesh.get_faces()
		for index in range(0,vertices.size(),3):
			var a := mesh.to_global(vertices[index])
			var b := mesh.to_global(vertices[index+1])
			var c := mesh.to_global(vertices[index+2])
			var normal := (b-a).cross(c-a).normalized()
			if normal.length_squared() > 0.5:
				var projected := point-normal*(point-a).dot(normal)
				if normal.dot((b-a).cross(projected-a)) >= -0.000001 \
					and normal.dot((c-b).cross(projected-b)) >= -0.000001 \
					and normal.dot((a-c).cross(projected-c)) >= -0.000001:
					distance = minf(distance,point.distance_to(projected))
			for edge: Array in [[a,b],[b,c],[c,a]]:
				distance = minf(distance,point.distance_to(Geometry3D.get_closest_point_to_segment(point,edge[0],edge[1])))
	return distance


static func _playable_specials(tree: SceneTree, game: Node, check: Callable) -> void:
	var saved: Array[String] = game.career.completed_ids.duplicate()
	for id: String in ["first_shift","one_long_line"]:
		if not game.career.completed_ids.has(id): game.career.completed_ids.append(id)
	for command: Dictionary in Catalog.special_commands():
		_playback_phase = "fixture"
		await _air_fixture(tree,game)
		_playback_phase = "special_" + str(command.id)
		_playback_step = 0
		# Explicit full-meter/unlock eligibility fixture, not earned meter evidence.
		game.special_meter.value = 100.0
		game.special_meter.active = true
		_set_direction(command.directions[0])
		await _physics(tree,1)
		_set_direction("neutral")
		await _physics(tree,1)
		_set_direction(command.directions[1])
		Input.action_press(command.action)
		await _physics(tree,1)
		Input.action_release(command.action)
		_set_direction("neutral")
		var entry: Dictionary = Catalog.definition(command.id)
		check.call(game.skater.last_trick_id == command.id and game.skater.special_name == entry.display_name
			and game.score.combo_trick_count == 1 and game.score.combo_base == entry.base_points,
			"full repertoire playable: %s directional command executes its real special and exact entry value" % command.id)
		await _settle(tree,game)
		var rotation_bonus := roundi(absf(float(entry.special_body_yaw)) / PI) * 200
		check.call(game.score.total_score == int(entry.base_points) + rotation_bonus and game.score.get_combo_value() == 0,
			"full repertoire playable: %s finishes its authored animation before a native landing/bank" % command.id)
	game.career.completed_ids = saved


static func _playable_lips(tree: SceneTree, game: Node, check: Callable) -> void:
	# Use the retained work transition's published approach. The current default
	# compacted the Clyde quay; its old hard-coded X=-113 start is outside it.
	var approach := PackedVector3Array()
	for feature: Dictionary in game.world.get_skate_feature_definitions():
		if str(feature.get("id","")) == "kelvingrove_promenade_practice":
			approach = feature.get("approach",PackedVector3Array())
	if approach.size() < 2:
		check.call(false,"full repertoire playable: authored promenade quarter approach exists for native lip trials")
		return
	var forward: Vector3 = (approach[-1]-approach[0]).normalized()
	for direction: String in Catalog.DIRECTIONS:
		_playback_phase = "lip_" + str(Catalog.resolve("lip",direction).id)
		_playback_step = 0
		_release_inputs()
		game.skater.spawn_position = approach[0]+Vector3.UP*0.8
		game.restart_run()
		await _physics(tree,30)
		game.skater.rotation.y = atan2(-forward.x,-forward.z)
		Input.action_press("push")
		Input.action_press("grind")
		for frame in 300:
			await _physics(tree,1)
			if game.skater.lip_active or game.skater.bail_active: break
		check.call(game.skater.lip_active and not game.skater.bail_active,
			"full repertoire playable: actual authored promenade approach reaches native lip contact for " + direction)
		if not game.skater.lip_active: continue
		var base: int = game.score.combo_base
		var initial: String = game.skater.lip_trick_id
		var entry: Dictionary = Catalog.resolve("lip",direction)
		if direction != "neutral":
			_set_direction(direction)
			Input.action_press("flip")
			await _physics(tree,1)
			Input.action_release("flip")
		_set_direction("neutral")
		await _physics(tree,20)
		var changed: bool = initial != entry.id
		var expected_base := base + (int(entry.base_points) if changed else 0)
		var entries := 2 if changed else 1
		check.call(game.skater.lip_active and game.skater.lip_trick_id == entry.id
			and game.score.combo_trick_count == entries and game.score.combo_base == expected_base,
			"full repertoire playable: %s real lip input selects %s with one finite style-entry award" % [direction,entry.id])
		if entry.lip_invert:
			var frame: Dictionary = game.skater._feature_transition.lip_frame()
			var normal: Vector3 = frame.normal
			var planted := 0
			var contact := true
			for arm: Dictionary in game.skater._visual_rig._arms:
				if not is_zero_approx(float(entry.lip_hand_side)) and arm.side != entry.lip_hand_side: continue
				planted += 1
				var palm: Vector3 = arm.hand.to_global(Vector3(0,-0.075,-0.015))
				contact = contact and absf((palm - Vector3(frame.point)).dot(normal)) < 0.06 \
					and palm.distance_to(frame.point) < (0.22 if planted == 2 or is_zero_approx(float(entry.lip_hand_side)) else 0.06)
			check.call(planted > 0 and contact,
				"full repertoire playable: %s visible palm geometry actually supports the inverted rider on native coping" % entry.id)
		Input.action_release("grind")
		await _settle(tree,game)
		check.call(game.score.total_score == expected_base * entries and game.score.get_combo_value() == 0,
			"full repertoire playable: %s drops back from native lip support and banks its actual line" % entry.id)


static func _playable_rail_pivot(tree: SceneTree, game: Node, check: Callable) -> void:
	_playback_phase = "grind_grind_pivot"
	_playback_step = 0
	_release_inputs()
	game.skater.spawn_position = Vector3(-22,0.8,28)
	game.restart_run()
	await _physics(tree,3)
	# Descending acquisition fixture, then native GrindRide and mapped inputs.
	game.skater.set_physics_process(false)
	game.skater.global_position = Vector3(-63.85,3.10,1.5)
	game.skater.rotation.y = 0.0
	game.skater.velocity = Vector3.ZERO
	game.skater.move_and_slide()
	game.skater.velocity = Vector3(0,-1,-6)
	game.skater.speed = 6.0
	game.skater.airborne = true
	game.skater.set_physics_process(true)
	var captures: Array[String] = []
	var on_capture := func(id: String): captures.append(id)
	var held := {"points":0}
	var on_hold := func(points: int): held.points += points
	game.skater.grind_captured.connect(on_capture)
	game.skater.hold_points_awarded.connect(on_hold)
	Input.action_press("grind")
	await _physics(tree,3)
	check.call(game.skater.grinding and captures == ["Grind_Rail_CentralGround"]
		and game.score.combo_trick_count == 1 and game.score.combo_base == 200,
		"full repertoire playable: pivot fixture acquires one actual authored rail through native contact")
	var heading: float = game.skater.rotation.y
	var motion: Vector3 = game.skater.velocity
	var before_speed: float = absf(game.skater.speed)
	Input.action_press("revert")
	await _physics(tree,1)
	check.call(game.skater.grinding and game.skater.last_trick_id != "grind_pivot"
		and game.score.combo_trick_count == 1,
		"full repertoire playable: native pivot unweights before awarding its completed physical transfer")
	# This second fresh press occurs early in the actual motion, so its bounded
	# queue expires before the .35s start-based cooldown ends. A held button
	# thereafter must not create another entry when eligibility returns.
	Input.action_release("revert")
	await _physics(tree,1)
	Input.action_press("revert")
	for frame in 48:
		before_speed = absf(game.skater._grind.speed)
		await _physics(tree,1)
		if game.skater.last_trick_id == "grind_pivot" or not game.skater.grinding: break
	check.call(game.skater.grinding and absf(absf(angle_difference(heading,game.skater.rotation.y)) - PI) < 0.02
		and game.skater.stance == "SWITCH" and game.skater.speed < 0.0,
		"full repertoire playable: fresh rail Revert physically pivots facing and functional stance 180 degrees")
	check.call(game.skater.velocity.normalized().dot(motion.normalized()) > 0.999
		and absf(absf(game.skater.speed) - before_speed * 0.85) < 0.04,
		"full repertoire playable: pivot preserves real rail tangent travel with the documented 15 percent speed cost")
	check.call(captures.size() == 1 and game.skater.last_trick_id == "grind_pivot"
		and game.score.combo_trick_count == 2 and game.score.combo_base == 350+int(held.points),
		"full repertoire playable: pivot adds one 150-point trick without fabricating another rail capture")
	await _physics(tree,19)
	check.call(game.skater.grinding and captures.size() == 1 and game.score.combo_trick_count == 2
		and game.score.combo_base == 350+int(held.points),
		"full repertoire playable: a held pivot and a fresh cooldown press cannot repeat its award")
	Input.action_release("revert")
	Input.action_press("ollie")
	await _physics(tree,1)
	Input.action_release("ollie")
	await _physics(tree,1)
	Input.action_release("grind")
	check.call(not game.skater.grinding and game.skater.airborne
		and absf(game.skater.velocity.y-game.skater.OLLIE_SPEED) <= game.skater.GRAVITY/60.0+0.1
		and game.score.combo_trick_count == 3 and game.score.combo_base == 450+int(held.points),
		"full repertoire playable: backwards-facing pivot links through a real release-pop hop without an early bank")
	await _settle(tree,game)
	var expected_bank := (Catalog.base_points("rail_grind")+Catalog.base_points("grind_pivot")
		+Catalog.base_points("ollie")+int(held.points))*3
	check.call(game.score.total_score == expected_bank and game.score.get_combo_value() == 0 and captures.size() == 1,
		"full repertoire playable: native Rail Grind to Pivot to Ollie banks its exact three entries and earned holds once")
	var banked: int = game.score.total_score
	await _physics(tree,20)
	check.call(game.score.total_score == banked,
		"full repertoire playable: the physical pivot line cannot bank again during ordinary ground travel")
	game.skater.grind_captured.disconnect(on_capture)
	game.skater.hold_points_awarded.disconnect(on_hold)


static func _air_fixture(tree: SceneTree, game: Node) -> void:
	_release_inputs()
	game.restart_run()
	await _physics(tree,2)
	game.skater.set_physics_process(false)
	game.skater.global_position = Vector3(-22,12,28)
	game.skater.velocity = Vector3.ZERO
	game.skater.move_and_slide()
	game.skater.velocity = Vector3(0,2,0)
	game.skater.speed = 0.0
	game.skater.airborne = true
	game.skater.set_physics_process(true)


static func _settle(tree: SceneTree, game: Node) -> void:
	for frame in 180:
		await _physics(tree,1)
		if not game.skater.airborne and game.score.get_combo_value() == 0: break
	await _physics(tree,2)


static func _set_direction(direction: String) -> void:
	for action: String in ["push","brake","steer_left","steer_right"]: Input.action_release(action)
	if direction.contains("north"): Input.action_press("push")
	if direction.contains("south"): Input.action_press("brake")
	if direction.contains("west"): Input.action_press("steer_left")
	if direction.contains("east"): Input.action_press("steer_right")


static func _release_inputs() -> void:
	for action: StringName in InputMap.get_actions(): Input.action_release(action)


static func _physics(tree: SceneTree, count: int) -> void:
	for frame in count:
		await tree.physics_frame
		await tree.process_frame
		_playback_step += 1
		if _playback_observer.is_valid() and is_instance_valid(_playback_game):
			await _playback_observer.call(_playback_phase,_playback_game,_playback_step)


static func _advanced_direction(tree: SceneTree, direction: String) -> void:
	if direction == "neutral": return
	_set_direction(direction)
	await _physics(tree,1)
	_set_direction("neutral")
	await _physics(tree,1)
	_set_direction(direction)


static func _axis(direction: String) -> Vector2:
	return {"north":Vector2.UP,"south":Vector2.DOWN,"east":Vector2.RIGHT,
		"west":Vector2.LEFT}.get(direction,Vector2.ZERO)
