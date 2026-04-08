extends SceneTree

func _initialize() -> void:
	await _run()

func _run() -> void:
	var scene := load("res://scenes/entities/enemies/enemy_one.tscn") as PackedScene
	if scene == null:
		push_error("Failed to load enemy_one.tscn")
		quit(1)
		return
	
	var enemy := scene.instantiate()
	root.add_child(enemy)
	await process_frame
	await physics_frame
	
	var sprite := enemy.get_node_or_null("animated_sprite") as AnimatedSprite2D
	if sprite == null:
		push_error("Expected enemy_one to expose an AnimatedSprite2D named animated_sprite")
		quit(1)
		return
	
	if sprite.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
		push_error("Expected enemy sprite to use nearest filtering")
		quit(1)
		return
	
	if sprite.scale != Vector2(0.18, 0.18):
		push_error("Expected enemy sprite scale to match the player sprite scale")
		quit(1)
		return
	
	if sprite.animation != "idle":
		push_error("Expected enemy to play idle animation by default")
		quit(1)
		return
	
	if sprite.is_playing() == false:
		push_error("Expected enemy idle animation to keep playing")
		quit(1)
		return
	
	print("enemy_one_visual_smoke: ok")
	quit(0)
