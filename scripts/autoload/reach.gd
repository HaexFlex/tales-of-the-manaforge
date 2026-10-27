extends Node
## Endless reach rooms. Idle slots and manual fights share one outing.
## An idle room is a real fight, resolved at the end of its 12 minutes. Loot stays in the pack until the run ends.
## Briarwood, herbs, Heart Salve and Bile Vial live in the Backpack once the pack is banked.
## Offline catch-up of an open run is one pass over raw closed seconds. Play speed never multiplies it.
## The locked draft's Fate term, every-5 start checkpoints, room twists, crates, and Amberbind are not in this pass.
## Any unlocked depth can be started. Every 10th room attempted in an expedition is a boss at that room's depth.

signal changed
signal party_changed
## One dictionary per resolved room: room, depth, outcome, boss.
signal room_resolved(entry: Dictionary)

const DEPART_ESSENCE: int = 20
const ROOM_SEC: float = 720.0
## A live frame longer than this (after play speed) resolves in one pass.
const BIG_DELTA_SEC: float = 5.0
const REST_SEC: float = 1440.0
const HOURS: Array[int] = [1, 2, 4, 8]

const PACK_ITEM_IDS: Array[String] = ["briarwood", "herbs", "heart_salve", "bile_vial"]

var deepest_depth: int = 0
var reaches_cleared: int = 0
var dojo_exp: int = 0
## Marker for the outing. Later jobs add fields here with defaults.
var expedition: Dictionary = {"status": "home"}
var running: bool = false
var control: String = "idle"
var depth: int = 1
var hours: float = 1.0
var elapsed: float = 0.0
var room_left: float = 0.0
var phase: String = "home"
var run_clears: int = 0
## Rooms begun this expedition, cleared or failed. Room 10, 20, 30… is the boss. A new Depart starts at 0.
var rooms_attempted: int = 0
var run_id: int = 0
## Main-save guard: this run's pack and leftover loadout were already sent home.
var last_banked_run_id: int = 0
var run_seed: int = 0
var slots_total: int = 0
var slots_used: int = 0
var rest_slots_left: int = 0
var room_clock: float = 0.0
var room_seed: int = 0
var pack: Pack = Pack.new()
var party: Array[Dictionary] = []
var loadout: Dictionary = {}
var boss_paid: Array[int] = []
var room_log: Array[Dictionary] = []
var last_summary: Dictionary = {}
var exp_gained: int = 0
var essence_payback: int = 0
var last_room_exp: int = 0
## True while catch_up is inside advance_clock. Run actions and saves change nothing.
var catching_up: bool = false
## Last one-pass result: source, seconds_in, seconds_used, rooms, ms.
var last_catchup: Dictionary = {
	"source": "",
	"seconds_in": 0.0,
	"seconds_used": 0.0,
	"rooms": 0,
	"ms": 0,
}

## catch_up sets this so advance_clock does not emit changed per slot.
var _quiet: bool = false
var _forced_outcomes: Array[String] = []
var _test_run_seed: int = -1
var _rng := RandomNumberGenerator.new()
var _manual: FightState
## Live fight handed to idle Auto. Resumes if Manual returns before this room's 12 minutes.
var _handoff: FightState = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_rng.randomize()


func _process(delta: float) -> void:
	if not running:
		return
	if not _session_open():
		return
	var step := delta
	if has_node("/root/GameState"):
		step = GameState.active_play_delta(delta)
	process_frame_delta(step)


func debug_tools() -> bool:
	if OS.has_feature("manaforge_stable"):
		return false
	if has_node("/root/AnimPreviewHotkey"):
		return bool(AnimPreviewHotkey.debug_tools_enabled())
	return OS.is_debug_build()


func reset_for_new_game() -> void:
	deepest_depth = 0
	reaches_cleared = 0
	dojo_exp = 0
	_clear_pack_items()
	_end_run("dark")
	_clear_slot_memory()
	control = "idle"
	depth = 1
	hours = 1.0
	_forced_outcomes.clear()
	_test_run_seed = -1
	last_banked_run_id = 0
	changed.emit()


func on_ascend() -> void:
	## Deepest depth, the lifetime reach counter, and the dojo pool stay.
	## Mid-run Ascend: loot pack is lost; unused carried loadout returns to the bag.
	if running:
		_return_loadout_on_ascend()
		if pack != null:
			pack.clear()
	_end_run("dark")
	changed.emit()


func _return_loadout_on_ascend() -> void:
	for key_v: Variant in loadout.keys():
		var item_id: String = str(key_v)
		var qty: int = int(loadout[key_v])
		if qty > 0:
			_item_add(item_id, qty)
	loadout = {}


func max_start_depth() -> int:
	return maxi(1, deepest_depth)


func room_exp(room_depth: int) -> int:
	return maxi(0, int(round(10.0 * pow(float(maxi(1, room_depth)), 0.8))))


func is_boss_room() -> bool:
	return rooms_attempted > 0 and rooms_attempted % 10 == 0


