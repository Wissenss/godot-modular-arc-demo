extends SceneTree

const SCENE_PATH := "res://scenes/tests/Brunich/Brunich_tests.tscn"
const EXIT_CENTER := Vector2((17.0 * 32.0 + 23.0 * 32.0) * 0.5, 44.0)

var _failures: Array[String] = []
var _completed := false

func _initialize() -> void:
	print("START brunich_room_cli_smoke")
	call_deferred("_arm_timeout")
	call_deferred("_run")

func _run() -> void:
	var world: Node = load(SCENE_PATH).instantiate()
	if _has_property(world, "DisableSceneReloadForTests"):
		world.DisableSceneReloadForTests = true
	root.add_child(world)

	await _wait_frames(4)

	var player := world.get_node("MC") as Node2D
	var hud_layer := world.get_node_or_null("hud_layer") as CanvasLayer
	var hud_root := hud_layer.get_node_or_null("hud_root") as Control if hud_layer != null else null
	var room_cli := hud_root.get_node_or_null("room_cli") as Control if hud_root != null else null
	var room_label := room_cli.get_node_or_null("room_cli_label") as Label if room_cli != null else null

	_expect(room_cli != null, "el HUD debe mostrar un room CLI arriba a la derecha")
	_expect(room_label != null, "el room CLI debe tener una etiqueta visible")
	_expect(world.has_method("debug_get_room_cli_text"), "Brunich debe exponer el texto actual del room CLI en pruebas")
	_expect(world.has_method("debug_get_room_cli_target_text"), "Brunich debe exponer el target del room CLI en pruebas")
	_expect(world.has_method("debug_is_room_cli_animating"), "Brunich debe exponer si el room CLI sigue animando en pruebas")

	if room_cli != null:
		_expect(room_cli.anchor_left >= 0.99 and room_cli.anchor_right >= 0.99, "el room CLI debe estar anclado al borde derecho")
	if room_label != null:
		_expect(room_label.horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT, "el room CLI debe alinearse como terminal hacia la derecha")

	if world.has_method("debug_get_room_cli_text"):
		_expect(String(world.debug_get_room_cli_text()) == "room::01/10", "el primer cuarto debe mostrarse de inmediato en el room CLI")

	if world.has_method("debug_force_room_completion_for_tests"):
		world.debug_force_room_completion_for_tests()
	await _wait_frames(1)
	player.global_position = EXIT_CENTER
	await _wait_frames(2)
	if world.has_method("debug_try_context_action"):
		world.debug_try_context_action()
	await _wait_frames(1)

	if world.has_method("debug_get_room_cli_target_text"):
		_expect(String(world.debug_get_room_cli_target_text()) == "room::02/10", "al cambiar de cuarto el room CLI debe apuntar al nuevo numero")
	if world.has_method("debug_is_room_cli_animating"):
		_expect(bool(world.debug_is_room_cli_animating()), "al cambiar de cuarto el room CLI debe entrar en animacion de borrado/escritura")

	await _wait_frames(4)
	if world.has_method("debug_get_room_cli_text") and world.has_method("debug_get_room_cli_target_text"):
		_expect(String(world.debug_get_room_cli_text()) != String(world.debug_get_room_cli_target_text()), "durante la animacion el room CLI no debe saltar de golpe al texto final")

	await _wait_frames(40)
	if world.has_method("debug_is_room_cli_animating"):
		_expect(not bool(world.debug_is_room_cli_animating()), "el room CLI debe terminar su animacion tras unos frames")
	if world.has_method("debug_get_room_cli_text"):
		_expect(String(world.debug_get_room_cli_text()) == "room::02/10", "el room CLI debe terminar mostrando el nuevo cuarto")

	_completed = true
	if _failures.is_empty():
		print("PASS brunich_room_cli_smoke")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)

func _arm_timeout() -> void:
	await create_timer(10.0).timeout
	if _completed:
		return
	push_error("brunich_room_cli_smoke timeout")
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
