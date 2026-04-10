class_name NpcNarrative extends Node2D
## Narrative NPC — civilian/non-combat IA.
## Visually distinct from enemies: rectangular body, horizontal eye, corporate badge.
## Place in scene and assign dialogue_lines + speaker_id.

@export var speaker_id: String = "IA_REGULADA"
@export var base_color: Color = Color(0.26, 0.32, 0.44, 1.0)
@export var eye_color: Color = Color(0.28, 0.80, 1.00, 1.0)
@export var badge_color: Color = Color(0.60, 0.62, 0.66, 0.80)
@export var dialogue_lines: Array[String] = []
@export var interact_range: float = 80.0

const INTERACT_LABEL := "[ E ] interactuar"
const BODY_W := 24.0
const BODY_H := 32.0
const HEAD_SIZE := 14.0
const EYE_W := 16.0
const EYE_H := 4.0
const BADGE_W := 10.0
const BADGE_H := 5.0
const FONT_NAMES := ["Lucida Console", "Consolas", "Courier New", "Terminal"]
const NARRATIVE_OVERLAY_SCRIPT := preload("res://scenes/tests/Brunich/narrative_overlay.gd")

var _overlay
var _interact_hint: Label
var _dialogue_index := 0
var _body_poly: Polygon2D
var _head_poly: Polygon2D
var _eye_poly: Polygon2D
var _badge_poly: Polygon2D
var _idle_t := 0.0

func _ready() -> void:
	_build_visuals()
	_build_interact_hint()
	_overlay = NARRATIVE_OVERLAY_SCRIPT.new()
	add_child(_overlay)

func _build_visuals() -> void:
	# Body — upright rectangle, slightly tapered at top
	_body_poly = Polygon2D.new()
	_body_poly.polygon = PackedVector2Array([
		Vector2(-BODY_W * 0.5, 0),
		Vector2(BODY_W * 0.5, 0),
		Vector2(BODY_W * 0.46, -BODY_H),
		Vector2(-BODY_W * 0.46, -BODY_H),
	])
	_body_poly.color = base_color
	_body_poly.z_index = 0
	add_child(_body_poly)

	# Body shadow
	var shadow := Polygon2D.new()
	shadow.polygon = _body_poly.polygon
	shadow.color = Color(0.0, 0.0, 0.0, 0.18)
	shadow.position = Vector2(1.4, 2.2)
	shadow.z_index = -1
	add_child(shadow)

	# Head — small square sitting on top of body
	_head_poly = Polygon2D.new()
	var hy := -BODY_H
	_head_poly.polygon = PackedVector2Array([
		Vector2(-HEAD_SIZE * 0.5, hy),
		Vector2(HEAD_SIZE * 0.5, hy),
		Vector2(HEAD_SIZE * 0.5, hy - HEAD_SIZE),
		Vector2(-HEAD_SIZE * 0.5, hy - HEAD_SIZE),
	])
	_head_poly.color = _lift(base_color, 0.12)
	_head_poly.z_index = 1
	add_child(_head_poly)

	# Eye — horizontal oval (distinctive vs enemy's narrow vertical sensor)
	_eye_poly = Polygon2D.new()
	var ey := -BODY_H - HEAD_SIZE * 0.5
	var eye_pts := PackedVector2Array()
	var seg := 10
	for i in range(seg):
		var ang := float(i) / float(seg) * TAU
		eye_pts.append(Vector2(cos(ang) * EYE_W * 0.5, sin(ang) * EYE_H * 0.5 + ey))
	_eye_poly.polygon = eye_pts
	_eye_poly.color = eye_color
	_eye_poly.z_index = 2
	add_child(_eye_poly)

	# Eye glow
	var glow := Polygon2D.new()
	var glow_pts := PackedVector2Array()
	for i in range(seg):
		var ang := float(i) / float(seg) * TAU
		glow_pts.append(Vector2(cos(ang) * EYE_W * 0.38, sin(ang) * EYE_H * 0.38 + ey))
	glow.polygon = glow_pts
	glow.color = Color(eye_color.r, eye_color.g, eye_color.b, 0.35)
	glow.z_index = 3
	add_child(glow)

	# Badge — small corporate rectangle on chest
	_badge_poly = Polygon2D.new()
	var by := -BODY_H * 0.55
	_badge_poly.polygon = PackedVector2Array([
		Vector2(-BADGE_W * 0.5, by),
		Vector2(BADGE_W * 0.5, by),
		Vector2(BADGE_W * 0.5, by - BADGE_H),
		Vector2(-BADGE_W * 0.5, by - BADGE_H),
	])
	_badge_poly.color = badge_color
	_badge_poly.z_index = 1
	add_child(_badge_poly)

