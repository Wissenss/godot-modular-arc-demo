extends SceneTree

const PLAYER_PROJECTILE_SCENE := "res://scenes/tests/Brunich/projectile_one_shader.tscn"
const ENEMY_PROJECTILE_SCENE := "res://scenes/tests/Brunich/enemy_projectile.tscn"

var _failures: Array[String] = []
var _completed := false

func _initialize() -> void:
	print("START brunich_combat_vfx_smoke")
	call_deferred("_arm_timeout")
	call_deferred("_run")

func _run() -> void:
	var world := Node2D.new()
	root.add_child(world)

	var player_projectile := load(PLAYER_PROJECTILE_SCENE).instantiate() as Node2D
	player_projectile.Owner = Node2D.new()
	world.add_child(player_projectile)
	await _wait_frames(2)
	player_projectile._handle_on_hurt(Area2D.new(), 1)
	await _wait_frames(2)
	_expect(_count_group("combat_vfx") > 0, "el proyectil del jugador debe generar un impacto visual al colisionar")

	var enemy_projectile := load(ENEMY_PROJECTILE_SCENE).instantiate() as Node2D
	enemy_projectile.Owner = Node2D.new()
	world.add_child(enemy_projectile)
	await _wait_frames(2)
	enemy_projectile._handle_on_hurt(Area2D.new(), 1)
	await _wait_frames(2)
	_expect(_count_group("combat_vfx") > 0, "el proyectil enemigo debe generar un impacto visual al colisionar")

	world.queue_free()
	await _wait_frames(1)
	_completed = true
	if _failures.is_empty():
		print("PASS brunich_combat_vfx_smoke")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)

func _count_group(group_name: String) -> int:
	var count := 0
	for node in root.get_tree().get_nodes_in_group(group_name):
		if is_instance_valid(node) and not node.is_queued_for_deletion():
			count += 1
	return count

func _arm_timeout() -> void:
	await create_timer(8.0).timeout
	if _completed:
		return
	push_error("brunich_combat_vfx_smoke timeout")
	quit(2)

func _wait_frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
