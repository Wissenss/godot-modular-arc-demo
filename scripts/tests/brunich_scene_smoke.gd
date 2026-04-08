extends SceneTree

const SCENE_PATH := "res://scenes/tests/Brunich/Brunich_tests.tscn"
const PLAYER_PROJECTILE_PATH := "res://scenes/tests/Brunich/projectile_one_shader.tscn"

var _failures: Array[String] = []
var _completed := false

func _initialize() -> void:
	print("START brunich_scene_smoke")
	call_deferred("_arm_timeout")
	call_deferred("_run")

func _run() -> void:
	print("STEP load_world")
	var world: Node = load(SCENE_PATH).instantiate()
	if _has_property(world, "DisableSceneReloadForTests"):
		world.DisableSceneReloadForTests = true
	root.add_child(world)

	await _wait_frames(2)

	var floor_tiles := world.get_node("floor_tiles") as TileMapLayer
	var mc: Node2D = world.get_node("MC") as Node2D
	var enemy: CharacterBody2D = world.get_node("EnemyRegulated") as CharacterBody2D
	var weapon: Node = enemy.get_node("enemy_weapon")

	_expect(floor_tiles != null, "floor_tiles debe existir")
	if floor_tiles != null and floor_tiles.tile_set != null:
		_expect(floor_tiles.tile_set.tile_size == Vector2i(32, 32), "el tileset de Brunich debe usar tiles de 32x32")
		_expect(floor_tiles.get_used_cells().size() >= 700, "el mapa debe tener suficiente densidad visual para una arena mas detallada")

	var top_open_cells := 0
	for x in range(17, 23):
		if floor_tiles.get_cell_source_id(Vector2i(x, 0)) == -1:
			top_open_cells += 1
	_expect(top_open_cells >= 3, "la parte superior debe tener una apertura clara para continuar al siguiente cuarto")

	_expect(enemy.HealthComp.get_max_health() >= 240, "el enemigo debe tener mucha mas vida que la version actual")
	_expect(weapon.ShootInterval <= 0.75, "el enemigo debe disparar mucho mas seguido")

	var shader_text := FileAccess.get_file_as_string("res://scenes/tests/Brunich/glitch_shader.gdshader")
	_expect(shader_text.find("SCREEN_TEXTURE") == -1, "el glitch del MC no debe deformar el fondo con SCREEN_TEXTURE")
	_expect(not mc.has_node("core_polygon"), "el MC debe volver a su look anterior sin el rombo central nuevo")
	_expect(InputMap.has_action("attack"), "debe existir una accion attack para el click izquierdo")
	_expect(InputMap.has_action("dash"), "debe existir una accion dash para espacio")
	_expect(mc.has_method("request_dash"), "el MC debe exponer una accion de dash reutilizable")
	_expect(mc.Weapon.SHOOT_COOLDOWN <= 0.1, "el arma del MC debe disparar muy rapido al mantener el click")
	_expect(FileAccess.get_file_as_string("res://scripts/components/controller_comp.gd").find("Input.is_action_pressed(\"attack\")") != -1, "el ataque debe salir al mantener presionado el click izquierdo")
	_expect(load(PLAYER_PROJECTILE_PATH).instantiate().has_node("outline_polygon"), "el proyectil del MC debe tener un perimetro remarcado para leerse mejor")

	var initial_player_health: int = mc.HealthComp.get_health()
	mc.Weapon._shoot(Vector2.RIGHT)
	await _wait_physics_frames(2)
	_expect(mc.HealthComp.get_health() == initial_player_health, "disparar no debe danar al MC con su propio proyectil")
	_expect(not mc.GlitchPolygon.visible, "disparar no debe activar el glitch de dano del MC")
	await _assert_player_attack_cooldown(world, mc)
	await _assert_dash_system(mc)
	await _assert_enemy_dodges(world, mc, enemy)
	await _assert_enemy_respawn(world, enemy)
	await _assert_player_restart_request(world, mc)

	_completed = true
	if _failures.is_empty():
		print("PASS brunich_scene_smoke")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)

