## brunich_metagame_smoke.gd
## Verifica SaveManager, flujo de escenas, upgrades y sistemas narrativos.
## Correr: godot --headless -s res://scripts/tests/brunich_metagame_smoke.gd
extends SceneTree

var _failures: Array[String] = []
var _checks := 0

func _initialize() -> void:
	print("START brunich_metagame_smoke")
	call_deferred("_run")

func _run() -> void:
	_test_save_manager_basics()
	_test_save_manager_upgrades()
	_test_save_manager_slots_independent()
	_test_narrative_overlay_instantiation()
	_test_npc_narrative_instantiation()
	_test_brunich_tests_loads()
	await _wait_frames(4)
	await _test_brunich_tests_narrative_hooks()
	_report()

# ── SaveManager ───────────────────────────────────────────────────────────────

func _test_save_manager_basics() -> void:
	var sm: Node = root.get_node_or_null("SaveManager")
	_expect(sm != null, "SaveManager debe existir como autoload")
	if sm == null:
		return

	# Cargar slot temporal en un path de test
	sm.load_slot(0)
	_expect(sm.active_slot == 0, "active_slot debe ser 0 tras load_slot(0)")
	_expect(sm.get_resources() >= 0, "recursos deben ser >= 0")
	_expect(sm.get_run_count() >= 0, "run_count debe ser >= 0")

	# Recursos
	var res_before := sm.get_resources()
	sm.add_resources(10)
	_expect(sm.get_resources() == res_before + 10, "add_resources(10) debe sumar 10")
	_expect(sm.get_pending_resources() >= 10, "pending_resources debe incluir lo recién sumado")

	var spent := sm.spend_resources(5)
	_expect(spent, "spend_resources(5) debe devolver true si hay suficiente")
	_expect(sm.get_resources() == res_before + 5, "recursos deben ser res_before+5 tras gastar 5")

	var failed := sm.spend_resources(99999)
	_expect(not failed, "spend_resources con monto excesivo debe devolver false")

	# Limpiar
	sm.data["resources"] = res_before
	sm.data["pending_resources"] = 0

func _test_save_manager_upgrades() -> void:
	var sm: Node = root.get_node_or_null("SaveManager")
	if sm == null:
		return

	sm.load_slot(0)
	var upgrades_before: Dictionary = sm.get_upgrades().duplicate()

	# Cada upgrade acumula correctamente
	sm.apply_upgrade("max_hp_up")
	_expect(int(sm.get_upgrades().get("max_hp_bonus", 0)) == int(upgrades_before.get("max_hp_bonus", 0)) + 25,
		"max_hp_up debe sumar 25 a max_hp_bonus")

	sm.apply_upgrade("max_ciclos_up")
	_expect(int(sm.get_upgrades().get("max_ciclos_bonus", 0)) == int(upgrades_before.get("max_ciclos_bonus", 0)) + 20,
		"max_ciclos_up debe sumar 20 a max_ciclos_bonus")

	sm.apply_upgrade("hackeo_range")
	_expect(float(sm.get_upgrades().get("hackeo_range_bonus", 0.0)) == float(upgrades_before.get("hackeo_range_bonus", 0.0)) + 30.0,
		"hackeo_range debe sumar 30 a hackeo_range_bonus")

	sm.apply_upgrade("hackeo_cost_down")
	_expect(int(sm.get_upgrades().get("hackeo_cost_reduction", 0)) == int(upgrades_before.get("hackeo_cost_reduction", 0)) + 8,
		"hackeo_cost_down debe sumar 8 a hackeo_cost_reduction")

	# dash_recharge no supera 0.6
	for _i in range(8):
		sm.apply_upgrade("dash_recharge")
	_expect(float(sm.get_upgrades().get("dash_recharge_factor", 0.0)) <= 0.6,
		"dash_recharge_factor nunca debe superar 0.6")

	# Restaurar estado original de upgrades para no contaminar otros tests
	sm.data["upgrades"] = upgrades_before

func _test_save_manager_slots_independent() -> void:
	var sm: Node = root.get_node_or_null("SaveManager")
	if sm == null:
		return

	# Slot 1 y slot 2 son independientes
	sm.load_slot(1)
	var res_slot1 := sm.get_resources()

	sm.load_slot(2)
	var res_slot2 := sm.get_resources()

	sm.load_slot(1)
	_expect(sm.get_resources() == res_slot1, "recargar slot 1 no debe ver datos del slot 2")
	_expect(sm.active_slot == 1, "active_slot debe ser 1")

