extends Node2D
## Forest hub 1280×720: grass tiles, dense deco trees, 3 harvest channels, Manatree water channel.

@onready var keeper: Keeper = $World/Keeper
@onready var manatree: Manatree = $World/Manatree
@onready var hud: GameHUD = $HUD
@onready var ground: TileMap = $Ground
@onready var click_layer: ColorRect = $ClickLayer
@onready var world: Node2D = $World

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


func _ready() -> void:
	_build_grass()
	_spawn_forest_props()
	# Pass clicks through so Area2D harvest / Manatree can receive them.
	click_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_viewport().physics_object_picking = true
	manatree.fruit_menu_requested.connect(_on_fruit_menu)
	manatree.care_menu_requested.connect(_on_care_menu)
	hud.bind_manatree(manatree)
	GameAudio.play_hub_music()
	if SaveService.has_save():
		SaveService.load_game()


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
	for x: int in range(COLS):
		for y: int in range(ROWS):
			var pick: Vector2i = ATLAS_GRASS[(x * 3 + y * 5) % ATLAS_GRASS.size()]
			ground.set_cell(0, Vector2i(x, y), src_id, pick)
	var mid_x: int = 10
	var mid_y: int = 6
	for x: int in range(3, 17):
		ground.set_cell(0, Vector2i(x, mid_y), src_id, ATLAS_PATH_H)
	for y: int in range(4, 10):
		ground.set_cell(0, Vector2i(mid_x, y), src_id, ATLAS_PATH_V)
	ground.set_cell(0, Vector2i(mid_x, mid_y), src_id, ATLAS_PATH_CROSS)
	for x: int in range(3, 8):
		ground.set_cell(0, Vector2i(x, 8), src_id, ATLAS_PATH_H)
	for x: int in range(13, 17):
		ground.set_cell(0, Vector2i(x, 8), src_id, ATLAS_PATH_H)


func _spawn_forest_props() -> void:
	## 15–40 Y-sorted decorative (non-interactive) trees around clearing edges.
	var catalog: Array[Dictionary] = [
		{"tex": "res://assets/art/trees/tree_forest_imagine.png", "size": Vector2(128, 160)},
		{"tex": "res://assets/art/trees/tree_oak_b.png", "size": Vector2(128, 160)},
		{"tex": "res://assets/art/trees/tree_oak_a.png", "size": Vector2(96, 128)},
		{"tex": "res://assets/art/trees/tree_pine_a.png", "size": Vector2(80, 144)},
		{"tex": "res://assets/art/trees/tree_autumn_a.png", "size": Vector2(96, 128)},
		{"tex": "res://assets/art/trees/bush_a.png", "size": Vector2(64, 48)},
		{"tex": "res://assets/art/trees/stump_a.png", "size": Vector2(48, 40)},
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260915
	var placed: int = 0
	var attempts: int = 0
	while placed < 28 and attempts < 200:
		attempts += 1
		var edge: int = attempts % 4
		var pos: Vector2
		match edge:
			0:
				pos = Vector2(rng.randf_range(40, 1240), rng.randf_range(80, 220))
			1:
				pos = Vector2(rng.randf_range(40, 1240), rng.randf_range(620, 700))
			2:
				pos = Vector2(rng.randf_range(40, 180), rng.randf_range(200, 680))
			_:
				pos = Vector2(rng.randf_range(1100, 1240), rng.randf_range(200, 680))
		if not _clear_of_landmarks(pos, 110.0):
			continue
		var entry: Dictionary = catalog[placed % catalog.size()]
		var spr := Sprite2D.new()
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		spr.centered = false
		var sz: Vector2 = entry["size"]
		spr.offset = Vector2(-sz.x * 0.5, -sz.y)
		spr.texture = load(str(entry["tex"])) as Texture2D
		spr.position = pos
		spr.y_sort_enabled = true
		spr.z_index = 0
		world.add_child(spr)
		placed += 1


func _clear_of_landmarks(pos: Vector2, min_dist: float) -> bool:
	for p: Vector2 in CLEAR_POINTS:
		if pos.distance_to(p) < min_dist:
			return false
	return true


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb: InputEventMouseButton = event
	if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if hud.care_panel.visible or hud.prestige_panel.visible:
		return
	# Belt-and-suspenders: skip ground move if an interactable Area2D is under the cursor.
	if _interactable_under_point(get_global_mouse_position()):
		return
	keeper.move_to(get_global_mouse_position(), null)


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
	hud.show_prestige_menu()


func _on_care_menu() -> void:
	hud.show_care_menu()
