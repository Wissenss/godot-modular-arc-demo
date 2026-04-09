extends Node2D

const ENEMY_SCENE := preload("res://scenes/tests/Brunich/enemy_regulated.tscn")

const ROOM_SIZE := Vector2(1280.0, 640.0)
const PLAYER_SPAWN := Vector2(180.0, 324.0)
const ENEMY_SPAWN := Vector2(950.0, 324.0)
const EXIT_LEFT := 17.0 * 32.0
const EXIT_RIGHT := 23.0 * 32.0
const EXIT_INTERACT_Y := 72.0
const EXIT_BLOCKER_SIZE := Vector2(192.0, 34.0)
const PROMPT_STEAL := "press E to steal :: bind.enemy.attack()"
const PROMPT_OPEN := "press E to open :: door.teleport()"
const PROMPT_LOCKED := "complete.room.to.finish()"
const ROOM_TRANSITION_LOCK := 0.45
const HUD_MARGIN := Vector2(18.0, 18.0)
const HUD_BAR_SIZE := Vector2(214.0, 16.0)
const HUD_BAR_GAP := 10.0
const HUD_FRAME_COLOR := Color(0.12, 0.09, 0.16, 0.94)
const HUD_BACK_COLOR := Color(0.03, 0.03, 0.05, 0.90)
const HUD_HEALTH_COLOR := Color(0.88, 0.16, 0.16, 0.96)
const HUD_MANA_COLOR := Color(0.06, 0.12, 0.32, 0.96)

var DisableSceneReloadForTests := false
var RestartWasRequested := false
var ExitUnlocked := false
var CurrentRoomIndex := 0
var CurrentPromptText := ""

var _player: Node2D = null
var _teleport_cooldown := 0.0
var _exit_blocker_collision: CollisionShape2D = null
var _prompt_root: Node2D = null
var _prompt_bg: Polygon2D = null
var _prompt_label: Label = null
var _hud_layer: CanvasLayer = null
var _hud_root: Control = null
var _health_fill: ColorRect = null
var _mana_fill: ColorRect = null
var _health_label: Label = null
var _mana_label: Label = null

func _ready() -> void:
	_player = get_node_or_null("MC") as Node2D
	if _player != null:
		_bind_player(_player)
		_configure_camera_limits(_player)
		_player.global_position = PLAYER_SPAWN

	_bind_existing_enemy()
	_build_exit_blocker()
	_build_command_prompt()
	_build_hud()
	_set_exit_unlocked(false)
	_update_hud_bars()

func _process(delta: float) -> void:
	_teleport_cooldown = maxf(_teleport_cooldown - delta, 0.0)
	_update_interaction_prompt()
	_update_hud_bars()
	if InputMap.has_action("steal") and Input.is_action_just_pressed("steal"):
		_try_context_action()

func _bind_player(player: Node) -> void:
	if not player.HealthComp.on_died.is_connected(_handle_player_died):
		player.HealthComp.on_died.connect(_handle_player_died)
	if not player.HealthComp.on_health_changed.is_connected(_handle_player_health_changed):
		player.HealthComp.on_health_changed.connect(_handle_player_health_changed)

func _bind_existing_enemy() -> void:
	var enemy := get_node_or_null("EnemyRegulated") as CharacterBody2D
	if enemy == null:
		enemy = _spawn_enemy_for_current_room()
	if enemy != null:
		_bind_enemy(enemy, CurrentRoomIndex)

func _bind_enemy(enemy: CharacterBody2D, room_index: int) -> void:
	enemy.name = "EnemyRegulated"
	enemy.position = ENEMY_SPAWN
	enemy.set_meta("room_index", room_index)
	var on_enemy_died := Callable(self, "_handle_enemy_died").bind(room_index)
	if not enemy.HealthComp.on_died.is_connected(on_enemy_died):
		enemy.HealthComp.on_died.connect(on_enemy_died)

func _handle_player_died() -> void:
	RestartWasRequested = true
	if DisableSceneReloadForTests:
		return
	call_deferred("_reload_scene")

func _reload_scene() -> void:
	get_tree().reload_current_scene()

func _handle_enemy_died(room_index: int) -> void:
	if room_index != CurrentRoomIndex:
		return
	if _player != null and _player.has_method("notify_enemy_eliminated"):
		_player.notify_enemy_eliminated()
	_set_exit_unlocked(true)

func _try_context_action() -> void:
	if _player == null:
		return

	var pickup := _get_nearest_pickup_in_range()
	if pickup != null and _player.has_method("try_steal_attack"):
		_player.try_steal_attack()
		return

	if not _is_player_near_exit():
		return

	if not _is_room_complete(CurrentRoomIndex):
		_set_prompt(PROMPT_LOCKED, _get_exit_prompt_position())
		return

	if ExitUnlocked and _teleport_cooldown <= 0.0:
		_advance_room()

