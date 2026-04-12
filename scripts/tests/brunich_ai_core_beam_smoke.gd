extends SceneTree

const PLAYER_SCENE_PATH := "res://scenes/tests/Brunich/test_character_shaders.tscn"
const AI_CORE_SCENE_PATH := "res://scenes/tests/Brunich/enemy_ai_core.tscn"
const BLOCKER_SCENE_PATH := "res://scenes/tests/Brunich/enemy_regulated.tscn"

var _failures: Array[String] = []
var _completed := false

func _initialize() -> void:
	print("START brunich_ai_core_beam_smoke")
	call_deferred("_arm_timeout")
	call_deferred("_run")

func _run() -> void:
	var world := Node2D.new()
	root.add_child(world)

	var player := load(PLAYER_SCENE_PATH).instantiate() as Node2D
	player.global_position = Vector2(940.0, 320.0)
	world.add_child(player)

	var blocker := load(BLOCKER_SCENE_PATH).instantiate() as CharacterBody2D
	blocker.global_position = Vector2(700.0, 320.0)
	blocker.MoveSpeed = 0.0
	blocker.StrafeSpeed = 0.0
	blocker.DodgeSpeed = 0.0
	world.add_child(blocker)

	var enemy := load(AI_CORE_SCENE_PATH).instantiate() as CharacterBody2D
	enemy.global_position = Vector2(420.0, 320.0)
	enemy.MoveSpeed = 0.0
	enemy.StrafeSpeed = 0.0
	enemy.DodgeSpeed = 0.0
	world.add_child(enemy)
	await _wait_frames(3)

	var weapon := enemy.get_node_or_null("enemy_ai_core_weapon")
	_expect(weapon != null, "el AI core debe usar un arma beam propia")
	if weapon != null:
		_expect(String(weapon.get_attack_profile_for_player().get("fire_mode", "")) == "beam", "el ataque robable del AI core debe ser beam")
		var beam_profile: Dictionary = weapon._get_beam_profile()
		_expect(float(beam_profile.get("active_duration", 0.0)) >= 6.0, "el beam del AI core debe durar cerca de 6 segundos antes de enfriarse")
		_expect(float(beam_profile.get("track_speed", 0.0)) >= 430.0, "el beam del AI core debe rastrear con una agresividad aun mayor en esta iteracion")
		_expect(int(beam_profile.get("damage_per_tick", 0)) <= 26, "el beam del AI core debe bajar su dano cerca de 30 por ciento en esta iteracion")
		weapon.ShootInterval = 0.05

	var face_shell := enemy.get_node_or_null("face_shell") as Polygon2D
	var start_scale := face_shell.scale if face_shell != null else Vector2.ONE
	await _wait_frames(12)
	if face_shell != null:
		_expect(face_shell.scale.distance_to(start_scale) > 0.01, "el chip central del AI core debe respirar con un pulso visible")

	await _wait_frames(60)
	var beams := world.get_tree().get_nodes_in_group("enemy_ai_beam")
	_expect(not beams.is_empty(), "el AI core debe disparar un beam sostenido")
	if beams.is_empty():
		_finish(world)
		return

	var beam := beams[0] as Node2D
	_expect(beam.BeamOuter.polygon.size() >= 10, "el beam del AI core debe construirse con un contorno mas quebrado y no verse como una simple franja")
	_expect(beam.BeamCore.polygon.size() >= 10, "el nucleo del beam tambien debe sentirse como rayo y no como una luz lisa")
	_expect(beam.BeamPixels.get_child_count() >= 12, "el beam del AI core debe construir pixeles electricos visibles a lo largo del rayo")
	var start_rotation := beam.rotation
	player.global_position = Vector2(940.0, 180.0)
	await _wait_frames(10)
	_expect(absf(wrapf(beam.rotation - start_rotation, -PI, PI)) > 0.16, "el beam del AI core debe seguir al jugador mientras dura")
	_expect(player.HealthComp.get_health() < player.HealthComp.get_max_health(), "el beam del AI core debe hacer dano por segundo al tocar al jugador")
	var player_damage_taken: int = player.HealthComp.get_max_health() - player.HealthComp.get_health()
	var blocker_damage_taken: int = blocker.HealthComp.get_max_health() - blocker.HealthComp.get_health()
	_expect(blocker_damage_taken > 0, "si un enemigo se pone enfrente del beam tambien debe recibir dano")
	_expect(player_damage_taken < blocker_damage_taken, "un enemigo puesto enfrente debe tapar el beam y reducir el dano al jugador que esta detras")
	await _wait_frames(220)
	_expect(is_instance_valid(beam) and not beam.is_queued_for_deletion(), "el beam del AI core debe mantenerse activo por varios segundos")

	_finish(world)

func _finish(world: Node) -> void:
	world.queue_free()
	await _wait_frames(1)
	_completed = true
	if _failures.is_empty():
		print("PASS brunich_ai_core_beam_smoke")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)

func _arm_timeout() -> void:
	await create_timer(14.0).timeout
	if _completed:
		return
	push_error("brunich_ai_core_beam_smoke timeout")
	quit(2)

func _wait_frames(count: int) -> void:
	for _i in range(count):
		await physics_frame

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
