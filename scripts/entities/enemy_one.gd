class_name EnemyOne extends CharacterBody2D
## ─────────────────────────────────────────────────────────────────────────────
## Enemy with full AI: chase, charged ranged attack, projectile dodging,
## and a lootable corpse the player can steal a weapon from.
## Solo = manageable.  Three at once = challenging.
## ─────────────────────────────────────────────────────────────────────────────

# ── Animation ────────────────────────────────────────────────────────────────
const IDLE_FRAME_DIRECTORY := "res://art/generated/character_one/idle"
const IDLE_FRAME_INDICES   := [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
const IDLE_ANIMATION_SPEED := 7.0

# ── Tuning ───────────────────────────────────────────────────────────────────
const HEALTH             := 80
const CHASE_SPEED        := 100.0    # slower than player (260)
const DETECTION_RANGE    := 350.0
const ATTACK_RANGE       := 220.0
const CHARGE_TIME        := 1.6      # seconds of visible telegraph
const ATTACK_COOLDOWN    := 3.2      # seconds between attacks
const DODGE_SPEED        := 650.0
const DODGE_DURATION     := 0.18
const DODGE_COOLDOWN     := 1.4
const DODGE_DETECT_RANGE := 130.0    # how far to scan for incoming projectiles
const CONTACT_DAMAGE     := 15
const CORPSE_LINGER_TIME := 15.0     # seconds body stays lootable

# ── State machine ────────────────────────────────────────────────────────────
enum State { IDLE, CHASE, CHARGE, ATTACK, DODGE, DEAD }
var _state : State = State.IDLE

# ── Node references ──────────────────────────────────────────────────────────
var Sprite       : AnimatedSprite2D
var HurtboxComp  : HurtboxComponent
var HitboxComp   : HitboxComponent
var KnockbackComp: KnockbackComponent
var HealthComp   : HealthComponent

# ── Components created at runtime (to avoid touching Codex's scene edits) ──
var _velocity_comp : ConstantVelocityComponent
var _weapon        : Node2D

# ── Internal state ───────────────────────────────────────────────────────────
var _player        : CharacterBody2D = null
var _dodge_dir     := Vector2.ZERO
var _charge_elapsed := 0.0

# Timers
var _attack_cd_timer     : Timer
var _dodge_timer         : Timer
var _dodge_cd_timer      : Timer
var _corpse_timer        : Timer

var _can_attack          := true
var _is_dodging          := false
var _can_dodge           := true

## The weapon type string this enemy drops on death.
var weapon_id : String = "weapon_enemy"


# ══════════════════════════════════════════════════════════════════════════════
# Lifecycle
# ══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	# ── Sprite ──
	self.Sprite = $animated_sprite
	self._setup_sprite_frames()
	self._play_idle_animation()

	# ── Existing scene components ──
	self.HurtboxComp = $hurtbox_comp
	self.HurtboxComp.Damage = CONTACT_DAMAGE
	self.HurtboxComp.on_hurt.connect(self._handle_on_hurt)

	self.KnockbackComp = $knockback_comp
	self.KnockbackComp.Force = 100
	self.KnockbackComp.Owner = self

	self.HitboxComp = $hitbox_comp
	self.HitboxComp.on_hit.connect(self._handle_on_hit)

	# ── Create HealthComponent at runtime ──
	self.HealthComp = HealthComponent.new()
	self.HealthComp.name = "health_comp"
	add_child(self.HealthComp)
	self.HealthComp.set_max_health(HEALTH)
	self.HealthComp.set_health(HEALTH)
	self.HealthComp.on_died.connect(self._handle_on_died)
	self.HealthComp.on_health_changed.connect(self._handle_health_changed)

	# ── Create ConstantVelocityComponent at runtime ──
	self._velocity_comp = ConstantVelocityComponent.new()
	self._velocity_comp.name = "constant_velocity_comp"
	self._velocity_comp.Owner = self
	self._velocity_comp.Speed = CHASE_SPEED
	add_child(self._velocity_comp)

	# ── Create WeaponEnemy at runtime ──
	self._weapon = WeaponEnemyScript.new()
	self._weapon.name = "weapon_enemy"
	self._weapon.Owner = self
	add_child(self._weapon)

	# ── Timers ──
	self._attack_cd_timer = _make_timer(ATTACK_COOLDOWN, func(): self._can_attack = true)
	self._dodge_timer     = _make_timer(DODGE_DURATION,   self._end_dodge)
	self._dodge_cd_timer  = _make_timer(DODGE_COOLDOWN,   func(): self._can_dodge = true)
	self._corpse_timer    = _make_timer(CORPSE_LINGER_TIME, self._remove_corpse)

	# ── Find player ──
	# Deferred so all nodes are ready
	call_deferred("_find_player")


func _make_timer(wait: float, cb: Callable) -> Timer:
	var t := Timer.new()
	t.one_shot = true
	t.wait_time = wait
	t.timeout.connect(cb)
	add_child(t)
	return t


func _find_player() -> void:
	# Look for the first CharacterOne in the scene tree
	for node in get_tree().get_nodes_in_group("player"):
		self._player = node
		return
	# Fallback: search by class
	_find_player_by_class(get_tree().root)


func _find_player_by_class(node: Node) -> void:
	if node is CharacterOne:
		self._player = node
		return
	for child in node.get_children():
		if self._player != null:
			return
		_find_player_by_class(child)


# ══════════════════════════════════════════════════════════════════════════════
# Physics / AI tick
# ══════════════════════════════════════════════════════════════════════════════

func _physics_process(delta: float) -> void:
	if _state == State.DEAD:
		self._velocity_comp.Direction = Vector2.ZERO
		return

	if _player == null:
		return

	var dist_to_player := global_position.distance_to(_player.global_position)
	var dir_to_player  := ((_player.global_position - global_position)).normalized()

	match _state:
		State.IDLE:
			self._velocity_comp.Direction = Vector2.ZERO
			if dist_to_player < DETECTION_RANGE:
				_change_state(State.CHASE)

		State.CHASE:
			self._velocity_comp.Speed = CHASE_SPEED
			self._velocity_comp.Direction = dir_to_player

			# Dodge incoming projectiles
			if _can_dodge and _detect_incoming_projectile():
				_start_dodge(dir_to_player)
				return

			if dist_to_player > DETECTION_RANGE * 1.3:
				_change_state(State.IDLE)
			elif dist_to_player < ATTACK_RANGE and _can_attack:
				_change_state(State.CHARGE)

		State.CHARGE:
			# Slow down while charging
			self._velocity_comp.Direction = dir_to_player * 0.15
			_charge_elapsed += delta

			# Dodge interrupt: if projectile comes while charging, dodge
			if _can_dodge and _detect_incoming_projectile():
				_charge_elapsed = 0.0
				_start_dodge(dir_to_player)
				return

			# Visual telegraph: pulse red glow
			var pulse := 0.5 + 0.5 * sin(_charge_elapsed * 10.0)
			self.Sprite.modulate = Color(1.0 + pulse * 0.6, 1.0 - pulse * 0.5, 1.0 - pulse * 0.5)

			if _charge_elapsed >= CHARGE_TIME:
				_change_state(State.ATTACK)

		State.ATTACK:
			_fire_charged_attack(dir_to_player)
			_change_state(State.CHASE)

		State.DODGE:
			self._velocity_comp.Speed = DODGE_SPEED
			self._velocity_comp.Direction = _dodge_dir


# ══════════════════════════════════════════════════════════════════════════════
# State transitions
# ══════════════════════════════════════════════════════════════════════════════

func _change_state(new_state: State) -> void:
	# Exit current state
	match _state:
		State.CHARGE:
			_charge_elapsed = 0.0
			self.Sprite.modulate = Color.WHITE

	_state = new_state

	# Enter new state
	match new_state:
		State.IDLE:
			self._velocity_comp.Direction = Vector2.ZERO
		State.ATTACK:
			pass   # handled immediately in _physics_process
		State.DEAD:
			_enter_dead_state()


# ══════════════════════════════════════════════════════════════════════════════
# Combat: attack
# ══════════════════════════════════════════════════════════════════════════════

func _fire_charged_attack(direction: Vector2) -> void:
	self._weapon._shoot(direction)
	self._can_attack = false
	self._attack_cd_timer.start(ATTACK_COOLDOWN)
	self.Sprite.modulate = Color.WHITE


# ══════════════════════════════════════════════════════════════════════════════
# Combat: dodge
# ══════════════════════════════════════════════════════════════════════════════

func _detect_incoming_projectile() -> bool:
	## Scan the tree for projectiles heading toward this enemy.
	for node in get_tree().get_nodes_in_group("projectile"):
		if _is_projectile_threatening(node):
			return true
	# Fallback scan for ProjectileOne instances
	return _scan_projectiles(get_tree().root)


func _scan_projectiles(node: Node) -> bool:
	if node is ProjectileOne and _is_projectile_threatening(node):
		return true
	for child in node.get_children():
		if _scan_projectiles(child):
			return true
	return false


func _is_projectile_threatening(proj: Node) -> bool:
	if not is_instance_valid(proj) or not proj is Node2D:
		return false
	var p := proj as Node2D
	var dist := global_position.distance_to(p.global_position)
	if dist > DODGE_DETECT_RANGE:
		return false
	# Check if it has a velocity component heading toward us
	var vel_comp = p.get_node_or_null("constant_velocity_comp")
	if vel_comp == null:
		return false
	var proj_dir : Vector2 = vel_comp.Direction
	var to_enemy := (global_position - p.global_position).normalized()
	# Dot product > 0.5 means projectile points roughly at us
	return proj_dir.dot(to_enemy) > 0.5


func _start_dodge(dir_to_player: Vector2) -> void:
	_is_dodging = true
	_can_dodge  = false

	# Dodge perpendicular to the direction the player is in
	var perp := Vector2(-dir_to_player.y, dir_to_player.x)
	# Pick a random side
	if randf() > 0.5:
		perp = -perp
	_dodge_dir = perp

	# If charging, cancel the charge
	if _state == State.CHARGE:
		_charge_elapsed = 0.0
		self.Sprite.modulate = Color.WHITE

	_state = State.DODGE
	self._velocity_comp.Speed = DODGE_SPEED
	self._velocity_comp.Direction = _dodge_dir
	self._dodge_timer.start(DODGE_DURATION)

	# Visual flash
	self.Sprite.modulate = Color(0.5, 0.9, 1.0, 0.8)


func _end_dodge() -> void:
	_is_dodging = false
	self.Sprite.modulate = Color.WHITE
	self._velocity_comp.Speed = CHASE_SPEED
	self._dodge_cd_timer.start(DODGE_COOLDOWN)
	_change_state(State.CHASE)


# ══════════════════════════════════════════════════════════════════════════════
# Damage / death
# ══════════════════════════════════════════════════════════════════════════════

func _handle_health_changed(health: int, old_health: int) -> void:
	if health < old_health:
		self._do_blink_effect()


func _handle_on_died() -> void:
	_change_state(State.DEAD)


func _enter_dead_state() -> void:
	# Stop all movement
	self._velocity_comp.Direction = Vector2.ZERO
	self._velocity_comp.Speed = 0

	# Disable combat
	self.HurtboxComp.set_deferred("monitoring", false)
	self.HurtboxComp.set_deferred("monitorable", false)
	self.HitboxComp.set_deferred("monitoring", false)
	self.HitboxComp.set_deferred("monitorable", false)

	# Disable physics body collision
	var collision_node = get_node_or_null("collision")
	if collision_node:
		collision_node.set_deferred("disabled", true)

	# Visual: darken + shrink slightly
	self.Sprite.modulate = Color(0.35, 0.35, 0.45, 0.8)
	var tween := create_tween()
	tween.tween_property(self.Sprite, "scale", self.Sprite.scale * 0.85, 0.4)

	# Add to "lootable" group for player pickup detection
	add_to_group("lootable_enemy")

	# Start corpse linger timer
	self._corpse_timer.start(CORPSE_LINGER_TIME)


func _remove_corpse() -> void:
	# Fade out then free
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.8)
	tween.tween_callback(self.queue_free)


