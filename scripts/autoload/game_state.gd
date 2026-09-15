extends Node
## Run + prestige state per SYSTEMS_V01 v0.1.3 + welcome flag. Fully typed.

signal resources_changed(resource_id: StringName, new_amount: int)
signal stage_changed(stage_id: StringName)
signal growth_changed(growth: int, required: int)
signal fruit_ready_changed(ready: bool)
signal upgrades_changed
signal status_message(text: String)
signal load_completed

const STAGE_ORDER: Array[StringName] = [
	&"sapling", &"young", &"mature", &"elder", &"ancient"
]
const OFFER_IDS: Array[StringName] = [&"wood", &"stone", &"food", &"manashards"]
const HARVEST_IDS: Array[StringName] = [&"wood", &"stone", &"food"]

var wood: int = 0
var stone: int = 0
var food: int = 0
var manashards: int = 0
var essence: int = 0

var stage_id: StringName = &"sapling"
var growth: int = 0
var fruit_ready: bool = false
## True after Fruit harvested this cycle; waiting for Ascend.
var fruit_harvested_pending_ascend: bool = false
## True after first-boot welcome was dismissed (once per new save).
var welcome_shown: bool = false

var ascensions: int = 0
var lifetime_waters: int = 0
var lifetime_shards_from_water: int = 0
var lifetime_essence_from_water: int = 0
var lifetime_offered: Dictionary = {}
var lifetime_fruit_harvested: int = 0
var lifetime_harvested: Dictionary = {}
var upgrade_ranks: Dictionary = {}

var stages_data: Array = []
var upgrades_data: Array = []
var params: Dictionary = {}

var _offer_cooldown_until: float = 0.0


func _ready() -> void:
	_load_tables()
	_ensure_upgrade_keys()
	_ensure_offer_keys()
	_ensure_harvest_keys()


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


func _ensure_offer_keys() -> void:
	for rid: StringName in OFFER_IDS:
		var key: String = String(rid)
		if not lifetime_offered.has(key):
			lifetime_offered[key] = 0


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


func get_water_growth_amount() -> int:
	return param_int("WATER_GROWTH", 1) + int(get_effect_total("water_growth_bonus"))


func get_offer_growth_amount(resource_id: StringName) -> int:
	var key: String = "OFFER_GROWTH_%s" % String(resource_id).to_upper()
	return param_int(key, 10)


func get_offer_cost(resource_id: StringName) -> int:
	return param_int("OFFER_COST", 1)


func get_lifetime_offers_total() -> int:
	var total: int = 0
	for rid: StringName in OFFER_IDS:
		total += int(lifetime_offered.get(String(rid), 0))
	return total


func get_growth_required_for_next() -> int:
	var next_id: StringName = get_next_stage_id()
	if next_id == &"":
		return 0
	var def: Dictionary = get_stage_def(next_id)
	var raw: int = int(def.get("growth_required", 0))
	var reduced: int = raw - int(get_effect_total("growth_required_reduction"))
	return maxi(10, reduced)


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


## Water channel pulse: manashards U{1,3}+shard_sight, essence+1, growth (unless blocked by pending ascend).
## At Ancient: still pays shards+essence; no further stage growth.
func apply_water_pulse() -> Dictionary:
	if fruit_harvested_pending_ascend:
		return {"ok": false, "reason": "pending_ascend", "shards": 0, "essence": 0, "growth": 0}
	var shard_min: int = param_int("WATER_SHARD_MIN", 1)
	var shard_max: int = param_int("WATER_SHARD_MAX", 3)
	var shards: int = randi_range(shard_min, shard_max) + int(get_effect_total("water_shard_bonus"))
	var ess: int = param_int("WATER_ESSENCE_PER_SEC", 1)
	add_resource(&"manashards", shards)
	add_resource(&"essence", ess)
	lifetime_waters += 1
	lifetime_shards_from_water += shards
	lifetime_essence_from_water += ess
	var add_g: int = 0
	if stage_id != &"ancient":
		add_g = get_water_growth_amount()
		growth += add_g
		var required: int = get_growth_required_for_next()
		growth_changed.emit(growth, required)
		_try_stage_up()
	else:
		growth_changed.emit(growth, 0)
	return {"ok": true, "reason": "ok", "shards": shards, "essence": ess, "growth": add_g}


