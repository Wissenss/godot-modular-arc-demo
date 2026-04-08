extends Node2D

const ENEMY_SCENE := preload("res://scenes/tests/Brunich/enemy_regulated.tscn")

@export var EnemyRespawnDelay := 0.45
@export var EnemySpawnPosition := Vector2(950, 324)

var DisableSceneReloadForTests := false
var RestartWasRequested := false

var _enemy_respawn_pending := false

func _ready() -> void:
	var player := get_node_or_null("MC")
	if player != null:
		_bind_player(player)

	var enemy := get_node_or_null("EnemyRegulated")
	if enemy != null:
		EnemySpawnPosition = enemy.position
		_bind_enemy(enemy)

func _bind_player(player: Node) -> void:
	if not player.HealthComp.on_died.is_connected(_handle_player_died):
		player.HealthComp.on_died.connect(_handle_player_died)

func _bind_enemy(enemy: Node) -> void:
	var on_enemy_died := Callable(self, "_handle_enemy_died")
	if not enemy.HealthComp.on_died.is_connected(on_enemy_died):
		enemy.HealthComp.on_died.connect(_handle_enemy_died)

func _handle_player_died() -> void:
	RestartWasRequested = true
	if DisableSceneReloadForTests:
		return

	call_deferred("_reload_scene")

func _reload_scene() -> void:
	get_tree().reload_current_scene()

func _handle_enemy_died() -> void:
	if _enemy_respawn_pending:
		return

	_enemy_respawn_pending = true
	_respawn_enemy.call_deferred()

func _respawn_enemy() -> void:
	await get_tree().create_timer(EnemyRespawnDelay).timeout

	var enemy := ENEMY_SCENE.instantiate()
	enemy.name = "EnemyRegulated"
	enemy.position = EnemySpawnPosition
	add_child(enemy)
	_bind_enemy(enemy)
	_enemy_respawn_pending = false
