extends Node2D
## Forest hub 1280×720: RTS LMB select / RMB command, wisps orbit assigned targets (SYSTEMS v0.3.2).

@onready var keeper: Keeper = $World/Keeper
@onready var manatree: Manatree = $World/Manatree
@onready var hud: GameHUD = $HUD
@onready var ground: TileMap = $Ground
@onready var click_layer: ColorRect = $ClickLayer
@onready var world: Node2D = $World
@onready var pause_menu: PauseMenu = $PauseMenu

const TILE: int = 64
const COLS: int = 20
const ROWS: int = 12
## Match Area2D collision_layer on gatherable / manatree scenes.
const INTERACT_PICK_MASK: int = 4

const ATLAS_GRASS: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)
]
const ATLAS_PATH_H := Vector2i(0, 1)
const ATLAS_PATH_V := Vector2i(1, 1)
const ATLAS_PATH_CROSS := Vector2i(2, 1)

## Keep clear of Manatree stand, three harvest nodes, keeper spawn.
const CLEAR_POINTS: Array[Vector2] = [
	Vector2(640, 420),
	Vector2(200, 560),
	Vector2(400, 580),
	Vector2(900, 560),
	Vector2(480, 520),
]
## Larger open glade — variable-size Haex canopies stay on the ring, not the hub.
const GLADE := Rect2(175, 185, 930, 500)
const TREES_META_PATH: String = "res://assets/art/trees/trees_meta.json"
const BUSHES_META_PATH: String = "res://assets/art/bushes/bushes_meta.json"

const WISP_SCENE: PackedScene = preload("res://scenes/wisp.tscn")
var _wisp_nodes: Dictionary = {}  # wisp_id int → WispOrb


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_build_grass()
	_spawn_forest_props()
	# Pass clicks through so Area2D harvest / Manatree can receive them.
	click_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_viewport().physics_object_picking = true
	manatree.fruit_menu_requested.connect(_on_fruit_menu)
	manatree.care_menu_requested.connect(_on_care_menu)
	hud.bind_manatree(manatree)
	hud.bind_pause_menu(pause_menu)
	GameAudio.play_hub_music()
	GameState.wisps_changed.connect(_sync_wisps)
	GameState.load_completed.connect(_sync_wisps)
	if SaveService.has_save():
		SaveService.load_game()
	_sync_wisps()
	# First load / new save: show Keeper welcome once (flag in save).
	hud.maybe_show_welcome()


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
	for x: int in range(COLS):
		for y: int in range(ROWS):
			var world_pt := Vector2(float(x * TILE + TILE / 2), float(y * TILE + TILE / 2))
			var pick: Vector2i
			if GLADE.has_point(world_pt):
				pick = ATLAS_GRASS[(x + y) % 2]
			else:
				pick = ATLAS_GRASS[(x * 3 + y * 5) % ATLAS_GRASS.size()]
			ground.set_cell(0, Vector2i(x, y), src_id, pick)
	var mid_x: int = 10
	var mid_y: int = 6
	## Wider hub path so the clearing reads as a glade, not a trail.
	for x: int in range(2, 18):
		ground.set_cell(0, Vector2i(x, mid_y), src_id, ATLAS_PATH_H)
	for y: int in range(3, 11):
		ground.set_cell(0, Vector2i(mid_x, y), src_id, ATLAS_PATH_V)
	ground.set_cell(0, Vector2i(mid_x, mid_y), src_id, ATLAS_PATH_CROSS)
	for x: int in range(2, 8):
		ground.set_cell(0, Vector2i(x, 8), src_id, ATLAS_PATH_H)
	for x: int in range(13, 18):
		ground.set_cell(0, Vector2i(x, 8), src_id, ATLAS_PATH_H)
	for x: int in range(8, 13):
		for y: int in range(5, 8):
			if abs(x - mid_x) + abs(y - mid_y) <= 3:
				ground.set_cell(0, Vector2i(x, y), src_id, ATLAS_PATH_CROSS if x == mid_x or y == mid_y else ATLAS_PATH_H)


