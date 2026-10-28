extends Node
## Manual slots user://manaforge_save_slot_{1..7}.json plus three rotating autosaves.
## Payload schema SAVE_VERSION 16 — companions{id: joined, level, chore, gear}. Atomic temp-then-rename writes.

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
var _hub_life_script: GDScript


func _hub_life() -> GDScript:
	if _hub_life_script == null:
		var script_name := "hub_life.gd"
		_hub_life_script = load("res://scripts/%s" % script_name) as GDScript
	return _hub_life_script

const SAVE_VERSION: int = 16
## Never read a save newer than this build writes: unknown fields would be dropped silently.
const SAVE_VERSION_MAX_READ: int = SAVE_VERSION
const SAVE_SLOT_COUNT: int = 7
const AUTOSAVE_SLOT_COUNT: int = 3
const AUTOSAVE_THROTTLE_SEC: float = 60.0
const LEGACY_SAVE_PATH: String = "user://manaforge_save.json"
const SLOT_PATH_FMT: String = "user://manaforge_save_slot_%d.json"
const AUTOSAVE_PATH_FMT: String = "user://manaforge_autosave_%d.json"
## Separate from the 7 manual slots and the 3 autosaves. One live run.
const ADV_VERSION: int = 1
const ADVENTURE_PATH: String = "user://manaforge_adventure.json"

