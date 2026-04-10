## Brunich arena generator.
## Builds a focused 32x32 atlas from the UpDown sheet and paints the approved
## industrial-sunken layout with a clear top exit.
extends TileMapLayer

const COLS := 40
const ROWS := 20
const TILE_SIZE := 32

const EXIT_START := 17
const EXIT_END := 22
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
const LAYOUT_IDS := [
	LAYOUT_CLASSIC,
	LAYOUT_RIB_CAGE,
	LAYOUT_SPLIT_BRIDGE,
	LAYOUT_REACTOR_SPINE,
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
	var layout_ids: Array[StringName] = []
	for layout_id in LAYOUT_IDS:
		layout_ids.append(layout_id)
	return layout_ids

func set_layout_id(layout_id: StringName) -> void:
	var resolved_layout := layout_id
	if not LAYOUT_IDS.has(resolved_layout):
		resolved_layout = LAYOUT_CLASSIC
	if CurrentLayoutId == resolved_layout and get_used_cells().size() > 0:
		return
	CurrentLayoutId = resolved_layout
	if is_inside_tree():
		_refresh_room()

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

func _pick_border(col: int, row: int) -> Vector2i:
	if row == 0 and col >= EXIT_START - 1 and col <= EXIT_END + 1:
		return T_PANEL_GOLD
	if row == 0 or row == ROWS - 1:
		return T_WALL_BEVEL if col % 2 == 0 else T_NEON_STRIP
	return T_WALL_BEVEL

func _pick_floor_variant(col: int, row: int) -> Vector2i:
	if col >= 10 and col <= 29 and row >= 5 and row <= 14:
		return T_FLOOR_GRID if (col + row) % 2 == 0 else T_FLOOR_PANEL
	if (col + row) % 5 == 0:
		return T_FLOOR_PANEL
	return T_FLOOR_PLAIN

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
		backdrop.color = Color(0.015, 0.024, 0.055, 1.0)

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