func debug_try_context_action() -> void:
	_try_context_action()

func _advance_room() -> void:
	CurrentRoomIndex += 1
	_teleport_cooldown = ROOM_TRANSITION_LOCK
	_clear_room_pickups()
	_clear_active_enemy()
	_set_exit_unlocked(false)
	if _player != null:
		_player.global_position = PLAYER_SPAWN
	var enemy := _spawn_enemy_for_current_room()
	if enemy != null:
		_bind_enemy(enemy, CurrentRoomIndex)
	_clear_prompt()

func _spawn_enemy_for_current_room() -> CharacterBody2D:
	var enemy := ENEMY_SCENE.instantiate() as CharacterBody2D
	enemy.name = "EnemyRegulated"
	enemy.position = ENEMY_SPAWN
	add_child(enemy)
	return enemy

func _clear_active_enemy() -> void:
	var enemy := get_node_or_null("EnemyRegulated") as CharacterBody2D
	if enemy != null:
		enemy.queue_free()

func _clear_room_pickups() -> void:
	for pickup in get_tree().get_nodes_in_group("enemy_attack_pickup"):
		if is_instance_valid(pickup):
			pickup.queue_free()

func _is_player_near_exit() -> bool:
	if _player == null:
		return false
	if _player.global_position.x < EXIT_LEFT - 28.0 or _player.global_position.x > EXIT_RIGHT + 28.0:
		return false
	if _player.global_position.y > EXIT_INTERACT_Y:
		return false
	return true

func _is_room_complete(room_index: int) -> bool:
	return not _has_live_enemy_in_room(room_index)

func _has_live_enemy_in_room(room_index: int) -> bool:
	var enemy := get_node_or_null("EnemyRegulated") as CharacterBody2D
	if enemy == null:
		return false
	if enemy.is_queued_for_deletion():
		return false
	if not enemy.has_meta("room_index"):
		return false
	if int(enemy.get_meta("room_index")) != room_index:
		return false
	var health_comp = enemy.get_node_or_null("health_comp")
	return health_comp != null and health_comp.get_health() > 0

func _set_exit_unlocked(unlocked: bool) -> void:
	ExitUnlocked = unlocked
	if _exit_blocker_collision != null:
		_exit_blocker_collision.disabled = unlocked

func _build_exit_blocker() -> void:
	var blocker := StaticBody2D.new()
	blocker.name = "exit_blocker"
	blocker.position = Vector2((EXIT_LEFT + EXIT_RIGHT) * 0.5, -6.0)
	add_child(blocker)

	_exit_blocker_collision = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = EXIT_BLOCKER_SIZE
	_exit_blocker_collision.shape = shape
	blocker.add_child(_exit_blocker_collision)

func _configure_camera_limits(player: Node2D) -> void:
	var camera := player.get_node_or_null("camera") as Camera2D
	if camera == null:
		return
	camera.limit_left = 0
	camera.limit_right = int(ROOM_SIZE.x)
	camera.limit_top = 0
	camera.limit_bottom = int(ROOM_SIZE.y)

func _build_command_prompt() -> void:
	_prompt_root = Node2D.new()
	_prompt_root.name = "command_prompt"
	_prompt_root.z_index = 40
	_prompt_root.visible = false
	add_child(_prompt_root)

	_prompt_bg = Polygon2D.new()
	_prompt_bg.color = Color(0.04, 0.08, 0.15, 0.0)
	_prompt_bg.polygon = PackedVector2Array([
		Vector2(-122, -12), Vector2(122, -12), Vector2(122, 12), Vector2(-122, 12),
	])
	_prompt_root.add_child(_prompt_bg)

	_prompt_label = Label.new()
	var settings := LabelSettings.new()
	settings.font_size = 13
	settings.font_color = Color(0.72, 1.0, 0.94, 1.0)
	_prompt_label.label_settings = settings
	_prompt_label.position = Vector2(-116, -11)
	_prompt_label.size = Vector2(232, 22)
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_root.add_child(_prompt_label)

func _update_interaction_prompt() -> void:
	if _player == null:
		_clear_prompt()
		return

	var pickup := _get_nearest_pickup_in_range()
	if pickup != null:
		var prompt_pos: Vector2 = pickup.global_position + Vector2(0, -46)
		if pickup.has_method("get_prompt_position"):
			prompt_pos = pickup.get_prompt_position()
		_set_prompt(PROMPT_STEAL, prompt_pos)
		return

	if _is_player_near_exit():
		if _is_room_complete(CurrentRoomIndex) and ExitUnlocked:
			_set_prompt(PROMPT_OPEN, _get_exit_prompt_position())
		else:
			_set_prompt(PROMPT_LOCKED, _get_exit_prompt_position())
		return

	_clear_prompt()

