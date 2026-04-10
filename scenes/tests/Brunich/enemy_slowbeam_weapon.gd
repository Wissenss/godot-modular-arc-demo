class_name EnemySlowbeamWeapon extends Node2D

## Control beam: slow heavy projectile that applies a speed penalty on hit.

const MUZZLE_OFFSET := 32.0
const PROJECTILE_SPEED := 395.0
const PROJECTILE_SCENE := preload("res://scenes/tests/Brunich/enemy_slowbeam_projectile.tscn")

var Owner: CharacterBody2D
var ShootInterval := 1.55
var PredictionLead := 0.06

var _shoot_timer := 0.0
var _projectile_scene: PackedScene

func _ready() -> void:
	randomize()
	_projectile_scene = PROJECTILE_SCENE

func _process(delta: float) -> void:
	if Owner == null:
		return

	_shoot_timer += delta
	if _shoot_timer >= ShootInterval:
		_shoot_timer = 0.0
		_fire_slow()

func _fire_slow() -> void:
	var target := _get_player()
	if target == null:
		return
	_shoot(_get_predicted_direction(target))

func _get_player() -> Node2D:
	var players := get_tree().get_nodes_in_group("player")
	return players[0] as Node2D if not players.is_empty() else null

func _get_predicted_direction(target: Node2D) -> Vector2:
	var target_velocity := Vector2.ZERO
	if target.has_node("constant_velocity_comp"):
		var vc := target.get_node("constant_velocity_comp")
		target_velocity = vc.Direction * vc.Speed
	return ((target.global_position + target_velocity * PredictionLead) - Owner.global_position).normalized()

func _shoot(direction: Vector2) -> void:
	var d := direction.normalized()
	if d == Vector2.ZERO:
		return

	var proj: Node2D = _projectile_scene.instantiate() as Node2D
	proj.global_position = Owner.global_position + d * MUZZLE_OFFSET
	proj.rotation = d.angle()
	proj.Owner = Owner
	if proj.has_method("configure_projectile"):
		proj.configure_projectile(_get_projectile_profile())

	var parent: Node = get_tree().current_scene if get_tree().current_scene != null else get_tree().root
	parent.add_child(proj)

	proj.HurtboxComp.Owner = Owner
	proj.ConstantVelocityComp.Speed = PROJECTILE_SPEED
	proj.ConstantVelocityComp.Direction = d

func get_attack_profile_for_player() -> Dictionary:
	return {
		"id": "enemy_slowbeam",
		"fire_mode": "single",
		"projectile_scene": PROJECTILE_SCENE,
		"muzzle_offset": MUZZLE_OFFSET,
		"projectile_speed": 380.0,
		"shoot_cooldown": 0.14,
		"projectile_profile": _get_pickup_profile(),
	}

func _get_projectile_profile() -> Dictionary:
	return {
		"damage": 8,
		"life_time": 3.0,
		"visual_scale": 1.62,
		"outer_color": Color(0.06, 0.84, 0.72, 0.90),
		"core_color": Color(0.02, 0.14, 0.12, 1.0),
		"code_color": Color(0.72, 0.98, 0.94, 0.96),
		"trail_color": Color(0.04, 0.82, 0.68, 0.60),
		"trail_scale_min": 6.0,
		"trail_scale_max": 10.0,
		"slow_factor": 0.36,
		"slow_duration": 1.8,
	}

func _get_pickup_profile() -> Dictionary:
	return {
		"damage": 8,
		"life_time": 2.8,
		"visual_scale": 1.55,
		"outer_color": Color(0.06, 0.84, 0.72, 0.90),
		"core_color": Color(0.02, 0.16, 0.14, 1.0),
		"code_color": Color(0.72, 0.98, 0.94, 0.96),
		"trail_color": Color(0.04, 0.82, 0.68, 0.58),
		"trail_scale_min": 6.0,
		"trail_scale_max": 9.0,
		"slow_factor": 0.36,
		"slow_duration": 1.8,
	}
