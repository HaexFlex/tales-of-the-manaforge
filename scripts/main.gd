extends Node2D
## Forest hub 2560×2160 (2× × 3× of 1280×720): arrow-key camera, RTS LMB/RMB, wisps.

@onready var keeper: Keeper = %Keeper
@onready var manatree: Manatree = %Manatree
@onready var hud: GameHUD = %HUD
@onready var ground: TileMap = %Ground
@onready var click_layer: ColorRect = %ClickLayer
@onready var world: Node2D = %World
@onready var pause_menu: PauseMenu = %PauseMenu
@onready var camera: Camera2D = %Camera2D

const TILE: int = 64
## Match Area2D collision_layer on gatherable / manatree scenes.
const INTERACT_PICK_MASK: int = 4
const HUB_MAP_PATH: String = "res://data/hub_map.json"

const ATLAS_GRASS: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)
]
## Trunk and door, not the whole canopy. The rest of the clearing may hold flora.
const MANATREE_DECOR_RADIUS: float = 200.0

const WISP_SCENE: PackedScene = preload("res://scenes/wisp.tscn")
const RUNESTONE_SCENE: PackedScene = preload("res://scenes/runestone.tscn")
const PORTAL_SCENE: PackedScene = preload("res://scenes/echo_portal.tscn")
var _wisp_nodes: Dictionary = {}  # wisp_id int → WispOrb
var hub_map: Dictionary = {}
var play_size: Vector2 = Vector2(2560, 2160)
var view_size: Vector2 = Vector2(1280, 720)
var camera_pan_speed: float = 420.0
var glade: Rect2 = Rect2(760, 820, 1680, 1360)
var clearing_center: Vector2 = Vector2(1600, 1500)
var clearing_rx: float = 1200.0
var clearing_ry: float = 980.0
var clear_points: Array[Vector2] = []
var clear_radii: Array[float] = []
var _cols: int = 40
var _rows: int = 34
const TITLE_SCENE: String = "res://scenes/title_screen.tscn"
const CLICK_SLOP: float = 6.0
var _boot_redirect: bool = false
var _drag_active: bool = false
var _drag_from: Vector2 = Vector2.ZERO
var _marquee: Line2D


func _enter_tree() -> void:
	# Apply before child _ready so the HUD does not paint the previous run.
	# A bare launch of this scene (Run Project / Run Current Scene) is the title.
	if _bare_boot_to_title():
		_boot_redirect = true
		return
	_apply_boot_intent()


func _bare_boot_to_title() -> bool:
	if str(SaveService.boot_intent) != "auto":
		return false
	var tree: SceneTree = get_tree()
	return tree != null and tree.current_scene == self


func _ready() -> void:
	if _boot_redirect:
		var tree: SceneTree = get_tree()
		if tree:
			tree.call_deferred("change_scene_to_file", TITLE_SCENE)
		return
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("main_root")
	_load_hub_map()
	# Layout lives in scenes/main.tscn. Baking would rebuild the forest and wipe editor edits.
	if OS.get_environment("MANAFORGE_BAKE") == "1":
		push_error("MANAFORGE_BAKE refused. The hub layout lives in scenes/main.tscn. Do not bake; it would wipe editor edits.")
	_setup_camera(false)
	_apply_forge_return()
	# Pass clicks through so Area2D harvest / Manatree can receive them.
	click_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	click_layer.position = Vector2.ZERO
	click_layer.size = play_size
	get_viewport().physics_object_picking = true
	manatree.fruit_menu_requested.connect(_on_fruit_menu)
	manatree.care_menu_requested.connect(_on_care_menu)
	hud.bind_manatree(manatree)
	hud.bind_pause_menu(pause_menu)
	GameAudio.play_hub_music()
	GameState.wisps_changed.connect(_sync_wisps)
	GameState.load_completed.connect(_sync_wisps)
	_sync_wisps()
	# First load / new save: show Keeper welcome once (flag in save).
	hud.maybe_show_welcome()


