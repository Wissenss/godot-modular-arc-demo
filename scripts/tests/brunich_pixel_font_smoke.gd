extends SceneTree

const MAIN_MENU_SCENE := preload("res://scenes/tests/Brunich/main_menu.tscn")
const INTRO_SCENE := preload("res://scenes/tests/Brunich/intro_cinematic.tscn")
const REST_ZONE_SCENE := preload("res://scenes/tests/Brunich/rest_zone.tscn")
const BRUNICH_SCENE := preload("res://scenes/tests/Brunich/Brunich_tests.tscn")
const PIXEL_FONT_SUFFIX := "Silkscreen-Regular.ttf"

var _failures: Array[String] = []
var _completed := false

func _initialize() -> void:
	print("START brunich_pixel_font_smoke")
	call_deferred("_arm_timeout")
	call_deferred("_run")

func _run() -> void:
	await _expect_scene_uses_pixel_font(MAIN_MENU_SCENE.instantiate(), "menu principal")
	await _expect_scene_uses_pixel_font(INTRO_SCENE.instantiate(), "intro")
	await _expect_scene_uses_pixel_font(REST_ZONE_SCENE.instantiate(), "hub")
	var brunich: Node = BRUNICH_SCENE.instantiate()
	if _has_property(brunich, "DisableSceneReloadForTests"):
		brunich.DisableSceneReloadForTests = true
	await _expect_scene_uses_pixel_font(brunich, "run principal")

	_completed = true
	if _failures.is_empty():
		print("PASS brunich_pixel_font_smoke")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)

func _expect_scene_uses_pixel_font(scene: Node, scene_name: String) -> void:
	root.add_child(scene)
	await _wait_frames(3)
	if scene.has_method("get") and scene.get("_narrative") != null:
		var narrative: Variant = scene.get("_narrative")
		if narrative != null and narrative.has_method("stop"):
			narrative.stop()
			paused = false
			await _wait_frames(1)
	_expect_all_labels_use_pixel_font(scene, scene_name)
	scene.queue_free()
	await _wait_frames(2)

func _expect_all_labels_use_pixel_font(root_node: Node, scene_name: String) -> void:
	for label in _collect_labels(root_node):
		if label.text.strip_edges().is_empty():
			continue
		_expect(label.label_settings != null, "%s debe asignar LabelSettings a \"%s\"" % [scene_name, label.text])
		if label.label_settings == null:
			continue
		_expect(label.label_settings.font is FontFile, "%s debe usar una fuente pixel real en \"%s\"" % [scene_name, label.text])
		if label.label_settings.font is FontFile:
			_expect(String(label.label_settings.font.resource_path).ends_with(PIXEL_FONT_SUFFIX), "%s debe usar la fuente pixel compartida en \"%s\"" % [scene_name, label.text])

func _collect_labels(root_node: Node) -> Array[Label]:
	var result: Array[Label] = []
	for child in root_node.get_children():
		if child is Label:
			result.append(child)
		result.append_array(_collect_labels(child))
	return result

func _arm_timeout() -> void:
	await create_timer(20.0).timeout
	if _completed:
		return
	push_error("brunich_pixel_font_smoke timeout")
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