func rooms_until_boss() -> int:
	## While the boss room is open this is 0. Otherwise it is how many rooms remain through that boss.
	var entered := rooms_attempted
	if running and (phase == "idle_room" or phase == "manual") and is_boss_room():
		return 0
	if entered % 10 == 0:
		return 10
	return 10 - (entered % 10)


func rooms_fight_cap() -> int:
	## Fight rooms still in this outing's timeline. Rest slots (spent or queued) are not rooms.
	var rest_blocked: int = maxi(0, slots_used - rooms_attempted)
	if phase == "rest":
		rest_blocked += rest_slots_left
	return maxi(rooms_attempted, slots_total - rest_blocked)


func boss_line() -> String:
	if rooms_until_boss() == 0:
		return "Boss room"
	return "Rooms until boss: %d" % rooms_until_boss()


func grant_salve(n: int) -> void:
	_item_add("heart_salve", n)


func grant_vial(n: int) -> void:
	_item_add("bile_vial", n)


func depart(start_depth: int, length_hours: float, _pace_unused: String, control_mode: String) -> String:
	## Legacy test path: no Essence charge and an empty loadout. Push pace is gone; the third arg is ignored.
	if running:
		return "busy"
	depth = clampi(start_depth, 1, max_start_depth())
	var picked: int = int(round(length_hours))
	hours = float(picked if HOURS.has(picked) else 1)
	elapsed = 0.0
	var rooms: int = int(hours) * SlotEngine.ROOMS_PER_HOUR
	return _begin_outing({
		"depth": depth,
		"rooms": rooms,
		"control": "manual" if control_mode == "manual" else "idle",
		"party": [{"member": "keeper", "row": "front"}],
		"loadout": {},
	})


func member_away(member: String) -> bool:
	if not running:
		return false
	for entry: Dictionary in party:
		if str(entry.get("member", "")) == member:
			return true
	return false


func away_members() -> Array[String]:
	var out: Array[String] = []
	if not running:
		return out
	for entry: Dictionary in party:
		out.append(str(entry.get("member", "")))
	return out


func set_test_run_seed(seed: int) -> void:
	## The next depart uses this 31-bit seed for both run_seed and run_id.
	_test_run_seed = seed & 0x7FFFFFFF


func depart_slots(cfg: Dictionary) -> String:
	if catching_up:
		return "busy"
	if running:
		return "busy"
	var party_err: String = _party_cfg_error(cfg)
	if party_err != "":
		return party_err
	var cleaned_loadout: Dictionary = _clean_loadout(cfg.get("loadout", {}))
	if not _loadout_owned(cleaned_loadout):
		return "bad_loadout"
	if not has_node("/root/GameState") or int(GameState.essence) < DEPART_ESSENCE:
		return "no_essence"
	GameState.add_resource(&"essence", -DEPART_ESSENCE)
	for key_v: Variant in cleaned_loadout.keys():
		var item_id: String = str(key_v)
		var qty: int = int(cleaned_loadout[key_v])
		if qty > 0:
			Backpack.try_spend(item_id, qty)
	var outing_cfg: Dictionary = cfg.duplicate(true)
	outing_cfg["loadout"] = cleaned_loadout
	var result: String = _begin_outing(outing_cfg)
	if result == "ok":
		_touch_adventure()
	return result


func _party_cfg_error(cfg: Dictionary) -> String:
	var raw_party: Variant = cfg.get("party", [])
	if typeof(raw_party) != TYPE_ARRAY or (raw_party as Array).is_empty():
		return "bad_party"
	var occupied: Dictionary = {}
	for entry_v: Variant in raw_party as Array:
		if typeof(entry_v) != TYPE_DICTIONARY:
			return "bad_party"
		var entry: Dictionary = entry_v as Dictionary
		var member: String = str(entry.get("member", ""))
		if member != "keeper" and member != "elaia" and member != "bramble":
			return "bad_party"
		if member == "bramble" and (not has_node("/root/GameState") or not GameState.bramble_joined()):
			return "bad_party"
		if SlotEngine.member_stats(member).is_empty():
			return "bad_party"
		if entry.has("cell"):
			var cell: int = int(entry.get("cell", -1))
			if cell < 0 or cell > 2:
				return "bad_party"
			var row: String = "back" if str(entry.get("row", "")) == "back" else "front"
			var key: String = "%s:%d" % [row, cell]
			if occupied.has(key):
				return "bad_party"
			occupied[key] = true
	return ""


func _loadout_owned(lo: Dictionary) -> bool:
	if lo.size() > 2:
		return false
	for key_v: Variant in lo.keys():
		var qty: int = int(lo[key_v])
		if qty <= 0 or qty > 100:
			return false
		if _item_count(str(key_v)) < qty:
			return false
	return true


