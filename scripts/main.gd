extends Node2D
## Forest hub 2560×2160 (2× × 3× of 1280×720): arrow-key camera, RTS LMB/RMB, wisps.

@onready var keeper: Keeper = $World/Keeper
@onready var manatree: Manatree = $World/Manatree
@onready var hud: GameHUD = $HUD
@onready var ground: TileMap = $Ground
@onready var click_layer: ColorRect = $ClickLayer
@onready var world: Node2D = $World
@onready var pause_menu: PauseMenu = $PauseMenu
@onready var camera: Camera2D = $Camera2D

const TILE: int = 64
## Match Area2D collision_layer on gatherable / manatree scenes.
const INTERACT_PICK_MASK: int = 4
const HUB_MAP_PATH: String = "res://data/hub_map.json"
const TREES_META_PATH: String = "res://assets/art/trees/trees_meta.json"
const BUSHES_META_PATH: String = "res://assets/art/bushes/bushes_meta.json"

const ATLAS_GRASS: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)
]
const ATLAS_PATH_H := Vector2i(0, 1)
const ATLAS_PATH_V := Vector2i(1, 1)
const ATLAS_PATH_CROSS := Vector2i(2, 1)

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
var scatter_seed: int = 20260924
const DECOR_META_PATH: String = "res://assets/art/decor/decor_meta.json"
var clear_points: Array[Vector2] = []
var clear_radii: Array[float] = []
var collision_cfg: Dictionary = {}
var _cols: int = 40
var _rows: int = 34


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("main_root")
	_load_hub_map()
	_apply_landmarks()
	_spawn_runestones()
	_spawn_echo_portal()
	_setup_camera()
	_build_grass()
	_spawn_forest_props()
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
	_apply_boot_intent()
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
	scatter_seed = int(hub_map.get("scatter_seed", scatter_seed))
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
	collision_cfg = hub_map.get("collision", {}) as Dictionary
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
	portal.position = _vec2_from(marks.get("echo_portal", [1560, 820]))
	world.add_child(portal)


func _setup_camera() -> void:
	if camera == null:
		camera = Camera2D.new()
		camera.name = "Camera2D"
		add_child(camera)
	camera.enabled = true
	camera.make_current()
	camera.position_smoothing_enabled = false
	var start: Vector2 = _vec2_from((hub_map.get("landmarks", {}) as Dictionary).get("manatree", [1280, 1000]))
	camera.position = start
	_clamp_camera()


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


func camera_min() -> Vector2:
	return _half_view() + Vector2(CAMERA_EDGE_INSET, CAMERA_EDGE_INSET)


func camera_max() -> Vector2:
	return play_size - _half_view() - Vector2(CAMERA_EDGE_INSET, CAMERA_EDGE_INSET)


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
	SaveService.boot_intent = "auto"
	SaveService.boot_slot = 0
	match intent:
		"new":
			GameState.reset_for_new_game()
		"continue":
			if SaveService.has_save():
				SaveService.load_game()
		"load":
			if slot >= 1 and SaveService.has_slot(slot):
				SaveService.load_game(slot)
		_:
			if SaveService.has_save():
				SaveService.load_game()


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
	var mid_x: int = int(floor(play_size.x / float(TILE) * 0.5))
	var mid_y: int = int(floor((glade.position.y + glade.size.y * 0.55) / float(TILE)))
	var path_left: int = maxi(4, int(floor(glade.position.x / float(TILE))) + 1)
	var path_right: int = mini(_cols - 4, int(floor((glade.position.x + glade.size.x) / float(TILE))) - 1)
	var path_top: int = maxi(4, int(floor(glade.position.y / float(TILE))) + 2)
	var path_bot: int = mini(_rows - 3, int(floor((glade.position.y + glade.size.y) / float(TILE))) - 2)
	for x: int in range(path_left, path_right + 1):
		ground.set_cell(0, Vector2i(x, mid_y), src_id, ATLAS_PATH_H)
	for y: int in range(path_top, path_bot + 1):
		ground.set_cell(0, Vector2i(mid_x, y), src_id, ATLAS_PATH_V)
	ground.set_cell(0, Vector2i(mid_x, mid_y), src_id, ATLAS_PATH_CROSS)
	var arm_y: int = mid_y + 3
	for x: int in range(path_left, mid_x - 2):
		ground.set_cell(0, Vector2i(x, arm_y), src_id, ATLAS_PATH_H)
	for x: int in range(mid_x + 3, path_right + 1):
		ground.set_cell(0, Vector2i(x, arm_y), src_id, ATLAS_PATH_H)


