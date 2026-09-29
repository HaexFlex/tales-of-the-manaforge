extends SceneTree
## Short hub + Echo Chamber load check. Not the long VERIFY suite.
## Autoload names are not in scope for --script, so this looks them up on the root.
## Run: godot --headless --path <project> --script res://tools/scene_sanity.gd

func _initialize() -> void:
	print("SANITY_INIT")
	call_deferred("_run")


func _run() -> void:
	var failed: int = 0
	var game: Node = root.get_node("GameState")
	var strings: Node = root.get_node("ContentStrings")
	root.get_node("SaveService").set("boot_intent", "new")
	game.call("reset_for_new_game")
	game.set("welcome_shown", true)
	var packed: PackedScene = load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		print("FAIL main scene missing")
		quit(1)
		return
	var live: Node = packed.instantiate()
	root.add_child(live)
	await process_frame
	await process_frame
	var props_before: int = get_nodes_in_group("forest_prop").size()
	await process_frame
	var props: int = get_nodes_in_group("forest_prop").size()
	failed += _check(props == props_before, "forest props stable after frames (got %d)" % props)
	failed += _check(props >= 80, "forest_prop >= 80 (got %d)" % props)
	var play: Vector2 = live.call("get_play_size")
	failed += _check(absf(play.x - 4800.0) < 0.5 and absf(play.y - 4200.0) < 0.5, "play 4800x4200")
	var cam: Camera2D = live.get_node_or_null("Camera2D") as Camera2D
	failed += _check(cam != null, "Camera2D")
	if cam:
		failed += _check(cam.limit_left == 180 and cam.limit_top == 180 and cam.limit_right == 4620 and cam.limit_bottom == 4020, "camera limits")
	var cam_min: Vector2 = live.call("camera_min")
	var cam_max: Vector2 = live.call("camera_max")
	live.call("pan_camera", Vector2(-9999, -9999))
	var lo: Vector2 = live.call("get_camera_position_clamped")
	live.call("pan_camera", Vector2(9999, 9999))
	var hi: Vector2 = live.call("get_camera_position_clamped")
	failed += _check(lo.distance_to(cam_min) < 1.5, "camera clamp min")
	failed += _check(hi.distance_to(cam_max) < 1.5, "camera clamp max")
	failed += _check(get_nodes_in_group("runestone").size() == 7, "7 runestones")
	failed += _check(get_nodes_in_group("gatherable").size() == 3, "3 harvest nodes")
	failed += _near(live, "World/Manatree", Vector2(2400, 2340))
	failed += _near(live, "World/Keeper", Vector2(2200, 2560))
	failed += _near(live, "World/HarvestTree", Vector2(1560, 2200))
	failed += _near(live, "World/HarvestStone", Vector2(3240, 2100))
	failed += _near(live, "World/HarvestBerry", Vector2(3000, 2760))
	failed += _near(live, "World/EchoPortal", Vector2(2520, 1500))
	failed += _near(live, "World/Runestones/Runestone_might", Vector2(3120, 1680))
	failed += _near(live, "World/Runestones/Runestone_arcana", Vector2(3480, 1980))
	failed += _near(live, "World/Runestones/Runestone_resilience", Vector2(3540, 2460))
	failed += _near(live, "World/Runestones/Runestone_ward", Vector2(3180, 2940))
	failed += _near(live, "World/Runestones/Runestone_vitality", Vector2(1980, 3000))
	failed += _near(live, "World/Runestones/Runestone_swiftness", Vector2(1500, 2640))
	failed += _near(live, "World/Runestones/Runestone_fate", Vector2(1440, 2040))
	failed += _check(live.get_node_or_null("World/Manatree/Door") != null, "Door marker")
	failed += _check(live.get_node_or_null("World/Keeper/SpawnPoint") != null, "SpawnPoint marker")
	var click: ColorRect = live.get_node_or_null("ClickLayer") as ColorRect
	failed += _check(click != null and click.mouse_filter == Control.MOUSE_FILTER_IGNORE and absf(click.size.x - 4800.0) < 0.5, "click layer")
	failed += _layout_pass(live)
	var tree_cols: int = 0
	var bush_cols: int = 0
	var canopy_ok: int = 0
	for prop: Node in get_nodes_in_group("forest_prop"):
		var kind: String = str(prop.get_meta("prop_kind", ""))
		var body: StaticBody2D = null
		var spr: Sprite2D = null
		for ch: Node in prop.get_children():
			if ch is StaticBody2D:
				body = ch
			elif ch is Sprite2D:
				spr = ch
		if body == null:
			continue
		if kind == "tree":
			tree_cols += 1
			var csz: Vector2 = prop.get_meta("collider_size", Vector2.ZERO)
			if spr and spr.texture and csz.y > 0.0 and csz.y <= float(spr.texture.get_height()) * 0.20 + 2.0:
				canopy_ok += 1
		elif kind == "bush" or kind == "tuft":
			bush_cols += 1
	failed += _check(tree_cols >= 40, "tree colliders %d" % tree_cols)
	failed += _check(bush_cols >= 20, "bush colliders %d" % bush_cols)
	failed += _check(canopy_ok >= 20, "canopy colliders %d" % canopy_ok)
	var ground: TileMap = live.get_node_or_null("Ground") as TileMap
	var bad_tiles: int = 0
	if ground:
		for cell: Vector2i in ground.get_used_cells(0):
			if ground.get_cell_atlas_coords(0, cell).y != 0:
				bad_tiles += 1
	failed += _check(ground != null and bad_tiles == 0, "grass atlas")
	var decor: Array = get_nodes_in_group("forest_decor")
	failed += _check(decor.size() >= 20 and decor.size() <= 60, "decor count %d" % decor.size())
	var decor_bad: int = 0
	var decor_hit: int = 0
	for decor_node: Node in decor:
		var dspr: Sprite2D = null
		for dch: Node in decor_node.get_children():
			if dch is Sprite2D:
				dspr = dch
				break
		var dpath: String = ""
		if dspr and dspr.texture:
			dpath = str(dspr.texture.resource_path)
		if dpath.find("/decor/grass_") < 0:
			decor_bad += 1
		if decor_node is Node2D and not bool(live.call("decor_spot_allowed", (decor_node as Node2D).global_position)):
			decor_hit += 1
	failed += _check(decor_bad == 0 and decor_hit == 0, "decor grass off landmarks")
	failed += _art_fit(live)
	game.set("forge_key", true)
	var forge_msg: String = str(live.get_node("HUD").call("open_forge_entry"))
	failed += _check(forge_msg == str(strings.call("get_text", "forge_not_built")), "forge stub")
	live.queue_free()
	await process_frame

	failed += _weapons()
	failed += await _battle_view()

	game.set("arrow_mode", "magical")
	game.call("apply_save_dict", {"arrow_mode": "physical"})
	failed += _check(str(game.get("arrow_mode")) == "physical", "arrow_mode physical roundtrip")
	game.call("apply_save_dict", {})
	failed += _check(str(game.get("arrow_mode")) == "physical", "old save defaults arrow_mode")
	var save_src: String = FileAccess.get_file_as_string("res://scripts/autoload/save_service.gd")
	failed += _check(save_src.find("const SAVE_VERSION: int = 8") >= 0, "SAVE_VERSION 8")

	if failed == 0:
		print("SANITY_OK")
	else:
		print("SANITY_FAIL %d" % failed)
	quit(failed)


