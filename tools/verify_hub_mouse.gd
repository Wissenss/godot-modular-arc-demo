extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var manager := root.get_node("SaveManager")
	if not String(manager.get("storage_directory")).begins_with("user://tests/"):
		quit(2)
		return
	manager.call("load_slot", 0)
	var hub := load("res://scenes/tests/Brunich/rest_zone.tscn").instantiate() as Node
	root.add_child(hub)
	current_scene = hub
	hub.get("_overlay").call("stop")
	# El hit-test usa la posición del viewport; no movemos el mouse de Bruno.
	var pointer := root.get_mouse_position()
	hub.set("_start_rect", Rect2(pointer - Vector2(5, 5), Vector2(10, 10)))
	var event := InputEventMouseButton.new()
	event.position = pointer
	event.button_index = MOUSE_BUTTON_RIGHT
	event.pressed = true
	hub.call("_input", event)
	if manager.call("get_attempt_count") != 0:
		push_error("Clic derecho no debe iniciar un intento")
		quit(1)
		return
	event.button_index = MOUSE_BUTTON_LEFT
	hub.call("_input", event)
	hub.call("_input", event)
	if manager.call("get_attempt_count") != 1:
		push_error("Clic izquierdo inicia una sola vez durante la transición")
		quit(1)
		return
	for i in 3:
		await process_frame
	print("PASS botón de inicio: izquierdo inicia; derecho no")
	quit(0)
