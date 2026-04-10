class_name EnemyWeapon extends Node2D

const MUZZLE_OFFSET := 34.0
const PROJECTILE_SPEED := 410.0
const PROJECTILE_SCENE := preload("res://scenes/tests/Brunich/enemy_projectile.tscn")

var Owner: CharacterBody2D
var ShootInterval := 0.62
var BurstSize := 2
var BurstSpacing := 0.16
var SpreadAngle := 0.14
var PredictionLead := 0.22

var _shoot_timer := 0.0
var _burst_timer := 0.0
var _burst_remaining := 0
var _projectile_scene: PackedScene

func _ready() -> void:
	randomize()
	_projectile_scene = PROJECTILE_SCENE

func _process(delta: float) -> void:
	if Owner == null:
		return

	if _burst_remaining > 0:
		_burst_timer -= delta
		if _burst_timer <= 0.0:
			_fire_burst_shot()
		return

	_shoot_timer += delta
	if _shoot_timer >= ShootInterval:
		_shoot_timer = 0.0
		_burst_remaining = BurstSize
		_burst_timer = 0.0

func _fire_burst_shot() -> void:
	var target := _get_player()
	if target == null:
		_burst_remaining = 0
		return

	var direction := _get_predicted_direction(target)
	var spread_index := BurstSize - _burst_remaining
	var centered := float(spread_index) - float(BurstSize - 1) * 0.5
	direction = direction.rotated(centered * SpreadAngle)
	_shoot(direction)

	_burst_remaining -= 1
	_burst_timer = BurstSpacing

func _get_player() -> Node2D:
	var players := get_tree().get_nodes_in_group("player")
	return players[0] as Node2D if not players.is_empty() else null

func _get_predicted_direction(target: Node2D) -> Vector2:
	var target_velocity := Vector2.ZERO
	if target.has_node("constant_velocity_comp"):
		var velocity_comp := target.get_node("constant_velocity_comp")
		target_velocity = velocity_comp.Direction * velocity_comp.Speed

	var predicted_pos := target.global_position + target_velocity * PredictionLead
	return (predicted_pos - Owner.global_position).normalized()

func _shoot(direction: Vector2) -> void:
	var shoot_dir := direction.normalized()
	if shoot_dir == Vector2.ZERO:
		return

	var projectile: Node2D = _projectile_scene.instantiate() as Node2D
	projectile.global_position = Owner.global_position + shoot_dir * MUZZLE_OFFSET
	projectile.rotation = shoot_dir.angle()
	projectile.Owner = Owner
	if projectile.has_method("configure_projectile"):
		projectile.configure_projectile(_get_projectile_profile())

	var parent: Node = get_tree().current_scene if get_tree().current_scene != null else get_tree().root
	parent.add_child(projectile)

	projectile.HurtboxComp.Owner = Owner
	projectile.ConstantVelocityComp.Speed = PROJECTILE_SPEED
	projectile.ConstantVelocityComp.Direction = shoot_dir

func get_attack_profile_for_player() -> Dictionary:
	return {
		"id": "enemy_orb",
		"fire_mode": "burst",
		"burst_size": BurstSize,
		"burst_spacing": BurstSpacing,
		"spread_angle": SpreadAngle,
		"projectile_scene": PROJECTILE_SCENE,
		"muzzle_offset": MUZZLE_OFFSET,
		"projectile_speed": 390.0,
		"shoot_cooldown": 0.22,
		"projectile_profile": {
			"damage": 14,
			"life_time": 2.0,
			"visual_scale": 1.28,
			"outer_color": Color(0.18, 0.94, 1.0, 0.94),
			"core_color": Color(0.04, 0.16, 0.32, 1.0),
			"code_color": Color(0.92, 0.98, 1.0, 0.92),
			"trail_color": Color(0.40, 0.92, 1.0, 0.55),
			"trail_scale_min": 6.0,
			"trail_scale_max": 9.0,
		},
	}

func _get_projectile_profile() -> Dictionary:
	return {
		"damage": 22,
		"life_time": 2.5,
		"visual_scale": 1.28,
		"outer_color": Color(0.18, 0.94, 1.0, 0.94),
		"core_color": Color(0.04, 0.16, 0.32, 1.0),
		"code_color": Color(0.92, 0.99, 1.0, 0.95),
		"trail_color": Color(0.06, 0.88, 1.0, 0.6),
		"trail_scale_min": 6.0,
		"trail_scale_max": 9.0,
	}
