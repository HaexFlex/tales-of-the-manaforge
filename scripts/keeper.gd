extends CharacterBody2D
class_name Keeper
## RTS LMB-select Keeper + harvest / water channels (SYSTEMS v0.3.2).
## Walk clips pace at actual_speed / 80. Work loops play only after he arrives at a tuned spot.

signal arrived
signal interaction_finished(target: Node)
signal channel_changed(kind: StringName, active: bool)

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var label: Label = $Label
@onready var select_ring: Sprite2D = $SelectRing
@onready var click_area: Area2D = $ClickArea

var _target: Vector2 = Vector2.ZERO
var _moving: bool = false
var _pending_interact: Node = null

enum ChannelKind { NONE, HARVEST, WATER }
var _channel_kind: int = ChannelKind.NONE
var _channel_target: Node = null
var _channel_accum: float = 0.0
var _hovered: bool = false
var _outline_mat: ShaderMaterial

const OUTLINE_SHADER: Shader = preload("res://assets/art/ui/select_outline.gdshader")
const ARRIVE_DIST: float = 12.0
const INTERACT_DIST: float = 64.0
const BODY_SIZE: Vector2 = Vector2(128, 128)
const IDLE_HOLD_MS: float = 140.0
const WALK_HOLD_MS: float = 90.0
const WALK_REF_SPEED: float = 80.0
const WORK_ARRIVE_SLACK: float = 10.0
const WORK_SPOTS_PATH: String = "res://data/keeper_work_spots.json"
const OFFSET_BODY: Vector2 = Vector2(-64, -128)
const OFFSET_HARVEST: Vector2 = Vector2(-96, -136)
const OFFSET_WATER: Vector2 = Vector2(-104, -136)
const REACH_SLACK: float = 14.0

const WALK_MS: Array[float] = [120.0, 125.0, 130.0, 125.0, 120.0, 125.0, 130.0, 125.0]
const RUN_MS: Array[float] = [100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0]
const AXE_MS: Array[float] = [140.0, 70.0, 60.0, 180.0, 90.0, 90.0, 90.0, 90.0, 90.0]
const PICK_MS: Array[float] = [100.0, 90.0, 90.0, 150.0, 70.0, 60.0, 60.0, 180.0, 100.0]
const BERRY_MS: Array[float] = [160.0, 90.0, 90.0, 100.0, 160.0, 100.0, 90.0, 110.0]
const WATER_MS: Array[float] = [170.0, 100.0, 90.0, 90.0, 110.0, 250.0, 250.0, 100.0, 90.0, 100.0]
const STATION_MS: Array[float] = [110.0, 110.0, 80.0, 80.0, 80.0, 110.0, 80.0, 110.0, 90.0, 90.0]

var _facing: String = "south"
var _has_work_spot: bool = false
var _work_spot: Vector2 = Vector2.ZERO
var _work_side: String = ""
var _work_facing: String = "south"
var _work_tool: String = ""
var _work_type: String = ""
var _work_station_id: String = ""
var _work_target: Node = null
var _work_loop: bool = false
var _water_pending: bool = false
var _suppress_work_clear: bool = false
var _fallback_logged: Dictionary = {}

static var _spots_cache: Dictionary = {}


class WorkSpotGate:
	var block_west_of: float = -1.0e12
	var block_all: bool = false

	func gate(pos: Vector2) -> bool:
		if block_all:
			return true
		return pos.x < block_west_of


func _ready() -> void:
	_target = global_position
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = false
	sprite.offset = OFFSET_BODY
	sprite.flip_h = false
	sprite.sprite_frames = _build_frames()
	sprite.play(&"idle_south")
	label.text = ContentStrings.get_text("keeper_select")
	label.position = Vector2(-40, -148)
	add_to_group("keeper")
	if select_ring:
		select_ring.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		select_ring.centered = true
		select_ring.position = Vector2(0, 0)
		select_ring.texture = load("res://assets/art/keeper/keeper_select_ring.png") as Texture2D
		select_ring.visible = false
		select_ring.z_index = -1
	if label:
		label.visible = false
	if click_area:
		click_area.input_event.connect(_on_click_area_input)
		click_area.mouse_entered.connect(_on_hover.bind(true))
		click_area.mouse_exited.connect(_on_hover.bind(false))
		click_area.collision_layer = 4
		click_area.collision_mask = 0
		click_area.monitoring = false
		click_area.monitorable = true
		click_area.add_to_group("interactable")
	GameState.selection_changed.connect(_on_selection_changed)
	_on_selection_changed()


