class_name WeaponEnemy extends Node2D
## Charged projectile weapon used by enemies (and by the player after stealing).
## Fires a slower, larger, more damaging projectile.

var ProjectileScene : PackedScene
var Owner : Node2D

## Damage dealt by the projectile hurtbox.
var Damage := 40
## Projectile travel speed (lower = slower but bigger projectile).
var ProjectileSpeed := 35.0


func _ready() -> void:
	self.ProjectileScene = preload("res://scenes/weapons/proyectiles/projectile_enemy.tscn")


func _shoot(direction: Vector2) -> void:
	var proj = self.ProjectileScene.instantiate()

	proj.global_position = self.Owner.global_position
	proj.Owner = self.Owner

	get_tree().root.add_child(proj)

	proj.HurtboxComp.Owner  = self.Owner
	proj.HurtboxComp.Damage = self.Damage
	proj.ConstantVelocityComp.Speed     = self.ProjectileSpeed
	proj.ConstantVelocityComp.Direction = direction
