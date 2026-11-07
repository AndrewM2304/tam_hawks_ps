shader_type sky;

// Original distant scenery; one native lookup without per-pixel angle conversion.
uniform samplerCube context_sky : source_color, filter_linear;

void sky() {
	COLOR = textureLod(context_sky, EYEDIR, 0.0).rgb;
}
