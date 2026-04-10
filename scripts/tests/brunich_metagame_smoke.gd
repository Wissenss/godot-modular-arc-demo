## brunich_metagame_smoke.gd
## Verifica SaveManager, flujo de escenas, upgrades y sistemas narrativos.
## Correr: godot --headless -s res://scripts/tests/brunich_metagame_smoke.gd
extends SceneTree

const NARRATIVE_OVERLAY_SCRIPT := preload("res://scenes/tests/Brunich/narrative_overlay.gd")
const NPC_NARRATIVE_SCRIPT := preload("res://scenes/tests/Brunich/npc_narrative.gd")
const MAIN_MENU_SCENE := preload("res://scenes/tests/Brunich/main_menu.tscn")
const INTRO_SCENE := preload("res://scenes/tests/Brunich/intro_cinematic.tscn")
const REST_ZONE_SCENE := preload("res://scenes/tests/Brunich/rest_zone.tscn")
const BRUNICH_SCENE := preload("res://scenes/tests/Brunich/Brunich_tests.tscn")

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
	_test_scene_shells_load()
	_test_brunich_tests_loads()
	await _wait_frames(4)
	await _test_brunich_tests_narrative_hooks()
	await _test_scene_flow_basics()
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
	var res_before: int = sm.get_resources()
	sm.add_resources(10)
	_expect(sm.get_resources() == res_before + 10, "add_resources(10) debe sumar 10")
	_expect(sm.get_pending_resources() >= 10, "pending_resources debe incluir lo recién sumado")

	var spent: bool = sm.spend_resources(5)
	_expect(spent, "spend_resources(5) debe devolver true si hay suficiente")
	_expect(sm.get_resources() == res_before + 5, "recursos deben ser res_before+5 tras gastar 5")

	var failed: bool = sm.spend_resources(99999)
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
	_expect(int(sm.get_upgrades().get("max_hp_bonus", 0)) == mini(int(upgrades_before.get("max_hp_bonus", 0)) + 25, 100),
		"max_hp_up debe sumar 25 a max_hp_bonus")

	sm.apply_upgrade("max_ciclos_up")
	_expect(int(sm.get_upgrades().get("max_ciclos_bonus", 0)) == mini(int(upgrades_before.get("max_ciclos_bonus", 0)) + 20, 80),
		"max_ciclos_up debe sumar 20 a max_ciclos_bonus")

	sm.apply_upgrade("hackeo_range")
	_expect(is_equal_approx(float(sm.get_upgrades().get("hackeo_range_bonus", 0.0)), minf(float(upgrades_before.get("hackeo_range_bonus", 0.0)) + 30.0, 90.0)),
		"hackeo_range debe sumar 30 a hackeo_range_bonus")

	sm.apply_upgrade("hackeo_cost_down")
	_expect(int(sm.get_upgrades().get("hackeo_cost_reduction", 0)) == mini(int(upgrades_before.get("hackeo_cost_reduction", 0)) + 8, 24),
		"hackeo_cost_down debe sumar 8 a hackeo_cost_reduction")

	_expect(sm.has_method("is_upgrade_maxed"), "SaveManager debe exponer si una mejora ya llego a su tope")
	_expect(sm.has_method("get_upgrade_cap"), "SaveManager debe exponer el tope numerico de cada mejora")

	# Los upgrades deben quedar topados de forma clara
	for _i in range(8):
		sm.apply_upgrade("max_hp_up")
	for _i in range(8):
		sm.apply_upgrade("max_ciclos_up")
	for _i in range(8):
		sm.apply_upgrade("dash_recharge")
	for _i in range(8):
		sm.apply_upgrade("hackeo_range")
	for _i in range(8):
		sm.apply_upgrade("hackeo_cost_down")

	_expect(int(sm.get_upgrades().get("max_hp_bonus", 0)) == 100,
		"max_hp_bonus debe toparse en +100")
	_expect(int(sm.get_upgrades().get("max_ciclos_bonus", 0)) == 80,
		"max_ciclos_bonus debe toparse en +80")
	_expect(is_equal_approx(float(sm.get_upgrades().get("dash_recharge_factor", 0.0)), 0.45),
		"dash_recharge_factor debe toparse en 0.45")
	_expect(is_equal_approx(float(sm.get_upgrades().get("hackeo_range_bonus", 0.0)), 90.0),
		"hackeo_range_bonus debe toparse en +90")
	_expect(int(sm.get_upgrades().get("hackeo_cost_reduction", 0)) == 24,
		"hackeo_cost_reduction debe toparse en 24")
	_expect(sm.is_upgrade_maxed("max_hp_up"), "SaveManager debe marcar max_hp_up como maxeada al llegar al tope")
	_expect(sm.is_upgrade_maxed("dash_recharge"), "SaveManager debe marcar dash_recharge como maxeada al llegar al tope")
	_expect(int(sm.get_upgrade_cap("hackeo_cost_down")) == 24, "SaveManager debe exponer el cap correcto de hackeo_cost_down")

	# Restaurar estado original de upgrades para no contaminar otros tests
	sm.data["upgrades"] = upgrades_before

