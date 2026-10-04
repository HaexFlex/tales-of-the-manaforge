extends SceneTree
## Short hub + Echo Chamber load check. Not the long VERIFY suite.
## Autoload names are not in scope for --script, so this looks them up on the root.
## Run: godot --headless --path <project> --script res://tools/scene_sanity.gd

func _initialize() -> void:
	print("SANITY_INIT")
	call_deferred("_run")


func _run() -> void:
	var failed: int = 0
	var jobs: Node = root.get_node_or_null("ForgeJobs")
	if jobs:
		jobs.call("set_dev_speed_override", 1.0)
		jobs.call("set_autosave_enabled", false)
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
	failed += _check(absf(play.x - 4320.0) < 0.5 and absf(play.y - 3780.0) < 0.5, "play 4320x3780")
	var cam: Camera2D = live.get_node_or_null("Camera2D") as Camera2D
	failed += _check(cam != null, "Camera2D")
	if cam:
		failed += _check(cam.limit_left == 180 and cam.limit_top == 180 and cam.limit_right == 4140 and cam.limit_bottom == 3600, "camera limits")
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
	failed += _near(live, "World/Manatree", Vector2(2160, 2106))
	failed += _near(live, "World/Keeper", Vector2(2080, 2460))
	failed += _near(live, "World/HarvestTree", Vector2(1200, 2100))
	failed += _near(live, "World/HarvestStone", Vector2(3300, 1900))
	failed += _near(live, "World/HarvestBerry", Vector2(2480, 2780))
	failed += _near(live, "World/EchoPortal", Vector2(2900, 1280))
	failed += _near(live, "World/Runestones/Runestone_might", Vector2(2000, 1000))
	failed += _near(live, "World/Runestones/Runestone_arcana", Vector2(3200, 1600))
	failed += _near(live, "World/Runestones/Runestone_resilience", Vector2(3300, 2500))
	failed += _near(live, "World/Runestones/Runestone_ward", Vector2(2700, 2950))
	failed += _near(live, "World/Runestones/Runestone_vitality", Vector2(1800, 2950))
	failed += _near(live, "World/Runestones/Runestone_swiftness", Vector2(900, 2400))
	failed += _near(live, "World/Runestones/Runestone_fate", Vector2(1100, 1500))
	failed += _spacing_pass(live)
	failed += _check(live.get_node_or_null("World/Manatree/Door") != null, "Door marker")
	failed += _check(live.get_node_or_null("World/Keeper/SpawnPoint") != null, "SpawnPoint marker")
	var click: ColorRect = live.get_node_or_null("ClickLayer") as ColorRect
	failed += _check(click != null and click.mouse_filter == Control.MOUSE_FILTER_IGNORE and absf(click.size.x - 4320.0) < 0.5, "click layer")
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
	var base_n: int = 0
	var bases: Node = live.get_node_or_null("World/ForestBases")
	if bases:
		base_n = bases.get_child_count()
	print("FOREST_COLLIDERS trees=%d bushes=%d canopy=%d bases=%d" % [tree_cols, bush_cols, canopy_ok, base_n])
	failed += await _forest_seal(live)
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
		if dpath.find("/hub/ground/grass_tuft_") < 0:
			decor_bad += 1
		if decor_node is Node2D and not bool(live.call("decor_spot_allowed", (decor_node as Node2D).global_position)):
			decor_hit += 1
	failed += _check(decor_bad == 0 and decor_hit == 0, "decor grass off landmarks")
	failed += _hub_ground_deco(live)
	failed += _art_fit(live)
	game.set("forge_key", false)
	var forge_msg: String = str(live.get_node("HUD").call("open_forge_entry"))
	failed += _check(forge_msg == str(strings.call("get_text", "forge_no_key")), "forge needs a key")
	failed += _check(FileAccess.file_exists("res://scenes/forge_room.tscn"), "forge room scene")
	game.set("stage_id", &"elder")
	game.set("forge_key", true)
	failed += _check(jobs != null and bool(jobs.call("can_enter_forge")), "elder with a key can enter")
	game.set("stage_id", &"sapling")
	game.set("forge_key", false)
	failed += _elaia_portrait_gate(live)
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
	failed += _check(save_src.find("const SAVE_VERSION: int = 10") >= 0, "SAVE_VERSION 10")
	failed += _content_keys()
	failed += _gear_bonus_match()
	failed += _scene_exit_audit()

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
	var berry_vis := Vector2(float(berry_sprite.texture.get_width()), float(berry_sprite.texture.get_height())) * berry_sprite.scale
	var berry_click: CollisionShape2D = berry.get_node("CollisionShape2D") as CollisionShape2D
	var berry_rect: RectangleShape2D = berry_click.shape as RectangleShape2D
	failed += _check(absf(berry_vis.y - 128.0) < 1.0 and berry_vis.x <= 128.5, "berry display is 2x the 64 box")
	failed += _check(berry_rect != null and berry_rect.size.distance_to(berry_vis) < 1.5, "berry click matches the doubled sprite")
	failed += _check(berry_click.position.distance_to(Vector2(0, -berry_vis.y * 0.5)) < 1.5, "berry click centered on the sprite")
	var stone_spent: Texture2D = stone.get("spent_texture") as Texture2D
	var stone_sprite: Sprite2D = stone.get_node("Sprite") as Sprite2D
	failed += _check(stone_spent != null and str(stone_spent.resource_path).ends_with("harvest_stone_spent.png"), "stone spent texture ready")
	failed += _check(stone_sprite.texture != null and str(stone_sprite.texture.resource_path).ends_with("harvest_stone.png"), "stone still shows the live art")
	var main_src: String = FileAccess.get_file_as_string("res://scenes/main.tscn")
	failed += _check(main_src.find("width = 36.0") < 0 and main_src.find("width = 48.0") >= 0, "saved path width 48")
	failed += _check(main_src.find("texture_repeat = 2") >= 0 and main_src.find("texture_filter = 1") >= 0, "saved path filter and repeat")
	var ground: TileMap = live.get_node_or_null("Ground") as TileMap
	var cells: int = ground.get_used_cells(0).size() if ground else 0
	failed += _check(cells >= 4000 and cells <= 4200, "grass covers tighter clearing (%d)" % cells)
	return failed


