## Brunich arena generator.
## Builds a focused 32x32 atlas from the UpDown sheet and paints the approved
## industrial-sunken layout with a clear top exit.
extends TileMapLayer
const BRUNICH_PALETTE := preload("res://scenes/tests/Brunich/brunich_palette.gd")

var COLS := 40
var ROWS := 20
const TILE_SIZE := 32

var EXIT_START := 17
var EXIT_END := 22
const EXIT_WIDTH_TILES := 6
const WALL_THICKNESS := 32.0

const ATLAS_PATH := "res://art/generated/brunich/brunich_updown_atlas.png"

const T_FLOOR_PLAIN := Vector2i(0, 0)
const T_FLOOR_PANEL := Vector2i(1, 0)
const T_FLOOR_GRID := Vector2i(2, 0)
const T_PIT_DEEP := Vector2i(3, 0)
const T_WALL_BEVEL := Vector2i(0, 1)
const T_PANEL_GOLD := Vector2i(1, 1)
const T_DOOR_HATCH := Vector2i(2, 1)
const T_NEON_STRIP := Vector2i(3, 1)
const INVALID_TILE := Vector2i(-1, -1)

const LAYOUT_CLASSIC: StringName = &"classic"
const LAYOUT_RIB_CAGE: StringName = &"rib_cage"
const LAYOUT_SPLIT_BRIDGE: StringName = &"split_bridge"
const LAYOUT_REACTOR_SPINE: StringName = &"reactor_spine"
const LAYOUT_MEGACORE: StringName = &"megacore"
const LAYOUT_IDS := [
	LAYOUT_CLASSIC,
	LAYOUT_RIB_CAGE,
	LAYOUT_SPLIT_BRIDGE,
	LAYOUT_REACTOR_SPINE,
]
const LAYOUT_IDS_LARGE := [
	LAYOUT_MEGACORE,
]

var CurrentLayoutId: StringName = LAYOUT_CLASSIC

func _ready() -> void:
	tile_set = _build_tileset()
	_refresh_room()

func _build_tileset() -> TileSet:
	var image := Image.load_from_file(ProjectSettings.globalize_path(ATLAS_PATH))
	var tex := ImageTexture.create_from_image(image)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = tex
	atlas.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)

	for row in range(2):
		for col in range(4):
			atlas.create_tile(Vector2i(col, row))

	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	ts.add_source(atlas, 0)
	return ts

func get_layout_id() -> StringName:
	return CurrentLayoutId

func get_layout_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	if COLS > 40:
		for id in LAYOUT_IDS_LARGE:
			ids.append(id)
	else:
		for id in LAYOUT_IDS:
			ids.append(id)
	return ids

func set_layout_id(layout_id: StringName) -> void:
	var resolved_layout := layout_id
	var valid_ids := get_layout_ids()
	if not valid_ids.has(resolved_layout):
		resolved_layout = valid_ids[0] if not valid_ids.is_empty() else LAYOUT_CLASSIC
	if CurrentLayoutId == resolved_layout and get_used_cells().size() > 0:
		return
	CurrentLayoutId = resolved_layout
	if is_inside_tree():
		_refresh_room()

## ── Dimension API ────────────────────────────────────────────────────────────

func set_dimensions(cols: int, rows: int) -> void:
	COLS = cols
	ROWS = rows
	var mid := COLS / 2
	EXIT_START = mid - EXIT_WIDTH_TILES / 2
	EXIT_END   = mid + EXIT_WIDTH_TILES / 2 - 1
	if is_inside_tree():
		tile_set = _build_tileset()
		_refresh_room()

func reset_to_default_dimensions() -> void:
	set_dimensions(40, 20)

func get_room_pixel_size() -> Vector2:
	return Vector2(float(COLS * TILE_SIZE), float(ROWS * TILE_SIZE))

func get_exit_start_px() -> float:
	return float(EXIT_START * TILE_SIZE)

func get_exit_end_px() -> float:
	return float((EXIT_END + 1) * TILE_SIZE)

func _refresh_room() -> void:
	_generate()
	_tint_backdrop()
	_ensure_arena_bounds()

func _generate() -> void:
	clear()
	for row in range(ROWS):
		for col in range(COLS):
			var atlas_coords := _pick(col, row)
			if atlas_coords == INVALID_TILE:
				erase_cell(Vector2i(col, row))
				continue
			set_cell(Vector2i(col, row), 0, atlas_coords)

