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

	if absf(sprite.scale.x - roundf(sprite.scale.x)) > 0.01 or absf(sprite.scale.y - roundf(sprite.scale.y)) > 0.01:
		push_error("Expected integer sprite scaling for crisper pixel art, got %s" % sprite.scale)
		quit(1)
		return

	if character.ConstantVelocityComp.Speed != 260:
		push_error("Expected movement speed to be retuned to 260 for the new skin")
		quit(1)
		return

	var expected_animations := [
		"idle",
		"move_up",
		"move_down",
		"move_left",
		"move_right",
		"move_up_left",
		"move_up_right",
		"move_down_left",
		"move_down_right",
		"hit",
		"attack_front",
		"attack_down",
		"attack_side",
		"attack_up",
		"dash_up",
		"dash_down",
		"dash_left",
		"dash_right",
		"dash_up_left",
		"dash_up_right",
		"dash_down_left",
		"dash_down_right",
	]
	for animation_name in expected_animations:
		if sprite.sprite_frames.has_animation(animation_name) == false:
			push_error("Expected animation '%s' to exist for the new 8-direction skin" % animation_name)
			quit(1)
			return
		if sprite.sprite_frames.get_frame_count(animation_name) < 1:
			push_error("Expected animation '%s' to have at least one frame" % animation_name)
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

	var idle_fps := sprite.sprite_frames.get_animation_speed("idle")
	if idle_fps < 7.5 or idle_fps > 10.5:
		push_error("Expected idle animation speed to stay readable and smooth, got %s fps" % idle_fps)
		quit(1)
		return

	for movement_animation in ["move_up", "move_down", "move_left", "move_right", "move_up_left", "move_up_right", "move_down_left", "move_down_right"]:
		var movement_fps := sprite.sprite_frames.get_animation_speed(movement_animation)
		if movement_fps < 8.0 or movement_fps > 10.75:
			push_error("Expected %s animation speed to feel smooth without looking rushed, got %s fps" % [movement_animation, movement_fps])
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

	for special_animation in ["hit", "attack_front", "attack_down", "attack_side", "attack_up", "dash_up", "dash_down", "dash_left", "dash_right", "dash_up_left", "dash_up_right", "dash_down_left", "dash_down_right"]:
		var special_texture := sprite.sprite_frames.get_frame_texture(special_animation, 0)
		if special_texture == null:
			push_error("Expected special animation frame for %s" % special_animation)
			quit(1)
			return

		var special_size := _opaque_size(special_texture.get_image())
		if special_size.y < idle_size.y * 0.78 or special_size.y > idle_size.y * 1.38:
			push_error("Expected %s to stay near the player size, got %s vs idle %s" % [special_animation, special_size, idle_size])
			quit(1)
			return

		var border_pixels := _opaque_pixels_on_outer_border(special_texture.get_image(), 2)
		if border_pixels > 4:
			push_error("Expected %s to stay cropped away from the frame border, got %s border pixels" % [special_animation, border_pixels])
			quit(1)
			return

	for grounded_animation in ["idle", "move_left", "move_right", "move_down", "move_down_left", "move_down_right"]:
		var min_bottom_margin := _animation_min_bottom_margin(sprite, grounded_animation)
		if min_bottom_margin < 42:
			push_error("Expected %s to leave enough space under the feet, got margin %s" % [grounded_animation, min_bottom_margin])
			quit(1)
			return

	for artifact_animation in ["move_left", "move_up_left", "move_down_right"]:
		var artifact_texture := sprite.sprite_frames.get_frame_texture(artifact_animation, 0)
		if artifact_texture == null:
			push_error("Expected artifact check frame for %s" % artifact_animation)
			quit(1)
			return

		var artifact_pixels := _opaque_pixels_on_outer_border(artifact_texture.get_image(), 2)
		if artifact_pixels > 4:
			push_error("Expected %s to avoid source-sheet residue touching the frame border, got %s opaque border pixels" % [artifact_animation, artifact_pixels])
			quit(1)
			return

	for animation_name in ["move_right", "move_down_right"]:
		var brightness_spread := _animation_brightness_spread(sprite, animation_name)
		if brightness_spread > 12.0:
			push_error("Expected %s to avoid brightness flicker across frames, got spread %s" % [animation_name, brightness_spread])
			quit(1)
			return

	for animation_name in ["idle", "move_left", "move_right", "move_up_left", "move_up_right"]:
		var head_top_spread := _animation_head_metric_spread(sprite, animation_name, "head_top")
		if head_top_spread > 12.0:
			push_error("Expected %s head anchor to stay vertically stable, got spread %s" % [animation_name, head_top_spread])
			quit(1)
			return

		var head_center_spread := _animation_head_metric_spread(sprite, animation_name, "head_center_x")
		if head_center_spread > 14.0:
			push_error("Expected %s head anchor to stay horizontally stable, got spread %s" % [animation_name, head_center_spread])
			quit(1)
			return

		var head_width_spread := _animation_head_metric_spread(sprite, animation_name, "head_width")
		var max_head_width_spread := 12.0
		if animation_name == "idle":
			max_head_width_spread = 20.0
		if head_width_spread > max_head_width_spread:
			push_error("Expected %s head size to stay consistent, got spread %s" % [animation_name, head_width_spread])
			quit(1)
			return

	for animation_name in ["hit", "attack_front", "attack_down", "attack_side", "attack_up"]:
		var attack_head_top_spread := _animation_head_metric_spread(sprite, animation_name, "head_top")
		var max_attack_head_top_spread := 34.0
		if animation_name == "hit":
			max_attack_head_top_spread = 48.0
		if attack_head_top_spread > max_attack_head_top_spread:
			push_error("Expected %s head anchor to stay vertically stable, got spread %s" % [animation_name, attack_head_top_spread])
			quit(1)
			return

		var attack_head_center_spread := _animation_head_metric_spread(sprite, animation_name, "head_center_x")
		var max_attack_head_center_spread := 24.0
		if animation_name == "hit":
			max_attack_head_center_spread = 30.0
		if attack_head_center_spread > max_attack_head_center_spread:
			push_error("Expected %s head anchor to stay horizontally stable, got spread %s" % [animation_name, attack_head_center_spread])
			quit(1)
			return

	var move_up_right_x_spread := _animation_metric_spread(sprite, "move_up_right", "x")
	if move_up_right_x_spread > 70.0:
		push_error("Expected move_up_right to stay horizontally stable, got x spread %s" % move_up_right_x_spread)
		quit(1)
		return
	
	var body_collision := character.get_node("collision") as CollisionPolygon2D
	var hitbox_collision := character.get_node("hitbox_comp/collision") as CollisionPolygon2D
	if _is_humanoid_hitbox(body_collision.polygon) == false:
		push_error("Expected player body collision to match the robot silhouette better")
		quit(1)
		return
	if _is_humanoid_hitbox(hitbox_collision.polygon) == false:
		push_error("Expected player hitbox collision to match the robot silhouette better")
		quit(1)
		return
	
	print("character_one_visual_smoke: ok")
	quit(0)

