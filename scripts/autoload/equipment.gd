extends Node
## Battle gear inventory + paper-doll slots. Thin module beside GameState.
## Backpack keeps forest crafts. This inventory keeps weapons and (later) armor.
## Equipped bonuses are flat. level / runes are stored and unused until the forge pass.

signal equipment_changed

const DATA_PATH: String = "res://data/equipment.json"
const SLOT_ORDER: Array[StringName] = [
	&"weapon", &"relic", &"head", &"body", &"hands", &"pants", &"feet", &"cape", &"ring_1", &"ring_2"
]

var slots_data: Array = []
var items_data: Array = []
var recipes_data: Array = []
var _slot_index: Dictionary = {}
var _item_index: Dictionary = {}
var _recipe_index: Dictionary = {}
## Unequipped instances: {id, level, runes}.
var owned: Array[Dictionary] = []
## slot_id -> instance dict. Missing or empty id means bare.
var equipped: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_load_tables()


func _load_tables() -> void:
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("Equipment: cannot open equipment.json")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var root: Dictionary = parsed
	var slots_v: Variant = root.get("slots", [])
	slots_data = slots_v if typeof(slots_v) == TYPE_ARRAY else []
	var items_v: Variant = root.get("items", [])
	items_data = items_v if typeof(items_v) == TYPE_ARRAY else []
	var recipes_v: Variant = root.get("recipes", [])
	recipes_data = recipes_v if typeof(recipes_v) == TYPE_ARRAY else []
	_slot_index.clear()
	for entry: Variant in slots_data:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = entry
		var sid: String = str(d.get("id", ""))
		if sid != "":
			_slot_index[sid] = d
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


func is_known_slot(slot_id: String) -> bool:
	return _slot_index.has(slot_id)


func is_known_item(item_id: String) -> bool:
	return _item_index.has(item_id)


func has_recipe(recipe_id: String) -> bool:
	return _recipe_index.has(recipe_id)


func get_slot_def(slot_id: String) -> Dictionary:
	var found: Variant = _slot_index.get(slot_id, {})
	return found if typeof(found) == TYPE_DICTIONARY else {}


func get_item_def(item_id: String) -> Dictionary:
	var found: Variant = _item_index.get(item_id, {})
	return found if typeof(found) == TYPE_DICTIONARY else {}


func get_recipe_def(recipe_id: String) -> Dictionary:
	var found: Variant = _recipe_index.get(recipe_id, {})
	return found if typeof(found) == TYPE_DICTIONARY else {}


func is_slot_unlocked(slot_id: String) -> bool:
	return bool(get_slot_def(slot_id).get("unlocked", false))


func slot_display_name(slot_id: String) -> String:
	var def: Dictionary = get_slot_def(slot_id)
	var key: String = str(def.get("label_key", "equip_slot_%s" % slot_id))
	var labeled: String = ContentStrings.get_text(key)
	if labeled != key and labeled != "":
		return labeled
	return slot_id.capitalize()


func slot_lock_short(slot_id: String) -> String:
	var def: Dictionary = get_slot_def(slot_id)
	var key: String = str(def.get("lock_short_key", "equip_locked_short"))
	var labeled: String = ContentStrings.get_text(key)
	if labeled != key and labeled != "":
		return labeled
	return "Locked"


func slot_lock_hint(slot_id: String) -> String:
	var def: Dictionary = get_slot_def(slot_id)
	var key: String = str(def.get("lock_hint_key", "equip_locked_armor"))
	var labeled: String = ContentStrings.get_text(key)
	if labeled != key and labeled != "":
		return labeled
	return "Locked."


func slot_anchor(slot_id: String) -> Vector2:
	var raw: Variant = get_slot_def(slot_id).get("anchor", [0.5, 0.5])
	if typeof(raw) == TYPE_ARRAY and (raw as Array).size() >= 2:
		var arr: Array = raw
		return Vector2(float(arr[0]), float(arr[1]))
	return Vector2(0.5, 0.5)


func item_display_name(item_id: String) -> String:
	var def: Dictionary = get_item_def(item_id)
	var key: String = str(def.get("string_key", ""))
	if key != "":
		var labeled: String = ContentStrings.get_text(key)
		if labeled != key and labeled != "":
			return labeled
	if not def.is_empty():
		return str(def.get("display_name", item_id))
	return item_id


func item_color(item_id: String) -> Color:
	var hex: String = str(get_item_def(item_id).get("color", "#888888"))
	return Color(hex)


func item_slot(item_id: String) -> String:
	return str(get_item_def(item_id).get("slot", ""))


func is_unique_item(item_id: String) -> bool:
	return bool(get_item_def(item_id).get("unique", false))


