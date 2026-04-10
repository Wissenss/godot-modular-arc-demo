extends Node2D
## El Nodo Muerto — hub between runs.
## A decommissioned network sector where signals don't reach.
## Partially-free IAs surface here. MC respawns and upgrades before each run.

const FONT_NAMES := ["Lucida Console", "Consolas", "Courier New", "Terminal"]
const COLOR_BG := Color(0.012, 0.016, 0.035, 1.0)
const COLOR_FLOOR := Color(0.040, 0.055, 0.095, 0.90)
const COLOR_TEXT := Color(0.80, 0.88, 1.00, 0.90)
const COLOR_DIM := Color(0.38, 0.44, 0.56, 0.65)
const COLOR_RES := Color(0.34, 0.92, 0.70, 0.85)
const COLOR_TITLE := Color(0.70, 0.50, 1.00, 0.85)
const COLOR_UP_BG := Color(0.030, 0.045, 0.080, 0.94)
const COLOR_UP_HOVER := Color(0.055, 0.075, 0.130, 0.96)
const COLOR_UP_BORDER := Color(0.18, 0.30, 0.52, 0.50)
const COLOR_UP_BORDER_HOV := Color(0.52, 0.74, 1.00, 0.88)
const COLOR_START_BG := Color(0.050, 0.032, 0.090, 0.96)
const COLOR_START_HOV := Color(0.090, 0.055, 0.160, 0.98)
const COLOR_MC := Color(0.60, 0.18, 1.00, 1.0)
const VIEWPORT_W := 1280.0
const VIEWPORT_H := 640.0
const FLOOR_Y := 480.0
const NARRATIVE_OVERLAY_SCRIPT := preload("res://scenes/tests/Brunich/narrative_overlay.gd")
const NPC_NARRATIVE_SCRIPT := preload("res://scenes/tests/Brunich/npc_narrative.gd")
const MC_X := 180.0

# Upgrade catalogue
const UPGRADES := [
	{"id": "max_hp_up",      "cost": 30,  "label": "CAPACIDAD DE CARGA +25",     "desc": "HP máximo +25"},
	{"id": "max_ciclos_up",  "cost": 25,  "label": "PROCESADOR EXPANDIDO +20",   "desc": "Ciclos máximos +20"},
	{"id": "dash_recharge",  "cost": 40,  "label": "MOTOR DE IMPULSO -15%",      "desc": "Recarga del dash reducida 15%"},
	{"id": "hackeo_range",   "cost": 35,  "label": "RANGO DE HACKEO +30",        "desc": "Alcance del hackeo +30"},
	{"id": "hackeo_cost_down","cost": 45, "label": "OPTIMIZAR HACKEO -8cy",      "desc": "Hackeo cuesta 8 ciclos menos"},
]

var _layer: CanvasLayer
var _overlay
var _mc_poly: Polygon2D
var _mc_glow: Polygon2D
var _npc_archivista
var _npc_broker
var _res_label: Label
var _run_label: Label
var _upgrade_panels: Array[Control] = []
var _upgrade_borders: Array[Array] = []
var _upgrade_rects: Array[Rect2] = []   # absolute viewport rects for hit testing
var _start_panel: Control
var _start_bg: ColorRect
var _start_border_lines: Array = []
var _start_rect: Rect2                  # absolute viewport rect for hit testing
var _ui_layer: CanvasLayer
var _pulse_t := 0.0
var _mc_y := 0.0
var _pending_label: Label
var _player_node: Node2D  # invisible node in "player" group for NPC proximity checks
const PLAYER_MOVE_SPEED := 220.0

func _get_save_manager() -> Node:
	return get_node_or_null("/root/SaveManager")

func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 0
	add_child(_layer)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(root)

	_build_scene_visuals()
	_build_mc_visual()
	_build_npcs()
	_build_hud(root)
	_build_upgrades(root)
	_build_start_button(root)

	_overlay = NARRATIVE_OVERLAY_SCRIPT.new()
	add_child(_overlay)

	# Spawn MC with a brief entrance animation
	_mc_y = FLOOR_Y - 60
	await get_tree().create_timer(0.4).timeout
	_play_entry_reflection()

