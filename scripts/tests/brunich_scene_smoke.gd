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
	var camera := mc.get_node("camera") as Camera2D

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
	var mc_source := FileAccess.get_file_as_string("res://scenes/tests/Brunich/test_character_shaders.gd")
	_expect(shader_text.find("SCREEN_TEXTURE") == -1, "el glitch del MC no debe deformar el fondo con SCREEN_TEXTURE")
	_expect(not mc.has_node("core_polygon"), "el MC debe volver a su look anterior sin el rombo central nuevo")
	_expect(mc.has_node("screen_shell"), "el MC debe tener una carcasa de pantalla tipo TV")
	_expect(mc.has_node("screen_frame"), "el MC debe tener una pequena pantalla central")
	_expect(mc.has_node("screen_trim"), "el MC debe tener un bisel interno para que la pantalla se lea mejor")
	_expect(mc.has_node("screen_reflection_corner"), "la pantalla del MC debe tener reflejos pixelados tipo CRT")
	_expect(mc.has_node("screen_reflection_steps"), "la pantalla del MC debe tener bloques de reflejo escalonados")
	_expect(mc.has_node("screen_blur"), "la pantalla del MC debe tener una capa CRT de blur ligero")
	_expect(mc.has_node("screen_scanlines"), "la cara del MC debe tener rayas grises visibles de pantalla")
	_expect(mc.has_node("screen_sweep_lines"), "la pantalla del MC debe tener lineas de blur que barran de arriba a abajo")
	_expect(mc.has_node("face_pixels"), "el MC debe tener una cara pixel dentro de la pantalla")
	_expect((mc.get_node("screen_fill") as Polygon2D).polygon.size() > 4, "la pantalla del MC debe leerse mas como un CRT con esquinas trabajadas")
	_expect((mc.get_node("screen_fill") as Polygon2D).material != null, "la pantalla del MC debe usar un material para leerse mas como display")
	_expect((mc.get_node("screen_shell") as Polygon2D).scale.x < 0.82, "el cuadrado del MC debe bajar un poco de tamano respecto a la iteracion anterior")
	_expect((mc.get_node("screen_fill") as Polygon2D).scale.x < 0.95, "el display del MC debe sentirse mas pequeno que la version anterior")
	_expect((mc.get_node("screen_shell") as Polygon2D).scale.x >= 0.74, "el cuadrado del MC debe seguir viendose claro tras reducirse un poco")
	_expect(mc.has_method("get_available_face_expressions"), "el MC debe exponer el catalogo de caritas disponibles")
	_expect(mc.has_method("get_current_face_expression"), "el MC debe exponer la carita actual para debug")
	var screen_shader_text := FileAccess.get_file_as_string("res://scenes/tests/Brunich/scanline_shader.gdshader")
	_expect(screen_shader_text.find("subpixel_strength") != -1, "el shader CRT debe simular subpixeles para el blur de TV")
	_expect(screen_shader_text.find("chroma_strength") != -1, "el shader CRT debe tener una pequena separacion cromatica de pantalla")
	_expect(screen_shader_text.find("shadow_strength") != -1, "el shader CRT debe seguir moldeando la pantalla con sombreado")
	_expect(mc_source.find("Time.get_ticks_msec()) * 0.0011") != -1, "el barrido scan del MC debe ir claramente mas lento")
	_expect(mc_source.find("lerpf(-12.6, 12.6") != -1, "las rayas scan del MC deben recorrer desde arriba hasta abajo del display")
	_expect(InputMap.has_action("attack"), "debe existir una accion attack para el click izquierdo")
	_expect(InputMap.has_action("dash"), "debe existir una accion dash para espacio")
	_expect(InputMap.has_action("steal"), "debe existir una accion steal para robar ataques con E")
	_expect(mc.has_method("request_dash"), "el MC debe exponer una accion de dash reutilizable")
	_expect(mc.has_method("try_steal_attack"), "el MC debe poder intentar robar ataques cercanos")
	_expect(_has_property(world, "CurrentPromptText"), "Brunich debe exponer el prompt actual para depuracion")
	_expect(world.has_method("debug_try_context_action"), "Brunich debe exponer una interaccion de contexto para pruebas")
	_expect(mc.Weapon.SHOOT_COOLDOWN <= 0.1, "el arma del MC debe disparar muy rapido al mantener el click")
	_expect(is_equal_approx(mc.ConstantVelocityComp.Speed, 374.0), "la velocidad base del MC debe subir diez por ciento respecto a la iteracion anterior")
	_expect(camera.zoom.x <= 1.56 and camera.zoom.x >= 1.50, "la camara debe quedar aproximadamente 30 por ciento mas alejada")
	_expect(mc.BodyParticles.amount >= 250, "los cuadritos morados del MC deben aumentar de nuevo su generacion")
	_expect(mc.TrailParticles.amount >= 190, "la estela del MC tambien debe aumentar en densidad")
	_expect(mc.BodyParticles.scale_amount_max <= 12.5, "los cuadritos morados del MC deben verse claramente mas pequenos")
	_expect(mc.BodyParticlesBright.scale_amount_max <= 6.5, "las particulas brillantes del MC deben reducir su tamano")
	_expect(mc.BodyParticles.local_coords, "los cuadritos morados del cuerpo deben emitirse en coordenadas locales para rodear al MC")
	_expect(FileAccess.get_file_as_string("res://scripts/components/controller_comp.gd").find("Input.is_action_pressed(\"attack\")") != -1, "el ataque debe salir al mantener presionado el click izquierdo")
	_expect(load(PLAYER_PROJECTILE_PATH).instantiate().has_node("outline_polygon"), "el proyectil del MC debe tener un perimetro remarcado para leerse mejor")
	_expect(mc.get_current_face_expression() == "angry", "el MC debe mantener angry como expresion base")
	var sweep_lines := mc.get_node("screen_sweep_lines") as Node2D
	if sweep_lines != null and sweep_lines.get_child_count() > 0:
		var first_sweep := sweep_lines.get_child(0) as Polygon2D
		var min_x := INF
		var max_x := -INF
		for point in first_sweep.polygon:
			min_x = minf(min_x, point.x)
			max_x = maxf(max_x, point.x)
		_expect(min_x <= -12.0 and max_x >= 12.0, "las rayas scan deben ir de lado a lado del display")
	var pickup_source := FileAccess.get_file_as_string("res://scenes/tests/Brunich/enemy_attack_pickup.gd")
	_expect(pickup_source.find("const PICKUP_DURATION := 10.0") != -1, "el arma en el suelo debe poder robarse durante 10 segundos")

	var initial_player_health: int = mc.HealthComp.get_health()
	mc.Weapon._shoot(Vector2.RIGHT)
	await _wait_physics_frames(2)
	_expect(mc.HealthComp.get_health() == initial_player_health, "disparar no debe danar al MC con su propio proyectil")
	_expect(not mc.GlitchPolygon.visible, "disparar no debe activar el glitch de dano del MC")
	_expect(mc.get_available_face_expressions().size() >= 25, "el MC debe tener un catalogo amplio de caritas para diferentes situaciones")
	_assert_player_face_stays_stable_while_moving(mc)
	_assert_face_pixels_are_smaller(mc)
	await _assert_player_attack_cooldown(world, mc)
	await _assert_dash_system(mc)
	await _assert_enemy_dodges(world, mc, enemy)
	await _assert_room_progression_and_attack_steal(world, mc, enemy)
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

	var fake_hurtbox := HurtboxComponent.new()
	fake_hurtbox.Owner = mc.get_parent().get_node("EnemyRegulated")
	fake_hurtbox.Damage = 12
	mc._handle_on_hit(fake_hurtbox)
	_expect(mc.HealthComp.get_health() == 100, "el dash debe volver invencible al MC solo mientras dura la animacion")
	await _wait_physics_frames(14)
	mc._handle_on_hit(fake_hurtbox)
	_expect(mc.HealthComp.get_health() < 100, "al terminar el dash el MC ya no debe seguir invencible")
	fake_hurtbox.queue_free()

	await _wait_physics_frames(12)
	_expect(mc.DashCharges == 0, "las dos cargas no deben regresar demasiado pronto")
	await _wait_physics_frames(8)
	_expect(mc.DashCharges == 1, "la primera carga de dash debe recargarse antes que antes pero por separado")
	await _wait_physics_frames(16)
	_expect(mc.DashCharges == 2, "la segunda carga de dash debe terminar de recargarse claramente mas rapido que la configuracion anterior")

