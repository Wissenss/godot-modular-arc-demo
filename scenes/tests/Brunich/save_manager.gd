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
	var parsed := JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if parsed is Dictionary else {}

func load_slot(slot: int) -> void:
	active_slot = slot
	data = DEFAULT_DATA.duplicate(true)
	data["upgrades"] = DEFAULT_UPGRADES.duplicate(true)
	var preview := get_slot_preview(slot)
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
	var u = data.get("upgrades", {})
	return u if u is Dictionary else DEFAULT_UPGRADES.duplicate(true)

func apply_upgrade(upgrade_id: String) -> void:
	var u: Dictionary = get_upgrades()
	match upgrade_id:
		"max_hp_up":         u["max_hp_bonus"]         = int(u.get("max_hp_bonus", 0)) + 25
		"max_ciclos_up":     u["max_ciclos_bonus"]      = int(u.get("max_ciclos_bonus", 0)) + 20
		"dash_recharge":     u["dash_recharge_factor"]  = minf(float(u.get("dash_recharge_factor", 0.0)) + 0.15, 0.6)
		"hackeo_range":      u["hackeo_range_bonus"]    = float(u.get("hackeo_range_bonus", 0.0)) + 30.0
		"hackeo_cost_down":  u["hackeo_cost_reduction"] = int(u.get("hackeo_cost_reduction", 0)) + 8
	data["upgrades"] = u
	save_current()