func _opaque_size(image: Image) -> Vector2i:
	var used_rect := image.get_used_rect()
	return used_rect.size

func _opaque_pixels_on_outer_border(image: Image, border_size: int) -> int:
	var width := image.get_width()
	var height := image.get_height()
	var count := 0
	for y in range(height):
		for x in range(width):
			var in_band := x < border_size or x >= width - border_size or y < border_size or y >= height - border_size
			if in_band == false:
				continue

			if image.get_pixel(x, y).a > 0.0:
				count += 1

	return count

func _is_humanoid_hitbox(points: PackedVector2Array) -> bool:
	if points.size() < 5:
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
	return height > width * 1.35 and height >= 70.0

func _animation_brightness_spread(sprite: AnimatedSprite2D, animation_name: String) -> float:
	var values: Array[float] = []
	var frame_count := sprite.sprite_frames.get_frame_count(animation_name)
	for frame_index in range(frame_count):
		var texture := sprite.sprite_frames.get_frame_texture(animation_name, frame_index)
		if texture == null:
			continue
		values.append(_average_opaque_brightness(texture.get_image()))

	if values.is_empty():
		return 0.0

	return values.max() - values.min()

func _animation_metric_spread(sprite: AnimatedSprite2D, animation_name: String, metric: String) -> float:
	var values: Array[float] = []
	var frame_count := sprite.sprite_frames.get_frame_count(animation_name)
	for frame_index in range(frame_count):
		var texture := sprite.sprite_frames.get_frame_texture(animation_name, frame_index)
		if texture == null:
			continue
		var rect := texture.get_image().get_used_rect()
		match metric:
			"x":
				values.append(float(rect.position.x))
			"width":
				values.append(float(rect.size.x))
			_:
				values.append(0.0)

	if values.is_empty():
		return 0.0

	return values.max() - values.min()

