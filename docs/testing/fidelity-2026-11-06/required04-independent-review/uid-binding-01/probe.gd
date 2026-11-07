extends SceneTree
var passed := 0
var failed := 0
func _initialize() -> void:
	for path: String in ["game/tricks/native_gap_finish.gd.uid", "tests/cable_gap_input_driver.gd.uid", "tests/native_gap_finish_capture_controls.gd.uid", "tests/native_gap_finish_contract_tests.gd.uid", "tests/native_gap_finish_integration_tests.gd.uid"]:
		var text: String = FileAccess.get_file_as_string("res://" + path).strip_edges()
		var id: int = ResourceUID.text_to_id(text)
		var resource: String = "res://" + path.trim_suffix(".uid")
		_check(id != ResourceUID.INVALID_ID and ResourceUID.id_to_text(id) == text, "canonical UID " + path)
		_check(ResourceLoader.get_resource_uid(resource) == id, "native source UID binding " + resource)
		_check(ResourceUID.has_id(id) and ResourceUID.get_id_path(id) == resource, "native UID registry path " + resource)
	print("UID RESULT: ", passed, " passed, ", failed, " failed")
	quit(1 if failed else 0)
func _check(ok: bool, label: String) -> void:
	if ok: passed += 1; print("PASS: ", label)
	else: failed += 1; push_error(label)
