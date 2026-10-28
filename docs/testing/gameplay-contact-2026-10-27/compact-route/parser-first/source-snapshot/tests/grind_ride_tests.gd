extends RefCounted
## Pure state checks; player/collision/input integration is checked by the main runner.

const Line = preload("res://game/tricks/grind_line.gd")
const Ride = preload("res://game/tricks/grind_ride.gd")


static func run(check: Callable) -> void:
	var rail = _rail("straight", Vector3.ZERO, Vector3(0, 0, -20))
	var ride = Ride.new()
	check.call(ride.start([rail], Vector3(0.2, 0.1, -5), Vector3(0, 0, -6)),
		"grind ride: an airborne approach within capture bounds attaches")
	check.call(ride.active and ride.direction == 1.0 and is_equal_approx(ride.speed, 6.0)
		and ride.position().distance_to(Vector3(0, 0, -5)) < 0.025,
		"grind ride: entry preserves projected speed and samples the rail")
	check.call(ride.step(0.1, 0.0) == "riding" and ride.distance > 5.5
		and ride.position().z < -5.5 and ride.speed < 6.0,
		"grind ride: forward travel advances distance and loses speed to friction")
	var held_position: Vector3 = ride.position()
	var held_velocity: Vector3 = ride.travel_velocity()
	ride.stop()
	check.call(not ride.active and ride.position() == held_position and ride.travel_velocity() == held_velocity,
		"grind ride: stop retains finite release position and momentum")
	check.call(ride.step(0.2, 0.0) == "slow" and ride.position() == held_position,
		"grind ride: inactive updates do not keep moving the released skater")

	var farther = _rail("far", Vector3(0.4, 0, 0), Vector3(0.4, 0, -20))
	var near = _rail("near", Vector3(0.1, 0, 0), Vector3(0.1, 0, -20))
	var nearest = Ride.new()
	check.call(nearest.start([farther, near], Vector3(0, 0.1, -5), Vector3(0, 0, -6))
		and nearest.line == near, "grind ride: selects nearest eligible rail regardless of list order")
	var obstructed = Ride.new()
	var clear_only_far := func(_from: Vector3, to: Vector3) -> bool: return to.x > 0.2
	check.call(obstructed.start([near, farther], Vector3(0, 0.1, -5), Vector3(0, 0, -6), clear_only_far)
		and obstructed.line == farther, "grind ride: blocked nearest rail falls back to a clear eligible rail")
	var none_clear = Ride.new()
	check.call(not none_clear.start([rail], Vector3(0, 0.1, -5), Vector3(0, 0, -6),
		func(_from: Vector3, _to: Vector3) -> bool: return false),
		"grind ride: obstructed snap is rejected")

	var reverse = Ride.new()
	check.call(reverse.start([rail], Vector3(0, 0.1, -5), Vector3(0, 0, 6))
		and reverse.direction == -1.0, "grind ride: reverse entry keeps its signed travel direction")
	check.call(reverse.step(0.1, 0.0) == "riding" and reverse.distance < 4.5
		and reverse.travel_velocity().z > 0.0, "grind ride: reverse motion decreases distance and keeps momentum")
	for sign_value in [-1.0, 1.0]:
		var edge = Ride.new()
		var at := Vector3(0, 0.05, -0.1 if sign_value < 0 else -19.9)
		check.call(edge.start([rail], at, Vector3(0, 0, -6 * sign_value))
			and edge.step(0.1, 0.0) == "end" and not edge.active,
			"grind ride: crossing an open endpoint releases in direction " + str(sign_value))
		check.call(edge.position().distance_to(Vector3.ZERO if sign_value < 0 else Vector3(0, 0, -20)) < 0.025
			and edge.travel_velocity().z * sign_value < 0.0,
			"grind ride: endpoint clamps without wrapping and preserves outgoing direction")
	check.call(not Ride.new().start([rail], Vector3(0, 0.05, 0.1), Vector3(0, 0, 6))
		and not Ride.new().start([rail], Vector3(0, 0.05, -20.1), Vector3(0, 0, -6)),
		"grind ride: outward approaches beyond either endpoint do not attach")
	check.call(Ride.new().start([rail], Vector3(0, 0.05, 0.1), Vector3(0, 0, -6)),
		"grind ride: an inward approach near an endpoint can attach")
	var curved = Line.new("corner", PackedVector3Array([
		Vector3(4, 2, 8), Vector3(4, 2, 4), Vector3(12, 2, 4),
	]))
	var corner = Ride.new()
	check.call(corner.start([curved], Vector3(4, 2.05, 4.2), Vector3(0, 0, -6))
		and corner.step(0.15, 0.0) == "riding" and corner.position().x > 4.5
		and absf(corner.position().z - 4.0) < 0.025 and corner.travel_velocity().x > 5.0,
		"grind ride: distance follows a translated bent rail and the outgoing tangent turns with it")
	for degrees in [84.0, 86.0]:
		var approach := Vector3(sin(deg_to_rad(degrees)), 0, -cos(deg_to_rad(degrees))) * 8.0
		check.call(Ride.new().start([rail], Vector3(0.5, 0.1, -5), approach) == (degrees < 85.0),
			"grind ride: rough aim accepts84degrees while a distant86degree crossing remains outside its separate near-contact band")
	for offset: Vector3 in [Vector3(0.78,0.1,-5),Vector3(0,0.58,-5),Vector3(0,-0.13,-5)]:
		check.call(Ride.new().start([rail],offset,Vector3(0,-2,-8)),
			"grind ride: deliberate enlarged margin admits a near-edge lateral/vertical approach "+str(offset))
	for direction: float in [-1.0,1.0]:
		var approach := Vector3(sin(deg_to_rad(64.0))*direction,0,-cos(deg_to_rad(64.0)))*8.0
		var level := Ride.new()
		var falling := Ride.new()
		check.call(level.start([rail],Vector3(0,0.1,-5),approach)
			and falling.start([rail],Vector3(0,0.1,-5),approach+Vector3.DOWN*40.0)
			and level.speed >= 7.2 and level.speed <= 8.00001 and is_equal_approx(level.speed,falling.speed),
			"grind ride: angled catch retains at least 90 percent horizontal speed without converting a fall to flat-rail boost")

	var slope = _rail("slope", Vector3.ZERO, Vector3(0, 8, -20))
	var uphill = Ride.new()
	var downhill = Ride.new()
	check.call(uphill.start([slope], Vector3(0, 4.05, -10), Vector3(0, 0, -8))
		and downhill.start([slope], Vector3(0, 4.05, -10), Vector3(0, 0, 8)),
		"grind ride: sloped rails capture both travel directions")
	var up_before: float = uphill.speed
	var down_before: float = downhill.speed
	uphill.step(0.1, 0.0)
	downhill.step(0.1, 0.0)
	check.call(uphill.speed < up_before and downhill.speed > down_before
		and uphill.travel_velocity().y > 0.0 and downhill.travel_velocity().y < 0.0,
		"grind ride: slope gravity changes speed and outgoing velocity retains the vertical tangent")
	var slow = Ride.new()
	slow.start([slope], Vector3(0, 4.05, -10), Vector3(0, 0, -3))
	check.call(slow.step(0.3, 0.0) == "slow" and not slow.active and slow.speed >= 0.0,
		"grind ride: insufficient uphill momentum releases without silently reversing")
	var fast = Ride.new()
	fast.start([slope], Vector3(0, 4.05, -10), Vector3(0, 0, 18))
	fast.step(0.3, 0.0)
	check.call(fast.speed <= 18.0, "grind ride: downhill acceleration respects the speed ceiling")

	var bad_cases := [
		[Vector3(0.86, 0, -5), Vector3(0, 0, -6), "full snap distance"],
		[Vector3(0, 0.61, -5), Vector3(0, 0, -6), "vertical reach"],
		[Vector3(0, -0.15, -5), Vector3(0, 0, -6), "below the rail"],
		[Vector3(0, -0.05, -5), Vector3(0, 1.01, -6), "ascending below the actual rail datum"],
		[Vector3(0.5, 0.1, -5), Vector3(6, 0, 0), "distant sideways approach"],
		[Vector3(0, 0.1, -5), Vector3(0, 0, -1.99), "too little speed"],
		[Vector3(0, 0.1, -5), Vector3(0, 0, -18.01), "excessive speed"],
		[Vector3(INF, 0, -5), Vector3(0, 0, -6), "nonfinite position"],
		[Vector3(0, 0.1, -5), Vector3(0, NAN, -6), "nonfinite velocity"],
	]
	for entry in bad_cases:
		var rejected = Ride.new()
		check.call(not rejected.start([rail], entry[0], entry[1]) and not rejected.active,
			"grind ride: rejects " + entry[2])
	check.call(not Ride.new().start([null, "not a rail", Line.new("empty", PackedVector3Array())],
		Vector3(0, 0.1, -5), Vector3(0, 0, -6)), "grind ride: malformed rail lists cannot attach")
	check.call(not Ride.new().start([_rail("vertical", Vector3.ZERO, Vector3(0, 10, 0))],
		Vector3(0, 5, 0), Vector3(0, 0, -6)), "grind ride: vertical lines have no usable horizontal approach")

	var long_rail = _rail("balance", Vector3.ZERO, Vector3(0, 0, -200))
	var unbalanced = Ride.new()
	var corrected = Ride.new()
	unbalanced.start([long_rail], Vector3(0, 0.1, -5), Vector3(0, 0, -8))
	corrected.start([long_rail], Vector3(0, 0.1, -5), Vector3(0, 0, -8))
	for tick in range(360):
		unbalanced.step(1.0 / 60.0, 0.0)
		corrected.step(1.0 / 60.0, -0.14 - corrected.balance)
	check.call(not unbalanced.active and unbalanced.step(0.0, 0.0) == "bail",
		"grind ride: unattended deterministic balance eventually bails")
	check.call(corrected.active and absf(corrected.balance) < 0.1,
		"grind ride: countersteering controls the balance instead of an unavoidable timeout")
	var bounded = Ride.new()
	var unit_input = Ride.new()
	bounded.start([long_rail], Vector3(0, 0.1, -5), Vector3(0, 0, -8))
	unit_input.start([long_rail], Vector3(0, 0.1, -5), Vector3(0, 0, -8))
	bounded.step(0.1, 1000.0)
	unit_input.step(0.1, 1.0)
	check.call(is_equal_approx(bounded.balance, unit_input.balance),
		"grind ride: analog correction is bounded to the normal input range")
	for invalid_step in [[NAN, 0.0], [INF, 0.0], [-0.1, 0.0], [0.1, NAN]]:
		var invalid = Ride.new()
		invalid.start([rail], Vector3(0, 0.1, -5), Vector3(0, 0, -6))
		check.call(invalid.step(invalid_step[0], invalid_step[1]) == "bail"
			and not invalid.active and invalid.position().is_finite() and invalid.travel_velocity().is_finite(),
			"grind ride: invalid update safely releases without contaminating body transforms")
	_human_error_margin(check, rail)
	_held_intent_capture(check,rail)
	_physical_contact_paths(check)
	_swept_current_height(check)
	_finite_endpoint_clearance(check)


