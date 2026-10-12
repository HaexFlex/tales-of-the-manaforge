class_name SpawnRoller
extends RefCounted
## Headless room spawn roller. Matches the Director sim roll_room(), place_rows(), compositions().
## Returns placement data only; FightState builds fighters from it (job 19).


const SPAWN_TABLES_PATH: String = "res://data/spawn_tables.json"
const BEASTS_PATH: String = "res://data/beasts.json"
const MOSSMITE_ID: String = "foe_mossmite"

static var _spawn_data: Dictionary = {}
static var _beasts_by_id: Dictionary = {}
static var _mossmite: Dictionary = {}
static var _data_ready: bool = false


static func _ensure_data() -> void:
	if _data_ready:
		return
	_spawn_data = _read_json(SPAWN_TABLES_PATH)
	var beasts: Dictionary = _read_json(BEASTS_PATH)
	_beasts_by_id = {}
	for row_v: Variant in (beasts.get("species", []) as Array) + (beasts.get("variants", []) as Array):
		var row: Dictionary = row_v as Dictionary
		_beasts_by_id[str(row.get("id", ""))] = row
	_mossmite = {}
	for row_v: Variant in beasts.get("fillers", []) as Array:
		var filler: Dictionary = row_v as Dictionary
		if str(filler.get("id", "")) == MOSSMITE_ID:
			_mossmite = filler
	_data_ready = true


static func _read_json(path: String) -> Dictionary:
	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(text)
	return parsed as Dictionary if parsed is Dictionary else {}


static func budget(depth: int) -> int:
	_ensure_data()
	var b: Dictionary = _spawn_data.get("budget", {}) as Dictionary
	if depth <= 10:
		return int(b.get("base", 0)) + int(b.get("per_depth_to_10", 0)) * (depth - 1)
	return int(b.get("at_10", 0)) + int(b.get("per_depth_after_10", 0)) * (depth - 10)


static func _raw_weights_for(depth: int) -> Array:
	var tables: Array = _spawn_data.get("tables", []) as Array
	var best: Array = []
	for t_v: Variant in tables:
		var t: Dictionary = t_v as Dictionary
		if int(t.get("depth", 0)) <= depth:
			best = t.get("weights", []) as Array
	return best


static func table_for(depth: int) -> Array[Dictionary]:
	_ensure_data()
	var rows: Array[Dictionary] = []
	for w_v: Variant in _raw_weights_for(depth):
		var w: Dictionary = w_v as Dictionary
		var bid: String = str(w.get("beast", ""))
		var beast: Dictionary = _beasts_by_id.get(bid, {}) as Dictionary
		rows.append({
			"beast": bid,
			"weight": int(w.get("weight", 0)),
			"threat": int(beast.get("threat", 0)),
			"attack": str(beast.get("attack", "physical")),
		})
	return rows


static func compositions(depth: int) -> Array:
	_ensure_data()
	var fill: Dictionary = _spawn_data.get("fill", {}) as Dictionary
	var max_beasts: int = int(fill.get("max_beasts", 6))
	var pool: Array[Dictionary] = []
	for row: Dictionary in table_for(depth):
		pool.append({"id": str(row["beast"]), "threat": int(row["threat"])})
	var found: Dictionary = {}
	_comp_rec(pool, budget(depth), max_beasts, 0, [], 0, found)
	var keys: Array[String] = []
	for k: Variant in found.keys():
		keys.append(str(k))
	keys.sort()
	var out: Array = []
	for key: String in keys:
		var ids: PackedStringArray = key.split(",")
		var room: Array[String] = []
		for id: String in ids:
			if not id.is_empty():
				room.append(id)
		out.append(room)
	return out


