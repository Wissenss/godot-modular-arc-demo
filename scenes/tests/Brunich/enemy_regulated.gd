class_name EnemyRegulated extends CharacterBody2D

## Base enemy controller. All enemy types (regulated/spread/pierce/slowbeam)
## share this script and differ only in @export values and the weapon child.
## The weapon child is auto-detected by the presence of get_attack_profile_for_player().

@export var MaxHealth: int = 320
@export var MoveSpeed: float = 132.0
@export var StrafeSpeed: float = 96.0
@export var DodgeSpeed: float = 220.0
@export var DodgeDuration: float = 0.28
@export var DodgeCooldown: float = 0.85
@export var DesiredRangeMin: float = 220.0
@export var DesiredRangeMax: float = 380.0
@export var ProjectileAlertRange: float = 250.0
@export var OrbitFrequency: float = 1.7
@export var BaseColor: Color = Color(0.16, 0.82, 1.0, 1.0)

const HIT_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const ARENA_MIN := Vector2(54, 52)
const ARENA_MAX := Vector2(1226, 610)
const ATTACK_PICKUP_SCRIPT := preload("res://scenes/tests/Brunich/enemy_attack_pickup.gd")
const DEATH_SHADER := preload("res://scenes/tests/Brunich/enemy_death_shader.gdshader")
const SCANLINE_SHADER := preload("res://scenes/tests/Brunich/scanline_shader.gdshader")
const DEATH_DURATION := 0.62
const FACE_NODE_NAMES := [
	"face_shell", "face_fill", "face_glass", "face_eye", "face_pupil",
	"face_eye_left", "face_eye_right", "face_pupil_left", "face_pupil_right",
	"face_cross_h", "face_cross_v",
]
const DISPLAY_POLISH_NODE_NAMES := [
	"body_shadow_poly",
	"body_rim_poly",
	"body_reflection_poly",
	"face_blur",
	"face_reflection",
	"death_echo_back",
	"death_echo_front",
]

var HitboxComp: HitboxComponent
var HealthComp: HealthComponent
var Weapon
var Polygon: Polygon2D
var ShieldPoly: Polygon2D
var BodyParticles: CPUParticles2D
var OrbitParticles: CPUParticles2D
var BodyShadowPoly: Polygon2D
var BodyRimPoly: Polygon2D
var BodyReflectionPoly: Polygon2D
var FaceBlur: Polygon2D
var FaceReflection: Polygon2D
var FaceScanlines: Node2D
var FaceSweepLines: Node2D

var _combat_time := 0.0
var _alive := true
var _dodge_timer := 0.0
var _dodge_cooldown := 0.0
var _dodge_vector := Vector2.ZERO
var _shield_base_color := Color.WHITE
var _death_material: ShaderMaterial
var _face_sweep_polys: Array[Polygon2D] = []

func _ready() -> void:
	add_to_group("regulated_enemy")
	self.Polygon = $polygon
	self.ShieldPoly = $shield_poly
	self.BodyParticles = $body_particles
	self.OrbitParticles = $orbit_particles
	self.Polygon.color = BaseColor
	_shield_base_color = self.ShieldPoly.color
	_build_body_polish()
	_build_face_display_polish()

	self.HitboxComp = $hitbox_comp
	self.HitboxComp.Owner = self
	self.HitboxComp.on_hit.connect(self._handle_on_hit)

	self.HealthComp = $health_comp
	self.HealthComp.set_max_health(MaxHealth)
	self.HealthComp.set_health(MaxHealth)
	self.HealthComp.on_died.connect(self._handle_on_died)

	self.Weapon = _find_weapon_child()
	if self.Weapon != null:
		self.Weapon.Owner = self

func _find_weapon_child() -> Node:
	for child in get_children():
		if child.has_method("get_attack_profile_for_player"):
			return child
	return null

func _physics_process(delta: float) -> void:
	if not _alive:
		return

	_combat_time += delta
	_dodge_timer = maxf(_dodge_timer - delta, 0.0)
	_dodge_cooldown = maxf(_dodge_cooldown - delta, 0.0)

	var player := _get_player()
	if player == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if _dodge_timer <= 0.0:
		_try_start_dodge(player)

	if _dodge_timer > 0.0:
		velocity = _dodge_vector * DodgeSpeed
	else:
		velocity = _compute_patrol_velocity(player)

	move_and_slide()
	global_position = global_position.clamp(ARENA_MIN, ARENA_MAX)
	_update_visuals()

