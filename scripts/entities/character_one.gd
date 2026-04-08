class_name CharacterOne extends CharacterBody2D

# ── Animation directories ──────────────────────────────────────────────────────
const ANIMATION_FRAME_DIRECTORIES := {
	# Movement
	"idle":            "res://art/generated/character_one_robot/idle",
	"move_up":         "res://art/generated/character_one_robot/move_up",
	"move_down":       "res://art/generated/character_one_robot/move_down",
	"move_left":       "res://art/generated/character_one_robot/move_left",
	"move_right":      "res://art/generated/character_one_robot/move_right",
	"move_up_left":    "res://art/generated/character_one_robot/move_up_left",
	"move_up_right":   "res://art/generated/character_one_robot/move_up_right",
	"move_down_left":  "res://art/generated/character_one_robot/move_down_left",
	"move_down_right": "res://art/generated/character_one_robot/move_down_right",
	# Hit / damage received
	"hit":             "res://art/generated/character_one_robot/hit",
	# Attack (by aim direction)
	"attack_front":    "res://art/generated/character_one_robot/attack_front",
	"attack_down":     "res://art/generated/character_one_robot/attack_front",
	"attack_side":     "res://art/generated/character_one_robot/attack_side",
	"attack_up":       "res://art/generated/character_one_robot/attack_up",
	# Dash (by movement direction)
	"dash_up":         "res://art/generated/character_one_robot/dash_up",
	"dash_down":       "res://art/generated/character_one_robot/dash_down",
	"dash_left":       "res://art/generated/character_one_robot/dash_left",
	"dash_right":      "res://art/generated/character_one_robot/dash_right",
	"dash_up_left":    "res://art/generated/character_one_robot/dash_up_left",
	"dash_up_right":   "res://art/generated/character_one_robot/dash_up_right",
	"dash_down_left":  "res://art/generated/character_one_robot/dash_down_left",
	"dash_down_right": "res://art/generated/character_one_robot/dash_down_right",
}

# ── Tuning constants ───────────────────────────────────────────────────────────
const MOVEMENT_SPEED        := 260.0
const IDLE_ANIMATION_FPS    := 14.0
const MOVE_FPS_SHORT        := 16.0
const MOVE_FPS_MEDIUM       := 18.0
const MOVE_FPS_LONG         := 20.0
const DASH_SPEED            := 1400.0
const DASH_DURATION         := 0.15
const DASH_COOLDOWN         := 0.8
const ATTACK_ANIM_DURATION  := 0.45   # seconds – how long the attack anim plays
const HIT_ANIM_DURATION     := 0.5    # seconds – how long the hit anim plays

# ── Components ────────────────────────────────────────────────────────────────
var HealthComp          : HealthComponent
var HitboxComp          : HitboxComponent
var ControllerComp      : ControllerComponent
var ConstantVelocityComp: ConstantVelocityComponent
var WeaponOne           : WeaponOne
var Sprite              : AnimatedSprite2D

# ── Dash state ────────────────────────────────────────────────────────────────
var _is_dashing          := false
var _can_dash            := true
var _dash_direction      := Vector2.ZERO
var _dash_timer          : Timer
var _dash_cooldown_timer : Timer

# ── Attack state ──────────────────────────────────────────────────────────────
var _is_attacking        := false
var _attack_timer        : Timer

# ── Hit state ─────────────────────────────────────────────────────────────────
var _is_hit              := false
var _hit_timer           : Timer


# ══════════════════════════════════════════════════════════════════════════════
# Lifecycle
# ══════════════════════════════════════════════════════════════════════════════

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
	self.Sprite.animation_finished.connect(self._on_animation_finished)
	self._play_looping("idle")

	# Dash timers
	self._dash_timer = _make_timer(DASH_DURATION, self._handle_dash_end)
	self._dash_cooldown_timer = _make_timer(DASH_COOLDOWN, self._handle_dash_cooldown_end)

	# Attack / hit safety timers (fire only if animation_finished doesn't beat them)
	self._attack_timer = _make_timer(ATTACK_ANIM_DURATION, self._handle_attack_end)
	self._hit_timer    = _make_timer(HIT_ANIM_DURATION,    self._handle_hit_end)


func _make_timer(wait: float, callback: Callable) -> Timer:
	var t := Timer.new()
	t.one_shot = true
	t.wait_time = wait
	t.timeout.connect(callback)
	add_child(t)
	return t


