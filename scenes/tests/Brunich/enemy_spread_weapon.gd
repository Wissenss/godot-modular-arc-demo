class_name EnemySpreadWeapon extends Node2D

## Shotgun-style burst: 5 pellets fired simultaneously in a wide arc.

const MUZZLE_OFFSET := 30.0
const PROJECTILE_SPEED := 483.0
const PELLET_COUNT := 5
const SPREAD_TOTAL := 0.455  # 35% tighter than the prior spread
const PROJECTILE_SCENE := preload("res://scenes/tests/Brunich/enemy_spread_projectile.tscn")

var Owner: CharacterBody2D
var ShootInterval := 0.195
var PredictionLead := 0.10

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
		_fire_spread()

func _fire_spread() -> void:
	var target := _get_player()
	if target == null:
		return

	var base_dir := _get_predicted_direction(target)
	for i in range(PELLET_COUNT):
		var t := float(i) / float(PELLET_COUNT - 1)
		var angle := -SPREAD_TOTAL * 0.5 + SPREAD_TOTAL * t
		_shoot(base_dir.rotated(angle))

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
		"id": "enemy_spread",
		"fire_mode": "spread",
		"pellet_count": PELLET_COUNT,
		"spread_total": SPREAD_TOTAL,
		"projectile_scene": PROJECTILE_SCENE,
		"muzzle_offset": MUZZLE_OFFSET,
		"projectile_speed": PROJECTILE_SPEED,
		"shoot_cooldown": ShootInterval,
		"projectile_profile": _get_projectile_profile(),
	}

func _get_projectile_profile() -> Dictionary:
	return {
		"damage": 3,
		"life_time": 1.05,
		"visual_scale": 0.80,
		"outer_color": Color(1.0, 0.74, 0.05, 0.92),
		"core_color": Color(0.24, 0.10, 0.02, 1.0),
		"code_color": Color(1.0, 0.93, 0.65, 0.96),
		"trail_color": Color(1.0, 0.62, 0.06, 0.55),
		"trail_scale_min": 4.0,
		"trail_scale_max": 6.0,
	}

func _get_pickup_profile() -> Dictionary:
	return {
		"damage": 3,
		"life_time": 1.2,
		"visual_scale": 0.85,
		"outer_color": Color(1.0, 0.78, 0.08, 0.92),
		"core_color": Color(0.28, 0.14, 0.02, 1.0),
		"code_color": Color(1.0, 0.96, 0.72, 0.95),
		"trail_color": Color(1.0, 0.72, 0.10, 0.55),
		"trail_scale_min": 5.0,
		"trail_scale_max": 7.0,
	}
