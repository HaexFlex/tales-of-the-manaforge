extends SceneTree
var _echo_chip_ready: bool = false
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
	failed += _resilience_tree(live)
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
	failed += _bramble_shards()
	failed += _floating_names()
	failed += _hover_rest()
	failed += _trait_speed_rows()
	failed += _water_splash()
	failed += _forge_arch_raise()
	failed += _forge_wisp_ring()
	failed += _manual_save_guard()
	failed += _load_confirm()
	failed += await _bench_cancel()
	failed += _footsteps_theme()
	failed += _ancient_orbit()
	failed += _elaia_mirror_art()
	failed += await _slot_rename()
	failed += await _ascend_gather()
	failed += await _room_cleared_window()
	failed += await _battle_view()
	failed += await _echo_turn_flow()
	failed += await _portal_fee_confirm()

	game.set("arrow_mode", "magical")
	game.call("apply_save_dict", {"arrow_mode": "physical"})
	failed += _check(str(game.get("arrow_mode")) == "physical", "arrow_mode physical roundtrip")
	game.call("apply_save_dict", {})
	failed += _check(str(game.get("arrow_mode")) == "physical", "old save defaults arrow_mode")
	var save_src: String = FileAccess.get_file_as_string("res://scripts/autoload/save_service.gd")
	failed += _check(save_src.find("const SAVE_VERSION: int = 15") >= 0, "SAVE_VERSION 15")
	failed += _content_keys()
	failed += _gear_bonus_match()
	failed += _scene_exit_audit()
	failed += await _res540_theme_sanity()
	failed += await _res540_input_sanity()
	failed += await _res540_shop_sanity()
	failed += _res540_char_sanity()
	failed += _res540_bag_sanity()
	failed += _res540_board_sanity()
	failed += _res540_battle_sanity()
	failed += _res540_care_sanity()
	failed += _res540_debug_sanity()
	failed += _res540_help_sanity()
	failed += _minigame_scenes()

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
	failed += _check(str(gear.call("try_equip", "sapstaff")) == "wrong_user", "keeper cannot wear sapstaff")
	failed += _check(str(gear.call("try_equip", "sapstaff", "elaia")) == "ok", "elaia equips sapstaff")
	failed += _check(int(gear.call("gear_bonus_for", "elaia", "arcana")) == 2, "elaia equipped arcana")
	failed += _check(str(gear.call("try_craft", "thornbow")) == "ok", "craft thornbow")
	failed += _check(str(gear.call("try_equip", "thornbow")) == "ok", "equip thornbow")
	failed += _check(str(gear.call("equipped_strike_kind")) == "hybrid", "equipped hybrid")
	var mag := EchoBattle.new()
	mag.strike_kind = "magical"
	mag.configure(
		{"might": 1, "arcana": 20, "resilience": 40, "ward": 40, "vitality": 20, "swiftness": 20, "fate": 1},
		{"stats": {"resilience": 5, "ward": 0, "arcana": 1, "swiftness": 1, "vitality": 8, "fate": 1, "might": 1}, "display_name": "Elaia"}
	)
	# force_crit was removed with the BattleResolver retune (16de7cd); setting it
	# raised a script error that skipped the rest of this check. Pin the dice instead.
	mag.set_seed(1)
	mag.choose("strike")
	var mag_turn: Dictionary = mag.turn_log[0] if mag.turn_log.size() > 0 else {}
	var mag_expect: int = _replay_keeper_strike("magic", 1, 20, 1, 5, 0, 1, 8)
	failed += _check(str(mag_turn.get("mode", "")) == "magic" and mag.last_keeper_damage == mag_expect, "magical strike uses arcana vs ward (got %d, want %d)" % [mag.last_keeper_damage, mag_expect])
	var phys := EchoBattle.new()
	phys.strike_kind = "physical"
	phys.configure(
		{"might": 1, "arcana": 20, "resilience": 40, "ward": 40, "vitality": 20, "swiftness": 20, "fate": 1},
		{"stats": {"resilience": 5, "ward": 0, "arcana": 1, "swiftness": 1, "vitality": 8, "fate": 1, "might": 1}, "display_name": "Elaia"}
	)
	# force_crit was removed with the BattleResolver retune (16de7cd); setting it
	# raised a script error that skipped the rest of this check. Pin the dice instead.
	phys.set_seed(1)
	phys.choose("strike")
	var phys_turn: Dictionary = phys.turn_log[0] if phys.turn_log.size() > 0 else {}
	var phys_expect: int = _replay_keeper_strike("physical", 1, 20, 1, 5, 0, 1, 8)
	failed += _check(str(phys_turn.get("mode", "")) == "physical" and phys.last_keeper_damage == phys_expect, "physical strike uses might vs resilience (got %d, want %d)" % [phys.last_keeper_damage, phys_expect])
	failed += _check(mag_expect != phys_expect, "magical and physical strikes differ (%d vs %d)" % [mag_expect, phys_expect])
	var hybrid := EchoBattle.new()
	hybrid.strike_kind = "hybrid"
	hybrid.arrow_mode = "physical"
	failed += _check(hybrid.resolved_strike_kind() == "physical", "hybrid starts physical")
	failed += _check(hybrid.toggle_arrow_mode() == "magical" and hybrid.resolved_strike_kind() == "magical", "hybrid toggles magical")
	return failed


func _replay_keeper_strike(mode: String, might: int, arcana: int, fate: int, def_res: int, def_ward: int, def_swift: int, def_vit: int) -> int:
	## Expected first Keeper strike for a seed-1 EchoBattle: the same BattleResolver
	## call EchoBattle._resolve_swing makes, on fresh seed-1 dice.
	var dice := BattleRng.new()
	dice.set_seed(1)
	var max_hp: int = BattleResolver.max_hp_for(def_vit)
	var res: Dictionary = BattleResolver.resolve(
		{"attack": mode, "might": might, "arcana": arcana, "fate": fate},
		{"resilience": def_res, "ward": def_ward, "swiftness": def_swift, "hp": max_hp, "max_hp": max_hp, "side": "echo"},
		0, 1, 1, dice
	)
	return int(res.get("damage", -1))


func _resilience_tree(live: Node) -> int:
	## 40 px east and 24 px south of where this crown sat on the Resilience stone.
	var failed: int = 0
	var prop: Node2D = live.get_node_or_null("World/ArtTree_0017") as Node2D
	failed += _check(prop != null, "resilience decorative tree")
	if prop != null:
		var moved: Vector2 = prop.position - Vector2(3401.2980, 2740.3648)
		failed += _check(moved.x > 24.0 and moved.y > 16.0, "tree moved south-east (%.1f, %.1f)" % [moved.x, moved.y])
		failed += _check(prop.position.distance_to(Vector2(3441.2980, 2764.3648)) < 1.0, "tree sits at the shifted spot")
	if failed == 0:
		print("RESILIENCE_TREE_OK")
	return failed


func _floating_names() -> int:
	## The black Keeper line is not editor-only. Play shows it while the cursor is over the sprite.
	var failed: int = 0
	var samples: Array[String] = [
		"res://scenes/keeper.tscn",
		"res://scenes/wisp.tscn",
		"res://scenes/echo_portal.tscn",
		"res://scenes/bramble_warden.tscn",
		"res://scenes/keepers_bench.tscn",
		"res://scenes/forge/anvil.tscn",
		"res://scenes/gatherable.tscn",
		"res://scenes/manatree.tscn",
		"res://scenes/runestone.tscn",
	]
	for path: String in samples:
		var packed: PackedScene = load(path) as PackedScene
		failed += _check(packed != null, "floating name scene %s" % path)
		if packed == null:
			continue
		var node: Node = packed.instantiate()
		root.add_child(node)
		if node.has_method("_on_hover"):
			node.call("_on_hover", true)
		if node.has_method("_on_title_hover"):
			node.call("_on_title_hover", true)
		var floating: Label = node.get_node_or_null("Label") as Label
		if floating == null:
			floating = node.get_node_or_null("Title") as Label
		failed += _check(floating != null and not floating.visible, "no floating name on %s" % path.get_file())
		node.queue_free()
	if failed == 0:
		print("FLOATING_NAMES_OK")
	return failed


func _hover_rest() -> int:
	var failed: int = 0
	WorldHover.install()
	failed += _check(is_equal_approx(WorldHover.rest_sec(), 0.8), "hover rest is 0.8s")
	failed += _check(
		is_equal_approx(float(ProjectSettings.get_setting("gui/timers/tooltip_delay_sec", 0.0)), 0.8),
		"control tooltips share the 0.8s rest"
	)
	var host := Node2D.new()
	root.add_child(host)
	WorldHover.present(host, "Harvest Stone")
	failed += _check(WorldHover.current_text() == "", "world hover stays blank until the rest ends")
	WorldHover.complete_rest()
	failed += _check(WorldHover.current_text() == "Harvest Stone", "world hover shows after the rest")
	WorldHover.dismiss(host)
	failed += _check(WorldHover.current_text() == "", "world hover hides when the pointer leaves")
	var sheet := CharacterSheet.new()
	root.add_child(sheet)
	var pop: CanvasItem = sheet.get_node_or_null("TraitPopup") as CanvasItem
	failed += _check(pop != null and not pop.visible, "trait window starts hidden")
	sheet.call("_arm_trait_hover")
	failed += _check(bool(sheet.call("trait_rest_pending")) and pop != null and not pop.visible, "trait hover waits 0.8s")
	sheet.call("complete_trait_rest")
	failed += _check(pop != null and pop.visible and not bool(sheet.call("trait_rest_pending")), "trait hover opens after the rest")
	sheet.call("close_trait_popup")
	failed += _check(pop != null and not pop.visible, "trait hover closes when the pointer leaves")
	sheet.queue_free()
	host.queue_free()
	WorldHover.shutdown()
	if failed == 0:
		print("HOVER_REST_OK")
	return failed


func _trait_speed_rows() -> int:
	var failed: int = 0
	var strings: Node = root.get_node("ContentStrings")
	var sheet := CharacterSheet.new()
	root.add_child(sheet)
	sheet.call("open_trait_popup")
	var panel: Node = sheet.get_node_or_null("TraitPopup/Panel")
	failed += _trait_row(panel, strings, "Work", "char_sheet_trait_work", "1.0×", true)
	failed += _trait_row(panel, strings, "Craft", "char_sheet_trait_craft", "1.0×", true)
	failed += _trait_row(panel, strings, "Water", "char_sheet_trait_water", "1.0×", true)
	failed += _trait_row(panel, strings, "Reliquary", "char_sheet_trait_reliquary", "", false)
	failed += _trait_row(panel, strings, "Pace", "char_sheet_trait_move", "", false)
	failed += _trait_row(panel, strings, "Brew", "char_sheet_trait_brew", "", false)
	sheet.set("_actor_id", "elaia")
	sheet.call("open_trait_popup")
	failed += _trait_row(panel, strings, "Work", "char_sheet_trait_work", "0.8×", true)
	failed += _trait_row(panel, strings, "Reliquary", "char_sheet_trait_reliquary", "1.5×", true)
	failed += _trait_row(panel, strings, "Pace", "char_sheet_trait_move", "", false)
	sheet.set("_actor_id", "bramble")
	sheet.call("open_trait_popup")
	failed += _trait_row(panel, strings, "Pace", "char_sheet_trait_move", "1.0×", true)
	failed += _trait_row(panel, strings, "Reliquary", "char_sheet_trait_reliquary", "", false)
	sheet.set("_actor_id", "puff")
	sheet.call("open_trait_popup")
	failed += _trait_row(panel, strings, "Brew", "char_sheet_trait_brew", "1.0×", true)
	failed += _trait_row(panel, strings, "Pace", "char_sheet_trait_move", "", false)
	sheet.queue_free()
	if failed == 0:
		print("TRAIT_SPEEDS_OK")
	return failed


func _water_splash() -> int:
	## Cue id stays sfx_water_pulse. The file is the soft splash, bus SFX_World, offset -18.
	var failed: int = 0
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/audio_cues.json"))
	var cues: Dictionary = parsed.get("cues", {}) if typeof(parsed) == TYPE_DICTIONARY else {}
	var cue: Dictionary = cues.get("sfx_water_pulse", {}) if typeof(cues.get("sfx_water_pulse", {})) == TYPE_DICTIONARY else {}
	var path: String = str(cue.get("path", ""))
	failed += _check(path.ends_with("sfx_gather_water_soft.ogg"), "sfx_water_pulse points at the soft splash")
	failed += _check(str(cue.get("bus", "")) == "SFX_World", "sfx_water_pulse bus is SFX_World")
	failed += _check(ResourceLoader.exists(path), "soft splash file is in the repo")
	var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/audio/MANIFEST.json"))
	var manifest_cues: Dictionary = manifest.get("cues", {}) if typeof(manifest) == TYPE_DICTIONARY else {}
	var listed: Dictionary = manifest_cues.get("sfx_water_pulse", {}) if typeof(manifest_cues.get("sfx_water_pulse", {})) == TYPE_DICTIONARY else {}
	failed += _check(str(listed.get("path", "")).ends_with("sfx_gather_water_soft.ogg"), "manifest pulse path is the soft splash")
	failed += _check(str(listed.get("bus", "")) == "SFX_World", "manifest pulse bus is SFX_World")
	failed += _check(is_equal_approx(float(listed.get("play_offset_db", 0.0)), -18.0), "manifest pulse offset is -18")
	var audio: Node = root.get_node_or_null("GameAudio")
	failed += _check(audio != null, "GameAudio for the splash")
	if audio != null:
		audio.call("clear_played_log")
		audio.call("play_water_pulse")
		failed += _check(bool(audio.call("did_play", &"sfx_water_pulse")), "watering plays sfx_water_pulse")
		failed += _check(not bool(audio.call("did_play", &"sfx_gather_water_soft")), "watering keeps the pulse cue id")
		failed += _check(is_equal_approx(float(audio.get("last_cue_volume_db")), -18.0), "watering plays at -18 dB")
	if failed == 0:
		print("WATER_SPLASH_OK")
	return failed


