extends RefCounted
## Original trick definitions and structural guards. See ADR-006 for runtime guards.
## A definition does not establish physical entry, input freshness or animation.

const LANDING_LINK_SECONDS: float = 0.35
const RUN_OVERTIME_SECONDS: float = 3.0
const REPEAT_HALVING_LIMIT: int = 4
const UNIQUE_MULTIPLIER_LIMIT: int = 8
const MAX_BASE_POINTS: int = 1000000

const STATES: Array[String] = ["ground", "air", "grind", "manual", "lip", "revert", "bail"]
const ACTIVATIONS: Array[String] = ["launch", "press", "landing", "entry", "crossing"]
const TRANSITIONS: Dictionary = {
	"ground": ["air", "manual", "revert", "bail"],
	"air": ["ground", "grind", "lip", "bail"],
	"grind": ["air", "ground", "bail"],
	"manual": ["ground", "air", "bail"],
	"lip": ["air", "ground", "bail"],
	"revert": ["ground", "manual", "air", "bail"],
	"bail": ["ground"],
}
const DEFINITIONS: Array = [
	{"id": "ollie", "display_name": "Ollie", "base_points": 100,
		"allowed_states": ["ground", "manual", "grind", "lip"], "activation": "launch"},
	{"id": "kickflip", "display_name": "Kickflip", "base_points": 300,
		"allowed_states": ["air"], "activation": "press"},
	{"id": "heelflip", "display_name": "Heelflip", "base_points": 300,
		"allowed_states": ["air"], "activation": "press"},
	{"id": "pop_shuvit", "display_name": "Pop Shuvit", "base_points": 180,
		"allowed_states": ["air"], "activation": "press"},
	{"id": "frontside_shuvit", "display_name": "Frontside Shuvit", "base_points": 200,
		"allowed_states": ["air"], "activation": "press"},
	{"id": "varial_flip", "display_name": "Varial Flip", "base_points": 450,
		"allowed_states": ["air"], "activation": "press"},
	{"id": "hardflip", "display_name": "Hardflip", "base_points": 550,
		"allowed_states": ["air"], "activation": "press"},
	{"id": "melon_grab", "display_name": "Melon Grab", "base_points": 250,
		"allowed_states": ["air"], "activation": "press"},
	{"id": "indy_grab", "display_name": "Indy Grab", "base_points": 300,
		"allowed_states": ["air"], "activation": "press"},
	{"id": "nose_grab", "display_name": "Nose Grab", "base_points": 300,
		"allowed_states": ["air"], "activation": "press"},
	{"id": "tail_grab", "display_name": "Tail Grab", "base_points": 300,
		"allowed_states": ["air"], "activation": "press"},
	{"id": "method_grab", "display_name": "Method Grab", "base_points": 400,
		"allowed_states": ["air"], "activation": "press"},
	{"id": "spin_180", "display_name": "Spin 180", "base_points": 200,
		"allowed_states": ["air"], "activation": "landing"},
	{"id": "rail_grind", "display_name": "Rail Grind", "base_points": 200,
		"allowed_states": ["grind"], "activation": "entry"},
	{"id": "grind_50_50", "display_name": "50-50", "base_points": 200,
		"allowed_states": ["grind"], "activation": "entry"},
	{"id": "boardslide", "display_name": "Boardslide", "base_points": 200,
		"allowed_states": ["grind"], "activation": "entry"},
	{"id": "manual", "display_name": "Manual", "base_points": 100,
		"allowed_states": ["manual"], "activation": "entry"},
	{"id": "nose_manual", "display_name": "Nose Manual", "base_points": 100,
		"allowed_states": ["manual"], "activation": "entry"},
	{"id": "axle_stall", "display_name": "Axle Stall", "base_points": 200,
		"allowed_states": ["lip"], "activation": "entry"},
	{"id": "nose_stall", "display_name": "Nose Stall", "base_points": 250,
		"allowed_states": ["lip"], "activation": "entry"},
	{"id": "tail_stall", "display_name": "Tail Stall", "base_points": 250,
		"allowed_states": ["lip"], "activation": "entry"},
	{"id": "disaster", "display_name": "Disaster", "base_points": 300,
		"allowed_states": ["lip"], "activation": "entry"},
	{"id": "revert", "display_name": "Revert", "base_points": 150,
		"allowed_states": ["revert"], "activation": "entry"},
	{"id": "special_clyde_carousel", "display_name": "Clyde Carousel", "base_points": 1000,
		"allowed_states": ["air"], "activation": "press"},
	{"id": "special_tenement_tumble", "display_name": "Tenement Tumble", "base_points": 1200,
		"allowed_states": ["air"], "activation": "press"},
	{"id": "named_gap", "display_name": "Named Gap", "base_points": 500,
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


## Entry consumers must recognize catalogued contact styles without relying on
## an English name containing "grind" (50-50 and Boardslide do not).
static func is_grind_name(display_name: String) -> bool:
	for entry: Dictionary in DEFINITIONS:
		if entry.display_name == display_name and entry.allowed_states == ["grind"]:
			return true
	return false

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
	return errors
