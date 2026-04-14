extends SceneTree

const PLAYER_SCENE_PATH := "res://scenes/tests/Brunich/test_character_shaders.tscn"
const AI_CORE_WEAPON_SCENE_PATH := "res://scenes/tests/Brunich/enemy_ai_core_weapon.tscn"
const REGULATED_ENEMY_SCENE_PATH := "res://scenes/tests/Brunich/enemy_regulated.tscn"
const PICKUP_SCRIPT := preload("res://scenes/tests/Brunich/enemy_attack_pickup.gd")

var _failures: Array[String] = []
var _completed := false

func _initialize() -> void:
	print("START brunich_stolen_ai_beam_smoke")
	call_deferred("_arm_timeout")
	call_deferred("_run")

func _run() -> void:
	var world := Node2D.new()
	root.add_child(world)

	var player := load(PLAYER_SCENE_PATH).instantiate() as CharacterBody2D
	player.global_position = Vector2(180.0, 280.0)
	world.add_child(player)
	await _wait_frames(2)

	var weapon: Node = load(AI_CORE_WEAPON_SCENE_PATH).instantiate()
	world.add_child(weapon)
	await _wait_frames(1)
	var profile: Dictionary = weapon.get_attack_profile_for_player()
	weapon.queue_free()

	var pickup = PICKUP_SCRIPT.new()
	pickup.configure(player.global_position + Vector2(14.0, 0.0), profile)
	world.add_child(pickup)
	await _wait_frames(1)

	_expect(player.try_steal_attack(), "el MC debe poder robar el beam del AI core")
	var beam_profile: Dictionary = player.Weapon.get("_current_beam_profile")
	_expect(is_equal_approx(float(beam_profile.get("beam_width", -1.0)), 30.0), "el beam robado debe reducir su ancho visual cerca de 25 por ciento")
	_expect(is_equal_approx(float(beam_profile.get("warning_width", -1.0)), 13.5), "el warning del beam robado tambien debe reducirse cerca de 25 por ciento")

	var front_enemy := _spawn_dummy_enemy(world, Vector2(420.0, 280.0))
	var back_enemy := _spawn_dummy_enemy(world, Vector2(610.0, 280.0))
	await _wait_frames(2)

	player.Weapon._shoot(Vector2.RIGHT)
	await _wait_frames(52)
	var beam := _find_owned_beam(world, player)
	_expect(beam != null, "el beam robado del AI core debe aparecer al disparar")
	if beam == null:
		_finish(world)
		return

	var locked_rotation := beam.rotation
	player.Weapon._shoot(Vector2.UP)
	await _wait_frames(6)
	_expect(absf(wrapf(beam.rotation - locked_rotation, -PI, PI)) < 0.03, "el beam robado debe quedarse fijo donde disparo y no seguir rotando durante el disparo")

	var front_health_before: int = front_enemy.HealthComp.get_health()
	var back_health_before: int = back_enemy.HealthComp.get_health()
	await _wait_frames(18)
	_expect(front_enemy.HealthComp.get_health() < front_health_before, "el primer enemigo enfrente del beam robado debe recibir dano")
	_expect(back_enemy.HealthComp.get_health() == back_health_before, "el beam robado no debe atravesar enemigos colocados detras del primero")

	_finish(world)

func _spawn_dummy_enemy(world: Node, position: Vector2) -> CharacterBody2D:
	var enemy := load(REGULATED_ENEMY_SCENE_PATH).instantiate() as CharacterBody2D
	enemy.global_position = position
	enemy.MoveSpeed = 0.0
	enemy.StrafeSpeed = 0.0
	enemy.DodgeSpeed = 0.0
	enemy.ProjectileAlertRange = 0.0
	world.add_child(enemy)
	var weapon := enemy.get_node_or_null("enemy_weapon")
	if weapon != null:
		weapon.process_mode = Node.PROCESS_MODE_DISABLED
	return enemy

func _find_owned_beam(world: Node, owner: Node) -> Node2D:
	for beam in world.get_tree().get_nodes_in_group("enemy_ai_beam"):
		if beam.Owner == owner:
			return beam as Node2D
	return null

func _finish(world: Node) -> void:
	world.queue_free()
	await _wait_frames(1)
	_completed = true
	if _failures.is_empty():
		print("PASS brunich_stolen_ai_beam_smoke")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)

func _arm_timeout() -> void:
	await create_timer(10.0).timeout
	if _completed:
		return
	push_error("brunich_stolen_ai_beam_smoke timeout")
	quit(2)

func _wait_frames(count: int) -> void:
	for _i in range(count):
		await physics_frame

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