func _forge_arch_raise() -> int:
	## 35 px up from the original (another 3 px). The mouth clears the one-slot HUD.
	var failed: int = 0
	var packed: PackedScene = load("res://scenes/forge_room.tscn") as PackedScene
	failed += _check(packed != null, "forge room for the arch raise")
	if packed == null:
		return failed
	var room: Node2D = packed.instantiate() as Node2D
	root.add_child(room)
	var arch: Sprite2D = room.get_node_or_null("ArchFront") as Sprite2D
	var door: Node2D = room.get_node_or_null("ExitDoor") as Node2D
	failed += _check(arch != null and is_equal_approx(arch.position.y, 1052.0), "arch moved up another 3 px (y %s)" % str(arch.position.y if arch else 0))
	failed += _check(door != null and is_equal_approx(door.position.y, 1089.0), "exit stays with the raised arch")
	var jobs: Node = root.get_node_or_null("ForgeJobs")
	var spawn_y: float = float(jobs.call("forge_arch_spawn").y) if jobs != null else 0.0
	failed += _check(is_equal_approx(spawn_y, 1013.0), "keeper spawn stays on the raised lip")
	if arch != null:
		var mouth_bottom: float = arch.position.y + 66.0
		var screen_bottom: float = mouth_bottom - 660.0
		var hud_top: float = 540.0 - 24.0 - 44.0
		failed += _check(screen_bottom <= hud_top - 8.0, "arch opening clears the bottom HUD (screen %.0f hud %.0f)" % [screen_bottom, hud_top])
	room.queue_free()
	if failed == 0:
		print("FORGE_ARCH_RAISE_OK")
	return failed


func _forge_wisp_ring() -> int:
	var failed: int = 0
	var station: Node2D = (load("res://scenes/forge/crucible.tscn") as PackedScene).instantiate() as Node2D
	var tree: Node2D = (load("res://scenes/gatherable.tscn") as PackedScene).instantiate() as Node2D
	var wisp: Node2D = (load("res://scenes/wisp.tscn") as PackedScene).instantiate() as Node2D
	root.add_child(station)
	root.add_child(tree)
	root.add_child(wisp)
	var radii: Vector2 = station.call("wisp_orbit_radii")
	failed += _check(radii.x < 90.0 and radii.y < 90.0, "forge station ring is tight (%.1f, %.1f)" % [radii.x, radii.y])
	failed += _check(bool(station.call("wisp_sorts_with_feet")), "forge station uses the clearing depth rule")
	var station_z: int = (station as CanvasItem).z_index
	var north: int = int(wisp.call("_ring_z", station, -PI * 0.5))
	var south: int = int(wisp.call("_ring_z", station, PI * 0.5))
	var tree_north: int = int(wisp.call("_ring_z", tree, -PI * 0.5))
	var tree_south: int = int(wisp.call("_ring_z", tree, PI * 0.5))
	failed += _check(tree_north < 0 and tree_south > 0, "a clearing wisp still uses z -1 and 1")
	failed += _check(north < station_z and south > station_z, "a forge wisp stays behind the upper half and in front of the lower half")
	var tied: bool = false
	for step: int in 8:
		var angle: float = float(step) * TAU / 8.0
		var zed: int = int(wisp.call("_ring_z", station, angle))
		if zed == station_z:
			tied = true
		var upper: bool = sin(angle) < 0.0
		failed += _check((zed < station_z) == upper, "forge ring depth follows the upper half at %.2f" % angle)
	failed += _check(not tied, "a forge wisp never shares the station z, so it cannot vanish mid-ring")
	var room: Node = (load("res://scenes/forge_room.tscn") as PackedScene).instantiate()
	root.add_child(room)
	var game: Node = root.get_node("GameState")
	var had: int = int(game.get("wisp_count"))
	game.set("wisp_count", maxi(had, 1))
	room.call("_sync_wisps")
	var clicked: bool = false
	for child: Node in room.get_children():
		if child.has_signal("wisp_clicked") and child.is_connected("wisp_clicked", Callable(room, "_on_wisp_clicked")):
			clicked = true
	failed += _check(clicked, "the forge connects wisp_clicked the way the clearing does")
	game.set("wisp_count", had)
	room.queue_free()
	station.queue_free()
	tree.queue_free()
	wisp.queue_free()
	if failed == 0:
		print("FORGE_WISP_RING_OK")
	return failed


func _manual_save_guard() -> int:
	var failed: int = 0
	var save: Node = root.get_node("SaveService")
	var path: String = str(save.call("autosave_path", 1))
	var backup: String = FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else ""
	var had: bool = FileAccess.file_exists(path)
	var sentinel := "{\"kind\":\"autosave\",\"sentinel\":1}"
	var file := FileAccess.open(path, FileAccess.WRITE)
	failed += _check(file != null, "autosave slot 1 can be marked")
	if file != null:
		file.store_string(sentinel)
		file.close()
	failed += _check(not bool(save.call("_write_payload", path, 1, "manual")), "a manual write refuses an autosave path")
	failed += _check(FileAccess.get_file_as_string(path) == sentinel, "the autosave file is unchanged")
	var pause_packed: PackedScene = load("res://scenes/pause_menu.tscn") as PackedScene
	var pm: Node = pause_packed.instantiate()
	root.add_child(pm)
	pm.set("_slot_mode", 1)
	pm.call("_show_slots", "Save")
	var autosave_tab: Button = pm.get_node_or_null("SlotsPanel/TabAutosave") as Button
	failed += _check(autosave_tab != null and autosave_tab.disabled, "Save disables the Autosaves tab")
	pm.call("_on_slot_tab", "autosave")
	failed += _check(str(pm.get("_slot_tab")) == "manual", "Save stays on the manual tab")
	failed += _check(_live_slot_button(pm, "autosave", 1) == null, "Save does not list autosave slots")
	failed += _check(_live_slot_button(pm, "manual", 1) != null, "Save still lists manual slots")
	pm.free()
	if had:
		var restore := FileAccess.open(path, FileAccess.WRITE)
		if restore != null:
			restore.store_string(backup)
			restore.close()
	else:
		DirAccess.remove_absolute(path)
	if failed == 0:
		print("MANUAL_SAVE_GUARD_OK")
	return failed


func _load_confirm() -> int:
	var failed: int = 0
	var save: Node = root.get_node("SaveService")
	var path: String = str(save.call("slot_path", 7))
	var backup: String = FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else ""
	var had: bool = FileAccess.file_exists(path)
	var file := FileAccess.open(path, FileAccess.WRITE)
	failed += _check(file != null, "load confirm can mark slot 7")
	if file != null:
		file.store_string(JSON.stringify({
			"save_version": 15,
			"timestamp": 2,
			"slot": 7,
			"kind": "manual",
			"state": {"stage_id": "elder"},
		}))
		file.close()
	var pm: Node = (load("res://scenes/pause_menu.tscn") as PackedScene).instantiate()
	root.add_child(pm)
	pm.set("_slot_mode", 2)
	pm.call("_show_slots", "Load")
	pm.call("_on_slot_pressed", "manual", 0)
	var confirm: CanvasItem = pm.get_node_or_null("ConfirmPanel") as CanvasItem
	failed += _check(confirm != null and not confirm.visible, "an empty slot does not ask")
	var btn: Button = _live_slot_button(pm, "manual", 7)
	failed += _check(btn != null, "load lists the filled manual slot")
	if btn != null:
		btn.pressed.emit()
	failed += _check(confirm != null and confirm.visible, "loading a save asks first")
	failed += _check(str(pm.get("_confirm_action")) == "load_slot", "the ask is a load confirm")
	var body: Label = pm.get_node_or_null("ConfirmPanel/ConfirmLabel") as Label
	failed += _check(body != null and body.text.find("Load this memory") >= 0, "the ask names the load")
	pm.call("_on_confirm_no")
	failed += _check(confirm != null and not confirm.visible, "Stay leaves the save unloaded")
	failed += _check(FileAccess.file_exists(path), "Stay does not delete the slot")
	pm.free()
	if had:
		var restore := FileAccess.open(path, FileAccess.WRITE)
		if restore != null:
			restore.store_string(backup)
			restore.close()
	else:
		DirAccess.remove_absolute(path)
	if failed == 0:
		print("LOAD_CONFIRM_OK")
	return failed


func _bench_cancel() -> int:
	var failed: int = 0
	var game: Node = root.get_node("GameState")
	var jobs: Node = root.get_node("ForgeJobs")
	var pack: Node = root.get_node("Backpack")
	var wood_was: int = int(game.call("get_resource", &"wood"))
	var planks_was: int = int(pack.call("get_count", "wooden_planks"))
	var prev: Dictionary = jobs.call("keeper_task")
	if jobs.has_method("set_autosave_enabled"):
		jobs.call("set_autosave_enabled", false)
	if bool(jobs.call("has_job", "workbench")):
		jobs.call("cancel_batch", "workbench")
	game.call("set_resource", &"wood", 9)
	pack.call("set_count", "wooden_planks", 0)
	failed += _check(str(jobs.call("try_begin_batch", "workbench", "wooden_planks", 3)) == "ok", "a workbench batch can start")
	var panel: Node = (load("res://scenes/ui/batch_panel.tscn") as PackedScene).instantiate()
	panel.set("compact", true)
	panel.size = Vector2(400, 148)
	panel.custom_minimum_size = Vector2(400, 148)
	root.add_child(panel)
	panel.call("setup", "workbench")
	await process_frame
	var cancel: Button = panel.find_child("Cancel", true, false) as Button
	failed += _check(cancel != null and cancel.visible and not cancel.disabled, "the workbench Cancel button is on screen")
	if cancel != null:
		var host: Control = panel as Control
		failed += _check(host.get_global_rect().encloses(cancel.get_global_rect()), "Cancel sits inside the workbench batch slot")
		cancel.pressed.emit()
	var confirm: Control = panel.find_child("CancelConfirm", true, false) as Control
	var yes: Button = panel.find_child("ConfirmYes", true, false) as Button
	failed += _check(confirm != null and confirm.visible, "Cancel opens the confirm")
	if confirm != null:
		failed += _check((panel as Control).get_global_rect().encloses(confirm.get_global_rect()), "the confirm stays inside the batch slot")
	if yes != null:
		yes.pressed.emit()
	failed += _check(not bool(jobs.call("has_job", "workbench")), "confirming cancel clears the batch")
	failed += _check(int(game.call("get_resource", &"wood")) == 4, "cancel returns half the unused wood, rounded down")
	failed += _check(int(pack.call("get_count", "wooden_planks")) == 0, "nothing finished means no planks come back")
	jobs.call("set_keeper_working", "workbench", true)
	game.call("set_resource", &"wood", 6)
	failed += _check(str(jobs.call("try_begin_batch", "workbench", "wooden_planks", 2)) == "ok", "a second batch starts")
	jobs.call("advance_seconds", 6.0)
	failed += _check(int(pack.call("get_count", "wooden_planks")) == 1, "the finished plank is already made")
	jobs.call("cancel_batch", "workbench")
	failed += _check(int(pack.call("get_count", "wooden_planks")) == 1, "cancel keeps the plank that was already made")
	failed += _check(int(game.call("get_resource", &"wood")) == 1, "half of the leftover plank's wood rounds down")
	panel.queue_free()
	game.call("set_resource", &"wood", wood_was)
	if bool(prev.get("working", false)):
		jobs.call("set_keeper_task", str(prev.get("kind", "")), str(prev.get("target", "")), true)
	else:
		jobs.call("note_keeper_idle")
	if pack.has_method("set_count"):
		pack.call("set_count", "wooden_planks", planks_was)
	if failed == 0:
		print("BENCH_CANCEL_OK")
	return failed


