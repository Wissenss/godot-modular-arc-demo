class_name EnemyOne extends CharacterBody2D

var Polygon : Polygon2D
var HurtboxComp : HurtboxComponent
var KnockbackComp : KnockbackComponent

func _ready() -> void:
	self.Polygon = $polygon
	
	self.HurtboxComp = $hurtbox_comp
	self.HurtboxComp.Damage = 30
	self.HurtboxComp.on_hurt.connect(self._handle_on_hurt)
	
	self.KnockbackComp = $knockback_comp
	self.KnockbackComp.Force = 100
	self.KnockbackComp.Owner = self

func _handle_on_hurt(to : Area2D, damage : int) -> void:
	# apply knockback effect
	if to is HitboxComponent:
		self.KnockbackComp._apply_knockback_to_character(to.Owner)
	
	# blinks when it deals damage
	for i in range(4):
		self.Polygon.color.r += 20
		await get_tree().create_timer(0.1).timeout
		self.Polygon.color.r -= 20
		await get_tree().create_timer(0.1).timeout
