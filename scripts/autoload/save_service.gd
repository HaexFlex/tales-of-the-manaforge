extends Node
## Manual slots user://manaforge_save_slot_{1..7}.json plus three rotating autosaves.
## Payload schema SAVE_VERSION 10 — ancient freeze and forge-visited. Atomic temp-then-rename writes.

signal save_completed(ok: bool)
signal load_completed(ok: bool)

## Set by the title screen before main.tscn loads. "auto" keeps the old boot
## (load the newest slot) for direct launches, including headless verify.
var boot_intent: String = "auto"
var boot_slot: int = 0
## "manual" or "autosave". Title load sets this with boot_slot.
var boot_slot_kind: String = "manual"
## True while a play session is in main or the Forge. Title quit does not save a blank Keeper.
var session_active: bool = false

const SAVE_VERSION: int = 10
## Accept one write ahead of this schema (plus legacy 4–9).
const SAVE_VERSION_MAX_READ: int = 11
const SAVE_SLOT_COUNT: int = 7
const AUTOSAVE_SLOT_COUNT: int = 3
const AUTOSAVE_THROTTLE_SEC: float = 60.0
const LEGACY_SAVE_PATH: String = "user://manaforge_save.json"
const SLOT_PATH_FMT: String = "user://manaforge_save_slot_%d.json"
const AUTOSAVE_PATH_FMT: String = "user://manaforge_autosave_%d.json"

var _last_autosave_msec: int = -100000000
var _autosave_coalesce_sec: float = 1.2
var _autosave_serial: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	migrate_legacy_save_if_needed()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_on_quit()
		get_tree().quit()


func slot_path(slot: int) -> String:
	return SLOT_PATH_FMT % slot


func autosave_path(slot: int) -> String:
	return AUTOSAVE_PATH_FMT % slot


func is_valid_slot(slot: int) -> bool:
	return slot >= 1 and slot <= SAVE_SLOT_COUNT


func is_valid_autosave(slot: int) -> bool:
	return slot >= 1 and slot <= AUTOSAVE_SLOT_COUNT


func note_session_started() -> void:
	session_active = true


func note_session_ended() -> void:
	session_active = false


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
	if not _write_atomic(slot_path(1), text):
		push_error("SaveService: migrate write failed slot 1")
		return false
	DirAccess.remove_absolute(LEGACY_SAVE_PATH)
	return true


func save_game(slot: int = 0) -> bool:
	## slot <= 0 is a throttled autosave. An explicit 1–7 stays a manual slot.
	if slot <= 0:
		return save_autosave(false)
	if not is_valid_slot(slot):
		push_error("SaveService: invalid slot %d" % slot)
		save_completed.emit(false)
		return false
	if _battle_blocks_save():
		save_completed.emit(false)
		return false
	var ok: bool = _write_payload(slot_path(slot), slot, "manual")
	save_completed.emit(ok)
	return ok


func set_autosave_coalesce(seconds: float) -> void:
	_autosave_coalesce_sec = maxf(0.0, seconds)


func save_autosave(force: bool = false) -> bool:
	if not session_active:
		return false
	if _battle_blocks_save():
		save_completed.emit(false)
		return false
	var now: int = Time.get_ticks_msec()
	## Event, timer, and quit saves in the same moment write one slot.
	## force used to skip the throttle and stamp all three slots with one clock second.
	var window: float = _autosave_coalesce_sec
	if not force:
		window = maxf(window, AUTOSAVE_THROTTLE_SEC)
	if now - _last_autosave_msec < int(window * 1000.0):
		save_completed.emit(true)
		return true
	var slot: int = _next_autosave_slot()
	_autosave_serial += 1
	var stamped: float = Time.get_unix_time_from_system() + float(_autosave_serial) * 0.001
	var ok: bool = _write_payload(autosave_path(slot), slot, "autosave", stamped)
	if ok:
		_last_autosave_msec = now
	save_completed.emit(ok)
	return ok


func save_on_quit() -> bool:
	if not session_active or _battle_blocks_save():
		return false
	## Window close always writes, even inside the event-save throttle.
	_last_autosave_msec = -100000000
	return save_autosave(true)