func _get_nearest_pickup_in_range() -> Node2D:
	var nearest_pickup: Node2D = null
	var nearest_distance := INF
	for pickup in get_tree().get_nodes_in_group("enemy_attack_pickup"):
		if not is_instance_valid(pickup):
			continue
		if pickup.has_method("is_in_range") and not pickup.is_in_range(_player.global_position):
			continue
		var distance := _player.global_position.distance_to(pickup.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_pickup = pickup
	return nearest_pickup

func _get_exit_prompt_position() -> Vector2:
	return Vector2((EXIT_LEFT + EXIT_RIGHT) * 0.5, 38.0)

func _set_prompt(message: String, world_position: Vector2) -> void:
	CurrentPromptText = message
	if _prompt_root == null:
		return
	_prompt_root.visible = true
	_prompt_root.position = world_position + Vector2(0, sin(float(Time.get_ticks_msec()) * 0.010) * 2.0)
	var blink := "_" if int(Time.get_ticks_msec() / 220) % 2 == 0 else ""
	_prompt_label.text = "%s%s" % [message, blink]
	_prompt_bg.color = Color(0.04, 0.08, 0.15, 0.78 + sin(float(Time.get_ticks_msec()) * 0.018) * 0.04)
	_prompt_label.modulate = Color(0.72, 1.0, 0.94, 0.94)

func _clear_prompt() -> void:
	CurrentPromptText = ""
	if _prompt_root != null:
		_prompt_root.visible = false

func _build_hud() -> void:
	_hud_layer = CanvasLayer.new()
	_hud_layer.name = "hud_layer"
	_hud_layer.layer = 20
	add_child(_hud_layer)

	_hud_root = Control.new()
	_hud_root.name = "hud_root"
	_hud_root.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_hud_root.position = HUD_MARGIN
	_hud_layer.add_child(_hud_root)

	var health_bar := _create_hud_bar("HP", Vector2.ZERO, HUD_HEALTH_COLOR)
	_health_fill = health_bar["fill"] as ColorRect
	_health_label = health_bar["label"] as Label

	var mana_bar := _create_hud_bar("MN", Vector2(0.0, HUD_BAR_SIZE.y + HUD_BAR_GAP), HUD_MANA_COLOR)
	_mana_fill = mana_bar["fill"] as ColorRect
	_mana_label = mana_bar["label"] as Label

func _create_hud_bar(label_text: String, local_position: Vector2, fill_color: Color) -> Dictionary:
	var container := Control.new()
	container.name = "%s_bar" % label_text.to_lower()
	container.position = local_position
	container.custom_minimum_size = Vector2(HUD_BAR_SIZE.x + 36.0, HUD_BAR_SIZE.y + 2.0)
	_hud_root.add_child(container)

	var label := Label.new()
	label.name = "%s_label" % label_text.to_lower()
	var label_settings := LabelSettings.new()
	label_settings.font_size = 12
	label_settings.font_color = Color(0.90, 0.94, 1.0, 0.92)
	label.label_settings = label_settings
	label.text = label_text
	label.position = Vector2(0.0, -1.0)
	label.size = Vector2(28.0, HUD_BAR_SIZE.y + 2.0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	container.add_child(label)

	var frame := ColorRect.new()
	frame.name = "%s_frame" % label_text.to_lower()
	frame.color = HUD_FRAME_COLOR
	frame.position = Vector2(30.0, 0.0)
	frame.size = HUD_BAR_SIZE + Vector2(4.0, 4.0)
	container.add_child(frame)

	var background := ColorRect.new()
	background.name = "%s_bg" % label_text.to_lower()
	background.color = HUD_BACK_COLOR
	background.position = Vector2(32.0, 2.0)
	background.size = HUD_BAR_SIZE
	container.add_child(background)

	var fill := ColorRect.new()
	fill.name = "%s_fill" % label_text.to_lower()
	fill.color = fill_color
	fill.position = background.position
	fill.size = HUD_BAR_SIZE
	container.add_child(fill)

	return {
		"container": container,
		"frame": frame,
		"background": background,
		"fill": fill,
		"label": label,
	}

func _handle_player_health_changed(_health: int, _old_health: int) -> void:
	_update_hud_bars()

func _update_hud_bars() -> void:
	if _health_fill == null or _mana_fill == null:
		return

	var health_ratio := 1.0
	if _player != null and _player.HealthComp != null:
		var max_health := maxf(float(_player.HealthComp.get_max_health()), 1.0)
		health_ratio = clampf(float(_player.HealthComp.get_health()) / max_health, 0.0, 1.0)

	_health_fill.size.x = HUD_BAR_SIZE.x * health_ratio
	_health_fill.size.y = HUD_BAR_SIZE.y
	_mana_fill.size = HUD_BAR_SIZE
