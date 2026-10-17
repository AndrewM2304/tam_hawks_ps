extends RefCounted
## Visual budgets only. Collision, simulation, controls and camera framing stay live.

const IDS: Array[String] = ["performance", "balanced", "high"]
const LABELS := {"performance":"Performance", "balanced":"Balanced", "high":"High"}
const PROFILES := {
	"performance":{"scale":0.75,"far":150.0,"shadows":30.0,"msaa":Viewport.MSAA_DISABLED},
	"balanced":{"scale":1.0,"far":220.0,"shadows":45.0,"msaa":Viewport.MSAA_2X},
	"high":{"scale":1.0,"far":220.0,"shadows":75.0,"msaa":Viewport.MSAA_2X},
}
# Enabled only after the independent same-world occlusion comparison accepts it.
const SOLID_WALL_OCCLUSION := false


static func normalized(value: Variant) -> String:
	return str(value) if value is String and IDS.has(value) else "balanced"


static func profile(value: Variant) -> Dictionary:
	return PROFILES[normalized(value)].duplicate()


static func apply(viewport: Viewport, skater: Node3D, world: Node3D, value: Variant) -> String:
	var id := normalized(value)
	var budget := profile(id)
	viewport.scaling_3d_scale = budget.scale
	viewport.msaa_3d = budget.msaa
	viewport.use_occlusion_culling = SOLID_WALL_OCCLUSION
	var camera := skater.get_node_or_null("ChaseCamera") as Camera3D
	if camera != null: camera.far = budget.far
	var sun := world.get_node_or_null("LateAfternoonSun") as DirectionalLight3D
	if sun != null: sun.directional_shadow_max_distance = budget.shadows
	return id
