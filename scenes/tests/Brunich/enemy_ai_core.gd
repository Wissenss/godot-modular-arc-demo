class_name EnemyAICore
extends EnemyRegulated

const AI_BODY_SHADER := preload("res://scenes/tests/Brunich/enemy_ai_core_body.gdshader")
const ENERGY_CORE_SHADER := preload("res://scenes/tests/Brunich/energy_core_shader.gdshader")

const GLYPH_PIXEL_SIZE := 2.2
const AI_LETTER_A := [
	"01110",
	"10001",
	"10001",
	"11111",
	"10001",
	"10001",
	"10001",
]

const AI_LETTER_I := [
	"11111",
	"00100",
	"00100",
	"00100",
	"00100",
	"00100",
	"11111",
]

const BACK_PIXEL_LAYOUT := [
	{"angle": -2.76, "radius": 29.0, "size": 6.0, "speed": 0.38, "phase": 0.20, "drift": 1.0, "alpha": 0.48, "bob": 1.5},
	{"angle": -2.35, "radius": 34.0, "size": 4.0, "speed": 0.46, "phase": 0.64, "drift": 1.3, "alpha": 0.52, "bob": 1.6},
	{"angle": -1.96, "radius": 31.0, "size": 7.0, "speed": 0.30, "phase": 1.22, "drift": 1.2, "alpha": 0.44, "bob": 1.3},
	{"angle": -1.55, "radius": 37.0, "size": 5.0, "speed": 0.36, "phase": 1.74, "drift": 1.1, "alpha": 0.54, "bob": 1.4},
	{"angle": -1.10, "radius": 32.0, "size": 6.0, "speed": 0.42, "phase": 2.10, "drift": 1.0, "alpha": 0.50, "bob": 1.8},
	{"angle": -0.62, "radius": 35.0, "size": 7.0, "speed": 0.34, "phase": 2.56, "drift": 1.4, "alpha": 0.46, "bob": 1.5},
	{"angle": -0.18, "radius": 30.0, "size": 5.0, "speed": 0.40, "phase": 3.08, "drift": 0.9, "alpha": 0.58, "bob": 1.2},
	{"angle": 0.28, "radius": 34.0, "size": 6.0, "speed": 0.28, "phase": 3.50, "drift": 1.2, "alpha": 0.44, "bob": 1.6},
	{"angle": 0.80, "radius": 38.0, "size": 5.0, "speed": 0.32, "phase": 4.06, "drift": 1.5, "alpha": 0.48, "bob": 1.9},
	{"angle": 1.24, "radius": 33.0, "size": 7.0, "speed": 0.35, "phase": 4.58, "drift": 1.1, "alpha": 0.52, "bob": 1.6},
	{"angle": 1.74, "radius": 30.0, "size": 5.0, "speed": 0.44, "phase": 5.02, "drift": 0.9, "alpha": 0.54, "bob": 1.3},
	{"angle": 2.18, "radius": 36.0, "size": 6.0, "speed": 0.31, "phase": 5.56, "drift": 1.3, "alpha": 0.46, "bob": 1.7},
	{"angle": 2.62, "radius": 32.0, "size": 4.0, "speed": 0.43, "phase": 5.98, "drift": 1.1, "alpha": 0.55, "bob": 1.4},
	{"angle": 3.00, "radius": 28.0, "size": 6.0, "speed": 0.37, "phase": 6.40, "drift": 0.8, "alpha": 0.50, "bob": 1.1},
]

