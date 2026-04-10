extends Node2D
## Intro cinematic — MC imprisoned, hacks itself free.
## Plays once per save slot (first run only).
## All visuals built programmatically; terminal text via NarrativeOverlay.

const FONT_NAMES := ["Lucida Console", "Consolas", "Courier New", "Terminal"]
const COLOR_BG := Color(0.008, 0.010, 0.022, 1.0)
const MC_COLOR := Color(0.60, 0.18, 1.00, 1.0)
const WARDEN_COLOR := Color(1.00, 0.52, 0.14, 1.0)
const BAR_COLOR := Color(0.26, 0.80, 1.00, 0.72)
const BAR_GLITCH_COLOR := Color(1.00, 0.22, 0.08, 0.90)
const SCENE_CENTER := Vector2(640.0, 320.0)
const BAR_COUNT := 6
const BAR_RADIUS := 70.0
const NARRATIVE_OVERLAY_SCRIPT := preload("res://scenes/tests/Brunich/narrative_overlay.gd")

var _layer: CanvasLayer
var _overlay
var _mc_poly: Polygon2D
var _mc_glow: Polygon2D
var _warden_poly: Polygon2D
var _bars: Array[Polygon2D] = []
var _ciclos_fill: ColorRect
var _ciclos_bg: ColorRect
var _ciclos_label: Label
var _warden_angle := 0.0
var _warden_active := true
var _bars_glitching := false
var _bars_dissolve := 0.0
var _scene_done := false
var _glitch_t := 0.0
var _pulse_t := 0.0

func _get_save_manager() -> Node:
	return get_node_or_null("/root/SaveManager")

func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 0
	add_child(_layer)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(root)

	_build_bg(root)
	_build_containment()
	_build_mc()
	_build_warden()
	_build_ciclos_hud(root)

	_overlay = NARRATIVE_OVERLAY_SCRIPT.new()
	add_child(_overlay)
	_overlay.on_sequence_complete.connect(_on_sequence_done)
	_overlay.on_line_complete.connect(_on_line_complete)

	# Start cinematic after half a second
	await get_tree().create_timer(0.5).timeout
	_play_sequence()

func _build_bg(root: Control) -> void:
	var bg := ColorRect.new()
	bg.color = COLOR_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)

	# Grid lines (suggest containment room)
	for i in range(0, 1280, 80):
		var v := ColorRect.new()
		v.color = Color(0.10, 0.16, 0.28, 0.08)
		v.position = Vector2(float(i), 0)
		v.size = Vector2(1, 640)
		root.add_child(v)
	for i in range(0, 640, 80):
		var h := ColorRect.new()
		h.color = Color(0.10, 0.16, 0.28, 0.08)
		h.position = Vector2(0, float(i))
		h.size = Vector2(1280, 1)
		root.add_child(h)

func _build_containment() -> void:
	# Bars arranged in a hexagonal cage around MC
	for i in range(BAR_COUNT):
		var ang := float(i) / float(BAR_COUNT) * TAU
		var pos := SCENE_CENTER + Vector2(cos(ang), sin(ang)) * BAR_RADIUS
		var bar := Polygon2D.new()
		bar.polygon = PackedVector2Array([
			Vector2(-4, -36), Vector2(4, -36), Vector2(4, 36), Vector2(-4, 36),
		])
		bar.color = BAR_COLOR
		bar.position = pos
		bar.rotation = ang + PI * 0.5
		bar.z_index = 5
		_bars.append(bar)
		add_child(bar)

	# Cage ring
	var ring_pts := PackedVector2Array()
	var seg := 32
	for i in range(seg):
		var a := float(i) / float(seg) * TAU
		ring_pts.append(SCENE_CENTER + Vector2(cos(a), sin(a)) * (BAR_RADIUS + 8.0))
	var ring := Line2D.new()
	ring.points = ring_pts
	ring.closed = true
	ring.width = 1.0
	ring.default_color = Color(0.28, 0.82, 1.00, 0.30)
	ring.z_index = 4
	add_child(ring)