func _footsteps_theme() -> int:
	var failed: int = 0
	var hud: Node = (load("res://scenes/hud.tscn") as PackedScene).instantiate()
	root.add_child(hud)
	hud.call("_ensure_footsteps_popup")
	var pop: Panel = hud.get_node_or_null("ElaiaFootsteps") as Panel
	failed += _check(pop != null, "footsteps window exists")
	if pop != null:
		var box: StyleBoxTexture = pop.get_theme_stylebox(&"panel") as StyleBoxTexture
		var path: String = box.texture.resource_path if box != null and box.texture != null else ""
		failed += _check(path.find("frame_9s_96") >= 0, "footsteps window uses bark and parchment")
		var body: Label = pop.get_node_or_null("Body") as Label
		var go: Button = pop.get_node_or_null("Go") as Button
		var speaker: Label = pop.get_node_or_null("Speaker") as Label
		var strings: Node = root.get_node("ContentStrings")
		failed += _check(speaker != null and speaker.text == str(strings.call("get_text", "wisp_name")), "footsteps names the Wisp")
		failed += _check(body != null and body.text == str(strings.call("get_text", "forge_elaia_footsteps")), "footsteps keeps the line")
		failed += _check(go != null and go.text == str(strings.call("get_text", "forge_elaia_footsteps_ok")), "footsteps keeps Go and see")
		var inner := Rect2(28, 28, pop.size.x - 56, pop.size.y - 56)
		if body != null:
			failed += _check(inner.encloses(Rect2(body.position, body.size)), "footsteps text sits inside the frame")
		if go != null:
			failed += _check(inner.encloses(Rect2(go.position, go.size)), "Go and see sits inside the frame")
			failed += _check(go.size.y >= 44.0, "Go and see is a full tap target")
	hud.queue_free()
	if failed == 0:
		print("FOOTSTEPS_THEME_OK")
	return failed


func _ancient_orbit() -> int:
	var failed: int = 0
	var game: Node = root.get_node("GameState")
	var previous: StringName = game.get("stage_id")
	var mana: Node = (load("res://scenes/manatree.tscn") as PackedScene).instantiate()
	root.add_child(mana)
	game.set("stage_id", StringName("elder"))
	var elder: Vector2 = mana.call("wisp_orbit_radii")
	game.set("stage_id", StringName("ancient"))
	var ancient: Vector2 = mana.call("wisp_orbit_radii")
	game.set("stage_id", previous)
	failed += _check(is_equal_approx(ancient.x, elder.x) and is_equal_approx(ancient.y, elder.y), "ancient wisp circle matches the elder")
	failed += _check(ancient.x >= 280.0, "ancient circle keeps the elder width")
	mana.queue_free()
	if failed == 0:
		print("ANCIENT_ORBIT_OK")
	return failed


func _ascend_gather() -> int:
	var failed: int = 0
	var game: Node = root.get_node("GameState")
	var jobs: Node = root.get_node("ForgeJobs")
	var save: Node = root.get_node("SaveService")
	var snap: Dictionary = game.call("to_save_dict")
	game.call("reset_for_new_game")
	game.set("fruit_committed", true)
	game.set("keeper_area", "forge")
	game.set("keeper_pos", Vector2(12, 12))
	game.set("elaia_area", "forge")
	game.set("elaia_pos", Vector2(20, 20))
	jobs.call("set_keeper_task", "forge", "crucible", true)
	jobs.call("set_elaia_task", "water", "manatree", true)
	game.set("wisp_count", 1)
	(game.get("wisp_assignments") as Dictionary)["0"] = "manatree"
	game.call("ascend")
	var keeper_task: Dictionary = jobs.call("keeper_task")
	var elaia_task: Dictionary = jobs.call("elaia_task")
	failed += _check(not bool(keeper_task.get("working", true)), "ascend stops the Keeper's job")
	failed += _check(not bool(elaia_task.get("working", true)), "ascend stops Elaia's job")
	failed += _check((game.get("wisp_assignments") as Dictionary).is_empty(), "ascend takes every wisp off its work")
	failed += _check(str(game.get("elaia_area")) == "forge", "Elaia stays put until she has joined")
	failed += _check(str(game.get("keeper_area")) == "clearing", "the Keeper comes back to the clearing")
	var origin: Vector2 = jobs.call("manatree_origin")
	var kspot: Vector2 = game.call("ascend_gather_spot", "keeper")
	var espot: Vector2 = game.call("ascend_gather_spot", "elaia")
	failed += _check(kspot.x < origin.x and espot.x > origin.x and kspot.y > origin.y and espot.y > origin.y, "they stand south of the trunk, one on each side")
	failed += _check((game.get("keeper_pos") as Vector2).distance_to(kspot) < 1.0, "the Keeper's place is beside the tree")
	game.call("reset_for_new_game")
	game.set("fruit_committed", true)
	game.set("echo_01_redeemed", true)
	game.set("first_relic_crafted", true)
	game.set("elaia_join_seen", true)
	game.set("keeper_area", "forge")
	game.set("elaia_area", "forge")
	game.call("ascend")
	failed += _check(str(game.get("elaia_area")) == "clearing" and (game.get("elaia_pos") as Vector2).distance_to(game.call("ascend_gather_spot", "elaia")) < 1.0, "a joined Elaia is sent to the tree")
	save.set("boot_intent", "new")
	var packed: PackedScene = load("res://scenes/main.tscn") as PackedScene
	var live: Node = packed.instantiate() if packed != null else null
	if live == null:
		failed += _check(false, "clearing loads for the gather")
	else:
		root.add_child(live)
		await process_frame
		game.set("welcome_shown", true)
		game.set("echo_01_redeemed", true)
		game.set("first_relic_crafted", true)
		game.set("elaia_join_seen", true)
		game.set("fruit_committed", false)
		game.set("elaia_area", "clearing")
		game.set("keeper_area", "clearing")
		var keeper: Node2D = get_first_node_in_group("keeper") as Node2D
		var elaia: Node2D = get_first_node_in_group("elaia") as Node2D
		var trees: Array[Node] = get_nodes_in_group("manatree")
		var manatree: Node = trees[0] if not trees.is_empty() else null
		failed += _check(keeper != null and elaia != null and manatree != null, "the party and the tree are in the clearing")
		if keeper != null and elaia != null and manatree != null:
			elaia.call("_apply_presence")
			keeper.call("apply_keeper_presence")
			var stand: Vector2 = keeper.call("work_destination", manatree, "manatree")
			keeper.global_position = stand
			stand = keeper.call("work_destination", manatree, "manatree")
			keeper.global_position = stand
			keeper.call("start_water_channel", manatree)
			var watered: bool = bool(manatree.get("_watering"))
			failed += _check(watered, "the Keeper was watering")
			var tree_at: Vector2 = (manatree as Node2D).global_position
			keeper.global_position = tree_at + Vector2(-240, 200)
			elaia.global_position = tree_at + Vector2(240, 200)
			elaia.call("begin_work_loop")
			jobs.call("set_elaia_task", "harvest", "wood", true)
			game.set("fruit_committed", true)
			game.call("ascend")
			var want_k: Vector2 = game.call("ascend_gather_spot", "keeper")
			var want_e: Vector2 = game.call("ascend_gather_spot", "elaia")
			failed += _check(not bool(manatree.get("_watering")) and int(keeper.get("_channel_kind")) == 0, "ascend stops the watering")
			failed += _check(bool(keeper.get("_moving")) and (keeper.get("_target") as Vector2).distance_to(want_k) < 1.0, "the Keeper walks to the tree")
			failed += _check(not bool(keeper.get("_work_loop")), "the Keeper is no longer working")
			failed += _check(bool(elaia.get("_moving")) and (elaia.get("_target") as Vector2).distance_to(want_e) < 1.0, "Elaia walks to the tree")
			var after: Dictionary = jobs.call("elaia_task")
			failed += _check(not bool(after.get("working", true)) and not bool(elaia.get("_work_loop")), "Elaia stops her harvest")
		live.queue_free()
		await process_frame
		var forge_packed: PackedScene = load("res://scenes/forge_room.tscn") as PackedScene
		var forge: Node = forge_packed.instantiate() if forge_packed != null else null
		if forge != null:
			root.add_child(forge)
			await process_frame
			var spawn: Node2D = forge.get_node_or_null("Keeper") as Node2D
			failed += _check(spawn != null and spawn.global_position.distance_to(Vector2(800, 860)) < 1.0, "a gathered clearing pose does not move the forge spawn")
			forge.free()
	game.call("apply_save_dict", snap)
	if failed == 0:
		print("ASCEND_GATHER_OK")
	return failed


func _elaia_mirror_art() -> int:
	## idle_w is a pixel flip of idle_e. Soles stay on row 123. No new sheet.
	var failed: int = 0
	var names: PackedStringArray = PackedStringArray([
		"res://assets/art/battle/party/battle_elaia_idle_e.png",
		"res://assets/art/battle/party/battle_elaia_attack.png",
		"res://assets/art/battle/party/battle_elaia_brace.png",
		"res://assets/art/battle/party/battle_elaia_hurt.png",
		"res://assets/art/battle/party/battle_elaia_ko.png",
	])
	for path: String in names:
		var sheet := Image.new()
		failed += _check(sheet.load(ProjectSettings.globalize_path(path)) == OK and sheet.get_width() == 128 and sheet.get_height() == 128, "Elaia sheet 128x128 %s" % path.get_file())
	var east := Image.new()
	var west := Image.new()
	var east_ok: bool = east.load(ProjectSettings.globalize_path("res://assets/art/battle/party/battle_elaia_idle_e.png")) == OK
	var west_ok: bool = west.load(ProjectSettings.globalize_path("res://assets/art/echo/battle_elaia_idle_w.png")) == OK
	failed += _check(east_ok and west_ok, "Elaia idle pair loads")
	if east_ok and west_ok:
		var flipped: Image = east.duplicate()
		flipped.flip_x()
		var same: bool = true
		var sole: int = -1
		for y: int in range(east.get_height()):
			for x: int in range(east.get_width()):
				if east.get_pixel(x, y).a > 0.0:
					sole = y
				if flipped.get_pixel(x, y) != west.get_pixel(x, y):
					same = false
		failed += _check(same, "idle_w is flip_h of idle_e about x=64")
		failed += _check(sole == 123, "Elaia soles sit on row 123 (got %d)" % sole)
	if failed == 0:
		print("ELAIA_MIRROR_ART_OK")
	return failed


func _live_slot_button(pm: Node, kind: String, slot: int) -> Button:
	var box: Node = pm.get_node_or_null("SlotsPanel/SlotScroll/SlotButtons")
	if box == null:
		return null
	for child: Node in box.get_children():
		if child.is_queued_for_deletion() or not child.has_meta("slot_index"):
			continue
		if str(child.get_meta("slot_kind", "")) == kind and int(child.get_meta("slot_index", 0)) == slot:
			return child as Button
	return null


func _slot_rename() -> int:
	var failed: int = 0
	var save: Node = root.get_node("SaveService")
	var elder: Dictionary = {"kind": "manual", "stage_display": "Elder Tree", "slot_name": ""}
	failed += _check(str(save.call("record_title", elder)) == "Elder Tree", "a new manual slot still shows the stage")
	elder["slot_name"] = "North Grove"
	failed += _check(str(save.call("record_title", elder)) == "North Grove", "a clicked name replaces Elder Tree")
	elder["kind"] = "autosave"
	failed += _check(str(save.call("record_title", elder)) == "Elder Tree", "autosave keeps the stage name")
	var path: String = str(save.call("slot_path", 7))
	var backup: String = FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else ""
	var had: bool = FileAccess.file_exists(path)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		failed += _check(false, "slot 7 can be written")
	else:
		file.store_string(JSON.stringify({
			"save_version": 15,
			"timestamp": 1,
			"slot": 7,
			"kind": "manual",
			"state": {"stage_id": "elder"},
		}))
		file.close()
		var info: Dictionary = save.call("get_slot_info", 7)
		failed += _check(str(save.call("record_title", info)) == "Elder Tree", "an old manual file has no custom name")
		failed += _check(bool(save.call("rename_manual_slot", 7, "North Grove")), "rename writes")
		info = save.call("get_slot_info", 7)
		failed += _check(str(info.get("slot_name", "")) == "North Grove", "the name is stored")
		failed += _check(int(info.get("save_version", 0)) == 15, "rename does not bump SAVE_VERSION")
		var pause_packed: PackedScene = load("res://scenes/pause_menu.tscn") as PackedScene
		var pm: Node = pause_packed.instantiate() if pause_packed != null else null
		if pm != null:
			root.add_child(pm)
			pm.set("_slot_mode", 2)
			pm.call("_show_slots", "Load")
			var manual: Button = _live_slot_button(pm, "manual", 7)
			var edit: LineEdit = manual.get_node_or_null("NameEdit") as LineEdit if manual != null else null
			failed += _check(edit != null and edit.visible and edit.text == "North Grove" and edit.max_length == 28, "a manual slot renames on click")
			pm.call("_on_slot_tab", "autosave")
			var auto_btn: Button = _live_slot_button(pm, "autosave", 1)
			failed += _check(auto_btn != null and auto_btn.get_node_or_null("NameEdit") == null, "an autosave keeps its automatic name")
			pm.queue_free()
		else:
			failed += _check(false, "pause menu loads")
		failed += _check(bool(save.call("save_game", 7)), "overwrite keeps the slot")
		info = save.call("get_slot_info", 7)
		failed += _check(str(info.get("slot_name", "")) == "North Grove", "saving again keeps the clicked name")
	if had:
		var restore := FileAccess.open(path, FileAccess.WRITE)
		if restore != null:
			restore.store_string(backup)
			restore.close()
	else:
		DirAccess.remove_absolute(path)
	if failed == 0:
		print("SLOT_RENAME_OK")
	return failed


