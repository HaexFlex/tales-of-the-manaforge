extends Node
## Run + prestige state per SYSTEMS_V01 v0.4.0 — Grow (Fertilizer+Essence), backpack via Backpack autoload. Fully typed.

signal resources_changed(resource_id: StringName, new_amount: int)
signal stage_changed(stage_id: StringName)
signal needs_changed
signal fruit_ready_changed(ready: bool)
signal upgrades_changed
signal status_message(text: String)
signal load_completed
signal wisps_changed
signal selection_changed
signal wisp_assigned(wisp_id: int, node_id: String, result: String)
signal wisp_assign_failed(reason: String, node_id: String)
signal wisp_unassigned(wisp_id: int)
signal wisp_pulsed(resource_id: StringName)

const STAGE_ORDER: Array[StringName] = [
	&"sapling", &"young", &"mature", &"elder", &"ancient"
]
const HARVEST_IDS: Array[StringName] = [&"wood", &"stone", &"food"]
## Grow spends Fertilizer + Essence only. green_thumb retargets to fertilizer *craft* cost (not Grow).
const NEED_ORDER: Array[StringName] = [&"essence", &"fertilizer"]
## Assignment target id for the Manatree. Stored as a string in SAVE_VERSION 5 — no schema bump.
## Playtest: multiple wisps may stack on the same target (harvest nodes and Manatree).
const NODE_ID_MANATREE: String = "manatree"

var wood: int = 0
var stone: int = 0
var food: int = 0
var manashards: int = 0
var essence: int = 0

var stage_id: StringName = &"sapling"
var fruit_ready: bool = false
## SYSTEMS v0.3.3: true after Fruit COMMIT (paused shop until Ascend). Design save field.
var fruit_committed: bool = false
## Legacy alias of fruit_committed (kept for existing call sites / SAVE_VERSION 5 payloads).
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

## node_id is harvest_tree/stone/berry or NODE_ID_MANATREE ("manatree"). String stays
## SAVE_VERSION 5 compatible — no schema bump for the new Manatree target type.
## Stacking allowed: any number of wisps may share one harvest node or the Manatree
## (WISP_PER_NODE / WISP_PER_MANATREE = 0 → unlimited). Each assigned wisp pulses independently.
var wisp_count: int = 0
var wisp_assignments: Dictionary = {}
var wisp_pulse_accum: Dictionary = {}
## Runtime selection (RTS: LMB select unit; mutually exclusive Keeper XOR one Wisp).
## Wisp select does not require Keeper selected.
var keeper_selected: bool = false
var selected_wisp_id: int = -1

var stages_data: Array = []
var upgrades_data: Array = []
var params: Dictionary = {}


func _ready() -> void:
	# Autoloads inherit root ALWAYS — force pausable so pause freezes run_time / logic.
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_load_tables()
	_ensure_upgrade_keys()
	_ensure_harvest_keys()
	_ensure_wisp_slots()
	if has_node("/root/Backpack") and not Backpack.inventory_changed.is_connected(_on_backpack_changed):
		Backpack.inventory_changed.connect(_on_backpack_changed)


func _process(delta: float) -> void:
	## Pausable by default — stops when get_tree().paused (pause menu).
	run_time_sec += delta
	apply_wisp_pulses(delta)


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



func get_wisp_pulse_sec() -> float:
	## Base 10s; wisp_haste −1s/rank; min 5s (SYSTEMS v0.3.0).
	var base_s: float = param_float("WISP_PULSE_SEC", 10.0)
	var haste: int = get_upgrade_rank("wisp_haste")
	return maxf(5.0, base_s - float(haste))


func get_wisp_capacity() -> int:
	return param_int("WISP_FROM_STAGES_MAX", 4) + get_upgrade_rank("bonus_wisp")


func get_wisp_assignment(wisp_id: int) -> String:
	return str(wisp_assignments.get(str(wisp_id), ""))


func node_id_for_resource(resource_id: StringName) -> String:
	match resource_id:
		&"wood":
			return "harvest_tree"
		&"stone":
			return "harvest_stone"
		&"food":
			return "harvest_berry"
		&"manashards":
			return NODE_ID_MANATREE
		_:
			return ""