func _load_hub_map() -> void:
	hub_map = _load_json_dict(HUB_MAP_PATH)
	play_size = Vector2(
		float(hub_map.get("play_width", 2560)),
		float(hub_map.get("play_height", 2160))
	)
	view_size = Vector2(
		float(hub_map.get("viewport_width", 1280)),
		float(hub_map.get("viewport_height", 720))
	)
	camera_pan_speed = float(hub_map.get("camera_pan_speed", 420.0))
	var clearing_v: Variant = hub_map.get("clearing", {})
	if typeof(clearing_v) == TYPE_DICTIONARY:
		var cd: Dictionary = clearing_v
		clearing_center = _vec2_from(cd.get("center", [clearing_center.x, clearing_center.y]))
		clearing_rx = float(cd.get("rx", clearing_rx))
		clearing_ry = float(cd.get("ry", clearing_ry))
	var glade_v: Variant = hub_map.get("glade", [760, 820, 1680, 1360])
	if typeof(glade_v) == TYPE_ARRAY and (glade_v as Array).size() >= 4:
		var ga: Array = glade_v
		glade = Rect2(float(ga[0]), float(ga[1]), float(ga[2]), float(ga[3]))
	var tile: int = int(hub_map.get("tile", TILE))
	_cols = int(ceili(play_size.x / float(tile)))
	_rows = int(ceili(play_size.y / float(tile)))
	clear_points.clear()
	clear_radii.clear()
	var marks: Dictionary = hub_map.get("landmarks", {}) as Dictionary
	var order: Array[String] = ["manatree", "harvest_tree", "harvest_stone", "harvest_berry", "keeper"]
	var radii_v: Variant = hub_map.get("clear_radii", [200, 175, 140, 160, 80])
	for i: int in range(order.size()):
		var pt: Vector2 = _vec2_from(marks.get(order[i], [0, 0]))
		clear_points.append(pt)
		var rad: float = 80.0
		if typeof(radii_v) == TYPE_ARRAY and (radii_v as Array).size() > i:
			rad = float((radii_v as Array)[i])
		clear_radii.append(rad)
	var extras: Variant = hub_map.get("extra_clear", [])
	if typeof(extras) == TYPE_ARRAY:
		for extra_v: Variant in extras:
			if typeof(extra_v) != TYPE_DICTIONARY:
				continue
			var extra: Dictionary = extra_v
			clear_points.append(_vec2_from(extra.get("pos", [0, 0])))
			clear_radii.append(float(extra.get("radius", 120.0)))
	var stone_clear: float = float(hub_map.get("runestone_clear", 84.0))
	var stone_rows: Variant = hub_map.get("runestones", [])
	if typeof(stone_rows) == TYPE_ARRAY:
		for stone_v: Variant in stone_rows:
			if typeof(stone_v) != TYPE_DICTIONARY:
				continue
			clear_points.append(_vec2_from((stone_v as Dictionary).get("pos", [0, 0])))
			clear_radii.append(stone_clear)


func _vec2_from(raw: Variant) -> Vector2:
	if typeof(raw) == TYPE_ARRAY and (raw as Array).size() >= 2:
		return Vector2(float((raw as Array)[0]), float((raw as Array)[1]))
	if raw is Vector2:
		return raw
	return Vector2.ZERO


func _apply_landmarks() -> void:
	var marks: Dictionary = hub_map.get("landmarks", {}) as Dictionary
	if manatree:
		manatree.position = _vec2_from(marks.get("manatree", [1280, 1000]))
	if keeper:
		keeper.position = _vec2_from(marks.get("keeper", [1120, 1100]))
	var harvest_tree: Node2D = get_node_or_null("World/HarvestTree") as Node2D
	var harvest_stone: Node2D = get_node_or_null("World/HarvestStone") as Node2D
	var harvest_berry: Node2D = get_node_or_null("World/HarvestBerry") as Node2D
	if harvest_tree:
		harvest_tree.position = _vec2_from(marks.get("harvest_tree", [840, 1140]))
	if harvest_stone:
		harvest_stone.position = _vec2_from(marks.get("harvest_stone", [1040, 1160]))
	if harvest_berry:
		harvest_berry.position = _vec2_from(marks.get("harvest_berry", [1540, 1140]))


