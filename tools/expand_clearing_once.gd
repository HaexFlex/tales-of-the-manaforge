extends SceneTree
## One-shot layout pass: scale the baked forest ring by 1.5 and place the wide clearing.
## Does not set MANAFORGE_BAKE and does not call tools/bake_hub_layout.gd.
## Refuses to run again once Camera2D.limit_right is already the wide clearing.
##   godot --headless --path . --script res://tools/expand_clearing_once.gd

const SCALE: float = 1.5
const SKIP: Array[String] = [
	"Manatree", "Keeper", "HarvestTree", "HarvestStone", "HarvestBerry", "Runestones", "EchoPortal",
]

const LANDMARKS: Dictionary = {
	"Manatree": Vector2(2400, 2340),
	"Keeper": Vector2(2200, 2560),
	"HarvestTree": Vector2(1560, 2200),
	"HarvestStone": Vector2(3240, 2100),
	"HarvestBerry": Vector2(3000, 2760),
	"EchoPortal": Vector2(2520, 1500),
}

const RUNESTONES: Dictionary = {
	"Runestone_might": Vector2(3120, 1680),
	"Runestone_arcana": Vector2(3480, 1980),
	"Runestone_resilience": Vector2(3540, 2460),
	"Runestone_ward": Vector2(3180, 2940),
	"Runestone_vitality": Vector2(1980, 3000),
	"Runestone_swiftness": Vector2(1500, 2640),
	"Runestone_fate": Vector2(1440, 2040),
}


func _initialize() -> void:
	print("EXPAND_INIT")
	call_deferred("_expand")


func _expand() -> void:
	print("EXPAND_START")
	if OS.get_environment("MANAFORGE_BAKE") == "1":
		push_error("expand: unset MANAFORGE_BAKE; this pass must not rebuild the forest")
		quit(1)
		return
	var packed_main: PackedScene = load("res://scenes/main.tscn") as PackedScene
	if packed_main == null:
		push_error("expand: main.tscn missing")
		quit(1)
		return
	root.get_node("SaveService").set("boot_intent", "new")
	var game: Node = root.get_node("GameState")
	game.call("reset_for_new_game")
	game.set("welcome_shown", true)
	var src: Node = packed_main.instantiate()
	print("EXPAND_ADD")
	root.add_child(src)
	print("EXPAND_ADDED")
	var main := src as Node2D
	if main == null or not main.has_method("get_play_size"):
		push_error("expand: main did not come up")
		quit(1)
		return
	var camera: Camera2D = main.get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		push_error("expand: Camera2D missing")
		quit(1)
		return
	if camera.limit_right >= 4000:
		push_error("expand: clearing already wide (limit_right %d); refusing to scale again" % camera.limit_right)
		quit(1)
		return
	var world: Node2D = main.get_node("World") as Node2D
	var scaled: int = 0
	for child: Node in world.get_children():
		if SKIP.has(child.name):
			continue
		var body: Node2D = child as Node2D
		if body == null:
			continue
		body.position *= SCALE
		scaled += 1
	for mark_name: String in LANDMARKS.keys():
		var mark: Node2D = world.get_node_or_null(mark_name) as Node2D
		if mark == null:
			push_error("expand: missing %s" % mark_name)
			quit(1)
			return
		mark.position = LANDMARKS[mark_name]
	var stones: Node2D = world.get_node_or_null("Runestones") as Node2D
	if stones == null:
		push_error("expand: Runestones missing")
		quit(1)
		return
	stones.position = Vector2.ZERO
	for stone_name: String in RUNESTONES.keys():
		var stone: Node2D = stones.get_node_or_null(stone_name) as Node2D
		if stone == null:
			push_error("expand: missing %s" % stone_name)
			quit(1)
			return
		stone.position = RUNESTONES[stone_name]
	_nudge_decor(main)
	if main.has_method("_build_grass"):
		main.call("_build_grass")
	var play: Vector2 = main.call("get_play_size")
	camera.limit_left = 180
	camera.limit_top = 180
	camera.limit_right = int(play.x) - 180
	camera.limit_bottom = int(play.y) - 180
	camera.position = (world.get_node("Manatree") as Node2D).position
	camera.position_smoothing_enabled = false
	var click: ColorRect = main.get_node("ClickLayer") as ColorRect
	click.mouse_filter = Control.MOUSE_FILTER_IGNORE
	click.position = Vector2.ZERO
	click.size = play
	click.offset_left = 0.0
	click.offset_top = 0.0
	click.offset_right = play.x
	click.offset_bottom = play.y
	world.z_index = 1
	world.y_sort_enabled = true
	var keeper_h: float = _keeper_height(world.get_node("Keeper"))
	var tree: Node = world.get_node("HarvestTree")
	tree.set("stand_height", keeper_h * 3.0)
	var tree_h: float = _tree_height(tree)
	print("KEEPER_HEIGHT %.2f" % keeper_h)
	print("TREE_HEIGHT %.2f" % tree_h)
	if tree_h + 0.5 < keeper_h * 3.0:
		push_error("expand: tree %.2f is under 3x keeper %.2f" % [tree_h, keeper_h])
		quit(1)
		return
	_add_paths(main, world.get_node("Manatree") as Node2D)
	var portal: Node2D = world.get_node_or_null("EchoPortal") as Node2D
	if portal:
		portal.visible = true
		portal.set("input_pickable", true)
	var wisps: Array[Node] = []
	for wisp: Node in main.get_tree().get_nodes_in_group("wisp"):
		wisps.append(wisp)
	for wisp: Node in wisps:
		wisp.free()
	var dst := Node2D.new()
	dst.name = "Main"
	dst.set_script(load("res://scripts/main.gd"))
	var ground: Node = main.get_node("Ground")
	main.remove_child(ground)
	dst.add_child(ground)
	var paths: Node = main.get_node("Paths")
	main.remove_child(paths)
	dst.add_child(paths)
	for child_name: String in ["Camera2D", "ClickLayer", "World"]:
		var node: Node = main.get_node(child_name)
		main.remove_child(node)
		dst.add_child(node)
	var hud: Node = (load("res://scenes/hud.tscn") as PackedScene).instantiate()
	hud.name = "HUD"
	hud.unique_name_in_owner = true
	dst.add_child(hud)
	var pause: Node = (load("res://scenes/pause_menu.tscn") as PackedScene).instantiate()
	pause.name = "PauseMenu"
	pause.unique_name_in_owner = true
	dst.add_child(pause)
	_claim(dst, dst)
	var packed := PackedScene.new()
	var err: Error = packed.pack(dst)
	if err != OK:
		push_error("expand: pack failed %s" % err)
		quit(1)
		return
	err = ResourceSaver.save(packed, "res://scenes/main.tscn")
	if err != OK:
		push_error("expand: save failed %s" % err)
		quit(1)
		return
	print("EXPAND_OK scaled=%d play=%s limits=%d,%d,%d,%d" % [
		scaled, play, camera.limit_left, camera.limit_top, camera.limit_right, camera.limit_bottom,
	])
	quit(0)


