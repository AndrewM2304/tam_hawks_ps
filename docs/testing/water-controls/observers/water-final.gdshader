shader_type spatial;
render_mode diffuse_lambert;

// One opaque surface. Flow and ripples use no textures or screen-copy passes.
uniform vec2 flow_velocity = vec2(0.65, 0.09);
const vec2 WAVE_A = vec2(2.15, 0.72);
const vec2 WAVE_B = vec2(-0.48, 1.65);
varying vec2 water_phase;

void vertex() {
	// Both phases are affine in world position: interpolating them is exact.
	// Do flow/dot products per vertex, rather than at every river pixel.
	vec2 p = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz - flow_velocity * TIME;
	water_phase = vec2(dot(p, WAVE_A), dot(p, WAVE_B) + TIME * 0.7);
}

void fragment() {
	// Fade wavelengths smaller than a pixel instead of letting distant ripples
	// shimmer. Measure actual screen-space phase frequency on every bearing.
	vec2 attenuation = clamp(vec2(1.0) - fwidth(water_phase) / 3.14159265,
		vec2(0.0), vec2(1.0));
	vec2 gradient = cos(water_phase) * attenuation;
	vec2 slope = gradient.x * WAVE_A * 0.035 + gradient.y * WAVE_B * 0.03;
	// Analytic world-space normal: central water and both bent strips share it,
	// independent of their triangle/tangent orientation. Banks stay fixed.
	NORMAL = normalize((VIEW_MATRIX * vec4(-slope.x, 1.0, -slope.y, 0.0)).xyz);
	// Let moving normals/native reflections describe water, rather than
	// painting light/dark stripes into the river's blue-green depth colour.
	ALBEDO = vec3(0.10, 0.205, 0.225);
	ROUGHNESS = 0.56;
	METALLIC = 0.0;
	SPECULAR = 0.35;
}
