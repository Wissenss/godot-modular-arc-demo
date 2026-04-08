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

	var body_collision := enemy.get_node("collision") as CollisionPolygon2D
	var hurtbox_collision := enemy.get_node("hurtbox_comp/polygon") as CollisionPolygon2D
	var hitbox_collision := enemy.get_node("hitbox_comp/polygon") as CollisionPolygon2D
	if _is_round_hitbox(body_collision.polygon) == false:
		push_error("Expected enemy body collision to match the visible sprite")
		quit(1)
		return
	if _is_round_hitbox(hurtbox_collision.polygon) == false:
		push_error("Expected enemy hurtbox to match the visible sprite")
		quit(1)
		return
	if _is_round_hitbox(hitbox_collision.polygon) == false:
		push_error("Expected enemy hitbox to match the visible sprite")
		quit(1)
		return
	
	print("enemy_one_visual_smoke: ok")
	quit(0)

func _is_round_hitbox(points: PackedVector2Array) -> bool:
	if points.size() < 8:
		return false

	var min_x := points[0].x
	var max_x := points[0].x
	var min_y := points[0].y
	var max_y := points[0].y
	for point in points:
		min_x = min(min_x, point.x)
		max_x = max(max_x, point.x)
		min_y = min(min_y, point.y)
		max_y = max(max_y, point.y)

	var width := max_x - min_x
	var height := max_y - min_y
	var ratio: float = width / max(height, 1.0)
	return ratio >= 0.8 and ratio <= 1.25 and width >= 48.0 and height >= 48.0
