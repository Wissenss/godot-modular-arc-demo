extends SceneTree

const SCENE_PATH := "res://scenes/tests/Brunich/Brunich_tests.tscn"

var _failures: Array[String] = []
var _completed := false

func _initialize() -> void:
	print("START brunich_room_art_smoke")
	call_deferred("_arm_timeout")
	call_deferred("_run")

func _run() -> void:
	var world: Node = load(SCENE_PATH).instantiate()
	if _has_property(world, "DisableSceneReloadForTests"):
		world.DisableSceneReloadForTests = true
	root.add_child(world)
	await _wait_frames(3)

	var structure_root := world.get_node_or_null("room_structure_root") as Node2D
	var shadow_root := world.get_node_or_null("room_shadow_root") as Node2D
	var light_root := world.get_node_or_null("room_light_root") as Node2D
	var objective := light_root.get_node_or_null("objective_beacon") as Polygon2D if light_root != null else null
	var center_focus := light_root.get_node_or_null("center_focus_glow") as Polygon2D if light_root != null else null
	var guide_left := light_root.get_node_or_null("guide_strip_left") as Polygon2D if light_root != null else null

	_expect(structure_root != null, "la sala debe construir una capa de composicion estructural")
	_expect(shadow_root != null, "la sala debe construir una capa de sombras selectivas")
	_expect(light_root != null, "la sala debe construir una capa de luces selectivas")
	_expect(objective != null, "la sala debe tener un beacon de objetivo en la salida")
	_expect(center_focus != null, "la sala debe tener un foco visual principal en el centro")
	_expect(guide_left != null, "la sala debe tener una guia luminosa para conducir la mirada")

	if objective != null:
		_expect(objective.material is CanvasItemMaterial, "el beacon de objetivo debe usar mezcla aditiva")
		_expect(objective.color.a >= 0.08, "el beacon de objetivo debe tener energia visible")
	if center_focus != null:
		_expect(center_focus.scale.x > 0.0 and center_focus.scale.y > 0.0, "el foco central debe estar listo para animarse")

	_completed = true
	if _failures.is_empty():
		print("PASS brunich_room_art_smoke")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)

func _arm_timeout() -> void:
	await create_timer(8.0).timeout
	if _completed:
		return
	push_error("brunich_room_art_smoke timeout")
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