func _spawn_runestones() -> void:
	## One placeholder stone per combat stat, beside the Manatree in the open glade.
	var rows: Variant = hub_map.get("runestones", [])
	if typeof(rows) != TYPE_ARRAY or world == null:
		return
	var root := Node2D.new()
	root.name = "Runestones"
	root.unique_name_in_owner = true
	world.add_child(root)
	for entry: Variant in rows:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = entry
		var sid: String = str(d.get("stat", ""))
		if sid == "":
			continue
		var stone: Runestone = RUNESTONE_SCENE.instantiate() as Runestone
		if stone == null:
			continue
		stone.name = "Runestone_%s" % sid
		stone.stat_id = StringName(sid)
		stone.position = _vec2_from(d.get("pos", [0, 0]))
		root.add_child(stone)


func _spawn_echo_portal() -> void:
	if world == null:
		return
	var marks: Dictionary = hub_map.get("landmarks", {}) as Dictionary
	var portal: EchoPortal = PORTAL_SCENE.instantiate() as EchoPortal
	if portal == null:
		return
	portal.name = "EchoPortal"
	portal.unique_name_in_owner = true
	portal.position = _vec2_from(marks.get("echo_portal", [1560, 820]))
	world.add_child(portal)


func _setup_camera(snap_to_tree: bool) -> void:
	if camera == null:
		camera = Camera2D.new()
		camera.name = "Camera2D"
		add_child(camera)
	camera.enabled = true
	camera.make_current()
	camera.position_smoothing_enabled = false
	if snap_to_tree and manatree:
		camera.position = manatree.position
	_clamp_camera()


func _apply_forge_return() -> void:
	if not has_node("/root/ForgeJobs") or not ForgeJobs.take_clearing_return():
		return
	if keeper == null or manatree == null:
		return
	keeper.global_position = manatree.global_position + ForgeJobs.return_offset()
	if keeper.has_method("face_out"):
		keeper.face_out()
	if camera:
		camera.position = _clamped_camera_pos(keeper.global_position)


func focus_manatree() -> void:
	if camera == null or manatree == null:
		return
	camera.position = _clamped_camera_pos(manatree.global_position)


func get_play_size() -> Vector2:
	return play_size


func get_camera_pan_speed() -> float:
	return camera_pan_speed


func get_camera_position_clamped() -> Vector2:
	return _clamped_camera_pos(camera.position if camera else Vector2.ZERO)


## Keep the outer hem of the map — bare grass past the last trunks — off screen.
const CAMERA_EDGE_INSET: float = 120.0


func _half_view() -> Vector2:
	var view := view_size
	if is_inside_tree():
		var vp := get_viewport().get_visible_rect().size
		if vp.x >= 64.0 and vp.y >= 64.0:
			view = vp
	return view * 0.5


func _camera_limit_rect() -> Rect2:
	## Inspector values on Camera2D (Limit). Defaults match the old inset around the play rect.
	if camera != null and camera.limit_right < 1000000 and camera.limit_bottom < 1000000:
		return Rect2(
			float(camera.limit_left),
			float(camera.limit_top),
			float(camera.limit_right - camera.limit_left),
			float(camera.limit_bottom - camera.limit_top)
		)
	return Rect2(
		CAMERA_EDGE_INSET,
		CAMERA_EDGE_INSET,
		play_size.x - CAMERA_EDGE_INSET * 2.0,
		play_size.y - CAMERA_EDGE_INSET * 2.0
	)


func camera_min() -> Vector2:
	return _camera_limit_rect().position + _half_view()


func camera_max() -> Vector2:
	var rect: Rect2 = _camera_limit_rect()
	return rect.position + rect.size - _half_view()


func _clamped_camera_pos(pos: Vector2) -> Vector2:
	var lo: Vector2 = camera_min()
	var hi: Vector2 = camera_max()
	if hi.x < lo.x:
		hi.x = lo.x
	if hi.y < lo.y:
		hi.y = lo.y
	return Vector2(clampf(pos.x, lo.x, hi.x), clampf(pos.y, lo.y, hi.y))


