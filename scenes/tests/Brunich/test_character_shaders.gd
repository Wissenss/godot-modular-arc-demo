extends CharacterBody2D

const GLITCH_DURATION := 0.35
const INVINCIBLE_DURATION := 0.6
const MOVE_SPEED := 374.0
const DASH_SPEED := 980.0
const DASH_DURATION := 0.16
const DASH_RECHARGE_FIRST := 0.52
const DASH_RECHARGE_SECOND := 0.24
const MAX_DASH_CHARGES := 2
const FACE_DATA_PATH := "res://art/generated/brunich/mc_face_expressions.json"
const SCANLINE_SHADER := preload("res://scenes/tests/Brunich/scanline_shader.gdshader")
const SCREEN_FRAME_IDLE := Color(0.07, 0.09, 0.16, 0.96)
const SCREEN_FRAME_ACTIVE := Color(0.12, 0.12, 0.22, 0.98)
const SCREEN_SHELL_IDLE := Color(0.03, 0.05, 0.10, 0.98)
const SCREEN_SHELL_ACTIVE := Color(0.08, 0.07, 0.16, 1.0)
const SCREEN_TRIM_IDLE := Color(0.16, 0.24, 0.40, 0.90)
const SCREEN_TRIM_ACTIVE := Color(0.34, 0.50, 0.78, 0.94)
const SCREEN_FILL_IDLE := Color(0.23, 0.23, 0.25, 0.98)
const SCREEN_FILL_ACTIVE := Color(0.28, 0.28, 0.31, 1.0)
const SCREEN_GLOW_IDLE := Color(0.34, 0.56, 1.0, 0.10)
const SCREEN_GLOW_ACTIVE := Color(0.55, 0.24, 0.98, 0.18)
const PIXEL_IDLE := Color(0.84, 0.86, 0.90, 0.98)
const PIXEL_ALERT := Color(0.96, 0.97, 1.0, 1.0)
const FACE_PIXEL_SCALE := 0.688
const FACE_PIXEL_POOL_SIZE := 64
const STEAL_RANGE := 76.0
const WEAPON_SWAP_HEAL_RATIO := 0.05
const WEAPON_SWAP_SPEED_BONUS := 93.5
const WEAPON_SWAP_BUFF_DURATION := 10.0
const WEAPON_SWAP_COOLDOWN_MULTIPLIER := 0.86
const WEAPON_SWAP_FACE_DURATION := 6.0
const HACK_POPUP_DURATION := 1.1
const HEAL_FLASH_DURATION := 0.46
const SCREEN_BASE_SCALE := 0.747
const SCREEN_GLOW_BASE_SCALE := 0.802
const SCREEN_BLUR_BASE_SCALE := 0.860
const FACE_ROOT_SCALE := 0.904
const PARTICLE_SPEED_MULTIPLIER := 0.5
const PARTICLE_LIFETIME_MULTIPLIER := 1.45

# --- Ciclos (processing capacity used for hackeo) ---
const MAX_CICLOS := 100.0
const CICLOS_REGEN_RATE := 7.0      # per second (passive)
const CICLOS_KILL_REWARD := 20.0    # gained on enemy eliminated
const HACKEO_RANGE := 92.0          # max distance to hackeo target
const HACKEO_COST := 35.0           # ciclos consumed per hackeo
const HACKEO_CICLOS_REWARD := 15.0  # ciclos returned after successful hackeo
const HACKEO_HEALTH_THRESHOLD := 0.42  # target must be below this HP ratio

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
var ScreenGlow: Polygon2D
var ScreenShell: Polygon2D
var ScreenFrame: Polygon2D
var ScreenTrim: Polygon2D
var ScreenFill: Polygon2D
var ScreenGlass: Polygon2D
var ScreenGlassSecondary: Polygon2D
var ScreenReflectionRight: Polygon2D
var ScreenShadow: Polygon2D
var ScreenReflectionCorner: Polygon2D
var ScreenReflectionSteps: Polygon2D
var ScreenBlur: Polygon2D
var ScreenScanlines: Node2D
var ScreenSweepLines: Node2D
var FacePixels: Node2D
var StealBuffParticlesBack: CPUParticles2D
var StealBuffParticlesFront: CPUParticles2D
var HealParticles: CPUParticles2D
var HealSparkParticles: CPUParticles2D
var HealCrownBack: Node2D
var HealCrownFront: Node2D
var DashCharges := MAX_DASH_CHARGES

var _glitch_timer := 0.0
var _invincible_timer := 0.0
var _dash_timer := 0.0
var _dash_recharge_timer := 0.0
var _dash_direction := Vector2.ZERO
var _face_variant := 0
var _face_rng := RandomNumberGenerator.new()
var _face_catalog: Dictionary = {}
var _face_pixel_pool: Array[Polygon2D] = []
var _face_override := ""
var _face_override_timer := 0.0
var _resolved_face_expression := "angry"
var _weapon_swap_buff_timer := 0.0
var _heal_flash_timer := 0.0
var _screen_sweep_pixels: Array[Polygon2D] = []
var _hack_popup_root: Node2D
var _hack_popup_bg: Polygon2D
var _hack_popup_label: Label
var _hack_popup_message := ""
var _hack_popup_timer := 0.0
var Ciclos := MAX_CICLOS * 0.5      # start at 50 ciclos
var _slow_timer := 0.0
var _slow_factor := 0.0

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
	self.ScreenGlow = $screen_glow
	self.ScreenShell = $screen_shell
	self.ScreenFrame = $screen_frame
	self.ScreenTrim = $screen_trim
	self.ScreenFill = $screen_fill
	self.ScreenGlass = $screen_glass
	self.ScreenGlassSecondary = $screen_glass_secondary
	self.ScreenReflectionRight = $screen_reflection_right
	self.ScreenShadow = $screen_shadow
	self.FacePixels = $face_pixels
	_configure_tv_screen()
	self.FacePixels.scale = Vector2.ONE * FACE_ROOT_SCALE
	_build_feedback_particles()
	_configure_core_particles()

	self.HitboxComp = $hitbox_comp
	self.HitboxComp.Owner = self
	self.HitboxComp.on_hit.connect(self._handle_on_hit)

	self.HealthComp = $health_comp
	self.HealthComp.set_max_health(100)
	self.HealthComp.set_health(100)
	self.HealthComp.on_died.connect(self._handle_on_died)

	_face_rng.randomize()
	_load_face_catalog()
	_build_face_pixel_pool()
	_build_hack_popup()
	self.BodyParticlesDark.emitting = true
	self.BodyParticlesBright.emitting = true
	_apply_face("angry")

	self.GlitchPolygon = $polygon
	self.GlitchPolygon.color = Color(0.60, 0.18, 1.0, 1.0)
	self.GlitchPolygon.visible = false