func _compute_patrol_velocity(player: Node2D) -> Vector2:
	var to_player := player.global_position - global_position
	var distance := to_player.length()
	var dir_to_player := to_player.normalized()
	var orbit := Vector2(-dir_to_player.y, dir_to_player.x)
	var orbit_sign := 1.0 if sin(_combat_time * OrbitFrequency) >= 0.0 else -1.0
	var move := orbit * StrafeSpeed * orbit_sign

	if distance > DesiredRangeMax:
		move += dir_to_player * MoveSpeed
	elif distance < DesiredRangeMin:
		move -= dir_to_player * MoveSpeed * 0.9
	else:
		move += dir_to_player * 28.0

	return move.limit_length(MoveSpeed + StrafeSpeed * 0.75)

func _try_start_dodge(player: Node2D) -> void:
	if _dodge_cooldown > 0.0:
		return

	for projectile in get_tree().get_nodes_in_group("player_projectile"):
		if projectile.Owner == self:
			continue

		var to_enemy: Vector2 = global_position - projectile.global_position
		if to_enemy.length() > ProjectileAlertRange:
			continue

		var projectile_dir: Vector2 = projectile.ConstantVelocityComp.Direction.normalized()
		if projectile_dir == Vector2.ZERO:
			continue

		if projectile_dir.dot(to_enemy.normalized()) < 0.78:
			continue

		var dodge_dir := Vector2(-projectile_dir.y, projectile_dir.x)
		var away_from_player := (global_position - player.global_position).normalized()
		if dodge_dir.dot(away_from_player) < 0.0:
			dodge_dir *= -1.0

		_dodge_vector = dodge_dir.normalized()
		_dodge_timer = DodgeDuration
		_dodge_cooldown = DodgeCooldown
		return

func _update_visuals() -> void:
	var pulse := sin(_combat_time * 3.8) * 0.5 + 0.5
	self.ShieldPoly.color = Color(_shield_base_color.r, _shield_base_color.g, _shield_base_color.b, 0.08 + pulse * 0.09)
	self.OrbitParticles.orbit_velocity_min = -0.4 - pulse * 0.3
	self.OrbitParticles.orbit_velocity_max = 0.4 + pulse * 0.3
	if self.BodyShadowPoly != null:
		self.BodyShadowPoly.position = Vector2(1.6, 2.8 + pulse * 0.6)
		self.BodyShadowPoly.color = Color(0.0, 0.0, 0.0, 0.24 + pulse * 0.06)
	if self.BodyRimPoly != null:
		self.BodyRimPoly.position = Vector2(-0.8, -1.2)
		self.BodyRimPoly.scale = Vector2.ONE * (0.84 + pulse * 0.03)
		self.BodyRimPoly.color = _lift_color(BaseColor, 0.42, 0.18 + pulse * 0.05)
	if self.BodyReflectionPoly != null:
		self.BodyReflectionPoly.position = Vector2(-3.2, -4.4 + pulse * 0.3)
		self.BodyReflectionPoly.scale = Vector2.ONE * (0.56 + pulse * 0.02)
		self.BodyReflectionPoly.color = _lift_color(BaseColor, 0.70, 0.16 + pulse * 0.04)
	_update_face_display_polish(pulse)

func _build_body_polish() -> void:
	self.BodyShadowPoly = _ensure_polygon_node(
		"body_shadow_poly",
		-1,
		Color(0.0, 0.0, 0.0, 0.26),
		self.Polygon.polygon
	)
	self.BodyShadowPoly.position = Vector2(1.6, 2.8)
	self.BodyShadowPoly.scale = Vector2.ONE * 1.04

	self.BodyRimPoly = _ensure_polygon_node(
		"body_rim_poly",
		1,
		_lift_color(BaseColor, 0.36, 0.20),
		self.Polygon.polygon
	)
	self.BodyRimPoly.scale = Vector2.ONE * 0.84

	self.BodyReflectionPoly = _ensure_polygon_node(
		"body_reflection_poly",
		1,
		_lift_color(BaseColor, 0.70, 0.18),
		self.Polygon.polygon
	)
	self.BodyReflectionPoly.position = Vector2(-3.2, -4.4)
	self.BodyReflectionPoly.scale = Vector2.ONE * 0.56

func _build_face_display_polish() -> void:
	var face_points := _get_face_display_points()
	self.FaceBlur = _ensure_polygon_node(
		"face_blur",
		4,
		_lift_color(BaseColor, 0.44, 0.18),
		face_points
	)
	self.FaceBlur.material = _create_scanline_material(0.42, 18.0, 0.12, 0.86, 0.12, 0.03, 0.34, 0.08, 26.0, 0.14)
	self.FaceBlur.scale = Vector2.ONE * 1.08

	self.FaceReflection = _ensure_polygon_node(
		"face_reflection",
		5,
		Color(0.90, 0.96, 1.0, 0.18),
		face_points
	)
	self.FaceReflection.position = Vector2(-2.4, -1.8)
	self.FaceReflection.scale = Vector2.ONE * 0.46

	self.FaceScanlines = _ensure_effect_container("face_scanlines", 5)
	self.FaceSweepLines = _ensure_effect_container("face_sweep_lines", 5)
	_build_face_scanlines(face_points)
	_build_face_sweep_lines(face_points)

