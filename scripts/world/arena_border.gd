class_name ArenaBorder extends StaticBody2D

const ArenaLayoutData := preload("res://scripts/world/arena_layout.gd")

const BORDER_THICKNESS := 6.0


func _ready() -> void:
	self._rebuild()


func _rebuild() -> void:
	for child in self.get_children():
		child.queue_free()

	self._add_wall("top_left", Vector2(ArenaLayoutData.CORRIDOR_LEFT * 0.5, -BORDER_THICKNESS * 0.5), Vector2(ArenaLayoutData.CORRIDOR_LEFT, BORDER_THICKNESS))
	self._add_wall("top_right", Vector2(ArenaLayoutData.CORRIDOR_RIGHT + (ArenaLayoutData.ROOM_WIDTH - ArenaLayoutData.CORRIDOR_RIGHT) * 0.5, -BORDER_THICKNESS * 0.5), Vector2(ArenaLayoutData.ROOM_WIDTH - ArenaLayoutData.CORRIDOR_RIGHT, BORDER_THICKNESS))
	self._add_wall("bottom", Vector2(ArenaLayoutData.ROOM_WIDTH * 0.5, ArenaLayoutData.ROOM_HEIGHT + BORDER_THICKNESS * 0.5), Vector2(ArenaLayoutData.ROOM_WIDTH, BORDER_THICKNESS))
	self._add_wall("left", Vector2(-BORDER_THICKNESS * 0.5, ArenaLayoutData.ROOM_HEIGHT * 0.5), Vector2(BORDER_THICKNESS, ArenaLayoutData.ROOM_HEIGHT))
	self._add_wall("right", Vector2(ArenaLayoutData.ROOM_WIDTH + BORDER_THICKNESS * 0.5, ArenaLayoutData.ROOM_HEIGHT * 0.5), Vector2(BORDER_THICKNESS, ArenaLayoutData.ROOM_HEIGHT))
	self._add_wall("corridor_left", Vector2(ArenaLayoutData.CORRIDOR_LEFT - BORDER_THICKNESS * 0.5, ArenaLayoutData.CORRIDOR_TOP + ArenaLayoutData.CORRIDOR_HEIGHT * 0.5), Vector2(BORDER_THICKNESS, ArenaLayoutData.CORRIDOR_HEIGHT))
	self._add_wall("corridor_right", Vector2(ArenaLayoutData.CORRIDOR_RIGHT + BORDER_THICKNESS * 0.5, ArenaLayoutData.CORRIDOR_TOP + ArenaLayoutData.CORRIDOR_HEIGHT * 0.5), Vector2(BORDER_THICKNESS, ArenaLayoutData.CORRIDOR_HEIGHT))
	self._add_wall("corridor_top", Vector2(ArenaLayoutData.CORRIDOR_LEFT + ArenaLayoutData.CORRIDOR_WIDTH * 0.5, ArenaLayoutData.CORRIDOR_TOP - BORDER_THICKNESS * 0.5), Vector2(ArenaLayoutData.CORRIDOR_WIDTH, BORDER_THICKNESS))


func _add_wall(node_name: String, wall_position: Vector2, wall_size: Vector2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = wall_size

	var collision := CollisionShape2D.new()
	collision.name = node_name
	collision.position = wall_position
	collision.shape = shape
	add_child(collision)
