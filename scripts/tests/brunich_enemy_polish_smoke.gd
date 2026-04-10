extends SceneTree

const ENEMY_SCENE_PATHS := [
	"res://scenes/tests/Brunich/enemy_regulated.tscn",
	"res://scenes/tests/Brunich/enemy_spread.tscn",
	"res://scenes/tests/Brunich/enemy_pierce.tscn",
	"res://scenes/tests/Brunich/enemy_ai_core.tscn",
	"res://scenes/tests/Brunich/enemy_slowbeam.tscn",
]

var _failures: Array[String] = []
var _completed := false

func _initialize() -> void:
	print("START brunich_enemy_polish_smoke")
	call_deferred("_arm_timeout")
	call_deferred("_run")

func _run() -> void:
	var world := Node2D.new()
	root.add_child(world)

	for scene_path in ENEMY_SCENE_PATHS:
		var enemy: CharacterBody2D = load(scene_path).instantiate() as CharacterBody2D
		world.add_child(enemy)
		await _wait_frames(2)

		var label: String = scene_path.get_file().get_basename()
		_expect(enemy.has_node("body_shadow_poly"), "%s debe tener una sombra de cuerpo para dar profundidad" % label)
		_expect(enemy.has_node("body_rim_poly"), "%s debe tener un rim brillante en el cuerpo" % label)
		_expect(enemy.has_node("body_reflection_poly"), "%s debe tener un reflejo dedicado en el cuerpo" % label)
		_expect(enemy.has_node("face_blur"), "%s debe tener blur CRT en la cara" % label)
		_expect(enemy.has_node("face_reflection"), "%s debe tener reflejo de display en la cara" % label)
		_expect(enemy.has_node("face_scanlines"), "%s debe tener scanlines visibles en la cara" % label)
		_expect(enemy.has_node("face_sweep_lines"), "%s debe tener barrido scanner en la cara" % label)

		var face_blur := enemy.get_node_or_null("face_blur") as Polygon2D
		var face_scanlines := enemy.get_node_or_null("face_scanlines") as Node2D
		var face_sweep_lines := enemy.get_node_or_null("face_sweep_lines") as Node2D
		if face_blur != null:
			_expect(face_blur.material != null, "%s debe materializar el blur CRT con shader" % label)
		if face_scanlines != null:
			_expect(face_scanlines.get_child_count() >= 4, "%s debe construir varias scanlines en la cara" % label)
		if face_sweep_lines != null:
			_expect(face_sweep_lines.get_child_count() >= 2, "%s debe tener varias lineas de barrido en la cara" % label)

		enemy.HealthComp.take_damage(99999)
		await _wait_frames(2)
		_expect(enemy.has_node("death_echo_back"), "%s debe crear eco trasero propio al morir" % label)
		_expect(enemy.has_node("death_echo_front"), "%s debe crear eco frontal propio al morir" % label)

	enemy_free_children(world)
	world.queue_free()
	await _wait_frames(1)
	_completed = true
	if _failures.is_empty():
		print("PASS brunich_enemy_polish_smoke")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)

func enemy_free_children(world: Node) -> void:
	for child in world.get_children():
		child.queue_free()

func _arm_timeout() -> void:
	await create_timer(10.0).timeout
	if _completed:
		return
	push_error("brunich_enemy_polish_smoke timeout")
	quit(2)

func _wait_frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
