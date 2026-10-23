extends RefCounted
## Original analytic trick motion, not captured franchise animation.
## Coordinates: +Y up, -Z nose/forward. Physics and scoring live in Skater.

static func ollie_pitch(elapsed: float) -> float:
	# Original front-foot lead, then rear-foot tuck/level-off. No physical boost.
	var time := maxf(elapsed, 0.0)
	return .38 * smoothstep(0.0, .045, time) * (1.0 - smoothstep(.065, .18, time))

static func board_angles(flip_id: String, progress: float) -> Vector3:
	var phase := clampf(progress, 0.0, 1.0)
	match flip_id:
		"heelflip":
			return Vector3(0, 0, -TAU * phase)
		"pop_shuvit":
			return Vector3(0, PI * phase, 0)
		"frontside_shuvit":
			return Vector3(0, -PI * phase, 0)
		"varial_flip":
			return Vector3(0, PI * phase, TAU * phase)
		"hardflip":
			# Frontside shuvit plus a flip, with the deck passing more vertically.
			return Vector3(0.90 * sin(PI * phase), -PI * phase, TAU * phase)
		_:
			return Vector3(0, 0, TAU * phase)

static func grab_pose(grab_id: String) -> Dictionary:
	match grab_id:
		"indy_grab":
			return {"hand_side": 1.0, "deck_target": Vector3(0.128, 0.022, 0.015),
				"pitch": -0.10, "roll": -0.12, "tuck": 0.42}
		"nose_grab":
			return {"hand_side": -1.0, "deck_target": Vector3(-0.025, 0.026, -0.385),
				"pitch": 0.30, "roll": -0.04, "tuck": 0.29}
		"tail_grab":
			return {"hand_side": 1.0, "deck_target": Vector3(0.025, 0.026, 0.385),
				"pitch": -0.26, "roll": 0.08, "tuck": 0.44}
		"method_grab":
			return {"hand_side": -1.0, "deck_target": Vector3(-0.128, 0.022, -0.035),
				"pitch": -0.32, "roll": -0.64, "tuck": 0.38}
		_:
			# Default keeps the existing Melon hand/board contact; deeper tuck preserves arm reach.
			return {"hand_side": -1.0, "deck_target": Vector3(-0.128, 0.022, -0.035),
				"pitch": 0.0, "roll": 0.0, "tuck": 0.37}