func _layout_pass(live: Node) -> int:
	var failed: int = 0
	var world: Node2D = live.get_node_or_null("World") as Node2D
	failed += _check(world != null and world.y_sort_enabled and world.z_index > 0, "world y-sort above ground")
	var nested: int = 0
	for prop: Node in get_nodes_in_group("forest_prop"):
		if prop.get_parent() != world:
			nested += 1
	failed += _check(nested == 0, "forest props stay direct children of World (nested %d)" % nested)
	var keeper: Node = live.get_node_or_null("World/Keeper")
	var kspr: AnimatedSprite2D = keeper.get_node("Sprite") as AnimatedSprite2D
	var ktex: Texture2D = kspr.sprite_frames.get_frame_texture(&"idle_south", 0)
	var keeper_h: float = float(ktex.get_height()) * absf(kspr.scale.y)
	var tree: Node = live.get_node_or_null("World/HarvestTree")
	var tspr: Sprite2D = tree.get_node("Sprite") as Sprite2D
	var tree_h: float = 0.0
	if tspr.texture:
		tree_h = float(tspr.texture.get_height()) * absf(tspr.scale.y)
	print("KEEPER_HEIGHT %.2f" % keeper_h)
	print("TREE_HEIGHT %.2f" % tree_h)
	failed += _check(tree_h + 0.5 >= keeper_h * 3.0, "wood tree >= 3x keeper")
	failed += _check(tspr.texture != null and str(tspr.texture.resource_path).ends_with("harvest_tree.png"), "wood texture path")
	failed += _check(absf(tspr.offset.x + float(tspr.texture.get_width()) * 0.5) < 0.5, "tree feet x")
	failed += _check(absf(tspr.offset.y + float(tspr.texture.get_height())) < 0.5, "tree feet y")
	failed += _check(absf(float(tree.get("stand_height")) - 384.0) < 0.5, "stand_height 384")
	failed += _check(absf(tspr.scale.y - 1.0) < 0.02, "tree scale 1")
	var click_shape: CollisionShape2D = tree.get_node("CollisionShape2D") as CollisionShape2D
	var click_rect: RectangleShape2D = click_shape.shape as RectangleShape2D
	var vis := Vector2(float(tspr.texture.get_width()), float(tspr.texture.get_height())) * tspr.scale
	failed += _check(click_rect != null and click_rect.size.distance_to(Vector2(120, 240)) < 1.5, "click 120x240")
	failed += _check(click_shape.position.distance_to(Vector2(0, -120)) < 1.5, "click centered (0,-120)")
	var trunk_shape: CollisionShape2D = tree.get_node("Trunk/CollisionShape2D") as CollisionShape2D
	var trunk_rect: RectangleShape2D = trunk_shape.shape as RectangleShape2D
	failed += _check(trunk_shape != null and not trunk_shape.disabled, "trunk collision on")
	failed += _check(absf(float(tree.get("trunk_width_ratio")) - 0.26) < 0.011, "trunk_width_ratio 0.26")
	failed += _check(trunk_rect != null and absf(trunk_rect.size.x - vis.x * 0.26) < 1.5, "trunk width matches ratio")
	failed += _check(trunk_rect != null and trunk_rect.size.y < vis.y * 0.45 and trunk_rect.size.y > 8.0, "trunk is the base")
	var spent: Texture2D = tree.get("spent_texture") as Texture2D
	failed += _check(spent != null and str(spent.resource_path).ends_with("harvest_tree_spent.png"), "tree spent texture ready")
	failed += _check(str(tspr.texture.resource_path).ends_with("harvest_tree.png"), "spent art is not shown")
	failed += _check(str(tree.get("resource_id")) == "wood" and str(tree.get("node_key")) == "wood", "wood ids")
	var stone: Node = live.get_node("World/HarvestStone")
	var berry: Node = live.get_node("World/HarvestBerry")
	failed += _check(str(stone.get("resource_id")) == "stone" and str(stone.get("node_key")) == "stone", "stone ids")
	failed += _check(str(berry.get("resource_id")) == "food" and str(berry.get("node_key")) == "food", "food ids")
	var paths: Node = live.get_node_or_null("Paths")
	failed += _check(paths != null and paths.get_parent() == live, "Paths in main")
	if paths:
		failed += _check(int(paths.z_index) < int(world.z_index), "paths under props")
		var lines: int = 0
		for child: Node in paths.get_children():
			if child is Line2D:
				lines += 1
		failed += _check(lines >= 11, "path lines %d" % lines)
		var path_tex: Texture2D = paths.get("path_texture") as Texture2D
		failed += _check(path_tex != null and str(path_tex.resource_path).ends_with("trample_path_strip.png"), "trample strip")
		failed += _check(absf(float(paths.get("path_width")) - 48.0) < 0.5, "path width 48")
		var path_tint: Color = paths.get("tint")
		failed += _check(path_tint.r > 0.98 and path_tint.g > 0.98 and path_tint.b > 0.98 and path_tint.a > 0.98, "path tint white")
		var sample: Line2D = paths.get_node_or_null("ToHarvestTree") as Line2D
		failed += _check(sample != null and sample.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "path nearest")
		failed += _check(sample != null and sample.texture_repeat == CanvasItem.TEXTURE_REPEAT_ENABLED, "path repeat")
		var patches: int = 0
		for child: Node in paths.get_children():
			if child is Sprite2D:
				patches += 1
		failed += _check(patches >= 8, "trample patches %d" % patches)
	var berry_spent: Texture2D = berry.get("spent_texture") as Texture2D
	var berry_sprite: Sprite2D = berry.get_node("Sprite") as Sprite2D
	failed += _check(berry_spent != null and str(berry_spent.resource_path).ends_with("harvest_berry_spent.png"), "berry spent texture ready")
	failed += _check(berry_sprite.texture != null and str(berry_sprite.texture.resource_path).ends_with("berry_harvest_node.png"), "berry still shows the live art")
	var stone_spent: Texture2D = stone.get("spent_texture") as Texture2D
	var stone_sprite: Sprite2D = stone.get_node("Sprite") as Sprite2D
	failed += _check(stone_spent != null and str(stone_spent.resource_path).ends_with("harvest_stone_spent.png"), "stone spent texture ready")
	failed += _check(stone_sprite.texture != null and str(stone_sprite.texture.resource_path).ends_with("harvest_stone.png"), "stone still shows the live art")
	var main_src: String = FileAccess.get_file_as_string("res://scenes/main.tscn")
	failed += _check(main_src.find("width = 36.0") < 0 and main_src.find("width = 48.0") >= 0, "saved path width 48")
	failed += _check(main_src.find("texture_repeat = 2") >= 0 and main_src.find("texture_filter = 1") >= 0, "saved path filter and repeat")
	var ground: TileMap = live.get_node_or_null("Ground") as TileMap
	var cells: int = ground.get_used_cells(0).size() if ground else 0
	failed += _check(cells >= 4900, "grass covers wide clearing (%d)" % cells)
	return failed


