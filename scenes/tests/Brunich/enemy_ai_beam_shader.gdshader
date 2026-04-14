/*
	AI Beam Shader
	Electric rail-beam with a hot muzzle bloom, pixel-cut veins, and layered streaks.
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
uniform float origin_bloom : hint_range(0.0, 2.0) = 1.18;
uniform float streak_strength : hint_range(0.0, 2.0) = 0.86;
uniform float tail_fade : hint_range(0.2, 2.0) = 0.84;

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float stepped_arc(vec2 uv, float time_value, float lane) {
	float zigzag = sin(uv.x * 22.0 - time_value * flow_speed * 1.7 + lane * 3.4) * 0.11;
	zigzag += sin(uv.x * 48.0 + time_value * flow_speed * 2.5 + lane * 5.2) * 0.042;
	float snapped = floor((uv.y + zigzag) * 22.0) / 22.0;
	return abs(snapped - lane);
}

void fragment() {
	vec2 uv = UV;
	vec2 pixel_uv = floor(uv * vec2(pixel_density, pixel_density * 0.76)) / vec2(pixel_density, pixel_density * 0.76);
	float center_dist = abs(pixel_uv.y - 0.5) * 2.0;
	float beam_mask = smoothstep(1.04, 0.04, center_dist);
	float core = smoothstep(1.0, 0.0, center_dist * (1.18 + pow(max(1.0 - uv.x, 0.0), 1.8) * 0.52));
	float channel = smoothstep(1.0, 0.10, center_dist);
	float edge = smoothstep(0.0, edge_softness, uv.x) * smoothstep(0.0, edge_softness, 1.0 - uv.x);
	float origin = pow(max(1.0 - uv.x, 0.0), 1.42);
	float stripe = sin((uv.x * stripe_density - TIME * flow_speed) * 6.2831853) * 0.5 + 0.5;
	float counter_stripe = sin((uv.x * (stripe_density * 0.58) + TIME * flow_speed * 0.72 + uv.y * 7.0) * 6.2831853) * 0.5 + 0.5;
	float rear_stripe = sin((uv.x * (stripe_density * 0.28) - TIME * flow_speed * 0.34 + uv.y * 4.2) * 6.2831853) * 0.5 + 0.5;
	float bolt_line_a = stepped_arc(pixel_uv, TIME, 0.50);
	float bolt_line_b = stepped_arc(pixel_uv, TIME * 1.08 + 1.4, 0.34);
	float bolt_line_c = stepped_arc(pixel_uv, TIME * 0.94 - 0.8, 0.66);
	float bolt = smoothstep(0.18, 0.0, bolt_line_a);
	float side_bolt = smoothstep(0.12, 0.0, min(bolt_line_b, bolt_line_c));
	float branch_noise = hash21(floor(vec2(pixel_uv.x * 24.0, pixel_uv.y * 12.0)) + vec2(floor(TIME * 18.0), floor(TIME * 12.0)));
	float branches = smoothstep(0.78, 1.0, branch_noise) * smoothstep(0.94, 0.08, center_dist) * bolt_strength;
	float spark_noise = hash21(floor(vec2(pixel_uv.x * 34.0, pixel_uv.y * 20.0)) + vec2(floor(TIME * 10.0), floor(TIME * 14.0)));
	float spark_lane = smoothstep(0.88, 1.0, spark_noise) * smoothstep(0.98, 0.18, center_dist) * streak_strength;
	float noise = hash21(floor(vec2(uv.x * 42.0, uv.y * 18.0)) + vec2(floor(TIME * 10.0), floor(TIME * 7.0)));
	float pulse = sin(TIME * flow_speed * 4.2 + uv.x * 18.0) * 0.5 + 0.5;
	float muzzle_flash = pow(origin, 2.6) * (0.74 + pulse * 0.26) * origin_bloom;
	float tail_streak = smoothstep(0.44, 0.0, abs(pixel_uv.y - 0.34)) * (0.34 + rear_stripe * 0.66);
	tail_streak += smoothstep(0.44, 0.0, abs(pixel_uv.y - 0.66)) * (0.28 + stripe * 0.58);
	tail_streak *= pow(clamp(uv.x, 0.0, 1.0), tail_fade);
	float white_core = pow(core, 2.1) * (0.56 + bolt * 0.16 + muzzle_flash * 0.22);

	vec3 color = COLOR.rgb;
	color *= 0.36 + channel * 0.58 + muzzle_flash * 0.18;
	color += vec3(0.04, 0.12, 0.34) * stripe * 0.18;
	color += vec3(0.08, 0.30, 0.72) * counter_stripe * 0.24;
	color += vec3(0.08, 0.74, 0.96) * tail_streak * 0.48;
	color += vec3(0.68, 0.96, 1.0) * bolt * (0.74 + glow_strength * 0.42);
	color += vec3(0.42, 0.92, 1.0) * side_bolt * 0.58;
	color += vec3(0.54, 0.96, 1.0) * branches * (0.68 + pulse * 0.28);
	color += vec3(0.72, 1.0, 1.0) * spark_lane * (0.52 + origin * 0.34);
	color += vec3(0.98, 1.0, 1.0) * white_core * core_hotness;
	color += vec3(1.0, 1.0, 1.0) * muzzle_flash * 0.84;
	color += vec3(0.08, 0.16, 0.36) * noise * shimmer_strength * 0.24;

	float alpha = COLOR.a * edge * beam_mask;
	alpha *= 0.86 + bolt * 0.24 + side_bolt * 0.14 + pulse * 0.06 + spark_lane * 0.10 + muzzle_flash * 0.12;

	COLOR = vec4(clamp(color, 0.0, 3.0), alpha);
}