func _assert_player_face_stays_stable_while_moving(mc: Node2D) -> void:
	if not mc.has_node("face_pixels"):
		return

	mc._update_screen_visual(0.016, true, false)
	mc._update_visual_state(0.016, false)
	var face_pixels := mc.get_node("face_pixels") as Node2D
	_expect(face_pixels.position == Vector2.ZERO, "al moverse, la cara del MC debe mantenerse estable y no deformarse")
	_expect(mc.BodyParticles.emitting, "al moverse tambien deben seguir generandose cuadritos alrededor del MC")

func _assert_face_pixels_are_smaller(mc: Node2D) -> void:
	var face_pixels := mc.get_node("face_pixels") as Node2D
	if face_pixels.get_child_count() == 0:
		return
	var first_pixel := face_pixels.get_child(0) as Polygon2D
	_expect(first_pixel.scale.x >= 0.68 and first_pixel.scale.x <= 0.9, "los pixeles de las expresiones deben ser mas pequenos para permitir formas mas detalladas")
	_expect(face_pixels.scale.x >= 0.90 and face_pixels.scale.x <= 0.98, "la cara completa del MC debe crecer un poco para volver a notarse mejor")
	_expect(first_pixel.color.r >= 0.70 and absf(first_pixel.color.r - first_pixel.color.g) <= 0.08 and absf(first_pixel.color.g - first_pixel.color.b) <= 0.10, "las expresiones del MC deben pasar a gris claro")

