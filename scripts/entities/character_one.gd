class_name CharacterOne extends CharacterBody2D

var HealthComp : HealthComponent
var HitboxComp : HitboxComponent
var ControllerComp : ControllerComponent
var ConstantVelocityComp : ConstantVelocityComponent

func _ready() -> void:
	self.HealthComp = $health_comp
	self.HealthComp.set_health(100)
	self.HealthComp.set_max_health(100)
	self.HealthComp.on_health_changed.connect(self._handle_on_health_changed)
	self.HealthComp.on_died.connect(self._handle_on_died)
	
	self.HitboxComp = $hitbox_comp
	self.HitboxComp.Owner = self
	self.HitboxComp.on_hit.connect(_handle_on_hit)
	
	self.ControllerComp = $controller_comp
	self.ControllerComp.Owner = self
	
	self.ConstantVelocityComp = $constant_velocity_comp
	self.ConstantVelocityComp.Owner = self
	self.ConstantVelocityComp.Speed = 400

func _handle_on_health_changed(health : int, old_health: int) -> void:
	pass

func _handle_on_died() -> void:
	self.queue_free()

func _handle_on_hit(by: Area2D) -> void:
	if by is HurtboxComponent:
		self.HealthComp.take_damage(by.Damage)

func _input(event: InputEvent) -> void:
	# if the character has knockback, do not apply movement
	if Utils.HasComponent(self, KnockbackEffectComponent.get_class_name()):
		self.ConstantVelocityComp.Direction = Vector2(0, 0)
		return
	
	self.ConstantVelocityComp.Direction = self.ControllerComp._get_move_direction()