const FRONT_PIXEL_LAYOUT := [
	{"angle": -2.92, "radius": 24.0, "size": 6.0, "speed": 0.56, "phase": 0.12, "drift": 1.1, "alpha": 0.66, "bob": 1.2},
	{"angle": -2.58, "radius": 20.0, "size": 4.0, "speed": 0.62, "phase": 0.44, "drift": 1.4, "alpha": 0.72, "bob": 1.0},
	{"angle": -2.18, "radius": 25.0, "size": 7.0, "speed": 0.50, "phase": 0.86, "drift": 1.0, "alpha": 0.60, "bob": 1.4},
	{"angle": -1.82, "radius": 22.0, "size": 5.0, "speed": 0.70, "phase": 1.34, "drift": 1.3, "alpha": 0.74, "bob": 1.0},
	{"angle": -1.42, "radius": 25.0, "size": 6.0, "speed": 0.48, "phase": 1.76, "drift": 1.0, "alpha": 0.68, "bob": 1.5},
	{"angle": -1.02, "radius": 20.0, "size": 4.0, "speed": 0.76, "phase": 2.10, "drift": 1.1, "alpha": 0.78, "bob": 0.8},
	{"angle": -0.64, "radius": 23.0, "size": 7.0, "speed": 0.54, "phase": 2.54, "drift": 1.4, "alpha": 0.62, "bob": 1.3},
	{"angle": -0.26, "radius": 19.0, "size": 5.0, "speed": 0.66, "phase": 2.92, "drift": 1.0, "alpha": 0.76, "bob": 0.9},
	{"angle": 0.16, "radius": 23.0, "size": 6.0, "speed": 0.52, "phase": 3.28, "drift": 1.3, "alpha": 0.70, "bob": 1.2},
	{"angle": 0.58, "radius": 21.0, "size": 4.0, "speed": 0.74, "phase": 3.72, "drift": 1.0, "alpha": 0.80, "bob": 1.0},
	{"angle": 0.98, "radius": 25.0, "size": 7.0, "speed": 0.46, "phase": 4.16, "drift": 1.5, "alpha": 0.64, "bob": 1.6},
	{"angle": 1.36, "radius": 20.0, "size": 5.0, "speed": 0.68, "phase": 4.54, "drift": 1.1, "alpha": 0.74, "bob": 0.8},
	{"angle": 1.78, "radius": 22.0, "size": 6.0, "speed": 0.50, "phase": 4.94, "drift": 1.2, "alpha": 0.68, "bob": 1.4},
	{"angle": 2.16, "radius": 25.0, "size": 4.0, "speed": 0.72, "phase": 5.34, "drift": 1.0, "alpha": 0.76, "bob": 1.1},
	{"angle": 2.56, "radius": 19.0, "size": 6.0, "speed": 0.60, "phase": 5.76, "drift": 1.2, "alpha": 0.72, "bob": 0.9},
	{"angle": 2.92, "radius": 23.0, "size": 5.0, "speed": 0.58, "phase": 6.10, "drift": 1.3, "alpha": 0.66, "bob": 1.2},
]

