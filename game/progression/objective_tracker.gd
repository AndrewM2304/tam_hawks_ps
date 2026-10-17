extends Node3D
## Original local objective markers. Definitions come from the level, progress from CareerProgress.
var _markers: Array[Dictionary] = []
var _collected: Dictionary = {}
var _phase := 0.0
var reduced_motion := false

func configure(definitions: Array) -> void:
	for child in get_children():
		child.queue_free()
	_markers.clear()
	_collected.clear()
	for raw in definitions:
		if not raw is Dictionary or not raw.has_all(["id", "kind", "position"]):
			continue
		if not raw.position is Vector3 or not raw.position.is_finite():
			continue
		var entry: Dictionary = raw.duplicate(true)
		entry.radius = clampf(float(entry.get("radius", 1.4)), 0.5, 4.0)
		entry.key = str(entry.kind) + ":" + str(entry.id)
		entry.node = _make_marker(entry)
		_markers.append(entry)

func reset_run() -> void:
	_collected.clear()
	for entry in _markers:
		entry.node.visible = true

func poll(position: Vector3, interact: bool) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if not position.is_finite():
		return events
	for entry in _markers:
		if _collected.has(entry.key):
			continue
		var offset: Vector3 = position - entry.position
		if Vector2(offset.x, offset.z).length() > entry.radius or absf(offset.y) > 2.1:
			continue
		if entry.kind == "interaction" and not interact:
			continue
		_collected[entry.key] = true
		entry.node.visible = false
		events.append({"kind": entry.kind, "id": entry.id})
	return events

func nearby_prompt(position: Vector3) -> String:
	for entry in _markers:
		if entry.kind == "interaction" and not _collected.has(entry.key) and position.distance_to(entry.position) < 5.0:
			return "X / DPAD DOWN  —  CONE DUTY"
	return ""

func _process(delta: float) -> void:
	if reduced_motion:
		return
	_phase += delta
	for i in _markers.size():
		var entry: Dictionary = _markers[i]
		if entry.kind != "district":
			entry.node.position.y = entry.position.y + sin(_phase * 2.0 + i) * 0.12
			var halo: Node3D = entry.node.get_node("Halo")
			halo.rotation.y += delta * 0.6

func _make_marker(entry: Dictionary) -> Node3D:
	var marker := Node3D.new()
	marker.position = entry.position
	marker.name = String(entry.key).replace(":", "_")
	add_child(marker)
	var tint := Color("ffb36b")
	if entry.kind == "district": tint = Color("7ebcb1")
	elif entry.kind == "collectible": tint = Color("bc9be1")
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.emission_enabled = true
	material.emission = tint * 0.3
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var halo := MeshInstance3D.new()
	halo.name = "Halo"
	var ring := TorusMesh.new()
	ring.inner_radius = 0.42
	ring.outer_radius = 0.5
	ring.rings = 16
	ring.ring_segments = 8
	halo.mesh = ring
	halo.material_override = material
	halo.rotation.x = PI / 2.0
	marker.add_child(halo)
	var label := Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 52
	label.pixel_size = 0.009
	label.modulate = Color("fff2d8")
	label.outline_modulate = Color("14252a")
	label.outline_size = 10
	match String(entry.kind):
		"letter": label.text = str(entry.id)
		"market_item": label.text = "+"
		"interaction": label.text = "CONE"
		"collectible": label.text = "REC"
		_: label.text = "•"
	marker.add_child(label)
	return marker