func _clamp_camera() -> void:
	if camera == null:
		return
	camera.position = _clamped_camera_pos(camera.position)


func pan_camera(delta: Vector2) -> void:
	if camera == null:
		return
	camera.position += delta
	_clamp_camera()


func _process(delta: float) -> void:
	if camera == null:
		return
	if world_input_blocked():
		return
	var dir := Vector2.ZERO
	if Input.is_action_pressed("ui_left"):
		dir.x -= 1.0
	if Input.is_action_pressed("ui_right"):
		dir.x += 1.0
	if Input.is_action_pressed("ui_up"):
		dir.y -= 1.0
	if Input.is_action_pressed("ui_down"):
		dir.y += 1.0
	if dir == Vector2.ZERO:
		return
	pan_camera(dir.normalized() * camera_pan_speed * delta)


func _apply_boot_intent() -> void:
	## Title sets continue / new / load. A direct main.tscn launch (verify) stays on auto.
	var intent: String = str(SaveService.boot_intent)
	var slot: int = int(SaveService.boot_slot)
	var kind: String = str(SaveService.boot_slot_kind)
	SaveService.boot_intent = "auto"
	SaveService.boot_slot = 0
	SaveService.boot_slot_kind = "manual"
	match intent:
		"forge_return":
			SaveService.note_session_started()
		"new":
			GameState.reset_for_new_game()
			SaveService.note_session_started()
		"continue":
			if SaveService.has_save():
				SaveService.load_game()
			SaveService.note_session_started()
		"load":
			if kind == "autosave" and SaveService.has_autosave(slot):
				SaveService.load_autosave(slot)
			elif slot >= 1 and SaveService.has_slot(slot):
				SaveService.load_game(slot)
			SaveService.note_session_started()
		_:
			if SaveService.has_save():
				SaveService.load_game()
			SaveService.note_session_started()


func _ellipse_norm(pos: Vector2) -> float:
	## 0 at the clearing center, 1 on the wobbling tree line. Not mirrored.
	var dx: float = (pos.x - clearing_center.x) / maxf(clearing_rx, 1.0)
	var dy: float = (pos.y - clearing_center.y) / maxf(clearing_ry, 1.0)
	var ang: float = atan2(dy, dx)
	var wobble: float = (
		0.075 * sin(ang * 3.0 + 0.55)
		+ 0.055 * sin(ang * 5.0 + 2.15)
		+ 0.040 * cos(ang * 2.0 + 0.35)
		+ 0.028 * sin(ang * 7.0 + 1.15)
	)
	var limit: float = maxf(0.72, 1.0 + wobble)
	return sqrt(dx * dx + dy * dy) / limit


func _in_clearing(pos: Vector2) -> bool:
	return _ellipse_norm(pos) < 1.0


func _build_grass() -> void:
	ground.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = load("res://assets/art/tiles/tileset_grass_64.png") as Texture2D
	atlas.texture_region_size = Vector2i(TILE, TILE)
	for x: int in range(4):
		for y: int in range(2):
			var coords := Vector2i(x, y)
			if not atlas.has_tile(coords):
				atlas.create_tile(coords)
	var src_id: int = ts.add_source(atlas, 0)
	ground.tile_set = ts
	## Calmer grass in the open glade; mixed tiles under the forest ring.
	for x: int in range(_cols):
		for y: int in range(_rows):
			var world_pt := Vector2(float(x * TILE + TILE / 2), float(y * TILE + TILE / 2))
			var pick: Vector2i
			if _in_clearing(world_pt):
				pick = ATLAS_GRASS[(x + y) % 2]
			else:
				pick = ATLAS_GRASS[(x * 3 + y * 5) % ATLAS_GRASS.size()]
			ground.set_cell(0, Vector2i(x, y), src_id, pick)