static func _human_error_margin(check: Callable, rail: RefCounted) -> void:
	# An offset approach must remain usable across angle, speed and tick phase;
	# production tries the eligible current origin before moving, then a sweep.
	# Retain every original tuple, including below-band completed moves. The old
	# sixth tuple rounds just below -.14m in Vector3; include its just-inside phase.
	# These are envelopes for a human playtest, not evidence that it feels good.
	var approaches := [
		[30.0, -0.4, -35.0, 8.0, 22.0, 0.50, false],
		[60.0, 0.4, 35.0, 12.0, 42.0, 0.50, false],
		[120.0, -0.5, -25.0, 17.0, 60.0, 0.46, true],
		[60.0, 0.55, 0.0, 4.0, 28.0, 0.46, true],
		[120.0, -0.3, 45.0, 10.0, 18.0, 0.46, true],
		[30.0, 0.0, 0.0, 17.0, 18.0, 0.46, false],
		[30.0, 0.0, 0.0, 17.0, 18.0, 0.47, true],
	]
	for entry in approaches:
		var from := Vector3(entry[1], entry[5], -5.0)
		var radians: float = deg_to_rad(entry[2])
		var velocity := Vector3(sin(radians) * entry[3], -entry[4], -cos(radians) * entry[3])
		var to: Vector3 = from + velocity / entry[0]
		var target: Vector3 = Ride.new()._body_point(rail,float(rail.closest(to).dist))
		print("GRIND_TICK_PHASE ",JSON.stringify({"entry":entry,"from":from,"to":to,
			"physical_body_target":target,"current_height":to.y-target.y}))
		check.call(Ride.new().start([rail], from, velocity),
			"grind forgiveness: the actual pre-move origin catches before the completed tick can overshoot " + str(entry))
		check.call(Ride.new().start([rail], to, velocity) == entry[6],
			"grind forgiveness: completed point capture respects its actual strict height at tick phase " + str(entry))
		check.call(Ride.new().start_swept([rail], from, to, velocity) == entry[6],
			"grind forgiveness: completed sweep preserves the current point-height envelope at tick phase " + str(entry))

	# Preserve the older below-band overshoot tuple as a rejection. Historical
	# eligibility no longer waives the actual current body's height envelope.
	var from := Vector3(0.35, 0.66, -5.0)
	var velocity := Vector3(0, -54, -12)
	var to: Vector3 = from + velocity / 60.0
	check.call(not Ride.new().start([rail], from, velocity)
		and not Ride.new().start([rail], to, velocity)
		and not Ride.new().start_swept([rail], from, to, velocity),
		"grind forgiveness: the old .66m to -.24m overshoot cannot recover below the present14cm band")
	velocity = Vector3(0, -45.6, -12)
	to = from + velocity / 60.0
	check.call(not Ride.new().start([rail], from, velocity)
		and Ride.new().start([rail], to, velocity)
		and Ride.new().start_swept([rail], from, to, velocity),
		"grind forgiveness: .66m to -.10m descending travel retains capture within the present height and displacement bounds")

	var queried_origins: Array[Vector3] = []
	var reject_path := func(origin: Vector3, _at: Vector3) -> bool:
		queried_origins.append(origin)
		return false
	check.call(not Ride.new().start_swept([rail], from, to, velocity, reject_path)
		and not queried_origins.is_empty(),
		"grind forgiveness: a blocked actual-body sweep rejects every historical sample")
	var actual_origin_only := true
	for origin in queried_origins:
		actual_origin_only = actual_origin_only and origin.is_equal_approx(to)
	check.call(actual_origin_only,
		"grind forgiveness: clearance always starts at the current body, never a past sample")

	var rejected_approaches := [
		[Vector3(0.95, 0.1, -5), Vector3(0.95, 0.05, -5.2), Vector3(0, -3, -12), "lateral miss"],
		[Vector3(0, 0.9, -5), Vector3(0, 0.7, -5.2), Vector3(0, -12, -12), "wrong upper level"],
		[Vector3(0, -0.3, -5), Vector3(0, -0.5, -5.2), Vector3(0, -12, -12), "below rail"],
		[Vector3(0.4, 0.3, -5), Vector3(0.4, 0.1, -5), Vector3(8, -12, 0), "distant perpendicular motion"],
		[Vector3(0, 0.1, 0.1), Vector3(0, 0.05, 0.3), Vector3(0, -3, 12), "rail behind travel"],
		[Vector3(0, -0.1, -5), Vector3(0, -0.01, -5.2), Vector3(0, 6, -12), "rising below support"],
		[Vector3(0, 0.3, -5), Vector3(0, 0.1, -5.02), Vector3(0, -12, -1), "insufficient forward speed"],
		[Vector3(0, 0.3, -5), Vector3(0, 0.1, -5.32), Vector3(0, -12, -19), "excessive forward speed"],
		[Vector3(0, 1, -5), Vector3(0, -1, -5.2), Vector3(0, -120, -12), "teleport-sized sweep"],
		[Vector3(INF, 0.3, -5), Vector3(0, 0.1, -5.2), Vector3(0, -12, -12), "nonfinite history"],
	]
	for entry in rejected_approaches:
		check.call(not Ride.new().start_swept([rail], entry[0], entry[1], entry[2]),
			"grind forgiveness: no larger admission envelope for " + entry[3])

	var riding = Ride.new()
	riding.start([rail], Vector3(0, 0.1, -5), Vector3(0, 0, -8))
	var held_distance: float = riding.distance
	check.call(not riding.start_swept([rail], from, to, velocity)
		and is_equal_approx(riding.distance, held_distance),
		"grind forgiveness: a second sweep cannot restart an active rail or duplicate its admission")


