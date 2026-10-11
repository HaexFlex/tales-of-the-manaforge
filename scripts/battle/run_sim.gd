class_name RunSim
extends RefCounted
## Headless idle run preview for the expedition board. No autoload writes.


static func _room_exp(room_depth: int) -> int:
	## Same formula as Reach.room_exp; kept here so simulate never touches autoloads.
	return maxi(0, int(round(10.0 * pow(float(maxi(1, room_depth)), 0.8))))


static func _clean_loadout(raw: Variant) -> Dictionary:
	var out: Dictionary = {}
	if typeof(raw) != TYPE_DICTIONARY:
		return out
	for key_v: Variant in (raw as Dictionary).keys():
		var n: int = int((raw as Dictionary)[key_v])
		if n > 0:
			out[str(key_v)] = n
	return out


static func _build_party(raw: Variant) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if typeof(raw) != TYPE_ARRAY:
		return out
	for entry_v: Variant in raw as Array:
		if typeof(entry_v) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = (entry_v as Dictionary).duplicate(true)
		var member: String = str(entry.get("member", ""))
		if member != "keeper" and member != "elaia":
			continue
		var stats: Dictionary = SlotEngine.member_stats(member)
		if stats.is_empty():
			continue
		entry["member"] = member
		entry["row"] = "back" if str(entry.get("row", "")) == "back" else "front"
		entry["stats"] = stats
		out.append(entry)
	return out


static func _items_used(start: Dictionary, end: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	var keys: Dictionary = {}
	for key_v: Variant in start.keys():
		keys[str(key_v)] = true
	for key_v: Variant in end.keys():
		keys[str(key_v)] = true
	for key_v: Variant in keys.keys():
		var item_id: String = str(key_v)
		var used: int = int(start.get(item_id, 0)) - int(end.get(item_id, 0))
		if used > 0:
			out[item_id] = used
	return out


static func _strings() -> Node:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null("ContentStrings")


static func _lost_reason(room: int, outcome: String, fight: FightState, trace: Dictionary) -> String:
	var strings: Node = _strings()
	if strings == null:
		return ""
	if outcome == "flee":
		var flee_reason: String = str(trace.get("flee_reason", "below_half"))
		if flee_reason == "round_cap":
			return str(strings.call("get_text", "sim_reason_flee_rounds")).replace("{n}", str(room))
		return str(strings.call("get_text", "sim_reason_flee_half")).replace("{n}", str(room))
	var beast: String = str(trace.get("last_ko_by", ""))
	var beast_name: String = fight.display_name(beast) if beast != "" else ""
	if beast_name == "":
		beast_name = "the beasts"
	return str(strings.call("get_text", "sim_reason_overwhelmed")).replace("{n}", str(room)).replace("{beast}", beast_name)


static func simulate(cfg: Dictionary, sim_seed: int) -> Dictionary:
	var t0: int = Time.get_ticks_msec()
	var depth: int = maxi(1, int(cfg.get("depth", 1)))
	var rooms_total: int = maxi(1, int(cfg.get("rooms", 1)))
	var seed: int = sim_seed & 0x7FFFFFFF
	var pack: Pack = Pack.new()
	var loadout: Dictionary = _clean_loadout(cfg.get("loadout", {}))
	var loadout_start: Dictionary = loadout.duplicate()
	var party: Array[Dictionary] = _build_party(cfg.get("party", []))
	var slots_used: int = 0
	var rooms_attempted: int = 0
	var rooms_fought: int = 0
	var rooms_cleared: int = 0
	var exp: int = 0
	var essence_payback: int = 0
	var boss_paid: Array[int] = []
	var lost: Array[Dictionary] = []

	while slots_used < rooms_total:
		rooms_attempted += 1
		rooms_fought += 1
		var room_seed: int = SlotEngine.room_seed_for(seed, rooms_attempted)
		var boss: bool = SlotEngine.is_boss_index(rooms_attempted)
		var room: Array[Dictionary] = SlotEngine.build_room(depth, room_seed, boss)
		var fight: FightState = SlotEngine.fight_for_room(party, loadout, room, room_seed)
		fight.controller = "idle"
		var trace: Dictionary = {}
		var outcome: String = AutoPolicy.run_idle(fight, trace)
		if outcome != "win" and outcome != "flee" and outcome != "overwhelmed":
			outcome = "overwhelmed"
		loadout = fight.loadout.duplicate()
		slots_used += 1
		if outcome == "win":
			rooms_cleared += 1
			var loot: Dictionary = RoomLoot.roll(depth, party.size(), boss, RoomLoot.loot_rng(room_seed))
			pack.add_all(loot)
			var exp_mult: int = 2 if boss else 1
			exp += _room_exp(depth) * exp_mult
			if boss and not boss_paid.has(rooms_attempted):
				essence_payback += SlotEngine.BOSS_ESSENCE
				boss_paid.append(rooms_attempted)
			if slots_used < rooms_total:
				continue
			break
		if outcome == "flee":
			pack.halve()
			lost.append({
				"room": rooms_attempted,
				"outcome": outcome,
				"reason": _lost_reason(rooms_attempted, outcome, fight, trace),
			})
			if slots_used < rooms_total:
				continue
			break
		pack.clear()
		lost.append({
			"room": rooms_attempted,
			"outcome": outcome,
			"reason": _lost_reason(rooms_attempted, outcome, fight, trace),
		})
		if rooms_total - slots_used >= SlotEngine.REST_SLOTS:
			slots_used += SlotEngine.REST_SLOTS
			if slots_used >= rooms_total:
				break
			continue
		break

	var ms: int = Time.get_ticks_msec() - t0
	return {
		"rooms_total": rooms_total,
		"rooms_fought": rooms_fought,
		"rooms_cleared": rooms_cleared,
		"lost": lost,
		"banked": pack.banked_share(100),
		"exp": exp,
		"essence_payback": essence_payback,
		"items_used": _items_used(loadout_start, loadout),
		"ms": ms,
	}
