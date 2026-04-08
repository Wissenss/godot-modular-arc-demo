extends CharacterBody2D

const GLITCH_DURATION := 0.35
const INVINCIBLE_DURATION := 0.6
const MOVE_SPEED := 400.0
const DASH_SPEED := 980.0
const DASH_DURATION := 0.16
const DASH_RECHARGE_TIME := 1.2
const MAX_DASH_CHARGES := 2

var ControllerComp: ControllerComponent
var ConstantVelocityComp: ConstantVelocityComponent
var BodyParticles: CPUParticles2D
var TrailParticles: CPUParticles2D
var BodyParticlesDark: CPUParticles2D
var BodyParticlesBright: CPUParticles2D
var Weapon
var HitboxComp: HitboxComponent
var HealthComp: HealthComponent
var GlitchPolygon: Polygon2D
var DashCharges := MAX_DASH_CHARGES

var _glitch_timer := 0.0
var _invincible_timer := 0.0
var _dash_timer := 0.0
var _dash_recharge_timer := 0.0
var _dash_direction := Vector2.ZERO

func _ready() -> void:
	add_to_group("player")
	_ensure_input_actions()

	self.ControllerComp = $controller_comp
	self.ControllerComp.Owner = self

	self.ConstantVelocityComp = $constant_velocity_comp
	self.ConstantVelocityComp.Owner = self
	self.ConstantVelocityComp.Speed = MOVE_SPEED

	self.Weapon = $weapon_one_shader
	self.Weapon.Owner = self

	self.BodyParticles = $body_particles
	self.TrailParticles = $trail_particles
	self.BodyParticlesDark = $body_particles3
	self.BodyParticlesBright = $body_particles2

	self.HitboxComp = $hitbox_comp
	self.HitboxComp.Owner = self
	self.HitboxComp.on_hit.connect(self._handle_on_hit)

	self.HealthComp = $health_comp
	self.HealthComp.set_max_health(100)
	self.HealthComp.set_health(100)
	self.HealthComp.on_died.connect(self._handle_on_died)

	self.GlitchPolygon = $polygon
	self.GlitchPolygon.color = Color(0.60, 0.18, 1.0, 1.0)
	self.GlitchPolygon.visible = false

func _process(delta: float) -> void:
	if _has_effect_component("KnockbackEffectComponent") or _has_effect_component("FrozenEffectComponent"):
		self.ConstantVelocityComp.Direction = Vector2.ZERO
	else:
		self.ConstantVelocityComp.Direction = self.ControllerComp._get_move_direction()

	var aim_dir := _get_world_aim_dir()
	if self.ControllerComp._is_attack_pressed() and aim_dir != Vector2.ZERO:
		self.Weapon._shoot(aim_dir)

	if self.ControllerComp._is_dash_pressed():
		var dash_dir := self.ConstantVelocityComp.Direction if self.ConstantVelocityComp.Direction != Vector2.ZERO else aim_dir
		request_dash(dash_dir)

	_update_visual_state(delta)

func _physics_process(delta: float) -> void:
	if _dash_timer > 0.0:
		self.position += _dash_direction * DASH_SPEED * delta
		_dash_timer = maxf(_dash_timer - delta, 0.0)

func _get_world_aim_dir() -> Vector2:
	var mouse_screen := get_viewport().get_mouse_position()
	var cam_xform := get_viewport().get_canvas_transform()
	var mouse_world := cam_xform.affine_inverse() * mouse_screen
	return (mouse_world - global_position).normalized()

func request_dash(direction: Vector2) -> bool:
	if DashCharges <= 0:
		return false

	var dash_dir := direction.normalized()
	if dash_dir == Vector2.ZERO:
		return false

	DashCharges -= 1
	_dash_direction = dash_dir
	_dash_timer = DASH_DURATION

	if DashCharges == MAX_DASH_CHARGES - 1 or _dash_recharge_timer <= 0.0:
		_dash_recharge_timer = DASH_RECHARGE_TIME

	_trigger_dash_particles()
	return true

func _trigger_glitch_flash() -> void:
	self.GlitchPolygon.visible = true
	_glitch_timer = GLITCH_DURATION

func _handle_on_hit(by: Area2D) -> void:
	if _invincible_timer > 0.0:
		return

	if by is HurtboxComponent:
		if by.Owner == self:
			return

		self.HealthComp.take_damage(by.Damage)
		_invincible_timer = INVINCIBLE_DURATION
		_trigger_glitch_flash()

func _handle_on_died() -> void:
	self.BodyParticles.emitting = false
	self.TrailParticles.emitting = false
	self.BodyParticlesDark.emitting = false
	self.BodyParticlesBright.emitting = false
	self.queue_free()

func _update_visual_state(delta: float) -> void:
	var is_moving := self.ConstantVelocityComp.Direction != Vector2.ZERO or _dash_timer > 0.0

	if is_moving:
		self.BodyParticles.orbit_velocity_min = 0
		self.BodyParticles.orbit_velocity_max = 0
		self.BodyParticles.emitting = false
		self.TrailParticles.emitting = true
	else:
		self.BodyParticles.orbit_velocity_min = -1
		self.BodyParticles.orbit_velocity_max = 1
		self.BodyParticles.emitting = true
		self.TrailParticles.emitting = false

	if _dash_timer > 0.0:
		self.TrailParticles.scale_amount_max = 34.0
		self.TrailParticles.initial_velocity_max = 180.0
	else:
		self.TrailParticles.scale_amount_max = 24.0
		self.TrailParticles.initial_velocity_max = 100.0

	if _glitch_timer > 0.0:
		_glitch_timer -= delta
		if _glitch_timer <= 0.0:
			self.GlitchPolygon.visible = false

	if _invincible_timer > 0.0:
		_invincible_timer -= delta

	if DashCharges < MAX_DASH_CHARGES:
		_dash_recharge_timer -= delta
		if _dash_recharge_timer <= 0.0:
			DashCharges += 1
			if DashCharges < MAX_DASH_CHARGES:
				_dash_recharge_timer += DASH_RECHARGE_TIME
			else:
				_dash_recharge_timer = 0.0

func _trigger_dash_particles() -> void:
	self.TrailParticles.emitting = true
	self.TrailParticles.restart()
	self.BodyParticlesDark.restart()
	self.BodyParticlesBright.restart()

func _ensure_input_actions() -> void:
	if not InputMap.has_action("attack"):
		InputMap.add_action("attack")
	if not InputMap.has_action("dash"):
		InputMap.add_action("dash")

	if not _action_has_mouse_button("attack", MOUSE_BUTTON_LEFT):
		var attack_event := InputEventMouseButton.new()
		attack_event.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("attack", attack_event)

	if not _action_has_key("dash", KEY_SPACE):
		var dash_event := InputEventKey.new()
		dash_event.physical_keycode = KEY_SPACE
		InputMap.action_add_event("dash", dash_event)

func _action_has_mouse_button(action: StringName, button: MouseButton) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventMouseButton and event.button_index == button:
			return true
	return false

func _action_has_key(action: StringName, key: Key) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey and event.physical_keycode == key:
			return true
	return false

func _has_effect_component(effect_class_name: StringName) -> bool:
	for child in get_children():
		if child.has_method("get_class_name") and child.get_class_name() == effect_class_name:
			return true
	return false
