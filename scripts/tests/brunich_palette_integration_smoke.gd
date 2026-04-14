extends SceneTree

const PALETTE := preload("res://scenes/tests/Brunich/brunich_palette.gd")
const AI_CORE_WEAPON_SCENE := "res://scenes/tests/Brunich/enemy_ai_core_weapon.tscn"
const AI_BEAM_SCENE := "res://scenes/tests/Brunich/enemy_ai_beam.tscn"
const PIERCE_WEAPON_SCENE := "res://scenes/tests/Brunich/enemy_pierce_weapon.tscn"
const SPREAD_WEAPON_SCENE := "res://scenes/tests/Brunich/enemy_spread_weapon.tscn"
const PLAYER_WEAPON_SCENE := "res://scenes/tests/Brunich/weapon_one_shader.tscn"

var _failures: Array[String] = []
var _completed := false

func _initialize() -> void:
	print("START brunich_palette_integration_smoke")
	call_deferred("_arm_timeout")
	call_deferred("_run")

func _run() -> void:
	var world := Node2D.new()
	root.add_child(world)

	var ai_core_weapon: Node = load(AI_CORE_WEAPON_SCENE).instantiate()
	world.add_child(ai_core_weapon)
	await _wait_frames(1)
	var ai_beam_profile: Dictionary = ai_core_weapon._get_beam_profile()
	_expect(_same_color(ai_beam_profile.get("warning_color"), PALETTE.with_alpha(PALETTE.ACCENT_COLD_HOT, 0.52)), "el warning del beam AI debe usar el acento frio brillante de la paleta")
	_expect(_same_color(ai_beam_profile.get("beam_outer_color"), PALETTE.with_alpha(PALETTE.ENEMY_COLD_OUTER, 0.96)), "el halo exterior del beam AI debe usar el color frio principal de la paleta")
	_expect(_same_color(ai_beam_profile.get("beam_core_color"), PALETTE.with_alpha(PALETTE.ENEMY_COLD_CODE, 0.98)), "el nucleo del beam AI debe usar el tono claro de lectura de la paleta")
	_expect(_same_color(ai_beam_profile.get("endpoint_color"), PALETTE.with_alpha(PALETTE.ENEMY_COLD_CODE, 0.94)), "el endpoint del beam AI debe mantenerse en la misma familia de color")

	var beam_owner := Node2D.new()
	world.add_child(beam_owner)
	var ai_beam := load(AI_BEAM_SCENE).instantiate() as Node2D
	ai_beam.Owner = beam_owner
	world.add_child(ai_beam)
	ai_beam.configure_beam(ai_beam_profile)
	await _wait_frames(2)
	_expect(_same_color(ai_beam.BeamHalo.color, PALETTE.with_alpha(PALETTE.ACCENT_COLD, 0.20)), "el halo del beam AI debe caer en la paleta fria del bioma")
	_expect(_same_color(ai_beam.BeamGhost.color, PALETTE.with_alpha(PALETTE.ENEMY_COLD_OUTER, 0.28)), "el ghost del beam AI debe seguir la misma familia cromatica")
	_expect(_same_color(ai_beam.MuzzleGlow.color, PALETTE.with_alpha(PALETTE.ENEMY_COLD_CODE, 0.88)), "el muzzle glow del beam AI debe usar el blanco frio de la paleta")
	_expect(_same_color(ai_beam.MuzzleBurst.color, PALETTE.with_alpha(PALETTE.ACCENT_COLD_HOT, 0.68)), "el muzzle burst del beam AI debe usar el acento brillante del bioma")

	var pierce_weapon: Node = load(PIERCE_WEAPON_SCENE).instantiate()
	world.add_child(pierce_weapon)
	await _wait_frames(1)
	var pierce_profile: Dictionary = pierce_weapon._get_projectile_profile()
	_expect(_same_color(pierce_profile.get("outer_color"), PALETTE.with_alpha(PALETTE.ROOM_METAL_EDGE, 0.96)), "el sniper debe usar metal claro de la paleta para su silueta")
	_expect(_same_color(pierce_profile.get("core_color"), PALETTE.ROOM_PANEL_DARK), "el sniper debe usar un centro oscuro consistente con los paneles")
	_expect(_same_color(pierce_profile.get("code_color"), PALETTE.HUD_TEXT), "el sniper debe usar el color de lectura claro compartido")
	_expect(_same_color(pierce_profile.get("trail_color"), PALETTE.with_alpha(PALETTE.ROOM_METAL_SOFT, 0.65)), "la estela del sniper debe usar el metal suave de la paleta")

	var spread_weapon: Node = load(SPREAD_WEAPON_SCENE).instantiate()
	world.add_child(spread_weapon)
	await _wait_frames(1)
	var spread_profile: Dictionary = spread_weapon._get_projectile_profile()
	_expect(_same_color(spread_profile.get("outer_color"), PALETTE.with_alpha(PALETTE.ENEMY_WARM_OUTER, 0.92)), "la escopeta debe usar el acento calido definido en la paleta")
	_expect(_same_color(spread_profile.get("core_color"), PALETTE.ENEMY_WARM_CORE), "la escopeta debe usar un nucleo oscuro calido coherente")
	_expect(_same_color(spread_profile.get("code_color"), PALETTE.with_alpha(PALETTE.ENEMY_WARM_CODE, 0.96)), "la escopeta debe usar el color claro compartido para lectura interna")
	_expect(_same_color(spread_profile.get("trail_color"), PALETTE.with_alpha(PALETTE.ENEMY_WARM_OUTER, 0.55)), "la estela de la escopeta debe permanecer en la misma familia calida")

	var player_weapon: Node = load(PLAYER_WEAPON_SCENE).instantiate()
	world.add_child(player_weapon)
	await _wait_frames(1)
	player_weapon.equip_enemy_attack(ai_core_weapon.get_attack_profile_for_player())
	var stolen_beam_profile: Dictionary = player_weapon.get("_current_beam_profile")
	_expect(_same_color(stolen_beam_profile.get("warning_color"), PALETTE.with_alpha(PALETTE.ACCENT_THOUGHT_HOT, 0.42)), "el beam robado debe migrar al lenguaje morado del MC")
	_expect(_same_color(stolen_beam_profile.get("beam_outer_color"), Color8(243, 137, 245, 242)), "el beam robado debe usar el borde morado del MC")
	_expect(_same_color(stolen_beam_profile.get("beam_core_color"), Color8(249, 230, 207, 245)), "el beam robado debe usar el tono claro del MC")
	_expect(_same_color(stolen_beam_profile.get("endpoint_color"), Color8(249, 230, 207, 245)), "el endpoint del beam robado debe permanecer en la misma familia del MC")

	_completed = true
	if _failures.is_empty():
		print("PASS brunich_palette_integration_smoke")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)

func _arm_timeout() -> void:
	await create_timer(8.0).timeout
	if _completed:
		return
	push_error("brunich_palette_integration_smoke timeout")
	quit(2)

func _wait_frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _same_color(left_value: Variant, right_value: Variant) -> bool:
	if not left_value is Color or not right_value is Color:
		return false
	var left: Color = left_value
	var right: Color = right_value
	return is_equal_approx(left.r, right.r) and is_equal_approx(left.g, right.g) and is_equal_approx(left.b, right.b) and is_equal_approx(left.a, right.a)
