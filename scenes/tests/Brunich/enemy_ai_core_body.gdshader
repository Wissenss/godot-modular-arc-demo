/*
	AI Core Body Shader
	Blocky digital bloom for the spherical shell around the central chip.
	The UVs are intentionally quantized so the glow reads as square pixels.
*/
shader_type canvas_item;

uniform float pulse_speed : hint_range(0.1, 6.0) = 1.6;
uniform float grid_density : hint_range(4.0, 32.0) = 16.0;
uniform float rim_strength : hint_range(0.0, 1.4) = 0.42;
uniform float block_strength : hint_range(0.0, 1.6) = 0.72;
uniform float haze_strength : hint_range(0.0, 0.8) = 0.20;

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
	vec2 centered = (UV - vec2(0.5)) * vec2(1.0, 0.92);
	float dist = length(centered);
	float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5;

	vec2 cell_uv = floor(UV * grid_density);
	float cell = hash21(cell_uv + floor(TIME * (3.0 + pulse_speed)));
	float block_mask = smoothstep(0.42, 0.98, cell);

	float core = smoothstep(0.82, 0.10, dist);
	float rim = smoothstep(0.26, 0.90, dist) * smoothstep(1.02, 0.58, dist);
	float haze = sin((UV.x + UV.y) * 16.0 - TIME * (2.4 + pulse_speed)) * 0.5 + 0.5;
	float spoke = sin((UV.x - UV.y) * 9.0 + TIME * 1.6) * 0.5 + 0.5;

	vec3 color = COLOR.rgb;
	color *= 0.74 + core * (0.34 + pulse * 0.10);
	color += vec3(0.10, 0.22, 0.40) * block_mask * block_strength * (0.35 + core * 0.65);
	color += vec3(0.44, 0.74, 1.0) * rim * rim_strength * (0.85 + pulse * 0.25);
	color += vec3(0.18, 0.36, 0.65) * haze * haze_strength * (0.40 + core * 0.60);
	color += vec3(0.08, 0.22, 0.48) * spoke * 0.10 * (0.50 + pulse * 0.30);

	float alpha = COLOR.a * smoothstep(1.04, 0.82, dist);
	alpha *= 0.86 + rim * 0.20 + block_mask * 0.06;

	COLOR = vec4(clamp(color, 0.0, 2.4), alpha);
}