const SPARK_LAYOUT := [
	{"angle": -2.90, "radius": 52.0, "size": 2.4, "speed": 0.80, "phase": 0.14, "drift": 2.6, "alpha": 0.44, "bob": 2.2},
	{"angle": -2.58, "radius": 58.0, "size": 1.8, "speed": 0.92, "phase": 0.42, "drift": 2.4, "alpha": 0.54, "bob": 2.4},
	{"angle": -2.22, "radius": 46.0, "size": 2.2, "speed": 0.86, "phase": 0.74, "drift": 2.8, "alpha": 0.50, "bob": 2.6},
	{"angle": -1.92, "radius": 64.0, "size": 1.6, "speed": 1.02, "phase": 1.12, "drift": 3.2, "alpha": 0.58, "bob": 2.8},
	{"angle": -1.62, "radius": 48.0, "size": 2.0, "speed": 0.88, "phase": 1.44, "drift": 2.6, "alpha": 0.52, "bob": 2.0},
	{"angle": -1.28, "radius": 60.0, "size": 1.8, "speed": 1.08, "phase": 1.86, "drift": 3.0, "alpha": 0.60, "bob": 2.4},
	{"angle": -0.96, "radius": 44.0, "size": 2.2, "speed": 0.82, "phase": 2.16, "drift": 2.4, "alpha": 0.46, "bob": 2.2},
	{"angle": -0.68, "radius": 56.0, "size": 1.6, "speed": 1.10, "phase": 2.44, "drift": 3.2, "alpha": 0.62, "bob": 2.8},
	{"angle": -0.34, "radius": 50.0, "size": 2.0, "speed": 0.94, "phase": 2.82, "drift": 2.8, "alpha": 0.56, "bob": 2.2},
	{"angle": -0.02, "radius": 62.0, "size": 1.8, "speed": 1.16, "phase": 3.10, "drift": 3.0, "alpha": 0.60, "bob": 3.0},
	{"angle": 0.28, "radius": 46.0, "size": 2.4, "speed": 0.84, "phase": 3.42, "drift": 2.6, "alpha": 0.48, "bob": 2.4},
	{"angle": 0.62, "radius": 58.0, "size": 1.6, "speed": 1.06, "phase": 3.78, "drift": 3.1, "alpha": 0.62, "bob": 2.6},
	{"angle": 0.96, "radius": 52.0, "size": 2.2, "speed": 0.90, "phase": 4.10, "drift": 2.5, "alpha": 0.54, "bob": 2.3},
	{"angle": 1.28, "radius": 64.0, "size": 1.8, "speed": 1.14, "phase": 4.48, "drift": 3.3, "alpha": 0.58, "bob": 3.1},
	{"angle": 1.58, "radius": 46.0, "size": 2.0, "speed": 0.86, "phase": 4.78, "drift": 2.7, "alpha": 0.50, "bob": 2.0},
	{"angle": 1.90, "radius": 60.0, "size": 1.6, "speed": 1.12, "phase": 5.12, "drift": 3.0, "alpha": 0.60, "bob": 2.9},
	{"angle": 2.24, "radius": 48.0, "size": 2.2, "speed": 0.88, "phase": 5.46, "drift": 2.8, "alpha": 0.52, "bob": 2.5},
	{"angle": 2.56, "radius": 62.0, "size": 1.8, "speed": 1.04, "phase": 5.78, "drift": 3.1, "alpha": 0.58, "bob": 2.7},
	{"angle": 2.88, "radius": 50.0, "size": 2.0, "speed": 0.92, "phase": 6.12, "drift": 2.6, "alpha": 0.48, "bob": 2.2},
	{"angle": 3.14, "radius": 56.0, "size": 1.6, "speed": 1.08, "phase": 6.38, "drift": 3.2, "alpha": 0.62, "bob": 3.0},
]

var AIGlyphRoot: Node2D
var AIPixelHaloBack: Node2D
var AIPixelHaloFront: Node2D
var AISparkField: Node2D
var AICoreGlow: Polygon2D
var AICornerBrackets: Node2D
var _glyph_pixels: Array[Dictionary] = []
var _halo_back_pixels: Array[Dictionary] = []
var _halo_front_pixels: Array[Dictionary] = []
var _spark_pixels: Array[Dictionary] = []
var _bracket_parts: Array[Dictionary] = []
var _face_shell_base_scale := Vector2.ONE
var _face_fill_base_scale := Vector2.ONE
var _face_glass_base_scale := Vector2.ONE
var _glyph_root_base_scale := Vector2.ONE
var _face_shell_base_position := Vector2.ZERO
var _face_fill_base_position := Vector2.ZERO
var _face_glass_base_position := Vector2.ZERO
var _glyph_root_base_position := Vector2.ZERO

