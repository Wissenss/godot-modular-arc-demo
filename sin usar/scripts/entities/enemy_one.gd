class_name EnemyOne extends CharacterBody2D

var Polygon : Polygon2D
var HurtboxComp : HurtboxComponent
var HitboxComp : HitboxComponent
var KnockbackComp : KnockbackComponent

func _ready() -> void:
	self.Polygon = $polygon
	
	self.HurtboxComp = $hurtbox_comp
	self.HurtboxComp.Damage = 30
	self.HurtboxComp.on_hurt.connect(self._handle_on_hurt)
	
	self.KnockbackComp = $knockback_comp
	self.KnockbackComp.Force = 100
	self.KnockbackComp.Owner = self
	
	self.HitboxComp = $hitbox_comp
	self.HitboxComp.on_hit.connect(self._handle_on_hit)

func _do_blink_effect() -> void:
	for i in range(4):
		self.Polygon.color.r += 20
		await get_tree().create_timer(0.1).timeout
		self.Polygon.color.r -= 20
		await get_tree().create_timer(0.1).timeout

func _handle_on_hurt(to : Area2D, damage : int) -> void:
	# apply knockback effect
	if to is HitboxComponent:
		if to == self.HitboxComp: # do not, knockback yourself
			return
		
		self.KnockbackComp._apply_knockback_to_character(to.Owner)

func _handle_on_hit(by : Area2D):
	self._do_blink_effect()