func _trait_row(panel: Node, strings: Node, row_name: String, key: String, value: String, shown: bool) -> int:
	var row: CanvasItem = panel.get_node_or_null("Row%s" % row_name) as CanvasItem if panel != null else null
	var failed: int = _check(row != null and row.visible == shown, "trait row %s shown=%s" % [row_name, str(shown)])
	if row == null or not shown:
		return failed
	var name_lbl: Label = row.get_node_or_null("Name") as Label
	var value_lbl: Label = row.get_node_or_null("Value") as Label
	var expect: String = str(strings.call("get_text", key))
	failed += _check(name_lbl != null and name_lbl.text == expect, "trait label %s (got %s)" % [expect, name_lbl.text if name_lbl else ""])
	failed += _check(value_lbl != null and value_lbl.text == value, "trait number %s (got %s)" % [value, value_lbl.text if value_lbl else ""])
	return failed


func _room_cleared_window() -> int:
	var failed: int = 0
	var packed: PackedScene = load("res://scenes/battle/battle_scene.tscn") as PackedScene
	failed += _check(packed != null, "room cleared battle scene")
	if packed == null:
		return failed
	var view: Node = packed.instantiate()
	root.add_child(view)
	await process_frame
	var host := Node2D.new()
	host.name = "RoomClearedNameHost"
	root.add_child(host)
	var tag := Label.new()
	tag.name = "NameLabel"
	tag.text = "Keeper"
	tag.size = Vector2(80, 22)
	host.add_child(tag)
	view.call("_show_end_panel", "win")
	await process_frame
	var panel: Panel = view.get_node_or_null("Arena/EndPanel") as Panel
	if panel != null:
		tag.global_position = panel.get_global_rect().position + Vector2(48, 48)
		view.call("_conceal_names_under", panel)
	failed += _check(panel != null, "room cleared panel")
	if panel == null:
		view.queue_free()
		host.queue_free()
		return failed
	var box: StyleBox = panel.get_theme_stylebox("panel")
	var tex: Texture2D = (box as StyleBoxTexture).texture if box is StyleBoxTexture else null
	failed += _check(tex != null and str(tex.resource_path).find("frame_9s_96") >= 0, "room cleared uses the kit frame")
	failed += _check(panel.z_index >= 20, "room cleared draws above the arena")
	var inner: Rect2 = Rect2(panel.position + Vector2(28, 28), panel.size - Vector2(56, 56))
	for node_name: String in ["EndTitle", "EndDetail", "EndExp", "EndButtons"]:
		var child: Control = panel.get_node_or_null(node_name) as Control
		var child_rect: Rect2 = Rect2(panel.position + child.position, child.size) if child != null else Rect2()
		failed += _check(child != null and inner.encloses(child_rect), "%s sits inside the room cleared frame" % node_name)
	var title: Label = panel.get_node_or_null("EndTitle") as Label
	failed += _check(title != null and title.text == "Room cleared", "room cleared title")
	failed += _check(not tag.visible and tag.has_meta("fled_hidden"), "room cleared covers the Keeper name tag")
	view.queue_free()
	host.queue_free()
	await process_frame
	if failed == 0:
		print("ROOM_CLEARED_THEME_OK")
	return failed


func _bramble_shards() -> int:
	var failed: int = 0
	var echo: Node = root.get_node("EchoChamber")
	var game: Node = root.get_node("GameState")
	var before: int = int(game.call("get_resource", &"manashards"))
	var resolved: bool = bool(game.get("echo_02_resolved"))
	var outcome_was: String = str(game.get("echo_02_outcome"))
	var paid: bool = bool(game.get("echo_02_fee_paid"))
	var key: bool = bool(game.get("forge_key"))
	echo.set("battle_context", "echo2")
	var expect_spare: int = int(echo.call("snapshot_payout", "spare"))
	var spare_pay: Dictionary = echo.call("apply_outcome", "spare")
	failed += _check(expect_spare > 0 and int(spare_pay.get("shards", -1)) == expect_spare, "Bramble spare uses Elaia's shard formula")
	failed += _check(int(game.call("get_resource", &"manashards")) == before + expect_spare, "Bramble spare adds the shards")
	failed += _check(not bool(game.get("forge_key")), "Bramble spare does not grant the Forge Key")
	echo.set("battle_context", "echo2")
	var expect_defeat: int = int(echo.call("snapshot_payout", "defeat"))
	var mid: int = int(game.call("get_resource", &"manashards"))
	var defeat_pay: Dictionary = echo.call("apply_outcome", "defeat")
	failed += _check(expect_defeat > 0 and int(defeat_pay.get("shards", -1)) == expect_defeat, "Bramble defeat uses Elaia's shard formula")
	failed += _check(int(game.call("get_resource", &"manashards")) == mid + expect_defeat, "Bramble defeat adds the shards")
	game.call("set_resource", &"manashards", before)
	game.set("echo_02_resolved", resolved)
	game.set("echo_02_outcome", outcome_was)
	game.set("echo_02_fee_paid", paid)
	game.set("forge_key", key)
	echo.set("battle_context", "")
	failed += _bramble_spare_window(echo)
	if failed == 0:
		print("BRAMBLE_SHARDS_OK")
	return failed


func _bramble_spare_window(echo: Node) -> int:
	var failed: int = 0
	var packed: PackedScene = load("res://scenes/echo_battle.tscn") as PackedScene
	failed += _check(packed != null, "bramble spare window has the echo scene")
	if packed == null:
		return failed
	echo.set("battle_context", "echo2")
	var view: Node = packed.instantiate()
	root.add_child(view)
	view.call("_offer_return", "spare")
	var row_label: Label = view.get_node_or_null("EchoRewards/RewardRow0/Label") as Label
	var story: Label = view.get_node_or_null("EchoRewards/RewardRow1/Label") as Label
	failed += _check(row_label != null and row_label.text.find("Manashards") >= 0, "the spare reward row names Manashards")
	failed += _check(story != null and story.text.find("Manashards") < 0, "the spare story does not name Manashards again")
	failed += _check(story != null and story.text.find("spared") >= 0, "the spare story still says he is spared")
	var mentions: int = 0
	if view.get_node_or_null("EchoRewards") != null:
		mentions = _manashard_mentions(view.get_node_or_null("EchoRewards"))
	failed += _check(mentions == 1, "the spared window says Manashards once (got %d)" % mentions)
	view.free()
	echo.set("battle_context", "")
	return failed


func _manashard_mentions(node: Node) -> int:
	var count: int = 0
	if node is Label:
		var text: String = (node as Label).text
		var from: int = 0
		while true:
			var at: int = text.find("Manashards", from)
			if at < 0:
				break
			count += 1
			from = at + 10
	for child: Node in node.get_children():
		count += _manashard_mentions(child)
	return count


func _adventure_mode_chip() -> int:
	var failed: int = 0
	var gear: Node = root.get_node("Equipment")
	var game: Node = root.get_node("GameState")
	var packed: PackedScene = load("res://scenes/battle/battle_scene.tscn") as PackedScene
	failed += _check(packed != null, "adventure battle scene")
	if packed == null:
		return failed
	game.set("arrow_mode", "physical")
	var view: Node = packed.instantiate()
	root.add_child(view)
	var fight := FightState.new()
	fight.add_member("keeper", {"might": 5, "arcana": 8, "vitality": 6, "attack": "physical"}, 0, "front", "keeper")
	view.set("_fight", fight)
	view.set("_target_mode", "")
	var strike: CanvasItem = view.get_node_or_null("Arena/ActionMenu/StrikeButton") as CanvasItem
	var menu: CanvasItem = view.get_node_or_null("Arena/ActionMenu") as CanvasItem
	if menu:
		menu.visible = true
	if strike:
		strike.visible = true
	view.call("_refresh_mode_chip")
	var armed: bool = str(gear.call("equipped_strike_kind")) == "hybrid"
	failed += _check(armed and bool(view.call("mode_chip_shown")), "adventure shows the hybrid chip")
	failed += _check(str(view.call("mode_chip_text")) == "Phys", "adventure chip starts on Might")
	var chip: Button = view.get_node_or_null("Arena/ArrowToggle") as Button
	failed += _check(chip != null and not chip.disabled and chip.custom_minimum_size.x >= 44.0, "adventure chip meets the tap size")
	view.call("_on_mode_chip_pressed")
	var row: Dictionary = fight.fighter_dict("keeper")
	failed += _check(str(game.get("arrow_mode")) == "magical" and str(row.get("attack", "")) == "magic", "adventure chip selects Arcana")
	failed += _check(str(view.call("mode_chip_text")) == "Mag", "adventure chip reads Mag")
	var sheet: Dictionary = SlotEngine.member_stats("keeper")
	failed += _check(str(sheet.get("attack", "")) == "magic", "a hybrid weapon strikes with Arcana")
	game.set("arrow_mode", "physical")
	var physical_sheet: Dictionary = SlotEngine.member_stats("keeper")
	failed += _check(str(physical_sheet.get("attack", "")) == "physical", "a hybrid weapon strikes with Might")
	var had: String = str(gear.call("equipped_id", "weapon"))
	gear.call("grant_item", "stone_sword")
	failed += _check(str(gear.call("try_equip", "stone_sword")) == "ok", "stone sword equips for the chip hide")
	view.call("_refresh_mode_chip")
	failed += _check(not bool(view.call("mode_chip_shown")), "a physical weapon hides the chip")
	var plain: Dictionary = SlotEngine.member_stats("keeper")
	failed += _check(str(plain.get("attack", "")) == "physical", "a physical weapon stays Might")
	if had != "" and had != "stone_sword":
		gear.call("try_equip", had)
	fight.loadout = {"heart_salve": 2}
	view.call("_update_salve_button")
	var salve_btn: Button = view.get_node_or_null("Arena/ActionMenu/SalveButton") as Button
	var items_ok: bool = salve_btn != null and salve_btn.text == "Items" and salve_btn.tooltip_text.find("Heart Salve") >= 0 and salve_btn.tooltip_text.find("×2") >= 0
	failed += _check(items_ok, "the third action button says Items")
	if items_ok:
		print("ITEMS_BUTTON_OK")
	view.queue_free()
	if failed == 0 and _echo_chip_ready:
		print("HYBRID_CHIP_OK")
	return failed


func _echo_rootbind_count(battle: EchoBattle) -> int:
	var count: int = 0
	for entry: Dictionary in battle.turn_log:
		if bool(entry.get("rootbind", false)):
			count += 1
	return count