func _nudge_decor(main: Node) -> void:
	var decor: Array[Node] = []
	for node: Node in main.get_tree().get_nodes_in_group("forest_decor"):
		decor.append(node)
	var moved: int = 0
	for node: Node in decor:
		var body: Node2D = node as Node2D
		if body == null:
			continue
		if bool(main.call("decor_spot_allowed", body.position)):
			continue
		var placed: bool = false
		for ring: int in range(1, 36):
			for step: int in range(16):
				var ang: float = TAU * float(step) / 16.0
				var trial: Vector2 = body.position + Vector2(cos(ang), sin(ang)) * (14.0 * float(ring))
				if bool(main.call("decor_spot_allowed", trial)):
					body.position = trial
					placed = true
					moved += 1
					break
			if placed:
				break
	print("EXPAND_DECOR_NUDGED %d" % moved)


func _add_paths(main: Node, tree: Node2D) -> void:
	var paths := Node2D.new()
	paths.name = "Paths"
	paths.unique_name_in_owner = true
	paths.set_script(load("res://scripts/trampled_paths.gd"))
	paths.z_index = 0
	paths.position = Vector2.ZERO
	var origin: Vector2 = tree.position
	var targets: Array[Dictionary] = [
		{"name": "ToHarvestTree", "pos": LANDMARKS["HarvestTree"], "bow": 56.0},
		{"name": "ToHarvestStone", "pos": LANDMARKS["HarvestStone"], "bow": -56.0},
		{"name": "ToHarvestBerry", "pos": LANDMARKS["HarvestBerry"], "bow": 48.0},
		{"name": "ToEchoPortal", "pos": LANDMARKS["EchoPortal"], "bow": -40.0},
		{"name": "ToMight", "pos": RUNESTONES["Runestone_might"], "bow": 52.0},
		{"name": "ToArcana", "pos": RUNESTONES["Runestone_arcana"], "bow": -48.0},
		{"name": "ToResilience", "pos": RUNESTONES["Runestone_resilience"], "bow": 44.0},
		{"name": "ToWard", "pos": RUNESTONES["Runestone_ward"], "bow": -52.0},
		{"name": "ToVitality", "pos": RUNESTONES["Runestone_vitality"], "bow": 40.0},
		{"name": "ToSwiftness", "pos": RUNESTONES["Runestone_swiftness"], "bow": -44.0},
		{"name": "ToFate", "pos": RUNESTONES["Runestone_fate"], "bow": 36.0},
	]
	for entry: Dictionary in targets:
		var line := Line2D.new()
		line.name = str(entry["name"])
		var dest: Vector2 = entry["pos"]
		var delta: Vector2 = dest - origin
		var perp: Vector2 = Vector2(-delta.y, delta.x).normalized()
		var mid: Vector2 = (origin + dest) * 0.5 + perp * float(entry["bow"])
		line.points = PackedVector2Array([origin, mid, dest])
		paths.add_child(line)
	main.add_child(paths)
	main.move_child(paths, main.get_node("Ground").get_index() + 1)
	if paths.has_method("_apply"):
		paths.call("_apply")


func _keeper_height(keeper: Node) -> float:
	var sprite: AnimatedSprite2D = keeper.get_node("Sprite") as AnimatedSprite2D
	var tex: Texture2D = sprite.sprite_frames.get_frame_texture(&"idle_south", 0)
	return float(tex.get_height()) * absf(sprite.scale.y)


func _tree_height(tree: Node) -> float:
	var sprite: Sprite2D = tree.get_node("Sprite") as Sprite2D
	if sprite.texture == null:
		return 0.0
	return float(sprite.texture.get_height()) * absf(sprite.scale.y)


func _claim(node: Node, scene_root: Node) -> void:
	if node != scene_root:
		node.owner = scene_root
	for child: Node in node.get_children():
		if child.scene_file_path != "":
			child.owner = scene_root
		else:
			_claim(child, scene_root)
