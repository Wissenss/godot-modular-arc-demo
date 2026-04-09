extends Node2D

## Enemy roster — escalates in quantity and variety as rooms advance.
const ENEMY_REGULATED_SCENE := preload("res://scenes/tests/Brunich/enemy_regulated.tscn")
const ENEMY_SPREAD_SCENE := preload("res://scenes/tests/Brunich/enemy_spread.tscn")
const ENEMY_PIERCE_SCENE := preload("res://scenes/tests/Brunich/enemy_pierce.tscn")
const ENEMY_SLOWBEAM_SCENE := preload("res://scenes/tests/Brunich/enemy_slowbeam.tscn")
const ENEMY_SCENES := [
	ENEMY_REGULATED_SCENE,
	ENEMY_SPREAD_SCENE,
	ENEMY_PIERCE_SCENE,
	ENEMY_SLOWBEAM_SCENE,
]
const BOSS_SCENE := ENEMY_SLOWBEAM_SCENE
const BIOME_ROOM_COUNT := 10
const BOSS_LAYOUT_IDS := [
	&"reactor_spine",
	&"split_bridge",
]
const LAYOUT_SPAWN_SLOTS := {
	&"classic": [
		Vector2(950.0, 324.0),
		Vector2(1030.0, 220.0),
		Vector2(1030.0, 428.0),
		Vector2(840.0, 220.0),
		Vector2(840.0, 428.0),
		Vector2(1090.0, 324.0),
	],
	&"rib_cage": [
		Vector2(760.0, 200.0),
		Vector2(760.0, 448.0),
		Vector2(892.0, 248.0),
		Vector2(892.0, 400.0),
		Vector2(1020.0, 152.0),
		Vector2(1020.0, 488.0),
	],
	&"split_bridge": [
		Vector2(704.0, 168.0),
		Vector2(704.0, 480.0),
		Vector2(608.0, 324.0),
		Vector2(940.0, 120.0),
		Vector2(940.0, 520.0),
		Vector2(760.0, 324.0),
	],
	&"reactor_spine": [
		Vector2(760.0, 200.0),
		Vector2(760.0, 448.0),
		Vector2(960.0, 200.0),
		Vector2(960.0, 448.0),
		Vector2(640.0, 324.0),
		Vector2(1080.0, 324.0),
	],
}

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
const HUD_MANA_COLOR := Color(0.06, 0.72, 0.94, 0.96)

var DisableSceneReloadForTests := false
var RestartWasRequested := false
var ExitUnlocked := false
var CurrentRoomIndex := 0
var CurrentBiomeIndex := 1
var CurrentBiomeRoomNumber := 1
var CurrentLayoutId: StringName = &"classic"
var IsBossRoom := false
var CurrentPromptText := ""

var _player: Node2D = null
var _floor_tiles: TileMapLayer = null
var _teleport_cooldown := 0.0
var _active_room_token := 0
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
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	_floor_tiles = get_node_or_null("floor_tiles") as TileMapLayer
	_player = get_node_or_null("MC") as Node2D
	if _player != null:
		_bind_player(_player)
		_configure_camera_limits(_player)
		_player.global_position = PLAYER_SPAWN

	_build_exit_blocker()
	_build_command_prompt()
	_build_hud()
	_enter_current_room(true)
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

func _bind_enemy(enemy: CharacterBody2D, room_index: int, room_token: int, enemy_index: int) -> void:
	enemy.name = "EnemyRegulated" if enemy_index == 0 else "EnemyRegulated_%d" % enemy_index
	enemy.set_meta("room_index", room_index)
	enemy.set_meta("room_token", room_token)
	enemy.set_meta("enemy_index", enemy_index)
	enemy.set_meta("enemy_type_id", String(enemy.scene_file_path.get_file()))
	var on_enemy_died := Callable(self, "_handle_enemy_died").bind(room_token)
	if not enemy.HealthComp.on_died.is_connected(on_enemy_died):
		enemy.HealthComp.on_died.connect(on_enemy_died)

func _handle_player_died() -> void:
	RestartWasRequested = true
	if DisableSceneReloadForTests:
		return
	call_deferred("_reload_scene")

func _reload_scene() -> void:
	get_tree().reload_current_scene()