func _process(delta: float) -> void:
	if _has_effect_component("KnockbackEffectComponent") or _has_effect_component("FrozenEffectComponent"):
		self.ConstantVelocityComp.Direction = Vector2.ZERO
	else:
		self.ConstantVelocityComp.Direction = self.ControllerComp._get_move_direction()

	var aim_dir := _get_world_aim_dir()
	var is_attacking := self.ControllerComp._is_attack_pressed() and aim_dir != Vector2.ZERO
	if is_attacking:
		self.Weapon._shoot(aim_dir)

	if self.ControllerComp._is_dash_pressed():
		var dash_dir := self.ConstantVelocityComp.Direction if self.ConstantVelocityComp.Direction != Vector2.ZERO else aim_dir
		request_dash(dash_dir)

	if self.ControllerComp.has_method("_is_steal_pressed") and self.ControllerComp._is_steal_pressed():
		try_steal_attack()

	_update_hack_popup(delta)
	_update_visual_state(delta, is_attacking)

	# Ciclos passive regen
	Ciclos = minf(Ciclos + CICLOS_REGEN_RATE * delta, MAX_CICLOS)

	# Hackeo action (H key)
	if InputMap.has_action("hackeo") and Input.is_action_just_pressed("hackeo"):
		try_hackeo()

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

	if DashCharges < MAX_DASH_CHARGES:
		_dash_recharge_timer = _get_dash_recharge_duration()

	_trigger_dash_particles()
	return true

func _trigger_glitch_flash() -> void:
	self.GlitchPolygon.visible = true
	_glitch_timer = GLITCH_DURATION
	_face_variant = _face_rng.randi_range(0, 2)

func _handle_on_hit(by: Area2D) -> void:
	if _invincible_timer > 0.0:
		return
	if _dash_timer > 0.0:
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

func _update_visual_state(delta: float, is_attacking: bool) -> void:
	var is_moving := self.ConstantVelocityComp.Direction != Vector2.ZERO or _dash_timer > 0.0
	_weapon_swap_buff_timer = maxf(_weapon_swap_buff_timer - delta, 0.0)
	_slow_timer = maxf(_slow_timer - delta, 0.0)
	var slow_mult := 1.0 - _slow_factor * (1.0 if _slow_timer > 0.0 else 0.0)
	self.ConstantVelocityComp.Speed = (MOVE_SPEED * slow_mult) + (WEAPON_SWAP_SPEED_BONUS if _weapon_swap_buff_timer > 0.0 else 0.0)
	_heal_flash_timer = maxf(_heal_flash_timer - delta, 0.0)
	var move_vector := self.ConstantVelocityComp.Direction
	if move_vector == Vector2.ZERO and _dash_timer > 0.0:
		move_vector = _dash_direction
	var move_dir := move_vector.normalized() if move_vector != Vector2.ZERO else Vector2.UP
	var side_dir := move_dir.orthogonal()
	var flow_time := float(Time.get_ticks_msec()) * 0.0012
	var sway := sin(flow_time * 6.2) * 0.32
	var lateral_sway := cos(flow_time * 4.8) * 0.22
	var drift_dir := (move_dir.rotated(sway) + side_dir * lateral_sway).normalized()
	var particle_speed := PARTICLE_SPEED_MULTIPLIER
	var particle_lifetime := PARTICLE_LIFETIME_MULTIPLIER

	if is_moving:
		self.BodyParticles.local_coords = false
		self.BodyParticlesDark.local_coords = false
		self.BodyParticlesBright.local_coords = false
		self.BodyParticles.orbit_velocity_min = -0.18 * particle_speed
		self.BodyParticles.orbit_velocity_max = 0.18 * particle_speed
		self.BodyParticlesDark.orbit_velocity_min = -0.12 * particle_speed
		self.BodyParticlesDark.orbit_velocity_max = 0.12 * particle_speed
		self.BodyParticlesBright.orbit_velocity_min = -0.16 * particle_speed
		self.BodyParticlesBright.orbit_velocity_max = 0.16 * particle_speed
		self.BodyParticles.emitting = true
		self.BodyParticlesDark.emitting = true
		self.BodyParticlesBright.emitting = true
		self.TrailParticles.emitting = true
		self.BodyParticles.direction = -drift_dir
		self.BodyParticles.spread = 158.0
		self.BodyParticles.gravity = (-move_dir * 54.0 + side_dir * sin(flow_time * 7.8) * 28.0 + Vector2(0, 26)) * particle_speed
		self.BodyParticles.lifetime = 0.64 * particle_lifetime
		self.BodyParticlesDark.direction = -drift_dir.rotated(-0.24)
		self.BodyParticlesDark.spread = 150.0
		self.BodyParticlesDark.gravity = (-move_dir * 34.0 + side_dir * cos(flow_time * 6.0) * 18.0 + Vector2(0, 18)) * particle_speed
		self.BodyParticlesDark.lifetime = 0.60 * particle_lifetime
		self.BodyParticlesBright.direction = (-drift_dir + side_dir * 0.20).normalized()
		self.BodyParticlesBright.spread = 146.0
		self.BodyParticlesBright.gravity = (-move_dir * 40.0 + side_dir * sin(flow_time * 8.4 + 1.3) * 22.0 + Vector2(0, 16)) * particle_speed
		self.BodyParticlesBright.lifetime = 0.56 * particle_lifetime
		self.TrailParticles.direction = -move_dir
		self.TrailParticles.spread = 88.0
		self.TrailParticles.gravity = (-move_dir * 52.0 + side_dir * cos(flow_time * 5.4) * 12.0 + Vector2(0, 20)) * particle_speed
		self.TrailParticles.lifetime = 0.42 * particle_lifetime
	else:
		self.BodyParticles.local_coords = false
		self.BodyParticlesDark.local_coords = false
		self.BodyParticlesBright.local_coords = false
		self.BodyParticles.orbit_velocity_min = -1 * particle_speed
		self.BodyParticles.orbit_velocity_max = 1 * particle_speed
		self.BodyParticlesDark.orbit_velocity_min = -0.7 * particle_speed
		self.BodyParticlesDark.orbit_velocity_max = 0.7 * particle_speed
		self.BodyParticlesBright.orbit_velocity_min = -0.85 * particle_speed
		self.BodyParticlesBright.orbit_velocity_max = 0.85 * particle_speed
		self.BodyParticles.emitting = true
		self.BodyParticlesDark.emitting = true
		self.BodyParticlesBright.emitting = true
		self.TrailParticles.emitting = false
		self.BodyParticles.direction = Vector2.ZERO
		self.BodyParticles.spread = 180.0
		self.BodyParticles.gravity = Vector2(0, 12) * particle_speed
		self.BodyParticles.lifetime = 0.74 * particle_lifetime
		self.BodyParticlesDark.direction = Vector2.ZERO
		self.BodyParticlesDark.spread = 180.0
		self.BodyParticlesDark.gravity = Vector2(0, 8) * particle_speed
		self.BodyParticlesDark.lifetime = 0.70 * particle_lifetime
		self.BodyParticlesBright.direction = Vector2.ZERO
		self.BodyParticlesBright.spread = 180.0
		self.BodyParticlesBright.gravity = Vector2(0, 10) * particle_speed
		self.BodyParticlesBright.lifetime = 0.66 * particle_lifetime
		self.TrailParticles.direction = Vector2.ZERO
		self.TrailParticles.spread = 180.0
		self.TrailParticles.gravity = Vector2.ZERO
		self.TrailParticles.lifetime = 0.42 * particle_lifetime

	if _dash_timer > 0.0:
		self.TrailParticles.scale_amount_max = 11.04
		self.TrailParticles.initial_velocity_max = 180.0 * particle_speed
	else:
		self.TrailParticles.scale_amount_max = 7.84
		self.TrailParticles.initial_velocity_max = 100.0 * particle_speed

	var pulse := sin(float(Time.get_ticks_msec()) * 0.0062) * 0.5 + 0.5
	var motion_boost := 1.0 if is_moving else 0.0
	var dash_boost := 1.0 if _dash_timer > 0.0 else 0.0
	var flux_boost := 1.0 if _weapon_swap_buff_timer > 0.0 else 0.0
	self.BodyParticlesBright.initial_velocity_max = (150.0 + motion_boost * 18.0 + dash_boost * 36.0 + flux_boost * 20.0) * particle_speed
	self.BodyParticlesBright.scale_amount_max = 4.8 + pulse * 0.75 + dash_boost * 1.0 + flux_boost * 0.8
	self.BodyParticlesBright.color = Color(0.43, 0.16, 0.97, 0.54 + pulse * 0.12 + dash_boost * 0.08 + flux_boost * 0.10)
	self.BodyParticlesDark.initial_velocity_max = (132.0 + motion_boost * 14.0 + dash_boost * 24.0) * particle_speed
	self.BodyParticlesDark.scale_amount_max = 4.4 + pulse * 0.6 + flux_boost * 0.4
	self.BodyParticlesDark.color = Color(0.0, 0.0, 0.0, 0.46 + pulse * 0.08)
	self.BodyParticles.initial_velocity_max = (154.0 + motion_boost * 26.0 + dash_boost * 30.0 + flux_boost * 18.0) * particle_speed
	self.BodyParticles.scale_amount_max = 8.64 + pulse * 0.72 + dash_boost * 0.96 + flux_boost * 0.72
	self.BodyParticles.color = Color(0.10, 0.04, 0.48, 0.38 + pulse * 0.10 + dash_boost * 0.05 + flux_boost * 0.08)

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
				_dash_recharge_timer = _get_dash_recharge_duration()
			else:
				_dash_recharge_timer = 0.0

	_update_screen_visual(delta, is_moving, is_attacking)
	_update_flux_feedback(pulse, flux_boost, dash_boost)
	_update_heal_feedback()

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
	if not InputMap.has_action("steal"):
		InputMap.add_action("steal")
	if not InputMap.has_action("hackeo"):
		InputMap.add_action("hackeo")

	if not _action_has_mouse_button("attack", MOUSE_BUTTON_LEFT):
		var attack_event := InputEventMouseButton.new()
		attack_event.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("attack", attack_event)

	if not _action_has_key("dash", KEY_SPACE):
		var dash_event := InputEventKey.new()
		dash_event.physical_keycode = KEY_SPACE
		InputMap.action_add_event("dash", dash_event)

	if not _action_has_key("steal", KEY_E):
		var steal_event := InputEventKey.new()
		steal_event.physical_keycode = KEY_E
		InputMap.action_add_event("steal", steal_event)

	if not _action_has_key("hackeo", KEY_H):
		var hackeo_event := InputEventKey.new()
		hackeo_event.physical_keycode = KEY_H
		InputMap.action_add_event("hackeo", hackeo_event)

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

