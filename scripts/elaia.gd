extends Keeper
class_name Elaia
## Companion body. Same walk / work-spot / channel loop as the Keeper, with her frames and rates.
## Box-select never includes her: the marquee is Wisps + the Keeper. Select her by this sprite or her HUD portrait.

const ART: String = "res://assets/art/elaia/anim"

## Clearing or forge. The instance whose home matches GameState.elaia_area is the one that walks.
@export var home_area: String = "clearing"

const ELAIA_WALK_MS: Array[float] = [120.0, 125.0, 130.0, 125.0, 120.0, 125.0, 130.0, 125.0]
const ELAIA_AXE_MS: Array[float] = [140.0, 70.0, 60.0, 180.0, 90.0, 90.0, 90.0, 90.0, 90.0]
const ELAIA_PICK_MS: Array[float] = [100.0, 90.0, 90.0, 150.0, 70.0, 60.0, 60.0, 180.0, 100.0]
const ELAIA_BERRY_MS: Array[float] = [160.0, 90.0, 90.0, 100.0, 160.0, 100.0, 90.0, 110.0]
const ELAIA_WATER_MS: Array[float] = [170.0, 100.0, 90.0, 90.0, 110.0, 250.0, 250.0, 100.0, 90.0, 100.0]
const ELAIA_STATION_MS: Array[float] = [80.0, 120.0, 85.0, 85.0, 120.0, 85.0, 85.0, 80.0, 120.0, 80.0]


func _ready() -> void:
	super._ready()
	if not GameState.echo_flags_changed.is_connected(_on_join_flags):
		GameState.echo_flags_changed.connect(_on_join_flags)
	_apply_presence()


func _on_join_flags() -> void:
	if is_inside_tree():
		_apply_presence()


func start_water_channel(tree: Manatree) -> void:
	if not GameState.elaia_in_party():
		return
	if GameState.elaia_area != home_area:
		return
	super.start_water_channel(tree)


func _join_groups() -> void:
	## Not the "keeper" group. Commands that look up that group must keep finding the Keeper.
	## companion_id is declared on Keeper and stays empty there.
	companion_id = "elaia"
	add_to_group("companion")
	add_to_group("elaia")


func actor_id() -> String:
	return "elaia"


func actor_idle_uses_facing() -> bool:
	return true


func actor_selected() -> bool:
	return str(GameState.selected_companion_id) == "elaia"


func actor_select() -> void:
	GameState.select_companion("elaia")


func actor_label_idle() -> String:
	return ContentStrings.get_text("echo_elaia_name")


func actor_label_selected() -> String:
	return ContentStrings.get_text("echo_elaia_name")


func _build_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	_add_anim(frames, &"idle_south", ["%s/idle/south.png" % ART], IDLE_HOLD_MS)
	_add_anim(frames, &"idle_north", ["%s/idle/north.png" % ART], IDLE_HOLD_MS)
	_add_anim(frames, &"idle_east", ["%s/idle/east.png" % ART], IDLE_HOLD_MS)
	_add_anim(frames, &"idle_west", ["%s/idle/west.png" % ART], IDLE_HOLD_MS)
	_add_anim(frames, &"idle_front", ["%s/idle/south.png" % ART], IDLE_HOLD_MS)
	# No run cycle exists for her.
	_add_timed_root(frames, &"walk_south", "walk/south", ELAIA_WALK_MS)
	_add_timed_root(frames, &"walk_north", "walk/north", ELAIA_WALK_MS)
	_add_timed_root(frames, &"walk_east", "walk/east", ELAIA_WALK_MS)
	_add_timed_root(frames, &"walk_west", "walk/west", ELAIA_WALK_MS)
	_add_timed_root(frames, &"walk_front", "walk/south", ELAIA_WALK_MS)
	_add_timed_root(frames, &"harvest_axe_east", "harvest/axe/east", ELAIA_AXE_MS)
	_add_timed_root(frames, &"harvest_axe_west", "harvest/axe/west", ELAIA_AXE_MS)
	_add_timed_root(frames, &"harvest_pickaxe_east", "harvest/pickaxe/east", ELAIA_PICK_MS)
	_add_timed_root(frames, &"harvest_pickaxe_west", "harvest/pickaxe/west", ELAIA_PICK_MS)
	_add_timed_root(frames, &"harvest_berries_east", "harvest/berries/east", ELAIA_BERRY_MS)
	_add_timed_root(frames, &"harvest_berries_west", "harvest/berries/west", ELAIA_BERRY_MS)
	_add_timed_root(frames, &"harvest_water_east", "water/east", ELAIA_WATER_MS)
	_add_timed_root(frames, &"harvest_water_west", "water/west", ELAIA_WATER_MS)
	_add_timed_root(frames, &"station_work_north", "station/north", ELAIA_STATION_MS)
	return frames


