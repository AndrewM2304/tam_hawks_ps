extends Node3D
## Connected original quarters, a real flat bottom and supported side roll-ins.
const Quarter = preload("res://game/levels/transition_feature.gd")
var radius := 2.2
var width := 8.0
var flat_length := 6.0
var deck_length := 2.5
var feature_id := "halfpipe"
## An installed concourse may own the flush flat's visible paving. Keep native
## support, but do not draw a second coplanar floor over that existing surface.
var build_flat_visual := true
var _quarters: Array[Node3D] = []

func _ready() -> void:
	for side: float in [-1.0,1.0]:
		var quarter := Quarter.new()
		quarter.name = "NorthTransition" if side<0 else "SouthTransition"
		quarter.feature_id = feature_id+quarter.name
		quarter.radius = radius
		quarter.width = width
		quarter.deck_length = deck_length
		quarter.position.z = side*flat_length*0.5
		quarter.rotation.y = 0.0 if side<0 else PI
		add_child(quarter)
		_quarters.append(quarter)
	var builder = _quarters[0]
	var flat: StaticBody3D = builder._box("ConnectedFlatBottom",Vector3(width,0.24,flat_length),
		Vector3(0,-0.12,flat_length*0.5),Quarter._concrete_material())
	if not build_flat_visual:
		for visual: MeshInstance3D in flat.find_children("*", "MeshInstance3D", true, false):
			visual.free()

func get_grind_lines() -> Array:
	var lines: Array = []
	for quarter in _quarters: lines.append_array(quarter.get_grind_lines())
	return lines

func get_feature_definitions() -> Array:
	return [{"id":feature_id,"kind":"halfpipe","floor_y":global_position.y,
		"approach":PackedVector3Array([to_global(Vector3(width*0.5+4,0,0)),global_position]),
		"lips":PackedVector3Array([to_global(Vector3(0,radius,-flat_length*0.5-radius)),to_global(Vector3(0,radius,flat_length*0.5+radius))])}]