func _build_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	_add_anim(frames, &"idle_front", [
		"res://assets/art/keeper/keeper_idle_south.png",
	], IDLE_HOLD_MS)
	_add_anim(frames, &"idle_south", [
		"res://assets/art/keeper/keeper_idle_south.png",
	], IDLE_HOLD_MS)
	_add_anim(frames, &"idle_back", [
		"res://assets/art/keeper/keeper_idle_back_0000.png",
	], IDLE_HOLD_MS)
	# walk_front stays as the south clip so older callers still resolve.
	_add_timed(frames, &"walk_front", "walk/south", WALK_MS)
	_add_timed(frames, &"walk_south", "walk/south", WALK_MS)
	_add_timed(frames, &"walk_north", "walk/north", WALK_MS)
	_add_timed(frames, &"walk_east", "walk/east", WALK_MS)
	_add_timed(frames, &"walk_west", "walk/west", WALK_MS)
	# No sprint exists. Run clips stay in the library unused.
	_add_timed(frames, &"run_south", "run/south", RUN_MS)
	_add_timed(frames, &"run_north", "run/north", RUN_MS)
	_add_timed(frames, &"run_east", "run/east", RUN_MS)
	_add_timed(frames, &"run_west", "run/west", RUN_MS)
	_add_timed(frames, &"harvest_axe_east", "harvest/axe/east", AXE_MS)
	_add_timed(frames, &"harvest_axe_west", "harvest/axe/west", AXE_MS)
	_add_timed(frames, &"harvest_pickaxe_east", "harvest/pickaxe/east", PICK_MS)
	_add_timed(frames, &"harvest_pickaxe_west", "harvest/pickaxe/west", PICK_MS)
	_add_timed(frames, &"harvest_berries_east", "harvest/berries/east", BERRY_MS)
	_add_timed(frames, &"harvest_berries_west", "harvest/berries/west", BERRY_MS)
	_add_timed(frames, &"harvest_water_east", "water/east", WATER_MS)
	_add_timed(frames, &"harvest_water_west", "water/west", WATER_MS)
	_add_timed(frames, &"station_work_north", "station/north", STATION_MS)
	_add_anim(frames, &"walk_back", [
		"res://assets/art/keeper/keeper_walk_back_0000.png",
		"res://assets/art/keeper/keeper_walk_back_0001.png",
		"res://assets/art/keeper/keeper_walk_back_0002.png",
		"res://assets/art/keeper/keeper_walk_back_0003.png",
		"res://assets/art/keeper/keeper_walk_back_0004.png",
		"res://assets/art/keeper/keeper_walk_back_0005.png",
	], WALK_HOLD_MS)
	return frames


func _add_anim(frames: SpriteFrames, anim: StringName, paths: Array, hold_ms: float) -> void:
	frames.add_animation(anim)
	frames.set_animation_loop(anim, true)
	frames.set_animation_speed(anim, 1000.0 / hold_ms)
	for path: String in paths:
		var tex: Texture2D = load(path) as Texture2D
		frames.add_frame(anim, tex)


func _add_timed(frames: SpriteFrames, anim: StringName, folder: String, durations: Array[float]) -> void:
	frames.add_animation(anim)
	frames.set_animation_loop(anim, true)
	frames.set_animation_speed(anim, 1000.0)
	for i: int in range(durations.size()):
		var path := "res://assets/art/keeper/anim/%s/frame_%04d.png" % [folder, i]
		var tex: Texture2D = load(path) as Texture2D
		frames.add_frame(anim, tex, durations[i])