func resource_for_node_id(node_id: String) -> StringName:
	match node_id:
		"harvest_tree":
			return &"wood"
		"harvest_stone":
			return &"stone"
		"harvest_berry":
			return &"food"
		"manatree":
			return &"manashards"
		_:
			return &""


func assignment_target_display(node_id: String) -> String:
	match node_id:
		"harvest_tree":
			return ContentStrings.get_text("node_wood_prompt")
		"harvest_stone":
			return ContentStrings.get_text("node_stone_prompt")
		"harvest_berry":
			return ContentStrings.get_text("node_food_prompt")
		NODE_ID_MANATREE:
			return ContentStrings.get_text("tree_menu_title")
		_:
			return node_id


func is_valid_wisp_node_id(node_id: String) -> bool:
	return resource_for_node_id(node_id) != &""


func _ensure_wisp_slots() -> void:
	for i: int in range(wisp_count):
		var key: String = str(i)
		if not wisp_assignments.has(key):
			wisp_assignments[key] = ""
		if not wisp_pulse_accum.has(key):
			wisp_pulse_accum[key] = 0.0
	var keys: Array = wisp_assignments.keys()
	for k: Variant in keys:
		var ks: String = str(k)
		if int(ks) >= wisp_count:
			wisp_assignments.erase(ks)
			wisp_pulse_accum.erase(ks)


func grant_wisp_from_stage() -> void:
	## +1 per successful Grow (Young→Ancient); capacity = 4 + bonus_wisp.
	if wisp_count >= get_wisp_capacity():
		return
	wisp_count += 1
	_ensure_wisp_slots()
	wisps_changed.emit()
	status_message.emit(ContentStrings.get_text("wisp_gained"))


func count_wisps_on_node(node_id: String) -> int:
	var n: int = 0
	for k: Variant in wisp_assignments.keys():
		if str(wisp_assignments[k]) == node_id:
			n += 1
	return n


func wisp_slot_index_on_node(wisp_id: int, node_id: String) -> int:
	## Stable 0-based index among wisps assigned to node_id (by wisp id order).
	var ids: Array[int] = []
	for k: Variant in wisp_assignments.keys():
		if str(wisp_assignments[k]) == node_id:
			ids.append(int(str(k)))
	ids.sort()
	var idx: int = ids.find(wisp_id)
	return idx if idx >= 0 else 0


func try_assign_wisp(wisp_id: int, node_id: String) -> String:
	## Returns "ok" | "reassign" | "invalid". Stacking allowed (no slot-full busy deny).
	if fruit_committed:
		wisp_assign_failed.emit("invalid", node_id)
		return "invalid"
	if wisp_id < 0 or wisp_id >= wisp_count:
		wisp_assign_failed.emit("invalid", node_id)
		return "invalid"
	if not is_valid_wisp_node_id(node_id):
		wisp_assign_failed.emit("invalid", node_id)
		return "invalid"
	var key: String = str(wisp_id)
	var prev: String = str(wisp_assignments.get(key, ""))
	if prev == node_id:
		selected_wisp_id = -1
		selection_changed.emit()
		return "ok"
	var joining: bool = count_wisps_on_node(node_id) > 0
	wisp_assignments[key] = node_id
	wisp_pulse_accum[key] = 0.0
	selected_wisp_id = -1
	wisps_changed.emit()
	selection_changed.emit()
	var result: String
	if joining:
		result = "join"
	elif prev != "":
		result = "reassign"
	else:
		result = "ok"
	wisp_assigned.emit(wisp_id, node_id, result)
	return result


func toast_wisp_assign(result: String, node_id: String) -> void:
	match result:
		"ok":
			if node_id == NODE_ID_MANATREE:
				status_message.emit(ContentStrings.get_text("wisp_assign_manatree_ok"))
			else:
				status_message.emit(ContentStrings.get_text("wisp_assign_ok"))
		"join":
			status_message.emit(ContentStrings.get_text("wisp_assign_join_ok"))
		"reassign":
			status_message.emit(ContentStrings.get_text("wisp_reassign_ok"))
		_:
			pass


func unassign_wisp(wisp_id: int) -> bool:
	if fruit_committed:
		return false
	if wisp_id < 0 or wisp_id >= wisp_count:
		return false
	var key: String = str(wisp_id)
	if str(wisp_assignments.get(key, "")) == "":
		return false
	wisp_assignments[key] = ""
	wisp_pulse_accum[key] = 0.0
	wisps_changed.emit()
	wisp_unassigned.emit(wisp_id)
	return true


