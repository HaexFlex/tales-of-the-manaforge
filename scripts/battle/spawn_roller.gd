class_name SpawnRoller
extends RefCounted
## Headless room spawn roller. Matches the Director sim roll_room(), place_rows(), compositions().
## Returns placement data only; FightState builds fighters from it (job 19).


const SPAWN_TABLES_PATH: String = "res://data/spawn_tables.json"
const BEASTS_PATH: String = "res://data/beasts.json"
const MOSSMITE_ID: String = "foe_mossmite"

static var _spawn_data: Dictionary = {}
static var _beasts_by_id: Dictionary = {}
static var _species_of_beast: Dictionary = {}
static var _mossmite: Dictionary = {}
static var _data_ready: bool = false


static func _ensure_data() -> void:
	if _data_ready:
		return
	_spawn_data = _read_json(SPAWN_TABLES_PATH)
	var beasts: Dictionary = _read_json(BEASTS_PATH)
	_beasts_by_id = {}
	_species_of_beast = {}
	for row_v: Variant in (beasts.get("species", []) as Array) + (beasts.get("variants", []) as Array):
		var row: Dictionary = row_v as Dictionary
		var bid: String = str(row.get("id", ""))
		_beasts_by_id[bid] = row
		if row.has("variant_of"):
			_species_of_beast[bid] = str(row.get("variant_of", ""))
		else:
			_species_of_beast[bid] = bid
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
	var at_one: int = int(b.get("depth_1", 85))
	var step_from: int = maxi(2, int(b.get("step_from_depth", 2)))
	var initial_step: int = int(b.get("initial_step", 4))
	var band_len: int = maxi(1, int(b.get("depths_per_step_band", 10)))
	var step_inc: int = int(b.get("step_increase_per_band", 2))
	var d: int = maxi(1, depth)
	if d <= 1:
		return at_one
	var total: int = at_one
	var band: int = 0
	while true:
		var depth_start: int = step_from if band == 0 else step_from - 1 + band * band_len
		if d < depth_start:
			break
		var depth_end: int = step_from + band_len - 2 if band == 0 else depth_start + band_len - 1
		var last: int = mini(d, depth_end)
		var steps: int = last - depth_start + 1
		var step_size: int = initial_step + step_inc * band
		total += steps * step_size
		if last >= depth_end:
			band += 1
		else:
			break
	return total


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


static func species_key(beast_id: String) -> String:
	_ensure_data()
	return str(_species_of_beast.get(beast_id, beast_id))


static func species_variety_count(picks: Array) -> int:
	var seen: Dictionary = {}
	for row_v: Variant in picks:
		var row: Dictionary = row_v as Dictionary
		seen[species_key(str(row.get("beast", "")))] = true
	return seen.size()


static func _variety_count(picks: Array) -> int:
	return species_variety_count(picks)


static func _combo_sort_key(picks: Array) -> String:
	var ids: PackedStringArray = PackedStringArray()
	for row_v: Variant in picks:
		ids.append(str((row_v as Dictionary).get("beast", "")))
	ids.sort()
	return ",".join(ids)


static func _combo_table_weight(picks: Array, table: Array[Dictionary]) -> int:
	var by_id: Dictionary = {}
	for row: Dictionary in table:
		by_id[str(row["beast"])] = maxi(1, int(row["weight"]))
	var product: int = 1
	for row_v: Variant in picks:
		product *= int(by_id.get(str((row_v as Dictionary).get("beast", "")), 1))
	return maxi(1, product)


static func _combo_threat(picks: Array) -> int:
	var total: int = 0
	for row_v: Variant in picks:
		total += int((row_v as Dictionary).get("threat", 0))
	return total


static func _enumerate_combos(pool: Array[Dictionary], max_beasts: int, room_budget: int, start: int, chosen: Array, total: int, out: Array) -> void:
	if not chosen.is_empty():
		out.append(chosen.duplicate())
	if chosen.size() >= max_beasts:
		return
	for i: int in range(start, pool.size()):
		var row: Dictionary = pool[i]
		var threat: int = int(row["threat"])
		if threat <= 0 or total + threat > room_budget:
			continue
		var next: Array = chosen.duplicate()
		next.append(row)
		_enumerate_combos(pool, max_beasts, room_budget, i, next, total + threat, out)


static func _cheapest_beast_combo(pool: Array[Dictionary]) -> Array:
	if pool.is_empty():
		return []
	var best: Dictionary = pool[0]
	for row: Dictionary in pool:
		if int(row["threat"]) < int(best["threat"]):
			best = row
	return [best.duplicate()]


