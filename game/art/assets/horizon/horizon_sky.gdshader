shader_type sky;

// Original distant scenery; one native lookup without per-pixel angle conversion.
uniform samplerCube context_sky : source_color, filter_linear_mipmap;

void sky() {
	COLOR = texture(context_sky, EYEDIR).rgb;
}
