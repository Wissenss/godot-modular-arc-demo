## room_decor.gd
## Depth-decoration layer for Brunich rooms.
## Uses Beta2 props (3D-look sci-fi objects) + pipe tile overlays
## to give each room visual depth beyond just the tilemap.
##
## Usage:
##   var decor: Node2D = preload("room_decor.gd").new()
##   add_child(decor)
##   decor.setup(&"classic", Vector2(1280, 640), 544.0, 736.0)
extends Node2D

const DECOR_PATH := "res://art/decor/"
const BG_KEY_THRESHOLD := 0.055

## Shared additive-blend material (reused by all glow sprites)
var _add_mat: CanvasItemMaterial
## Texture cache so we load each PNG only once per session
var _tex_cache: Dictionary = {}

# ── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	_add_mat = CanvasItemMaterial.new()
	_add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD

## Remove all current decoration sprites.
func clear_decor() -> void:
	for child in get_children():
		child.queue_free()

## Rebuild decoration for a given layout and room size.
func setup(layout_id: StringName, room_size: Vector2,
		exit_l: float, exit_r: float) -> void:
	clear_decor()
	match layout_id:
		&"classic":
			_decorate_classic(room_size, exit_l, exit_r)
		&"rib_cage":
			_decorate_rib_cage(room_size, exit_l, exit_r)
		&"split_bridge":
			_decorate_split_bridge(room_size, exit_l, exit_r)
		&"reactor_spine":
			_decorate_reactor_spine(room_size, exit_l, exit_r)
		# Megacore (5× room) — minimal decoration for now
		&"megacore":
			_decorate_megacore(room_size, exit_l, exit_r)

# ── Layout decorators ─────────────────────────────────────────────────────────

func _decorate_classic(rs: Vector2, el: float, er: float) -> void:
	var cx := rs.x * 0.5
	var cy := rs.y * 0.5
	var exit_cx := (el + er) * 0.5

	# ── 1. Pipe/conduit overlay on the floor (ADD blend, subtle) ──────────
	_pipe_field_classic(rs, cx, cy)

	# ── 2. Physical objects (normal blend, transparent PNG bg) ────────────
	# Terminals in the spawn lanes (left / right)
	_prop("terminal_a", Vector2(220.0, cy + 14.0), 0.48, false, -1)
	_prop("terminal_a", Vector2(rs.x - 220.0, cy + 14.0), 0.48, false, -1)
	# Tech altars near spawn-lane corners (give depth to upper flanks)
	_prop("altar", Vector2(232.0, cy - 78.0), 0.40, false, -1)
	_prop("altar", Vector2(rs.x - 232.0, cy - 78.0), 0.40, false, -1)

	# ── 3. Glow / energy objects (ADD blend) ───────────────────────────────
	# Hologram pillars at the central structural ribs (col 12 = 384px, col 27 = 864px)
	_prop("pillar", Vector2(384.0, cy + 6.0), 0.60, true, 0)
	_prop("pillar", Vector2(864.0, cy + 6.0), 0.60, true, 0)
	# Central energy orb — dead-center, the "heart" of the room
	_prop("orb", Vector2(cx, cy - 6.0), 0.70, true, 2)
	# Exit-portal glow directly below the exit opening
	_prop("portal_circ", Vector2(exit_cx, 60.0), 0.52, true, 1)

func _pipe_field_classic(rs: Vector2, cx: float, cy: float) -> void:
	# Glowing pipe crosses scattered across the play area (floor depth layer)
	var positions: Array[Vector2] = [
		Vector2(cx,        cy),
		Vector2(cx - 192,  cy),
		Vector2(cx + 192,  cy),
		Vector2(cx,        cy - 96),
		Vector2(cx,        cy + 96),
		Vector2(cx - 352,  cy),
		Vector2(cx + 352,  cy),
	]
	for pos in positions:
		_pipe_sprite("pipe_cross_glow", pos, 0.24, Color(0.20, 0.70, 1.00, 0.20))

