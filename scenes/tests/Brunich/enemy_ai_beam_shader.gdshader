/*
	AI Beam Shader
	Electric rail-beam with stepped lightning veins and a hot digital core.
*/
shader_type canvas_item;

uniform float flow_speed : hint_range(0.2, 12.0) = 3.2;
uniform float stripe_density : hint_range(2.0, 48.0) = 26.0;
uniform float glow_strength : hint_range(0.0, 2.0) = 0.8;
uniform float shimmer_strength : hint_range(0.0, 1.0) = 0.20;
uniform float bolt_strength : hint_range(0.0, 1.5) = 0.52;
uniform float core_hotness : hint_range(0.0, 1.5) = 0.92;
uniform float edge_softness : hint_range(0.02, 0.4) = 0.14;
uniform float pixel_density : hint_range(8.0, 64.0) = 28.0;

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float stepped_arc(vec2 uv, float time_value) {
	float wave = sin(uv.x * 18.0 - time_value * flow_speed * 1.7) * 0.08;
	wave += sin(uv.x * 33.0 + time_value * flow_speed * 2.1 + 0.7) * 0.04;
	float snapped = floor((uv.y + wave) * 18.0) / 18.0;
	return abs(snapped - 0.5);
}

void fragment() {
	vec2 uv = UV;
	vec2 pixel_uv = floor(uv * vec2(pixel_density, pixel_density * 0.55)) / vec2(pixel_density, pixel_density * 0.55);
	float center_dist = abs(uv.y - 0.5) * 2.0;
	float core = smoothstep(1.0, 0.0, center_dist);
	float channel = smoothstep(1.0, 0.20, center_dist);
	float edge = smoothstep(0.0, edge_softness, uv.x) * smoothstep(0.0, edge_softness, 1.0 - uv.x);
	float stripe = sin((uv.x * stripe_density - TIME * flow_speed) * 6.2831853) * 0.5 + 0.5;
	float counter_stripe = sin((uv.x * (stripe_density * 0.58) + TIME * flow_speed * 0.72 + uv.y * 7.0) * 6.2831853) * 0.5 + 0.5;
	float bolt_line = stepped_arc(pixel_uv, TIME);
	float bolt = smoothstep(0.22, 0.0, bolt_line);
	float branch_noise = hash21(floor(vec2(pixel_uv.x * 24.0, pixel_uv.y * 12.0)) + floor(TIME * 18.0));
	float branches = smoothstep(0.82, 1.0, branch_noise) * smoothstep(0.78, 0.12, center_dist) * bolt_strength;
	float noise = hash21(floor(vec2(uv.x * 42.0, uv.y * 18.0)) + floor(TIME * 10.0));

	vec3 color = COLOR.rgb;
	color *= 0.56 + channel * 0.46;
	color += vec3(0.16, 0.34, 0.74) * stripe * 0.20;
	color += vec3(0.32, 0.62, 1.0) * counter_stripe * 0.18;
	color += vec3(0.84, 0.98, 1.0) * bolt * (0.46 + glow_strength * 0.28);
	color += vec3(0.56, 0.90, 1.0) * branches;
	color += vec3(0.96, 1.0, 1.0) * pow(core, 1.8) * core_hotness;
	color += vec3(0.10, 0.18, 0.36) * noise * shimmer_strength * 0.38;

	float alpha = COLOR.a * edge * smoothstep(1.08, 0.02, center_dist);
	alpha *= 0.78 + bolt * 0.26 + stripe * 0.08;

	COLOR = vec4(clamp(color, 0.0, 2.4), alpha);
}
