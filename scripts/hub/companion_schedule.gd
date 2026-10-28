class_name CompanionSchedule
extends RefCounted
## Day-night places for companions who are not on a chore.
## Walks with the body's existing move and walk clips. Stands stay off the Bench,
## the Forge door, work spots, and the path into those spots.

const DATA_PATH: String = "res://data/companion_schedule.json"

static var _loaded: bool = false
static var _data: Dictionary = {}
static var _spots: Dictionary = {}
static var _force_drive: bool = false


static func _ensure() -> void:
	if _loaded:
		return
	_loaded = true
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	if typeof(parsed) == TYPE_DICTIONARY:
		_data = parsed


static func set_force_drive(on: bool) -> void:
	_force_drive = on


static func _row(companion_id: String) -> Dictionary:
	_ensure()
	var all: Variant = _data.get("companions", {})
	if typeof(all) != TYPE_DICTIONARY:
		return {}
	var found: Variant = (all as Dictionary).get(companion_id, {})
	return found if typeof(found) == TYPE_DICTIONARY else {}


static func place_for(companion_id: String, phase01: float) -> String:
	## Chore wins over the clock. The place id is "chore" or a routine place.
	if not CompanionChores.follows_routine(companion_id):
		return "chore"
	var row: Dictionary = _row(companion_id)
	var routine: Variant = row.get("routine", [])
	if typeof(routine) != TYPE_ARRAY or (routine as Array).is_empty():
		return "tree"
	var phase: float = HubTimePhase.wrap_phase01(phase01)
	for entry_v: Variant in routine as Array:
		if typeof(entry_v) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_v
		var from_p: float = float(entry.get("from", 0.0))
		var to_p: float = float(entry.get("to", 1.0))
		if phase >= from_p and phase < to_p:
			return str(entry.get("place", "tree"))
	return "tree"


static func place_label_key(place: String) -> String:
	match place:
		"bench":
			return "companion_schedule_bench"
		"runestone":
			return "companion_schedule_runestone"
		"tree":
			return "companion_schedule_tree"
		"chore":
			return "companion_schedule_chore"
		_:
			return "companion_schedule_tree"


static func place_label(place: String) -> String:
	var key: String = place_label_key(place)
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return key
	var strings: Node = tree.root.get_node_or_null("ContentStrings")
	if strings == null:
		return key
	return str(strings.call("get_text", key))


static func lane_of(companion_id: String) -> int:
	return int(_row(companion_id).get("lane", 0))


static func tick(delta: float) -> void:
	if delta < 0.0:
		return
	if not _force_drive and DisplayServer.get_name() == "headless":
		return
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var gs: Node = tree.root.get_node_or_null("GameState")
	if gs == null or bool(gs.call("is_world_frozen")):
		return
	var phase: float = HubTimePhase.sample_phase01()
	for node: Node in tree.get_nodes_in_group("companion"):
		if not node.has_method("hold_schedule_spot"):
			continue
		var body: Node2D = node as Node2D
		if body == null or not body.visible:
			continue
		var companion_id: String = str(body.get("companion_id"))
		if companion_id == "" or CompanionChores.is_away(companion_id):
			continue
		if not CompanionChores.is_around(companion_id) and not CompanionChores.follows_routine(companion_id):
			continue
		if bool(body.call("player_order_active")):
			continue
		body.y_sort_enabled = true
		if not CompanionChores.follows_routine(companion_id):
			_hold_chore(body, companion_id)
		else:
			_hold_routine(body, companion_id, phase)


static func _hold_chore(body: Node2D, companion_id: String) -> void:
	var node_id: String = CompanionChores.assignment_of(companion_id)
	var target: Node2D = CompanionChores.find_work_node(node_id)
	if target == null:
		return
	var type_id: String = CompanionChores.work_type_for(node_id)
	if type_id == "":
		return
	body.call("hold_chore_node", target, type_id)


static func _hold_routine(body: Node2D, companion_id: String, phase: float) -> void:
	var place: String = place_for(companion_id, phase)
	var anchor: Vector2 = _anchor(place, companion_id)
	if anchor == Vector2.INF:
		return
	var stand: Vector2 = cleared_stand(anchor, place, companion_id)
	var face: String = "south"
	if place == "bench" or place == "tree":
		face = "north"
	body.call("hold_schedule_spot", stand, face)


static func _anchor(place: String, companion_id: String) -> Vector2:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return Vector2.INF
	match place:
		"bench":
			var bench: Node2D = tree.get_first_node_in_group("keepers_bench") as Node2D
			if bench == null:
				return Vector2.INF
			return bench.global_position
		"runestone":
			var stone: Node2D = tree.get_first_node_in_group("runestone") as Node2D
			if stone == null:
				return Vector2.INF
			return stone.global_position
		"tree":
			var manatree: Node2D = tree.get_first_node_in_group("manatree") as Node2D
			if manatree == null:
				return Vector2.INF
			return manatree.global_position
		"chore":
			var node_id: String = CompanionChores.assignment_of(companion_id)
			if node_id == "":
				node_id = str(CompanionChores.default_assignments().get(companion_id, "manatree"))
			var target: Node2D = CompanionChores.find_work_node(node_id)
			if target == null:
				return Vector2.INF
			return target.global_position
		_:
			return Vector2.INF


