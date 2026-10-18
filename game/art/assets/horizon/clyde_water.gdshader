shader_type spatial;
render_mode diffuse_lambert;

// One opaque surface. Flow and ripples use no textures or screen-copy passes.
uniform vec2 flow_velocity = vec2(0.65, 0.09);
varying vec2 water_position;

void vertex() {
	water_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	vec2 p = water_position - flow_velocity * TIME;
	vec2 a = vec2(2.15, 0.72);
	vec2 b = vec2(-0.48, 1.65);
	vec2 phase = vec2(dot(p, a), dot(p, b) + TIME * 0.7);
	// Fade wavelengths smaller than a pixel instead of letting distant ripples
	// shimmer. Derivatives depend on world scale, not camera-specific thresholds.
	vec2 span = fwidth(p);
	vec2 attenuation = clamp(vec2(1.0) - vec2(dot(abs(a), span),
		dot(abs(b), span)) / 3.14159265, vec2(0.0), vec2(1.0));
	vec2 gradient = cos(phase) * attenuation;
	vec2 slope = gradient.x * a * 0.035 + gradient.y * b * 0.03;
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
