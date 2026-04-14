extends SceneTree

const SCENE_PATH := "res://scenes/tests/Brunich/Brunich_tests.tscn"
const OUT_DIR := "res://.superpowers/analysis/brunich_probe"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_ensure_dir(ProjectSettings.globalize_path(OUT_DIR))

	var world: Node = load(SCENE_PATH).instantiate()
	if _has_property(world, "DisableSceneReloadForTests"):
		world.DisableSceneReloadForTests = true
	root.add_child(world)
	await _wait_frames(2)

	var narrative: Variant = world.get("_narrative")
	if narrative != null and narrative.has_method("stop"):
		narrative.stop()
	paused = false
	await _wait_frames(2)

	await _capture("00_idle.png")

	var mc: Node2D = world.get_node("MC") as Node2D
	mc.Weapon._shoot(Vector2.RIGHT)
	await _wait_frames(3)
	await _capture("01_after_shot.png")

	mc._trigger_glitch_flash()
	await _wait_frames(2)
	await _capture("02_after_glitch.png")

	print(ProjectSettings.globalize_path(OUT_DIR))
	quit(0)

func _capture(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path("%s/%s" % [OUT_DIR, file_name]))

func _wait_frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _ensure_dir(path: String) -> void:
	DirAccess.make_dir_recursive_absolute(path)

func _has_property(node: Object, property_name: String) -> bool:
	for prop in node.get_property_list():
		if prop.name == property_name:
			return true
	return false
