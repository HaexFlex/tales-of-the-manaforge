class_name SpawnRoller
extends RefCounted
## Headless room spawn roller. Matches the Director sim roll_room(), place_rows(), compositions().
## Returns placement data only; FightState builds fighters from it (job 19).


const SPAWN_TABLES_PATH: String = "res://data/spawn_tables.json"
const BEASTS_PATH: String = "res://data/beasts.json"

static var _spawn_data: Dictionary = {}
static var _beasts_by_id: Dictionary = {}
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