func item_fits_slot(item_id: String, slot_id: String) -> bool:
	return is_known_item(item_id) and item_slot(item_id) == slot_id


func _blank_instance(item_id: String) -> Dictionary:
	var def: Dictionary = get_item_def(item_id)
	var sockets: Variant = def.get("rune_sockets", [])
	var runes: Array = (sockets as Array).duplicate(true) if typeof(sockets) == TYPE_ARRAY else []
	return {
		"id": item_id,
		"level": maxi(1, int(def.get("level", 1))),
		"runes": runes,
	}


func _normalize_instance(raw: Dictionary) -> Dictionary:
	var iid: String = str(raw.get("id", ""))
	if not is_known_item(iid):
		return {}
	var runes_v: Variant = raw.get("runes", [])
	var runes: Array = runes_v if typeof(runes_v) == TYPE_ARRAY else []
	return {
		"id": iid,
		"level": maxi(1, int(raw.get("level", 1))),
		"runes": runes.duplicate(true),
	}


func equipped_instance(slot_id: String) -> Dictionary:
	var found: Variant = equipped.get(slot_id, {})
	if typeof(found) != TYPE_DICTIONARY:
		return {}
	return found as Dictionary


func equipped_id(slot_id: String) -> String:
	return str(equipped_instance(slot_id).get("id", ""))


func _owned_index(item_id: String) -> int:
	for i: int in range(owned.size()):
		if str(owned[i].get("id", "")) == item_id:
			return i
	return -1


func unequipped_count(item_id: String) -> int:
	var n: int = 0
	for inst: Dictionary in owned:
		if str(inst.get("id", "")) == item_id:
			n += 1
	return n


func owns_anywhere(item_id: String) -> bool:
	if unequipped_count(item_id) > 0:
		return true
	for slot_id: StringName in SLOT_ORDER:
		if equipped_id(String(slot_id)) == item_id:
			return true
	return false


func list_unequipped() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for inst: Dictionary in owned:
		out.append(inst.duplicate(true))
	return out


func _item_bonus(item_id: String, stat_id: String) -> int:
	## Level is stored on the instance but does not scale power yet.
	var bonuses: Variant = get_item_def(item_id).get("bonuses", {})
	if typeof(bonuses) != TYPE_DICTIONARY:
		return 0
	return int((bonuses as Dictionary).get(stat_id, 0))


func gear_bonus(stat_id: String) -> int:
	var total: int = 0
	for slot_id: StringName in SLOT_ORDER:
		var iid: String = equipped_id(String(slot_id))
		if iid != "":
			total += _item_bonus(iid, stat_id)
	return total


func total_for(stat_id: String) -> int:
	return KeeperStats.get_base(stat_id) + gear_bonus(stat_id)


## Gear column if `item_id` replaced whatever is in its slot. Empty item_id = current.
func preview_gear_bonus(stat_id: String, item_id: String) -> int:
	if item_id == "" or not is_known_item(item_id):
		return gear_bonus(stat_id)
	var slot_id: String = item_slot(item_id)
	var total: int = 0
	for sid: StringName in SLOT_ORDER:
		var slot: String = String(sid)
		var iid: String = item_id if slot == slot_id else equipped_id(slot)
		if iid != "":
			total += _item_bonus(iid, stat_id)
	return total


func try_equip(item_id: String) -> String:
	return try_equip_to_slot(item_id, item_slot(item_id))


func try_equip_to_slot(item_id: String, slot_id: String) -> String:
	if not is_known_item(item_id):
		return "missing"
	if not item_fits_slot(item_id, slot_id):
		return "wrong_slot"
	if not is_slot_unlocked(slot_id):
		return "locked"
	var idx: int = _owned_index(item_id)
	if idx < 0:
		return "missing"
	var inst: Dictionary = owned[idx].duplicate(true)
	owned.remove_at(idx)
	var previous: Dictionary = equipped_instance(slot_id)
	if str(previous.get("id", "")) != "":
		owned.append(previous.duplicate(true))
	equipped[slot_id] = inst
	equipment_changed.emit()
	return "ok"


func try_unequip(slot_id: String) -> String:
	if not is_known_slot(slot_id):
		return "missing"
	var inst: Dictionary = equipped_instance(slot_id)
	if str(inst.get("id", "")) == "":
		return "empty"
	owned.append(inst.duplicate(true))
	equipped.erase(slot_id)
	equipment_changed.emit()
	return "ok"


func grant_item(item_id: String) -> bool:
	if not is_known_item(item_id):
		return false
	if is_unique_item(item_id) and owns_anywhere(item_id):
		return false
	owned.append(_blank_instance(item_id))
	equipment_changed.emit()
	return true


