extends Node
## Run + prestige state per SYSTEMS_V01 v0.2.3 — needs-only; Ascension Manashard blessing shop. Fully typed.

signal resources_changed(resource_id: StringName, new_amount: int)
signal stage_changed(stage_id: StringName)
signal needs_changed
signal fruit_ready_changed(ready: bool)
signal upgrades_changed
signal status_message(text: String)
signal load_completed

const STAGE_ORDER: Array[StringName] = [
	&"sapling", &"young", &"mature", &"elder", &"ancient"
]
const HARVEST_IDS: Array[StringName] = [&"wood", &"stone", &"food"]
## Soft mats that green_thumb can reduce (not essence).
const SOFT_NEED_IDS: Array[StringName] = [&"food", &"wood", &"stone", &"manashards"]
const NEED_ORDER: Array[StringName] = [&"essence", &"food", &"wood", &"stone", &"manashards"]

var wood: int = 0
var stone: int = 0
var food: int = 0
var manashards: int = 0
var essence: int = 0

var stage_id: StringName = &"sapling"
var fruit_ready: bool = false
## True after Fruit harvested this cycle; waiting for Ascend.
var fruit_harvested_pending_ascend: bool = false
## True after first-boot welcome was dismissed (once per new save).
var welcome_shown: bool = false

## Accumulated unpaused sim time (freezes while SceneTree.paused).
var run_time_sec: float = 0.0

var ascensions: int = 0
var lifetime_waters: int = 0
var lifetime_shards_from_water: int = 0
var lifetime_essence_from_water: int = 0
var lifetime_fruit_harvested: int = 0
var lifetime_harvested: Dictionary = {}
var upgrade_ranks: Dictionary = {}

var stages_data: Array = []
var upgrades_data: Array = []
var params: Dictionary = {}


func _ready() -> void:
	# Autoloads inherit root ALWAYS — force pausable so pause freezes run_time / logic.
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_load_tables()
	_ensure_upgrade_keys()
	_ensure_harvest_keys()


func _process(delta: float) -> void:
	## Pausable by default — stops when get_tree().paused (pause menu).
	run_time_sec += delta


func _load_tables() -> void:
	var file := FileAccess.open("res://data/manatree_stages.json", FileAccess.READ)
	if file == null:
		push_error("GameState: cannot open manatree_stages.json")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var root: Dictionary = parsed
	params = root.get("params", {}) as Dictionary
	var stages: Variant = root.get("stages", [])
	stages_data = stages if typeof(stages) == TYPE_ARRAY else []
	var uf := FileAccess.open("res://data/fruit_upgrades.json", FileAccess.READ)
	if uf == null:
		return
	var up: Variant = JSON.parse_string(uf.get_as_text())
	uf.close()
	if typeof(up) == TYPE_DICTIONARY:
		var uroot: Dictionary = up
		var arr: Variant = uroot.get("upgrades", [])
		upgrades_data = arr if typeof(arr) == TYPE_ARRAY else []


func _ensure_upgrade_keys() -> void:
	for entry: Variant in upgrades_data:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = entry
		var uid: String = str(d.get("id", ""))
		if uid != "" and not upgrade_ranks.has(uid):
			upgrade_ranks[uid] = 0


func _ensure_harvest_keys() -> void:
	for rid: StringName in HARVEST_IDS:
		var key: String = String(rid)
		if not lifetime_harvested.has(key):
			lifetime_harvested[key] = 0


func param_int(key: String, default_v: int = 0) -> int:
	return int(params.get(key, default_v))


func param_float(key: String, default_v: float = 0.0) -> float:
	return float(params.get(key, default_v))


func get_resource(resource_id: StringName) -> int:
	match resource_id:
		&"wood":
			return wood
		&"stone":
			return stone
		&"food":
			return food
		&"manashards":
			return manashards
		&"essence":
			return essence
		_:
			return 0


func set_resource(resource_id: StringName, amount: int) -> void:
	amount = maxi(amount, 0)
	match resource_id:
		&"wood":
			wood = amount
		&"stone":
			stone = amount
		&"food":
			food = amount
		&"manashards":
			manashards = amount
		&"essence":
			essence = amount
		_:
			return
	resources_changed.emit(resource_id, amount)
	needs_changed.emit()


func add_resource(resource_id: StringName, delta: int) -> void:
	set_resource(resource_id, get_resource(resource_id) + delta)


func get_stage_index(id: StringName = stage_id) -> int:
	return STAGE_ORDER.find(id)


func get_stage_def(id: StringName = stage_id) -> Dictionary:
	for entry: Variant in stages_data:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = entry
		if str(d.get("id", "")) == String(id):
			return d
	return {}


