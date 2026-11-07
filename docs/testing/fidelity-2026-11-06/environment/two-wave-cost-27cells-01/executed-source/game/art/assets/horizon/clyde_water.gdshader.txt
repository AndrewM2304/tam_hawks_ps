shader_type spatial;
render_mode diffuse_lambert;

// One shared opaque surface. River, pond and fountain retain their exact mesh
// and collision. No texture, screen copy, transparency or displacement pass.
uniform vec2 flow_velocity = vec2(0.32, 0.045);
const vec2 WAVE_A = vec2(0.82, 0.33);
const vec2 WAVE_B = vec2(-0.37, 1.47);
varying vec2 water_phase;

void vertex() {
	// Two gentle directions retain calm wave shape at the original phase cost.
	// Affine phase interpolation remains exact over large quads.
	vec2 p = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz - flow_velocity * TIME;
	water_phase = vec2(dot(p, WAVE_A), dot(p, WAVE_B) + TIME * 0.31);
}

void fragment() {
	// Filter both phases by their actual pixel footprint on every bearing.
	// No extra phase/texture is needed for the restrained calm-water response.
	vec2 attenuation = clamp(vec2(1.0) - fwidth(water_phase) / 3.14159265,
		vec2(0.0), vec2(1.0));
	vec2 gradient = cos(water_phase) * attenuation;
	vec2 slope = gradient.x * WAVE_A * 0.021 + gradient.y * WAVE_B * 0.012;
	// World-space normals keep every river bend, fountain and pond coherent
	// independent of their original triangle/tangent orientation.
	NORMAL = normalize((VIEW_MATRIX * vec4(-slope.x, 1.0, -slope.y, 0.0)).xyz);
	ALBEDO = vec3(0.055, 0.110, 0.115);
	ROUGHNESS = 0.48;
	METALLIC = 0.0;
	// Native Godot F0 is0.16*SPECULAR^2:0.35 gives0.0196, near water.
	SPECULAR = 0.35;
}
