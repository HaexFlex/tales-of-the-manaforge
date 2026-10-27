extends Node
## Seven combat stats. Runestones spend shared Manashards per actor.
## R5: ranks_by_actor. Next rank cost = floor(cost_base * cost_growth^(trained - STAT_BASE_START)).
## Design v2 runestone table (trained value before buy): 5→100, 6→165, 7→272, 8→449, 9→741, …
## Example: Puff Arcana trained 8 → next point costs 449 Essence.

signal ranks_changed(stat_id: StringName)

const STAT_BASE_START: int = 5
const DATA_PATH: String = "res://data/keeper_stats.json"
const STAT_ORDER: Array[StringName] = [
	&"might", &"arcana", &"resilience", &"ward", &"vitality", &"swiftness", &"fate"
]
const RUNESTONE_ACTORS: PackedStringArray = [
	"keeper", "elaia", "puff", "moss_tortoise", "bramble"
]

const STAT_INK: Dictionary = {
	"might": Color8(170, 52, 40),
	"arcana": Color8(118, 64, 150),
	"resilience": Color8(104, 110, 40),
	"ward": Color8(46, 84, 150),
	"vitality": Color8(52, 120, 52),
	"swiftness": Color8(160, 104, 20),
	"fate": Color8(160, 60, 120),
}

var ranks: Dictionary = {}
var ranks_by_actor: Dictionary = {}
var params: Dictionary = {}
var stats_data: Array = []
var _stat_index: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_load_tables()
	_ensure_actor_ranks()


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


func stat_base_start() -> int:
	return STAT_BASE_START


func starting_base() -> int:
	return stat_base_start()


func _ensure_actor_ranks() -> void:
	for actor: String in RUNESTONE_ACTORS:
		_ensure_actor_keys(actor)


func _ensure_actor_keys(actor: String) -> void:
	if not ranks_by_actor.has(actor):
		ranks_by_actor[actor] = {}
	var bucket: Dictionary = ranks_by_actor[actor]
	for sid: StringName in STAT_ORDER:
		var key: String = String(sid)
		if not bucket.has(key):
			bucket[key] = 0


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


func stat_ink_color(stat_id: String) -> Color:
	if STAT_INK.has(stat_id):
		return STAT_INK[stat_id] as Color
	return stat_color(stat_id).darkened(0.45)


func get_rank(stat_id: String) -> int:
	return get_rank_for_actor("keeper", stat_id)


func get_rank_for_actor(actor: String, stat_id: String) -> int:
	_ensure_actor_keys(actor)
	var bucket: Variant = ranks_by_actor.get(actor, {})
	if typeof(bucket) != TYPE_DICTIONARY:
		return 0
	return int((bucket as Dictionary).get(stat_id, 0))


func get_max_rank() -> int:
	if params.has("max_rank"):
		return maxi(1, int(params.get("max_rank", 1)))
	return 1_000_000


func power_per_rank() -> int:
	return maxi(1, int(params.get("power_per_rank", 1)))


func sheet_base_for(actor: String, stat_id: String) -> int:
	if actor == "keeper":
		return stat_base_start()
	if actor == "elaia":
		return elaia_echo_base(stat_id)
	if has_node("/root/CompanionSheets") and CompanionSheets.has_actor(actor):
		return int(CompanionSheets.base_stats(actor).get(stat_id, 0))
	return 0


func trained_value(actor: String, stat_id: String) -> int:
	return sheet_base_for(actor, stat_id) + get_rank_for_actor(actor, stat_id) * power_per_rank()


func get_base(stat_id: String) -> int:
	return trained_value("keeper", stat_id)


func get_base_for(actor: String, stat_id: String) -> int:
	return trained_value(actor, stat_id)


func elaia_echo_base(stat_id: String) -> int:
	var stats: Dictionary = _echo_elaia_stats()
	if not stats.has(stat_id):
		return 0
	return int(stats[stat_id])