func _pick(col: int, row: int) -> Vector2i:
	if _is_exit_void(col, row):
		return INVALID_TILE

	if row == 0 or row == ROWS - 1 or col == 0 or col == COLS - 1:
		return _pick_border(col, row)

	if _is_exit_threshold(col, row):
		return T_DOOR_HATCH

	if _is_exit_signal(col, row):
		return T_NEON_STRIP

	if _is_exit_frame(col, row):
		return T_PANEL_GOLD

	match CurrentLayoutId:
		LAYOUT_MEGACORE:
			return _pick_megacore(col, row)
		LAYOUT_RIB_CAGE:
			return _pick_rib_cage(col, row)
		LAYOUT_SPLIT_BRIDGE:
			return _pick_split_bridge(col, row)
		LAYOUT_REACTOR_SPINE:
			return _pick_reactor_spine(col, row)
		_:
			return _pick_classic(col, row)

func _pick_classic(col: int, row: int) -> Vector2i:
	if _is_sunken_corner(col, row):
		return T_PIT_DEEP

	if _is_central_rib(col, row):
		return T_WALL_BEVEL

	if _is_core_platform(col, row):
		return T_PANEL_GOLD

	if _is_spawn_lane(col, row):
		return T_FLOOR_PLAIN

	if _is_mechanical_spine(col, row):
		return T_FLOOR_PANEL

	return _pick_floor_variant(col, row)

func _pick_rib_cage(col: int, row: int) -> Vector2i:
	if _matches_rect(col, row, 4, 9, 6, 13) or _matches_rect(col, row, 30, 35, 6, 13):
		return T_PIT_DEEP

	if ((col == 14) or (col == 25)) and row >= 5 and row <= 14:
		return T_WALL_BEVEL

	if (row == 6 or row == 13) and col >= 17 and col <= 22:
		return T_NEON_STRIP

	if ((row >= 8 and row <= 11 and col >= 17 and col <= 22)
		or ((row == 9 or row == 10) and (col == 16 or col == 23))):
		return T_PANEL_GOLD

	if (row == 5 or row == 14) and col >= 15 and col <= 24:
		return T_FLOOR_PANEL

	if (((col >= 11 and col <= 13) or (col >= 26 and col <= 28)) and row >= 7 and row <= 12):
		return T_FLOOR_GRID

	return _pick_floor_variant(col, row)

func _pick_split_bridge(col: int, row: int) -> Vector2i:
	if _matches_rect(col, row, 6, 14, 7, 12) or _matches_rect(col, row, 25, 33, 7, 12):
		return T_PIT_DEEP

	if (col == 15 or col == 24) and row >= 6 and row <= 13:
		return T_WALL_BEVEL

	if (row == 8 or row == 11) and col >= 16 and col <= 23:
		return T_NEON_STRIP

	if row >= 9 and row <= 10 and col >= 16 and col <= 23:
		return T_PANEL_GOLD

	if (col == 17 or col == 22) and ((row >= 6 and row <= 7) or (row >= 12 and row <= 13)):
		return T_DOOR_HATCH

	return _pick_floor_variant(col, row)

func _pick_reactor_spine(col: int, row: int) -> Vector2i:
	if _matches_rect(col, row, 4, 7, 4, 7) or _matches_rect(col, row, 32, 35, 4, 7):
		return T_PIT_DEEP
	if _matches_rect(col, row, 4, 7, 12, 15) or _matches_rect(col, row, 32, 35, 12, 15):
		return T_PIT_DEEP

	if (col == 17 or col == 22) and row >= 5 and row <= 14:
		return T_NEON_STRIP

	if col >= 18 and col <= 21 and row >= 6 and row <= 13:
		return T_PANEL_GOLD

	if (row == 6 or row == 13) and col >= 14 and col <= 25:
		return T_FLOOR_PANEL

	if (col == 15 or col == 24) and row >= 7 and row <= 12:
		return T_WALL_BEVEL

	if (row == 9 or row == 10) and (col == 16 or col == 23):
		return T_DOOR_HATCH

	return _pick_floor_variant(col, row)

## ── MEGACORE: versión 5× del Classic (para cuartos 200×100) ─────────────────

func _pick_megacore(col: int, row: int) -> Vector2i:
	if _is_mega_sunken_corner(col, row):
		return T_PIT_DEEP
	if _is_mega_central_rib(col, row):
		return T_WALL_BEVEL
	if _is_mega_core_platform(col, row):
		return T_PANEL_GOLD
	if _is_mega_spawn_lane(col, row):
		return T_FLOOR_PLAIN
	if _is_mega_mechanical_spine(col, row):
		return T_FLOOR_PANEL
	return _pick_floor_variant_mega(col, row)

