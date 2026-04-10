class_name EnemyAttackPickup extends Node2D

const PICKUP_DURATION := 10.0
const BLINK_DURATION := 0.9
const INTERACT_RANGE := 68.0

var AttackProfile: Dictionary = {}
var _time_remaining := PICKUP_DURATION
var _consumed := false
var _body_polygon: Polygon2D
var _shield_polygon: Polygon2D
var _crack_polygon: Polygon2D
var _code_polygons: Array[Polygon2D] = []

func _ready() -> void:
	add_to_group("enemy_attack_pickup")
	_build_visuals()

func _process(delta: float) -> void:
	if _consumed:
		return

	_time_remaining = maxf(_time_remaining - delta, 0.0)
	var elapsed := PICKUP_DURATION - _time_remaining
	var pulse := sin(elapsed * 5.4) * 0.5 + 0.5
	rotation = 0.42 + sin(elapsed * 1.6) * 0.05
	_shield_polygon.color.a = 0.07 + pulse * 0.08
	for index in range(_code_polygons.size()):
		var glyph := _code_polygons[index]
		glyph.position.x = 12.0 + index * 8.0 + sin(elapsed * 4.2 + index) * 1.4
		glyph.color.a = 0.42 + pulse * 0.32

	if _time_remaining <= BLINK_DURATION:
		visible = int(floor(_time_remaining * 14.0)) % 2 == 0

	if _time_remaining <= 0.0:
		queue_free()

func configure(global_pos: Vector2, attack_profile: Dictionary) -> void:
	global_position = global_pos
	AttackProfile = attack_profile.duplicate(true)

func is_in_range(point: Vector2) -> bool:
	return global_position.distance_to(point) <= INTERACT_RANGE

func get_prompt_position() -> Vector2:
	return global_position + Vector2(0, -46)

func try_steal() -> Dictionary:
	if _consumed:
		return {}

	_consumed = true
	queue_free()
	return AttackProfile.duplicate(true)

func _build_visuals() -> void:
	if _body_polygon != null:
		return

	_body_polygon = _make_polygon(
		PackedVector2Array([Vector2(0, -28), Vector2(22, 0), Vector2(0, 28), Vector2(-22, 0)]),
		Color(0.12, 0.44, 0.68, 0.9),
		0
	)
	_shield_polygon = _make_polygon(
		PackedVector2Array([Vector2(0, -38), Vector2(33, -19), Vector2(33, 19), Vector2(0, 38), Vector2(-33, 19), Vector2(-33, -19)]),
		Color(0.2, 0.7, 1.0, 0.12),
		-1
	)
	_crack_polygon = _make_polygon(
		PackedVector2Array([
			Vector2(-10, -18), Vector2(-2, -11), Vector2(-8, -5), Vector2(2, 4),
			Vector2(-3, 10), Vector2(9, 18), Vector2(13, 13), Vector2(2, 5),
			Vector2(8, -2), Vector2(-1, -10), Vector2(5, -17),
		]),
		Color(0.92, 0.99, 1.0, 0.92),
		2
	)

	for offset in [12.0, 20.0, 28.0]:
		var glyph := _make_polygon(
			PackedVector2Array([
				Vector2(-3, -8), Vector2(3, -8), Vector2(3, -5), Vector2(-1, -5),
				Vector2(-1, -1), Vector2(4, -1), Vector2(4, 2), Vector2(-4, 2),
				Vector2(-4, 5), Vector2(2, 5), Vector2(2, 8), Vector2(-3, 8),
			]),
			Color(0.56, 0.96, 1.0, 0.64),
			3
		)
		glyph.position = Vector2(offset, -4.0 + _code_polygons.size() * 10.0)
		_code_polygons.append(glyph)

func _make_polygon(points: PackedVector2Array, color: Color, z_index_value: int) -> Polygon2D:
	var polygon := Polygon2D.new()
	polygon.polygon = points
	polygon.color = color
	polygon.z_index = z_index_value
	add_child(polygon)
	return polygon
