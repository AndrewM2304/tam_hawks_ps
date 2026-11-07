shader_type spatial;
render_mode diffuse_burley;

// Original opaque room-box mapping with native sky specular. The existing
// facade pane geometry and batch count are unchanged; no screen-copy pass,
// texture, dynamic light, alpha sorting or per-frame CPU work is introduced.
uniform vec3 glass_tint : source_color = vec3(0.22, 0.29, 0.31);
uniform float room_light : hint_range(0.0, 0.3) = 0.0;
varying vec3 pane_center;

float hash31(vec3 p) {
	return fract(sin(dot(p, vec3(12.9898, 78.233, 39.425))) * 43758.5453);
}

void vertex() {
	pane_center = MODEL_MATRIX[3].xyz;
}

void fragment() {
	// BoxMesh UVs occupy an atlas. On the front pane the central quarter is the
	// full opening; fract restores pane-local coordinates without new vertices.
	vec2 uv = fract(UV * vec2(3.0, 2.0));
	vec3 toward_camera = vec3(dot(VIEW, TANGENT), dot(VIEW, BINORMAL), dot(VIEW, NORMAL));
	vec3 ray = normalize(vec3(-toward_camera.xy * 0.60, -max(abs(toward_camera.z), 0.08)));
	vec3 origin = vec3(uv * 2.0 - 1.0, 1.0);
	vec3 far_wall = mix(vec3(-1.0), vec3(1.0), step(vec3(0.0), ray));
	vec3 safe_ray = far_wall * max(abs(ray), vec3(0.0001));
	vec3 intervals = (far_wall - origin) / safe_ray;
	float travel = min(intervals.x, min(intervals.y, intervals.z));
	vec3 room = origin + ray * max(travel, 0.0);
	float variant = hash31(floor(pane_center * 0.5));
	vec3 plaster = mix(vec3(0.20, 0.19, 0.16), vec3(0.31, 0.30, 0.26), variant);
	float back = step(abs(room.z + 1.0), 0.004);
	float floor_wall = step(abs(room.y + 1.0), 0.004);
	vec3 interior = plaster * mix(0.58, 0.85, back);
	interior = mix(interior, vec3(0.095, 0.076, 0.054), floor_wall);
	// A lower furniture silhouette and open curtains make rooms differ without
	// emitting uniformly bright rectangles across an otherwise daylight street.
	float furniture = back * step(room.y, -0.32) * step(abs(room.x + (variant - 0.5) * 0.6), 0.62);
	interior = mix(interior, vec3(0.075, 0.067, 0.055), furniture * 0.65);
	float curtain_width = mix(0.0, 0.22, step(0.45, variant));
	float curtain = step(1.0 - curtain_width, abs(origin.x));
	float folds = 0.84 + 0.16 * sin(origin.x * 55.0);
	interior = mix(interior, plaster * folds, curtain * 0.72);
	float facing = clamp(abs(toward_camera.z), 0.0, 1.0);
	float fresnel = pow(1.0 - facing, 5.0);
	ALBEDO = mix(interior * 0.65, glass_tint, 0.18 + fresnel * 0.45);
	ROUGHNESS = 0.13 + variant * 0.08;
	SPECULAR = 0.5;
	METALLIC = 0.0;
	EMISSION = interior * room_light;
}
