extends Node
## Crafted-item backpack + handcraft recipes. Thin module beside GameState (SYSTEMS v0.4.0).
## Resources stay on GameState. Backpack holds intermediates, tools, Fertilizer only.

signal inventory_changed(item_id: StringName, new_amount: int)

const RECIPES_PATH: String = "res://data/handcraft_recipes.json"
const RESOURCE_IDS: Array[StringName] = [&"wood", &"stone", &"food", &"manashards", &"essence"]
const KEPT_TOOL_IDS: Array[StringName] = [
	&"stone_axe", &"stone_pickaxe", &"wooden_basket", &"stone_watering_can"
]

var items: Dictionary = {}
var items_data: Array = []
var recipes_data: Array = []
var params: Dictionary = {}
var grow_costs: Dictionary = {}
var _item_index: Dictionary = {}
var _recipe_index: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_load_tables()
	_ensure_item_keys()


func _load_tables() -> void:
	var file := FileAccess.open(RECIPES_PATH, FileAccess.READ)
	if file == null:
		push_error("Backpack: cannot open handcraft_recipes.json")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var root: Dictionary = parsed
	params = root.get("params", {}) as Dictionary
	grow_costs = root.get("grow_costs", {}) as Dictionary
	var items_v: Variant = root.get("items", [])
	items_data = items_v if typeof(items_v) == TYPE_ARRAY else []
	var recipes_v: Variant = root.get("recipes", [])
	recipes_data = recipes_v if typeof(recipes_v) == TYPE_ARRAY else []
	_item_index.clear()
	for entry: Variant in items_data:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = entry
		var iid: String = str(d.get("id", ""))
		if iid != "":
			_item_index[iid] = d
	_recipe_index.clear()
	for entry: Variant in recipes_data:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = entry
		var rid: String = str(d.get("id", ""))
		if rid != "":
			_recipe_index[rid] = d


func _ensure_item_keys() -> void:
	for entry: Variant in items_data:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var iid: String = str((entry as Dictionary).get("id", ""))
		if iid != "" and not items.has(iid):
			items[iid] = 0


func param_float(key: String, default_v: float = 0.0) -> float:
	return float(params.get(key, default_v))


func get_item_def(item_id: String) -> Dictionary:
	var found: Variant = _item_index.get(item_id, {})
	return found if typeof(found) == TYPE_DICTIONARY else {}


func get_recipe_def(recipe_id: String) -> Dictionary:
	var found: Variant = _recipe_index.get(recipe_id, {})
	return found if typeof(found) == TYPE_DICTIONARY else {}


func is_known_item(item_id: String) -> bool:
	return _item_index.has(item_id)


func is_unique_item(item_id: String) -> bool:
	return bool(get_item_def(item_id).get("unique", false))


func is_tool(item_id: String) -> bool:
	return str(get_item_def(item_id).get("kind", "")) == "tool"


func item_color(item_id: String) -> Color:
	var hex: String = str(get_item_def(item_id).get("color", "#888888"))
	return Color(hex)


func item_string_key(item_id: String) -> String:
	var def: Dictionary = get_item_def(item_id)
	var keyed: String = str(def.get("string_key", ""))
	if keyed != "":
		return keyed
	match item_id:
		"wooden_planks":
			return "part_wood_plank"
		"stone_fragments":
			return "part_stone_fragment"
		"wooden_tool_rod":
			return "part_wood_rod"
		"axe_head", "pickaxe_head":
			return "part_stone_head"
		"stone_axe":
			return "tool_stone_axe"
		"stone_pickaxe":
			return "tool_stone_pickaxe"
		"wooden_basket":
			return "tool_wooden_basket"
		"stone_watering_can":
			return "tool_stone_watering_can"
		"fertilizer":
			return "fertilizer_name"
		_:
			return "item_%s" % item_id


func item_display_name(item_id: String) -> String:
	var key: String = item_string_key(item_id)
	var labeled: String = ContentStrings.get_text(key)
	if labeled != key:
		return labeled
	var def: Dictionary = get_item_def(item_id)
	if not def.is_empty():
		return str(def.get("display_name", item_id))
	return item_id


func item_kind(item_id: String) -> String:
	return str(get_item_def(item_id).get("kind", ""))


func is_part(item_id: String) -> bool:
	var kind: String = item_kind(item_id)
	return kind == "intermediate" or kind == "consumable"


func get_count(item_id: String) -> int:
	return int(items.get(item_id, 0))


func owns_item(item_id: String) -> bool:
	return get_count(item_id) > 0


func owns_tool_for_resource(resource_id: StringName) -> bool:
	match resource_id:
		&"wood":
			return owns_item("stone_axe")
		&"stone":
			return owns_item("stone_pickaxe")
		&"food":
			return owns_item("wooden_basket")
		_:
			return false


func owns_watering_can() -> bool:
	return owns_item("stone_watering_can")


func set_count(item_id: String, amount: int) -> void:
	if not is_known_item(item_id):
		return
	amount = maxi(amount, 0)
	if is_unique_item(item_id):
		amount = mini(amount, 1)
	items[item_id] = amount
	inventory_changed.emit(StringName(item_id), amount)


func add_item(item_id: String, delta: int) -> int:
	if delta == 0:
		return get_count(item_id)
	if delta < 0:
		try_spend(item_id, -delta)
		return get_count(item_id)
	if is_unique_item(item_id) and owns_item(item_id):
		return get_count(item_id)
	set_count(item_id, get_count(item_id) + delta)
	return get_count(item_id)


func try_spend(item_id: String, amount: int) -> bool:
	if amount <= 0:
		return true
	if get_count(item_id) < amount:
		return false
	set_count(item_id, get_count(item_id) - amount)
	return true