## Legacy one-shot entry used by older verify paths — delegates to a single water pulse.
func try_water() -> String:
	var result: Dictionary = apply_water_pulse()
	if not bool(result.get("ok", false)):
		return str(result.get("reason", "fail"))
	return "ok"


func get_upgrade_cost(upgrade_id: String) -> int:
	var def: Dictionary = get_upgrade_def(upgrade_id)
	if def.is_empty():
		return 999999
	var rank: int = get_upgrade_rank(upgrade_id)
	return int(def.get("cost_base", 1)) + int(def.get("cost_per_rank", 1)) * rank


func can_buy_upgrade(upgrade_id: String) -> bool:
	var def: Dictionary = get_upgrade_def(upgrade_id)
	if def.is_empty():
		return false
	var max_rank: int = int(def.get("max_rank", 1))
	if get_upgrade_rank(upgrade_id) >= max_rank:
		return false
	return essence >= get_upgrade_cost(upgrade_id)


func buy_upgrade(upgrade_id: String) -> bool:
	if not can_buy_upgrade(upgrade_id):
		return false
	var cost: int = get_upgrade_cost(upgrade_id)
	add_resource(&"essence", -cost)
	upgrade_ranks[upgrade_id] = get_upgrade_rank(upgrade_id) + 1
	upgrades_changed.emit()
	return true


func _mats_for_next() -> Dictionary:
	var next_id: StringName = get_next_stage_id()
	if next_id == &"":
		return {}
	var def: Dictionary = get_stage_def(next_id)
	return {
		"wood": int(def.get("cost_wood", 0)),
		"stone": int(def.get("cost_stone", 0)),
		"food": int(def.get("cost_food", 0)),
		"manashards": int(def.get("cost_manashards", 0)),
	}


func has_mats_for_next() -> bool:
	var mats: Dictionary = _mats_for_next()
	return wood >= int(mats.get("wood", 0)) \
		and stone >= int(mats.get("stone", 0)) \
		and food >= int(mats.get("food", 0)) \
		and manashards >= int(mats.get("manashards", 0))


func format_missing_mats() -> String:
	return _join_cost_parts(_remaining_cost_parts())


func get_remaining_gate_costs() -> Dictionary:
	## Amount still needed for next stage gate (max 0). Empty if Ancient / no next.
	var mats: Dictionary = _mats_for_next()
	if mats.is_empty():
		return {}
	return {
		"wood": maxi(0, int(mats.get("wood", 0)) - wood),
		"stone": maxi(0, int(mats.get("stone", 0)) - stone),
		"food": maxi(0, int(mats.get("food", 0)) - food),
		"manashards": maxi(0, int(mats.get("manashards", 0)) - manashards),
	}


func get_next_stage_gate_costs() -> Dictionary:
	return _mats_for_next()


func _remaining_cost_parts() -> PackedStringArray:
	var rem: Dictionary = get_remaining_gate_costs()
	var parts: PackedStringArray = PackedStringArray()
	if int(rem.get("wood", 0)) > 0:
		parts.append(ContentStrings.get_text("tree_stage_blocked_wood", {"count": int(rem["wood"])}))
	if int(rem.get("stone", 0)) > 0:
		parts.append(ContentStrings.get_text("tree_stage_blocked_stone", {"count": int(rem["stone"])}))
	if int(rem.get("food", 0)) > 0:
		parts.append(ContentStrings.get_text("tree_stage_blocked_food", {"count": int(rem["food"])}))
	if int(rem.get("manashards", 0)) > 0:
		parts.append(ContentStrings.get_text("tree_stage_blocked_shards", {"count": int(rem["manashards"])}))
	return parts


func _join_cost_parts(parts: PackedStringArray) -> String:
	## Content: commas + "and" — e.g. Wood ×4, Stone ×2, and Food ×2.
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