static func _held_intent_capture(check: Callable, rail: RefCounted) -> void:
	for ascent: float in [1.01,4.0,9.0]:
		var ride := Ride.new()
		check.call(ride.start([rail],Vector3(0.4,0.1,-5),Vector3(0,ascent,-8))
			and ride.position().distance_to(Vector3(0,0,-5))<0.025 and ride.speed==8.0,
			"grind intent: rising Ollie catches above the real datum without converting ascent into flat-rail speed "+str(ascent))
	check.call(not Ride.new().start([rail],Vector3(0,-0.01,-5),Vector3(0,9,-8)),
		"grind intent: ascent below the rail cannot pull a rider through its underside")
	for side: float in [-1.0,1.0]:
		var crossing := Ride.new()
		check.call(crossing.start([rail],Vector3(side*0.15,0.1,-5),Vector3(-side*8,-2,0))
			and crossing.direction==1.0 and crossing.speed>=7.2 and crossing.speed<=8.0,
			"grind intent: close inward perpendicular crossing catches with stable tangent direction from side "+str(side))
		check.call(not Ride.new().start([rail],Vector3(side*0.15,0.1,-5),Vector3(side*8,-2,0))
			and not Ride.new().start([rail],Vector3(side*0.30,0.1,-5),Vector3(-side*8,-2,0)),
			"grind intent: sideways travel away from the rail or outside contact range has no broad magnetic catch "+str(side))
	var endpoint := Ride.new()
	check.call(endpoint.start([rail],Vector3(0.1,0.1,-19.9),Vector3(-8,-2,0)) and endpoint.direction==-1.0,
		"grind intent: perpendicular catch near an open end chooses the finite inward run")
	var blocked := Ride.new()
	check.call(not blocked.start([rail],Vector3(0.1,0.1,-5),Vector3(-8,4,0),
		func(_from: Vector3,_to: Vector3)->bool:return false)
		and not Ride.new().start([rail],Vector3(0.1,0.1,-5),Vector3(-8,4,0),Callable(),
		func(_line,_offset:float,_direction:float)->bool:return false),
		"grind intent: rising and sideways forgiveness never bypass actual path or support rejection")
	var from := Vector3(0.1,-0.1,-5)
	var to := Vector3(0.1,0.1,-5.1)
	var swept := Ride.new()
	check.call(swept.start_swept([rail],from,to,Vector3(0,12,-6))
		and swept.position().distance_to(to)<=Ride.MAX_CAPTURE_CORRECTION
		and swept.position().distance_to(from)<=Ride.MAX_CAPTURE_TICK_DISPLACEMENT,
		"grind intent: an actual upward crossing uses the same present and previous native correction caps")
	check.call(not Ride.new().start([rail],Vector3(0.1,0.7,-5),Vector3(-8,4,0))
		and not Ride.new().start([rail],Vector3(0.1,-0.2,-5),Vector3(-8,-4,0))
		and not Ride.new().start_swept([rail],Vector3(0,2,-5),Vector3(0,0.1,-5),Vector3(0,-114,-8)),
		"grind intent: new intent handling preserves wrong-level, underside and over-metre sweep exclusions")


