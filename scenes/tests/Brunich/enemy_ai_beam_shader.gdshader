/*
	AI Beam Shader
	Electric rail-beam with stepped lightning veins and a hot digital core.
*/
shader_type canvas_item;

uniform float flow_speed : hint_range(0.2, 12.0) = 3.2;
uniform float stripe_density : hint_range(2.0, 48.0) = 26.0;
uniform float glow_strength : hint_range(0.0, 2.0) = 0.8;
uniform float shimmer_strength : hint_range(0.0, 1.0) = 0.14;
uniform float bolt_strength : hint_range(0.0, 1.5) = 0.68;
uniform float core_hotness : hint_range(0.0, 1.5) = 0.92;
uniform float edge_softness : hint_range(0.02, 0.4) = 0.14;
uniform float pixel_density : hint_range(8.0, 64.0) = 28.0;

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float stepped_arc(vec2 uv, float time_value, float lane) {
	float zigzag = sin(uv.x * 20.0 - time_value * flow_speed * 1.7 + lane * 3.4) * 0.11;
	zigzag += sin(uv.x * 47.0 + time_value * flow_speed * 2.4 + lane * 5.2) * 0.035;
	float snapped = floor((uv.y + zigzag) * 20.0) / 20.0;
	return abs(snapped - lane);
}

void fragment() {
	vec2 uv = UV;
	vec2 pixel_uv = floor(uv * vec2(pixel_density, pixel_density * 0.72)) / vec2(pixel_density, pixel_density * 0.72);
	float center_dist = abs(uv.y - 0.5) * 2.0;
	float core = smoothstep(1.0, 0.0, center_dist);
	float channel = smoothstep(1.0, 0.12, center_dist);
	float edge = smoothstep(0.0, edge_softness, uv.x) * smoothstep(0.0, edge_softness, 1.0 - uv.x);
	float stripe = sin((uv.x * stripe_density - TIME * flow_speed) * 6.2831853) * 0.5 + 0.5;
	float counter_stripe = sin((uv.x * (stripe_density * 0.58) + TIME * flow_speed * 0.72 + uv.y * 7.0) * 6.2831853) * 0.5 + 0.5;
	float bolt_line_a = stepped_arc(pixel_uv, TIME, 0.50);
	float bolt_line_b = stepped_arc(pixel_uv, TIME * 1.08 + 1.4, 0.34);
	float bolt_line_c = stepped_arc(pixel_uv, TIME * 0.94 - 0.8, 0.66);
	float bolt = smoothstep(0.18, 0.0, bolt_line_a);
	float side_bolt = smoothstep(0.12, 0.0, min(bolt_line_b, bolt_line_c));
	float branch_noise = hash21(floor(vec2(pixel_uv.x * 24.0, pixel_uv.y * 12.0)) + floor(TIME * 18.0));
	float branches = smoothstep(0.78, 1.0, branch_noise) * smoothstep(0.92, 0.10, center_dist) * bolt_strength;
	float noise = hash21(floor(vec2(uv.x * 42.0, uv.y * 18.0)) + floor(TIME * 10.0));
	float pulse = sin(TIME * flow_speed * 4.2 + uv.x * 18.0) * 0.5 + 0.5;

	vec3 color = COLOR.rgb;
	color *= 0.44 + channel * 0.54;
	color += vec3(0.10, 0.22, 0.60) * stripe * 0.16;
	color += vec3(0.18, 0.42, 0.92) * counter_stripe * 0.18;
	color += vec3(0.76, 0.96, 1.0) * bolt * (0.68 + glow_strength * 0.34);
	color += vec3(0.58, 0.86, 1.0) * side_bolt * 0.52;
	color += vec3(0.56, 0.90, 1.0) * branches * (0.72 + pulse * 0.24);
	color += vec3(0.98, 1.0, 1.0) * pow(core, 1.6) * core_hotness;
	color += vec3(0.08, 0.14, 0.30) * noise * shimmer_strength * 0.24;

	float beam_mask = smoothstep(1.02, 0.04, center_dist);
	float alpha = COLOR.a * edge * beam_mask;
	alpha *= 0.86 + bolt * 0.24 + side_bolt * 0.14 + pulse * 0.06;

	COLOR = vec4(clamp(color, 0.0, 2.4), alpha);
}