func get_next_stage_id() -> StringName:
	var idx: int = get_stage_index()
	if idx < 0 or idx >= STAGE_ORDER.size() - 1:
		return &""
	return STAGE_ORDER[idx + 1]


func get_upgrade_rank(upgrade_id: String) -> int:
	return int(upgrade_ranks.get(upgrade_id, 0))


func get_upgrade_def(upgrade_id: String) -> Dictionary:
	for entry: Variant in upgrades_data:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = entry
		if str(d.get("id", "")) == upgrade_id:
			return d
	return {}


func get_effect_total(effect_name: String) -> float:
	var total: float = 0.0
	for entry: Variant in upgrades_data:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = entry
		if str(d.get("effect", "")) != effect_name:
			continue
		var uid: String = str(d.get("id", ""))
		total += float(d.get("value_per_rank", 0)) * float(get_upgrade_rank(uid))
	return total


func get_water_essence_amount() -> int:
	## Base + floor(deep_roots_rank / 2) per SYSTEMS v0.2.0.
	var base_amt: int = param_int("WATER_ESSENCE_PER_SEC", 1)
	var deep_rank: int = get_upgrade_rank("deep_roots")
	return base_amt + int(floor(float(deep_rank) / 2.0))


func get_stage_gather_mult() -> float:
	var def: Dictionary = get_stage_def()
	return float(def.get("gather_mult", 1.0))


func get_global_gather_mult() -> float:
	return get_stage_gather_mult() + get_effect_total("gather_mult_bonus")


func get_move_speed() -> float:
	var base_s: float = param_float("BASE_MOVE_SPEED", 180.0)
	var mult: float = 1.0 + get_effect_total("move_speed_mult")
	return base_s * mult


func get_channel_pulse_sec() -> float:
	return param_float("CHANNEL_PULSE_SEC", 1.0)


func get_harvest_range() -> float:
	return param_float("HARVEST_RANGE_PX", 48.0)


## Harvest channel pulse grant (wood/stone/food). Essence is NOT from harvest nodes.
func get_harvest_grant(resource_id: StringName) -> int:
	var key: String = "HARVEST_%s_PER_SEC" % String(resource_id).to_upper()
	var base_amt: int = param_int(key, 1)
	var amount: float = float(base_amt) * get_global_gather_mult()
	return maxi(1, int(floor(amount)))


## Alias kept for older call sites / verify.
func get_gather_grant(resource_id: StringName) -> int:
	return get_harvest_grant(resource_id)


func apply_harvest_pulse(resource_id: StringName) -> int:
	if not resource_id in HARVEST_IDS:
		return 0
	var grant: int = get_harvest_grant(resource_id)
	add_resource(resource_id, grant)
	var key: String = String(resource_id)
	lifetime_harvested[key] = int(lifetime_harvested.get(key, 0)) + grant
	return grant


## Water channel pulse: manashards U{1,3}+shard_sight, essence income only (no growth).
## At Ancient: still pays shards+essence.
func apply_water_pulse() -> Dictionary:
	if fruit_harvested_pending_ascend:
		return {"ok": false, "reason": "pending_ascend", "shards": 0, "essence": 0}
	var shard_min: int = param_int("WATER_SHARD_MIN", 1)
	var shard_max: int = param_int("WATER_SHARD_MAX", 3)
	var shards: int = randi_range(shard_min, shard_max) + int(get_effect_total("water_shard_bonus"))
	var ess: int = get_water_essence_amount()
	add_resource(&"manashards", shards)
	add_resource(&"essence", ess)
	lifetime_waters += 1
	lifetime_shards_from_water += shards
	lifetime_essence_from_water += ess
	return {"ok": true, "reason": "ok", "shards": shards, "essence": ess}


## Legacy one-shot entry used by older verify paths — delegates to a single water pulse.
func try_water() -> String:
	var result: Dictionary = apply_water_pulse()
	if not bool(result.get("ok", false)):
		return str(result.get("reason", "fail"))
	return "ok"


func get_upgrade_cost(upgrade_id: String) -> int:
	## SYSTEMS v0.2.5: cost = SHOP_BASE * (rank + 1) via cost_base=400, cost_per_rank=400.
	var def: Dictionary = get_upgrade_def(upgrade_id)
	if def.is_empty():
		return 999999
	var rank: int = get_upgrade_rank(upgrade_id)
	return int(def.get("cost_base", 1)) + int(def.get("cost_per_rank", 1)) * rank


