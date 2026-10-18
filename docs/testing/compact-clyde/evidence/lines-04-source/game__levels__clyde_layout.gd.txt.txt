extends RefCounted
## One authored placement contract for the compact river pocket (metres).
## Feature dimensions stay native; only whole groups and their joins move.
const NORTH_QUAY := Rect2(-85,55,170,23)
const SOUTH_QUAY := Rect2(-39,116,115,14)
const YARD_GROUND := Rect2(-39,130,115,13)
const SAFE_X := -25.0
const TRANSFER_X := 20.0
const YARD_SHIFT := Vector3(-15,0,0)
const HALF_SHIFT := Vector3(-20,0,0)
const HALF_CENTRE := Vector3(-42,2,60.5)
const QUARTER_TOE := Vector3(-15,2,62)
const QUARTER_YAW := PI * 0.5
const TERRACE_BLOCKS := [Vector2(18.5,115)]


static func quay_edge_spans(north: bool) -> Array[Vector2]:
	var bounds := NORTH_QUAY if north else SOUTH_QUAY
	return [Vector2(bounds.position.x+1.1,SAFE_X-4.4),
		Vector2(SAFE_X+4.4,TRANSFER_X-2.9),Vector2(TRANSFER_X+2.9,bounds.end.x-1.1)]