func _ready() -> void:
	super()
	_configure_materials()
	_configure_particles()
	_build_core_glow()
	_build_corner_brackets()
	_build_ai_glyph()
	_build_pixel_layer("ai_pixel_halo_back", AIPixelHaloBack, _halo_back_pixels, BACK_PIXEL_LAYOUT, 0, 0.86)
	_build_pixel_layer("ai_pixel_halo_front", AIPixelHaloFront, _halo_front_pixels, FRONT_PIXEL_LAYOUT, 6, 1.0)
	_build_pixel_layer("ai_spark_field", AISparkField, _spark_pixels, SPARK_LAYOUT, 7, 0.56)
	_face_shell_base_scale = ($face_shell as Polygon2D).scale
	_face_fill_base_scale = ($face_fill as Polygon2D).scale
	_face_glass_base_scale = ($face_glass as Polygon2D).scale
	_face_shell_base_position = ($face_shell as Polygon2D).position
	_face_fill_base_position = ($face_fill as Polygon2D).position
	_face_glass_base_position = ($face_glass as Polygon2D).position
	_glyph_root_base_scale = self.AIGlyphRoot.scale if self.AIGlyphRoot != null else Vector2.ONE
	_glyph_root_base_position = self.AIGlyphRoot.position if self.AIGlyphRoot != null else Vector2.ZERO
	_update_visuals()

func _configure_materials() -> void:
	self.Polygon.material = _create_body_material(1.6, 16.0, 0.42, 0.72, 0.20)
	self.ShieldPoly.material = _create_body_material(1.2, 11.0, 0.26, 0.44, 0.10)
	self.ShieldPoly.color = Color(BaseColor.r, BaseColor.g, BaseColor.b, 0.14)
	if has_node("face_shell"):
		($face_shell as Polygon2D).color = Color(0.05, 0.14, 0.28, 0.96)
	if has_node("face_fill"):
		($face_fill as Polygon2D).color = Color(0.06, 0.24, 0.46, 1.0)
	if has_node("face_glass"):
		var face_glass := $face_glass as Polygon2D
		face_glass.color = Color(0.28, 0.80, 1.0, 0.96)
		face_glass.material = _create_scanline_material(0.54, 21.0, 0.16, 1.20, 0.16, 0.04, 0.20, 0.08, 28.0, 0.18)

func _configure_particles() -> void:
	self.BodyParticles.amount = 10
	self.BodyParticles.initial_velocity_min = 12.0
	self.BodyParticles.initial_velocity_max = 28.0
	self.BodyParticles.scale_amount_min = 1.8
	self.BodyParticles.scale_amount_max = 3.2
	self.BodyParticles.color = Color(0.36, 0.82, 1.0, 0.36)
	self.OrbitParticles.amount = 8
	self.OrbitParticles.initial_velocity_min = 4.0
	self.OrbitParticles.initial_velocity_max = 11.0
	self.OrbitParticles.scale_amount_min = 1.6
	self.OrbitParticles.scale_amount_max = 2.4
	self.OrbitParticles.color = Color(0.82, 0.96, 1.0, 0.38)

func _update_visuals() -> void:
	super()
	var attack_state := _get_attack_visual_state()
	var prep_ratio := float(attack_state.get("prep_ratio", 0.0))
	var charge_ratio := float(attack_state.get("charge_ratio", 0.0))
	var beam_intensity := float(attack_state.get("beam_intensity", 0.0))
	var pulse := sin(_combat_time * (2.6 + charge_ratio * 1.8 + beam_intensity * 2.2)) * 0.5 + 0.5
	_update_body_materials(charge_ratio, beam_intensity)
	_update_core_breath(pulse, prep_ratio, charge_ratio, beam_intensity)
	_update_core_glow(pulse, charge_ratio, beam_intensity)
	_update_glyph_pixels(pulse, charge_ratio, beam_intensity)
	_update_brackets(pulse, charge_ratio, beam_intensity)
	_update_pixel_layer(_halo_back_pixels, pulse, 0.68, 3.2, charge_ratio, beam_intensity)
	_update_pixel_layer(_halo_front_pixels, pulse, 0.96, 5.2, charge_ratio, beam_intensity)
	_update_spark_field(pulse, charge_ratio, beam_intensity)

func _get_attack_visual_state() -> Dictionary:
	if self.Weapon != null and self.Weapon.has_method("get_visual_attack_state"):
		return self.Weapon.get_visual_attack_state()
	return {
		"prep_ratio": 0.0,
		"charge_ratio": 0.0,
		"beam_intensity": 0.0,
		"fade_ratio": 0.0,
	}

