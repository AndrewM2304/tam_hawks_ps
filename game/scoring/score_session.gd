extends RefCounted
## Authoritative session score and landing-link deadline. Tick only during active play.
## Stable gameplay IDs own run-long staleness independently of styled labels.
## Every accepted entry builds the combo; holds and rotations extend existing tricks.

const Catalog = preload("res://game/tricks/trick_catalog.gd")
## Saturate score records at signed 32-bit maximum for portable HUD/save consumers.
## Individual events obey the catalog's 1,000,000-point authoring bound. Existing
## gameplay awards are 100–1,200 points; these caps prevent overflow, not tune play.
const MAX_SCORE: int = 2147483647
const MAX_EVENT_POINTS: int = Catalog.MAX_BASE_POINTS
const MULTIPLIER_LIMIT: int = 100

var total_score: int = 0
var combo_base: int = 0
var combo_multiplier: int = 0
var best_combo: int = 0
var last_trick: String = ""
var last_banked: int = 0
var trick_history: Array[String] = []
var combo_trick_count: int = 0
var last_award: int = 0
var last_repeat: bool = false
var last_bonus: int = 0
var last_banked_tricks: Array[String] = []
var last_dropped_value: int = 0
var pending_landing: bool = false
var landing_remaining: float = 0.0
var _repetitions: Dictionary = {}
var _last_identity := ""
var _last_repeats_before := 0
var _last_entry_points := 0
var _last_rotation_suffix := ""

func add_trick(trick_name: String, points: int, identity: String = "") -> int:
	if points <= 0 or trick_name.strip_edges().is_empty():
		return 0
	var repeat_key := identity.strip_edges() if not identity.strip_edges().is_empty() else trick_name
	var repeats: int = _repetitions.get(repeat_key, 0)
	var award: int = Catalog.repeated_points(mini(points, MAX_EVENT_POINTS), repeats)
	var before := clampi(combo_base, 0, MAX_SCORE)
	combo_base = mini(MAX_SCORE, before + award)
	_repetitions[repeat_key] = mini(repeats + 1, Catalog.REPEAT_HALVING_LIMIT)
	combo_trick_count = mini(MAX_SCORE, combo_trick_count + 1)
	combo_multiplier = mini(combo_trick_count, MULTIPLIER_LIMIT)
	last_award = combo_base - before
	last_repeat = repeats > 0
	last_bonus = 0
	_last_identity = repeat_key
	_last_repeats_before = repeats
	_last_entry_points = last_award
	_last_rotation_suffix = ""
	last_trick = trick_name
	trick_history.append(trick_name)
	if trick_history.size() > 8:
		trick_history.pop_front()
	return last_award

## A second tap can refine an unfinished single flip into one double flip.
## Replace that provisional entry, including its staleness identity, rather
## than awarding a second entry. Points are the upgraded move's full base value.
## The returned signed adjustment is bounded by actual score capacity; a stale
## upgraded move can be worth less than the provisional move it replaces.
func upgrade_last_trick(trick_name: String, points: int, identity: String = "") -> int:
	if points <= 0 or trick_name.strip_edges().is_empty() or _last_identity.is_empty() \
			or combo_trick_count <= 0 or trick_history.is_empty():
		return 0
	if _last_repeats_before == 0:
		_repetitions.erase(_last_identity)
	else:
		_repetitions[_last_identity] = _last_repeats_before
	var repeat_key := identity.strip_edges() if not identity.strip_edges().is_empty() else trick_name
	var repeats: int = _repetitions.get(repeat_key, 0)
	var award := Catalog.repeated_points(mini(points, MAX_EVENT_POINTS), repeats)
	var before := clampi(combo_base, 0, MAX_SCORE)
	var without_entry := maxi(0, before - _last_entry_points)
	combo_base = mini(MAX_SCORE, without_entry + award)
	_last_entry_points = combo_base - without_entry
	_last_identity = repeat_key
	_last_repeats_before = repeats
	_repetitions[repeat_key] = mini(repeats + 1, Catalog.REPEAT_HALVING_LIMIT)
	last_award = _last_entry_points
	last_repeat = repeats > 0
	last_bonus = 0
	last_trick = trick_name + _last_rotation_suffix
	trick_history[trick_history.size() - 1] = last_trick
	return combo_base - before

## The skater owns each hold's duration/cap. These points extend an existing
## trick only: they never create an entry, increase variety or move a deadline.
func add_hold_points(points: int) -> int:
	return _add_bonus(points)

## Rotation extends an air trick, not another multiplier entry. Optional text
## decorates its receipt without changing the stable repetition identity.
func add_spin_bonus(points: int, label: String = "") -> int:
	var added := _add_bonus(points)
	if added > 0 and not label.strip_edges().is_empty() and not trick_history.is_empty():
		var suffix := " · " + label.strip_edges()
		_last_rotation_suffix += suffix
		last_trick += suffix
		trick_history[trick_history.size() - 1] = last_trick
	return added

func _add_bonus(points: int) -> int:
	if points <= 0 or combo_trick_count <= 0 or get_combo_value() <= 0:
		return 0
	var before := clampi(combo_base, 0, MAX_SCORE)
	combo_base = mini(MAX_SCORE, before + mini(points, MAX_EVENT_POINTS))
	last_bonus = combo_base - before
	return last_bonus

func get_combo_value() -> int:
	return mini(MAX_SCORE, clampi(combo_base, 0, MAX_SCORE)
		* clampi(combo_multiplier, 0, MULTIPLIER_LIMIT))

## A duplicate landing event cannot extend the same pending combo.
func begin_landing() -> void:
	if pending_landing or get_combo_value() <= 0:
		return
	pending_landing = true
	landing_remaining = Catalog.LANDING_LINK_SECONDS

## Only a valid movement link suspends banking; merely adding a trick does not.
func continue_combo() -> void:
	pending_landing = false
	landing_remaining = 0.0

## Return a bank value exactly once. Invalid deltas and unticked pauses consume no time.
func tick(delta: float) -> int:
	if not pending_landing or not is_finite(delta) or delta <= 0.0:
		return 0
	if get_combo_value() <= 0:
		continue_combo()
		return 0
	landing_remaining = maxf(0.0, landing_remaining - delta)
	# Remove only floating-point residue after accumulated physics steps.
	if landing_remaining <= 0.000000000001:
		return bank_combo()
	return 0

func bank_combo() -> int:
	var value := get_combo_value()
	total_score = mini(MAX_SCORE, clampi(total_score, 0, MAX_SCORE) + value)
	best_combo = maxi(clampi(best_combo, 0, MAX_SCORE), value)
	last_banked = value
	last_banked_tricks = trick_history.duplicate()
	last_dropped_value = 0
	_clear_combo()
	return value

func drop_combo() -> void:
	last_dropped_value = get_combo_value()
	last_banked = 0
	last_banked_tricks.clear()
	_clear_combo()

func reset() -> void:
	total_score = 0
	best_combo = 0
	last_banked = 0
	last_banked_tricks.clear()
	last_dropped_value = 0
	_clear_combo()
	_repetitions.clear()

func _clear_combo() -> void:
	continue_combo()
	combo_base = 0
	combo_multiplier = 0
	last_trick = ""
	combo_trick_count = 0
	last_award = 0
	last_repeat = false
	last_bonus = 0
	_last_identity = ""
	_last_repeats_before = 0
	_last_entry_points = 0
	_last_rotation_suffix = ""
	trick_history.clear()
