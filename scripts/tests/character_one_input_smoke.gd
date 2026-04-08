extends SceneTree


func _initialize() -> void:
	await _run()


func _run() -> void:
	var scene := load("res://scenes/entities/characters/character_one.tscn") as PackedScene
	if scene == null:
		push_error("Failed to load character_one.tscn")
		quit(1)
		return

	var character := scene.instantiate()
	root.add_child(character)
	await process_frame

	var dash_event := InputEventKey.new()
	dash_event.keycode = KEY_SPACE
	dash_event.physical_keycode = KEY_SPACE
	dash_event.unicode = 32
	dash_event.pressed = true
	Input.parse_input_event(dash_event)
	await process_frame

	var projectile_count_after_dash := _projectile_count()
	if projectile_count_after_dash != 0:
		push_error("Expected dash input not to spawn projectiles, got %s" % projectile_count_after_dash)
		quit(1)
		return

	var shoot_event := InputEventMouseButton.new()
	shoot_event.button_index = MOUSE_BUTTON_LEFT
	shoot_event.pressed = true
	Input.parse_input_event(shoot_event)
	await process_frame

	var projectile_count_after_click := _projectile_count()
	if projectile_count_after_click != 1:
		push_error("Expected left click to spawn one projectile, got %s" % projectile_count_after_click)
		quit(1)
		return

	print("character_one_input_smoke: ok")
	quit(0)


func _projectile_count() -> int:
	var projectile_count := 0
	for node in root.get_children():
		if node is ProjectileOne:
			projectile_count += 1

	return projectile_count
