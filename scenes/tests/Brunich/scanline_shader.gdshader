/*
	Scanline Shader — Regulated AI visual effect
	Applies moving horizontal scanlines to suggest a "monitored/controlled" system.
*/

shader_type canvas_item;

uniform float scan_speed : hint_range(0.5, 10.0) = 2.5;
uniform float line_density : hint_range(1.0, 30.0) = 10.0;
uniform float line_brightness : hint_range(0.0, 1.0) = 0.3;
uniform float pulse_speed : hint_range(0.0, 5.0) = 1.2;
uniform float subpixel_strength : hint_range(0.0, 0.4) = 0.08;
uniform float chroma_strength : hint_range(0.0, 0.25) = 0.03;
uniform float blur_strength : hint_range(0.0, 0.8) = 0.12;
uniform float shadow_strength : hint_range(0.0, 0.5) = 0.12;
uniform float stripe_density : hint_range(4.0, 80.0) = 26.0;
uniform float stripe_strength : hint_range(0.0, 1.0) = 0.25;

void fragment() {
	float scan = sin((UV.y * line_density - TIME * scan_speed) * 6.2831853) * 0.5 + 0.5;
	float line = mix(1.0 - line_brightness, 1.0 + line_brightness * 0.35, scan);
	float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5;
	float triad = fract(UV.x * 42.0);
	vec3 mask = vec3(1.0 - subpixel_strength * 0.5);
	if (triad < 0.33333334) {
		mask.r += subpixel_strength;
	} else if (triad < 0.6666667) {
		mask.g += subpixel_strength * 0.55;
	} else {
		mask.b += subpixel_strength;
	}
	vec2 centered = UV - vec2(0.5);
	float edge = smoothstep(0.18, 0.62, length(centered * vec2(1.08, 0.94)));
	float blur = edge * blur_strength;
	float stripe_wave = sin(UV.y * stripe_density * 6.2831853) * 0.5 + 0.5;
	float stripe_mask = mix(1.0 - stripe_strength, 1.0, smoothstep(0.42, 0.96, stripe_wave));
	float chroma_wave = sin((UV.y * 180.0) + (UV.x * 52.0) + TIME * 0.35) * 0.5 + 0.5;
	vec3 chroma = vec3(chroma_strength * chroma_wave, 0.0, chroma_strength * (1.0 - chroma_wave));
	vec3 color = COLOR.rgb;
	color *= mask;
	color *= line * (0.92 + pulse * 0.08);
	color *= stripe_mask;
	color += chroma;
	color += vec3(0.08, 0.05, 0.12) * blur;
	color *= 1.0 - edge * shadow_strength;

	COLOR.rgb = clamp(color, 0.0, 1.5);
}
