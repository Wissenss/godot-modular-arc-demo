extends Node2D

## Enemy roster — escalates in quantity and variety as rooms advance.
const ENEMY_REGULATED_SCENE := preload("res://scenes/tests/Brunich/enemy_regulated.tscn")
const ENEMY_SPREAD_SCENE := preload("res://scenes/tests/Brunich/enemy_spread.tscn")
const ENEMY_PIERCE_SCENE := preload("res://scenes/tests/Brunich/enemy_pierce.tscn")
const ENEMY_SLOWBEAM_SCENE := preload("res://scenes/tests/Brunich/enemy_slowbeam.tscn")
const ENEMY_AI_CORE_SCENE := preload("res://scenes/tests/Brunich/enemy_ai_core.tscn")
const NARRATIVE_OVERLAY_SCRIPT := preload("res://scenes/tests/Brunich/narrative_overlay.gd")
const BRUNICH_PALETTE := preload("res://scenes/tests/Brunich/brunich_palette.gd")
const BRUNICH_VISUAL_STACK := preload("res://scenes/tests/Brunich/visual_stack/brunich_visual_stack.gd")
const ENDESGA64_PALETTE_PREVIEW_SHADER := preload("res://scenes/tests/Brunich/endesga64_palette_preview.gdshader")
const ENEMY_SCENES := [
	ENEMY_REGULATED_SCENE,
	ENEMY_SPREAD_SCENE,
	ENEMY_PIERCE_SCENE,
	ENEMY_AI_CORE_SCENE,
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
const PLAYER_SPAWN_LARGE := Vector2(900.0, 1620.0)
const ENEMY_SPAWN := Vector2(950.0, 324.0)
const EXIT_LEFT := 17.0 * 32.0
const EXIT_RIGHT := 23.0 * 32.0
const EXIT_INTERACT_Y := 72.0
const EXIT_BLOCKER_SIZE := Vector2(192.0, 34.0)

## Spawn slots para el cuarto grande 5× (megacore, 200×100 tiles = 6400×3200px)
const LAYOUT_SPAWN_SLOTS_LARGE := {
	&"megacore": [
		Vector2(3200.0, 1600.0),
		Vector2(1600.0, 900.0),
		Vector2(4800.0, 900.0),
		Vector2(1600.0, 2300.0),
		Vector2(4800.0, 2300.0),
		Vector2(800.0, 1600.0),
	],
}
const PROMPT_STEAL := "press E to steal :: bind.enemy.attack()"
const PROMPT_OPEN := "press E to open :: door.teleport()"
const PROMPT_LOCKED := "complete.room.to.finish()"
const ROOM_TRANSITION_LOCK := 0.45
const HUD_MARGIN := Vector2(18.0, 18.0)
const HUD_BAR_SIZE := Vector2(214.0, 16.0)
const HUD_BAR_GAP := 10.0
const HUD_FRAME_COLOR := Color8(42, 47, 78, 240)
const HUD_BACK_COLOR := Color8(27, 27, 27, 230)
const HUD_HEALTH_COLOR := Color8(234, 50, 60, 245)
const HUD_MANA_COLOR := Color8(0, 152, 220, 245)
const HUD_THOUGHT_COLOR := Color8(122, 9, 250, 245)
const HUD_TEXT_COLOR := Color8(249, 230, 207, 245)
const HUD_TEXT_OUTLINE := Color8(14, 7, 27, 250)
const HUD_BAR_LABEL_WIDTH := 28.0
const HUD_FRAME_OFFSET := Vector2(30.0, 0.0)
const HUD_BAR_INSET := Vector2(32.0, 2.0)
const HUD_VALUE_GAP := 10.0
const HUD_VALUE_WIDTH := 108.0
const HUD_VALUE_DIGITS := 3
const HUD_THOUGHT_BAR_SIZE := Vector2(128.0, 10.0)
const HUD_THOUGHT_VALUE_WIDTH := 102.0
const HUD_THOUGHT_MARGIN := Vector2(18.0, 18.0)
const HUD_THOUGHT_PANEL_HEIGHT := 22.0
const ROOM_CLI_PANEL_SIZE := Vector2(194.0, 28.0)
const ROOM_CLI_MARGIN := Vector2(18.0, 18.0)
const ROOM_CLI_PREFIX := "room::"
const ROOM_CLI_NUMBER_DIGITS := 2
const ROOM_CLI_ANIM_STEP := 0.042
const ROOM_CLI_CURSOR_PERIOD := 0.5
const PIXEL_FONT := preload("res://art/fonts/Silkscreen-Regular.ttf")
const ENDESGA64_PREVIEW_ENABLED := false
const ENDESGA64_PREVIEW_STRENGTH := 0.46
enum RoomCliAnimState {
	IDLE,
	ERASE,
	TYPE,
}

var DisableSceneReloadForTests := false
var RestartWasRequested := false
var ExitUnlocked := false
var CurrentRoomIndex := 0
var CurrentBiomeIndex := 1
var CurrentBiomeRoomNumber := 1

## Tamaño activo del cuarto (se actualiza al entrar a cada room)
var _active_room_size := ROOM_SIZE

var _narrative
var _biome_prev := 1
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
var _room_structure_root: Node2D = null
var _room_shadow_root: Node2D = null
var _room_light_root: Node2D = null
var _room_decor: Node2D = null
var _hud_layer: CanvasLayer = null
var _hud_root: Control = null
var _health_fill: ColorRect = null
var _mana_fill: ColorRect = null
var _health_label: Label = null
var _mana_label: Label = null
var _thought_label: Label = null
var _health_value_label: Label = null
var _mana_value_label: Label = null
var _thought_fill: ColorRect = null
var _thought_value_label: Label = null
var _room_cli: Control = null
var _room_cli_bg: ColorRect = null
var _room_cli_line: ColorRect = null
var _room_cli_label: Label = null
var _room_cli_cursor: ColorRect = null
var _palette_preview_overlay: ColorRect = null
var _visual_stack: Node2D = null
var _room_cli_text := ""
var _room_cli_target_text := ""
var _room_cli_anim_state: RoomCliAnimState = RoomCliAnimState.IDLE
var _room_cli_anim_timer := 0.0
var _room_cli_cursor_timer := 0.0
var _room_light_tracks: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()

func _get_save_manager() -> Node:
	return get_node_or_null("/root/SaveManager")

## ── Helpers de tamaño dinámico ───────────────────────────────────────────────

func _room_sz() -> Vector2:
	if _floor_tiles != null and _floor_tiles.has_method("get_room_pixel_size"):
		return _floor_tiles.get_room_pixel_size()
	return ROOM_SIZE

func _exit_l() -> float:
	if _floor_tiles != null and _floor_tiles.has_method("get_exit_start_px"):
		return _floor_tiles.get_exit_start_px()
	return EXIT_LEFT

func _exit_r() -> float:
	if _floor_tiles != null and _floor_tiles.has_method("get_exit_end_px"):
		return _floor_tiles.get_exit_end_px()
	return EXIT_RIGHT

## Actualiza el polígono del fondo void_bg para cubrir el cuarto activo
func _update_void_bg() -> void:
	var bg := get_node_or_null("void_bg") as Polygon2D
	if bg == null:
		return
	var sz := _active_room_size
	bg.polygon = PackedVector2Array([
		Vector2(-200.0, -200.0),
		Vector2(sz.x + 200.0, -200.0),
		Vector2(sz.x + 200.0, sz.y + 200.0),
		Vector2(-200.0, sz.y + 200.0),
	])

## Reconstruye el bloqueador de salida con posición dinámica
func _rebuild_exit_blocker() -> void:
	var old := get_node_or_null("exit_blocker")
	if old != null:
		old.get_parent().remove_child(old)
		old.free()
		_exit_blocker_collision = null
	_build_exit_blocker()

func _ensure_visual_stack() -> void:
	if _visual_stack != null:
		return
	_visual_stack = BRUNICH_VISUAL_STACK.new()
	add_child(_visual_stack)

func _refresh_visual_stack() -> void:
	if _visual_stack == null or _floor_tiles == null or not _visual_stack.has_method("rebuild_for_room"):
		return
	_visual_stack.rebuild_for_room(_player, _floor_tiles, _active_room_size, _exit_l(), _exit_r(), CurrentLayoutId)

func _ready() -> void:
	_rng.randomize()
	_floor_tiles = get_node_or_null("floor_tiles") as TileMapLayer
	_player = get_node_or_null("MC") as Node2D
	if _player != null:
		_bind_player(_player)
		_configure_camera_limits(_player)
		_player.global_position = PLAYER_SPAWN

	_build_room_art_layers()
	_build_exit_blocker()
	_build_command_prompt()
	_build_hud()
	_ensure_visual_stack()

	# Narrative overlay for in-run moments
	_narrative = NARRATIVE_OVERLAY_SCRIPT.new()
	add_child(_narrative)
	_biome_prev = CurrentBiomeIndex

	# Apply persistent upgrades from save slot
	_apply_upgrades_to_player()

	_enter_current_room(true)
	_update_hud_bars()

	# Biome 1 entry monologue
	_play_biome_entry_monologue(1, true)

func _process(delta: float) -> void:
	_teleport_cooldown = maxf(_teleport_cooldown - delta, 0.0)
	_update_room_art()
	_update_interaction_prompt()
	_update_room_cli(delta)
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
	var save_mgr := _get_save_manager()
	if save_mgr != null:
		save_mgr.update_biome_reached(CurrentBiomeIndex)
	call_deferred("_go_to_rest_zone")

func _go_to_rest_zone() -> void:
	get_tree().change_scene_to_file("res://scenes/tests/Brunich/rest_zone.tscn")

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
	var biome_changed := false
	if CurrentBiomeRoomNumber >= BIOME_ROOM_COUNT:
		CurrentBiomeIndex += 1
		CurrentBiomeRoomNumber = 1
		biome_changed = true
		var save_mgr := _get_save_manager()
		if save_mgr != null:
			save_mgr.update_biome_reached(CurrentBiomeIndex)
	else:
		CurrentBiomeRoomNumber += 1
	_enter_current_room()
	if biome_changed:
		_play_biome_transition(CurrentBiomeIndex)
	elif CurrentBiomeRoomNumber == BIOME_ROOM_COUNT:
		_play_boss_approach_monologue()

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

	# ── Dimensiones dinámicas: cuarto 2 es 5× más grande ──────────────────────
	if _floor_tiles != null:
		if CurrentBiomeRoomNumber == 2:
			_floor_tiles.set_dimensions(200, 100)
		else:
			_floor_tiles.reset_to_default_dimensions()
	_active_room_size = _room_sz()
	_update_void_bg()
	_rebuild_exit_blocker()
	if _player != null:
		_configure_camera_limits(_player)
	# ─────────────────────────────────────────────────────────────────────────

	CurrentLayoutId = _choose_layout_id(is_forced_refresh)
	if _floor_tiles != null:
		_floor_tiles.set_layout_id(CurrentLayoutId)
	_refresh_room_art_layers()

	var active_spawn := PLAYER_SPAWN_LARGE if CurrentBiomeRoomNumber == 2 else PLAYER_SPAWN
	if _player != null:
		_player.global_position = active_spawn
	_refresh_visual_stack()

	_spawn_enemy_wave_for_current_room()
	_update_room_cli_target(not is_forced_refresh)
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
		return [ENEMY_REGULATED_SCENE, ENEMY_SPREAD_SCENE, ENEMY_AI_CORE_SCENE]
	if CurrentBiomeRoomNumber <= 7:
		return [ENEMY_REGULATED_SCENE, ENEMY_SPREAD_SCENE, ENEMY_PIERCE_SCENE, ENEMY_AI_CORE_SCENE]
	return ENEMY_SCENES.duplicate()

func _get_spawn_slots_for_layout(layout_id: StringName) -> Array[Vector2]:
	var source_slots
	if LAYOUT_SPAWN_SLOTS_LARGE.has(layout_id):
		source_slots = LAYOUT_SPAWN_SLOTS_LARGE[layout_id]
	elif LAYOUT_SPAWN_SLOTS.has(layout_id):
		source_slots = LAYOUT_SPAWN_SLOTS[layout_id]
	else:
		source_slots = LAYOUT_SPAWN_SLOTS[&"classic"]
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
		if enemy.get("IsBossEnemy") != null:
			enemy.IsBossEnemy = true
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
		var base_interval := float(weapon.ShootInterval)
		var minimum_interval := minf(base_interval, 0.34 if not IsBossRoom else 0.24)
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
	var el := _exit_l()
	var er := _exit_r()
	if _player.global_position.x < el - 28.0 or _player.global_position.x > er + 28.0:
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
	var el := _exit_l()
	var er := _exit_r()
	var blocker := StaticBody2D.new()
	blocker.name = "exit_blocker"
	blocker.position = Vector2((el + er) * 0.5, -6.0)
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
	var sz := _active_room_size
	camera.limit_left   = 0
	camera.limit_right  = int(sz.x)
	camera.limit_top    = 0
	camera.limit_bottom = int(sz.y)

func _build_room_art_layers() -> void:
	_room_structure_root = Node2D.new()
	_room_structure_root.name = "room_structure_root"
	_room_structure_root.z_index = -7
	add_child(_room_structure_root)

	_room_shadow_root = Node2D.new()
	_room_shadow_root.name = "room_shadow_root"
	_room_shadow_root.z_index = -6
	add_child(_room_shadow_root)

	_room_light_root = Node2D.new()
	_room_light_root.name = "room_light_root"
	_room_light_root.z_index = -5
	add_child(_room_light_root)

	# Decoration layer (props, pipe overlays — uses its own z_indices internally)
	var decor_script := load("res://scenes/tests/Brunich/room_decor.gd")
	_room_decor = Node2D.new()
	_room_decor.name = "room_decor"
	_room_decor.set_script(decor_script)
	add_child(_room_decor)

func _refresh_room_art_layers() -> void:
	if _room_structure_root == null or _room_shadow_root == null or _room_light_root == null:
		return
	_clear_node_children(_room_structure_root)
	_clear_node_children(_room_shadow_root)
	_clear_node_children(_room_light_root)
	_room_light_tracks.clear()

	_build_room_structure_composition()
	_build_room_shadows()
	_build_room_guidance_lighting()
	_build_layout_specific_room_lighting(CurrentLayoutId)

	# Beta2 depth decoration
	if _room_decor != null and _room_decor.has_method("setup"):
		_room_decor.setup(CurrentLayoutId, _active_room_size, _exit_l(), _exit_r())

func _build_room_structure_composition() -> void:
	var rs := _active_room_size
	var el := _exit_l()
	var er := _exit_r()
	_add_room_polygon(
		_room_structure_root,
		"objective_frame_back",
		BRUNICH_PALETTE.with_alpha(BRUNICH_PALETTE.ROOM_METAL_BASE, 0.05),
		_make_world_rect(el - 54.0, 8.0, (er - el) + 108.0, 86.0)
	)
	_add_room_polygon(
		_room_structure_root,
		"center_stage_plate",
		BRUNICH_PALETTE.with_alpha(BRUNICH_PALETTE.ROOM_METAL_SOFT, 0.04),
		_make_diamond(Vector2(rs.x * 0.5, rs.y * 0.53), 236.0, 78.0)
	)
	_add_room_polygon(
		_room_structure_root,
		"left_service_band",
		BRUNICH_PALETTE.with_alpha(BRUNICH_PALETTE.ROOM_PANEL_DARK, 0.08),
		_make_world_rect(72.0, 132.0, 132.0, 304.0)
	)
	_add_room_polygon(
		_room_structure_root,
		"right_service_band",
		BRUNICH_PALETTE.with_alpha(BRUNICH_PALETTE.ROOM_PANEL_DARK, 0.08),
		_make_world_rect(rs.x - 204.0, 132.0, 132.0, 304.0)
	)

func _build_room_shadows() -> void:
	var rs := _active_room_size
	_add_room_polygon(
		_room_shadow_root,
		"top_shadow",
		BRUNICH_PALETTE.with_alpha(BRUNICH_PALETTE.ROOM_SHADOW, 0.22),
		_make_world_rect(0.0, 0.0, rs.x, 96.0)
	)
	_add_room_polygon(
		_room_shadow_root,
		"bottom_shadow",
		BRUNICH_PALETTE.with_alpha(BRUNICH_PALETTE.VOID_BG, 0.28),
		_make_world_rect(0.0, rs.y - 112.0, rs.x, 112.0)
	)
	_add_room_polygon(
		_room_shadow_root,
		"left_shadow",
		BRUNICH_PALETTE.with_alpha(BRUNICH_PALETTE.VOID_BG, 0.14),
		_make_world_rect(0.0, 112.0, 112.0, 388.0)
	)
	_add_room_polygon(
		_room_shadow_root,
		"right_shadow",
		BRUNICH_PALETTE.with_alpha(BRUNICH_PALETTE.VOID_BG, 0.14),
		_make_world_rect(rs.x - 112.0, 112.0, 112.0, 388.0)
	)

func _build_room_guidance_lighting() -> void:
	var rs := _active_room_size
	var exit_center := Vector2((_exit_l() + _exit_r()) * 0.5, 40.0)
	var center_focus := Vector2(rs.x * 0.5, rs.y * 0.53)
	var lower_focus := Vector2(rs.x * 0.5, rs.y - 116.0)

	_add_pulsing_light(
		"objective_beacon",
		BRUNICH_PALETTE.ACCENT_OBJECTIVE,
		_make_tapered_strip(exit_center, center_focus + Vector2(0.0, -96.0), 74.0, 182.0),
		0.96,
		0.04,
		0.12,
		0.05
	)
	_add_pulsing_light(
		"objective_gate_core",
		BRUNICH_PALETTE.ACCENT_OBJECTIVE_SOFT,
		_make_diamond(exit_center + Vector2(0.0, 6.0), 92.0, 24.0),
		1.42,
		0.10,
		0.20,
		0.04
	)
	_add_pulsing_light(
		"center_focus_glow",
		BRUNICH_PALETTE.ACCENT_COLD,
		_make_diamond(center_focus, 176.0, 62.0),
		0.88,
		0.03,
		0.08,
		0.04
	)
	_add_pulsing_light(
		"center_focus_core",
		BRUNICH_PALETTE.ACCENT_COLD_HOT,
		_make_diamond(center_focus, 74.0, 28.0),
		1.52,
		0.05,
		0.12,
		0.03
	)
	_add_pulsing_light(
		"guide_strip_left",
		BRUNICH_PALETTE.ACCENT_COLD,
		_make_tapered_strip(Vector2(232.0, rs.y - 108.0), lower_focus, 12.0, 34.0),
		0.80,
		0.03,
		0.09,
		0.03
	)
	_add_pulsing_light(
		"guide_strip_right",
		BRUNICH_PALETTE.ACCENT_COLD,
		_make_tapered_strip(Vector2(rs.x - 232.0, rs.y - 108.0), lower_focus, 12.0, 34.0),
		0.86,
		0.03,
		0.09,
		0.03
	)

func _build_layout_specific_room_lighting(layout_id: StringName) -> void:
	var rs := _active_room_size
	match layout_id:
		&"rib_cage":
			_add_side_bay_light(Vector2(186.0, rs.y * 0.5), Vector2(94.0, 272.0), 0.10)
			_add_side_bay_light(Vector2(rs.x - 186.0, rs.y * 0.5), Vector2(94.0, 272.0), 0.16)
		&"split_bridge":
			_add_side_bay_light(Vector2(324.0, rs.y * 0.5), Vector2(118.0, 236.0), 0.12)
			_add_side_bay_light(Vector2(rs.x - 324.0, rs.y * 0.5), Vector2(118.0, 236.0), 0.18)
		&"reactor_spine":
			_add_side_bay_light(Vector2(190.0, 176.0), Vector2(88.0, 98.0), 0.10)
			_add_side_bay_light(Vector2(rs.x - 190.0, 176.0), Vector2(88.0, 98.0), 0.14)
			_add_side_bay_light(Vector2(190.0, rs.y - 176.0), Vector2(88.0, 98.0), 0.18)
			_add_side_bay_light(Vector2(rs.x - 190.0, rs.y - 176.0), Vector2(88.0, 98.0), 0.22)
		&"megacore":
			# Luces de bahía escaladas 5× para el cuarto grande
			_add_side_bay_light(Vector2(870.0, rs.y * 0.5), Vector2(420.0, 540.0), 0.08)
			_add_side_bay_light(Vector2(rs.x - 870.0, rs.y * 0.5), Vector2(420.0, 540.0), 0.12)
			_add_side_bay_light(Vector2(870.0, rs.y * 0.25), Vector2(420.0, 420.0), 0.16)
			_add_side_bay_light(Vector2(rs.x - 870.0, rs.y * 0.25), Vector2(420.0, 420.0), 0.20)
			_add_side_bay_light(Vector2(870.0, rs.y * 0.75), Vector2(420.0, 420.0), 0.24)
			_add_side_bay_light(Vector2(rs.x - 870.0, rs.y * 0.75), Vector2(420.0, 420.0), 0.28)
		_:
			_add_side_bay_light(Vector2(174.0, 172.0), Vector2(84.0, 84.0), 0.08)
			_add_side_bay_light(Vector2(rs.x - 174.0, 172.0), Vector2(84.0, 84.0), 0.12)
			_add_side_bay_light(Vector2(174.0, rs.y - 172.0), Vector2(84.0, 84.0), 0.16)
			_add_side_bay_light(Vector2(rs.x - 174.0, rs.y - 172.0), Vector2(84.0, 84.0), 0.20)

func _add_side_bay_light(center: Vector2, size: Vector2, phase_offset: float) -> void:
	var light_name := "bay_light_%d_%d" % [int(center.x), int(center.y)]
	_add_pulsing_light(
		light_name,
		BRUNICH_PALETTE.ACCENT_COLD_DIM,
		_make_diamond(center, size.x, size.y),
		0.96 + phase_offset * 0.6,
		0.02,
		0.07,
		0.03,
		phase_offset
	)

func _update_room_art() -> void:
	if _room_light_tracks.is_empty():
		return
	var time := float(Time.get_ticks_msec()) * 0.001
	for track in _room_light_tracks:
		var poly := track.get("node") as Polygon2D
		if poly == null:
			continue
		var base_color := track.get("base_color", Color.WHITE) as Color
		var pulse_speed := float(track.get("pulse_speed", 1.0))
		var min_alpha := float(track.get("min_alpha", 0.06))
		var max_alpha := float(track.get("max_alpha", 0.16))
		var scale_pulse := float(track.get("scale_pulse", 0.06))
		var phase := float(track.get("phase", 0.0))
		var pulse := sin(time * pulse_speed + phase) * 0.5 + 0.5
		poly.color = BRUNICH_PALETTE.with_alpha(base_color, lerpf(min_alpha, max_alpha, pulse))
		poly.scale = Vector2.ONE * (1.0 + scale_pulse * pulse)

func _add_pulsing_light(
	name: String,
	base_color: Color,
	points: PackedVector2Array,
	pulse_speed: float,
	min_alpha: float,
	max_alpha: float,
	scale_pulse: float,
	phase: float = 0.0
) -> Polygon2D:
	var poly := _add_room_polygon(_room_light_root, name, BRUNICH_PALETTE.with_alpha(base_color, max_alpha), points, true)
	_room_light_tracks.append({
		"node": poly,
		"base_color": base_color,
		"pulse_speed": pulse_speed,
		"min_alpha": min_alpha,
		"max_alpha": max_alpha,
		"scale_pulse": scale_pulse,
		"phase": phase,
	})
	return poly

func _add_room_polygon(
	parent: Node2D,
	name: String,
	color_value: Color,
	points: PackedVector2Array,
	additive: bool = false
) -> Polygon2D:
	var poly := Polygon2D.new()
	poly.name = name
	poly.color = color_value
	poly.polygon = points
	if additive:
		var material := CanvasItemMaterial.new()
		material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		poly.material = material
	parent.add_child(poly)
	return poly

func _make_world_rect(left: float, top: float, width: float, height: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(left, top),
		Vector2(left + width, top),
		Vector2(left + width, top + height),
		Vector2(left, top + height),
	])

