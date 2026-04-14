extends Node2D
class_name BrunichVisualStack

const BRUNICH_PALETTE := preload("res://scenes/tests/Brunich/brunich_palette.gd")
const POSTFX_SHADER := preload("res://scenes/tests/Brunich/visual_stack/postfx/ScreenEffects_Ultimate.tres")
const NOISE_TEXTURE := preload("res://scenes/tests/Brunich/visual_stack/postfx/noise_texture.tres")
const BEAM_SHADER := preload("res://scenes/tests/Brunich/visual_stack/room_light_beam.gdshader")
const HAZE_SHADER := preload("res://scenes/tests/Brunich/visual_stack/room_haze_overlay.gdshader")

var _player: Node2D
var _floor_tiles: TileMapLayer
var _room_size := Vector2.ZERO
var _exit_left := 0.0
var _exit_right := 0.0
var _current_layout_id: StringName = &"classic"

var ambient_modulate: CanvasModulate
var lighting_root: Node2D
var shaft_root: Node2D
var occluder_root: Node2D
var world_post_fx_layer: CanvasLayer
var post_fx_root: Control
var haze_rect: ColorRect
var post_fx_rect: ColorRect
var _player_key_light: PointLight2D
var _runtime_tracks: Array[Dictionary] = []

func setup(player: Node2D, floor_tiles: TileMapLayer, room_size: Vector2, exit_left: float, exit_right: float) -> void:
	rebuild_for_room(player, floor_tiles, room_size, exit_left, exit_right, &"classic")

func rebuild_for_room(player: Node2D, floor_tiles: TileMapLayer, room_size: Vector2, exit_left: float, exit_right: float, layout_id: StringName) -> void:
	_player = player
	_floor_tiles = floor_tiles
	_room_size = room_size
	_exit_left = exit_left
	_exit_right = exit_right
	_current_layout_id = layout_id
	_ensure_nodes()
	_configure_post_fx()
	_enhance_tilemap_texture()
	refresh_layout(layout_id)

func refresh_layout(layout_id: StringName) -> void:
	if lighting_root == null or shaft_root == null or occluder_root == null:
		return
	_current_layout_id = layout_id
	_clear_children(lighting_root)
	_clear_children(shaft_root)
	_clear_children(occluder_root)
	_runtime_tracks.clear()
	_build_occluders()
	_build_base_lighting(layout_id)
	_build_atmosphere_shafts(layout_id)

func _process(delta: float) -> void:
	if _player_key_light != null and is_instance_valid(_player) and is_instance_valid(_player_key_light):
		_player_key_light.global_position = _player_key_light.global_position.lerp(_player.global_position + Vector2(0.0, -8.0), minf(1.0, delta * 7.6))
	for track in _runtime_tracks:
		var node := track.get("node", null) as CanvasItem
		if node == null or not is_instance_valid(node):
			continue
		var phase := float(track.get("phase", 0.0))
		var speed := float(track.get("speed", 1.0))
		var amplitude := float(track.get("amplitude", 0.1))
		if node is PointLight2D:
			var light := node as PointLight2D
			var base_energy := float(track.get("base_energy", light.energy))
			light.energy = base_energy + sin(Time.get_ticks_msec() * 0.001 * speed + phase) * amplitude
		elif node is Polygon2D:
			var poly := node as Polygon2D
			var base_alpha := float(track.get("base_alpha", poly.modulate.a))
			var next_alpha := clampf(base_alpha + sin(Time.get_ticks_msec() * 0.001 * speed + phase) * amplitude, 0.0, 1.0)
			poly.modulate = Color(poly.modulate.r, poly.modulate.g, poly.modulate.b, next_alpha)