func _weapons() -> int:
	var failed: int = 0
	var gear: Node = root.get_node("Equipment")
	var game: Node = root.get_node("GameState")
	var pack: Node = root.get_node("Backpack")
	gear.call("reset_for_new_game")
	game.call("reset_for_new_game")
	failed += _check(str(gear.call("item_damage_kind", "stone_sword")) == "physical", "stone_sword physical")
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
		failed += _check(bw == 86.0 and bh == 128.0, "berry canvas 86x128 (got %sx%s)" % [bw, bh])
		failed += _check(not berry.centered, "berry bottom-anchored")
		failed += _check(absf(berry.offset.x + bw * 0.5) < 0.5 and absf(berry.offset.y + bh) < 0.5, "berry offset bottom-center")
	var marker: Sprite2D = live.get_node_or_null("World/EchoPortal/Visual/Marker") as Sprite2D
	failed += _check(marker != null and marker.texture != null, "portal sprite")
	if marker and marker.texture:
		var pw: float = float(marker.texture.get_width())
		var ph: float = float(marker.texture.get_height())
		failed += _check(pw == 160.0 and ph == 200.0, "portal canvas 160x200 (got %sx%s)" % [pw, ph])
		failed += _check(not marker.centered, "portal bottom-anchored")
		failed += _check(absf(marker.offset.x + pw * 0.5) < 0.5 and absf(marker.offset.y + ph) < 0.5, "portal offset bottom-center")
	for index: int in range(10):
		var icon: Texture2D = HudIcons.cell(index)
		var label: String = "hud icon %d" % index
		failed += _check(icon != null and icon.get_width() == 32 and icon.get_height() == 32, label)
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


func _spacing_pass(live: Node) -> int:
	var failed: int = 0
	var world: Node2D = live.get_node("World") as Node2D
	var named: Dictionary = {}
	for mark_name: String in ["HarvestTree", "HarvestStone", "HarvestBerry", "EchoPortal", "Keeper", "KeepersBench"]:
		named[mark_name] = _sprite_rect(world.get_node(mark_name))
	var stones: Node2D = world.get_node("Runestones") as Node2D
	for stone: Node in stones.get_children():
		named[str(stone.name)] = _sprite_rect(stone)
	var bench_canvas: Rect2 = named["KeepersBench"]
	var bench_node: Node2D = world.get_node("KeepersBench") as Node2D
	var bench_rect: Rect2 = _opaque_sprite_rect(bench_node)
	named["KeepersBench"] = bench_rect
	var keys: Array = named.keys()
	var min_gap: float = 1.0e9
	for i: int in range(keys.size()):
		for j: int in range(i + 1, keys.size()):
			min_gap = minf(min_gap, _rect_gap(named[keys[i]], named[keys[j]]))
	var tree_rect: Rect2 = named["HarvestTree"]
	var rune_gap: float = 1.0e9
	for stone: Node in stones.get_children():
		rune_gap = minf(rune_gap, _rect_gap(tree_rect, named[str(stone.name)]))
	var bench_tree_gap: float = _rect_gap(tree_rect, bench_rect)
	var exclusion: Rect2 = _manatree_exclusion((world.get_node("Manatree") as Node2D).position)
	var hidden: int = 0
	for mark_name: String in ["HarvestTree", "HarvestStone", "HarvestBerry", "EchoPortal", "KeepersBench"]:
		if named[mark_name].intersects(exclusion):
			hidden += 1
			print("FAIL hidden by manatree %s" % mark_name)
	for stone: Node in stones.get_children():
		if named[str(stone.name)].intersects(exclusion):
			hidden += 1
			print("FAIL hidden by manatree %s" % stone.name)
	var path_gap: float = 1.0e9
	var paths: Node = live.get_node("Paths")
	for child: Node in paths.get_children():
		if not (child is Line2D) or str(child.name) == "ToBench":
			continue
		path_gap = minf(path_gap, _line_clearance(child as Line2D, bench_rect))
	var clear_radius: float = _bench_clear_radius()
	var footprint: float = _farthest_corner(bench_rect, bench_node.position)
	print("MIN_PAIR_GAP %.2f" % min_gap)
	print("RUNE_TREE_GAP %.2f" % rune_gap)
	print("BENCH_TREE_GAP %.2f" % bench_tree_gap)
	print("BENCH_RECT %.1f %.1f %.1f %.1f" % [
		bench_rect.position.x, bench_rect.position.y, bench_rect.size.x, bench_rect.size.y,
	])
	print("BENCH_CANVAS %.1f %.1f %.1f %.1f" % [
		bench_canvas.position.x, bench_canvas.position.y, bench_canvas.size.x, bench_canvas.size.y,
	])
	print("BENCH_PATH_GAP %.2f" % path_gap)
	print("BENCH_CLEAR %.1f covers %.1f" % [clear_radius, footprint])
	print("MANATREE_EXCLUSION %.1f %.1f %.1f %.1f" % [
		exclusion.position.x, exclusion.position.y, exclusion.size.x, exclusion.size.y,
	])
	failed += _check(min_gap + 0.01 >= 64.0, "pairwise sprite gap >= 64")
	failed += _check(rune_gap + 0.01 >= 160.0, "runestone to harvest tree >= 160")
	failed += _check(bench_tree_gap + 0.01 >= 160.0, "bench to harvest tree >= 160")
	failed += _check(hidden == 0, "nodes stay outside the grown manatree")
	failed += _check(path_gap + 0.01 >= 16.0, "bench clears path ribbons")
	failed += _check(clear_radius + 0.1 >= footprint, "bench clear radius covers the painted footprint")
	failed += _check(bench_node.position.distance_to(Vector2(1760, 2580)) < 1.0, "bench position")
	var map_text: String = FileAccess.get_file_as_string("res://data/hub_map.json")
	var map_v: Variant = JSON.parse_string(map_text)
	var marks: Dictionary = (map_v as Dictionary).get("landmarks", {}) if typeof(map_v) == TYPE_DICTIONARY else {}
	var bench_mark: Variant = marks.get("keepers_bench", [])
	var mark_ok: bool = typeof(bench_mark) == TYPE_ARRAY and (bench_mark as Array).size() >= 2
	if mark_ok:
		mark_ok = Vector2(float((bench_mark as Array)[0]), float((bench_mark as Array)[1])).distance_to(bench_node.position) < 1.0
	failed += _check(mark_ok, "hub_map keepers_bench matches the scene")
	failed += _check(live.get_node_or_null("Paths/ToBench") is Line2D, "path branch to the bench")
	failed += _path_network(live)
	return failed


