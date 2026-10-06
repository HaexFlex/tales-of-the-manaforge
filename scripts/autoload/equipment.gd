extends Node
## Battle gear inventory + paper-doll slots. Thin module beside GameState.
## Backpack keeps forest crafts. This inventory keeps Weapon Rod and stone_sword (stone_sword_name).
## Equipped bonuses are flat. Relic unlocks when the Keeper holds a Forge Key.

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
## Unequipped battle items: item_id -> count. Shared bag.
var gear_inventory: Dictionary = {}
## slot_id -> item_id. Missing key means bare. Keeper doll.
var equipped: Dictionary = {}
## Elaia's doll. Same shape. One item instance sits on one doll.
var elaia_equipped: Dictionary = {}


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
	if typeof(found) != TYPE_DICTIONARY:
		return {}
	var base: Dictionary = found
	if not has_node("/root/ForgeJobs"):
		return base
	var overlay: Dictionary = ForgeJobs.gear_overlay(item_id)
	if overlay.is_empty():
		return base
	var merged: Dictionary = base.duplicate(true)
	var changed: bool = false
	var bonuses: Dictionary = {}
	var bonuses_v: Variant = merged.get("bonuses", {})
	if typeof(bonuses_v) == TYPE_DICTIONARY:
		bonuses = bonuses_v
	var extra_v: Variant = overlay.get("bonuses", {})
	if bonuses.is_empty() and typeof(extra_v) == TYPE_DICTIONARY and not (extra_v as Dictionary).is_empty():
		merged["bonuses"] = (extra_v as Dictionary).duplicate(true)
		changed = true
	if str(merged.get("damage_kind", "")) == "" and str(overlay.get("damage_kind", "")) != "":
		merged["damage_kind"] = str(overlay.get("damage_kind", ""))
		changed = true
	if str(merged.get("category", "")) == "" and str(overlay.get("category", "")) != "":
		merged["category"] = str(overlay.get("category", ""))
		changed = true
	return merged if changed else base


func get_recipe_def(recipe_id: String) -> Dictionary:
	var found: Variant = _recipe_index.get(recipe_id, {})
	return found if typeof(found) == TYPE_DICTIONARY else {}


func is_slot_unlocked(slot_id: String) -> bool:
	## Relic follows the Forge Key. Other slots stay on the data file.
	var sid: String = _canonical_slot(slot_id)
	if sid == "relic":
		return has_node("/root/GameState") and GameState.forge_key
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


func item_art_path(item_id: String) -> String:
	## Standalone icon from equipment.json or the backpack item's art_name.
	## Files live either in ui/ or ui/icons/. The HUD sheet is a separate path.
	var art_name: String = str(get_item_def(item_id).get("art_name", ""))
	if art_name == "" and has_node("/root/Backpack"):
		art_name = str(Backpack.get_item_def(item_id).get("art_name", ""))
	if art_name == "":
		return ""
	var direct: String = "res://assets/art/ui/%s.png" % art_name
	if ResourceLoader.exists(direct):
		return direct
	var nested: String = "res://assets/art/ui/icons/%s.png" % art_name
	if ResourceLoader.exists(nested):
		return nested
	return ""


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
	var flavor: String = ""
	var key: String = str(def.get("tooltip_key", ""))
	if key != "":
		var labeled: String = ContentStrings.get_text(key)
		if labeled != key and labeled != "":
			flavor = labeled
	var stats: String = _generated_stat_lines(def)
	if flavor != "" and stats != "":
		return "%s\n%s" % [flavor, stats]
	if flavor != "":
		return flavor
	if stats != "":
		return stats
	var named: String = item_display_name(item_id)
	if named == item_id:
		return ""
	return named