static func _physical_contact_paths(check: Callable) -> void:
	var crown:=Line.new("raised crown",PackedVector3Array([Vector3.ZERO,Vector3(0,0,-20)]))
	crown.configure_contact(0.3,0.0,"native.box_crown")
	var raised:=Ride.new()
	check.call(raised.start([crown],Vector3(0,0.4,-5),Vector3(0,4,-8)) and absf(raised.position().y-0.3)<0.000001,
		"grind contact: verified raised bar captures and carries the body on its real crown rather than inside its centre guide")
	check.call(not Ride.new().start([crown],Vector3(0,0.2,-5),Vector3(0,4,-8)),
		"grind contact: being above a guide centre cannot authorize an ascent from below the actual steel crown")
	var slope:=Line.new("inclined crown",PackedVector3Array([Vector3.ZERO,Vector3(0,4,-10)]))
	slope.configure_contact(0.0,0.07,"native.cylinder_crown")
	var up: Vector3=slope.contact_up(slope.length*0.5)
	var at: Vector3=slope.contact_at(slope.length*0.5)
	var tilted:=Ride.new();tilted.body_radius=0.28
	check.call(tilted.start([slope],at+Vector3.UP*0.05,Vector3(0,-1,-8))
		and absf((tilted.position()+Vector3.UP*0.28-slope.contact_at(tilted.distance)).dot(up)-0.28)<0.000001,
		"grind contact: the real upright capsule hemisphere rests outside an inclined crown instead of intersecting its tangent plane")
	var origins: Array[Vector3]=[]
	var reject_native:=func(_line,from:Vector3,_target:Vector3,_offset:float,_dir:float)->bool:
		origins.append(from);return false
	check.call(not Ride.new().start([crown],Vector3(0,0.2,-5),Vector3(0,4,-8),Callable(),Callable(),reject_native),
		"grind contact: the lower rising band cannot bypass a failed target-aware native capsule proof")
	var permitted:=Ride.new()
	var permit_native:=func(_line,_from:Vector3,_target:Vector3,_offset:float,_dir:float)->bool:return true
	check.call(permitted.start([crown],Vector3(0,0.2,-5),Vector3(0,4,-8),Callable(),Callable(),permit_native)
		and not Ride.new().start([crown],Vector3(0,0.15,-5),Vector3(0,4,-8),Callable(),Callable(),permit_native),
		"grind contact: an explicit successful native proof can use only the existing14cm lower band, never widen it")
	origins.clear()
	var previous:=Vector3(0,0.15,-5)
	var current:=Vector3(0,0.35,-5.1)
	check.call(not Ride.new().start_swept([crown],previous,current,Vector3(0,12,-6),Callable(),Callable(),reject_native)
		and not origins.is_empty(),
		"grind contact: recovered crown crossings retain native target proof for every historical sample")
	var only_current:=true
	for origin: Vector3 in origins:only_current=only_current and origin==current
	check.call(only_current,"grind contact: target-aware swept clearance always starts at the completed actual body position")


