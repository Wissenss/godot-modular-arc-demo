extends SceneTree

const SCENE_PATH := "res://scenes/tests/Brunich/Brunich_tests.tscn"

var _failures: Array[String] = []
var _completed := false

func _initialize() -> void:
	print("START brunich_hud_values_smoke")
	call_deferred("_arm_timeout")
	call_deferred("_run")

func _run() -> void:
	var world: Node = load(SCENE_PATH).instantiate()
	if _has_property(world, "DisableSceneReloadForTests"):
		world.DisableSceneReloadForTests = true
	root.add_child(world)

	await _wait_frames(2)
	var narrative: Variant = world.get("_narrative")
	if narrative != null and narrative.has_method("stop"):
		narrative.stop()
	paused = false
	await _wait_frames(1)

	var player := world.get_node("MC") as Node2D
	var hud_layer := world.get_node_or_null("hud_layer") as CanvasLayer
	var hud_root := hud_layer.get_node_or_null("hud_root") as Control if hud_layer != null else null
	var health_bg := hud_root.get_node_or_null("hp_bar/hp_bg") as ColorRect if hud_root != null else null
	var health_value := hud_root.get_node_or_null("hp_bar/hp_value") as Label if hud_root != null else null
	var mana_bg := hud_root.get_node_or_null("cy_bar/cy_bg") as ColorRect if hud_root != null else null
	var mana_value := hud_root.get_node_or_null("cy_bar/cy_value") as Label if hud_root != null else null
	var at_bar := hud_root.get_node_or_null("at_bar") as Control if hud_root != null else null
	var thought_bg := hud_root.get_node_or_null("at_bar/at_bg") as ColorRect if hud_root != null else null
	var thought_value := hud_root.get_node_or_null("at_bar/at_value") as Label if hud_root != null else null

	_expect(hud_layer != null, "el HUD debe existir como CanvasLayer")
	_expect(hud_root != null, "el HUD debe construir un contenedor raiz")
	_expect(health_value != null, "la barra de vida debe mostrar el valor actual a la derecha")
	_expect(mana_value != null, "la barra de mana debe mostrar el valor actual a la derecha")
	_expect(thought_value != null, "la barra de pensamiento acelerado debe mostrar el valor actual a la derecha")
	_expect(at_bar != null, "la barra de pensamiento acelerado debe existir como widget propio")

	if health_bg != null and health_value != null:
		_expect(health_value.position.x >= health_bg.position.x + health_bg.size.x + 6.0, "el valor de vida debe quedar justo a la derecha de la barra")
	if mana_bg != null and mana_value != null:
		_expect(mana_value.position.x >= mana_bg.position.x + mana_bg.size.x + 6.0, "el valor de mana debe quedar justo a la derecha de la barra")
	if thought_bg != null and thought_value != null:
		_expect(thought_value.position.x >= thought_bg.position.x + thought_bg.size.x + 6.0, "el valor de pensamiento acelerado debe quedar justo a la derecha de la barra")
	if at_bar != null:
		_expect(at_bar.offset_right <= -16.0 and at_bar.offset_bottom <= -16.0, "la barra de pensamiento acelerado debe quedar abajo a la derecha")
	if thought_bg != null:
		_expect(thought_bg.size.x <= 132.0 and thought_bg.size.y <= 10.5, "la barra de pensamiento acelerado debe verse mas pequena que vida y mana")

	if health_value != null:
		_expect(health_value.text == "200/200", "la vida inicial debe mostrarse completa")
		_expect(health_value.label_settings != null, "el valor de vida debe tener un estilo dedicado")
		if health_value.label_settings != null:
			_expect(health_value.label_settings.outline_size >= 1, "el texto HUD debe tener contorno para leerse como pixel font")
			_expect(health_value.label_settings.font is FontFile, "el HUD debe usar una fuente pixel real")
			_expect(String(health_value.label_settings.font.resource_path).ends_with("Silkscreen-Regular.ttf"), "el HUD debe apuntar a la fuente pixel compartida")

	if mana_value != null:
		_expect(mana_value.text == "050/100", "el mana inicial debe arrancar a la mitad")
	if thought_value != null:
		_expect(thought_value.text == "1.3/1.3", "pensamiento acelerado debe arrancar lleno")
		if thought_value.label_settings != null:
			_expect(thought_value.label_settings.font is FontFile, "la barra de pensamiento acelerado debe usar la misma familia pixel font")
			_expect(String(thought_value.label_settings.font.resource_path).ends_with("Silkscreen-Regular.ttf"), "la barra de pensamiento acelerado debe usar la fuente pixel compartida")

	player.HealthComp.take_damage(37)
	player.Ciclos = 12.0
	player._accelerated_thought_charge = 0.8
	await _wait_frames(2)

	if health_value != null:
		_expect(health_value.text == "163/200", "el valor de vida debe actualizarse al recibir dano")
	if mana_value != null:
		var mana_parts := mana_value.text.split("/")
		var shown_mana := int(mana_parts[0]) if not mana_parts.is_empty() else -1
		_expect(shown_mana >= 12 and shown_mana <= 14, "el valor de mana debe actualizarse al cambiar ciclos")
	if thought_value != null:
		_expect(thought_value.text == "0.8/1.3", "el valor de pensamiento acelerado debe actualizarse al cambiar la reserva")

	_completed = true
	if _failures.is_empty():
		print("PASS brunich_hud_values_smoke")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)

func _arm_timeout() -> void:
	await create_timer(8.0).timeout
	if _completed:
		return
	push_error("brunich_hud_values_smoke timeout")
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
