class_name WeaponOne extends Node2D

var ProjectileScene : PackedScene
var Owner : Node2D

func _ready() -> void: 
	# TODO: allow the weapon to change amunition
	self.ProjectileScene = preload("res://scenes/weapons/proyectiles/projectile_one.tscn") 

func _shoot(direction : Vector2) -> void:
	var projectile = self.ProjectileScene.instantiate()
	
	projectile.global_position = self.Owner.global_position
	projectile.Owner = self.Owner
	
	get_tree().root.add_child(projectile)
	
	projectile.HurtboxComp.Owner = self.Owner
	projectile.ConstantVelocityComp.Speed = 50
	projectile.ConstantVelocityComp.Direction = direction
