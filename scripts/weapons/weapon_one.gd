class_name WeaponOne extends Node2D

var projectileScene : PackedScene
var Owner : Node2D

func _ready() -> void: 
	# TODO: allow the weapon to change amunition
	self.projectileScene = preload("res://scenes/weapons/proyectiles/proyectile_one.tscn") 

func _shoot(direction : Vector2) -> void:
	var projectile = projectileScene.instantiate()
	
	projectile.global_position = self.Owner.global_position
	projectile.Owner = self.Owner
	
	get_tree().root.add_child(projectile)
	
	projectile.HurtboxComp.Owner = self.Owner
	projectile.ConstantVelocityComp.Speed = 50
	projectile.ConstantVelocityComp.Direction = direction