func _add_timed_root(frames: SpriteFrames, anim: StringName, folder: String, durations: Array[float]) -> void:
	frames.add_animation(anim)
	frames.set_animation_loop(anim, true)
	frames.set_animation_speed(anim, 1000.0)
	for i: int in range(durations.size()):
		var path := "%s/%s/frame_%04d.png" % [ART, folder, i]
		var tex: Texture2D = load(path) as Texture2D
		frames.add_frame(anim, tex, durations[i])


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if visible:
		_remember_pose()


func _apply_presence() -> void:
	var here: bool = GameState.elaia_in_party() and GameState.elaia_area == home_area
	if here and not GameState.elaia_has_pos and home_area == "clearing":
		_spawn_beside_keeper()
		here = true
	_set_present(here)
	if not here:
		return
	if GameState.elaia_has_pos:
		global_position = GameState.elaia_pos
		_target = global_position
	_facing = GameState.elaia_facing if GameState.elaia_facing != "" else "south"
	_resume_saved_task()


func _spawn_beside_keeper() -> void:
	var spot := global_position
	if has_node("/root/ForgeJobs"):
		spot = ForgeJobs.elaia_join_stand()
	else:
		var keepers: Array[Node] = get_tree().get_nodes_in_group("keeper") if is_inside_tree() else []
		if not keepers.is_empty() and keepers[0] is Node2D:
			spot = (keepers[0] as Node2D).global_position + Vector2(84, 6)
	global_position = spot
	_target = spot
	GameState.elaia_has_pos = true
	GameState.elaia_pos = spot
	GameState.elaia_area = "clearing"
	GameState.elaia_facing = "south"
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
	## She does not follow the camera. A job in the other area uses the same door bark, then she walks.
	if GameState.elaia_area != home_area:
		if has_node("/root/GameAudio"):
			GameAudio.play(&"sfx_door_bark")
	GameState.elaia_area = home_area
	GameState.elaia_has_pos = true
	global_position = near
	_target = global_position
	GameState.elaia_pos = global_position
	_set_present(true)


func command_move(world_pos: Vector2) -> void:
	if not GameState.elaia_in_party():
		return
	if GameState.elaia_area != home_area:
		return
	move_to(world_pos, null)


func command_work(target: Node2D, type_id: String, claim_key: String = "") -> void:
	if not GameState.elaia_in_party():
		return
	if GameState.elaia_area != home_area:
		return
	super.command_work(target, type_id, claim_key)


func command_station(station: Node2D) -> void:
	if not GameState.elaia_in_party():
		return
	if GameState.elaia_area != home_area:
		return
	super.command_station(station)


func _entry_point() -> Vector2:
	if has_node("/root/ForgeJobs"):
		if home_area == "forge":
			return ForgeJobs.forge_arch_spawn()
		return ForgeJobs.clearing_door_stand()
	if home_area == "forge":
		return Vector2(800, 1048)
	return global_position


func _resume_saved_task() -> void:
	if not has_node("/root/ForgeJobs"):
		_update_anim(Vector2.ZERO)
		return
	var task: Dictionary = ForgeJobs.elaia_task()
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
			ForgeJobs.set_elaia_working(target_id, true)
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


func _remember_pose() -> void:
	## Area is written only by the door transfer. This used to stamp home_area
	## every physics frame, and the deferred scene swap let that stamp land
	## after the door had already moved her, so the next scene hid her.
	if not has_node("/root/GameState"):
		return
	if GameState.elaia_area != home_area:
		return
	GameState.elaia_pos = global_position
	GameState.elaia_has_pos = true
	GameState.elaia_facing = _facing