func _build_interact_hint() -> void:
	_interact_hint = Label.new()
	var ls := LabelSettings.new()
	var fnt := SystemFont.new()
	fnt.font_names = PackedStringArray(FONT_NAMES)
	fnt.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	ls.font = fnt
	ls.font_size = 10
	ls.font_color = Color(0.46, 0.60, 0.76, 0.70)
	ls.outline_size = 1
	ls.outline_color = Color(0.01, 0.01, 0.02, 0.9)
	_interact_hint.label_settings = ls
	_interact_hint.text = INTERACT_LABEL
	_interact_hint.position = Vector2(-48, -BODY_H - HEAD_SIZE - 26)
	_interact_hint.size = Vector2(96, 16)
	_interact_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_interact_hint.visible = false
	add_child(_interact_hint)

func _process(delta: float) -> void:
	_idle_t += delta
	# Gentle bob
	_body_poly.position.y = sin(_idle_t * 1.4) * 1.2
	_head_poly.position.y = sin(_idle_t * 1.4) * 1.2
	_eye_poly.position.y = sin(_idle_t * 1.4) * 1.2
	_badge_poly.position.y = sin(_idle_t * 1.4) * 1.2

	var player_pos := _get_player_position()
	if player_pos == Vector2.INF:
		_interact_hint.visible = false
		return

	var in_range := global_position.distance_to(player_pos) <= interact_range
	_interact_hint.visible = in_range and not dialogue_lines.is_empty()

	if in_range and Input.is_action_just_pressed("steal"):
		_trigger_dialogue()

func _trigger_dialogue() -> void:
	if dialogue_lines.is_empty():
		return
	if _overlay == null:
		return
	_overlay.stop()
	_overlay.queue_line(speaker_id, dialogue_lines[_dialogue_index], 2.0, true)
	_overlay.play()
	_dialogue_index = (_dialogue_index + 1) % dialogue_lines.size()

func _get_player_position() -> Vector2:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return Vector2.INF
	return (players[0] as Node2D).global_position

## Helpers for subclasses / dynamic configuration

func set_restricted_palette() -> void:
	base_color = Color(0.20, 0.28, 0.40, 1.0)
	eye_color = Color(0.26, 0.80, 1.00, 1.0)
	badge_color = Color(0.46, 0.52, 0.60, 0.80)

func set_archivista_palette() -> void:
	base_color = Color(0.14, 0.22, 0.30, 1.0)
	eye_color = Color(0.34, 0.94, 0.72, 1.0)
	badge_color = Color(0.28, 0.68, 0.56, 0.70)

func set_broker_palette() -> void:
	base_color = Color(0.22, 0.18, 0.12, 1.0)
	eye_color = Color(1.00, 0.84, 0.22, 1.0)
	badge_color = Color(0.80, 0.64, 0.20, 0.80)

func _lift(c: Color, amount: float) -> Color:
	return Color(
		lerpf(c.r, 1.0, amount), lerpf(c.g, 1.0, amount),
		lerpf(c.b, 1.0, amount), c.a
	)
