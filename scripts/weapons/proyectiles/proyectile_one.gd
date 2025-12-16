class_name ProyectileOne extends Node2D

var ConstantVelocityComp : ConstantVelocityComponent
var HurtboxComp : HurtboxComponent
var Owner : Node2D
var Direction : Vector2

func _ready() -> void:
	self.ConstantVelocityComp = $constant_velocity_comp
	self.ConstantVelocityComp.Owner = self
	self.ConstantVelocityComp.Direction = Direction
	
	self.HurtboxComp = $hurtbox_comp
	self.HurtboxComp.on_hurt.connect(self._handle_on_hurt)

func _set_direction(direction : Vector2):
	self.Direction = direction

func _handle_on_hurt(to: Area2D, damage: int):	
	if to is HitboxComponent:
		if self.Owner == to.Owner: # do not destroy projectile if it hits the player that shoot it
			return
		
		self.queue_free()
