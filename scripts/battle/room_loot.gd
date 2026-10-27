class_name RoomLoot
extends RefCounted
## One cleared-room loot roll from spawn_tables.json → loot (job 23b).


const SPAWN_TABLES_PATH: String = "res://data/spawn_tables.json"

static var _loot: Dictionary = {}
static var _ready: bool = false


static func _ensure_data() -> void:
	if _ready:
		return
	var text: String = FileAccess.get_file_as_string(SPAWN_TABLES_PATH)
	var parsed: Variant = JSON.parse_string(text) if not text.is_empty() else null
	var root: Dictionary = parsed as Dictionary if parsed is Dictionary else {}
	_loot = root.get("loot", {}) as Dictionary
	_ready = true


static func depth_g(depth: int) -> float:
	_ensure_data()
	var curve: Dictionary = _loot.get("depth_curve", {}) as Dictionary
	var a: float = float(curve.get("a", 0.0))
	var d: int = maxi(1, depth)
	return 1.0 + a * (log(float(d)) / log(2.0))


static func loot_rng(room_seed: int) -> BattleRng:
	var rng: BattleRng = BattleRng.new()
	rng.set_seed(BattleRng.mix_stream(room_seed, "loot"))
	return rng


static func chance(rng: BattleRng, p: float) -> bool:
	return rng.roll_die(10000) <= int(round(p * 10000.0))


static func expected_herbs(depth: int, party_size: int) -> float:
	_ensure_data()
	var size_key: String = _size_key(party_size)
	var herbs: Dictionary = _loot.get("herbs_by_depth", {}) as Dictionary
	var base: Dictionary = herbs.get("base", {}) as Dictionary
	var row: Dictionary = base.get(size_key, {}) as Dictionary
	var avg: float = float(row.get("avg", 0.0))
	return avg * depth_g(depth)


static func roll(depth: int, party_size: int, boss: bool, rng: BattleRng) -> Dictionary:
	_ensure_data()
	var out: Dictionary = {}
	var size_key: String = _size_key(party_size)
	var g: float = depth_g(depth)

	# Briarwood
	var briar: Dictionary = _loot.get("briarwood", {}) as Dictionary
	var briar_base: Dictionary = briar.get("base", {}) as Dictionary
	var briar_row: Dictionary = briar_base.get(size_key, {}) as Dictionary
	var briar_n: int = int(briar_row.get("guaranteed", 0))
	if chance(rng, float(briar_row.get("bonus_chance", 0.0))):
		briar_n += 1
	_add_count(out, "briarwood", briar_n)

	# Herbs (base + depth extras, each typed)
	var herbs: Dictionary = _loot.get("herbs_by_depth", {}) as Dictionary
	var herb_base: Dictionary = herbs.get("base", {}) as Dictionary
	var herb_row: Dictionary = herb_base.get(size_key, {}) as Dictionary
	var herb_n: int = int(herb_row.get("guaranteed", 0))
	if chance(rng, float(herb_row.get("bonus_chance", 0.0))):
		herb_n += 1
	var avg: float = float(herb_row.get("avg", 0.0))
	var x: float = avg * (g - 1.0)
	var extra: int = int(floor(x))
	if chance(rng, x - float(extra)):
		extra += 1
	herb_n += extra
	var types: Array = herbs.get("types", []) as Array
	var type_weights: Array = herbs.get("type_weights", []) as Array
	for _i: int in herb_n:
		var herb_id: String = _pick_weighted(types, type_weights, rng)
		if herb_id != "":
			_add_count(out, herb_id, 1)

	# Bonus drop bundle
	if chance(rng, float(_loot.get("bonus_drop_chance", 0.0))):
		_roll_bonus_drop(out, depth, boss, g, rng)

	# Boss ×2 on briarwood and herbs only (bonus already used boss_mult).
	if boss:
		for id: String in ["briarwood", "glowcap", "bitterroot"]:
			if out.has(id):
				out[id] = int(out[id]) * 2

	return _drop_zeros(out)


static func _size_key(party_size: int) -> String:
	## Design v2: loot tier is solo (1) or duo (2+). Parties of 3–6 use the duo sheet.
	return "solo" if party_size <= 1 else "duo"


static func _add_count(out: Dictionary, item_id: String, n: int) -> void:
	if n <= 0:
		return
	out[item_id] = int(out.get(item_id, 0)) + n


static func _drop_zeros(out: Dictionary) -> Dictionary:
	var clean: Dictionary = {}
	for k: Variant in out.keys():
		var n: int = int(out[k])
		if n > 0:
			clean[str(k)] = n
	return clean


static func _pick_weighted(types: Array, weights: Array, rng: BattleRng) -> String:
	if types.is_empty():
		return ""
	var total: int = 0
	for w: Variant in weights:
		total += int(w)
	if total <= 0:
		return str(types[0])
	var roll: int = rng.roll_die(total)
	var acc: int = 0
	for i: int in types.size():
		var w: int = int(weights[i]) if i < weights.size() else 0
		if w <= 0:
			continue
		acc += w
		if roll <= acc:
			return str(types[i])
	return str(types[types.size() - 1])


static func _depth_band_index(depth: int) -> int:
	var contents: Dictionary = _loot.get("bonus_drop_contents", {}) as Dictionary
	var bands: Array = contents.get("depth_bands", []) as Array
	for i: int in bands.size():
		var band: Dictionary = bands[i] as Dictionary
		var min_d: int = int(band.get("min_depth", 1))
		var max_v: Variant = band.get("max_depth", null)
		if depth < min_d:
			continue
		if max_v == null:
			return i
		if depth <= int(max_v):
			return i
	return maxi(0, bands.size() - 1)


static func _roll_bonus_drop(out: Dictionary, depth: int, boss: bool, g: float, rng: BattleRng) -> void:
	var contents: Dictionary = _loot.get("bonus_drop_contents", {}) as Dictionary
	var groups: Array = contents.get("groups", []) as Array
	var band_i: int = _depth_band_index(depth)
	var never: Array = _loot.get("bonus_drop_never", []) as Array
	var boss_mult: int = int(contents.get("boss_mult", 1))

	var picks: Array[Dictionary] = []
	var total_w: int = 0
	for g_i: int in groups.size():
		var group: Dictionary = groups[g_i] as Dictionary
		var weights: Array = group.get("weights", []) as Array
		var w: int = int(weights[band_i]) if band_i < weights.size() else 0
		if w <= 0:
			continue
		picks.append({"group": group, "weight": w})
		total_w += w
	if total_w <= 0 or picks.is_empty():
		return

	var roll: int = rng.roll_die(total_w)
	var acc: int = 0
	var chosen: Dictionary = picks[0]["group"] as Dictionary
	for pick: Dictionary in picks:
		acc += int(pick["weight"])
		if roll <= acc:
			chosen = pick["group"] as Dictionary
			break

	var items: Array = chosen.get("items", []) as Array
	if items.is_empty():
		return
	var item_roll: int = rng.roll_die(items.size())
	var item_id: String = str(items[item_roll - 1])
	if never.has(item_id):
		push_error("RoomLoot: bonus_drop_never item %s in data" % item_id)
		return
	var qty: int = BattleResolver.round_half_up_number(float(chosen.get("base_qty", 0)) * g)
	if boss:
		qty *= boss_mult
	_add_count(out, item_id, qty)
