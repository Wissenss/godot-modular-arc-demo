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
	await physics_frame
	
	var sprite := character.Sprite as AnimatedSprite2D
	if sprite == null:
		push_error("Character sprite was not initialized")
		quit(1)
		return
	
	if sprite.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
		push_error("Expected nearest texture filter for sharper sprite rendering")
		quit(1)
		return
	
	if sprite.scale.x <= 0.12 or sprite.scale.y <= 0.12:
		push_error("Expected sprite scale to be larger than the current placeholder size")
		quit(1)
		return
	
	if sprite.animation != "idle":
		push_error("Expected idle animation to be active by default")
		quit(1)
		return
	
	if sprite.is_playing() == false:
		push_error("Expected idle animation to keep playing while the character is standing still")
		quit(1)
		return

	var idle_texture := sprite.sprite_frames.get_frame_texture("idle", 0)
	var move_texture := sprite.sprite_frames.get_frame_texture("move_left", 0)
	if idle_texture == null or move_texture == null:
		push_error("Expected both idle and movement textures to exist")
		quit(1)
		return

	var idle_size := _opaque_size(idle_texture.get_image())
	var move_size := _opaque_size(move_texture.get_image())
	if move_size.y < idle_size.y * 0.85:
		push_error("Expected movement frames to stay close to idle size, got %s vs %s" % [move_size, idle_size])
		quit(1)
		return
	
	print("character_one_visual_smoke: ok")
	quit(0)

func _opaque_size(image: Image) -> Vector2i:
	var used_rect := image.get_used_rect()
	return used_rect.size
