extends CharacterBody2D

var ControllerComp : ControllerComponent
var ConstantVelocityComp : ConstantVelocityComponent
var BodyParticles : CPUParticles2D
var TrailParticles : CPUParticles2D

func _ready() -> void:
	self.ControllerComp = $controller_comp
	self.ControllerComp.Owner = self

	self.ConstantVelocityComp = $constant_velocity_comp
	self.ConstantVelocityComp.Owner = self
	self.ConstantVelocityComp.Speed = 400
	
	self.BodyParticles = $body_particles
	self.TrailParticles = $trail_particles

func _input(event: InputEvent) -> void:
	if Utils.HasComponent(self, KnockbackEffectComponent.get_class_name()):
		self.ConstantVelocityComp.Direction = Vector2(0, 0)
		return

	if Utils.HasComponent(self, FrozenEffectComp.get_class_name()):
		self.ConstantVelocityComp.Direction = Vector2(0, 0)
		return
	
	self.ConstantVelocityComp.Direction = self.ControllerComp._get_move_direction()

func _process(delta):
	var is_moving : bool = self.ConstantVelocityComp.Direction != Vector2.ZERO
	
	if is_moving:
		self.BodyParticles.orbit_velocity_min = 0
		self.BodyParticles.orbit_velocity_max = 0
		#self.BodyParticles.lifetime = 0.5
		self.BodyParticles.emitting = false
		self.TrailParticles.emitting = true
	else:
		self.BodyParticles.orbit_velocity_min = -1
		self.BodyParticles.orbit_velocity_max = 1
		#self.BodyParticles.lifetime = 1
		self.BodyParticles.emitting = true
		self.TrailParticles.emitting = false
