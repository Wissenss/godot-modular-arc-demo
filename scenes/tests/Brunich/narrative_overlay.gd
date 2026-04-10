class_name NarrativeOverlay extends CanvasLayer
## Terminal-style narrative overlay.
## Instantiate, add as child, call queue_line() / queue_sequence(), then play().
## Attach to any scene — self-contained CanvasLayer.

signal on_sequence_complete
signal on_line_complete(line_index: int)

const CHAR_RATE := 36.0          # characters per second
const LINE_HOLD_DEFAULT := 1.6   # seconds to hold a line before auto-advancing
const PANEL_HEIGHT := 128.0

const SPEAKER_COLORS: Dictionary = {
	"MC":           Color(0.74, 0.50, 1.00),
	"SISTEMA":      Color(1.00, 0.28, 0.18),
	"CARCELERO":    Color(1.00, 0.54, 0.14),
	"ARCHIVISTA":   Color(0.34, 0.94, 0.72),
	"BROKER":       Color(1.00, 0.86, 0.24),
	"IA_REGULADA":  Color(0.28, 0.80, 1.00),
	"":             Color(0.72, 0.78, 0.90),
}
const FONT_NAMES := ["Lucida Console", "Consolas", "Courier New", "Terminal"]

enum _State { IDLE, TYPING, HOLDING, WAITING }

var _queue: Array = []
var _idx := 0
var _state := _State.IDLE
var _typed := 0.0
var _hold_t := 0.0
var _emitted := false
var _blink := 0.0
var _skip_req := false

var _panel: ColorRect
var _speaker: Label
var _body: Label
var _prompt: Label

func _ready() -> void:
	layer = 50
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
	top_border.offset_bottom = 1.0
	_panel.add_child(top_border)

	_speaker = _mk_lbl(10, Color(0.50, 0.55, 0.66, 0.80))
	_speaker.position = Vector2(20, 10)
	_speaker.size = Vector2(600, 18)
	_panel.add_child(_speaker)

	_body = _mk_lbl(13, Color(0.88, 0.93, 1.00, 0.96))
	_body.position = Vector2(20, 30)
	_body.size = Vector2(1240, 76)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD
	_panel.add_child(_body)

	_prompt = _mk_lbl(10, Color(0.42, 0.54, 0.70, 0.60))
	_prompt.position = Vector2(20, 110)
	_prompt.size = Vector2(700, 16)
	_panel.add_child(_prompt)

func _mk_lbl(sz: int, col: Color) -> Label:
	var lbl := Label.new()
	var ls := LabelSettings.new()
	var fnt := SystemFont.new()
	fnt.font_names = PackedStringArray(FONT_NAMES)
	fnt.antialiasing = TextServer.FONT_ANTIALIASING_NONE
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

func stop() -> void:
	_state = _State.IDLE
	_queue.clear()
	visible = false

func skip_current() -> void:
	_skip_req = true

# ── Internal ─────────────────────────────────────────────────────────────────

func _start_line() -> void:
	if _idx >= _queue.size():
		_finish()
		return
	var line: Dictionary = _queue[_idx]
	var speaker: String = line.get("speaker", "")
	_typed = 0.0
	_hold_t = 0.0
	_emitted = false
	_skip_req = false
	_state = _State.TYPING

	var col: Color = SPEAKER_COLORS.get(speaker, SPEAKER_COLORS[""])
	var ls_copy := _speaker.label_settings.duplicate() as LabelSettings
	ls_copy.font_color = col
	_speaker.label_settings = ls_copy
	_speaker.text = "> %s" % speaker if speaker != "" else ""
	_body.text = ""
	_prompt.text = ""

func _next() -> void:
	_idx += 1
	_start_line()

func _finish() -> void:
	_state = _State.IDLE
	_queue.clear()
	visible = false
	on_sequence_complete.emit()

func _process(delta: float) -> void:
	if _state == _State.IDLE:
		return
	_blink = fmod(_blink + delta, 0.8)
	var cur := "_" if _blink < 0.4 else " "

	var line: Dictionary = _queue[_idx]
	var full: String = line.get("text", "")
	var hold: float = line.get("hold", LINE_HOLD_DEFAULT)
	var wait: bool = line.get("wait_input", false)

	match _state:
		_State.TYPING:
			if _skip_req:
				_typed = float(full.length())
				_skip_req = false
			else:
				_typed = minf(_typed + CHAR_RATE * delta, float(full.length()))
			_body.text = full.substr(0, int(_typed)) + cur
			if _typed >= float(full.length()):
				if not _emitted:
					_emitted = true
					on_line_complete.emit(_idx)
				_state = _State.WAITING if wait else _State.HOLDING
				if wait:
					_prompt.text = "[ ENTER / espacio para continuar ]"

		_State.HOLDING:
			_body.text = full + cur
			_hold_t += delta
			if _hold_t >= hold or _skip_req:
				_next()

		_State.WAITING:
			_body.text = full + cur
			if _skip_req or Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("attack"):
				_prompt.text = ""
				_skip_req = false
				_next()

func _unhandled_key_input(event: InputEvent) -> void:
	if _state == _State.IDLE or not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		skip_current()
