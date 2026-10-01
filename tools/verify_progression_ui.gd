extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _inspect(node: Node) -> void:
	for child in node.get_children():
		if child is Label and child.is_visible_in_tree() and not child.text.is_empty():
			var parent := child.get_parent() as Control
			if parent != null and parent.size.x > 0 and parent.size.y > 0:
				if not Rect2(Vector2.ZERO, parent.size).encloses(child.get_rect()):
					failures.append("Texto fuera de su contenedor: " + child.text)
		_inspect(child)

func _run() -> void:
	var manager := root.get_node("SaveManager")
	if not String(manager.get("storage_directory")).begins_with("user://tests/"):
		quit(2)
		return
	manager.call("load_slot", 0)
	manager.call("start_attempt")
	manager.call("complete_run")
	for scene_name in ["main_menu", "rest_zone"]:
		var scene := load("res://scenes/tests/Brunich/" + scene_name + ".tscn").instantiate() as Node
		root.add_child(scene)
		if scene_name == "rest_zone":
			scene.get("_overlay").call("stop")
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		_inspect(scene)
		root.get_texture().get_image().save_png("res://tmp/progression_" + scene_name + ".png")
		scene.queue_free()
		await process_frame
		await process_frame
	for failure in failures:
		push_error(failure)
	print("RESULT interfaz progresión fallos=", failures.size())
	quit(0 if failures.is_empty() else 1)
