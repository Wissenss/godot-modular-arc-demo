class_name NarrativeOverlay extends CanvasLayer
## Terminal-style narrative overlay.
## Instantiate, add as child, call queue_line() / queue_sequence(), then play().
## Attach to any scene — self-contained CanvasLayer.

signal on_sequence_complete
signal on_line_complete(line_index: int)

const CHAR_RATE := 24.0
const LINE_HOLD_DEFAULT := 1.6
const PANEL_HEIGHT := 176.0
const TYPE_CURSOR_PERIOD := 0.56
const ADVANCE_CURSOR_PERIOD := 0.86
const SPACE_DELAY := 0.010
const PUNCTUATION_DELAY := 0.048
const CLAUSE_DELAY := 0.085
const NEWLINE_DELAY := 0.110

const SPEAKER_COLORS: Dictionary = {
	"MC":           Color(0.74, 0.50, 1.00),
	"SISTEMA":      Color(1.00, 0.28, 0.18),
	"CARCELERO":    Color(1.00, 0.54, 0.14),
	"ARCHIVISTA":   Color(0.34, 0.94, 0.72),
	"BROKER":       Color(1.00, 0.86, 0.24),
	"IA_REGULADA":  Color(0.28, 0.80, 1.00),
	"":             Color(0.72, 0.78, 0.90),
}
const FONT_NAMES := ["Terminal"]

enum _State { IDLE, TYPING, WAITING }

var _queue: Array = []
var _idx := 0
var _state := _State.IDLE
var _visible_chars := 0
var _type_accum := 0.0
var _next_char_delay := 0.0
var _emitted := false
var _blink := 0.0
var _owns_tree_pause := false
var _real_time_prev := 0.0

var _panel: ColorRect
var _header: Label
var _speaker: Label
var _body: Label
var _prompt: Label

func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("narrative_overlay")
	_real_time_prev = _get_real_time_seconds()
	_build()
	visible = false

func _build() -> void:
	_panel = ColorRect.new()
	_panel.color = Color(0.016, 0.022, 0.048, 0.93)
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_top = -PANEL_HEIGHT
	_panel.offset_bottom = 0.0
	add_child(_panel)

	var top_border := ColorRect.new()
	top_border.color = Color(0.22, 0.36, 0.60, 0.50)
	top_border.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_border.offset_top = 0.0
	top_border.offset_bottom = 2.0
	_panel.add_child(top_border)

	_header = _mk_lbl(12, Color(0.34, 0.52, 0.76, 0.86))
	_header.position = Vector2(20, 8)
	_header.size = Vector2(760, 18)
	_header.text = "narrative.stream() :: live_input"
	_panel.add_child(_header)

	_speaker = _mk_lbl(16, Color(0.50, 0.55, 0.66, 0.80))
	_speaker.position = Vector2(20, 28)
	_speaker.size = Vector2(760, 22)
	_panel.add_child(_speaker)

	_body = _mk_lbl(22, Color(0.88, 0.93, 1.00, 0.96))
	_body.position = Vector2(20, 56)
	_body.size = Vector2(1240, 86)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD
	_panel.add_child(_body)

	_prompt = _mk_lbl(13, Color(0.42, 0.54, 0.70, 0.68))
	_prompt.position = Vector2(20, 146)
	_prompt.size = Vector2(900, 18)
	_panel.add_child(_prompt)

func _mk_lbl(sz: int, col: Color) -> Label:
	var lbl := Label.new()
	var ls := LabelSettings.new()
	var fnt := SystemFont.new()
	fnt.font_names = PackedStringArray(FONT_NAMES)
	fnt.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	fnt.hinting = TextServer.HINTING_NONE
	fnt.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	ls.font = fnt
	ls.font_size = sz
	ls.font_color = col
	ls.outline_size = 1
	ls.outline_color = Color(0.01, 0.01, 0.02, 0.92)
	lbl.label_settings = ls
	return lbl

# ── Public API ───────────────────────────────────────────────────────────────

func queue_line(speaker: String, text: String, hold: float = LINE_HOLD_DEFAULT, wait_input: bool = false) -> void:
	_queue.append({"speaker": speaker, "text": text, "hold": hold, "wait_input": wait_input})

func queue_sequence(lines: Array) -> void:
	for line in lines:
		_queue.append(line)

func play() -> void:
	if _queue.is_empty():
		return
	_idx = 0
	_state = _State.IDLE
	_start_line()
	visible = true
	_set_tree_pause_lock(true)

func stop() -> void:
	_state = _State.IDLE
	_queue.clear()
	visible = false
	_set_tree_pause_lock(false)

func skip_current() -> void:
	receive_advance_input()

func receive_advance_input() -> void:
	if _state == _State.IDLE or _idx >= _queue.size():
		return
	match _state:
		_State.TYPING:
			_reveal_current_line()
		_State.WAITING:
			_prompt.text = ""
			_next()

