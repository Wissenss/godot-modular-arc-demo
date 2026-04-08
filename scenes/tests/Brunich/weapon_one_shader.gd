extends Node2D

const MUZZLE_OFFSET := 30.0
const PROJECTILE_SPEED := 360.0
const SHOOT_COOLDOWN := 0.08

var ProjectileScene: PackedScene
var Owner: Node2D
var _cooldown_remaining := 0.0

func _ready() -> void:
	self.ProjectileScene = preload("res://scenes/tests/Brunich/projectile_one_shader.tscn")

func _process(delta: float) -> void:
	_cooldown_remaining = maxf(_cooldown_remaining - delta, 0.0)

func _shoot(direction: Vector2) -> bool:
	if _cooldown_remaining > 0.0:
		return false

	var shoot_dir := direction.normalized()
	if shoot_dir == Vector2.ZERO:
		return false

	var projectile: Node2D = self.ProjectileScene.instantiate() as Node2D
	projectile.global_position = self.Owner.global_position + shoot_dir * MUZZLE_OFFSET
	projectile.rotation = shoot_dir.angle()
	projectile.Owner = self.Owner

	var parent: Node = get_tree().current_scene if get_tree().current_scene != null else get_tree().root
	parent.add_child(projectile)

	projectile.HurtboxComp.Owner = self.Owner
	projectile.ConstantVelocityComp.Speed = PROJECTILE_SPEED
	projectile.ConstantVelocityComp.Direction = shoot_dir
	_cooldown_remaining = SHOOT_COOLDOWN
	return true
