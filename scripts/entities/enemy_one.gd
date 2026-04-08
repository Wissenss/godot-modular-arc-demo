class_name EnemyOne extends CharacterBody2D

const IDLE_FRAME_DIRECTORY := "res://art/generated/character_one/idle"
const IDLE_FRAME_INDICES := [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
const IDLE_ANIMATION_SPEED := 7.0

var Sprite : AnimatedSprite2D
var HurtboxComp : HurtboxComponent
var HitboxComp : HitboxComponent
var KnockbackComp : KnockbackComponent

func _ready() -> void:
	self.Sprite = $animated_sprite
	self._setup_sprite_frames()
	self._play_idle_animation()
	
	self.HurtboxComp = $hurtbox_comp
	self.HurtboxComp.Damage = 30
	self.HurtboxComp.on_hurt.connect(self._handle_on_hurt)
	
	self.KnockbackComp = $knockback_comp
	self.KnockbackComp.Force = 100
	self.KnockbackComp.Owner = self
	
	self.HitboxComp = $hitbox_comp
	self.HitboxComp.on_hit.connect(self._handle_on_hit)

func _setup_sprite_frames() -> void:
	var sprite_frames := SpriteFrames.new()
	sprite_frames.add_animation("idle")
	sprite_frames.set_animation_loop("idle", true)
	sprite_frames.set_animation_speed("idle", IDLE_ANIMATION_SPEED)
	
	for frame_index in IDLE_FRAME_INDICES:
		var frame_path := "%s/frame_%s.png" % [IDLE_FRAME_DIRECTORY, str(frame_index).pad_zeros(2)]
		var frame_texture := self._load_frame_texture(frame_path)
		if frame_texture == null:
			push_warning("Missing enemy idle frame: %s" % frame_path)
			continue
		
		sprite_frames.add_frame("idle", frame_texture)
	
	self.Sprite.sprite_frames = sprite_frames

func _load_frame_texture(frame_path: String) -> Texture2D:
	var frame_image := Image.load_from_file(frame_path)
	if frame_image == null or frame_image.is_empty():
		return null
	
	return ImageTexture.create_from_image(frame_image)

func _play_idle_animation() -> void:
	if self.Sprite.animation != "idle":
		self.Sprite.play("idle")
		return
	
	if self.Sprite.is_playing() == false:
		self.Sprite.play()

func _do_blink_effect() -> void:
	for i in range(4):
		self.Sprite.modulate = Color(1.35, 1.0, 1.0, 1.0)
		await get_tree().create_timer(0.1).timeout
		self.Sprite.modulate = Color.WHITE
		await get_tree().create_timer(0.1).timeout

func _handle_on_hurt(to : Area2D, damage : int) -> void:
	# apply knockback effect
	if to is HitboxComponent:
		if to == self.HitboxComp: # do not, knockback yourself
			return
		
		self.KnockbackComp._apply_knockback_to_character(to.Owner)

func _handle_on_hit(by : Area2D):
	self._do_blink_effect()
