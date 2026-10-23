extends RefCounted
## Original M02 definitions and structural guards. See ADR-006 for runtime guards.
## Definitions select directional variants; movement still owns physical eligibility.

const LANDING_LINK_SECONDS: float = 0.35
const RUN_OVERTIME_SECONDS: float = 3.0
const REPEAT_HALVING_LIMIT: int = 4
const UNIQUE_MULTIPLIER_LIMIT: int = 8
const MAX_BASE_POINTS: int = 1000000

const STATES: Array[String] = ["ground", "air", "grind", "manual", "revert", "bail"]
const ACTIVATIONS: Array[String] = ["launch", "press", "landing", "entry", "crossing"]
const TRANSITIONS: Dictionary = {
	"ground": ["air", "manual", "revert", "bail"],
	"air": ["ground", "grind", "bail"],
	"grind": ["air", "ground", "bail"],
	"manual": ["ground", "air", "bail"],
	"revert": ["ground", "manual", "air", "bail"],
	"bail": ["ground"],
}
const FAMILIES: Array[String] = ["launch", "flip", "grab", "spin", "grind", "manual", "revert", "special", "gap"]
const DIRECTIONS: Array[String] = ["neutral", "north", "south", "east", "west",
	"north_east", "north_west", "south_east", "south_west"]