func apply_wisp_pulses(delta: float) -> void:
	## AFK grant: +WISP_PULSE_GRANT of assigned resource every get_wisp_pulse_sec(). No gather_mult.
	## Each wisp has its own timer. Audio: one quiet pulse SFX per node/Manatree per tick
	## (not per wisp) when any grant fires on that target.
	if fruit_committed:
		return
	var pulse: float = get_wisp_pulse_sec()
	var grant: int = param_int("WISP_PULSE_GRANT", 1)
	var pulsed_nodes: Dictionary = {}
	for i: int in range(wisp_count):
		var key: String = str(i)
		var nid: String = str(wisp_assignments.get(key, ""))
		if nid == "":
			wisp_pulse_accum[key] = 0.0
			continue
		var acc: float = float(wisp_pulse_accum.get(key, 0.0)) + delta
		while acc >= pulse:
			acc -= pulse
			var rid: StringName = resource_for_node_id(nid)
			if rid != &"":
				add_resource(rid, grant)
				var hk: String = String(rid)
				lifetime_harvested[hk] = int(lifetime_harvested.get(hk, 0)) + grant
				pulsed_nodes[nid] = rid
		wisp_pulse_accum[key] = acc
	for nid2: Variant in pulsed_nodes.keys():
		wisp_pulsed.emit(pulsed_nodes[nid2] as StringName)


func set_keeper_selected(value: bool) -> void:
	if value:
		select_keeper()
		return
	if not keeper_selected:
		return
	keeper_selected = false
	selection_changed.emit()


func select_keeper() -> void:
	## LMB on Keeper: select Keeper, deselect any Wisp.
	if keeper_selected and selected_wisp_id < 0:
		return
	keeper_selected = true
	selected_wisp_id = -1
	selection_changed.emit()


func toggle_keeper_selected() -> void:
	if keeper_selected:
		set_keeper_selected(false)
	else:
		select_keeper()


func select_wisp(wisp_id: int) -> void:
	## LMB on Wisp: select that wisp (does NOT require Keeper). Deselects Keeper.
	if wisp_id < 0 or wisp_id >= wisp_count:
		return
	if selected_wisp_id == wisp_id and not keeper_selected:
		return
	keeper_selected = false
	selected_wisp_id = wisp_id
	selection_changed.emit()


func clear_wisp_selection() -> void:
	if selected_wisp_id < 0:
		return
	selected_wisp_id = -1
	selection_changed.emit()


func clear_selection() -> bool:
	var had: bool = keeper_selected or selected_wisp_id >= 0
	keeper_selected = false
	selected_wisp_id = -1
	if had:
		selection_changed.emit()
	return had


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


func _tool_speed_divisor() -> float:
	## 2× Keeper channel speed → half wait between yields. Yield/pulse unchanged.
	return maxf(1.0, param_float("TOOL_CHANNEL_SPEED_MULT", 2.0))


func get_keeper_harvest_pulse_sec(resource_id: StringName) -> float:
	## Hands always work. Matching tool (Keeper only) halves wait. Wisps ignore this.
	var base_s: float = get_channel_pulse_sec()
	if Backpack.owns_tool_for_resource(resource_id):
		return base_s / _tool_speed_divisor()
	return base_s


func get_water_essence_pulse_sec() -> float:
	## Stone Watering Can never speeds Essence — base CHANNEL_PULSE_SEC.
	return get_channel_pulse_sec()


func get_water_shard_pulse_sec() -> float:
	## v0.4.0: can doubles shard_roll, not pulse wait. Both grants share CHANNEL_PULSE_SEC.
	return get_channel_pulse_sec()


func get_water_shard_roll_mult() -> int:
	## Watering Can owned → shard_roll ×2. Essence grant unchanged.
	if Backpack.owns_watering_can():
		return maxi(1, int(round(param_float("WATER_CAN_SHARD_ROLL_MULT", 2.0))))
	return 1


func _on_backpack_changed(_item_id: StringName, _new_amount: int) -> void:
	needs_changed.emit()