func _physics_process(delta: float) -> void:
	if GameState.is_world_frozen():
		if _moving or _channel_kind != ChannelKind.NONE:
			halt()
		velocity = Vector2.ZERO
		move_and_slide()
		_update_anim(Vector2.ZERO)
		return
	if _moving:
		var speed: float = GameState.get_move_speed()
		var to_target: Vector2 = _target - global_position
		if to_target.length() <= ARRIVE_DIST:
			_moving = false
			velocity = Vector2.ZERO
			move_and_slide()
			_update_anim(Vector2.ZERO)
			if _water_pending:
				_water_pending = false
				_pending_interact = null
				var tree := _work_target as Manatree
				arrived.emit()
				if tree != null:
					_begin_water_channel(tree)
			else:
				arrived.emit()
				_try_interact()
		else:
			var intended: Vector2 = to_target.normalized() * speed
			velocity = intended
			move_and_slide()
			_update_anim(intended)
			_check_channel_range()
		return

	velocity = Vector2.ZERO
	move_and_slide()
	_update_anim(Vector2.ZERO)
	_tick_channel(delta)


func _update_anim(intended: Vector2) -> void:
	if sprite == null:
		return
	sprite.flip_h = false
	if _moving and intended.length_squared() > 0.01:
		_facing = facing_for_velocity(intended, _facing)
		var scale: float = walk_speed_scale_for(velocity.length())
		_play_loop(StringName("walk_%s" % _facing), scale, OFFSET_BODY)
		return
	if _should_work_loop():
		var anim := StringName(work_anim_for(_work_tool, _work_facing))
		_play_loop(anim, 1.0, _offset_for_anim(String(anim)))
		return
	_play_loop(&"idle_south", 1.0, OFFSET_BODY)


func _play_loop(anim: StringName, speed_scale: float, offset: Vector2) -> void:
	if sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(anim):
		anim = &"idle_south"
		offset = OFFSET_BODY
	if sprite.offset != offset:
		sprite.offset = offset
	if not is_equal_approx(sprite.speed_scale, speed_scale):
		sprite.speed_scale = speed_scale
	if sprite.animation != anim or not sprite.is_playing():
		sprite.play(anim)


func _offset_for_anim(anim: String) -> Vector2:
	if anim.begins_with("harvest_water"):
		return OFFSET_WATER
	if anim.begins_with("harvest_"):
		return OFFSET_HARVEST
	return OFFSET_BODY


func _should_work_loop() -> bool:
	if _moving or not _has_work_spot:
		return false
	if global_position.distance_to(_work_spot) > ARRIVE_DIST + WORK_ARRIVE_SLACK:
		return false
	if _work_loop:
		return true
	if _channel_kind != ChannelKind.NONE and _channel_target == _work_target:
		return _work_tool != ""
	return _station_task_matches()


func _station_task_matches() -> bool:
	if _work_tool != "station" or _work_station_id == "":
		return false
	if not has_node("/root/ForgeJobs"):
		return false
	var task: Dictionary = ForgeJobs.keeper_task()
	return str(task.get("kind", "")) == "forge" and bool(task.get("working", false)) and str(task.get("target", "")) == _work_station_id


static func facing_for_velocity(vel: Vector2, current: String = "south") -> String:
	if vel.length_squared() < 0.01:
		return current
	if absf(vel.x) >= absf(vel.y):
		return "east" if vel.x > 0.0 else "west"
	return "south" if vel.y > 0.0 else "north"


static func walk_anim_for_velocity(vel: Vector2, current: String = "south") -> String:
	return "walk_%s" % facing_for_velocity(vel, current)


static func walk_speed_scale_for(speed: float) -> float:
	return speed / WALK_REF_SPEED


static func work_anim_for(tool: String, facing: String) -> String:
	if tool == "station":
		return "station_work_north"
	if tool == "water":
		return "harvest_water_%s" % facing
	if tool == "axe" or tool == "pickaxe" or tool == "berries":
		return "harvest_%s_%s" % [tool, facing]
	return "idle_south"


static func tool_for_type(type_id: String) -> String:
	return str(work_spot_spec(type_id).get("tool", ""))