func can_buy_upgrade(upgrade_id: String) -> bool:
	## Manashard shop — only while awaiting Ascend after Fruit harvest.
	if not fruit_harvested_pending_ascend:
		return false
	var def: Dictionary = get_upgrade_def(upgrade_id)
	if def.is_empty():
		return false
	var max_rank: int = int(def.get("max_rank", 1))
	if get_upgrade_rank(upgrade_id) >= max_rank:
		return false
	return manashards >= get_upgrade_cost(upgrade_id)


func buy_upgrade(upgrade_id: String) -> bool:
	## Spend Manashards for +1 blessing rank (multi-buy OK). Essence untouched.
	if not can_buy_upgrade(upgrade_id):
		return false
	var cost: int = get_upgrade_cost(upgrade_id)
	add_resource(&"manashards", -cost)
	upgrade_ranks[upgrade_id] = get_upgrade_rank(upgrade_id) + 1
	upgrades_changed.emit()
	needs_changed.emit()
	return true


func _raw_needs_for_next() -> Dictionary:
	var next_id: StringName = get_next_stage_id()
	if next_id == &"":
		return {}
	var def: Dictionary = get_stage_def(next_id)
	return {
		"essence": int(def.get("cost_essence", 0)),
		"food": int(def.get("cost_food", 0)),
		"wood": int(def.get("cost_wood", 0)),
		"stone": int(def.get("cost_stone", 0)),
		"manashards": int(def.get("cost_manashards", 0)),
	}


## Applies green_thumb soft-mat −10%/rank (floor, min 1 if >0). Essence unchanged.
func get_next_stage_needs() -> Dictionary:
	var raw: Dictionary = _raw_needs_for_next()
	if raw.is_empty():
		return {}
	var thumb_rank: int = get_upgrade_rank("green_thumb")
	var reduction: float = 0.1 * float(thumb_rank)
	var out: Dictionary = {}
	for rid: StringName in NEED_ORDER:
		var key: String = String(rid)
		var need: int = int(raw.get(key, 0))
		if need <= 0:
			continue
		if rid in SOFT_NEED_IDS and thumb_rank > 0:
			var reduced: int = int(floor(float(need) * (1.0 - reduction)))
			need = maxi(1, reduced)
		out[key] = need
	return out


func has_needs_for_next() -> bool:
	var needs: Dictionary = get_next_stage_needs()
	if needs.is_empty():
		return false
	for key: Variant in needs.keys():
		var rid: StringName = StringName(str(key))
		if get_resource(rid) < int(needs[key]):
			return false
	return true


func can_pay_stage() -> bool:
	if stage_id == &"ancient" or fruit_harvested_pending_ascend:
		return false
	return has_needs_for_next()


func get_remaining_needs() -> Dictionary:
	var needs: Dictionary = get_next_stage_needs()
	var rem: Dictionary = {}
	for key: Variant in needs.keys():
		var k: String = str(key)
		var need: int = int(needs[k])
		var have: int = get_resource(StringName(k))
		rem[k] = maxi(0, need - have)
	return rem


func _item_display(resource_id: String) -> String:
	match resource_id:
		"essence":
			return ContentStrings.get_text("hud_essence")
		"food":
			return ContentStrings.get_text("hud_food")
		"wood":
			return ContentStrings.get_text("hud_wood")
		"stone":
			return ContentStrings.get_text("hud_stone")
		"manashards":
			return ContentStrings.get_text("hud_manashards")
		_:
			return resource_id.capitalize()


func format_need_checklist_lines() -> PackedStringArray:
	var needs: Dictionary = get_next_stage_needs()
	var lines: PackedStringArray = PackedStringArray()
	for rid: StringName in NEED_ORDER:
		var key: String = String(rid)
		if not needs.has(key):
			continue
		var need: int = int(needs[key])
		if need <= 0:
			continue
		var have: int = get_resource(rid)
		var item: String = _item_display(key)
		var toks: Dictionary = {"item": item, "have": have, "need": need}
		if have >= need:
			lines.append(ContentStrings.get_text("tree_need_line_met", toks))
		else:
			lines.append(ContentStrings.get_text("tree_need_line", toks))
	return lines


func format_missing_needs() -> String:
	return _join_cost_parts(_remaining_need_parts())