func _update_body_materials(charge_ratio: float, beam_intensity: float) -> void:
	var body_material := self.Polygon.material as ShaderMaterial
	if body_material != null:
		body_material.set_shader_parameter("pulse_speed", 1.6 + charge_ratio * 1.5 + beam_intensity * 2.2)
		body_material.set_shader_parameter("grid_density", 16.0 + charge_ratio * 3.0 + beam_intensity * 4.0)
		body_material.set_shader_parameter("block_strength", 0.72 + charge_ratio * 0.20 + beam_intensity * 0.34)
		body_material.set_shader_parameter("haze_strength", 0.20 + charge_ratio * 0.08 + beam_intensity * 0.14)
	var shield_material := self.ShieldPoly.material as ShaderMaterial
	if shield_material != null:
		shield_material.set_shader_parameter("pulse_speed", 1.2 + charge_ratio * 1.2 + beam_intensity * 1.6)
		shield_material.set_shader_parameter("block_strength", 0.44 + charge_ratio * 0.16 + beam_intensity * 0.24)
		shield_material.set_shader_parameter("haze_strength", 0.10 + charge_ratio * 0.05 + beam_intensity * 0.10)

func _update_core_breath(pulse: float, prep_ratio: float, charge_ratio: float, beam_intensity: float) -> void:
	var breath_scale := 0.96 + pulse * 0.08 + prep_ratio * 0.02 + charge_ratio * 0.06 + beam_intensity * 0.08
	var fill_scale := 0.97 + pulse * 0.08 + charge_ratio * 0.05 + beam_intensity * 0.06
	var glass_scale := 0.98 + pulse * 0.10 + charge_ratio * 0.06 + beam_intensity * 0.10
	($face_shell as Polygon2D).scale = _face_shell_base_scale * breath_scale
	($face_fill as Polygon2D).scale = _face_fill_base_scale * fill_scale
	($face_glass as Polygon2D).scale = _face_glass_base_scale * glass_scale
	($face_shell as Polygon2D).position = _face_shell_base_position + Vector2(-0.3 + pulse * 0.8, -0.8 + pulse * 1.2 - charge_ratio * 1.4)
	($face_fill as Polygon2D).position = _face_fill_base_position + Vector2(-0.2 + pulse * 0.6, -0.6 + pulse * 1.0 - charge_ratio * 1.0)
	($face_glass as Polygon2D).position = _face_glass_base_position + Vector2(0.0, -0.4 + pulse * 0.8 - charge_ratio * 0.9)
	if self.AIGlyphRoot != null:
		self.AIGlyphRoot.scale = _glyph_root_base_scale * (0.94 + pulse * 0.08 + charge_ratio * 0.06 + beam_intensity * 0.10)
		self.AIGlyphRoot.position = _glyph_root_base_position + Vector2(-0.7 + pulse * 1.1, -0.9 + pulse * 1.0 - charge_ratio * 1.4)

func _build_core_glow() -> void:
	var face_points := _get_face_display_points()
	self.AICoreGlow = _ensure_polygon_node(
		"ai_core_glow",
		2,
		Color(0.34, 0.86, 1.0, 0.28),
		face_points
	)
	self.AICoreGlow.scale = Vector2.ONE * 1.42
	self.AICoreGlow.material = _create_energy_material(6.0, 1.1, 0.34, 0.46)

