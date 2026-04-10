shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float strength : hint_range(0.0, 1.0) = 0.0;
uniform float ui_time = 0.0;
uniform vec2 focus_uv = vec2(0.5, 0.5);

float hash12(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 34.345);
	return fract(p.x * p.y);
}

float stripe(vec2 uv, float density, float speed) {
	return smoothstep(0.72, 1.0, sin((uv.y + ui_time * speed) * density) * 0.5 + 0.5);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 centered = (uv - focus_uv) * vec2(1.0, 1.55);
	float dist = length(centered);
	float pulse = sin(ui_time * 6.8 - dist * 26.0) * 0.5 + 0.5;
	float ring = smoothstep(0.42, 0.0, dist) * (0.5 + pulse * 0.5);
	float scan = stripe(uv, 210.0, 0.42);
	float secondary_scan = stripe(uv.yx, 128.0, -0.31);
	vec2 grid = floor(uv * vec2(30.0, 18.0));
	float block = step(0.74, hash12(grid + floor(ui_time * 10.0)));
	float code_stream = step(0.84, fract(uv.y * 26.0 - ui_time * (4.0 + floor(uv.x * 14.0))));
	vec2 warp = vec2(
		sin(uv.y * 48.0 + ui_time * 8.4),
		cos(uv.x * 34.0 - ui_time * 7.1)
	) * (0.0016 + ring * 0.0020) * strength;

	vec3 screen = texture(screen_tex, uv + warp).rgb;
	vec3 cooled = mix(screen, screen * vec3(0.34, 0.68, 1.18), 0.24 * strength);
	vec3 overlay = vec3(0.0);
	overlay += vec3(0.01, 0.05, 0.12) * (0.9 + ring * 0.6);
	overlay += vec3(0.06, 0.56, 0.98) * code_stream * 0.18;
	overlay += vec3(0.42, 0.84, 1.0) * block * 0.10;
	overlay += vec3(0.04, 0.22, 0.44) * secondary_scan * 0.12;
	overlay += vec3(0.18, 0.88, 1.0) * ring * 0.16;
	overlay += vec3(0.02, 0.12, 0.22) * scan * 0.14;

	float vignette = smoothstep(1.05, 0.20, length((uv - vec2(0.5)) * vec2(1.08, 1.0)));
	vec3 result = cooled + overlay * strength;
	result *= mix(1.0, 0.88 + vignette * 0.20, 0.35 * strength);

	COLOR = vec4(result, 1.0);
}