func _update_face_display_polish(pulse: float) -> void:
	if self.FaceBlur != null:
		self.FaceBlur.color = _lift_color(BaseColor, 0.40, 0.14 + pulse * 0.05)
		self.FaceBlur.scale = Vector2.ONE * (1.06 + pulse * 0.04)
	if self.FaceReflection != null:
		self.FaceReflection.modulate = Color(0.96, 0.98, 1.0, 0.16 + pulse * 0.06)
		self.FaceReflection.scale = Vector2.ONE * (0.44 + pulse * 0.03)
	for stripe in self.FaceScanlines.get_children():
		var stripe_poly := stripe as Polygon2D
		if stripe_poly == null:
			continue
		stripe_poly.modulate = Color(0.56, 0.60, 0.70, 0.10 + pulse * 0.04)
	_update_face_sweep_lines(pulse)

func _build_face_scanlines(face_points: PackedVector2Array) -> void:
	for child in self.FaceScanlines.get_children():
		child.queue_free()
	var bounds := _get_polygon_bounds(face_points)
	var stripe_count := 5
	for stripe_index in range(stripe_count):
		var stripe := Polygon2D.new()
		var stripe_y := bounds.position.y + 1.0 + float(stripe_index) * ((bounds.size.y - 2.0) / float(stripe_count))
		stripe.color = Color(0.54, 0.58, 0.66, 0.12 if stripe_index % 2 == 0 else 0.08)
		stripe.polygon = PackedVector2Array([
			Vector2(bounds.position.x + 0.8, stripe_y),
			Vector2(bounds.position.x + bounds.size.x - 0.8, stripe_y),
			Vector2(bounds.position.x + bounds.size.x - 0.8, stripe_y + 0.26),
			Vector2(bounds.position.x + 0.8, stripe_y + 0.26),
		])
		self.FaceScanlines.add_child(stripe)

func _build_face_sweep_lines(face_points: PackedVector2Array) -> void:
	for child in self.FaceSweepLines.get_children():
		child.queue_free()
	_face_sweep_polys.clear()
	var bounds := _get_polygon_bounds(face_points)
	for _i in range(2):
		var sweep := Polygon2D.new()
		sweep.color = Color(0.74, 0.86, 1.0, 0.0)
		sweep.polygon = PackedVector2Array([
			Vector2(bounds.position.x + 0.6, -0.22),
			Vector2(bounds.position.x + bounds.size.x - 0.6, -0.22),
			Vector2(bounds.position.x + bounds.size.x - 0.6, 0.22),
			Vector2(bounds.position.x + 0.6, 0.22),
		])
		self.FaceSweepLines.add_child(sweep)
		_face_sweep_polys.append(sweep)

func _update_face_sweep_lines(pulse: float) -> void:
	if _face_sweep_polys.is_empty():
		return
	var face_points := _get_face_display_points()
	var bounds := _get_polygon_bounds(face_points)
	var t := float(Time.get_ticks_msec()) * 0.00072
	for sweep_index in range(_face_sweep_polys.size()):
		var sweep := _face_sweep_polys[sweep_index]
		var phase := fposmod(t + float(sweep_index) * 0.43, 1.0)
		sweep.position = Vector2(0.0, lerpf(bounds.position.y + 0.8, bounds.position.y + bounds.size.y - 0.8, phase))
		sweep.color = Color(0.72, 0.86, 1.0, sin(phase * PI) * (0.10 + pulse * 0.04))

func _get_face_display_points() -> PackedVector2Array:
	if has_node("face_fill"):
		return ($face_fill as Polygon2D).polygon
	if has_node("face_glass"):
		return ($face_glass as Polygon2D).polygon
	return PackedVector2Array([
		Vector2(-8.0, -5.0), Vector2(8.0, -5.0), Vector2(8.0, 5.0), Vector2(-8.0, 5.0),
	])

func _get_polygon_bounds(points: PackedVector2Array) -> Rect2:
	var min_x := INF
	var max_x := -INF
	var min_y := INF
	var max_y := -INF
	for point in points:
		min_x = minf(min_x, point.x)
		max_x = maxf(max_x, point.x)
		min_y = minf(min_y, point.y)
		max_y = maxf(max_y, point.y)
	return Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))

