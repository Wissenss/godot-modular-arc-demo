class_name EnemyWeapon extends Node2D

const MUZZLE_OFFSET := 34.0
const PROJECTILE_SPEED := 300.0

var Owner: CharacterBody2D
var ShootInterval := 0.55
var BurstSize := 3
var BurstSpacing := 0.11
var SpreadAngle := 0.12
var PredictionLead := 0.22

var _shoot_timer := 0.0
var _burst_timer := 0.0
var _burst_remaining := 0
var _projectile_scene: PackedScene

func _ready() -> void:
	randomize()
	_projectile_scene = preload("res://scenes/tests/Brunich/enemy_projectile.tscn")

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

	var parent: Node = get_tree().current_scene if get_tree().current_scene != null else get_tree().root
	parent.add_child(projectile)

	projectile.HurtboxComp.Owner = Owner
	projectile.ConstantVelocityComp.Speed = PROJECTILE_SPEED
	projectile.ConstantVelocityComp.Direction = shoot_dir