func _begin_outing(cfg: Dictionary) -> String:
	var built: Array[Dictionary] = []
	var raw_party: Variant = cfg.get("party", [])
	for entry_v: Variant in raw_party as Array:
		var entry: Dictionary = (entry_v as Dictionary).duplicate(true)
		var member: String = str(entry.get("member", ""))
		var stats: Dictionary = SlotEngine.member_stats(member)
		entry["member"] = member
		entry["row"] = "back" if str(entry.get("row", "")) == "back" else "front"
		if entry.has("cell"):
			entry["cell"] = clampi(int(entry.get("cell", 1)), 0, 2)
		entry["stats"] = stats
		built.append(entry)
	depth = clampi(maxi(1, int(cfg.get("depth", depth))), 1, max_start_depth())
	control = "manual" if str(cfg.get("control", "idle")) == "manual" else "idle"
	var fresh_seed: int = _rng.randi() & 0x7FFFFFFF
	var fresh_id: int = _rng.randi() & 0x7FFFFFFF
	if _test_run_seed >= 0:
		fresh_seed = _test_run_seed & 0x7FFFFFFF
		fresh_id = fresh_seed
		_test_run_seed = -1
	run_seed = fresh_seed
	run_id = fresh_id
	slots_total = maxi(1, int(cfg.get("rooms", 1)))
	slots_used = 0
	rooms_attempted = 0
	run_clears = 0
	rest_slots_left = 0
	room_clock = 0.0
	exp_gained = 0
	essence_payback = 0
	last_room_exp = 0
	boss_paid = []
	room_log = []
	last_summary = {}
	pack = Pack.new()
	loadout = _clean_loadout(cfg.get("loadout", {}))
	party = built
	_handoff = null
	elapsed = 0.0
	running = true
	_begin_room()
	_set_lantern("amber")
	_remember_expedition()
	changed.emit()
	party_changed.emit()
	return "ok"


func debug_force_outcomes(list: Array) -> void:
	## Queues idle outcomes for the next resolves. Ignored outside debug tools.
	## Untyped Array so headless `call()` can pass a plain array.
	if not debug_tools():
		return
	_forced_outcomes.clear()
	for outcome_v: Variant in list:
		var outcome: String = str(outcome_v)
		if outcome == "win" or outcome == "flee" or outcome == "overwhelmed":
			_forced_outcomes.append(outcome)


func debug_finish_run(reason: String = "finished") -> void:
	if not debug_tools() or not running:
		return
	var r: String = reason if reason != "" else "finished"
	_finish_run(r)


func debug_set_depths(depth_v: int, deepest_v: int) -> void:
	if not debug_tools():
		return
	depth = maxi(1, depth_v)
	deepest_depth = maxi(depth, deepest_v)
	changed.emit()


func debug_set_dojo_exp(amount: int) -> void:
	if not debug_tools():
		return
	dojo_exp = maxi(0, amount)
	changed.emit()


func debug_set_reaches_cleared(n: int) -> void:
	if not debug_tools():
		return
	reaches_cleared = maxi(0, n)
	changed.emit()


func debug_add_pack(item_id: String, n: int) -> void:
	if not debug_tools():
		return
	if pack != null:
		pack.add(item_id, n)


func debug_set_echo_02(resolved: bool, outcome: String, fee_paid: bool) -> void:
	if not debug_tools():
		return
	GameState.echo_02_resolved = resolved
	GameState.echo_02_outcome = outcome if outcome == "spare" or outcome == "flee" or outcome == "ko" else ""
	GameState.echo_02_fee_paid = fee_paid
	GameState.echo_flags_changed.emit()


func set_control(mode: String) -> void:
	if catching_up:
		return
	if mode != "idle" and mode != "manual":
		return
	## Board Idle mid-fight is the same hand-off as the arena Idle button.
	if mode == "idle" and running and phase == "manual":
		hand_to_idle()
		return
	control = mode
	if mode == "manual" and running and phase == "rest":
		rest_slots_left = 0
		room_clock = 0.0
		_begin_room()
		changed.emit()
		return
	if not running or phase == "rest" or phase == "home":
		changed.emit()
		return
	if phase == "idle_room" and mode == "manual":
		if _handoff != null:
			## Within this room's 12 minutes the same fight comes back. Not a new attempt.
			_manual = _handoff
			_manual.controller = "manual"
			_handoff = null
			phase = "manual"
			BattleView.open_reach_fight(_manual)
			if has_node("/root/GameState") and has_node("/root/ContentStrings"):
				GameState.status_message.emit(ContentStrings.get_text("adv_handoff_resumed"))
			_touch_adventure()
		elif not _start_fight():
			control = "idle"
	changed.emit()


func handoff_pending() -> bool:
	return _handoff != null


func hand_to_idle() -> String:
	## The arena Idle button and set_control("idle") during a live manual fight.
	if catching_up:
		return "invalid"
	if not running or phase != "manual" or _manual == null or _manual.outcome() != "":
		return "invalid"
	_handoff = _manual
	_handoff.controller = "idle_pending"
	_manual = null
	phase = "idle_room"
	room_clock = 0.0
	room_left = ROOM_SEC
	control = "idle"
	_close_view()
	_touch_adventure()
	changed.emit()
	return "ok"


func apply_offline_seconds(closed_sec: float) -> void:
	## Wall-clock seconds only. The play-speed button does not apply.
	if closed_sec <= 0.0 or not running:
		return
	catch_up(closed_sec, "load")


