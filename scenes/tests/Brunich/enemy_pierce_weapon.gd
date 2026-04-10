class_name EnemyPierceWeapon extends Node2D

## Precision sniper: single slow heavy projectile that passes through the player once.

const MUZZLE_OFFSET := 42.0
const PROJECTILE_SPEED := 687.7
const PROJECTILE_SCENE := preload("res://scenes/tests/Brunich/enemy_pierce_projectile.tscn")

var Owner: CharacterBody2D
var ShootInterval := 2.28
var PredictionLead := 0.28

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
		_fire_pierce()

func _fire_pierce() -> void:
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
		"id": "enemy_pierce",
		"fire_mode": "single",
		"projectile_scene": PROJECTILE_SCENE,
		"muzzle_offset": MUZZLE_OFFSET,
		"projectile_speed": PROJECTILE_SPEED,
		"shoot_cooldown": ShootInterval,
		"projectile_profile": _get_projectile_profile(),
	}

func _get_projectile_profile() -> Dictionary:
	return {
		"damage": 62,
		"life_time": 3.2,
		"visual_scale": 1.75,
		"outer_color": Color(0.84, 0.90, 1.0, 0.96),
		"core_color": Color(0.06, 0.06, 0.10, 1.0),
		"code_color": Color(0.94, 0.96, 1.0, 1.0),
		"trail_color": Color(0.74, 0.82, 1.0, 0.65),
		"trail_scale_min": 7.0,
		"trail_scale_max": 11.0,
		"pierce_count": -1,
		"preserve_stolen_damage": true,
	}

func _get_pickup_profile() -> Dictionary:
	return {
		"damage": 62,
		"life_time": 3.0,
		"visual_scale": 1.70,
		"outer_color": Color(0.82, 0.88, 1.0, 0.96),
		"core_color": Color(0.08, 0.08, 0.12, 1.0),
		"code_color": Color(0.92, 0.94, 1.0, 0.98),
		"trail_color": Color(0.72, 0.80, 1.0, 0.60),
		"trail_scale_min": 7.0,
		"trail_scale_max": 10.0,
		"pierce_count": -1,
		"preserve_stolen_damage": true,
	}
