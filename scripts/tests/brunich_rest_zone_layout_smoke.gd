extends SceneTree

const REST_ZONE_SCENE := preload("res://scenes/tests/Brunich/rest_zone.tscn")

var _failures: Array[String] = []
var _completed := false

func _initialize() -> void:
	print("START brunich_rest_zone_layout_smoke")
	call_deferred("_arm_timeout")
	call_deferred("_run")

func _run() -> void:
	var scene := REST_ZONE_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(4)

	var narrative: Variant = scene.get("_overlay") if scene.has_method("get") else null
	if narrative != null and narrative.has_method("stop"):
		narrative.stop()
		paused = false
		await _wait_frames(1)

	_expect_all_hub_labels_fit(scene)

	scene.queue_free()
	await _wait_frames(2)
	_completed = true
	if _failures.is_empty():
		print("PASS brunich_rest_zone_layout_smoke")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)

func _expect_all_hub_labels_fit(root_node: Node) -> void:
	for label in _collect_labels(root_node):
		if _is_inside_narrative_overlay(label):
			continue
		if not label.visible:
			continue
		if label.text.strip_edges().is_empty():
			continue
		var settings := label.label_settings
		if settings == null or not (settings.font is FontFile):
			continue
		var font := settings.font as FontFile
		var font_size := settings.font_size
		var outline_size := settings.outline_size
		var text_size := font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
		var required_height := font.get_height(font_size) + float(outline_size * 2) + 2.0
		var required_width := ceilf(text_size.x) + float(outline_size * 2) + 2.0
		_expect(label.size.y >= required_height, "el label del lobby no tiene alto suficiente para la pixel font: %s" % label.text)
		_expect(label.size.x >= required_width, "el label del lobby no tiene ancho suficiente para la pixel font: %s" % label.text)

func _collect_labels(root_node: Node) -> Array[Label]:
	var result: Array[Label] = []
	for child in root_node.get_children():
		if child is Label:
			result.append(child)
		result.append_array(_collect_labels(child))
	return result

func _is_inside_narrative_overlay(node: Node) -> bool:
	var current: Node = node
	while current != null:
		if current.is_in_group("narrative_overlay"):
			return true
		current = current.get_parent()
	return false

func _arm_timeout() -> void:
	await create_timer(12.0).timeout
	if _completed:
		return
	push_error("brunich_rest_zone_layout_smoke timeout")
	quit(2)

func _wait_frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