func _test_narrative_overlay_instantiation() -> void:
	# Verifica que NarrativeOverlay puede instanciarse y tiene la interfaz correcta
	var scene_path := "res://scenes/tests/Brunich/narrative_overlay.gd"
	_expect(ResourceLoader.exists(scene_path), "narrative_overlay.gd debe existir en res://")

	var script := load(scene_path)
	_expect(script != null, "narrative_overlay.gd debe cargar sin errores")
	if script == null:
		return

	var overlay := NarrativeOverlay.new()
	_expect(overlay != null, "NarrativeOverlay.new() no debe ser null")
	_expect(overlay.has_method("queue_line"), "NarrativeOverlay debe tener queue_line()")
	_expect(overlay.has_method("queue_sequence"), "NarrativeOverlay debe tener queue_sequence()")
	_expect(overlay.has_method("play"), "NarrativeOverlay debe tener play()")
	_expect(overlay.has_method("stop"), "NarrativeOverlay debe tener stop()")
	_expect(overlay.has_signal("on_sequence_complete"), "NarrativeOverlay debe tener señal on_sequence_complete")
	_expect(overlay.has_signal("on_line_complete"), "NarrativeOverlay debe tener señal on_line_complete")
	overlay.free()

func _test_npc_narrative_instantiation() -> void:
	var script_path := "res://scenes/tests/Brunich/npc_narrative.gd"
	_expect(ResourceLoader.exists(script_path), "npc_narrative.gd debe existir")

	var npc := NpcNarrative.new()
	root.add_child(npc)
	_expect(npc != null, "NpcNarrative.new() no debe ser null")
	_expect(npc.has_method("set_archivista_palette"), "NpcNarrative debe tener set_archivista_palette()")
	_expect(npc.has_method("set_broker_palette"), "NpcNarrative debe tener set_broker_palette()")
	_expect(npc.get("speaker_id") != null, "NpcNarrative debe exponer speaker_id")
	_expect(npc.get("dialogue_lines") != null, "NpcNarrative debe exponer dialogue_lines")
	npc.queue_free()

func _test_brunich_tests_loads() -> void:
	var scene_path := "res://scenes/tests/Brunich/Brunich_tests.tscn"
	_expect(ResourceLoader.exists(scene_path), "Brunich_tests.tscn debe existir")
	var packed := load(scene_path)
	_expect(packed != null, "Brunich_tests.tscn debe cargar sin parse errors (script incluido)")

func _test_brunich_tests_narrative_hooks() -> void:
	# Instancia la escena de juego y verifica hooks narrativos
	var sm: Node = root.get_node_or_null("SaveManager")
	if sm != null:
		sm.load_slot(0)
		sm.data["has_intro_played"] = true   # evita redirigir al intro

	var scene := load("res://scenes/tests/Brunich/Brunich_tests.tscn").instantiate()
	if has_property(scene, "DisableSceneReloadForTests"):
		scene.DisableSceneReloadForTests = true
	root.add_child(scene)

	await _wait_frames(3)

	_expect(scene.get("_narrative") != null, "brunich_tests debe tener _narrative (NarrativeOverlay)")
	_expect(scene.has_method("_play_biome_transition"), "brunich_tests debe tener _play_biome_transition()")
	_expect(scene.has_method("_play_biome_entry_monologue"), "brunich_tests debe tener _play_biome_entry_monologue()")
	_expect(scene.has_method("_apply_upgrades_to_player"), "brunich_tests debe tener _apply_upgrades_to_player()")
	_expect(scene.has_method("_go_to_rest_zone"), "brunich_tests debe tener _go_to_rest_zone()")

	# Verifica que _apply_upgrades_to_player no rompe con upgrades en 0
	if scene.has_method("_apply_upgrades_to_player"):
		scene._apply_upgrades_to_player()  # no debe crashear con upgrades vacíos

	scene.queue_free()

# ── Helpers ───────────────────────────────────────────────────────────────────

func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append("FAIL: %s" % message)
		print("  FAIL: %s" % message)
	else:
		print("  OK:   %s" % message)

func _wait_frames(n: int) -> Signal:
	for _i in range(n):
		await process_frame
	return process_frame

func _report() -> void:
	print("")
	if _failures.is_empty():
		print("PASS brunich_metagame_smoke (%d checks)" % _checks)
	else:
		print("FAIL brunich_metagame_smoke — %d errores:" % _failures.size())
		for f in _failures:
			print("  " + f)
	quit(0 if _failures.is_empty() else 1)

func has_property(obj: Object, prop: String) -> bool:
	for p in obj.get_property_list():
		if p["name"] == prop:
			return true
	return false
