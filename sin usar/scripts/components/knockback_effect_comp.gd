class_name KnockbackEffectComponent extends Node

# resp: actual knockback effect

var Owner : Node2D
#var Owner : PhysicalBone2D
var Force : float
var Direction : Vector2

var _friction : float = 1

func _physics_process(delta: float) -> void:
	self.Owner.position += self.Direction * self.Force * delta
	
	self.Force -= self._friction
	
	# this component deletes itself, the effect is only temporary;
	if self.Force <= 0:
		self.queue_free()

static func get_class_name() -> StringName:
	return "KnockbackEffectComponent"
