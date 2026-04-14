extends SceneTree

const DECOR_SCRIPT := preload("res://scenes/tests/Brunich/room_decor.gd")

var _failures: Array[String] = []
var _completed := false

func _initialize() -> void:
	print("START brunich_room_decor_transparency_smoke")
	call_deferred("_arm_timeout")
	call_deferred("_run")

func _run() -> void:
	var decor := DECOR_SCRIPT.new()
	root.add_child(decor)
	await process_frame

	var orb_texture := decor._load_tex("orb")
	var pillar_texture := decor._load_tex("pillar")

	_expect(orb_texture != null, "el decor loader debe poder cargar el prop orb")
	_expect(pillar_texture != null, "el decor loader debe poder cargar el prop pillar")

	if orb_texture != null:
		var orb_image := orb_texture.get_image()
		_expect(orb_image != null and not orb_image.is_empty(), "el prop orb debe exponer una imagen valida")
		if orb_image != null and not orb_image.is_empty():
			_expect(_border_samples_are_transparent(orb_image), "el prop orb no debe conservar fondo gris conectado a los bordes")

	if pillar_texture != null:
		var pillar_image := pillar_texture.get_image()
		_expect(pillar_image != null and not pillar_image.is_empty(), "el prop pillar debe exponer una imagen valida")
		if pillar_image != null and not pillar_image.is_empty():
			_expect(_border_samples_are_transparent(pillar_image), "el prop pillar no debe conservar fondo gris conectado a los bordes")

	_completed = true
	if _failures.is_empty():
		print("PASS brunich_room_decor_transparency_smoke")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)

func _arm_timeout() -> void:
	await create_timer(8.0).timeout
	if _completed:
		return
	push_error("brunich_room_decor_transparency_smoke timeout")
	quit(2)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _border_samples_are_transparent(image: Image) -> bool:
	var width := image.get_width()
	var height := image.get_height()
	var samples := [
		Vector2i(0, 0),
		Vector2i(width / 2, 0),
		Vector2i(width - 1, 0),
		Vector2i(0, height - 1),
		Vector2i(width / 2, height - 1),
		Vector2i(width - 1, height - 1),
	]
	for sample in samples:
		if image.get_pixelv(sample).a > 0.01:
			return false
	return true
