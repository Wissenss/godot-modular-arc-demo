extends SceneTree

const PLAYER_SCENE_PATH := "res://scenes/tests/Brunich/test_character_shaders.tscn"
const PICKUP_SCRIPT := preload("res://scenes/tests/Brunich/enemy_attack_pickup.gd")

const ATTACK_SPECS := [
	{
		"weapon_scene": "res://scenes/tests/Brunich/enemy_weapon.tscn",
		"attack_id": "enemy_orb",
		"projectile_scene": "res://scenes/tests/Brunich/enemy_projectile.tscn",
		"projectile_count": 2,
		"wait_time": 0.30,
		"requires_pierce": false,
		"requires_slow": false,
	},
	{
		"weapon_scene": "res://scenes/tests/Brunich/enemy_spread_weapon.tscn",
		"attack_id": "enemy_spread",
		"projectile_scene": "res://scenes/tests/Brunich/enemy_spread_projectile.tscn",
		"projectile_count": 5,
		"wait_time": 0.08,
		"requires_pierce": false,
		"requires_slow": false,
	},
	{
		"weapon_scene": "res://scenes/tests/Brunich/enemy_pierce_weapon.tscn",
		"attack_id": "enemy_pierce",
		"projectile_scene": "res://scenes/tests/Brunich/enemy_pierce_projectile.tscn",
		"projectile_count": 1,
		"wait_time": 0.08,
		"requires_pierce": true,
		"requires_slow": false,
	},
	{
		"weapon_scene": "res://scenes/tests/Brunich/enemy_slowbeam_weapon.tscn",
		"attack_id": "enemy_slowbeam",
		"projectile_scene": "res://scenes/tests/Brunich/enemy_slowbeam_projectile.tscn",
		"projectile_count": 1,
		"wait_time": 0.08,
		"requires_pierce": false,
		"requires_slow": true,
	},
	{
		"weapon_scene": "res://scenes/tests/Brunich/enemy_ai_core_weapon.tscn",
		"attack_id": "enemy_ai_core_beam",
		"projectile_scene": "res://scenes/tests/Brunich/enemy_ai_beam.tscn",
		"projectile_count": 1,
		"wait_time": 0.60,
		"requires_pierce": false,
		"requires_slow": false,
		"requires_beam": true,
	},
]

var _failures: Array[String] = []
var _completed := false

func _initialize() -> void:
	print("START brunich_stolen_weapons_smoke")
	call_deferred("_arm_timeout")
	call_deferred("_run")

