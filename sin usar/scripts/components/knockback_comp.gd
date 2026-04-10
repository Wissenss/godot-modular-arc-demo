class_name KnockbackComponent extends Node

# resp: apply knockback effect

var Owner : Node2D
var Force : float = 10

func _apply_knockback_to_character(target : CharacterBody2D):
	var effect := KnockbackEffectComponent.new()
	
	effect.Owner = target
	effect.Force = self.Force
	effect.Direction = self.Owner.position.direction_to(target.position)
	
	target.add_child(effect)