func _path_network(live: Node) -> int:
	var failed: int = 0
	var map_v: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/hub_map.json"))
	var paths_v: Variant = (map_v as Dictionary).get("paths", []) if typeof(map_v) == TYPE_DICTIONARY else []
	failed += _check(typeof(paths_v) == TYPE_ARRAY and (paths_v as Array).size() >= 11, "hub_map paths")
	var paths_node: Node = live.get_node("Paths")
	var seen: Dictionary = {}
	if typeof(paths_v) == TYPE_ARRAY:
		for entry_v: Variant in paths_v:
			if typeof(entry_v) != TYPE_DICTIONARY:
				failed += 1
				continue
			var entry: Dictionary = entry_v
			var line_name: String = str(entry.get("name", ""))
			var line: Line2D = paths_node.get_node_or_null(line_name) as Line2D
			var pts_v: Variant = entry.get("points", [])
			var match_ok: bool = line != null and typeof(pts_v) == TYPE_ARRAY
			if match_ok:
				var want: Array = pts_v
				match_ok = line.points.size() == want.size()
				if match_ok:
					for i: int in range(want.size()):
						var pair: Array = want[i]
						var got: Vector2 = line.points[i]
						if got.distance_to(Vector2(float(pair[0]), float(pair[1]))) > 1.0:
							match_ok = false
							break
			if not match_ok:
				print("FAIL path %s does not match hub_map" % line_name)
				failed += 1
			seen[line_name] = true
	var parent: Dictionary = {}
	var snap: float = 24.0
	var knots: Array[Vector2] = []
	var line_count: int = 0
	for child: Node in paths_node.get_children():
		if not (child is Line2D):
			continue
		line_count += 1
		var line2: Line2D = child as Line2D
		if line2.points.size() < 2:
			continue
		var a: Vector2 = _snap_knot(knots, line2.points[0], snap)
		var b: Vector2 = _snap_knot(knots, line2.points[line2.points.size() - 1], snap)
		_union_knot(parent, a, b)
	var roots: Dictionary = {}
	for knot: Vector2 in knots:
		roots[_find_knot(parent, knot)] = true
	var landmarks: Array[Vector2] = [
		Vector2(2160, 2106), Vector2(1200, 2100), Vector2(3300, 1900), Vector2(2480, 2780),
		Vector2(2900, 1280), Vector2(1760, 2580), Vector2(2000, 1000), Vector2(3200, 1600),
		Vector2(3300, 2500), Vector2(2700, 2950), Vector2(1800, 2950), Vector2(900, 2400),
		Vector2(1100, 1500),
	]
	var covered: int = 0
	for mark: Vector2 in landmarks:
		for knot: Vector2 in knots:
			if knot.distance_to(mark) <= snap:
				covered += 1
				break
	print("PATH_GRAPH components %d lines %d landmarks %d/%d" % [roots.size(), line_count, covered, landmarks.size()])
	failed += _check(roots.size() == 1, "path graph is one piece (got %d)" % roots.size())
	failed += _check(covered == landmarks.size(), "paths reach every landmark (%d/%d)" % [covered, landmarks.size()])
	return failed


func _scene_exit_audit() -> int:
	## Player scene changes: pause menu is the only path to the title.
	## The Forge south door and Esc return to the hub. Echo battle is an overlay.
	var failed: int = 0
	var title_callers: PackedStringArray = PackedStringArray()
	var dir := DirAccess.open("res://scripts")
	if dir == null:
		return _check(false, "scripts dir")
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".gd"):
			var src: String = FileAccess.get_file_as_string("res://scripts/%s" % file_name)
			var names_title: bool = src.find("title_screen.tscn") >= 0 or src.find("TITLE_SCENE") >= 0
			var changes_scene: bool = src.find("change_scene_to_file") >= 0
			if names_title and changes_scene:
				title_callers.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	var allowed: Dictionary = {
		"pause_menu.gd": true,
		"main.gd": true,
		"playtest_quit.gd": true,
		"playtest_ship.gd": true,
		"pass_f_playthrough.gd": true,
		# The verify harness names the title scene to prove a bare launch still
		# opens it. It is not a player exit.
		"verify_headless.gd": true,
	}
	for caller: String in title_callers:
		if not allowed.has(caller):
			print("FAIL title exit in %s" % caller)
			failed += 1
	var forge_src: String = FileAccess.get_file_as_string("res://scripts/autoload/forge_jobs.gd")
	var echo_src: String = FileAccess.get_file_as_string("res://scripts/autoload/echo_chamber.gd")
	var forge_ok: bool = forge_src.find("boot_intent = \"forge_return\"") >= 0 and forge_src.find("change_scene_to_file(HUB_SCENE)") >= 0
	var echo_ok: bool = echo_src.find("change_scene") < 0
	## Reads .gd source. A release pck ships compiled scripts, so this scan cannot
	## run against the pack. Packed builds cover this path with SCENE_TRANSITIONS_OK.
	failed += _check(title_callers.has("pause_menu.gd"), "pause menu can reach the title")
	failed += _check(forge_ok, "forge exit returns to the hub")
	failed += _check(echo_ok, "echo battle stays an overlay")
	print("SCENE_EXITS title=%s forge_return=%s echo=overlay" % [",".join(title_callers), "yes" if forge_ok else "no"])
	return failed


func _snap_knot(knots: Array[Vector2], point: Vector2, snap: float) -> Vector2:
	for knot: Vector2 in knots:
		if knot.distance_to(point) <= snap:
			return knot
	knots.append(point)
	return point


