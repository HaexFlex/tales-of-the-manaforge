extends Keeper
class_name Companion
## One hub body for every roster id. Art, rates, and join come from data/companions.json.
## The Keeper scene does not use this script.

const SCENE_PATH: String = "res://scenes/companion.tscn"

@export var home_area: String = "clearing"

var _blank: Texture2D


func _ready() -> void:
	super._ready()
	if not GameState.echo_flags_changed.is_connected(_on_join_flags):
		GameState.echo_flags_changed.connect(_on_join_flags)
	if not GameState.load_completed.is_connected(_on_join_flags):
		GameState.load_completed.connect(_on_join_flags)
	_apply_presence()


func _on_join_flags() -> void:
	if is_inside_tree():
		_apply_presence()


static func ensure_hub_bodies(parent: Node, area: String) -> void:
	if parent == null:
		return
	var packed: PackedScene = load(SCENE_PATH) as PackedScene
	if packed == null:
		return
	var lane: int = 0
	for actor_id: String in CompanionRoster.ids():
		if actor_id == "elaia" or not CompanionRoster.hub_body(actor_id):
			continue
		var node_name: String = actor_id.capitalize()
		if parent.get_node_or_null(node_name) != null:
			continue
		var body: Companion = packed.instantiate() as Companion
		if body == null:
			continue
		body.name = node_name
		body.companion_id = actor_id
		body.home_area = area
		body.y_sort_enabled = true
		body.position = Vector2(2144, 2460) + Vector2(36.0 * float(lane + 1), 18.0)
		parent.add_child(body)
		lane += 1


func _join_groups() -> void:
	companion_id = CompanionRoster.canonical_id(companion_id)
	add_to_group("companion")
	if companion_id != "":
		add_to_group(companion_id)


func actor_id() -> String:
	return companion_id if companion_id != "" else "elaia"


func actor_selected() -> bool:
	return str(GameState.selected_companion_id) == actor_id()


func actor_select() -> void:
	GameState.select_companion(actor_id())


func actor_label_idle() -> String:
	return GameState.hero_display_name(actor_id())


func actor_label_selected() -> String:
	return actor_label_idle()


func actor_task() -> Dictionary:
	if not has_node("/root/ForgeJobs"):
		return {"kind": "none", "target": "", "working": false}
	return ForgeJobs.task_for(actor_id())


func _build_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	var spec: Dictionary = CompanionRoster.row(actor_id())
	var anim_v: Variant = spec.get("anim", {})
	var anim: Dictionary = anim_v if typeof(anim_v) == TYPE_DICTIONARY else {}
	var root: String = str(anim.get("root", ""))
	var hold: float = float(anim.get("idle_hold_ms", 140.0))
	var idle_v: Variant = anim.get("idle", {})
	var idle: Dictionary = idle_v if typeof(idle_v) == TYPE_DICTIONARY else {}
	for face: String in ["south", "north", "east", "west"]:
		var rel: String = str(idle.get(face, ""))
		var path: String = "%s/%s" % [root, rel] if root != "" and rel != "" else ""
		_add_still(frames, StringName("idle_%s" % face), path, hold)
	if not frames.has_animation(&"idle_front"):
		_add_still(frames, &"idle_front", "%s/%s" % [root, str(idle.get("south", ""))] if root != "" else "", hold)
	var clips_v: Variant = anim.get("clips", {})
	if typeof(clips_v) == TYPE_DICTIONARY:
		for clip_v: Variant in (clips_v as Dictionary).keys():
			var clip_name: String = str(clip_v)
			var clip: Variant = (clips_v as Dictionary)[clip_v]
			if typeof(clip) != TYPE_DICTIONARY:
				continue
			var folder: String = str((clip as Dictionary).get("dir", ""))
			var ms_v: Variant = (clip as Dictionary).get("ms", [])
			var frame_ms: float = float((clip as Dictionary).get("frame_ms", 0.0))
			var durations: Array[float] = []
			if typeof(ms_v) == TYPE_ARRAY:
				for ms: Variant in ms_v as Array:
					durations.append(float(ms))
			if frame_ms > 0.0:
				var disk_ms: Array[float] = _durations_from_disk(root, folder, frame_ms)
				if not disk_ms.is_empty():
					durations = disk_ms
			_add_clip(frames, StringName(clip_name), root, folder, durations)
	if not frames.has_animation(&"walk_south"):
		_add_still(frames, &"walk_south", "", 100.0)
	if not frames.has_animation(&"idle_south"):
		_add_still(frames, &"idle_south", "", hold)
	return frames