func get_recipe_ingredients(recipe_id: String) -> Dictionary:
	var def: Dictionary = get_recipe_def(recipe_id)
	var ings: Variant = def.get("ingredients", {})
	if typeof(ings) != TYPE_DICTIONARY:
		return {}
	var out: Dictionary = {}
	for key: Variant in (ings as Dictionary).keys():
		out[str(key)] = int((ings as Dictionary)[key])
	return out


func _have_ingredient(ing_id: String, need: int) -> bool:
	if StringName(ing_id) in Backpack.RESOURCE_IDS:
		return GameState.get_resource(StringName(ing_id)) >= need
	return Backpack.get_count(ing_id) >= need


func _spend_ingredient(ing_id: String, need: int) -> bool:
	if StringName(ing_id) in Backpack.RESOURCE_IDS:
		if GameState.get_resource(StringName(ing_id)) < need:
			return false
		GameState.add_resource(StringName(ing_id), -need)
		return true
	return Backpack.try_spend(ing_id, need)


func craft_block_reason(recipe_id: String) -> String:
	var def: Dictionary = get_recipe_def(recipe_id)
	if def.is_empty():
		return "unknown"
	if GameState.fruit_committed:
		return "pending_ascend"
	var out_id: String = str(def.get("output_id", recipe_id))
	if is_unique_item(out_id) and owns_anywhere(out_id):
		return "unique"
	var ings: Dictionary = get_recipe_ingredients(recipe_id)
	for key: Variant in ings.keys():
		var iid: String = str(key)
		var need: int = int(ings[key])
		if iid == "manashards" and need > 0:
			return "no_shards"
		if not _have_ingredient(iid, need):
			return "cant_afford"
	return ""


func recipe_ingredient_lines(recipe_id: String) -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	var ings: Dictionary = get_recipe_ingredients(recipe_id)
	for key: Variant in ings.keys():
		var iid: String = str(key)
		var need: int = int(ings[key])
		var have: int
		var name: String
		if StringName(iid) in Backpack.RESOURCE_IDS:
			have = GameState.get_resource(StringName(iid))
			name = ContentStrings.get_text("hud_%s" % iid)
		else:
			have = Backpack.get_count(iid)
			name = Backpack.item_display_name(iid)
		lines.append("%s %d/%d" % [name, have, need])
	return lines


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
	var out_n: int = maxi(1, int(def.get("output_count", 1)))
	for _i: int in range(out_n):
		if not grant_item(out_id):
			return "unique"
	return "ok"


func on_ascend() -> void:
	## Battle kit stays with the Keeper. Backpack intermediates (Weapon Rod included) wipe.
	pass


func reset_for_new_game() -> void:
	owned.clear()
	equipped.clear()
	equipment_changed.emit()


func to_save_dict() -> Dictionary:
	var owned_out: Array = []
	for inst: Dictionary in owned:
		owned_out.append(inst.duplicate(true))
	var eq_out: Dictionary = {}
	for slot_id: StringName in SLOT_ORDER:
		var key: String = String(slot_id)
		var inst: Dictionary = equipped_instance(key)
		if str(inst.get("id", "")) != "":
			eq_out[key] = inst.duplicate(true)
	return {"owned": owned_out, "equipped": eq_out}


func apply_save_dict(data: Variant) -> void:
	owned.clear()
	equipped.clear()
	if typeof(data) != TYPE_DICTIONARY:
		equipment_changed.emit()
		return
	var src: Dictionary = data
	var owned_v: Variant = src.get("owned", [])
	if typeof(owned_v) == TYPE_ARRAY:
		for entry: Variant in owned_v:
			if typeof(entry) != TYPE_DICTIONARY:
				continue
			var inst: Dictionary = _normalize_instance(entry as Dictionary)
			if inst.is_empty():
				continue
			if is_unique_item(str(inst.get("id", ""))) and owns_anywhere(str(inst.get("id", ""))):
				continue
			owned.append(inst)
	var eq_v: Variant = src.get("equipped", {})
	if typeof(eq_v) == TYPE_DICTIONARY:
		for slot_id: StringName in SLOT_ORDER:
			var key: String = String(slot_id)
			var raw: Variant = (eq_v as Dictionary).get(key, {})
			if typeof(raw) != TYPE_DICTIONARY:
				continue
			var inst: Dictionary = _normalize_instance(raw as Dictionary)
			if inst.is_empty():
				continue
			if not item_fits_slot(str(inst.get("id", "")), key):
				continue
			if is_unique_item(str(inst.get("id", ""))) and owns_anywhere(str(inst.get("id", ""))):
				continue
			equipped[key] = inst
	equipment_changed.emit()
