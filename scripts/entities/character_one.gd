class_name CharacterOne extends CharacterBody2D

const WeaponEnemyScript := preload("res://scripts/weapons/weapon_enemy.gd")

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
const IDLE_ANIMATION_FPS    := 8.25
const MOVE_LOOP_DURATION    := 0.94
const DASH_SPEED            := 1400.0
const DASH_DURATION         := 0.15
const DASH_COOLDOWN         := 0.8
const ATTACK_ANIM_DURATION  := 0.45
const HIT_ANIM_DURATION     := 0.5

# ── Weapon-swap buff ─────────────────────────────────────────────────────────
const LOOT_RANGE            := 60.0    # distance to interact with dead enemy
const SWAP_BUFF_DURATION    := 6.0     # seconds the buff lasts
const SWAP_SPEED_MULT       := 1.25    # 25 % extra speed during buff
const SWAP_HEAL_PERCENT     := 0.05    # 5 % of max HP healed on swap

# ── Components ────────────────────────────────────────────────────────────────
var HealthComp          : HealthComponent
var HitboxComp          : HitboxComponent
var ControllerComp      : ControllerComponent
var ConstantVelocityComp: ConstantVelocityComponent
var Sprite              : AnimatedSprite2D

# ── Weapon (swappable) ───────────────────────────────────────────────────────
## Active weapon node.  Starts as WeaponOne; gets replaced on loot.
var _active_weapon      : Node2D
## ID of the currently equipped weapon ("weapon_one" or "weapon_enemy", etc.)
var _weapon_id          : String = "weapon_one"

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

# ── Swap-buff state ──────────────────────────────────────────────────────────
var _swap_buff_active    := false
var _swap_buff_timer     : Timer


# ══════════════════════════════════════════════════════════════════════════════
# Lifecycle
# ══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	add_to_group("player")   # so enemies can find us

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

	# Weapon setup (initial = weapon_one from the scene)
	self._active_weapon = $weapon_one
	self._active_weapon.Owner = self
	self._weapon_id = "weapon_one"

	self.Sprite = $animated_sprite
	self._setup_sprite_frames()
	self.Sprite.animation_finished.connect(self._on_animation_finished)
	self._play_looping("idle")

	# Timers
	self._dash_timer         = _make_timer(DASH_DURATION,       self._handle_dash_end)
	self._dash_cooldown_timer = _make_timer(DASH_COOLDOWN,      self._handle_dash_cooldown_end)
	self._attack_timer       = _make_timer(ATTACK_ANIM_DURATION, self._handle_attack_end)
	self._hit_timer          = _make_timer(HIT_ANIM_DURATION,    self._handle_hit_end)
	self._swap_buff_timer    = _make_timer(SWAP_BUFF_DURATION,   self._handle_swap_buff_end)


func _make_timer(wait: float, callback: Callable) -> Timer:
	var t := Timer.new()
	t.one_shot = true
	t.wait_time = wait
	t.timeout.connect(callback)
	add_child(t)
	return t


func _physics_process(_delta: float) -> void:
	var move_dir := self._get_move_direction()
	var current_speed := MOVEMENT_SPEED
	if _swap_buff_active:
		current_speed = MOVEMENT_SPEED * SWAP_SPEED_MULT

	if self._is_dashing:
		self.ConstantVelocityComp.Direction = self._dash_direction
		self.ConstantVelocityComp.Speed = DASH_SPEED
		self._play_dash_animation(self._dash_direction)
	else:
		self.ConstantVelocityComp.Direction = move_dir
		self.ConstantVelocityComp.Speed = current_speed
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
	# ── Shoot ──
	if self.ControllerComp._is_shoot_event(event):
		var aim := self.ControllerComp._get_aim_direction()
		self._active_weapon._shoot(aim)
		if not self._is_hit:
			self._start_attack(aim)

	# ── Dash ──
	if event.is_action_pressed("dash") and self._can_dash and not self._is_dashing:
		self._start_dash()

	# ── Loot / weapon steal (E key) ──
	if event.is_action_pressed("interact"):
		self._try_loot_nearby()


# ══════════════════════════════════════════════════════════════════════════════
# Weapon stealing
# ══════════════════════════════════════════════════════════════════════════════

