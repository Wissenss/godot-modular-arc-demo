/*
	AI Beam Shader
	Bright data-beam with flowing scan bands and soft pixel shimmer.
*/
shader_type canvas_item;

uniform float flow_speed : hint_range(0.2, 12.0) = 3.2;
uniform float stripe_density : hint_range(2.0, 48.0) = 26.0;
uniform float glow_strength : hint_range(0.0, 2.0) = 0.8;
uniform float shimmer_strength : hint_range(0.0, 1.0) = 0.20;
uniform float edge_softness : hint_range(0.02, 0.4) = 0.14;
uniform float pixel_density : hint_range(8.0, 64.0) = 28.0;

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
	vec2 uv = UV;
	vec2 pixel_uv = floor(uv * vec2(pixel_density, pixel_density * 0.35)) / vec2(pixel_density, pixel_density * 0.35);
	float center_dist = abs(uv.y - 0.5) * 2.0;
	float core = smoothstep(1.0, 0.0, center_dist);
	float edge = smoothstep(0.0, edge_softness, uv.x) * smoothstep(0.0, edge_softness, 1.0 - uv.x);
	float stripe = sin((uv.x * stripe_density - TIME * flow_speed) * 6.2831853) * 0.5 + 0.5;
	float pulse = sin(TIME * 4.2 + uv.x * 8.0) * 0.5 + 0.5;
	float pulse_band = sin((pixel_uv.x * 18.0 - TIME * (flow_speed * 1.8)) * 6.2831853) * 0.5 + 0.5;
	float block_noise = hash21(floor(vec2(pixel_uv.x * 34.0, pixel_uv.y * 22.0)) + floor(TIME * 12.0));
	float noise = hash21(floor(vec2(uv.x * 42.0, uv.y * 18.0)) + floor(TIME * 10.0));
	float side_glow = smoothstep(1.0, 0.18, center_dist);

	vec3 color = COLOR.rgb;
	color *= 0.74 + core * 0.34;
	color += vec3(0.20, 0.36, 0.60) * stripe * 0.20;
	color += vec3(0.40, 0.68, 1.0) * pulse * glow_strength * core;
	color += vec3(0.74, 0.92, 1.0) * pulse_band * 0.18 * side_glow;
	color += vec3(0.22, 0.42, 0.80) * smoothstep(0.56, 1.0, block_noise) * 0.16;
	color += vec3(0.14, 0.24, 0.40) * noise * shimmer_strength;

	float alpha = COLOR.a * core * edge;
	alpha *= 0.82 + pulse * 0.10 + pulse_band * 0.08;

	COLOR = vec4(clamp(color, 0.0, 2.4), alpha);
}