func _echo_elaia_stats() -> Dictionary:
	if has_node("/root/EchoChamber"):
		var live: Variant = EchoChamber.echo_def().get("stats", {})
		if typeof(live) == TYPE_DICTIONARY and not (live as Dictionary).is_empty():
			return live
	var file := FileAccess.open("res://data/echo_keeper_01.json", FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var stats: Variant = (parsed as Dictionary).get("stats", {})
	return stats if typeof(stats) == TYPE_DICTIONARY else {}


func get_next_cost(stat_id: String, actor: String = "keeper") -> int:
	return get_next_cost_for_actor(actor, stat_id)


func get_next_cost_for_actor(actor: String, stat_id: String) -> int:
	if not is_known_stat(stat_id):
		return -1
	if get_rank_for_actor(actor, stat_id) >= get_max_rank():
		return -1
	var base_cost: int = int(params.get("cost_base", 100))
	var growth: float = float(params.get("cost_growth", 1.65))
	var current: int = trained_value(actor, stat_id)
	## Exponent = trained − STAT_BASE_START (5). Matches Design v2 table; see file header.
	var exponent: int = maxi(0, current - stat_base_start())
	return int(floor(float(base_cost) * pow(growth, float(exponent)) + 0.0000001))


func can_buy(stat_id: String, actor: String = "keeper") -> bool:
	return try_buy_reason(stat_id, actor) == ""


func try_buy_reason(stat_id: String, actor: String = "keeper") -> String:
	if not is_known_stat(stat_id):
		return "unknown"
	if GameState.fruit_committed:
		return "pending_ascend"
	var cost: int = get_next_cost_for_actor(actor, stat_id)
	if cost < 0:
		return "maxed"
	if GameState.manashards < cost:
		return "cant_afford"
	return ""


func try_buy(stat_id: String, actor: String = "keeper") -> String:
	var reason: String = try_buy_reason(stat_id, actor)
	if reason != "":
		return reason
	var cost: int = get_next_cost_for_actor(actor, stat_id)
	GameState.add_resource(&"manashards", -cost)
	set_rank_for_actor(actor, stat_id, get_rank_for_actor(actor, stat_id) + 1)
	return "ok"


func set_rank(stat_id: String, rank: int) -> void:
	set_rank_for_actor("keeper", stat_id, rank)


func set_rank_for_actor(actor: String, stat_id: String, rank: int) -> void:
	if not is_known_stat(stat_id):
		return
	_ensure_actor_keys(actor)
	(ranks_by_actor[actor] as Dictionary)[stat_id] = clampi(rank, 0, get_max_rank())
	if actor == "keeper":
		ranks[stat_id] = get_rank_for_actor("keeper", stat_id)
	ranks_changed.emit(StringName(stat_id))


func affects_gather(_stat_id: String) -> bool:
	return false


func affects_wisps(_stat_id: String) -> bool:
	return false


func affects_craft(_stat_id: String) -> bool:
	return false


func on_ascend() -> void:
	pass


func reset_for_new_game() -> void:
	ranks.clear()
	ranks_by_actor.clear()
	_ensure_actor_ranks()
	ranks_changed.emit(&"")


func to_save_dict() -> Dictionary:
	return {"ranks_by_actor": ranks_by_actor.duplicate(true)}


func normalize_loaded_rank(present: bool, raw: int) -> int:
	if not present:
		return 0
	return clampi(raw, 0, get_max_rank())


func apply_save_dict(data: Variant) -> void:
	ranks.clear()
	ranks_by_actor.clear()
	if typeof(data) == TYPE_DICTIONARY:
		var src: Dictionary = data
		if src.has("ranks_by_actor") and typeof(src.get("ranks_by_actor")) == TYPE_DICTIONARY:
			ranks_by_actor = (src.get("ranks_by_actor") as Dictionary).duplicate(true)
		else:
			var legacy: Dictionary = {}
			for sid: StringName in STAT_ORDER:
				var key: String = String(sid)
				var present: bool = src.has(key)
				var raw: int = int(src.get(key, 0)) if present else 0
				legacy[key] = normalize_loaded_rank(present, raw)
			ranks_by_actor["keeper"] = legacy
	_ensure_actor_ranks()
	for sid: StringName in STAT_ORDER:
		ranks[String(sid)] = get_rank_for_actor("keeper", String(sid))
	ranks_changed.emit(&"")