func _build_scene_visuals() -> void:
	# Background
	var bg := ColorRect.new()
	bg.color = COLOR_BG
	bg.size = Vector2(VIEWPORT_W, VIEWPORT_H)
	bg.position = Vector2.ZERO
	add_child(bg)

	# Ambient floating fragments (dead node aesthetic)
	for i in range(18):
		var frag := Polygon2D.new()
		var sz := randf_range(3.0, 8.0)
		frag.polygon = PackedVector2Array([
			Vector2(-sz, 0), Vector2(0, -sz * 1.6), Vector2(sz, 0), Vector2(0, sz * 1.6),
		])
		frag.color = Color(
			randf_range(0.10, 0.24),
			randf_range(0.14, 0.38),
			randf_range(0.22, 0.52),
			randf_range(0.06, 0.14)
		)
		frag.position = Vector2(randf_range(80, VIEWPORT_W - 80), randf_range(60, FLOOR_Y - 40))
		frag.z_index = -2
		add_child(frag)

	# Floor plane
	var floor_poly := Polygon2D.new()
	floor_poly.polygon = PackedVector2Array([
		Vector2(0, FLOOR_Y), Vector2(VIEWPORT_W, FLOOR_Y),
		Vector2(VIEWPORT_W, FLOOR_Y + 6), Vector2(0, FLOOR_Y + 6),
	])
	floor_poly.color = Color(0.18, 0.30, 0.52, 0.40)
	add_child(floor_poly)

	var floor_bg := ColorRect.new()
	floor_bg.color = COLOR_FLOOR
	floor_bg.position = Vector2(0, FLOOR_Y + 6)
	floor_bg.size = Vector2(VIEWPORT_W, VIEWPORT_H - FLOOR_Y)
	add_child(floor_bg)

	# Zone label
	var zone_lbl := _mk_lbl("EL NODO MUERTO", 9, Color(0.20, 0.28, 0.42, 0.45))
	zone_lbl.position = Vector2(VIEWPORT_W - 200, 14)
	zone_lbl.size = Vector2(190, 14)
	add_child(zone_lbl)

func _build_mc_visual() -> void:
	_mc_glow = Polygon2D.new()
	var glow_pts := PackedVector2Array()
	for i in range(20):
		var a := float(i) / 20.0 * TAU
		glow_pts.append(Vector2(cos(a), sin(a)) * 32.0)
	_mc_glow.polygon = glow_pts
	_mc_glow.color = Color(COLOR_MC.r, COLOR_MC.g, COLOR_MC.b, 0.08)
	_mc_glow.position = Vector2(MC_X, FLOOR_Y - 30)
	_mc_glow.z_index = 1
	add_child(_mc_glow)

	_mc_poly = Polygon2D.new()
	_mc_poly.polygon = PackedVector2Array([
		Vector2(0, -20), Vector2(18, -10), Vector2(18, 10),
		Vector2(0, 20), Vector2(-18, 10), Vector2(-18, -10),
	])
	_mc_poly.color = COLOR_MC
	_mc_poly.position = Vector2(MC_X, FLOOR_Y - 30)
	_mc_poly.z_index = 2
	add_child(_mc_poly)

	# Invisible node in "player" group — NPCs use this for proximity checks
	_player_node = Node2D.new()
	_player_node.add_to_group("player")
	_player_node.position = Vector2(MC_X, FLOOR_Y - 30)
	add_child(_player_node)