var _last_autosave_msec: int = -100000000
var _autosave_coalesce_sec: float = 1.2
var _autosave_serial: int = 0
## Player-facing reason the last load failed ("" after a good load).
var last_load_error: String = ""
## Id of the main save last written or loaded this session. 0 means none yet.
var current_save_id: int = 0
var _save_id_rng := RandomNumberGenerator.new()
## True for the whole load pass (Forge, then the expedition). Saves refuse.
var catchup_running: bool = false
## Set when a load pass runs: "forge" then "reach".
var last_catchup_order: Array[String] = []
## Runtime only. The away panel reads this after load. Not written into the save.
var pending_offline_report: Dictionary = {}
## Background hold. Pause and focus-out share one flush. Not a save field.
var _background_held: bool = false
var _master_mute_before: bool = false
var _tree_paused_before: bool = false
## Wall clock seen at the last pause or resume. A debug override feeds tests.
var _lifecycle_seen_unix: float = 0.0
var _unix_now_override: float = -1.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_save_id_rng.randomize()
	migrate_legacy_save_if_needed()
	if OS.has_feature("mobile"):
		get_tree().set_auto_accept_quit(false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_on_quit()
		get_tree().quit()
	elif what == NOTIFICATION_APPLICATION_PAUSED:
		handle_application_paused()
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		handle_application_focus_out()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		handle_application_resumed()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		handle_application_focus_in()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		handle_back_request()


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
	if slot <= 0:
		push_warning("SaveService: every autosave slot holds a newer build's save; autosave skipped")
		save_completed.emit(false)
		return false
	_autosave_serial += 1
	var stamped: float = Time.get_unix_time_from_system() + float(_autosave_serial) * 0.001
	var ok: bool = _write_payload(autosave_path(slot), slot, "autosave", stamped)
	if ok:
		_last_autosave_msec = now
	save_completed.emit(ok)
	return ok


func save_echo_pack() -> bool:
	## A Heart Salve is already gone from the pack. Write that pack with the
	## existing autosave payload so a hard kill cannot put the dose back.
	## SAVE_VERSION stays 15. No new field.
	if not session_active or catchup_running:
		return false
	if has_node("/root/Reach") and Reach.catching_up:
		return false
	var slot: int = _next_autosave_slot()
	if slot <= 0:
		return false
	_autosave_serial += 1
	var stamped: float = Time.get_unix_time_from_system() + float(_autosave_serial) * 0.001
	var ok: bool = _write_payload(autosave_path(slot), slot, "autosave", stamped)
	if ok:
		_last_autosave_msec = Time.get_ticks_msec()
	return ok


func save_on_quit() -> bool:
	if not session_active or _battle_blocks_save():
		return false
	## Window close always writes, even inside the event-save throttle.
	_last_autosave_msec = -100000000
	return save_autosave(true)


func debug_set_unix_now(unix_sec: float) -> void:
	## Tests only. File stamps stay on the real wall clock. The gap uses this.
	_unix_now_override = unix_sec


func handle_application_paused() -> void:
	_hold_background()


func handle_application_focus_out() -> void:
	_hold_background()


func handle_application_resumed() -> void:
	_release_background()


func handle_application_focus_in() -> void:
	_release_background()


func handle_back_request() -> void:
	## Android back. Opens Pause, or closes it when it is already open. Never quits.
	var tree := get_tree()
	if tree != null:
		tree.set_auto_accept_quit(false)
		var menu: Node = tree.get_first_node_in_group("pause_menu")
		if menu != null and menu.has_method("is_open") and bool(menu.call("is_open")):
			if menu.has_method("resume_game"):
				menu.call("resume_game")
		elif menu != null and menu.has_method("open_pause"):
			menu.call("open_pause")
	## Same rotating autosaves. force skips the 60s throttle and keeps the 1.2s coalesce.
	save_autosave(true)


func _unix_now() -> float:
	if _unix_now_override >= 0.0:
		return _unix_now_override
	return Time.get_unix_time_from_system()


func _hold_background() -> void:
	## Pause and focus-out in one backgrounding share a single forced autosave.
	if _background_held:
		return
	_background_held = true
	_lifecycle_seen_unix = _unix_now()
	var tree := get_tree()
	_tree_paused_before = tree.paused if tree != null else false
	var master: int = AudioServer.get_bus_index("Master")
	if master >= 0:
		_master_mute_before = AudioServer.is_bus_mute(master)
		AudioServer.set_bus_mute(master, true)
	if tree != null:
		tree.paused = true
	## Flush even inside the 1.2s coalesce. The save stamp is the real wall clock.
	_last_autosave_msec = -100000000
	save_autosave(true)


func _release_background() -> void:
	if not _background_held:
		return
	_background_held = false
	var gap: float = _unix_now() - _lifecycle_seen_unix
	if session_active and gap >= 1.0:
		_apply_offline_gap(gap)
	_lifecycle_seen_unix = _unix_now()
	if session_active:
		_last_autosave_msec = -100000000
		save_autosave(true)
	var master: int = AudioServer.get_bus_index("Master")
	if master >= 0:
		AudioServer.set_bus_mute(master, _master_mute_before)
	var tree := get_tree()
	if tree != null:
		tree.paused = _tree_paused_before
	_present_offline_if_due()


func _present_offline_if_due() -> void:
	if pending_offline_report.is_empty() or not bool(pending_offline_report.get("show", false)):
		return
	var tree := get_tree()
	if tree == null:
		return
	var summary: Node = tree.root.find_child("OfflineSummary", true, false)
	if summary != null and summary.has_method("tick_queue"):
		summary.call("tick_queue")


func debug_set_last_autosave_age(seconds: float) -> void:
	_last_autosave_msec = Time.get_ticks_msec() - int(seconds * 1000.0)


func _battle_blocks_save() -> bool:
	if catchup_running:
		return true
	if has_node("/root/Reach") and Reach.catching_up:
		return true
	return has_node("/root/EchoChamber") and EchoChamber.in_battle


func manual_path_is_autosave(path: String) -> bool:
	for slot: int in range(1, AUTOSAVE_SLOT_COUNT + 1):
		if path == autosave_path(slot):
			return true
	return false


func _write_payload(path: String, slot: int, kind: String, stamped: float = -1.0) -> bool:
	if kind == "manual" and manual_path_is_autosave(path):
		push_error("SaveService: a manual save cannot overwrite an autosave")
		return false
	var when: float = stamped if stamped >= 0.0 else Time.get_unix_time_from_system()
	var save_id: int = _fresh_save_id()
	var payload: Dictionary = {
		"save_version": SAVE_VERSION,
		"save_id": save_id,
		"timestamp": when,
		"slot": slot,
		"kind": kind,
		"state": GameState.to_save_dict(),
	}
	## Optional label. Old files omit it and still read. Autosaves never take one.
	if kind == "manual":
		var previous: Dictionary = _read_root(path)
		var kept: String = str(previous.get("slot_name", "")).strip_edges()
		if kept != "":
			payload["slot_name"] = kept
	var ok: bool = _write_atomic(path, JSON.stringify(payload, "\t"))
	if not ok:
		return false
	current_save_id = save_id
	## The adventure file's owner follows the newest main save while a run is out.
	if has_node("/root/Reach") and bool(Reach.running):
		write_adventure()
	return true


func _fresh_save_id() -> int:
	## 31-bit, never 0. A missing save_id loads as 0 and must not match a real write.
	var n: int = _save_id_rng.randi() & 0x7FFFFFFF
	if n == 0:
		n = 1
	return n


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
	last_load_error = ""
	var root: Dictionary = _read_root(path)
	if root.is_empty():
		load_completed.emit(false)
		return false
	var version: int = int(root.get("save_version", 0))
	if version > SAVE_VERSION_MAX_READ:
		last_load_error = newer_save_message(version)
		push_error("SaveService: refused %s, save v%d is newer than this build (reads up to v%d)" % [path, version, SAVE_VERSION_MAX_READ])
		if has_node("/root/GameState"):
			GameState.status_message.emit(last_load_error)
		load_completed.emit(false)
		return false
	var state: Variant = root.get("state", {})
	if typeof(state) != TYPE_DICTIONARY:
		load_completed.emit(false)
		return false
	var migrated: Dictionary = _migrate(version, state as Dictionary)
	var reach_v: Variant = migrated.get("reach", {})
	if typeof(reach_v) == TYPE_DICTIONARY:
		var reach_block: Dictionary = reach_v
		if bool(reach_block.get("running", false)) and not reach_block.has("slots_total"):
			clear_legacy_run(migrated)
	GameState.apply_save_dict(migrated)
	current_save_id = int(root.get("save_id", 0))
	_apply_loaded_adventure()
	_apply_offline_catchup(root)
	_hub_life().call("on_save_loaded")
	load_completed.emit(true)
	return true


func write_adventure() -> bool:
	## Refused during catch-up (and any other save block). Does not touch slot files.
	if _battle_blocks_save():
		return false
	if not has_node("/root/Reach"):
		return false
	Reach.sync_manual_loadout()
	var fight_payload: Variant = null
	if bool(Reach.fight_active()):
		var live: FightState = Reach.manual_fight()
		if live != null:
			fight_payload = live.to_dict()
	var payload: Dictionary = {
		"adv_version": ADV_VERSION,
		"owner_save_id": current_save_id,
		"run_id": int(Reach.run_id),
		"written_at": Time.get_unix_time_from_system(),
		"reach": Reach.capture_run_block(),
		"fight": fight_payload,
		"phase_detail": {
			"phase": str(Reach.phase),
			"room_clock": float(Reach.room_clock),
		},
	}
	return _write_atomic(ADVENTURE_PATH, JSON.stringify(payload, "\t"))


func write_adventure_raw(d: Dictionary) -> bool:
	## Debug snapshots only (the Mid-fight loader). Refused unless Reach.debug_tools().
	if not has_node("/root/Reach") or not bool(Reach.debug_tools()):
		return false
	if d.is_empty() or int(d.get("adv_version", 0)) > ADV_VERSION:
		return false
	return _write_atomic(ADVENTURE_PATH, JSON.stringify(d, "\t"))


func read_adventure() -> Dictionary:
	var root: Dictionary = _read_root(ADVENTURE_PATH)
	return root


func clear_adventure() -> void:
	_remove_if_exists(ADVENTURE_PATH)
	_remove_if_exists(ADVENTURE_PATH + ".tmp")
	_remove_if_exists(ADVENTURE_PATH + ".bak")


func adventure_newer_message(v: int) -> String:
	return "This adventure file is from a newer version (v%d). This build reads adventure files up to v%d." % [v, ADV_VERSION]


func _apply_loaded_adventure() -> void:
	## After the main save, before offline catch-up. A mismatch leaves the file alone.
	if not has_node("/root/Reach"):
		return
	var adv: Dictionary = read_adventure()
	if adv.is_empty():
		return
	var ver: int = int(adv.get("adv_version", 0))
	if ver > ADV_VERSION:
		last_load_error = adventure_newer_message(ver)
		push_error("SaveService: ignored adventure v%d, newer than this build (reads up to v%d)" % [ver, ADV_VERSION])
		if has_node("/root/GameState"):
			GameState.status_message.emit(last_load_error)
		return
	if int(adv.get("owner_save_id", -1)) != current_save_id:
		return
	if int(adv.get("run_id", -1)) != int(Reach.run_id):
		return
	var reach_v: Variant = adv.get("reach", {})
	if typeof(reach_v) == TYPE_DICTIONARY:
		Reach.apply_run_block(reach_v)
	var fight_v: Variant = adv.get("fight", null)
	if typeof(fight_v) == TYPE_DICTIONARY:
		Reach.restore_manual_fight(FightState.from_dict(fight_v))


func newer_save_message(version: int) -> String:
	var fallback: String = "This save is from a newer version of the game (v%d). This build reads saves up to v%d." % [version, SAVE_VERSION_MAX_READ]
	if not has_node("/root/ContentStrings"):
		return fallback
	var text: String = ContentStrings.get_text("save_newer_build", {"found": version, "max": SAVE_VERSION_MAX_READ})
	if text == "" or text == "save_newer_build":
		return fallback
	return text


func is_newer_than_build(version: int) -> bool:
	return version > SAVE_VERSION_MAX_READ


func migrate_state(version: int, state: Dictionary) -> Dictionary:
	## Public migration path (debug snapshots use it). Refuses saves newer than this build with {}.
	if is_newer_than_build(version):
		push_error("SaveService: refused state v%d, newer than this build (reads up to v%d)" % [version, SAVE_VERSION_MAX_READ])
		return {}
	return _migrate(version, state)


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
		"depth": int(state.get("depth", 1)),
		"save_version": int(root.get("save_version", 0)),
		"newer": is_newer_than_build(int(root.get("save_version", 0))),
		"slot_name": str(root.get("slot_name", "")),
	}


