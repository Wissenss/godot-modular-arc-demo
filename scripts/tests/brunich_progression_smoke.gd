extends SceneTree

const SCENE_PATH := "res://scenes/tests/Brunich/Brunich_tests.tscn"

var _failures: Array[String] = []
var _completed := false

func _initialize() -> void:
	print("START brunich_progression_smoke")
	call_deferred("_arm_timeout")
	call_deferred("_run")

func _run() -> void:
	var world: Node = load(SCENE_PATH).instantiate()
	if _has_property(world, "DisableSceneReloadForTests"):
		world.DisableSceneReloadForTests = true
	root.add_child(world)

	await _wait_frames(2)

	var floor_tiles := world.get_node("floor_tiles")
	var player := world.get_node("MC") as Node2D

	_expect(_has_property(world, "CurrentBiomeIndex"), "Brunich debe exponer el bioma actual")
	_expect(_has_property(world, "CurrentBiomeRoomNumber"), "Brunich debe exponer el numero de cuarto dentro del bioma")
	_expect(_has_property(world, "CurrentLayoutId"), "Brunich debe exponer el layout actual del cuarto")
	_expect(_has_property(world, "IsBossRoom"), "Brunich debe indicar si el cuarto actual es boss room")
	_expect(world.has_method("get_active_room_enemy_count"), "Brunich debe exponer cuantos enemigos vivos tiene el cuarto actual")
	_expect(world.has_method("get_active_room_enemies"), "Brunich debe exponer la lista de enemigos vivos del cuarto actual")
	_expect(world.has_method("debug_force_room_completion_for_tests"), "Brunich debe permitir completar la sala actual en pruebas")
	_expect(world.has_method("debug_configure_progression_for_tests"), "Brunich debe permitir fijar un cuarto/bioma para pruebas")
	_expect(floor_tiles.has_method("get_layout_id"), "el generador del mapa debe exponer el layout activo")

	if world.has_method("get_active_room_enemy_count"):
		_expect(world.get_active_room_enemy_count() == 1, "el primer cuarto debe arrancar con un solo enemigo")
	if _has_property(world, "CurrentBiomeIndex"):
		_expect(int(world.CurrentBiomeIndex) == 1, "el run debe arrancar en el bioma 1")
	if _has_property(world, "CurrentBiomeRoomNumber"):
		_expect(int(world.CurrentBiomeRoomNumber) == 1, "el run debe arrancar en el cuarto 1")

	var initial_layout := ""
	if _has_property(world, "CurrentLayoutId"):
		initial_layout = String(world.CurrentLayoutId)

	if world.has_method("debug_force_room_completion_for_tests"):
		world.debug_force_room_completion_for_tests()
	await _wait_frames(1)

	player.global_position = Vector2((17.0 * 32.0 + 23.0 * 32.0) * 0.5, 44.0)
	await _wait_frames(2)
	if world.has_method("debug_try_context_action"):
		world.debug_try_context_action()
	await _wait_frames(2)

	if _has_property(world, "CurrentBiomeRoomNumber"):
		_expect(int(world.CurrentBiomeRoomNumber) == 2, "al abrir la puerta debe avanzar al cuarto 2 del bioma")
	if _has_property(world, "CurrentLayoutId"):
		_expect(String(world.CurrentLayoutId) != initial_layout, "al cambiar de cuarto el layout no debe repetirse inmediatamente")
	if world.has_method("get_active_room_enemy_count"):
		_expect(world.get_active_room_enemy_count() >= 2, "el siguiente cuarto debe subir la cantidad de enemigos")
	if world.has_method("get_active_room_enemies"):
		var roster: Dictionary = {}
		for enemy in world.get_active_room_enemies():
			if not is_instance_valid(enemy):
				continue
			roster[String(enemy.scene_file_path)] = true
		_expect(roster.size() >= 2, "el siguiente cuarto debe introducir variedad de enemigos")

	if world.has_method("debug_configure_progression_for_tests"):
		world.debug_configure_progression_for_tests(1, 10)
		await _wait_frames(2)
		if _has_property(world, "IsBossRoom"):
			_expect(bool(world.IsBossRoom), "el cuarto 10 de un bioma debe ser boss room")
		if world.has_method("get_active_room_enemy_count"):
			_expect(world.get_active_room_enemy_count() == 1, "la boss room debe tener un solo enemigo activo")
		if world.has_method("get_active_room_enemies"):
			var boss_roster: Array = world.get_active_room_enemies()
			if not boss_roster.is_empty():
				var boss: Node = boss_roster[0]
				var health_comp = boss.get_node_or_null("health_comp")
				if health_comp != null:
					_expect(health_comp.get_max_health() >= 700, "el boss placeholder debe tener mucha mas vida que una sala normal")
		if world.has_method("debug_force_room_completion_for_tests"):
			world.debug_force_room_completion_for_tests()
		await _wait_frames(1)
		player.global_position = Vector2((17.0 * 32.0 + 23.0 * 32.0) * 0.5, 44.0)
		await _wait_frames(2)
		if world.has_method("debug_try_context_action"):
			world.debug_try_context_action()
		await _wait_frames(2)
		if _has_property(world, "CurrentBiomeIndex"):
			_expect(int(world.CurrentBiomeIndex) == 2, "al salir del cuarto 10 debe avanzar al siguiente bioma")
		if _has_property(world, "CurrentBiomeRoomNumber"):
			_expect(int(world.CurrentBiomeRoomNumber) == 1, "al entrar al siguiente bioma el contador de cuarto debe reiniciarse")

	_completed = true
	if _failures.is_empty():
		print("PASS brunich_progression_smoke")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)

func _arm_timeout() -> void:
	await create_timer(10.0).timeout
	if _completed:
		return
	push_error("brunich_progression_smoke timeout")
	quit(2)

func _wait_frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _has_property(node: Object, property_name: String) -> bool:
	for prop in node.get_property_list():
		if prop.name == property_name:
			return true
	return false