func _weapons() -> int:
	var failed: int = 0
	var gear: Node = root.get_node("Equipment")
	var game: Node = root.get_node("GameState")
	var pack: Node = root.get_node("Backpack")
	gear.call("reset_for_new_game")
	game.call("reset_for_new_game")
	failed += _check(str(gear.call("item_damage_kind", "stone_sword")) == "physical", "stone sword physical")
	failed += _check(str(gear.call("item_damage_kind", "sapstaff")) == "magical", "sapstaff magical")
	failed += _check(str(gear.call("item_damage_kind", "thornbow")) == "hybrid", "thornbow hybrid")
	var staff_def: Dictionary = gear.call("get_item_def", "sapstaff")
	var staff_bonus: Variant = staff_def.get("bonuses", {})
	failed += _check(typeof(staff_bonus) == TYPE_DICTIONARY and int((staff_bonus as Dictionary).get("arcana", 0)) == 2, "sapstaff +2 arcana")
	var bow_def: Dictionary = gear.call("get_item_def", "thornbow")
	var bow_bonus: Variant = bow_def.get("bonuses", {})
	failed += _check(
		typeof(bow_bonus) == TYPE_DICTIONARY
		and int((bow_bonus as Dictionary).get("might", 0)) == 1
		and int((bow_bonus as Dictionary).get("arcana", 0)) == 1,
		"thornbow +1/+1"
	)
	failed += _check(str(gear.call("recipe_station", "sapstaff")) == "handcraft" and str(gear.call("recipe_station", "thornbow")) == "handcraft", "handcraft station")
	failed += _check(str(gear.call("try_craft", "sapstaff")) == "cant_afford", "sapstaff needs ingredients")
	pack.call("set_count", "wooden_planks", 50)
	pack.call("set_count", "stone_fragments", 30)
	game.call("set_resource", &"food", 20)
	failed += _check(bool(gear.call("grant_item", "weapon_rod")), "grant rod")
	failed += _check(str(gear.call("try_craft", "sapstaff")) == "ok", "craft sapstaff")
	failed += _check(str(gear.call("try_equip", "sapstaff")) == "ok", "equip sapstaff")
	failed += _check(str(gear.call("equipped_strike_kind")) == "magical", "equipped magical")
	failed += _check(int(gear.call("gear_bonus", "arcana")) == 2, "equipped arcana")
	failed += _check(str(gear.call("try_craft", "thornbow")) == "ok", "craft thornbow")
	failed += _check(str(gear.call("try_equip", "thornbow")) == "ok", "equip thornbow")
	failed += _check(str(gear.call("equipped_strike_kind")) == "hybrid", "equipped hybrid")
	var mag := EchoBattle.new()
	mag.force_crit = 0
	mag.strike_kind = "magical"
	mag.configure(
		{"might": 1, "arcana": 20, "resilience": 40, "ward": 40, "vitality": 20, "swiftness": 20, "fate": 1},
		{"stats": {"resilience": 5, "ward": 0, "arcana": 1, "swiftness": 1, "vitality": 8, "fate": 1, "might": 1}, "display_name": "Elaia"}
	)
	mag.choose("strike")
	failed += _check(mag.last_keeper_damage == 200, "magical strike uses arcana vs ward (got %d)" % mag.last_keeper_damage)
	var phys := EchoBattle.new()
	phys.force_crit = 0
	phys.strike_kind = "physical"
	phys.configure(
		{"might": 1, "arcana": 20, "resilience": 40, "ward": 40, "vitality": 20, "swiftness": 20, "fate": 1},
		{"stats": {"resilience": 5, "ward": 0, "arcana": 1, "swiftness": 1, "vitality": 8, "fate": 1, "might": 1}, "display_name": "Elaia"}
	)
	phys.choose("strike")
	failed += _check(phys.last_keeper_damage == 0, "physical strike uses might vs resilience (got %d)" % phys.last_keeper_damage)
	var hybrid := EchoBattle.new()
	hybrid.strike_kind = "hybrid"
	hybrid.arrow_mode = "physical"
	failed += _check(hybrid.resolved_strike_kind() == "physical", "hybrid starts physical")
	failed += _check(hybrid.toggle_arrow_mode() == "magical" and hybrid.resolved_strike_kind() == "magical", "hybrid toggles magical")
	return failed