func get_need_have(resource_id: StringName) -> int:
	if resource_id == &"fertilizer":
		return Backpack.get_count("fertilizer")
	return get_resource(resource_id)


func spend_need(resource_id: StringName, amount: int) -> void:
	if amount <= 0:
		return
	if resource_id == &"fertilizer":
		Backpack.try_spend("fertilizer", amount)
		return
	add_resource(resource_id, -amount)


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
	if fruit_committed:
		return 0
	if not resource_id in HARVEST_IDS:
		return 0
	var grant: int = get_harvest_grant(resource_id)
	add_resource(resource_id, grant)
	var key: String = String(resource_id)
	lifetime_harvested[key] = int(lifetime_harvested.get(key, 0)) + grant
	return grant


## Water channel pulse: manashards U{1,3}×can + shard_sight, essence income only (no growth).
## At Ancient: still pays shards+essence. Split flags are test-only; Keeper grants both.
func apply_water_pulse(grant_shards: bool = true, grant_essence: bool = true) -> Dictionary:
	if fruit_committed:
		return {"ok": false, "reason": "pending_ascend", "shards": 0, "essence": 0}
	if not grant_shards and not grant_essence:
		return {"ok": false, "reason": "empty", "shards": 0, "essence": 0}
	var shards: int = 0
	var ess: int = 0
	if grant_shards:
		var shard_min: int = param_int("WATER_SHARD_MIN", 1)
		var shard_max: int = param_int("WATER_SHARD_MAX", 3)
		## SYSTEMS v0.4.0: shard_roll = U{1,3} + shard_sight, then Can ×2.
		var shard_roll: int = randi_range(shard_min, shard_max) + int(get_effect_total("water_shard_bonus"))
		shards = shard_roll * get_water_shard_roll_mult()
		add_resource(&"manashards", shards)
		lifetime_shards_from_water += shards
	if grant_essence:
		ess = get_water_essence_amount()
		add_resource(&"essence", ess)
		lifetime_essence_from_water += ess
	lifetime_waters += 1
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
	## Manashard shop — only while awaiting Ascend after Fruit commit.
	if not fruit_committed:
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
	## Grow spends Fertilizer + Essence only (playtest 3/6/12/24 + 20/40/60/80).
	var next_id: StringName = get_next_stage_id()
	if next_id == &"":
		return {}
	var def: Dictionary = get_stage_def(next_id)
	return {
		"essence": int(def.get("cost_essence", 0)),
		"fertilizer": int(def.get("cost_fertilizer", 0)),
	}


## Grow costs are raw Fertilizer + Essence. green_thumb does not cut Grow (craft only).
func get_next_stage_needs() -> Dictionary:
	var raw: Dictionary = _raw_needs_for_next()
	if raw.is_empty():
		return {}
	var out: Dictionary = {}
	for rid: StringName in NEED_ORDER:
		var key: String = String(rid)
		var need: int = int(raw.get(key, 0))
		if need > 0:
			out[key] = need
	return out


func has_needs_for_next() -> bool:
	var needs: Dictionary = get_next_stage_needs()
	if needs.is_empty():
		return false
	for key: Variant in needs.keys():
		var rid: StringName = StringName(str(key))
		if get_need_have(rid) < int(needs[key]):
			return false
	return true


func _set_fruit_committed(value: bool) -> void:
	## Keep Design field and legacy alias in lockstep (no SAVE_VERSION bump).
	fruit_committed = value
	fruit_harvested_pending_ascend = value


func can_pay_stage() -> bool:
	if stage_id == &"ancient" or fruit_committed:
		return false
	return has_needs_for_next()


func get_remaining_needs() -> Dictionary:
	var needs: Dictionary = get_next_stage_needs()
	var rem: Dictionary = {}
	for key: Variant in needs.keys():
		var k: String = str(key)
		var need: int = int(needs[k])
		var have: int = get_need_have(StringName(k))
		rem[k] = maxi(0, need - have)
	return rem


