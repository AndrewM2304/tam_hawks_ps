extends RefCounted
## Startup-only broad phase. Capture still uses the exact curve, direction and
## real-body clearance rules. Expanded segment cells include the swept window.

const Line = preload("res://game/tricks/grind_line.gd")
const CELL_SIZE := 8.0
const MARGIN := 1.90 # 0.85m capture + at most 1m completed physics sweep.
var _cells: Dictionary = {}
var _empty: Array = []


func rebuild(lines: Array) -> void:
	_cells.clear()
	for line in lines:
		if not line is Line or not line.is_valid: continue
		for i in range(line.points.size() - 1):
			var first: Vector3 = line.points[i].min(line.points[i + 1]) - Vector3.ONE * MARGIN
			var last: Vector3 = line.points[i].max(line.points[i + 1]) + Vector3.ONE * MARGIN
			var low := _key(first)
			var high := _key(last)
			for x in range(low.x, high.x + 1):
				for y in range(low.y, high.y + 1):
					for z in range(low.z, high.z + 1):
						var key := Vector3i(x, y, z)
						if not _cells.has(key): _cells[key] = []
						if not _cells[key].has(line): _cells[key].append(line)


func nearby(point: Vector3) -> Array:
	if not point.is_finite(): return _empty
	return _cells.get(_key(point), _empty)


func _key(point: Vector3) -> Vector3i:
	return Vector3i(floori(point.x / CELL_SIZE), floori(point.y / CELL_SIZE), floori(point.z / CELL_SIZE))