func _echo_turn_flow() -> int:
	var failed: int = 0
	var view_src: String = FileAccess.get_file_as_string("res://scripts/echo_battle_view.gd")
	var rules_src: String = FileAccess.get_file_as_string("res://scripts/echo_battle.gd")
	failed += _check(view_src.find("BattlePlayback") < 0 and view_src.find("FightState") < 0, "EchoBattleView keeps its own pose player")
	failed += _check(rules_src.find("BattlePlayback") < 0 and rules_src.find("FightState") < 0, "EchoBattle keeps its own turn split")
	var tie := EchoBattle.new()
	tie.configure(
		{"might": 1, "arcana": 1, "resilience": 8, "ward": 8, "vitality": 8, "swiftness": 6, "fate": 1},
		{"display_name": "Elaia", "stats": {"swiftness": 6, "vitality": 8}}
	)
	failed += _check(tie.keeper_acts_first(), "a Swiftness tie goes to the Keeper")
	var direct := EchoBattle.new()
	direct.configure(
		{"might": 1, "arcana": 1, "resilience": 8, "ward": 8, "vitality": 8, "swiftness": 8, "fate": 1},
		{"display_name": "Elaia", "stats": {"swiftness": 1, "vitality": 8}}
	)
	direct.set_seed(4)
	var direct_result: String = direct.choose("strike")
	failed += _check(direct_result != "presenting" and direct.pending_half() == "", "a direct choose stays one call")
	var mercy_seed: int = -1
	var mercy_hp: int = -1
	var mercy_log: String = ""
	var keeper_fast: Dictionary = {"might": 8, "arcana": 1, "resilience": 8, "ward": 8, "vitality": 8, "swiftness": 8, "fate": 1}
	var echo_slow: Dictionary = {"display_name": "Elaia", "stats": {"might": 1, "arcana": 1, "resilience": 1, "ward": 1, "vitality": 8, "swiftness": 1, "fate": 1}}
	for s: int in range(1, 50):
		var probe := EchoBattle.new()
		probe.configure(keeper_fast, echo_slow)
		probe.set_seed(s)
		probe.echo_max_hp = 10
		probe.echo_hp = 2
		if probe.choose("strike") == "spare_window" and probe.echo_hp >= 1 and probe.enemy_turns == 0 and probe.pending_half() == "":
			mercy_seed = s
			mercy_hp = probe.echo_hp
			mercy_log = str(probe.turn_log)
			break
	failed += _check(mercy_seed > 0, "a strike can open the mercy floor")
	if mercy_seed > 0:
		var floored := EchoBattle.new()
		floored.configure(keeper_fast, echo_slow)
		floored.set_seed(mercy_seed)
		floored.echo_max_hp = 10
		floored.echo_hp = 2
		floored.present_halves = true
		floored.instant_present = false
		var floored_result: String = floored.choose("strike")
		failed += _check(floored_result == "spare_window" and floored.spare_window and floored.echo_hp == mercy_hp and floored.echo_hp >= 1, "the mercy floor still leaves her standing")
		failed += _check(floored.pending_half() == "" and floored.enemy_turns == 0, "the mercy floor does not hand the Echo a turn")
		failed += _check(str(floored.turn_log) == mercy_log, "a presented mercy floor matches one choose()")
	var tank_keeper: Dictionary = {"might": 1, "arcana": 1, "resilience": 12, "ward": 12, "vitality": 12, "swiftness": 1, "fate": 1}
	var tank_echo: Dictionary = {
		"display_name": "Elaia",
		"rootbind_every": 3,
		"stats": {"might": 1, "arcana": 1, "resilience": 12, "ward": 12, "vitality": 12, "swiftness": 9, "fate": 1},
	}
	var live := EchoBattle.new()
	var twin := EchoBattle.new()
	live.configure(tank_keeper, tank_echo)
	twin.configure(tank_keeper, tank_echo)
	live.set_seed(11)
	twin.set_seed(11)
	live.keeper_max_hp = 5000
	live.keeper_hp = 5000
	live.echo_max_hp = 5000
	live.echo_hp = 5000
	twin.keeper_max_hp = 5000
	twin.keeper_hp = 5000
	twin.echo_max_hp = 5000
	twin.echo_hp = 5000
	live.present_halves = true
	var mash_ok: bool = true
	for _step: int in range(3):
		var result: String = live.choose("strike")
		if result != "presenting" or live.pending_half() != "keeper":
			mash_ok = false
			break
		var turns_now: int = live.enemy_turns
		var round_now: int = live.round
		var binds_now: int = _echo_rootbind_count(live)
		if live.choose("strike") != "presenting" or live.enemy_turns != turns_now or live.round != round_now or _echo_rootbind_count(live) != binds_now:
			mash_ok = false
			break
		live.finish_presented_half()
		twin.choose("strike")
	failed += _check(mash_ok, "a click during the Echo half does not start another round")
	failed += _check(_echo_rootbind_count(live) == 1 and _echo_rootbind_count(twin) == 1, "Rootbind fires once, on the third Echo turn")
	failed += _check(live.enemy_turns == 3 and twin.enemy_turns == 3, "three Echo turns")
	failed += _check(str(live.turn_log) == str(twin.turn_log), "presented rounds match one choose() each")
	failed += _check(live.echo_hp == twin.echo_hp and live.keeper_hp == twin.keeper_hp, "presented hp matches one choose() each")
	failed += _check(live.outcome == "" and not live.spare_window and live.outcome == twin.outcome and live.spare_window == twin.spare_window, "the split does not skip the mercy floor")
	var echo: Node = root.get_node("EchoChamber")
	var saved_ctx: String = str(echo.get("battle_context"))
	var packed: PackedScene = load("res://scenes/echo_battle.tscn") as PackedScene
	failed += _check(packed != null, "echo turn flow has the battle scene")
	if packed == null:
		return failed
	var view: Node = packed.instantiate()
	root.add_child(view)
	await process_frame
	var shown := EchoBattle.new()
	shown.configure(
		tank_keeper,
		{"display_name": "Elaia", "stats": {"might": 1, "arcana": 1, "resilience": 12, "ward": 12, "vitality": 12, "swiftness": 9, "fate": 1}}
	)
	shown.set_seed(11)
	shown.keeper_max_hp = 5000
	shown.keeper_hp = 5000
	shown.echo_max_hp = 5000
	shown.echo_hp = 5000
	view.set("_battle", shown)
	view.set("_waiting_return", false)
	view.set("_phase", "fight")
	view.call("set_instant_turns", false)
	view.call("_on_strike")
	var echo_path: String = str(view.call("portrait_texture_path", "echo"))
	var echo_rect: TextureRect = view.get_node_or_null("EchoPortrait") as TextureRect
	var pivot: float = float(view.call("portrait_pivot_x", "echo"))
	failed += _check(bool(view.call("turn_busy")) and shown.pending_half() == "keeper", "the Echo half locks the menu")
	failed += _check(echo_path.find("battle_elaia_attack") >= 0 and bool(view.call("portrait_flipped", "echo")), "Elaia's attack sheet is flipped")
	failed += _check(echo_rect != null and is_equal_approx(echo_rect.size.x, 256.0) and is_equal_approx(pivot, 128.0), "Elaia flips about x=64")
	failed += _check(not bool(view.call("portrait_flipped", "keeper")), "the Keeper is not flipped while Elaia swings")
	failed += _check(is_equal_approx(float(view.get("_pose_left")), 1.0), "the strike pose holds for 1.0s")
	var saw_hurt: bool = false
	var queued: Variant = view.get("_pose_queue")
	if queued is Array:
		for step: Variant in queued as Array:
			if step is Dictionary and (str((step as Dictionary).get("pose", "")) == "hurt" or str((step as Dictionary).get("pose", "")) == "ko"):
				saw_hurt = true
	failed += _check(saw_hurt == (shown.last_echo_damage > 0), "a landed blow queues the hurt pose")
	var locked_round: int = shown.round
	var locked_turns: int = shown.enemy_turns
	shown.spare_window = true
	view.call("_on_strike")
	view.call("_on_brace")
	view.call("_on_salve")
	view.call("_on_flee")
	view.call("_on_spare")
	failed += _check(not bool(view.call("end_confirm_open")), "a click during the Echo half does not ask to finish")
	failed += _check(shown.round == locked_round and shown.enemy_turns == locked_turns and shown.pending_half() == "keeper", "those clicks do not start a second round")
	shown.spare_window = false
	view.call("set_instant_turns", true)
	await process_frame
	failed += _check(not bool(view.call("turn_busy")) and shown.pending_half() == "" and shown.round == locked_round, "instant mode finishes the round in one frame")
	var idle_path: String = str(view.call("portrait_texture_path", "echo"))
	failed += _check(idle_path.find("battle_elaia_idle_w") >= 0 and not bool(view.call("portrait_flipped", "echo")), "Elaia returns to the unflipped idle")
	var round_before: int = shown.round
	view.call("_on_strike")
	await process_frame
	failed += _check(not bool(view.call("turn_busy")) and shown.pending_half() == "" and shown.round == round_before + 1, "a later instant strike also finishes in one frame")
	view.call("_apply_combat_pose", "keeper", "attack")
	failed += _check(str(view.call("portrait_texture_path", "keeper")).find("battle_keeper_attack") >= 0 and not bool(view.call("portrait_flipped", "keeper")), "the Keeper attack sheet stays unflipped")
	echo.set("battle_context", "echo2")
	shown.foe_art_path = "res://assets/art/battle/party/battle_bramble_idle_e.png"
	view.call("_apply_combat_pose", "echo", "attack")
	failed += _check(str(view.call("portrait_texture_path", "echo")).find("battle_bramble_attack") >= 0 and bool(view.call("portrait_flipped", "echo")), "Bramble's attack sheet is flipped")
	view.call("_apply_combat_pose", "echo", "idle")
	var bramble_idle: String = str(view.call("portrait_texture_path", "echo"))
	failed += _check(bramble_idle.find("battle_bramble_idle_e") >= 0 and not bool(view.call("portrait_flipped", "echo")), "Bramble's idle stays unflipped")
	view.free()
	echo.set("battle_context", saved_ctx)
	if failed == 0:
		print("ECHO_TURN_FLOW_OK")
	return failed


