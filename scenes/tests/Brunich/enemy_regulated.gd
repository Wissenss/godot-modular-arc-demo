class_name EnemyRegulated extends CharacterBody2D

const MAX_HEALTH := 320
const MOVE_SPEED := 132.0
const STRAFE_SPEED := 96.0
const DODGE_SPEED := 220.0
const DODGE_DURATION := 0.28
const DODGE_COOLDOWN := 0.85
const DESIRED_RANGE_MIN := 220.0
const DESIRED_RANGE_MAX := 380.0
const PROJECTILE_ALERT_RANGE := 250.0
const ARENA_MIN := Vector2(54, 52)
const ARENA_MAX := Vector2(1226, 610)

const BASE_COLOR := Color(0.16, 0.82, 1.0, 1.0)
const HIT_COLOR := Color(1.0, 1.0, 1.0, 1.0)

var HitboxComp: HitboxComponent
var HealthComp: HealthComponent
var Weapon: EnemyWeapon
var Polygon: Polygon2D
var ShieldPoly: Polygon2D
var BodyParticles: CPUParticles2D
var OrbitParticles: CPUParticles2D

var _combat_time := 0.0
var _alive := true
var _dodge_timer := 0.0
var _dodge_cooldown := 0.0
var _dodge_vector := Vector2.ZERO

func _ready() -> void:
	self.Polygon = $polygon
	self.ShieldPoly = $shield_poly
	self.BodyParticles = $body_particles
	self.OrbitParticles = $orbit_particles

	self.HitboxComp = $hitbox_comp
	self.HitboxComp.Owner = self
	self.HitboxComp.on_hit.connect(self._handle_on_hit)

	self.HealthComp = $health_comp
	self.HealthComp.set_max_health(MAX_HEALTH)
	self.HealthComp.set_health(MAX_HEALTH)
	self.HealthComp.on_died.connect(self._handle_on_died)

	self.Weapon = $enemy_weapon
	self.Weapon.Owner = self

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
		velocity = _dodge_vector * DODGE_SPEED
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
	var orbit_sign := 1.0 if sin(_combat_time * 1.7) >= 0.0 else -1.0
	var move := orbit * STRAFE_SPEED * orbit_sign

	if distance > DESIRED_RANGE_MAX:
		move += dir_to_player * MOVE_SPEED
	elif distance < DESIRED_RANGE_MIN:
		move -= dir_to_player * MOVE_SPEED * 0.9
	else:
		move += dir_to_player * 28.0

	return move.limit_length(MOVE_SPEED + STRAFE_SPEED * 0.75)

func _try_start_dodge(player: Node2D) -> void:
	if _dodge_cooldown > 0.0:
		return

	for projectile in get_tree().get_nodes_in_group("player_projectile"):
		if projectile.Owner == self:
			continue

		var to_enemy: Vector2 = global_position - projectile.global_position
		if to_enemy.length() > PROJECTILE_ALERT_RANGE:
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
		_dodge_timer = DODGE_DURATION
		_dodge_cooldown = DODGE_COOLDOWN
		return

func _update_visuals() -> void:
	var pulse := sin(_combat_time * 3.8) * 0.5 + 0.5
	self.ShieldPoly.color.a = 0.08 + pulse * 0.09
	self.BodyParticles.color = Color(0.0, 0.85, 1.0, 0.35 + pulse * 0.2)
	self.OrbitParticles.orbit_velocity_min = -0.4 - pulse * 0.3
	self.OrbitParticles.orbit_velocity_max = 0.4 + pulse * 0.3

func _get_player() -> Node2D:
	var players := get_tree().get_nodes_in_group("player")
	return players[0] as Node2D if not players.is_empty() else null

func _handle_on_hit(by: Area2D) -> void:
	if by is HurtboxComponent:
		if by.Owner == self:
			return

		self.HealthComp.take_damage(by.Damage)
		_do_hit_flash()

func _do_hit_flash() -> void:
	self.Polygon.color = HIT_COLOR
	self.ShieldPoly.color = Color(1.0, 1.0, 1.0, 0.18)
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(self):
		self.Polygon.color = BASE_COLOR

func _handle_on_died() -> void:
	_alive = false
	queue_free()
