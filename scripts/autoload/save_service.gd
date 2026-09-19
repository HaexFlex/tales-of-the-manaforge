extends Node
## Slot-based save/load: user://manaforge_save_slot_{1..7}.json (SYSTEMS v0.4.0).
## Payload schema SAVE_VERSION 6 — backpack + tool flags. Migrates legacy single-file → slot 1.

signal save_completed(ok: bool)
signal load_completed(ok: bool)

const SAVE_VERSION: int = 6
## Accept one write ahead of this schema (plus legacy 4–5).
const SAVE_VERSION_MAX_READ: int = 7
const SAVE_SLOT_COUNT: int = 7
const LEGACY_SAVE_PATH: String = "user://manaforge_save.json"
const SLOT_PATH_FMT: String = "user://manaforge_save_slot_%d.json"


func _ready() -> void:
	migrate_legacy_save_if_needed()


func slot_path(slot: int) -> String:
	return SLOT_PATH_FMT % slot


func is_valid_slot(slot: int) -> bool:
	return slot >= 1 and slot <= SAVE_SLOT_COUNT


func migrate_legacy_save_if_needed() -> bool:
	## Copy single-file save into slot 1 if slot 1 empty and legacy exists.
	if not FileAccess.file_exists(LEGACY_SAVE_PATH):
		return false
	if FileAccess.file_exists(slot_path(1)):
		return false
	var file := FileAccess.open(LEGACY_SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var text: String = file.get_as_text()
	file.close()
	var out := FileAccess.open(slot_path(1), FileAccess.WRITE)
	if out == null:
		push_error("SaveService: migrate write failed slot 1")
		return false
	out.store_string(text)
	out.close()
	DirAccess.remove_absolute(LEGACY_SAVE_PATH)
	return true


func save_game(slot: int = 1) -> bool:
	if not is_valid_slot(slot):
		push_error("SaveService: invalid slot %d" % slot)
		save_completed.emit(false)
		return false
	var path: String = slot_path(slot)
	var payload: Dictionary = {
		"save_version": SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"slot": slot,
		"state": GameState.to_save_dict(),
	}
	var json_text: String = JSON.stringify(payload, "\t")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SaveService: write failed %s err=%s" % [path, FileAccess.get_open_error()])
		save_completed.emit(false)
		return false
	file.store_string(json_text)
	file.close()
	save_completed.emit(true)
	return true


func load_game(slot: int = -1) -> bool:
	## slot < 1 → most recent filled slot (or slot 1).
	if slot < 1:
		slot = get_most_recent_slot()
		if slot < 1:
			load_completed.emit(false)
			return false
	if not is_valid_slot(slot):
		load_completed.emit(false)
		return false
	var path: String = slot_path(slot)
	if not FileAccess.file_exists(path):
		load_completed.emit(false)
		return false
	var root: Dictionary = _read_slot_root(slot)
	if root.is_empty():
		load_completed.emit(false)
		return false
	var version: int = int(root.get("save_version", 0))
	if version > SAVE_VERSION_MAX_READ:
		push_error("SaveService: save v%d newer than %d" % [version, SAVE_VERSION_MAX_READ])
		load_completed.emit(false)
		return false
	var state: Variant = root.get("state", {})
	if typeof(state) != TYPE_DICTIONARY:
		load_completed.emit(false)
		return false
	GameState.apply_save_dict(_migrate(version, state as Dictionary))
	load_completed.emit(true)
	return true


func _read_slot_root(slot: int) -> Dictionary:
	var path: String = slot_path(slot)
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed as Dictionary


func get_slot_info(slot: int) -> Dictionary:
	## {filled, timestamp, stage_id, stage_display, ascensions, essence, empty_label-ready}
	if not is_valid_slot(slot):
		return {"filled": false, "slot": slot}
	var root: Dictionary = _read_slot_root(slot)
	if root.is_empty():
		return {"filled": false, "slot": slot}
	var state_v: Variant = root.get("state", {})
	if typeof(state_v) != TYPE_DICTIONARY:
		return {"filled": false, "slot": slot}
	var state: Dictionary = state_v
	var stage_id: String = str(state.get("stage_id", "sapling"))
	var stage_display: String = stage_id.capitalize()
	var def: Dictionary = GameState.get_stage_def(StringName(stage_id))
	if not def.is_empty():
		stage_display = str(def.get("display_name", stage_display))
	return {
		"filled": true,
		"slot": slot,
		"timestamp": float(root.get("timestamp", 0)),
		"stage_id": stage_id,
		"stage_display": stage_display,
		"ascensions": int(state.get("ascensions", 0)),
		"essence": int(state.get("essence", 0)),
		"wood": int(state.get("wood", 0)),
		"save_version": int(root.get("save_version", 0)),
	}


func get_most_recent_slot() -> int:
	var best_slot: int = 0
	var best_ts: float = -1.0
	for slot: int in range(1, SAVE_SLOT_COUNT + 1):
		var info: Dictionary = get_slot_info(slot)
		if not bool(info.get("filled", false)):
			continue
		var ts: float = float(info.get("timestamp", 0))
		if ts >= best_ts:
			best_ts = ts
			best_slot = slot
	return best_slot


func _migrate(from_version: int, state: Dictionary) -> Dictionary:
	var out: Dictionary = state.duplicate(true)
	if from_version < 2:
		out.erase("lifetime_food_watered")
		if not out.has("lifetime_waters"):
			out["lifetime_waters"] = 0
	if from_version < 3:
		if not out.has("lifetime_shards_from_water"):
			out["lifetime_shards_from_water"] = 0
		if not out.has("lifetime_essence_from_water"):
			out["lifetime_essence_from_water"] = 0
		if not out.has("lifetime_harvested") or typeof(out.get("lifetime_harvested")) != TYPE_DICTIONARY:
			out["lifetime_harvested"] = {"wood": 0, "stone": 0, "food": 0}
	if from_version < 4:
		# Needs-only: drop growth meter + offer lifetime tracking.
		out.erase("growth")
		out.erase("lifetime_offered")
	if from_version < 5:
		if not out.has("wisp_count"):
			out["wisp_count"] = 0
		if not out.has("wisp_assignments") or typeof(out.get("wisp_assignments")) != TYPE_DICTIONARY:
			out["wisp_assignments"] = {}
	if from_version < 6:
		## SYSTEMS v0.4.0: v5→v6 starts empty backpack; tool flags false.
		out["backpack"] = {}
		out["owns_stone_axe"] = false
		out["owns_stone_pickaxe"] = false
		out["owns_wooden_basket"] = false
		out["owns_stone_watering_can"] = false
	# Additive welcome flag: legacy saves already played.
	if not out.has("welcome_shown"):
		out["welcome_shown"] = true
	return out


func delete_slot(slot: int) -> void:
	if not is_valid_slot(slot):
		return
	var path: String = slot_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func delete_save() -> void:
	## Clears all slots + legacy (verify / new-game helpers).
	for slot: int in range(1, SAVE_SLOT_COUNT + 1):
		delete_slot(slot)
	if FileAccess.file_exists(LEGACY_SAVE_PATH):
		DirAccess.remove_absolute(LEGACY_SAVE_PATH)


func has_slot(slot: int) -> bool:
	return is_valid_slot(slot) and FileAccess.file_exists(slot_path(slot))


func has_save() -> bool:
	if get_most_recent_slot() >= 1:
		return true
	return FileAccess.file_exists(LEGACY_SAVE_PATH)