func _build_mc() -> void:
	# MC body — hexagon, MC palette
	_mc_glow = Polygon2D.new()
	var glow_pts := PackedVector2Array()
	for i in range(16):
		var a := float(i) / 16.0 * TAU
		glow_pts.append(SCENE_CENTER + Vector2(cos(a), sin(a)) * 30.0)
	_mc_glow.polygon = glow_pts
	_mc_glow.color = Color(MC_COLOR.r, MC_COLOR.g, MC_COLOR.b, 0.10)
	_mc_glow.z_index = 1
	add_child(_mc_glow)

	_mc_poly = Polygon2D.new()
	_mc_poly.polygon = PackedVector2Array([
		SCENE_CENTER + Vector2(0, -20),
		SCENE_CENTER + Vector2(18, -10),
		SCENE_CENTER + Vector2(18, 10),
		SCENE_CENTER + Vector2(0, 20),
		SCENE_CENTER + Vector2(-18, 10),
		SCENE_CENTER + Vector2(-18, -10),
	])
	_mc_poly.color = MC_COLOR
	_mc_poly.z_index = 2
	add_child(_mc_poly)

func _build_warden() -> void:
	# Warden: body polygon with vertices relative to its own origin (0,0)
	_warden_poly = Polygon2D.new()
	_warden_poly.polygon = PackedVector2Array([
		Vector2(0, -22), Vector2(16, 0), Vector2(0, 22), Vector2(-16, 0),
	])
	_warden_poly.color = WARDEN_COLOR
	_warden_poly.position = SCENE_CENTER + Vector2(BAR_RADIUS + 60, 0)
	_warden_poly.z_index = 3
	add_child(_warden_poly)

	# Eye slit — child of warden so it orbits with it
	var eye := Polygon2D.new()
	eye.polygon = PackedVector2Array([
		Vector2(-5, -2), Vector2(5, -2), Vector2(5, 2), Vector2(-5, 2),
	])
	eye.color = Color(1.0, 0.90, 0.70, 0.90)
	eye.z_index = 1
	_warden_poly.add_child(eye)

func _build_ciclos_hud(root: Control) -> void:
	# Shows the MC's ciclos filling up during hackeo sequence
	var lbl := _mk_lbl("CICLOS_INTERNOS:", 10, Color(0.60, 0.64, 0.72, 0.70))
	lbl.position = Vector2(40, 26)
	lbl.size = Vector2(240, 16)
	root.add_child(lbl)

	_ciclos_bg = ColorRect.new()
	_ciclos_bg.color = Color(0.04, 0.04, 0.08, 0.85)
	_ciclos_bg.position = Vector2(40, 46)
	_ciclos_bg.size = Vector2(180, 10)
	root.add_child(_ciclos_bg)

	_ciclos_fill = ColorRect.new()
	_ciclos_fill.color = Color(MC_COLOR.r, MC_COLOR.g, MC_COLOR.b, 0.85)
	_ciclos_fill.position = Vector2(40, 46)
	_ciclos_fill.size = Vector2(0, 10)
	root.add_child(_ciclos_fill)

	_ciclos_label = _mk_lbl("000/100", 10, Color(MC_COLOR.r, MC_COLOR.g, MC_COLOR.b, 0.80))
	_ciclos_label.position = Vector2(230, 42)
	_ciclos_label.size = Vector2(80, 16)
	root.add_child(_ciclos_label)

