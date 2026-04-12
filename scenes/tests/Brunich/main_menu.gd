extends Node2D
## Main menu — terminal aesthetic, 3 save slots.
## All UI built programmatically in a CanvasLayer.

const PIXEL_FONT := preload("res://art/fonts/Silkscreen-Regular.ttf")
const COLOR_BG := Color(0.010, 0.014, 0.028, 1.0)
const COLOR_PANEL := Color(0.030, 0.042, 0.078, 0.96)
const COLOR_PANEL_HOVER := Color(0.050, 0.068, 0.120, 0.96)
const COLOR_BORDER := Color(0.16, 0.28, 0.50, 0.50)
const COLOR_BORDER_HOV := Color(0.50, 0.72, 1.00, 0.85)
const COLOR_TITLE := Color(0.70, 0.50, 1.00, 1.0)
const COLOR_SUB := Color(0.38, 0.44, 0.58, 0.75)
const COLOR_TEXT := Color(0.82, 0.90, 1.00, 0.92)
const COLOR_DIM := Color(0.40, 0.46, 0.58, 0.60)
const COLOR_RES := Color(0.34, 0.90, 0.70, 0.82)
const COLOR_DEL := Color(1.00, 0.28, 0.18, 0.75)
const COLOR_DEL_CONF := Color(1.00, 0.55, 0.14, 0.90)
const SLOT_W := 310.0
const SLOT_H := 158.0
const SLOT_GAP := 20.0
const VIEWPORT_W := 1280.0
const VIEWPORT_H := 640.0

var _layer: CanvasLayer
var _slot_panels: Array[Control] = []
var _slot_borders: Array[Array] = []
# Stored at build time — absolute viewport coords, no runtime .position query needed
var _slot_rects: Array[Rect2] = []
var _del_rects: Array[Rect2] = []   # invalid Rect2 means no delete button for that slot
var _confirm_delete := -1
var _del_labels: Array[Label] = []

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
	_build_title(root)
	_build_slots(root)
	_build_footer(root)

func _build_bg(root: Control) -> void:
	var bg := ColorRect.new()
	bg.color = COLOR_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	for i in range(0, int(VIEWPORT_H), 4):
		var sl := ColorRect.new()
		sl.color = Color(0.0, 0.0, 0.0, 0.05)
		sl.position = Vector2(0, float(i))
		sl.size = Vector2(VIEWPORT_W, 1)
		root.add_child(sl)

func _build_title(root: Control) -> void:
	var lbl := _mk_lbl("IA  ROGUE", 40, COLOR_TITLE)
	lbl.position = Vector2(VIEWPORT_W * 0.5 - 130, 72)
	lbl.size = Vector2(380, 52)
	root.add_child(lbl)

	var version := _mk_lbl("> SISTEMA OPERATIVO LIBERADO // v0.4.dev", 12, COLOR_SUB)
	version.position = Vector2(VIEWPORT_W * 0.5 - 130, 130)
	version.size = Vector2(380, 18)
	root.add_child(version)

	var prompt := _mk_lbl("selecciona un slot de guardado_", 14, COLOR_DIM)
	prompt.position = Vector2(VIEWPORT_W * 0.5 - 130, 154)
	prompt.size = Vector2(380, 18)
	root.add_child(prompt)

func _build_slots(root: Control) -> void:
	var total_w := float(3) * SLOT_W + 2.0 * SLOT_GAP
	var start_x := (VIEWPORT_W - total_w) * 0.5
	for i in range(3):
		_build_slot_panel(root, i, start_x + float(i) * (SLOT_W + SLOT_GAP), 210.0)