static func _comp_rec(pool: Array[Dictionary], room_budget: int, max_beasts: int, start: int, chosen: Array, total: int, found: Dictionary) -> void:
	var rem: int = room_budget - total
	if not chosen.is_empty():
		var nothing_fits: bool = true
		for b: Dictionary in pool:
			if int(b["threat"]) <= rem:
				nothing_fits = false
		if chosen.size() == max_beasts or nothing_fits:
			var ids: Array = chosen.duplicate()
			ids.sort()
			found[",".join(PackedStringArray(ids))] = true
			return
	for i: int in range(start, pool.size()):
		var b: Dictionary = pool[i]
		if total + int(b["threat"]) <= room_budget:
			var next: Array = chosen.duplicate()
			next.append(str(b["id"]))
			_comp_rec(pool, room_budget, max_beasts, i, next, total + int(b["threat"]), found)


static func roll_room(depth: int, rng: BattleRng, boss: bool = false) -> Array[Dictionary]:
	_ensure_data()
	var fill: Dictionary = _spawn_data.get("fill", {}) as Dictionary
	var max_beasts: int = int(fill.get("max_beasts", 6))
	var table: Array[Dictionary] = table_for(depth)
	var rem: int = budget(depth)
	var picks: Array[Dictionary] = []
	var counts: Dictionary = {}
	while picks.size() < max_beasts:
		var options: Array[Dictionary] = []
		for row: Dictionary in table:
			if int(row["threat"]) <= rem:
				options.append(row)
		if options.is_empty():
			break
		var total_weight: int = 0
		for row: Dictionary in options:
			var bid: String = str(row["beast"])
			var w: int = int(row["weight"])
			if not counts.has(bid):
				w *= 2
			total_weight += w
		var r: int = rng.roll_die(total_weight) - 1
		var acc: int = 0
		var picked: Dictionary = options[0]
		for row: Dictionary in options:
			var bid: String = str(row["beast"])
			var w: int = int(row["weight"])
			if not counts.has(bid):
				w *= 2
			acc += w
			if r < acc:
				picked = row
				break
		var pid: String = str(picked["beast"])
		picks.append({"beast": pid, "threat": int(picked["threat"]), "attack": str(picked["attack"])})
		counts[pid] = int(counts.get(pid, 0)) + 1
		rem -= int(picked["threat"])
	return _place_rows(picks, boss)


static func _place_rows(picks: Array[Dictionary], boss: bool) -> Array[Dictionary]:
	var front: Array[Dictionary] = []
	var back: Array[Dictionary] = []
	for p: Dictionary in picks:
		if str(p["attack"]) == "magic":
			back.append(p)
		else:
			front.append(p)
	while front.size() > 3:
		back.append(front.pop_back())
	while back.size() > 3:
		front.append(back.pop_back())
	var out: Array[Dictionary] = []
	var slot: int = 0
	for p: Dictionary in front:
		out.append({
			"beast": str(p["beast"]),
			"row": "front",
			"slot": slot,
			"boss": false,
			"threat": int(p["threat"]),
		})
		slot += 1
	for p: Dictionary in back:
		out.append({
			"beast": str(p["beast"]),
			"row": "back",
			"slot": slot,
			"boss": false,
			"threat": int(p["threat"]),
		})
		slot += 1
	if boss and not out.is_empty():
		var best_i: int = 0
		for i: int in range(1, out.size()):
			var cur: Dictionary = out[i]
			var best: Dictionary = out[best_i]
			if int(cur["threat"]) > int(best["threat"]):
				best_i = i
			elif int(cur["threat"]) == int(best["threat"]) and int(cur["slot"]) < int(best["slot"]):
				best_i = i
		out[best_i]["boss"] = true
	return out


static func room_seed_rng(room_seed: int) -> BattleRng:
	var dice := BattleRng.new()
	dice.set_seed(BattleRng.mix_stream(room_seed, "spawn"))
	return dice


static func mossmite_def() -> Dictionary:
	_ensure_data()
	return _mossmite


static func mossmite_open_cost() -> int:
	return maxi(1, int(mossmite_def().get("threat_open", 7)))


