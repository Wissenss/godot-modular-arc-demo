extends SceneTree

const SCENE_PATH := "res://scenes/tests/Brunich/Brunich_tests.tscn"

var _failures: Array[String] = []
var _completed := false

func _initialize() -> void:
	print("START brunich_visual_stack_smoke")
	call_deferred("_arm_timeout")
	call_deferred("_run")

func _run() -> void:
	var world: Node = load(SCENE_PATH).instantiate()
	if _has_property(world, "DisableSceneReloadForTests"):
		world.DisableSceneReloadForTests = true
	root.add_child(world)

	await _wait_frames(3)

	var visual_stack := world.get_node_or_null("visual_stack_root")
	var post_fx_layer := world.get_node_or_null("visual_stack_root/world_post_fx_layer") as CanvasLayer
	var post_fx_rect := world.get_node_or_null("visual_stack_root/world_post_fx_layer/post_fx_rect") as ColorRect
	var ambient_modulate := world.get_node_or_null("visual_stack_root/ambient_modulate") as CanvasModulate
	var lighting_root := world.get_node_or_null("visual_stack_root/lighting_root") as Node2D
	var shaft_root := world.get_node_or_null("visual_stack_root/shaft_root") as Node2D
	var floor_tiles := world.get_node_or_null("floor_tiles") as TileMapLayer

	_expect(visual_stack != null, "la escena debe montar un visual stack dedicado para rehacer el look")
	_expect(post_fx_layer != null, "el visual stack debe incluir una capa de postproceso global")
	_expect(post_fx_rect != null, "el visual stack debe incluir un rect full-screen para color grading y bloom")
	_expect(ambient_modulate != null, "el visual stack debe incluir una ambientacion base via CanvasModulate")
	_expect(lighting_root != null, "el visual stack debe construir una raiz para luces dinamicas")
	_expect(shaft_root != null, "el visual stack debe construir una raiz para shafts y niebla de luz")
	if post_fx_rect != null:
		_expect(post_fx_rect.material is ShaderMaterial, "el postproceso debe usar un ShaderMaterial real")

	if lighting_root != null:
		var point_light_count := 0
		for child in lighting_root.get_children():
			if child is PointLight2D:
				point_light_count += 1
		_expect(point_light_count >= 4, "la escena debe tener varias PointLight2D para foco hero y relleno atmosferico")

	if floor_tiles != null and floor_tiles.tile_set != null:
		var source := floor_tiles.tile_set.get_source(0) as TileSetAtlasSource
		_expect(source != null, "el tileset principal debe exponer su atlas fuente")
		if source != null:
			_expect(source.texture is CanvasTexture, "el atlas principal debe convertirse a CanvasTexture para soportar normales 2D")
			var canvas_texture := source.texture as CanvasTexture
			if canvas_texture != null:
				_expect(canvas_texture.normal_texture != null, "el atlas principal debe tener normal map para responder a la iluminacion")
	else:
		_failures.append("la smoke no encontro el TileMapLayer principal")

	_completed = true
	if _failures.is_empty():
		print("PASS brunich_visual_stack_smoke")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)

func _arm_timeout() -> void:
	await create_timer(10.0).timeout
	if _completed:
		return
	push_error("brunich_visual_stack_smoke timeout")
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