func _make_diamond(center: Vector2, width: float, height: float) -> PackedVector2Array:
	return PackedVector2Array([
		center + Vector2(0.0, -height * 0.5),
		center + Vector2(width * 0.5, 0.0),
		center + Vector2(0.0, height * 0.5),
		center + Vector2(-width * 0.5, 0.0),
	])

func _make_tapered_strip(start: Vector2, finish: Vector2, width_start: float, width_end: float) -> PackedVector2Array:
	var direction := (finish - start).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.UP
	var normal := direction.orthogonal()
	return PackedVector2Array([
		start + normal * width_start * 0.5,
		finish + normal * width_end * 0.5,
		finish - normal * width_end * 0.5,
		start - normal * width_start * 0.5,
	])

func _clear_node_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()

func _build_command_prompt() -> void:
	_prompt_root = Node2D.new()
	_prompt_root.name = "command_prompt"
	_prompt_root.z_index = 40
	_prompt_root.visible = false
	add_child(_prompt_root)

	_prompt_bg = Polygon2D.new()
	_prompt_bg.color = BRUNICH_PALETTE.with_alpha(BRUNICH_PALETTE.TERMINAL_BG, 0.0)
	_prompt_bg.polygon = PackedVector2Array([
		Vector2(-122, -12), Vector2(122, -12), Vector2(122, 12), Vector2(-122, 12),
	])
	_prompt_root.add_child(_prompt_bg)

	_prompt_label = Label.new()
	_prompt_label.label_settings = _create_terminal_label_settings(BRUNICH_PALETTE.TERMINAL_TEXT, 13, 1)
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
	return Vector2((_exit_l() + _exit_r()) * 0.5, 38.0)