func _spawn_forest_props() -> void:
	## Dense Y-sorted decorative ring around a larger open glade. Not harvestable.
	var trees_meta: Dictionary = _load_json_dict(TREES_META_PATH)
	var bushes_meta: Dictionary = _load_json_dict(BUSHES_META_PATH)
	var tree_items: Dictionary = trees_meta.get("items", {}) as Dictionary
	var bush_items: Dictionary = bushes_meta.get("items", {}) as Dictionary
	var tree_ids: Array = (trees_meta.get("spawn_catalog", {}) as Dictionary).get("tree", []) as Array
	var bush_cat: Dictionary = bushes_meta.get("spawn_catalog", {}) as Dictionary
	var tree_entries: Array[Dictionary] = _catalog_entries(tree_items, tree_ids, "res://assets/art/trees/")
	var bush_ids: Array = bush_cat.get("bush", []) as Array
	var tuft_ids: Array = bush_cat.get("tuft", []) as Array
	var bush_pick: Array = []
	for idv: Variant in bush_ids:
		var bid: String = str(idv)
		if bid.begins_with("bush_big_") or bid.begins_with("bush_native_") or bush_pick.size() < 36:
			bush_pick.append(bid)
	var bush_entries: Array[Dictionary] = _catalog_entries(bush_items, bush_pick, "res://assets/art/bushes/")
	var tuft_entries: Array[Dictionary] = _catalog_entries(bush_items, tuft_ids, "res://assets/art/bushes/")
	var rng := RandomNumberGenerator.new()
	rng.seed = scatter_seed
	var occupied: Array[Vector2] = []
	var bands: Array = hub_map.get("scatter", []) as Array
	if bands.is_empty():
		_scatter_grid(rng, tree_entries, occupied, "tree", 22, 4, Rect2(24, 36, 2512, 300), 56.0, 16.0, 0.0)
		_scatter_grid(rng, tree_entries, occupied, "tree", 22, 3, Rect2(24, 1820, 2512, 320), 56.0, 16.0, 0.0)
		_scatter_grid(rng, tree_entries, occupied, "tree", 3, 14, Rect2(16, 320, 320, 1500), 54.0, 14.0, 0.0)
		_scatter_grid(rng, tree_entries, occupied, "tree", 3, 14, Rect2(2224, 320, 320, 1500), 54.0, 14.0, 0.0)
		_scatter_grid(rng, bush_entries, occupied, "bush", 18, 2, Rect2(280, 300, 2000, 70), 38.0, 10.0, 18.0)
		_scatter_grid(rng, bush_entries, occupied, "bush", 18, 2, Rect2(280, 1780, 2000, 70), 36.0, 10.0, 18.0)
		_scatter_grid(rng, tuft_entries, occupied, "tuft", 16, 1, Rect2(420, 340, 1720, 36), 24.0, 8.0, 28.0)
		_seal_clearing_edge(rng, bush_entries, occupied)
		_fill_outer_forest(tree_entries, bush_entries, occupied)
		_spawn_ground_decor(rng, occupied)
		return
	for band_v: Variant in bands:
		if typeof(band_v) != TYPE_DICTIONARY:
			continue
		var band: Dictionary = band_v
		var kind: String = str(band.get("kind", "tree"))
		var entries: Array[Dictionary] = tree_entries
		if kind == "bush":
			entries = bush_entries
		elif kind == "tuft":
			entries = tuft_entries
		var rect_v: Variant = band.get("rect", [0, 0, 64, 64])
		var rect := Rect2(0, 0, 64, 64)
		if typeof(rect_v) == TYPE_ARRAY and (rect_v as Array).size() >= 4:
			var ra: Array = rect_v
			rect = Rect2(float(ra[0]), float(ra[1]), float(ra[2]), float(ra[3]))
		_scatter_grid(
			rng,
			entries,
			occupied,
			kind,
			int(band.get("cols", 1)),
			int(band.get("rows", 1)),
			rect,
			float(band.get("min_sep", 40.0)),
			float(band.get("jitter", 8.0)),
			float(band.get("glade_inset", 0.0))
		)
	_seal_clearing_edge(rng, bush_entries, occupied)
	_fill_outer_forest(tree_entries, bush_entries, occupied)
	_spawn_ground_decor(rng, occupied)


