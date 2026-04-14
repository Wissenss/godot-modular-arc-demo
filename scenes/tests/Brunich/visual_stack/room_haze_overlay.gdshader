shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform sampler2D noise_tex : filter_linear, repeat_enable;
uniform vec4 haze_color : source_color = vec4(0.15, 0.08, 0.30, 0.34);
uniform float edge_strength : hint_range(0.0, 1.5, 0.01) = 0.54;
uniform float bottom_strength : hint_range(0.0, 1.5, 0.01) = 0.40;
uniform float center_clear : hint_range(0.0, 1.2, 0.01) = 0.54;
uniform float drift_speed : hint_range(0.0, 0.2, 0.001) = 0.018;

void fragment() {
	vec2 uv = UV;
	float dist = distance(uv, vec2(0.5, 0.48)) * 1.28;
	float edge_mask = smoothstep(center_clear, 1.18, dist);
	float bottom_mask = smoothstep(0.28, 1.0, uv.y);

	vec2 noise_uv = uv * vec2(1.35, 0.82) + vec2(TIME * drift_speed, -TIME * drift_speed * 0.75);
	float noise_value = texture(noise_tex, noise_uv).r;
	float alpha = haze_color.a * ((edge_mask * edge_strength) + (bottom_mask * bottom_strength)) * (0.72 + noise_value * 0.28);
	COLOR = vec4(haze_color.rgb, clamp(alpha, 0.0, 1.0));
}
