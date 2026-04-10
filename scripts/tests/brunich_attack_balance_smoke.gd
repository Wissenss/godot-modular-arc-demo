extends SceneTree

const SPREAD_WEAPON_SCENE := "res://scenes/tests/Brunich/enemy_spread_weapon.tscn"
const PIERCE_WEAPON_SCENE := "res://scenes/tests/Brunich/enemy_pierce_weapon.tscn"
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

	var spread_weapon: Node = load(SPREAD_WEAPON_SCENE).instantiate()
	world.add_child(spread_weapon)
	await _wait_frames(1)
	var spread_pickup_profile: Dictionary = spread_weapon.get_attack_profile_for_player()
	var spread_live_profile: Dictionary = spread_weapon._get_projectile_profile()
	_expect(int(spread_live_profile.get("damage", -1)) == 6, "la escopeta enemiga debe bajar a 6 de dano por pellet")
	_expect(int(spread_pickup_profile.get("projectile_profile", {}).get("damage", -1)) == 6, "la escopeta robada debe mantener 6 de dano por pellet")
	spread_weapon.queue_free()

	var pierce_weapon: Node = load(PIERCE_WEAPON_SCENE).instantiate()
	world.add_child(pierce_weapon)
	await _wait_frames(1)
	var pierce_pickup_profile: Dictionary = pierce_weapon.get_attack_profile_for_player()
	var pierce_live_profile: Dictionary = pierce_weapon._get_projectile_profile()
	_expect(int(round(float(pierce_weapon.PROJECTILE_SPEED))) == 598, "el proyectil pierce debe subir su velocidad 30 por ciento")
	_expect(int(pierce_live_profile.get("damage", -1)) >= 62, "el pierce debe subir mucho su dano")
	_expect(int(pierce_pickup_profile.get("projectile_speed", -1)) == 598, "el pierce robado debe conservar la velocidad nueva")
	_expect(int(pierce_pickup_profile.get("projectile_profile", {}).get("damage", -1)) >= 62, "el pierce robado debe conservar el dano alto")
	_expect(int(pierce_live_profile.get("pierce_count", 0)) == -1, "el pierce debe atravesar todo sin agotarse")
	_expect(int(pierce_pickup_profile.get("projectile_profile", {}).get("pierce_count", 0)) == -1, "el pierce robado tambien debe atravesar todo")
	pierce_weapon.queue_free()

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

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
