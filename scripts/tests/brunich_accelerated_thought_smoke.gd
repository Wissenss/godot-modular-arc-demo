extends SceneTree

const PLAYER_SCENE := "res://scenes/tests/Brunich/test_character_shaders.tscn"

var _failures: Array[String] = []
var _completed := false

func _initialize() -> void:
	print("START brunich_accelerated_thought_smoke")
	call_deferred("_arm_timeout")
	call_deferred("_run")

func _run() -> void:
	var world := Node2D.new()
	root.add_child(world)

	var player := load(PLAYER_SCENE).instantiate() as CharacterBody2D
	world.add_child(player)
	await _wait_frames(2)

	_expect(InputMap.has_action("accelerated_thought"), "debe existir la accion accelerated_thought para click derecho")
	_expect(player.has_method("is_accelerated_thought_active"), "el MC debe exponer si pensamiento acelerado esta activo")
	_expect(player.has_method("get_accelerated_thought_charge"), "el MC debe exponer la carga actual de pensamiento acelerado")
	_expect(player.has_method("get_accelerated_thought_max_charge"), "el MC debe exponer la carga maxima de pensamiento acelerado")
	var max_charge := float(player.get_accelerated_thought_max_charge())
	_expect(is_equal_approx(max_charge, 1.0), "pensamiento acelerado debe tener 1 segundo de carga maxima")

	Input.action_press("accelerated_thought")
	await _wait_frames(2)
	_expect(player.is_accelerated_thought_active(), "pensamiento acelerado debe marcarse activo")
	_expect(Engine.time_scale < 0.6, "pensamiento acelerado debe bajar de forma fuerte el tiempo global")
	_expect(player.has_node("accelerated_thought_layer"), "pensamiento acelerado debe construir una capa visual dedicada")
	var overlay := player.get_node_or_null("accelerated_thought_layer/filter_root/filter_rect") as ColorRect
	_expect(overlay != null, "pensamiento acelerado debe tener un filtro fullscreen")
	_expect(overlay != null and overlay.material != null, "el filtro de pensamiento acelerado debe usar shader")

	await _wait_real_seconds(0.7)
	var partial_charge := float(player.get_accelerated_thought_charge())
	_expect(partial_charge < max_charge and partial_charge > 0.18, "pensamiento acelerado debe drenar de forma gradual mientras se sostiene")
	Input.action_release("accelerated_thought")
	await _wait_frames(2)
	_expect(not player.is_accelerated_thought_active(), "pensamiento acelerado debe apagarse al soltar click derecho")
	_expect(is_equal_approx(Engine.time_scale, 1.0), "al soltar pensamiento acelerado el tiempo global debe volver a la normalidad")

	await _wait_real_seconds(0.9)
	var recharged_charge := float(player.get_accelerated_thought_charge())
	_expect(recharged_charge > partial_charge, "pensamiento acelerado debe recargarse incluso si no se vacio")
	Input.action_press("accelerated_thought")
	await _wait_frames(2)
	_expect(player.is_accelerated_thought_active(), "pensamiento acelerado debe poder reutilizarse rapido al tener carga disponible")

	await _wait_real_seconds(2.3)
	_expect(not player.is_accelerated_thought_active(), "pensamiento acelerado debe apagarse al quedarse sin reserva")
	_expect(float(player.get_accelerated_thought_charge()) <= 0.08, "pensamiento acelerado debe poder vaciar por completo la reserva")

	Input.action_release("accelerated_thought")
	await _wait_frames(2)
	await _wait_real_seconds(2.1)
	_expect(float(player.get_accelerated_thought_charge()) >= 0.95, "pensamiento acelerado debe rellenarse de nuevo en cerca de 2 segundos reales")

	player.queue_free()
	await _wait_frames(2)
	_expect(is_equal_approx(Engine.time_scale, 1.0), "al liberar al MC el time_scale debe quedar restaurado")

	world.queue_free()
	await _wait_frames(1)
	_completed = true
	if _failures.is_empty():
		print("PASS brunich_accelerated_thought_smoke")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)

func _arm_timeout() -> void:
	await create_timer(12.0).timeout
	if _completed:
		return
	push_error("brunich_accelerated_thought_smoke timeout")
	quit(2)

func _wait_frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _wait_real_seconds(duration: float) -> void:
	var start_ms := Time.get_ticks_msec()
	while float(Time.get_ticks_msec() - start_ms) < duration * 1000.0:
		await process_frame

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
