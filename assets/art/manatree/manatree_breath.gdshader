shader_type canvas_item;

uniform float sway_amp_px : hint_range(0.0, 4.0) = 1.0;
uniform float sway_hz : hint_range(0.0, 1.0) = 0.25;
uniform float crown_h_px : hint_range(1.0, 4096.0) = 100.0;
uniform float canopy_base_y : hint_range(-4096.0, 4096.0) = 0.0;

void vertex() {
	float w: float = 0.0;
	if (VERTEX.y < canopy_base_y) {
		w = clamp((canopy_base_y - VERTEX.y) / crown_h_px, 0.0, 1.0);
	}
	VERTEX.x += round(sin(TIME * sway_hz * TAU) * sway_amp_px * w);
}