func _get_dash_recharge_duration() -> float:
	return DASH_RECHARGE_FIRST if DashCharges <= 0 else DASH_RECHARGE_SECOND

func _update_screen_visual(delta: float, is_moving: bool, is_attacking: bool) -> void:
	if _face_override_timer > 0.0:
		_face_override_timer = maxf(_face_override_timer - delta, 0.0)
		if _face_override_timer <= 0.0:
			_face_override = ""

	var dash_boost := 1.0 if _dash_timer > 0.0 else 0.0
	var attack_boost := 1.0 if is_attacking else 0.0
	var flux_boost := 1.0 if _weapon_swap_buff_timer > 0.0 else 0.0
	var pulse := sin(float(Time.get_ticks_msec()) * 0.0085) * 0.5 + 0.5
	var face_offset := Vector2.ZERO
	if _glitch_timer > 0.0:
		face_offset = Vector2(
			sin(float(Time.get_ticks_msec()) * 0.031 + float(_face_variant)),
			cos(float(Time.get_ticks_msec()) * 0.025 + float(_face_variant))
		) * 0.42

	self.ScreenGlow.color = SCREEN_GLOW_IDLE.lerp(SCREEN_GLOW_ACTIVE, dash_boost * 0.75 + attack_boost * 0.18 + flux_boost * 0.25 + pulse * 0.16)
	self.ScreenShell.color = SCREEN_SHELL_IDLE.lerp(SCREEN_SHELL_ACTIVE, dash_boost * 0.45 + flux_boost * 0.18)
	self.ScreenFrame.color = SCREEN_FRAME_IDLE.lerp(SCREEN_FRAME_ACTIVE, dash_boost * 0.55 + attack_boost * 0.20 + flux_boost * 0.18)
	self.ScreenTrim.color = SCREEN_TRIM_IDLE.lerp(SCREEN_TRIM_ACTIVE, dash_boost * 0.45 + flux_boost * 0.32 + pulse * 0.10)
	self.ScreenFill.color = SCREEN_FILL_IDLE.lerp(SCREEN_FILL_ACTIVE, dash_boost * 0.32 + flux_boost * 0.12 + pulse * 0.10)
	self.ScreenGlow.scale = Vector2.ONE * (SCREEN_GLOW_BASE_SCALE + pulse * 0.030 + dash_boost * 0.04 + flux_boost * 0.02)
	self.ScreenShell.scale = Vector2.ONE * (SCREEN_BASE_SCALE + pulse * 0.012)
	self.ScreenFrame.scale = Vector2.ONE * (SCREEN_BASE_SCALE + pulse * 0.010 + attack_boost * 0.008)
	self.ScreenTrim.scale = Vector2.ONE * (SCREEN_BASE_SCALE + pulse * 0.010 + flux_boost * 0.012)
	self.ScreenFill.scale = Vector2.ONE * (SCREEN_BASE_SCALE + attack_boost * 0.012 + dash_boost * 0.015 + flux_boost * 0.012)
	self.ScreenGlass.modulate = Color(0.96, 0.99, 1.0, 0.34 + pulse * 0.06 + attack_boost * 0.04)
	self.ScreenGlassSecondary.modulate = Color(0.90, 0.93, 0.98, 0.24 + pulse * 0.04)
	self.ScreenReflectionRight.modulate = Color(0.11, 0.12, 0.16, 0.38 + pulse * 0.04 + dash_boost * 0.03)
	self.ScreenShadow.modulate = Color(0.09, 0.10, 0.12, 0.20 + dash_boost * 0.03)
	self.ScreenGlass.scale = Vector2.ONE * (SCREEN_BASE_SCALE + pulse * 0.010)
	self.ScreenGlassSecondary.scale = Vector2.ONE * (SCREEN_BASE_SCALE + pulse * 0.010)
	self.ScreenReflectionRight.scale = Vector2.ONE * (SCREEN_BASE_SCALE + pulse * 0.010)
	self.ScreenShadow.scale = Vector2.ONE * (SCREEN_BASE_SCALE + pulse * 0.010)
	if self.ScreenReflectionCorner != null:
		self.ScreenReflectionCorner.modulate = Color(0.82, 0.85, 0.94, 0.18 + pulse * 0.04 + attack_boost * 0.03)
		self.ScreenReflectionCorner.scale = Vector2.ONE * (SCREEN_BASE_SCALE + pulse * 0.010)
	if self.ScreenReflectionSteps != null:
		self.ScreenReflectionSteps.modulate = Color(0.34, 0.36, 0.46, 0.24 + pulse * 0.04 + flux_boost * 0.04)
		self.ScreenReflectionSteps.scale = Vector2.ONE * (SCREEN_BASE_SCALE + pulse * 0.010)
	if self.ScreenScanlines != null:
		self.ScreenScanlines.scale = Vector2.ONE * (SCREEN_BASE_SCALE + pulse * 0.006)
		for stripe in self.ScreenScanlines.get_children():
			stripe.modulate = Color(0.56, 0.60, 0.66, 0.18 + pulse * 0.03)
	if self.ScreenSweepLines != null:
		self.ScreenSweepLines.scale = Vector2.ONE * (SCREEN_BASE_SCALE + pulse * 0.004)
		_update_screen_sweep_lines(pulse, dash_boost, attack_boost, flux_boost)
	if self.ScreenBlur != null:
		self.ScreenBlur.modulate = Color(0.66, 0.74, 0.96, 0.28 + pulse * 0.05 + dash_boost * 0.04 + attack_boost * 0.03)
		self.ScreenBlur.scale = Vector2.ONE * (SCREEN_BLUR_BASE_SCALE + pulse * 0.026 + dash_boost * 0.022)
	if self.ScreenFill.material is ShaderMaterial:
		var screen_material := self.ScreenFill.material as ShaderMaterial
		screen_material.set_shader_parameter("scan_speed", 0.36 + dash_boost * 0.11 + flux_boost * 0.06)
		screen_material.set_shader_parameter("line_density", 18.0 + pulse * 3.0 + attack_boost * 1.2)
		screen_material.set_shader_parameter("line_brightness", 0.035 + dash_boost * 0.02 + flux_boost * 0.03)
		screen_material.set_shader_parameter("pulse_speed", 0.24 + dash_boost * 0.08 + flux_boost * 0.12)
	self.FacePixels.position = face_offset

	var active_expression := "angry"
	if _face_override != "":
		active_expression = _face_override
	elif _glitch_timer > 0.0:
		active_expression = "glitch"

	_resolved_face_expression = active_expression
	_apply_face(active_expression)

