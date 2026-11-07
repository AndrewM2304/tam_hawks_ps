shader_type spatial;
render_mode diffuse_lambert;

// One shared opaque surface. River, pond and fountain retain their exact mesh
// and collision. No texture, screen copy, transparency or displacement pass.
uniform vec2 flow_velocity = vec2(0.32, 0.045);
const vec2 WAVE_A = vec2(0.82, 0.33);
const vec2 WAVE_B = vec2(-0.37, 1.47);
const vec2 WAVE_C = vec2(3.91, -2.13);
varying vec3 water_phase;

void vertex() {
	// Three incommensurate directions avoid the conspicuous pair of repeated
	// glossy bands. Affine phase interpolation remains exact over large quads.
	vec2 p = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz - flow_velocity * TIME;
	water_phase = vec3(dot(p, WAVE_A), dot(p, WAVE_B) + TIME * 0.31,
		dot(p, WAVE_C) - TIME * 0.19);
}

void fragment() {
	// Filter each phase by its actual pixel footprint on every camera bearing;
	// the short ripple fades before its wavelength becomes a shimmering pixel.
	vec3 attenuation = clamp(vec3(1.0) - fwidth(water_phase) / 3.14159265,
		vec3(0.0), vec3(1.0));
	vec3 gradient = cos(water_phase) * attenuation;
	vec2 slope = gradient.x * WAVE_A * 0.021 + gradient.y * WAVE_B * 0.012
		+ gradient.z * WAVE_C * 0.0035;
	// World-space normals keep every river bend, fountain and pond coherent
	// independent of their original triangle/tangent orientation.
	NORMAL = normalize((VIEW_MATRIX * vec4(-slope.x, 1.0, -slope.y, 0.0)).xyz);
	ALBEDO = vec3(0.055, 0.110, 0.115);
	ROUGHNESS = 0.36;
	METALLIC = 0.0;
	SPECULAR = 0.50;
}
