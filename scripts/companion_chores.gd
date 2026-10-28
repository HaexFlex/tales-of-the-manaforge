class_name CompanionChores
extends RefCounted
## Idle companions, not out with a reach party, work one hub node at rate_mult
## of the Keeper's rate. One companion per node. Wisps add on top.
## Offline uses the locked gather curve (the same seconds Keeper gathering uses).

const DATA_PATH: String = "res://data/companion_chores.json"

static var _loaded: bool = false
static var _data: Dictionary = {}
static var assignments: Dictionary = {}
static var _forced: Dictionary = {}
static var _force_auto: bool = false


static func _ensure() -> void:
	if _loaded:
		return
	_loaded = true
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	if typeof(parsed) == TYPE_DICTIONARY:
		_data = parsed
	reset_for_new_game()


static func rate_mult() -> float:
	_ensure()
	return float(_data.get("rate_mult", 0.5))


static func max_per_node() -> int:
	_ensure()
	return maxi(1, int(_data.get("max_per_node", 1)))


static func default_assignments() -> Dictionary:
	_ensure()
	var raw: Variant = _data.get("assignments", {})
	if typeof(raw) != TYPE_DICTIONARY:
		return {}
	var out: Dictionary = {}
	for key_v: Variant in (raw as Dictionary).keys():
		out[str(key_v)] = str((raw as Dictionary)[key_v])
	return out


static func reset_for_new_game() -> void:
	_ensure()
	assignments = _enforce(default_assignments())
	_forced.clear()


static func set_force_auto(on: bool) -> void:
	_force_auto = on


static func set_forced_present(companion_id: String, present: bool) -> void:
	_ensure()
	_forced[companion_id] = present


static func clear_forced() -> void:
	_forced.clear()


static func set_assignment(companion_id: String, node_id: String) -> void:
	_ensure()
	var next: Dictionary = assignments.duplicate()
	next[companion_id] = node_id
	assignments = _enforce(next)


static func assignment_of(companion_id: String) -> String:
	_ensure()
	return str(assignments.get(companion_id, ""))


static func save_fields() -> Dictionary:
	_ensure()
	return {"companion_chores": assignments.duplicate()}


static func apply_save_dict(data: Dictionary) -> void:
	_ensure()
	var raw: Variant = data.get("companion_chores", null)
	if typeof(raw) != TYPE_DICTIONARY:
		assignments = _enforce(default_assignments())
		return
	var merged: Dictionary = default_assignments()
	for key_v: Variant in (raw as Dictionary).keys():
		merged[str(key_v)] = str((raw as Dictionary)[key_v])
	assignments = _enforce(merged)


static func migrate_fields(out: Dictionary) -> void:
	## Missing field loads the defaults. A saved map is kept and filled in.
	var defaults: Dictionary = default_assignments()
	var raw: Variant = out.get("companion_chores", {})
	var have: Dictionary = raw if typeof(raw) == TYPE_DICTIONARY else {}
	var merged: Dictionary = defaults.duplicate()
	for key_v: Variant in have.keys():
		merged[str(key_v)] = str(have[key_v])
	out["companion_chores"] = _enforce(merged)