func _find_knot(parent: Dictionary, point: Vector2) -> Vector2:
	var key: String = "%s,%s" % [point.x, point.y]
	if not parent.has(key):
		parent[key] = point
		return point
	var at: Vector2 = parent[key]
	if at.distance_to(point) <= 0.01:
		return point
	var root: Vector2 = _find_knot(parent, at)
	parent[key] = root
	return root


func _union_knot(parent: Dictionary, a: Vector2, b: Vector2) -> void:
	var ra: Vector2 = _find_knot(parent, a)
	var rb: Vector2 = _find_knot(parent, b)
	parent["%s,%s" % [rb.x, rb.y]] = ra


func _gear_bonus_match() -> int:
	var failed: int = 0
	var eq_v: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/equipment.json"))
	var tune_v: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/forge_tuning.json"))
	if typeof(eq_v) != TYPE_DICTIONARY or typeof(tune_v) != TYPE_DICTIONARY:
		return _check(false, "gear json")
	var by_id: Dictionary = {}
	for item_v: Variant in (eq_v as Dictionary).get("items", []):
		if typeof(item_v) == TYPE_DICTIONARY:
			by_id[str((item_v as Dictionary).get("id", ""))] = item_v
	var recipes: Dictionary = (tune_v as Dictionary).get("recipes", {})
	var ids: Array[String] = ["rootsteel_edge", "heartwand", "switchshaft", "oakheart_knot", "shardlens", "windthorn_bead"]
	for item_id: String in ids:
		var item: Dictionary = by_id.get(item_id, {})
		var recipe: Dictionary = recipes.get(item_id, {})
		var same: bool = _bonus_dict_equal(item.get("bonuses", {}), recipe.get("bonuses", {}))
		failed += _check(same, "%s bonuses match forge_tuning" % item_id)
		var item_kind: String = str(item.get("damage_kind", ""))
		var recipe_kind: String = str(recipe.get("damage_kind", ""))
		if item_kind != "" or recipe_kind != "":
			failed += _check(item_kind == recipe_kind, "%s damage_kind matches forge_tuning" % item_id)
	return failed


func _bonus_dict_equal(a: Variant, b: Variant) -> bool:
	if typeof(a) != TYPE_DICTIONARY or typeof(b) != TYPE_DICTIONARY:
		return false
	var left: Dictionary = a
	var right: Dictionary = b
	var keys: Dictionary = {}
	for key: Variant in left.keys():
		keys[str(key)] = true
	for key: Variant in right.keys():
		keys[str(key)] = true
	for key: Variant in keys.keys():
		if int(left.get(key, 0)) != int(right.get(key, 0)):
			return false
	return not keys.is_empty()


func _hub_ground_deco(live: Node) -> int:
	var failed: int = 0
	var nodes: Array = get_nodes_in_group("hub_ground_deco")
	failed += _check(nodes.size() == 150, "hub ground deco %d" % nodes.size())
	var world: Node2D = live.get_node("World") as Node2D
	var exclusion: Rect2 = _manatree_exclusion((world.get_node("Manatree") as Node2D).position)
	var bench: Vector2 = (world.get_node("KeepersBench") as Node2D).position
	var bench_r: float = _bench_clear_radius()
	var paths: Node = live.get_node("Paths")
	var off: int = 0
	var rock_body: int = 0
	var glow_bad: int = 0
	var glow_n: int = 0
	var grass_files: Dictionary = {}
	var families: Dictionary = {}
	for node: Node in nodes:
		if not (node is Node2D):
			off += 1
			continue
		var at: Vector2 = (node as Node2D).global_position
		if exclusion.has_point(at) or at.distance_to(bench) < bench_r:
			off += 1
		if not bool(live.call("decor_spot_allowed", at)) or _near_path(paths, at, 36.0):
			off += 1
		var tex_path: String = str(node.get("texture_path"))
		var kind: String = "other"
		if tex_path.find("grass_tuft_") >= 0:
			kind = "grass"
			grass_files[tex_path] = true
		elif tex_path.find("fern_") >= 0:
			kind = "fern"
		elif tex_path.find("mushroom_glow_") >= 0:
			kind = "glow"
		elif tex_path.find("mushroom_plain_") >= 0:
			kind = "plain"
		elif tex_path.find("rock_mossy_") >= 0:
			kind = "rock"
		elif tex_path.find("flower_") >= 0:
			kind = "flower"
		families[kind] = int(families.get(kind, 0)) + 1
		if kind == "rock" and node.get_node_or_null("Body") != null:
			rock_body += 1
		if kind == "glow":
			glow_n += 1
			var glow: Sprite2D = node.get_node_or_null("Glow") as Sprite2D
			var mat: CanvasItemMaterial = glow.material as CanvasItemMaterial if glow else null
			var gtex: Texture2D = glow.texture if glow else null
			if glow == null or mat == null or mat.blend_mode != CanvasItemMaterial.BLEND_MODE_ADD:
				glow_bad += 1
			elif gtex == null or gtex.get_width() != 96 or not str(gtex.resource_path).ends_with("_glow.png"):
				glow_bad += 1
	failed += _check(off == 0, "ground deco off paths, exclusion, bench, and nodes (hits %d)" % off)
	failed += _check(rock_body == 0, "rocks have no collision")
	failed += _check(glow_n == 6 and glow_bad == 0, "glow mushrooms %d bad %d" % [glow_n, glow_bad])
	failed += _check(grass_files.size() >= 4, "grass variants %d" % grass_files.size())
	failed += _check(int(families.get("grass", 0)) == 60, "added grass %d" % int(families.get("grass", 0)))
	failed += _check(int(families.get("fern", 0)) == 30, "ferns %d" % int(families.get("fern", 0)))
	failed += _check(int(families.get("plain", 0)) == 10, "plain mushrooms %d" % int(families.get("plain", 0)))
	failed += _check(int(families.get("rock", 0)) == 20, "rocks %d" % int(families.get("rock", 0)))
	failed += _check(int(families.get("flower", 0)) == 24, "flowers %d" % int(families.get("flower", 0)))
	return failed


func _near_path(paths: Node, at: Vector2, limit: float) -> bool:
	if paths == null:
		return false
	for child: Node in paths.get_children():
		if not (child is Line2D):
			continue
		var pts: PackedVector2Array = (child as Line2D).points
		for i: int in range(pts.size() - 1):
			if _dist_seg(at, pts[i], pts[i + 1]) < limit:
				return true
	return false


