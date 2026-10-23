extends RefCounted
## Authoritative session score and landing-link deadline. Tick only during active play.
## Stable gameplay IDs can identify repeats independently of styled display labels.
## Legacy callers retain display-name identity, including dynamic spin names.

const Catalog = preload("res://game/tricks/trick_catalog.gd")
## Saturate score records at signed 32-bit maximum for portable HUD/save consumers.
## Individual events obey the catalog's 1,000,000-point authoring bound. Existing
## gameplay awards are 100–1,200 points; these caps prevent overflow, not tune play.
const MAX_SCORE: int = 2147483647
const MAX_EVENT_POINTS: int = Catalog.MAX_BASE_POINTS

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
var last_banked_tricks: Array[String] = []
var last_dropped_value: int = 0
var pending_landing: bool = false
var landing_remaining: float = 0.0
var _repetitions: Dictionary = {}

func add_trick(trick_name: String, points: int, identity: String = "") -> void:
	if points <= 0 or trick_name.strip_edges().is_empty():
		return
	var repeat_key := identity.strip_edges() if not identity.strip_edges().is_empty() else trick_name
	var repeats: int = _repetitions.get(repeat_key, 0)
	var award: int = Catalog.repeated_points(mini(points, MAX_EVENT_POINTS), repeats)
	combo_base = mini(MAX_SCORE, clampi(combo_base, 0, MAX_SCORE) + award)
	_repetitions[repeat_key] = mini(repeats + 1, Catalog.REPEAT_HALVING_LIMIT)
	combo_multiplier = mini(_repetitions.size(), Catalog.UNIQUE_MULTIPLIER_LIMIT)
	combo_trick_count = mini(MAX_SCORE, combo_trick_count + 1)
	last_award = award
	last_repeat = repeats > 0
	last_trick = trick_name
	trick_history.append(trick_name)
	if trick_history.size() > 8:
		trick_history.pop_front()

## The skater owns each hold's duration/cap. These points extend an existing
## trick only: they never create an entry, increase variety or move a deadline.
func add_hold_points(points: int) -> void:
	if points <= 0 or combo_trick_count <= 0 or get_combo_value() <= 0:
		return
	combo_base = mini(MAX_SCORE, clampi(combo_base, 0, MAX_SCORE) + mini(points, MAX_EVENT_POINTS))

func get_combo_value() -> int:
	return mini(MAX_SCORE, clampi(combo_base, 0, MAX_SCORE)
		* clampi(combo_multiplier, 0, Catalog.UNIQUE_MULTIPLIER_LIMIT))

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

func _clear_combo() -> void:
	continue_combo()
	combo_base = 0
	combo_multiplier = 0
	last_trick = ""
	combo_trick_count = 0
	last_award = 0
	last_repeat = false
	trick_history.clear()
	_repetitions.clear()