func _remaining_need_parts() -> PackedStringArray:
	var needs: Dictionary = get_next_stage_needs()
	var parts: PackedStringArray = PackedStringArray()
	for rid: StringName in NEED_ORDER:
		var key: String = String(rid)
		if not needs.has(key):
			continue
		var need: int = int(needs[key])
		var have: int = get_resource(rid)
		if have >= need:
			continue
		var toks: Dictionary = {"have": have, "need": need, "count": need - have}
		match rid:
			&"essence":
				parts.append(ContentStrings.get_text("tree_stage_blocked_essence", toks))
			&"food":
				parts.append(ContentStrings.get_text("tree_stage_blocked_food", toks))
			&"wood":
				parts.append(ContentStrings.get_text("tree_stage_blocked_wood", toks))
			&"stone":
				parts.append(ContentStrings.get_text("tree_stage_blocked_stone", toks))
			&"manashards":
				parts.append(ContentStrings.get_text("tree_stage_blocked_shards", {
					"count": need - have, "have": have, "need": need
				}))
	return parts


func _join_cost_parts(parts: PackedStringArray) -> String:
	## Content: commas + "and".
	if parts.is_empty():
		return ""
	if parts.size() == 1:
		return parts[0]
	if parts.size() == 2:
		return "%s and %s" % [parts[0], parts[1]]
	var head: PackedStringArray = PackedStringArray()
	for i: int in range(parts.size() - 1):
		head.append(parts[i])
	return "%s, and %s" % [", ".join(head), parts[parts.size() - 1]]


## Care-menu / HUD helper: next-stage needs checklist, or Ancient fruit/ascend state.
func get_care_next_stage_info() -> Dictionary:
	if stage_id == &"ancient" or fruit_harvested_pending_ascend:
		var ancient_line: String = ContentStrings.get_text("tree_at_ancient_idle")
		if fruit_harvested_pending_ascend:
			ancient_line = ContentStrings.get_text("ascend_prompt")
		elif fruit_ready:
			ancient_line = ContentStrings.get_text("fruit_ready_prompt")
		return {
			"is_ancient": true,
			"title": str(get_stage_def().get("display_name", "Ancient")),
			"needs_header": "",
			"needs_lines": PackedStringArray([ancient_line]),
			"needs_status": ancient_line,
			"can_pay": false,
			"ready_for_fruit": fruit_ready,
			"pending_ascend": fruit_harvested_pending_ascend,
		}
	var next_id: StringName = get_next_stage_id()
	var next_def: Dictionary = get_stage_def(next_id)
	var next_display: String = str(next_def.get("display_name", next_id))
	var lines: PackedStringArray = format_need_checklist_lines()
	var needs: Dictionary = get_next_stage_needs()
	var status: String
	if needs.is_empty():
		status = ContentStrings.get_text("tree_next_stage_needs_none")
	elif has_needs_for_next():
		status = ContentStrings.get_text("tree_next_stage_needs_met")
	else:
		status = ContentStrings.get_text("tree_pay_cant_afford", {"costs": format_missing_needs()})
	return {
		"is_ancient": false,
		"title": ContentStrings.get_text("tree_next_stage_title", {"next_stage": next_display}),
		"needs_header": ContentStrings.get_text("tree_next_stage_needs_header"),
		"needs_lines": lines,
		"needs_status": status,
		"can_pay": has_needs_for_next(),
		"next_stage_display": next_display,
		"ready_for_fruit": false,
		"pending_ascend": false,
	}


## Pay needs to advance one stage. Returns "ok" | "cant_afford" | "ancient" | "no_next".
func try_pay_stage() -> String:
	if stage_id == &"ancient" or fruit_harvested_pending_ascend:
		return "ancient"
	var next_id: StringName = get_next_stage_id()
	if next_id == &"":
		return "no_next"
	var needs: Dictionary = get_next_stage_needs()
	if needs.is_empty():
		return "no_next"
	if not has_needs_for_next():
		status_message.emit(ContentStrings.get_text("tree_pay_cant_afford", {"costs": format_missing_needs()}))
		return "cant_afford"
	for key: Variant in needs.keys():
		var rid: StringName = StringName(str(key))
		add_resource(rid, -int(needs[key]))
	_set_stage(next_id)
	var next_display: String = str(get_stage_def(next_id).get("display_name", next_id))
	status_message.emit(ContentStrings.get_text("tree_pay_ok", {"next_stage": next_display}))
	needs_changed.emit()
	return "ok"


## Alias for Content tree_advance* keys.
func try_advance() -> String:
	return try_pay_stage()


func _set_stage(id: StringName) -> void:
	stage_id = id
	var def: Dictionary = get_stage_def(id)
	fruit_ready = bool(def.get("grants_fruit", false)) and not fruit_harvested_pending_ascend
	stage_changed.emit(stage_id)
	fruit_ready_changed.emit(fruit_ready)
	needs_changed.emit()