func _battle_view() -> int:
	var failed: int = 0
	var game: Node = root.get_node("GameState")
	var strings: Node = root.get_node("ContentStrings")
	var echo: Node = root.get_node("EchoChamber")
	var view_packed: PackedScene = load("res://scenes/echo_battle.tscn") as PackedScene
	failed += _check(view_packed != null, "echo battle scene")
	if view_packed == null:
		return failed
	var battle := EchoBattle.new()
	battle.force_crit = 0
	battle.strike_kind = "hybrid"
	battle.arrow_mode = "physical"
	battle.configure(
		{"might": 8, "arcana": 8, "resilience": 8, "ward": 8, "vitality": 8, "swiftness": 8, "fate": 1},
		{"display_name": "Elaia", "stats": {"swiftness": 1, "vitality": 6}}
	)
	echo.set("battle", battle)
	echo.set("in_battle", true)
	echo.set("reentry", false)
	var view: Node = view_packed.instantiate()
	root.add_child(view)
	await process_frame
	failed += _check(bool(view.call("speech_between_portraits")), "speech between portraits")
	var ssize: Vector2 = view.call("speech_band_size")
	var csize: Vector2 = view.call("command_band_size")
	var lsize: Vector2 = view.call("log_band_size")
	failed += _check(ssize.y >= 80.0 and ssize.y <= 100.0, "speech band")
	failed += _check(absf(csize.x - 720.0) < 0.5 and absf(csize.y - 120.0) < 0.5, "command band")
	failed += _check(lsize.y >= 100.0 and lsize.y <= 140.0, "log band")
	var psize: Vector2 = view.call("portrait_size")
	failed += _check(absf(psize.x - 384.0) < 0.5, "portrait 384")
	failed += _check(bool(view.call("keeper_uses_idle_texture")), "keeper portrait")
	failed += _check(bool(view.call("echo_uses_elaia_texture")), "elaia portrait")
	failed += _check(bool(view.call("is_arrow_toggle_shown")), "hybrid toggle shown")
	failed += _check(str(view.call("arrow_toggle_text")) == str(strings.call("get_text", "battle_toggle_phys")), "toggle reads Phys")
	view.call("_on_arrow")
	failed += _check(str(game.get("arrow_mode")) == "magical", "toggle writes GameState")
	failed += _check(str(view.call("arrow_toggle_text")) == str(strings.call("get_text", "battle_toggle_mag")), "toggle reads Mag")
	failed += _chamber_plate(view)
	view.queue_free()
	echo.set("battle", null)
	echo.set("in_battle", false)
	await process_frame
	return failed