func _point_on_clearing(ang: float, target_norm: float) -> Vector2:
	var lo: float = 0.0
	var hi: float = maxf(play_size.x, play_size.y)
	var pos: Vector2 = clearing_center
	for _i: int in range(18):
		var mid: float = (lo + hi) * 0.5
		pos = clearing_center + Vector2(cos(ang), sin(ang)) * mid
		if _ellipse_norm(pos) < target_norm:
			lo = mid
		else:
			hi = mid
	return pos


func _fill_outer_forest(tree_entries: Array[Dictionary], bush_entries: Array[Dictionary], occupied: Array[Vector2]) -> void:
	## Visual canopy past the walk wall, out to the play edge the camera can see.
	## No extra colliders — the bush seal stays the wall.
	if tree_entries.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = scatter_seed + 91
	var n: int = 0
	var step: float = 108.0
	var y: float = 36.0
	var row_i: int = 0
	while y < play_size.y + 48.0:
		var x: float = 24.0
		if row_i % 2 == 1:
			x += step * 0.5
		while x < play_size.x + 48.0:
			var pos := Vector2(x, y)
			pos += Vector2(rng.randf_range(-14.0, 14.0), rng.randf_range(-12.0, 12.0))
			pos.x = clampf(pos.x, 12.0, play_size.x + 24.0)
			pos.y = clampf(pos.y, 28.0, play_size.y + 36.0)
			if _ellipse_norm(pos) >= 1.02 and _skirt_clear(pos, occupied, 72.0):
				var entry: Dictionary = tree_entries[n % tree_entries.size()].duplicate()
				entry["visual_only"] = true
				_plant_prop(entry, pos, "tree")
				occupied.append(pos)
				n += 1
			x += step
		y += step * 0.92
		row_i += 1
	if bush_entries.is_empty():
		return
	var bn: int = 0
	var bstep: float = 54.0
	y = 20.0
	row_i = 0
	while y < play_size.y + 28.0:
		var x: float = 16.0
		if row_i % 2 == 1:
			x += bstep * 0.5
		while x < play_size.x + 28.0:
			var pos := Vector2(x, y)
			pos += Vector2(rng.randf_range(-8.0, 8.0), rng.randf_range(-6.0, 6.0))
			pos.x = clampf(pos.x, 8.0, play_size.x + 16.0)
			pos.y = clampf(pos.y, 16.0, play_size.y + 20.0)
			var norm: float = _ellipse_norm(pos)
			var hem: bool = pos.x < 360.0 or pos.y < 280.0 or pos.x > play_size.x - 360.0 or pos.y > play_size.y - 340.0
			if norm >= 1.06 and hem and _skirt_clear(pos, occupied, 34.0):
				var entry: Dictionary = bush_entries[bn % bush_entries.size()].duplicate()
				entry["visual_only"] = true
				_plant_prop(entry, pos, "bush")
				occupied.append(pos)
				bn += 1
			x += bstep
		y += bstep
		row_i += 1


func _skirt_clear(pos: Vector2, occupied: Array[Vector2], min_sep: float) -> bool:
	if not _clear_of_landmarks(pos, 0.0):
		return false
	for other: Vector2 in occupied:
		if pos.distance_to(other) < min_sep:
			return false
	return true


