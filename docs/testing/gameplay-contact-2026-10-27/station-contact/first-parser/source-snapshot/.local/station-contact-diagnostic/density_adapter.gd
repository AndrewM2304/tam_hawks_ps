extends RefCounted
const Original=preload("res://tests/full_level_density_tests.gd")
const Observer=preload("res://.local/station-contact-diagnostic/observer.gd")
static var observed:=false
static func _camera_clear(game:Node)->bool:
	var result:bool=Original._camera_clear(game)
	if not result and not observed:
		observed=true
		Observer.observe(game)
	return result
