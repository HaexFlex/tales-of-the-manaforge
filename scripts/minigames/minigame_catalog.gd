class_name MinigameCatalog
extends RefCounted
## Which node plays which game. Numbers live in data/minigame_tuning.json.
## Hot Spots stands in Forge Glow's place at the Crucible, Anvil, and Reliquary.

const TUNING_PATH: String = "res://data/minigame_tuning.json"
const WINDOW_SIZE := Vector2(696, 472)
const PLAY_SIZE := Vector2(640, 320)
const PLAY_ORIGIN := Vector2(28, 70)

static var _data: Dictionary = {}
static var _ready: bool = false


static func _load() -> Dictionary:
	if _ready:
		return _data
	_ready = true
	if not FileAccess.file_exists(TUNING_PATH):
		push_error("MinigameCatalog: missing tuning")
		return _data
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(TUNING_PATH))
	if typeof(parsed) == TYPE_DICTIONARY:
		_data = parsed
	return _data


static func games() -> Dictionary:
	var raw: Variant = _load().get("games", {})
	return raw if typeof(raw) == TYPE_DICTIONARY else {}


static func game(game_id: String) -> Dictionary:
	var raw: Variant = games().get(game_id, {})
	return raw if typeof(raw) == TYPE_DICTIONARY else {}


static func playable_ids() -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for key: Variant in games().keys():
		var id: String = str(key)
		if id == "":
			continue
		out.append(id)
	out.sort()
	return out


static func kind(game_id: String) -> String:
	return str(game(game_id).get("kind", ""))


static func title(game_id: String) -> String:
	var named: String = str(game(game_id).get("title", ""))
	return named if named != "" else game_id


static func resource_id(game_id: String) -> String:
	return str(game(game_id).get("resource", ""))


static func hint(game_id: String, phone: bool) -> String:
	var row: Dictionary = game(game_id)
	if phone:
		return str(row.get("hint_phone", row.get("hint_pc", "")))
	return str(row.get("hint_pc", ""))


static func scene_path(game_id: String) -> String:
	return "res://scenes/minigames/%s.tscn" % game_id


## Steeping's brewing and cauldron stations are not in the world. The scene
## stays, and nothing offers it until a station exists and this flag flips.
static func is_reachable(game_id: String) -> bool:
	return bool(game(game_id).get("reachable", true))


static func game_for(node_id: String) -> String:
	for key: Variant in games().keys():
		var id: String = str(key)
		var nodes_v: Variant = game(id).get("nodes", [])
		if typeof(nodes_v) != TYPE_ARRAY:
			continue
		for entry: Variant in nodes_v as Array:
			if str(entry) == node_id:
				return id
	return ""


static func r_of(game_id: String) -> float:
	var row: Dictionary = game(game_id)
	if row.has("r"):
		return float(row.get("r", 0.0))
	if game_id == "steeping":
		var cycle: float = float(row.get("cycle_sec", 8.0))
		if cycle <= 0.0:
			return 0.0
		return 60.0 / cycle
	if game_id == "with_the_grain":
		var avg: float = grain_average_round(false)
		if avg <= 0.0:
			return 0.0
		return 60.0 / avg
	return 0.0


static func k_for(game_id: String, phone: bool = false) -> float:
	var row: Dictionary = game(game_id)
	if game_id == "woodsong":
		return MinigameMath.woodsong_k(false, float(row.get("r", 48.0)), int(row.get("heavy_every", 8)), float(row.get("heavy_mult", 2.0)))
	if game_id == "with_the_grain":
		return MinigameMath.grain_k(grain_average_round(phone))
	if row.has("k"):
		return float(row.get("k", 0.0))
	return MinigameMath.k_from_r(float(row.get("r", 0.0)))


static func woodsong_k(heavy: bool) -> float:
	var row: Dictionary = game("woodsong")
	return MinigameMath.woodsong_k(heavy, float(row.get("r", 48.0)), int(row.get("heavy_every", 8)), float(row.get("heavy_mult", 2.0)))


static func grain_shapes() -> Array:
	var raw: Variant = game("with_the_grain").get("shapes", [])
	return raw if typeof(raw) == TYPE_ARRAY else []


static func grain_round_seconds(shape_index: int, phone: bool) -> float:
	var shapes: Array = grain_shapes()
	if shapes.is_empty():
		return 4.0
	var idx: int = posmod(shape_index, shapes.size())
	var entry_v: Variant = shapes[idx]
	var entry: Dictionary = entry_v if typeof(entry_v) == TYPE_DICTIONARY else {}
	var row: Dictionary = game("with_the_grain")
	return MinigameMath.grain_round_seconds(
		bool(entry.get("curvy", false)),
		phone,
		float(row.get("round_sec", 4.0)),
		float(row.get("round_sec_curvy_phone", 6.0))
	)


static func grain_average_round(phone: bool) -> float:
	var shapes: Array = grain_shapes()
	if shapes.is_empty():
		return 4.0
	var sum: float = 0.0
	for i: int in shapes.size():
		sum += grain_round_seconds(i, phone)
	return sum / float(shapes.size())


static func steeping_cycle() -> float:
	return maxf(8.0, float(game("steeping").get("cycle_sec", 8.0)))


static func hot_spot_points(station: String) -> PackedVector2Array:
	var out := PackedVector2Array()
	var stations_v: Variant = game("hot_spots").get("stations", {})
	if typeof(stations_v) != TYPE_DICTIONARY:
		return out
	var list_v: Variant = (stations_v as Dictionary).get(station, [])
	if typeof(list_v) != TYPE_ARRAY:
		return out
	for entry: Variant in list_v as Array:
		if typeof(entry) != TYPE_ARRAY:
			continue
		var pair: Array = entry
		if pair.size() < 2:
			continue
		out.append(Vector2(float(pair[0]), float(pair[1])))
	return out
