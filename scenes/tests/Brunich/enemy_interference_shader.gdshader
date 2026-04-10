/*
	Interference Wave Shader — EnemySlowbeam body.
	Two overlapping sine waves creating interference + dampening rings.
*/
shader_type canvas_item;

uniform float wave_speed : hint_range(0.3, 10.0) = 2.6;
uniform float wave_density : hint_range(2.0, 22.0) = 6.5;
uniform float interference_strength : hint_range(0.0, 0.6) = 0.22;
uniform float pulse_speed : hint_range(0.1, 5.0) = 1.3;
uniform float ring_count : hint_range(1.0, 6.0) = 3.0;
uniform float edge_damp : hint_range(0.0, 0.6) = 0.28;

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 centered = UV - vec2(0.5);
	float dist = length(centered);
	float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5;

	// Interference — two overlapping sine waves at different frequencies/angles
	float wave_a = sin(UV.y * wave_density * 6.28318 - TIME * wave_speed) * 0.5 + 0.5;
	float wave_b = sin(UV.x * wave_density * 0.55 * 6.28318 + TIME * wave_speed * 0.65) * 0.5 + 0.5;
	float interference = wave_a * wave_b * interference_strength * (0.7 + pulse * 0.3);

	// Dampening rings from center — concentric circles fading outward
	float rings = sin(dist * ring_count * 14.0 - TIME * wave_speed * 0.6) * 0.5 + 0.5;
	float ring_fade = smoothstep(0.08, 0.38, dist) * smoothstep(0.52, 0.30, dist);
	float ring_effect = rings * ring_fade * 0.15 * (0.6 + pulse * 0.4);

	// Signal noise — subtle digital grain
	float noise = hash21(floor(UV * 18.0) + floor(TIME * 4.5)) * 0.06;

	// Edge softening — darken toward perimeter
	float edge_shadow = dist * edge_damp * (1.0 - pulse * 0.2);

	vec3 color = COLOR.rgb;
	color += vec3(0.0, interference * 0.75, interference);
	color += vec3(0.0, ring_effect * 0.65, ring_effect);
	color += vec3(0.0, noise * 0.4, noise);
	color *= 1.0 - edge_shadow;

	COLOR.rgb = clamp(color, 0.0, 1.6);
}
