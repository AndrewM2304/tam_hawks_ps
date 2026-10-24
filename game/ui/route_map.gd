extends Control
## Original route diagram from the same world points used to author skating lines.

const LABELS := {
	"royal_exchange": "EXCHANGE", "george_square": "GEORGE SQUARE",
	"central_station": "CENTRAL", "barras": "BARRAS",
	"clyde": "RIVER CLYDE", "clyde_quay": "RIVER CLYDE",
	"kelvingrove": "KELVINGROVE", "kelvingrove_park": "KELVINGROVE",
}
var checkpoints: Dictionary = {}
var routes: Array = []
var rider := Vector3.ZERO
var heading := 0.0
var _bounds := Rect2(-145, -145, 290, 280)


func configure(points: Dictionary, lines: Array, at: Vector3, angle: float) -> void:
	checkpoints = points.duplicate(true)
	routes = lines.duplicate(true)
	rider = at
	heading = angle
	_bounds = Rect2(Vector2(at.x, at.z), Vector2.ONE)
	for point: Vector3 in checkpoints.values():
		_bounds = _bounds.expand(Vector2(point.x, point.z))
	for route: Dictionary in routes:
		for point: Vector3 in route.get("points", []):
			_bounds = _bounds.expand(Vector2(point.x, point.z))
		if route.get("map_marker") is Vector3:
			var marker: Vector3 = route.map_marker
			if marker.is_finite(): _bounds = _bounds.expand(Vector2(marker.x, marker.z))
	_bounds = _bounds.grow(18.0)
	queue_redraw()


func _ready() -> void:
	resized.connect(queue_redraw)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _map(at: Vector3) -> Vector2:
	var available := size - Vector2(90, 54)
	var scale_factor := minf(available.x / _bounds.size.x, available.y / _bounds.size.y)
	return (Vector2(at.x, at.z) - _bounds.get_center()) * scale_factor + size * 0.5


func _draw() -> void:
	draw_style_box(_background(), Rect2(Vector2.ZERO, size))
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(18, 24), "N ↑     GLASGOW / SKATE ROUTES", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("aebfbb"))
	for route: Dictionary in routes:
		var points: PackedVector3Array = PackedVector3Array(route.get("points", []))
		var jump: bool = route.get("requires_jump", false)
		for i in range(1, points.size()):
			var height_tint := clampf((points[i].y + points[i - 1].y) / 24.0, 0.0, 1.0)
			var tint := Color("97b0ac").lerp(Color("d8ef96"), height_tint)
			if jump:
				draw_dashed_line(_map(points[i - 1]), _map(points[i]), Color("ffb27d"), 3.0, 5.0)
			else:
				draw_line(_map(points[i - 1]), _map(points[i]), tint, 3.0, true)
	for id: String in checkpoints:
		var point: Vector3 = checkpoints[id]
		var at := _map(point)
		draw_circle(at, 5.0, Color("d8ef96"))
		var label: String = LABELS.get(id, id.replace("_", " ").to_upper())
		var label_width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		var label_y := at.y + 22.0 if id in ["central_station", "clyde", "clyde_quay"] else at.y - 12.0
		var text_at := Vector2(clampf(at.x - label_width * 0.5, 12, maxf(12, size.x - label_width - 12)), label_y)
		draw_string_outline(font, text_at, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 4, Color("14272c"))
		draw_string(font, text_at, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("f2f4e9"))
	for marker: Dictionary in feature_markers():
		var at := _map(marker.position)
		draw_colored_polygon(PackedVector2Array([at+Vector2(0,-7),at+Vector2(7,0),
			at+Vector2(0,7),at+Vector2(-7,0)]),Color("ffb27d"))
		var label: String = marker.label
		var width := font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x
		var label_y := at.y-13.0 if at.y > 70.0 else at.y+23.0
		var text_at := Vector2(clampf(at.x-width*0.5,12,maxf(12,size.x-width-12)),
			clampf(label_y,46,size.y-36))
		draw_string_outline(font,text_at,label,HORIZONTAL_ALIGNMENT_LEFT,-1,12,4,Color("14272c"))
		draw_string(font,text_at,label,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("ffb27d"))
	var position_2d := _map(rider)
	var direction := Vector2(-sin(heading), -cos(heading))
	var side := direction.orthogonal()
	draw_circle(position_2d, 11.0, Color("14272c"))
	draw_colored_polygon(PackedVector2Array([position_2d + direction * 10.0,
		position_2d - direction * 6.0 + side * 6.0, position_2d - direction * 6.0 - side * 6.0]), Color("ffb27d"))
	var legend := "▲ YOU     ◆ SKATEPARK ENTRY     BRIGHTER = HIGHER" if not feature_markers().is_empty() else "▲ YOU     BRIGHTER ROUTES CLIMB HIGHER"
	draw_string(font, Vector2(18, size.y - 14), legend, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("aebfbb"))


func feature_markers() -> Array[Dictionary]:
	# The same authored route supplies navigation and its entrance marker. A
	# facility marker is separate from district/save checkpoints.
	var result: Array[Dictionary] = []
	var seen: Dictionary = {}
	for route: Dictionary in routes:
		if not route.get("enabled",true): continue
		if str(route.get("map_kind","")) != "skatepark" or not route.get("map_marker") is Vector3: continue
		var point: Vector3 = route.map_marker
		var label := str(route.get("map_label","")).strip_edges()
		var id := str(route.get("id",""))
		if not point.is_finite() or label.is_empty() or seen.has(id): continue
		seen[id] = true
		result.append({"id":id,"position":point,"label":label})
	return result


func _background() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1c3338")
	style.set_corner_radius_all(10)
	return style
