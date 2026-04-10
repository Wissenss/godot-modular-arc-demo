/*
	Precision Grid Shader — EnemyPierce body.
	Cold targeting grid + scanning sweep line + crosshair center.
*/
shader_type canvas_item;

uniform float grid_density : hint_range(4.0, 40.0) = 14.0;
uniform float grid_strength : hint_range(0.0, 0.5) = 0.13;
uniform float scan_speed : hint_range(0.0, 5.0) = 0.75;
uniform float crosshair_alpha : hint_range(0.0, 0.7) = 0.24;
uniform float pulse_speed : hint_range(0.1, 4.0) = 0.85;
uniform float shimmer_strength : hint_range(0.0, 0.4) = 0.18;

void fragment() {
	float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5;
	float slow_pulse = sin(TIME * pulse_speed * 0.4) * 0.5 + 0.5;

	// Tight orthogonal grid
	float grid_x = step(1.0 - grid_strength, fract(UV.x * grid_density));
	float grid_y = step(1.0 - grid_strength, fract(UV.y * grid_density));
	float grid = max(grid_x, grid_y) * 0.45 * (0.7 + slow_pulse * 0.3);

	// Targeting sweep — horizontal scan line moving top to bottom
	float scan_pos = fract(TIME * scan_speed);
	float scan_dist = abs(UV.y - scan_pos);
	float scan_line = smoothstep(0.06, 0.002, scan_dist) * 0.32 * (0.7 + pulse * 0.3);

	// Cross-hair at center — thin + and X overlay
	float cx = abs(UV.x - 0.5);
	float cy = abs(UV.y - 0.5);
	float ch_h = smoothstep(0.022, 0.003, cy) * smoothstep(0.12, 0.08, cx);
	float ch_v = smoothstep(0.022, 0.003, cx) * smoothstep(0.12, 0.08, cy);
	float crosshair = max(ch_h, ch_v) * crosshair_alpha * (0.65 + pulse * 0.35);

	// Cold edge shimmer
	vec2 centered = UV - vec2(0.5);
	float dist = length(centered) * 2.0;
	float shimmer = smoothstep(0.55, 1.0, dist) * shimmer_strength * (0.55 + pulse * 0.45);

	vec3 color = COLOR.rgb;
	color += vec3(grid * 0.55, grid * 0.65, grid);
	color += vec3(scan_line * 0.50, scan_line * 0.60, scan_line);
	color += vec3(crosshair * 0.55, crosshair * 0.65, crosshair);
	color += vec3(shimmer * 0.45, shimmer * 0.55, shimmer);

	COLOR.rgb = clamp(color, 0.0, 1.6);
}