func _seal_clearing_edge(rng: RandomNumberGenerator, bush_entries: Array[Dictionary], occupied: Array[Vector2]) -> void:
	## Two staggered bush rings just outside the wobbling tree line.
	## Spacing overlaps the bush colliders so the Keeper cannot walk out.
	if bush_entries.is_empty():
		return
	var targets: Array[float] = [1.025, 1.11]
	var n: int = 0
	for ring: int in range(targets.size()):
		var sample: Vector2 = _point_on_clearing(0.2, targets[ring])
		var radius: float = maxf(sample.distance_to(clearing_center), 400.0)
		var count: int = maxi(64, int(ceil(TAU * radius / 24.0)))
		var phase: float = 0.0 if ring == 0 else PI / float(count)
		for i: int in range(count):
			var ang: float = TAU * float(i) / float(count) + phase
			var pos: Vector2 = _point_on_clearing(ang, targets[ring])
			pos += Vector2(rng.randf_range(-3.0, 3.0), rng.randf_range(-2.0, 2.0))
			pos.x = clampf(pos.x, 20.0, play_size.x - 20.0)
			pos.y = clampf(pos.y, 20.0, play_size.y - 20.0)
			if _ellipse_norm(pos) < 1.0:
				continue
			if not _clear_of_landmarks(pos, 0.0):
				continue
			var crowded: bool = false
			for other: Vector2 in occupied:
				if pos.distance_to(other) < 14.0:
					crowded = true
					break
			if crowded:
				continue
			var entry: Dictionary = bush_entries[n % bush_entries.size()].duplicate()
			entry["seal"] = true
			_plant_prop(entry, pos, "bush")
			occupied.append(pos)
			n += 1


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
		var scale_v: float = float(it.get("scale", 1.0))
		out.append({"tex": path, "size": sz, "id": id, "scale": scale_v})
	return out