func process_frame_delta(step: float) -> void:
	## The frame step after play speed. Tests drive this directly.
	if step > BIG_DELTA_SEC:
		catch_up(step, "frame")
		return
	advance_clock(step)


func catch_up(seconds: float, source: String) -> Dictionary:
	## One pass. changed fires once at the end. Time after the run ends is dropped.
	var started_ms: int = Time.get_ticks_msec()
	var elapsed_before: float = elapsed
	var rooms_before: int = room_log.size()
	catching_up = true
	_quiet = true
	advance_clock(maxf(0.0, seconds))
	_quiet = false
	catching_up = false
	var used: float = maxf(0.0, elapsed - elapsed_before)
	if used > seconds and seconds >= 0.0:
		used = seconds
	last_catchup = {
		"source": source,
		"seconds_in": seconds,
		"seconds_used": used,
		"rooms": room_log.size() - rooms_before,
		"ms": Time.get_ticks_msec() - started_ms,
	}
	changed.emit()
	return last_catchup


func capture_offline_snapshot() -> Dictionary:
	## Point-in-time view so a catch-up can report rooms, EXP, and how the run ended.
	var pack_items: Dictionary = {}
	if pack != null:
		var packed: Dictionary = pack.to_dict()
		var items_v: Variant = packed.get("items", {})
		if typeof(items_v) == TYPE_DICTIONARY:
			pack_items = (items_v as Dictionary).duplicate()
	var log: Array = []
	for entry: Dictionary in room_log:
		log.append({"room": int(entry.get("room", 0)), "outcome": str(entry.get("outcome", ""))})
	var banked: Dictionary = {}
	var banked_v: Variant = last_summary.get("banked", {})
	if typeof(banked_v) == TYPE_DICTIONARY:
		banked = (banked_v as Dictionary).duplicate()
	return {
		"running": running,
		"phase": phase,
		"room_count": room_log.size(),
		"rooms_attempted": rooms_attempted,
		"exp_gained": exp_gained,
		"dojo_exp": dojo_exp,
		"pack": pack_items,
		"reason": str(last_summary.get("reason", "")),
		"banked": banked,
		"log": log,
	}


func advance_clock(seconds: float) -> void:
	## One slot at a time. Idle rooms resolve only when the 12 minutes are up.
	## Manual rooms ignore the clock. Elapsed is display only and never ends a run.
	## _quiet (set by catch_up) skips the closing changed emit.
	var left: float = maxf(0.0, seconds)
	var guard: int = 0
	while left > 0.0000001 and running and guard < 10000:
		guard += 1
		if phase == "manual":
			elapsed += left
			left = 0.0
			break
		if phase != "idle_room" and phase != "rest":
			break
		var need: float = SlotEngine.ROOM_SEC - room_clock
		if need <= 0.0000001:
			_complete_slot()
			continue
		var step: float = minf(left, need)
		elapsed += step
		room_clock += step
		left -= step
		if room_clock + 0.0000001 >= SlotEngine.ROOM_SEC:
			_complete_slot()
	if not _quiet:
		changed.emit()


func fight_active() -> bool:
	return _manual != null and running and phase == "manual"


func manual_fight() -> FightState:
	return _manual


func on_manual_outcome(outcome: String) -> void:
	if not running or phase != "manual" or _manual == null:
		return
	## A restored fight opens the view, which reports the outcome again. The room was already paid.
	if _outcome_already_logged(outcome):
		return
	match outcome:
		"win":
			slots_used += 1
			loadout = _manual.loadout.duplicate()
			var boss: bool = is_boss_room()
			var loot: Dictionary = RoomLoot.roll(depth, party.size(), boss, RoomLoot.loot_rng(room_seed))
			var exp_mult: int = 2 if boss else 1
			last_room_exp = room_exp(depth) * exp_mult
			_apply_room_win(boss, loot)
			var entry := {
				"room": rooms_attempted,
				"depth": depth,
				"outcome": "win",
				"boss": boss,
			}
			room_log.append(entry)
			room_resolved.emit(entry.duplicate())
		"flee":
			slots_used += 1
			_finish_run("flee")
		"overwhelmed":
			slots_used += 1
			pack.clear()
			_finish_run("overwhelmed")
		_:
			push_error("Reach: unknown manual outcome %s" % outcome)
	changed.emit()
	_touch_adventure()


func manual_choice(choice: String) -> String:
	if catching_up:
		return "busy"
	if not running or phase != "manual":
		return "invalid"
	if room_log.is_empty() or str(room_log[room_log.size() - 1].get("outcome", "")) != "win":
		return "invalid"
	var result: String = "invalid"
	match choice:
		"continue":
			if slots_used >= slots_total:
				_finish_run("finished")
				return "finished"
			_begin_room()
			result = "continue"
		"deeper":
			depth += 1
			if slots_used >= slots_total:
				_finish_run("finished")
				return "finished"
			_begin_room()
			result = "deeper"
		"home":
			_finish_run("head_home")
			return "home"
		_:
			return "invalid"
	_touch_adventure()
	return result


