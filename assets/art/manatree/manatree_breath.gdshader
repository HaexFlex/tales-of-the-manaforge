shader_type canvas_item;

uniform float sway_amp_px : hint_range(0.0, 4.0) = 1.0;
uniform float sway_hz : hint_range(0.0, 1.0) = 0.25;
uniform float crown_h_px : hint_range(1.0, 4096.0) = 100.0;

void vertex() {
	float w: float = clamp(-VERTEX.y / crown_h_px, 0.0, 1.0);
	VERTEX.x += sin(TIME * sway_hz * TAU) * sway_amp_px * w;
}