func _blank_tex() -> Texture2D:
	if _blank != null:
		return _blank
	var image := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_blank = ImageTexture.create_from_image(image)
	return _blank


func _add_still(frames: SpriteFrames, anim: StringName, path: String, hold_ms: float) -> void:
	if frames.has_animation(anim):
		return
	frames.add_animation(anim)
	frames.set_animation_loop(anim, true)
	frames.set_animation_speed(anim, 1000.0 / maxf(hold_ms, 1.0))
	var tex: Texture2D = _blank_tex()
	if path != "" and ResourceLoader.exists(path):
		var loaded: Texture2D = load(path) as Texture2D
		if loaded != null:
			tex = loaded
	frames.add_frame(anim, tex, hold_ms)


func _durations_from_disk(root: String, folder: String, frame_ms: float) -> Array[float]:
	var out: Array[float] = []
	if root == "" or folder == "":
		return out
	var i: int = 0
	while true:
		var path: String = "%s/%s/frame_%04d.png" % [root, folder, i]
		if not ResourceLoader.exists(path):
			break
		out.append(frame_ms)
		i += 1
	return out


func _add_clip(frames: SpriteFrames, anim: StringName, root: String, folder: String, durations: Array[float]) -> void:
	if frames.has_animation(anim):
		return
	frames.add_animation(anim)
	frames.set_animation_loop(anim, true)
	frames.set_animation_speed(anim, 1000.0)
	var added: int = 0
	for i: int in range(durations.size()):
		var path: String = "%s/%s/frame_%04d.png" % [root, folder, i]
		if root == "" or folder == "" or not ResourceLoader.exists(path):
			continue
		var tex: Texture2D = load(path) as Texture2D
		if tex == null:
			continue
		frames.add_frame(anim, tex, durations[i])
		added += 1
	if added == 0:
		frames.add_frame(anim, _blank_tex(), 100.0)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if visible:
		_remember_pose()


func start_water_channel(tree: Manatree) -> void:
	if not GameState.companion_joined(actor_id()):
		return
	if GameState.companion_area(actor_id()) != home_area:
		return
	super.start_water_channel(tree)


func _apply_presence() -> void:
	var here: bool = GameState.companion_body_visible(actor_id()) and GameState.companion_area(actor_id()) == home_area and not GameState.member_away(actor_id())
	if here and not GameState.companion_has_pos(actor_id()) and home_area == "clearing":
		_spawn_beside_keeper()
		here = true
	_set_present(here)
	if not here:
		return
	if GameState.companion_has_pos(actor_id()):
		global_position = GameState.companion_pos(actor_id())
		_target = global_position
	var face: String = GameState.companion_facing(actor_id())
	_facing = face if face != "" else "south"
	_resume_saved_task()


func _spawn_beside_keeper() -> void:
	var spot := global_position
	if actor_id() == "elaia" and has_node("/root/ForgeJobs"):
		spot = ForgeJobs.elaia_join_stand()
	else:
		var keepers: Array[Node] = get_tree().get_nodes_in_group("keeper") if is_inside_tree() else []
		if not keepers.is_empty() and keepers[0] is Node2D:
			var lane: float = float(CompanionSchedule.lane_of(actor_id()))
			spot = (keepers[0] as Node2D).global_position + Vector2(84.0 + lane * 36.0, 6.0)
	global_position = spot
	_target = spot
	GameState.set_companion_pose(actor_id(), "clearing", spot, "south", true)
	_facing = "south"


func _set_present(on: bool) -> void:
	visible = on
	set_physics_process(on)
	var body_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if body_shape:
		body_shape.disabled = not on
	if click_area:
		click_area.monitorable = on
		var click_shape := click_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if click_shape:
			click_shape.disabled = not on
	if not on:
		_moving = false
		velocity = Vector2.ZERO


func bring_to_this_area(near: Vector2) -> void:
	if GameState.companion_area(actor_id()) != home_area:
		if has_node("/root/GameAudio"):
			GameAudio.play(&"sfx_door_bark")
	GameState.set_companion_pose(actor_id(), home_area, near, _facing, true)
	global_position = near
	_target = global_position
	_set_present(true)


func command_move(world_pos: Vector2) -> void:
	note_player_order()
	if not GameState.companion_joined(actor_id()):
		return
	if GameState.companion_area(actor_id()) != home_area:
		return
	move_to(world_pos, null)