func _dist_seg(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var den: float = ab.length_squared()
	var t: float = 0.0 if den <= 0.0001 else clampf((p - a).dot(ab) / den, 0.0, 1.0)
	return p.distance_to(a + ab * t)


func _manatree_exclusion(origin: Vector2) -> Rect2:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/manatree/native/manatree_meta.json"))
	var union := Rect2()
	var first: bool = true
	for entry: Variant in (parsed as Dictionary).get("stages", []):
		var stage: Dictionary = entry
		var size_v: Array = stage.get("size", [0, 0])
		var door_v: Array = stage.get("door_floor", [0, 0])
		var sc: float = float(stage.get("display_scale", 1.0))
		var sz := Vector2(float(size_v[0]), float(size_v[1])) * sc
		var door := Vector2(float(door_v[0]), float(door_v[1])) * sc
		var rect := Rect2(origin + Vector2(-door.x, -door.y), sz)
		union = rect if first else union.merge(rect)
		first = false
	return union.grow(96.0)


func _opaque_sprite_rect(node: Node) -> Rect2:
	var spr: Sprite2D = node.get_node_or_null("Sprite") as Sprite2D
	if spr == null or spr.texture == null or spr.centered:
		return _sprite_rect(node)
	var image: Image = spr.texture.get_image()
	if image == null:
		return _sprite_rect(node)
	var used: Rect2i = image.get_used_rect()
	if used.size.x <= 0 or used.size.y <= 0:
		return _sprite_rect(node)
	var local := Rect2(spr.offset + Vector2(used.position), Vector2(used.size))
	return _transformed_rect(spr.global_transform, local)


func _bench_clear_radius() -> float:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/hub_map.json"))
	if typeof(parsed) != TYPE_DICTIONARY:
		return 0.0
	var extras: Variant = (parsed as Dictionary).get("extra_clear", [])
	if typeof(extras) != TYPE_ARRAY:
		return 0.0
	for extra_v: Variant in extras:
		if typeof(extra_v) != TYPE_DICTIONARY:
			continue
		var extra: Dictionary = extra_v
		var pos: Variant = extra.get("pos", [])
		if typeof(pos) == TYPE_ARRAY and (pos as Array).size() >= 2:
			var at := Vector2(float((pos as Array)[0]), float((pos as Array)[1]))
			if at.distance_to(Vector2(1760, 2580)) < 1.0:
				return float(extra.get("radius", 0.0))
	return 0.0


func _farthest_corner(rect: Rect2, origin: Vector2) -> float:
	var far: float = 0.0
	for corner: Vector2 in [rect.position, rect.end, Vector2(rect.position.x, rect.end.y), Vector2(rect.end.x, rect.position.y)]:
		far = maxf(far, origin.distance_to(corner))
	return far


func _line_clearance(line: Line2D, rect: Rect2) -> float:
	var best: float = 1.0e9
	var pts: PackedVector2Array = line.points
	for i: int in range(pts.size() - 1):
		best = minf(best, _segment_rect_distance(pts[i], pts[i + 1], rect))
	return best - line.width * 0.5


func _segment_rect_distance(a: Vector2, b: Vector2, rect: Rect2) -> float:
	var best: float = 1.0e9
	var steps: int = 64
	for step: int in range(steps + 1):
		var p: Vector2 = a.lerp(b, float(step) / float(steps))
		var dx: float = maxf(rect.position.x - p.x, maxf(0.0, p.x - rect.end.x))
		var dy: float = maxf(rect.position.y - p.y, maxf(0.0, p.y - rect.end.y))
		best = minf(best, Vector2(dx, dy).length())
	return best


func _sprite_rect(node: Node) -> Rect2:
	var spr: Node = node.get_node_or_null("Sprite")
	if spr == null:
		spr = node.get_node_or_null("Visual/Marker")
	if spr == null:
		spr = node.get_node_or_null("Stone")
	if spr is Sprite2D and (spr as Sprite2D).texture != null:
		var sprite: Sprite2D = spr as Sprite2D
		var fw: float = float(sprite.texture.get_width())
		var fh: float = float(sprite.texture.get_height())
		if sprite.hframes > 1:
			fw /= float(sprite.hframes)
		if sprite.vframes > 1:
			fh /= float(sprite.vframes)
		return _transformed_rect(sprite.global_transform, Rect2(sprite.offset, Vector2(fw, fh)))
	if spr is AnimatedSprite2D:
		var anim: AnimatedSprite2D = spr as AnimatedSprite2D
		var tex: Texture2D = anim.sprite_frames.get_frame_texture(anim.animation, 0) if anim.sprite_frames else null
		if tex == null:
			return Rect2(anim.global_position, Vector2(128, 128))
		return _transformed_rect(anim.global_transform, Rect2(anim.offset, Vector2(float(tex.get_width()), float(tex.get_height()))))
	return Rect2((node as Node2D).global_position, Vector2(64, 64))


func _transformed_rect(xf: Transform2D, local: Rect2) -> Rect2:
	var pts: Array[Vector2] = [
		xf * local.position,
		xf * (local.position + Vector2(local.size.x, 0)),
		xf * (local.position + local.size),
		xf * (local.position + Vector2(0, local.size.y)),
	]
	var lo: Vector2 = pts[0]
	var hi: Vector2 = pts[0]
	for p: Vector2 in pts:
		lo = lo.min(p)
		hi = hi.max(p)
	return Rect2(lo, hi - lo)


func _rect_gap(a: Rect2, b: Rect2) -> float:
	var dx: float = maxf(a.position.x - b.end.x, b.position.x - a.end.x)
	var dy: float = maxf(a.position.y - b.end.y, b.position.y - a.end.y)
	if dx < 0.0 and dy < 0.0:
		return maxf(dx, dy)
	if dx < 0.0:
		return dy
	if dy < 0.0:
		return dx
	return sqrt(dx * dx + dy * dy)


func _near(live: Node, path: String, want: Vector2) -> int:
	var node: Node2D = live.get_node_or_null(path) as Node2D
	if node == null:
		print("FAIL missing %s" % path)
		return 1
	if node.position.distance_to(want) > 0.5:
		print("FAIL %s at %s want %s" % [path, node.position, want])
		return 1
	return 0


func _forest_seal(live: Node) -> int:
	var failed: int = 0
	var edge: Node = live.get_node_or_null("World/ForestEdge")
	failed += _check(edge is StaticBody2D, "ForestEdge collision body")
	var seg_count: int = 0
	if edge:
		for child: Node in edge.get_children():
			if child is CollisionShape2D:
				seg_count += 1
	failed += _check(seg_count >= 40, "forest wall segments %d" % seg_count)
	var tree_n: int = 0
	var bush_n: int = 0
	var rects: Array[Rect2] = []
	for prop: Node in get_nodes_in_group("forest_prop"):
		var kind: String = str(prop.get_meta("prop_kind", ""))
		if kind != "tree" and kind != "bush":
			continue
		if kind == "tree":
			tree_n += 1
		else:
			bush_n += 1
		var spr: Sprite2D = prop.get_node_or_null("Sprite") as Sprite2D
		if spr == null or spr.texture == null or not (prop is Node2D):
			continue
		var sc: float = absf(spr.scale.x)
		var origin: Vector2 = (prop as Node2D).global_position
		var w: float = float(spr.texture.get_width()) * sc
		var h: float = float(spr.texture.get_height()) * sc
		rects.append(Rect2(origin.x + spr.offset.x * sc, origin.y + spr.offset.y * sc, w, h))
	print("FOREST_COUNTS trees=%d bushes=%d" % [tree_n, bush_n])
	failed += _check(tree_n > bush_n and tree_n >= 200 and bush_n >= 40, "forest is mostly trees (%d trees, %d bushes)" % [tree_n, bush_n])
	var cell: float = 32.0
	var covered: Dictionary = {}
	for rect: Rect2 in rects:
		var x0: int = int(floor(rect.position.x / cell))
		var y0: int = int(floor(rect.position.y / cell))
		var x1: int = int(floor(rect.end.x / cell))
		var y1: int = int(floor(rect.end.y / cell))
		for gx: int in range(x0, x1 + 1):
			for gy: int in range(y0, y1 + 1):
				var cx: float = (float(gx) + 0.5) * cell
				var cy: float = (float(gy) + 0.5) * cell
				if cx >= rect.position.x and cy >= rect.position.y and cx <= rect.end.x and cy <= rect.end.y:
					covered[Vector2i(gx, gy)] = true
	var holes: int = 0
	var sx: float = 180.0
	while sx <= 4140.0:
		var sy: float = 180.0
		while sy <= 3600.0:
			if float(live.call("_ellipse_norm", Vector2(sx, sy))) >= 0.97:
				if not covered.has(Vector2i(int(floor(sx / cell)), int(floor(sy / cell)))):
					holes += 1
					if holes <= 6:
						print("FOREST_HOLE %.1f %.1f" % [sx, sy])
			sy += 32.0
		sx += 32.0
	var edge_pts: Array[Vector2] = [
		Vector2(188, 188), Vector2(4132, 188), Vector2(188, 3592), Vector2(4132, 3592),
		Vector2(2160, 188), Vector2(2160, 3592), Vector2(188, 1890), Vector2(4132, 1890),
	]
	for edge_pt: Vector2 in edge_pts:
		var hit: bool = false
		for rect: Rect2 in rects:
			if edge_pt.x >= rect.position.x and edge_pt.y >= rect.position.y and edge_pt.x <= rect.end.x and edge_pt.y <= rect.end.y:
				hit = true
				break
		if not hit:
			holes += 1
			print("FOREST_EDGE_HOLE %.1f %.1f" % [edge_pt.x, edge_pt.y])
	failed += _check(holes == 0, "camera shows no void (%d holes)" % holes)
	await process_frame
	await physics_frame
	var space: PhysicsDirectSpaceState2D = live.get_world_2d().direct_space_state
	failed += _check(space != null, "physics space")
	if space == null:
		return failed
	var circle := CircleShape2D.new()
	circle.radius = 18.0
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = circle
	params.collision_mask = 1
	params.collide_with_bodies = true
	params.collide_with_areas = false
	var step: float = 22.0
	var origin := Vector2(2080, 2460)
	var queue: Array[Vector2] = [origin]
	var seen: Dictionary = {_forest_cell(origin, step): true}
	var head: int = 0
	var targets: Array[Vector2] = [
		Vector2(1200, 2100), Vector2(3300, 1900), Vector2(2480, 2780),
		Vector2(1760, 2580), Vector2(2160, 2106),
	]
	var names: PackedStringArray = ["harvest tree", "harvest stone", "harvest berry", "bench", "forge door"]
	var reached: Array[bool] = [false, false, false, false, false]
	var leaked: bool = false
	var max_norm: float = 0.0
	var guard: int = 0
	while head < queue.size() and guard < 90000:
		guard += 1
		var at: Vector2 = queue[head]
		head += 1
		var here: float = float(live.call("_ellipse_norm", at))
		if here > max_norm:
			max_norm = here
		if at.x < 140.0 or at.y < 140.0 or at.x > 4180.0 or at.y > 3640.0:
			leaked = true
			print("FOREST_LEAK %.1f %.1f norm %.3f" % [at.x, at.y, here])
			break
		for i: int in targets.size():
			if at.distance_to(targets[i]) <= 42.0:
				reached[i] = true
		for dir: Vector2 in [Vector2(step, 0), Vector2(-step, 0), Vector2(0, step), Vector2(0, -step)]:
			var nxt: Vector2 = at + dir
			var key: Vector2i = _forest_cell(nxt, step)
			if seen.has(key):
				continue
			seen[key] = true
			params.transform = Transform2D(0.0, nxt)
			if not space.intersect_shape(params, 1).is_empty():
				continue
			queue.append(nxt)
	print("FOREST_SEAL leaked=%s max_norm=%.3f visited=%d" % ["yes" if leaked else "no", max_norm, queue.size()])
	failed += _check(not leaked, "no walkable gap out of the clearing")
	for i: int in names.size():
		failed += _check(reached[i], "%s reachable inside the clearing" % names[i])
	failed += _work_reach(live)
	await _frame_times(live)
	return failed


func _work_reach(live: Node) -> int:
	var blocked_n: int = 0
	var rows: Array = [
		["World/HarvestBerry", "food", "berry"],
		["World/HarvestStone", "stone", "stone"],
		["World/HarvestTree", "wood", "wood"],
		["World/KeepersBench", "bench", "bench"],
		["World/Manatree", "door", "manatree door"],
		["World/Manatree", "manatree", "manatree water"],
	]
	for row: Array in rows:
		var node: Node2D = live.get_node_or_null(str(row[0])) as Node2D
		if node == null:
			print("WORK_REACH missing %s" % str(row[2]))
			blocked_n += 1
			continue
		blocked_n += _reach_one(live, node, str(row[1]), str(row[2]), "keeper")
		blocked_n += _reach_one(live, node, str(row[1]), "%s elaia" % str(row[2]), "elaia")
	for stone: Node in get_nodes_in_group("runestone"):
		if stone is Node2D:
			blocked_n += _reach_one(live, stone as Node2D, "runestone", stone.name, "keeper")
			blocked_n += _reach_one(live, stone as Node2D, "runestone", "%s elaia" % stone.name, "elaia")
	var portal: Node2D = live.get_node_or_null("World/EchoPortal") as Node2D
	if portal == null:
		print("WORK_REACH missing portal")
		blocked_n += 1
	else:
		for actor_id: String in ["keeper", "elaia"]:
			var entry: Vector2 = portal.global_position + Vector2(0, 50)
			if _spot_hits(live, entry, portal) or not bool(live.call("_in_clearing", entry)):
				print("WORK_REACH blocked portal entry %s %s" % [actor_id, entry])
				blocked_n += 1
	blocked_n += _reach_forge_stations()
	print("WORK_REACH blocked=%d" % blocked_n)
	return 1 if blocked_n != 0 else 0


func _reach_forge_stations() -> int:
	## Stations live in the forge. Check them here so WORK_REACH covers every interactable.
	var blocked_n: int = 0
	var paths: PackedStringArray = PackedStringArray([
		"res://scenes/forge/crucible.tscn",
		"res://scenes/forge/mill.tscn",
		"res://scenes/forge/press.tscn",
		"res://scenes/forge/anvil.tscn",
		"res://scenes/forge/reliquary.tscn",
	])
	var api = load("res://scripts/keeper.gd")
	var host := Node2D.new()
	host.name = "StationReachHost"
	get_root().add_child(host)
	var i: int = 0
	for path: String in paths:
		var packed: PackedScene = load(path) as PackedScene
		if packed == null:
			print("WORK_REACH missing station %s" % path)
			blocked_n += 1
			continue
		var station: Node2D = packed.instantiate() as Node2D
		station.position = Vector2(12000 + i * 500, 12000)
		host.add_child(station)
		i += 1
		var footprint: Rect2 = station.call("work_footprint")
		var sid: String = str(station.get("station_id"))
		for actor_id: String in ["keeper", "elaia"]:
			var solved: Dictionary = api.solve_work_spot(
				footprint,
				station.global_position,
				"station",
				Callable(self, "_station_blocked").bind(station),
				sid,
				actor_id
			)
			var pos: Vector2 = solved.get("position", Vector2.ZERO)
			var walk: Rect2 = footprint.grow(2.0)
			var inside: bool = walk.has_point(pos)
			if bool(solved.get("fallback", false)) or inside:
				print("WORK_REACH blocked station %s %s at %s" % [sid, actor_id, pos])
				blocked_n += 1
	host.queue_free()
	return blocked_n


func _station_blocked(pos: Vector2, station: Node2D) -> bool:
	if station == null or not station.has_method("work_footprint"):
		return false
	var walk: Rect2 = station.call("work_footprint")
	return walk.grow(4.0).has_point(pos)


func _reach_one(live: Node, node: Node2D, type_id: String, label: String, actor_id: String) -> int:
	var footprint: Rect2 = Rect2(node.global_position, Vector2(32, 32))
	var api = load("res://scripts/keeper.gd")
	if node.has_method("work_footprint"):
		footprint = node.call("work_footprint")
	else:
		var spr: Sprite2D = node.get_node_or_null("Sprite") as Sprite2D
		if spr:
			footprint = api.sprite_footprint(spr)
	var solved: Dictionary = api.solve_work_spot(
		footprint,
		node.global_position,
		type_id,
		Callable(self, "_reach_blocked").bind(live, node),
		"",
		actor_id
	)
	var pos: Vector2 = solved.get("position", Vector2.ZERO)
	var bad: bool = bool(solved.get("fallback", false)) or _spot_hits(live, pos, node)
	if bad:
		print("WORK_REACH blocked %s %s at %s fallback=%s" % [label, type_id, pos, bool(solved.get("fallback", false))])
		return 1
	return 0


func _reach_blocked(pos: Vector2, live: Node, target: Node) -> bool:
	if live.has_method("_in_clearing") and not bool(live.call("_in_clearing", pos)):
		return true
	return _spot_hits(live, pos, target)


func _spot_hits(live: Node, pos: Vector2, target: Node) -> bool:
	var space: PhysicsDirectSpaceState2D = live.get_world_2d().direct_space_state
	if space == null:
		return true
	var shape := RectangleShape2D.new()
	shape.size = Vector2(36, 48)
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = Transform2D(0.0, pos + Vector2(0, -24))
	params.collision_mask = 1
	params.collide_with_areas = false
	params.collide_with_bodies = true
	var exclude: Array[RID] = []
	for body_path: String in ["World/Keeper", "World/Elaia"]:
		var body: CollisionObject2D = live.get_node_or_null(body_path) as CollisionObject2D
		if body:
			exclude.append(body.get_rid())
	if target:
		var trunk: StaticBody2D = target.get_node_or_null("Trunk") as StaticBody2D
		if trunk:
			exclude.append(trunk.get_rid())
	params.exclude = exclude
	return not space.intersect_shape(params, 1).is_empty()


func _frame_times(live: Node) -> void:
	var cam: Camera2D = live.get_node_or_null("Camera2D") as Camera2D
	if cam == null:
		print("FRAME_MS center n/a")
		print("FRAME_MS north n/a")
		return
	for spot: Array in [["center", Vector2(2160, 2025)], ["north", Vector2(2160, 900)]]:
		cam.position = live.call("_clamped_camera_pos", spot[1])
		await process_frame
		var acc: int = 0
		for _i: int in 6:
			var t0: int = Time.get_ticks_usec()
			await process_frame
			acc += Time.get_ticks_usec() - t0
		print("FRAME_MS %s %.2f" % [str(spot[0]), float(acc) / 6000.0])


func _forest_cell(p: Vector2, step: float) -> Vector2i:
	return Vector2i(int(floor(p.x / step)), int(floor(p.y / step)))


func _elaia_portrait_gate(live: Node) -> int:
	## Fresh save: no portrait and no sprite. Joined save (spared + first relic): both show.
	var failed: int = 0
	var game: Node = root.get_node("GameState")
	var hud: Node = live.get_node_or_null("HUD")
	var slot: CanvasItem = live.get_node_or_null("HUD/PartyBar/Column/Elaia") as CanvasItem
	var body: CanvasItem = live.get_node_or_null("World/Elaia") as CanvasItem
	if hud:
		hud.call("_refresh_party_bar")
	failed += _check(not bool(game.call("elaia_in_party")), "fresh save has not joined Elaia")
	failed += _check(slot != null and not slot.visible, "fresh save hides the Elaia portrait")
	failed += _check(body != null and not body.visible, "fresh save hides the Elaia sprite")
	game.set("echo_01_redeemed", true)
	game.set("first_relic_crafted", true)
	if hud:
		hud.call("_refresh_party_bar")
	if body and body.has_method("_apply_presence"):
		body.call("_apply_presence")
	failed += _check(bool(game.call("elaia_in_party")), "joined save has Elaia")
	failed += _check(slot != null and not slot.visible, "portrait waits until the Clearing dialogue")
	game.set("elaia_join_seen", true)
	if hud:
		hud.call("_refresh_party_bar")
	failed += _check(slot != null and slot.visible, "joined save shows the Elaia portrait")
	var portrait: TextureRect = live.get_node_or_null("HUD/PartyBar/Column/Elaia/Portrait") as TextureRect
	failed += _check(portrait != null and portrait.texture != null, "joined portrait has a texture")
	failed += _check(body != null and body.visible, "joined save shows the Elaia sprite")
	game.set("echo_01_redeemed", false)
	game.set("first_relic_crafted", false)
	game.set("elaia_has_pos", false)
	game.set("elaia_join_seen", false)
	if hud:
		hud.call("_refresh_party_bar")
	if body and body.has_method("_apply_presence"):
		body.call("_apply_presence")
	return failed


func _content_keys() -> int:
	var failed: int = 0
	var strings: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/strings_v01.json"))
	var forge: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/forge_copy.json"))
	if typeof(strings) != TYPE_DICTIONARY or typeof(forge) != TYPE_DICTIONARY:
		return _check(false, "string tables parse")
	var story: PackedStringArray = PackedStringArray([
		"rootsteel_edge_name", "rootsteel_edge_tooltip", "heartwand_name", "heartwand_tooltip",
		"switchshaft_name", "switchshaft_tooltip", "oakheart_knot_name", "oakheart_knot_tooltip",
		"shardlens_name", "shardlens_tooltip", "windthorn_bead_name", "windthorn_bead_tooltip",
		"sapsteel_name", "sapsteel_tooltip", "heartwood_bits_name", "heartwood_bits_tooltip",
		"amberbind_name", "amberbind_tooltip", "forge_key_relic_tooltip", "welcome_body",
		"welcome_body_short", "wisp_node_shared_hint", "ascend_confirm", "ascend_confirm_essence_wipe",
		"ascend_hint", "tree_water_ancient_block", "echo_01_intro", "echo_01_flee",
		"ascend_frozen_button", "ascend_frozen_hint", "ascend_frozen_deny", "nav_to_forge",
		"nav_to_clearing", "load_autosave_header", "load_autosave_slot", "load_manual_header",
		"title_continue_hint", "title_new_game_confirm", "pause_new_game_confirm",
		"hud_sel_keeper", "hud_sel_wisp", "hud_sel_wisp_group", "hud_sel_plus_wisps",
		"hud_task_idle", "hud_stage_label", "hud_stage_label_fruit_ready",
		"elaia_join_1", "elaia_join_2", "elaia_join_3", "elaia_join_4", "elaia_join_5",
		"elaia_join_toast", "hud_elaia_portrait_tooltip", "hud_companion_target_busy",
		"char_sheet_elaia_title", "char_sheet_elaia_role", "char_sheet_elaia_no_gear",
		"char_sheet_elaia_tending", "char_sheet_elaia_work_rate", "char_sheet_elaia_work_role",
		"char_sheet_elaia_reliquary", "char_sheet_elaia_reliquary_role",
		"char_sheet_elaia_water", "char_sheet_elaia_water_role",
		"char_sheet_elaia_move", "char_sheet_elaia_move_role",
		"char_sheet_trait_label", "char_sheet_keeper_trait", "char_sheet_elaia_trait",
		"char_sheet_trait_popup_title", "char_sheet_trait_work", "char_sheet_trait_reliquary",
		"char_sheet_trait_water", "char_sheet_trait_move",
	])
	var shop: PackedStringArray = PackedStringArray([
		"station_busy", "station_paused", "not_enough_material", "job_done", "jobs_finished_away",
		"wisp_speed_hint", "relic_swap_confirm", "ascend_warning_materials", "ascend_warning_jobs",
		"examine_crucible", "examine_mill", "examine_press", "examine_anvil", "examine_reliquary",
		"examine_bench", "wisp_counter", "queue_full", "already_owned", "job_started",
	])
	for key: String in story:
		failed += _check((strings as Dictionary).has(key) and str((strings as Dictionary)[key]) != key, key)
	for key: String in shop:
		failed += _check((forge as Dictionary).has(key) and str((forge as Dictionary)[key]) != key, key)
	return failed


func _check(ok: bool, label: String) -> int:
	if ok:
		return 0
	print("FAIL %s" % label)
	return 1
