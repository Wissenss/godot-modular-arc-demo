class_name EnemyProjectile extends Node2D

const LIFE_TIME := 2.4
const BASE_DAMAGE := 18

var ConstantVelocityComp: ConstantVelocityComponent
var HurtboxComp: HurtboxComponent
var Owner: Node2D
var OuterRing: Polygon2D
var CorePolygon: Polygon2D
var CodePolygon: Polygon2D
var TrailParticles: CPUParticles2D
var _life_remaining := LIFE_TIME
var _damage := BASE_DAMAGE
var _visual_scale := 1.0
var _stolen_attack := false
var _pending_profile: Dictionary = {}
var _pierce_count := 0      # 0 = dies on first hit; N = passes through N times
var _slow_factor := 0.0     # 0 = no slow; 0.36 = 36% speed reduction on hit
var _slow_duration := 1.8   # seconds the slow effect lasts

func _ready() -> void:
	add_to_group("enemy_projectile")

	self.OuterRing = $outer_ring
	self.CorePolygon = $core_polygon
	self.CodePolygon = $code_polygon
	self.TrailParticles = $trail_particles

	self.ConstantVelocityComp = $constant_velocity_comp
	self.ConstantVelocityComp.Owner = self

	self.HurtboxComp = $hurtbox_comp
	self.HurtboxComp.Damage = _damage
	self.HurtboxComp.on_hurt.connect(self._handle_on_hurt)
	_apply_visual_profile(_pending_profile)

func _physics_process(delta: float) -> void:
	_life_remaining -= delta
	if _life_remaining <= 0.0:
		queue_free()
		return

	if self.ConstantVelocityComp.Direction != Vector2.ZERO:
		rotation = self.ConstantVelocityComp.Direction.angle()

func _handle_on_hurt(to: Area2D, _damage: int) -> void:
	if to is HitboxComponent and self.Owner != null and self.Owner == to.Owner:
		return

	# Apply slow effect to whatever was hit
	if _slow_factor > 0.0 and to is HitboxComponent and to.Owner != null:
		if to.Owner.has_method("apply_slow"):
			to.Owner.apply_slow(_slow_factor, _slow_duration)

	# Pierce: pass through instead of dying
	if _pierce_count < 0:
		return
	if _pierce_count > 0:
		_pierce_count -= 1
		return

	queue_free()

func configure_projectile(profile: Dictionary) -> void:
	_pending_profile = profile.duplicate(true)
	_damage = int(profile.get("damage", BASE_DAMAGE))
	_life_remaining = float(profile.get("life_time", LIFE_TIME))
	_visual_scale = float(profile.get("visual_scale", 1.0))
	_stolen_attack = bool(profile.get("stolen_attack", false))
	_pierce_count = int(profile.get("pierce_count", 0))
	_slow_factor = float(profile.get("slow_factor", 0.0))
	_slow_duration = float(profile.get("slow_duration", 1.8))
	if self.HurtboxComp != null:
		self.HurtboxComp.Damage = _damage
	_apply_visual_profile(_pending_profile)

func _apply_visual_profile(profile: Dictionary) -> void:
	if self.OuterRing == null:
		return

	self.OuterRing.color = profile.get("outer_color", Color(0.0, 0.85, 1.0, 0.9))
	self.CorePolygon.color = profile.get("core_color", Color(0.0, 0.18, 0.38, 0.95))
	self.CodePolygon.color = profile.get("code_color", Color(0.92, 0.99, 1.0, 0.95))
	self.TrailParticles.color = profile.get("trail_color", Color(0.0, 0.85, 1.0, 0.6))
	self.TrailParticles.scale_amount_min = float(profile.get("trail_scale_min", 3.0))
	self.TrailParticles.scale_amount_max = float(profile.get("trail_scale_max", 5.0))
	if _stolen_attack:
		self.TrailParticles.color = Color(
			maxf(self.TrailParticles.color.r, 0.68),
			minf(self.TrailParticles.color.g, 0.74),
			maxf(self.TrailParticles.color.b, 0.92),
			maxf(self.TrailParticles.color.a, 0.72)
		)
		self.TrailParticles.scale_amount_min = maxf(self.TrailParticles.scale_amount_min, 6.0)
		self.TrailParticles.scale_amount_max = maxf(self.TrailParticles.scale_amount_max, 8.0)

	self.OuterRing.scale = Vector2.ONE * (6.2 * _visual_scale)
	self.CorePolygon.scale = Vector2.ONE * (3.8 * _visual_scale)
	self.CodePolygon.scale = Vector2.ONE * (2.8 * _visual_scale)
