extends RefCounted
## Public scoring invariants for styled tricks, hold points and outcome receipts.

const Score = preload("res://game/scoring/score_session.gd")
const HUD = preload("res://game/ui/hud.gd")


static func run(check: Callable) -> void:
	var score = Score.new()
	score.add_trick("Kickflip", 300, "kickflip")
	check.call(score.combo_trick_count == 1 and score.last_award == 300 and not score.last_repeat,
		"trick score: a fresh trick exposes its accepted award and entry count")
	score.add_trick("Switch Kickflip", 300, "kickflip")
	check.call(score.combo_base == 450 and score.combo_multiplier == 2
		and score.combo_trick_count == 2 and score.last_repeat and score.last_award == 150,
		"trick score: a styled entry adds a multiplier but retains stable-ID repetition")
	score.add_trick("Heelflip", 300, "heelflip")
	check.call(score.combo_base == 750 and score.combo_multiplier == 3
		and score.combo_trick_count == 3 and not score.last_repeat,
		"trick score: a fresh physical trick adds the third entry and clears repeat feedback")
	score.begin_landing()
	score.tick(0.1)
	var deadline: float = score.landing_remaining
	score.add_hold_points(120)
	check.call(score.combo_base == 870 and score.get_combo_value() == 2610,
		"trick score: a hold extends the existing combo base before multiplication")
	check.call(score.combo_multiplier == 3 and score.combo_trick_count == 3
		and score.trick_history == ["Kickflip", "Switch Kickflip", "Heelflip"],
		"trick score: hold samples cannot create trick entries, history or variety")
	check.call(score.pending_landing and score.landing_remaining == deadline,
		"trick score: hold points cannot refresh or suspend the landing deadline")
	score.add_hold_points(0)
	score.add_hold_points(-100)
	check.call(score.get_combo_value() == 2610, "trick score: nonpositive hold awards are ignored")
	check.call(score.tick(deadline) == 2610 and score.last_banked == 2610
		and score.last_banked_tricks == ["Kickflip", "Switch Kickflip", "Heelflip"],
		"trick score: banking snapshots the actual accepted trick list before clearing")
	check.call(score.combo_trick_count == 0 and score.last_award == 0 and not score.last_repeat,
		"trick score: banking clears live entry and repeat feedback")
	score.add_hold_points(300)
	check.call(score.get_combo_value() == 0 and score.total_score == 2610,
		"trick score: a late hold cannot resurrect a banked combo")
	score.add_trick("Kickflip", 300, "kickflip")
	check.call(score.last_award == 75 and score.last_repeat,
		"trick score: stable repetition persists after a bank within the run")
	check.call(score.last_banked_tricks == ["Kickflip", "Switch Kickflip", "Heelflip"],
		"trick score: a new live line retains the previous bank receipt")
	score.drop_combo()
	check.call(score.last_dropped_value == 75 and score.last_banked == 0
		and score.last_banked_tricks.is_empty() and score.total_score == 2610,
		"trick score: bail records only lost pending value and preserves already banked points")
	score.add_hold_points(300)
	check.call(score.get_combo_value() == 0, "trick score: holds cannot score after a bail")
	score.add_trick("Manual", 100, "manual")
	score.bank_combo()
	check.call(score.last_dropped_value == 0 and score.last_banked_tricks == ["Manual"],
		"trick score: a successful outcome replaces the previous drop receipt")
	score.reset()
	check.call(score.total_score == 0 and score.best_combo == 0 and score.last_banked == 0
		and score.last_banked_tricks.is_empty() and score.last_dropped_value == 0,
		"trick score: restart clears both live and previous-outcome state")
	var legacy = Score.new()
	legacy.add_trick("Backside 180", 200)
	legacy.add_trick("Backside 360", 400)
	legacy.add_trick("Backside 180", 200, "  ")
	check.call(legacy.combo_base == 700 and legacy.combo_multiplier == 3,
		"trick score: callers without stable IDs retain legacy display-name identity")
	var invalid = Score.new()
	invalid.add_trick(" ", 300, "kickflip")
	invalid.add_trick("Kickflip", -1, "kickflip")
	invalid.add_hold_points(100)
	check.call(invalid.combo_trick_count == 0 and invalid.trick_history.is_empty()
		and invalid.combo_base == 0, "trick score: rejected entries cannot authorize hold points")
	var bounded = Score.new()
	bounded.add_trick("Manual", 100, "manual")
	bounded.add_hold_points(9223372036854775807)
	check.call(bounded.combo_base == 100 + Score.MAX_EVENT_POINTS,
		"trick score: oversized hold events clamp before arithmetic")
	bounded.combo_base = Score.MAX_SCORE - 20
	bounded.add_hold_points(100)
	check.call(bounded.combo_base == Score.MAX_SCORE and bounded.bank_combo() == Score.MAX_SCORE,
		"trick score: hold arithmetic saturates at the portable score limit")
	var many = Score.new()
	for index in 12:
		many.add_trick("Trick %d" % index, 100, "trick_%d" % index)
	check.call(many.combo_trick_count == 12 and many.combo_multiplier == 12
		and many.trick_history.size() == 8, "trick score: multiplier and readable history limits remain independent")
	many.bank_combo()
	many.add_trick("New trick", 100, "new")
	check.call(many.last_banked_tricks.size() == 8 and not many.last_banked_tricks.has("New trick"),
		"trick score: outcome history is a snapshot independent of the next combo")