const DIRECTIONAL_SETS: Dictionary = {
	"flip": {"neutral": "kickflip", "north": "hardflip", "south": "pop_shove_it",
		"east": "heelflip", "west": "kickflip", "north_west": "varial_kickflip",
		"north_east": "inward_heelflip", "south_west": "tre_flip", "south_east": "varial_heelflip"},
	"grab": {"neutral": "melon_grab", "north": "nose_grab", "south": "tail_grab",
		"east": "indy_grab", "west": "melon_grab", "north_west": "mute_grab",
		"north_east": "japan_grab", "south_west": "method_grab", "south_east": "stalefish_grab"},
	"grind": {"neutral": "rail_grind", "north": "nosegrind", "south": "five_o_grind",
		"east": "boardslide", "west": "lipslide", "north_west": "crooked_grind",
		"north_east": "overcrook_grind", "south_west": "smith_grind", "south_east": "feeble_grind"},
	"manual": {"neutral": "manual", "north": "nose_manual", "south": "manual",
		"east": "manual", "west": "manual", "north_west": "nose_manual",
		"north_east": "nose_manual", "south_west": "manual", "south_east": "manual"},
}
const DEFINITIONS: Array = [
	{"id": "ollie", "display_name": "Ollie", "base_points": 100, "family": "launch",
		"allowed_states": ["ground", "manual", "grind"], "activation": "launch"},
	{"id": "kickflip", "display_name": "Kickflip", "base_points": 300, "family": "flip",
		"allowed_states": ["air"], "activation": "press", "duration": 0.32, "board_roll": TAU, "board_yaw": 0.0, "board_pitch": 0.0},
	{"id": "heelflip", "display_name": "Heelflip", "base_points": 300, "family": "flip",
		"allowed_states": ["air"], "activation": "press", "duration": 0.32, "board_roll": -TAU, "board_yaw": 0.0, "board_pitch": 0.0},
	{"id": "pop_shove_it", "display_name": "Pop Shove-it", "base_points": 250, "family": "flip",
		"allowed_states": ["air"], "activation": "press", "duration": 0.30, "board_roll": 0.0, "board_yaw": PI, "board_pitch": 0.0},
	{"id": "hardflip", "display_name": "Hardflip", "base_points": 500, "family": "flip",
		"allowed_states": ["air"], "activation": "press", "duration": 0.36, "board_roll": TAU, "board_yaw": -PI, "board_pitch": 0.40},
	{"id": "varial_kickflip", "display_name": "Varial Kickflip", "base_points": 450, "family": "flip",
		"allowed_states": ["air"], "activation": "press", "duration": 0.34, "board_roll": TAU, "board_yaw": PI, "board_pitch": 0.0},
	{"id": "inward_heelflip", "display_name": "Inward Heelflip", "base_points": 550, "family": "flip",
		"allowed_states": ["air"], "activation": "press", "duration": 0.38, "board_roll": -TAU, "board_yaw": PI, "board_pitch": 0.25},
	{"id": "tre_flip", "display_name": "360 Flip", "base_points": 600, "family": "flip",
		"allowed_states": ["air"], "activation": "press", "duration": 0.40, "board_roll": TAU, "board_yaw": TAU, "board_pitch": 0.0},
	{"id": "varial_heelflip", "display_name": "Varial Heelflip", "base_points": 450, "family": "flip",
		"allowed_states": ["air"], "activation": "press", "duration": 0.34, "board_roll": -TAU, "board_yaw": -PI, "board_pitch": 0.0},
	{"id": "melon_grab", "display_name": "Melon Grab", "base_points": 250, "family": "grab",
		"allowed_states": ["air"], "activation": "press", "grab_side": -1.0,
		"grab_target": Vector3(-0.128, 0.022, -0.035), "board_pitch": -0.08, "board_roll": 0.0},
	{"id": "indy_grab", "display_name": "Indy Grab", "base_points": 250, "family": "grab",
		"allowed_states": ["air"], "activation": "press", "grab_side": 1.0,
		"grab_target": Vector3(0.128, 0.022, -0.035), "board_pitch": 0.05, "board_roll": 0.0},
	{"id": "nose_grab", "display_name": "Nose Grab", "base_points": 350, "family": "grab",
		"allowed_states": ["air"], "activation": "press", "grab_side": -1.0,
		"grab_target": Vector3(0, 0.022, -0.38), "board_pitch": 0.18, "board_roll": 0.0},
	{"id": "tail_grab", "display_name": "Tail Grab", "base_points": 350, "family": "grab",
		"allowed_states": ["air"], "activation": "press", "grab_side": 1.0,
		"grab_target": Vector3(0, 0.022, 0.38), "board_pitch": -0.18, "board_roll": 0.0},
	{"id": "mute_grab", "display_name": "Mute Grab", "base_points": 300, "family": "grab",
		"allowed_states": ["air"], "activation": "press", "grab_side": -1.0,
		"grab_target": Vector3(0.128, 0.022, -0.09), "board_pitch": 0.10, "board_roll": -0.10},
	{"id": "japan_grab", "display_name": "Japan Grab", "base_points": 400, "family": "grab",
		"allowed_states": ["air"], "activation": "press", "grab_side": 1.0,
		"grab_target": Vector3(0.128, 0.022, -0.12), "board_pitch": 0.20, "board_roll": 0.24},
	{"id": "method_grab", "display_name": "Method Grab", "base_points": 400, "family": "grab",
		"allowed_states": ["air"], "activation": "press", "grab_side": -1.0,
		"grab_target": Vector3(-0.128, 0.022, 0.06), "board_pitch": 0.15, "board_roll": -0.40},
	{"id": "stalefish_grab", "display_name": "Stalefish Grab", "base_points": 350, "family": "grab",
		"allowed_states": ["air"], "activation": "press", "grab_side": 1.0,
		"grab_target": Vector3(0.128, 0.022, 0.15), "board_pitch": -0.10, "board_roll": 0.08},
	{"id": "spin_180", "display_name": "Spin 180", "base_points": 200, "family": "spin",
		"allowed_states": ["air"], "activation": "landing"},
	{"id": "rail_grind", "display_name": "Rail Grind", "base_points": 200, "family": "grind",
		"allowed_states": ["grind"], "activation": "entry", "grind_yaw": 0.0, "grind_pitch": 0.0},
	{"id": "nosegrind", "display_name": "Nosegrind", "base_points": 300, "family": "grind",
		"allowed_states": ["grind"], "activation": "entry", "grind_yaw": 0.0, "grind_pitch": -0.18},
	{"id": "five_o_grind", "display_name": "5-0 Grind", "base_points": 300, "family": "grind",
		"allowed_states": ["grind"], "activation": "entry", "grind_yaw": 0.0, "grind_pitch": 0.20},
	{"id": "boardslide", "display_name": "Boardslide", "base_points": 250, "family": "grind",
		"allowed_states": ["grind"], "activation": "entry", "grind_yaw": PI / 2.0, "grind_pitch": 0.0},
	{"id": "lipslide", "display_name": "Lipslide", "base_points": 300, "family": "grind",
		"allowed_states": ["grind"], "activation": "entry", "grind_yaw": -PI / 2.0, "grind_pitch": 0.0},
	{"id": "crooked_grind", "display_name": "Crooked Grind", "base_points": 350, "family": "grind",
		"allowed_states": ["grind"], "activation": "entry", "grind_yaw": -0.35, "grind_pitch": -0.18},
	{"id": "overcrook_grind", "display_name": "Overcrook Grind", "base_points": 400, "family": "grind",
		"allowed_states": ["grind"], "activation": "entry", "grind_yaw": 0.35, "grind_pitch": -0.18},
	{"id": "smith_grind", "display_name": "Smith Grind", "base_points": 350, "family": "grind",
		"allowed_states": ["grind"], "activation": "entry", "grind_yaw": -0.55, "grind_pitch": -0.12},
	{"id": "feeble_grind", "display_name": "Feeble Grind", "base_points": 350, "family": "grind",
		"allowed_states": ["grind"], "activation": "entry", "grind_yaw": 0.55, "grind_pitch": -0.12},
	{"id": "manual", "display_name": "Manual", "base_points": 100, "family": "manual",
		"allowed_states": ["manual"], "activation": "entry", "manual_sign": 1.0},
	{"id": "nose_manual", "display_name": "Nose Manual", "base_points": 150, "family": "manual",
		"allowed_states": ["manual"], "activation": "entry", "manual_sign": -1.0},
	{"id": "revert", "display_name": "Revert", "base_points": 150, "family": "revert",
		"allowed_states": ["revert"], "activation": "entry"},
	{"id": "special_clyde_carousel", "display_name": "Clyde Carousel", "base_points": 1000, "family": "special",
		"allowed_states": ["air"], "activation": "press"},
	{"id": "special_tenement_tumble", "display_name": "Tenement Tumble", "base_points": 1200, "family": "special",
		"allowed_states": ["air"], "activation": "press"},
	{"id": "named_gap", "display_name": "Named Gap", "base_points": 500, "family": "gap",
		"allowed_states": ["air", "ground", "grind", "manual"], "activation": "crossing"},
]

