extends RefCounted
class_name CombatVfx

static func spawn_pixel_impact(
	parent: Node,
	position: Vector2,
	direction: Vector2,
	outer_color: Color,
	core_color: Color,
	spark_color: Color,
	size_scale: float = 1.0,
	z_index_value: int = 8,
	lifetime: float = 0.26
) -> Node2D:
	if parent == null:
		return null

	var root := Node2D.new()
	root.name = "combat_impact_fx"
	root.position = position
	root.z_index = z_index_value
	root.add_to_group("combat_vfx")
	parent.add_child(root)

	var travel := direction.normalized()
	if travel == Vector2.ZERO:
		travel = Vector2.RIGHT

	var halo := Polygon2D.new()
	halo.name = "impact_halo"
	halo.color = outer_color
	halo.polygon = _diamond_points(8.0 * size_scale, 6.0 * size_scale)
	halo.material = _create_additive_material()
	halo.scale = Vector2.ONE * 0.42
	root.add_child(halo)

	var streak := Polygon2D.new()
	streak.name = "impact_streak"
	streak.color = core_color
	streak.polygon = _streak_points(18.0 * size_scale, 5.0 * size_scale)
	streak.rotation = travel.angle()
	streak.material = _create_additive_material()
	streak.scale = Vector2.ONE * 0.56
	root.add_child(streak)

	var core := Polygon2D.new()
	core.name = "impact_core"
	core.color = spark_color
	core.polygon = _diamond_points(4.2 * size_scale, 4.2 * size_scale)
	core.material = _create_additive_material()
	root.add_child(core)

	var sparks := CPUParticles2D.new()
	sparks.name = "impact_sparks"
	sparks.one_shot = true
	sparks.explosiveness = 1.0
	sparks.local_coords = false
	sparks.amount = maxi(8, int(round(12.0 * size_scale)))
	sparks.lifetime = 0.16 + size_scale * 0.05
	sparks.direction = -travel
	sparks.spread = 84.0
	sparks.gravity = Vector2.ZERO
	sparks.initial_velocity_min = 18.0 * size_scale
	sparks.initial_velocity_max = 44.0 * size_scale
	sparks.scale_amount_min = 1.4
	sparks.scale_amount_max = 3.6 * size_scale
	sparks.color = spark_color
	root.add_child(sparks)
	sparks.emitting = true

	var tween := root.create_tween()
	tween.set_parallel(true)
	tween.tween_property(halo, "scale", Vector2.ONE * (1.82 + size_scale * 0.12), lifetime)
	tween.tween_property(halo, "modulate:a", 0.0, lifetime)
	tween.tween_property(streak, "scale", Vector2.ONE * (1.36 + size_scale * 0.10), lifetime * 0.82)
	tween.tween_property(streak, "modulate:a", 0.0, lifetime * 0.82)
	tween.tween_property(core, "scale", Vector2.ONE * (0.14 + size_scale * 0.08), lifetime * 0.68)
	tween.tween_property(core, "modulate:a", 0.0, lifetime * 0.68)
	tween.tween_property(sparks, "modulate:a", 0.0, lifetime)
	tween.chain().tween_callback(root.queue_free)
	return root

static func _create_additive_material() -> CanvasItemMaterial:
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return material

static func _diamond_points(radius_x: float, radius_y: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0.0, -radius_y),
		Vector2(radius_x, 0.0),
		Vector2(0.0, radius_y),
		Vector2(-radius_x, 0.0),
	])

static func _streak_points(length: float, width: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(-length * 0.35, -width),
		Vector2(length, 0.0),
		Vector2(-length * 0.35, width),
		Vector2(-length * 0.65, 0.0),
	])
