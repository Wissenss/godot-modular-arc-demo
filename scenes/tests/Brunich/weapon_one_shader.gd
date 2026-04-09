extends Node2D

const SHOOT_COOLDOWN := 0.08
const DEFAULT_ATTACK_ID := "rogue_shard"
const ENEMY_ATTACK_ID := "enemy_orb"
const STOLEN_OUTER_COLOR := Color(0.85, 0.77, 1.0, 0.95)
const STOLEN_TRAIL_COLOR := Color(0.78, 0.67, 1.0, 0.72)

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

func _ready() -> void:
	self.ProjectileScene = preload("res://scenes/tests/Brunich/projectile_one_shader.tscn")
	_restore_default_profile()

func _process(delta: float) -> void:
	_cooldown_remaining = maxf(_cooldown_remaining - delta, 0.0)
	if _cooldown_buff_timer > 0.0:
		_cooldown_buff_timer = maxf(_cooldown_buff_timer - delta, 0.0)
		if _cooldown_buff_timer <= 0.0:
			_cooldown_multiplier = 1.0

func _shoot(direction: Vector2) -> bool:
	if _cooldown_remaining > 0.0:
		return false

	var shoot_dir := direction.normalized()
	if shoot_dir == Vector2.ZERO:
		return false

	var projectile: Node2D = _current_projectile_scene.instantiate() as Node2D
	projectile.global_position = self.Owner.global_position + shoot_dir * _current_muzzle_offset
	projectile.rotation = shoot_dir.angle()
	projectile.Owner = self.Owner
	if projectile.has_method("configure_projectile") and not _current_projectile_profile.is_empty():
		projectile.configure_projectile(_current_projectile_profile.duplicate(true))

	var parent: Node = get_tree().current_scene if get_tree().current_scene != null else get_tree().root
	parent.add_child(projectile)

	projectile.HurtboxComp.Owner = self.Owner
	projectile.ConstantVelocityComp.Speed = _current_projectile_speed
	projectile.ConstantVelocityComp.Direction = shoot_dir
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
		"core_color": Color(0.04, 0.16, 0.32, 1.0),
		"code_color": Color(0.92, 0.99, 1.0, 0.95),
		"trail_color": STOLEN_TRAIL_COLOR,
		"trail_scale_min": 6.0,
		"trail_scale_max": 8.0,
		"stolen_attack": true,
	}
	var merged_profile := {
		"id": ENEMY_ATTACK_ID,
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

func _apply_stolen_attack_overrides(projectile_profile: Dictionary) -> void:
	projectile_profile["stolen_attack"] = true
	projectile_profile["outer_color"] = STOLEN_OUTER_COLOR
	projectile_profile["trail_color"] = STOLEN_TRAIL_COLOR
	projectile_profile["trail_scale_min"] = maxf(float(projectile_profile.get("trail_scale_min", 6.0)), 6.0)
	projectile_profile["trail_scale_max"] = maxf(float(projectile_profile.get("trail_scale_max", 8.0)), 8.0)