func _outcome_already_logged(outcome: String) -> bool:
	if room_log.is_empty():
		return false
	var last: Dictionary = room_log[room_log.size() - 1]
	return int(last.get("room", -1)) == rooms_attempted and str(last.get("outcome", "")) == outcome


func note_fight_action() -> void:
	## BattleView calls this after every reach-mode step, including beast steps.
	if _manual == null or not running or phase != "manual":
		return
	sync_manual_loadout()
	_touch_adventure()


func sync_manual_loadout() -> void:
	if _manual == null:
		return
	loadout = _manual.loadout.duplicate()


func restore_manual_fight(fight: FightState) -> void:
	## The view closes itself on load_completed, so open on the next idle frame.
	if fight == null:
		return
	_manual = fight
	phase = "manual"
	running = true
	sync_manual_loadout()
	call_deferred("_open_restored_manual_fight")


func _open_restored_manual_fight() -> void:
	if _manual == null or not running or phase != "manual":
		return
	_open_view()


func capture_run_block() -> Dictionary:
	## The current run only. Lifetime counters stay on the main save.
	return {
		"running": running,
		"control": control,
		"depth": depth,
		"hours": hours,
		"elapsed": elapsed,
		"room_left": room_left,
		"phase": phase,
		"run_clears": run_clears,
		"rooms_attempted": rooms_attempted,
		"run_id": run_id,
		"run_seed": run_seed,
		"room_seed": room_seed,
		"slots_total": slots_total,
		"slots_used": slots_used,
		"rest_slots_left": rest_slots_left,
		"room_clock": room_clock,
		"exp_gained": exp_gained,
		"essence_payback": essence_payback,
		"pack": pack.to_dict() if pack != null else {"items": {}},
		"party": party.duplicate(true),
		"loadout": loadout.duplicate(),
		"boss_paid": boss_paid.duplicate(),
		"room_log": room_log.duplicate(true),
		"last_summary": last_summary.duplicate(true),
		"handoff": _handoff.to_dict() if _handoff != null else null,
	}


func apply_run_block(data: Dictionary) -> void:
	## Overlays the current run. Does not touch lifetime counters or last_banked_run_id.
	if data.is_empty():
		return
	control = "manual" if str(data.get("control", "idle")) == "manual" else "idle"
	depth = maxi(1, int(data.get("depth", 1)))
	hours = float(data.get("hours", 1.0))
	elapsed = maxf(0.0, float(data.get("elapsed", 0.0)))
	room_left = maxf(0.0, float(data.get("room_left", 0.0)))
	run_clears = maxi(0, int(data.get("run_clears", 0)))
	rooms_attempted = maxi(0, int(data.get("rooms_attempted", 0)))
	run_id = int(data.get("run_id", 0))
	run_seed = int(data.get("run_seed", 0))
	room_seed = int(data.get("room_seed", 0))
	slots_total = maxi(0, int(data.get("slots_total", 0)))
	slots_used = maxi(0, int(data.get("slots_used", 0)))
	rest_slots_left = maxi(0, int(data.get("rest_slots_left", 0)))
	room_clock = clampf(float(data.get("room_clock", 0.0)), 0.0, SlotEngine.ROOM_SEC)
	exp_gained = maxi(0, int(data.get("exp_gained", 0)))
	essence_payback = maxi(0, int(data.get("essence_payback", 0)))
	var pack_v: Variant = data.get("pack", {})
	pack = Pack.from_dict(pack_v if typeof(pack_v) == TYPE_DICTIONARY else {})
	party = _clean_party(data.get("party", []))
	loadout = _clean_loadout(data.get("loadout", {}))
	boss_paid = _clean_boss_paid(data.get("boss_paid", []))
	room_log = _clean_room_log(data.get("room_log", []))
	last_summary = _clean_summary(data.get("last_summary", {}))
	var saved_phase := str(data.get("phase", "home"))
	running = bool(data.get("running", false))
	if not running:
		_end_run(str(GameState.expedition_lantern) if has_node("/root/GameState") else "dark")
		return
	if saved_phase != "rest" and saved_phase != "idle_room" and saved_phase != "manual":
		saved_phase = "idle_room"
	phase = saved_phase
	_manual = null
	_handoff = null
	var handoff_v: Variant = data.get("handoff", null)
	if typeof(handoff_v) == TYPE_DICTIONARY and not (handoff_v as Dictionary).is_empty():
		_handoff = FightState.from_dict(handoff_v)
	_close_view()
	changed.emit()


func capture_save_fields() -> Dictionary:
	var run := capture_run_block()
	if str(run.get("phase", "")) == "manual":
		run["phase"] = "idle_room"
	run["deepest_depth"] = deepest_depth
	run["reaches_cleared"] = reaches_cleared
	run["dojo_exp"] = dojo_exp
	run["last_banked_run_id"] = last_banked_run_id
	return {
		"reach": run,
		"expedition": _capture_expedition(),
	}