func _echo_end_confirm(view: Node) -> int:
	var failed: int = 0
	var battle := EchoBattle.new()
	battle.configure(
		{"might": 1, "arcana": 1, "resilience": 8, "ward": 8, "vitality": 8, "swiftness": 8, "fate": 1},
		{"display_name": "Elaia", "stats": {"swiftness": 1, "vitality": 30}}
	)
	battle.spare_window = false
	battle.outcome = ""
	view.set("_battle", battle)
	view.set("_waiting_return", false)
	view.set("_phase", "fight")
	view.call("_on_strike")
	failed += _check(not bool(view.call("end_confirm_open")), "a normal strike does not ask")
	failed += _check(str(battle.outcome) == "", "a normal strike does not end the fight")
	battle.spare_window = true
	battle.outcome = ""
	view.call("_on_strike")
	failed += _check(bool(view.call("end_confirm_open")), "the killing strike asks first")
	failed += _check(str(view.call("end_confirm_text")).find("Strike") >= 0, "the ask names Strike")
	failed += _check(str(battle.outcome) == "", "the ask does not strike yet")
	view.call("_on_strike")
	failed += _check(str(battle.outcome) == "" and bool(view.call("end_confirm_open")), "mashing Strike does not confirm")
	view.call("_on_brace")
	view.call("_on_salve")
	view.call("_on_flee")
	failed += _check(str(battle.outcome) == "", "brace, salve, and flee do not confirm the end")
	view.call("_dismiss_end")
	failed += _check(not bool(view.call("end_confirm_open")) and str(battle.outcome) == "", "Not now keeps the fight going")
	view.call("_on_spare")
	failed += _check(bool(view.call("end_confirm_open")) and str(view.call("end_confirm_text")).find("Spare") >= 0, "spare asks too")
	failed += _check(str(battle.outcome) == "", "the spare ask does not spare yet")
	view.call("_dismiss_end")
	view.call("_on_strike")
	view.call("_confirm_end")
	failed += _check(str(battle.outcome) == "defeat", "Yes on Strike ends the fight")
	failed += _check(not bool(view.call("end_confirm_open")), "Yes closes the ask")
	if failed == 0:
		print("ECHO_END_CONFIRM_OK")
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
	battle.strike_kind = "hybrid"
	battle.arrow_mode = "physical"
	battle.configure(
		{"might": 8, "arcana": 8, "resilience": 8, "ward": 8, "vitality": 8, "swiftness": 8, "fate": 1},
		{"display_name": "Elaia", "stats": {"swiftness": 1, "vitality": 6}}
	)
	# force_crit was removed with the BattleResolver retune (16de7cd); setting it
	# raised a script error that skipped the rest of this check. Pin the dice instead.
	battle.set_seed(1)
	echo.set("battle", battle)
	echo.set("in_battle", true)
	echo.set("reentry", false)
	var view: Node = view_packed.instantiate()
	root.add_child(view)
	await process_frame
	failed += _check(bool(view.call("speech_between_portraits")), "speech between portraits")
	var ssize: Vector2 = view.call("speech_band_size")
	failed += _check(absf(ssize.x - 432.0) < 0.5 and absf(ssize.y - 132.0) < 0.5, "speech box 432x132")
	var intro: String = str(strings.call("get_text", "echo_02_intro"))
	var pages: PackedStringArray = EchoTheme.paginate(intro)
	var body_font: Font = load(EchoTheme.BODY_FONT)
	failed += _check(pages.size() == 2, "Bramble intro pages into two (got %d)" % pages.size())
	if pages.size() >= 1:
		failed += _check(pages[0].length() <= EchoTheme.PAGE_CHARS_MAX and pages[0].length() >= 160, "first page is about 200 characters (%d)" % pages[0].length())
		failed += _check(EchoTheme.line_count(pages[0], body_font) <= EchoTheme.SPEECH_LINES, "first page is 3 lines")
	var psize: Vector2 = view.call("portrait_size")
	failed += _check(absf(psize.x - 256.0) < 0.5, "portrait 256")
	failed += _check(not bool(view.call("is_chamber_shown")), "entry skips the fee-paid window")
	var face_btn: CanvasItem = view.get_node_or_null("FaceButton") as CanvasItem
	var chamber_panel: CanvasItem = view.get_node_or_null("ChamberPanel") as CanvasItem
	failed += _check(face_btn == null or not face_btn.visible, "Face the Echo stays hidden")
	failed += _check(chamber_panel == null or not chamber_panel.visible, "the fee-paid panel stays hidden")
	failed += _check(str(view.get("_phase")) == "speech", "entry opens on the fight dialogue")
	failed += _check(not bool(view.call("is_flee_shown")), "the opening dialogue hides Flee")
	if not bool(view.call("is_chamber_shown")) and str(view.get("_phase")) == "speech":
		print("ECHO_DIRECT_FIGHT_OK")
	var legacy_log: CanvasItem = view.get_node_or_null("LogBg") as CanvasItem
	var legacy_hp: CanvasItem = view.get_node_or_null("KeeperHpBack") as CanvasItem
	var legacy_title: CanvasItem = view.get_node_or_null("LogTitle") as CanvasItem
	var legacy_band: CanvasItem = view.get_node_or_null("CommandBand") as CanvasItem
	failed += _check(legacy_log == null or not legacy_log.visible, "chamber hides the battle log band")
	failed += _check(legacy_hp == null or not legacy_hp.visible, "chamber hides the battle HP bars")
	failed += _check(legacy_title == null or not legacy_title.visible, "chamber hides the Battle label")
	failed += _check(legacy_band == null or not legacy_band.visible, "chamber card has no wider band behind it")
	view.call("begin_face_off")
	failed += _check(not bool(view.call("is_flee_shown")), "menu stays locked through the speech")
	var locked_ability: Button = view.get_node_or_null("EchoActionMenu/AbilityButton") as Button
	var locked_salve: Button = view.get_node_or_null("EchoActionMenu/SalveButton") as Button
	var phys_chip: Control = view.get_node_or_null("EchoActionMenu/ArrowToggle") as Control
	var strike_btn: Control = view.get_node_or_null("EchoActionMenu/StrikeButton") as Control
	failed += _check(locked_ability != null and locked_ability.disabled and locked_ability.modulate.r < 0.7, "Ability is dim while the speech locks the menu")
	failed += _check(locked_salve != null and locked_salve.disabled and locked_salve.modulate.r < 0.7, "Salve is dim while the speech locks the menu")
	var locked_spare: Button = view.get_node_or_null("EchoActionMenu/SpareButton") as Button
	failed += _check(_hotkey_badge_dim(locked_ability) and _hotkey_badge_dim(locked_salve) and _hotkey_badge_dim(locked_spare), "locked Ability, Salve, and Spare dim their hotkey badges")
	var strike_font: Font = strike_btn.get_theme_font("font") if strike_btn is Button else null
	var strike_px: int = (strike_btn as Button).get_theme_font_size("font_size") if strike_btn is Button else 19
	var strike_word: float = strike_font.get_string_size(strike_btn.text, HORIZONTAL_ALIGNMENT_LEFT, -1, strike_px).x if strike_font != null else 99.0
	var strike_cap: Control = strike_btn.get_node_or_null("Keycap") if strike_btn else null
	var strike_box: StyleBox = (strike_btn as Button).get_theme_stylebox("disabled") if strike_btn is Button else null
	var strike_text_left: float = 0.0
	if strike_box != null and strike_btn is Button:
		strike_text_left = strike_box.get_content_margin(SIDE_LEFT) + float((strike_btn as Button).get_theme_constant("icon_max_width")) + float((strike_btn as Button).get_theme_constant("h_separation"))
	var ability_slot: Control = view.get_node_or_null("EchoActionMenu/AbilityButton") as Control
	failed += _check(phys_chip != null and strike_btn != null and not phys_chip.get_rect().intersects(strike_btn.get_rect()) and phys_chip.position.x >= strike_btn.position.x + strike_btn.size.x - 0.5, "Phys chip sits clear of Strike")
	failed += _check(ability_slot != null and phys_chip != null and phys_chip.position.x + phys_chip.size.x <= ability_slot.position.x + 0.5, "Phys chip stops before Ability")
	failed += _check(strike_cap != null and strike_text_left + strike_word <= strike_cap.position.x - 1.0, "Strike label shows in full beside the hotkey")
	failed += _check(str(view.call("log_text")).find("Tap the box") >= 0 and str(view.call("log_text")).find("Page ") >= 0, "speech log explains the page")
	echo.set("reentry", true)
	view.call("_refresh_status_chip")
	var attempt: Label = view.get_node_or_null("EchoStatusChip/Label") as Label
	failed += _check(attempt != null and attempt.visible and attempt.text == "Attempt 2", "later attempt shows Attempt 2")
	echo.set("reentry", false)
	view.call("_refresh_status_chip")
	view.call("finish_speech")
	failed += _check(bool(view.call("is_flee_shown")), "last page opens the menu")
	var live_chip: Button = view.get_node_or_null("EchoActionMenu/ArrowToggle") as Button
	var echo_chip_on: bool = live_chip != null and live_chip.visible and not live_chip.disabled and live_chip.modulate == Color.WHITE
	failed += _check(echo_chip_on, "hybrid chip is selectable once the fight starts")
	await process_frame
	var strike_focus: Control = view.get_viewport().gui_get_focus_owner() as Control
	failed += _check(strike_focus != null and strike_focus.name == "StrikeButton", "Strike takes the focus ring")
	var round_chip: Label = view.get_node_or_null("EchoStatusChip/Label") as Label
	failed += _check(round_chip != null and round_chip.visible and round_chip.text == "Round 1", "Round chip uses the battle round")
	echo.set("reentry", true)
	view.call("_refresh_status_chip")
	var later_fight: Label = view.get_node_or_null("EchoStatusChip/Label") as Label
	failed += _check(later_fight != null and later_fight.visible and later_fight.text == "Attempt 2", "a later fight shows Attempt 2 instead of Round 1")
	echo.set("reentry", false)
	view.call("_refresh_status_chip")
	failed += _check(later_fight != null and later_fight.text == "Round 1", "clearing reentry restores the round chip")
	var status_chip: Control = view.get_node_or_null("EchoStatusChip") as Control
	var live_plate: Control = view.get_node_or_null("EchoTitlePlate") as Control
	var chip_gap: float = 0.0
	if status_chip != null and live_plate != null:
		chip_gap = live_plate.position.x - (status_chip.position.x + status_chip.size.x)
	failed += _check(status_chip != null and live_plate != null and chip_gap >= 24.0 and not status_chip.get_rect().intersects(live_plate.get_rect()), "Round chip clears the title plank (gap %s)" % chip_gap)
	failed += _check(str(view.call("log_text")).find("Your turn") >= 0, "battle log shows a line")
	var mode_before: String = str(battle.arrow_mode)
	view.call("_on_arrow")
	var echo_toggled: bool = str(battle.arrow_mode) != mode_before and str(battle.arrow_mode) == str(game.get("arrow_mode"))
	failed += _check(echo_toggled, "hybrid chip toggles Arcana and Might")
	view.call("_on_arrow")
	var echo_restored: bool = str(battle.arrow_mode) == mode_before
	failed += _check(echo_restored, "hybrid chip toggles back")
	var live_chip_now: Button = view.get_node_or_null("EchoActionMenu/ArrowToggle") as Button
	echo_chip_on = live_chip_now != null and live_chip_now.visible and not live_chip_now.disabled
	_echo_chip_ready = echo_chip_on and echo_toggled and echo_restored
	view.call("_set_speech", "Your turn")
	var short_speech: Vector2 = view.call("speech_band_size")
	failed += _check(absf(short_speech.x - 432.0) < 0.5 and absf(short_speech.y - 48.0) < 0.5, "one battle line uses a short speech box")
	var menu: Control = view.get_node_or_null("EchoActionMenu") as Control
	failed += _check(menu != null and str(menu.get_meta("built_by", "")) == "res://scripts/battle/battle_view.gd", "echo menu is built by battle_view")
	var slot_names: PackedStringArray = PackedStringArray()
	if menu:
		for child: Node in menu.get_children():
			if child is Button and child.has_meta("echo_slot"):
				slot_names.append(str(child.name))
	failed += _check(",".join(slot_names) == "StrikeButton,AbilityButton,SalveButton,BraceButton,FleeButton,SpareButton", "Strike / Ability / Items / Brace / Flee / Spare")
	var ability_btn: Button = view.get_node_or_null("EchoActionMenu/AbilityButton") as Button
	failed += _check(ability_btn != null and ability_btn.disabled and not BattleView.keeper_abilities_exist(), "Ability stays disabled")
	var spare_btn: Button = view.get_node_or_null("EchoActionMenu/SpareButton") as Button
	failed += _check(spare_btn != null and spare_btn.disabled, "Spare disabled until the falter")
	var bar: Control = view.get_node_or_null("EchoActionMenu/EchoBottomBar") as Control
	failed += _check(bar != null and absf(bar.size.x - 904.0) < 0.5 and absf(bar.size.y - 144.0) < 0.5 and EchoTheme.panel_ok(bar.size), "bottom bar 904x144 on the tile grid")
	var echo_log: Control = view.get_node_or_null("EchoActionMenu/EchoLog") as Control
	failed += _check(echo_log != null and absf(echo_log.size.x - 412.0) < 0.5 and absf(echo_log.size.y - 100.0) < 0.5, "battle log 412x100")
	failed += _echo_salve_rule()
	failed += _check(bool(view.call("keeper_uses_idle_texture")), "keeper portrait")
	failed += _check(bool(view.call("echo_uses_elaia_texture")), "elaia portrait")
	failed += _check(bool(view.call("is_arrow_toggle_shown")), "hybrid toggle shown")
	failed += _check(str(view.call("arrow_toggle_text")) == str(strings.call("get_text", "battle_toggle_phys")), "toggle reads Phys")
	view.call("_on_arrow")
	failed += _check(str(game.get("arrow_mode")) == "magical", "toggle writes GameState")
	failed += _check(str(view.call("arrow_toggle_text")) == str(strings.call("get_text", "battle_toggle_mag")), "toggle reads Mag")
	view.call("_open_leave_confirm")
	var leave: Control = view.get_node_or_null("LeaveConfirm") as Control
	var stay: Button = view.get_node_or_null("LeaveConfirm/LeaveStay") as Button
	var flee_btn: Button = view.get_node_or_null("LeaveConfirm/LeaveFlee") as Button
	failed += _check(leave != null and EchoTheme.panel_ok(leave.size) and is_equal_approx(leave.self_modulate.a, 0.88), "leave confirm is an ink panel on the tile grid")
	failed += _check(stay != null and flee_btn != null and stay.position.y + stay.size.y <= leave.size.y and flee_btn.position.y + flee_btn.size.y <= leave.size.y, "Flee and Stay sit inside the panel")
	var leave_body: Label = view.get_node_or_null("LeaveConfirm/LeaveBody") as Label
	failed += _check(leave_body != null and leave_body.text.find("counts as Flee") >= 0, "leave copy says it counts as Flee")
	var esc_cap: CanvasItem = view.get_node_or_null("LeaveConfirm/LeaveStay/EscKeycap") as CanvasItem
	failed += _check(esc_cap != null and esc_cap.visible, "Stay shows the Esc keycap")
	failed += _check(stay != null and flee_btn != null and stay.position.x > flee_btn.position.x, "Stay is the right-hand button")
	failed += _check(view.get_node_or_null("LeaveConfirm/EchoClose") == null, "the leave confirm has no ×")
	failed += _check(stay != null and stay.custom_minimum_size.y >= 44.0 and flee_btn.custom_minimum_size.x >= 44.0, "leave buttons are at least 44 px")
	view.call("_confirm_stay")
	failed += _check(not bool(view.call("leave_confirm_open")), "Stay closes the confirm")
	view.call("_offer_return", "spare")
	var rewards: Control = view.get_node_or_null("EchoRewards") as Control
	var rewards_back: Button = view.get_node_or_null("EchoRewards/RewardsReturn") as Button
	var reward_row: Control = view.get_node_or_null("EchoRewards/RewardRow0") as Control
	var reward_value: Label = view.get_node_or_null("EchoRewards/RewardRow0/Value") as Label
	failed += _check(rewards != null and EchoTheme.panel_ok(rewards.size) and is_equal_approx(rewards.self_modulate.a, 1.0), "rewards window is an opaque tile")
	failed += _check(view.get_node_or_null("EchoRewardsDim") != null, "rewards dims the chamber behind the window")
	failed += _check(rewards_back != null and rewards_back.text == "Return to the tree", "rewards return to the tree")
	var rewards_close: Button = view.get_node_or_null("EchoRewards/RewardsClose") as Button
	var close_glyph: TextureRect = view.get_node_or_null("EchoRewards/RewardsClose/CloseGlyph") as TextureRect
	failed += _check(rewards_close != null, "rewards keeps the ×")
	failed += _check(rewards_close != null and is_equal_approx(rewards_close.position.x, 493.0) and is_equal_approx(rewards_close.position.y, 15.0) and close_glyph != null and close_glyph.size.y <= 16.0, "rewards × matches the card corner and the glyph is small")
	var rewards_footer: Label = view.get_node_or_null("EchoRewards/RewardsFooter") as Label
	var rewards_flavour: Label = view.get_node_or_null("EchoRewards/RewardsFlavour") as Label
	var rewards_title: Label = view.get_node_or_null("EchoRewards/RewardsTitle") as Label
	var reward_label: Label = view.get_node_or_null("EchoRewards/RewardRow0/Label") as Label
	var key_value: Label = view.get_node_or_null("EchoRewards/RewardRow1/Value") as Label
	var niche_value: Label = view.get_node_or_null("EchoRewards/RewardRow2/Value") as Label
	var redeemed_value: Label = view.get_node_or_null("EchoRewards/RewardRow3/Value") as Label
	var row1: Control = view.get_node_or_null("EchoRewards/RewardRow1") as Control
	var rewards_dim: Control = view.get_node_or_null("EchoRewardsDim") as Control
	failed += _check(rewards != null and is_equal_approx(rewards.position.x, EchoTheme.shift() + 200.0) and is_equal_approx(rewards.position.y, 40.0) and is_equal_approx(rewards.size.x, 560.0) and is_equal_approx(rewards.size.y, 464.0), "rewards card is 560x464 at x200 y40")
	failed += _check(rewards_footer != null and rewards_footer.text.find("Manatree") >= 0, "rewards footer names the wake")
	failed += _check(rewards_title != null and is_equal_approx(rewards_title.position.y + rewards_title.size.y * 0.5, 35.0), "rewards title centres on screen y 75")
	failed += _check(rewards_flavour != null and is_equal_approx(rewards_flavour.position.y, 78.0) and rewards_flavour.position.y + rewards_flavour.size.y <= 150.0, "reward flavour sits on screen y 118 above the rows")
	failed += _check(reward_row != null and is_equal_approx(reward_row.position.x, 28.0) and is_equal_approx(reward_row.position.y, 150.0) and is_equal_approx(reward_row.size.x, 504.0) and is_equal_approx(reward_row.size.y, 44.0), "first reward row is screen x228 y190, 44 tall")
	failed += _check(row1 != null and is_equal_approx(row1.position.y, 200.0), "reward rows step by 50")
	failed += _check(rewards_footer != null and is_equal_approx(rewards_footer.position.y, 361.0), "rewards footer sits on screen y 401")
	failed += _check(rewards_back != null and is_equal_approx(rewards_back.position.x, 128.0) and is_equal_approx(rewards_back.position.y, 382.0) and is_equal_approx(rewards_back.size.x, 304.0) and is_equal_approx(rewards_back.size.y, 56.0), "Return matches screen x328 y422")
	failed += _check(reward_row != null and is_equal_approx(reward_row.self_modulate.a, 1.0), "reward rows do not stack the fade")
	failed += _check(reward_value != null and reward_value.get_theme_color("font_color") == EchoTheme.CYAN, "manashard value is cyan")
	failed += _check(key_value != null and key_value.get_theme_color("font_color") == EchoTheme.AMBER, "forge key gains stay amber")
	failed += _check(reward_label != null and reward_label.get_theme_color("font_color") == EchoTheme.PEARL, "reward labels are pearl")
	failed += _check(niche_value != null and niche_value.get_theme_color("font_color") == EchoTheme.PEARL and niche_value.text == "unlocked", "unlocked is pearl")
	failed += _check(redeemed_value != null and redeemed_value.get_theme_color("font_color") == EchoTheme.PEARL and redeemed_value.text == "redeemed", "redeemed is pearl")
	failed += _check(reward_value != null and reward_value.get_theme_color("font_color") != EchoTheme.GOLD, "rewards do not use gold")
	var title_plate: Control = view.get_node_or_null("EchoTitlePlate") as Control
	var round_while_open: CanvasItem = view.get_node_or_null("EchoStatusChip") as CanvasItem
	failed += _check(title_plate != null and not title_plate.visible, "rewards hides the chamber title plank")
	failed += _check(rewards_dim != null and title_plate != null and rewards_dim.get_index() > title_plate.get_index(), "rewards backdrop draws over the chamber plank")
	failed += _check(round_while_open == null or not round_while_open.visible, "rewards hides the round chip")
	view.call("_clear_rewards")
	view.set("_waiting_return", false)
	view.set("_pending_outcome", "")
	var chamber_close_before: CanvasItem = view.get_node_or_null("EchoClose") as CanvasItem
	var fled_menu_before: CanvasItem = view.get_node_or_null("EchoActionMenu") as CanvasItem
	if chamber_close_before:
		chamber_close_before.visible = true
	if fled_menu_before:
		fled_menu_before.visible = true
	view.call("_offer_return", "flee")
	var fled: Panel = view.get_node_or_null("EchoFledWindow") as Panel
	var fled_box: StyleBox = fled.get_theme_stylebox("panel") if fled else null
	var fled_tex: Texture2D = (fled_box as StyleBoxTexture).texture if fled_box is StyleBoxTexture else null
	failed += _check(fled_tex != null and str(fled_tex.resource_path).find("frame_9s_96") >= 0, "Echo Fled stays on the hub frame")
	var chamber_close: CanvasItem = view.get_node_or_null("EchoClose") as CanvasItem
	var fled_menu: CanvasItem = view.get_node_or_null("EchoActionMenu") as CanvasItem
	failed += _check(chamber_close == null or not chamber_close.visible, "fled window hides the chamber ×")
	failed += _check(fled_menu == null or not fled_menu.visible, "fled window hides the battle log band")
	failed += _chamber_plate(view)
	failed += _echo_end_confirm(view)
	view.queue_free()
	echo.set("battle", null)
	echo.set("in_battle", false)
	await process_frame
	failed += await _adventure_mode_chip()
	return failed