func debug_set_last_autosave_age(seconds: float) -> void:
	_last_autosave_msec = Time.get_ticks_msec() - int(seconds * 1000.0)


func _battle_blocks_save() -> bool:
	return has_node("/root/EchoChamber") and EchoChamber.in_battle


func _write_payload(path: String, slot: int, kind: String, stamped: float = -1.0) -> bool:
	var when: float = stamped if stamped >= 0.0 else Time.get_unix_time_from_system()
	var payload: Dictionary = {
		"save_version": SAVE_VERSION,
		"timestamp": when,
		"slot": slot,
		"kind": kind,
		"state": GameState.to_save_dict(),
	}
	return _write_atomic(path, JSON.stringify(payload, "\t"))


func _write_atomic(path: String, json_text: String) -> bool:
	## Temp file, flush, then rename. A crash mid-write must not leave a partial slot.
	var tmp: String = path + ".tmp"
	var file := FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		push_error("SaveService: tmp write failed %s err=%s" % [tmp, FileAccess.get_open_error()])
		return false
	file.store_string(json_text)
	file.flush()
	file.close()
	if not _json_file_ok(tmp):
		DirAccess.remove_absolute(tmp)
		push_error("SaveService: tmp was not valid JSON %s" % tmp)
		return false
	var renamed: Error = DirAccess.rename_absolute(tmp, path)
	if renamed == OK:
		_remove_if_exists(path + ".bak")
		return true
	var bak: String = path + ".bak"
	_remove_if_exists(bak)
	if FileAccess.file_exists(path):
		if DirAccess.rename_absolute(path, bak) != OK:
			DirAccess.remove_absolute(tmp)
			push_error("SaveService: could not move %s aside" % path)
			return false
	renamed = DirAccess.rename_absolute(tmp, path)
	if renamed != OK:
		if FileAccess.file_exists(bak):
			DirAccess.rename_absolute(bak, path)
		push_error("SaveService: rename failed %s" % path)
		return false
	_remove_if_exists(bak)
	return true