func apply_save_fields(data: Dictionary) -> void:
	if data.is_empty():
		reset_for_new_game()
		return
	deepest_depth = maxi(0, int(data.get("deepest_depth", 0)))
	reaches_cleared = maxi(0, int(data.get("reaches_cleared", 0)))
	dojo_exp = maxi(0, int(data.get("dojo_exp", 0)))
	last_banked_run_id = maxi(0, int(data.get("last_banked_run_id", 0)))
	## A main save stores a manual room as idle. The adventure file keeps the live phase.
	var run_data: Dictionary = data.duplicate(true)
	var saved_phase := str(run_data.get("phase", "home"))
	if saved_phase != "rest" and saved_phase != "idle_room":
		saved_phase = "idle_room"
	run_data["phase"] = saved_phase
	apply_run_block(run_data)


func default_save_fields() -> Dictionary:
	return {
		"deepest_depth": 0,
		"reaches_cleared": 0,
		"dojo_exp": 0,
		"running": false,
		"control": "idle",
		"depth": 1,
		"hours": 1.0,
		"elapsed": 0.0,
		"room_left": 0.0,
		"phase": "home",
		"run_clears": 0,
		"rooms_attempted": 0,
		"run_id": 0,
		"last_banked_run_id": 0,
		"run_seed": 0,
		"room_seed": 0,
		"slots_total": 0,
		"slots_used": 0,
		"rest_slots_left": 0,
		"room_clock": 0.0,
		"exp_gained": 0,
		"essence_payback": 0,
		"pack": {"items": {}},
		"party": [],
		"loadout": {},
		"boss_paid": [],
		"room_log": [],
		"last_summary": {},
		"handoff": null,
	}


func apply_expedition(data: Dictionary) -> void:
	## Empty means "derive it from the run we just applied". A saved block wins, including its summary.
	if data.is_empty():
		expedition = {}
		_remember_expedition()
		return
	expedition = data.duplicate(true)
	if str(expedition.get("status", "")) == "":
		_remember_expedition()


func _capture_expedition() -> Dictionary:
	## Status follows the live run. Other keys stay so later jobs can add defaults.
	var out: Dictionary = expedition.duplicate(true)
	if running:
		out["status"] = "out"
		out.erase("summary")
	elif _lantern() == "cyan":
		out["status"] = "finished_unseen"
	else:
		out["status"] = "home"
		out.erase("summary")
	return out


func _remember_expedition() -> void:
	expedition = _capture_expedition()


func _lantern() -> String:
	if not has_node("/root/GameState"):
		return "dark"
	var state := str(GameState.expedition_lantern)
	if state != "amber" and state != "cyan":
		return "dark"
	return state


func _item_count(item_id: String) -> int:
	if not has_node("/root/Backpack"):
		return 0
	return Backpack.get_count(item_id)


func _item_add(item_id: String, amount: int) -> void:
	if amount == 0 or not has_node("/root/Backpack"):
		return
	if amount > 0:
		Backpack.add_item(item_id, amount)
	else:
		Backpack.try_spend(item_id, -amount)


func _item_set(item_id: String, amount: int) -> void:
	if not has_node("/root/Backpack"):
		return
	Backpack.set_count(item_id, maxi(0, amount))


func _clear_pack_items() -> void:
	for item_id: String in PACK_ITEM_IDS:
		_item_set(item_id, 0)


func _begin_room() -> void:
	rooms_attempted += 1
	_handoff = null
	room_seed = SlotEngine.room_seed_for(run_seed, rooms_attempted)
	room_clock = 0.0
	room_left = ROOM_SEC
	## A catch-up pass keeps the room idle, including a fight that was saved as manual.
	if control == "manual" and not catching_up and _start_fight():
		_touch_adventure()
		return
	phase = "idle_room"
	_manual = null
	_close_view()
	_touch_adventure()


func _start_fight() -> bool:
	var room: Array[Dictionary] = SlotEngine.build_room(depth, room_seed, is_boss_room())
	if room.is_empty():
		push_error("Reach: refusing to start a fight with no enemies")
		return false
	_manual = SlotEngine.fight_for_room(party, loadout, room, room_seed)
	_manual.start_fight()
	_manual.controller = "manual"
	phase = "manual"
	_open_view()
	return true


func _complete_slot() -> void:
	room_clock = 0.0
	if phase == "rest":
		slots_used += 1
		rest_slots_left -= 1
		if rest_slots_left <= 0:
			if slots_used >= slots_total:
				_finish_run("finished")
			else:
				_begin_room()
		return
	if phase == "idle_room":
		_resolve_slot_room()