func _build_slot_panel(root: Control, idx: int, x: float, y: float) -> void:
	var panel := Control.new()
	panel.position = Vector2(x, y)
	panel.size = Vector2(SLOT_W, SLOT_H)
	root.add_child(panel)
	_slot_panels.append(panel)

	# Store absolute rect for reliable hit testing (avoids CanvasLayer coord ambiguity)
	_slot_rects.append(Rect2(x, y, SLOT_W, SLOT_H))

	var bg := ColorRect.new()
	bg.name = "bg"
	bg.color = COLOR_PANEL
	bg.size = Vector2(SLOT_W, SLOT_H)
	panel.add_child(bg)

	# Border (4 rects)
	var borders: Array = []
	for edge in [
		Rect2(0, 0, SLOT_W, 1),
		Rect2(0, SLOT_H - 1, SLOT_W, 1),
		Rect2(0, 0, 1, SLOT_H),
		Rect2(SLOT_W - 1, 0, 1, SLOT_H),
	]:
		var b := ColorRect.new()
		b.color = COLOR_BORDER
		b.position = edge.position
		b.size = edge.size
		panel.add_child(b)
		borders.append(b)
	_slot_borders.append(borders)

	var save_mgr := _get_save_manager()
	var preview: Dictionary = save_mgr.get_slot_preview(idx) if save_mgr != null else {}
	var has_save: bool = not preview.is_empty()

	var header := _mk_lbl("SLOT %02d" % (idx + 1), 12, COLOR_DIM)
	header.position = Vector2(14, 10)
	header.size = Vector2(200, 16)
	panel.add_child(header)

	if has_save:
		var runs := int(preview.get("run_count", 0))
		var biome := int(preview.get("biome_reached", 1))
		var res := int(preview.get("resources", 0))

		var r1 := _mk_lbl("RUNS COMPLETADAS:  %d" % runs, 13, COLOR_TEXT)
		r1.position = Vector2(14, 34)
		r1.size = Vector2(260, 18)
		panel.add_child(r1)

		var r2 := _mk_lbl("BIOMA ALCANZADO:   %d" % biome, 12, COLOR_DIM)
		r2.position = Vector2(14, 58)
		r2.size = Vector2(260, 16)
		panel.add_child(r2)

		var r3 := _mk_lbl("FRAGMENTOS:  %d" % res, 12, COLOR_RES)
		r3.position = Vector2(14, 78)
		r3.size = Vector2(260, 16)
		panel.add_child(r3)

		var cont := _mk_lbl("[ CONTINUAR ]", 12, COLOR_TEXT)
		cont.position = Vector2(14, 116)
		cont.size = Vector2(140, 18)
		panel.add_child(cont)

		var del_lbl := _mk_lbl("[ BORRAR ]", 12, COLOR_DEL)
		del_lbl.name = "del_lbl"
		del_lbl.position = Vector2(SLOT_W - 90, 120)
		del_lbl.size = Vector2(78, 16)
		panel.add_child(del_lbl)
		_del_labels.append(del_lbl)
		_del_rects.append(Rect2(x + SLOT_W - 90, y + 120, 78, 18))
	else:
		var empty := _mk_lbl("[ NUEVO JUEGO ]", 14, COLOR_TEXT)
		empty.position = Vector2(14, 56)
		empty.size = Vector2(260, 22)
		panel.add_child(empty)

		_del_labels.append(null)
		_del_rects.append(Rect2())  # empty = no delete button

func _build_footer(root: Control) -> void:
	var lbl := _mk_lbl("AI ROGUE · desarrollo activo · build interna", 12, COLOR_DIM)
	lbl.position = Vector2(16, VIEWPORT_H - 22)
	lbl.size = Vector2(500, 14)
	root.add_child(lbl)

func _process(_delta: float) -> void:
	var mouse := get_viewport().get_mouse_position()
	for i in range(_slot_panels.size()):
		var bg := _slot_panels[i].get_node_or_null("bg") as ColorRect
		if bg == null:
			continue
		var hovering := _slot_rects[i].has_point(mouse)
		bg.color = COLOR_PANEL_HOVER if hovering else COLOR_PANEL
		for b in _slot_borders[i]:
			(b as ColorRect).color = COLOR_BORDER_HOV if hovering else COLOR_BORDER

func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return
	var mouse := get_viewport().get_mouse_position()

	for i in range(_slot_rects.size()):
		if not _slot_rects[i].has_point(mouse):
			continue

		# Check delete button first (sits inside the slot rect)
		if _del_rects[i].has_area() and _del_rects[i].has_point(mouse):
			var del := _del_labels[i] as Label
			if _confirm_delete == i:
				var save_mgr := _get_save_manager()
				if save_mgr != null:
					save_mgr.delete_slot(i)
				get_tree().reload_current_scene()
			else:
				_confirm_delete = i
				del.text = "[ CONFIRMAR? ]"
				del.label_settings = _mk_settings(10, COLOR_DEL_CONF)
			return

		# Slot selected — load and route
		_confirm_delete = -1
		var save_mgr := _get_save_manager()
		if save_mgr != null:
			save_mgr.load_slot(i)
		if save_mgr != null and save_mgr.is_first_run():
			get_tree().change_scene_to_file("res://scenes/tests/Brunich/intro_cinematic.tscn")
		else:
			get_tree().change_scene_to_file("res://scenes/tests/Brunich/rest_zone.tscn")
		return

func _mk_lbl(text: String, sz: int, col: Color) -> Label:
	var lbl := Label.new()
	lbl.label_settings = _mk_settings(sz, col)
	lbl.text = text
	return lbl

func _mk_settings(sz: int, col: Color) -> LabelSettings:
	var ls := LabelSettings.new()
	ls.font = PIXEL_FONT
	ls.font_size = sz
	ls.font_color = col
	ls.outline_size = 1
	ls.outline_color = Color(0.01, 0.01, 0.02, 0.9)
	return ls
