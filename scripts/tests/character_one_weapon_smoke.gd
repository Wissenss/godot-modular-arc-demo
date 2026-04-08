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

	var shoot_direction := Vector2.RIGHT
	character.WeaponOne._shoot(shoot_direction)
	await process_frame

	var projectiles := root.get_children().filter(func(node): return node is ProjectileOne)
	if projectiles.size() != 1:
		push_error("Expected exactly one projectile, got %s" % projectiles.size())
		quit(1)
		return

	var projectile := projectiles[0] as ProjectileOne
	if projectile.Owner != character:
		push_error("Expected projectile owner to match the character")
		quit(1)
		return

	if projectile.ConstantVelocityComp.Direction != shoot_direction:
		push_error("Expected projectile direction to stay aligned with the requested shot direction")
		quit(1)
		return

	print("character_one_weapon_smoke: ok")
	quit(0)