static func _offset(place: String, companion_id: String) -> Vector2:
	_ensure()
	var all: Variant = _data.get("stand_offsets", {})
	var row: Dictionary = {}
	if typeof(all) == TYPE_DICTIONARY:
		var found: Variant = (all as Dictionary).get(place, {})
		if typeof(found) == TYPE_DICTIONARY:
			row = found
	var lane: float = float(lane_of(companion_id)) * float(_data.get("lane_px", 36.0))
	return Vector2(float(row.get("x", 96.0)) + lane, float(row.get("y", 72.0)))


static func cleared_stand(anchor: Vector2, place: String, companion_id: String) -> Vector2:
	var stand: Vector2 = anchor + _offset(place, companion_id)
	var step: float = float(_data.get("nudge_px", 8.0)) if _loaded else 8.0
	var steps: int = int(_data.get("nudge_steps", 12)) if _loaded else 12
	var actor: String = companion_id if companion_id != "" else "elaia"
	for _i: int in range(maxi(1, steps)):
		if not _stand_hits_forbidden(stand, actor):
			return stand
		stand.y += step
	return stand


static func body_rect(stand: Vector2, actor_id: String) -> Rect2:
	var box: Vector2 = FeetBox.actor_box(actor_id if actor_id != "" else "elaia")
	return Rect2(stand + Vector2(-box.x * 0.5, -box.y), box)


static func forbidden_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return out
	var bench: Node2D = tree.get_first_node_in_group("keepers_bench") as Node2D
	if bench != null and bench.has_method("work_footprint"):
		out.append(bench.call("work_footprint"))
	var manatree: Node2D = tree.get_first_node_in_group("manatree") as Node2D
	if manatree != null:
		## Forge door at the sill. The arch is the only way into the Forge.
		out.append(Rect2(manatree.global_position + Vector2(-40.0, -24.0), Vector2(80.0, 56.0)))
	for node: Node in tree.get_nodes_in_group("gatherable"):
		if node is Node2D and node.has_method("work_footprint"):
			var fp: Rect2 = node.call("work_footprint")
			var type_id: String = str(node.get("resource_id"))
			if type_id == "":
				type_id = "wood"
			var spot: Vector2 = _solved_stand(fp, type_id, (node as Node2D).global_position)
			out.append(Rect2(spot + Vector2(-20.0, -16.0), Vector2(40.0, 32.0)))
	if manatree != null and manatree.has_method("work_footprint"):
		var tree_fp: Rect2 = manatree.call("work_footprint")
		var water_spot: Vector2 = _solved_stand(tree_fp, "manatree", manatree.global_position)
		out.append(Rect2(water_spot + Vector2(-22.0, -16.0), Vector2(44.0, 36.0)))
	if bench != null and bench.has_method("work_footprint"):
		var bench_fp: Rect2 = bench.call("work_footprint")
		var seat_spot: Vector2 = _solved_stand(bench_fp, "bench", bench.global_position)
		out.append(Rect2(seat_spot + Vector2(-24.0, -12.0), Vector2(48.0, 28.0)))
	return out


static func _solved_stand(footprint: Rect2, type_id: String, fallback: Vector2) -> Vector2:
	## Same nearest-to-origin pick as Keeper.solve_work_spot with an empty approach.
	## Read from the spot table so this file does not depend on the Keeper script.
	var types: Variant = _spot_table().get("types", {})
	if typeof(types) != TYPE_DICTIONARY:
		return fallback
	var spec: Dictionary = (types as Dictionary).get(type_id, {})
	if spec.is_empty():
		return fallback
	var forced: String = str(spec.get("force_side", ""))
	var sides: Array = [forced] if forced != "" else (spec.get("sides", ["west", "east"]) as Array)
	var best: Vector2 = fallback
	var best_d: float = INF
	var found: bool = false
	for side_v: Variant in sides:
		var pos: Vector2 = _spot_for_side(footprint, str(side_v), spec)
		var dist: float = pos.distance_squared_to(Vector2.ZERO)
		if not found or dist < best_d:
			best = pos
			best_d = dist
			found = true
	return best if found else fallback


static func _spot_table() -> Dictionary:
	if not _spots.is_empty():
		return _spots
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/keeper_work_spots.json"))
	if typeof(parsed) == TYPE_DICTIONARY:
		_spots = parsed
	return _spots


static func _spot_for_side(footprint: Rect2, side: String, spec: Dictionary) -> Vector2:
	var side_px: float = float(spec.get("side_px", 0.0))
	var y_px: float = float(spec.get("y_px", 0.0))
	var measure: String = str(spec.get("measure", "edge"))
	var bottom: float = footprint.position.y + footprint.size.y
	var center: Vector2 = footprint.get_center()
	match side:
		"west":
			var x: float = center.x - side_px if measure == "center" else footprint.position.x - side_px
			return Vector2(x, bottom + y_px)
		"east":
			var x_east: float = center.x + side_px if measure == "center" else footprint.position.x + footprint.size.x + side_px
			return Vector2(x_east, bottom + y_px)
		"north":
			return Vector2(center.x, footprint.position.y - side_px + y_px)
		_:
			return Vector2(center.x, bottom + side_px + y_px)


static func _stand_hits_forbidden(stand: Vector2, actor_id: String) -> bool:
	var body: Rect2 = body_rect(stand, actor_id)
	for rect: Rect2 in forbidden_rects():
		if body.intersects(rect):
			return true
	return false


static func stand_is_clear(stand: Vector2, actor_id: String) -> bool:
	return not _stand_hits_forbidden(stand, actor_id)
