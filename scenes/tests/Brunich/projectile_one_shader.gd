extends Node2D

const LIFE_TIME := 1.8
const BASE_DAMAGE := 24
const BRUNICH_PALETTE := preload("res://scenes/tests/Brunich/brunich_palette.gd")
const COMBAT_VFX := preload("res://scenes/tests/Brunich/combat_vfx.gd")

var ConstantVelocityComp: ConstantVelocityComponent
var HurtboxComp: HurtboxComponent
var Owner: Node2D
var OutlinePolygon: Polygon2D
var CorePolygon: Polygon2D
var TrailParticles: CPUParticles2D
var _life_remaining := LIFE_TIME
var _impact_emitted := false

func _ready() -> void:
	add_to_group("player_projectile")

	self.OutlinePolygon = $outline_polygon
	self.CorePolygon = $Polygon2D
	self.TrailParticles = $CPUParticles2D
	self.ConstantVelocityComp = $constant_velocity_comp
	self.ConstantVelocityComp.Owner = self

	self.HurtboxComp = $hurtbox_comp
	self.HurtboxComp.Damage = BASE_DAMAGE
	self.HurtboxComp.on_hurt.connect(self._handle_on_hurt)
	self.OutlinePolygon.color = BRUNICH_PALETTE.with_alpha(BRUNICH_PALETTE.HERO_PROJECTILE_OUTER, 0.95)
	self.CorePolygon.color = BRUNICH_PALETTE.with_alpha(BRUNICH_PALETTE.HERO_PROJECTILE_CORE, 0.96)
	self.TrailParticles.color = BRUNICH_PALETTE.with_alpha(BRUNICH_PALETTE.HERO_PROJECTILE_TRAIL, 0.70)

func _physics_process(delta: float) -> void:
	_life_remaining -= delta
	if _life_remaining <= 0.0:
		_emit_impact(0.58)
		queue_free()
		return

	if self.ConstantVelocityComp.Direction != Vector2.ZERO:
		rotation = self.ConstantVelocityComp.Direction.angle()

func _handle_on_hurt(to: Area2D, _damage: int) -> void:
	if to is HitboxComponent and self.Owner != null and self.Owner == to.Owner:
		return

	_emit_impact(1.0)
	queue_free()

func _emit_impact(size_scale: float) -> void:
	if _impact_emitted:
		return
	_impact_emitted = true
	var parent: Node = get_tree().current_scene if get_tree().current_scene != null else get_tree().root
	COMBAT_VFX.spawn_pixel_impact(
		parent,
		global_position,
		self.ConstantVelocityComp.Direction,
		self.OutlinePolygon.color,
		self.CorePolygon.color,
		BRUNICH_PALETTE.with_alpha(BRUNICH_PALETTE.HERO_PROJECTILE_CODE, 0.96),
		size_scale,
		9,
		0.22
	)