func format_remaining_gate_costs() -> String:
	return _join_cost_parts(_remaining_cost_parts())


## Care-menu / HUD helper: next-stage growth + remaining mats, or Ancient fruit/ascend state.
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
			"growth_line": ancient_line,
			"needs_header": "",
			"needs_line": "",
			"ready_for_fruit": fruit_ready,
			"pending_ascend": fruit_harvested_pending_ascend,
		}
	var next_id: StringName = get_next_stage_id()
	var next_def: Dictionary = get_stage_def(next_id)
	var next_display: String = str(next_def.get("display_name", next_id))
	var required: int = get_growth_required_for_next()
	var growth_line: String
	if growth >= required and required > 0:
		growth_line = ContentStrings.get_text("tree_next_stage_growth_ready")
	else:
		growth_line = ContentStrings.get_text("tree_next_stage_growth", {"current": growth, "required": required})
	var gate: Dictionary = get_next_stage_gate_costs()
	var total_gate: int = int(gate.get("wood", 0)) + int(gate.get("stone", 0)) + int(gate.get("food", 0)) + int(gate.get("manashards", 0))
	var needs_header: String = ContentStrings.get_text("tree_next_stage_needs_header")
	var needs_line: String
	if total_gate <= 0:
		needs_line = ContentStrings.get_text("tree_next_stage_needs_none")
	elif has_mats_for_next():
		needs_line = ContentStrings.get_text("tree_next_stage_needs_met")
	else:
		var costs: String = format_remaining_gate_costs()
		needs_line = ContentStrings.get_text("tree_next_stage_needs_line", {"costs": costs})
	return {
		"is_ancient": false,
		"title": ContentStrings.get_text("tree_next_stage_title", {"next_stage": next_display}),
		"growth_line": growth_line,
		"needs_header": needs_header,
		"needs_line": needs_line,
		"growth": growth,
		"required": required,
		"remaining_costs": get_remaining_gate_costs(),
		"ready_for_fruit": false,
		"pending_ascend": false,
	}


func try_offer(resource_id: StringName) -> String:
	## Spend soft mat for OFFER_GROWTH; separate anti-spam cooldown. Instant (not channelled).
	if stage_id == &"ancient" or fruit_harvested_pending_ascend:
		return "ancient"
	if not resource_id in OFFER_IDS:
		return "bad_resource"
	var now: float = Time.get_ticks_msec() / 1000.0
	if now < _offer_cooldown_until:
		return "cooldown"
	var cost: int = get_offer_cost(resource_id)
	if get_resource(resource_id) < cost:
		return "no_res"
	add_resource(resource_id, -cost)
	var key: String = String(resource_id)
	lifetime_offered[key] = int(lifetime_offered.get(key, 0)) + cost
	_offer_cooldown_until = now + param_float("OFFER_COOLDOWN_SEC", 0.25)
	growth += get_offer_growth_amount(resource_id)
	var required: int = get_growth_required_for_next()
	growth_changed.emit(growth, required)
	_try_stage_up()
	return "ok"


func _try_stage_up() -> void:
	var next_id: StringName = get_next_stage_id()
	if next_id == &"":
		return
	var required: int = get_growth_required_for_next()
	if growth < required:
		return
	if not has_mats_for_next():
		growth = required
		growth_changed.emit(growth, required)
		status_message.emit(ContentStrings.get_text("tree_stage_blocked_mats", {"costs": format_missing_mats()}))
		return
	var mats: Dictionary = _mats_for_next()
	add_resource(&"wood", -int(mats.get("wood", 0)))
	add_resource(&"stone", -int(mats.get("stone", 0)))
	add_resource(&"food", -int(mats.get("food", 0)))
	add_resource(&"manashards", -int(mats.get("manashards", 0)))
	if bool(params.get("GROWTH_CARRIES", true)):
		growth = growth - required
	else:
		growth = 0
	_set_stage(next_id)
	var toast_key: String = "stage_up_%s" % String(next_id)
	status_message.emit(ContentStrings.get_text(toast_key))
	growth_changed.emit(growth, get_growth_required_for_next())


