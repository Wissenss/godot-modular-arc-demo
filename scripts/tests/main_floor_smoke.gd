extends SceneTree

func _initialize() -> void:
	await _run()

func _run() -> void:
	var scene := load("res://scenes/main.tscn") as PackedScene
	if scene == null:
		push_error("Failed to load main.tscn")
		quit(1)
		return

	var main_scene := scene.instantiate()
	root.add_child(main_scene)
	await process_frame
	await physics_frame

	var floor := main_scene.get_node_or_null("floor_grid") as Node2D
	if floor == null:
		push_error("Expected main scene to include a floor_grid node")
		quit(1)
		return

	var character := main_scene.get_node_or_null("character_one") as Node2D
	if character == null:
		push_error("Expected main scene to still include character_one")
		quit(1)
		return

	var camera := character.get_node_or_null("camera") as Camera2D
	if camera == null:
		push_error("Expected character_one to include a follow camera")
		quit(1)
		return
	if camera.enabled == false:
		push_error("Expected the follow camera to be enabled")
		quit(1)
		return
	if camera.limit_top > -200 or camera.limit_bottom < 1000 or camera.limit_right < 1380:
		push_error("Expected the camera limits to cover a taller arena with an upper corridor, got top=%s bottom=%s right=%s" % [camera.limit_top, camera.limit_bottom, camera.limit_right])
		quit(1)
		return

	if floor.z_index >= character.z_index:
		push_error("Expected floor_grid to render below character_one")
		quit(1)
		return

	var tile_sprites: Array[Sprite2D] = []
	for child in floor.get_children():
		if child is Sprite2D:
			tile_sprites.append(child)

	if tile_sprites.size() < 250:
		push_error("Expected floor_grid to place a visible floor made from many tiles, got %s sprites" % tile_sprites.size())
		quit(1)
		return

	var min_x := INF
	var min_y := INF
	var max_x := -INF
	var max_y := -INF
	for tile in tile_sprites:
		if tile.texture == null:
			push_error("Expected each floor tile sprite to have a texture")
			quit(1)
			return
		if tile.centered:
			push_error("Expected floor tile sprites to use top-left placement for clean gridding")
			quit(1)
			return
		if tile.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
			push_error("Expected floor tile sprites to keep nearest filtering for pixel crispness")
			quit(1)
			return
		if tile.texture.get_width() > 80 or tile.texture.get_height() > 80:
			push_error("Expected smaller floor tiles after the map retune, got %sx%s" % [tile.texture.get_width(), tile.texture.get_height()])
			quit(1)
			return

		min_x = min(min_x, tile.position.x)
		min_y = min(min_y, tile.position.y)
		max_x = max(max_x, tile.position.x + tile.texture.get_width())
		max_y = max(max_y, tile.position.y + tile.texture.get_height())

	if min_y > -200.0:
		push_error("Expected some floor tiles to extend upward into the corridor, got min_y=%s" % min_y)
		quit(1)
		return

	if max_x - min_x < 1380.0 or max_y - min_y < 1080.0:
		push_error("Expected floor coverage to span the arena, got %sx%s" % [max_x - min_x, max_y - min_y])
		quit(1)
		return

	for node_path in ["environment/border/top_left", "environment/border/top_right", "environment/border/corridor_left", "environment/border/corridor_right", "environment/border/corridor_top"]:
		if main_scene.get_node_or_null(node_path) == null:
			push_error("Expected arena border node %s for the larger room layout" % node_path)
			quit(1)
			return

	print("main_floor_smoke: ok")
	quit(0)