func _ensure_nodes() -> void:
	name = "visual_stack_root"
	if ambient_modulate != null and is_instance_valid(ambient_modulate):
		return

	ambient_modulate = CanvasModulate.new()
	ambient_modulate.name = "ambient_modulate"
	add_child(ambient_modulate)

	shaft_root = Node2D.new()
	shaft_root.name = "shaft_root"
	shaft_root.z_index = -5
	add_child(shaft_root)

	lighting_root = Node2D.new()
	lighting_root.name = "lighting_root"
	lighting_root.z_index = -4
	add_child(lighting_root)

	occluder_root = Node2D.new()
	occluder_root.name = "occluder_root"
	add_child(occluder_root)

	world_post_fx_layer = CanvasLayer.new()
	world_post_fx_layer.name = "world_post_fx_layer"
	world_post_fx_layer.layer = 12
	add_child(world_post_fx_layer)

	post_fx_root = Control.new()
	post_fx_root.name = "post_fx_root"
	post_fx_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	post_fx_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	post_fx_root.visible = false
	world_post_fx_layer.add_child(post_fx_root)

	haze_rect = ColorRect.new()
	haze_rect.name = "haze_rect"
	haze_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	haze_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	haze_rect.color = Color.WHITE
	world_post_fx_layer.add_child(haze_rect)

	post_fx_rect = ColorRect.new()
	post_fx_rect.name = "post_fx_rect"
	post_fx_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	post_fx_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	post_fx_rect.color = Color.WHITE
	world_post_fx_layer.add_child(post_fx_rect)

func _configure_post_fx() -> void:
	if ambient_modulate != null:
		ambient_modulate.color = Color8(92, 102, 142, 255)

	if haze_rect != null:
		var haze_material := ShaderMaterial.new()
		haze_material.shader = HAZE_SHADER
		haze_material.set_shader_parameter("noise_tex", NOISE_TEXTURE)
		haze_material.set_shader_parameter("haze_color", Color(0.10, 0.06, 0.18, 0.24))
		haze_material.set_shader_parameter("edge_strength", 0.58)
		haze_material.set_shader_parameter("bottom_strength", 0.34)
		haze_material.set_shader_parameter("center_clear", 0.56)
		haze_rect.material = haze_material

	if post_fx_rect == null:
		return
	var post_material := ShaderMaterial.new()
	post_material.shader = POSTFX_SHADER
	post_material.set_shader_parameter("Pixelation_Scale", 1.0)
	post_material.set_shader_parameter("Panini", 0.0)
	post_material.set_shader_parameter("Chromatic_Peripheral", 0.18)
	post_material.set_shader_parameter("Chromatic_Aberrations", 0.22)
	post_material.set_shader_parameter("Chromatic_Darkening", 0.12)
	post_material.set_shader_parameter("Blur_Amount", 0.08)
	post_material.set_shader_parameter("Blur_Centered", 0.03)
	post_material.set_shader_parameter("Bloom_Starts", 0.86)
	post_material.set_shader_parameter("Bloom_Halation", 0.18)
	post_material.set_shader_parameter("Bloom_Booster", 0.82)
	post_material.set_shader_parameter("Shadows_Split", 0.31)
	post_material.set_shader_parameter("Highlights_Split", 0.70)
	post_material.set_shader_parameter("Shadow_Color_Temp", -16.0)
	post_material.set_shader_parameter("Shadow_Green_Tint", 2.0)
	post_material.set_shader_parameter("Shadow_Brightness", 0.93)
	post_material.set_shader_parameter("Shadow_Contrast", 1.08)
	post_material.set_shader_parameter("Shadows_Saturation", 1.10)
	post_material.set_shader_parameter("Mid_Color_Temp", -6.0)
	post_material.set_shader_parameter("Mid_Green_Tint", 0.0)
	post_material.set_shader_parameter("Mid_Brightness", 1.02)
	post_material.set_shader_parameter("Mid_Contrast", 1.08)
	post_material.set_shader_parameter("Mid_Saturation", 1.06)
	post_material.set_shader_parameter("High_Color_Temp", 15.0)
	post_material.set_shader_parameter("High_Green_Tint", -2.0)
	post_material.set_shader_parameter("High_Brightness", 1.05)
	post_material.set_shader_parameter("High_Contrast", 1.10)
	post_material.set_shader_parameter("High_Saturation", 1.12)
	post_material.set_shader_parameter("Main_Color_Temp", 4650.0)
	post_material.set_shader_parameter("Main_Green_Tint", -1.0)
	post_material.set_shader_parameter("Main_Brightness", 0.99)
	post_material.set_shader_parameter("Main_Contrast", 1.10)
	post_material.set_shader_parameter("Main_Saturation", 1.06)
	post_material.set_shader_parameter("Posterization", 0.0)
	post_material.set_shader_parameter("Vignette", 0.74)
	post_material.set_shader_parameter("Film_Grain", 0.04)
	post_material.set_shader_parameter("Filter_Strenght", 0.0)
	post_fx_rect.material = post_material