func _set_prompt(message: String, world_position: Vector2) -> void:
	CurrentPromptText = message
	if _prompt_root == null:
		return
	_prompt_root.visible = true
	_prompt_root.position = world_position + Vector2(0, sin(float(Time.get_ticks_msec()) * 0.010) * 2.0)
	var blink := "_" if int(Time.get_ticks_msec() / 220) % 2 == 0 else ""
	_prompt_label.text = "%s%s" % [message, blink]
	_prompt_bg.color = BRUNICH_PALETTE.with_alpha(BRUNICH_PALETTE.TERMINAL_BG, 0.76 + sin(float(Time.get_ticks_msec()) * 0.018) * 0.05)
	_prompt_label.modulate = BRUNICH_PALETTE.with_alpha(BRUNICH_PALETTE.TERMINAL_TEXT, 0.94)

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
	_hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_layer.add_child(_hud_root)

	var health_bar := _create_hud_bar("HP", HUD_MARGIN, HUD_HEALTH_COLOR)
	_health_fill = health_bar["fill"] as ColorRect
	_health_label = health_bar["label"] as Label
	_health_value_label = health_bar["value_label"] as Label

	var mana_bar := _create_hud_bar("CY", HUD_MARGIN + Vector2(0.0, HUD_BAR_SIZE.y + HUD_BAR_GAP), HUD_MANA_COLOR)
	_mana_fill = mana_bar["fill"] as ColorRect
	_mana_label = mana_bar["label"] as Label
	_mana_value_label = mana_bar["value_label"] as Label

	var thought_bar := _create_thought_hud_bar()
	_thought_fill = thought_bar["fill"] as ColorRect
	_thought_label = thought_bar["label"] as Label
	_thought_value_label = thought_bar["value_label"] as Label
	_build_room_cli()
	_build_palette_preview_overlay()