func _scatter_grid(
	rng: RandomNumberGenerator,
	entries: Array[Dictionary],
	occupied: Array[Vector2],
	kind: String,
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
			pos.x = clampf(pos.x, 16.0, play_size.x - 16.0)
			pos.y = clampf(pos.y, 40.0, play_size.y - 16.0)
			if not _can_plant(pos, occupied, min_sep, glade_inset):
				continue
			_plant_prop(entries[n % entries.size()], pos, kind)
			occupied.append(pos)
			n += 1


func _plant_prop(entry: Dictionary, pos: Vector2, kind: String = "tree") -> void:
	## Y-sorted visual at the foot; collision only on the trunk/base, never the canopy.
	var root := Node2D.new()
	root.position = pos
	root.y_sort_enabled = true
	root.z_index = 0
	root.add_to_group("forest_prop")
	root.set_meta("prop_kind", kind)
	var spr := Sprite2D.new()
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.centered = false
	var tex: Texture2D = load(str(entry["tex"])) as Texture2D
	spr.texture = tex
	var sz: Vector2 = entry["size"]
	if tex != null:
		sz = Vector2(float(tex.get_width()), float(tex.get_height()))
	spr.offset = Vector2(-sz.x * 0.5, -sz.y)
	var spr_scale: float = float(entry.get("scale", 1.0))
	if spr_scale <= 0.0:
		spr_scale = 1.0
	spr.scale = Vector2(spr_scale, spr_scale)
	spr.y_sort_enabled = true
	root.add_child(spr)
	if kind == "decor" or bool(entry.get("visual_only", false)):
		if kind == "decor":
			root.add_to_group("forest_decor")
			spr.modulate = Color(1.15, 1.22, 1.06, 1.0)
		else:
			root.add_to_group("forest_fill")
		world.add_child(root)
		return
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.add_to_group("forest_collision")
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	var col_size: Vector2
	var col_off: Vector2
	if kind == "tree":
		var trunk_h: float = maxf(18.0, sz.y * float(collision_cfg.get("tree_trunk_height_frac", 0.30)))
		var col_h: float = maxf(8.0, trunk_h * float(collision_cfg.get("tree_collider_of_trunk_frac", 0.333)))
		var col_w: float = clampf(
			sz.x * float(collision_cfg.get("tree_width_frac", 0.16)),
			float(collision_cfg.get("tree_width_min", 14)),
			float(collision_cfg.get("tree_width_max", 36))
		)
		col_size = Vector2(col_w, col_h)
		col_off = Vector2(0.0, -col_h * 0.5)
	else:
		if bool(entry.get("seal", false)):
			col_size = Vector2(32.0, 24.0)
		else:
			col_size = Vector2(
				float(collision_cfg.get("bush_width", 16)),
				float(collision_cfg.get("bush_height", 10))
			)
		col_off = Vector2(0.0, -col_size.y * 0.5)
	shape.size = col_size
	col.shape = shape
	col.position = col_off
	body.add_child(col)
	root.add_child(body)
	root.set_meta("collider_size", col_size)
	world.add_child(root)


func _can_plant(pos: Vector2, occupied: Array[Vector2], min_sep: float, glade_inset: float) -> bool:
	## glade_inset lets bushes tuck a few pixels into the wobbling tree line.
	var allow: float = glade_inset / maxf((clearing_rx + clearing_ry) * 0.5, 1.0)
	if _ellipse_norm(pos) < 1.0 - allow:
		return false
	if not _clear_of_landmarks(pos, 0.0):
		return false
	for other: Vector2 in occupied:
		if pos.distance_to(other) < min_sep:
			return false
	return true


func _spawn_ground_decor(rng: RandomNumberGenerator, occupied: Array[Vector2]) -> void:
	## Grass, ferns, flowers, twigs, and a few loose stones. No collision, not clickable.
	var meta: Dictionary = _load_json_dict(DECOR_META_PATH)
	var items: Array = meta.get("items", []) as Array
	var flora: Array[Dictionary] = []
	var stones: Array[Dictionary] = []
	for entry_v: Variant in items:
		if typeof(entry_v) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = entry_v
		var file: String = str(d.get("file", ""))
		if file == "":
			continue
		var rec: Dictionary = {
			"tex": "res://assets/art/decor/%s" % file,
			"size": Vector2(32, 32),
			"id": str(d.get("id", "")),
			"scale": 2.0,
		}
		if str(d.get("kind", "")) == "stone":
			stones.append(rec)
		else:
			flora.append(rec)
	if flora.is_empty():
		return
	var cols: int = 52
	var rows: int = 44
	var n: int = 0
	for row: int in range(rows):
		for col: int in range(cols):
			var pos := Vector2(
				(float(col) + 0.5) / float(cols) * play_size.x + rng.randf_range(-22.0, 22.0),
				(float(row) + 0.5) / float(rows) * play_size.y + rng.randf_range(-16.0, 16.0)
			)
			pos.x = clampf(pos.x, 24.0, play_size.x - 24.0)
			pos.y = clampf(pos.y, 24.0, play_size.y - 24.0)
			var norm: float = _ellipse_norm(pos)
			if norm >= 0.96:
				continue
			var keep: float = 0.10 + norm * 0.78
			if norm < 0.30:
				keep = 0.16
			if rng.randf() > keep:
				continue
			if not _decor_clear(pos):
				continue
			var blocked: bool = false
			for other: Vector2 in occupied:
				if pos.distance_to(other) < 36.0:
					blocked = true
					break
			if blocked:
				continue
			var use_stone: bool = not stones.is_empty() and norm > 0.62 and rng.randf() < 0.12
			var pool: Array[Dictionary] = stones if use_stone else flora
			_plant_prop(pool[n % pool.size()], pos, "decor")
			occupied.append(pos)
			n += 1


func _decor_clear(pos: Vector2) -> bool:
	for i: int in range(clear_points.size()):
		var need: float = _landmark_radius(i)
		if i == 0:
			need = maxf(need, 400.0)
		elif need < 100.0:
			need += 12.0
		if pos.distance_to(clear_points[i]) < need:
			return false
	return true


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


func _clear_of_landmarks(pos: Vector2, min_dist: float) -> bool:
	for i: int in range(clear_points.size()):
		var need: float = min_dist if min_dist > 0.0 else _landmark_radius(i)
		if pos.distance_to(clear_points[i]) < need:
			return false
	return true


func world_input_blocked() -> bool:
	if hud == null or pause_menu == null:
		return false
	if hud.care_panel.visible or hud.ascension_panel.visible or hud.welcome_panel.visible:
		return true
	if hud.fruit_confirm_panel.visible:
		return true
	if hud.has_method("is_backpack_open") and bool(hud.call("is_backpack_open")):
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