func _json_file_ok(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var text: String = file.get_as_text()
	file.close()
	return typeof(JSON.parse_string(text)) == TYPE_DICTIONARY


func _remove_if_exists(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func load_game(slot: int = -1) -> bool:
	## slot < 1 → most recent file across manuals and autosaves.
	if slot < 1:
		var picked: Dictionary = get_most_recent_record()
		if picked.is_empty():
			load_completed.emit(false)
			return false
		return _load_path(str(picked.get("path", "")))
	if not is_valid_slot(slot):
		load_completed.emit(false)
		return false
	return _load_path(slot_path(slot))


func load_autosave(slot: int) -> bool:
	if not is_valid_autosave(slot):
		load_completed.emit(false)
		return false
	return _load_path(autosave_path(slot))


func _load_path(path: String) -> bool:
	var root: Dictionary = _read_root(path)
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
	_apply_offline_catchup(root)
	load_completed.emit(true)
	return true


func _read_slot_root(slot: int) -> Dictionary:
	return _read_root(slot_path(slot))


func _read_root(path: String) -> Dictionary:
	## A valid leftover .tmp is promoted when the slot is missing or corrupt.
	if not _json_file_ok(path):
		var tmp: String = path + ".tmp"
		if _json_file_ok(tmp):
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(path)
			DirAccess.rename_absolute(tmp, path)
		else:
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
	if not is_valid_slot(slot):
		return {"filled": false, "slot": slot, "kind": "manual"}
	return _info_from_root(slot, "manual", _read_root(slot_path(slot)))


func get_autosave_info(slot: int) -> Dictionary:
	if not is_valid_autosave(slot):
		return {"filled": false, "slot": slot, "kind": "autosave"}
	return _info_from_root(slot, "autosave", _read_root(autosave_path(slot)))


func _info_from_root(slot: int, kind: String, root: Dictionary) -> Dictionary:
	if root.is_empty():
		return {"filled": false, "slot": slot, "kind": kind}
	var state_v: Variant = root.get("state", {})
	if typeof(state_v) != TYPE_DICTIONARY:
		return {"filled": false, "slot": slot, "kind": kind}
	var state: Dictionary = state_v
	var stage_id: String = str(state.get("stage_id", "sapling"))
	var stage_display: String = stage_id.capitalize()
	var def: Dictionary = GameState.get_stage_def(StringName(stage_id))
	if not def.is_empty():
		stage_display = str(def.get("display_name", stage_display))
	return {
		"filled": true,
		"slot": slot,
		"kind": kind,
		"timestamp": float(root.get("timestamp", 0)),
		"stage_id": stage_id,
		"stage_display": stage_display,
		"ascensions": int(state.get("ascensions", 0)),
		"essence": int(state.get("essence", 0)),
		"wood": int(state.get("wood", 0)),
		"save_version": int(root.get("save_version", 0)),
	}


func get_most_recent_slot() -> int:
	## Manual slots only. Autosave rotation uses _oldest_autosave_slot.
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


func get_most_recent_record() -> Dictionary:
	var best: Dictionary = {}
	var best_ts: float = -1.0
	for slot: int in range(1, SAVE_SLOT_COUNT + 1):
		var info: Dictionary = get_slot_info(slot)
		if not bool(info.get("filled", false)):
			continue
		var ts: float = float(info.get("timestamp", 0))
		if ts >= best_ts:
			best_ts = ts
			best = {"path": slot_path(slot), "kind": "manual", "slot": slot, "timestamp": ts}
	for slot: int in range(1, AUTOSAVE_SLOT_COUNT + 1):
		var info: Dictionary = get_autosave_info(slot)
		if not bool(info.get("filled", false)):
			continue
		var ts: float = float(info.get("timestamp", 0))
		if ts >= best_ts:
			best_ts = ts
			best = {"path": autosave_path(slot), "kind": "autosave", "slot": slot, "timestamp": ts}
	return best


func _next_autosave_slot() -> int:
	## Fill an empty slot first. Otherwise write the slot after the newest, so three saves stay distinct.
	var empty_slot: int = 0
	var newest_slot: int = 0
	var newest_ts: float = -1.0
	for slot: int in range(1, AUTOSAVE_SLOT_COUNT + 1):
		var info: Dictionary = get_autosave_info(slot)
		if not bool(info.get("filled", false)):
			if empty_slot == 0:
				empty_slot = slot
			continue
		var ts: float = float(info.get("timestamp", 0))
		if ts > newest_ts:
			newest_ts = ts
			newest_slot = slot
	if empty_slot != 0:
		return empty_slot
	if newest_slot <= 0:
		return 1
	var nxt: int = newest_slot + 1
	if nxt > AUTOSAVE_SLOT_COUNT:
		nxt = 1
	return nxt


func _oldest_autosave_slot() -> int:
	var best_slot: int = 1
	var best_ts: float = 1.0e30
	for slot: int in range(1, AUTOSAVE_SLOT_COUNT + 1):
		var info: Dictionary = get_autosave_info(slot)
		if not bool(info.get("filled", false)):
			return slot
		var ts: float = float(info.get("timestamp", 0))
		if ts < best_ts:
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
		out.erase("growth")
		out.erase("lifetime_offered")
	if from_version < 5:
		if not out.has("wisp_count"):
			out["wisp_count"] = 0
		if not out.has("wisp_assignments") or typeof(out.get("wisp_assignments")) != TYPE_DICTIONARY:
			out["wisp_assignments"] = {}
	if from_version < 6:
		out["backpack"] = {}
		out["owns_stone_axe"] = false
		out["owns_stone_pickaxe"] = false
		out["owns_wooden_basket"] = false
		out["owns_stone_watering_can"] = false
	if from_version < 7:
		_migrate_gear_v7(out)
	if from_version < 8:
		if not out.has("portal_unlocked"):
			out["portal_unlocked"] = int(out.get("ascensions", 0)) >= 1
		if not out.has("portal_fee_paid"):
			out["portal_fee_paid"] = false
		if not out.has("echo_01_resolved"):
			out["echo_01_resolved"] = false
		if not out.has("echo_01_redeemed"):
			out["echo_01_redeemed"] = false
		if not out.has("forge_key"):
			out["forge_key"] = false
		if not out.has("echo_01_narrator_heard"):
			out["echo_01_narrator_heard"] = false
	if from_version < 9:
		if not out.has("forge_jobs") or typeof(out.get("forge_jobs")) != TYPE_DICTIONARY:
			out["forge_jobs"] = {}
		if not out.has("forge_workers") or typeof(out.get("forge_workers")) != TYPE_DICTIONARY:
			out["forge_workers"] = {}
		if not out.has("keeper_task") or typeof(out.get("keeper_task")) != TYPE_DICTIONARY:
			out["keeper_task"] = {"kind": "none", "target": "", "working": false}
		if not out.has("idle_timestamp"):
			out["idle_timestamp"] = 0
		_migrate_equipped_key_to_inventory(out)
		if not out.has("item_categories") or typeof(out.get("item_categories")) != TYPE_DICTIONARY:
			if has_node("/root/ForgeJobs"):
				out["item_categories"] = ForgeJobs.item_categories()
			else:
				out["item_categories"] = {}
		if not out.has("harvest_accum") or typeof(out.get("harvest_accum")) != TYPE_DICTIONARY:
			out["harvest_accum"] = {}
		if str(out.get("stage_id", "")) == "ancient" and not bool(out.get("fruit_committed", out.get("fruit_harvested_pending_ascend", false))):
			if not out.has("ancient_remaining_sec"):
				var full_ancient: float = 600.0
				if has_node("/root/GameState"):
					full_ancient = float(GameState.ancient_duration_sec())
				out["ancient_remaining_sec"] = full_ancient
		if not out.has("offline_closed_sec"):
			out["offline_closed_sec"] = 0.0
		if not out.has("active_since_load_sec"):
			out["active_since_load_sec"] = 0.0
	if from_version < 10:
		_migrate_v10(out)
	_normalize_stat_ranks(out)
	if not out.has("welcome_shown"):
		out["welcome_shown"] = true
	return out


func _migrate_v10(out: Dictionary) -> void:
	## Timeout with the timer already at 0 becomes a frozen commit. A live timer stays cancelable.
	var committed: bool = bool(out.get("fruit_committed", out.get("fruit_harvested_pending_ascend", false)))
	var remaining: float = float(out.get("ancient_remaining_sec", 0.0))
	if str(out.get("stage_id", "")) == "ancient" and remaining <= 0.0:
		out["ancient_frozen"] = true
		out["fruit_committed"] = true
		out["fruit_harvested_pending_ascend"] = true
		out["fruit_ready"] = false
	else:
		out["ancient_frozen"] = false
		if committed:
			out["fruit_committed"] = true
			out["fruit_harvested_pending_ascend"] = true
	if not bool(out.get("forge_visited", false)):
		out["forge_visited"] = _infer_forge_visited(out)


func _infer_forge_visited(out: Dictionary) -> bool:
	if bool(out.get("forge_key", false)) or bool(out.get("first_relic_crafted", false)):
		return true
	var task_v: Variant = out.get("keeper_task", {})
	if typeof(task_v) == TYPE_DICTIONARY and str((task_v as Dictionary).get("kind", "")) == "forge":
		return true
	var jobs_v: Variant = out.get("forge_jobs", {})
	if typeof(jobs_v) == TYPE_DICTIONARY and not (jobs_v as Dictionary).is_empty():
		return true
	var workers_v: Variant = out.get("forge_workers", {})
	if typeof(workers_v) == TYPE_DICTIONARY and not (workers_v as Dictionary).is_empty():
		return true
	var pack_v: Variant = out.get("backpack", {})
	if typeof(pack_v) == TYPE_DICTIONARY:
		var pack: Dictionary = pack_v
		for item_id: String in ["sapsteel", "heartwood_bits", "amberbind"]:
			if int(pack.get(item_id, 0)) > 0:
				return true
	var gear_ids: Array[String] = [
		"forge_key_relic", "forge_key",
		"rootsteel_edge", "heartwand", "switchshaft",
		"oakheart_knot", "shardlens", "windthorn_bead",
	]
	var bag_v: Variant = out.get("gear_inventory", {})
	if typeof(bag_v) == TYPE_DICTIONARY:
		var bag: Dictionary = bag_v
		for item_id: String in gear_ids:
			if int(bag.get(item_id, 0)) > 0:
				return true
	var eq_v: Variant = out.get("equipment_equipped", {})
	if typeof(eq_v) == TYPE_DICTIONARY:
		for raw: Variant in (eq_v as Dictionary).values():
			if raw == null:
				continue
			if str(raw) in gear_ids:
				return true
	return false


func _migrate_gear_v7(out: Dictionary) -> void:
	out["keeper_stats"] = {
		"might": 0,
		"arcana": 0,
		"resilience": 0,
		"ward": 0,
		"vitality": 0,
		"swiftness": 0,
		"fate": 0,
	}
	out["equipment_unlocked"] = {
		"weapon": true,
		"relic": false,
		"head": false,
		"body": false,
		"hands": false,
		"pants": false,
		"feet": false,
		"cape": false,
		"ring1": false,
		"ring2": false,
	}
	out["equipment_equipped"] = {
		"weapon": null,
		"relic": null,
		"head": null,
		"body": null,
		"hands": null,
		"pants": null,
		"feet": null,
		"cape": null,
		"ring1": null,
		"ring2": null,
	}
	out["gear_inventory"] = {}
	out.erase("equipment")


func _normalize_stat_ranks(out: Dictionary) -> void:
	var raw_v: Variant = out.get("keeper_stats", {})
	var src: Dictionary = raw_v if typeof(raw_v) == TYPE_DICTIONARY else {}
	var stats: Dictionary = {}
	for sid: String in ["might", "arcana", "resilience", "ward", "vitality", "swiftness", "fate"]:
		if not src.has(sid):
			stats[sid] = 0
		else:
			stats[sid] = maxi(0, int(src[sid]))
	out["keeper_stats"] = stats


func delete_slot(slot: int) -> void:
	if not is_valid_slot(slot):
		return
	_remove_slot_files(slot_path(slot))


func delete_autosave(slot: int) -> void:
	if not is_valid_autosave(slot):
		return
	_remove_slot_files(autosave_path(slot))


func _remove_slot_files(path: String) -> void:
	_remove_if_exists(path)
	_remove_if_exists(path + ".tmp")
	_remove_if_exists(path + ".bak")


func delete_save() -> void:
	for slot: int in range(1, SAVE_SLOT_COUNT + 1):
		delete_slot(slot)
	for slot: int in range(1, AUTOSAVE_SLOT_COUNT + 1):
		delete_autosave(slot)
	_remove_if_exists(LEGACY_SAVE_PATH)
	_remove_if_exists(LEGACY_SAVE_PATH + ".tmp")
	_remove_if_exists(LEGACY_SAVE_PATH + ".bak")


func has_slot(slot: int) -> bool:
	return is_valid_slot(slot) and FileAccess.file_exists(slot_path(slot))


func has_autosave(slot: int) -> bool:
	return is_valid_autosave(slot) and FileAccess.file_exists(autosave_path(slot))


func _apply_offline_catchup(root: Dictionary) -> void:
	if not has_node("/root/ForgeJobs"):
		return
	var ts: float = float(root.get("timestamp", 0.0))
	if ts <= 1.0:
		return
	var closed: float = Time.get_unix_time_from_system() - ts
	if closed < 1.0:
		return
	ForgeJobs.apply_saved_offline_gap(closed)


func _migrate_equipped_key_to_inventory(out: Dictionary) -> void:
	var eq_v: Variant = out.get("equipment_equipped", {})
	if typeof(eq_v) != TYPE_DICTIONARY:
		return
	var eq: Dictionary = eq_v
	var relic_v: Variant = eq.get("relic", null)
	var relic_id: String = ""
	if relic_v != null:
		relic_id = str(relic_v)
	if relic_id != "forge_key" and relic_id != "forge_key_relic":
		return
	eq["relic"] = null
	out["equipment_equipped"] = eq
	var bag_v: Variant = out.get("gear_inventory", {})
	var bag: Dictionary = (bag_v as Dictionary).duplicate(true) if typeof(bag_v) == TYPE_DICTIONARY else {}
	if int(bag.get("forge_key_relic", 0)) < 1 and int(bag.get("forge_key", 0)) < 1:
		bag["forge_key_relic"] = 1
	out["gear_inventory"] = bag


func has_save() -> bool:
	if not get_most_recent_record().is_empty():
		return true
	return FileAccess.file_exists(LEGACY_SAVE_PATH)
