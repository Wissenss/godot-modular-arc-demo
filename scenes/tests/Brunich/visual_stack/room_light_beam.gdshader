shader_type canvas_item;
render_mode unshaded, blend_add;

uniform sampler2D noise_tex : filter_linear, repeat_enable;
uniform vec4 beam_color : source_color = vec4(0.65, 0.92, 1.0, 0.32);
uniform float intensity : hint_range(0.0, 3.0, 0.01) = 1.0;
uniform float scroll_speed : hint_range(-0.5, 0.5, 0.001) = 0.06;
uniform float drift_strength : hint_range(0.0, 1.0, 0.01) = 0.10;
uniform float edge_softness : hint_range(0.5, 6.0, 0.01) = 2.2;
uniform float pulse_speed : hint_range(0.0, 3.0, 0.01) = 0.45;
uniform float breakup : hint_range(0.0, 1.0, 0.01) = 0.40;

void fragment() {
	vec2 uv = UV;
	float center_mask = 1.0 - abs(uv.x - 0.5) * 2.0;
	center_mask = pow(clamp(center_mask, 0.0, 1.0), edge_softness);

	float vertical_fade = smoothstep(0.0, 0.14, uv.y);
	vertical_fade *= 1.0 - smoothstep(0.72, 1.0, uv.y);

	vec2 noise_uv = vec2(
		uv.x * 1.8 + TIME * scroll_speed * 0.35,
		uv.y * 2.6 - TIME * scroll_speed
	);
	float noise_a = texture(noise_tex, noise_uv).r;
	float noise_b = texture(noise_tex, noise_uv * vec2(1.9, 0.7) + vec2(2.1, 0.6)).r;
	float noise_mix = mix(noise_a, noise_b, 0.42);
	float beam_breakup = mix(1.0 - breakup, 1.0 + breakup * 0.85, noise_mix);

	float pulse = 0.92 + sin(TIME * pulse_speed + uv.y * 6.4) * 0.08;
	float drift = 1.0 - abs((uv.x - 0.5) + (noise_mix - 0.5) * drift_strength * 0.25) * 0.22;

	float alpha = beam_color.a * intensity * center_mask * vertical_fade * beam_breakup * pulse * drift;
	vec3 rgb = beam_color.rgb * (0.74 + noise_mix * 0.42);
	COLOR = vec4(rgb, clamp(alpha, 0.0, 1.0));
}
