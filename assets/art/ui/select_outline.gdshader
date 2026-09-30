shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(0.78, 0.92, 0.62, 0.55);

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	if (col.a > 0.15) {
		COLOR = col;
	} else {
		vec2 px = TEXTURE_PIXEL_SIZE;
		float edge = 0.0;
		edge = max(edge, texture(TEXTURE, UV + vec2(px.x, 0.0)).a);
		edge = max(edge, texture(TEXTURE, UV - vec2(px.x, 0.0)).a);
		edge = max(edge, texture(TEXTURE, UV + vec2(0.0, px.y)).a);
		edge = max(edge, texture(TEXTURE, UV - vec2(0.0, px.y)).a);
		COLOR = vec4(outline_color.rgb, outline_color.a * step(0.15, edge));
	}
}