func _resolve_slot_room() -> void:
	var forced: String = ""
	if not _forced_outcomes.is_empty():
		forced = str(_forced_outcomes.pop_front())
	var result: Dictionary = {}
	if forced == "win" or forced == "flee" or forced == "overwhelmed":
		result = _forced_room_result(forced)
		_handoff = null
	elif _handoff != null:
		result = _handoff_room_result()
		_handoff = null
	else:
		result = SlotEngine.resolve_idle_room(party, loadout, depth, rooms_attempted, room_seed)
	slots_used += 1
	var after_v: Variant = result.get("loadout_after", loadout)
	if typeof(after_v) == TYPE_DICTIONARY:
		loadout = (after_v as Dictionary).duplicate()
	var outcome: String = str(result.get("outcome", "overwhelmed"))
	var boss: bool = bool(result.get("boss", is_boss_room()))
	var entry := {
		"room": rooms_attempted,
		"depth": depth,
		"outcome": outcome,
		"boss": boss,
	}
	room_log.append(entry)
	if outcome == "win":
		var loot_v: Variant = result.get("loot", {})
		var loot: Dictionary = loot_v if typeof(loot_v) == TYPE_DICTIONARY else {}
		_apply_win(loot, int(result.get("exp_mult", 1)), boss)
		_continue_after_room()
	elif outcome == "flee":
		pack.halve()
		_continue_after_room()
	else:
		pack.clear()
		if slots_total - slots_used >= 2:
			phase = "rest"
			rest_slots_left = SlotEngine.REST_SLOTS
			room_clock = 0.0
			room_left = REST_SEC
			_manual = null
			_close_view()
		else:
			_finish_run("overwhelmed")
	room_resolved.emit(entry.duplicate())
	_touch_adventure()


func _handoff_room_result() -> Dictionary:
	## Finish the fight that was handed over, from its round, HP, Salves and RNG.
	var fight: FightState = _handoff
	var outcome: String = AutoPolicy.run_idle(fight)
	if outcome != "win" and outcome != "flee" and outcome != "overwhelmed":
		push_error("Reach: unexpected handoff outcome %s" % outcome)
		outcome = "overwhelmed"
	var boss: bool = is_boss_room()
	var loot: Dictionary = {}
	var exp_mult: int = 1
	if outcome == "win":
		loot = RoomLoot.roll(depth, party.size(), boss, RoomLoot.loot_rng(room_seed))
		exp_mult = 2 if boss else 1
	return {
		"outcome": outcome,
		"boss": boss,
		"loot": loot,
		"exp_mult": exp_mult,
		"loadout_after": fight.loadout.duplicate(),
		"salves_used": fight.salves_used,
		"rounds": fight.round,
		"fight": fight,
	}


func _forced_room_result(outcome: String) -> Dictionary:
	var boss: bool = is_boss_room()
	var loot: Dictionary = {}
	var exp_mult: int = 1
	if outcome == "win":
		loot = RoomLoot.roll(depth, party.size(), boss, RoomLoot.loot_rng(room_seed))
		exp_mult = 2 if boss else 1
	return {
		"outcome": outcome,
		"boss": boss,
		"loot": loot,
		"exp_mult": exp_mult,
		"loadout_after": loadout.duplicate(),
		"salves_used": 0,
		"rounds": 0,
		"fight": null,
	}


func _apply_room_win(boss: bool, loot: Dictionary) -> void:
	var exp_mult: int = 2 if boss else 1
	_apply_win(loot, exp_mult, boss)


func _apply_win(loot: Dictionary, exp_mult: int, boss: bool) -> void:
	if GameState.expedition_loot_mult() > 1.0 and not loot.is_empty():
		var scaled: Dictionary = {}
		for k: Variant in loot.keys():
			scaled[str(k)] = int(round(float(int(loot[k])) * GameState.expedition_loot_mult()))
		loot = scaled
	pack.add_all(loot)
	var gained: int = int(round(float(room_exp(depth) * maxi(1, exp_mult)) * GameState.dojo_exp_mult()))
	dojo_exp += gained
	exp_gained += gained
	reaches_cleared += 1
	run_clears += 1
	if depth > deepest_depth:
		deepest_depth = depth
	if boss and not boss_paid.has(rooms_attempted):
		if has_node("/root/GameState"):
			GameState.add_resource(&"essence", SlotEngine.BOSS_ESSENCE)
		essence_payback += SlotEngine.BOSS_ESSENCE
		boss_paid.append(rooms_attempted)


func _continue_after_room() -> void:
	if slots_used < slots_total:
		_begin_room()
	else:
		_finish_run("finished")


func _finish_run(reason: String) -> void:
	var already_banked: bool = run_id == last_banked_run_id
	if already_banked:
		push_warning("Reach: run %d was already banked; skipping a second bank" % run_id)
	var loadout_returned: Dictionary = {}
	if not already_banked:
		for key_v: Variant in loadout.keys():
			var item_id: String = str(key_v)
			var qty: int = int(loadout[key_v])
			if qty > 0:
				_item_add(item_id, qty)
				loadout_returned[item_id] = qty
	loadout = {}
	var banked: Dictionary = {}
	if not already_banked:
		if pack != null:
			banked = pack.bank_with_sturdy(reason, GameState.sturdy_pack_safe_ratio())
			if not banked.is_empty():
				GameState.note_first_pack_lost()
		last_banked_run_id = run_id
	_manual = null
	var keep_battle_view: bool = reason == "flee" or reason == "overwhelmed"
	last_summary = {
		"reason": reason,
		"rooms": slots_total,
		"rooms_cleared": run_clears,
		"banked": banked,
		"exp_gained": exp_gained,
		"essence_payback": essence_payback,
		"run_id": run_id,
		"loadout_returned": loadout_returned,
	}
	expedition["summary"] = last_summary.duplicate(true)
	var brought: bool = run_clears > 0 or not banked.is_empty()
	_end_run("cyan" if brought else "dark", keep_battle_view)
	party_changed.emit()
	if has_node("/root/SaveService"):
		SaveService.write_adventure()
		SaveService.clear_adventure()


