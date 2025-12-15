class_name ControllerComponent extends Node

var Owner : Node2D

# resp: map input to common actions, this could inherit from base class
# to give multi divice support, keyboard, controller etc...

func _get_move_direction() -> Vector2:
	var direction := Vector2(0, 0)
	
	if Input.is_action_pressed("ui_up"):
		direction.y -= 1
	if Input.is_action_pressed("ui_down"):
		direction.y += 1
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
	if Input.is_action_pressed("ui_right"):
		direction.x += 1
	
	return direction.normalized()

func _get_aim_direction() -> Vector2:
	var mouse_pos = get_viewport().get_mouse_position()
	var player_pos = self.Owner.position
	
	var direction = player_pos - mouse_pos
	
	return direction.normalized()