func record_title(info: Dictionary) -> String:
	## A manual slot shows its clicked name. Autosaves stay on the stage name.
	if str(info.get("kind", "")) == "manual":
		var custom: String = str(info.get("slot_name", "")).strip_edges()
		if custom != "":
			return custom
	return str(info.get("stage_display", ""))


func rename_manual_slot(slot: int, raw_name: String) -> bool:
	if not is_valid_slot(slot):
		return false
	var path: String = slot_path(slot)
	var root: Dictionary = _read_root(path)
	if root.is_empty():
		return false
	var trimmed: String = raw_name.strip_edges()
	if trimmed.length() > 28:
		trimmed = trimmed.substr(0, 28)
	if trimmed == "":
		root.erase("slot_name")
	else:
		root["slot_name"] = trimmed
	return _write_atomic(path, JSON.stringify(root, "\t"))


func get_most_recent_slot() -> int:
	## Manual slots only. Autosave rotation uses _oldest_autosave_slot.
	var best_slot: int = 0
	var best_ts: float = -1.0
	for slot: int in range(1, SAVE_SLOT_COUNT + 1):
		var info: Dictionary = get_slot_info(slot)
		if not bool(info.get("filled", false)) or bool(info.get("newer", false)):
			continue
		var ts: float = float(info.get("timestamp", 0))
		if ts >= best_ts:
			best_ts = ts
			best_slot = slot
	return best_slot