func _apply_face(expression: StringName) -> void:
	var face_name := String(expression)
	if face_name == "scan":
		_render_scan_face()
		return
	if face_name == "glitch":
		_render_glitch_face()
		return

	var pixels: Array = _face_catalog.get(face_name, _face_catalog.get("calm", []))
	_reset_face_pixels()
	for i in range(min(pixels.size(), _face_pixel_pool.size())):
		var pixel_def: Array = pixels[i]
		_set_pixel(_face_pixel_pool[i], Vector2(pixel_def[0], pixel_def[1]), PIXEL_ALERT if face_name == "glitch" else PIXEL_IDLE)

func _reset_face_pixels() -> void:
	for pixel in _face_pixel_pool:
		pixel.visible = false
		pixel.color = PIXEL_IDLE
		pixel.position = Vector2.ZERO

func _set_pixel(pixel: Polygon2D, pixel_pos: Vector2, color: Color = PIXEL_IDLE) -> void:
	pixel.visible = true
	pixel.position = pixel_pos
	pixel.color = color

func _load_face_catalog() -> void:
	var raw_text := FileAccess.get_file_as_string(FACE_DATA_PATH)
	var parsed = JSON.parse_string(raw_text)
	if typeof(parsed) == TYPE_DICTIONARY and parsed.has("expressions"):
		_face_catalog = parsed["expressions"]
	else:
		push_warning("No se pudo cargar el catalogo de caritas desde %s" % FACE_DATA_PATH)
		_face_catalog = {"angry": [[-6, -5], [-5, -6], [-4, -5], [4, -5], [5, -6], [6, -5], [-5, -3], [-4, -3], [4, -3], [5, -3], [-3, 5], [-2, 4], [-1, 4], [0, 4], [1, 4], [2, 4], [3, 5]]}

func _build_face_pixel_pool() -> void:
	for child in self.FacePixels.get_children():
		child.queue_free()

	_face_pixel_pool.clear()
	for _i in range(FACE_PIXEL_POOL_SIZE):
		var pixel := Polygon2D.new()
		pixel.visible = false
		pixel.scale = Vector2.ONE * FACE_PIXEL_SCALE
		pixel.color = PIXEL_IDLE
		pixel.polygon = PackedVector2Array([
			Vector2(-0.5, -0.5),
			Vector2(0.5, -0.5),
			Vector2(0.5, 0.5),
			Vector2(-0.5, 0.5),
		])
		self.FacePixels.add_child(pixel)
		_face_pixel_pool.append(pixel)

func get_available_face_expressions() -> PackedStringArray:
	var names := PackedStringArray()
	for name in _face_catalog.keys():
		names.append(str(name))
	names.sort()
	return names

func set_face_expression(expression: StringName, duration: float = 0.0) -> void:
	var face_name := String(expression)
	if not _face_catalog.has(face_name):
		return

	_face_override = face_name
	_face_override_timer = maxf(duration, 0.0)
	_resolved_face_expression = face_name
	if duration <= 0.0:
		_face_override_timer = 9999.0
	if self.FacePixels != null:
		_apply_face(face_name)

func clear_face_expression_override() -> void:
	_face_override = ""
	_face_override_timer = 0.0

func get_current_face_expression() -> String:
	return _resolved_face_expression

