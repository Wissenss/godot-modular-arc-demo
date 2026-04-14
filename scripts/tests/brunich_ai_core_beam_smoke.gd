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
	player.global_position = Vector2(860.0, 320.0)
	world.add_child(player)

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
		_expect(float(beam_profile.get("active_duration", 0.0)) >= 1.15 and float(beam_profile.get("active_duration", 0.0)) <= 1.25, "el beam del AI core debe quedarse clavado cerca de 1.2 segundos despues de disparar")
		_expect(float(beam_profile.get("track_speed", 0.0)) >= 430.0, "el beam del AI core debe rastrear con una agresividad aun mayor en esta iteracion")
		_expect(int(beam_profile.get("damage_per_tick", 0)) <= 26, "el beam del AI core debe bajar su dano cerca de 30 por ciento en esta iteracion")
		_expect(is_equal_approx(float(weapon.ShootInterval), 0.6), "el AI core debe volver a disparar justo cuando regresa el dash base sin mejoras")
		weapon._shoot_timer = weapon.ShootInterval

	var face_shell := enemy.get_node_or_null("face_shell") as Polygon2D
	var start_scale := face_shell.scale if face_shell != null else Vector2.ONE
	await _wait_frames(12)
	if face_shell != null:
		_expect(face_shell.scale.distance_to(start_scale) > 0.01, "el chip central del AI core debe respirar con un pulso visible")

	await _wait_frames(4)
	var beams := _find_owned_beams(world, enemy)
	_expect(not beams.is_empty(), "el AI core debe disparar un beam sostenido")
	if beams.is_empty():
		_finish(world)
		return

	var beam := beams[0] as Node2D
	await _wait_frames(45)
	_expect(beam.BeamOuter.polygon.size() >= 10, "el beam del AI core debe construirse con un contorno mas quebrado y no verse como una simple franja")
	_expect(beam.BeamCore.polygon.size() >= 10, "el nucleo del beam tambien debe sentirse como rayo y no como una luz lisa")
	_expect(beam.BeamPixels.get_child_count() >= 24, "el beam del AI core debe construir bastantes pixeles electricos visibles a lo largo del rayo")
	var locked_rotation := beam.rotation
	player.global_position = Vector2(860.0, 200.0)
	await _wait_frames(10)
	_expect(absf(wrapf(beam.rotation - locked_rotation, -PI, PI)) < 0.03, "cuando el beam del AI core ya disparo debe quedarse fijo en el angulo marcado y no seguir persiguiendo")
	player.global_position = Vector2(860.0, 320.0)
	await _wait_frames(6)
	var health_before_beam: int = player.HealthComp.get_health()
	await _wait_frames(14)
	_expect(player.HealthComp.get_health() < player.HealthComp.get_max_health(), "el beam del AI core debe hacer dano por segundo al tocar al jugador")
	var dashed: bool = player.request_dash(Vector2.UP)
	_expect(dashed, "el jugador debe poder intentar el dash justo a tiempo contra el beam del AI core")
	_expect(player.DashCharges == 0, "el dash debe gastar la unica carga disponible al esquivar el beam")
	await _wait_frames(4)
	_expect(not beam.HurtboxComp.monitoring, "si el dash entra justo a tiempo el beam del AI core debe descargarse y dejar de hacer dano")
	var health_after_dash: int = player.HealthComp.get_health()
	await _wait_frames(18)
	_expect(player.HealthComp.get_health() >= health_after_dash, "despues del dash correcto el beam del AI core no debe seguir drenando vida")
	_expect(not is_instance_valid(beam) or beam.is_queued_for_deletion(), "despues de descargarse el beam del AI core debe apagarse antes del siguiente ciclo")
	await _wait_physics_frames(12)
	_expect(player.DashCharges == 0, "el dash base aun no debe volver antes de 0.6 segundos")
	_expect(_find_owned_beams(world, enemy).is_empty(), "el AI core no debe volver a crear otro beam antes de que regrese el dash base")
	await _wait_physics_frames(28)
	_expect(player.DashCharges == 1, "el dash base debe volver cerca de 0.6 segundos sin mejoras")
	_expect(not _find_owned_beams(world, enemy).is_empty(), "cuando vuelve el dash base el AI core tambien debe estar listo para crear otro beam")

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

func _wait_physics_frames(count: int) -> void:
	for _i in range(count):
		await physics_frame

func _find_owned_beams(world: Node, owner: Node) -> Array[Node2D]:
	var beams: Array[Node2D] = []
	for beam in world.get_tree().get_nodes_in_group("enemy_ai_beam"):
		if beam.Owner == owner:
			beams.append(beam as Node2D)
	return beams

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