func get_most_recent_record() -> Dictionary:
	## Continue skips saves from a newer build; this build cannot read them.
	var best: Dictionary = {}
	var best_ts: float = -1.0
	for slot: int in range(1, SAVE_SLOT_COUNT + 1):
		var info: Dictionary = get_slot_info(slot)
		if not bool(info.get("filled", false)) or bool(info.get("newer", false)):
			continue
		var ts: float = float(info.get("timestamp", 0))
		if ts >= best_ts:
			best_ts = ts
			best = {"path": slot_path(slot), "kind": "manual", "slot": slot, "timestamp": ts}
	for slot: int in range(1, AUTOSAVE_SLOT_COUNT + 1):
		var info: Dictionary = get_autosave_info(slot)
		if not bool(info.get("filled", false)) or bool(info.get("newer", false)):
			continue
		var ts: float = float(info.get("timestamp", 0))
		if ts >= best_ts:
			best_ts = ts
			best = {"path": autosave_path(slot), "kind": "autosave", "slot": slot, "timestamp": ts}
	return best


func _next_autosave_slot() -> int:
	## Fill an empty slot first. Otherwise write the slot after the newest, so three saves stay distinct.
	## A slot holding a newer build's save is never overwritten. 0 means no slot may be written.
	var empty_slot: int = 0
	var newest_slot: int = 0
	var newest_ts: float = -1.0
	var writable: Array[int] = []
	for slot: int in range(1, AUTOSAVE_SLOT_COUNT + 1):
		var info: Dictionary = get_autosave_info(slot)
		if bool(info.get("newer", false)):
			continue
		writable.append(slot)
		if not bool(info.get("filled", false)):
			if empty_slot == 0:
				empty_slot = slot
			continue
		var ts: float = float(info.get("timestamp", 0))
		if ts > newest_ts:
			newest_ts = ts
			newest_slot = slot
	if writable.is_empty():
		return 0
	if empty_slot != 0:
		return empty_slot
	if newest_slot <= 0:
		return writable[0]
	var at: int = writable.find(newest_slot)
	return writable[(at + 1) % writable.size()]


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
	if from_version < 11:
		_migrate_v11(out)
	if from_version < 12:
		_migrate_v12(out)
	if from_version < 13:
		_migrate_v13(out)
	if from_version < 14:
		_migrate_v14(out)
	if from_version < 15:
		_migrate_v15(out)
	_drop_removed_blessings(out)
	_normalize_stat_ranks(out)
	_hub_life().call("migrate_fields", out)
	if from_version < 16:
		_migrate_v16(out)
	if not out.has("welcome_shown"):
		out["welcome_shown"] = true
	return out


