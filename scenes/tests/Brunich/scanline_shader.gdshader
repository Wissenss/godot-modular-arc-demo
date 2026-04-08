/*
	Scanline Shader — Regulated AI visual effect
	Applies moving horizontal scanlines to suggest a "monitored/controlled" system.
*/

shader_type canvas_item;

uniform float scan_speed : hint_range(0.5, 10.0) = 2.5;
uniform float line_density : hint_range(1.0, 30.0) = 10.0;
uniform float line_brightness : hint_range(0.0, 1.0) = 0.3;
uniform float pulse_speed : hint_range(0.0, 5.0) = 1.2;

void fragment() {
	float scan = fract(UV.y * line_density - TIME * scan_speed);
	float line = smoothstep(0.0, 0.1, scan) * smoothstep(0.3, 0.1, scan);

	float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5;

	COLOR.rgb += vec3(line * line_brightness * (0.7 + pulse * 0.3));
	COLOR.rgb = clamp(COLOR.rgb, 0.0, 1.5);
}
