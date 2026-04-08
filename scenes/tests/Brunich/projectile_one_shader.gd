extends Node2D

const LIFE_TIME := 1.8
const BASE_DAMAGE := 24

var ConstantVelocityComp: ConstantVelocityComponent
var HurtboxComp: HurtboxComponent
var Owner: Node2D
var _life_remaining := LIFE_TIME

func _ready() -> void:
	add_to_group("player_projectile")

	self.ConstantVelocityComp = $constant_velocity_comp
	self.ConstantVelocityComp.Owner = self

	self.HurtboxComp = $hurtbox_comp
	self.HurtboxComp.Damage = BASE_DAMAGE
	self.HurtboxComp.on_hurt.connect(self._handle_on_hurt)

func _physics_process(delta: float) -> void:
	_life_remaining -= delta
	if _life_remaining <= 0.0:
		queue_free()
		return

	if self.ConstantVelocityComp.Direction != Vector2.ZERO:
		rotation = self.ConstantVelocityComp.Direction.angle()

func _handle_on_hurt(to: Area2D, _damage: int) -> void:
	if to is HitboxComponent and self.Owner != null and self.Owner == to.Owner:
		return

	queue_free()
