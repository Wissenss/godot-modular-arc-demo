class_name HurtboxComponent extends Area2D

var Damage := 0

signal on_hurt(to: Area2D, damage_dealt : int)

func _ready() -> void:
	self.collision_mask = 1 
	self.collision_layer = 2

func _on_area_entered(area: Area2D) -> void:
	on_hurt.emit(area, self.Damage)