static func work_spot_table() -> Dictionary:
	if not _spots_cache.is_empty():
		return _spots_cache
	var f := FileAccess.open(WORK_SPOTS_PATH, FileAccess.READ)
	if f == null:
		push_warning("Keeper: missing %s" % WORK_SPOTS_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Keeper: %s is not an object" % WORK_SPOTS_PATH)
		return {}
	_spots_cache = parsed
	return _spots_cache


static func work_spot_spec(type_id: String, station_id: String = "") -> Dictionary:
	var types: Dictionary = work_spot_table().get("types", {}) as Dictionary
	var spec: Dictionary = (types.get(type_id, {}) as Dictionary).duplicate(true)
	if station_id != "" and spec.get("overrides") is Dictionary:
		var overrides: Dictionary = spec.get("overrides") as Dictionary
		if overrides.get(station_id) is Dictionary:
			var extra: Dictionary = overrides.get(station_id) as Dictionary
			for key: Variant in extra.keys():
				spec[key] = extra[key]
	return spec


static func contact_point(feet: Vector2, facing: String, contact_px: float) -> Vector2:
	match facing:
		"east":
			return feet + Vector2(contact_px, 0.0)
		"west":
			return feet + Vector2(-contact_px, 0.0)
		"north":
			return feet + Vector2(0.0, -contact_px)
		"south":
			return feet + Vector2(0.0, contact_px)
		_:
			return feet


static func distance_to_rect(point: Vector2, rect: Rect2) -> float:
	var closest := Vector2(
		clampf(point.x, rect.position.x, rect.position.x + rect.size.x),
		clampf(point.y, rect.position.y, rect.position.y + rect.size.y)
	)
	return point.distance_to(closest)


static func solve_work_spot(footprint: Rect2, approach: Vector2, type_id: String, blocked: Callable, station_id: String = "") -> Dictionary:
	var spec: Dictionary = work_spot_spec(type_id, station_id)
	var sides: Array = spec.get("sides", ["west", "east"]) as Array
	var cands: Array[Dictionary] = []
	for side_v: Variant in sides:
		cands.append(_spot_for_side(footprint, str(side_v), spec))
	if cands.is_empty():
		cands.append(_spot_for_side(footprint, "south", spec))
	var ordered: Array[Dictionary] = _order_candidates(cands, approach)
	var picked: Dictionary = {}
	var used_fallback := false
	for cand: Dictionary in ordered:
		var clear: Dictionary = _clear_variant(cand, blocked)
		if not clear.is_empty():
			picked = clear
			break
	if picked.is_empty():
		used_fallback = true
		picked = ordered[0].duplicate()
	var contact_px: float = float(spec.get("contact_px", 0.0))
	var facing := str(picked.get("facing", "south"))
	var feet: Vector2 = picked.get("position", Vector2.ZERO)
	picked["position"] = feet
	picked["facing"] = facing
	picked["tool"] = str(spec.get("tool", ""))
	picked["contact_px"] = contact_px
	picked["contact"] = contact_point(feet, facing, contact_px)
	picked["fallback"] = used_fallback
	picked["type"] = type_id
	picked["station_id"] = station_id
	return picked


static func _spot_for_side(footprint: Rect2, side: String, spec: Dictionary) -> Dictionary:
	var side_px: float = float(spec.get("side_px", 0.0))
	var y_px: float = float(spec.get("y_px", 0.0))
	var measure := str(spec.get("measure", "edge"))
	var bottom: float = footprint.position.y + footprint.size.y
	var center: Vector2 = footprint.get_center()
	var pos := Vector2.ZERO
	var facing := "south"
	match side:
		"west":
			facing = "east"
			var x: float = center.x - side_px if measure == "center" else footprint.position.x - side_px
			pos = Vector2(x, bottom + y_px)
		"east":
			facing = "west"
			var x_east: float = center.x + side_px if measure == "center" else footprint.position.x + footprint.size.x + side_px
			pos = Vector2(x_east, bottom + y_px)
		"north":
			facing = "south"
			pos = Vector2(center.x, footprint.position.y - side_px + y_px)
		_:
			facing = "north"
			pos = Vector2(center.x, bottom + side_px + y_px)
	return {"position": pos, "side": side, "facing": facing}


static func _order_candidates(cands: Array[Dictionary], approach: Vector2) -> Array[Dictionary]:
	var ordered: Array[Dictionary] = []
	for cand: Dictionary in cands:
		var placed := false
		var cand_pos: Vector2 = cand.get("position", Vector2.ZERO)
		for i: int in range(ordered.size()):
			var existing: Dictionary = ordered[i]
			var existing_pos: Vector2 = existing.get("position", Vector2.ZERO)
			if approach.distance_squared_to(cand_pos) < approach.distance_squared_to(existing_pos):
				ordered.insert(i, cand)
				placed = true
				break
		if not placed:
			ordered.append(cand)
	return ordered


static func _clear_variant(base: Dictionary, blocked: Callable) -> Dictionary:
	var origin: Vector2 = base.get("position", Vector2.ZERO)
	for pos: Vector2 in _nudge_options(origin, str(base.get("side", ""))):
		if not _call_blocked(blocked, pos):
			var picked: Dictionary = base.duplicate()
			picked["position"] = pos
			return picked
	return {}


static func _nudge_options(origin: Vector2, side: String) -> Array[Vector2]:
	var opts: Array[Vector2] = [origin]
	var outward := Vector2.ZERO
	var along := Vector2.RIGHT
	match side:
		"west":
			outward = Vector2.LEFT
			along = Vector2.DOWN
		"east":
			outward = Vector2.RIGHT
			along = Vector2.DOWN
		"north":
			outward = Vector2.UP
			along = Vector2.RIGHT
		_:
			outward = Vector2.DOWN
			along = Vector2.RIGHT
	for step: float in [16.0, 32.0, 48.0]:
		opts.append(origin + outward * step)
		opts.append(origin + along * step)
		opts.append(origin - along * step)
		opts.append(origin + outward * step + along * step)
		opts.append(origin + outward * step - along * step)
	return opts


static func _call_blocked(blocked: Callable, pos: Vector2) -> bool:
	if not blocked.is_valid():
		return false
	return bool(blocked.call(pos))


static func sprite_footprint(sprite_node: Sprite2D) -> Rect2:
	if sprite_node == null or sprite_node.texture == null:
		return Rect2()
	var frame := Vector2(sprite_node.texture.get_width(), sprite_node.texture.get_height())
	if sprite_node.hframes > 1:
		frame.x /= float(sprite_node.hframes)
	if sprite_node.vframes > 1:
		frame.y /= float(sprite_node.vframes)
	var origin: Vector2 = sprite_node.offset
	if sprite_node.centered:
		origin -= frame * 0.5
	var xf: Transform2D = sprite_node.global_transform
	var sc: Vector2 = xf.get_scale()
	return Rect2(xf * origin, Vector2(frame.x * absf(sc.x), frame.y * absf(sc.y)))


func plan_work(target: Node2D, type_id: String, station_id: String = "") -> Dictionary:
	return _solve_for(target, type_id, station_id)


func work_destination(target: Node2D, type_id: String) -> Vector2:
	var solved: Dictionary = _solve_for(target, type_id)
	return solved.get("position", target.global_position)


func work_spot_position() -> Vector2:
	if _has_work_spot:
		return _work_spot
	return global_position


func has_station_work_spot() -> bool:
	return _has_work_spot and _work_tool == "station"


func command_work(target: Node2D, type_id: String) -> void:
	if target == null:
		return
	if GameState.is_world_frozen():
		GameState.note_frozen_deny()
		return
	var solved: Dictionary = _solve_for(target, type_id)
	_apply_solved(target, type_id, solved)
	_suppress_work_clear = true
	move_to(_work_spot, target)
	_suppress_work_clear = false


func command_station(station: Node2D) -> void:
	if station == null:
		return
	if GameState.is_world_frozen():
		GameState.note_frozen_deny()
		return
	var sid := ""
	if "station_id" in station:
		sid = str(station.get("station_id"))
	var solved: Dictionary = _solve_for(station, "station", sid)
	_apply_solved(station, "station", solved)
	_suppress_work_clear = true
	move_to(_work_spot, null)
	_suppress_work_clear = false


func begin_work_loop() -> void:
	_work_loop = true


func end_work_loop() -> void:
	_work_loop = false


func hold_contact_pose(anim: StringName, frame_idx: int) -> void:
	set_physics_process(false)
	_moving = false
	velocity = Vector2.ZERO
	if sprite == null:
		return
	sprite.flip_h = false
	sprite.speed_scale = 0.0
	sprite.offset = _offset_for_anim(String(anim))
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(anim):
		sprite.play(anim)
		sprite.frame = clampi(frame_idx, 0, sprite.sprite_frames.get_frame_count(anim) - 1)
		sprite.pause()


func preview_station_work(station_id: String) -> void:
	_moving = false
	velocity = Vector2.ZERO
	_has_work_spot = true
	_work_spot = global_position
	_work_tool = "station"
	_work_facing = "north"
	_work_type = "station"
	_work_station_id = station_id
	_work_target = null
	_work_loop = false
	if has_node("/root/ForgeJobs"):
		ForgeJobs.set_keeper_working(station_id, true)


func clear_work_preview() -> void:
	_clear_work_order()
	if has_node("/root/ForgeJobs"):
		ForgeJobs.set_keeper_working("", false)
	_update_anim(Vector2.ZERO)


func _solve_for(target: Node2D, type_id: String, station_id: String = "") -> Dictionary:
	var footprint: Rect2 = _footprint_of(target)
	var blocked := Callable(self, "_spot_blocked").bind(target)
	return solve_work_spot(footprint, global_position, type_id, blocked, station_id)


func _footprint_of(target: Node2D) -> Rect2:
	if target != null and target.has_method("work_footprint"):
		return target.call("work_footprint")
	if target == null:
		return Rect2()
	return Rect2(target.global_position, Vector2(32, 32))


func _apply_solved(target: Node, type_id: String, solved: Dictionary) -> void:
	_has_work_spot = true
	_work_spot = solved.get("position", global_position)
	_work_side = str(solved.get("side", ""))
	_work_facing = str(solved.get("facing", "south"))
	_work_tool = str(solved.get("tool", ""))
	_work_type = type_id
	_work_station_id = str(solved.get("station_id", ""))
	_work_target = target
	if bool(solved.get("fallback", false)):
		_warn_fallback_once(target, type_id)


func _warn_fallback_once(target: Node, type_id: String) -> void:
	if target == null or not OS.is_debug_build():
		return
	var key := "%s:%s" % [target.get_instance_id(), type_id]
	if _fallback_logged.has(key):
		return
	_fallback_logged[key] = true
	push_warning("Keeper work spot: both sides blocked for %s (%s); using nearest spot %s" % [type_id, target.name, str(_work_spot)])


func _spot_blocked(pos: Vector2, target: Node) -> bool:
	if is_inside_tree():
		var mains: Array[Node] = get_tree().get_nodes_in_group("main_root")
		if not mains.is_empty() and mains[0].has_method("_in_clearing"):
			if not bool(mains[0].call("_in_clearing", pos)):
				return true
	if not is_inside_tree():
		return false
	var world: World2D = get_world_2d()
	if world == null:
		return false
	var space: PhysicsDirectSpaceState2D = world.direct_space_state
	if space == null:
		return false
	var shape := RectangleShape2D.new()
	shape.size = Vector2(36, 48)
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = Transform2D(0.0, pos + Vector2(0, -24))
	params.collision_mask = 1
	params.collide_with_areas = false
	params.collide_with_bodies = true
	var exclude: Array[RID] = [get_rid()]
	var trunk: StaticBody2D = _trunk_of(target)
	if trunk != null:
		exclude.append(trunk.get_rid())
	params.exclude = exclude
	return not space.intersect_shape(params, 1).is_empty()


func _trunk_of(target: Node) -> StaticBody2D:
	if target == null:
		return null
	return target.get_node_or_null("Trunk") as StaticBody2D


func _clear_work_order() -> void:
	_has_work_spot = false
	_work_loop = false
	_work_target = null
	_work_tool = ""
	_work_type = ""
	_work_station_id = ""
	_work_side = ""
	_work_facing = "south"


func _ensure_work_spot(target: Node2D, type_id: String) -> Vector2:
	if _has_work_spot and _work_target == target and _work_type == type_id:
		return _work_spot
	var solved: Dictionary = _solve_for(target, type_id)
	_apply_solved(target, type_id, solved)
	return _work_spot


func halt() -> void:
	_moving = false
	_pending_interact = null
	_water_pending = false
	velocity = Vector2.ZERO
	_clear_work_order()
	cancel_channel(false)


func move_to(world_pos: Vector2, interact: Node = null) -> void:
	if GameState.is_world_frozen():
		GameState.note_frozen_deny()
		return
	if _channel_kind != ChannelKind.NONE:
		if interact != _channel_target:
			cancel_channel()
	if not _suppress_work_clear:
		_clear_work_order()
		_water_pending = false
	_target = world_pos
	_pending_interact = interact
	_moving = true


func start_harvest_channel(node: Gatherable) -> void:
	if GameState.is_world_frozen():
		GameState.note_frozen_deny()
		return
	if node == null:
		return
	cancel_channel()
	_ensure_work_spot(node, String(node.resource_id))
	_channel_kind = ChannelKind.HARVEST
	_channel_target = node
	_channel_accum = 0.0
	node.set_channeling(true)
	GameAudio.play_channel_start()
	GameState.status_message.emit(ContentStrings.get_text("harvest_start"))
	channel_changed.emit(&"harvest", true)
	if has_node("/root/ForgeJobs"):
		ForgeJobs.set_keeper_task("harvest", String(node.resource_id), true)
	_channel_accum = 0.0


func start_water_channel(tree: Manatree) -> void:
	if GameState.is_world_frozen():
		GameState.note_frozen_deny()
		return
	if tree == null:
		return
	var spot: Vector2 = _ensure_work_spot(tree, "manatree")
	if global_position.distance_to(spot) > ARRIVE_DIST + WORK_ARRIVE_SLACK:
		_water_pending = true
		_suppress_work_clear = true
		move_to(spot, null)
		_suppress_work_clear = false
		return
	_begin_water_channel(tree)


func _begin_water_channel(tree: Manatree) -> void:
	if tree == null:
		return
	cancel_channel()
	_ensure_work_spot(tree, "manatree")
	_channel_kind = ChannelKind.WATER
	_channel_target = tree
	_channel_accum = 0.0
	tree.set_watering(true)
	GameAudio.play_channel_start()
	GameState.status_message.emit(ContentStrings.get_text("tree_water_start"))
	channel_changed.emit(&"water", true)
	if has_node("/root/ForgeJobs"):
		ForgeJobs.set_keeper_task("water", "manatree", true)
	_do_water_pulse()
	_channel_accum = 0.0


func cancel_channel(emit_status: bool = true) -> void:
	if _channel_kind == ChannelKind.NONE:
		return
	var kind: int = _channel_kind
	var target: Node = _channel_target
	_channel_kind = ChannelKind.NONE
	_channel_target = null
	_channel_accum = 0.0
	if kind == ChannelKind.HARVEST and target is Gatherable:
		var g: Gatherable = target as Gatherable
		if emit_status:
			g.on_channel_cancel()
		else:
			g.set_channeling(false)
		channel_changed.emit(&"harvest", false)
	elif kind == ChannelKind.WATER and target is Manatree:
		var t: Manatree = target as Manatree
		t.set_watering(false)
		if emit_status:
			GameState.status_message.emit(ContentStrings.get_text("tree_water_cancel"))
		channel_changed.emit(&"water", false)
	if has_node("/root/ForgeJobs"):
		var task: Dictionary = ForgeJobs.keeper_task()
		var task_kind: String = str(task.get("kind", ""))
		if task_kind == "harvest" or task_kind == "water":
			ForgeJobs.note_keeper_idle()


func is_channeling() -> bool:
	return _channel_kind != ChannelKind.NONE


func get_channel_kind() -> StringName:
	match _channel_kind:
		ChannelKind.HARVEST:
			return &"harvest"
		ChannelKind.WATER:
			return &"water"
		_:
			return &""


func _channel_stand_pos(target: Node) -> Vector2:
	if _has_work_spot and target == _work_target:
		return _work_spot
	if target is Manatree:
		return target.global_position + Vector2(0, 40)
	if target is Gatherable:
		return (target as Gatherable).approach_point()
	return target.global_position


func _check_channel_range() -> void:
	if _channel_kind == ChannelKind.NONE or _channel_target == null or not is_instance_valid(_channel_target):
		if _channel_kind != ChannelKind.NONE:
			cancel_channel()
		return
	var range_px: float = GameState.get_harvest_range() + 24.0
	if global_position.distance_to(_channel_stand_pos(_channel_target)) > range_px * 2.0:
		var was_harvest: bool = _channel_kind == ChannelKind.HARVEST
		cancel_channel(false)
		if was_harvest:
			GameState.status_message.emit(ContentStrings.get_text("harvest_out_of_range"))
		else:
			GameState.status_message.emit(ContentStrings.get_text("tree_water_out_of_range"))


func _tick_channel(delta: float) -> void:
	if _channel_kind == ChannelKind.NONE:
		return
	if _channel_target == null or not is_instance_valid(_channel_target):
		cancel_channel(false)
		return
	var range_px: float = GameState.get_harvest_range() + 32.0
	if global_position.distance_to(_channel_stand_pos(_channel_target)) > range_px:
		var was_harvest: bool = _channel_kind == ChannelKind.HARVEST
		cancel_channel(false)
		if was_harvest:
			GameState.status_message.emit(ContentStrings.get_text("harvest_out_of_range"))
		else:
			GameState.status_message.emit(ContentStrings.get_text("tree_water_out_of_range"))
		return
	if _channel_kind == ChannelKind.HARVEST and _channel_target is Gatherable:
		var rid: StringName = (_channel_target as Gatherable).resource_id
		GameState.accumulate_keeper_harvest(rid, delta)
	elif _channel_kind == ChannelKind.WATER:
		_channel_accum += delta
		var pulse: float = GameState.get_water_essence_pulse_sec()
		if pulse <= 0.0:
			return
		while _channel_accum >= pulse:
			_channel_accum -= pulse
			_do_water_pulse()


func _do_water_pulse() -> void:
	var result: Dictionary = GameState.apply_water_pulse()
	if not bool(result.get("ok", false)):
		cancel_channel(false)
		return
	GameAudio.play_water_pulse()
	GameState.status_message.emit(ContentStrings.get_text("tree_water_pulse_hud", {
		"shards": int(result.get("shards", 0)),
		"essence": int(result.get("essence", 0)),
	}))
	if _channel_target is Manatree:
		(_channel_target as Manatree).refresh_after_care()


func _try_interact() -> void:
	if _pending_interact == null or not is_instance_valid(_pending_interact):
		_pending_interact = null
		return
	if global_position.distance_to(_pending_interact.global_position) > INTERACT_DIST * 2.5:
		_pending_interact = null
		return
	if _pending_interact.has_method("on_interact"):
		_pending_interact.call("on_interact", self)
	interaction_finished.emit(_pending_interact)
	_pending_interact = null


func _on_click_area_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if not mb.pressed:
			return
		if mb.button_index == MOUSE_BUTTON_LEFT:
			GameState.select_keeper()
			GameState.status_message.emit(ContentStrings.get_text("keeper_select_hint"))
			get_viewport().set_input_as_handled()
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			get_viewport().set_input_as_handled()


func _on_hover(inside: bool) -> void:
	_hovered = inside
	_on_selection_changed()


func _apply_outline(show_outline: bool) -> void:
	if sprite == null:
		return
	if show_outline:
		if _outline_mat == null:
			_outline_mat = ShaderMaterial.new()
			_outline_mat.shader = OUTLINE_SHADER
		sprite.material = _outline_mat
	else:
		sprite.material = null


func face_out() -> void:
	## South door of the Manatree. Idle faces the clearing.
	_moving = false
	_pending_interact = null
	_water_pending = false
	_target = global_position
	if sprite:
		sprite.flip_h = false
		sprite.speed_scale = 1.0
		sprite.offset = OFFSET_BODY
		sprite.play(&"idle_south")


func _on_selection_changed() -> void:
	if select_ring:
		select_ring.visible = false
	_apply_outline(GameState.keeper_selected)
	if label:
		if GameState.keeper_selected:
			label.text = ContentStrings.get_text("keeper_selected")
			modulate = Color(1.08, 1.12, 1.0, 1.0)
		else:
			label.text = ContentStrings.get_text("keeper_select")
			modulate = Color.WHITE
		label.visible = _hovered