func _assert_room_progression_and_attack_steal(world: Node, mc: Node2D, enemy: CharacterBody2D) -> void:
	mc.global_position = Vector2((17.0 * 32.0 + 23.0 * 32.0) * 0.5, 44.0)
	await _wait_frames(2)
	_expect(world.CurrentPromptText.find("complete.room.to.finish") != -1, "si el cuarto no esta completo, la puerta debe indicar que falta terminar la sala")
	world.debug_try_context_action()
	_expect(world.CurrentRoomIndex == 0, "no debe abrirse la puerta si quedan enemigos en el cuarto")

	mc.HealthComp.take_damage(20)
	var health_before_steal: int = mc.HealthComp.get_health()
	var initial_name := String(enemy.name)
	enemy.HealthComp.take_damage(9999)
	await _wait_physics_frames(1)
	_expect(mc.get_current_face_expression() == "happy", "al eliminar un enemigo el MC debe cambiar brevemente a happy")
	_expect(float(mc.get("_face_override_timer")) >= 3.8, "la expresion happy debe durar cerca de cuatro segundos tras matar un enemigo")
	mc._update_screen_visual(4.1, false, false)
	_expect(mc.get_current_face_expression() == "angry", "tras el lapso feliz el MC debe volver a angry")
	_expect(_has_property(world, "ExitUnlocked") and world.ExitUnlocked, "al matar al enemigo del primer cuarto se debe liberar la puerta superior")
	var pickups := world.get_tree().get_nodes_in_group("enemy_attack_pickup")
	_expect(not pickups.is_empty(), "al morir un enemigo debe quedar un arma robable en el suelo")
	if not pickups.is_empty():
		var pickup := pickups[0] as Node2D
		mc.global_position = pickup.global_position + Vector2(-10, 0)
		await _wait_frames(2)
		_expect(world.CurrentPromptText.find("press E to steal") != -1, "al acercarse a un enemigo caido debe aparecer el prompt de robar")
		var stole: bool = mc.try_steal_attack()
		_expect(stole, "el MC debe poder robar el ataque del enemigo con E cerca del pickup")
		_expect(mc.Weapon.get_current_attack_id() == "enemy_orb", "al robar el ataque el MC debe equipar el arma del enemigo")
		_expect(mc.get_current_face_expression() == "scan", "al robar el ataque el MC debe mostrar scan")
		_expect(mc.HealthComp.get_health() == health_before_steal + 5, "cambiar de arma debe recuperar cinco por ciento de vida")
		_expect(mc._hack_popup_message.find("stealing.bind") != -1, "el popup de robo debe usar un codigo corto de hackeo mas natural")
		_expect(float(mc.get("_weapon_swap_buff_timer")) >= 9.6, "cambiar de arma debe otorgar un buff de velocidad de diez segundos")
		await _wait_frames(1)
		mc._update_visual_state(0.016, false)
		_expect(is_equal_approx(mc.ConstantVelocityComp.Speed, 467.5), "el buff de cambio de arma debe dar 25 por ciento de velocidad adicional")
		_expect(mc.has_node("steal_buff_particles_back"), "el MC debe mostrar un buff visual al robar un ataque")
		_expect(mc.has_node("heal_particles"), "el MC debe mostrar una animacion de curacion al cambiar de arma")
		_expect((mc.get_node("steal_buff_particles_back") as CPUParticles2D).emitting, "el buff visual del robo debe permanecer activo varios segundos")
		_expect((mc.get_node("heal_particles") as CPUParticles2D).emitting, "la curacion debe disparar una animacion rapida dedicada")
		_expect((mc.get_node("heal_particles") as CPUParticles2D).color.g > (mc.get_node("heal_particles") as CPUParticles2D).color.r, "la animacion de cambio de arma debe pasar a un verde de curacion")
		mc.Weapon._shoot(Vector2.RIGHT)
		await _wait_physics_frames(1)
		var stolen_projectile := _find_projectile_owned_by(world, "enemy_projectile", mc)
		_expect(stolen_projectile != null, "el arma robada debe disparar una version del proyectil enemigo")
		if stolen_projectile != null:
			var outer_ring := stolen_projectile.get_node("outer_ring") as Polygon2D
			var trail_particles := stolen_projectile.get_node("trail_particles") as CPUParticles2D
			_expect(outer_ring.color.b > outer_ring.color.g and outer_ring.color.r > 0.35, "el proyectil robado debe diferenciarse con una circunferencia morada del MC")
			_expect(trail_particles.color.r > 0.45 and trail_particles.color.b > trail_particles.color.g, "todos los ataques robados deben mantener una estela morada del MC")
	await _wait_physics_frames(40)
	var replacement := world.get_node_or_null(NodePath(initial_name)) as CharacterBody2D
	_expect(replacement == null, "en el primer cuarto no debe reaparecer otro enemigo")
	mc.global_position = Vector2((17.0 * 32.0 + 23.0 * 32.0) * 0.5, 44.0)
	await _wait_frames(2)
	_expect(world.CurrentPromptText.find("press E to open") != -1, "al completar la sala y acercarse a la puerta debe aparecer el prompt para abrir")
	world.debug_try_context_action()
	await _wait_frames(2)
	_expect(_has_property(world, "CurrentRoomIndex") and world.CurrentRoomIndex == 1, "la puerta superior debe avanzar al siguiente cuarto solo al interactuar con E")
	_expect(mc.global_position.distance_to(Vector2(180.0, 324.0)) < 24.0, "al cambiar de cuarto el jugador debe reaparecer en el spawn del nuevo cuarto")
	_expect(world.get_node_or_null("floor_tiles_room_2") == null, "solo debe cargarse un cuarto a la vez para evitar mostrar el cuarto anterior")
	var room_2_enemy := world.get_node_or_null("EnemyRegulated") as CharacterBody2D
	_expect(room_2_enemy != null, "al llegar al siguiente cuarto debe existir un nuevo enemigo activo")
	_expect(room_2_enemy.global_position.y > 0.0, "el enemigo del nuevo cuarto no debe aparecer en el cuarto anterior")

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

func _find_projectile_owned_by(world: Node, group_name: StringName, owner: Node) -> Node2D:
	for node in world.get_tree().get_nodes_in_group(group_name):
		if node.Owner == owner:
			return node as Node2D
	return null

func _has_property(node: Object, property_name: String) -> bool:
	for prop in node.get_property_list():
		if prop.name == property_name:
			return true
	return false
