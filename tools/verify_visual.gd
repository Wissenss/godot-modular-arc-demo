extends SceneTree

var _failures := 0


func _init() -> void:
	_run.call_deferred()


func _check(condition: bool, label: String) -> void:
	print(("PASS " if condition else "FAIL ") + label)
	if not condition:
		_failures += 1


func _run() -> void:
	create_timer(90.0, true, false, true).timeout.connect(func(): quit(2))
	var baseline := OS.get_cmdline_user_args().has("baseline=1")
	_check(root.get_node("SaveManager").get("active_slot") == -1, "sin partida de usuario abierta")
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280, 640))
	root.size = Vector2i(1280, 640)
	var room := load("res://scenes/tests/Brunich/Brunich_tests.tscn").instantiate() as Node2D
	root.add_child(room)
	current_scene = room
	room.get("_narrative").call("stop")
	for i in 120:
		await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tmp"))
	var image := root.get_texture().get_image()
	_check(image.save_png("res://tmp/" + ("antes" if baseline else "despues") + ".png") == OK, "captura del juego original")
	var floor_map := room.get_node("floor_tiles") as TileMapLayer
	var player := room.get_node("MC")
	_check(floor_map.get_used_cells().size() > 700, "arena completa")
	_check(floor_map.tile_set.tile_size == Vector2i(32, 32), "rejilla de 32 px")
	_check(player.get("MOVE_SPEED") == 374.0, "velocidad original conservada")
	_check(player.get("STEAL_RANGE") == 76.0, "alcance original de robo conservado")
	_check(player.get("ACCELERATED_THOUGHT_TIME_SCALE") == 0.42, "ralentizacion original conservada")
	if not baseline:
		_check(player.get_node("face_pixels").scale.is_equal_approx(Vector2.ONE * 0.76), "cara con mayor margen dentro del CRT")
		_check(floor_map.get("ATLAS_PATH") == "res://art/generated/brunich/brunich_industrial_atlas.res", "atlas nuevo nativo")
	var layouts: Array = floor_map.call("get_layout_ids")
	for layout in layouts:
		floor_map.call("set_layout_id", layout)
		_check(floor_map.get_used_cells().size() > 700, "layout completo: " + String(layout))
		_check(floor_map.get_cell_atlas_coords(Vector2i(0, 5)) == Vector2i(0, 1), "borde conservado: " + String(layout))
	Engine.time_scale = 1.0
	room.queue_free()
	await process_frame
	print("RESULT visual failures=", _failures)
	quit(0 if _failures == 0 else 1)