func _item_display(resource_id: String) -> String:
	match resource_id:
		"essence":
			return ContentStrings.get_text("hud_essence")
		"fertilizer":
			return ContentStrings.get_text("fertilizer_name")
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
		var have: int = get_need_have(rid)
		var item: String = _item_display(key)
		var toks: Dictionary = {"item": item, "have": have, "need": need}
		var cost_key: String = "tree_grow_cost_line"
		if key == "fertilizer":
			cost_key = "tree_grow_cost_fertilizer_met" if have >= need else "tree_grow_cost_fertilizer"
		elif key == "essence":
			cost_key = "tree_grow_cost_essence_met" if have >= need else "tree_grow_cost_essence"
		elif have >= need:
			cost_key = "tree_need_line_met"
		else:
			cost_key = "tree_need_line"
		lines.append(ContentStrings.get_text(cost_key, toks))
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
		var have: int = get_need_have(rid)
		if have >= need:
			continue
		var toks: Dictionary = {"have": have, "need": need, "count": need - have}
		match rid:
			&"essence":
				parts.append(ContentStrings.get_text("tree_stage_blocked_essence", toks))
			&"fertilizer":
				parts.append(ContentStrings.get_text("tree_stage_blocked_fertilizer", toks))
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
	if stage_id == &"ancient" or fruit_committed:
		var ancient_line: String = ContentStrings.get_text("tree_at_ancient_idle")
		if fruit_committed:
			ancient_line = ContentStrings.get_text("ascension_paused_body")
		elif fruit_ready:
			ancient_line = ContentStrings.get_text("tree_ancient_care_hint")
		return {
			"is_ancient": true,
			"title": str(get_stage_def().get("display_name", "Ancient")),
			"needs_header": "",
			"needs_lines": PackedStringArray([ancient_line]),
			"needs_status": ancient_line,
			"can_pay": false,
			"can_grow": false,
			"ready_for_fruit": fruit_ready,
			"pending_ascend": fruit_committed,
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
		status = ContentStrings.get_text("tree_grow_ready")
	else:
		status = ContentStrings.get_text("tree_grow_cant_afford", {"costs": format_missing_needs()})
	return {
		"is_ancient": false,
		"title": ContentStrings.get_text("tree_next_stage_title", {"next_stage": next_display}),
		"needs_header": ContentStrings.get_text("tree_next_stage_needs_header"),
		"needs_lines": lines,
		"needs_status": status,
		"can_pay": has_needs_for_next(),
		"can_grow": has_needs_for_next(),
		"next_stage_display": next_display,
		"next_stage_id": String(next_id),
		"ready_for_fruit": false,
		"pending_ascend": false,
		"needs": needs,
	}


## One-click Grow: spend Fertilizer + Essence to advance one stage.
## Returns "ok" | "cant_afford" | "ancient" | "no_next".
func try_grow_stage() -> String:
	if stage_id == &"ancient" or fruit_committed:
		return "ancient"
	var next_id: StringName = get_next_stage_id()
	if next_id == &"":
		return "no_next"
	var needs: Dictionary = get_next_stage_needs()
	if needs.is_empty():
		return "no_next"
	if not has_needs_for_next():
		status_message.emit(ContentStrings.get_text("tree_grow_cant_afford", {"costs": format_missing_needs()}))
		return "cant_afford"
	for key: Variant in needs.keys():
		spend_need(StringName(str(key)), int(needs[key]))
	_set_stage(next_id)
	grant_wisp_from_stage()
	var next_display: String = str(get_stage_def(next_id).get("display_name", next_id))
	status_message.emit(ContentStrings.get_text("tree_grow_ok", {"next_stage": next_display}))
	needs_changed.emit()
	return "ok"


## Alias — CTA is Grow (tree_pay string).
func try_pay_stage() -> String:
	return try_grow_stage()


func can_grow_stage() -> bool:
	return can_pay_stage()


## Alias for Content tree_advance* keys.
func try_advance() -> String:
	return try_grow_stage()


func _set_stage(id: StringName) -> void:
	stage_id = id
	var def: Dictionary = get_stage_def(id)
	fruit_ready = bool(def.get("grants_fruit", false)) and not fruit_committed
	stage_changed.emit(stage_id)
	fruit_ready_changed.emit(fruit_ready)
	needs_changed.emit()


func harvest_fruit() -> int:
	## SYSTEMS v0.3.4: commit only — do NOT bank ESSENCE_PER_HARVEST (wiped on Ascend anyway).
	if stage_id != &"ancient" or fruit_committed:
		return 0
	lifetime_fruit_harvested += 1
	fruit_ready = false
	_set_fruit_committed(true)
	fruit_ready_changed.emit(false)
	return 1


func can_ascend() -> bool:
	## Ascend after Fruit commit; Manashard purchases optional.
	return fruit_committed


func ascend() -> void:
	if not fruit_committed:
		return
	ascensions += 1
	wood = 0
	stone = 0
	food = 0
	manashards = 0
	essence = 0
	_set_fruit_committed(false)
	fruit_ready = false
	wisp_count = get_upgrade_rank("bonus_wisp")
	wisp_assignments.clear()
	wisp_pulse_accum.clear()
	_ensure_wisp_slots()
	clear_selection()
	wisps_changed.emit()
	_set_stage(&"sapling")
	resources_changed.emit(&"wood", wood)
	resources_changed.emit(&"stone", stone)
	resources_changed.emit(&"food", food)
	resources_changed.emit(&"manashards", manashards)
	resources_changed.emit(&"essence", essence)
	Backpack.on_ascend()
	needs_changed.emit()
	status_message.emit(ContentStrings.get_text("ascend_toast"))
	status_message.emit(ContentStrings.get_text("ascend_essence_reset_toast"))
	if get_upgrade_rank("keep_tools") > 0:
		status_message.emit(ContentStrings.get_text("upgrade_keep_tools_toast"))
		status_message.emit(ContentStrings.get_text("keep_tools_regrant_toast"))
		var keep_wipe: String = ContentStrings.get_text("backpack_wiped_keep_tools_toast")
		if keep_wipe != "backpack_wiped_keep_tools_toast":
			status_message.emit(keep_wipe)
	else:
		var wipe: String = ContentStrings.get_text("backpack_wiped_toast")
		if wipe != "backpack_wiped_toast":
			status_message.emit(wipe)
		else:
			status_message.emit(ContentStrings.get_text("ascend_backpack_wipe_toast"))


func to_save_dict() -> Dictionary:
	return {
		"wood": wood,
		"stone": stone,
		"food": food,
		"manashards": manashards,
		"essence": essence,
		"stage_id": String(stage_id),
		"fruit_ready": fruit_ready,
		"fruit_committed": fruit_committed,
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
		"wisp_count": wisp_count,
		"wisp_assignments": wisp_assignments.duplicate(true),
		"backpack": Backpack.to_save_dict(),
		"owns_stone_axe": Backpack.owns_item("stone_axe"),
		"owns_stone_pickaxe": Backpack.owns_item("stone_pickaxe"),
		"owns_wooden_basket": Backpack.owns_item("wooden_basket"),
		"owns_stone_watering_can": Backpack.owns_item("stone_watering_can"),
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
	## Prefer Design field; migrate from legacy alias without SAVE_VERSION bump.
	_set_fruit_committed(bool(data.get("fruit_committed", data.get("fruit_harvested_pending_ascend", false))))
	if fruit_committed:
		fruit_ready = false
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
	wisp_count = int(data.get("wisp_count", 0))
	var assigns: Variant = data.get("wisp_assignments", {})
	if typeof(assigns) == TYPE_DICTIONARY:
		wisp_assignments = (assigns as Dictionary).duplicate(true)
	else:
		wisp_assignments = {}
	wisp_pulse_accum.clear()
	_ensure_wisp_slots()
	Backpack.apply_save_dict(data.get("backpack", {}))
	## SYSTEMS v0.4.0 prefers unique-tool flags; backpack stacks (max 1) also OK.
	if bool(data.get("owns_stone_axe", false)):
		Backpack.set_count("stone_axe", 1)
	if bool(data.get("owns_stone_pickaxe", false)):
		Backpack.set_count("stone_pickaxe", 1)
	if bool(data.get("owns_wooden_basket", false)):
		Backpack.set_count("wooden_basket", 1)
	if bool(data.get("owns_stone_watering_can", false)):
		Backpack.set_count("stone_watering_can", 1)
	keeper_selected = false
	selected_wisp_id = -1
	wisps_changed.emit()
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
	_set_fruit_committed(false)
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
	wisp_count = 0
	wisp_assignments.clear()
	wisp_pulse_accum.clear()
	keeper_selected = false
	selected_wisp_id = -1
	run_time_sec = 0.0
	Backpack.reset_for_new_game()
	wisps_changed.emit()
	selection_changed.emit()
