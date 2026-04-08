class_name WeaponOneShader extends Node2D

var ProjectileScene : PackedScene
var Owner : Node2D

func _ready() -> void:
	self.ProjectileScene = preload("res://scenes/tests/wissens/projectile_one_shader.tscn")

func _shoot(direction : Vector2) -> void:
	var projectile = self.ProjectileScene.instantiate()

	projectile.global_position = self.Owner.global_position
	projectile.Owner = self.Owner

	get_tree().root.add_child(projectile)

	projectile.HurtboxComp.Owner = self.Owner
	projectile.ConstantVelocityComp.Speed = 50
	projectile.ConstantVelocityComp.Direction = direction