func _generated_stat_lines(def: Dictionary) -> String:
	var lines: PackedStringArray = PackedStringArray()
	var bonuses_v: Variant = def.get("bonuses", {})
	if typeof(bonuses_v) == TYPE_DICTIONARY:
		for stat_id: String in ["might", "arcana", "resilience", "ward", "vitality", "swiftness", "fate"]:
			var amount: int = int((bonuses_v as Dictionary).get(stat_id, 0))
			if amount == 0:
				continue
			var stat_name: String = stat_id.capitalize()
			if has_node("/root/KeeperStats"):
				stat_name = KeeperStats.stat_display_name(stat_id)
			var sign: String = "+" if amount > 0 else ""
			lines.append("%s%d %s" % [sign, amount, stat_name])
	var kind: String = str(def.get("damage_kind", ""))
	if kind != "":
		lines.append(kind.capitalize())
	var damage: int = int(def.get("damage", 0))
	if damage > 0:
		if kind != "":
			lines[lines.size() - 1] = "%d %s" % [damage, kind.capitalize()]
		else:
			lines.append(str(damage))
	return "\n".join(lines)


func item_color(item_id: String) -> Color:
	var hex: String = str(get_item_def(item_id).get("color", "#888888"))
	return Color(hex)


func item_slot(item_id: String) -> String:
	return str(get_item_def(item_id).get("slot", ""))


func item_damage_kind(item_id: String) -> String:
	return str(get_item_def(item_id).get("damage_kind", ""))


func equipped_strike_kind() -> String:
	## physical | magical | hybrid. Bare hands and non-weapons stay physical.
	var kind: String = item_damage_kind(equipped_id("weapon"))
	if kind == "magical" or kind == "hybrid" or kind == "physical":
		return kind
	return "physical"


func recipe_station(recipe_id: String) -> String:
	var station: String = str(get_recipe_def(recipe_id).get("station", "handcraft"))
	if station == "":
		return "handcraft"
	return station


func is_handcraft_recipe(recipe_id: String) -> bool:
	return has_recipe(recipe_id) and recipe_station(recipe_id) != "anvil"


func is_unique_item(item_id: String) -> bool:
	return bool(get_item_def(item_id).get("unique", false))


func item_fits_slot(item_id: String, slot_id: String) -> bool:
	var slot: String = item_slot(item_id)
	return is_known_item(item_id) and slot != "" and slot == _canonical_slot(slot_id)


func _normalize_actor(actor: String) -> String:
	return "elaia" if actor == "elaia" else "keeper"


func _other_actor(actor: String) -> String:
	return "keeper" if _normalize_actor(actor) == "elaia" else "elaia"


func _doll(actor: String) -> Dictionary:
	if _normalize_actor(actor) == "elaia":
		return elaia_equipped
	return equipped


func equipped_id_for(actor: String, slot_id: String) -> String:
	return str(_doll(actor).get(_canonical_slot(slot_id), ""))


func equipped_id(slot_id: String) -> String:
	return equipped_id_for("keeper", slot_id)


func unequipped_count(item_id: String) -> int:
	return int(gear_inventory.get(item_id, 0))


func gear_count_anywhere(item_id: String) -> int:
	var n: int = unequipped_count(item_id)
	for slot_id: StringName in SLOT_ORDER:
		var key: String = String(slot_id)
		if equipped_id_for("keeper", key) == item_id:
			n += 1
		if equipped_id_for("elaia", key) == item_id:
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