func _handle_enemy_died(room_token: int) -> void:
	if room_token != _active_room_token:
		return
	call_deferred("_refresh_room_clear_state", room_token)

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
	if CurrentBiomeRoomNumber >= BIOME_ROOM_COUNT:
		CurrentBiomeIndex += 1
		CurrentBiomeRoomNumber = 1
	else:
		CurrentBiomeRoomNumber += 1
	_enter_current_room()

func get_active_room_enemy_count() -> int:
	return get_active_room_enemies().size()

func get_active_room_enemies() -> Array[CharacterBody2D]:
	var enemies: Array[CharacterBody2D] = []
	for node in get_tree().get_nodes_in_group("regulated_enemy"):
		if not (node is CharacterBody2D):
			continue
		var enemy := node as CharacterBody2D
		if enemy.get_parent() != self:
			continue
		if enemy.is_queued_for_deletion():
			continue
		if not enemy.has_meta("room_token"):
			continue
		if int(enemy.get_meta("room_token")) != _active_room_token:
			continue
		var health_comp = enemy.get_node_or_null("health_comp")
		if health_comp == null or health_comp.get_health() <= 0:
			continue
		enemies.append(enemy)
	return enemies

func debug_force_room_completion_for_tests() -> void:
	_clear_active_enemy()
	_set_exit_unlocked(true)
	_clear_prompt()

func debug_configure_progression_for_tests(biome_index: int, biome_room_number: int) -> void:
	CurrentBiomeIndex = maxi(1, biome_index)
	CurrentBiomeRoomNumber = clampi(biome_room_number, 1, BIOME_ROOM_COUNT)
	CurrentRoomIndex = (CurrentBiomeIndex - 1) * BIOME_ROOM_COUNT + (CurrentBiomeRoomNumber - 1)
	_enter_current_room(true)

func _enter_current_room(is_forced_refresh: bool = false) -> void:
	IsBossRoom = CurrentBiomeRoomNumber == BIOME_ROOM_COUNT
	_active_room_token += 1
	_teleport_cooldown = 0.0 if is_forced_refresh else ROOM_TRANSITION_LOCK
	_clear_room_pickups()
	_clear_active_enemy()
	_set_exit_unlocked(false)
	CurrentLayoutId = _choose_layout_id(is_forced_refresh)
	if _floor_tiles != null:
		_floor_tiles.set_layout_id(CurrentLayoutId)
	if _player != null:
		_player.global_position = PLAYER_SPAWN
	_spawn_enemy_wave_for_current_room()
	_clear_prompt()

func _choose_layout_id(is_forced_refresh: bool) -> StringName:
	if _floor_tiles == null:
		return &"classic"
	var available: Array[StringName] = _floor_tiles.get_layout_ids()
	if available.is_empty():
		return &"classic"
	if is_forced_refresh and CurrentBiomeIndex == 1 and CurrentBiomeRoomNumber == 1:
		return &"classic" if available.has(&"classic") else available[0]

	var candidates: Array[StringName] = []
	if IsBossRoom:
		for layout_id in BOSS_LAYOUT_IDS:
			if available.has(layout_id):
				candidates.append(layout_id)
	else:
		candidates = available.duplicate()

	if candidates.is_empty():
		candidates = available.duplicate()

	var filtered: Array[StringName] = []
	for layout_id in candidates:
		if layout_id != CurrentLayoutId:
			filtered.append(layout_id)
	if filtered.is_empty():
		filtered = candidates

	return filtered[_rng.randi_range(0, filtered.size() - 1)]

func _spawn_enemy_wave_for_current_room() -> void:
	var roster := _build_enemy_roster_for_current_room()
	var slots := _get_spawn_slots_for_layout(CurrentLayoutId)
	for enemy_index in range(roster.size()):
		var enemy_scene := roster[enemy_index]
		var enemy := enemy_scene.instantiate() as CharacterBody2D
		var slot_index := mini(enemy_index, slots.size() - 1)
		enemy.position = slots[slot_index]
		_apply_enemy_scaling(enemy, enemy_index)
		add_child(enemy)
		_bind_enemy(enemy, CurrentRoomIndex, _active_room_token, enemy_index)

func _build_enemy_roster_for_current_room() -> Array[PackedScene]:
	if IsBossRoom:
		return [BOSS_SCENE]

	var count := _get_regular_room_enemy_count()
	var pool := _get_enemy_pool_for_current_room()
	var roster: Array[PackedScene] = []
	var unique_pool: Array[PackedScene] = pool.duplicate()
	unique_pool.shuffle()
	for enemy_scene in unique_pool:
		if roster.size() >= count:
			break
		roster.append(enemy_scene)
	while roster.size() < count:
		roster.append(pool[_rng.randi_range(0, pool.size() - 1)])
	return roster