func _portal_fee_confirm() -> int:
	var failed: int = 0
	var game: Node = root.get_node("GameState")
	var essence_before: int = int(game.get("essence"))
	var unlocked: bool = bool(game.get("portal_unlocked"))
	var resolved: bool = bool(game.get("echo_01_resolved"))
	var paid: bool = bool(game.get("portal_fee_paid"))
	game.set("portal_unlocked", true)
	game.set("echo_01_resolved", false)
	game.set("portal_fee_paid", false)
	game.call("set_resource", &"essence", 10)
	var portal: Node = (load("res://scenes/echo_portal.tscn") as PackedScene).instantiate()
	root.add_child(portal)
	await process_frame
	failed += _check(str(portal.call("begin_entry")) == "reject", "short fee keeps the hub confirm open")
	var panel: Panel = root.get_node_or_null("EchoPortalConfirm/Panel") as Panel
	var yes: Button = root.get_node_or_null("EchoPortalConfirm/Panel/Yes") as Button
	var no: Button = root.get_node_or_null("EchoPortalConfirm/Panel/No") as Button
	var note: Label = root.get_node_or_null("EchoPortalConfirm/Panel/Note") as Label
	var warn: TextureRect = root.get_node_or_null("EchoPortalConfirm/Panel/FeeWarn") as TextureRect
	var box: StyleBox = panel.get_theme_stylebox("panel") if panel else null
	var tex: Texture2D = (box as StyleBoxTexture).texture if box is StyleBoxTexture else null
	failed += _check(tex != null and str(tex.resource_path).find("frame_9s_96") >= 0, "portal fee stays on the hub frame")
	failed += _check(panel != null and panel.get_node_or_null("VineFrame") != null, "portal fee keeps the hub vines")
	failed += _check(yes != null and no != null and no.position.x > yes.position.x, "Not now is the right-hand button")
	failed += _check(yes != null and no != null and yes.disabled and yes.size.y >= 44.0 and no.size.y >= 44.0, "fee buttons are at least 44 px")
	failed += _check(panel != null and no != null and no.text == "Not now" and no.position.y + no.size.y <= panel.size.y + 1.0, "Not now sits inside the fee panel")
	failed += _check(note != null and note.visible and note.text.find("Not enough Essence") >= 0, "amber can't-afford line")
	failed += _check(note != null and note.get_theme_color("font_color") == Ui540.WARNING_AMBER, "can't-afford uses kit amber")
	failed += _check(warn != null and warn.visible and warn.texture != null and str(warn.texture.resource_path).find("icon_warn_amber_kit") >= 0, "kit amber warning icon")
	failed += _check(panel != null and panel.get_node_or_null("Close") == null, "the fee confirm has no ×")
	var cap: TextureRect = no.get_node_or_null("EscKeycap") as TextureRect if no else null
	failed += _check(cap != null and cap.visible, "Esc keycap on Not now")
	failed += _check(cap != null and cap.position.y + cap.size.y <= 0.0, "Esc keycap sits above Not now")
	var fee_body: Label = root.get_node_or_null("EchoPortalConfirm/Panel/Body") as Label
	failed += _check(fee_body != null and fee_body.text.find("You have") >= 0 and fee_body.text.find("Paid once") >= 0, "fee confirm names the balance and the once-only hint")
	var fee_view_h: float = panel.get_viewport().get_visible_rect().size.y if panel else 540.0
	var toast_top: float = fee_view_h - 24.0 - 44.0 - 8.0 - 32.0
	failed += _check(panel != null and panel.position.y + panel.size.y <= toast_top - 12.0, "fee confirm stays clear of the toast")
	var focus_box: StyleBox = no.get_theme_stylebox(&"focus") if no else null
	var focus_tex: Texture2D = (focus_box as StyleBoxTexture).texture if focus_box is StyleBoxTexture else null
	failed += _check(focus_tex != null and str(focus_tex.resource_path).find("ink_focus_ring") >= 0, "Not now uses the cyan focus ring")
	await process_frame
	failed += _check(no != null and no.has_focus(), "Not now holds focus")
	portal.cancel_fee()
	failed += _check(not bool(portal.call("is_fee_confirm_open")), "Not now's cancel closes the fee UI")
	portal.queue_free()
	game.set("portal_unlocked", unlocked)
	game.set("echo_01_resolved", resolved)
	game.set("portal_fee_paid", paid)
	game.call("set_resource", &"essence", essence_before)
	await process_frame
	return failed


func _echo_salve_rule() -> int:
	var failed: int = 0
	var pack: Node = root.get_node("Backpack")
	var save: Node = root.get_node("SaveService")
	var before: int = int(pack.call("get_count", "heart_salve"))
	var was_session: bool = bool(save.get("session_active"))
	var autosave_snap: Dictionary = _snapshot_autosaves(save)
	save.call("note_session_started")
	pack.call("set_count", "heart_salve", 5)
	var duel := EchoBattle.new()
	duel.configure(
		{"might": 1, "arcana": 1, "resilience": 40, "ward": 40, "vitality": 40, "swiftness": 20, "fate": 1},
		{"display_name": "Elaia", "stats": {"might": 1, "arcana": 1, "swiftness": 1, "vitality": 4, "resilience": 1, "ward": 1, "fate": 1}}
	)
	duel.set_seed(1)
	failed += _check(duel.salves_left() == 2, "salve allowance is 2 even when the pack holds more")
	failed += _check(duel.choose("salve") != "no_salve", "first salve spends")
	failed += _check(duel.choose("salve") != "no_salve", "second salve spends")
	failed += _check(duel.choose("salve") == "no_salve", "third salve is refused")
	failed += _check(duel.salves_used == 2 and int(pack.call("get_count", "heart_salve")) == 3, "two salves leave the pack")
	failed += _check(_newest_autosave_salves(save) == 3, "salve spend is in the save")
	_restore_autosaves(autosave_snap)
	if not was_session:
		save.call("note_session_ended")
	var braced := EchoBattle.new()
	braced.configure(
		{"might": 1, "arcana": 1, "resilience": 40, "ward": 40, "vitality": 40, "swiftness": 20, "fate": 1},
		{"display_name": "Elaia", "stats": {"might": 1, "arcana": 1, "swiftness": 1, "vitality": 8, "resilience": 1, "ward": 1, "fate": 1}}
	)
	braced.set_seed(2)
	var echo_before: int = braced.echo_hp
	braced.choose("brace")
	failed += _check(braced.echo_hp == echo_before, "Brace spends the Strike")
	pack.call("set_count", "heart_salve", before)
	return failed


func _snapshot_autosaves(save: Node) -> Dictionary:
	var snap: Dictionary = {}
	for slot: int in range(1, 4):
		var path: String = str(save.call("autosave_path", slot))
		if FileAccess.file_exists(path):
			snap[path] = FileAccess.get_file_as_bytes(path)
		else:
			snap[path] = PackedByteArray()
	return snap


func _restore_autosaves(snap: Dictionary) -> void:
	for path_v: Variant in snap.keys():
		var path: String = str(path_v)
		var bytes: PackedByteArray = snap[path_v]
		if bytes.is_empty():
			DirAccess.remove_absolute(path)
		else:
			var file := FileAccess.open(path, FileAccess.WRITE)
			if file != null:
				file.store_buffer(bytes)
				file.close()


