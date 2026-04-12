class_name EnemyAIBeam
extends Node2D

signal beam_finished

const BEAM_SHADER := preload("res://scenes/tests/Brunich/enemy_ai_beam_shader.gdshader")

enum BeamState {
	CHARGING,
	FIRING,
	FADING,
}

const DEFAULT_PROFILE := {
	"charge_duration": 0.72,
	"active_duration": 1.18,
	"fade_duration": 0.16,
	"beam_length": 700.0,
	"warning_width": 14.0,
	"beam_width": 28.0,
	"track_speed": 6.2,
	"damage_tick_interval": 0.12,
	"damage_per_tick": 7,
	"origin_offset": 26.0,
	"warning_color": Color(0.72, 0.94, 1.0, 0.44),
	"beam_outer_color": Color(0.58, 0.88, 1.0, 0.90),
	"beam_core_color": Color(0.96, 0.99, 1.0, 0.96),
	"endpoint_color": Color(0.94, 0.98, 1.0, 0.86),
}

var Owner: Node2D
var TrackingTarget: Node2D

var WarningPolygon: Polygon2D
var BeamHalo: Polygon2D
var BeamOuter: Polygon2D
var BeamCore: Polygon2D
var EndpointGlow: Polygon2D
var ChargeRing: Polygon2D
var ChargePixels: Node2D
var BeamPixels: Node2D
var HurtboxComp: HurtboxComponent
var CollisionPolygon: CollisionPolygon2D

var _beam_profile: Dictionary = DEFAULT_PROFILE.duplicate(true)
var _state: BeamState = BeamState.CHARGING
var _state_time := 0.0
var _manual_tracking := false
var _manual_direction := Vector2.RIGHT
var _charge_duration := 0.72
var _active_duration := 1.18
var _fade_duration := 0.16
var _beam_length := 700.0
var _warning_width := 14.0
var _beam_width := 28.0
var _track_speed := 6.2
var _damage_tick_interval := 0.12
var _damage_tick_remaining := 0.0
var _origin_offset := 26.0
var _charge_pixel_data: Array[Dictionary] = []
var _beam_pixel_data: Array[Dictionary] = []

func _ready() -> void:
	add_to_group("enemy_ai_beam")
	self.WarningPolygon = $warning_polygon
	self.BeamOuter = $beam_outer
	self.BeamCore = $beam_core
	self.EndpointGlow = $endpoint_glow
	self.ChargeRing = $charge_ring
	self.ChargePixels = $charge_pixels
	self.BeamPixels = $beam_pixels
	self.HurtboxComp = $hurtbox_comp
	self.CollisionPolygon = $hurtbox_comp/collision as CollisionPolygon2D
	self.HurtboxComp.monitoring = false
	self.HurtboxComp.monitorable = true
	_ensure_beam_halo()
	_build_charge_pixels()
	_build_beam_pixels()
	_apply_profile()

func get_visual_state() -> Dictionary:
	var charge_ratio := 0.0
	var beam_intensity := 0.0
	var fade_ratio := 0.0
	match _state:
		BeamState.CHARGING:
			charge_ratio = clampf(_state_time / maxf(_charge_duration, 0.001), 0.0, 1.0)
			beam_intensity = charge_ratio * 0.34
		BeamState.FIRING:
			charge_ratio = 1.0
			beam_intensity = 1.0
		BeamState.FADING:
			charge_ratio = 1.0
			fade_ratio = clampf(_state_time / maxf(_fade_duration, 0.001), 0.0, 1.0)
			beam_intensity = 1.0 - fade_ratio
	return {
		"charge_ratio": charge_ratio,
		"beam_intensity": beam_intensity,
		"fade_ratio": fade_ratio,
	}

func configure_beam(profile: Dictionary) -> void:
	_beam_profile = DEFAULT_PROFILE.duplicate(true)
	for key in profile.keys():
		_beam_profile[key] = profile[key]
	if is_node_ready():
		_apply_profile()