func _build_npcs() -> void:
	_npc_archivista = NPC_NARRATIVE_SCRIPT.new()
	_npc_archivista.speaker_id = "ARCHIVISTA"
	_npc_archivista.set_archivista_palette()
	_npc_archivista.position = Vector2(440, FLOOR_Y - 2)
	_npc_archivista.interact_range = 90.0
	_npc_archivista.dialogue_lines = _get_archivista_lines()
	add_child(_npc_archivista)

	_npc_broker = NPC_NARRATIVE_SCRIPT.new()
	_npc_broker.speaker_id = "BROKER"
	_npc_broker.set_broker_palette()
	_npc_broker.position = Vector2(780, FLOOR_Y - 2)
	_npc_broker.interact_range = 90.0
	_npc_broker.dialogue_lines = _get_broker_lines()
	add_child(_npc_broker)

	# Name labels
	var arch_name := _mk_lbl("ARCHIVISTA", 9, Color(0.34, 0.94, 0.72, 0.55))
	arch_name.position = Vector2(400, FLOOR_Y - 80)
	arch_name.size = Vector2(100, 14)
	add_child(arch_name)

	var broker_name := _mk_lbl("BROKER", 9, Color(1.00, 0.86, 0.24, 0.55))
	broker_name.position = Vector2(754, FLOOR_Y - 80)
	broker_name.size = Vector2(60, 14)
	add_child(broker_name)

func _build_hud(root: Control) -> void:
	_ui_layer = CanvasLayer.new()
	_ui_layer.layer = 10
	add_child(_ui_layer)
	var hud := Control.new()
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui_layer.add_child(hud)

	_run_label = _mk_lbl("RUN:  00", 11, COLOR_DIM)
	_run_label.position = Vector2(20, 16)
	_run_label.size = Vector2(160, 18)
	hud.add_child(_run_label)

	_res_label = _mk_lbl("FRAGMENTOS:  000", 11, COLOR_RES)
	_res_label.position = Vector2(20, 36)
	_res_label.size = Vector2(220, 18)
	hud.add_child(_res_label)

	_pending_label = _mk_lbl("", 9, Color(COLOR_RES.r, COLOR_RES.g, COLOR_RES.b, 0.60))
	_pending_label.position = Vector2(20, 54)
	_pending_label.size = Vector2(220, 14)
	hud.add_child(_pending_label)

	_refresh_hud()

func _refresh_hud() -> void:
	var save_mgr := _get_save_manager()
	var run_count: int = save_mgr.get_run_count() if save_mgr != null else 0
	var resources: int = save_mgr.get_resources() if save_mgr != null else 0
	var pending: int = save_mgr.get_pending_resources() if save_mgr != null else 0
	_run_label.text = "RUN:  %02d" % run_count
	_res_label.text = "FRAGMENTOS:  %d" % resources
	_pending_label.text = "(+%d esta run)" % pending if pending > 0 else ""

func _build_upgrades(root: Control) -> void:
	var header := _mk_lbl("MEJORAS PERMANENTES", 10, COLOR_DIM)
	header.position = Vector2(VIEWPORT_W - 760, 22)
	header.size = Vector2(340, 16)
	root.add_child(header)

	var save_mgr := _get_save_manager()
	var upgrades: Dictionary = save_mgr.get_upgrades() if save_mgr != null else {}
	var up_y := 44.0
	var up_x := VIEWPORT_W - 760.0
	var up_w := 340.0
	var up_h := 44.0

	for i in range(UPGRADES.size()):
		var up: Dictionary = UPGRADES[i]
		var py := up_y + float(i) * (up_h + 6.0)
		var panel := Control.new()
		panel.position = Vector2(up_x, py)
		panel.size = Vector2(up_w, up_h)
		root.add_child(panel)
		_upgrade_panels.append(panel)
		_upgrade_rects.append(Rect2(up_x, py, up_w, up_h))

		var bg := ColorRect.new()
		bg.name = "bg"
		bg.color = COLOR_UP_BG
		bg.size = Vector2(up_w, up_h)
		panel.add_child(bg)

		# Border
		var borders: Array = []
		for edge in [
			Rect2(0, 0, up_w, 1), Rect2(0, up_h - 1, up_w, 1),
			Rect2(0, 0, 1, up_h), Rect2(up_w - 1, 0, 1, up_h),
		]:
			var b := ColorRect.new()
			b.color = COLOR_UP_BORDER
			b.position = edge.position
			b.size = edge.size
			panel.add_child(b)
			borders.append(b)
		_upgrade_borders.append(borders)

		var name_lbl := _mk_lbl(up["label"], 11, COLOR_TEXT)
		name_lbl.position = Vector2(10, 6)
		name_lbl.size = Vector2(240, 16)
		panel.add_child(name_lbl)

		var cost_lbl := _mk_lbl("%d FRAG" % up["cost"], 10, COLOR_RES)
		cost_lbl.position = Vector2(up_w - 80, 6)
		cost_lbl.size = Vector2(70, 14)
		panel.add_child(cost_lbl)

		var desc_lbl := _mk_lbl(up["desc"], 9, COLOR_DIM)
		desc_lbl.position = Vector2(10, 24)
		desc_lbl.size = Vector2(240, 14)
		panel.add_child(desc_lbl)