## Bag rows this character can wear. The other doll's kit stays off this sheet.
func list_for_sheet(actor: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for inst: Dictionary in list_unequipped():
		var iid: String = str(inst.get("id", ""))
		var n: int = int(inst.get("count", 0))
		if n > 0 and usable_by(iid, actor):
			out.append({"id": iid, "count": n})
	return out


## Empty users means either character. Gear items set this explicitly.
func usable_by(item_id: String, actor: String) -> bool:
	var raw: Variant = get_item_def(item_id).get("users", [])
	if typeof(raw) != TYPE_ARRAY:
		return true
	var users: Array = raw
	if users.is_empty():
		return true
	var who: String = _normalize_actor(actor)
	for entry: Variant in users:
		if str(entry) == who:
			return true
	return false


func _item_bonus(item_id: String, stat_id: String) -> int:
	var bonuses: Variant = get_item_def(item_id).get("bonuses", {})
	if typeof(bonuses) != TYPE_DICTIONARY:
		return 0
	return int((bonuses as Dictionary).get(stat_id, 0))


func gear_bonus_for(actor: String, stat_id: String) -> int:
	var total: int = 0
	for slot_id: StringName in SLOT_ORDER:
		var iid: String = equipped_id_for(actor, String(slot_id))
		if iid != "":
			total += _item_bonus(iid, stat_id)
	return total


func gear_bonus(stat_id: String) -> int:
	return gear_bonus_for("keeper", stat_id)


func total_for(stat_id: String) -> int:
	return KeeperStats.get_base(stat_id) + gear_bonus(stat_id)


## Gear column if `item_id` replaced whatever is in its slot. Empty item_id = current.
func preview_gear_bonus_for(actor: String, stat_id: String, item_id: String) -> int:
	if item_id == "" or not is_known_item(item_id):
		return gear_bonus_for(actor, stat_id)
	var slot_id: String = item_slot(item_id)
	var total: int = 0
	for sid: StringName in SLOT_ORDER:
		var slot: String = String(sid)
		var iid: String = item_id if slot == slot_id else equipped_id_for(actor, slot)
		if iid != "":
			total += _item_bonus(iid, stat_id)
	return total


func preview_gear_bonus(stat_id: String, item_id: String) -> int:
	return preview_gear_bonus_for("keeper", stat_id, item_id)


func try_equip(item_id: String, actor: String = "keeper") -> String:
	return try_equip_to_slot(item_id, item_slot(item_id), actor)


func try_equip_to_slot(item_id: String, slot_id: String, actor: String = "keeper") -> String:
	if not is_known_item(item_id):
		return "missing"
	var sid: String = _canonical_slot(slot_id)
	if not is_known_slot(sid):
		return "missing"
	if not is_slot_unlocked(sid):
		return "locked"
	if not item_fits_slot(item_id, sid):
		return "wrong_slot"
	var who: String = _normalize_actor(actor)
	if not usable_by(item_id, who):
		return "wrong_user"
	var doll: Dictionary = _doll(who)
	var took: bool = _take_for_equip(who, doll, sid, item_id)
	if not took:
		return "missing"
	var previous: String = str(doll.get(sid, ""))
	if previous != "":
		_add_unequipped(previous, 1)
	doll[sid] = item_id
	equipment_changed.emit()
	if sid == "relic" and previous != "" and previous != item_id:
		if has_node("/root/GameAudio"):
			GameAudio.play(&"sfx_upgrade_buy")
		if has_node("/root/ForgeJobs") and has_node("/root/GameState"):
			var label: String = item_display_name(item_id)
			GameState.status_message.emit(ForgeJobs.copy_text("relic_swap_confirm", {"item": label}))
	return "ok"


func _take_for_equip(who: String, doll: Dictionary, sid: String, item_id: String) -> bool:
	## Shared bag first, so a spare does not pull gear off the other character.
	## Then the other doll. A second copy on this doll moves only when nothing else is free.
	if unequipped_count(item_id) > 0:
		return _take_unequipped(item_id, 1)
	var other: Dictionary = _doll(_other_actor(who))
	for slot_name: StringName in SLOT_ORDER:
		var key: String = String(slot_name)
		if str(other.get(key, "")) == item_id:
			other.erase(key)
			return true
	for slot_name: StringName in SLOT_ORDER:
		var key: String = String(slot_name)
		if key == sid:
			continue
		if str(doll.get(key, "")) == item_id:
			doll.erase(key)
			return true
	return false


func try_unequip(slot_id: String, actor: String = "keeper") -> String:
	var sid: String = _canonical_slot(slot_id)
	if not is_known_slot(sid):
		return "missing"
	var doll: Dictionary = _doll(actor)
	var iid: String = str(doll.get(sid, ""))
	if iid == "":
		return "empty"
	_add_unequipped(iid, 1)
	doll.erase(sid)
	equipment_changed.emit()
	return "ok"


func grant_item(item_id: String) -> bool:
	return add_gear(item_id, 1)


## Spare / Defeat (and load migration): unlock Relic, own the Key relic.
## Auto-equip only when the relic slot is empty; otherwise leave in gear inventory.
func ensure_forge_key_from_load() -> void:
	## Grant and auto-equip only when the Key item is missing. A migrated Key stays in the bag.
	_migrate_legacy_forge_key_id()
	if not owns_anywhere("forge_key_relic"):
		grant_item("forge_key_relic")
		if equipped_id("relic") == "" and unequipped_count("forge_key_relic") > 0:
			try_equip("forge_key_relic")
			return
	equipment_changed.emit()


func ensure_forge_key_equipped() -> void:
	if has_node("/root/GameState"):
		GameState.forge_key = true
	_migrate_legacy_forge_key_id()
	if not owns_anywhere("forge_key_relic"):
		grant_item("forge_key_relic")
	if equipped_id("relic") == "forge_key_relic":
		equipment_changed.emit()
		return
	if equipped_id("relic") == "" and unequipped_count("forge_key_relic") > 0:
		try_equip("forge_key_relic")
		return
	equipment_changed.emit()


func _migrate_legacy_forge_key_id() -> void:
	## Pre-v0.6.1 drafts used item id `forge_key`. Rename in place; no SAVE_VERSION bump.
	if equipped_id("relic") == "forge_key":
		equipped["relic"] = "forge_key_relic"
	if equipped_id_for("elaia", "relic") == "forge_key":
		elaia_equipped["relic"] = "forge_key_relic"
	var n: int = int(gear_inventory.get("forge_key", 0))
	if n > 0:
		gear_inventory.erase("forge_key")
		gear_inventory["forge_key_relic"] = int(gear_inventory.get("forge_key_relic", 0)) + n


func spend_known_gear(item_id: String, amount: int) -> bool:
	return _spend_gear_anywhere(item_id, amount)


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
		if has_node("/root/Backpack") and Backpack.has_method("counted_item_name"):
			name = Backpack.counted_item_name(iid, need, name)
		lines.append("%s %d/%d" % [name, have, need])
	return lines


func try_craft(recipe_id: String) -> String:
	## Anvil upgrades are not crafted from the hub. Handcraft stays instant.
	if recipe_station(recipe_id) == "anvil":
		return "anvil"
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
	## Equipped gear, both dolls, and the gear inventory stay. Backpack still wipes.
	pass


func reset_for_new_game() -> void:
	gear_inventory.clear()
	equipped.clear()
	elaia_equipped.clear()
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


func elaia_equipped_to_save() -> Dictionary:
	var eq_out: Dictionary = {}
	for slot_id: StringName in SLOT_ORDER:
		var key: String = String(slot_id)
		var iid: String = equipped_id_for("elaia", key)
		eq_out[key] = iid if iid != "" else null
	return eq_out


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
	## Forge Key auto-equip runs after Elaia's doll is loaded. See GameState.apply_save_dict.
	equipment_changed.emit()


func apply_elaia_equipped(raw: Variant) -> void:
	elaia_equipped.clear()
	if typeof(raw) != TYPE_DICTIONARY:
		equipment_changed.emit()
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
		elaia_equipped[key] = iid
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
	for actor_name: String in ["keeper", "elaia"]:
		if need <= 0:
			break
		var doll: Dictionary = _doll(actor_name)
		for slot_id: StringName in SLOT_ORDER:
			if need <= 0:
				break
			var key: String = String(slot_id)
			if str(doll.get(key, "")) != item_id:
				continue
			doll.erase(key)
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