func notify_enemy_eliminated() -> void:
	Ciclos = minf(Ciclos + CICLOS_KILL_REWARD, MAX_CICLOS)
	set_face_expression("happy", 4.0)

func get_ciclos() -> float:
	return Ciclos

func apply_slow(factor: float, duration: float) -> void:
	_slow_factor = maxf(factor, _slow_factor)
	_slow_timer = maxf(duration, _slow_timer)

func try_hackeo() -> bool:
	if Ciclos < HACKEO_COST:
		_show_hack_popup("ciclos.insuficientes()")
		return false

	var best_enemy: Node = null
	var best_dist := HACKEO_RANGE

	for enemy_node in get_tree().get_nodes_in_group("regulated_enemy"):
		if not is_instance_valid(enemy_node):
			continue
		var dist := global_position.distance_to(enemy_node.global_position)
		if dist > best_dist:
			continue
		var hc := enemy_node.get_node_or_null("health_comp")
		if hc == null:
			continue
		var hp_ratio := float(hc.get_health()) / float(hc.get_max_health())
		if hp_ratio > HACKEO_HEALTH_THRESHOLD:
			continue
		best_enemy = enemy_node
		best_dist = dist

	if best_enemy == null:
		_show_hack_popup("target.not_found(range=%.0f)" % HACKEO_RANGE)
		return false

	Ciclos = maxf(Ciclos - HACKEO_COST, 0.0)
	if best_enemy.has_method("trigger_hackeo"):
		best_enemy.trigger_hackeo()
	Ciclos = minf(Ciclos + HACKEO_CICLOS_REWARD, MAX_CICLOS)
	_show_hack_popup("restriccion.eliminada() +%.0fcy" % HACKEO_CICLOS_REWARD)
	set_face_expression("scan", 0.8)
	return true

func try_steal_attack() -> bool:
	var nearest_pickup: Node2D = null
	var nearest_distance := STEAL_RANGE

	for pickup in get_tree().get_nodes_in_group("enemy_attack_pickup"):
		if not pickup.has_method("try_steal"):
			continue
		var distance := global_position.distance_to(pickup.global_position)
		if distance > nearest_distance:
			continue
		nearest_distance = distance
		nearest_pickup = pickup

	if nearest_pickup == null:
		return false

	var profile: Dictionary = nearest_pickup.try_steal()
	if profile.is_empty():
		return false

	self.Weapon.equip_enemy_attack(profile)
	self.Weapon.apply_flux_swap_buff(WEAPON_SWAP_COOLDOWN_MULTIPLIER, WEAPON_SWAP_BUFF_DURATION)
	_weapon_swap_buff_timer = WEAPON_SWAP_BUFF_DURATION
	self.HealthComp.set_health(self.HealthComp.get_health() + _get_weapon_swap_heal_amount())
	_trigger_weapon_swap_feedback()
	set_face_expression("scan", WEAPON_SWAP_FACE_DURATION)
	_show_hack_popup("stealing.bind(enemy.attack,slot_a)")
	return true

func _get_weapon_swap_heal_amount() -> int:
	return maxi(1, int(round(float(self.HealthComp.get_max_health()) * WEAPON_SWAP_HEAL_RATIO)))

func _render_scan_face() -> void:
	_reset_face_pixels()
	var sweep := int(round(lerpf(-5.0, 5.0, fposmod(float(Time.get_ticks_msec()) * 0.0065, 1.0))))
	var pixel_index := 0
	for x in range(-6, 7):
		if pixel_index >= _face_pixel_pool.size():
			return
		_set_pixel(_face_pixel_pool[pixel_index], Vector2(x, sweep), PIXEL_ALERT)
		pixel_index += 1

func _render_glitch_face() -> void:
	var frames := ["glitch_angry_a", "glitch_angry_b", "glitch_angry_c"]
	var frame_name: String = frames[(int(Time.get_ticks_msec() / 70) + _face_variant) % frames.size()]
	var pixels: Array = _face_catalog.get(frame_name, _face_catalog.get("angry", []))
	_reset_face_pixels()
	for i in range(min(pixels.size(), _face_pixel_pool.size())):
		var pixel_def: Array = pixels[i]
		_set_pixel(_face_pixel_pool[i], Vector2(pixel_def[0], pixel_def[1]), PIXEL_ALERT)

func _build_hack_popup() -> void:
	_hack_popup_root = Node2D.new()
	_hack_popup_root.z_index = 16
	_hack_popup_root.visible = false
	add_child(_hack_popup_root)

	_hack_popup_bg = Polygon2D.new()
	_hack_popup_bg.color = Color(0.04, 0.08, 0.15, 0.0)
	_hack_popup_bg.polygon = PackedVector2Array([
		Vector2(-90, -12), Vector2(90, -12), Vector2(90, 12), Vector2(-90, 12),
	])
	_hack_popup_root.add_child(_hack_popup_bg)

	_hack_popup_label = Label.new()
	var label_settings := LabelSettings.new()
	label_settings.font_size = 13
	label_settings.font_color = Color(0.72, 1.0, 0.94, 1.0)
	_hack_popup_label.label_settings = label_settings
	_hack_popup_label.position = Vector2(-86, -11)
	_hack_popup_label.size = Vector2(172, 22)
	_hack_popup_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hack_popup_root.add_child(_hack_popup_label)

func _show_hack_popup(message: String) -> void:
	_hack_popup_message = message
	_hack_popup_timer = HACK_POPUP_DURATION
	_hack_popup_root.visible = true
	_hack_popup_root.position = Vector2(0, -36)
	_hack_popup_label.text = ""

func _update_hack_popup(delta: float) -> void:
	if _hack_popup_root == null:
		return
	if _hack_popup_timer <= 0.0:
		_hack_popup_root.visible = false
		return

	_hack_popup_timer = maxf(_hack_popup_timer - delta, 0.0)
	var reveal_ratio := 1.0 - (_hack_popup_timer / HACK_POPUP_DURATION)
	var reveal_chars := clampi(int(floor(reveal_ratio * float(_hack_popup_message.length() + 1))), 0, _hack_popup_message.length())
	var suffix := "_" if reveal_chars < _hack_popup_message.length() else ""
	_hack_popup_label.text = _hack_popup_message.substr(0, reveal_chars) + suffix
	_hack_popup_root.position = Vector2(0, -36 - reveal_ratio * 14.0)

	var fade_alpha := 1.0 if _hack_popup_timer > 0.18 else _hack_popup_timer / 0.18
	_hack_popup_bg.color = Color(0.04, 0.08, 0.15, 0.82 * fade_alpha)
	_hack_popup_label.modulate = Color(0.72, 1.0, 0.94, fade_alpha * (0.86 + sin(float(Time.get_ticks_msec()) * 0.024) * 0.14))