func _migrate_v16(out: Dictionary) -> void:
	## Per-name fields become companions{id: {joined, level, chore, gear}}.
	## tortoise is only a save alias for mossback. It is not a roster id.
	## Puff and Mossback join from data/companions.json hooks on load when the save
	## already meets manatree_stage or reach_cleared. joined in the blob may stay false;
	## companion_joined() evaluates hooks live (no SAVE_VERSION bump).
	## elaia_* keys stay on the blob. This migration is what copies her join, chore,
	## and gear into companions{}. Pose, the join dialogue, footsteps, and the water
	## fraction still live on those keys, so apply_save_dict keeps reading them.
	var chores_v: Variant = out.get("companion_chores", {})
	var chores: Dictionary = chores_v if typeof(chores_v) == TYPE_DICTIONARY else {}
	if chores.has("tortoise"):
		var stone: String = str(chores.get("tortoise", ""))
		if not chores.has("mossback") or str(chores.get("mossback", "")) == "":
			chores["mossback"] = stone
		chores.erase("tortoise")
		out["companion_chores"] = chores
	var companions_v: Variant = out.get("companions", {})
	var companions: Dictionary = companions_v.duplicate(true) if typeof(companions_v) == TYPE_DICTIONARY else {}
	if companions.has("tortoise"):
		if not companions.has("mossback"):
			companions["mossback"] = companions["tortoise"]
		companions.erase("tortoise")
	var elaia_joined: bool = bool(out.get("echo_01_redeemed", false)) and (bool(out.get("first_relic_crafted", false)) or bool(out.get("elaia_legacy_joined", false)))
	var elaia_block: Dictionary = companions.get("elaia", {}) if typeof(companions.get("elaia", {})) == TYPE_DICTIONARY else {}
	elaia_block["joined"] = elaia_joined
	elaia_block["level"] = int(elaia_block.get("level", 1))
	elaia_block["chore"] = str(chores.get("elaia", elaia_block.get("chore", "")))
	var gear_v: Variant = out.get("elaia_equipped", elaia_block.get("gear", {}))
	elaia_block["gear"] = (gear_v as Dictionary).duplicate(true) if typeof(gear_v) == TYPE_DICTIONARY else {}
	companions["elaia"] = elaia_block
	var reach_v: Variant = out.get("reach", {})
	var clears: int = int((reach_v as Dictionary).get("reaches_cleared", 0)) if typeof(reach_v) == TYPE_DICTIONARY else 0
	var bramble_joined: bool = str(out.get("echo_02_outcome", "")) == "spare" and clears >= 30
	for actor_id: String in ["puff", "mossback", "bramble"]:
		var block: Dictionary = companions.get(actor_id, {}) if typeof(companions.get(actor_id, {})) == TYPE_DICTIONARY else {}
		if actor_id == "bramble":
			block["joined"] = bramble_joined
		elif not block.has("joined"):
			block["joined"] = false
		block["level"] = int(block.get("level", 1))
		block["chore"] = str(chores.get(actor_id, block.get("chore", "")))
		if typeof(block.get("gear", {})) != TYPE_DICTIONARY:
			block["gear"] = {}
		companions[actor_id] = block
	out["companions"] = companions


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


