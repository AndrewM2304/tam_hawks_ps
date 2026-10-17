extends RefCounted

const Response = preload("res://game/player/skate_response.gd")


static func run(check: Callable) -> void:
	var response = Response.new()
	check.call(absf(response.coast_speed(15.0, 3.0) - 5.97623272188) < 0.000001,
		"skate response: top-speed release reaches about 6 m/s after three seconds")
	check.call(response.coast_speed(15.0, 7.0) == 0.0,
		"skate response: ordinary release stops rather than retaining a minimum cruise")
	for hz: int in [30, 60, 120]:
		var speed := 15.0
		var monotonic := true
		for frame in range(3 * hz):
			var previous := speed
			speed = response.coast_speed(speed, 1.0 / hz)
			monotonic = monotonic and speed >= 0.0 and speed <= previous
		check.call(monotonic and absf(speed - 5.97623272188) < 0.000001,
			"skate response: %d Hz coasting matches elapsed time without generating speed" % hz)
	for invalid: float in [NAN, INF, -INF]:
		check.call(response.coast_speed(invalid, 0.1) == 0.0,
			"skate response: nonfinite speed cannot persist: %s" % invalid)
	check.call(absf(response.coast_speed(-15.0, 3.0) + 5.97623272188) < 0.000001
		and response.coast_speed(-15.0, 7.0) == 0.0,
		"skate response: rollback coasts toward rest without flipping direction")
	var down_slope := response.apply_slope_gravity(0.0, 0.5, 0.1, 22.0)
	var up_slope := response.apply_slope_gravity(0.0, -0.5, 0.1, 22.0)
	check.call(down_slope > 0.0 and absf(down_slope + up_slope) < 0.000001,
		"skate response: projected slope gravity accelerates downhill and rolls back uphill")
	check.call(response.apply_slope_gravity(15.0, 1.0, 1.0, 22.0) == 15.0
		and response.apply_slope_gravity(-15.0, -1.0, 1.0, 22.0) == -15.0,
		"skate response: ground slope acceleration respects both signed speed limits")
	for invalid_delta: float in [NAN, INF, -INF, -1.0, 0.0]:
		check.call(response.coast_speed(10.0, invalid_delta) == 10.0
			and response.steering_step(1.0, 10.0, true, invalid_delta) == 0.0,
			"skate response: invalid/nonpositive time does not advance motion: %s" % invalid_delta)
	check.call(response.coast_speed(0.0, 1.0) == 0.0 and response.coast_speed(0.01, 1.0) == 0.0,
		"skate response: rest and the final low-speed interval stop without reversing")
	check.call(response.coast_speed(30.0, 0.1) < 30.0 and response.coast_speed(30.0, 0.1) > 15.0,
		"skate response: external downhill/rail speed dissipates without an artificial cap jump")

	var reference_angle := 0.0
	for hz: int in [30, 60, 120]:
		response.reset()
		var angle := 0.0
		for frame in range(hz):
			angle += response.steering_step(-1.0, 15.0, true, 1.0 / hz)
		if hz == 30: reference_angle = angle
		check.call(angle > 0.98 and angle < 1.01 and absf(angle - reference_angle) < 0.000001,
			"skate response: %d Hz high-speed carving preserves the 0.1-second response" % hz)
	response.reset()
	var first := response.steering_step(-1.0, 15.0, true, 1.0 / 60.0)
	var later := first
	for frame in range(30): later = response.steering_step(-1.0, 15.0, true, 1.0 / 60.0)
	check.call(first > 0.0 and first < 0.002 and later > first * 5.0 and later <= 1.1 / 60.0,
		"skate response: ground input builds smoothly within the high-speed rate")
	var air := response.steering_step(-1.0, 15.0, false, 0.1)
	check.call(absf(air - 0.05) < 0.000001,
		"skate response: takeoff cannot carry ground turn rate into air correction")
	check.call(response.steering_step(0.0, 15.0, false, 0.1) == 0.0,
		"skate response: released air steering stops correcting immediately")
	var landed := response.steering_step(-1.0, 15.0, true, 1.0 / 60.0)
	check.call(absf(landed - first) < 0.000001,
		"skate response: a landing begins a new ground response without stale yaw")
	response.reset()
	check.call(response.steering_step(0.0, 15.0, true, 0.1) == 0.0,
		"skate response: reset clears all residual steering")
	for invalid: float in [NAN, INF, -INF]:
		response.reset()
		check.call(response.steering_step(invalid, 15.0, true, 0.1) == 0.0
			and is_finite(response.steering_step(1.0, invalid, true, 0.1)),
			"skate response: nonfinite input/speed produces finite steering: %s" % invalid)
	response.reset()
	var left := response.steering_step(-10.0, 15.0, true, 0.1)
	response.reset()
	var right := response.steering_step(10.0, 15.0, true, 0.1)
	check.call(absf(left + right) < 0.000001 and left > 0.0,
		"skate response: steering clamps inputs and treats both directions equally")
	check.call(absf(response.steering_step(10.0, 0.0, false, 0.1) + 0.05) < 0.000001
		and absf(response.steering_step(1.0, 100.0, false, 0.1) + 0.05) < 0.000001,
		"skate response: air correction is bounded independently of ground speed")
