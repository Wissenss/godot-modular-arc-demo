class_name PlayerArenaCamera extends Camera2D

const ArenaLayoutData := preload("res://scripts/world/arena_layout.gd")


func _ready() -> void:
	self.enabled = true
	self.position = Vector2.ZERO
	self.ignore_rotation = true
	self.position_smoothing_enabled = false
	self.limit_left = ArenaLayoutData.WORLD_LEFT
	self.limit_top = ArenaLayoutData.WORLD_TOP
	self.limit_right = ArenaLayoutData.WORLD_RIGHT
	self.limit_bottom = ArenaLayoutData.WORLD_BOTTOM