func _try_loot_nearby() -> void:
	var closest_enemy : Node = null
	var closest_dist  := LOOT_RANGE + 1.0

	for enemy in get_tree().get_nodes_in_group("lootable_enemy"):
		if not is_instance_valid(enemy):
			continue
		var dist := global_position.distance_to(enemy.global_position)
		if dist < closest_dist:
			closest_dist  = dist
			closest_enemy = enemy

	if closest_enemy == null:
		return

	# Ask the enemy what weapon it drops
	var looted_weapon_id : String = closest_enemy.loot()   # also removes the corpse

	# Skip if same weapon already equipped
	if looted_weapon_id == _weapon_id:
		_apply_swap_buff()
		return

	_swap_weapon(looted_weapon_id)
	_apply_swap_buff()


func _swap_weapon(new_weapon_id: String) -> void:
	# Remove old weapon
	if _active_weapon != null:
		_active_weapon.queue_free()

	# Create new weapon
	match new_weapon_id:
		"weapon_enemy":
			var w := WeaponEnemyScript.new()
			w.name = "active_weapon"
			w.Owner = self
			add_child(w)
			_active_weapon = w
		_:
			# Default: restore weapon_one
			var scene := preload("res://scenes/weapons/weapon_one.tscn")
			var w := scene.instantiate()
			w.name = "active_weapon"
			add_child(w)
			w.Owner = self
			_active_weapon = w

	_weapon_id = new_weapon_id


func _apply_swap_buff() -> void:
	# Heal 5 % max HP
	var heal_amount := int(self.HealthComp.get_max_health() * SWAP_HEAL_PERCENT)
	self.HealthComp.set_health(self.HealthComp.get_health() + heal_amount)

	# Activate speed buff
	_swap_buff_active = true
	_swap_buff_timer.start(SWAP_BUFF_DURATION)

	# Visual feedback: green glow while buff is active
	_do_swap_glow()


func _handle_swap_buff_end() -> void:
	_swap_buff_active = false
	self.Sprite.modulate = Color.WHITE


func _do_swap_glow() -> void:
	if not _swap_buff_active:
		return
	# Subtle green pulse for the buff duration
	var tween := create_tween().set_loops(int(SWAP_BUFF_DURATION / 0.8))
	tween.tween_property(self.Sprite, "modulate", Color(0.7, 1.4, 0.7, 1.0), 0.4)
	tween.tween_property(self.Sprite, "modulate", Color.WHITE, 0.4)


# ══════════════════════════════════════════════════════════════════════════════
# Health / death
# ══════════════════════════════════════════════════════════════════════════════

func _handle_on_health_changed(_health: int, _old_health: int) -> void:
	pass


func _handle_on_died() -> void:
	self.queue_free()


func _handle_on_hit(by: Area2D) -> void:
	if by is HurtboxComponent:
		if by.Owner == self:
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
	self._is_dashing     = true
	self._can_dash       = false
	self._dash_direction = direction
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
	self._attack_timer.start(ATTACK_ANIM_DURATION)


func _handle_attack_end() -> void:
	self._is_attacking = false
	self.Sprite.flip_h  = false
	self._attack_timer.stop()


# ══════════════════════════════════════════════════════════════════════════════
# Hit / damage received
# ══════════════════════════════════════════════════════════════════════════════

func _start_hit() -> void:
	self._is_hit = true
	self._play_once("hit")
	self._hit_timer.start(HIT_ANIM_DURATION)
	self._do_hit_flash()


func _handle_hit_end() -> void:
	self._is_hit         = false
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
	if abs(aim.y) >= abs(aim.x):
		if aim.y >= 0:
			return "attack_front"
		else:
			return "attack_up"
	else:
		if aim.x < 0:
			self.Sprite.flip_h = true
		return "attack_side"


func _play_dash_animation(dir: Vector2) -> void:
	self.Sprite.flip_h = false
	var anim := self._resolve_dash_animation(dir)
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
		return 2.0
	return clampf(float(frame_count) / MOVE_LOOP_DURATION, 8.0, 10.25)


func _load_frame_texture(frame_path: String) -> Texture2D:
	var img := Image.load_from_file(frame_path)
	if img == null or img.is_empty():
		return null
	return ImageTexture.create_from_image(img)