func harvest_fruit() -> int:
	if stage_id != &"ancient" or fruit_harvested_pending_ascend:
		return 0
	## Flat ESSENCE_PER_HARVEST burst (watering already paid essence over time).
	var gained: int = param_int("ESSENCE_PER_HARVEST", 5)
	add_resource(&"essence", gained)
	lifetime_fruit_harvested += 1
	fruit_ready = false
	fruit_harvested_pending_ascend = true
	fruit_ready_changed.emit(false)
	return gained


func can_ascend() -> bool:
	## Ascend after Fruit harvest; Manashard purchases optional.
	return fruit_harvested_pending_ascend


func ascend() -> void:
	if not fruit_harvested_pending_ascend:
		return
	ascensions += 1
	wood = 0
	stone = 0
	food = 0
	manashards = 0
	fruit_harvested_pending_ascend = false
	fruit_ready = false
	_set_stage(&"sapling")
	resources_changed.emit(&"wood", wood)
	resources_changed.emit(&"stone", stone)
	resources_changed.emit(&"food", food)
	resources_changed.emit(&"manashards", manashards)
	resources_changed.emit(&"essence", essence)
	needs_changed.emit()
	status_message.emit(ContentStrings.get_text("ascend_toast"))


func to_save_dict() -> Dictionary:
	return {
		"wood": wood,
		"stone": stone,
		"food": food,
		"manashards": manashards,
		"essence": essence,
		"stage_id": String(stage_id),
		"fruit_ready": fruit_ready,
		"fruit_harvested_pending_ascend": fruit_harvested_pending_ascend,
		"welcome_shown": welcome_shown,
		"run_time_sec": run_time_sec,
		"ascensions": ascensions,
		"lifetime_waters": lifetime_waters,
		"lifetime_shards_from_water": lifetime_shards_from_water,
		"lifetime_essence_from_water": lifetime_essence_from_water,
		"lifetime_fruit_harvested": lifetime_fruit_harvested,
		"lifetime_harvested": lifetime_harvested.duplicate(true),
		"upgrades": upgrade_ranks.duplicate(true),
	}


func apply_save_dict(data: Dictionary) -> void:
	wood = int(data.get("wood", 0))
	stone = int(data.get("stone", 0))
	food = int(data.get("food", 0))
	manashards = int(data.get("manashards", 0))
	essence = int(data.get("essence", 0))
	stage_id = StringName(str(data.get("stage_id", "sapling")))
	# growth ignored (SAVE_VERSION 4 / v3 migrate)
	fruit_ready = bool(data.get("fruit_ready", false))
	fruit_harvested_pending_ascend = bool(data.get("fruit_harvested_pending_ascend", false))
	welcome_shown = bool(data.get("welcome_shown", false))
	run_time_sec = float(data.get("run_time_sec", 0.0))
	ascensions = int(data.get("ascensions", data.get("ascension_count", 0)))
	lifetime_waters = int(data.get("lifetime_waters", 0))
	lifetime_shards_from_water = int(data.get("lifetime_shards_from_water", 0))
	lifetime_essence_from_water = int(data.get("lifetime_essence_from_water", 0))
	lifetime_fruit_harvested = int(data.get("lifetime_fruit_harvested", 0))
	var harvested: Variant = data.get("lifetime_harvested", {})
	if typeof(harvested) == TYPE_DICTIONARY:
		lifetime_harvested = (harvested as Dictionary).duplicate(true)
	else:
		lifetime_harvested = {}
	_ensure_harvest_keys()
	var ranks: Variant = data.get("upgrades", data.get("upgrade_ranks", {}))
	if typeof(ranks) == TYPE_DICTIONARY:
		upgrade_ranks = (ranks as Dictionary).duplicate(true)
	_ensure_upgrade_keys()
	resources_changed.emit(&"wood", wood)
	resources_changed.emit(&"stone", stone)
	resources_changed.emit(&"food", food)
	resources_changed.emit(&"manashards", manashards)
	resources_changed.emit(&"essence", essence)
	stage_changed.emit(stage_id)
	fruit_ready_changed.emit(fruit_ready)
	needs_changed.emit()
	upgrades_changed.emit()
	load_completed.emit()


func reset_for_new_game() -> void:
	wood = 0
	stone = 0
	food = 0
	manashards = 0
	essence = 0
	stage_id = &"sapling"
	fruit_ready = false
	fruit_harvested_pending_ascend = false
	welcome_shown = false
	ascensions = 0
	lifetime_waters = 0
	lifetime_shards_from_water = 0
	lifetime_essence_from_water = 0
	lifetime_fruit_harvested = 0
	lifetime_harvested.clear()
	_ensure_harvest_keys()
	upgrade_ranks.clear()
	_ensure_upgrade_keys()
	run_time_sec = 0.0