func _migrate_v11(out: Dictionary) -> void:
	## A running Keep-going job becomes one prepaid batch so the item in progress is kept.
	var jobs_v: Variant = out.get("forge_jobs", {})
	if typeof(jobs_v) != TYPE_DICTIONARY:
		out["forge_jobs"] = {}
		return
	var workers_v: Variant = out.get("forge_workers", {})
	var workers: Dictionary = workers_v if typeof(workers_v) == TYPE_DICTIONARY else {}
	if has_node("/root/ForgeJobs"):
		out["forge_jobs"] = ForgeJobs.migrate_saved_jobs(jobs_v as Dictionary, workers)


func _migrate_v12(out: Dictionary) -> void:
	## Reach rooms. Missing block is a fresh road: nothing cleared, nobody out.
	var reach_v: Variant = out.get("reach", {})
	if typeof(reach_v) == TYPE_DICTIONARY and (reach_v as Dictionary).has("reaches_cleared"):
		return
	var blank: Dictionary = {}
	if has_node("/root/Reach"):
		blank = Reach.default_save_fields()
	else:
		blank = {
			"deepest_depth": 0,
			"reaches_cleared": 0,
			"dojo_exp": 0,
			"running": false,
			"pace": "hold",
			"control": "idle",
			"depth": 1,
			"hours": 1.0,
			"elapsed": 0.0,
			"room_left": 0.0,
			"phase": "home",
			"run_clears": 0,
			"rooms_attempted": 0,
			"salve_used": false,
		}
	out["reach"] = blank


func _migrate_v13(out: Dictionary) -> void:
	## Boss rooms are every 10th attempt of an expedition, not every 10th depth.
	## An in-progress room counts as the first attempt. Older saves did not track the counter.
	var reach_v: Variant = out.get("reach", {})
	if typeof(reach_v) != TYPE_DICTIONARY:
		return
	var reach: Dictionary = (reach_v as Dictionary).duplicate(true)
	if reach.has("rooms_attempted"):
		return
	var guessed := 0
	if bool(reach.get("running", false)) and str(reach.get("phase", "")) == "idle_room":
		guessed = 1
	reach["rooms_attempted"] = guessed
	out["reach"] = reach


func _drop_removed_blessings(out: Dictionary) -> void:
	## Keep Forge Materials is gone. Forge materials always wipe on Ascend. No refund.
	for key: String in ["upgrades", "upgrade_ranks"]:
		var ranks_v: Variant = out.get(key, null)
		if typeof(ranks_v) != TYPE_DICTIONARY:
			continue
		var ranks: Dictionary = ranks_v as Dictionary
		ranks.erase("keep_forge_intermediates")


func _migrate_v15(out: Dictionary) -> void:
	## Ascension shop toggles and spoiler count; blessing unlock milestones default off.
	if not out.has("shop_hide_locked"):
		out["shop_hide_locked"] = true
	if not out.has("shop_hide_maxed"):
		out["shop_hide_maxed"] = true
	if not out.has("shop_spoiler_shown_count"):
		out["shop_spoiler_shown_count"] = 0
	for flag: String in [
		"first_wisp_gained",
		"first_tool_crafted",
		"first_pack_lost",
		"first_minigame_played",
	]:
		if not out.has(flag):
			out[flag] = false
	var wc: int = int(out.get("wisp_count", 0))
	if wc > 0:
		out["first_wisp_gained"] = true