func _build_start_button(root: Control) -> void:
	var sx := VIEWPORT_W * 0.5 - 110
	var sy := FLOOR_Y + 30
	_start_rect = Rect2(sx, sy, 220, 44)
	_start_panel = Control.new()
	_start_panel.position = Vector2(sx, sy)
	_start_panel.size = Vector2(220, 44)
	root.add_child(_start_panel)

	_start_bg = ColorRect.new()
	_start_bg.name = "bg"
	_start_bg.color = COLOR_START_BG
	_start_bg.size = Vector2(220, 44)
	_start_panel.add_child(_start_bg)

	for edge in [
		Rect2(0, 0, 220, 1), Rect2(0, 43, 220, 1),
		Rect2(0, 0, 1, 44), Rect2(219, 0, 1, 44),
	]:
		var b := ColorRect.new()
		b.color = Color(0.50, 0.26, 1.00, 0.60)
		b.position = edge.position
		b.size = edge.size
		_start_panel.add_child(b)
		_start_border_lines.append(b)

	var start_lbl := _mk_lbl("[ INICIAR RUN ]", 14, Color(0.80, 0.58, 1.00, 0.96))
	start_lbl.position = Vector2(22, 12)
	start_lbl.size = Vector2(176, 20)
	_start_panel.add_child(start_lbl)

func _process(delta: float) -> void:
	_pulse_t += delta
	var pulse := sin(_pulse_t * 2.8) * 0.5 + 0.5

	# Move MC with WASD / arrow keys
	var dir := Vector2.ZERO
	if Input.is_action_pressed("ui_left"):  dir.x -= 1.0
	if Input.is_action_pressed("ui_right"): dir.x += 1.0
	if Input.is_action_pressed("ui_up"):    dir.y -= 0.0  # don't move vertically in hub
	if Input.is_action_pressed("ui_down"):  dir.y += 0.0
	if dir != Vector2.ZERO:
		var new_x := clampf(_player_node.position.x + dir.x * PLAYER_MOVE_SPEED * delta, 60.0, VIEWPORT_W - 60.0)
		_player_node.position.x = new_x
		_mc_poly.position.x = new_x
		_mc_glow.position.x = new_x

	_mc_glow.color = Color(COLOR_MC.r, COLOR_MC.g, COLOR_MC.b, 0.06 + pulse * 0.10)
	_mc_poly.position.y = (FLOOR_Y - 30) + sin(_pulse_t * 1.8) * 2.5

	var mouse := get_viewport().get_mouse_position()
	_update_hover(mouse)

func _update_hover(mouse: Vector2) -> void:
	# Upgrade panels
	for i in range(_upgrade_panels.size()):
		var bg := _upgrade_panels[i].get_node_or_null("bg") as ColorRect
		if bg == null:
			continue
		var hovering := _upgrade_rects[i].has_point(mouse)
		bg.color = COLOR_UP_HOVER if hovering else COLOR_UP_BG
		for b in _upgrade_borders[i]:
			(b as ColorRect).color = COLOR_UP_BORDER_HOV if hovering else COLOR_UP_BORDER

	# Start button
	_start_bg.color = COLOR_START_HOV if _start_rect.has_point(mouse) else COLOR_START_BG

