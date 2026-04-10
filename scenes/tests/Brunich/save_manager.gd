## SaveManager — autoload singleton.
## Manages 3 save slots and in-run state (resources, upgrades, run progression).
extends Node

const SAVE_SLOTS := 3
const SAVE_PATH := "user://save_slot_%d.json"

const DEFAULT_UPGRADES := {
	"max_hp_bonus": 0,
	"max_ciclos_bonus": 0,
	"dash_recharge_factor": 0.0,   # 0..1 reduces recharge time
	"hackeo_range_bonus": 0.0,
	"hackeo_cost_reduction": 0,
}
const UPGRADE_CONFIG := {
	"max_hp_up": {
		"key": "max_hp_bonus",
		"step": 25,
		"cap": 100,
	},
	"max_ciclos_up": {
		"key": "max_ciclos_bonus",
		"step": 20,
		"cap": 80,
	},
	"dash_recharge": {
		"key": "dash_recharge_factor",
		"step": 0.15,
		"cap": 0.45,
	},
	"hackeo_range": {
		"key": "hackeo_range_bonus",
		"step": 30.0,
		"cap": 90.0,
	},
	"hackeo_cost_down": {
		"key": "hackeo_cost_reduction",
		"step": 8,
		"cap": 24,
	},
}
const DEFAULT_DATA := {
	"run_count": 0,
	"biome_reached": 1,
	"resources": 0,
	"pending_resources": 0,
	"has_intro_played": false,
	"last_run_biome": 1,
	"upgrades": {},
}

var active_slot: int = -1
var data: Dictionary = {}

# ── Slot management ──────────────────────────────────────────────────────────

func has_save(slot: int) -> bool:
	return FileAccess.file_exists(SAVE_PATH % slot)

func get_slot_preview(slot: int) -> Dictionary:
	var path := SAVE_PATH % slot
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if parsed is Dictionary else {}

func load_slot(slot: int) -> void:
	active_slot = slot
	data = DEFAULT_DATA.duplicate(true)
	data["upgrades"] = DEFAULT_UPGRADES.duplicate(true)
	var preview: Dictionary = get_slot_preview(slot)
	if preview.is_empty():
		return
	for key in preview:
		data[key] = preview[key]
	# Forward-compat: fill missing upgrade keys
	if not (data["upgrades"] is Dictionary):
		data["upgrades"] = DEFAULT_UPGRADES.duplicate(true)
	else:
		for key in DEFAULT_UPGRADES:
			if not data["upgrades"].has(key):
				data["upgrades"][key] = DEFAULT_UPGRADES[key]

func save_current() -> void:
	if active_slot < 0:
		return
	var file := FileAccess.open(SAVE_PATH % active_slot, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

func delete_slot(slot: int) -> void:
	var dir := DirAccess.open("user://")
	if dir != null and FileAccess.file_exists(SAVE_PATH % slot):
		dir.remove(("save_slot_%d.json") % slot)
	if active_slot == slot:
		active_slot = -1
		data = {}

# ── Run state ────────────────────────────────────────────────────────────────

func is_first_run() -> bool:
	return int(data.get("run_count", 0)) == 0 and not bool(data.get("has_intro_played", false))

func mark_intro_played() -> void:
	data["has_intro_played"] = true
	save_current()

func get_run_count() -> int:
	return int(data.get("run_count", 0))

func increment_run() -> void:
	data["run_count"] = int(data.get("run_count", 0)) + 1
	data["pending_resources"] = 0
	save_current()

func update_biome_reached(biome: int) -> void:
	data["last_run_biome"] = biome
	if biome > int(data.get("biome_reached", 1)):
		data["biome_reached"] = biome
	save_current()

# ── Resources ────────────────────────────────────────────────────────────────

func add_resources(amount: int) -> void:
	data["resources"] = int(data.get("resources", 0)) + amount
	data["pending_resources"] = int(data.get("pending_resources", 0)) + amount
	save_current()

func get_resources() -> int:
	return int(data.get("resources", 0))

func get_pending_resources() -> int:
	return int(data.get("pending_resources", 0))

func clear_pending_resources() -> void:
	data["pending_resources"] = 0
	save_current()

func spend_resources(amount: int) -> bool:
	if get_resources() < amount:
		return false
	data["resources"] = get_resources() - amount
	save_current()
	return true

# ── Upgrades ─────────────────────────────────────────────────────────────────

func get_upgrades() -> Dictionary:
	var u: Variant = data.get("upgrades", {})
	return u if u is Dictionary else DEFAULT_UPGRADES.duplicate(true)

func get_upgrade_cap(upgrade_id: String) -> Variant:
	var config: Variant = UPGRADE_CONFIG.get(upgrade_id, {})
	if not (config is Dictionary):
		return null
	return (config as Dictionary).get("cap")

func get_upgrade_step(upgrade_id: String) -> Variant:
	var config: Variant = UPGRADE_CONFIG.get(upgrade_id, {})
	if not (config is Dictionary):
		return null
	return (config as Dictionary).get("step")

func get_upgrade_current_value(upgrade_id: String) -> Variant:
	var config: Variant = UPGRADE_CONFIG.get(upgrade_id, {})
	if not (config is Dictionary):
		return null
	var key := String((config as Dictionary).get("key", ""))
	if key == "":
		return null
	var upgrades := get_upgrades()
	return upgrades.get(key, DEFAULT_UPGRADES.get(key))

func is_upgrade_maxed(upgrade_id: String) -> bool:
	var cap: Variant = get_upgrade_cap(upgrade_id)
	var current: Variant = get_upgrade_current_value(upgrade_id)
	if cap == null or current == null:
		return false
	if cap is float or current is float:
		return float(current) >= float(cap) - 0.0001
	return int(current) >= int(cap)

func apply_upgrade(upgrade_id: String) -> bool:
	var u: Dictionary = get_upgrades()
	var config: Variant = UPGRADE_CONFIG.get(upgrade_id, {})
	if not (config is Dictionary):
		return false
	var config_dict := config as Dictionary
	var key := String(config_dict.get("key", ""))
	if key == "":
		return false
	var current_value: Variant = u.get(key, DEFAULT_UPGRADES.get(key))
	var previous_value: Variant = current_value
	if current_value is float or config_dict.get("step") is float or config_dict.get("cap") is float:
		current_value = minf(float(current_value) + float(config_dict.get("step", 0.0)), float(config_dict.get("cap", 0.0)))
	else:
		current_value = mini(int(current_value) + int(config_dict.get("step", 0)), int(config_dict.get("cap", 0)))
	if previous_value == current_value:
		return false
	u[key] = current_value
	data["upgrades"] = u
	save_current()
	return true