func _configure_tv_screen() -> void:
	self.ScreenGlow.polygon = PackedVector2Array([
		Vector2(-18, -13), Vector2(-14, -17), Vector2(14, -17), Vector2(18, -13),
		Vector2(18, 13), Vector2(14, 17), Vector2(-14, 17), Vector2(-18, 13),
	])
	self.ScreenShell.polygon = PackedVector2Array([
		Vector2(-16, -12), Vector2(-12, -16), Vector2(12, -16), Vector2(16, -12),
		Vector2(16, 12), Vector2(12, 16), Vector2(-12, 16), Vector2(-16, 12),
	])
	self.ScreenFrame.polygon = PackedVector2Array([
		Vector2(-15.0, -11.1), Vector2(-11.3, -14.8), Vector2(11.3, -14.8), Vector2(15.0, -11.1),
		Vector2(15.0, 11.1), Vector2(11.3, 14.8), Vector2(-11.3, 14.8), Vector2(-15.0, 11.1),
	])
	self.ScreenTrim.polygon = PackedVector2Array([
		Vector2(-14.5, -10.8), Vector2(-11.0, -14.3), Vector2(11.0, -14.3), Vector2(14.5, -10.8),
		Vector2(14.5, 10.8), Vector2(11.0, 14.3), Vector2(-11.0, 14.3), Vector2(-14.5, 10.8),
	])
	self.ScreenFill.polygon = PackedVector2Array([
		Vector2(-13.6, -9.9), Vector2(-12.4, -11.2), Vector2(-9.5, -12.6), Vector2(-2.8, -13.2),
		Vector2(7.1, -12.8), Vector2(10.0, -11.4), Vector2(11.7, -9.2), Vector2(12.5, -4.9),
		Vector2(12.5, 6.9), Vector2(11.4, 9.7), Vector2(9.0, 11.4), Vector2(5.0, 12.6),
		Vector2(-5.4, 12.6), Vector2(-9.2, 11.4), Vector2(-11.5, 9.2), Vector2(-12.5, 5.4),
		Vector2(-12.5, -4.9), Vector2(-11.7, -8.4),
	])
	self.ScreenGlass.polygon = PackedVector2Array([
		Vector2(-8.5, -7.5), Vector2(-6.6, -7.5), Vector2(-6.6, -4.0), Vector2(-7.7, -2.8),
		Vector2(-9.1, -3.6), Vector2(-9.1, -6.3),
	])
	self.ScreenGlassSecondary.polygon = PackedVector2Array([
		Vector2(-7.2, -0.4), Vector2(-5.4, -0.4), Vector2(-5.4, 1.6), Vector2(-7.2, 1.6),
	])
	self.ScreenReflectionRight.polygon = PackedVector2Array([
		Vector2(10.6, -9.1), Vector2(11.0, -9.1), Vector2(11.0, 7.1), Vector2(10.8, 7.8),
		Vector2(10.6, 8.8), Vector2(10.3, 8.8), Vector2(10.3, -8.2), Vector2(10.6, -8.5),
	])
	self.ScreenShadow.polygon = PackedVector2Array([
		Vector2(-9.2, 8.0), Vector2(3.8, 8.0), Vector2(5.5, 9.7), Vector2(-7.5, 9.7),
	])
	self.ScreenReflectionCorner = _ensure_polygon_node(
		"screen_reflection_corner",
		6,
		Color(0.82, 0.85, 0.94, 0.20),
		PackedVector2Array([
			Vector2(-8.2, -6.0), Vector2(-7.0, -6.0), Vector2(-7.0, -4.2), Vector2(-8.2, -4.2),
		])
	)
	self.ScreenReflectionSteps = _ensure_polygon_node(
		"screen_reflection_steps",
		6,
		Color(0.34, 0.36, 0.46, 0.24),
		PackedVector2Array([
			Vector2(2.9, 2.8), Vector2(4.5, 2.8), Vector2(4.5, 4.4), Vector2(6.0, 4.4),
			Vector2(6.0, 6.0), Vector2(7.6, 6.0), Vector2(7.6, 9.2), Vector2(6.0, 9.2),
			Vector2(6.0, 7.6), Vector2(4.5, 7.6), Vector2(4.5, 6.0), Vector2(2.9, 6.0),
		])
	)
	self.ScreenBlur = _ensure_polygon_node(
		"screen_blur",
		5,
		Color(0.60, 0.46, 0.88, 0.12),
		self.ScreenFill.polygon
	)
	_build_screen_scanlines()
	_build_screen_sweep_lines()
	self.FacePixels.z_index = 7
	self.ScreenFill.material = _create_scanline_material(0.36, 19.0, 0.06, 0.24, 0.14, 0.030, 0.22, 0.10, 30.0, 0.16)
	self.ScreenBlur.material = _create_scanline_material(0.49, 24.0, 0.14, 0.42, 0.22, 0.080, 0.58, 0.02, 40.0, 0.38)
	self.ScreenBlur.show_behind_parent = false

func _build_screen_scanlines() -> void:
	if self.ScreenScanlines == null:
		self.ScreenScanlines = get_node_or_null("screen_scanlines") as Node2D
	if self.ScreenScanlines == null:
		self.ScreenScanlines = Node2D.new()
		self.ScreenScanlines.name = "screen_scanlines"
		self.ScreenScanlines.z_index = 6
		add_child(self.ScreenScanlines)
	for child in self.ScreenScanlines.get_children():
		child.queue_free()
	for stripe_index in range(9):
		var stripe := Polygon2D.new()
		var y := -8.6 + float(stripe_index) * 2.0
		stripe.color = Color(0.48, 0.52, 0.58, 0.18 if stripe_index % 2 == 0 else 0.10)
		stripe.polygon = PackedVector2Array([
			Vector2(-11.1, y),
			Vector2(11.1, y),
			Vector2(11.1, y + 0.38),
			Vector2(-11.1, y + 0.38),
		])
		self.ScreenScanlines.add_child(stripe)

func _build_screen_sweep_lines() -> void:
	if self.ScreenSweepLines == null:
		self.ScreenSweepLines = get_node_or_null("screen_sweep_lines") as Node2D
	if self.ScreenSweepLines == null:
		self.ScreenSweepLines = Node2D.new()
		self.ScreenSweepLines.name = "screen_sweep_lines"
		self.ScreenSweepLines.z_index = 6
		add_child(self.ScreenSweepLines)
	for child in self.ScreenSweepLines.get_children():
		child.queue_free()
	_screen_sweep_pixels.clear()
	for _i in range(3):
		var sweep := Polygon2D.new()
		sweep.color = Color(0.76, 0.88, 1.0, 0.0)
		sweep.polygon = PackedVector2Array([
			Vector2(-12.8, -0.38),
			Vector2(12.8, -0.38),
			Vector2(12.8, 0.38),
			Vector2(-12.8, 0.38),
		])
		self.ScreenSweepLines.add_child(sweep)
		_screen_sweep_pixels.append(sweep)

