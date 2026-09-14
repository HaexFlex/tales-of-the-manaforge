extends Node2D
## Forest hub 1280×720: grass tiles, y-sorted trees, click-to-move, care/gather.

@onready var keeper: Keeper = $World/Keeper
@onready var manatree: Manatree = $World/Manatree
@onready var hud: GameHUD = $HUD
@onready var ground: TileMap = $Ground
@onready var click_layer: ColorRect = $ClickLayer
@onready var world: Node2D = $World

const TILE: int = 64
const COLS: int = 20
const ROWS: int = 12

## Atlas indices in tileset_grass_64.png (4×2): row0 grass, row1 paths
const ATLAS_GRASS: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)
]
const ATLAS_PATH_H := Vector2i(0, 1)
const ATLAS_PATH_V := Vector2i(1, 1)
const ATLAS_PATH_CROSS := Vector2i(2, 1)


func _ready() -> void:
	_build_grass()
	_spawn_forest_props()
	click_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	click_layer.gui_input.connect(_on_ground_input)
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
	# Fill grass with slight variation
	for x: int in range(COLS):
		for y: int in range(ROWS):
			var pick: Vector2i = ATLAS_GRASS[(x * 3 + y * 5) % ATLAS_GRASS.size()]
			ground.set_cell(0, Vector2i(x, y), src_id, pick)
	# Clearing paths toward Manatree / gather lanes
	var mid_x: int = 10
	var mid_y: int = 6
	for x: int in range(3, 17):
		ground.set_cell(0, Vector2i(x, mid_y), src_id, ATLAS_PATH_H)
	for y: int in range(4, 10):
		ground.set_cell(0, Vector2i(mid_x, y), src_id, ATLAS_PATH_V)
	ground.set_cell(0, Vector2i(mid_x, mid_y), src_id, ATLAS_PATH_CROSS)
	# Soft path to wood / food sides
	for x: int in range(3, 8):
		ground.set_cell(0, Vector2i(x, 8), src_id, ATLAS_PATH_H)
	for x: int in range(13, 17):
		ground.set_cell(0, Vector2i(x, 8), src_id, ATLAS_PATH_H)


func _spawn_forest_props() -> void:
	var placements: Array[Dictionary] = [
		{"tex": "res://assets/art/trees/tree_forest_imagine.png", "pos": Vector2(96, 200), "size": Vector2(128, 160)},
		{"tex": "res://assets/art/trees/tree_oak_b.png", "pos": Vector2(1180, 220), "size": Vector2(128, 160)},
		{"tex": "res://assets/art/trees/tree_oak_a.png", "pos": Vector2(160, 360), "size": Vector2(96, 128)},
		{"tex": "res://assets/art/trees/tree_pine_a.png", "pos": Vector2(1120, 520), "size": Vector2(80, 144)},
		{"tex": "res://assets/art/trees/tree_autumn_a.png", "pos": Vector2(80, 620), "size": Vector2(96, 128)},
		{"tex": "res://assets/art/trees/tree_oak_a.png", "pos": Vector2(1200, 640), "size": Vector2(96, 128)},
		{"tex": "res://assets/art/trees/tree_pine_a.png", "pos": Vector2(320, 180), "size": Vector2(80, 144)},
		{"tex": "res://assets/art/trees/tree_forest_imagine.png", "pos": Vector2(980, 160), "size": Vector2(128, 160)},
		{"tex": "res://assets/art/trees/bush_a.png", "pos": Vector2(520, 300), "size": Vector2(64, 48)},
		{"tex": "res://assets/art/trees/bush_a.png", "pos": Vector2(760, 300), "size": Vector2(64, 48)},
		{"tex": "res://assets/art/trees/stump_a.png", "pos": Vector2(360, 480), "size": Vector2(48, 40)},
		{"tex": "res://assets/art/trees/bush_a.png", "pos": Vector2(1040, 580), "size": Vector2(64, 48)},
		{"tex": "res://assets/art/trees/tree_autumn_a.png", "pos": Vector2(240, 700), "size": Vector2(96, 128)},
		{"tex": "res://assets/art/trees/tree_oak_b.png", "pos": Vector2(700, 700), "size": Vector2(128, 160)},
	]
	for entry: Dictionary in placements:
		var spr := Sprite2D.new()
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		spr.centered = false
		var sz: Vector2 = entry["size"]
		spr.offset = Vector2(-sz.x * 0.5, -sz.y)  # base_center / feet
		spr.texture = load(str(entry["tex"])) as Texture2D
		spr.position = entry["pos"]
		spr.y_sort_enabled = true
		world.add_child(spr)


func _on_ground_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			if hud.care_panel.visible or hud.prestige_panel.visible:
				return
			var world_pos: Vector2 = click_layer.global_position + mb.position
			keeper.move_to(world_pos, null)


func _on_fruit_menu() -> void:
	hud.show_prestige_menu()


func _on_care_menu() -> void:
	hud.show_care_menu()
