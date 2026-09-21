extends Node
## Battle gear inventory + paper-doll slots. Thin module beside GameState.
## Backpack keeps forest crafts. This inventory keeps Weapon Rod and Stone Sword.
## Equipped bonuses are flat. Relic stays locked this ship (no Forge Key).

signal equipment_changed

const DATA_PATH: String = "res://data/equipment.json"
const SLOT_ORDER: Array[StringName] = [
	&"weapon", &"relic", &"head", &"body", &"hands", &"pants", &"feet", &"cape", &"ring1", &"ring2"
]

var slots_data: Array = []
var items_data: Array = []
var recipes_data: Array = []
var _slot_index: Dictionary = {}
var _item_index: Dictionary = {}
var _recipe_index: Dictionary = {}
## Unequipped battle items: item_id -> count.
var gear_inventory: Dictionary = {}
## slot_id -> item_id. Missing key means bare.
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
	return _slot_index.has(_canonical_slot(slot_id))


func is_known_item(item_id: String) -> bool:
	return _item_index.has(item_id)


func has_recipe(recipe_id: String) -> bool:
	return _recipe_index.has(recipe_id)


func get_slot_def(slot_id: String) -> Dictionary:
	var found: Variant = _slot_index.get(_canonical_slot(slot_id), {})
	return found if typeof(found) == TYPE_DICTIONARY else {}


func get_item_def(item_id: String) -> Dictionary:
	var found: Variant = _item_index.get(item_id, {})
	return found if typeof(found) == TYPE_DICTIONARY else {}


func get_recipe_def(recipe_id: String) -> Dictionary:
	var found: Variant = _recipe_index.get(recipe_id, {})
	return found if typeof(found) == TYPE_DICTIONARY else {}


func is_slot_unlocked(slot_id: String) -> bool:
	## Relic stays locked until Forge Key — that item is not in this ship.
	var sid: String = _canonical_slot(slot_id)
	if sid == "relic":
		return false
	return bool(get_slot_def(sid).get("unlocked", false))


func slot_display_name(slot_id: String) -> String:
	var sid: String = _canonical_slot(slot_id)
	var def: Dictionary = get_slot_def(sid)
	var key: String = str(def.get("label_key", "equip_slot_%s" % sid))
	var labeled: String = ContentStrings.get_text(key)
	if labeled != key and labeled != "":
		return labeled
	return sid.capitalize()


func slot_lock_hint(slot_id: String) -> String:
	var sid: String = _canonical_slot(slot_id)
	if sid == "relic":
		return ContentStrings.get_text("equip_locked_relic")
	if sid == "weapon":
		return ContentStrings.get_text("equip_locked_hint")
	return ContentStrings.get_text("equip_locked_armor")


func slot_lock_short(_slot_id: String) -> String:
	return ContentStrings.get_text("equip_locked")


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


func item_tooltip(item_id: String) -> String:
	var def: Dictionary = get_item_def(item_id)
	var key: String = str(def.get("tooltip_key", ""))
	if key != "":
		var labeled: String = ContentStrings.get_text(key)
		if labeled != key and labeled != "":
			return labeled
	return item_display_name(item_id)


func item_color(item_id: String) -> Color:
	var hex: String = str(get_item_def(item_id).get("color", "#888888"))
	return Color(hex)


func item_slot(item_id: String) -> String:
	return str(get_item_def(item_id).get("slot", ""))


func is_unique_item(item_id: String) -> bool:
	return bool(get_item_def(item_id).get("unique", false))


func item_fits_slot(item_id: String, slot_id: String) -> bool:
	var slot: String = item_slot(item_id)
	return is_known_item(item_id) and slot != "" and slot == _canonical_slot(slot_id)


func equipped_id(slot_id: String) -> String:
	return str(equipped.get(_canonical_slot(slot_id), ""))


func unequipped_count(item_id: String) -> int:
	return int(gear_inventory.get(item_id, 0))


func gear_count_anywhere(item_id: String) -> int:
	var n: int = unequipped_count(item_id)
	for slot_id: StringName in SLOT_ORDER:
		if equipped_id(String(slot_id)) == item_id:
			n += 1
	return n


func owns_anywhere(item_id: String) -> bool:
	return gear_count_anywhere(item_id) > 0


func list_unequipped() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for key: Variant in gear_inventory.keys():
		var iid: String = str(key)
		var n: int = int(gear_inventory[key])
		if n > 0 and is_known_item(iid):
			out.append({"id": iid, "count": n})
	return out


func _item_bonus(item_id: String, stat_id: String) -> int:
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
	var sid: String = _canonical_slot(slot_id)
	if not is_known_slot(sid):
		return "missing"
	if not is_slot_unlocked(sid):
		return "locked"
	if not item_fits_slot(item_id, sid):
		return "wrong_slot"
	if unequipped_count(item_id) <= 0:
		return "missing"
	_take_unequipped(item_id, 1)
	var previous: String = equipped_id(sid)
	if previous != "":
		_add_unequipped(previous, 1)
	equipped[sid] = item_id
	equipment_changed.emit()
	return "ok"


func try_unequip(slot_id: String) -> String:
	var sid: String = _canonical_slot(slot_id)
	if not is_known_slot(sid):
		return "missing"
	var iid: String = equipped_id(sid)
	if iid == "":
		return "empty"
	_add_unequipped(iid, 1)
	equipped.erase(sid)
	equipment_changed.emit()
	return "ok"


func grant_item(item_id: String) -> bool:
	return add_gear(item_id, 1)