static func _ordered_ids(source: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	for preferred: String in default_assignments().keys():
		if source.has(preferred):
			ids.append(preferred)
	var rest: Array[String] = []
	for key_v: Variant in source.keys():
		var key: String = str(key_v)
		if not ids.has(key):
			rest.append(key)
	rest.sort()
	ids.append_array(rest)
	return ids


static func _enforce(source: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	var used: Dictionary = {}
	var cap: int = max_per_node()
	for companion_id: String in _ordered_ids(source):
		var node_id: String = str(source.get(companion_id, ""))
		if node_id == "":
			out[companion_id] = ""
			continue
		var count: int = int(used.get(node_id, 0))
		if count >= cap:
			out[companion_id] = ""
			continue
		used[node_id] = count + 1
		out[companion_id] = node_id
	return out


static func is_water_node(node_id: String) -> bool:
	return node_id == "manatree"


static func resource_for(node_id: String) -> StringName:
	match node_id:
		"harvest_berry", "berries", "food":
			return &"food"
		"harvest_stone", "stone":
			return &"stone"
		"harvest_tree", "wood":
			return &"wood"
		_:
			return &""


static func node_label_key(node_id: String) -> String:
	var rid: StringName = resource_for(node_id)
	if rid == &"food":
		return "companion_chore_berries"
	if rid == &"stone":
		return "companion_chore_stone"
	return "companion_chore_manatree"


static func node_label(node_id: String) -> String:
	var key: String = node_label_key(node_id)
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return key
	var strings: Node = tree.root.get_node_or_null("ContentStrings")
	if strings == null:
		return key
	return str(strings.call("get_text", key))


static func work_type_for(node_id: String) -> String:
	if is_water_node(node_id):
		return "manatree"
	return String(resource_for(node_id))


static func is_around(companion_id: String) -> bool:
	if _forced.has(companion_id):
		return bool(_forced[companion_id])
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return false
	var gs: Node = tree.root.get_node_or_null("GameState")
	if gs == null:
		return false
	if companion_id == "elaia":
		return bool(gs.call("elaia_in_party"))
	if companion_id == "bramble":
		return bool(gs.call("bramble_joined"))
	return false


static func is_away(companion_id: String) -> bool:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return false
	var gs: Node = tree.root.get_node_or_null("GameState")
	if gs == null:
		return false
	return bool(gs.call("member_away", companion_id))


static func player_task_working(companion_id: String) -> bool:
	if companion_id != "elaia" and companion_id != "keeper":
		return false
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return false
	var jobs: Node = tree.root.get_node_or_null("ForgeJobs")
	if jobs == null:
		return false
	var task: Dictionary = jobs.call("elaia_task") if companion_id == "elaia" else jobs.call("keeper_task")
	return bool(task.get("working", false))


static func has_chore(companion_id: String) -> bool:
	_ensure()
	return str(assignments.get(companion_id, "")) != ""


static func active_ids() -> Array[String]:
	_ensure()
	var out: Array[String] = []
	for companion_id: String in _ordered_ids(assignments):
		if str(assignments.get(companion_id, "")) == "":
			continue
		if not is_around(companion_id) or is_away(companion_id):
			continue
		if player_task_working(companion_id):
			continue
		out.append(companion_id)
	return out


static func follows_routine(companion_id: String) -> bool:
	## A companion on a chore stays at that node. Only an unassigned companion walks the clock.
	return not has_chore(companion_id)


static func tick(delta: float) -> void:
	if not _force_auto and DisplayServer.get_name() == "headless":
		return
	if delta <= 0.0:
		return
	grant_online_seconds(delta)


static func grant_online_seconds(seconds: float) -> void:
	if seconds <= 0.0:
		return
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var gs: Node = tree.root.get_node_or_null("GameState")
	if gs == null or bool(gs.get("fruit_committed")) or bool(gs.call("is_world_frozen")):
		return
	var keeper_rate: float = float(gs.call("actor_work_rate", "keeper", ""))
	var water_mult: float = float(gs.call("actor_water_mult", "keeper")) * rate_mult()
	for companion_id: String in active_ids():
		var node_id: String = assignment_of(companion_id)
		if is_water_node(node_id):
			_grant_water(gs, seconds, water_mult)
		else:
			var rid: StringName = resource_for(node_id)
			if rid != &"":
				gs.call("accumulate_keeper_harvest", rid, seconds, keeper_rate * rate_mult())


static func _grant_water(gs: Node, seconds: float, mult: float) -> void:
	var pulse: float = maxf(float(gs.call("get_water_essence_pulse_sec")), 0.05)
	var left: float = seconds
	while left >= pulse - 0.00001:
		gs.call("apply_water_pulse", true, true, mult, "chore")
		left -= pulse
	if left > 0.0001:
		gs.call("apply_water_pulse", true, true, mult * (left / pulse), "chore")


static func apply_offline(eff: float, result: Dictionary) -> void:
	## eff is already the locked curve. Weather bonuses are not part of this path.
	if eff <= 0.0:
		return
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var gs: Node = tree.root.get_node_or_null("GameState")
	var jobs: Node = tree.root.get_node_or_null("ForgeJobs")
	if gs == null or jobs == null:
		return
	if bool(gs.get("fruit_committed")) or str(gs.get("stage_id")) == "ancient":
		return
	var keeper_rate: float = float(gs.call("actor_work_rate", "keeper", ""))
	for companion_id: String in active_ids():
		var node_id: String = assignment_of(companion_id)
		if is_water_node(node_id):
			var before_shards: int = int(gs.call("get_resource", &"manashards"))
			var before_ess: int = int(gs.call("get_resource", &"essence"))
			var water: Dictionary = jobs.call("_offline_water", eff, rate_mult(), "chore")
			var shards: int = int(gs.call("get_resource", &"manashards")) - before_shards
			var ess: int = int(gs.call("get_resource", &"essence")) - before_ess
			if shards <= 0:
				shards = int(water.get("shards", 0))
			if ess <= 0:
				ess = int(water.get("essence", 0))
			jobs.call("_note_offline_gain", result, "chores", "manashards", shards)
			jobs.call("_note_offline_gain", result, "chores", "essence", ess)
		else:
			var rid: StringName = resource_for(node_id)
			if rid == &"":
				continue
			var gained: int = int(gs.call("apply_offline_keeper_harvest", eff, rid, keeper_rate * rate_mult()))
			jobs.call("_note_offline_gain", result, "chores", String(rid), gained)


static func find_work_node(node_id: String) -> Node2D:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	if is_water_node(node_id):
		var tree_node: Node = tree.get_first_node_in_group("manatree")
		return tree_node as Node2D
	var want: String = String(resource_for(node_id))
	for node: Node in tree.get_nodes_in_group("gatherable"):
		if node is Node2D and str(node.get("resource_id")) == want:
			return node as Node2D
	return null