static func _swept_current_height(check: Callable) -> void:
	var crown := Line.new("present bounds",PackedVector3Array([Vector3.ZERO,Vector3(0,0,-20)]))
	crown.configure_contact(0.3,0.0,"native.present_bounds")
	var clear := func(_from: Vector3,_to: Vector3) -> bool:return true
	var native_clear := func(_line,_from: Vector3,_to: Vector3,_distance: float,_direction: float) -> bool:return true
	var previous_up := Vector3(0,0.8,-5)
	var outside_up := Vector3(0,1.0,-5.1)
	var inside_up := Vector3(0,0.89,-5.1)
	var upward := Vector3(0,12,-6)
	check.call(not Ride.new().start_swept([crown],previous_up,outside_up,upward,clear)
		and not Ride.new().start_swept([crown],previous_up,outside_up,upward,Callable(),Callable(),native_clear)
		and Ride.new().start_swept([crown],previous_up,inside_up,upward,clear)
		and Ride.new().start_swept([crown],previous_up,inside_up,upward,Callable(),Callable(),native_clear),
		"grind current bounds: an earlier eligible rising sample cannot pull the actual body down from above60cm even with a clear native path")
	var previous_down := Vector3(0,0.2,-5)
	var outside_down := Vector3(0,0.1,-5.1)
	var inside_down := Vector3(0,0.17,-5.1)
	var downward := Vector3(0,-6,-6)
	check.call(not Ride.new().start_swept([crown],previous_down,outside_down,downward,clear)
		and not Ride.new().start_swept([crown],previous_down,outside_down,downward,Callable(),Callable(),native_clear)
		and Ride.new().start_swept([crown],previous_down,inside_down,downward,clear)
		and Ride.new().start_swept([crown],previous_down,inside_down,downward,Callable(),Callable(),native_clear),
		"grind current bounds: an earlier eligible falling sample cannot lift the actual body from below14cm even with a clear native path")