func _physics_process(_delta: float) -> void:
	var move_dir := self._get_move_direction()

	if self._is_dashing:
		self.ConstantVelocityComp.Direction = self._dash_direction
		self.ConstantVelocityComp.Speed = DASH_SPEED
		# Dash animation takes priority over everything while dashing
		self._play_dash_animation(self._dash_direction)
	else:
		self.ConstantVelocityComp.Direction = move_dir
		self.ConstantVelocityComp.Speed = MOVEMENT_SPEED
		# Movement anim only plays if nothing higher-priority is active
		if not self._is_hit and not self._is_attacking:
			self._update_movement_animation(move_dir)


func _get_move_direction() -> Vector2:
	if Utils.HasComponent(self, KnockbackEffectComponent.get_class_name()):
		return Vector2.ZERO

	if Utils.HasComponent(self, FrozenEffectComp.get_class_name()):
		return Vector2.ZERO

	return self.ControllerComp._get_move_direction()


# ══════════════════════════════════════════════════════════════════════════════
# Input
# ══════════════════════════════════════════════════════════════════════════════

func _input(event: InputEvent) -> void:
	if self.ControllerComp._is_shoot_event(event):
		var aim := self.ControllerComp._get_aim_direction()
		self.WeaponOne._shoot(aim)
		# Attack anim only if not currently taking a hit
		if not self._is_hit:
			self._start_attack(aim)

	if event.is_action_pressed("dash") and self._can_dash and not self._is_dashing:
		self._start_dash()


# ══════════════════════════════════════════════════════════════════════════════
# Health / death
# ══════════════════════════════════════════════════════════════════════════════

func _handle_on_health_changed(_health: int, _old_health: int) -> void:
	pass


func _handle_on_died() -> void:
	self.queue_free()


func _handle_on_hit(by: Area2D) -> void:
	if by is HurtboxComponent:
		if by.Owner == self:   # ignore own projectiles
			return
		self.HealthComp.take_damage(by.Damage)
		self._start_hit()


# ══════════════════════════════════════════════════════════════════════════════
# Dash
# ══════════════════════════════════════════════════════════════════════════════

func _start_dash() -> void:
	var direction := self.ControllerComp._get_move_direction()
	if direction == Vector2.ZERO:
		return

	self._is_dashing          = true
	self._can_dash            = false
	self._dash_direction      = direction
	self._dash_timer.start(DASH_DURATION)
	self._do_dash_effect()


func _handle_dash_end() -> void:
	self._is_dashing = false
	self._dash_cooldown_timer.start(DASH_COOLDOWN)


func _handle_dash_cooldown_end() -> void:
	self._can_dash = true


func _do_dash_effect() -> void:
	self.Sprite.modulate = Color(0.4, 0.8, 1.0, 0.75)
	await get_tree().create_timer(DASH_DURATION).timeout
	self.Sprite.modulate = Color.WHITE


# ══════════════════════════════════════════════════════════════════════════════
# Attack
# ══════════════════════════════════════════════════════════════════════════════

func _start_attack(aim: Vector2) -> void:
	self._is_attacking = true
	var anim := self._resolve_attack_animation(aim)
	self._play_once(anim)
	# Safety timer: resets state even if animation_finished is missed
	self._attack_timer.start(ATTACK_ANIM_DURATION)


func _handle_attack_end() -> void:
	self._is_attacking    = false
	self.Sprite.flip_h    = false
	self._attack_timer.stop()


# ══════════════════════════════════════════════════════════════════════════════
# Hit / damage received
# ══════════════════════════════════════════════════════════════════════════════

func _start_hit() -> void:
	self._is_hit = true
	# Hit overrides whatever was playing
	self._play_once("hit")
	self._hit_timer.start(HIT_ANIM_DURATION)
	self._do_hit_flash()


func _handle_hit_end() -> void:
	self._is_hit       = false
	self.Sprite.modulate = Color.WHITE
	self._hit_timer.stop()


func _do_hit_flash() -> void:
	for _i in range(3):
		self.Sprite.modulate = Color(1.8, 0.3, 0.3, 1.0)
		await get_tree().create_timer(0.06).timeout
		self.Sprite.modulate = Color.WHITE
		await get_tree().create_timer(0.06).timeout


# ══════════════════════════════════════════════════════════════════════════════
# Animation helpers
# ══════════════════════════════════════════════════════════════════════════════

func _on_animation_finished() -> void:
	var anim := self.Sprite.animation
	if anim == "hit":
		self._handle_hit_end()
	elif anim.begins_with("attack"):
		self._handle_attack_end()
	# dash / movement animations are looping – they won't fire this signal


func _update_movement_animation(direction: Vector2) -> void:
	self.Sprite.flip_h = false
	if direction == Vector2.ZERO:
		self._play_looping("idle")
		return
	self._play_looping(self._resolve_movement_animation(direction))


func _play_looping(anim: String) -> void:
	if self.Sprite.animation != anim:
		self.Sprite.play(anim)
	elif not self.Sprite.is_playing():
		self.Sprite.play()


