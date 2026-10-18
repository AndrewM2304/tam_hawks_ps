shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, specular_disabled;

// Match the standard material's sRGB vertex-colour convention on every backend.
// No albedo texture/default-white lookup or UV work is needed for these faces.
void vertex() {
	if (!OUTPUT_IS_SRGB) {
		vec3 colour = COLOR.rgb;
		COLOR.rgb = mix(pow((colour + vec3(0.055)) / 1.055, vec3(2.4)),
			colour / 12.92, lessThan(colour, vec3(0.04045)));
	}
}

void fragment() {
	ALBEDO = COLOR.rgb;
}