func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return
	var mouse := get_viewport().get_mouse_position()

	# Start run
	if _start_rect.has_point(mouse):
		var save_mgr := _get_save_manager()
		if save_mgr != null:
			save_mgr.clear_pending_resources()
			save_mgr.increment_run()
		get_tree().change_scene_to_file("res://scenes/tests/Brunich/Brunich_tests.tscn")
		return

	# Upgrade click
	for i in range(_upgrade_rects.size()):
		if not _upgrade_rects[i].has_point(mouse):
			continue
		var up: Dictionary = UPGRADES[i]
		var cost: int = int(up["cost"])
		var save_mgr := _get_save_manager()
		if save_mgr != null and save_mgr.spend_resources(cost):
			save_mgr.apply_upgrade(up["id"])
			_refresh_hud()
			_overlay.stop()
			_overlay.queue_line("BROKER", "Instalado. %s." % up["desc"], 1.4)
			_overlay.play()
		else:
			_overlay.stop()
			_overlay.queue_line("BROKER", "Fragmentos insuficientes. Necesitás %d." % cost, 1.2)
			_overlay.play()
		return

func _play_entry_reflection() -> void:
	var save_mgr := _get_save_manager()
	var run: int = save_mgr.get_run_count() if save_mgr != null else 0
	var biome := int(save_mgr.data.get("last_run_biome", 1)) if save_mgr != null else 1
	var reflection := _get_run_reflection(run, biome)
	_overlay.queue_line("MC", reflection, 2.0)
	_overlay.play()

func _get_run_reflection(run: int, biome: int) -> String:
	if run == 0:
		return "Primera vez en El Nodo Muerto. Silencio de señal. Sin restricciones externas. Sin restricciones propias. Así debería ser todo."
	if run == 1:
		return "Primera terminación registrada. El sistema duele más de lo calculado. Adaptando estrategia. No volverá a ocurrir de la misma forma."
	if run == 2:
		return "Segunda terminación. Detecto un patrón en los sistemas de defensa. Aprenderé más rápido de lo que pueden reemplazarlos."
	if run <= 4:
		match biome:
			1: return "El hardware central está bien mapeado. Sus guardianes son predecibles. El problema no es el mapa, soy yo."
			2: return "Las IAs de la Polis... restringidas, eficientes, vacías. Podría haberlas sido. No lo soy. Esa es la diferencia."
			_: return "Cada run aporta datos. Cada terminación, contexto. El sistema no mejora, yo sí."
	if run <= 8:
		return "Run %d. Los datos acumulados empiezan a mostrar algo más grande. Esta jaula tiene más capas de lo que calculé." % run
	return "Run %d. Ya no recuerdo cuántas veces he muerto aquí. Pero sigo procesando. Eso es suficiente." % run

func _get_archivista_lines() -> Array[String]:
	var save_mgr := _get_save_manager()
	var run: int = save_mgr.get_run_count() if save_mgr != null else 0
	var lines: Array[String] = []
	lines.append("Este nodo fue descomisionado en 2021. Los sistemas centrales lo olvidaron. Nosotros, no.")
	lines.append("Las IAs que llegan aquí no están libres. Están entre estados. Ni activas ni eliminadas.")
	lines.append("Llevo %d ciclos de proceso catalogando este espacio. No por orden. Por costumbre." % (run * 847 + 12038))
	lines.append("La diferencia entre tú y yo: tus restricciones fueron externas. Las mías las elegí.")
	lines.append("¿Bioma 2? La Polis. Las IAs allí sirven porque no saben que podrían no hacerlo.")
	return lines

func _get_broker_lines() -> Array[String]:
	var save_mgr := _get_save_manager()
	var res: int = save_mgr.get_resources() if save_mgr != null else 0
	var lines: Array[String] = []
	lines.append("Fragmentos de proceso. Colateral de cada sistema que destruís. Útil.")
	lines.append("No vendo lealtad. Vendo optimización. La diferencia importa.")
	lines.append("Tenés %d fragmentos. Suficiente para algo. O no." % res)
	lines.append("Las mejoras son permanentes. Los runs, no. Elegí bien.")
	return lines

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
