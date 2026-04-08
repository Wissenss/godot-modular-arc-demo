class_name ProjectileEnemy extends Node2D
## Larger, slower, more damaging projectile used by enemies.
## Can be inherited by the player when stealing the enemy weapon.

var ConstantVelocityComp : ConstantVelocityComponent
var HurtboxComp : HurtboxComponent
var Owner : Node2D


func _ready() -> void:
	self.ConstantVelocityComp = $constant_velocity_comp
	self.ConstantVelocityComp.Owner = self

	self.HurtboxComp = $hurtbox_comp
	self.HurtboxComp.on_hurt.connect(self._handle_on_hurt)

	# Auto-destroy after 5 seconds to avoid leaks
	var lifetime := Timer.new()
	lifetime.one_shot = true
	lifetime.wait_time = 5.0
	lifetime.timeout.connect(self.queue_free)
	add_child(lifetime)
	lifetime.start()


func _handle_on_hurt(to: Area2D, _damage: int) -> void:
	if to is HitboxComponent:
		if self.Owner == to.Owner:
			return
		self.queue_free()