func _migrate_v14(out: Dictionary) -> void:
	## Reach's four counters join the backpack (add, never overwrite; a zero total adds no stack,
	## so players never see empty stacks). expedition is only a status
	## marker here. Later jobs add fields on that dictionary, each with a default, and must not
	## replace a status that is already set.
	var reach_v: Variant = out.get("reach", {})
	var reach: Dictionary = (reach_v as Dictionary).duplicate(true) if typeof(reach_v) == TYPE_DICTIONARY else {}
	var pack_v: Variant = out.get("backpack", {})
	var pack: Dictionary = (pack_v as Dictionary).duplicate(true) if typeof(pack_v) == TYPE_DICTIONARY else {}
	for item_id: String in ["briarwood", "herbs", "heart_salve", "bile_vial"]:
		var have := 0
		if pack.has(item_id):
			have = maxi(0, int(pack[item_id]))
		var moved := 0
		if reach.has(item_id):
			moved = maxi(0, int(reach[item_id]))
			reach.erase(item_id)
		if have + moved > 0:
			pack[item_id] = have + moved
		else:
			pack.erase(item_id)
	out["backpack"] = pack
	out["reach"] = reach
	## Job 25 is cut (Haex 2026-10-10): a v13-era run that is still out is cleared, never converted.
	clear_legacy_run(out)
	var exp_v: Variant = out.get("expedition", {})
	var exp: Dictionary = (exp_v as Dictionary).duplicate(true) if typeof(exp_v) == TYPE_DICTIONARY else {}
	if str(exp.get("status", "")) == "":
		if bool(reach.get("running", false)):
			exp["status"] = "out_legacy"
		elif str(out.get("expedition_lantern", "")) == "cyan":
			exp["status"] = "finished_unseen"
			exp["summary"] = "from an older save"
		else:
			exp["status"] = "home"
	out["expedition"] = exp


func clear_legacy_run(out: Dictionary) -> bool:
	## Ends a run from the old (pre-slot) engine in a save state, with no conversion.
	## Kept: deepest_depth, reaches_cleared, dojo_exp, and everything already banked
	## (the four reach items are in the backpack by now). The lantern goes dark and the
	## expedition is home, marked legacy_run_cleared. Returns true when a run was cleared.
	## The v14 migration calls it for v13-era saves; the slot engine (job 24) calls it for a
	## v14 save whose expedition is still out_legacy.
	var reach_v: Variant = out.get("reach", {})
	if typeof(reach_v) != TYPE_DICTIONARY or not bool((reach_v as Dictionary).get("running", false)):
		return false
	var reach: Dictionary = (reach_v as Dictionary).duplicate(true)
	var blank: Dictionary = {
		"running": false, "pace": "hold", "control": "idle", "depth": 1, "hours": 1.0,
		"elapsed": 0.0, "room_left": 0.0, "phase": "home", "run_clears": 0,
		"rooms_attempted": 0, "salve_used": false, "mix": [],
	}
	for key: String in blank.keys():
		reach[key] = blank[key]
	out["reach"] = reach
	if str(out.get("expedition_lantern", "dark")) == "amber":
		out["expedition_lantern"] = "dark"
	var exp_v: Variant = out.get("expedition", {})
	var exp: Dictionary = (exp_v as Dictionary).duplicate(true) if typeof(exp_v) == TYPE_DICTIONARY else {}
	exp["status"] = "home"
	exp.erase("summary")
	exp["legacy_run_cleared"] = true
	out["expedition"] = exp
	return true


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
		pending_offline_report = {}
		return
	var closed: float = Time.get_unix_time_from_system() - ts
	if closed < 1.0:
		pending_offline_report = {}
		return
	_apply_offline_gap(closed)