func _arm_timeout() -> void:
	await create_timer(8.0).timeout
	if _completed:
		return

	push_error("brunich_scene_smoke timeout")
	quit(2)

func _assert_enemy_dodges(world: Node, mc: Node2D, enemy: Node2D) -> void:
	var projectile: Node2D = load(PLAYER_PROJECTILE_PATH).instantiate() as Node2D
	projectile.global_position = enemy.global_position + Vector2(-140, 0)
	projectile.Owner = mc
	world.add_child(projectile)
	projectile.HurtboxComp.Owner = mc
	projectile.ConstantVelocityComp.Speed = 420
	projectile.ConstantVelocityComp.Direction = Vector2.RIGHT

	var start_y := enemy.global_position.y
	await _wait_physics_frames(18)
	_expect(absf(enemy.global_position.y - start_y) > 6.0, "el enemigo debe esquivar proyectiles entrantes cambiando de carril")

func _assert_player_attack_cooldown(world: Node, mc: Node2D) -> void:
	await _wait_physics_frames(10)
	var before := _count_player_projectiles(world)
	mc.Weapon._shoot(Vector2.RIGHT)
	mc.Weapon._shoot(Vector2.RIGHT)
	await _wait_physics_frames(1)
	var delta := _count_player_projectiles(world) - before
	_expect(delta == 1, "el ataque del jugador debe estar limitado y no spammear proyectiles instantaneos")

	await _wait_physics_frames(8)
	var mid := _count_player_projectiles(world)
	mc.Weapon._shoot(Vector2.RIGHT)
	await _wait_physics_frames(1)
	_expect(_count_player_projectiles(world) - mid == 1, "el arma del MC debe poder encadenar disparos rapidos al sostener el click")

func _assert_dash_system(mc: Node2D) -> void:
	if not mc.has_method("request_dash"):
		return

	var start_pos: Vector2 = mc.global_position
	var first_dash: bool = mc.request_dash(Vector2.RIGHT)
	await _wait_physics_frames(1)
	var second_dash: bool = mc.request_dash(Vector2.RIGHT)
	await _wait_physics_frames(1)
	var third_dash: bool = mc.request_dash(Vector2.RIGHT)
	_expect(first_dash, "el primer dash debe funcionar")
	_expect(second_dash, "el segundo dash debe funcionar seguido")
	_expect(not third_dash, "el tercer dash consecutivo debe quedar bloqueado hasta recargar")
	_expect(mc.global_position.distance_to(start_pos) > 20.0, "el dash debe mover de forma visible al MC")

	await _wait_physics_frames(85)
	var recharged_dash: bool = mc.request_dash(Vector2.RIGHT)
	_expect(recharged_dash, "las cargas de dash deben recargarse con el tiempo")

func _assert_enemy_respawn(world: Node, enemy: CharacterBody2D) -> void:
	var initial_name := String(enemy.name)
	enemy.HealthComp.take_damage(9999)
	await _wait_physics_frames(40)
	var replacement := world.get_node_or_null(NodePath(initial_name)) as CharacterBody2D
	_expect(replacement != null, "al morir el enemigo debe reaparecer otro")
	_expect(replacement != enemy, "el enemigo reaparecido debe ser una nueva instancia")

func _assert_player_restart_request(world: Node, mc: Node2D) -> void:
	mc.HealthComp.take_damage(9999)
	await _wait_physics_frames(2)
	_expect(_has_property(world, "RestartWasRequested") and world.RestartWasRequested, "al morir el MC debe solicitar reinicio del juego")

func _wait_frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _wait_physics_frames(count: int) -> void:
	for _i in range(count):
		await physics_frame

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _count_player_projectiles(world: Node) -> int:
	return world.get_tree().get_nodes_in_group("player_projectile").size()

func _has_property(node: Object, property_name: String) -> bool:
	for prop in node.get_property_list():
		if prop.name == property_name:
			return true
	return false