# Esquinas hundidas escaladas 5× (original: 4-6 y 33-35 / 4-6 y 13-15)
func _is_mega_sunken_corner(col: int, row: int) -> bool:
	return (_matches_rect(col, row, 20, 30, 20, 30))  \
		or (_matches_rect(col, row, 165, 175, 20, 30)) \
		or (_matches_rect(col, row, 20, 30, 65, 75))   \
		or (_matches_rect(col, row, 165, 175, 65, 75))

# Costillas centrales 5× (original: col 12 y 27, rows 7-12)
func _is_mega_central_rib(col: int, row: int) -> bool:
	return (col == 60 or col == 135) and row >= 35 and row <= 60

# Plataforma central 5× (original: rows 8-11 cols 16-23, plus bordes)
func _is_mega_core_platform(col: int, row: int) -> bool:
	return (_matches_rect(col, row, 80, 115, 40, 55)) \
		or (((row == 45) or (row == 50)) and (col == 75 or col == 120))

# Carriles de spawn 5× (original: cols 2-10 y 29-37, rows 7-12)
func _is_mega_spawn_lane(col: int, row: int) -> bool:
	return (_matches_rect(col, row, 10, 50, 35, 60)) \
		or (_matches_rect(col, row, 145, 185, 35, 60))

# Columna vertebral mecánica 5× (original: rows 5 y 14, cols 11-28)
func _is_mega_mechanical_spine(col: int, row: int) -> bool:
	return (row == 25 or row == 70) and col >= 55 and col <= 140

# Variante de suelo para el cuarto grande
func _pick_floor_variant_mega(col: int, row: int) -> Vector2i:
	# Pasillo hacia la salida (escala 5×: rows 15-60, cols 90-105)
	if row >= 15 and row <= 60 and col >= 90 and col <= 105:
		return T_FLOOR_GRID if row % 2 == 0 else T_FLOOR_PANEL
	# Banda central de enfoque (escala 5×: rows 40-55, cols 65-130)
	if row >= 40 and row <= 55 and col >= 65 and col <= 130:
		return T_FLOOR_PANEL if (col + row) % 2 == 0 else T_FLOOR_GRID
	# Carriles de servicio laterales (escala 5×: cols 30-40 y 155-165, rows 20-75)
	if ((col >= 30 and col <= 40) or (col >= 155 and col <= 165)) and row >= 20 and row <= 75:
		return T_FLOOR_PANEL if row % 3 == 0 else T_FLOOR_PLAIN
	# Zona central de cuadrícula (escala 5×: cols 50-145, rows 25-70)
	if col >= 50 and col <= 145 and row >= 25 and row <= 70:
		return T_FLOOR_GRID if (col + row) % 2 == 0 else T_FLOOR_PANEL
	if (col + row) % 5 == 0:
		return T_FLOOR_PANEL
	return T_FLOOR_PLAIN

func _pick_border(col: int, row: int) -> Vector2i:
	if row == 0 and col >= EXIT_START - 1 and col <= EXIT_END + 1:
		return T_PANEL_GOLD
	if row == 0 or row == ROWS - 1:
		return T_WALL_BEVEL if col % 2 == 0 else T_NEON_STRIP
	return T_WALL_BEVEL

func _pick_floor_variant(col: int, row: int) -> Vector2i:
	if _is_exit_runway(col, row):
		return T_FLOOR_GRID if row % 2 == 0 else T_FLOOR_PANEL
	if _is_center_focus_band(col, row):
		return T_FLOOR_PANEL if (col + row) % 2 == 0 else T_FLOOR_GRID
	if _is_side_service_lane(col, row):
		return T_FLOOR_PANEL if row % 3 == 0 else T_FLOOR_PLAIN
	if col >= 10 and col <= 29 and row >= 5 and row <= 14:
		return T_FLOOR_GRID if (col + row) % 2 == 0 else T_FLOOR_PANEL
	if (col + row) % 5 == 0:
		return T_FLOOR_PANEL
	return T_FLOOR_PLAIN

func _is_exit_runway(col: int, row: int) -> bool:
	return row >= 3 and row <= 12 and col >= 18 and col <= 21

func _is_center_focus_band(col: int, row: int) -> bool:
	return row >= 8 and row <= 11 and col >= 13 and col <= 26