func _touch_adventure() -> void:
	if not running or not has_node("/root/SaveService"):
		return
	SaveService.write_adventure()


func _end_run(lantern: String, keep_battle_view: bool = false) -> void:
	running = false
	phase = "home"
	room_left = 0.0
	room_clock = 0.0
	rest_slots_left = 0
	rooms_attempted = 0
	_manual = null
	_handoff = null
	if not keep_battle_view:
		_close_view()
	_set_lantern(lantern)
	_remember_expedition()


func _clear_slot_memory() -> void:
	run_id = 0
	run_seed = 0
	room_seed = 0
	slots_total = 0
	slots_used = 0
	rest_slots_left = 0
	room_clock = 0.0
	exp_gained = 0
	essence_payback = 0
	last_room_exp = 0
	pack = Pack.new()
	party = []
	loadout = {}
	boss_paid = []
	room_log = []
	last_summary = {}
	_handoff = null


func _clean_loadout(raw: Variant) -> Dictionary:
	var out: Dictionary = {}
	if typeof(raw) != TYPE_DICTIONARY:
		return out
	for key_v: Variant in (raw as Dictionary).keys():
		out[str(key_v)] = int((raw as Dictionary)[key_v])
	return out


func _clean_party(raw: Variant) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if typeof(raw) != TYPE_ARRAY:
		return out
	for entry_v: Variant in raw as Array:
		if typeof(entry_v) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_v
		var stats_v: Variant = entry.get("stats", {})
		var stats: Dictionary = {}
		if typeof(stats_v) == TYPE_DICTIONARY:
			for key_v: Variant in (stats_v as Dictionary).keys():
				var key: String = str(key_v)
				var stat_v: Variant = (stats_v as Dictionary)[key_v]
				if key == "attack":
					stats[key] = str(stat_v)
				elif key == "weapon_abilities":
					if stat_v is Array:
						stats[key] = (stat_v as Array).duplicate()
				else:
					stats[key] = _party_stat_int(stat_v, key)
		out.append({
			"member": str(entry.get("member", "")),
			"row": "back" if str(entry.get("row", "")) == "back" else "front",
			"stats": stats,
		})
	return out


static func _party_stat_int(raw: Variant, key: String, default_v: int = 5) -> int:
	if raw is int:
		return raw
	if raw is float:
		return int(raw)
	push_warning("Reach: party stat %s had non-numeric value %s; using %d" % [key, str(raw), default_v])
	return default_v


func _clean_boss_paid(raw: Variant) -> Array[int]:
	var out: Array[int] = []
	if typeof(raw) != TYPE_ARRAY:
		return out
	for entry_v: Variant in raw as Array:
		out.append(int(entry_v))
	return out


func _clean_room_log(raw: Variant) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if typeof(raw) != TYPE_ARRAY:
		return out
	for entry_v: Variant in raw as Array:
		if typeof(entry_v) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_v
		out.append({
			"room": int(entry.get("room", 0)),
			"depth": int(entry.get("depth", 1)),
			"outcome": str(entry.get("outcome", "")),
			"boss": bool(entry.get("boss", false)),
		})
	return out


func _clean_summary(raw: Variant) -> Dictionary:
	if typeof(raw) != TYPE_DICTIONARY or (raw as Dictionary).is_empty():
		return {}
	var src: Dictionary = raw
	var banked: Dictionary = {}
	var bank_v: Variant = src.get("banked", {})
	if typeof(bank_v) == TYPE_DICTIONARY:
		for key_v: Variant in (bank_v as Dictionary).keys():
			banked[str(key_v)] = int((bank_v as Dictionary)[key_v])
	var returned: Dictionary = {}
	var ret_v: Variant = src.get("loadout_returned", {})
	if typeof(ret_v) == TYPE_DICTIONARY:
		for key_v: Variant in (ret_v as Dictionary).keys():
			returned[str(key_v)] = int((ret_v as Dictionary)[key_v])
	return {
		"reason": str(src.get("reason", "")),
		"rooms": int(src.get("rooms", 0)),
		"rooms_cleared": int(src.get("rooms_cleared", 0)),
		"banked": banked,
		"exp_gained": int(src.get("exp_gained", 0)),
		"essence_payback": int(src.get("essence_payback", 0)),
		"run_id": int(src.get("run_id", 0)),
		"loadout_returned": returned,
	}


func _session_open() -> bool:
	return has_node("/root/SaveService") and SaveService.session_active


func _set_lantern(state: String) -> void:
	if not has_node("/root/GameState"):
		return
	if state != "amber" and state != "cyan" and state != "dark":
		state = "dark"
	GameState.expedition_lantern = state
	GameState.echo_flags_changed.emit()


func _open_view() -> void:
	if _manual == null:
		return
	BattleView.open_reach_fight(_manual)


func _close_view() -> void:
	if BattleView.is_open():
		BattleView.close_arena()
