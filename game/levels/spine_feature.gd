extends Node3D
## Two real opposing vertical faces sharing a narrow solid spine deck.
const Quarter = preload("res://game/levels/transition_feature.gd")
var radius := 2.2
var width := 8.0
var cap_width := 0.6
var feature_id := "spine"
var _quarters: Array[Node3D] = []

func _ready() -> void:
	for side: float in [-1.0,1.0]:
		var quarter := Quarter.new()
		quarter.name = "FrontTransition" if side>0 else "BackTransition"
		quarter.feature_id = feature_id+quarter.name
		quarter.radius = radius
		quarter.width = width
		quarter.deck_length = 0.0
		quarter.build_access = false
		quarter.position.z = side*(radius+cap_width*0.5)
		quarter.rotation.y = 0.0 if side>0 else PI
		add_child(quarter)
		_quarters.append(quarter)
	var builder = _quarters[0]
	# Construct in the first quarter's local space so the top remains exactly R.
	builder._box("SolidSpineCore",Vector3(width,radius,cap_width),
		builder.to_local(to_global(Vector3(0,radius*0.5,0))),Quarter._concrete_material())

func get_grind_lines() -> Array:
	var lines: Array = []
	for quarter in _quarters: lines.append_array(quarter.get_grind_lines())
	return lines

func get_feature_definitions() -> Array:
	return [{"id":feature_id,"kind":"spine","floor_y":global_position.y,
		"approach":PackedVector3Array([to_global(Vector3(0,0,radius+cap_width*0.5+10)),to_global(Vector3(0,0,radius+cap_width*0.5))]),
		"landing":PackedVector3Array([to_global(Vector3(0,0,-radius-cap_width*0.5)),to_global(Vector3(0,0,-radius-cap_width*0.5-10))]),
		"lips":PackedVector3Array([to_global(Vector3(0,radius,-cap_width*0.5)),to_global(Vector3(0,radius,cap_width*0.5))])}]
