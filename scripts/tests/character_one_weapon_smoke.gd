extends SceneTree

const PROJECTILE_ONE_SCRIPT := preload("res://scripts/weapons/proyectiles/proyectile_one.gd")


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

	var weapon := character.get_node_or_null("weapon_one")
	if weapon == null:
		push_error("Expected character_one to include weapon_one")
		quit(1)
		return

	var shoot_direction := Vector2.RIGHT
	weapon._shoot(shoot_direction)
	await process_frame

	var projectile_count := 0
	var projectile : Node2D = null
	for node in root.get_children():
		if node is Node2D and node.get_script() == PROJECTILE_ONE_SCRIPT:
			projectile_count += 1
			projectile = node

	if projectile_count != 1 or projectile == null:
		push_error("Expected exactly one projectile, got %s" % projectile_count)
		quit(1)
		return

	if projectile.get("Owner") != character:
		push_error("Expected projectile owner to match the character")
		quit(1)
		return

	var velocity_comp := projectile.get_node_or_null("constant_velocity_comp")
	if velocity_comp == null or velocity_comp.Direction != shoot_direction:
		push_error("Expected projectile direction to stay aligned with the requested shot direction")
		quit(1)
		return

	print("character_one_weapon_smoke: ok")
	quit(0)
