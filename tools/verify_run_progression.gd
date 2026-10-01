extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _run() -> void:
	var manager := root.get_node("SaveManager")
	if not String(manager.get("storage_directory")).begins_with("user://tests/"):
		quit(2)
		return
	var path := String(manager.get("storage_directory")).path_join("save_slot_0.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"run_count": 7, "resources": 37, "has_intro_played": true, "upgrades": {"max_hp_bonus": 25}}))
	file.close()
	manager.call("load_slot", 0)
	var data: Dictionary = manager.get("data")
	_check(int(data.get("attempt_count", -1)) == 7, "Migrar inicios antiguos a intentos")
	_check(int(data.get("completed_runs", -1)) == 0, "No inventar victorias antiguas")
	_check(manager.call("get_resources") == 37, "Conservar recursos")
	_check(int(manager.call("get_upgrades").get("max_hp_bonus")) == 25, "Conservar mejoras")
	if manager.has_method("start_attempt"):
		manager.call("start_attempt")
		manager.call("complete_run")
		manager.call("complete_run")
		_check(manager.call("get_attempt_count") == 8, "Contar un inicio")
		_check(manager.call("get_completed_runs") == 1, "Final idempotente")
		manager.call("start_attempt")
		manager.call("record_death")
		manager.call("record_death")
		_check(manager.call("get_completed_runs") == 1, "Morir no suma victoria")
		_check(int(manager.get("data").get("deaths", 0)) == 1, "Muerte idempotente")
		manager.call("load_slot", 0)
		_check(manager.call("get_attempt_count") == 9, "Persistir intentos")
		_check(not manager.get("data").has("run_count"), "Retirar contador ambiguo")
		manager.call("load_slot", 1)
		manager.call("start_attempt")
		var world := load("res://scenes/tests/Brunich/Brunich_tests.tscn").instantiate() as Node
		world.set("DisableSceneReloadForTests", true)
		root.add_child(world)
		world.get("_narrative").call("stop")
		var player: Node2D = world.get_node("MC")
		var enemy: Node2D = world.get_node("EnemyRegulated")
		enemy.global_position = player.global_position + Vector2(30, 0)
		var health := enemy.get_node("health_comp")
		health.call("take_damage", int(health.call("get_max_health")) - 1)
		var cycles: float = player.get("Ciclos")
		_check(not bool(player.call("try_hackeo")), "Hackeo bloqueado antes de completar la primera run")
		_check(is_equal_approx(float(player.get("Ciclos")), cycles), "Hackeo bloqueado no consume ciclos")
		world.call("debug_configure_progression_for_tests", 3, 10)
		world.get("_narrative").call("stop")
		world.call("_advance_room")
		_check(manager.call("get_completed_runs") == 1, "Primera run termina tras tres capas")
		_check(int(world.get("CurrentBiomeIndex")) == 3, "No avanzar a cuarta capa antes del primer final")
		world.call("_advance_room")
		_check(int(world.get("CurrentBiomeIndex")) == 3, "No avanzar mientras se cierra la run")
		world.queue_free()
		await process_frame
		await process_frame
		manager.call("start_attempt")
		world = load("res://scenes/tests/Brunich/Brunich_tests.tscn").instantiate() as Node
		world.set("DisableSceneReloadForTests", true)
		root.add_child(world)
		world.get("_narrative").call("stop")
		player = world.get_node("MC")
		enemy = world.get_node("EnemyRegulated")
		enemy.global_position = player.global_position + Vector2(30, 0)
		health = enemy.get_node("health_comp")
		health.call("take_damage", int(health.call("get_max_health")) - 1)
		_check(bool(player.call("try_hackeo")), "Hackeo disponible después del primer final")
		world.call("debug_configure_progression_for_tests", 4, 10)
		world.get("_narrative").call("stop")
		world.call("_advance_room")
		_check(manager.call("get_completed_runs") == 2, "Siguientes runs terminan tras cuatro capas")
		_check(int(world.get("CurrentBiomeIndex")) == 4, "No crear bioma cinco interminable")
		manager.call("start_attempt")
		world.call("_handle_player_died")
		_check(int(manager.get("data").get("deaths", 0)) == 1, "Muerte real registra resultado")
		world.queue_free()
		await process_frame
		await process_frame
	else:
		failures.append("Falta ciclo de intento y final")
	if failures.is_empty():
		print("PASS migración y contadores de progresión")
	else:
		for failure in failures:
			push_error(failure)
	quit(0 if failures.is_empty() else 1)