func _is_side_service_lane(col: int, row: int) -> bool:
	return (((col >= 6 and col <= 8) or (col >= 31 and col <= 33)) and row >= 4 and row <= 15)

func _is_exit_void(col: int, row: int) -> bool:
	return row == 0 and col >= EXIT_START and col <= EXIT_END

func _is_exit_threshold(col: int, row: int) -> bool:
	return row == 1 and col >= EXIT_START and col <= EXIT_END

func _is_exit_signal(col: int, row: int) -> bool:
	return row == 2 and col >= EXIT_START + 1 and col <= EXIT_END - 1

func _is_exit_frame(col: int, row: int) -> bool:
	return (col == EXIT_START - 1 or col == EXIT_END + 1) and row >= 1 and row <= 4

func _is_sunken_corner(col: int, row: int) -> bool:
	return (col >= 4 and col <= 6 and row >= 4 and row <= 6) \
		or (col >= 33 and col <= 35 and row >= 4 and row <= 6) \
		or (col >= 4 and col <= 6 and row >= 13 and row <= 15) \
		or (col >= 33 and col <= 35 and row >= 13 and row <= 15)

func _is_central_rib(col: int, row: int) -> bool:
	return (col == 12 or col == 27) and row >= 7 and row <= 12

func _is_core_platform(col: int, row: int) -> bool:
	return (row >= 8 and row <= 11 and col >= 16 and col <= 23) \
		or (row == 9 or row == 10) and (col == 15 or col == 24)

func _is_spawn_lane(col: int, row: int) -> bool:
	return (col >= 2 and col <= 10 and row >= 7 and row <= 12) \
		or (col >= 29 and col <= 37 and row >= 7 and row <= 12)

func _is_mechanical_spine(col: int, row: int) -> bool:
	return (row == 5 or row == 14) and col >= 11 and col <= 28

func _matches_rect(col: int, row: int, left: int, right: int, top: int, bottom: int) -> bool:
	return col >= left and col <= right and row >= top and row <= bottom

func _tint_backdrop() -> void:
	if get_parent() == null:
		return
	var backdrop := get_parent().get_node_or_null("void_bg") as Polygon2D
	if backdrop != null:
		backdrop.color = BRUNICH_PALETTE.VOID_BG

func _ensure_arena_bounds() -> void:
	if get_parent() == null:
		return

	var bounds := get_parent().get_node_or_null("arena_bounds") as StaticBody2D
	if bounds == null:
		return

	for child in bounds.get_children():
		child.queue_free()

	var world_width := float(COLS * TILE_SIZE)
	var world_height := float(ROWS * TILE_SIZE)
	var opening_width := float((EXIT_END - EXIT_START + 1) * TILE_SIZE)
	var side_width := (world_width - opening_width) * 0.5

	_add_rect_collision(bounds, "left_wall", Vector2(-WALL_THICKNESS * 0.5, world_height * 0.5), Vector2(WALL_THICKNESS, world_height))
	_add_rect_collision(bounds, "right_wall", Vector2(world_width + WALL_THICKNESS * 0.5, world_height * 0.5), Vector2(WALL_THICKNESS, world_height))
	_add_rect_collision(bounds, "bottom_wall", Vector2(world_width * 0.5, world_height + WALL_THICKNESS * 0.5), Vector2(world_width, WALL_THICKNESS))
	_add_rect_collision(bounds, "top_left_wall", Vector2(side_width * 0.5, -WALL_THICKNESS * 0.5), Vector2(side_width, WALL_THICKNESS))
	_add_rect_collision(bounds, "top_right_wall", Vector2(world_width - side_width * 0.5, -WALL_THICKNESS * 0.5), Vector2(side_width, WALL_THICKNESS))
	_add_rect_collision(bounds, "exit_jamb_left", Vector2(float(EXIT_START * TILE_SIZE) - WALL_THICKNESS * 0.5, 64.0), Vector2(WALL_THICKNESS, 128.0))
	_add_rect_collision(bounds, "exit_jamb_right", Vector2(float((EXIT_END + 1) * TILE_SIZE) + WALL_THICKNESS * 0.5, 64.0), Vector2(WALL_THICKNESS, 128.0))

func _add_rect_collision(parent: StaticBody2D, name: String, pos: Vector2, size: Vector2) -> void:
	var collision := CollisionShape2D.new()
	collision.name = name
	collision.position = pos

	var rect := RectangleShape2D.new()
	rect.size = size
	collision.shape = rect
	parent.add_child(collision)