func _decorate_rib_cage(rs: Vector2, el: float, er: float) -> void:
	var cx := rs.x * 0.5
	var cy := rs.y * 0.5
	# Symmetrical side bays → one orb per bay, terminals along the ribs
	_pipe_field_classic(rs, cx, cy)  # reuse pipe field
	_prop("orb",      Vector2(cx, cy - 4.0),          0.65, true,  2)
	_prop("pillar",   Vector2(cx * 0.56, cy),          0.55, true,  0)
	_prop("pillar",   Vector2(cx * 1.44, cy),          0.55, true,  0)
	_prop("terminal_a", Vector2(cx * 0.20, cy + 12.0), 0.44, false, -1)
	_prop("terminal_a", Vector2(cx * 1.80, cy + 12.0), 0.44, false, -1)
	_prop("portal_circ", Vector2((el + er) * 0.5, 60.0), 0.50, true, 1)

func _decorate_split_bridge(rs: Vector2, el: float, er: float) -> void:
	var cx := rs.x * 0.5
	var cy := rs.y * 0.5
	_pipe_field_classic(rs, cx, cy)
	# Central bridge has the orb; flanks have generators
	_prop("orb",       Vector2(cx, cy - 4.0),           0.68, true,  2)
	_prop("generator", Vector2(cx * 0.25, cy + 8.0),    0.40, false, -1)
	_prop("generator", Vector2(cx * 1.75, cy + 8.0),    0.40, false, -1)
	_prop("diamond_energy", Vector2(cx * 0.50, cy * 0.55), 0.40, true, 1)
	_prop("diamond_energy", Vector2(cx * 1.50, cy * 0.55), 0.40, true, 1)
	_prop("portal_circ",    Vector2((el + er) * 0.5, 60.0), 0.50, true, 1)

func _decorate_reactor_spine(rs: Vector2, el: float, er: float) -> void:
	var cx := rs.x * 0.5
	var cy := rs.y * 0.5
	_pipe_field_classic(rs, cx, cy)
	# Spine → two vertical pillars flanking center; corner pits have diamonds
	_prop("orb",     Vector2(cx, cy - 4.0),             0.70, true,  2)
	_prop("pillar",  Vector2(cx - 96.0, cy + 4.0),      0.55, true,  0)
	_prop("pillar",  Vector2(cx + 96.0, cy + 4.0),      0.55, true,  0)
	_prop("diamond_energy", Vector2(rs.x * 0.14, rs.y * 0.28), 0.38, true, 1)
	_prop("diamond_energy", Vector2(rs.x * 0.86, rs.y * 0.28), 0.38, true, 1)
	_prop("diamond_energy", Vector2(rs.x * 0.14, rs.y * 0.72), 0.38, true, 1)
	_prop("diamond_energy", Vector2(rs.x * 0.86, rs.y * 0.72), 0.38, true, 1)
	_prop("portal_circ",    Vector2((el + er) * 0.5, 60.0),    0.50, true, 1)

func _decorate_megacore(rs: Vector2, el: float, er: float) -> void:
	# 5× room — minimal but coherent decoration: orb at center, portals at zones
	var cx := rs.x * 0.5
	var cy := rs.y * 0.5
	_prop("orb",          Vector2(cx, cy - 8.0),               0.90, true,  2)
	_prop("portal_circ",  Vector2((el + er) * 0.5, 80.0),      0.70, true,  1)
	# 4 quadrant portals
	_prop("pillar",       Vector2(cx * 0.50, cy * 0.56),        0.70, true,  0)
	_prop("pillar",       Vector2(cx * 1.50, cy * 0.56),        0.70, true,  0)
	_prop("pillar",       Vector2(cx * 0.50, cy * 1.44),        0.70, true,  0)
	_prop("pillar",       Vector2(cx * 1.50, cy * 1.44),        0.70, true,  0)
	# Diamonds at spawn zones
	_prop("diamond_energy", Vector2(cx * 0.25, cy),             0.55, true,  1)
	_prop("diamond_energy", Vector2(cx * 1.75, cy),             0.55, true,  1)
	# Terminals scattered
	_prop("terminal_a",   Vector2(cx * 0.14, cy + 20.0),        0.55, false, -1)
	_prop("terminal_a",   Vector2(cx * 1.86, cy + 20.0),        0.55, false, -1)
	# Pipe crosses spread across the large room
	for xi in range(5):
		for yi in range(3):
			var px := rs.x * (0.15 + xi * 0.175)
			var py := rs.y * (0.22 + yi * 0.28)
			_pipe_sprite("pipe_cross_glow", Vector2(px, py), 0.32,
					Color(0.20, 0.70, 1.00, 0.20))

