shader_type canvas_item;

uniform float shake_power : hint_range(0.0, 0.2) = 0.045;
uniform float shake_rate : hint_range(0.0, 1.0) = 0.9;
uniform float shake_speed : hint_range(0.0, 40.0) = 14.0;
uniform float shake_block_size : hint_range(2.0, 32.0) = 8.0;
uniform float shake_color_rate : hint_range(0.0, 0.2) = 0.06;
uniform float alpha_strength : hint_range(0.0, 1.0) = 0.65;

float random(vec2 seed) {
	return fract(543.2543 * sin(dot(seed, vec2(3525.46, -54.3415))));
}

void fragment() {
	float block = floor(UV.y * shake_block_size + TIME * shake_speed * 0.2);
	float enable_shift = step(random(vec2(floor(TIME * shake_speed), block)), shake_rate);
	float jitter = (random(vec2(block, floor(TIME * shake_speed))) - 0.5) * shake_power * enable_shift;

	vec2 shifted_uv = clamp(UV + vec2(jitter, 0.0), vec2(0.0), vec2(1.0));
	float scan = sin((shifted_uv.y + TIME * 0.8) * 36.0) * 0.5 + 0.5;
	float edge_mask = smoothstep(0.0, 0.16, shifted_uv.x) * smoothstep(0.0, 0.16, shifted_uv.y);
	edge_mask *= smoothstep(1.0, 0.84, shifted_uv.x) * smoothstep(1.0, 0.84, shifted_uv.y);

	vec3 base = mix(COLOR.rgb, vec3(0.95, 0.85, 1.0), 0.25 + scan * 0.15);
	float red_shift = jitter * shake_color_rate * 7.0;
	float blue_shift = -jitter * shake_color_rate * 9.0;

	vec3 glitch_color = vec3(
		clamp(base.r + red_shift + scan * 0.08, 0.0, 1.0),
		clamp(base.g * 0.82 + enable_shift * 0.06, 0.0, 1.0),
		clamp(base.b + blue_shift + 0.14, 0.0, 1.0)
	);

	float strip = step(0.78, random(vec2(floor(shifted_uv.y * 18.0), floor(TIME * 9.0))));
	glitch_color += vec3(strip * 0.12, 0.0, strip * 0.18);

	float alpha = alpha_strength * edge_mask * (0.55 + scan * 0.45);
	COLOR = vec4(glitch_color, alpha);
}