func _get_regular_room_enemy_count() -> int:
	var room_step := float(CurrentBiomeRoomNumber - 1)
	return clampi(1 + int(ceil(room_step * 0.5)) + (CurrentBiomeIndex - 1), 1, 6)

func _get_enemy_pool_for_current_room() -> Array[PackedScene]:
	if CurrentBiomeRoomNumber <= 1:
		return [ENEMY_REGULATED_SCENE]
	if CurrentBiomeRoomNumber <= 3:
		return [ENEMY_REGULATED_SCENE, ENEMY_SPREAD_SCENE]
	if CurrentBiomeRoomNumber <= 5:
		return [ENEMY_REGULATED_SCENE, ENEMY_SPREAD_SCENE, ENEMY_PIERCE_SCENE]
	return ENEMY_SCENES.duplicate()

func _get_spawn_slots_for_layout(layout_id: StringName) -> Array[Vector2]:
	var source_slots = LAYOUT_SPAWN_SLOTS[layout_id] if LAYOUT_SPAWN_SLOTS.has(layout_id) else LAYOUT_SPAWN_SLOTS[&"classic"]
	var slots: Array[Vector2] = []
	for slot in source_slots:
		slots.append(slot)
	return slots

func _apply_enemy_scaling(enemy: CharacterBody2D, enemy_index: int) -> void:
	var room_progress := float(CurrentBiomeRoomNumber - 1)
	var biome_progress := float(CurrentBiomeIndex - 1)
	var health_mult := 1.0 + room_progress * 0.18 + biome_progress * 0.24
	var speed_mult := 1.0 + room_progress * 0.025 + biome_progress * 0.04
	var fire_mult := clampf(1.0 - room_progress * 0.035 - biome_progress * 0.03, 0.58, 1.0)

	if IsBossRoom:
		health_mult *= 2.2
		speed_mult += 0.14
		fire_mult = minf(fire_mult, 0.72)
		enemy.scale = Vector2.ONE * 1.22
	else:
		health_mult *= 0.96 + float(enemy_index) * 0.06

	enemy.MaxHealth = maxi(int(round(float(enemy.MaxHealth) * health_mult)), enemy.MaxHealth)
	enemy.MoveSpeed *= speed_mult
	enemy.StrafeSpeed *= speed_mult
	enemy.DodgeSpeed *= 1.0 + room_progress * 0.03 + biome_progress * 0.04
	enemy.DodgeCooldown = maxf(enemy.DodgeCooldown * fire_mult, 0.32)
	enemy.ProjectileAlertRange += room_progress * 10.0

	var weapon: Node = null
	for child in enemy.get_children():
		if child.has_method("get_attack_profile_for_player"):
			weapon = child
			break
	if weapon != null and weapon.get("ShootInterval") != null:
		var minimum_interval := 0.34 if not IsBossRoom else 0.24
		weapon.ShootInterval = maxf(float(weapon.ShootInterval) * fire_mult, minimum_interval)

func _refresh_room_clear_state(room_token: int) -> void:
	if room_token != _active_room_token:
		return
	if get_active_room_enemy_count() == 0:
		_set_exit_unlocked(true)

func _clear_active_enemy() -> void:
	for node in get_tree().get_nodes_in_group("regulated_enemy"):
		if not (node is CharacterBody2D):
			continue
		var enemy := node as CharacterBody2D
		if enemy.get_parent() == self and is_instance_valid(enemy):
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
	if room_index != CurrentRoomIndex:
		return false
	return get_active_room_enemy_count() > 0

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

	var mana_bar := _create_hud_bar("CY", Vector2(0.0, HUD_BAR_SIZE.y + HUD_BAR_GAP), HUD_MANA_COLOR)
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

	var ciclos_ratio := 1.0
	if _player != null and _player.has_method("get_ciclos"):
		var max_cy := 100.0
		if _player.get("MAX_CICLOS") != null:
			max_cy = float(_player.MAX_CICLOS)
		ciclos_ratio = clampf(_player.get_ciclos() / max_cy, 0.0, 1.0)
	_mana_fill.size.x = HUD_BAR_SIZE.x * ciclos_ratio
	_mana_fill.size.y = HUD_BAR_SIZE.y