func _play_once(anim: String) -> void:
	self.Sprite.play(anim)


func _play_idle_animation() -> void:
	self._play_looping("idle")


# ── Direction resolvers ───────────────────────────────────────────────────────

func _resolve_movement_animation(dir: Vector2) -> String:
	var h := int(sign(dir.x))
	var v := int(sign(dir.y))
	if h < 0 and v < 0: return "move_up_left"
	if h > 0 and v < 0: return "move_up_right"
	if h < 0 and v > 0: return "move_down_left"
	if h > 0 and v > 0: return "move_down_right"
	if h < 0: return "move_left"
	if h > 0: return "move_right"
	if v < 0: return "move_up"
	return "move_down"


func _resolve_dash_animation(dir: Vector2) -> String:
	var h := int(sign(dir.x))
	var v := int(sign(dir.y))
	if h < 0 and v < 0: return "dash_up_left"
	if h > 0 and v < 0: return "dash_up_right"
	if h < 0 and v > 0: return "dash_down_left"
	if h > 0 and v > 0: return "dash_down_right"
	if h < 0: return "dash_left"
	if h > 0: return "dash_right"
	if v < 0: return "dash_up"
	return "dash_down"


func _resolve_attack_animation(aim: Vector2) -> String:
	self.Sprite.flip_h = false
	# Horizontal vs vertical aim
	if abs(aim.y) >= abs(aim.x):
		if aim.y >= 0:
			return "attack_front"   # Aiming down / toward camera
		else:
			return "attack_up"      # Aiming up / away from camera
	else:
		if aim.x < 0:
			self.Sprite.flip_h = true   # Mirror side-attack sprite for left aim
		return "attack_side"


func _play_dash_animation(dir: Vector2) -> void:
	self.Sprite.flip_h = false
	var anim := self._resolve_dash_animation(dir)
	# Dash animations loop so we hold the pose throughout the dash
	self._play_looping(anim)


# ══════════════════════════════════════════════════════════════════════════════
# Sprite frame setup
# ══════════════════════════════════════════════════════════════════════════════

func _setup_sprite_frames() -> void:
	var sprite_frames := SpriteFrames.new()
	for anim_name in ANIMATION_FRAME_DIRECTORIES.keys():
		self._add_animation(sprite_frames, anim_name, ANIMATION_FRAME_DIRECTORIES[anim_name])
	self.Sprite.sprite_frames = sprite_frames


func _add_animation(sprite_frames: SpriteFrames, anim_name: String, frame_dir: String) -> void:
	var frame_paths := self._get_frame_paths(frame_dir)
	if frame_paths.is_empty():
		push_warning("Missing animation frames for: %s" % anim_name)
		return

	sprite_frames.add_animation(anim_name)

	# Looping policy:
	#   loop  → idle, move_*, dash_*   (hold pose / cycle continuously)
	#   once  → hit, attack_*          (play once then stop → fires animation_finished)
	var should_loop := not (anim_name == "hit" or anim_name.begins_with("attack"))
	sprite_frames.set_animation_loop(anim_name, should_loop)
	sprite_frames.set_animation_speed(anim_name, self._fps_for(anim_name, frame_paths.size()))

	for frame_path in frame_paths:
		var tex := self._load_frame_texture(frame_path)
		if tex == null:
			push_warning("Missing frame file: %s" % frame_path)
			continue
		sprite_frames.add_frame(anim_name, tex)


func _get_frame_paths(frame_dir: String) -> Array[String]:
	var paths: Array[String] = []
	for file_name in DirAccess.get_files_at(frame_dir):
		if file_name.ends_with(".png"):
			paths.append("%s/%s" % [frame_dir, file_name])
	paths.sort()
	return paths


func _fps_for(anim_name: String, frame_count: int) -> float:
	if anim_name == "idle":
		return IDLE_ANIMATION_FPS
	if anim_name.begins_with("attack"):
		return clampf(float(frame_count) / ATTACK_ANIM_DURATION, 8.0, 22.0)
	if anim_name == "hit":
		return clampf(float(frame_count) / HIT_ANIM_DURATION, 8.0, 16.0)
	if anim_name.begins_with("dash"):
		return 2.0   # Single-frame pose – very low FPS keeps it stable

	if frame_count >= 8:
		return MOVE_FPS_LONG
	if frame_count >= 6:
		return MOVE_FPS_MEDIUM
	return MOVE_FPS_SHORT


func _load_frame_texture(frame_path: String) -> Texture2D:
	var img := Image.load_from_file(frame_path)
	if img == null or img.is_empty():
		return null
	return ImageTexture.create_from_image(img)
