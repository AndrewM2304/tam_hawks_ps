extends RefCounted
const Original = preload("res://tests/full_level_density_tests.gd")
const Observer = preload("res://.local/contact-camera-diagnostic/camera_shape_witness.gd")
static var observed := false

static func _camera_clear(game: Node) -> bool:
	var original_result: bool=Original._camera_clear(game)
	if not original_result and not observed:
		observed=true
		Observer.observe(game,"pt24-20-first-strict-camera-failure")
	return original_result
