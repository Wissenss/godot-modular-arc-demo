extends SceneTree

const SCENE_PATH := "res://scenes/tests/Brunich/Brunich_tests.tscn"

var _failures: Array[String] = []
var _completed := false

func _initialize() -> void:
	print("START brunich_beta3_room_smoke")
	call_deferred("_arm_timeout")
	call_deferred("_run")

func _run() -> void:
	var world: Node = load(SCENE_PATH).instantiate()
	if _has_property(world, "DisableSceneReloadForTests"):
		world.DisableSceneReloadForTests = true
	root.add_child(world)
	await _wait_frames(3)

	var floor_tiles := world.get_node_or_null("floor_tiles") as TileMapLayer
	_expect(floor_tiles != null, "la escena debe seguir montando floor_tiles como base del cuarto")
	if floor_tiles != null:
		var room_size := floor_tiles.call("get_room_pixel_size") as Vector2
		_expect(room_size.x > 1280.0 and room_size.y > 640.0, "el cuarto base 2.5D debe crecer respecto al top-down anterior")
		_expect(floor_tiles.get_node_or_null("iso_floor_root") != null, "el cuarto debe montar una capa dedicada de piso Beta3")
		_expect(floor_tiles.get_node_or_null("iso_wall_back_root") != null, "el cuarto debe montar una capa trasera de muros Beta3")
		_expect(floor_tiles.get_node_or_null("iso_wall_front_root") != null, "el cuarto debe montar una capa frontal para profundidad y foreground")
		_expect(floor_tiles.get_node_or_null("iso_prop_root") != null, "el cuarto debe montar una capa de props 2.5D")

	_completed = true
	if _failures.is_empty():
		print("PASS brunich_beta3_room_smoke")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)

func _arm_timeout() -> void:
	await create_timer(8.0).timeout
	if _completed:
		return
	push_error("brunich_beta3_room_smoke timeout")
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