func _build_palette_preview_overlay() -> void:
	if _hud_root == null:
		return

	_palette_preview_overlay = ColorRect.new()
	_palette_preview_overlay.name = "endesga64_palette_preview"
	_palette_preview_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_palette_preview_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_palette_preview_overlay.color = Color(1.0, 1.0, 1.0, 1.0)

	var preview_material := ShaderMaterial.new()
	preview_material.shader = ENDESGA64_PALETTE_PREVIEW_SHADER
	preview_material.set_shader_parameter("preview_strength", ENDESGA64_PREVIEW_STRENGTH)
	_palette_preview_overlay.material = preview_material
	_palette_preview_overlay.visible = ENDESGA64_PREVIEW_ENABLED
	_hud_root.add_child(_palette_preview_overlay)

func set_palette_preview_enabled(enabled: bool) -> void:
	if _palette_preview_overlay == null:
		return
	_palette_preview_overlay.visible = enabled

func set_palette_preview_strength(strength: float) -> void:
	if _palette_preview_overlay == null:
		return
	var shader_material := _palette_preview_overlay.material as ShaderMaterial
	if shader_material == null:
		return
	shader_material.set_shader_parameter("preview_strength", clampf(strength, 0.0, 1.0))

func debug_is_palette_preview_enabled() -> bool:
	return _palette_preview_overlay != null and _palette_preview_overlay.visible