static func _finite_endpoint_clearance(check: Callable) -> void:
	# These are admission contracts with declared clearance answers. The actual
	# transverse-cap/model collision and played Park catch stay in native tests.
	var rail:=Line.new("finite endpoint",PackedVector3Array([Vector3.ZERO,Vector3(0,0,-4)]))
	rail.configure_contact(-.07,.07,"native.cylinder_crown")
	var from:=Vector3(0,.1,-.1)
	var velocity:=Vector3(0,-1,-6)
	var native_calls:Array[Vector3]=[]
	var model_calls:Array[float]=[]
	var native_clear:=func(_line,origin:Vector3,target:Vector3,_offset:float,_direction:float)->bool:
		native_calls.append(origin);return target.is_finite()
	var clear_model:=func(_line,offset:float,_direction:float)->bool:
		model_calls.append(offset);return true
	var nearest:=_endpoint_ride()
	check.call(nearest.start([rail],from,velocity,Callable(),clear_model,native_clear)
		and absf(nearest.distance-.1)<.001 and native_calls.size()==1 and model_calls.size()==1,
		"grind endpoint: an already clear nearest contact remains unchanged and performs no alternate queries")
	var cap_model:=func(_line,offset:float,_direction:float)->bool:
		model_calls.append(offset);return offset>=.4
	native_calls.clear();model_calls.clear()
	var inboard:=_endpoint_ride()
	check.call(inboard.start([rail],from,velocity,Callable(),cap_model,native_clear)
		and inboard.distance>=.4 and inboard.position().distance_to(from)<=Ride.CAPTURE_RADIUS
		and native_calls.size()==2 and model_calls.size()==2,
		"grind endpoint: a blocked nearest cap may use one physically rechecked inboard entry inside the original capture radius")
	var closed_model:=func(_line,offset:float,_direction:float)->bool:
		model_calls.append(offset);return false
	native_calls.clear();model_calls.clear()
	check.call(not _endpoint_ride().start([rail],from,velocity,Callable(),closed_model,native_clear)
		and native_calls.size()==2 and model_calls.size()==2,
		"grind endpoint: a still obstructed actual-model answer rejects after one alternate rather than ignoring the support")
	var blocked_native:=func(_line,origin:Vector3,_target:Vector3,_offset:float,_direction:float)->bool:
		native_calls.append(origin);return false
	native_calls.clear();model_calls.clear()
	check.call(not _endpoint_ride().start([rail],from,velocity,Callable(),cap_model,blocked_native)
		and native_calls.size()==2 and model_calls.is_empty(),
		"grind endpoint: an intervening native wall refuses both points before model admission")
	native_calls.clear();model_calls.clear()
	check.call(not _endpoint_ride().start([rail],Vector3(.8,.1,-.1),velocity,Callable(),cap_model,native_clear)
		and native_calls.size()==1 and model_calls.size()==1,
		"grind endpoint: a valid nearest gap cannot authorize an alternate farther than85cm")
	var graded:=Line.new("steep finite end",PackedVector3Array([Vector3.ZERO,Vector3(0,4,-1)]))
	graded.configure_contact(0.0,0.0,"native.finite_grade")
	native_calls.clear();model_calls.clear()
	var low:=_endpoint_ride();low.capture_model_radius=.7
	check.call(not low.start([graded],Vector3(0,.1,.1),velocity,Callable(),cap_model,native_clear)
		and native_calls.size()==1 and model_calls.size()==1,
		"grind endpoint: an eligible lower endpoint cannot lift the body beyond the original14cm lower band at its inboard target")
	var in_middle:=_endpoint_ride()
	native_calls.clear();model_calls.clear()
	check.call(not in_middle.start([rail],Vector3(0,.1,-2),velocity,Callable(),closed_model,native_clear)
		and native_calls.size()==1 and model_calls.size()==1,
		"grind endpoint: a middle-rail obstruction cannot trigger longitudinal searching")
	native_calls.clear();model_calls.clear()
	check.call(not _endpoint_ride().start([rail],Vector3(0,.1,.1),-velocity,Callable(),cap_model,native_clear)
		and native_calls.is_empty() and model_calls.is_empty(),
		"grind endpoint: outward travel beyond a finite end retains the original refusal without alternate queries")
	var loop:=Line.new("closed endpoint control",PackedVector3Array([Vector3.ZERO,Vector3(0,0,-4),Vector3(4,0,-4),Vector3.ZERO]))
	loop.configure_contact(0.0,0.0,"native.flat_loop")
	var unknown:=Line.new("unknown endpoint control",PackedVector3Array([Vector3.ZERO,Vector3(0,0,-4)]))
	for excluded in [loop,unknown]:
		native_calls.clear();model_calls.clear()
		check.call(not _endpoint_ride().start([excluded],from,velocity,Callable(),closed_model,native_clear)
			and native_calls.size()==1 and model_calls.size()==1,
			"grind endpoint: loops and unverified legacy geometry cannot gain an endpoint exception "+excluded.id)
	var other:=Line.new("closer clear line",PackedVector3Array([Vector3(.3,0,0),Vector3(.3,0,-4)]))
	other.configure_contact(0.0,0.0,"native.other_line")
	var select_model:=func(candidate,offset:float,_direction:float)->bool:return candidate==other or offset>=.4
	for order:Array in [[rail,other],[other,rail]]:
		var ordered:=_endpoint_ride()
		check.call(ordered.start(order,from,velocity,Callable(),select_model,native_clear) and ordered.line==other,
			"grind endpoint: an inboard correction cannot steal selection from a genuinely closer clear line in either enumeration order")
	native_calls.clear();model_calls.clear()
	check.call(not _endpoint_ride().start_swept([rail],Vector3(0,.1,.6),from,velocity,Callable(),cap_model,native_clear),
		"grind endpoint: a swept inboard target retains the previous body's99cm displacement cap")
	var only_present:=true
	for origin:Vector3 in native_calls:only_present=only_present and origin==from
	check.call(only_present and not native_calls.is_empty(),
		"grind endpoint: every swept native callback still starts at the actual completed body origin")
	for invalid:float in [-.1,NAN,INF,Ride.CAPTURE_RADIUS+.01]:
		var bad:=_endpoint_ride();bad.capture_model_radius=invalid
		check.call(not bad.start([rail],from,velocity,Callable(),clear_model,native_clear) and not bad.active,
			"grind endpoint: an invalid actual-model bound refuses without an active ride "+str(invalid))


static func _endpoint_ride() -> RefCounted:
	var ride:=Ride.new()
	ride.capture_model_radius=.42
	return ride


static func _rail(id: String, start: Vector3, end: Vector3) -> RefCounted:
	return Line.new(id, PackedVector3Array([start, end]))