func _apply_offline_gap(closed: float) -> void:
	if not has_node("/root/ForgeJobs"):
		return
	## Forge first, then the expedition. Saves stay blocked until both return.
	catchup_running = true
	var order: Array[String] = []
	var reach_before: Dictionary = {}
	if has_node("/root/Reach"):
		reach_before = Reach.capture_offline_snapshot()
	var forge: Dictionary = ForgeJobs.apply_saved_offline_gap(closed)
	order.append("forge")
	## Road time is the raw gap. Play speed and Rush do not stretch a closed game.
	var reach_after: Dictionary = reach_before
	if has_node("/root/Reach"):
		Reach.apply_offline_seconds(closed)
		order.append("reach")
		reach_after = Reach.capture_offline_snapshot()
	last_catchup_order = order
	catchup_running = false
	pending_offline_report = _compose_offline_report(forge, reach_before, reach_after, closed)


func _compose_offline_report(forge: Dictionary, before: Dictionary, after: Dictionary, raw_sec: float) -> Dictionary:
	var report: Dictionary = forge.duplicate(true)
	report["raw_sec"] = raw_sec
	if has_node("/root/GameState"):
		report["shard_mult"] = GameState.offline_shard_mult()
	report["expedition"] = _expedition_offline_delta(before, after)
	var min_sec: float = GameState.OFFLINE_PANEL_MIN_SEC if has_node("/root/GameState") else 600.0
	report["show"] = raw_sec + 0.001 >= min_sec and _offline_report_has_news(report)
	return report


func _expedition_offline_delta(before: Dictionary, after: Dictionary) -> Dictionary:
	var before_n: int = int(before.get("room_count", 0))
	var after_log_v: Variant = after.get("log", [])
	var after_log: Array = after_log_v if typeof(after_log_v) == TYPE_ARRAY else []
	var wins: int = 0
	var losses: int = 0
	var room_no: int = 0
	for i: int in range(before_n, after_log.size()):
		var entry_v: Variant = after_log[i]
		if typeof(entry_v) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_v
		var outcome: String = str(entry.get("outcome", ""))
		room_no = int(entry.get("room", room_no))
		if outcome == "win":
			wins += 1
		elif outcome == "overwhelmed" or outcome == "flee":
			losses += 1
	var was_running: bool = bool(before.get("running", false))
	var still_running: bool = bool(after.get("running", false))
	var reason: String = ""
	if was_running and not still_running:
		reason = str(after.get("reason", ""))
	var loot: Dictionary = {}
	if reason != "":
		var banked_v: Variant = after.get("banked", {})
		if typeof(banked_v) == TYPE_DICTIONARY:
			loot = (banked_v as Dictionary).duplicate()
	return {
		"rooms": maxi(0, after_log.size() - before_n),
		"wins": wins,
		"losses": losses,
		"room": room_no,
		"exp": maxi(0, int(after.get("exp_gained", 0)) - int(before.get("exp_gained", 0))),
		"reason": reason,
		"waiting": still_running and str(after.get("phase", "")) == "manual",
		"loot": loot,
	}


func _offline_report_has_news(report: Dictionary) -> bool:
	if bool(report.get("blocked", false)):
		return true
	for key: String in ["wood", "stone", "food", "manashards", "essence"]:
		if int(report.get(key, 0)) > 0:
			return true
	if int(report.get("forge_completed", 0)) > 0:
		return true
	var stations_v: Variant = report.get("forge_stations", {})
	if typeof(stations_v) == TYPE_DICTIONARY:
		for row_v: Variant in (stations_v as Dictionary).values():
			if typeof(row_v) == TYPE_DICTIONARY and bool((row_v as Dictionary).get("working", false)):
				return true
			if typeof(row_v) == TYPE_DICTIONARY and int((row_v as Dictionary).get("finished", 0)) > 0:
				return true
	var trip_v: Variant = report.get("expedition", {})
	if typeof(trip_v) == TYPE_DICTIONARY:
		var trip: Dictionary = trip_v
		if int(trip.get("rooms", 0)) > 0 or str(trip.get("reason", "")) != "" or bool(trip.get("waiting", false)):
			return true
	if str(report.get("keeper_kind", "")) == "":
		return true
	return false


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