func _spawn_forest_props() -> void:
	## Dense Y-sorted decorative ring around a larger open glade. Not harvestable.
	var trees_meta: Dictionary = _load_json_dict(TREES_META_PATH)
	var bushes_meta: Dictionary = _load_json_dict(BUSHES_META_PATH)
	var tree_items: Dictionary = trees_meta.get("items", {}) as Dictionary
	var bush_items: Dictionary = bushes_meta.get("items", {}) as Dictionary
	var tree_ids: Array = (trees_meta.get("spawn_catalog", {}) as Dictionary).get("tree", []) as Array
	var bush_cat: Dictionary = bushes_meta.get("spawn_catalog", {}) as Dictionary
	var tree_entries: Array[Dictionary] = _catalog_entries(tree_items, tree_ids, "res://assets/art/trees/")
	## Some bushes — big ring shrubs plus a handful of small ones, not the full 57.
	var bush_ids: Array = bush_cat.get("bush", []) as Array
	var tuft_ids: Array = bush_cat.get("tuft", []) as Array
	var bush_pick: Array = []
	for idv: Variant in bush_ids:
		var bid: String = str(idv)
		if bid.begins_with("bush_big_") or bush_pick.size() < 28:
			bush_pick.append(bid)
	var bush_entries: Array[Dictionary] = _catalog_entries(bush_items, bush_pick, "res://assets/art/bushes/")
	var tuft_entries: Array[Dictionary] = _catalog_entries(bush_items, tuft_ids, "res://assets/art/bushes/")
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260917
	var occupied: Array[Vector2] = []
	## Overlapping ~400px canopies on the outer ring; one column per side so the glade stays open.
	## No tall trees along the bottom — canopies hang upward and would swallow harvest nodes.
	_scatter_grid(rng, tree_entries, occupied, 12, 2, Rect2(20, 48, 1240, 120), 62.0, 16.0, 0.0)
	_scatter_grid(rng, tree_entries, occupied, 1, 6, Rect2(18, 150, 70, 280), 58.0, 12.0, 0.0)
	_scatter_grid(rng, tree_entries, occupied, 1, 6, Rect2(1192, 150, 70, 280), 58.0, 12.0, 0.0)
	## Inner-edge bushes (may sit a little into the glade). Bottom uses bushes only.
	_scatter_grid(rng, bush_entries, occupied, 10, 1, Rect2(80, 175, 1120, 32), 40.0, 10.0, 22.0)
	_scatter_grid(rng, bush_entries, occupied, 1, 7, Rect2(140, 200, 40, 430), 36.0, 8.0, 22.0)
	_scatter_grid(rng, bush_entries, occupied, 1, 7, Rect2(1100, 200, 40, 430), 36.0, 8.0, 22.0)
	_scatter_grid(rng, bush_entries, occupied, 10, 1, Rect2(40, 685, 240, 24), 34.0, 8.0, 18.0)
	_scatter_grid(rng, bush_entries, occupied, 10, 1, Rect2(1000, 685, 240, 24), 34.0, 8.0, 18.0)
	_scatter_grid(rng, bush_entries, occupied, 8, 1, Rect2(300, 690, 680, 22), 36.0, 8.0, 18.0)
	_scatter_grid(rng, tuft_entries, occupied, 8, 1, Rect2(220, 195, 840, 24), 26.0, 8.0, 32.0)


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