func _enhance_tilemap_texture() -> void:
	if _floor_tiles == null or _floor_tiles.tile_set == null:
		return
	var atlas := _floor_tiles.tile_set.get_source(0) as TileSetAtlasSource
	if atlas == null:
		return

	if atlas.texture is CanvasTexture:
		var existing_canvas := atlas.texture as CanvasTexture
		if existing_canvas != null:
			if existing_canvas.normal_texture != null:
				return
			atlas.texture = existing_canvas.diffuse_texture

	var diffuse_texture: Texture2D = atlas.texture
	if diffuse_texture == null:
		return
	var diffuse_image := diffuse_texture.get_image()
	if diffuse_image == null or diffuse_image.is_empty():
		return
	var normal_image := diffuse_image.duplicate()
	normal_image.bump_map_to_normal_map(3.1)
	var normal_texture := ImageTexture.create_from_image(normal_image)
	var canvas_texture := CanvasTexture.new()
	canvas_texture.diffuse_texture = diffuse_texture
	canvas_texture.normal_texture = normal_texture
	canvas_texture.resource_local_to_scene = true
	atlas.texture = canvas_texture

func _build_base_lighting(layout_id: StringName) -> void:
	var exit_center := Vector2((_exit_left + _exit_right) * 0.5, 56.0)
	var center_focus := Vector2(_room_size.x * 0.5, _room_size.y * 0.54)
	var spawn_focus := Vector2(252.0, _room_size.y * 0.56)
	var machine_focus := Vector2(402.0, _room_size.y * 0.50)

	_add_light(
		"exit_gold_light",
		exit_center + Vector2(0.0, 18.0),
		BRUNICH_PALETTE.with_alpha(BRUNICH_PALETTE.ACCENT_OBJECTIVE, 0.98),
		3.4,
		0.72,
		true,
		0.76,
		0.08,
		1.30,
		0.08
	)
	_add_light(
		"exit_cool_fill",
		exit_center + Vector2(0.0, 72.0),
		BRUNICH_PALETTE.with_alpha(BRUNICH_PALETTE.ACCENT_COLD_HOT, 0.95),
		6.2,
		0.66,
		true,
		1.25,
		0.10,
		1.05,
		0.10
	)
	_add_light(
		"center_cyan_fill",
		center_focus,
		BRUNICH_PALETTE.with_alpha(BRUNICH_PALETTE.ACCENT_COLD, 0.90),
		5.4,
		0.30,
		false,
		1.10,
		0.16,
		0.92,
		0.04
	)
	_add_light(
		"spawn_fill",
		spawn_focus,
		BRUNICH_PALETTE.with_alpha(BRUNICH_PALETTE.ACCENT_THOUGHT_SOFT, 0.88),
		4.8,
		0.38,
		false,
		0.88,
		0.33,
		0.74,
		0.05
	)
	_add_light(
		"left_machine_key",
		machine_focus,
		BRUNICH_PALETTE.with_alpha(BRUNICH_PALETTE.ACCENT_COLD_HOT, 0.90),
		3.4,
		0.26,
		false,
		0.66,
		0.18,
		0.82,
		0.03
	)
	_add_light(
		"side_left_rim",
		Vector2(132.0, 316.0),
		BRUNICH_PALETTE.with_alpha(BRUNICH_PALETTE.ACCENT_COLD_DIM, 0.88),
		3.8,
		0.24,
		false,
		0.72,
		0.55,
		0.80,
		0.04
	)
	_add_light(
		"side_right_rim",
		Vector2(_room_size.x - 132.0, 316.0),
		BRUNICH_PALETTE.with_alpha(BRUNICH_PALETTE.ACCENT_COLD_DIM, 0.88),
		3.8,
		0.24,
		false,
		0.72,
		0.92,
		0.80,
		0.04
	)

	_player_key_light = _add_light(
		"player_key_light",
		spawn_focus,
		BRUNICH_PALETTE.with_alpha(BRUNICH_PALETTE.HERO_PROJECTILE_CODE, 0.92),
		2.5,
		0.26,
		false,
		0.54,
		0.0,
		0.85,
		0.03
	)

	match layout_id:
		&"split_bridge":
			_add_light("bridge_rim_top", Vector2(_room_size.x * 0.5, 170.0), BRUNICH_PALETTE.with_alpha(BRUNICH_PALETTE.ACCENT_COLD_HOT, 0.90), 3.2, 0.28, false, 0.62, 0.10, 0.94, 0.03)
			_add_light("bridge_rim_bottom", Vector2(_room_size.x * 0.5, _room_size.y - 170.0), BRUNICH_PALETTE.with_alpha(BRUNICH_PALETTE.ACCENT_COLD_HOT, 0.90), 3.2, 0.28, false, 0.62, 0.40, 0.94, 0.03)
		&"rib_cage":
			_add_light("rib_left_core", Vector2(380.0, _room_size.y * 0.5), BRUNICH_PALETTE.with_alpha(BRUNICH_PALETTE.ACCENT_OBJECTIVE_SOFT, 0.90), 3.0, 0.22, false, 0.54, 0.2, 0.88, 0.02)
			_add_light("rib_right_core", Vector2(_room_size.x - 380.0, _room_size.y * 0.5), BRUNICH_PALETTE.with_alpha(BRUNICH_PALETTE.ACCENT_OBJECTIVE_SOFT, 0.90), 3.0, 0.22, false, 0.54, 0.7, 0.88, 0.02)
		&"reactor_spine":
			_add_light("reactor_core", Vector2(_room_size.x * 0.5, _room_size.y * 0.5), BRUNICH_PALETTE.with_alpha(BRUNICH_PALETTE.ACCENT_OBJECTIVE, 0.94), 2.9, 0.34, false, 0.70, 0.2, 1.24, 0.04)

