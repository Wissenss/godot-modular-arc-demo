extends Node2D

const SHOOT_COOLDOWN := 0.08
const DEFAULT_ATTACK_ID := "rogue_shard"
const DEFAULT_PROJECTILE_SPEED := 360.0
const STOLEN_OUTER_COLOR := Color(0.85, 0.77, 1.0, 0.95)
const STOLEN_CORE_COLOR := Color(0.20, 0.06, 0.32, 1.0)
const STOLEN_CODE_COLOR := Color(0.96, 0.88, 1.0, 0.96)
const STOLEN_TRAIL_COLOR := Color(0.78, 0.67, 1.0, 0.72)
const STOLEN_ATTACK_TARGET_DPS := 215.0
const STOLEN_ATTACK_MIN_DAMAGE := 28.0
const STOLEN_ATTACK_MAX_DAMAGE := 72.0

var ProjectileScene: PackedScene
var Owner: Node2D
var _cooldown_remaining := 0.0
var _cooldown_multiplier := 1.0
var _cooldown_buff_timer := 0.0
var _current_attack_id := DEFAULT_ATTACK_ID
var _current_projectile_scene: PackedScene
var _current_muzzle_offset := 30.0
var _current_projectile_speed := 360.0
var _current_projectile_profile: Dictionary = {}
var _current_shoot_cooldown := SHOOT_COOLDOWN
var _current_fire_mode := "single"
var _current_burst_size := 1
var _current_burst_spacing := 0.0
var _current_spread_angle := 0.0
var _current_pellet_count := 1
var _current_spread_total := 0.0
var _pending_burst_direction := Vector2.ZERO
var _burst_remaining := 0
var _burst_timer := 0.0

func _ready() -> void:
	self.ProjectileScene = preload("res://scenes/tests/Brunich/projectile_one_shader.tscn")
	_restore_default_profile()

func _process(delta: float) -> void:
	_cooldown_remaining = maxf(_cooldown_remaining - delta, 0.0)
	if _cooldown_buff_timer > 0.0:
		_cooldown_buff_timer = maxf(_cooldown_buff_timer - delta, 0.0)
		if _cooldown_buff_timer <= 0.0:
			_cooldown_multiplier = 1.0
	if _burst_remaining > 0:
		_burst_timer = maxf(_burst_timer - delta, 0.0)
		if _burst_timer <= 0.0:
			_fire_burst_step()

func _shoot(direction: Vector2) -> bool:
	if _cooldown_remaining > 0.0 or _burst_remaining > 0:
		return false

	var shoot_dir := direction.normalized()
	if shoot_dir == Vector2.ZERO:
		return false

	match _current_fire_mode:
		"burst":
			_start_burst_attack(shoot_dir)
		"spread":
			_fire_spread_attack(shoot_dir)
		_:
			_spawn_projectile(shoot_dir)

	_cooldown_remaining = _current_shoot_cooldown * _cooldown_multiplier
	return true

func get_current_attack_id() -> String:
	return _current_attack_id

func equip_enemy_attack(profile: Dictionary = {}) -> void:
	var merged_projectile_profile := {
		"damage": 14,
		"life_time": 2.0,
		"visual_scale": 1.28,
		"outer_color": STOLEN_OUTER_COLOR,
		"core_color": STOLEN_CORE_COLOR,
		"code_color": STOLEN_CODE_COLOR,
		"trail_color": STOLEN_TRAIL_COLOR,
		"trail_scale_min": 6.0,
		"trail_scale_max": 8.0,
		"stolen_attack": true,
	}
	var merged_profile := {
		"id": String(profile.get("id", "enemy_orb")),
		"fire_mode": String(profile.get("fire_mode", "single")),
		"burst_size": int(profile.get("burst_size", 1)),
		"burst_spacing": float(profile.get("burst_spacing", 0.0)),
		"spread_angle": float(profile.get("spread_angle", 0.0)),
		"pellet_count": int(profile.get("pellet_count", 1)),
		"spread_total": float(profile.get("spread_total", 0.0)),
		"projectile_scene": preload("res://scenes/tests/Brunich/enemy_projectile.tscn"),
		"muzzle_offset": 34.0,
		"projectile_speed": 260.0,
		"shoot_cooldown": 0.22,
		"projectile_profile": merged_projectile_profile,
	}
	var incoming_projectile_profile: Dictionary = profile.get("projectile_profile", {})
	for key in profile.keys():
		if key == "projectile_profile":
			continue
		merged_profile[key] = profile[key]
	for key in incoming_projectile_profile.keys():
		merged_projectile_profile[key] = incoming_projectile_profile[key]
	_rebalance_stolen_attack_profile(merged_profile, merged_projectile_profile)
	_apply_stolen_attack_overrides(merged_projectile_profile)
	_apply_attack_profile(merged_profile)

func restore_default_attack() -> void:
	_restore_default_profile()

func apply_flux_swap_buff(multiplier: float, duration: float) -> void:
	_cooldown_multiplier = clampf(multiplier, 0.55, 1.0)
	_cooldown_buff_timer = maxf(duration, 0.0)

func _restore_default_profile() -> void:
	_apply_attack_profile({
		"id": DEFAULT_ATTACK_ID,
		"fire_mode": "single",
		"burst_size": 1,
		"burst_spacing": 0.0,
		"spread_angle": 0.0,
		"pellet_count": 1,
		"spread_total": 0.0,
		"projectile_scene": self.ProjectileScene,
		"muzzle_offset": 30.0,
		"projectile_speed": 360.0,
		"shoot_cooldown": SHOOT_COOLDOWN,
		"projectile_profile": {},
	})

