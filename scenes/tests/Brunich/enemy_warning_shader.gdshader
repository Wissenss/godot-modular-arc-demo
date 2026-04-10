/*
	Warning Flash Shader — EnemySpread body.
	Fast amber pulse + danger diagonal stripes + alert flicker.
*/
shader_type canvas_item;

uniform float pulse_speed : hint_range(1.0, 14.0) = 6.0;
uniform float stripe_density : hint_range(2.0, 16.0) = 5.0;
uniform float stripe_strength : hint_range(0.0, 0.8) = 0.30;
uniform float edge_glow : hint_range(0.0, 0.8) = 0.28;
uniform float flicker_rate : hint_range(0.0, 24.0) = 8.5;

void fragment() {
	float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5;
	float fast_pulse = sin(TIME * pulse_speed * 2.4) * 0.5 + 0.5;

	// Diagonal warning stripes
	float stripe_pattern = fract((UV.x - UV.y) * stripe_density + TIME * 0.35);
	float stripe = step(0.5, stripe_pattern);
	float stripe_alpha = stripe * stripe_strength * (0.55 + pulse * 0.45);

	// Edge highlight — brighter ring at perimeter
	vec2 centered = UV - vec2(0.5);
	float dist_from_center = length(centered) * 2.0;
	float edge_highlight = smoothstep(0.45, 0.90, dist_from_center);
	float edge_effect = edge_glow * edge_highlight * (0.75 + fast_pulse * 0.25);

	// Alert flicker (rare bright pop)
	float flicker = step(0.88, sin(TIME * flicker_rate) * 0.5 + 0.5) * 0.20;

	// Scanline
	float scan = sin(UV.y * 22.0 - TIME * 3.5) * 0.5 + 0.5;
	float scan_effect = scan * 0.06 * pulse;

	vec3 color = COLOR.rgb;
	color += vec3(stripe_alpha * 0.55, stripe_alpha * 0.22, 0.0);
	color += vec3(edge_effect * 0.90, edge_effect * 0.38, 0.0);
	color += vec3(flicker * 0.9, flicker * 0.45, 0.0);
	color += vec3(scan_effect * 0.5, scan_effect * 0.2, 0.0);

	COLOR.rgb = clamp(color, 0.0, 1.7);
}