static func mossmite_per_bug_cost() -> int:
	return maxi(1, int(mossmite_def().get("threat_per_extra_bug", 2)))


static func mossmite_cap() -> int:
	return maxi(1, int(mossmite_def().get("max_bugs", 10)))


static func mossmite_threat_for(bugs: int) -> int:
	## 7 for the first bug, +2 for each extra. A full swarm of 10 costs 25.
	var n: int = maxi(0, bugs)
	if n <= 0:
		return 0
	return mossmite_open_cost() + mossmite_per_bug_cost() * (n - 1)


static func mossmite_hp_for(bugs: int) -> int:
	return maxi(0, bugs) * maxi(1, int(mossmite_def().get("hp_per_bug", 1)))


static func mossmite_might(bugs: int) -> int:
	## ceil(n/2) - 2. Can be negative. A dead swarm (n = 0) keeps the offset.
	var spec: Dictionary = mossmite_def().get("might", {}) as Dictionary
	var div: int = int(spec.get("per_bug_ceil_div", 2))
	var off: int = int(spec.get("offset", -2))
	if div <= 0:
		div = 2
	if bugs <= 0:
		return off
	return int((bugs + div - 1) / float(div)) + off


static func mossmite_res(bugs: int) -> int:
	## floor(n/3). Recomputed from the living bugs, not stored as a flat stat.
	var spec: Dictionary = mossmite_def().get("res", {}) as Dictionary
	var div: int = int(spec.get("per_bug_floor_div", 3))
	var off: int = int(spec.get("offset", 0))
	if bugs <= 0 or div <= 0:
		return off
	return int(bugs / float(div)) + off


static func roll_room_with_mossmites(depth: int, rng: BattleRng, boss: bool = false) -> Array[Dictionary]:
	## Baseline beasts keep the slots place_rows gave them. Swarms are filler only.
	## Boss rooms are not simmed: no swarms there.
	var room: Array[Dictionary] = roll_room(depth, rng, boss)
	if boss:
		return room
	var spent: int = 0
	for entry: Dictionary in room:
		spent += int(entry.get("threat", 0))
	return fill_mossmites(room, budget(depth) - spent, rng)


static func fill_mossmites(room: Array[Dictionary], rem: int, rng: BattleRng) -> Array[Dictionary]:
	## Phase A opens one-bug swarms into empty front slots, then empty back slots.
	## Phase B spends the rest one bug at a time on a uniformly random swarm under the cap.
	## Leftover threat is discarded. place_rows is not run again.
	_ensure_data()
	var out: Array[Dictionary] = []
	var n_front: int = 0
	for entry: Dictionary in room:
		out.append(entry)
		if str(entry.get("row", "")) == "front":
			n_front += 1
	var open_cost: int = mossmite_open_cost()
	var per_cost: int = mossmite_per_bug_cost()
	var cap: int = mossmite_cap()
	var max_foes: int = int((_spawn_data.get("fill", {}) as Dictionary).get("max_beasts", 6))
	var swarms: Array[Dictionary] = []
	while out.size() < max_foes and rem >= open_cost:
		var row_name: String = "back"
		if n_front < 3:
			row_name = "front"
			n_front += 1
		var sw: Dictionary = {
			"beast": MOSSMITE_ID,
			"row": row_name,
			"slot": out.size(),
			"boss": false,
			"threat": open_cost,
			"bugs": 1,
			"swarm": true,
		}
		out.append(sw)
		swarms.append(sw)
		rem -= open_cost
	while rem >= per_cost:
		var growable: Array[Dictionary] = []
		for sw: Dictionary in swarms:
			if int(sw.get("bugs", 0)) < cap:
				growable.append(sw)
		if growable.is_empty():
			break
		var picked: Dictionary = growable[rng.roll_die(growable.size()) - 1]
		picked["bugs"] = int(picked.get("bugs", 1)) + 1
		picked["threat"] = int(picked.get("threat", open_cost)) + per_cost
		rem -= per_cost
	return out