func _build_atmosphere_shafts(layout_id: StringName) -> void:
	var exit_center := Vector2((_exit_left + _exit_right) * 0.5, 10.0)
	var center_focus := Vector2(_room_size.x * 0.53, _room_size.y * 0.63)
	var left_beam_target := Vector2(238.0, _room_size.y * 0.74)

	_add_shaft(
		"main_cool_shaft",
		exit_center + Vector2(118.0, -18.0),
		center_focus + Vector2(74.0, -28.0),
		84.0,
		170.0,
		BRUNICH_PALETTE.with_alpha(BRUNICH_PALETTE.ACCENT_COLD_HOT, 0.08),
		0.66,
		0.0
	)
	_add_shaft(
		"objective_shaft",
		exit_center + Vector2(0.0, -26.0),
		Vector2((_exit_left + _exit_right) * 0.5, 146.0),
		44.0,
		96.0,
		BRUNICH_PALETTE.with_alpha(BRUNICH_PALETTE.ACCENT_COLD, 0.05),
		0.54,
		0.8
	)
	_add_shaft(
		"spawn_side_haze",
		Vector2(-40.0, 248.0),
		left_beam_target,
		210.0,
		320.0,
		BRUNICH_PALETTE.with_alpha(BRUNICH_PALETTE.ACCENT_THOUGHT_SOFT, 0.06),
		0.58,
		1.7
	)

	if layout_id == &"reactor_spine":
		_add_shaft(
			"reactor_cool_shaft",
			Vector2(_room_size.x * 0.5 + 96.0, 54.0),
			Vector2(_room_size.x * 0.5 + 84.0, _room_size.y * 0.5),
			120.0,
			250.0,
			BRUNICH_PALETTE.with_alpha(BRUNICH_PALETTE.ACCENT_COLD, 0.14),
			0.86,
			2.2
		)

