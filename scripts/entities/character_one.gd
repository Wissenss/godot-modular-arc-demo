class_name CharacterOne extends CharacterBody2D

const MOVEMENT_FRAME_DIRECTORY := "res://art/generated/character_one/movement"
const IDLE_FRAME_DIRECTORY := "res://art/generated/character_one/idle"
const UP_LEFT_FRAME_INDICES := [0, 1, 2, 3, 4, 5]
const LEFT_FRAME_INDICES := [6, 7, 8, 9]
const DOWN_LEFT_FRAME_INDICES := [10, 11, 12, 13, 14, 15]
const UP_FRAME_INDICES := [16, 17, 18, 19]
const MOVEMENT_ANIMATION_SPEED := 10.0
const IDLE_FRAME_INDICES := [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
const IDLE_ANIMATION_SPEED := 7.0

var HealthComp : HealthComponent
var HitboxComp : HitboxComponent
var ControllerComp : ControllerComponent
var ConstantVelocityComp : ConstantVelocityComponent

var WeaponOne : WeaponOne

var Sprite : AnimatedSprite2D

func _ready() -> void:
	self.HealthComp = $health_comp
	self.HealthComp.set_health(100)
	self.HealthComp.set_max_health(100)
	self.HealthComp.on_health_changed.connect(self._handle_on_health_changed)
	self.HealthComp.on_died.connect(self._handle_on_died)
	
	self.HitboxComp = $hitbox_comp
	self.HitboxComp.Owner = self
	self.HitboxComp.on_hit.connect(_handle_on_hit)
	
	self.ControllerComp = $controller_comp
	self.ControllerComp.Owner = self
	
	self.ConstantVelocityComp = $constant_velocity_comp
	self.ConstantVelocityComp.Owner = self
	self.ConstantVelocityComp.Speed = 400
	
	self.WeaponOne = $weapon_one
	self.WeaponOne.Owner = self
	
	self.Sprite = $animated_sprite
	self._setup_sprite_frames()
	self._play_idle_animation()

func _physics_process(_delta: float) -> void:
	var move_direction := self._get_move_direction()
	self.ConstantVelocityComp.Direction = move_direction
	self._update_movement_animation(move_direction)

func _handle_on_health_changed(health : int, old_health: int) -> void:
	pass

func _handle_on_died() -> void:
	self.queue_free()

func _setup_sprite_frames() -> void:
	var sprite_frames := SpriteFrames.new()
	
	self._add_animation(sprite_frames, "idle", IDLE_FRAME_DIRECTORY, IDLE_FRAME_INDICES, IDLE_ANIMATION_SPEED)
	self._add_animation(sprite_frames, "move_up_left", MOVEMENT_FRAME_DIRECTORY, UP_LEFT_FRAME_INDICES, MOVEMENT_ANIMATION_SPEED)
	self._add_animation(sprite_frames, "move_left", MOVEMENT_FRAME_DIRECTORY, LEFT_FRAME_INDICES, MOVEMENT_ANIMATION_SPEED)
	self._add_animation(sprite_frames, "move_down_left", MOVEMENT_FRAME_DIRECTORY, DOWN_LEFT_FRAME_INDICES, MOVEMENT_ANIMATION_SPEED)
	self._add_animation(sprite_frames, "move_up", MOVEMENT_FRAME_DIRECTORY, UP_FRAME_INDICES, MOVEMENT_ANIMATION_SPEED)
	
	self.Sprite.sprite_frames = sprite_frames

func _add_animation(sprite_frames: SpriteFrames, animation_name: String, frame_directory: String, frame_indices: Array, animation_speed: float) -> void:
	sprite_frames.add_animation(animation_name)
	sprite_frames.set_animation_loop(animation_name, true)
	sprite_frames.set_animation_speed(animation_name, animation_speed)
	
	for frame_index in frame_indices:
		var frame_path := "%s/frame_%s.png" % [frame_directory, str(frame_index).pad_zeros(2)]
		var frame_texture := self._load_frame_texture(frame_path)
		if frame_texture == null:
			push_warning("Missing movement frame: %s" % frame_path)
			continue
		
		sprite_frames.add_frame(animation_name, frame_texture)

func _load_frame_texture(frame_path: String) -> Texture2D:
	var frame_image := Image.load_from_file(frame_path)
	if frame_image == null or frame_image.is_empty():
		return null
	
	return ImageTexture.create_from_image(frame_image)

func _get_move_direction() -> Vector2:
	if Utils.HasComponent(self, KnockbackEffectComponent.get_class_name()):
		return Vector2.ZERO
	
	if Utils.HasComponent(self, FrozenEffectComp.get_class_name()):
		return Vector2.ZERO
	
	return self.ControllerComp._get_move_direction()

func _update_movement_animation(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		self._play_idle_animation()
		return
	
	var animation_state := self._resolve_animation_state(direction)
	
	self.Sprite.flip_h = animation_state["flip_h"]
	self.Sprite.flip_v = animation_state["flip_v"]
	
	if self.Sprite.animation != animation_state["animation"]:
		self.Sprite.play(animation_state["animation"])
		return
	
	if self.Sprite.is_playing() == false:
		self.Sprite.play()

func _play_idle_animation() -> void:
	self.Sprite.flip_h = false
	self.Sprite.flip_v = false
	
	if self.Sprite.animation != "idle":
		self.Sprite.play("idle")
		return
	
	if self.Sprite.is_playing() == false:
		self.Sprite.play()

func _resolve_animation_state(direction: Vector2) -> Dictionary:
	var horizontal_direction: int = int(sign(direction.x))
	var vertical_direction: int = int(sign(direction.y))
	
	if horizontal_direction < 0 and vertical_direction < 0:
		return {"animation": "move_up_left", "flip_h": false, "flip_v": false}
	if horizontal_direction > 0 and vertical_direction < 0:
		return {"animation": "move_up_left", "flip_h": true, "flip_v": false}
	if horizontal_direction < 0 and vertical_direction > 0:
		return {"animation": "move_down_left", "flip_h": false, "flip_v": false}
	if horizontal_direction > 0 and vertical_direction > 0:
		return {"animation": "move_down_left", "flip_h": true, "flip_v": false}
	if horizontal_direction < 0:
		return {"animation": "move_left", "flip_h": false, "flip_v": false}
	if horizontal_direction > 0:
		return {"animation": "move_left", "flip_h": true, "flip_v": false}
	if vertical_direction < 0:
		return {"animation": "move_up", "flip_h": false, "flip_v": false}
	
	return {"animation": "move_up", "flip_h": false, "flip_v": true}

func _do_blink_effect() -> void:
	for i in range(4):
		self.Sprite.modulate = Color(1.0, 1.0, 1.35, 1.0)
		await get_tree().create_timer(0.1).timeout
		self.Sprite.modulate = Color.WHITE
		await get_tree().create_timer(0.1).timeout

func _handle_on_hit(by: Area2D) -> void:
	if by is HurtboxComponent:
		if by.Owner == self: # ignore your own shots
			return
		
		self.HealthComp.take_damage(by.Damage)
		
		self._do_blink_effect()

func _input(event: InputEvent) -> void:
	if self.ControllerComp._is_shoot_pressed():
		self.WeaponOne._shoot(self.ControllerComp._get_aim_direction())