static func ids() -> Array[String]:
	var result: Array[String] = []
	for entry: Dictionary in DEFINITIONS:
		result.append(entry["id"])
	return result

static func definition(trick_id: String) -> Dictionary:
	for entry: Dictionary in DEFINITIONS:
		if entry["id"] == trick_id:
			return entry.duplicate(true)
	return {}

static func family_ids(family: String) -> Array[String]:
	var result: Array[String] = []
	for entry: Dictionary in DEFINITIONS:
		if entry["family"] == family:
			result.append(entry["id"])
	return result

static func resolve(family: String, direction: String = "neutral") -> Dictionary:
	# Unknown input never silently awards a default trick.
	if not DIRECTIONAL_SETS.has(family) or not DIRECTIONS.has(direction):
		return {}
	return definition(DIRECTIONAL_SETS[family][direction])

static func is_known(trick_id: String) -> bool:
	return not definition(trick_id).is_empty()

static func base_points(trick_id: String) -> int:
	return int(definition(trick_id).get("base_points", 0))

static func can_perform(trick_id: String, state: String) -> bool:
	# Structural eligibility only; callers still enforce feature/input/timing gates.
	var entry := definition(trick_id)
	return not entry.is_empty() and STATES.has(state) and entry["allowed_states"].has(state)

static func can_transition(from_state: String, to_state: String) -> bool:
	# Staying in a state is an update, not a new transition or scoring event.
	return TRANSITIONS.has(from_state) and TRANSITIONS[from_state].has(to_state)