func _apply_attack_profile(profile: Dictionary) -> void:
	_current_attack_id = str(profile.get("id", DEFAULT_ATTACK_ID))
	_current_projectile_scene = profile.get("projectile_scene", self.ProjectileScene)
	_current_muzzle_offset = float(profile.get("muzzle_offset", 30.0))
	_current_projectile_speed = float(profile.get("projectile_speed", 360.0))
	_current_shoot_cooldown = float(profile.get("shoot_cooldown", SHOOT_COOLDOWN))
	_current_projectile_profile = profile.get("projectile_profile", {}).duplicate(true)
	_current_fire_mode = str(profile.get("fire_mode", "single"))
	_current_burst_size = maxi(1, int(profile.get("burst_size", 1)))
	_current_burst_spacing = maxf(float(profile.get("burst_spacing", 0.0)), 0.0)
	_current_spread_angle = float(profile.get("spread_angle", 0.0))
	_current_pellet_count = maxi(1, int(profile.get("pellet_count", 1)))
	_current_spread_total = float(profile.get("spread_total", 0.0))
	_cooldown_remaining = 0.0
	_burst_remaining = 0
	_burst_timer = 0.0
	_pending_burst_direction = Vector2.ZERO

func _apply_stolen_attack_overrides(projectile_profile: Dictionary) -> void:
	projectile_profile["stolen_attack"] = true
	projectile_profile["outer_color"] = STOLEN_OUTER_COLOR
	projectile_profile["core_color"] = STOLEN_CORE_COLOR
	projectile_profile["code_color"] = STOLEN_CODE_COLOR
	projectile_profile["trail_color"] = STOLEN_TRAIL_COLOR
	projectile_profile["trail_scale_min"] = maxf(float(projectile_profile.get("trail_scale_min", 6.0)), 6.0)
	projectile_profile["trail_scale_max"] = maxf(float(projectile_profile.get("trail_scale_max", 8.0)), 8.0)

func _rebalance_stolen_attack_profile(attack_profile: Dictionary, projectile_profile: Dictionary) -> void:
	if bool(projectile_profile.get("preserve_stolen_damage", false)):
		return

	var shoot_cooldown := float(attack_profile.get("shoot_cooldown", SHOOT_COOLDOWN))
	var projectile_speed := float(attack_profile.get("projectile_speed", DEFAULT_PROJECTILE_SPEED))
	var visual_scale := float(projectile_profile.get("visual_scale", 1.0))
	var life_time := float(projectile_profile.get("life_time", 1.8))
	var base_damage := float(projectile_profile.get("damage", STOLEN_ATTACK_MIN_DAMAGE))
	var size_bonus := 1.0 + maxf(visual_scale - 1.0, 0.0) * 0.35
	var speed_bonus := 1.0 + maxf(DEFAULT_PROJECTILE_SPEED - projectile_speed, 0.0) / DEFAULT_PROJECTILE_SPEED * 0.45
	var life_bonus := 1.0 + maxf(life_time - 1.8, 0.0) / 1.8 * 0.18
	var target_damage := STOLEN_ATTACK_TARGET_DPS * shoot_cooldown * size_bonus * speed_bonus * life_bonus
	var floor_damage := maxf(base_damage * 1.8, STOLEN_ATTACK_MIN_DAMAGE)
	projectile_profile["damage"] = int(round(clampf(target_damage, floor_damage, STOLEN_ATTACK_MAX_DAMAGE)))

func _start_burst_attack(direction: Vector2) -> void:
	_pending_burst_direction = direction
	_burst_remaining = _current_burst_size
	_burst_timer = 0.0
	_fire_burst_step()

func _fire_burst_step() -> void:
	if _burst_remaining <= 0:
		return

	var spread_index := _current_burst_size - _burst_remaining
	var centered := float(spread_index) - float(_current_burst_size - 1) * 0.5
	var shot_direction := _pending_burst_direction.rotated(centered * _current_spread_angle)
	_spawn_projectile(shot_direction)
	_burst_remaining -= 1
	if _burst_remaining > 0:
		_burst_timer = _current_burst_spacing

func _fire_spread_attack(direction: Vector2) -> void:
	if _current_pellet_count <= 1:
		_spawn_projectile(direction)
		return

	for pellet_index in range(_current_pellet_count):
		var t := float(pellet_index) / float(_current_pellet_count - 1)
		var angle := -_current_spread_total * 0.5 + _current_spread_total * t
		_spawn_projectile(direction.rotated(angle))

func _spawn_projectile(direction: Vector2) -> void:
	var projectile: Node2D = _current_projectile_scene.instantiate() as Node2D
	projectile.global_position = self.Owner.global_position + direction * _current_muzzle_offset
	projectile.rotation = direction.angle()
	projectile.Owner = self.Owner
	if projectile.has_method("configure_projectile") and not _current_projectile_profile.is_empty():
		projectile.configure_projectile(_current_projectile_profile.duplicate(true))

	var parent: Node = get_tree().current_scene if get_tree().current_scene != null else get_tree().root
	parent.add_child(projectile)

	projectile.HurtboxComp.Owner = self.Owner
	projectile.ConstantVelocityComp.Speed = _current_projectile_speed
	projectile.ConstantVelocityComp.Direction = direction