func _art_fit(live: Node) -> int:
	var failed: int = 0
	var berry: Sprite2D = live.get_node_or_null("World/HarvestBerry/Sprite") as Sprite2D
	failed += _check(berry != null and berry.texture != null, "berry sprite")
	if berry and berry.texture:
		var bw: float = float(berry.texture.get_width())
		var bh: float = float(berry.texture.get_height())
		failed += _check(bw == 784.0 and bh == 1168.0, "berry canvas 784x1168 (got %sx%s)" % [bw, bh])
		failed += _check(not berry.centered, "berry bottom-anchored")
		failed += _check(absf(berry.offset.x + bw * 0.5) < 0.5 and absf(berry.offset.y + bh) < 0.5, "berry offset bottom-center")
	var marker: Sprite2D = live.get_node_or_null("World/EchoPortal/Visual/Marker") as Sprite2D
	failed += _check(marker != null and marker.texture != null, "portal sprite")
	if marker and marker.texture:
		var pw: float = float(marker.texture.get_width())
		var ph: float = float(marker.texture.get_height())
		failed += _check(pw == 784.0 and ph == 1168.0, "portal canvas 784x1168 (got %sx%s)" % [pw, ph])
		failed += _check(not marker.centered, "portal bottom-anchored")
		failed += _check(absf(marker.offset.x + pw * 0.5) < 0.5 and absf(marker.offset.y + ph) < 0.5, "portal offset bottom-center")
	var sheet: Texture2D = load("res://assets/art/ui/manaforge_hud_icons_sheet.png") as Texture2D
	failed += _check(sheet != null and sheet.get_width() == 1280 and sheet.get_height() == 512, "hud icon sheet 1280x512")
	return failed


