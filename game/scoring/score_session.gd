extends RefCounted
## Session-only M01 scoring. Combo links/manuals/rails are M02 tasks.

var total_score: int = 0
var combo_base: int = 0
var combo_multiplier: int = 0
var best_combo: int = 0
var last_trick: String = ""
var last_banked: int = 0
var trick_history: Array[String] = []
var _repetitions: Dictionary = {}

func add_trick(trick_name: String, points: int) -> void:
	if points <= 0 or trick_name.is_empty():
		return
	var repeats: int = _repetitions.get(trick_name, 0)
	combo_base += maxi(1, int(float(points) / pow(2.0, mini(repeats, 4))))
	_repetitions[trick_name] = repeats + 1
	combo_multiplier = mini(_repetitions.size(), 8)
	last_trick = trick_name
	trick_history.append(trick_name)
	if trick_history.size() > 8:
		trick_history.pop_front()

func get_combo_value() -> int:
	return combo_base * combo_multiplier

func bank_combo() -> int:
	var value := get_combo_value()
	total_score += value
	best_combo = maxi(best_combo, value)
	last_banked = value
	_clear_combo()
	return value

func drop_combo() -> void:
	last_banked = 0
	_clear_combo()

func reset() -> void:
	total_score = 0
	best_combo = 0
	last_banked = 0
	_clear_combo()

func _clear_combo() -> void:
	combo_base = 0
	combo_multiplier = 0
	last_trick = ""
	trick_history.clear()
	_repetitions.clear()
