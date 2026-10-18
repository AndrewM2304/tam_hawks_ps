shader_type spatial;

// One opaque surface. Flow and ripples use no textures or screen-copy passes.
uniform vec2 flow_velocity = vec2(0.65, 0.09);
varying vec3 water_position;

void vertex() {
	water_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = water_position.xz - flow_velocity * TIME;
	vec2 a = vec2(1.15, 0.72);
	vec2 b = vec2(-0.60, 1.85);
	vec2 c = vec2(0.18, 0.11);
	vec3 phase = vec3(dot(p, a), dot(p, b) + TIME * 0.7, dot(p, c) - TIME * 0.35);
	// Fade wavelengths smaller than a pixel instead of letting distant ripples
	// shimmer. Derivatives depend on world scale, not camera-specific thresholds.
	vec2 span = fwidth(p);
	vec3 attenuation = clamp(vec3(1.0) - vec3(dot(abs(a), span),
		dot(abs(b), span), dot(abs(c), span)) / 3.14159265, vec3(0.0), vec3(1.0));
	vec3 waves = sin(phase) * attenuation;
	vec3 gradient = cos(phase) * attenuation;
	vec2 slope = gradient.x * a * 0.11 + gradient.y * b * 0.055 + gradient.z * c * 0.33;
	// Analytic world-space normal: central water and both bent strips share it,
	// independent of their triangle/tangent orientation. Banks stay fixed.
	NORMAL = normalize((VIEW_MATRIX * vec4(-slope.x, 1.0, -slope.y, 0.0)).xyz);
	float tone = clamp(0.5 + dot(waves, vec3(0.18, 0.09, 0.22)), 0.0, 1.0);
	vec3 river_colour = mix(vec3(0.038, 0.105, 0.11), vec3(0.10, 0.195, 0.20), tone);
	float edge = clamp(1.0 - dot(NORMAL, VIEW), 0.0, 1.0);
	float sky_weight = edge * edge * (3.0 - 2.0 * edge);
	ALBEDO = mix(river_colour, vec3(0.24, 0.34, 0.35), sky_weight * 0.42);
	ROUGHNESS = 0.46;
	METALLIC = 0.0;
	SPECULAR = 0.5;
}
