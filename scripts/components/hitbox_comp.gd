class_name HitboxComponent extends Area2D

# resp: detect hit collisions, avoid friendly fire?

var Owner : Node2D

signal on_hit(by: Area2D)

func _ready() -> void:
	self.collision_mask = 2 
	self.collision_layer = 1

func _on_area_entered(area: Area2D) -> void:
	on_hit.emit(area)