static func repeated_points(points: int, previous_repeats: int) -> int:
	if points <= 0:
		return 0
	var halvings := clampi(previous_repeats, 0, REPEAT_HALVING_LIMIT)
	return maxi(1, int(float(points) / pow(2.0, halvings)))

static func validate_definitions(entries: Array = DEFINITIONS) -> Array[String]:
	var errors: Array[String] = []
	var seen_ids: Dictionary = {}
	if entries.is_empty():
		errors.append("Catalog must contain at least one trick.")
	for index: int in entries.size():
		var raw: Variant = entries[index]
		var prefix := "Entry %d: " % index
		if not raw is Dictionary:
			errors.append(prefix + "expected a Dictionary.")
			continue
		var entry: Dictionary = raw
		var raw_id: Variant = entry.get("id")
		if not raw_id is String or String(raw_id).is_empty():
			errors.append(prefix + "id must be a nonempty String.")
		else:
			var trick_id: String = raw_id
			if not trick_id.is_valid_identifier() or trick_id != trick_id.to_lower():
				errors.append(prefix + "id must be a lowercase identifier.")
			if seen_ids.has(trick_id):
				errors.append(prefix + "duplicate id " + trick_id + ".")
			seen_ids[trick_id] = true
		var display_name: Variant = entry.get("display_name")
		if not display_name is String or String(display_name).strip_edges().is_empty():
			errors.append(prefix + "display_name must be a nonempty String.")
		var points: Variant = entry.get("base_points")
		if not points is int or int(points) < 1 or int(points) > MAX_BASE_POINTS:
			errors.append(prefix + "base_points must be an integer from 1 to %d." % MAX_BASE_POINTS)
		var allowed_states: Variant = entry.get("allowed_states")
		if not allowed_states is Array or (allowed_states as Array).is_empty():
			errors.append(prefix + "allowed_states must be a nonempty Array.")
		else:
			var seen_states: Dictionary = {}
			for state: Variant in allowed_states:
				if not state is String or not STATES.has(state):
					errors.append(prefix + "allowed_states contains an unknown state.")
				elif seen_states.has(state):
					errors.append(prefix + "allowed_states contains a duplicate state.")
				else:
					seen_states[state] = true
		var activation: Variant = entry.get("activation")
		if not activation is String or not ACTIVATIONS.has(activation):
			errors.append(prefix + "activation must be a known event type.")
		var family: Variant = entry.get("family")
		if not family is String or not FAMILIES.has(family):
			errors.append(prefix + "family must be a known trick family.")
		else:
			_validate_pose(entry, family, prefix, errors)
	return errors

static func _validate_pose(entry: Dictionary, family: String, prefix: String, errors: Array[String]) -> void:
	var required: Array[String] = []
	match family:
		"flip": required = ["duration", "board_roll", "board_yaw", "board_pitch"]
		"grab": required = ["grab_side", "board_pitch", "board_roll"]
		"grind": required = ["grind_yaw", "grind_pitch"]
		"manual": required = ["manual_sign"]
	for field: String in required:
		var value: Variant = entry.get(field)
		if not (value is float or value is int) or not is_finite(float(value)):
			errors.append(prefix + field + " must be a finite number.")
		elif field == "duration" and (float(value) < 0.30 or float(value) > 0.55):
			errors.append(prefix + "duration must be between 0.30 and 0.55 seconds.")
		elif field in ["grab_side", "manual_sign"] and absf(float(value)) != 1.0:
			errors.append(prefix + field + " must be -1 or 1.")
		elif field != "duration" and absf(float(value)) > TAU * 2.0:
			errors.append(prefix + field + " exceeds two rotations.")
	if family == "grab":
		var target: Variant = entry.get("grab_target")
		if not target is Vector3:
			errors.append(prefix + "grab_target must be a board-local Vector3.")
		elif not (target as Vector3).is_finite() or (target as Vector3).length() > 0.60:
			errors.append(prefix + "grab_target must be finite and within the board.")
