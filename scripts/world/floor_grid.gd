class_name FloorGrid extends Node2D

const ArenaLayoutData := preload("res://scripts/world/arena_layout.gd")

const FLOOR_ATLAS_PATH := "res://art/Beta_floor1 tileset1.png"
const SOURCE_TILE_SIZE := Vector2i(128, 128)
const SOURCE_TILE_STRIDE := Vector2i(132, 128)

const BASE_DARK_TILES := [
	Vector2i(0, 0),
	Vector2i(0, 1),
]

const BASE_PANEL_TILES := [
	Vector2i(2, 0),
	Vector2i(2, 1),
]

const SEAM_TILES := [
	Vector2i(1, 0),
	Vector2i(1, 1),
]

const ENERGY_LEFT_TILES := [
	Vector2i(3, 0),
	Vector2i(3, 1),
	Vector2i(3, 3),
	Vector2i(3, 4),
]

const ENERGY_RIGHT_TILES := [
	Vector2i(4, 0),
	Vector2i(4, 1),
	Vector2i(4, 3),
	Vector2i(4, 4),
]

var _floor_atlas_image: Image
var _tile_texture_cache: Dictionary = {}


func _ready() -> void:
	self.z_index = -20
	self._floor_atlas_image = self._load_floor_atlas_image()
	self._rebuild()


func _rebuild() -> void:
	for child in self.get_children():
		child.queue_free()

	for row in range(-ArenaLayoutData.CORRIDOR_ROWS, ArenaLayoutData.MAIN_ROOM_ROWS):
		for column in range(ArenaLayoutData.MAIN_ROOM_COLUMNS):
			if not self._has_floor_tile(column, row):
				continue

			var tile := Sprite2D.new()
			tile.centered = false
			tile.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			tile.texture = self._make_tile_texture(self._select_tile_coordinate(column, row))
			tile.position = Vector2(column * ArenaLayoutData.TILE_RENDER_SIZE.x, row * ArenaLayoutData.TILE_RENDER_SIZE.y)
			add_child(tile)


func _has_floor_tile(column: int, row: int) -> bool:
	if row >= 0 and row < ArenaLayoutData.MAIN_ROOM_ROWS:
		return true

	return row >= -ArenaLayoutData.CORRIDOR_ROWS \
		and row < 0 \
		and column >= ArenaLayoutData.CORRIDOR_START_COLUMN \
		and column < ArenaLayoutData.CORRIDOR_START_COLUMN + ArenaLayoutData.CORRIDOR_COLUMNS


func _select_tile_coordinate(column: int, row: int) -> Vector2i:
	var corridor_left := ArenaLayoutData.CORRIDOR_START_COLUMN
	var corridor_right := corridor_left + ArenaLayoutData.CORRIDOR_COLUMNS - 1
	var energy_mid_left := corridor_left + 2
	var energy_mid_right := corridor_left + 3
	var pattern_index := posmod(row, ENERGY_LEFT_TILES.size())

	if row < 0:
		if row == -ArenaLayoutData.CORRIDOR_ROWS:
			if column == corridor_left or column == corridor_right:
				return SEAM_TILES[pattern_index % SEAM_TILES.size()]
			if column <= energy_mid_left:
				return ENERGY_LEFT_TILES[2]
			return ENERGY_RIGHT_TILES[2]

		if column == corridor_left or column == corridor_right:
			return SEAM_TILES[pattern_index % SEAM_TILES.size()]
		if column == corridor_left + 1 or column == corridor_right - 1:
			return BASE_PANEL_TILES[pattern_index % BASE_PANEL_TILES.size()]
		if column <= energy_mid_left:
			return ENERGY_LEFT_TILES[pattern_index]
		return ENERGY_RIGHT_TILES[pattern_index]

	if column == corridor_left - 2 or column == corridor_right + 2:
		return BASE_PANEL_TILES[posmod(row + 1, BASE_PANEL_TILES.size())]
	if column == corridor_left - 1 or column == corridor_right + 1:
		return SEAM_TILES[posmod(row, SEAM_TILES.size())]
	if column >= corridor_left and column <= corridor_right:
		if row == 0:
			if column <= energy_mid_left:
				return ENERGY_LEFT_TILES[3]
			return ENERGY_RIGHT_TILES[3]
		if column <= energy_mid_left:
			return ENERGY_LEFT_TILES[pattern_index]
		return ENERGY_RIGHT_TILES[pattern_index]
	if column < 2 or column >= ArenaLayoutData.MAIN_ROOM_COLUMNS - 2:
		return BASE_PANEL_TILES[posmod(row, BASE_PANEL_TILES.size())]
	if posmod(row, 4) == 2:
		return BASE_PANEL_TILES[posmod(column, BASE_PANEL_TILES.size())]
	return BASE_DARK_TILES[posmod(column + row, BASE_DARK_TILES.size())]


func _make_tile_texture(tile_coordinate: Vector2i) -> Texture2D:
	if self._tile_texture_cache.has(tile_coordinate):
		return self._tile_texture_cache[tile_coordinate]

	if self._floor_atlas_image == null or self._floor_atlas_image.is_empty():
		return null

	var source_rect := Rect2i(
		tile_coordinate.x * SOURCE_TILE_STRIDE.x,
		tile_coordinate.y * SOURCE_TILE_STRIDE.y,
		SOURCE_TILE_SIZE.x,
		SOURCE_TILE_SIZE.y
	)
	var tile_image := self._floor_atlas_image.get_region(source_rect)
	tile_image.resize(ArenaLayoutData.TILE_RENDER_SIZE.x, ArenaLayoutData.TILE_RENDER_SIZE.y, Image.INTERPOLATE_NEAREST)

	var tile_texture := ImageTexture.create_from_image(tile_image)
	self._tile_texture_cache[tile_coordinate] = tile_texture
	return tile_texture


func _load_floor_atlas_image() -> Image:
	var image := Image.load_from_file(FLOOR_ATLAS_PATH)
	if image == null or image.is_empty():
		push_warning("Missing floor atlas: %s" % FLOOR_ATLAS_PATH)
		return null
	return image