func _create_scanline_material(
	scan_speed: float,
	line_density: float,
	line_brightness: float,
	pulse_speed: float,
	subpixel_strength: float,
	chroma_strength: float,
	blur_strength: float,
	shadow_strength: float,
	stripe_density: float,
	stripe_strength: float
) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = SCANLINE_SHADER
	material.set_shader_parameter("scan_speed", scan_speed)
	material.set_shader_parameter("line_density", line_density)
	material.set_shader_parameter("line_brightness", line_brightness)
	material.set_shader_parameter("pulse_speed", pulse_speed)
	material.set_shader_parameter("subpixel_strength", subpixel_strength)
	material.set_shader_parameter("chroma_strength", chroma_strength)
	material.set_shader_parameter("blur_strength", blur_strength)
	material.set_shader_parameter("shadow_strength", shadow_strength)
	material.set_shader_parameter("stripe_density", stripe_density)
	material.set_shader_parameter("stripe_strength", stripe_strength)
	return material

func _ensure_polygon_node(name: String, z_index_value: int, color_value: Color, points: PackedVector2Array) -> Polygon2D:
	var polygon_node := get_node_or_null(name) as Polygon2D
	if polygon_node == null:
		polygon_node = Polygon2D.new()
		polygon_node.name = name
		add_child(polygon_node)
	polygon_node.z_index = z_index_value
	polygon_node.color = color_value
	polygon_node.polygon = points
	return polygon_node

func _ensure_effect_container(name: String, z_index_value: int) -> Node2D:
	var node := get_node_or_null(name) as Node2D
	if node == null:
		node = Node2D.new()
		node.name = name
		add_child(node)
	node.z_index = z_index_value
	return node

func _lift_color(color_value: Color, amount: float, alpha_value: float) -> Color:
	return Color(
		lerpf(color_value.r, 1.0, amount),
		lerpf(color_value.g, 1.0, amount),
		lerpf(color_value.b, 1.0, amount),
		alpha_value
	)

func _get_player() -> Node2D:
	var players := get_tree().get_nodes_in_group("player")
	return players[0] as Node2D if not players.is_empty() else null

func trigger_hackeo() -> void:
	## Called by player's hackeo action. Force-kills via health signal chain.
	if not _alive:
		return
	self.HealthComp.set_health(0)

func _handle_on_hit(by: Area2D) -> void:
	if by is HurtboxComponent:
		if by.Owner == self:
			return

		self.HealthComp.take_damage(by.Damage)
		_do_hit_flash()

func _do_hit_flash() -> void:
	self.Polygon.color = HIT_COLOR
	self.ShieldPoly.color = Color(1.0, 1.0, 1.0, 0.18)
	if self.BodyRimPoly != null:
		self.BodyRimPoly.color = Color(1.0, 1.0, 1.0, 0.42)
	if self.FaceBlur != null:
		self.FaceBlur.color = Color(1.0, 1.0, 1.0, 0.24)
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(self):
		self.Polygon.color = BaseColor

func _handle_on_died() -> void:
	_alive = false
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		if players[0].has_method("notify_enemy_eliminated"):
			players[0].notify_enemy_eliminated()
		elif players[0].has_method("set_face_expression"):
			players[0].set_face_expression("happy", 4.0)
	self.HitboxComp.set_deferred("monitorable", false)
	self.HitboxComp.set_deferred("monitoring", false)
	if has_node("hurtbox_comp"):
		var hurtbox := $hurtbox_comp as Area2D
		hurtbox.set_deferred("monitorable", false)
		hurtbox.set_deferred("monitoring", false)
	self.BodyParticles.emitting = false
	self.OrbitParticles.emitting = false
	if self.Weapon != null:
		self.Weapon.set_process(false)
	if ATTACK_PICKUP_SCRIPT != null and self.Weapon != null:
		var pickup := ATTACK_PICKUP_SCRIPT.new()
		pickup.configure(global_position, self.Weapon.get_attack_profile_for_player())
		var parent: Node = get_parent() if get_parent() != null else get_tree().current_scene
		parent.add_child(pickup)
	_play_death_animation()