func _load_json_dict(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_warning("Main: missing %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		return parsed
	return {}


func decor_spot_allowed(pos: Vector2) -> bool:
	return _decor_clear(pos)


func _decor_clear(pos: Vector2) -> bool:
	for i: int in range(clear_points.size()):
		if pos.distance_to(clear_points[i]) < _decor_keep_radius(i):
			return false
	return true


func _decor_keep_radius(index: int) -> float:
	## Manatree uses the trunk/door footprint so the open middle can still hold tufts.
	if index == 0:
		return MANATREE_DECOR_RADIUS
	var need: float = _landmark_radius(index)
	if need < 100.0:
		need += 12.0
	return need


func _landmark_radius(index: int) -> float:
	if index >= 0 and index < clear_radii.size():
		return clear_radii[index]
	match index:
		0:
			return 200.0
		1:
			return 175.0
		2:
			return 140.0
		3:
			return 160.0
		_:
			return 80.0


func world_input_blocked() -> bool:
	if hud == null or pause_menu == null:
		return false
	if hud.care_panel.visible or hud.ascension_panel.visible or hud.welcome_panel.visible:
		return true
	if hud.fruit_confirm_panel.visible:
		return true
	if hud.has_method("is_backpack_open") and bool(hud.call("is_backpack_open")):
		return true
	if hud.has_method("is_bench_open") and bool(hud.call("is_bench_open")):
		return true
	if hud.has_method("is_character_open") and bool(hud.call("is_character_open")):
		return true
	if hud.has_method("is_forge_popup_open") and bool(hud.call("is_forge_popup_open")):
		return true
	if EchoPortal.is_fee_confirm_open():
		return true
	if EchoChamber.in_battle:
		return true
	return pause_menu.is_open()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and _drag_active:
		_update_marquee(get_global_mouse_position())
		return
	if not (event is InputEventMouseButton):
		return
	var mb: InputEventMouseButton = event
	if mb.button_index == MOUSE_BUTTON_LEFT:
		if mb.pressed:
			if world_input_blocked():
				return
			if _interactable_under_point(get_global_mouse_position()):
				return
			_drag_active = true
			_drag_from = get_global_mouse_position()
			_update_marquee(_drag_from)
		elif _drag_active:
			_finish_marquee(get_global_mouse_position())
		return
	if not mb.pressed or world_input_blocked():
		return
	if _interactable_under_point(get_global_mouse_position()):
		return
	if mb.button_index == MOUSE_BUTTON_RIGHT:
		handle_rmb_ground(get_global_mouse_position())


func handle_lmb_ground() -> void:
	## LMB empty ground → deselect.
	if GameState.clear_selection():
		GameState.status_message.emit(ContentStrings.get_text("keeper_deselect_toast"))


func handle_rmb_ground(world_pos: Vector2) -> void:
	if GameState.is_world_frozen():
		GameState.note_frozen_deny()
		return
	## RMB empty ground: unassign every selected wisp, and walk the Keeper if he is selected.
	var ids: Array[int] = GameState.selected_wisp_list()
	var unassigned: bool = false
	for wid: int in ids:
		if GameState.unassign_wisp(wid):
			unassigned = true
	if unassigned:
		GameState.status_message.emit(ContentStrings.get_text("wisp_unassign_ok"))
	if GameState.keeper_selected:
		keeper.move_to(world_pos, null)
		return
	if ids.is_empty():
		GameState.status_message.emit(ContentStrings.get_text("keeper_required"))


func focus_selection() -> void:
	if camera == null:
		return
	camera.position = _clamped_camera_pos(_selection_focus_point())


func _selection_focus_point() -> Vector2:
	if GameState.keeper_selected and keeper:
		return keeper.global_position
	var ids: Array[int] = GameState.selected_wisp_list()
	if not ids.is_empty():
		for node: Node in get_tree().get_nodes_in_group("wisp"):
			if node is Node2D and int(node.get("wisp_id")) == ids[0]:
				return (node as Node2D).global_position
	if str(GameState.selected_companion_id) != "":
		var companion_id: String = str(GameState.selected_companion_id)
		for node: Node in get_tree().get_nodes_in_group("companion"):
			if node is Node2D and str(node.get("companion_id")) == companion_id:
				return (node as Node2D).global_position
		if camera:
			return camera.position
	return keeper.global_position if keeper else Vector2.ZERO


func _ensure_marquee() -> Line2D:
	if _marquee == null:
		_marquee = Line2D.new()
		_marquee.name = "Marquee"
		_marquee.width = 2.0
		_marquee.default_color = Color(0.85, 0.98, 0.7, 0.9)
		_marquee.z_index = 20
		_marquee.visible = false
		add_child(_marquee)
	return _marquee


func _update_marquee(world_pos: Vector2) -> void:
	var box: Line2D = _ensure_marquee()
	if _drag_from.distance_to(world_pos) < CLICK_SLOP:
		box.visible = false
		return
	var a: Vector2 = _drag_from
	var b: Vector2 = world_pos
	box.visible = true
	box.points = PackedVector2Array([
		a, Vector2(b.x, a.y), b, Vector2(a.x, b.y), a,
	])


func _finish_marquee(world_pos: Vector2) -> void:
	_drag_active = false
	if _marquee:
		_marquee.visible = false
	if _drag_from.distance_to(world_pos) < CLICK_SLOP:
		handle_lmb_ground()
		return
	var rect := Rect2(_drag_from, Vector2.ZERO)
	rect = rect.expand(world_pos)
	var ids: Array[int] = []
	for node: Node in get_tree().get_nodes_in_group("wisp"):
		if not (node is Node2D) or not node.visible:
			continue
		if rect.has_point((node as Node2D).global_position):
			ids.append(int(node.get("wisp_id")))
	var keeper_in: bool = keeper != null and rect.has_point(keeper.global_position)
	if ids.is_empty() and not keeper_in:
		GameState.clear_selection()
		return
	GameState.select_group(ids, keeper_in)


func _interactable_under_point(world_pos: Vector2) -> bool:
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	if space == null:
		return false
	var q := PhysicsPointQueryParameters2D.new()
	q.position = world_pos
	q.collide_with_areas = true
	q.collide_with_bodies = false
	q.collision_mask = INTERACT_PICK_MASK
	var hits: Array[Dictionary] = space.intersect_point(q, 32)
	for hit: Dictionary in hits:
		var collider: Variant = hit.get("collider")
		if collider is Node and (collider as Node).is_in_group("interactable"):
			return true
	return false


func _on_fruit_menu() -> void:
	if GameState.fruit_harvested_pending_ascend:
		hud.show_ascension_shop()
	else:
		hud.show_care_menu()


func _on_care_menu() -> void:
	hud.show_care_menu()


func _sync_wisps() -> void:
	## Spawn / free wisp orbs to match GameState.wisp_count.
	var want: int = GameState.wisp_count
	# Free extras
	var existing: Array = _wisp_nodes.keys()
	for kid: Variant in existing:
		var id: int = int(kid)
		if id >= want:
			var node: Node = _wisp_nodes[id]
			_wisp_nodes.erase(id)
			if is_instance_valid(node):
				node.queue_free()
	for i: int in range(want):
		if _wisp_nodes.has(i) and is_instance_valid(_wisp_nodes[i]):
			continue
		var orb: Node = WISP_SCENE.instantiate()
		if orb.has_method("setup"):
			orb.call("setup", i)
		world.add_child(orb)
		if orb.has_signal("wisp_clicked"):
			orb.connect("wisp_clicked", _on_wisp_clicked)
		_wisp_nodes[i] = orb


func _on_wisp_clicked(wisp_id: int) -> void:
	## LMB wisp select does NOT require Keeper selected (SYSTEMS v0.3.2).
	GameState.select_wisp(wisp_id)
	if GameState.selected_wisp_id == wisp_id:
		GameState.status_message.emit("%s  ·  %s  ·  %s" % [
			ContentStrings.get_text("wisp_orbit_hint"),
			ContentStrings.get_text("wisp_assign_hint"),
			ContentStrings.get_text("wisp_node_shared_hint"),
		])