func _have_ingredient(ing_id: String, need: int) -> bool:
	if StringName(ing_id) in RESOURCE_IDS:
		return GameState.get_resource(StringName(ing_id)) >= need
	return get_count(ing_id) >= need


func _spend_ingredient(ing_id: String, need: int) -> bool:
	if StringName(ing_id) in RESOURCE_IDS:
		if GameState.get_resource(StringName(ing_id)) < need:
			return false
		GameState.add_resource(StringName(ing_id), -need)
		return true
	return try_spend(ing_id, need)


func can_craft(recipe_id: String) -> bool:
	return craft_block_reason(recipe_id) == ""


func craft_block_reason(recipe_id: String) -> String:
	var def: Dictionary = get_recipe_def(recipe_id)
	if def.is_empty():
		return "unknown"
	if GameState.fruit_committed:
		return "pending_ascend"
	var out_id: String = str(def.get("output_id", recipe_id))
	if is_unique_item(out_id) and owns_item(out_id):
		return "unique"
	var ings: Dictionary = get_recipe_ingredients(recipe_id)
	if ings.is_empty() and get_recipe_def(recipe_id).is_empty():
		return "unknown"
	for key: Variant in ings.keys():
		var iid: String = str(key)
		var need: int = int(ings[key])
		if iid == "manashards" and need > 0:
			return "no_shards"
		if not _have_ingredient(iid, need):
			return "cant_afford"
	return ""


func recipe_has_manashards(recipe_id: String) -> bool:
	var ings: Dictionary = get_recipe_ingredients(recipe_id)
	return int(ings.get("manashards", 0)) > 0


func get_fertilizer_craft_cost_mult() -> float:
	## SYSTEMS v0.4.0: floor(base * FERTILIZER_CRAFT_COST_MULT * green_thumb_mult), min 1.
	var prestige: float = param_float("FERTILIZER_CRAFT_COST_MULT", 1.0)
	var rank: int = GameState.get_upgrade_rank("green_thumb")
	var thumb: float = maxf(0.0, 1.0 - 0.1 * float(rank))
	return maxf(0.0, prestige * thumb)


func _scaled_ingredient_need(recipe_id: String, raw_need: int) -> int:
	if raw_need <= 0:
		return 0
	if recipe_id != "fertilizer":
		return raw_need
	return maxi(1, int(floor(float(raw_need) * get_fertilizer_craft_cost_mult())))


func get_recipe_ingredients(recipe_id: String) -> Dictionary:
	var def: Dictionary = get_recipe_def(recipe_id)
	var ings: Variant = def.get("ingredients", {})
	if typeof(ings) != TYPE_DICTIONARY:
		return {}
	var out: Dictionary = {}
	for key: Variant in (ings as Dictionary).keys():
		var iid: String = str(key)
		out[iid] = _scaled_ingredient_need(recipe_id, int((ings as Dictionary)[key]))
	return out


func try_craft(recipe_id: String) -> String:
	var reason: String = craft_block_reason(recipe_id)
	if reason != "":
		return reason
	var def: Dictionary = get_recipe_def(recipe_id)
	var ings: Dictionary = get_recipe_ingredients(recipe_id)
	for key: Variant in ings.keys():
		if not _spend_ingredient(str(key), int(ings[key])):
			return "cant_afford"
	var out_id: String = str(def.get("output_id", recipe_id))
	var out_n: int = int(def.get("output_count", 1))
	add_item(out_id, out_n)
	return "ok"


func format_ingredient_line(ing_id: String, need: int, recipe_id: String = "") -> String:
	var have: int
	var name: String
	if StringName(ing_id) in RESOURCE_IDS:
		have = GameState.get_resource(StringName(ing_id))
		name = ContentStrings.get_text("hud_%s" % ing_id)
	else:
		have = get_count(ing_id)
		name = item_display_name(ing_id)
	if recipe_id == "fertilizer":
		var key: String = "fertilizer_craft_cost_%s" % ing_id
		var labeled: String = ContentStrings.get_text(key, {"have": have, "need": need, "item": name})
		if labeled != key:
			return labeled
		return ContentStrings.get_text("fertilizer_craft_cost_line", {"have": have, "need": need, "item": name})
	return "%s %d/%d" % [name, have, need]


func recipe_ingredient_lines(recipe_id: String) -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	var ings: Dictionary = get_recipe_ingredients(recipe_id)
	for key: Variant in ings.keys():
		lines.append(format_ingredient_line(str(key), int(ings[key]), recipe_id))
	return lines


func stacked_items() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for entry: Variant in items_data:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var iid: String = str((entry as Dictionary).get("id", ""))
		var n: int = get_count(iid)
		if n <= 0:
			continue
		out.append({
			"id": iid,
			"count": n,
			"display_name": item_display_name(iid),
			"color": item_color(iid),
			"unique": is_unique_item(iid),
			"kind": str((entry as Dictionary).get("kind", "")),
		})
	return out


func wipe_all() -> void:
	for key: Variant in items.keys():
		items[str(key)] = 0
	_ensure_item_keys()
	inventory_changed.emit(&"", 0)


func grant_kept_tools() -> void:
	for tid: StringName in KEPT_TOOL_IDS:
		set_count(String(tid), 1)


func on_ascend() -> void:
	var keep: bool = GameState.get_upgrade_rank("keep_tools") > 0
	wipe_all()
	if keep:
		grant_kept_tools()


func reset_for_new_game() -> void:
	wipe_all()


func to_save_dict() -> Dictionary:
	return items.duplicate(true)


func apply_save_dict(data: Variant) -> void:
	wipe_all()
	if typeof(data) != TYPE_DICTIONARY:
		return
	var src: Dictionary = data
	for key: Variant in src.keys():
		var iid: String = str(key)
		if is_known_item(iid):
			set_count(iid, int(src[key]))
