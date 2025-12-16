class_name ConstantVelocityComponent extends Node

# resp: apply constant velocity to CharacterBody

var Owner : Node2D
var Direction := Vector2(0, 0)
var Speed := 10

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	var velocity = self.Direction * self.Speed * delta
	
	self.Owner.position += velocity
	
	if self.Owner is CharacterBody2D:
		self.Owner.move_and_slide()