func command_work(target: Node2D, type_id: String, claim_key: String = "") -> void:
	if not GameState.companion_joined(actor_id()):
		return
	if GameState.companion_area(actor_id()) != home_area:
		return
	super.command_work(target, type_id, claim_key)


func command_station(station: Node2D) -> void:
	if not GameState.companion_joined(actor_id()):
		return
	if GameState.companion_area(actor_id()) != home_area:
		return
	super.command_station(station)


func _entry_point() -> Vector2:
	if has_node("/root/ForgeJobs"):
		if home_area == "forge":
			return ForgeJobs.forge_arch_spawn()
		return ForgeJobs.clearing_door_stand()
	if home_area == "forge":
		return Vector2(800, 1013)
	return global_position


func _resume_saved_task() -> void:
	if not has_node("/root/ForgeJobs"):
		_update_anim(Vector2.ZERO)
		return
	var task: Dictionary = ForgeJobs.task_for(actor_id())
	if not bool(task.get("working", false)):
		_update_anim(Vector2.ZERO)
		return
	var kind: String = str(task.get("kind", ""))
	var target_id: String = str(task.get("target", ""))
	if kind == "harvest" and home_area == "clearing":
		var node := _find_gatherable(target_id)
		if node:
			_snap_and_channel(node, target_id)
		return
	if kind == "water" and home_area == "clearing":
		var tree := _find_manatree()
		if tree:
			_snap_and_channel(tree, "manatree")
		return
	if kind == "forge" and home_area == "forge":
		var station := _find_station(target_id)
		if station:
			var solved: Dictionary = _solve_for(station, "station", target_id)
			global_position = solved.get("position", global_position)
			_target = global_position
			_apply_solved(station, "station", solved)
			_work_loop = true
			ForgeJobs.set_actor_working(actor_id(), target_id, true)
			_update_anim(Vector2.ZERO)
		return
	if kind == "bench" and home_area == "clearing":
		var bench := get_tree().get_first_node_in_group("keepers_bench") as Node2D
		if bench:
			var solved_bench: Dictionary = _solve_for(bench, "bench")
			global_position = solved_bench.get("position", global_position)
			_target = global_position
			_apply_solved(bench, "bench", solved_bench)
			_work_loop = true
			ForgeJobs.set_actor_working(actor_id(), "workbench", true)
			_update_anim(Vector2.ZERO)
		return
	_update_anim(Vector2.ZERO)


func _snap_and_channel(target: Node2D, type_id: String) -> void:
	var solved: Dictionary = _solve_for(target, type_id)
	global_position = solved.get("position", global_position)
	_target = global_position
	_apply_solved(target, type_id, solved)
	if type_id == "manatree" and target is Manatree:
		start_water_channel(target as Manatree)
	elif target is Gatherable:
		start_harvest_channel(target as Gatherable)
	_update_anim(Vector2.ZERO)


func _find_gatherable(resource_id: String) -> Gatherable:
	if not is_inside_tree():
		return null
	for node: Node in get_tree().get_nodes_in_group("gatherable"):
		if node is Gatherable and String((node as Gatherable).resource_id) == resource_id:
			return node as Gatherable
	return null


func _find_manatree() -> Manatree:
	if not is_inside_tree():
		return null
	var nodes: Array[Node] = get_tree().get_nodes_in_group("manatree")
	if nodes.is_empty():
		return null
	return nodes[0] as Manatree


func _find_station(station_id: String) -> Node2D:
	if not is_inside_tree():
		return null
	for node: Node in get_tree().get_nodes_in_group("forge_station"):
		if node is Node2D and str(node.get("station_id")) == station_id:
			return node as Node2D
	return null


func actor_work_anim(tool: String, facing: String) -> String:
	if actor_id() == "mossback" and tool == "pickaxe":
		return "work_stone"
	return super.actor_work_anim(tool, facing)


func actor_work_anim_offset(anim: String) -> Vector2:
	var clip: Dictionary = CompanionClips.clip_spec(actor_id(), anim)
	if not clip.is_empty():
		var layout: Dictionary = CompanionClips.layout(clip)
		return layout.get("offset", OFFSET_BODY) as Vector2
	return super.actor_work_anim_offset(anim)


func _remember_pose() -> void:
	if not has_node("/root/GameState"):
		return
	if GameState.companion_area(actor_id()) != home_area:
		return
	GameState.set_companion_pose(actor_id(), home_area, global_position, _facing, true)