func _animation_head_metric_spread(sprite: AnimatedSprite2D, animation_name: String, metric: String) -> float:
	var values: Array[float] = []
	var frame_count := sprite.sprite_frames.get_frame_count(animation_name)
	for frame_index in range(frame_count):
		var texture := sprite.sprite_frames.get_frame_texture(animation_name, frame_index)
		if texture == null:
			continue

		var head_metrics := _head_metrics(texture.get_image())
		match metric:
			"head_top":
				values.append(head_metrics.top)
			"head_center_x":
				values.append(head_metrics.center_x)
			"head_width":
				values.append(head_metrics.width)
			_:
				values.append(0.0)

	if values.is_empty():
		return 0.0

	return values.max() - values.min()

func _animation_min_bottom_margin(sprite: AnimatedSprite2D, animation_name: String) -> int:
	var min_margin := 10_000
	var frame_count := sprite.sprite_frames.get_frame_count(animation_name)
	for frame_index in range(frame_count):
		var texture := sprite.sprite_frames.get_frame_texture(animation_name, frame_index)
		if texture == null:
			continue

		var rect := texture.get_image().get_used_rect()
		min_margin = min(min_margin, texture.get_height() - (rect.position.y + rect.size.y))

	if min_margin == 10_000:
		return 0

	return min_margin

func _head_metrics(image: Image) -> Dictionary:
	var rect := image.get_used_rect()
	if rect.size == Vector2i.ZERO:
		return {"top": 0.0, "center_x": 0.0, "width": 0.0}

	var search_bottom: int = rect.position.y + max(1, int(round(rect.size.y * 0.38)))
	var min_x := image.get_width()
	var max_x := -1
	var min_y := image.get_height()
	for y in range(rect.position.y, min(search_bottom, image.get_height())):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			if image.get_pixel(x, y).a <= 0.0:
				continue
			min_x = min(min_x, x)
			max_x = max(max_x, x)
			min_y = min(min_y, y)

	if max_x < min_x:
		return {
			"top": float(rect.position.y),
			"center_x": float(rect.get_center().x),
			"width": float(rect.size.x),
		}

	return {
		"top": float(min_y),
		"center_x": float(min_x + max_x) / 2.0,
		"width": float(max_x - min_x + 1),
	}

func _average_opaque_brightness(image: Image) -> float:
	var total := 0.0
	var opaque_pixels := 0
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var pixel := image.get_pixel(x, y)
			if pixel.a <= 0.0:
				continue
			total += (pixel.r + pixel.g + pixel.b) / 3.0
			opaque_pixels += 1

	if opaque_pixels == 0:
		return 0.0

	return total / float(opaque_pixels)