func _update_screen_sweep_lines(pulse: float, dash_boost: float, attack_boost: float, flux_boost: float) -> void:
	if _screen_sweep_pixels.is_empty():
		return
	var t := float(Time.get_ticks_msec()) * 0.0011
	for i in range(_screen_sweep_pixels.size()):
		var sweep := _screen_sweep_pixels[i]
		var phase := fposmod(t + float(i) * 0.33, 1.0)
		var y := lerpf(-12.6, 12.6, phase)
		var alpha := sin(phase * PI) * (0.16 + pulse * 0.05 + attack_boost * 0.03 + flux_boost * 0.03)
		var width := 0.30 if i == 0 else 0.24
		sweep.position = Vector2(0.0, y)
		sweep.scale = Vector2.ONE * (1.0 + dash_boost * 0.03)
		sweep.color = Color(0.70, 0.82, 0.98, alpha)
		sweep.polygon = PackedVector2Array([
			Vector2(-12.8, -width),
			Vector2(12.8, -width),
			Vector2(12.8, width),
			Vector2(-12.8, width),
		])

func _configure_core_particles() -> void:
	self.BodyParticles.amount = 120
	self.BodyParticlesDark.amount = 33
	self.BodyParticlesBright.amount = 32
	self.TrailParticles.amount = 92
	self.BodyParticles.local_coords = false
	self.BodyParticlesDark.local_coords = false
	self.BodyParticlesBright.local_coords = false
	self.TrailParticles.local_coords = false
	self.BodyParticles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	self.BodyParticles.emission_rect_extents = Vector2(12.0, 12.0)
	self.BodyParticlesDark.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	self.BodyParticlesDark.emission_rect_extents = Vector2(10.0, 10.0)
	self.BodyParticlesBright.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	self.BodyParticlesBright.emission_rect_extents = Vector2(9.0, 9.0)
	self.BodyParticles.color = Color(0.10, 0.04, 0.48, 0.46)
	self.BodyParticlesBright.color = Color(0.48, 0.18, 0.98, 0.66)
	self.TrailParticles.color = Color(0.16, 0.06, 0.58, 0.60)
	self.BodyParticles.scale_amount_min = 1.6
	self.BodyParticles.scale_amount_max = 8.64
	self.BodyParticlesBright.scale_amount_min = 1.4
	self.BodyParticlesBright.scale_amount_max = 4.8
	self.BodyParticlesDark.scale_amount_min = 1.2
	self.BodyParticlesDark.scale_amount_max = 4.4
	self.TrailParticles.scale_amount_min = 1.8
	self.TrailParticles.scale_amount_max = 7.84

func _ensure_polygon_node(name: String, z_index_value: int, color_value: Color, polygon_points: PackedVector2Array) -> Polygon2D:
	var polygon_node := get_node_or_null(name) as Polygon2D
	if polygon_node == null:
		polygon_node = Polygon2D.new()
		polygon_node.name = name
		add_child(polygon_node)
	polygon_node.z_index = z_index_value
	polygon_node.color = color_value
	polygon_node.polygon = polygon_points
	return polygon_node

func _ensure_effect_container(name: String, z_index_value: int) -> Node2D:
	var node := get_node_or_null(name) as Node2D
	if node == null:
		node = Node2D.new()
		node.name = name
		add_child(node)
	node.z_index = z_index_value
	return node

func _rebuild_cross_layer(
	layer: Node2D,
	color_value: Color,
	positions: Array,
	arm_length: float,
	thickness: float
) -> void:
	for child in layer.get_children():
		child.queue_free()
	for pos in positions:
		var cross := Polygon2D.new()
		cross.color = color_value
		cross.polygon = _build_cross_polygon(arm_length, thickness)
		cross.position = pos
		layer.add_child(cross)

func _build_cross_polygon(arm_length: float, thickness: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(-thickness, -arm_length),
		Vector2(thickness, -arm_length),
		Vector2(thickness, -thickness),
		Vector2(arm_length, -thickness),
		Vector2(arm_length, thickness),
		Vector2(thickness, thickness),
		Vector2(thickness, arm_length),
		Vector2(-thickness, arm_length),
		Vector2(-thickness, thickness),
		Vector2(-arm_length, thickness),
		Vector2(-arm_length, -thickness),
		Vector2(-thickness, -thickness),
	])

func _create_scanline_material(
	scan_speed: float,
	line_density: float,
	line_brightness: float,
	pulse_speed: float,
	subpixel_strength: float,
	chroma_strength: float,
	blur_strength: float,
	shadow_strength: float,
	stripe_density: float,
	stripe_strength: float
) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = SCANLINE_SHADER
	material.set_shader_parameter("scan_speed", scan_speed)
	material.set_shader_parameter("line_density", line_density)
	material.set_shader_parameter("line_brightness", line_brightness)
	material.set_shader_parameter("pulse_speed", pulse_speed)
	material.set_shader_parameter("subpixel_strength", subpixel_strength)
	material.set_shader_parameter("chroma_strength", chroma_strength)
	material.set_shader_parameter("blur_strength", blur_strength)
	material.set_shader_parameter("shadow_strength", shadow_strength)
	material.set_shader_parameter("stripe_density", stripe_density)
	material.set_shader_parameter("stripe_strength", stripe_strength)
	return material

func _build_feedback_particles() -> void:
	self.StealBuffParticlesBack = _ensure_feedback_particles(
		"steal_buff_particles_back",
		0,
		Vector2(0, 10),
		24,
		false,
		true,
		Color(0.36, 0.88, 0.28, 0.46),
		Vector2(0, -0.28),
		150.0,
		16.0,
		40.0,
		Vector2(0, 16),
		1.8,
		3.6,
		0.84,
		0.55
	)
	self.StealBuffParticlesFront = _ensure_feedback_particles(
		"steal_buff_particles_front",
		8,
		Vector2(0, 12),
		16,
		false,
		true,
		Color(0.82, 1.0, 0.66, 0.70),
		Vector2(0, -0.22),
		160.0,
		20.0,
		48.0,
		Vector2(0, 18),
		1.8,
		3.2,
		0.72,
		0.62
	)
	self.HealParticles = _ensure_feedback_particles(
		"heal_particles",
		8,
		Vector2(0, 18),
		30,
		true,
		true,
		Color(0.46, 0.96, 0.28, 0.92),
		Vector2(0, -0.35),
		160.0,
		42.0,
		84.0,
		Vector2(0, 52),
		1.1,
		2.2,
		0.56,
		1.0
	)
	self.HealSparkParticles = _ensure_feedback_particles(
		"heal_spark_particles",
		9,
		Vector2(0, 14),
		18,
		true,
		true,
		Color(0.88, 1.0, 0.70, 0.92),
		Vector2(0, -0.25),
		150.0,
		58.0,
		102.0,
		Vector2(0, 34),
		0.8,
		1.6,
		0.48,
		1.0
	)
	_configure_heal_particles()
	_build_heal_crowns()