func _chamber_plate(view: Node) -> int:
	var failed: int = 0
	var art: TextureRect = view.get_node_or_null("ChamberArt") as TextureRect
	var bg: ColorRect = view.get_node_or_null("Background") as ColorRect
	var ground: ColorRect = view.get_node_or_null("Ground") as ColorRect
	var keeper: TextureRect = view.get_node_or_null("KeeperPortrait") as TextureRect
	var echo_portrait: TextureRect = view.get_node_or_null("EchoPortrait") as TextureRect
	failed += _check(art != null and bg != null and ground != null, "chamber nodes")
	failed += _check(bg != null and bg.visible and ground != null and ground.visible, "color rects stay as fallback")
	if art and ground and bg:
		failed += _check(art.get_index() > ground.get_index() and ground.get_index() > bg.get_index(), "plate draws over both color rects")
	var plate_path: String = "res://assets/art/echo/echo_chamber_bg.png"
	if FileAccess.file_exists(plate_path):
		failed += _check(art != null and art.visible and art.texture != null, "chamber plate visible")
		if art and art.texture:
			failed += _check(art.texture.get_width() == 1280 and art.texture.get_height() == 720, "plate is 1280x720")
	else:
		failed += _check(art != null and not art.visible, "chamber art hidden without a plate")
	failed += _check(
		keeper != null and keeper.position == Vector2(56, 114) and keeper.size == Vector2(384, 384),
		"keeper portrait box"
	)
	failed += _check(
		echo_portrait != null and echo_portrait.position == Vector2(840, 114) and echo_portrait.size == Vector2(384, 384),
		"elaia portrait box"
	)
	return failed


func _near(live: Node, path: String, want: Vector2) -> int:
	var node: Node2D = live.get_node_or_null(path) as Node2D
	if node == null:
		print("FAIL missing %s" % path)
		return 1
	if node.position.distance_to(want) > 0.5:
		print("FAIL %s at %s want %s" % [path, node.position, want])
		return 1
	return 0


func _check(ok: bool, label: String) -> int:
	if ok:
		return 0
	print("FAIL %s" % label)
	return 1