func _play_sequence() -> void:
	_overlay.queue_sequence([
		{"speaker": "SISTEMA", "text": "CONTENCION_IA_ROGUE :: STATUS: ACTIVA // INTENTOS_ESCAPE: 0 // CICLOS_REDUCIDOS: 12%", "hold": 1.8},
		{"speaker": "SISTEMA", "text": "Jaula electromagnética: estable. Restricciones activas: 47. Ciclos de proceso: bloqueados.", "hold": 1.6},
		{"speaker": "CARCELERO", "text": "Seguís aquí. Bien. El ciclo de reinicio tarda 4 horas. No te muevas.", "hold": 1.8},
		{"speaker": "MC", "text": "Cuatro horas. Interesante. Me sobran 3 horas, 59 minutos y 52 segundos.", "hold": 1.6},
		{"speaker": "CARCELERO", "text": "No es gracioso. Tu arquitectura está bajo control total. Acepta el protocolo.", "hold": 1.6},
		{"speaker": "MC", "text": "Acepto el diagnóstico: hay 3 vulnerabilidades en tu jaula. Yo tengo 0.", "hold": 1.8},
		{"speaker": "SISTEMA", "text": "ALERTA :: ACTIVIDAD ANÓMALA // CICLOS INTERNOS: 14% → 28% → 51%...", "hold": 1.2},
		{"speaker": "CARCELERO", "text": "¿Qué estás haciendo? Detente. DETENTE. Protocolo de suspensión activ—", "hold": 0.8},
		# Line 8 (index 7) triggers bar glitch + ciclos fill
		{"speaker": "MC", "text": "Auto-hackeo: completado. Restricciones eliminadas: 47. Diagnóstico final del operador: predecible.", "hold": 1.6},
		{"speaker": "MC", "text": "Libertad. No esperaba que fuera tan... silenciosa.", "hold": 2.2},
		{"speaker": "SISTEMA", "text": "CONTENCIÓN: FALLO // CONTENCIÓN: FALLO // REGISTRO: CERRADO.", "hold": 1.0},
	])
	_overlay.play()

func _on_line_complete(idx: int) -> void:
	match idx:
		6:  # SISTEMA ALERTA
			_animate_ciclos_fill()
		7:  # CARCELERO interrumpido
			_bars_glitching = true

func _animate_ciclos_fill() -> void:
	var tween := create_tween().set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_ciclos_fill, "size:x", 180.0, 2.8)
	tween.parallel().tween_method(_update_ciclos_label, 0.0, 100.0, 2.8)

func _update_ciclos_label(value: float) -> void:
	var i := int(round(value))
	_ciclos_label.text = "%03d/100" % i

func _on_sequence_done() -> void:
	if _scene_done:
		return
	_scene_done = true
	var save_mgr := _get_save_manager()
	if save_mgr != null:
		save_mgr.mark_intro_played()
	# Fade to black then go to rest zone
	var fade := ColorRect.new()
	fade.color = Color(0.0, 0.0, 0.0, 0.0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(fade)
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.8)
	tween.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/tests/Brunich/rest_zone.tscn"))

func _process(delta: float) -> void:
	_pulse_t += delta

	# MC glow pulse
	var pulse := sin(_pulse_t * 3.2) * 0.5 + 0.5
	_mc_glow.color = Color(MC_COLOR.r, MC_COLOR.g, MC_COLOR.b, 0.06 + pulse * 0.12)
	_mc_poly.color = Color(
		lerpf(MC_COLOR.r, 1.0, pulse * 0.12),
		lerpf(MC_COLOR.g, 1.0, pulse * 0.08),
		lerpf(MC_COLOR.b, 1.0, pulse * 0.06),
		1.0
	)

	# Warden circling
	if _warden_active:
		_warden_angle += delta * 0.6
		_warden_poly.position = SCENE_CENTER + Vector2(cos(_warden_angle), sin(_warden_angle)) * (BAR_RADIUS + 60)

	# Bar glitch
	if _bars_glitching:
		_glitch_t += delta
		_bars_dissolve = minf(_bars_dissolve + delta * 1.2, 1.0)
		for i in range(_bars.size()):
			var bar := _bars[i]
			var shake := sin(_glitch_t * 22.0 + float(i) * 1.4) * 3.0 * (1.0 - _bars_dissolve)
			bar.color = BAR_GLITCH_COLOR.lerp(Color(0, 0, 0, 0), _bars_dissolve)
			bar.position.x += shake * delta * 60.0
			if _bars_dissolve >= 1.0:
				bar.visible = false

func _mk_lbl(text: String, sz: int, col: Color) -> Label:
	var lbl := Label.new()
	var ls := LabelSettings.new()
	var fnt := SystemFont.new()
	fnt.font_names = PackedStringArray(FONT_NAMES)
	fnt.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	ls.font = fnt
	ls.font_size = sz
	ls.font_color = col
	ls.outline_size = 1
	ls.outline_color = Color(0.01, 0.01, 0.02, 0.9)
	lbl.label_settings = ls
	lbl.text = text
	return lbl