func _update_core_glow(pulse: float, charge_ratio: float, beam_intensity: float) -> void:
	if self.AICoreGlow == null:
		return
	self.AICoreGlow.scale = Vector2.ONE * (1.30 + pulse * 0.14 + charge_ratio * 0.18 + beam_intensity * 0.24)
	self.AICoreGlow.color = Color(
		0.28 + pulse * 0.10 + beam_intensity * 0.06,
		0.78 + pulse * 0.10 + charge_ratio * 0.10 + beam_intensity * 0.12,
		1.0,
		0.16 + pulse * 0.08 + charge_ratio * 0.10 + beam_intensity * 0.16
	)
	var core_material := self.AICoreGlow.material as ShaderMaterial
	if core_material != null:
		core_material.set_shader_parameter("pulse_speed", 6.0 + charge_ratio * 2.0 + beam_intensity * 2.8)
		core_material.set_shader_parameter("glow_intensity", 1.1 + charge_ratio * 0.28 + beam_intensity * 0.42)
		core_material.set_shader_parameter("shimmer_strength", 0.34 + charge_ratio * 0.10 + beam_intensity * 0.12)

func _build_corner_brackets() -> void:
	self.AICornerBrackets = _ensure_effect_container("ai_corner_brackets", 6)
	_clear_children(self.AICornerBrackets)
	_bracket_parts.clear()
	var pieces := [
		{"pos": Vector2(-13.8, -17.8), "size": Vector2(6.2, 1.8)},
		{"pos": Vector2(-16.0, -15.6), "size": Vector2(1.8, 6.2)},
		{"pos": Vector2(13.8, -17.8), "size": Vector2(6.2, 1.8)},
		{"pos": Vector2(16.0, -15.6), "size": Vector2(1.8, 6.2)},
		{"pos": Vector2(-13.8, 17.8), "size": Vector2(6.2, 1.8)},
		{"pos": Vector2(-16.0, 15.6), "size": Vector2(1.8, 6.2)},
		{"pos": Vector2(13.8, 17.8), "size": Vector2(6.2, 1.8)},
		{"pos": Vector2(16.0, 15.6), "size": Vector2(1.8, 6.2)},
	]
	for piece in pieces:
		var bracket := Polygon2D.new()
		bracket.color = Color(0.88, 0.98, 1.0, 0.92)
		bracket.polygon = _make_rect_points(piece.size.x, piece.size.y)
		bracket.position = piece.pos
		self.AICornerBrackets.add_child(bracket)
		_bracket_parts.append({"node": bracket, "phase": float(_bracket_parts.size()) * 0.42})

func _update_brackets(pulse: float, charge_ratio: float, beam_intensity: float) -> void:
	for bracket_data in _bracket_parts:
		var bracket := bracket_data["node"] as Polygon2D
		var phase := float(bracket_data["phase"])
		var flicker := sin(_combat_time * 4.2 + phase) * 0.5 + 0.5
		bracket.scale = Vector2.ONE * (1.0 + charge_ratio * 0.08 + beam_intensity * 0.12)
		bracket.modulate = Color(1.0, 1.0, 1.0, 0.70 + flicker * 0.18 + pulse * 0.04 + charge_ratio * 0.10 + beam_intensity * 0.16)

func _build_ai_glyph() -> void:
	self.AIGlyphRoot = _ensure_effect_container("ai_glyph_root", 7)
	_clear_children(self.AIGlyphRoot)
	_glyph_pixels.clear()
	_build_letter(AI_LETTER_A, Vector2(-8.2, -7.2), 0.0)
	_build_letter(AI_LETTER_I, Vector2(4.8, -7.2), 1.3)

func _build_letter(pattern: Array, origin: Vector2, phase_offset: float) -> void:
	for row in range(pattern.size()):
		var line: String = pattern[row]
		for column in range(line.length()):
			if line[column] != "1":
				continue
			var pixel := Polygon2D.new()
			pixel.color = Color(0.88, 0.98, 1.0, 0.94)
			pixel.polygon = _make_rect_points(GLYPH_PIXEL_SIZE, GLYPH_PIXEL_SIZE)
			pixel.position = origin + Vector2(float(column) * (GLYPH_PIXEL_SIZE + 0.45), float(row) * (GLYPH_PIXEL_SIZE + 0.40))
			self.AIGlyphRoot.add_child(pixel)
			_glyph_pixels.append({"node": pixel, "phase": phase_offset + float(row * 7 + column) * 0.18})