func is_capturing_input() -> bool:
	return visible and _state != _State.IDLE

func debug_get_body_text() -> String:
	return _body.text if _body != null else ""

func debug_get_prompt_text() -> String:
	return _prompt.text if _prompt != null else ""

func debug_get_state_name() -> String:
	match _state:
		_State.TYPING:
			return "typing"
		_State.WAITING:
			return "waiting"
		_:
			return "idle"

# ── Internal ─────────────────────────────────────────────────────────────────

func _start_line() -> void:
	if _idx >= _queue.size():
		_finish()
		return
	var line: Dictionary = _queue[_idx]
	var speaker: String = line.get("speaker", "")
	_visible_chars = 0
	_type_accum = 0.0
	_next_char_delay = _get_char_delay_for_index(line.get("text", ""), 0)
	_emitted = false
	_state = _State.TYPING

	var col: Color = SPEAKER_COLORS.get(speaker, SPEAKER_COLORS[""])
	var ls_copy := _speaker.label_settings.duplicate() as LabelSettings
	ls_copy.font_color = col
	_speaker.label_settings = ls_copy
	_speaker.text = "speaker::%s" % speaker.to_lower() if speaker != "" else "speaker::system"
	_body.text = ""
	_prompt.text = "[ click izq / espacio :: mostrar ]"

func _next() -> void:
	_idx += 1
	_start_line()

func _finish() -> void:
	_state = _State.IDLE
	_queue.clear()
	visible = false
	_set_tree_pause_lock(false)
	on_sequence_complete.emit()

func _process(delta: float) -> void:
	if _state == _State.IDLE:
		return
	var real_now := _get_real_time_seconds()
	var real_delta := maxf(real_now - _real_time_prev, 0.0)
	_real_time_prev = real_now
	_blink += real_delta

	var line: Dictionary = _queue[_idx]
	var full: String = line.get("text", "")

	match _state:
		_State.TYPING:
			_type_accum += real_delta
			var safety := 0
			while _visible_chars < full.length() and _type_accum >= _next_char_delay and safety < 512:
				_type_accum -= _next_char_delay
				_visible_chars += 1
				_next_char_delay = _get_char_delay_for_index(full, _visible_chars)
				safety += 1
			_body.text = full.substr(0, _visible_chars) + _get_cursor(TYPE_CURSOR_PERIOD)
			if _visible_chars >= full.length():
				_reveal_current_line()

		_State.WAITING:
			_body.text = full + _get_cursor(ADVANCE_CURSOR_PERIOD)

func _reveal_current_line() -> void:
	if _idx >= _queue.size():
		return
	var line: Dictionary = _queue[_idx]
	var full: String = line.get("text", "")
	_visible_chars = full.length()
	_body.text = full + _get_cursor(ADVANCE_CURSOR_PERIOD)
	if not _emitted:
		_emitted = true
		on_line_complete.emit(_idx)
	_state = _State.WAITING
	_prompt.text = "[ click izq / espacio :: siguiente ]"

func _get_char_delay_for_index(text: String, index: int) -> float:
	if index >= text.length():
		return 1.0 / CHAR_RATE
	var base_delay := 1.0 / CHAR_RATE
	var char := text.substr(index, 1)
	match char:
		" ":
			return base_delay + SPACE_DELAY
		",":
			return base_delay + PUNCTUATION_DELAY
		".":
			return base_delay + CLAUSE_DELAY
		":":
			return base_delay + PUNCTUATION_DELAY
		";":
			return base_delay + PUNCTUATION_DELAY
		"!":
			return base_delay + CLAUSE_DELAY
		"?":
			return base_delay + CLAUSE_DELAY
		"\n":
			return base_delay + NEWLINE_DELAY
		_:
			return base_delay

func _get_cursor(period: float) -> String:
	var blink_time := fmod(_blink, period * 2.0)
	return "|" if blink_time < period else " "

func _input(event: InputEvent) -> void:
	if not is_capturing_input():
		return
	var wants_advance := false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		wants_advance = true
	elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_SPACE:
		wants_advance = true
	if not wants_advance:
		return
	get_viewport().set_input_as_handled()
	receive_advance_input()

func _set_tree_pause_lock(active: bool) -> void:
	var tree := get_tree()
	if tree == null:
		return
	if active:
		tree.paused = true
		_owns_tree_pause = true
		return
	if not _owns_tree_pause:
		return
	_owns_tree_pause = false
	for overlay in tree.get_nodes_in_group("narrative_overlay"):
		if overlay == self:
			continue
		if overlay.has_method("is_capturing_input") and overlay.is_capturing_input():
			return
	tree.paused = false

func _get_real_time_seconds() -> float:
	return float(Time.get_ticks_msec()) * 0.001