## Called by the player when they loot this corpse.
func loot() -> String:
	remove_from_group("lootable_enemy")
	# Quick dissolve
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.3)
	tween.tween_callback(self.queue_free)
	return weapon_id


func is_dead() -> bool:
	return _state == State.DEAD


# ══════════════════════════════════════════════════════════════════════════════
# Existing combat handlers (preserved from original)
# ══════════════════════════════════════════════════════════════════════════════

func _handle_on_hurt(to: Area2D, _damage: int) -> void:
	if _state == State.DEAD:
		return
	if to is HitboxComponent:
		if to == self.HitboxComp:
			return
		self.KnockbackComp._apply_knockback_to_character(to.Owner)


func _handle_on_hit(by: Area2D) -> void:
	if _state == State.DEAD:
		return
	# Apply damage from incoming projectiles
	if by is HurtboxComponent:
		if by.Owner == self:
			return
		self.HealthComp.take_damage(by.Damage)


# ══════════════════════════════════════════════════════════════════════════════
# Animation (preserved + extended)
# ══════════════════════════════════════════════════════════════════════════════

func _setup_sprite_frames() -> void:
	var sprite_frames := SpriteFrames.new()
	sprite_frames.add_animation("idle")
	sprite_frames.set_animation_loop("idle", true)
	sprite_frames.set_animation_speed("idle", IDLE_ANIMATION_SPEED)

	for frame_index in IDLE_FRAME_INDICES:
		var frame_path := "%s/frame_%s.png" % [IDLE_FRAME_DIRECTORY, str(frame_index).pad_zeros(2)]
		var tex := _load_frame_texture(frame_path)
		if tex == null:
			push_warning("Missing enemy idle frame: %s" % frame_path)
			continue
		sprite_frames.add_frame("idle", tex)

	self.Sprite.sprite_frames = sprite_frames


func _load_frame_texture(frame_path: String) -> Texture2D:
	var frame_image := Image.load_from_file(frame_path)
	if frame_image == null or frame_image.is_empty():
		return null
	return ImageTexture.create_from_image(frame_image)


func _play_idle_animation() -> void:
	if self.Sprite.animation != "idle":
		self.Sprite.play("idle")
	elif not self.Sprite.is_playing():
		self.Sprite.play()


func _do_blink_effect() -> void:
	for _i in range(3):
		self.Sprite.modulate = Color(1.5, 0.4, 0.4, 1.0)
		await get_tree().create_timer(0.07).timeout
		self.Sprite.modulate = Color.WHITE
		await get_tree().create_timer(0.07).timeout
const WeaponEnemyScript := preload("res://scripts/weapons/weapon_enemy.gd")
