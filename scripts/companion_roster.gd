class_name CompanionRoster
extends RefCounted
## Reads data/companions.json. Keeper stays a top-level rate row.
## tortoise is the pre-roster id of mossback.

const DATA_PATH: String = "res://data/companions.json"
const LEGACY_IDS: Dictionary = {"tortoise": "mossback"}

static var _loaded: bool = false
static var _data: Dictionary = {}
static var _extras: Dictionary = {}


static func _ensure() -> void:
	if _loaded:
		return
	_loaded = true
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	if typeof(parsed) == TYPE_DICTIONARY:
		_data = parsed


static func reload() -> void:
	_loaded = false
	_data = {}
	_ensure()


static func canonical_id(actor_id: String) -> String:
	var key: String = str(LEGACY_IDS.get(actor_id, actor_id))
	return key


static func party_cap() -> int:
	_ensure()
	return maxi(1, int(_data.get("party_cap", 6)))


static func ids() -> Array[String]:
	_ensure()
	var out: Array[String] = []
	var listed: Variant = _data.get("roster", [])
	if typeof(listed) == TYPE_ARRAY:
		for item: Variant in listed as Array:
			var id: String = canonical_id(str(item))
			if id != "" and id != "keeper" and not out.has(id):
				out.append(id)
	for extra_id: String in _extras.keys():
		if not out.has(extra_id):
			out.append(extra_id)
	return out


static func has_id(actor_id: String) -> bool:
	var id: String = canonical_id(actor_id)
	if id == "keeper":
		return true
	return ids().has(id)


static func row(actor_id: String) -> Dictionary:
	_ensure()
	var id: String = canonical_id(actor_id)
	if _extras.has(id):
		var extra: Variant = _extras[id]
		if typeof(extra) == TYPE_DICTIONARY:
			return extra
	var found: Variant = _data.get(id, {})
	return found if typeof(found) == TYPE_DICTIONARY else {}


static func hub_body(actor_id: String) -> bool:
	var body: Variant = row(actor_id).get("hub_body", true)
	return bool(body) and canonical_id(actor_id) != "keeper"


static func push_test_companion(actor_id: String, spec: Dictionary) -> void:
	_extras[canonical_id(actor_id)] = spec.duplicate(true)


static func clear_test_companions() -> void:
	_extras.clear()


static func sheet_traits(actor_id: String) -> Array[String]:
	var raw: Variant = row(actor_id).get("sheet_traits", [])
	var out: Array[String] = []
	if typeof(raw) != TYPE_ARRAY:
		return out
	for item: Variant in raw as Array:
		out.append(str(item))
	return out


static func text_key(actor_id: String, field: String, fallback: String) -> String:
	var key: String = str(row(actor_id).get(field, ""))
	return key if key != "" else fallback


static func battle_pose(actor_id: String, pose: String) -> String:
	var art: Variant = row(actor_id).get("art", {})
	var block: Dictionary = art if typeof(art) == TYPE_DICTIONARY else {}
	var battle: Variant = block.get("battle", {})
	if typeof(battle) != TYPE_DICTIONARY:
		return ""
	var poses: Dictionary = battle
	if poses.has(pose):
		return str(poses[pose])
	if pose == "hurt" and poses.has("hit"):
		return str(poses["hit"])
	if pose == "hit" and poses.has("hurt"):
		return str(poses["hurt"])
	return ""


static func sim_sheet(actor_id: String) -> Dictionary:
	var raw: Variant = row(actor_id).get("sim_sheet", {})
	return raw if typeof(raw) == TYPE_DICTIONARY else {}


static func sim_duo_id() -> String:
	for actor_id: String in ids():
		if not sim_sheet(actor_id).is_empty():
			return actor_id
	return ""
