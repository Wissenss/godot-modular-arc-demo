class_name EnemyAICoreWeapon
extends Node2D

const BEAM_SCENE := preload("res://scenes/tests/Brunich/enemy_ai_beam.tscn")

var Owner: CharacterBody2D
var ShootInterval := 1.16

var _shoot_timer := 0.0
var _active_beam: Node2D = null

func _physics_process(delta: float) -> void:
	if Owner == null:
		return
	if is_instance_valid(_active_beam):
		return

	_shoot_timer += delta
	if _shoot_timer >= ShootInterval:
		_shoot_timer = 0.0
		_fire_beam()

func _fire_beam() -> void:
	var target := _get_player()
	if target == null:
		return

	var beam := BEAM_SCENE.instantiate() as Node2D
	beam.Owner = Owner
	beam.TrackingTarget = target
	beam.rotation = (target.global_position - Owner.global_position).angle()
	beam.configure_beam(_get_beam_profile())
	var parent: Node = get_tree().current_scene if get_tree().current_scene != null else get_tree().root
	parent.add_child(beam)
	_active_beam = beam
	beam.beam_finished.connect(_on_beam_finished)

func get_attack_profile_for_player() -> Dictionary:
	return {
		"id": "enemy_ai_core_beam",
		"fire_mode": "beam",
		"beam_scene": BEAM_SCENE,
		"shoot_cooldown": ShootInterval,
		"beam_profile": _get_beam_profile(),
	}

func get_visual_attack_state() -> Dictionary:
	var prep_ratio := clampf(_shoot_timer / maxf(ShootInterval, 0.001), 0.0, 1.0)
	var visual_state := {
		"prep_ratio": prep_ratio,
		"charge_ratio": prep_ratio * 0.16,
		"beam_intensity": 0.0,
		"fade_ratio": 0.0,
	}
	if _active_beam != null and is_instance_valid(_active_beam) and _active_beam.has_method("get_visual_state"):
		var beam_state: Dictionary = _active_beam.get_visual_state()
		for key in beam_state.keys():
			visual_state[key] = beam_state[key]
		visual_state["prep_ratio"] = 1.0
	return visual_state

func _get_player() -> Node2D:
	var players := get_tree().get_nodes_in_group("player")
	return players[0] as Node2D if not players.is_empty() else null

func _get_beam_profile() -> Dictionary:
	return {
		"charge_duration": 0.72,
		"active_duration": 6.0,
		"fade_duration": 0.24,
		"beam_length": 720.0,
		"warning_width": 16.0,
		"beam_width": 34.0,
		"track_speed": 430.1,
		"damage_tick_interval": 0.09,
		"damage_per_tick": 36,
		"origin_offset": 28.0,
		"warning_color": Color(0.74, 0.94, 1.0, 0.46),
		"beam_outer_color": Color(0.50, 0.86, 1.0, 0.92),
		"beam_core_color": Color(0.96, 0.99, 1.0, 0.98),
		"endpoint_color": Color(0.96, 0.99, 1.0, 0.88),
	}

func _get_pickup_beam_profile() -> Dictionary:
	return {
		"charge_duration": 0.40,
		"active_duration": 1.04,
		"fade_duration": 0.16,
		"beam_length": 760.0,
		"warning_width": 15.0,
		"beam_width": 30.0,
		"track_speed": 10.8,
		"damage_tick_interval": 0.10,
		"damage_per_tick": 8,
		"origin_offset": 28.0,
		"warning_color": Color(0.82, 0.94, 1.0, 0.44),
		"beam_outer_color": Color(0.62, 0.88, 1.0, 0.92),
		"beam_core_color": Color(0.98, 1.0, 1.0, 0.98),
		"endpoint_color": Color(0.98, 1.0, 1.0, 0.88),
	}

func _on_beam_finished() -> void:
	_active_beam = null