func _run() -> void:
	var world := Node2D.new()
	root.add_child(world)

	var player: Node2D = load(PLAYER_SCENE_PATH).instantiate() as Node2D
	world.add_child(player)
	await _wait_frames(2)
	var player_max_health: int = player.HealthComp.get_max_health()
	_expect(player_max_health == 200, "el MC debe arrancar con 200 de vida maxima")
	_expect(player.HealthComp.get_health() == 200, "el MC debe arrancar con toda su vida maxima nueva")

	for spec in ATTACK_SPECS:
		_clear_owned_enemy_projectiles(world, player)
		await _wait_frames(2)
		player.HealthComp.set_health(player_max_health - 80)

		var weapon: Node = load(String(spec.weapon_scene)).instantiate()
		var profile: Dictionary = weapon.get_attack_profile_for_player()
		weapon.queue_free()

		var pickup = PICKUP_SCRIPT.new()
		pickup.configure(player.global_position + Vector2(14.0, 0.0), profile)
		world.add_child(pickup)
		await _wait_frames(1)

		var stolen: bool = player.try_steal_attack()
		_expect(stolen, "el MC debe poder robar el ataque %s desde el pickup" % spec.attack_id)
		_expect(player.get_current_face_expression() == "scan", "al robar %s el MC debe entrar a scan" % spec.attack_id)
		_expect(float(player.get("_face_override_timer")) >= 5.9, "scan debe durar cerca de 6 segundos al cambiar al arma %s" % spec.attack_id)
		_expect(player.Weapon.get_current_attack_id() == String(spec.attack_id), "el arma robada debe conservar el id %s" % spec.attack_id)
		_expect(is_equal_approx(float(player.Weapon.get("_current_shoot_cooldown")), float(profile.get("shoot_cooldown", 0.0))), "al robar %s el cooldown real debe igualar la misma cadencia del enemigo" % spec.attack_id)
		_expect(player.HealthComp.get_health() == player_max_health - 30, "robar %s debe curar 25%% de la vida maxima del MC" % spec.attack_id)

		player.Weapon._shoot(Vector2.RIGHT)
		await _wait_seconds(float(spec.wait_time))

		if bool(spec.get("requires_beam", false)):
			var beams := _find_owned_enemy_beams(world, player)
			_expect(
				beams.size() == int(spec.projectile_count),
				"el arma %s debe disparar %d beam por accion, ahora salen %d" % [spec.attack_id, spec.projectile_count, beams.size()]
			)
			if not beams.is_empty():
				var beam := beams[0]
				_expect(beam.scene_file_path == String(spec.projectile_scene), "el arma %s debe usar su propia escena de beam" % spec.attack_id)
				var outer_beam := beam.get_node_or_null("beam_outer") as Polygon2D
				var core_beam := beam.get_node_or_null("beam_core") as Polygon2D
				if outer_beam != null:
					_expect(outer_beam.color.r > 0.48 and outer_beam.color.b > outer_beam.color.g, "el beam robado %s debe quedar morado" % spec.attack_id)
				if core_beam != null:
					_expect(core_beam.color.r > 0.70 and core_beam.color.b > core_beam.color.g, "el core del beam robado %s debe quedar morado" % spec.attack_id)
		else:
			var projectiles := _find_owned_enemy_projectiles(world, player)
			_expect(
				projectiles.size() == int(spec.projectile_count),
				"el arma %s debe disparar %d proyectiles por accion, ahora salen %d" % [spec.attack_id, spec.projectile_count, projectiles.size()]
			)

			for projectile in projectiles:
				_expect(projectile.scene_file_path == String(spec.projectile_scene), "el arma %s debe usar su propia escena de proyectil" % spec.attack_id)
				var outer_ring := projectile.get_node_or_null("outer_ring") as Polygon2D
				var trail_particles := projectile.get_node_or_null("trail_particles") as CPUParticles2D
				if outer_ring != null:
					_expect(outer_ring.color.r > 0.48 and outer_ring.color.b > outer_ring.color.g, "el proyectil robado %s debe quedar morado" % spec.attack_id)
				if trail_particles != null:
					_expect(trail_particles.color.r > 0.40 and trail_particles.color.b > trail_particles.color.g, "la estela robada %s debe quedar morada" % spec.attack_id)

			if bool(spec.requires_pierce) and not projectiles.is_empty():
				_expect(int(projectiles[0].get("_pierce_count")) < 0, "enemy_pierce robado debe atravesar todo sin agotarse")
			if bool(spec.requires_slow) and not projectiles.is_empty():
				_expect(float(projectiles[0].get("_slow_factor")) > 0.0, "enemy_slowbeam robado debe conservar el efecto de slow")

		player._update_screen_visual(6.1, false, false)
		_expect(player.get_current_face_expression() != "scan", "scan debe terminar despues del lapso completo del cambio de arma")

	_clear_owned_enemy_projectiles(world, player)
	world.queue_free()
	await _wait_frames(1)
	_completed = true
	if _failures.is_empty():
		print("PASS brunich_stolen_weapons_smoke")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)

func _arm_timeout() -> void:
	await create_timer(10.0).timeout
	if _completed:
		return
	push_error("brunich_stolen_weapons_smoke timeout")
	quit(2)

func _wait_frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _wait_seconds(duration: float) -> void:
	await create_timer(duration).timeout

func _find_owned_enemy_projectiles(world: Node, owner: Node) -> Array[Node2D]:
	var projectiles: Array[Node2D] = []
	for projectile in world.get_tree().get_nodes_in_group("enemy_projectile"):
		if projectile.Owner == owner:
			projectiles.append(projectile as Node2D)
	return projectiles

func _find_owned_enemy_beams(world: Node, owner: Node) -> Array[Node2D]:
	var beams: Array[Node2D] = []
	for beam in world.get_tree().get_nodes_in_group("enemy_ai_beam"):
		if beam.Owner == owner:
			beams.append(beam as Node2D)
	return beams

func _clear_owned_enemy_projectiles(world: Node, owner: Node) -> void:
	for projectile in _find_owned_enemy_projectiles(world, owner):
		projectile.queue_free()
	for beam in _find_owned_enemy_beams(world, owner):
		beam.queue_free()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
