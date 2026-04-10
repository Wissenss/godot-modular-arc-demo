shader_type canvas_item;

/*
	Death dissolve shader.
	- Per-cell noise dissolve driven by `dissolve_progress`.
	- Edge glow flashes on cells about to die.
	- Scanline glitch overlay fades out as progress completes.
	Applied at death time to the enemy's body/face polygons.
*/

uniform float dissolve_progress : hint_range(0.0, 1.0) = 0.0;
uniform float noise_scale : hint_range(0.05, 2.0) = 0.32;
uniform float glitch_intensity : hint_range(0.0, 2.0) = 0.75;
uniform float edge_glow : hint_range(0.0, 2.5) = 1.2;
uniform float scan_speed : hint_range(0.0, 30.0) = 18.0;

float hash(vec2 p) {
	p = fract(p * vec2(443.897, 441.423));
	p += dot(p, p.yx + 19.19);
	return fract((p.x + p.y) * p.x);
}

void fragment() {
	// Per-cell dissolve: UV in Polygon2D is vertex-position based.
	vec2 cell = floor(UV * noise_scale);
	float noise = hash(cell);

	// Carve cells whose noise value is below the current progress.
	float carved = step(noise, dissolve_progress);
	float alpha_mult = 1.0 - carved;

	// Edge halo: cells near the dissolve frontier flash bright.
	float edge_band = smoothstep(dissolve_progress - 0.18, dissolve_progress, noise) *
	                  (1.0 - smoothstep(dissolve_progress, dissolve_progress + 0.04, noise));
	float pulse = sin(TIME * scan_speed) * 0.5 + 0.5;

	// Scanline flicker fading out as dissolve advances.
	float scan = step(0.72, sin(UV.y * 0.42 + TIME * scan_speed));
	float life_left = 1.0 - dissolve_progress;

	vec3 color = COLOR.rgb;
	color += edge_band * edge_glow * vec3(1.0, 1.0, 1.0) * (0.4 + pulse * 0.6);
	color += scan * glitch_intensity * life_left * 0.35;

	COLOR.rgb = color;
	COLOR.a *= alpha_mult;
}