static func _max_combo_threat(pool: Array[Dictionary], max_beasts: int, room_budget: int) -> int:
	var combos: Array = []
	_enumerate_combos(pool, max_beasts, room_budget, 0, [], 0, combos)
	var best: int = 0
	for picks_v: Variant in combos:
		best = maxi(best, _combo_threat(picks_v as Array))
	return best


static func beast_floor_ratio() -> float:
	_ensure_data()
	var fill: Dictionary = _spawn_data.get("fill", {}) as Dictionary
	return float(fill.get("beast_floor_ratio", 0.9))


static func beast_fill_floor(depth: int) -> int:
	## Minimum beast threat when any combo reaches the configured floor ratio.
	var pool: Array[Dictionary] = table_for(depth)
	if pool.is_empty():
		return 0
	var room_budget: int = budget(depth)
	var best: int = _max_combo_threat(pool, int((_spawn_data.get("fill", {}) as Dictionary).get("max_beasts", 6)), room_budget)
	var floor90: int = int(ceil(beast_floor_ratio() * float(room_budget)))
	if best < floor90:
		return 0
	return floor90


static func roll_room(depth: int, rng: BattleRng, boss: bool = false) -> Array[Dictionary]:
	_ensure_data()
	var fill: Dictionary = _spawn_data.get("fill", {}) as Dictionary
	var max_beasts: int = int(fill.get("max_beasts", 6))
	var table: Array[Dictionary] = table_for(depth)
	var room_budget: int = budget(depth)
	var combos: Array = []
	_enumerate_combos(table, max_beasts, room_budget, 0, [], 0, combos)
	if combos.is_empty():
		var fallback: Array = _cheapest_beast_combo(table)
		if fallback.is_empty():
			return _place_rows([], boss)
		combos = [fallback]
	var best_threat: int = 0
	for picks_v: Variant in combos:
		best_threat = maxi(best_threat, _combo_threat(picks_v as Array))
	var floor90: int = int(ceil(beast_floor_ratio() * float(room_budget)))
	var candidates: Array = []
	if best_threat >= floor90:
		for picks_v: Variant in combos:
			var picks: Array = picks_v as Array
			if _combo_threat(picks) >= floor90:
				candidates.append(picks)
	else:
		for picks_v: Variant in combos:
			var picks: Array = picks_v as Array
			if _combo_threat(picks) == best_threat:
				candidates.append(picks)
	var tier: Array = []
	var tier_variety: int = 0
	for picks_v: Variant in candidates:
		var picks: Array = picks_v as Array
		var variety: int = _variety_count(picks)
		if variety > tier_variety:
			tier.clear()
			tier_variety = variety
		if variety == tier_variety:
			tier.append(picks)
	if tier.is_empty():
		tier = candidates
	tier.sort_custom(func(a: Array, b: Array) -> bool:
		return _combo_sort_key(a) < _combo_sort_key(b)
	)
	var pick_i: int = 0
	if tier.size() > 1:
		var total_weight: int = 0
		var weights: Array[int] = []
		for picks_v: Variant in tier:
			var w: int = _combo_table_weight(picks_v as Array, table)
			weights.append(w)
			total_weight += w
		var roll: int = rng.roll_die(total_weight) - 1
		var acc: int = 0
		for i: int in range(weights.size()):
			acc += weights[i]
			if roll < acc:
				pick_i = i
				break
	var picked: Array = tier[pick_i] as Array
	var picks: Array[Dictionary] = []
	for row_v: Variant in picked:
		var row: Dictionary = (row_v as Dictionary).duplicate()
		picks.append({
			"beast": str(row["beast"]),
			"threat": int(row["threat"]),
			"attack": str(row["attack"]),
		})
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
	## Beasts fill first (search + variety). Swarms spend leftover threat only.
	## Boss rooms are not simmed: no swarms there.
	var room: Array[Dictionary] = roll_room(depth, rng, boss)
	if boss:
		return room
	var spent: int = 0
	for entry: Dictionary in room:
		spent += int(entry.get("threat", 0))
	return fill_mossmites(room, budget(depth) - spent, rng)


static func fill_mossmites(room: Array[Dictionary], rem: int, _rng: BattleRng) -> Array[Dictionary]:
	## Grow the active swarm to 10 bugs before opening another. Swarms append after beasts.
	## Leftover threat under 2 is discarded. place_rows is not run again.
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
	while true:
		var progressed: bool = false
		if not swarms.is_empty():
			var active: Dictionary = swarms[swarms.size() - 1]
			if int(active.get("bugs", 0)) < cap and rem >= per_cost:
				active["bugs"] = int(active.get("bugs", 1)) + 1
				active["threat"] = int(active.get("threat", open_cost)) + per_cost
				rem -= per_cost
				progressed = true
				continue
		if out.size() < max_foes and rem >= open_cost:
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
			progressed = true
			continue
		if not progressed:
			break
	return out
