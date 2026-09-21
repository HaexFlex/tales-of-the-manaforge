extends Node
## Seven Keeper combat stats. Thin module beside GameState.
## Runestones spend Manashards for +1 rank. Cost is exponential; power is flat.
## Ranks persist through Ascend. Fate does not touch gather, Wisps, or handcraft.

signal ranks_changed(stat_id: StringName)

const DATA_PATH: String = "res://data/keeper_stats.json"
const STAT_ORDER: Array[StringName] = [
	&"might", &"arcana", &"resilience", &"ward", &"vitality", &"swiftness", &"fate"
]

var ranks: Dictionary = {}
var params: Dictionary = {}
var stats_data: Array = []
var _stat_index: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_load_tables()
	_ensure_keys()


func _load_tables() -> void:
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("KeeperStats: cannot open keeper_stats.json")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var root: Dictionary = parsed
	params = root.get("params", {}) as Dictionary
	var stats_v: Variant = root.get("stats", [])
	stats_data = stats_v if typeof(stats_v) == TYPE_ARRAY else []
	_stat_index.clear()
	for entry: Variant in stats_data:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = entry
		var sid: String = str(d.get("id", ""))
		if sid != "":
			_stat_index[sid] = d


func starting_base() -> int:
	return maxi(0, int(params.get("starting_base", 5)))


func _ensure_keys() -> void:
	var floor_at: int = starting_base()
	for sid: StringName in STAT_ORDER:
		var key: String = String(sid)
		if not ranks.has(key):
			ranks[key] = floor_at


func is_known_stat(stat_id: String) -> bool:
	return _stat_index.has(stat_id)


func get_stat_def(stat_id: String) -> Dictionary:
	var found: Variant = _stat_index.get(stat_id, {})
	return found if typeof(found) == TYPE_DICTIONARY else {}


func stat_display_name(stat_id: String) -> String:
	var def: Dictionary = get_stat_def(stat_id)
	var key: String = str(def.get("string_key", "stat_%s" % stat_id))
	var labeled: String = ContentStrings.get_text(key)
	if labeled != key and labeled != "":
		return labeled
	if not def.is_empty():
		return str(def.get("display_name", stat_id))
	return stat_id.capitalize()


func stat_role(stat_id: String) -> String:
	var def: Dictionary = get_stat_def(stat_id)
	var key: String = str(def.get("tooltip_key", "stat_%s_tooltip" % stat_id))
	if key != "":
		var labeled: String = ContentStrings.get_text(key)
		if labeled != key and labeled != "":
			return labeled
	return ""


func stat_color(stat_id: String) -> Color:
	var hex: String = str(get_stat_def(stat_id).get("color", "#888888"))
	return Color(hex)


func get_rank(stat_id: String) -> int:
	return int(ranks.get(stat_id, starting_base()))


## Purchases above the free starting base. The cost curve still starts at 0 → 100.
func purchased_rank(stat_id: String) -> int:
	return maxi(0, get_rank(stat_id) - starting_base())


func get_max_rank() -> int:
	return maxi(1, int(params.get("max_rank", 40)))


func power_per_rank() -> int:
	return maxi(1, int(params.get("power_per_rank", 1)))


## Flat combat power. Starts at starting_base; each purchase adds power_per_rank.
## Gear is added by Equipment, not here.
func get_base(stat_id: String) -> int:
	return get_rank(stat_id) * power_per_rank()


## Next purchase cost. -1 when the rank cap is reached.
func get_next_cost(stat_id: String) -> int:
	if not is_known_stat(stat_id):
		return -1
	if get_rank(stat_id) >= get_max_rank():
		return -1
	var bought: int = purchased_rank(stat_id)
	var base: int = int(params.get("cost_base", 100))
	var growth: float = float(params.get("cost_growth", 1.65))
	## floor(BASE * GROWTH^purchased). Fresh base 5 is purchased 0 and still costs BASE.
	return int(floor(float(base) * pow(growth, float(bought)) + 0.0000001))


func can_buy(stat_id: String) -> bool:
	return try_buy_reason(stat_id) == ""


func try_buy_reason(stat_id: String) -> String:
	if not is_known_stat(stat_id):
		return "unknown"
	if GameState.fruit_committed:
		return "pending_ascend"
	var cost: int = get_next_cost(stat_id)
	if cost < 0:
		return "maxed"
	if GameState.manashards < cost:
		return "cant_afford"
	return ""


func try_buy(stat_id: String) -> String:
	var reason: String = try_buy_reason(stat_id)
	if reason != "":
		return reason
	var cost: int = get_next_cost(stat_id)
	GameState.add_resource(&"manashards", -cost)
	set_rank(stat_id, get_rank(stat_id) + 1)
	return "ok"


func set_rank(stat_id: String, rank: int) -> void:
	if not is_known_stat(stat_id):
		return
	ranks[stat_id] = clampi(rank, starting_base(), get_max_rank())
	ranks_changed.emit(StringName(stat_id))


## Explicit lock: no stat, including Fate, feeds gather / Wisp / craft math.
func affects_gather(_stat_id: String) -> bool:
	return false


func affects_wisps(_stat_id: String) -> bool:
	return false


func affects_craft(_stat_id: String) -> bool:
	return false


func on_ascend() -> void:
	## Ranks stay. GameState still wipes the soft Manashard bank.
	pass


func reset_for_new_game() -> void:
	ranks.clear()
	_ensure_keys()
	ranks_changed.emit(&"")


func to_save_dict() -> Dictionary:
	return ranks.duplicate(true)


func apply_save_dict(data: Variant) -> void:
	ranks.clear()
	var src: Dictionary = data if typeof(data) == TYPE_DICTIONARY else {}
	var floor_at: int = starting_base()
	var cap: int = get_max_rank()
	for sid: StringName in STAT_ORDER:
		var key: String = String(sid)
		var raw: int = int(src.get(key, 0)) if src.has(key) else 0
		ranks[key] = clampi(maxi(raw, floor_at), floor_at, cap)
	ranks_changed.emit(&"")