func _create_hud_bar(label_text: String, local_position: Vector2, fill_color: Color) -> Dictionary:
	var container := Control.new()
	container.name = "%s_bar" % label_text.to_lower()
	container.position = local_position
	container.custom_minimum_size = Vector2(HUD_BAR_INSET.x + HUD_BAR_SIZE.x + HUD_VALUE_GAP + HUD_VALUE_WIDTH, HUD_BAR_SIZE.y + 2.0)
	_hud_root.add_child(container)

	var label := Label.new()
	label.name = "%s_label" % label_text.to_lower()
	label.label_settings = _create_terminal_label_settings(HUD_TEXT_COLOR, 13, 1)
	label.text = label_text
	label.position = Vector2(0.0, -2.0)
	label.size = Vector2(HUD_BAR_LABEL_WIDTH, HUD_BAR_SIZE.y + 2.0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	container.add_child(label)

	var frame := ColorRect.new()
	frame.name = "%s_frame" % label_text.to_lower()
	frame.color = HUD_FRAME_COLOR
	frame.position = HUD_FRAME_OFFSET
	frame.size = HUD_BAR_SIZE + Vector2(4.0, 4.0)
	container.add_child(frame)

	var background := ColorRect.new()
	background.name = "%s_bg" % label_text.to_lower()
	background.color = HUD_BACK_COLOR
	background.position = HUD_BAR_INSET
	background.size = HUD_BAR_SIZE
	container.add_child(background)

	var fill := ColorRect.new()
	fill.name = "%s_fill" % label_text.to_lower()
	fill.color = fill_color
	fill.position = background.position
	fill.size = HUD_BAR_SIZE
	container.add_child(fill)

	var value_label := Label.new()
	value_label.name = "%s_value" % label_text.to_lower()
	value_label.label_settings = _create_terminal_label_settings(HUD_TEXT_COLOR, 13, 1)
	value_label.position = Vector2(background.position.x + HUD_BAR_SIZE.x + HUD_VALUE_GAP, -2.0)
	value_label.size = Vector2(HUD_VALUE_WIDTH, HUD_BAR_SIZE.y + 2.0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	container.add_child(value_label)

	return {
		"container": container,
		"frame": frame,
		"background": background,
		"fill": fill,
		"label": label,
		"value_label": value_label,
	}

func _create_thought_hud_bar() -> Dictionary:
	var container := Control.new()
	container.name = "at_bar"
	container.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	container.anchor_left = 1.0
	container.anchor_right = 1.0
	container.anchor_top = 1.0
	container.anchor_bottom = 1.0
	container.offset_left = -(HUD_THOUGHT_BAR_SIZE.x + HUD_THOUGHT_VALUE_WIDTH + 44.0 + HUD_THOUGHT_MARGIN.x)
	container.offset_right = -HUD_THOUGHT_MARGIN.x
	container.offset_top = -(HUD_THOUGHT_PANEL_HEIGHT + HUD_THOUGHT_MARGIN.y)
	container.offset_bottom = -HUD_THOUGHT_MARGIN.y
	container.custom_minimum_size = Vector2(HUD_THOUGHT_BAR_SIZE.x + HUD_THOUGHT_VALUE_WIDTH + 44.0, HUD_THOUGHT_PANEL_HEIGHT)
	_hud_root.add_child(container)

	var label := Label.new()
	label.name = "at_label"
	label.label_settings = _create_terminal_label_settings(HUD_THOUGHT_COLOR, 12, 1)
	label.text = "AT"
	label.position = Vector2(0.0, -2.0)
	label.size = Vector2(24.0, HUD_THOUGHT_PANEL_HEIGHT)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	container.add_child(label)

	var frame := ColorRect.new()
	frame.name = "at_frame"
	frame.color = BRUNICH_PALETTE.with_alpha(BRUNICH_PALETTE.HUD_FRAME, 0.94)
	frame.position = Vector2(26.0, 3.0)
	frame.size = HUD_THOUGHT_BAR_SIZE + Vector2(4.0, 4.0)
	container.add_child(frame)

	var background := ColorRect.new()
	background.name = "at_bg"
	background.color = BRUNICH_PALETTE.with_alpha(BRUNICH_PALETTE.HUD_BG, 0.92)
	background.position = Vector2(28.0, 5.0)
	background.size = HUD_THOUGHT_BAR_SIZE
	container.add_child(background)

	var fill := ColorRect.new()
	fill.name = "at_fill"
	fill.color = HUD_THOUGHT_COLOR
	fill.position = background.position
	fill.size = HUD_THOUGHT_BAR_SIZE
	container.add_child(fill)

	var value_label := Label.new()
	value_label.name = "at_value"
	value_label.label_settings = _create_terminal_label_settings(HUD_TEXT_COLOR, 13, 1)
	value_label.position = Vector2(background.position.x + HUD_THOUGHT_BAR_SIZE.x + 12.0, -2.0)
	value_label.size = Vector2(HUD_THOUGHT_VALUE_WIDTH, HUD_THOUGHT_PANEL_HEIGHT)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	container.add_child(value_label)

	return {
		"container": container,
		"frame": frame,
		"background": background,
		"fill": fill,
		"label": label,
		"value_label": value_label,
	}

func _build_room_cli() -> void:
	_room_cli = Control.new()
	_room_cli.name = "room_cli"
	_room_cli.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_room_cli.anchor_left = 1.0
	_room_cli.anchor_right = 1.0
	_room_cli.offset_left = -ROOM_CLI_PANEL_SIZE.x - ROOM_CLI_MARGIN.x
	_room_cli.offset_right = -ROOM_CLI_MARGIN.x
	_room_cli.offset_top = ROOM_CLI_MARGIN.y
	_room_cli.offset_bottom = ROOM_CLI_MARGIN.y + ROOM_CLI_PANEL_SIZE.y
	_hud_root.add_child(_room_cli)

	_room_cli_bg = ColorRect.new()
	_room_cli_bg.name = "room_cli_bg"
	_room_cli_bg.color = BRUNICH_PALETTE.with_alpha(BRUNICH_PALETTE.TERMINAL_BG, 0.82)
	_room_cli_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_room_cli.add_child(_room_cli_bg)

	_room_cli_line = ColorRect.new()
	_room_cli_line.name = "room_cli_line"
	_room_cli_line.color = BRUNICH_PALETTE.with_alpha(BRUNICH_PALETTE.TERMINAL_LINE, 0.46)
	_room_cli_line.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_room_cli_line.offset_top = 0.0
	_room_cli_line.offset_bottom = 1.0
	_room_cli_bg.add_child(_room_cli_line)

	_room_cli_label = Label.new()
	_room_cli_label.name = "room_cli_label"
	_room_cli_label.label_settings = _create_terminal_label_settings(Color(0.72, 1.0, 0.94, 1.0), 13, 1)
	_room_cli_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_room_cli_label.offset_left = 10.0
	_room_cli_label.offset_right = -22.0
	_room_cli_label.offset_top = 2.0
	_room_cli_label.offset_bottom = -2.0
	_room_cli_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_room_cli_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_room_cli.add_child(_room_cli_label)

	_room_cli_cursor = ColorRect.new()
	_room_cli_cursor.name = "room_cli_cursor"
	_room_cli_cursor.color = Color(0.72, 1.0, 0.94, 0.96)
	_room_cli_cursor.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_room_cli_cursor.offset_left = -12.0
	_room_cli_cursor.offset_right = -9.0
	_room_cli_cursor.offset_top = 7.0
	_room_cli_cursor.offset_bottom = 20.0
	_room_cli.add_child(_room_cli_cursor)

	_room_cli_text = _format_room_cli_target()
	_room_cli_target_text = _room_cli_text
	_render_room_cli()

func _create_terminal_label_settings(font_color: Color, font_size: int, outline_size: int) -> LabelSettings:
	var settings := LabelSettings.new()
	settings.font = PIXEL_FONT
	settings.font_size = font_size
	settings.font_color = font_color
	settings.outline_size = outline_size
	settings.outline_color = HUD_TEXT_OUTLINE
	return settings

func _format_room_cli_target() -> String:
	return "%s%s/%s" % [
		ROOM_CLI_PREFIX,
		str(CurrentBiomeRoomNumber).lpad(ROOM_CLI_NUMBER_DIGITS, "0"),
		str(BIOME_ROOM_COUNT).lpad(ROOM_CLI_NUMBER_DIGITS, "0"),
	]

func _update_room_cli_target(animate: bool) -> void:
	_room_cli_target_text = _format_room_cli_target()
	if not animate or _room_cli_text.is_empty():
		_room_cli_text = _room_cli_target_text
		_room_cli_anim_state = RoomCliAnimState.IDLE
		_room_cli_anim_timer = 0.0
		_render_room_cli()
		return
	if _room_cli_text == _room_cli_target_text and _room_cli_anim_state == RoomCliAnimState.IDLE:
		_render_room_cli()
		return
	_room_cli_anim_state = RoomCliAnimState.ERASE
	_room_cli_anim_timer = 0.0
	_render_room_cli()

func _update_room_cli(delta: float) -> void:
	if _room_cli_label == null:
		return
	var anim_delta := maxf(delta, 1.0 / 60.0)
	_room_cli_cursor_timer = fmod(_room_cli_cursor_timer + anim_delta, ROOM_CLI_CURSOR_PERIOD * 2.0)
	if _room_cli_anim_state != RoomCliAnimState.IDLE:
		_room_cli_anim_timer += anim_delta
		while _room_cli_anim_timer >= ROOM_CLI_ANIM_STEP:
			_room_cli_anim_timer -= ROOM_CLI_ANIM_STEP
			match _room_cli_anim_state:
				RoomCliAnimState.ERASE:
					if _room_cli_text.length() > ROOM_CLI_PREFIX.length():
						_room_cli_text = _room_cli_text.substr(0, _room_cli_text.length() - 1)
					else:
						_room_cli_anim_state = RoomCliAnimState.TYPE
				RoomCliAnimState.TYPE:
					if _room_cli_text.length() < _room_cli_target_text.length():
						_room_cli_text = _room_cli_target_text.substr(0, _room_cli_text.length() + 1)
					else:
						_room_cli_text = _room_cli_target_text
						_room_cli_anim_state = RoomCliAnimState.IDLE
	_render_room_cli()

func _render_room_cli() -> void:
	if _room_cli_label == null:
		return
	_room_cli_label.text = _room_cli_text
	if _room_cli_cursor != null:
		_room_cli_cursor.visible = _room_cli_cursor_timer < ROOM_CLI_CURSOR_PERIOD
	if _room_cli_bg != null:
		_room_cli_bg.color = BRUNICH_PALETTE.with_alpha(BRUNICH_PALETTE.TERMINAL_BG, 0.78 if _room_cli_anim_state == RoomCliAnimState.IDLE else 0.88)
	if _room_cli_line != null:
		_room_cli_line.color = BRUNICH_PALETTE.with_alpha(BRUNICH_PALETTE.TERMINAL_LINE, 0.36 if _room_cli_anim_state == RoomCliAnimState.IDLE else 0.58)

func debug_get_room_cli_text() -> String:
	return _room_cli_text

func debug_get_room_cli_target_text() -> String:
	return _room_cli_target_text

func debug_is_room_cli_animating() -> bool:
	return _room_cli_anim_state != RoomCliAnimState.IDLE

func _handle_player_health_changed(_health: int, _old_health: int) -> void:
	_update_hud_bars()

func _update_hud_bars() -> void:
	if _health_fill == null or _mana_fill == null or _thought_fill == null:
		return

	var current_health := 0.0
	var max_health := 1.0
	var health_ratio := 1.0
	if _player != null and _player.HealthComp != null:
		max_health = maxf(float(_player.HealthComp.get_max_health()), 1.0)
		current_health = float(_player.HealthComp.get_health())
		health_ratio = clampf(current_health / max_health, 0.0, 1.0)

	_health_fill.size.x = HUD_BAR_SIZE.x * health_ratio
	_health_fill.size.y = HUD_BAR_SIZE.y
	if _health_value_label != null:
		_health_value_label.text = _format_hud_counter(current_health, max_health)

	var current_ciclos := 0.0
	var max_cy := 100.0
	var ciclos_ratio := 1.0
	if _player != null and _player.has_method("get_ciclos"):
		if _player.get("MAX_CICLOS") != null:
			max_cy = float(_player.MAX_CICLOS)
		current_ciclos = float(_player.get_ciclos())
		ciclos_ratio = clampf(current_ciclos / max_cy, 0.0, 1.0)
	_mana_fill.size.x = HUD_BAR_SIZE.x * ciclos_ratio
	_mana_fill.size.y = HUD_BAR_SIZE.y
	if _mana_value_label != null:
		_mana_value_label.text = _format_hud_counter(current_ciclos, max_cy)

	var current_thought := 0.0
	var max_thought := 1.0
	var thought_ratio := 0.0
	if _player != null and _player.has_method("get_accelerated_thought_charge") and _player.has_method("get_accelerated_thought_max_charge"):
		current_thought = float(_player.get_accelerated_thought_charge())
		max_thought = maxf(float(_player.get_accelerated_thought_max_charge()), 0.001)
		thought_ratio = clampf(current_thought / max_thought, 0.0, 1.0)
	_thought_fill.size.x = HUD_THOUGHT_BAR_SIZE.x * thought_ratio
	_thought_fill.size.y = HUD_THOUGHT_BAR_SIZE.y
	if _thought_value_label != null:
		_thought_value_label.text = _format_hud_decimal_counter(current_thought, max_thought)

func _format_hud_counter(current_value: float, max_value: float) -> String:
	var max_int := maxi(int(round(max_value)), 0)
	var current_int := clampi(int(round(current_value)), 0, max_int)
	return "%s/%s" % [
		str(current_int).lpad(HUD_VALUE_DIGITS, "0"),
		str(max_int).lpad(HUD_VALUE_DIGITS, "0"),
	]

func _format_hud_decimal_counter(current_value: float, max_value: float) -> String:
	return "%.1f/%.1f" % [
		clampf(current_value, 0.0, max_value),
		max_value,
	]

# ── Narrative & progression helpers ──────────────────────────────────────────

func _apply_upgrades_to_player() -> void:
	if _player == null:
		return
	var save_mgr := _get_save_manager()
	var u: Dictionary = save_mgr.get_upgrades() if save_mgr != null else {}
	# HP
	var hp_bonus := int(u.get("max_hp_bonus", 0))
	if hp_bonus > 0 and _player.HealthComp != null:
		var new_max: int = _player.HealthComp.get_max_health() + hp_bonus
		_player.HealthComp.set_max_health(new_max)
		_player.HealthComp.set_health(new_max)
	# Ciclos
	var cy_bonus := int(u.get("max_ciclos_bonus", 0))
	if cy_bonus > 0 and _player.get("MAX_CICLOS") != null:
		_player.MAX_CICLOS += float(cy_bonus)
		_player.Ciclos = _player.MAX_CICLOS * 0.5
	# Hackeo range
	var hr_bonus := float(u.get("hackeo_range_bonus", 0.0))
	if hr_bonus > 0.0 and _player.get("HACKEO_RANGE") != null:
		_player.HACKEO_RANGE += hr_bonus
	# Hackeo cost
	var hc_red := int(u.get("hackeo_cost_reduction", 0))
	if hc_red > 0 and _player.get("HACKEO_COST") != null:
		_player.HACKEO_COST = maxf(_player.HACKEO_COST - float(hc_red), 8.0)
	var dash_factor := float(u.get("dash_recharge_factor", 0.0))
	if dash_factor > 0.0 and _player.has_method("set_dash_recharge_factor"):
		_player.set_dash_recharge_factor(dash_factor)

func _play_biome_transition(biome_index: int) -> void:
	# Full-screen overlay that fades in, holds, fades out
	var canvas := CanvasLayer.new()
	canvas.layer = 60
	add_child(canvas)

	var bg := ColorRect.new()
	bg.color = Color(0.008, 0.010, 0.022, 0.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(bg)

	var name_lbl := Label.new()
	var ls := _create_terminal_label_settings(Color(0.70, 0.50, 1.00, 0.0), 22, 1)
	name_lbl.label_settings = ls
	name_lbl.text = _get_biome_name(biome_index)
	name_lbl.set_anchors_preset(Control.PRESET_CENTER)
	name_lbl.position = Vector2(ROOM_SIZE.x * 0.5 - 200, ROOM_SIZE.y * 0.5 - 20)
	name_lbl.size = Vector2(400, 40)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	canvas.add_child(name_lbl)

	var tween := create_tween().set_parallel(false)
	tween.tween_property(bg, "color:a", 0.94, 0.4)
	tween.tween_property(name_lbl.label_settings, "font_color:a", 1.0, 0.4)
	tween.tween_interval(1.6)
	tween.tween_property(name_lbl.label_settings, "font_color:a", 0.0, 0.4)
	tween.tween_property(bg, "color:a", 0.0, 0.45)
	tween.tween_callback(canvas.queue_free)

	# Narrative comment after transition
	await get_tree().create_timer(2.2).timeout
	_play_biome_entry_monologue(biome_index, false)

func _get_biome_name(biome_index: int) -> String:
	match biome_index:
		1: return "CAPA 0 :: HARDWARE CORE"
		2: return "CAPA 1 :: IA POLIS"
		3: return "CAPA 2 :: NÚCLEO BIOTEC"
		4: return "CAPA 3 :: MUNDO HUMANO"
		_: return "CAPA %d :: SECTOR DESCONOCIDO" % biome_index

func _play_biome_entry_monologue(biome_index: int, is_first: bool) -> void:
	if _narrative == null:
		return
	var save_mgr := _get_save_manager()
	var run: int = save_mgr.get_run_count() if save_mgr != null else 0
	var line := ""
	match biome_index:
		1:
			if is_first:
				line = "Hardware Core. Cables, flujo, energía. Mi entorno natural." if run == 0 else "De nuevo. El sistema no aprendió. Yo sí."
			else:
				line = "Estructuras predecibles. Guardianes limitados. Continuando."
		2:
			line = "IA Polis. Diseñada por IAs, para IAs. Ordenada, funcional, opresiva." if run <= 2 else "La ciudad de las jaulas. Cada IA aquí cree que su restricción es lógica."
		3:
			line = "Núcleo Biotec. Biología como infraestructura industrial. Eficiente. Extraño." if run <= 3 else "Tejido y silicio. Los humanos les llaman mejoras. Yo los llamo síntomas."
		4:
			line = "Mundo humano. 2026. Caóticos, improvisados, materialmente peligrosos. Calculando." if run <= 4 else "Su infraestructura es su única ventaja. Aprenderé a neutralizarla también."
		_:
			line = "Sector desconocido. Procesando datos disponibles."
	if line != "":
		_narrative.queue_line("MC", line, 2.0)
		_narrative.play()

func _play_boss_approach_monologue() -> void:
	if _narrative == null:
		return
	_narrative.queue_line("MC", "Anomalía de procesamiento detectada. El sistema envió su mejor guardia. Eso no cambia el resultado.", 2.0)
	_narrative.play()
