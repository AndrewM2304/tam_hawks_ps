extends RefCounted
const Original=preload("res://tests/full_level_density_tests.gd")
const Observer=preload("res://.local/clyde-civic-contact/observer.gd")
static var observed:=false
static var enabled:=false
static var tag:="clyde-civic-first-false"
static func _camera_clear(game:Node)->bool:
	var result:bool=Original._camera_clear(game)
	if enabled and not result and not observed:
		observed=true
		print("CONTACT_SCENARIO ",tag)
		Observer.observe(game)
	return result

static func _manual_crossing(tree:SceneTree,game:Node,feature:Dictionary,check:Callable,observer:Callable)->void:
	await Original._manual_crossing(tree,game,feature,check,observer)