func _update_glyph_pixels(pulse: float, charge_ratio: float, beam_intensity: float) -> void:
	for glyph_data in _glyph_pixels:
		var pixel := glyph_data["node"] as Polygon2D
		var phase := float(glyph_data["phase"])
		var flicker := sin(_combat_time * 5.4 + phase) * 0.5 + 0.5
		pixel.scale = Vector2.ONE * (0.88 + flicker * 0.18 + pulse * 0.04 + charge_ratio * 0.08 + beam_intensity * 0.10)
		pixel.color = Color(
			0.82 + flicker * 0.12 + beam_intensity * 0.06,
			0.94 + flicker * 0.05 + charge_ratio * 0.03 + beam_intensity * 0.04,
			1.0,
			0.68 + pulse * 0.12 + flicker * 0.10 + charge_ratio * 0.10 + beam_intensity * 0.14
		)

func _build_pixel_layer(container_name: String, container_ref: Node2D, target_array: Array[Dictionary], layout: Array, z_index_value: int, alpha_scale: float) -> void:
	container_ref = _ensure_effect_container(container_name, z_index_value)
	match container_name:
		"ai_pixel_halo_back":
			self.AIPixelHaloBack = container_ref
		"ai_pixel_halo_front":
			self.AIPixelHaloFront = container_ref
		"ai_spark_field":
			self.AISparkField = container_ref
	_clear_children(container_ref)
	target_array.clear()
	for config in layout:
		var variant_count := 1
		if container_name == "ai_spark_field" or container_name == "ai_pixel_halo_front":
			variant_count = 2
		for variant_index in range(variant_count):
			var pixel := Polygon2D.new()
			var variant_scale := 1.0 if variant_index == 0 else 0.58
			var radius_offset := 0.0 if variant_index == 0 else 4.0 + float(variant_index) * 2.0
			pixel.polygon = _make_rect_points(2.0, 2.0)
			pixel.scale = Vector2.ONE * float(config["size"]) * variant_scale
			pixel.color = Color(0.58, 0.90, 1.0, float(config["alpha"]) * alpha_scale * (1.0 if variant_index == 0 else 0.74))
			pixel.material = _create_energy_material(4.8 + float(config["speed"]) * 2.2 + float(variant_index) * 0.8, 0.82, 0.22, 0.18)
			container_ref.add_child(pixel)
			target_array.append({
				"node": pixel,
				"base_angle": float(config["angle"]) + float(variant_index) * 0.16,
				"radius": float(config["radius"]) + radius_offset,
				"speed": float(config["speed"]) + float(variant_index) * 0.08,
				"phase": float(config["phase"]) + float(variant_index) * 0.26,
				"drift": float(config["drift"]) * (1.0 + float(variant_index) * 0.24),
				"alpha": float(config["alpha"]) * alpha_scale * (1.0 if variant_index == 0 else 0.74),
				"base_scale": float(config["size"]) * variant_scale,
				"bob": float(config["bob"]) * (1.0 + float(variant_index) * 0.20),
				"variant": variant_index,
			})

