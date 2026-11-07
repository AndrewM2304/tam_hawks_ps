extends RefCounted
## Original M02 definitions and structural guards. See ADR-006 for runtime guards.
## Definitions select directional variants; movement still owns physical eligibility.

const LANDING_LINK_SECONDS: float = 0.35
const RUN_OVERTIME_SECONDS: float = 3.0
const REPEAT_HALVING_LIMIT: int = 4
# Legacy public constant retained for old tooling; ScoreSession.MULTIPLIER_LIMIT owns live entry scoring.
const UNIQUE_MULTIPLIER_LIMIT: int = 8
const MAX_BASE_POINTS: int = 1000000

const STATES: Array[String] = ["ground", "air", "grind", "manual", "revert", "transition", "wall", "lip", "skitch", "bail"]
const ACTIVATIONS: Array[String] = ["launch", "press", "landing", "entry", "crossing"]
const TRANSITIONS: Dictionary = {
	"ground": ["air", "manual", "revert", "transition", "skitch", "bail"],
	"air": ["ground", "grind", "transition", "wall", "lip", "bail"],
	"grind": ["air", "ground", "bail"],
	"manual": ["ground", "air", "bail"],
	"revert": ["ground", "manual", "air", "bail"],
	"transition": ["ground", "air", "lip", "bail"],
	"wall": ["air", "ground", "grind", "bail"],
	"lip": ["transition", "ground", "air", "bail"],
	"skitch": ["ground", "air", "bail"],
	"bail": ["ground"],
}
const FAMILIES: Array[String] = ["launch", "flip", "grab", "spin", "grind", "manual", "revert", "special", "gap", "wall", "lip", "skitch"]
# Existing default/save identities reuse authored motion without inflating the
# 78-record repertoire directory. Default selectors return these real identities.
const COMPATIBILITY_ALIASES: Dictionary = {
	"pop_shuvit": {"canonical_id":"pop_shove_it","repetition_id":"pop_shove_it","display_name":"Pop Shuvit","base_points":180,"duration":0.32},
	"frontside_shuvit": {"canonical_id":"pop_shove_it","display_name":"Frontside Shuvit","base_points":200,
		"board_yaw":-PI,"duration":0.32,"base_flip":"frontside_shuvit","upgrade_to":"frontside_shuvit_360"},
	"frontside_shuvit_360": {"canonical_id":"shove_it_360","display_name":"360 Frontside Shuvit","base_points":400,
		"board_yaw":-TAU,"base_flip":"frontside_shuvit","upgrade_to":"frontside_shuvit_540"},
	"frontside_shuvit_540": {"canonical_id":"shove_it_540","display_name":"540 Frontside Shuvit","base_points":600,
		"board_yaw":-PI*3.0,"base_flip":"frontside_shuvit"},
	"varial_flip": {"canonical_id":"varial_kickflip","repetition_id":"varial_kickflip","display_name":"Varial Flip","base_points":450,
		"duration":0.32,"base_flip":"varial_flip","upgrade_to":"double_varial_flip"},
	"double_varial_flip": {"canonical_id":"double_varial_kickflip","repetition_id":"double_varial_kickflip","display_name":"Double Varial Flip","base_points":900,
		"base_flip":"varial_flip","upgrade_to":"triple_varial_flip"},
	"triple_varial_flip": {"canonical_id":"triple_varial_kickflip","repetition_id":"triple_varial_kickflip","display_name":"Triple Varial Flip","base_points":1350,
		"base_flip":"varial_flip"},
	"grind_50_50": {"canonical_id":"rail_grind","repetition_id":"rail_grind","display_name":"50-50","base_points":200},
	"disaster": {"canonical_id":"disaster_stall","repetition_id":"disaster_stall","display_name":"Disaster","base_points":300},
}
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
	"lip": {"neutral": "lip_stall", "north": "nose_stall", "south": "tail_stall",
		"east": "axle_stall", "west": "rock_and_roll", "north_east": "handplant",
		"north_west": "invert", "south_east": "eggplant", "south_west": "disaster_stall"},
	"manual": {"neutral": "manual", "north": "nose_manual", "south": "manual",
		"east": "manual", "west": "manual", "north_west": "nose_manual",
		"north_east": "nose_manual", "south_west": "manual", "south_east": "manual"},
}
## These are movement directions followed by a fresh face-button press.
## Input recognition and the guide use the same records as runtime eligibility.
const SPECIAL_COMMANDS: Array[Dictionary] = [
	{"id": "special_clyde_carousel", "directions": ["west", "east"], "action": "flip"},
	{"id": "special_tenement_tumble", "directions": ["north", "south"], "action": "grab"},
	{"id": "special_kelvin_corkscrew", "directions": ["east", "west"], "action": "flip"},
	{"id": "special_barras_butterflip", "directions": ["south", "north"], "action": "grab"},
	{"id": "special_bridge_blender", "directions": ["north", "east"], "action": "flip"},
	{"id": "special_sandstone_salute", "directions": ["south", "west"], "action": "grab"},
]
const LIP_SUPPORTS: Array[String] = ["deck", "both_trucks", "front_truck", "rear_truck", "palms"]
const SPECIAL_POSES: Array[String] = ["carousel", "tumble", "corkscrew", "butterflip", "blender", "salute"]
const EXISTING_SPECIAL_UNLOCKS: Array[String] = ["special_clyde_carousel", "special_tenement_tumble"]
const DEFINITIONS: Array = [
	{"id": "ollie", "display_name": "Ollie", "base_points": 100, "family": "launch",
		"allowed_states": ["ground", "manual", "grind", "transition", "lip"], "activation": "launch"},
	{"id": "nollie", "display_name": "Nollie", "base_points": 150, "family": "launch",
		"allowed_states": ["ground", "manual", "grind", "transition", "lip"], "activation": "launch", "launch_speed_scale": 1.0},
	{"id": "boneless", "display_name": "Boneless", "base_points": 250, "family": "launch",
		"allowed_states": ["ground"], "activation": "launch", "launch_speed_scale": 1.14},
	{"id": "no_comply", "display_name": "No Comply", "base_points": 200, "family": "launch",
		"allowed_states": ["ground"], "activation": "launch", "launch_speed_scale": 1.10},
	{"id": "kickflip", "display_name": "Kickflip", "base_points": 300, "family": "flip",
		"allowed_states": ["air"], "activation": "press", "duration": 0.32, "board_roll": TAU, "board_yaw": 0.0, "board_pitch": 0.0, "base_flip": "kickflip", "tap_count": 1, "upgrade_to": "double_kickflip"},
	{"id": "heelflip", "display_name": "Heelflip", "base_points": 300, "family": "flip",
		"allowed_states": ["air"], "activation": "press", "duration": 0.32, "board_roll": -TAU, "board_yaw": 0.0, "board_pitch": 0.0, "base_flip": "heelflip", "tap_count": 1, "upgrade_to": "double_heelflip"},
	{"id": "double_kickflip", "display_name": "Double Kickflip", "base_points": 600, "family": "flip",
		"allowed_states": ["air"], "activation": "press", "duration": 0.44, "board_roll": TAU * 2.0, "board_yaw": 0.0, "board_pitch": 0.0, "base_flip": "kickflip", "tap_count": 2, "upgrade_to": "triple_kickflip"},
	{"id": "double_heelflip", "display_name": "Double Heelflip", "base_points": 600, "family": "flip",
		"allowed_states": ["air"], "activation": "press", "duration": 0.44, "board_roll": -TAU * 2.0, "board_yaw": 0.0, "board_pitch": 0.0, "base_flip": "heelflip", "tap_count": 2, "upgrade_to": "triple_heelflip"},
	{"id": "pop_shove_it", "display_name": "Pop Shove-it", "base_points": 250, "family": "flip",
		"allowed_states": ["air"], "activation": "press", "duration": 0.30, "board_roll": 0.0, "board_yaw": PI, "board_pitch": 0.0, "base_flip": "pop_shove_it", "tap_count": 1, "upgrade_to": "shove_it_360"},
	{"id": "hardflip", "display_name": "Hardflip", "base_points": 550, "family": "flip",
		"allowed_states": ["air"], "activation": "press", "duration": 0.32, "board_roll": TAU, "board_yaw": -PI, "board_pitch": 0.40, "base_flip": "hardflip", "tap_count": 1, "upgrade_to": "double_hardflip"},
	{"id": "varial_kickflip", "display_name": "Varial Kickflip", "base_points": 450, "family": "flip",
		"allowed_states": ["air"], "activation": "press", "duration": 0.34, "board_roll": TAU, "board_yaw": PI, "board_pitch": 0.0, "base_flip": "varial_kickflip", "tap_count": 1, "upgrade_to": "double_varial_kickflip"},
	{"id": "inward_heelflip", "display_name": "Inward Heelflip", "base_points": 550, "family": "flip",
		"allowed_states": ["air"], "activation": "press", "duration": 0.38, "board_roll": -TAU, "board_yaw": PI, "board_pitch": 0.25, "base_flip": "inward_heelflip", "tap_count": 1, "upgrade_to": "double_inward_heelflip"},
	{"id": "tre_flip", "display_name": "360 Flip", "base_points": 600, "family": "flip",
		"allowed_states": ["air"], "activation": "press", "duration": 0.40, "board_roll": TAU, "board_yaw": TAU, "board_pitch": 0.0, "base_flip": "tre_flip", "tap_count": 1, "upgrade_to": "double_tre_flip"},
	{"id": "varial_heelflip", "display_name": "Varial Heelflip", "base_points": 450, "family": "flip",
		"allowed_states": ["air"], "activation": "press", "duration": 0.34, "board_roll": -TAU, "board_yaw": -PI, "board_pitch": 0.0, "base_flip": "varial_heelflip", "tap_count": 1, "upgrade_to": "double_varial_heelflip"},
	{"id": "melon_grab", "display_name": "Melon Grab", "base_points": 250, "family": "grab",
		"allowed_states": ["air"], "activation": "press", "grab_side": -1.0,
		"grab_target": Vector3(-0.128, 0.022, -0.035), "board_pitch": -0.08, "board_roll": 0.0},
	{"id": "indy_grab", "display_name": "Indy Grab", "base_points": 300, "family": "grab",
		"allowed_states": ["air"], "activation": "press", "grab_side": 1.0,
		"grab_target": Vector3(0.128, 0.022, -0.035), "board_pitch": 0.05, "board_roll": 0.0},
	{"id": "nose_grab", "display_name": "Nose Grab", "base_points": 300, "family": "grab",
		"allowed_states": ["air"], "activation": "press", "grab_side": -1.0,
		"grab_target": Vector3(0, 0.039, -0.38), "board_pitch": 0.18, "board_roll": 0.0},
	{"id": "tail_grab", "display_name": "Tail Grab", "base_points": 300, "family": "grab",
		"allowed_states": ["air"], "activation": "press", "grab_side": 1.0,
		"grab_target": Vector3(0, 0.039, 0.38), "board_pitch": -0.18, "board_roll": 0.0},
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
	{"id": "boardslide", "display_name": "Boardslide", "base_points": 200, "family": "grind",
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
	{"id": "grind_pivot", "display_name": "Grind Pivot", "base_points": 150, "family": "grind",
		"allowed_states": ["grind"], "activation": "press", "grind_yaw": 0.0, "grind_pitch": 0.0},
	{"id": "manual", "display_name": "Manual", "base_points": 100, "family": "manual",
		"allowed_states": ["manual"], "activation": "entry", "manual_sign": 1.0},
	{"id": "nose_manual", "display_name": "Nose Manual", "base_points": 100, "family": "manual",
		"allowed_states": ["manual"], "activation": "entry", "manual_sign": -1.0},
	{"id": "spacewalk", "display_name": "Spacewalk", "base_points": 250, "family": "manual",
		"allowed_states": ["manual"], "activation": "press", "manual_sign": 1.0, "manual_walk": true,
		"manual_yaw": 0.0, "manual_roll": 0.10, "manual_foot_lift": 0.0},
	{"id": "one_foot_manual", "display_name": "One-foot Manual", "base_points": 300, "family": "manual",
		"allowed_states": ["manual"], "activation": "press", "manual_sign": 1.0, "manual_walk": false,
		"manual_yaw": 0.0, "manual_roll": 0.0, "manual_foot_lift": 0.16},
	{"id": "manual_pivot", "display_name": "Manual Pivot", "base_points": 200, "family": "manual",
		"allowed_states": ["manual"], "activation": "press", "manual_sign": 1.0, "manual_walk": false,
		"manual_yaw": PI, "manual_roll": 0.0, "manual_foot_lift": 0.0},
	{"id": "wallride", "display_name": "Wallride", "base_points": 300, "family": "wall",
		"allowed_states": ["wall"], "activation": "entry"},
	{"id": "skitch", "display_name": "Skitch", "base_points": 150, "family": "skitch",
		"allowed_states": ["skitch"], "activation": "entry"},
	{"id": "wallie", "display_name": "Wallie", "base_points": 250, "family": "launch",
		"allowed_states": ["wall"], "activation": "launch"},
	{"id": "lip_stall", "display_name": "Lip Stall", "base_points": 250, "family": "lip",
		"allowed_states": ["lip"], "activation": "entry", "lip_pitch": 0.0, "lip_roll": 0.0, "lip_yaw": 0.0, "lip_support": "deck", "lip_invert": false, "lip_hand_side": 0.0, "lip_body_pitch": 0.0, "lip_body_roll": 0.0},
	{"id": "revert", "display_name": "Revert", "base_points": 150, "family": "revert",
		"allowed_states": ["revert"], "activation": "entry"},
	{"id": "special_clyde_carousel", "display_name": "Clyde Carousel", "base_points": 1000, "family": "special",
		"allowed_states": ["air"], "activation": "press", "required_unlock": "special_clyde_carousel", "special_pose": "carousel", "duration": 0.65,
		"special_board_roll": 0.0, "special_board_yaw": TAU, "special_board_pitch": 0.0,
		"special_body_pitch": 0.0, "special_body_yaw": 0.0, "special_body_roll": 0.0, "special_tuck": 0.05, "special_grab": false},
	{"id": "special_tenement_tumble", "display_name": "Tenement Tumble", "base_points": 1200, "family": "special",
		"allowed_states": ["air"], "activation": "press", "required_unlock": "special_tenement_tumble", "special_pose": "tumble", "duration": 0.65,
		"special_board_roll": 0.0, "special_board_yaw": 0.0, "special_board_pitch": 0.0,
		"special_body_pitch": TAU, "special_body_yaw": 0.0, "special_body_roll": 0.0, "special_tuck": 0.25, "special_grab": false},
	{"id": "triple_kickflip", "display_name": "Triple Kickflip", "base_points": 900, "family": "flip",
		"allowed_states": ["air"], "activation": "press", "duration": 0.58,
		"board_roll": (TAU) * 3.0, "board_yaw": 0.0, "board_pitch": 0.0, "base_flip": "kickflip", "tap_count": 3},
	{"id": "triple_heelflip", "display_name": "Triple Heelflip", "base_points": 900, "family": "flip",
		"allowed_states": ["air"], "activation": "press", "duration": 0.58,
		"board_roll": (-TAU) * 3.0, "board_yaw": 0.0, "board_pitch": 0.0, "base_flip": "heelflip", "tap_count": 3},
	{"id": "shove_it_360", "display_name": "360 Shove-it", "base_points": 500, "family": "flip",
		"allowed_states": ["air"], "activation": "press", "duration": 0.42,
		"board_roll": 0.0, "board_yaw": PI * 2.0, "board_pitch": 0.0, "base_flip": "pop_shove_it", "tap_count": 2, "upgrade_to": "shove_it_540"},
	{"id": "shove_it_540", "display_name": "540 Shove-it", "base_points": 750, "family": "flip",
		"allowed_states": ["air"], "activation": "press", "duration": 0.54,
		"board_roll": 0.0, "board_yaw": PI * 3.0, "board_pitch": 0.0, "base_flip": "pop_shove_it", "tap_count": 3},
	{"id": "double_hardflip", "display_name": "Double Hardflip", "base_points": 1000, "family": "flip",
		"allowed_states": ["air"], "activation": "press", "duration": 0.50,
		"board_roll": (TAU) * 2.0, "board_yaw": -PI, "board_pitch": 0.40, "base_flip": "hardflip", "tap_count": 2, "upgrade_to": "triple_hardflip"},
	{"id": "triple_hardflip", "display_name": "Triple Hardflip", "base_points": 1500, "family": "flip",
		"allowed_states": ["air"], "activation": "press", "duration": 0.66,
		"board_roll": (TAU) * 3.0, "board_yaw": -PI, "board_pitch": 0.40, "base_flip": "hardflip", "tap_count": 3},
	{"id": "double_varial_kickflip", "display_name": "Double Varial Kickflip", "base_points": 900, "family": "flip",
		"allowed_states": ["air"], "activation": "press", "duration": 0.48,
		"board_roll": (TAU) * 2.0, "board_yaw": PI, "board_pitch": 0.0, "base_flip": "varial_kickflip", "tap_count": 2, "upgrade_to": "triple_varial_kickflip"},
	{"id": "triple_varial_kickflip", "display_name": "Triple Varial Kickflip", "base_points": 1350, "family": "flip",
		"allowed_states": ["air"], "activation": "press", "duration": 0.62,
		"board_roll": (TAU) * 3.0, "board_yaw": PI, "board_pitch": 0.0, "base_flip": "varial_kickflip", "tap_count": 3},
	{"id": "double_inward_heelflip", "display_name": "Double Inward Heelflip", "base_points": 1100, "family": "flip",
		"allowed_states": ["air"], "activation": "press", "duration": 0.52,
		"board_roll": (-TAU) * 2.0, "board_yaw": PI, "board_pitch": 0.25, "base_flip": "inward_heelflip", "tap_count": 2, "upgrade_to": "triple_inward_heelflip"},
	{"id": "triple_inward_heelflip", "display_name": "Triple Inward Heelflip", "base_points": 1650, "family": "flip",
		"allowed_states": ["air"], "activation": "press", "duration": 0.68,
		"board_roll": (-TAU) * 3.0, "board_yaw": PI, "board_pitch": 0.25, "base_flip": "inward_heelflip", "tap_count": 3},
	{"id": "double_tre_flip", "display_name": "Double 360 Flip", "base_points": 1200, "family": "flip",
		"allowed_states": ["air"], "activation": "press", "duration": 0.54,
		"board_roll": (TAU) * 2.0, "board_yaw": TAU, "board_pitch": 0.0, "base_flip": "tre_flip", "tap_count": 2, "upgrade_to": "triple_tre_flip"},
	{"id": "triple_tre_flip", "display_name": "Triple 360 Flip", "base_points": 1800, "family": "flip",
		"allowed_states": ["air"], "activation": "press", "duration": 0.70,
		"board_roll": (TAU) * 3.0, "board_yaw": TAU, "board_pitch": 0.0, "base_flip": "tre_flip", "tap_count": 3},
	{"id": "double_varial_heelflip", "display_name": "Double Varial Heelflip", "base_points": 900, "family": "flip",
		"allowed_states": ["air"], "activation": "press", "duration": 0.48,
		"board_roll": (-TAU) * 2.0, "board_yaw": -PI, "board_pitch": 0.0, "base_flip": "varial_heelflip", "tap_count": 2, "upgrade_to": "triple_varial_heelflip"},
	{"id": "triple_varial_heelflip", "display_name": "Triple Varial Heelflip", "base_points": 1350, "family": "flip",
		"allowed_states": ["air"], "activation": "press", "duration": 0.62,
		"board_roll": (-TAU) * 3.0, "board_yaw": -PI, "board_pitch": 0.0, "base_flip": "varial_heelflip", "tap_count": 3},
	{"id": "axle_stall", "display_name": "Axle Stall", "base_points": 200, "family": "lip",
		"allowed_states": ["lip"], "activation": "entry", "lip_pitch": 0.00, "lip_roll": 0.00, "lip_yaw": PI / 2.0,
		"lip_support": "both_trucks", "lip_invert": false, "lip_hand_side": 0.0, "lip_body_pitch": 0.0, "lip_body_roll": 0.0},
	{"id": "nose_stall", "display_name": "Nose Stall", "base_points": 250, "family": "lip",
		"allowed_states": ["lip"], "activation": "entry", "lip_pitch": -0.36, "lip_roll": 0.00, "lip_yaw": 0.0,
		"lip_support": "front_truck", "lip_invert": false, "lip_hand_side": 0.0, "lip_body_pitch": 0.0, "lip_body_roll": 0.0},
	{"id": "tail_stall", "display_name": "Tail Stall", "base_points": 250, "family": "lip",
		"allowed_states": ["lip"], "activation": "entry", "lip_pitch": 0.36, "lip_roll": 0.00, "lip_yaw": 0.0,
		"lip_support": "rear_truck", "lip_invert": false, "lip_hand_side": 0.0, "lip_body_pitch": 0.0, "lip_body_roll": 0.0},
	{"id": "rock_and_roll", "display_name": "Rock and Roll", "base_points": 450, "family": "lip",
		"allowed_states": ["lip"], "activation": "entry", "lip_pitch": 0.50, "lip_roll": 0.00, "lip_yaw": PI,
		"lip_support": "deck", "lip_invert": false, "lip_hand_side": 0.0, "lip_body_pitch": 0.0, "lip_body_roll": 0.0},
	{"id": "disaster_stall", "display_name": "Disaster Stall", "base_points": 500, "family": "lip",
		"allowed_states": ["lip"], "activation": "entry", "lip_pitch": 0.12, "lip_roll": 0.00, "lip_yaw": PI,
		"lip_support": "deck", "lip_invert": false, "lip_hand_side": 0.0, "lip_body_pitch": 0.0, "lip_body_roll": 0.0},
	{"id": "handplant", "display_name": "Handplant", "base_points": 600, "family": "lip",
		"allowed_states": ["lip"], "activation": "entry", "lip_pitch": 0.45, "lip_roll": 0.20, "lip_yaw": PI / 2.0,
		"lip_support": "palms", "lip_invert": true, "lip_hand_side": -1.0, "lip_body_pitch": PI, "lip_body_roll": 0.0},
	{"id": "invert", "display_name": "Invert", "base_points": 650, "family": "lip",
		"allowed_states": ["lip"], "activation": "entry", "lip_pitch": -0.70, "lip_roll": -0.25, "lip_yaw": 0.0,
		"lip_support": "palms", "lip_invert": true, "lip_hand_side": 0.0, "lip_body_pitch": PI, "lip_body_roll": -0.35},
	{"id": "eggplant", "display_name": "Eggplant", "base_points": 700, "family": "lip",
		"allowed_states": ["lip"], "activation": "entry", "lip_pitch": -0.30, "lip_roll": 0.40, "lip_yaw": -PI / 2.0,
		"lip_support": "palms", "lip_invert": true, "lip_hand_side": 1.0, "lip_body_pitch": PI, "lip_body_roll": 0.35},
	{"id": "one_foot_nose_manual", "display_name": "One-foot Nose Manual", "base_points": 350, "family": "manual",
		"allowed_states": ["manual"], "activation": "press", "manual_sign": -1.0, "manual_foot_lift": 0.16},
	{"id": "hang_ten", "display_name": "Hang Ten", "base_points": 350, "family": "manual",
		"allowed_states": ["manual"], "activation": "press", "manual_sign": -1.0, "manual_foot_shift": -0.20},
	{"id": "crossfoot_manual", "display_name": "Crossfoot Manual", "base_points": 350, "family": "manual",
		"allowed_states": ["manual"], "activation": "press", "manual_sign": 1.0, "manual_cross": true},
	{"id": "pogo", "display_name": "Pogo", "base_points": 450, "family": "manual",
		"allowed_states": ["manual"], "activation": "press", "manual_sign": 1.0, "manual_pogo": true},
	{"id": "casper_manual", "display_name": "Casper Manual", "base_points": 500, "family": "manual",
		"allowed_states": ["manual"], "activation": "press", "manual_sign": 1.0, "manual_casper": true},
	{"id": "nose_manual_pivot", "display_name": "Nose Manual Pivot", "base_points": 250, "family": "manual",
		"allowed_states": ["manual"], "activation": "press", "manual_sign": -1.0, "manual_yaw": PI},
	{"id": "special_kelvin_corkscrew", "display_name": "Kelvin Corkscrew", "base_points": 1600, "family": "special",
		"allowed_states": ["air"], "activation": "press", "required_unlock": "special_tenement_tumble", "special_pose": "corkscrew", "duration": 0.85,
		"special_board_roll": 0.0, "special_board_yaw": 0.0, "special_board_pitch": 0.0,
		"special_body_pitch": 0.0, "special_body_yaw": PI, "special_body_roll": TAU, "special_tuck": 0.20, "special_grab": false},
	{"id": "special_barras_butterflip", "display_name": "Barras Butterflip", "base_points": 1500, "family": "special",
		"allowed_states": ["air"], "activation": "press", "required_unlock": "special_clyde_carousel", "special_pose": "butterflip", "duration": 0.75,
		"special_board_roll": TAU * 2.0, "special_board_yaw": PI, "special_board_pitch": 0.0,
		"special_body_pitch": 0.0, "special_body_yaw": 0.0, "special_body_roll": 0.0, "special_tuck": 0.18, "special_grab": false},
	{"id": "special_bridge_blender", "display_name": "Bridge Blender", "base_points": 1800, "family": "special",
		"allowed_states": ["air"], "activation": "press", "required_unlock": "special_clyde_carousel", "special_pose": "blender", "duration": 0.90,
		"special_board_roll": -TAU, "special_board_yaw": TAU * 2.0, "special_board_pitch": 0.0,
		"special_body_pitch": 0.0, "special_body_yaw": TAU, "special_body_roll": 0.0, "special_tuck": 0.30, "special_grab": false},
	{"id": "special_sandstone_salute", "display_name": "Sandstone Salute", "base_points": 1400, "family": "special",
		"allowed_states": ["air"], "activation": "press", "required_unlock": "special_tenement_tumble", "special_pose": "salute", "duration": 0.75,
		"special_board_roll": 0.0, "special_board_yaw": 0.0, "special_board_pitch": 0.35,
		"special_body_pitch": 0.0, "special_body_yaw": PI, "special_body_roll": 0.0, "special_tuck": 0.12, "special_grab": true},
	{"id": "named_gap", "display_name": "Named Gap", "base_points": 500, "family": "gap",
		"allowed_states": ["air", "ground", "grind", "manual"], "activation": "crossing"},
]

static func ids() -> Array[String]:
	var result: Array[String] = []
	for entry: Dictionary in DEFINITIONS:
		result.append(entry["id"])
	return result

static func definition(trick_id: String) -> Dictionary:
	if COMPATIBILITY_ALIASES.has(trick_id):
		var overrides: Dictionary = COMPATIBILITY_ALIASES[trick_id]
		var result := definition(str(overrides.canonical_id))
		result.merge(overrides.duplicate(true),true)
		result.id = trick_id
		return result
	for entry: Dictionary in DEFINITIONS:
		if entry["id"] == trick_id:
			return entry.duplicate(true)
	return {}


static func compatibility_ids() -> Array:
	return COMPATIBILITY_ALIASES.keys()


static func repetition_id(trick_id: String) -> String:
	# Template reuse alone is not equivalence: Frontside Shuvit overrides the
	# actual yaw and intentionally has no shared repetition identity.
	var entry := definition(trick_id)
	return str(entry.get("repetition_id",trick_id)) if not entry.is_empty() else ""

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

static func resolve_upgrade(trick_id: String, tap_count: int = 0) -> Dictionary:
	# Zero asks for the next incomplete move; an explicit 2/3 selects that stage.
	# Never turn a finished triple into an unrelated move or grant another entry.
	var current := definition(trick_id)
	if current.get("family", "") != "flip" or tap_count < 0 or tap_count > 3 or tap_count == 1:
		return {}
	if tap_count == 0:
		return definition(str(current.get("upgrade_to", "")))
	if int(current.get("tap_count", 1)) > tap_count:
		return {}
	while int(current.get("tap_count", 1)) < tap_count:
		current = definition(str(current.get("upgrade_to", "")))
		if current.is_empty(): return {}
	return current


static func resolve_extension(family: String, action: String, direction: String = "neutral", _current_id: String = "") -> Dictionary:
	if not DIRECTIONS.has(direction) or action not in ["flip", "grab", "revert"]:
		return {}
	if family == "grind":
		return definition("grind_pivot") if action == "revert" else resolve("grind",direction)
	if family == "lip":
		if direction != "neutral": return resolve("lip", direction)
		return definition("handplant" if action == "flip" else ("invert" if action == "grab" else "rock_and_roll"))
	if family != "manual": return {}
	if action == "revert":
		return definition("nose_manual_pivot" if direction.contains("north") else "manual_pivot")
	if action == "flip":
		if direction.contains("north"): return definition("one_foot_nose_manual")
		if direction.contains("south"): return definition("casper_manual")
		return definition("one_foot_manual" if direction == "neutral" else "crossfoot_manual")
	if direction.contains("north"): return definition("hang_ten")
	if direction.contains("south"): return definition("pogo")
	return definition("spacewalk" if direction == "neutral" else "crossfoot_manual")


static func grab_tweak(trick_id: String, direction: String = "neutral") -> Dictionary:
	var entry := definition(trick_id)
	if entry.get("family", "") != "grab" or not DIRECTIONS.has(direction): return {}
	# Keep the original hand contact and identity; root upgrades this one entry.
	var modifier := "boned"
	var pitch := -0.32
	var roll := 0.0
	var yaw := 0.0
	var extension := 0.20
	if direction.contains("south"):
		modifier = "tucked"
		pitch = 0.38
		extension = -0.14
	elif direction.contains("east"):
		modifier = "twisted"
		pitch = 0.12
		roll = 0.28
		yaw = 0.35
		extension = 0.12
	elif direction.contains("west"):
		modifier = "extended"
		pitch = -0.15
		roll = -0.30
		extension = 0.24
	entry["display_name"] = str(entry.display_name) + " " + modifier.capitalize()
	entry["base_points"] = int(entry.base_points) + 150
	entry["tweak_points"] = 150
	entry["tweak_id"] = modifier
	entry["grab_tweak"] = modifier
	entry["tweak_leg_extension"] = extension
	entry["board_pitch"] = float(entry.get("board_pitch", 0.0)) + pitch
	entry["board_roll"] = float(entry.get("board_roll", 0.0)) + roll
	entry["board_yaw"] = float(entry.get("board_yaw", 0.0)) + yaw
	return entry


static func special_commands() -> Array[Dictionary]:
	return SPECIAL_COMMANDS.duplicate(true)


static func is_grind_name(display_name: String) -> bool:
	# Preserve native named-contact recognition without an English-name heuristic.
	for trick_id: String in ids()+compatibility_ids():
		var entry := definition(trick_id)
		if entry.display_name == display_name and entry.allowed_states == ["grind"]: return true
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
		"lip": required = ["lip_pitch", "lip_roll", "lip_yaw", "lip_hand_side", "lip_body_pitch", "lip_body_roll"]
		"special": required = ["duration", "special_board_roll", "special_board_yaw", "special_board_pitch",
			"special_body_pitch", "special_body_yaw", "special_body_roll", "special_tuck"]
	for field: String in required:
		var value: Variant = entry.get(field)
		if not (value is float or value is int) or not is_finite(float(value)):
			errors.append(prefix + field + " must be a finite number.")
		elif field == "duration" and (float(value) < 0.30 or float(value) > (1.2 if family == "special" else 0.75)):
			errors.append(prefix + "duration must stay within its bounded execution window.")
		elif field in ["grab_side", "manual_sign"] and absf(float(value)) != 1.0:
			errors.append(prefix + field + " must be -1 or 1.")
		elif field == "lip_hand_side" and float(value) not in [-1.0, 0.0, 1.0]:
			errors.append(prefix + "lip_hand_side must be -1, 0 or 1.")
		elif field == "special_tuck" and (float(value) < 0.0 or float(value) > 0.6):
			errors.append(prefix + "special_tuck must stay between 0 and 0.6 metres.")
		elif field != "duration" and absf(float(value)) > TAU * 3.0:
			errors.append(prefix + field + " exceeds three rotations.")
	if family == "flip":
		var taps: Variant = entry.get("tap_count")
		if not taps is int or int(taps) < 1 or int(taps) > 3:
			errors.append(prefix + "tap_count must be an integer from 1 to 3.")
		var base: Variant = entry.get("base_flip")
		if not base is String or definition(base).get("family", "") != "flip":
			errors.append(prefix + "base_flip must name an authored flip.")
		if entry.has("upgrade_to"):
			var next: Dictionary = definition(str(entry.upgrade_to))
			if next.get("family", "") != "flip" or next.get("base_flip", "") != base \
					or int(next.get("tap_count", 0)) != int(taps if taps is int else 0) + 1:
				errors.append(prefix + "upgrade_to must advance the same flip by one tap.")
	if family == "lip":
		if not entry.get("lip_support") is String or not LIP_SUPPORTS.has(entry.get("lip_support")):
			errors.append(prefix + "lip_support must name deck, both_trucks, front_truck, rear_truck or palms.")
		if not entry.get("lip_invert") is bool:
			errors.append(prefix + "lip_invert must be a bool.")
		if entry.get("lip_invert") is bool and entry.lip_invert and entry.get("lip_support") != "palms":
			errors.append(prefix + "an inverted lip requires actual palm support.")
	if family == "special":
		if not EXISTING_SPECIAL_UNLOCKS.has(entry.get("required_unlock")):
			errors.append(prefix + "required_unlock must reuse an existing career special unlock.")
		if not SPECIAL_POSES.has(entry.get("special_pose")):
			errors.append(prefix + "special_pose must select an authored animation.")
		if not entry.get("special_grab") is bool:
			errors.append(prefix + "special_grab must be a bool.")
	if family == "grab":
		var target: Variant = entry.get("grab_target")
		if not target is Vector3:
			errors.append(prefix + "grab_target must be a board-local Vector3.")
		elif not (target as Vector3).is_finite() or (target as Vector3).length() > 0.60:
			errors.append(prefix + "grab_target must be finite and within the board.")
	for field: String in ["manual_yaw", "manual_roll", "manual_foot_lift", "manual_foot_shift", "launch_speed_scale"]:
		if not entry.has(field):
			continue
		var value: Variant = entry[field]
		if not (value is float or value is int) or not is_finite(float(value)):
			errors.append(prefix + field + " must be a finite number.")
		elif field == "launch_speed_scale" and (float(value) < 0.5 or float(value) > 1.5):
			errors.append(prefix + "launch_speed_scale must be between 0.5 and 1.5.")
		elif field == "manual_foot_lift" and (float(value) < 0.0 or float(value) > 0.3):
			errors.append(prefix + "manual_foot_lift must stay between 0 and 0.3 metres.")
		elif field == "manual_foot_shift" and absf(float(value)) > 0.25:
			errors.append(prefix + "manual_foot_shift must stay within 0.25 metres.")
		elif field in ["manual_yaw", "manual_roll"] and absf(float(value)) > TAU:
			errors.append(prefix + field + " exceeds one rotation.")
	for field: String in ["manual_walk", "manual_pogo", "manual_casper", "manual_cross"]:
		if entry.has(field) and not entry[field] is bool:
			errors.append(prefix + field + " must be a bool.")
