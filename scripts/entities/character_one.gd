class_name CharacterOne extends CharacterBody2D

const ANIMATION_FRAME_DIRECTORIES := {
	"idle": "res://art/generated/character_one_robot/idle",
	"move_up": "res://art/generated/character_one_robot/move_up",
	"move_down": "res://art/generated/character_one_robot/move_down",
	"move_left": "res://art/generated/character_one_robot/move_left",
	"move_right": "res://art/generated/character_one_robot/move_right",
	"move_up_left": "res://art/generated/character_one_robot/move_up_left",
	"move_up_right": "res://art/generated/character_one_robot/move_up_right",
	"move_down_left": "res://art/generated/character_one_robot/move_down_left",
	"move_down_right": "res://art/generated/character_one_robot/move_down_right",
}
const MOVEMENT_SPEED := 260.0
const MOVEMENT_LOOP_DURATION := 0.52
const IDLE_LOOP_DURATION := 0.72

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
	self.ConstantVelocityComp.Speed = MOVEMENT_SPEED

	self.WeaponOne = $weapon_one
	self.WeaponOne.Owner = self

	self.Sprite = $animated_sprite
	self._setup_sprite_frames()
	self._play_idle_animation()


func _physics_process(_delta: float) -> void:
	var move_direction := self._get_move_direction()
	self.ConstantVelocityComp.Direction = move_direction
	self._update_movement_animation(move_direction)


func _handle_on_health_changed(_health : int, _old_health: int) -> void:
	pass


func _handle_on_died() -> void:
	self.queue_free()


func _setup_sprite_frames() -> void:
	var sprite_frames := SpriteFrames.new()
	for animation_name in ANIMATION_FRAME_DIRECTORIES.keys():
		self._add_animation(sprite_frames, animation_name, ANIMATION_FRAME_DIRECTORIES[animation_name])

	self.Sprite.sprite_frames = sprite_frames


func _add_animation(sprite_frames: SpriteFrames, animation_name: String, frame_directory: String) -> void:
	var frame_paths := self._get_frame_paths(frame_directory)
	if frame_paths.is_empty():
		push_warning("Missing animation frames for %s" % animation_name)
		return

	sprite_frames.add_animation(animation_name)
	sprite_frames.set_animation_loop(animation_name, true)
	sprite_frames.set_animation_speed(animation_name, self._animation_speed_for(animation_name, frame_paths.size()))

	for frame_path in frame_paths:
		var frame_texture := self._load_frame_texture(frame_path)
		if frame_texture == null:
			push_warning("Missing movement frame: %s" % frame_path)
			continue

		sprite_frames.add_frame(animation_name, frame_texture)


func _get_frame_paths(frame_directory: String) -> Array[String]:
	var frame_paths: Array[String] = []
	for file_name in DirAccess.get_files_at(frame_directory):
		if file_name.ends_with(".png") == false:
			continue
		frame_paths.append("%s/%s" % [frame_directory, file_name])

	frame_paths.sort()
	return frame_paths


func _animation_speed_for(animation_name: String, frame_count: int) -> float:
	var loop_duration := MOVEMENT_LOOP_DURATION
	var min_speed := 10.0
	var max_speed := 18.0

	if animation_name == "idle":
		loop_duration = IDLE_LOOP_DURATION
		min_speed = 7.5
		max_speed = 12.0

	return clampf(float(frame_count) / loop_duration, min_speed, max_speed)


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
	self.Sprite.flip_h = false
	self.Sprite.flip_v = false

	if direction == Vector2.ZERO:
		self._play_idle_animation()
		return

	var animation_name := self._resolve_animation_name(direction)

	if self.Sprite.animation != animation_name:
		self.Sprite.play(animation_name)
		return

	if self.Sprite.is_playing() == false:
		self.Sprite.play()


func _play_idle_animation() -> void:
	if self.Sprite.animation != "idle":
		self.Sprite.play("idle")
		return

	if self.Sprite.is_playing() == false:
		self.Sprite.play()


func _resolve_animation_name(direction: Vector2) -> String:
	var horizontal_direction: int = int(sign(direction.x))
	var vertical_direction: int = int(sign(direction.y))

	if horizontal_direction < 0 and vertical_direction < 0:
		return "move_up_left"
	if horizontal_direction > 0 and vertical_direction < 0:
		return "move_up_right"
	if horizontal_direction < 0 and vertical_direction > 0:
		return "move_down_left"
	if horizontal_direction > 0 and vertical_direction > 0:
		return "move_down_right"
	if horizontal_direction < 0:
		return "move_left"
	if horizontal_direction > 0:
		return "move_right"
	if vertical_direction < 0:
		return "move_up"

	return "move_down"


func _do_blink_effect() -> void:
	for _i in range(4):
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


func _input(_event: InputEvent) -> void:
	if self.ControllerComp._is_shoot_pressed():
		self.WeaponOne._shoot(self.ControllerComp._get_aim_direction())