static func run_ui(tree: SceneTree, check: Callable) -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(960, 600)
	viewport.process_mode = Node.PROCESS_MODE_ALWAYS
	tree.root.add_child(viewport)
	var hud := HUD.new()
	viewport.add_child(hud)
	var snapshot := {
		"combo": 900, "combo_base": 450, "multiplier": 2, "trick_count": 3,
		"tricks": "Ollie + Kickflip + Switch Kickflip", "last_award": 150,
		"last_repeat": true, "stance": "SWITCH", "manual": true,
		"manual_name": "Nose Manual", "settings": {"ui_scale": 1.4, "reduced_motion": true},
	}
	hud.update_display(snapshot)
	for frame in 3: await tree.process_frame
	check.call(hud._combo_status.text.contains("3 TRICKS")
		and hud._combo_status.text.contains("REPEAT +150"),
		"trick HUD: live feedback distinguishes entry count and reduced repeat award")
	check.call(hud._stance_label.text == "SWITCH STANCE"
		and hud._balance_label.text.begins_with("NOSE MANUAL"),
		"trick HUD: switch riding and the selected manual remain visible")
	snapshot.active_trick = "Nose Manual"
	snapshot.hold_points = 120
	hud.update_display(snapshot)
	check.call(hud._combo_status.text.contains("HOLD +120"),
		"trick HUD: sustained scoring appears without adding history entries")
	snapshot.landing_window = 0.18
	hud.update_display(snapshot)
	check.call(hud._combo_status.text.begins_with("LINK IT  0.18s")
		and hud._combo_status.text.contains("MANUAL"),
		"trick HUD: landing timing takes priority over repeat and hold detail")
	snapshot.combo = 0
	snapshot.feedback = "LANDED  +900"
	snapshot.last_banked_tricks = ["Ollie", "Kickflip", "Switch Kickflip"]
	snapshot.banked_combo = 900
	hud.update_display(snapshot)
	check.call(hud._tricks.text.contains("Switch Kickflip") and hud._combo_status.text == "COMBO BANKED",
		"trick HUD: landed feedback retains the accepted trick receipt")
	snapshot.feedback = ""
	hud.update_display(snapshot)
	check.call(hud._tricks.text.is_empty() and hud._combo_status.text.is_empty(),
		"trick HUD: the landed receipt expires with its authoritative feedback")
	hud.show_controls()
	for frame in 3: await tree.process_frame
	hud.show_trick_guide()
	for frame in 3: await tree.process_frame
	check.call(_has_label(hud._dialog, "BUILD YOUR TRICK SET")
		and _has_label(hud._dialog, "Release a grab before the next flip.")
		and _has_label(hud._dialog, "Heelflip") and _has_label(hud._dialog, "Crooked Grind"),
		"trick HUD: controls explains directional tricks and compatible action chaining")
	var bounds := Rect2(Vector2.ZERO, Vector2(viewport.size))
	check.call(bounds.encloses(hud._dialog.get_global_rect()) and hud._scroll.size.y >= 80,
		"trick HUD: trick guide retains usable scrolling at 960×600 and large UI")
	var instructions := _find_label(hud._dialog, "Release a grab before the next flip.")
	var manual_instructions := _find_label(hud._dialog, "just before landing; a fresh forward tap")
	check.call(_all_wrapped_lines_fit(instructions) and instructions.get_line_count() >= 2
		and _all_wrapped_lines_fit(manual_instructions) and manual_instructions.get_line_count() >= 2,
		"trick HUD: complete flip and manual instructions wrap into fully allocated lines at large UI")
	var directory_row := _find_label(hud._dialog, "Inward Heelflip")
	check.call(_all_wrapped_lines_fit(directory_row),
		"trick HUD: directional trick directory allocates every rendered text line")
	check.call(hud._scroll.get_v_scroll_bar().max_value > hud._scroll.size.y,
		"trick HUD: wrapped guide content remains reachable through vertical scrolling")
	hud._back()
	for frame in 3: await tree.process_frame
	check.call(hud._page == "controls", "trick HUD: trick guide returns to its controls origin without closing the menu")
	snapshot.paused = true
	snapshot.last_banked_tricks = ["Switch Kickflip", "Inward Heelflip", "Clyde Carousel", "Tenement Tumble",
		"Crooked Grind", "Stalefish Grab", "Frontside 540", "Nose Manual"]
	hud.update_display(snapshot)
	hud._show_page("pause")
	for frame in 3: await tree.process_frame
	var receipt := _find_label(hud._dialog, "Switch Kickflip  +  Inward Heelflip")
	check.call(_all_wrapped_lines_fit(receipt) and receipt.get_line_count() >= 2,
		"trick HUD: a long bank receipt wraps completely inside the scrolling pause panel")
	viewport.queue_free()
	await tree.process_frame


static func _has_label(node: Node, fragment: String) -> bool:
	return _find_label(node, fragment) != null


static func _find_label(node: Node, fragment: String) -> Label:
	if node is Label and node.text.contains(fragment): return node
	for child: Node in node.get_children():
		var found := _find_label(child, fragment)
		if found != null: return found
	return null


static func _all_wrapped_lines_fit(label: Label) -> bool:
	if label == null: return false
	var lines := label.get_line_count()
	var font: Font = label.get_theme_font("font")
	var height := font.get_height(label.get_theme_font_size("font_size")) * lines
	height += label.get_theme_constant("line_spacing") * maxi(0, lines - 1)
	return lines == label.get_visible_line_count() and label.size.y + 1.0 >= height