func _test_save_manager_slots_independent() -> void:
	var sm: Node = root.get_node_or_null("SaveManager")
	if sm == null:
		return

	# Slot 1 y slot 2 son independientes
	sm.load_slot(1)
	var res_slot1: int = sm.get_resources()

	sm.load_slot(2)
	var res_slot2: int = sm.get_resources()

	sm.load_slot(1)
	_expect(sm.get_resources() == res_slot1, "recargar slot 1 no debe ver datos del slot 2")
	_expect(res_slot2 >= 0, "slot 2 debe poder cargarse sin invalidar sus recursos")
	_expect(sm.active_slot == 1, "active_slot debe ser 1")

func _test_narrative_overlay_instantiation() -> void:
	# Verifica que NarrativeOverlay puede instanciarse y tiene la interfaz correcta
	var scene_path := "res://scenes/tests/Brunich/narrative_overlay.gd"
	_expect(ResourceLoader.exists(scene_path), "narrative_overlay.gd debe existir en res://")

	var script := load(scene_path)
	_expect(script != null, "narrative_overlay.gd debe cargar sin errores")
	if script == null:
		return

	var overlay: CanvasLayer = NARRATIVE_OVERLAY_SCRIPT.new()
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

	var npc: Node2D = NPC_NARRATIVE_SCRIPT.new()
	root.add_child(npc)
	_expect(npc != null, "NpcNarrative.new() no debe ser null")
	_expect(npc.has_method("set_archivista_palette"), "NpcNarrative debe tener set_archivista_palette()")
	_expect(npc.has_method("set_broker_palette"), "NpcNarrative debe tener set_broker_palette()")
	_expect(npc.get("speaker_id") != null, "NpcNarrative debe exponer speaker_id")
	_expect(npc.get("dialogue_lines") != null, "NpcNarrative debe exponer dialogue_lines")
	npc.queue_free()

func _test_scene_shells_load() -> void:
	_expect(MAIN_MENU_SCENE != null, "main_menu.tscn debe cargar")
	_expect(INTRO_SCENE != null, "intro_cinematic.tscn debe cargar")
	_expect(REST_ZONE_SCENE != null, "rest_zone.tscn debe cargar")

func _test_brunich_tests_loads() -> void:
	var scene_path := "res://scenes/tests/Brunich/Brunich_tests.tscn"
	_expect(ResourceLoader.exists(scene_path), "Brunich_tests.tscn debe existir")
	var packed := BRUNICH_SCENE
	_expect(packed != null, "Brunich_tests.tscn debe cargar sin parse errors (script incluido)")

func _test_brunich_tests_narrative_hooks() -> void:
	# Instancia la escena de juego y verifica hooks narrativos
	var sm: Node = root.get_node_or_null("SaveManager")
	if sm != null:
		sm.load_slot(0)
		sm.data["has_intro_played"] = true   # evita redirigir al intro

	var scene: Node = BRUNICH_SCENE.instantiate()
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

func _test_scene_flow_basics() -> void:
	var sm: Node = root.get_node_or_null("SaveManager")
	_expect(sm != null, "SaveManager debe seguir disponible para el flujo de escenas")
	if sm == null:
		return

	sm.delete_slot(2)
	sm.load_slot(2)
	_expect(sm.is_first_run(), "un slot nuevo debe detectar el primer run y mandar a la intro única")

	var intro: Node = INTRO_SCENE.instantiate()
	root.add_child(intro)
	await _wait_frames(3)
	_expect(intro.get("_overlay") != null, "la intro debe construir NarrativeOverlay")
	_expect(intro.has_method("_on_sequence_done"), "la intro debe exponer el cierre de secuencia")
	intro._on_sequence_done()
	await _wait_frames(2)
	_expect(bool(sm.data.get("has_intro_played", false)), "al terminar la intro el slot debe quedar marcado como intro ya vista")
	if is_instance_valid(intro):
		intro.queue_free()

	var rest_zone: Node = REST_ZONE_SCENE.instantiate()
	root.add_child(rest_zone)
	await _wait_frames(3)
	_expect(rest_zone.get("_overlay") != null, "el hub/rest zone debe construir NarrativeOverlay")
	_expect(rest_zone.get("_player_node") != null, "el hub debe crear el nodo invisible del jugador para NPCs")
	_expect(rest_zone.has_method("_play_entry_reflection"), "el hub debe tener reflexión de entrada")
	_expect(rest_zone.has_method("_refresh_hud"), "el hub debe poder refrescar el HUD con datos del save")
	rest_zone.queue_free()

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
