class_name MinigameCatalog
extends RefCounted
## Static access to minigame data and script factories.


static func data() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/minigames.json"))
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed as Dictionary


static func game_cfg(id: String) -> Dictionary:
	var root: Dictionary = data()
	if id == "tap_test":
		var dbg: Variant = root.get("debug_games", {})
		if typeof(dbg) == TYPE_DICTIONARY and (dbg as Dictionary).has("tap_test"):
			return ((dbg as Dictionary)["tap_test"] as Dictionary).duplicate(true)
		return {}
	var games: Variant = root.get("games", {})
	if typeof(games) != TYPE_DICTIONARY:
		return {}
	var found: Variant = (games as Dictionary).get(id, {})
	if typeof(found) != TYPE_DICTIONARY:
		return {}
	return (found as Dictionary).duplicate(true)


static func game_ids() -> PackedStringArray:
	var root: Dictionary = data()
	var games: Variant = root.get("games", {})
	if typeof(games) != TYPE_DICTIONARY:
		return PackedStringArray()
	var pairs: Array[Dictionary] = []
	for key: Variant in (games as Dictionary).keys():
		var g: Variant = (games as Dictionary)[key]
		if typeof(g) != TYPE_DICTIONARY:
			continue
		pairs.append({"id": str(key), "order": int((g as Dictionary).get("order", 999))})
	pairs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("order", 0)) < int(b.get("order", 0))
	)
	var out: PackedStringArray = PackedStringArray()
	for row: Dictionary in pairs:
		out.append(str(row.get("id", "")))
	return out


static func is_built(id: String) -> bool:
	var core_path: String = "res://scripts/minigames/games/%s_core.gd" % id
	var view_path: String = "res://scripts/minigames/games/%s_view.gd" % id
	return ResourceLoader.exists(core_path) and ResourceLoader.exists(view_path)


static func new_core(id: String) -> MinigameCore:
	var path: String = "res://scripts/minigames/games/%s_core.gd" % id
	var script: Script = load(path) as Script
	if script == null:
		push_error("MinigameCatalog: missing core %s" % path)
		return null
	return script.new() as MinigameCore


static func new_view(id: String) -> MinigameView:
	var path: String = "res://scripts/minigames/games/%s_view.gd" % id
	var script: Script = load(path) as Script
	if script == null:
		push_error("MinigameCatalog: missing view %s" % path)
		return null
	return script.new() as MinigameView


static func text(key: String) -> String:
	if key == "":
		return ""
	var strings: Node = _content_strings()
	if strings == null:
		return key
	var raw: String = str(strings.call("get_text", key))
	if raw.begins_with("[DRAFT] "):
		return raw.substr(8)
	return raw


static func _content_strings() -> Node:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null("ContentStrings")


static func r_weighted(cfg: Dictionary) -> float:
	var r: float = float(cfg.get("r", 0.0))
	var every: int = int(cfg.get("heavy_every", 0))
	if every <= 0:
		return r
	var heavy_weight: float = float(cfg.get("heavy_weight", 1.0))
	return r * (1.0 + (heavy_weight - 1.0) / float(every))