func _update_pixel_layer(target_array: Array[Dictionary], pulse: float, pulse_scale: float, detach_strength: float, charge_ratio: float, beam_intensity: float) -> void:
	for config in target_array:
		var pixel := config["node"] as Polygon2D
		var base_angle := float(config["base_angle"])
		var radius := float(config["radius"])
		var speed := float(config["speed"])
		var phase := float(config["phase"])
		var drift := float(config["drift"])
		var alpha := float(config["alpha"])
		var base_scale := float(config["base_scale"])
		var bob := float(config["bob"])
		var variant := float(config.get("variant", 0))

		var orbit_angle := base_angle + _combat_time * speed
		var radial_wave := sin(_combat_time * (speed * 2.2 + 0.6) + phase) * bob
		var detach_wave := pow(sin(_combat_time * (speed * 1.5 + 0.9) + phase) * 0.5 + 0.5, 2.0) * detach_strength
		var charge_pull := charge_ratio * (6.0 + drift * 1.3) * (1.0 + variant * 0.4)
		var beam_push := beam_intensity * (8.0 + drift * 1.8) * (1.0 + variant * 0.3)
		var orbit_dir := Vector2(cos(orbit_angle), sin(orbit_angle) * 0.90)
		var drift_offset := Vector2(
			sin(_combat_time * (speed * 3.1 + 0.8) + phase),
			cos(_combat_time * (speed * 2.4 + 1.2) + phase * 0.7)
		) * drift
		pixel.position = orbit_dir * (radius + radial_wave + detach_wave + beam_push - charge_pull) + drift_offset
		pixel.scale = Vector2.ONE * (base_scale * (0.88 + pulse * pulse_scale * 0.18 + charge_ratio * 0.08 + beam_intensity * 0.12))
		pixel.modulate = Color(1.0, 1.0, 1.0, alpha * (0.62 + pulse * 0.24 + charge_ratio * 0.20 + beam_intensity * 0.24))

func _update_spark_field(pulse: float, charge_ratio: float, beam_intensity: float) -> void:
	for config in _spark_pixels:
		var pixel := config["node"] as Polygon2D
		var base_angle := float(config["base_angle"])
		var radius := float(config["radius"])
		var speed := float(config["speed"])
		var phase := float(config["phase"])
		var drift := float(config["drift"])
		var alpha := float(config["alpha"])
		var base_scale := float(config["base_scale"])
		var variant := float(config.get("variant", 0))
		var cycle := fposmod(_combat_time * (0.18 + speed * 0.08) + phase * 0.22, 1.0)
		var angle := base_angle + sin(_combat_time * (0.7 + speed) + phase) * 0.24
		var orbit_dir := Vector2(cos(angle), sin(angle) * 0.92)
		var detach := cycle * (8.0 + drift * 1.4) + beam_intensity * (10.0 + drift * 1.8) - charge_ratio * (8.0 + drift * 1.4) * (1.0 + variant * 0.3)
		var drift_offset := Vector2(
			sin(_combat_time * (speed * 2.6 + 1.0) + phase),
			cos(_combat_time * (speed * 2.9 + 1.6) + phase * 0.8)
		) * (drift * 1.1)
		pixel.position = orbit_dir * (radius + detach) + drift_offset
		pixel.scale = Vector2.ONE * (base_scale * (0.82 + pulse * 0.12 + (1.0 - cycle) * 0.12 + charge_ratio * 0.10 + beam_intensity * 0.16))
		pixel.modulate = Color(1.0, 1.0, 1.0, alpha * (1.0 - cycle) * (0.76 + pulse * 0.16 + charge_ratio * 0.18 + beam_intensity * 0.28))

func _make_rect_points(width: float, height: float) -> PackedVector2Array:
	var half_width := width * 0.5
	var half_height := height * 0.5
	return PackedVector2Array([
		Vector2(-half_width, -half_height),
		Vector2(half_width, -half_height),
		Vector2(half_width, half_height),
		Vector2(-half_width, half_height),
	])

func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()

func _create_body_material(pulse_speed: float, grid_density: float, rim_strength: float, block_strength: float, haze_strength: float) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = AI_BODY_SHADER
	material.set_shader_parameter("pulse_speed", pulse_speed)
	material.set_shader_parameter("grid_density", grid_density)
	material.set_shader_parameter("rim_strength", rim_strength)
	material.set_shader_parameter("block_strength", block_strength)
	material.set_shader_parameter("haze_strength", haze_strength)
	return material

func _create_energy_material(pulse_speed: float, glow_intensity: float, shimmer_strength: float, flare_strength: float) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = ENERGY_CORE_SHADER
	material.set_shader_parameter("pulse_speed", pulse_speed)
	material.set_shader_parameter("glow_intensity", glow_intensity)
	material.set_shader_parameter("shimmer_strength", shimmer_strength)
	material.set_shader_parameter("flare_strength", flare_strength)
	return material