func _set_stage(id: StringName) -> void:
	stage_id = id
	var def: Dictionary = get_stage_def(id)
	fruit_ready = bool(def.get("grants_fruit", false)) and not fruit_harvested_pending_ascend
	stage_changed.emit(stage_id)
	fruit_ready_changed.emit(fruit_ready)


func harvest_fruit() -> int:
	if stage_id != &"ancient" or fruit_harvested_pending_ascend:
		return 0
	## v0.1.2: flat ESSENCE_PER_HARVEST burst (watering already paid essence over time).
	var gained: int = param_int("ESSENCE_PER_HARVEST", 5)
	add_resource(&"essence", gained)
	lifetime_fruit_harvested += 1
	fruit_ready = false
	fruit_harvested_pending_ascend = true
	fruit_ready_changed.emit(false)
	return gained


func can_ascend() -> bool:
	return fruit_harvested_pending_ascend


func ascend() -> void:
	if not fruit_harvested_pending_ascend:
		return
	ascensions += 1
	wood = 0
	stone = 0
	food = 0
	manashards = 0
	growth = 0
	fruit_harvested_pending_ascend = false
	fruit_ready = false
	_set_stage(&"sapling")
	resources_changed.emit(&"wood", wood)
	resources_changed.emit(&"stone", stone)
	resources_changed.emit(&"food", food)
	resources_changed.emit(&"manashards", manashards)
	resources_changed.emit(&"essence", essence)
	growth_changed.emit(growth, get_growth_required_for_next())
	status_message.emit(ContentStrings.get_text("ascend_toast"))


func to_save_dict() -> Dictionary:
	return {
		"wood": wood,
		"stone": stone,
		"food": food,
		"manashards": manashards,
		"essence": essence,
		"stage_id": String(stage_id),
		"growth": growth,
		"fruit_ready": fruit_ready,
		"fruit_harvested_pending_ascend": fruit_harvested_pending_ascend,
		"welcome_shown": welcome_shown,
		"ascensions": ascensions,
		"lifetime_waters": lifetime_waters,
		"lifetime_shards_from_water": lifetime_shards_from_water,
		"lifetime_essence_from_water": lifetime_essence_from_water,
		"lifetime_offered": lifetime_offered.duplicate(true),
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
	growth = int(data.get("growth", 0))
	fruit_ready = bool(data.get("fruit_ready", false))
	fruit_harvested_pending_ascend = bool(data.get("fruit_harvested_pending_ascend", false))
	welcome_shown = bool(data.get("welcome_shown", false))
	ascensions = int(data.get("ascensions", data.get("ascension_count", 0)))
	lifetime_waters = int(data.get("lifetime_waters", 0))
	lifetime_shards_from_water = int(data.get("lifetime_shards_from_water", 0))
	lifetime_essence_from_water = int(data.get("lifetime_essence_from_water", 0))
	var offered: Variant = data.get("lifetime_offered", {})
	if typeof(offered) == TYPE_DICTIONARY:
		lifetime_offered = (offered as Dictionary).duplicate(true)
	else:
		lifetime_offered = {}
	_ensure_offer_keys()
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
	growth_changed.emit(growth, get_growth_required_for_next())
	upgrades_changed.emit()
	load_completed.emit()


func reset_for_new_game() -> void:
	wood = 0
	stone = 0
	food = 0
	manashards = 0
	essence = 0
	stage_id = &"sapling"
	growth = 0
	fruit_ready = false
	fruit_harvested_pending_ascend = false
	welcome_shown = false
	ascensions = 0
	lifetime_waters = 0
	lifetime_shards_from_water = 0
	lifetime_essence_from_water = 0
	lifetime_offered.clear()
	_ensure_offer_keys()
	lifetime_fruit_harvested = 0
	lifetime_harvested.clear()
	_ensure_harvest_keys()
	upgrade_ranks.clear()
	_ensure_upgrade_keys()
	_offer_cooldown_until = 0.0