func set_manual_direction(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		return
	_manual_tracking = true
	_manual_direction = direction.normalized()

func _physics_process(delta: float) -> void:
	if Owner == null or not is_instance_valid(Owner):
		queue_free()
		return

	global_position = Owner.global_position
	_state_time += delta
	_update_tracking(delta)

	match _state:
		BeamState.CHARGING:
			_update_charge_visuals()
			if _state_time >= _charge_duration:
				_enter_firing_state()
		BeamState.FIRING:
			_update_beam_visuals()
			_damage_tick_remaining = maxf(_damage_tick_remaining - delta, 0.0)
			if _damage_tick_remaining <= 0.0:
				_damage_tick_remaining = _damage_tick_interval
				_apply_damage_tick()
			if _state_time >= _active_duration:
				_enter_fading_state()
		BeamState.FADING:
			_update_fade_visuals()
			if _state_time >= _fade_duration:
				beam_finished.emit()
				queue_free()

func _update_tracking(delta: float) -> void:
	var desired_angle := rotation
	if _manual_tracking:
		desired_angle = _manual_direction.angle()
	elif TrackingTarget != null and is_instance_valid(TrackingTarget):
		var desired_vector := TrackingTarget.global_position - global_position
		if desired_vector != Vector2.ZERO:
			desired_angle = desired_vector.angle()

	var tracking_multiplier := 0.82 if _state == BeamState.CHARGING else 1.0
	rotation = lerp_angle(rotation, desired_angle, minf(1.0, delta * _track_speed * tracking_multiplier))

func _apply_profile() -> void:
	_charge_duration = float(_beam_profile.get("charge_duration", 0.72))
	_active_duration = float(_beam_profile.get("active_duration", 1.18))
	_fade_duration = float(_beam_profile.get("fade_duration", 0.16))
	_beam_length = float(_beam_profile.get("beam_length", 700.0))
	_warning_width = float(_beam_profile.get("warning_width", 14.0))
	_beam_width = float(_beam_profile.get("beam_width", 28.0))
	_track_speed = float(_beam_profile.get("track_speed", 6.2))
	_damage_tick_interval = float(_beam_profile.get("damage_tick_interval", 0.12))
	_origin_offset = float(_beam_profile.get("origin_offset", 26.0))
	self.HurtboxComp.Damage = int(_beam_profile.get("damage_per_tick", 7))
	self.HurtboxComp.Owner = self.Owner
	self.WarningPolygon.color = _beam_profile.get("warning_color", Color(0.72, 0.94, 1.0, 0.44))
	self.BeamOuter.color = _beam_profile.get("beam_outer_color", Color(0.58, 0.88, 1.0, 0.90))
	self.BeamCore.color = _beam_profile.get("beam_core_color", Color(0.96, 0.99, 1.0, 0.96))
	self.EndpointGlow.color = _beam_profile.get("endpoint_color", Color(0.94, 0.98, 1.0, 0.86))
	if self.BeamHalo != null:
		self.BeamHalo.color = Color(0.18, 0.62, 1.0, 0.20)
	self.BeamOuter.material = _create_beam_material(4.8, 16.0, 0.88, 0.10, 0.72, 0.92)
	self.BeamCore.material = _create_beam_material(6.2, 24.0, 1.12, 0.06, 0.46, 1.18)
	_update_charge_visuals()

func _enter_firing_state() -> void:
	_state = BeamState.FIRING
	_state_time = 0.0
	_damage_tick_remaining = 0.0
	self.HurtboxComp.monitoring = true
	self.CollisionPolygon.disabled = false
	_update_beam_visuals()

func _enter_fading_state() -> void:
	_state = BeamState.FADING
	_state_time = 0.0
	self.HurtboxComp.monitoring = false
	self.CollisionPolygon.disabled = true

func _update_charge_visuals() -> void:
	var charge_ratio := clampf(_state_time / maxf(_charge_duration, 0.001), 0.0, 1.0)
	var pulse := sin(float(Time.get_ticks_msec()) * 0.009) * 0.5 + 0.5
	var charge_length := lerpf(_origin_offset + 26.0, _beam_length * 0.84, charge_ratio)
	var charge_width := _warning_width * (0.74 + charge_ratio * 0.56)
	var warning_points := _make_beam_points(charge_length, charge_width, _origin_offset, 2.2 + charge_ratio * 1.4, 6, 0.30, 0.10, true)
	self.WarningPolygon.visible = true
	if self.BeamHalo != null:
		self.BeamHalo.visible = true
	self.BeamOuter.visible = false
	self.BeamCore.visible = false
	self.EndpointGlow.visible = false
	self.WarningPolygon.polygon = warning_points
	self.WarningPolygon.modulate = Color(1.0, 1.0, 1.0, 0.32 + charge_ratio * 0.44 + pulse * 0.12)
	if self.BeamHalo != null:
		var halo_points := _make_beam_points(charge_length, charge_width * 1.9, _origin_offset - 4.0, 2.8 + charge_ratio * 1.8, 6, 0.22, 0.10, true)
		self.BeamHalo.polygon = halo_points
		self.BeamHalo.uv = _build_beam_uvs(halo_points, _origin_offset - 4.0, charge_length, charge_width * 1.9)
		self.BeamHalo.modulate = Color(1.0, 1.0, 1.0, 0.12 + charge_ratio * 0.20 + pulse * 0.08)
	self.ChargeRing.visible = true
	self.ChargeRing.scale = Vector2.ONE * (0.82 + charge_ratio * 0.34 + pulse * 0.04)
	self.ChargeRing.modulate = Color(1.0, 1.0, 1.0, 0.18 + charge_ratio * 0.34)
	self.CollisionPolygon.disabled = true
	_update_charge_pixels(charge_ratio, pulse)
	_update_beam_pixels(0.0, 0.0)

func _update_beam_visuals() -> void:
	var active_ratio := clampf(_state_time / maxf(_active_duration, 0.001), 0.0, 1.0)
	var pulse := sin(float(Time.get_ticks_msec()) * 0.015) * 0.5 + 0.5
	var halo_points := _make_beam_points(_beam_length, _beam_width * 1.92, _origin_offset - 8.0, 7.4 + pulse * 1.5, 9, 0.24, 0.24, true)
	var outer_points := _make_beam_points(_beam_length, _beam_width, _origin_offset, 7.0 + pulse * 1.1, 8, 0.24, 0.18, true)
	var core_points := _make_beam_points(_beam_length, _beam_width * 0.44, _origin_offset + 4.0, 3.8 + pulse * 0.6, 7, 0.20, 0.08, true)
	self.WarningPolygon.visible = true
	if self.BeamHalo != null:
		self.BeamHalo.visible = true
	self.BeamOuter.visible = true
	self.BeamCore.visible = true
	self.EndpointGlow.visible = true
	self.ChargeRing.visible = true
	self.WarningPolygon.polygon = _make_beam_points(_beam_length, _warning_width * 0.74, _origin_offset, 3.4 + pulse * 0.7, 6, 0.28, 0.08, true)
	self.WarningPolygon.modulate = Color(1.0, 1.0, 1.0, 0.18 + pulse * 0.08)
	if self.BeamHalo != null:
		self.BeamHalo.polygon = halo_points
		self.BeamHalo.uv = _build_beam_uvs(halo_points, _origin_offset - 8.0, _beam_length, _beam_width * 1.92)
		self.BeamHalo.modulate = Color(1.0, 1.0, 1.0, 0.30 + pulse * 0.12)
	self.BeamOuter.polygon = outer_points
	self.BeamOuter.uv = _build_beam_uvs(outer_points, _origin_offset, _beam_length, _beam_width)
	self.BeamCore.polygon = core_points
	self.BeamCore.uv = _build_beam_uvs(core_points, _origin_offset + 4.0, _beam_length, _beam_width * 0.44)
	self.BeamOuter.modulate = Color(1.0, 1.0, 1.0, 0.96 + pulse * 0.04)
	self.BeamCore.modulate = Color(1.0, 1.0, 1.0, 0.98 + pulse * 0.02)
	self.EndpointGlow.position = Vector2(_beam_length + 12.0, 0.0)
	self.EndpointGlow.scale = Vector2.ONE * (1.18 + pulse * 0.30)
	self.EndpointGlow.modulate = Color(1.0, 1.0, 1.0, 0.68 + pulse * 0.20)
	self.ChargeRing.scale = Vector2.ONE * (0.82 + pulse * 0.18)
	self.ChargeRing.modulate = Color(1.0, 1.0, 1.0, 0.22 + pulse * 0.14)
	self.CollisionPolygon.polygon = _make_collision_points(_beam_length, _beam_width * 0.60, _origin_offset)
	_update_charge_pixels(1.0, pulse)
	_update_beam_pixels(active_ratio, pulse)

func _update_fade_visuals() -> void:
	var fade_ratio := 1.0 - clampf(_state_time / maxf(_fade_duration, 0.001), 0.0, 1.0)
	self.WarningPolygon.visible = true
	if self.BeamHalo != null:
		self.BeamHalo.visible = true
	self.BeamOuter.visible = true
	self.BeamCore.visible = true
	self.EndpointGlow.visible = true
	self.ChargeRing.visible = true
	self.WarningPolygon.modulate = Color(1.0, 1.0, 1.0, fade_ratio * 0.16)
	if self.BeamHalo != null:
		self.BeamHalo.modulate = Color(1.0, 1.0, 1.0, fade_ratio * 0.18)
	self.BeamOuter.modulate = Color(1.0, 1.0, 1.0, fade_ratio * 0.72)
	self.BeamCore.modulate = Color(1.0, 1.0, 1.0, fade_ratio * 0.80)
	self.EndpointGlow.modulate = Color(1.0, 1.0, 1.0, fade_ratio * 0.42)
	self.ChargeRing.modulate = Color(1.0, 1.0, 1.0, fade_ratio * 0.20)
	_update_beam_pixels(1.0, fade_ratio)

func _apply_damage_tick() -> void:
	var candidates := _collect_beam_hitboxes()
	var blocker_in_front := false
	for candidate in candidates:
		var hitbox := candidate["hitbox"] as HitboxComponent
		var damage_scale := 1.0
		if blocker_in_front and _is_player_hitbox(hitbox) and _is_enemy_owned_beam():
			damage_scale = 0.4
		_damage_hitbox(hitbox, damage_scale)
		if _is_blocker_hitbox(hitbox):
			blocker_in_front = true

func _can_damage_hitbox(hitbox: HitboxComponent) -> bool:
	if hitbox == null or not is_instance_valid(hitbox):
		return false
	if self.Owner != null and hitbox.Owner == self.Owner:
		return false
	return true

func _damage_hitbox(hitbox: HitboxComponent, damage_scale: float = 1.0) -> void:
	var base_damage := self.HurtboxComp.Damage
	var scaled_damage := maxi(1, int(round(float(base_damage) * clampf(damage_scale, 0.0, 1.0))))
	self.HurtboxComp.Damage = scaled_damage
	if hitbox.Owner != null and hitbox.Owner.has_method("_handle_on_hit"):
		hitbox.Owner._handle_on_hit(self.HurtboxComp)
	else:
		hitbox.on_hit.emit(self.HurtboxComp)
	self.HurtboxComp.Damage = base_damage

func _is_hitbox_inside_beam(hitbox: HitboxComponent) -> bool:
	var beam_local := to_local(hitbox.global_position)
	var hitbox_radius := _estimate_hitbox_radius(hitbox)
	if beam_local.x < (_origin_offset - hitbox_radius):
		return false
	if beam_local.x > (_beam_length + hitbox_radius):
		return false
	return absf(beam_local.y) <= (_beam_width * 0.5 + hitbox_radius)

func _estimate_hitbox_radius(hitbox: HitboxComponent) -> float:
	for child in hitbox.get_children():
		if child is CollisionShape2D:
			var shape := (child as CollisionShape2D).shape
			if shape is RectangleShape2D:
				var size := (shape as RectangleShape2D).size
				return maxf(size.x, size.y) * 0.5
			if shape is CircleShape2D:
				return (shape as CircleShape2D).radius
		elif child is CollisionPolygon2D:
			var polygon := (child as CollisionPolygon2D).polygon
			if polygon.is_empty():
				continue
			var max_radius := 0.0
			for point in polygon:
				max_radius = maxf(max_radius, point.length())
			if max_radius > 0.0:
				return max_radius
	return 18.0

func _build_charge_pixels() -> void:
	_clear_children(self.ChargePixels)
	_charge_pixel_data.clear()
	for i in range(14):
		var angle := float(i) / 14.0 * TAU
		var pixel := Polygon2D.new()
		pixel.polygon = _make_rect_points(2.6, 2.6)
		pixel.color = Color(0.78, 0.95, 1.0, 0.66)
		pixel.scale = Vector2.ONE * (1.0 + fmod(float(i), 3.0) * 0.24)
		self.ChargePixels.add_child(pixel)
		_charge_pixel_data.append({
			"node": pixel,
			"config": {
				"angle": angle,
				"radius": 16.0 + float(i % 4) * 5.0,
				"phase": float(i) * 0.42,
			},
		})

func _build_beam_pixels() -> void:
	_clear_children(self.BeamPixels)
	_beam_pixel_data.clear()
	for i in range(26):
		var pixel := Polygon2D.new()
		pixel.polygon = _make_rect_points(6.6, 1.8)
		pixel.color = Color(0.90, 0.98, 1.0, 0.82)
		pixel.rotation = randf_range(-0.18, 0.18)
		self.BeamPixels.add_child(pixel)
		_beam_pixel_data.append({
			"node": pixel,
			"phase": float(i) * 0.17,
			"edge": -1.0 if i % 2 == 0 else 1.0,
			"speed": 0.34 + float(i % 5) * 0.12,
			"depth": 0.12 + float(i % 4) * 0.05,
		})

func _update_charge_pixels(charge_ratio: float, pulse: float) -> void:
	for entry in _charge_pixel_data:
		var pixel := entry["node"] as Polygon2D
		var config := entry["config"] as Dictionary
		var angle := float(config["angle"])
		var base_radius := float(config["radius"])
		var phase := float(config["phase"])
		var radius := lerpf(base_radius, 9.0, charge_ratio)
		var wobble := sin(float(Time.get_ticks_msec()) * 0.004 + phase) * (1.4 - charge_ratio)
		pixel.position = Vector2(cos(angle), sin(angle)) * (radius + wobble)
		pixel.rotation = angle
		pixel.modulate = Color(1.0, 1.0, 1.0, 0.36 + charge_ratio * 0.42 + pulse * 0.10)

func _update_beam_pixels(active_ratio: float, pulse: float) -> void:
	for entry in _beam_pixel_data:
		var pixel := entry["node"] as Polygon2D
		var phase := float(entry["phase"])
		var edge := float(entry["edge"])
		var speed := float(entry["speed"])
		var depth := float(entry["depth"])
		var travel := fposmod(float(Time.get_ticks_msec()) * 0.0018 * (1.2 + speed) + phase, 1.0)
		var x := lerpf(_origin_offset + 20.0, _beam_length - 22.0, travel)
		var fork := sin(float(Time.get_ticks_msec()) * 0.008 + phase * 2.6) * (_beam_width * depth)
		var offset_y := edge * (_beam_width * 0.18 + absf(fork))
		pixel.position = Vector2(x, offset_y)
		pixel.rotation = edge * 0.16 + sin(float(Time.get_ticks_msec()) * 0.004 + phase) * 0.08
		pixel.modulate = Color(1.0, 1.0, 1.0, maxf(active_ratio, pulse) * 0.62)
		pixel.visible = _state != BeamState.CHARGING

func _make_beam_points(length: float, width: float, start_offset: float, jaggedness: float = 0.0, segments: int = 6, start_taper: float = 0.44, end_flare: float = 0.0, animate: bool = true) -> PackedVector2Array:
	var safe_segments := maxi(segments, 2)
	var half_width := width * 0.5
	var polygon := PackedVector2Array()
	var bottom_points: Array[Vector2] = []
	var time := float(Time.get_ticks_msec()) * 0.001 if animate else 0.0
	for point_index in range(safe_segments + 1):
		var progress := float(point_index) / float(safe_segments)
		var x := lerpf(start_offset, length, progress)
		var width_scale := lerpf(start_taper, 1.0 + end_flare, progress)
		var edge_y := half_width * width_scale
		var jag := 0.0
		if jaggedness > 0.0:
			var envelope := sin(progress * PI)
			var wave_a := sin(progress * 22.0 + time * 9.6)
			var wave_b := sin(progress * 37.0 - time * 14.4 + 0.72)
			jag = (wave_a * 0.64 + wave_b * 0.36) * jaggedness * envelope
		polygon.append(Vector2(x, -edge_y + jag))
		bottom_points.append(Vector2(x, edge_y + jag * 0.55))
	for reverse_index in range(bottom_points.size() - 1, -1, -1):
		polygon.append(bottom_points[reverse_index])
	return polygon

func _make_collision_points(length: float, width: float, start_offset: float) -> PackedVector2Array:
	var half_width := width * 0.5
	return PackedVector2Array([
		Vector2(start_offset, -half_width * 0.38),
		Vector2(length, -half_width),
		Vector2(length, half_width),
		Vector2(start_offset, half_width * 0.38),
	])

func _make_rect_points(width: float, height: float) -> PackedVector2Array:
	var half_width := width * 0.5
	var half_height := height * 0.5
	return PackedVector2Array([
		Vector2(-half_width, -half_height),
		Vector2(half_width, -half_height),
		Vector2(half_width, half_height),
		Vector2(-half_width, half_height),
	])

func _create_beam_material(flow_speed: float, stripe_density: float, glow_strength: float, shimmer_strength: float, bolt_strength: float, core_hotness: float) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = BEAM_SHADER
	material.set_shader_parameter("flow_speed", flow_speed)
	material.set_shader_parameter("stripe_density", stripe_density)
	material.set_shader_parameter("glow_strength", glow_strength)
	material.set_shader_parameter("shimmer_strength", shimmer_strength)
	material.set_shader_parameter("bolt_strength", bolt_strength)
	material.set_shader_parameter("core_hotness", core_hotness)
	material.set_shader_parameter("edge_softness", 0.08)
	material.set_shader_parameter("pixel_density", 26.0 + stripe_density * 0.28)
	return material

func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()

func _ensure_beam_halo() -> void:
	if self.BeamHalo != null:
		return
	self.BeamHalo = Polygon2D.new()
	self.BeamHalo.name = "beam_halo"
	self.BeamHalo.z_index = 2
	self.BeamHalo.visible = false
	self.BeamHalo.color = Color(0.18, 0.62, 1.0, 0.20)
	add_child(self.BeamHalo)
	move_child(self.BeamHalo, 1)

func _collect_beam_hitboxes() -> Array[Dictionary]:
	var unique_hits: Dictionary = {}
	for area in self.HurtboxComp.get_overlapping_areas():
		if area is HitboxComponent:
			unique_hits[area.get_instance_id()] = area

	var scene_root: Node = get_tree().current_scene if get_tree().current_scene != null else get_tree().root
	for candidate in scene_root.find_children("*", "HitboxComponent", true, false):
		var hitbox := candidate as HitboxComponent
		if hitbox != null:
			unique_hits[hitbox.get_instance_id()] = hitbox

	for group_name in ["player", "regulated_enemy"]:
		for body in get_tree().get_nodes_in_group(group_name):
			if body == null or not is_instance_valid(body):
				continue
			var hitbox := body.get_node_or_null("hitbox_comp") as HitboxComponent
			if hitbox != null:
				unique_hits[hitbox.get_instance_id()] = hitbox

	var result: Array[Dictionary] = []
	for hitbox in unique_hits.values():
		if not _can_damage_hitbox(hitbox):
			continue
		if not _is_hitbox_inside_beam(hitbox):
			continue
		result.append({
			"hitbox": hitbox,
			"distance": to_local(hitbox.global_position).x,
		})
	result.sort_custom(_sort_beam_candidates)
	return result

func _sort_beam_candidates(a: Dictionary, b: Dictionary) -> bool:
	return float(a["distance"]) < float(b["distance"])

func _build_beam_uvs(points: PackedVector2Array, start_offset: float, length: float, width: float) -> PackedVector2Array:
	var safe_start := start_offset
	var safe_length := maxf(length - start_offset, 1.0)
	var safe_half_width := maxf(width * 0.5, 1.0)
	var uvs := PackedVector2Array()
	for point in points:
		var u := clampf((point.x - safe_start) / safe_length, 0.0, 1.0)
		var v := clampf((point.y / (safe_half_width * 2.0)) + 0.5, 0.0, 1.0)
		uvs.append(Vector2(u, v))
	return uvs

func _is_player_hitbox(hitbox: HitboxComponent) -> bool:
	return hitbox.Owner != null and hitbox.Owner.is_in_group("player")

func _is_blocker_hitbox(hitbox: HitboxComponent) -> bool:
	return hitbox.Owner != null and hitbox.Owner.is_in_group("regulated_enemy")

func _is_enemy_owned_beam() -> bool:
	return self.Owner != null and self.Owner.is_in_group("regulated_enemy")
