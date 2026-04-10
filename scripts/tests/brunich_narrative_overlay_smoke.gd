extends SceneTree

const NARRATIVE_OVERLAY_SCRIPT := preload("res://scenes/tests/Brunich/narrative_overlay.gd")

var _failures: Array[String] = []
var _completed := false

func _initialize() -> void:
	print("START brunich_narrative_overlay_smoke")
	call_deferred("_arm_timeout")
	call_deferred("_run")

func _run() -> void:
	var overlay := NARRATIVE_OVERLAY_SCRIPT.new()
	root.add_child(overlay)
	await _wait_frames(2)

	_expect(overlay.visible == false, "el overlay narrativo debe arrancar oculto")
	_expect(overlay.has_method("receive_advance_input"), "el overlay narrativo debe exponer el avance manual")
	_expect(overlay.has_method("is_capturing_input"), "el overlay narrativo debe exponer si esta capturando input")

	overlay.queue_line("MC", "Esto es una prueba terminal real.", 1.0, true)
	overlay.play()
	await _wait_frames(3)

	_expect(overlay.visible, "el overlay debe volverse visible al reproducirse")
	_expect(paused, "mientras el overlay este activo el resto del juego debe quedar pausado")
	_expect(overlay.debug_get_state_name() == "typing", "el overlay debe empezar escribiendo letra por letra")
	var panel := overlay.get_child(0) as ColorRect
	_expect(panel != null and panel.size.y >= 170.0, "el panel narrativo debe ser mas alto para leerse mejor")
	var speaker := panel.get_child(2) as Label
	var body := panel.get_child(3) as Label
	_expect(speaker != null and speaker.label_settings != null and speaker.label_settings.font_size >= 16, "el speaker del overlay debe ser mucho mas grande")
	_expect(body != null and body.label_settings != null and body.label_settings.font_size >= 22, "el cuerpo del overlay debe verse claramente mas grande")
	_expect(speaker != null and speaker.label_settings != null and speaker.label_settings.font is FontFile, "el overlay debe usar fuente pixel real en el speaker")
	_expect(body != null and body.label_settings != null and body.label_settings.font is FontFile, "el overlay debe usar fuente pixel real en el cuerpo")
	_expect(body != null and body.label_settings != null and String(body.label_settings.font.resource_path).ends_with("Silkscreen-Regular.ttf"), "el overlay debe usar la fuente pixel compartida")

	await _wait_real_seconds(0.25)
	var partial_text := overlay.debug_get_body_text()
	_expect(partial_text.length() > 0 and partial_text.find("prueba terminal real") == -1, "el texto debe escribirse a velocidad media y no aparecer completo de golpe")
	_expect(overlay.debug_get_prompt_text().find("mostrar") != -1, "mientras escribe el overlay debe pedir una primera confirmacion para revelar")

	overlay.receive_advance_input()
	await _wait_frames(1)
	_expect(overlay.debug_get_state_name() == "waiting", "el primer avance debe revelar todo el texto y quedar esperando")
	_expect(overlay.debug_get_body_text().find("prueba terminal real") != -1, "al primer avance el texto debe mostrarse completo")
	_expect(overlay.debug_get_prompt_text().find("siguiente") != -1, "tras revelar, el overlay debe pedir una segunda confirmacion para seguir")

	overlay.receive_advance_input()
	await _wait_frames(1)
	_expect(not overlay.visible, "la segunda confirmacion debe cerrar la secuencia si ya no hay mas lineas")
	_expect(not paused, "al cerrar el overlay el juego debe reanudarse")

	overlay.queue_line("SISTEMA", "Solo click izquierdo o espacio.", 1.0, true)
	overlay.play()
	await _wait_frames(2)
	var enter_event := InputEventKey.new()
	enter_event.pressed = true
	enter_event.physical_keycode = KEY_ENTER
	overlay._input(enter_event)
	_expect(overlay.debug_get_state_name() == "typing", "el overlay no debe avanzar con otras teclas como enter")
	overlay.receive_advance_input()
	await _wait_frames(1)
	overlay.receive_advance_input()
	await _wait_frames(1)
	_expect(not overlay.visible, "el overlay debe seguir funcionando tras un segundo ciclo de doble confirmacion")
	_expect(not paused, "al terminar un segundo ciclo el juego debe quedar reanudado")

	overlay.queue_free()
	await _wait_frames(1)
	_completed = true
	if _failures.is_empty():
		print("PASS brunich_narrative_overlay_smoke")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)

func _arm_timeout() -> void:
	await create_timer(10.0).timeout
	if _completed:
		return
	push_error("brunich_narrative_overlay_smoke timeout")
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