func _build_occluders() -> void:
	_add_occluder_rect("left_service_occluder", Rect2(72.0, 126.0, 180.0, 342.0))
	_add_occluder_rect("right_service_occluder", Rect2(_room_size.x - 252.0, 126.0, 180.0, 342.0))
	_add_occluder_rect("center_plate_occluder", Rect2(_room_size.x * 0.5 - 188.0, _room_size.y * 0.5 - 44.0, 376.0, 112.0))
	_add_occluder_rect("exit_frame_occluder", Rect2(_exit_left - 24.0, 0.0, (_exit_right - _exit_left) + 48.0, 92.0))

func _add_light(name_text: String, position: Vector2, color: Color, scale_value: float, energy_value: float, cast_shadow: bool, height_value: float, phase: float, speed: float, amplitude: float) -> PointLight2D:
	var light := PointLight2D.new()
	light.name = name_text
	light.position = position
	light.texture = _make_light_texture()
	light.texture_scale = scale_value
	light.color = color
	light.energy = energy_value
	light.height = height_value
	light.shadow_enabled = cast_shadow
	light.shadow_filter = Light2D.SHADOW_FILTER_PCF5
	lighting_root.add_child(light)
	_runtime_tracks.append({
		"node": light,
		"base_energy": energy_value,
		"phase": phase,
		"speed": speed,
		"amplitude": amplitude,
	})
	return light

func _add_shaft(name_text: String, from_pos: Vector2, to_pos: Vector2, from_width: float, to_width: float, color: Color, intensity: float, phase: float) -> void:
	var polygon := Polygon2D.new()
	polygon.name = name_text
	polygon.polygon = _make_beam_quad(from_pos, to_pos, from_width, to_width)
	polygon.uv = PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(1.0, 0.0),
		Vector2(1.0, 1.0),
		Vector2(0.0, 1.0),
	])
	polygon.color = Color.WHITE
	var material := ShaderMaterial.new()
	material.shader = BEAM_SHADER
	material.set_shader_parameter("noise_tex", NOISE_TEXTURE)
	material.set_shader_parameter("beam_color", color)
	material.set_shader_parameter("intensity", intensity)
	material.set_shader_parameter("scroll_speed", 0.05 + phase * 0.02)
	material.set_shader_parameter("drift_strength", 0.12)
	material.set_shader_parameter("edge_softness", 2.4)
	material.set_shader_parameter("pulse_speed", 0.32 + phase * 0.1)
	material.set_shader_parameter("breakup", 0.38)
	polygon.material = material
	polygon.modulate = Color(1.0, 1.0, 1.0, 1.0)
	shaft_root.add_child(polygon)
	_runtime_tracks.append({
		"node": polygon,
		"base_alpha": 1.0,
		"phase": phase,
		"speed": 0.55,
		"amplitude": 0.05,
	})

func _add_occluder_rect(name_text: String, rect: Rect2) -> void:
	var occluder := LightOccluder2D.new()
	occluder.name = name_text
	var polygon := OccluderPolygon2D.new()
	polygon.polygon = PackedVector2Array([
		rect.position,
		rect.position + Vector2(rect.size.x, 0.0),
		rect.position + rect.size,
		rect.position + Vector2(0.0, rect.size.y),
	])
	occluder.occluder = polygon
	occluder_root.add_child(occluder)

func _make_light_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CUBIC
	gradient.offsets = PackedFloat32Array([0.0, 0.20, 0.52, 1.0])
	gradient.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 1.0),
		Color(1.0, 1.0, 1.0, 0.92),
		Color(0.92, 0.92, 0.92, 0.28),
		Color(0.0, 0.0, 0.0, 0.0),
	])

	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 256
	texture.height = 256
	texture.use_hdr = true
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	return texture

func _make_beam_quad(from_pos: Vector2, to_pos: Vector2, from_width: float, to_width: float) -> PackedVector2Array:
	var direction := (to_pos - from_pos).normalized()
	var perpendicular := direction.orthogonal()
	return PackedVector2Array([
		from_pos - perpendicular * (from_width * 0.5),
		from_pos + perpendicular * (from_width * 0.5),
		to_pos + perpendicular * (to_width * 0.5),
		to_pos - perpendicular * (to_width * 0.5),
	])

func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()
