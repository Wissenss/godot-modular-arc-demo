extends SceneTree

const SPREAD_WEAPON_SCENE := "res://scenes/tests/Brunich/enemy_spread_weapon.tscn"
const PIERCE_WEAPON_SCENE := "res://scenes/tests/Brunich/enemy_pierce_weapon.tscn"
const ORB_WEAPON_SCENE := "res://scenes/tests/Brunich/enemy_weapon.tscn"
const SLOWBEAM_WEAPON_SCENE := "res://scenes/tests/Brunich/enemy_slowbeam_weapon.tscn"
const AI_CORE_WEAPON_SCENE := "res://scenes/tests/Brunich/enemy_ai_core_weapon.tscn"
const PLAYER_SCENE := "res://scenes/tests/Brunich/test_character_shaders.tscn"
const PROJECTILE_SCENE := "res://scenes/tests/Brunich/enemy_projectile.tscn"

var _failures: Array[String] = []
var _completed := false

func _initialize() -> void:
	print("START brunich_attack_balance_smoke")
	call_deferred("_arm_timeout")
	call_deferred("_run")

func _run() -> void:
	var world := Node2D.new()
	root.add_child(world)

	var orb_weapon: Node = load(ORB_WEAPON_SCENE).instantiate()
	world.add_child(orb_weapon)
	await _wait_frames(1)
	var orb_shoot_interval := float(orb_weapon.ShootInterval)
	var orb_pickup_profile: Dictionary = orb_weapon.get_attack_profile_for_player()
	var orb_live_profile: Dictionary = orb_weapon._get_projectile_profile()
	_expect(is_equal_approx(float(orb_weapon.ShootInterval), 0.496), "el enemigo orbe debe disparar 20 por ciento mas seguido")
	_expect(is_equal_approx(float(orb_weapon.PROJECTILE_SPEED), 471.5), "el proyectil basico enemigo debe viajar 15 por ciento mas rapido")
	_expect(is_equal_approx(float(orb_pickup_profile.get("shoot_cooldown", -1.0)), float(orb_weapon.ShootInterval)), "enemy_orb robado debe conservar la misma cadencia base del enemigo")
	_expect(is_equal_approx(float(orb_pickup_profile.get("projectile_speed", -1.0)), float(orb_weapon.PROJECTILE_SPEED)), "enemy_orb robado debe conservar la misma velocidad del enemigo")
	_expect(int(orb_pickup_profile.get("projectile_profile", {}).get("damage", -1)) == int(orb_live_profile.get("damage", -2)), "enemy_orb robado debe conservar el mismo dano del enemigo")
	orb_weapon.queue_free()

	var spread_weapon: Node = load(SPREAD_WEAPON_SCENE).instantiate()
	world.add_child(spread_weapon)
	await _wait_frames(1)
	var spread_pickup_profile: Dictionary = spread_weapon.get_attack_profile_for_player()
	var spread_live_profile: Dictionary = spread_weapon._get_projectile_profile()
	_expect(is_equal_approx(float(spread_weapon.ShootInterval), 0.84), "la escopeta enemiga debe disparar 20 por ciento mas seguido")
	_expect(is_equal_approx(float(spread_weapon.PROJECTILE_SPEED), 483.0), "la escopeta enemiga debe lanzar pellets 15 por ciento mas rapidos")
	_expect(int(spread_live_profile.get("damage", -1)) == 2, "la escopeta enemiga debe bajar a 2 de dano por pellet")
	_expect(is_equal_approx(float(spread_pickup_profile.get("shoot_cooldown", -1.0)), float(spread_weapon.ShootInterval)), "la escopeta robada debe conservar la misma cadencia base del enemigo")
	_expect(is_equal_approx(float(spread_pickup_profile.get("projectile_speed", -1.0)), float(spread_weapon.PROJECTILE_SPEED)), "la escopeta robada debe conservar la misma velocidad del enemigo")
	_expect(int(spread_pickup_profile.get("projectile_profile", {}).get("damage", -1)) == 2, "la escopeta robada debe mantener 2 de dano por pellet")
	spread_weapon.queue_free()

	var pierce_weapon: Node = load(PIERCE_WEAPON_SCENE).instantiate()
	world.add_child(pierce_weapon)
	await _wait_frames(1)
	var pierce_pickup_profile: Dictionary = pierce_weapon.get_attack_profile_for_player()
	var pierce_live_profile: Dictionary = pierce_weapon._get_projectile_profile()
	_expect(is_equal_approx(float(pierce_weapon.ShootInterval), 2.28), "el pierce enemigo debe disparar 20 por ciento mas seguido")
	_expect(is_equal_approx(float(pierce_weapon.PROJECTILE_SPEED), 687.7), "el proyectil pierce enemigo debe viajar 15 por ciento mas rapido sobre su nueva base")
	_expect(int(pierce_live_profile.get("damage", -1)) >= 62, "el pierce debe subir mucho su dano")
	_expect(is_equal_approx(float(pierce_pickup_profile.get("shoot_cooldown", -1.0)), float(pierce_weapon.ShootInterval)), "el pierce robado debe conservar la misma cadencia base del enemigo")
	_expect(is_equal_approx(float(pierce_pickup_profile.get("projectile_speed", -1)), 687.7), "el pierce robado debe conservar la nueva velocidad del proyectil")
	_expect(int(pierce_pickup_profile.get("projectile_profile", {}).get("damage", -1)) >= 62, "el pierce robado debe conservar el dano alto")
	_expect(int(pierce_live_profile.get("pierce_count", 0)) == -1, "el pierce debe atravesar todo sin agotarse")
	_expect(int(pierce_pickup_profile.get("projectile_profile", {}).get("pierce_count", 0)) == -1, "el pierce robado tambien debe atravesar todo")
	pierce_weapon.queue_free()

	var slowbeam_weapon: Node = load(SLOWBEAM_WEAPON_SCENE).instantiate()
	world.add_child(slowbeam_weapon)
	await _wait_frames(1)
	var slowbeam_pickup_profile: Dictionary = slowbeam_weapon.get_attack_profile_for_player()
	var slowbeam_live_profile: Dictionary = slowbeam_weapon._get_projectile_profile()
	_expect(is_equal_approx(float(slowbeam_weapon.ShootInterval), 1.24), "el slowbeam enemigo debe disparar 20 por ciento mas seguido")
	_expect(is_equal_approx(float(slowbeam_weapon.PROJECTILE_SPEED), 454.25), "el slowbeam enemigo debe viajar 15 por ciento mas rapido")
	_expect(is_equal_approx(float(slowbeam_pickup_profile.get("shoot_cooldown", -1.0)), float(slowbeam_weapon.ShootInterval)), "el slowbeam robado debe conservar la misma cadencia base del enemigo")
	_expect(is_equal_approx(float(slowbeam_pickup_profile.get("projectile_speed", -1.0)), float(slowbeam_weapon.PROJECTILE_SPEED)), "el slowbeam robado debe conservar la misma velocidad del enemigo")
	_expect(int(slowbeam_pickup_profile.get("projectile_profile", {}).get("damage", -1)) == int(slowbeam_live_profile.get("damage", -2)), "el slowbeam robado debe conservar el mismo dano del enemigo")
	slowbeam_weapon.queue_free()

	var ai_core_weapon: Node = load(AI_CORE_WEAPON_SCENE).instantiate()
	world.add_child(ai_core_weapon)
	await _wait_frames(1)
	var ai_beam_pickup_profile: Dictionary = ai_core_weapon.get_attack_profile_for_player()
	var ai_beam_live_profile: Dictionary = ai_core_weapon._get_beam_profile()
	_expect(is_equal_approx(float(ai_core_weapon.ShootInterval), 1.16), "el AI core tambien debe respetar la subida global de cadencia")
	_expect(float(ai_core_weapon._get_beam_profile().get("track_speed", 0.0)) >= 430.0, "el beam del AI core tambien debe perseguir 15 por ciento mas rapido")
	_expect(int(ai_core_weapon._get_beam_profile().get("damage_per_tick", -1)) >= 36, "el beam del AI core debe reflejar el nuevo dano doblado")
	_expect(is_equal_approx(float(ai_beam_pickup_profile.get("shoot_cooldown", -1.0)), float(ai_core_weapon.ShootInterval)), "el beam robado del AI core debe conservar la misma cadencia base del enemigo")
	_expect(float(ai_beam_pickup_profile.get("beam_profile", {}).get("track_speed", 0.0)) >= float(ai_beam_live_profile.get("track_speed", 0.0)), "el beam robado del AI core debe conservar el tracking fuerte del enemigo")
	_expect(int(ai_beam_pickup_profile.get("beam_profile", {}).get("damage_per_tick", -1)) == int(ai_beam_live_profile.get("damage_per_tick", -2)), "el beam robado del AI core debe conservar el mismo dano del enemigo")
	ai_core_weapon.queue_free()

	var player := load(PLAYER_SCENE).instantiate() as CharacterBody2D
	world.add_child(player)
	await _wait_frames(2)
	_expect(is_equal_approx(float(player.Weapon.get("_current_shoot_cooldown")), 0.10), "todas las armas del MC deben disparar 25 por ciento mas lento por defecto")
	var start_pos := player.global_position
	var dashed: bool = player.request_dash(Vector2.RIGHT)
	_expect(dashed, "el jugador debe poder disparar un dash de prueba para validar su alcance")
	await _wait_physics_frames(8)
	var dash_distance := player.global_position.distance_to(start_pos)
	_expect(dash_distance >= 88.0 and dash_distance <= 94.0, "el dash debe extenderse cerca de un 10 por ciento respecto al ajuste anterior")
	player.Weapon.equip_enemy_attack(orb_pickup_profile)
	_expect(is_equal_approx(float(player.Weapon.get("_current_shoot_cooldown")), orb_shoot_interval * 1.25), "las armas robadas del MC deben respetar la bajada global de cadencia del jugador")
	player.queue_free()

	var projectile := load(PROJECTILE_SCENE).instantiate() as Node2D
	world.add_child(projectile)
	projectile.configure_projectile({
		"damage": 62,
		"pierce_count": -1,
		"life_time": 5.0,
	})
	await _wait_frames(1)
	var fake_hitbox := HitboxComponent.new()
	projectile._handle_on_hurt(fake_hitbox, 62)
	projectile._handle_on_hurt(fake_hitbox, 62)
	_expect(not projectile.is_queued_for_deletion(), "un proyectil pierce infinito no debe destruirse al atravesar varios objetivos")
	fake_hitbox.queue_free()

	world.queue_free()
	await _wait_frames(1)
	_completed = true
	if _failures.is_empty():
		print("PASS brunich_attack_balance_smoke")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)

func _arm_timeout() -> void:
	await create_timer(8.0).timeout
	if _completed:
		return
	push_error("brunich_attack_balance_smoke timeout")
	quit(2)

func _wait_frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _wait_physics_frames(count: int) -> void:
	for _i in range(count):
		await physics_frame

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
