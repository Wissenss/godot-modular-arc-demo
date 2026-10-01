extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _snapshot() -> Array[String]:
	var hashes: Array[String] = []
	for slot in 3:
		var path := "user://save_slot_%d.json" % slot
		hashes.append(FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "ausente")
	return hashes


func _run() -> void:
	var manager := root.get_node("SaveManager")
	var directory: Variant = manager.get("storage_directory")
	if not directory is String or not directory.begins_with("user://tests/"):
		push_error("La prueba debe aislar el SaveManager real antes de escribir")
		quit(1)
		return
	var before := _snapshot()
	manager.call("load_slot", 2)
	manager.call("add_resources", 37)
	manager.call("load_slot", 2)
	if manager.call("get_resources") != 37:
		push_error("El guardado aislado debe persistir y recargar")
		quit(1)
		return
	manager.call("delete_slot", 2)
	if manager.call("has_save", 2) or before != _snapshot():
		push_error("Eliminar el slot de prueba no debe tocar partidas reales")
		quit(1)
		return
	print("PASS SaveManager real aislado; partidas de Bruno intactas")
	quit(0)
