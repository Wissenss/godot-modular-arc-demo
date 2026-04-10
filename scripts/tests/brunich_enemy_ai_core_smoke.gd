extends SceneTree

const SCENE_PATH := "res://scenes/tests/Brunich/enemy_ai_core.tscn"

var _failures: Array[String] = []
var _completed := false

func _initialize() -> void:
	print("START brunich_enemy_ai_core_smoke")
	call_deferred("_arm_timeout")
	call_deferred("_run")

func _run() -> void:
	var world := Node2D.new()
	root.add_child(world)

	var enemy := load(SCENE_PATH).instantiate() as CharacterBody2D
	world.add_child(enemy)
	await _wait_frames(3)

	_expect(enemy != null, "el enemigo AI core debe poder instanciarse")
	_expect(enemy.has_node("polygon"), "el enemigo AI core debe tener un cuerpo principal")
	_expect(enemy.has_node("face_shell"), "el enemigo AI core debe tener un marco central tipo chip")
	_expect(enemy.has_node("face_glass"), "el enemigo AI core debe tener un display central")
	_expect(enemy.has_node("ai_glyph_root"), "el enemigo AI core debe construir el glifo AI con cuadrados")
	_expect(enemy.has_node("ai_pixel_halo_back"), "el enemigo AI core debe tener un halo trasero de pixeles cuadrados")
	_expect(enemy.has_node("ai_pixel_halo_front"), "el enemigo AI core debe tener un halo frontal de pixeles cuadrados")
	_expect(enemy.has_node("ai_spark_field"), "el enemigo AI core debe tener micro particulas cuadradas alrededor")

	var body := enemy.get_node_or_null("polygon") as Polygon2D
	var display := enemy.get_node_or_null("face_glass") as Polygon2D
	var glyph_root := enemy.get_node_or_null("ai_glyph_root") as Node2D
	var halo_back := enemy.get_node_or_null("ai_pixel_halo_back") as Node2D
	var halo_front := enemy.get_node_or_null("ai_pixel_halo_front") as Node2D
	var spark_field := enemy.get_node_or_null("ai_spark_field") as Node2D
	if body != null:
		_expect(body.material != null, "el cuerpo del AI core debe tener shader dedicado")
		_expect(body.polygon.size() >= 12, "la silueta del AI core debe sentirse circular y rota, no solo un rombo simple")
	if display != null:
		_expect(display.material != null, "el display del AI core debe tener shader de scanline/glow")
	if glyph_root != null:
		_expect(glyph_root.get_child_count() >= 14, "el glifo AI debe construirse con suficientes cuadrados para leerse bien")
	if halo_back != null:
		_expect(halo_back.get_child_count() >= 12, "el halo trasero debe tener varios bloques cuadrados grandes")
	if halo_front != null:
		_expect(halo_front.get_child_count() >= 12, "el halo frontal debe tener varios bloques cuadrados grandes")
	if spark_field != null:
		_expect(spark_field.get_child_count() >= 18, "el AI core debe tener una nube de micro pixeles orbitando")

	var sample_pixel := halo_front.get_child(0) as Polygon2D if halo_front != null and halo_front.get_child_count() > 0 else null
	var start_position := sample_pixel.position if sample_pixel != null else Vector2.ZERO
	await _wait_frames(6)
	if sample_pixel != null:
		_expect(sample_pixel.position.distance_to(start_position) > 0.4, "los pixeles del halo deben animarse y no quedarse estaticos")

	enemy.HealthComp.take_damage(99999)
	await _wait_frames(2)
	_expect(enemy.has_node("death_echo_back"), "el AI core debe conservar la muerte estilizada del roster")
	_expect(enemy.has_node("death_echo_front"), "el AI core debe conservar el eco frontal al morir")

	world.queue_free()
	await _wait_frames(1)
	_completed = true
	if _failures.is_empty():
		print("PASS brunich_enemy_ai_core_smoke")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)

func _arm_timeout() -> void:
	await create_timer(8.0).timeout
	if _completed:
		return
	push_error("brunich_enemy_ai_core_smoke timeout")
	quit(2)

func _wait_frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