func _play_death_animation() -> void:
	var pale := _get_pale_color(BaseColor)

	_death_material = ShaderMaterial.new()
	_death_material.shader = DEATH_SHADER
	_death_material.set_shader_parameter("dissolve_progress", 0.0)
	_death_material.set_shader_parameter("noise_scale", 0.32)
	_death_material.set_shader_parameter("glitch_intensity", 0.75)
	_death_material.set_shader_parameter("edge_glow", 1.2)
	_death_material.set_shader_parameter("scan_speed", 18.0)

	self.Polygon.material = _death_material
	self.Polygon.color = pale
	_apply_death_material_to_polish_nodes()

	# Pale and re-material the face so the whole body dissolves together.
	for face_name in FACE_NODE_NAMES:
		if not has_node(face_name):
			continue
		var face_node := get_node(face_name) as Polygon2D
		if face_node == null:
			continue
		face_node.color = _pale_lerp(face_node.color, 0.55)
		if face_name == "face_glass":
			face_node.material = _death_material

	# Shield becomes a ghostly halo.
	self.ShieldPoly.color = Color(pale.r, pale.g, pale.b, 0.14)

	# Spawn a death particle burst sized to the enemy's color.
	_spawn_death_burst(pale)
	_spawn_death_echoes(pale)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.10)
	tween.tween_property(self, "scale", Vector2(0.55, 0.55), DEATH_DURATION - 0.10).set_delay(0.10)
	tween.tween_property(self, "modulate:a", 0.0, DEATH_DURATION * 0.85).set_delay(DEATH_DURATION * 0.15)
	tween.tween_method(
		_update_death_dissolve,
		0.0, 1.0, DEATH_DURATION
	)
	await tween.finished
	if is_instance_valid(self):
		queue_free()

func _update_death_dissolve(value: float) -> void:
	if _death_material != null:
		_death_material.set_shader_parameter("dissolve_progress", value)

func _apply_death_material_to_polish_nodes() -> void:
	for node_name in DISPLAY_POLISH_NODE_NAMES:
		var polygon_node := get_node_or_null(node_name) as Polygon2D
		if polygon_node == null:
			continue
		polygon_node.material = _death_material

func _spawn_death_echoes(pale: Color) -> void:
	var death_echo_back := _ensure_polygon_node(
		"death_echo_back",
		0,
		Color(pale.r, pale.g, pale.b, 0.28),
		self.Polygon.polygon
	)
	death_echo_back.position = Vector2.ZERO
	death_echo_back.scale = Vector2.ONE * 0.98
	death_echo_back.material = _death_material

	var death_echo_front := _ensure_polygon_node(
		"death_echo_front",
		2,
		Color(1.0, 1.0, 1.0, 0.22),
		self.Polygon.polygon
	)
	death_echo_front.position = Vector2.ZERO
	death_echo_front.scale = Vector2.ONE * 0.84
	death_echo_front.material = _death_material

	var echo_tween := create_tween()
	echo_tween.set_parallel(true)
	echo_tween.tween_property(death_echo_back, "scale", Vector2.ONE * 1.42, DEATH_DURATION * 0.78)
	echo_tween.tween_property(death_echo_back, "modulate:a", 0.0, DEATH_DURATION * 0.72)
	echo_tween.tween_property(death_echo_front, "scale", Vector2.ONE * 1.18, DEATH_DURATION * 0.46)
	echo_tween.tween_property(death_echo_front, "modulate:a", 0.0, DEATH_DURATION * 0.38)

func _get_pale_color(c: Color) -> Color:
	# Desaturate toward gray, then lighten slightly — simulates life draining.
	var gray := (c.r + c.g + c.b) / 3.0
	return Color(
		lerp(lerp(c.r, gray, 0.45), 0.86, 0.25),
		lerp(lerp(c.g, gray, 0.45), 0.86, 0.25),
		lerp(lerp(c.b, gray, 0.45), 0.86, 0.25),
		c.a
	)

func _pale_lerp(c: Color, amount: float) -> Color:
	var gray := (c.r + c.g + c.b) / 3.0
	return Color(
		lerp(c.r, lerp(gray, 0.86, 0.4), amount),
		lerp(c.g, lerp(gray, 0.86, 0.4), amount),
		lerp(c.b, lerp(gray, 0.86, 0.4), amount),
		c.a
	)

func _spawn_death_burst(pale: Color) -> void:
	var burst := CPUParticles2D.new()
	burst.emitting = false
	burst.one_shot = true
	burst.explosiveness = 0.95
	burst.amount = 18
	burst.lifetime = 0.55
	burst.spread = 180.0
	burst.initial_velocity_min = 45.0
	burst.initial_velocity_max = 120.0
	burst.scale_amount_min = 2.5
	burst.scale_amount_max = 4.8
	burst.gravity = Vector2.ZERO
	burst.color = Color(pale.r, pale.g, pale.b, 0.85)
	burst.position = Vector2.ZERO
	burst.z_index = 1
	add_child(burst)
	burst.emitting = true
