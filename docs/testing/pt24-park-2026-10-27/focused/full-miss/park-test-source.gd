extends RefCounted
## The flagship's protected whole-run miss, independently from combo admission.
## The staged summit/grind combo remains rejected in the accompanying evidence.
const Driver = preload("res://tests/pt24_flagship_runs_tests.gd")
const Routes = preload("res://tests/world_routes_tests.gd")
const PATH := [Vector3(-157,0,-174),Vector3(-153,0,-171),Vector3(-149,0,-168),
	Vector3(-146.4,0,-164),Vector3(-145.2,0,-158),Vector3(-144.6,0,-152),
	Vector3(-144.6,0,-146),Vector3(-144.6,0,-140),Vector3(-144.6,0,-134),
	Vector3(-144.6,0,-128),Vector3(-144,0,-125),Vector3(-138,0,-125),
	Vector3(-126,0,-124.45),Vector3(-110,0,-124),Vector3(-94,0,-123.5),
	Vector3(-78,0,-123),Vector3(-62,0,-122.6),Vector3(-44,0,-122)]

static func run(tree: SceneTree,game: Node,check: Callable,observer: Callable=Callable()) -> void:
	var old_spawn: Vector3=game.skater.spawn_position
	var old_mode: bool=game.free_skate_mode
	await Driver._frames(tree,2)
	var supported := true
	var clear := true
	var maximum_error := 0.0
	var samples := 0
	# Fixed route, independent of authored navigation/feature metadata.
	# Short ground-fitted segments preserve the real convex graded bends.
	for segment: int in PATH.size()-1:
		var first: Vector3=PATH[segment]
		var last: Vector3=PATH[segment+1]
		var side:=Vector3((last-first).z,0,-(last-first).x).normalized()*.4
		var count:=maxi(2,ceili(first.distance_to(last)))
		var previous:=Vector3.INF
		for step: int in count+1:
			var center:=first.lerp(last,float(step)/count)
			center.y=game.world.get_ground_height(center)
			if previous.is_finite():
				clear=clear and Routes._clear_sweep(game.world,previous,center) and Routes._clear_sweep(game.world,center,previous)
			previous=center
			for lateral: float in [-1,0,1]:
				var point:=center+side*lateral
				point.y=game.world.get_ground_height(point)
				var hit: Dictionary=game.world.get_world_3d().direct_space_state.intersect_ray(
					PhysicsRayQueryParameters3D.create(point+Vector3.UP*.1,point-Vector3.UP*.1,1))
				var error: float=INF if hit.is_empty() else absf(hit.position.y-point.y)
				maximum_error=maxf(maximum_error,error)
				supported=supported and is_finite(point.y) and error<.002 and not hit.is_empty() and hit.normal.y>cos(deg_to_rad(56))
				samples+=1
	check.call(supported and clear,
		"C04-L06 miss: fixed full-width summit/east-descent/civic-return samples agree with native ground and two-way capsule clearance")
	print("PARK_FLAGSHIP_MISS_SUPPORT samples=",samples," maximum_height_error_m=",maximum_error," clear=",clear)
	await Driver._miss_return(tree,game,check,"summit_to_civic",Vector3(-157,17.08,-174),-2.25,
		PackedVector3Array([Vector3(-146,0,-164),Vector3(-144.6,0,-146),Vector3(-144.6,6,-126),
			Vector3(-134,6,-125),Vector3(-110,6,-125),Vector3(-80,6,-124),Vector3(-44,6,-122)]),observer)
	await Driver._miss_return(tree,game,check,"civic_to_summit",Vector3(-44,6.08,-122),PI*.5,
		PackedVector3Array([Vector3(-80,6,-124),Vector3(-110,6,-125),Vector3(-134,6,-125),
			Vector3(-144.6,6,-126),Vector3(-144.6,0,-146),Vector3(-146,0,-164),Vector3(-157,17,-174)]),observer)
	Driver._release()
	game.skater.spawn_position=old_spawn
	game.start_mode(old_mode)
