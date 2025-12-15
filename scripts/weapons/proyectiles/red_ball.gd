class_name RedBall extends Node2D

var ConstantVelocityComp : ConstantVelocityComponent

func _ready() -> void:
	self.ConstantVelocityComp = $constant_velocity_comp
	pass