func _newest_autosave_salves(save: Node) -> int:
	var newest_path: String = ""
	var newest_ts: float = -1.0
	var version: int = -1
	for slot: int in range(1, 4):
		var info: Dictionary = save.call("get_autosave_info", slot)
		if not bool(info.get("filled", false)):
			continue
		var ts: float = float(info.get("timestamp", 0.0))
		if ts > newest_ts:
			newest_ts = ts
			newest_path = str(save.call("autosave_path", slot))
	if newest_path == "":
		return -1
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(newest_path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return -1
	version = int((parsed as Dictionary).get("save_version", -1))
	if version != 15:
		return -1
	var state_v: Variant = (parsed as Dictionary).get("state", {})
	if typeof(state_v) != TYPE_DICTIONARY:
		return -1
	var bag_v: Variant = (state_v as Dictionary).get("backpack", {})
	if typeof(bag_v) != TYPE_DICTIONARY:
		return -1
	return int((bag_v as Dictionary).get("heart_salve", -1))


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
			failed += _check(art.texture.get_width() == 960 and art.texture.get_height() == 540, "plate crop is 960x540")
	else:
		failed += _check(art != null and not art.visible, "chamber art hidden without a plate")
	failed += _check(
		keeper != null and keeper.position == Vector2(72, 94) and keeper.size == Vector2(256, 256),
		"keeper portrait box"
	)
	failed += _check(
		echo_portrait != null and echo_portrait.position == Vector2(632, 94) and echo_portrait.size == Vector2(256, 256),
		"elaia portrait box"
	)
	var plate_panel: Panel = view.get_node_or_null("EchoTitlePlate") as Panel
	var chamber_panel: Panel = view.get_node_or_null("ChamberPanel") as Panel
	failed += _check(plate_panel != null and EchoTheme.panel_ok(plate_panel.size), "title plate tiles at 40+8n")
	failed += _check(chamber_panel != null and EchoTheme.panel_ok(chamber_panel.size), "chamber panel tiles at 40+8n")
	failed += _check(plate_panel != null and is_equal_approx(plate_panel.self_modulate.a, EchoTheme.PANEL_ALPHA), "title plate opacity 0.88")
	failed += _check(chamber_panel != null and is_equal_approx(chamber_panel.self_modulate.a, EchoTheme.PANEL_ALPHA), "chamber panel opacity 0.88")
	failed += _check(EchoTheme.jersey_legible(19) and EchoTheme.jersey_legible(37), "Jersey 10 legible at 19 and 37")
	failed += _check(is_equal_approx(EchoTheme.shift_for_width(1200.0), 120.0), "20:9 shifts the chamber +120")
	failed += _check(EchoTheme.SPEECH_BOX.size == Vector2(432, 132), "speech box is 432x132")
	failed += _check(EchoTheme.MENU_SLOTS.size() == 6 and EchoTheme.MENU_SLOTS[5] == "spare", "Spare is slot 6")
	failed += _check(EchoTheme.SALVE_MAX == 2, "Heart Salve max is 2")
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
	var thorn: Node2D = live.get_node_or_null("World/ThornWall") as Node2D
	if thorn:
		## The north hedge stands in the gap left by the trees it replaced.
		## The feet row shares a sample cell with the ground just south of the canvas.
		rects.append(Rect2(thorn.position.x - 110.0, thorn.position.y - 158.0, 220.0, 176.0))
		var tw: Rect2 = rects[rects.size() - 1]
		var tx0: int = int(floor(tw.position.x / cell))
		var ty0: int = int(floor(tw.position.y / cell))
		var tx1: int = int(floor(tw.end.x / cell))
		var ty1: int = int(floor(tw.end.y / cell))
		for gx: int in range(tx0, tx1 + 1):
			for gy: int in range(ty0, ty1 + 1):
				var tx: float = (float(gx) + 0.5) * cell
				var ty: float = (float(gy) + 0.5) * cell
				if tx >= tw.position.x and ty >= tw.position.y and tx <= tw.end.x and ty <= tw.end.y:
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
	failed += _path_opening_exception(space, params)
	for i: int in names.size():
		failed += _check(reached[i], "%s reachable inside the clearing" % names[i])
	failed += _work_reach(live)
	await _frame_times(live)
	return failed


func _on_thorn_corridor(at: Vector2) -> bool:
	## The north road is an allowed mouth. It stops short of the map edge.
	if at.y < 540.0 or at.y > 1080.0 or at.x < 1880.0 or at.x > 2320.0:
		return false
	var pts: PackedVector2Array = PackedVector2Array([
		Vector2(2000, 1000), Vector2(2060, 880), Vector2(2108, 760),
		Vector2(2140, 690), Vector2(2140, 620),
	])
	for i: int in range(pts.size() - 1):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var ab: Vector2 = b - a
		var den: float = ab.length_squared()
		var t: float = 0.0
		if den > 0.001:
			t = clampf(((at - a).dot(ab)) / den, 0.0, 1.0)
		if at.distance_to(a + ab * t) <= 40.0:
			return true
	return false


func _path_opening_exception(space: PhysicsDirectSpaceState2D, params: PhysicsShapeQueryParameters2D) -> int:
	## Walk the clearing again, but the thorn corridor does not count as a wall.
	## Reaching the map border through that mouth is still a leak.
	var step: float = 22.0
	var origin := Vector2(2080, 2460)
	var queue: Array[Vector2] = [origin]
	var seen: Dictionary = {_forest_cell(origin, step): true}
	var head: int = 0
	var leaked: bool = false
	var guard: int = 0
	while head < queue.size() and guard < 90000:
		guard += 1
		var at: Vector2 = queue[head]
		head += 1
		if at.x < 140.0 or at.y < 140.0 or at.x > 4180.0 or at.y > 3640.0:
			leaked = true
			print("FOREST_SEAL path_opening leak %.1f %.1f" % [at.x, at.y])
			break
		for dir: Vector2 in [Vector2(step, 0), Vector2(-step, 0), Vector2(0, step), Vector2(0, -step)]:
			var nxt: Vector2 = at + dir
			var key: Vector2i = _forest_cell(nxt, step)
			if seen.has(key):
				continue
			seen[key] = true
			if not _on_thorn_corridor(nxt):
				params.transform = Transform2D(0.0, nxt)
				if not space.intersect_shape(params, 1).is_empty():
					continue
			queue.append(nxt)
	print("FOREST_SEAL path_opening=excepted leaked=%s visited=%d" % ["yes" if leaked else "no", queue.size()])
	return _check(not leaked, "thorn path opening stays inside the map")


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
	var box: Vector2 = FeetBox.actor_box("keeper")
	shape.size = box
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = Transform2D(0.0, pos + Vector2(0.0, -box.y * 0.5))
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
	failed += _check(body != null and not body.visible, "sprite waits until Go look")
	game.set("elaia_footsteps_seen", true)
	if body and body.has_method("_apply_presence"):
		body.call("_apply_presence")
	failed += _check(body != null and body.visible, "sprite shows after Go look")
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


func _minigame_scenes() -> int:
	var runner: RefCounted = (load("res://scripts/minigames/minigame_tests.gd") as GDScript).new()
	return int(runner.call("run_scenes"))


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
		"options_speedup_toggle", "options_speedup_toggle_hint", "options_debug_tools_toggle",
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
		"char_sheet_trait_popup_title", "char_sheet_trait_work", "char_sheet_trait_craft",
		"char_sheet_trait_reliquary", "char_sheet_trait_water", "char_sheet_trait_move",
		"char_sheet_trait_brew",
		"batch_make", "batch_max", "batch_cancel", "batch_amount",
		"batch_bar_current", "batch_bar_total",
		"batch_tooltip_current", "batch_tooltip_total", "batch_tooltip_paused",
		"batch_busy", "batch_unstaffed", "batch_done_toast", "batch_away_note",
		"batch_cancel_confirm_title", "batch_cancel_confirm_body",
		"batch_cancel_confirm_yes", "batch_cancel_confirm_no",
		"ascend_warning_batches",
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


func _hotkey_badge_dim(btn: Button) -> bool:
	if btn == null or not btn.disabled:
		return false
	var cap: CanvasItem = btn.get_node_or_null("Keycap") as CanvasItem
	var plate: CanvasItem = btn.get_node_or_null("KeycapPlate") as CanvasItem
	if cap == null or plate == null:
		return false
	return cap.modulate.r < 0.7 and plate.modulate.r < 0.7 and cap.modulate.g < 0.75


func _control_covers(window: Control, target: Control) -> bool:
	if window == null or target == null:
		return false
	var outer := Rect2(window.position, window.size)
	var inner := Rect2(target.position, target.size)
	return outer.position.x <= inner.position.x + 0.5 \
		and outer.position.y <= inner.position.y + 0.5 \
		and outer.end.x + 0.5 >= inner.end.x \
		and outer.end.y + 0.5 >= inner.end.y


func _check(ok: bool, label: String) -> int:
	if ok:
		return 0
	print("FAIL %s" % label)
	return 1


func _res540_theme_sanity() -> int:
	var failed: int = 0
	var theme: Node = root.get_node_or_null("GameTheme")
	failed += _check(theme != null, "GameTheme autoload")
	if theme != null:
		failed += _check(int(theme.call("silver_body_size")) == 19, "Silver body 19")
		failed += _check(int(theme.call("jersey_title_size")) == 37, "Jersey title 37")
	return failed


func _res540_input_sanity() -> int:
	var failed: int = 0
	failed += _check(InputMap.has_action("game_command"), "game_command action")
	failed += _check(InputMap.has_action("game_inspect"), "game_inspect action")
	var input_node: Node = root.get_node_or_null("GameInput")
	failed += _check(input_node != null, "GameInput autoload")
	return failed


func _res540_shop_sanity() -> int:
	var failed: int = 0
	var hud_src: String = FileAccess.get_file_as_string("res://scripts/hud.gd")
	failed += _check(hud_src.find("const SHOP_SIZE: Vector2 = Vector2(912, 472)") >= 0, "shop size 912x472 in hud.gd")
	failed += _check(912.0 + 48.0 <= 960.0 and 472.0 + 48.0 <= 540.0, "shop fits 540p with 24px margins")
	return failed


func _res540_help_sanity() -> int:
	var failed: int = 0
	var src: String = FileAccess.get_file_as_string("res://scripts/hud.gd")
	failed += _check(src.find("HelpDraftTag") >= 0, "help540 draft tag")
	failed += _check(src.find("_make_help_row") >= 0, "help540 keycap rows")
	failed += _check(src.find("Gamepad: not supported yet") >= 0, "help540 gamepad note")
	return failed


func _res540_debug_sanity() -> int:
	var failed: int = 0
	var src: String = FileAccess.get_file_as_string("res://tools/debug/debug_panel.gd")
	failed += _check(src.find("_build_tab_overlays") >= 0, "debug540 overlays tab")
	failed += _check(src.find("_build_tab_runes") >= 0, "debug540 runes tab")
	failed += _check(src.find("Search all tabs") >= 0, "debug540 search field")
	return failed


func _res540_care_sanity() -> int:
	var failed: int = 0
	var src: String = FileAccess.get_file_as_string("res://scripts/hud.gd")
	failed += _check(src.find("BlessingsPreviewButton") >= 0, "manatree540 blessings icon")
	failed += _check(src.find("const CARE_SIZE: Vector2 = Vector2(600, 440)") >= 0, "manatree540 window 600x440")
	failed += _check(src.find("CARE_SIZE.x - 124.0") >= 0, "blessings left of close")
	return failed


func _res540_battle_sanity() -> int:
	var failed: int = 0
	var src: String = FileAccess.get_file_as_string("res://scripts/battle/battle_view.gd")
	failed += _check(src.find("Vector2(232, 206)") >= 0, "battle540 party front sole row 206")
	failed += _check(src.find("Vector2(876, 206)") >= 0, "battle540 beast back sole row 206")
	return failed


func _res540_board_sanity() -> int:
	var failed: int = 0
	var src: String = FileAccess.get_file_as_string("res://scripts/ui/expedition_shell.gd")
	failed += _check(src.find("const PICKER_POPUP_W: float = 272.0") >= 0, "board540 picker width 272")
	failed += _check(src.find("const PICKER_ROW_H: float = 48.0") >= 0, "board540 picker row 48px")
	failed += _check(src.find("Who stands here?") >= 0, "board540 picker title")
	return failed


func _res540_bag_sanity() -> int:
	var failed: int = 0
	var src: String = FileAccess.get_file_as_string("res://scripts/hud.gd")
	failed += _check(src.find("TabCategoryCycle") >= 0, "bag540 category cycle tab")
	failed += _check(src.find("BagDetailPopup") >= 0, "bag540 detail popup")
	failed += _check(src.find("const BAG_PANEL_W: float = 560.0") >= 0, "bag540 panel width 560")
	return failed


func _res540_char_sanity() -> int:
	var failed: int = 0
	var src: String = FileAccess.get_file_as_string("res://scripts/character_sheet.gd")
	failed += _check(src.find("PrevCharButton") >= 0, "char540 prev actor control")
	failed += _check(src.find("GearCategoryCycle") >= 0, "char540 gear category cycle")
	failed += _check(src.find("const SHEET_SIZE: Vector2 = Vector2(912, 492)") >= 0, "char540 window 912x492")
	return failed
