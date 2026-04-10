/*
	Energy Core Shader — color-agnostic projectile glow.
	Works on any Polygon2D regardless of UV mapping. Amplifies the base
	COLOR so the effect always matches the enemy tint.
*/
shader_type canvas_item;

uniform float pulse_speed : hint_range(1.0, 30.0) = 8.0;
uniform float glow_intensity : hint_range(0.0, 2.5) = 1.10;
uniform float shimmer_rate : hint_range(1.0, 40.0) = 18.0;
uniform float shimmer_strength : hint_range(0.0, 1.2) = 0.45;
uniform float flare_cycle : hint_range(0.5, 10.0) = 3.2;
uniform float flare_strength : hint_range(0.0, 1.5) = 0.55;

void fragment() {
	float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5;
	float shimmer = sin(TIME * shimmer_rate + UV.x * 11.0 + UV.y * 7.0) * 0.5 + 0.5;
	float flare = pow(sin(TIME * flare_cycle) * 0.5 + 0.5, 3.0);

	vec3 color = COLOR.rgb;
	color *= (1.0 + glow_intensity * pulse * 0.7);
	color += color * shimmer * shimmer_strength;
	color += color * flare * flare_strength;

	COLOR.rgb = clamp(color, 0.0, 2.6);
}
