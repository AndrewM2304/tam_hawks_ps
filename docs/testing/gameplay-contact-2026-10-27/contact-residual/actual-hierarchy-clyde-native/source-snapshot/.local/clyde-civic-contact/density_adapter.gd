extends RefCounted
const Original=preload("res://tests/full_level_density_tests.gd")
const Observer=preload("res://.local/clyde-civic-contact/observer.gd")
static var observed:=false
static var observed_phases:Dictionary={}
static var enabled:=false
static var tag:="clyde-civic-first-false"
static func _camera_clear(game:Node)->bool:
	var result:bool=Original._camera_clear(game)
	# Print at most the initial failure and the two later native return-lip
	# phases. This observer does not change the predicate, inputs or timing.
	if enabled and not result and observed_phases.size()<3:
		var at:Vector3=game.skater.global_position
		var phase:String="first-false"
		if absf(at.x+11.2)<0.75 and absf(at.z-130.4)<0.75:
			phase="return-lip-low" if at.y<2.0 else "return-lip-high"
		if not observed_phases.has(phase):
			observed_phases[phase]=true
			observed=true
			print("CONTACT_SCENARIO ",tag," phase=",phase)
			Observer.observe(game,phase)
	return result

static func _manual_crossing(tree:SceneTree,game:Node,feature:Dictionary,check:Callable,observer:Callable)->void:
	await Original._manual_crossing(tree,game,feature,check,observer)