func add_gear(item_id: String, count: int) -> bool:
	if not is_known_item(item_id) or count <= 0:
		return false
	if is_unique_item(item_id) and owns_anywhere(item_id):
		return false
	var n: int = 1 if is_unique_item(item_id) else count
	_add_unequipped(item_id, n)
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
	if Backpack.is_known_item(ing_id):
		return Backpack.get_count(ing_id) >= need
	if is_known_item(ing_id):
		return gear_count_anywhere(ing_id) >= need
	return false


func _spend_ingredient(ing_id: String, need: int) -> bool:
	if StringName(ing_id) in Backpack.RESOURCE_IDS:
		if GameState.get_resource(StringName(ing_id)) < need:
			return false
		GameState.add_resource(StringName(ing_id), -need)
		return true
	if Backpack.is_known_item(ing_id):
		return Backpack.try_spend(ing_id, need)
	if is_known_item(ing_id):
		return _spend_gear_anywhere(ing_id, need)
	return false


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
		elif Backpack.is_known_item(iid):
			have = Backpack.get_count(iid)
			name = Backpack.item_display_name(iid)
		else:
			have = gear_count_anywhere(iid)
			name = item_display_name(iid)
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
	## Equipped gear and the gear inventory stay. Backpack still wipes.
	pass


func reset_for_new_game() -> void:
	gear_inventory.clear()
	equipped.clear()
	equipment_changed.emit()


func to_save_dict() -> Dictionary:
	var eq_out: Dictionary = {}
	for slot_id: StringName in SLOT_ORDER:
		var key: String = String(slot_id)
		var iid: String = equipped_id(key)
		eq_out[key] = iid if iid != "" else null
	var unlocked: Dictionary = {}
	for slot_id: StringName in SLOT_ORDER:
		var key: String = String(slot_id)
		unlocked[key] = is_slot_unlocked(key)
	var bag: Dictionary = {}
	for key: Variant in gear_inventory.keys():
		var n: int = int(gear_inventory[key])
		if n > 0:
			bag[str(key)] = n
	return {
		"equipment_unlocked": unlocked,
		"equipment_equipped": eq_out,
		"gear_inventory": bag,
	}


func apply_save_dict(data: Variant) -> void:
	gear_inventory.clear()
	equipped.clear()
	if typeof(data) != TYPE_DICTIONARY:
		equipment_changed.emit()
		return
	var src: Dictionary = data
	if src.has("gear_inventory") or src.has("equipment_equipped") or src.has("owned"):
		_apply_inventory(src.get("gear_inventory", src.get("owned", {})))
		_apply_equipped(src.get("equipment_equipped", src.get("equipped", {})))
	## Unlock flags stay on the data file this ship so a save cannot open the relic.
	equipment_changed.emit()


func _apply_inventory(raw: Variant) -> void:
	if typeof(raw) == TYPE_DICTIONARY:
		for key: Variant in (raw as Dictionary).keys():
			var iid: String = str(key)
			if not is_known_item(iid):
				continue
			var n: int = int((raw as Dictionary)[key])
			if n <= 0:
				continue
			if is_unique_item(iid):
				if owns_anywhere(iid):
					continue
				n = 1
			_add_unequipped(iid, n)
		return
	if typeof(raw) != TYPE_ARRAY:
		return
	for entry: Variant in raw:
		var iid: String = _item_id_of(entry)
		if iid == "" or not is_known_item(iid):
			continue
		if is_unique_item(iid) and owns_anywhere(iid):
			continue
		_add_unequipped(iid, 1)


func _apply_equipped(raw: Variant) -> void:
	if typeof(raw) != TYPE_DICTIONARY:
		return
	for slot_id: StringName in SLOT_ORDER:
		var key: String = String(slot_id)
		var found: Variant = (raw as Dictionary).get(key, null)
		if found == null and key == "ring1":
			found = (raw as Dictionary).get("ring_1", null)
		elif found == null and key == "ring2":
			found = (raw as Dictionary).get("ring_2", null)
		var iid: String = _item_id_of(found)
		if iid == "" or not item_fits_slot(iid, key):
			continue
		if is_unique_item(iid) and owns_anywhere(iid):
			continue
		equipped[key] = iid


func _add_unequipped(item_id: String, count: int) -> void:
	if count <= 0:
		return
	gear_inventory[item_id] = unequipped_count(item_id) + count


func _take_unequipped(item_id: String, count: int) -> bool:
	var have: int = unequipped_count(item_id)
	if have < count:
		return false
	var left: int = have - count
	if left <= 0:
		gear_inventory.erase(item_id)
	else:
		gear_inventory[item_id] = left
	return true


func _spend_gear_anywhere(item_id: String, need: int) -> bool:
	if gear_count_anywhere(item_id) < need:
		return false
	var from_bag: int = mini(unequipped_count(item_id), need)
	if from_bag > 0:
		_take_unequipped(item_id, from_bag)
		need -= from_bag
	if need <= 0:
		return true
	for slot_id: StringName in SLOT_ORDER:
		if need <= 0:
			break
		var key: String = String(slot_id)
		if equipped_id(key) != item_id:
			continue
		equipped.erase(key)
		need -= 1
	return need <= 0


func _item_id_of(raw: Variant) -> String:
	if raw == null:
		return ""
	if typeof(raw) == TYPE_STRING or typeof(raw) == TYPE_STRING_NAME:
		return str(raw)
	if typeof(raw) == TYPE_DICTIONARY:
		return str((raw as Dictionary).get("id", ""))
	return ""


func _canonical_slot(slot_id: String) -> String:
	if slot_id == "ring_1":
		return "ring1"
	if slot_id == "ring_2":
		return "ring2"
	return slot_id
