class_name CharacterOne extends CharacterBody2D

var HealthComp : HealthComponent
var HitboxComp : HitboxComponent
var ControllerComp : ControllerComponent
var ConstantVelocityComp : ConstantVelocityComponent

var WeaponOne : WeaponOne

var Polygon : Polygon2D

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
	
	self.WeaponOne = $weapon_one
	self.WeaponOne.Owner = self
	
	self.Polygon = $polygon

func _handle_on_health_changed(health : int, old_health: int) -> void:
	pass

func _handle_on_died() -> void:
	self.queue_free()

func _do_blink_effect() -> void:
	for i in range(4):
		self.Polygon.color.b += 20
		await get_tree().create_timer(0.1).timeout
		self.Polygon.color.b -= 20
		await get_tree().create_timer(0.1).timeout

func _handle_on_hit(by: Area2D) -> void:
	if by is HurtboxComponent:
		if by.Owner == self: # ignore your own shots
			return
		
		self.HealthComp.take_damage(by.Damage)
		
		self._do_blink_effect()

func _input(event: InputEvent) -> void:
	# if the character has knockback, do not apply movement
	if Utils.HasComponent(self, KnockbackEffectComponent.get_class_name()):
		self.ConstantVelocityComp.Direction = Vector2(0, 0)
		return
	
	# if the character is frozen, do not apply movement:
	if Utils.HasComponent(self, FrozenEffectComp.get_class_name()):
		self.ConstantVelocityComp.Direction = Vector2(0, 0)
		return
	
	self.ConstantVelocityComp.Direction = self.ControllerComp._get_move_direction()
	
	if self.ControllerComp._is_shoot_pressed():
		self.WeaponOne._shoot(self.ControllerComp._get_aim_direction())