func _ensure_feedback_particles(
	name: String,
	z_index_value: int,
	offset: Vector2,
	amount: int,
	one_shot: bool,
	local_coords_value: bool,
	color_value: Color,
	direction_value: Vector2,
	spread_value: float,
	velocity_min: float,
	velocity_max: float,
	gravity_value: Vector2,
	scale_min: float,
	scale_max: float,
	lifetime_value: float,
	explosiveness_value: float
) -> CPUParticles2D:
	var particles := get_node_or_null(name) as CPUParticles2D
	if particles == null:
		particles = CPUParticles2D.new()
		particles.name = name
		add_child(particles)
	particles.z_index = z_index_value
	particles.position = offset
	particles.amount = amount
	particles.one_shot = one_shot
	particles.local_coords = local_coords_value
	particles.emitting = false
	particles.direction = direction_value
	particles.spread = spread_value
	particles.gravity = gravity_value
	particles.initial_velocity_min = velocity_min
	particles.initial_velocity_max = velocity_max
	particles.scale_amount_min = scale_min
	particles.scale_amount_max = scale_max
	particles.color = color_value
	particles.lifetime = lifetime_value
	particles.explosiveness = explosiveness_value
	particles.material = _create_scanline_material(1.8, 16.0, 0.12, 0.88, 0.05, 0.01, 0.06, 0.04, 20.0, 0.12)
	return particles

func _configure_heal_particles() -> void:
	if self.HealParticles != null:
		self.HealParticles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		self.HealParticles.emission_rect_extents = Vector2(18.0, 4.0)
		self.HealParticles.scale_amount_curve = null
		self.HealParticles.material = _create_scanline_material(1.9, 20.0, 0.16, 0.96, 0.04, 0.01, 0.10, 0.02, 28.0, 0.14)
	if self.HealSparkParticles != null:
		self.HealSparkParticles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		self.HealSparkParticles.emission_rect_extents = Vector2(16.0, 3.0)
		self.HealSparkParticles.scale_amount_curve = null
		self.HealSparkParticles.material = _create_scanline_material(2.4, 18.0, 0.18, 1.14, 0.04, 0.01, 0.08, 0.02, 24.0, 0.12)
	if self.StealBuffParticlesBack != null:
		self.StealBuffParticlesBack.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		self.StealBuffParticlesBack.emission_rect_extents = Vector2(20.0, 5.0)
		self.StealBuffParticlesBack.scale_amount_curve = null
	if self.StealBuffParticlesFront != null:
		self.StealBuffParticlesFront.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		self.StealBuffParticlesFront.emission_rect_extents = Vector2(18.0, 4.0)
		self.StealBuffParticlesFront.scale_amount_curve = null

func _build_heal_crowns() -> void:
	self.HealCrownBack = _ensure_effect_container("heal_crown_back", 7)
	self.HealCrownFront = _ensure_effect_container("heal_crown_front", 8)
	_rebuild_cross_layer(
		self.HealCrownBack,
		Color(0.42, 0.92, 0.28, 0.0),
		[
			Vector2(-13, 5), Vector2(-7, 10), Vector2(0, 12), Vector2(7, 10), Vector2(13, 5)
		],
		3.4,
		1.1
	)
	_rebuild_cross_layer(
		self.HealCrownFront,
		Color(0.82, 1.0, 0.66, 0.0),
		[
			Vector2(-9, 7), Vector2(0, 10), Vector2(9, 7)
		],
		2.8,
		0.9
	)
	self.HealCrownBack.visible = false
	self.HealCrownFront.visible = false

func _update_heal_feedback() -> void:
	var active := _heal_flash_timer > 0.0
	if self.HealCrownBack == null or self.HealCrownFront == null:
		return

	self.HealCrownBack.visible = active
	self.HealCrownFront.visible = active
	if not active:
		return

	var progress := 1.0 - (_heal_flash_timer / HEAL_FLASH_DURATION)
	var lift_back := lerpf(14.0, 8.0, progress)
	var lift_front := lerpf(12.0, 6.0, progress)
	var spread := 0.94 + progress * 0.18
	var fade := sin(progress * PI)
	self.HealCrownBack.position = Vector2(0, lift_back)
	self.HealCrownFront.position = Vector2(0, lift_front)
	self.HealCrownBack.scale = Vector2.ONE * (spread + sin(progress * PI) * 0.04)
	self.HealCrownFront.scale = Vector2.ONE * (0.92 + progress * 0.16)
	self.HealCrownBack.modulate = Color(0.44, 0.94, 0.30, 0.76 * fade)
	self.HealCrownFront.modulate = Color(0.86, 1.0, 0.70, 0.88 * fade)

func _update_flux_feedback(pulse: float, flux_boost: float, dash_boost: float) -> void:
	var buff_active := _weapon_swap_buff_timer > 0.0
	if self.StealBuffParticlesBack != null:
		if buff_active and not self.StealBuffParticlesBack.emitting:
			self.StealBuffParticlesBack.restart()
			self.StealBuffParticlesBack.emitting = true
		elif not buff_active and self.StealBuffParticlesBack.emitting:
			self.StealBuffParticlesBack.emitting = false
		self.StealBuffParticlesBack.color = Color(0.40, 0.92, 0.30, 0.34 + flux_boost * 0.34 + pulse * 0.08)
		self.StealBuffParticlesBack.initial_velocity_max = 42.0 + dash_boost * 10.0
	if self.StealBuffParticlesFront != null:
		if buff_active and not self.StealBuffParticlesFront.emitting:
			self.StealBuffParticlesFront.restart()
			self.StealBuffParticlesFront.emitting = true
		elif not buff_active and self.StealBuffParticlesFront.emitting:
			self.StealBuffParticlesFront.emitting = false
		self.StealBuffParticlesFront.color = Color(0.84, 1.0, 0.70, 0.38 + flux_boost * 0.42 + pulse * 0.10)
		self.StealBuffParticlesFront.initial_velocity_max = 48.0 + dash_boost * 12.0

func _trigger_weapon_swap_feedback() -> void:
	_heal_flash_timer = HEAL_FLASH_DURATION
	if self.StealBuffParticlesBack != null:
		self.StealBuffParticlesBack.restart()
		self.StealBuffParticlesBack.emitting = true
	if self.StealBuffParticlesFront != null:
		self.StealBuffParticlesFront.restart()
		self.StealBuffParticlesFront.emitting = true
	if self.HealParticles != null:
		self.HealParticles.emitting = false
		self.HealParticles.restart()
		self.HealParticles.emitting = true
	if self.HealSparkParticles != null:
		self.HealSparkParticles.emitting = false
		self.HealSparkParticles.restart()
		self.HealSparkParticles.emitting = true
