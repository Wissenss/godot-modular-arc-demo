extends CharacterBody2D

var ControllerComp : ControllerComponent
var ConstantVelocityComp : ConstantVelocityComponent

func _ready() -> void:
	self.ControllerComp = $controller_comp
	self.ControllerComp.Owner = self

	self.ConstantVelocityComp = $constant_velocity_comp
	self.ConstantVelocityComp.Owner = self
	self.ConstantVelocityComp.Speed = 400

func _input(event: InputEvent) -> void:
	if Utils.HasComponent(self, KnockbackEffectComponent.get_class_name()):
		self.ConstantVelocityComp.Direction = Vector2(0, 0)
		return

	if Utils.HasComponent(self, FrozenEffectComp.get_class_name()):
		self.ConstantVelocityComp.Direction = Vector2(0, 0)
		return

	self.ConstantVelocityComp.Direction = self.ControllerComp._get_move_direction()
