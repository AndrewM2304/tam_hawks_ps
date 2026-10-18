shader_type spatial;

// One opaque surface. Flow and ripples use no textures or screen-copy passes.
uniform vec2 flow_velocity = vec2(0.65, 0.09);
varying vec2 water_position;

void vertex() {
	water_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	vec2 p = water_position - flow_velocity * TIME;
	vec2 a = vec2(1.15, 0.72);
	vec2 b = vec2(-0.28, 0.65);
	vec2 phase = vec2(dot(p, a), dot(p, b) + TIME * 0.7);
	// Fade wavelengths smaller than a pixel instead of letting distant ripples
	// shimmer. Derivatives depend on world scale, not camera-specific thresholds.
	vec2 span = fwidth(p);
	vec2 attenuation = clamp(vec2(1.0) - vec2(dot(abs(a), span),
		dot(abs(b), span)) / 3.14159265, vec2(0.0), vec2(1.0));
	vec2 waves = sin(phase) * attenuation;
	vec2 gradient = cos(phase) * attenuation;
	vec2 slope = gradient.x * a * 0.11 + gradient.y * b * 0.12;
	// Analytic world-space normal: central water and both bent strips share it,
	// independent of their triangle/tangent orientation. Banks stay fixed.
	NORMAL = normalize((VIEW_MATRIX * vec4(-slope.x, 1.0, -slope.y, 0.0)).xyz);
	float tone = clamp(0.5 + dot(waves, vec2(0.08, 0.05)), 0.0, 1.0);
	// Native PBR already supplies grazing reflections. Avoid duplicating that
	// term in ALBEDO or washing out the river's blue-green depth colour.
	ALBEDO = mix(vec3(0.075, 0.17, 0.19), vec3(0.13, 0.245, 0.26), tone);
	ROUGHNESS = 0.46;
	METALLIC = 0.0;
	SPECULAR = 0.5;
}
