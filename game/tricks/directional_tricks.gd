extends RefCounted
## Pure input snapshot selection. Coordinates follow Input.get_vector:
## left/right are -/+X; up/down are -/+Y. No runtime state or scoring is changed.

const Catalog = preload("res://game/tricks/trick_catalog.gd")
const DIRECTION_THRESHOLD: float = 0.35
const DEFAULTS: Dictionary = {
	"flip": "kickflip", "grab": "melon_grab", "manual": "manual", "lip": "axle_stall",
}
const CARDINALS: Dictionary = {
	"flip": {"left": "kickflip", "right": "heelflip", "up": "frontside_shuvit", "down": "pop_shuvit"},
	"grab": {"left": "melon_grab", "right": "indy_grab", "up": "nose_grab", "down": "tail_grab"},
	"manual": {"up": "nose_manual"},
	"lip": {"left": "disaster", "right": "disaster", "up": "nose_stall", "down": "tail_stall"},
}


static func select(category: String, direction: Vector2) -> Dictionary:
	# Do not convert corrupt device/fixture input into an apparently valid trick.
	if not DEFAULTS.has(category) or not direction.is_finite():
		return {}
	# Vector2 components use engine real precision; admit the authored boundary
	# even when its decimal value rounds just below the scalar float constant.
	var horizontal := _past_threshold(absf(direction.x))
	var vertical := _past_threshold(absf(direction.y))
	var trick_id: String = DEFAULTS[category]
	if horizontal and vertical:
		if category == "flip" and direction.x < 0.0 and direction.y > 0.0:
			return Catalog.definition("varial_flip")
		if category == "flip" and direction.x > 0.0 and direction.y < 0.0:
			return Catalog.definition("hardflip")
		if category == "grab" and direction.x < 0.0 and direction.y < 0.0:
			return Catalog.definition("method_grab")
	# Unassigned diagonals use the stronger axis; exact ties choose horizontal.
	var cardinal := ""
	if horizontal and (not vertical or absf(direction.x) >= absf(direction.y)):
		cardinal = "left" if direction.x < 0.0 else "right"
	elif vertical:
		cardinal = "up" if direction.y < 0.0 else "down"
	trick_id = CARDINALS[category].get(cardinal, trick_id)
	return Catalog.definition(trick_id)


static func _past_threshold(magnitude: float) -> bool:
	return magnitude >= DIRECTION_THRESHOLD or is_equal_approx(magnitude, DIRECTION_THRESHOLD)