# ── Primitive helpers ─────────────────────────────────────────────────────────

## Place a named prop sprite.
func _prop(name: String, pos: Vector2, scale_f: float,
		additive: bool, z_idx: int = 0) -> void:
	var tex := _load_tex(name)
	if tex == null:
		return
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.position = pos
	sprite.scale = Vector2.ONE * scale_f
	sprite.z_index = z_idx
	if additive:
		sprite.material = _add_mat
	add_child(sprite)

## Place a pipe-tile sprite (always ADD blend).
func _pipe_sprite(name: String, pos: Vector2, scale_f: float,
		tint: Color) -> void:
	var tex := _load_tex(name)
	if tex == null:
		return
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.position = pos
	sprite.scale = Vector2.ONE * scale_f
	sprite.z_index = -3
	sprite.material = _add_mat
	sprite.modulate = tint
	add_child(sprite)

## Load a texture from the decor folder, with in-memory cache.
func _load_tex(name: String) -> ImageTexture:
	if _tex_cache.has(name):
		return _tex_cache[name]
	var path := ProjectSettings.globalize_path(DECOR_PATH + name + ".png")
	var img := Image.load_from_file(path)
	if img == null:
		push_warning("room_decor: could not load " + path)
		_tex_cache[name] = null
		return null
	var processed := _remove_flat_background(img)
	var tex := ImageTexture.create_from_image(processed)
	_tex_cache[name] = tex
	return tex

func _remove_flat_background(source: Image) -> Image:
	var image := source.duplicate()
	image.convert(Image.FORMAT_RGBA8)

	var width: int = image.get_width()
	var height: int = image.get_height()
	if width <= 0 or height <= 0:
		return image

	var key_color: Color = _average_corner_color(image)
	var visited := PackedByteArray()
	visited.resize(width * height)
	var pending: Array[Vector2i] = []

	for x in range(width):
		_enqueue_bg_pixel(image, pending, visited, Vector2i(x, 0), key_color, width, height)
		_enqueue_bg_pixel(image, pending, visited, Vector2i(x, height - 1), key_color, width, height)
	for y in range(height):
		_enqueue_bg_pixel(image, pending, visited, Vector2i(0, y), key_color, width, height)
		_enqueue_bg_pixel(image, pending, visited, Vector2i(width - 1, y), key_color, width, height)

	while not pending.is_empty():
		var point: Vector2i = pending.pop_back()
		var pixel: Color = image.get_pixelv(point)
		image.set_pixelv(point, Color(pixel.r, pixel.g, pixel.b, 0.0))
		_enqueue_bg_pixel(image, pending, visited, point + Vector2i.LEFT, key_color, width, height)
		_enqueue_bg_pixel(image, pending, visited, point + Vector2i.RIGHT, key_color, width, height)
		_enqueue_bg_pixel(image, pending, visited, point + Vector2i.UP, key_color, width, height)
		_enqueue_bg_pixel(image, pending, visited, point + Vector2i.DOWN, key_color, width, height)
	return image

func _average_corner_color(image: Image) -> Color:
	var width: int = image.get_width()
	var height: int = image.get_height()
	var samples := [
		image.get_pixel(0, 0),
		image.get_pixel(width - 1, 0),
		image.get_pixel(0, height - 1),
		image.get_pixel(width - 1, height - 1),
	]
	var accum := Color(0.0, 0.0, 0.0, 0.0)
	for sample in samples:
		accum += sample
	return accum / float(samples.size())

func _enqueue_bg_pixel(
		image: Image,
		pending: Array[Vector2i],
		visited: PackedByteArray,
		point: Vector2i,
		key_color: Color,
		width: int,
		height: int
) -> void:
	if point.x < 0 or point.y < 0 or point.x >= width or point.y >= height:
		return
	var index := point.y * width + point.x
	if visited[index] != 0:
		return
	visited[index] = 1
	var pixel: Color = image.get_pixelv(point)
	if pixel.a <= 0.0:
		return
	if _background_delta(pixel, key_color) > BG_KEY_THRESHOLD:
		return
	pending.append(point)

func _background_delta(pixel: Color, key_color: Color) -> float:
	return maxf(
		maxf(absf(pixel.r - key_color.r), absf(pixel.g - key_color.g)),
		absf(pixel.b - key_color.b)
	)