func _catalog_entries(items: Dictionary, ids: Array, base_dir: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for idv: Variant in ids:
		var id: String = str(idv)
		if not items.has(id):
			continue
		var it: Dictionary = items[id]
		var file: String = str(it.get("file", ""))
		if file.is_empty():
			continue
		var path: String = file
		if not path.begins_with("res://"):
			path = base_dir + file
		var sz := Vector2(64, 64)
		var sz_v: Variant = it.get("size", [])
		if typeof(sz_v) == TYPE_ARRAY and (sz_v as Array).size() >= 2:
			sz = Vector2(float((sz_v as Array)[0]), float((sz_v as Array)[1]))
		out.append({"tex": path, "size": sz, "id": id})
	return out


func _scatter_grid(
	rng: RandomNumberGenerator,
	entries: Array[Dictionary],
	occupied: Array[Vector2],
	cols: int,
	rows: int,
	rect: Rect2,
	min_sep: float,
	jitter: float,
	glade_inset: float
) -> void:
	if entries.is_empty() or cols <= 0 or rows <= 0:
		return
	var n: int = occupied.size()
	for row: int in range(rows):
		for col: int in range(cols):
			var u: float = (float(col) + 0.5) / float(cols)
			var v: float = (float(row) + 0.5) / float(rows)
			var pos := Vector2(
				rect.position.x + u * rect.size.x + rng.randf_range(-jitter, jitter),
				rect.position.y + v * rect.size.y + rng.randf_range(-jitter, jitter)
			)
			pos.x = clampf(pos.x, 10.0, 1270.0)
			pos.y = clampf(pos.y, 36.0, 716.0)
			if not _can_plant(pos, occupied, min_sep, glade_inset):
				continue
			_plant_prop(entries[n % entries.size()], pos)
			occupied.append(pos)
			n += 1


func _plant_prop(entry: Dictionary, pos: Vector2) -> void:
	var spr := Sprite2D.new()
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.centered = false
	var tex: Texture2D = load(str(entry["tex"])) as Texture2D
	spr.texture = tex
	var sz: Vector2 = entry["size"]
	if tex != null:
		sz = Vector2(float(tex.get_width()), float(tex.get_height()))
	spr.offset = Vector2(-sz.x * 0.5, -sz.y)
	spr.position = pos
	spr.y_sort_enabled = true
	spr.z_index = 0
	spr.add_to_group("forest_prop")
	world.add_child(spr)


func _can_plant(pos: Vector2, occupied: Array[Vector2], min_sep: float, glade_inset: float) -> bool:
	var glade: Rect2 = GLADE.grow(-glade_inset)
	if glade.has_point(pos):
		return false
	if not _clear_of_landmarks(pos, 0.0):
		return false
	for other: Vector2 in occupied:
		if pos.distance_to(other) < min_sep:
			return false
	return true


func _landmark_radius(index: int) -> float:
	## Manatree needs extra room as stages grow; harvest nodes stay clickable.
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


func _clear_of_landmarks(pos: Vector2, min_dist: float) -> bool:
	for i: int in range(CLEAR_POINTS.size()):
		var need: float = min_dist if min_dist > 0.0 else _landmark_radius(i)
		if pos.distance_to(CLEAR_POINTS[i]) < need:
			return false
	return true


func world_input_blocked() -> bool:
	if hud == null or pause_menu == null:
		return false
	if hud.care_panel.visible or hud.ascension_panel.visible or hud.welcome_panel.visible:
		return true
	if hud.fruit_confirm_panel.visible:
		return true
	return pause_menu.is_open()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb: InputEventMouseButton = event
	if not mb.pressed:
		return
	if world_input_blocked():
		return
	# Belt-and-suspenders: skip if an interactable Area2D is under the cursor.
	if _interactable_under_point(get_global_mouse_position()):
		return
	if mb.button_index == MOUSE_BUTTON_LEFT:
		handle_lmb_ground()
		return
	if mb.button_index == MOUSE_BUTTON_RIGHT:
		handle_rmb_ground(get_global_mouse_position())


func handle_lmb_ground() -> void:
	## LMB empty ground → deselect.
	if GameState.clear_selection():
		GameState.status_message.emit(ContentStrings.get_text("keeper_deselect_toast"))


func handle_rmb_ground(world_pos: Vector2) -> void:
	## RMB empty ground: unassign selected wisp, or walk selected Keeper.
	if GameState.selected_wisp_id >= 0:
		var wid: int = GameState.selected_wisp_id
		if GameState.unassign_wisp(wid):
			GameState.status_message.emit(ContentStrings.get_text("wisp_unassign_ok"))
		return
	if GameState.keeper_selected:
		keeper.move_to(world_pos, null)
		return
	GameState.status_message.emit(ContentStrings.get_text("keeper_required"))


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
