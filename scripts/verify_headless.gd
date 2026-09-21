extends SceneTree
## Headless verification per SYSTEMS_V01 v0.4.1 — D6 playtest + camera/map. SAVE_VERSION 6.
##   godot --headless --path . -s res://scripts/verify_headless.gd


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var tree_root: Window = get_root()
	var game_state: Node = tree_root.get_node_or_null("GameState")
	var save_service: Node = tree_root.get_node_or_null("SaveService")
	var content_strings: Node = tree_root.get_node_or_null("ContentStrings")
	var game_audio: Node = tree_root.get_node_or_null("GameAudio")
	var backpack: Node = tree_root.get_node_or_null("Backpack")

	var failed: int = 0
	failed += _assert(game_state != null, "GameState autoload missing")
	failed += _assert(save_service != null, "SaveService autoload missing")
	failed += _assert(content_strings != null, "ContentStrings autoload missing")
	failed += _assert(game_audio != null, "GameAudio autoload missing")
	failed += _assert(backpack != null, "Backpack autoload missing")
	if failed > 0:
		print("VERIFY_FAIL: %d assertion(s) failed (early)" % failed)
		quit(1)
		return

	failed += _assert(int(game_state.get("stages_data").size()) == 5, "expected 5 stages")
	failed += _assert(int(game_state.get("upgrades_data").size()) == 8, "expected 8 fruit upgrades")
	failed += _assert(int(save_service.get("SAVE_VERSION")) == 6, "SAVE_VERSION should be 6")
	failed += _assert(int(save_service.get("SAVE_SLOT_COUNT")) == 7, "SAVE_SLOT_COUNT should be 7")
	failed += _assert(not (game_state.get("params") as Dictionary).has("WATER_GROWTH"), "WATER_GROWTH removed")
	failed += _assert(int(game_state.call("param_int", "HARVEST_WOOD_PER_SEC", 0)) == 1, "HARVEST_WOOD_PER_SEC")
	failed += _assert(int(game_state.call("param_int", "WATER_ESSENCE_PER_SEC", 0)) == 1, "WATER_ESSENCE_PER_SEC")
	failed += _assert(int(game_state.call("param_float", "CHANNEL_PULSE_SEC", 0.0)) == 1, "CHANNEL_PULSE_SEC 1")
	failed += _assert(str(content_strings.call("get_text", "tree_pay")) == "Grow", "tree_pay Grow")
	failed += _assert(str(content_strings.call("get_text", "tree_grow")) == "Grow", "tree_grow")
	failed += _assert(str(content_strings.call("get_text", "tree_grow_ready")) == "Ready to Grow", "tree_grow_ready")
	failed += _assert(str(content_strings.call("get_text", "tree_grow_ok")).find("{next_stage}") >= 0, "tree_grow_ok")
	failed += _assert(str(content_strings.call("get_text", "tree_grow_hint")).find("Fertilizer") >= 0, "tree_grow_hint")
	failed += _assert(str(content_strings.call("get_text", "tree_need_line")).find("{have}") >= 0, "tree_need_line")
	failed += _assert(str(content_strings.call("get_text", "tree_need_line_met")).find("✓") >= 0, "tree_need_line_met")
	failed += _assert(str(content_strings.call("get_text", "tree_stage_blocked_essence")).find("Essence") >= 0, "essence gate string")
	failed += _assert(str(content_strings.call("get_text", "tree_stage_blocked_food")).find("Food") >= 0, "food gate string")
	failed += _assert(str(content_strings.call("get_text", "tooltip_essence")).find("watering") >= 0, "essence not fruit-only")
	failed += _assert(str(content_strings.call("get_text", "node_wood_busy")).find("Harvesting") >= 0, "harvest channel HUD")
	failed += _assert(str(content_strings.call("get_text", "tree_water_pulse_hud")).find("Manashards") >= 0, "water pulse HUD")
	failed += _assert(str(content_strings.call("get_text", "tree_water_no_food")) == "tree_water_no_food", "tree_water_no_food must be removed")
	failed += _assert(str(content_strings.call("get_text", "welcome_boot")).find("Tend the Manatree") >= 0, "welcome_boot")
	failed += _assert(str(content_strings.call("get_text", "welcome_body")).find("Keeper") >= 0, "welcome_body")
	failed += _assert(str(content_strings.call("get_text", "welcome_dismiss")).find("tend") >= 0, "welcome_dismiss")
	failed += _assert(str(content_strings.call("get_text", "welcome_hint")).find("LMB") >= 0, "welcome_hint LMB")
	failed += _assert(str(content_strings.call("get_text", "tree_next_stage_needs_met")).find("Grow") >= 0, "tree_next_stage_needs_met Grow")
	failed += _assert(str(content_strings.call("get_text", "tree_pay_ok")).find("{next_stage}") >= 0, "tree_pay_ok")
	# Offers retired from Content UI
	failed += _assert(str(content_strings.call("get_text", "tree_offer_wood")) == "tree_offer_wood", "tree_offer_wood must be removed")

	# Pause menu content
	failed += _assert(str(content_strings.call("get_text", "pause_title")) == "Pause", "pause_title")
	failed += _assert(str(content_strings.call("get_text", "pause_resume")).find("Resume") >= 0, "pause_resume")
	failed += _assert(str(content_strings.call("get_text", "pause_new_game_confirm")).find("Keeper") >= 0, "pause_new_game_confirm")
	# Options → Audio (CONTENT v0.2.5) — stub retired
	failed += _assert(str(content_strings.call("get_text", "options_audio_title")) == "Audio", "options_audio_title")
	failed += _assert(str(content_strings.call("get_text", "options_music_volume")) == "Music", "options_music_volume")
	failed += _assert(str(content_strings.call("get_text", "options_sfx_volume")) == "Sounds", "options_sfx_volume")
	failed += _assert(str(content_strings.call("get_text", "options_audio_back")) == "Back", "options_audio_back")
	failed += _assert(str(content_strings.call("get_text", "options_audio_hint")).find("forest") >= 0, "options_audio_hint")
	failed += _assert(str(content_strings.call("get_text", "options_audio_reset")) == "Reset", "options_audio_reset")
	failed += _assert(str(content_strings.call("get_text", "options_music_volume_full")).find("Music") >= 0, "options_music_volume_full")
	failed += _assert(str(content_strings.call("get_text", "options_sfx_volume_full")).find("SFX") >= 0, "options_sfx_volume_full")
	failed += _assert(str(content_strings.call("get_text", "pause_slot_empty")).find("Empty") >= 0, "pause_slot_empty")
	failed += _assert(str(content_strings.call("get_text", "pause_save_ok")).find("remembers") >= 0, "pause_save_ok")
	failed += _assert(save_service.has_method("get_slot_info"), "get_slot_info")
	failed += _assert(save_service.has_method("migrate_legacy_save_if_needed"), "migrate_legacy_save_if_needed")
	failed += _assert(save_service.has_method("slot_path"), "slot_path")

	# Stage needs v0.2.0 (costs are to ENTER the named stage)
	var young: Dictionary = game_state.call("get_stage_def", &"young")
	var mature: Dictionary = game_state.call("get_stage_def", &"mature")
	var elder: Dictionary = game_state.call("get_stage_def", &"elder")
	var ancient: Dictionary = game_state.call("get_stage_def", &"ancient")
	failed += _assert(int(young.get("cost_essence", 0)) == 20 and int(young.get("cost_fertilizer", 0)) == 3, "young 20e+3fert")
	failed += _assert(int(mature.get("cost_essence", 0)) == 40 and int(mature.get("cost_fertilizer", 0)) == 6, "mature 40e+6fert")
	failed += _assert(int(elder.get("cost_essence", 0)) == 60 and int(elder.get("cost_fertilizer", 0)) == 12, "elder 60e+12fert")
	failed += _assert(
		int(ancient.get("cost_essence", 0)) == 80
		and int(ancient.get("cost_fertilizer", 0)) == 24,
		"ancient 80e+24fert"
	)
	failed += _assert(not young.has("growth_required"), "growth_required removed from young")
	var anc_size: Variant = ancient.get("size", [])
	failed += _assert(typeof(anc_size) == TYPE_ARRAY and int((anc_size as Array)[0]) == 512 and int((anc_size as Array)[1]) == 640, "ancient size 512x640")

	# deep_roots = water essence bonus; green_thumb = fertilizer craft cost
	var deep: Dictionary = game_state.call("get_upgrade_def", "deep_roots")
	failed += _assert(str(deep.get("effect", "")) == "water_essence_bonus", "deep_roots water_essence_bonus")
	var thumb: Dictionary = game_state.call("get_upgrade_def", "green_thumb")
	failed += _assert(str(thumb.get("effect", "")) == "fertilizer_craft_cost_mult", "green_thumb fertilizer_craft_cost_mult")

	# Art stage textures + meta
	failed += _assert(FileAccess.file_exists("res://assets/art/manatree/manatree_sapling.png"), "sapling texture")
	failed += _assert(FileAccess.file_exists("res://assets/art/manatree/manatree_young.png"), "young texture")
	failed += _assert(FileAccess.file_exists("res://assets/art/manatree/manatree_mature.png"), "mature texture")
	failed += _assert(FileAccess.file_exists("res://assets/art/manatree/manatree_elder.png"), "elder texture")
	failed += _assert(FileAccess.file_exists("res://assets/art/manatree/manatree_ancient.png"), "ancient texture")
	failed += _assert(FileAccess.file_exists("res://assets/art/manatree/manatree_meta.json"), "manatree_meta.json")
	var meta_file := FileAccess.open("res://assets/art/manatree/manatree_meta.json", FileAccess.READ)
	failed += _assert(meta_file != null, "open manatree_meta")
	if meta_file:
		var meta_parsed: Variant = JSON.parse_string(meta_file.get_as_text())
		meta_file.close()
		failed += _assert(typeof(meta_parsed) == TYPE_DICTIONARY, "meta dict")
		if typeof(meta_parsed) == TYPE_DICTIONARY:
			var mroot: Dictionary = meta_parsed
			failed += _assert(str(mroot.get("version", "")) == "v0.1.6-sheet-scaled", "meta version v0.1.6-sheet-scaled")
			var stages_m: Variant = mroot.get("stages", [])
			failed += _assert(typeof(stages_m) == TYPE_ARRAY and (stages_m as Array).size() == 5, "meta 5 stages")
			if typeof(stages_m) == TYPE_ARRAY:
				for entry: Variant in stages_m:
					if typeof(entry) != TYPE_DICTIONARY:
						continue
					var ed: Dictionary = entry
					if str(ed.get("stage_id", "")) == "ancient":
						var asz: Variant = ed.get("size", [])
						failed += _assert(typeof(asz) == TYPE_ARRAY and int((asz as Array)[0]) == 512 and int((asz as Array)[1]) == 640, "meta ancient 512x640")

	# Art harvest nodes
	failed += _assert(ResourceLoader.exists("res://assets/art/props/harvest_tree.png"), "harvest_tree art")
	failed += _assert(ResourceLoader.exists("res://assets/art/props/harvest_stone.png"), "harvest_stone art")
	failed += _assert(ResourceLoader.exists("res://assets/art/props/harvest_berry.png"), "harvest_berry art")

	# Art v0.1.13 — cleaned inbox forest + Keeper south walk
	failed += _assert(FileAccess.file_exists("res://assets/art/trees/tree_big_01.png"), "tree_big_01")
	failed += _assert(FileAccess.file_exists("res://assets/art/trees/tree_big_04.png"), "tree_big_04")
	failed += _assert(FileAccess.file_exists("res://assets/art/trees/tree_small_01.png"), "tree_small_01")
	failed += _assert(FileAccess.file_exists("res://assets/art/trees/tree_small_03.png"), "tree_small_03 thin")
	failed += _assert(FileAccess.file_exists("res://assets/art/bushes/bush_big_01.png"), "bush_big_01")
	failed += _assert(FileAccess.file_exists("res://assets/art/bushes/bush_big_12.png"), "bush_big_12")
	failed += _assert(FileAccess.file_exists("res://assets/art/bushes/bush_small_01.png"), "bush_small_01")
	failed += _assert(FileAccess.file_exists("res://assets/art/bushes/bush_small_57.png"), "bush_small_57")
	failed += _assert(FileAccess.file_exists("res://assets/art/bushes/bushes_meta.json"), "bushes_meta.json")
	failed += _assert(FileAccess.file_exists("res://assets/art/keeper/keeper_idle_south.png"), "keeper idle_south")
	failed += _assert(FileAccess.file_exists("res://assets/art/keeper/keeper_idle_south_0000.png"), "keeper idle_south_0000")
	failed += _assert(FileAccess.file_exists("res://assets/art/keeper/keeper_walk_south_0001.png"), "keeper walk_south 1")
	failed += _assert(FileAccess.file_exists("res://assets/art/keeper/keeper_walk_south_0009.png"), "keeper walk_south 9")
	failed += _assert(FileAccess.file_exists("res://assets/art/keeper/keeper_walk_south.png"), "keeper walk_south strip")
	var walk_strip: Texture2D = load("res://assets/art/keeper/keeper_walk_south.png") as Texture2D
	failed += _assert(walk_strip != null, "load walk_south strip")
	if walk_strip:
		failed += _assert(walk_strip.get_width() == 1152 and walk_strip.get_height() == 128, "walk strip 1152x128 (got %dx%d)" % [walk_strip.get_width(), walk_strip.get_height()])
	var tree_big: Texture2D = load("res://assets/art/trees/tree_big_01.png") as Texture2D
	failed += _assert(tree_big != null and tree_big.get_width() >= 400, "tree_big_01 full-size (got %s)" % (tree_big.get_width() if tree_big else 0))
	failed += _assert(FileAccess.file_exists("res://assets/art/keeper/native/keeper_idle_south_256.png"), "keeper native idle")
	failed += _assert(FileAccess.file_exists("res://Assets upload/Big Trees.png"), "inbox Big Trees.png kept")
	failed += _assert(FileAccess.file_exists("res://Assets upload/keeper/walk_south_09.png"), "inbox walk_south_09 kept")
	var trees_meta_f := FileAccess.open("res://assets/art/trees/trees_meta.json", FileAccess.READ)
	failed += _assert(trees_meta_f != null, "open trees_meta")
	if trees_meta_f:
		var trees_meta_parsed: Variant = JSON.parse_string(trees_meta_f.get_as_text())
		trees_meta_f.close()
		failed += _assert(typeof(trees_meta_parsed) == TYPE_DICTIONARY, "trees meta dict")
		if typeof(trees_meta_parsed) == TYPE_DICTIONARY:
			var tm: Dictionary = trees_meta_parsed
			failed += _assert(str(tm.get("version", "")) == "v0.1.13-assets-upload", "trees meta v0.1.13-assets-upload")
			var spawn_c: Variant = tm.get("spawn_catalog", {})
			failed += _assert(typeof(spawn_c) == TYPE_DICTIONARY, "spawn_catalog")
			if typeof(spawn_c) == TYPE_DICTIONARY:
				var trees_ids: Array = (spawn_c as Dictionary).get("tree", []) as Array
				failed += _assert(trees_ids.size() >= 8, "spawn trees >= 8 (got %d)" % trees_ids.size())
	var bushes_meta_f := FileAccess.open("res://assets/art/bushes/bushes_meta.json", FileAccess.READ)
	failed += _assert(bushes_meta_f != null, "open bushes_meta")
	if bushes_meta_f:
		var bm_parsed: Variant = JSON.parse_string(bushes_meta_f.get_as_text())
		bushes_meta_f.close()
		failed += _assert(typeof(bm_parsed) == TYPE_DICTIONARY, "bushes meta dict")
		if typeof(bm_parsed) == TYPE_DICTIONARY:
			failed += _assert(str((bm_parsed as Dictionary).get("version", "")) == "v0.1.13-assets-upload", "bushes meta version")
			var bitems: Variant = (bm_parsed as Dictionary).get("items", {})
			failed += _assert(typeof(bitems) == TYPE_DICTIONARY and (bitems as Dictionary).size() >= 69, "69 bush frames (got %d)" % ((bitems as Dictionary).size() if typeof(bitems) == TYPE_DICTIONARY else 0))
	var keeper_meta_f := FileAccess.open("res://assets/art/keeper/keeper_meta.json", FileAccess.READ)
	failed += _assert(keeper_meta_f != null, "open keeper_meta")
	if keeper_meta_f:
		var km_parsed: Variant = JSON.parse_string(keeper_meta_f.get_as_text())
		keeper_meta_f.close()
		failed += _assert(typeof(km_parsed) == TYPE_DICTIONARY, "keeper meta dict")
		if typeof(km_parsed) == TYPE_DICTIONARY:
			failed += _assert(str((km_parsed as Dictionary).get("version", "")) == "v0.1.13-assets-upload", "keeper meta v0.1.13")
			var clips_k: Variant = (km_parsed as Dictionary).get("clips", {})
			if typeof(clips_k) == TYPE_DICTIONARY:
				var ws: Dictionary = (clips_k as Dictionary).get("walk_south", {}) as Dictionary
				failed += _assert(int(ws.get("frames", 0)) == 9, "walk_south 9 frames")
				failed += _assert(int(ws.get("hold_ms", 0)) == 100, "walk_south hold_ms 100")

	save_service.call("delete_save")
	game_state.call("reset_for_new_game")
	failed += _assert(str(game_state.get("stage_id")) == "sapling", "expected sapling")
	failed += _assert(not (game_state.call("to_save_dict") as Dictionary).has("growth"), "save dict has no growth")
	failed += _assert(bool(game_state.get("welcome_shown")) == false, "welcome_shown false on new game")

	# Care UI helpers — needs checklist, no growth line
	var info: Dictionary = game_state.call("get_care_next_stage_info")
	failed += _assert(bool(info.get("is_ancient", true)) == false, "care info not ancient at sapling")
	failed += _assert(not info.has("growth_line"), "care has no growth_line")
	failed += _assert(bool(info.get("can_pay", true)) == false, "cannot pay at 0 essence")
	var lines: PackedStringArray = info.get("needs_lines", PackedStringArray()) as PackedStringArray
	failed += _assert(lines.size() >= 1 and str(lines[0]).find("Essence") >= 0, "care needs essence line")
	failed += _assert(game_state.has_method("get_next_stage_needs"), "get_next_stage_needs")
	failed += _assert(game_state.has_method("try_pay_stage"), "try_pay_stage")
	failed += _assert(game_state.has_method("can_pay_stage"), "can_pay_stage")

	# Simulate 1s harvest grants
	var w0: int = int(game_state.get("wood"))
	var grant_w: int = int(game_state.call("apply_harvest_pulse", &"wood"))
	failed += _assert(grant_w >= 1, "wood harvest grant")
	failed += _assert(int(game_state.get("wood")) == w0 + grant_w, "wood inventory after pulse")
	game_state.call("reset_for_new_game")
	game_state.call("apply_harvest_pulse", &"stone")
	failed += _assert(int(game_state.get("stone")) >= 1, "stone >=1 after pulse")
	game_state.call("apply_harvest_pulse", &"food")
	failed += _assert(int(game_state.get("food")) >= 1, "food >=1 after pulse")
	failed += _assert(int((game_state.get("lifetime_harvested") as Dictionary).get("food", 0)) >= 1, "lifetime_harvested food")

	# Water tick: manashards + essence, NO growth
	game_state.call("reset_for_new_game")
	var e0: int = int(game_state.get("essence"))
	var m0: int = int(game_state.get("manashards"))
	var water: Dictionary = game_state.call("apply_water_pulse")
	failed += _assert(bool(water.get("ok", false)), "water pulse ok")
	var shards: int = int(water.get("shards", 0))
	var ess: int = int(water.get("essence", 0))
	failed += _assert(shards >= 1 and shards <= 3, "water shards U{1,3} got %d" % shards)
	failed += _assert(ess == 1, "water essence +1")
	failed += _assert(not water.has("growth") or int(water.get("growth", 0)) == 0, "water no growth")
	failed += _assert(int(game_state.get("manashards")) == m0 + shards, "manashards inventory")
	failed += _assert(int(game_state.get("essence")) == e0 + ess, "essence from water")
	failed += _assert(int(game_state.call("get_water_essence_amount")) == 1, "water essence amount 1")
	failed += _assert(int(game_state.get("lifetime_waters")) == 1, "lifetime_waters")
	failed += _assert(int(game_state.get("lifetime_shards_from_water")) == shards, "lifetime_shards_from_water")
	failed += _assert(int(game_state.get("lifetime_essence_from_water")) == 1, "lifetime_essence_from_water")

	# Grow Young: 20 essence + 3 Fertilizer
	game_state.call("reset_for_new_game")
	game_state.call("set_resource", &"essence", 20)
	backpack.call("add_item", "fertilizer", 3)
	failed += _assert(bool(game_state.call("can_grow_stage")), "can grow young at 20e+3fert")
	var pay_y: String = str(game_state.call("try_grow_stage"))
	failed += _assert(pay_y == "ok", "grow young ok (got %s)" % pay_y)
	failed += _assert(str(game_state.get("stage_id")) == "young", "stage young after grow")
	failed += _assert(int(game_state.get("essence")) == 0, "essence spent for young")
	failed += _assert(int(backpack.call("get_count", "fertilizer")) == 0, "fertilizer spent for young")

	# Grow Mature: 40e + 6 Fertilizer
	game_state.call("set_resource", &"essence", 40)
	backpack.call("add_item", "fertilizer", 6)
	failed += _assert(str(game_state.call("try_grow_stage")) == "ok", "grow mature")
	failed += _assert(str(game_state.get("stage_id")) == "mature", "stage mature")

	# Grow Elder: 60e + 12 Fertilizer
	game_state.call("set_resource", &"essence", 60)
	backpack.call("add_item", "fertilizer", 12)
	failed += _assert(str(game_state.call("try_grow_stage")) == "ok", "grow elder")
	failed += _assert(str(game_state.get("stage_id")) == "elder", "stage elder")

	# Grow Ancient: 80e + 24 Fertilizer
	game_state.call("set_resource", &"essence", 80)
	backpack.call("add_item", "fertilizer", 24)
	failed += _assert(str(game_state.call("try_grow_stage")) == "ok", "grow ancient")
	failed += _assert(str(game_state.get("stage_id")) == "ancient", "stage ancient")
	failed += _assert(bool(game_state.get("fruit_ready")), "fruit ready at ancient")

	# Ancient water still pays
	var info_a: Dictionary = game_state.call("get_care_next_stage_info")
	failed += _assert(bool(info_a.get("is_ancient", false)), "care info ancient")
	var e_a: int = int(game_state.get("essence"))
	var m_a: int = int(game_state.get("manashards"))
	var w_anc: Dictionary = game_state.call("apply_water_pulse")
	failed += _assert(bool(w_anc.get("ok", false)), "ancient water still ok")
	failed += _assert(int(game_state.get("essence")) > e_a, "ancient water essence")
	failed += _assert(int(game_state.get("manashards")) > m_a, "ancient water shards")

	# Cant afford path
	game_state.call("reset_for_new_game")
	game_state.call("set_resource", &"essence", 5)
	failed += _assert(str(game_state.call("try_grow_stage")) == "cant_afford", "cant afford young")
	failed += _assert(str(game_state.get("stage_id")) == "sapling", "still sapling")

	# Save roundtrip slot 1 (SAVE_VERSION 5, wisps)
	game_state.call("reset_for_new_game")
	game_state.call("set_resource", &"wood", 42)
	game_state.call("set_resource", &"stone", 17)
	game_state.call("set_resource", &"food", 9)
	game_state.call("set_resource", &"manashards", 6)
	game_state.call("set_resource", &"essence", 4)
	game_state.call("_set_stage", &"mature")
	game_state.set("welcome_shown", true)
	var ranks: Dictionary = game_state.get("upgrade_ranks")
	ranks["deep_roots"] = 2
	game_state.set("upgrade_ranks", ranks)
	game_state.set("ascensions", 1)
	game_state.set("lifetime_waters", 120)
	game_state.set("lifetime_shards_from_water", 200)
	game_state.set("lifetime_essence_from_water", 120)
	game_state.set("lifetime_fruit_harvested", 1)
	game_state.set("lifetime_harvested", {"wood": 11, "stone": 7, "food": 5})

	failed += _assert(bool(save_service.call("save_game", 1)), "save_game slot 1 failed")
	# Confirm written save_version is 6 and no growth in payload
	var slot1_path: String = str(save_service.call("slot_path", 1))
	var s1f := FileAccess.open(slot1_path, FileAccess.READ)
	failed += _assert(s1f != null, "read slot 1")
	if s1f:
		var s1root: Variant = JSON.parse_string(s1f.get_as_text())
		s1f.close()
		if typeof(s1root) == TYPE_DICTIONARY:
			failed += _assert(int((s1root as Dictionary).get("save_version", 0)) == 6, "written save_version 6")
			var st: Variant = (s1root as Dictionary).get("state", {})
			if typeof(st) == TYPE_DICTIONARY:
				failed += _assert(not (st as Dictionary).has("growth"), "payload no growth field")
	game_state.call("reset_for_new_game")
	failed += _assert(bool(game_state.get("welcome_shown")) == false, "reset clears welcome_shown")
	failed += _assert(bool(save_service.call("load_game", 1)), "load_game slot 1 failed")
	failed += _assert(int(game_state.get("wood")) == 42, "wood mismatch")
	failed += _assert(bool(game_state.get("welcome_shown")) == true, "welcome_shown persisted")
	failed += _assert(int(game_state.get("lifetime_shards_from_water")) == 200, "shards lifetime")
	failed += _assert(int(game_state.get("lifetime_essence_from_water")) == 120, "essence lifetime")
	failed += _assert(int((game_state.get("lifetime_harvested") as Dictionary).get("wood", 0)) == 11, "harvested wood lifetime")
	# deep_roots rank 2 → floor(2/2)=1 bonus essence
	failed += _assert(int(game_state.call("get_water_essence_amount")) == 2, "deep_roots rank2 → essence 2")
	var info1: Dictionary = save_service.call("get_slot_info", 1)
	failed += _assert(bool(info1.get("filled", false)), "slot 1 filled summary")
	failed += _assert(str(info1.get("stage_id", "")) == "mature", "slot 1 stage summary")

	# Slot 2 roundtrip
	game_state.call("reset_for_new_game")
	game_state.call("set_resource", &"wood", 77)
	game_state.call("set_resource", &"essence", 13)
	game_state.call("_set_stage", &"young")
	game_state.set("ascensions", 2)
	game_state.set("welcome_shown", true)
	failed += _assert(bool(save_service.call("save_game", 2)), "save_game slot 2 failed")
	game_state.call("reset_for_new_game")
	failed += _assert(bool(save_service.call("load_game", 2)), "load_game slot 2 failed")
	failed += _assert(int(game_state.get("wood")) == 77, "slot 2 wood")
	failed += _assert(int(game_state.get("essence")) == 13, "slot 2 essence")
	failed += _assert(str(game_state.get("stage_id")) == "young", "slot 2 stage")
	failed += _assert(int(game_state.get("ascensions")) == 2, "slot 2 ascensions")
	failed += _assert(bool(save_service.call("has_slot", 1)), "slot 1 still present after slot 2 save")
	failed += _assert(bool(save_service.call("load_game", 1)), "reload slot 1")
	failed += _assert(int(game_state.get("wood")) == 42, "slot 1 wood after slot 2")

	# Legacy v3 save with growth → migrate drop growth, load as v4-compatible
	save_service.call("delete_save")
	game_state.call("reset_for_new_game")
	game_state.call("set_resource", &"stone", 55)
	game_state.set("welcome_shown", true)
	var legacy_state: Dictionary = game_state.call("to_save_dict")
	legacy_state["growth"] = 99
	legacy_state["lifetime_offered"] = {"wood": 1}
	var legacy_payload: Dictionary = {
		"save_version": 3,
		"timestamp": Time.get_unix_time_from_system(),
		"state": legacy_state,
	}
	var legacy_path: String = str(save_service.get("LEGACY_SAVE_PATH"))
	var leg_file := FileAccess.open(legacy_path, FileAccess.WRITE)
	failed += _assert(leg_file != null, "write legacy save")
	if leg_file:
		leg_file.store_string(JSON.stringify(legacy_payload))
		leg_file.close()
	failed += _assert(bool(save_service.call("migrate_legacy_save_if_needed")), "migrate legacy → slot 1")
	failed += _assert(bool(save_service.call("has_slot", 1)), "migrated slot 1 exists")
	failed += _assert(not FileAccess.file_exists(legacy_path), "legacy removed after migrate")
	game_state.call("reset_for_new_game")
	failed += _assert(bool(save_service.call("load_game", 1)), "load migrated slot 1")
	failed += _assert(int(game_state.get("stone")) == 55, "migrated stone")
	failed += _assert(not (game_state.call("to_save_dict") as Dictionary).has("growth"), "growth ignored after migrate")

	# Pause freezes GameState.run_time_sec
	failed += _assert(
		int(game_state.process_mode) == Node.PROCESS_MODE_INHERIT
		or int(game_state.process_mode) == Node.PROCESS_MODE_PAUSABLE,
		"GameState should be pausable (got %d)" % int(game_state.process_mode)
	)
	game_state.set("run_time_sec", 0.0)
	paused = false
	await process_frame
	await process_frame
	var t_unpaused: float = float(game_state.get("run_time_sec"))
	failed += _assert(t_unpaused > 0.0, "run_time advances while unpaused (got %s)" % t_unpaused)
	paused = true
	var t_at_pause: float = float(game_state.get("run_time_sec"))
	await process_frame
	await process_frame
	var t_while_paused: float = float(game_state.get("run_time_sec"))
	failed += _assert(
		abs(t_while_paused - t_at_pause) < 0.0001,
		"run_time frozen while paused (%s → %s)" % [t_at_pause, t_while_paused]
	)
	paused = false
	var pause_packed: PackedScene = load("res://scenes/pause_menu.tscn") as PackedScene
	failed += _assert(pause_packed != null, "pause_menu.tscn load")
	if pause_packed:
		var pm: Node = pause_packed.instantiate()
		tree_root.add_child(pm)
		await process_frame
		pm.call("open_pause")
		failed += _assert(paused == true, "open_pause sets tree.paused")
		pm.call("resume_game")
		failed += _assert(paused == false, "resume_game clears tree.paused")
		pm.queue_free()
		await process_frame

	# Offers removed
	failed += _assert(not game_state.has_method("try_offer"), "try_offer removed")

	# green_thumb retarget: Grow Fertilizer stays raw; craft 10*0.9=9
	game_state.call("reset_for_new_game")
	game_state.call("_set_stage", &"mature")  # next = elder needs fertilizer 12
	var ranks2: Dictionary = game_state.get("upgrade_ranks")
	ranks2["green_thumb"] = 1
	game_state.set("upgrade_ranks", ranks2)
	var needs_gt: Dictionary = game_state.call("get_next_stage_needs")
	failed += _assert(int(needs_gt.get("essence", 0)) == 60, "green_thumb leaves Grow essence alone")
	failed += _assert(int(needs_gt.get("fertilizer", 0)) == 12, "green_thumb does not cut Grow fertilizer")
	failed += _assert(not needs_gt.has("food"), "grow needs have no food")
	failed += _assert(not needs_gt.has("wood"), "grow needs have no wood")
	var fert_craft_gt: Dictionary = backpack.call("get_recipe_ingredients", "fertilizer")
	failed += _assert(int(fert_craft_gt.get("wood", 0)) == 9, "green_thumb craft wood 10*0.9=9")
	failed += _assert(int(fert_craft_gt.get("stone", 0)) == 9, "green_thumb craft stone 10*0.9=9")
	failed += _assert(int(fert_craft_gt.get("food", 0)) == 9, "green_thumb craft food 10*0.9=9")
	game_state.call("set_resource", &"wood", 9)
	game_state.call("set_resource", &"stone", 9)
	game_state.call("set_resource", &"food", 9)
	failed += _assert(str(backpack.call("try_craft", "fertilizer")) == "ok", "craft fertilizer at thumb-reduced 9/9/9")
	failed += _assert(int(game_state.get("wood")) == 0, "thumb craft spends 9 wood")
	failed += _assert(int(backpack.call("get_count", "fertilizer")) == 1, "thumb craft grants fertilizer")

	# Fruit / Ascend cycle (SYSTEMS v0.2.4 — Manashard shop; Ascension-only; Ascend optional)
	failed += _assert(str(content_strings.call("get_text", "fruit_step_1")).find("Harvest") >= 0, "fruit_step_1")
	failed += _assert(str(content_strings.call("get_text", "fruit_step_2")).find("Bless") >= 0, "fruit_step_2")
	failed += _assert(str(content_strings.call("get_text", "fruit_step_3")).find("Ascend") >= 0, "fruit_step_3")
	failed += _assert(str(content_strings.call("get_text", "fruit_flow_hint")).find("Ascension shop only") >= 0, "fruit_flow_hint")
	failed += _assert(str(content_strings.call("get_text", "fruit_panel_title")).find("Ascension") >= 0, "fruit_panel_title")
	failed += _assert(str(content_strings.call("get_text", "fruit_shards_hud")).find("Manashards") >= 0, "fruit_shards_hud")
	failed += _assert(str(content_strings.call("get_text", "upgrade_cost")).find("Manashards") >= 0, "upgrade_cost shards")
	failed += _assert(str(content_strings.call("get_text", "upgrade_cant_afford")).find("Manashards") >= 0, "upgrade_cant_afford")
	failed += _assert(str(content_strings.call("get_text", "ascend_hint")).find("Essence") >= 0, "ascend_hint Essence wipe")
	failed += _assert(str(content_strings.call("get_text", "ascend_before_bless_hint")).find("Manashards") >= 0, "ascend_before_bless_hint")
	failed += _assert(str(content_strings.call("get_text", "fruit_precommit_cta")).find("Primordial Fruit") >= 0, "fruit_precommit_cta")
	failed += _assert(str(content_strings.call("get_text", "fruit_precommit_hint")).find("water") >= 0, "fruit_precommit_hint")
	failed += _assert(str(content_strings.call("get_text", "fruit_precommit_no_shop")).find("Blessings") >= 0, "fruit_precommit_no_shop")
	failed += _assert(str(content_strings.call("get_text", "fruit_confirm_step1_yes")) == "Continue", "fruit step1 Continue")
	failed += _assert(str(content_strings.call("get_text", "fruit_confirm_step1_no")).find("watering") >= 0, "fruit step1 Keep watering")
	failed += _assert(str(content_strings.call("get_text", "fruit_confirm_step1")).find("still water") >= 0, "fruit step1 water until commit")
	failed += _assert(str(content_strings.call("get_text", "fruit_confirm_step2_yes")) == "Harvest", "fruit step2 Harvest")
	failed += _assert(str(content_strings.call("get_text", "fruit_confirm_step2_no")) == "Not yet", "fruit step2 Not yet")
	failed += _assert(str(content_strings.call("get_text", "fruit_confirm_step2")).find("must Ascend") >= 0, "fruit step2 commit copy")
	failed += _assert(str(content_strings.call("get_text", "fruit_shop_only_banner")).find("blessing shop only") >= 0, "fruit_shop_only_banner")
	failed += _assert(str(content_strings.call("get_text", "ascension_paused_title")) == "Ascension", "ascension_paused_title")
	failed += _assert(str(content_strings.call("get_text", "ascension_paused_body")).find("cannot return to watering") >= 0, "ascension_paused_body")
	failed += _assert(str(content_strings.call("get_text", "tree_water_ancient_note")).find("still water") >= 0, "tree_water_ancient_note")
	failed += _assert(str(content_strings.call("get_text", "tree_water_ancient_ok")).find("still drinks") >= 0, "tree_water_ancient_ok")
	failed += _assert(str(content_strings.call("get_text", "tree_ancient_care_hint")).find("Keep watering") >= 0, "tree_ancient_care_hint")
	failed += _assert(str(content_strings.call("get_text", "ascend_confirm_no")) == "Keep shopping", "ascend_confirm_no")
	failed += _assert(str(content_strings.call("get_text", "welcome_body")).find("Manashards") >= 0, "welcome_body manashards")
	# Shop locked before Fruit harvest
	game_state.call("reset_for_new_game")
	failed += _assert(not bool(game_state.call("can_buy_upgrade", "keeper_stride")), "shop locked pre-fruit")

	# Path A: Ascend without buying (always available after harvest)
	game_state.call("reset_for_new_game")
	game_state.call("_set_stage", &"ancient")
	failed += _assert(bool(game_state.get("fruit_ready")), "fruit ready at forced ancient")
	game_state.call("set_resource", &"wood", 11)
	game_state.call("set_resource", &"stone", 7)
	game_state.call("set_resource", &"food", 5)
	game_state.call("set_resource", &"manashards", 3)
	game_state.call("set_resource", &"essence", 4)
	var ess_before_a: int = int(game_state.get("essence"))
	var gained_a: int = int(game_state.call("harvest_fruit"))
	failed += _assert(gained_a >= 1, "fruit commit ok A: %d" % gained_a)
	failed += _assert(int(game_state.get("essence")) == ess_before_a, "no Essence bank on Fruit commit")
	failed += _assert(bool(game_state.get("fruit_harvested_pending_ascend")), "pending after harvest")
	failed += _assert(bool(game_state.get("fruit_committed")), "fruit_committed after harvest")
	failed += _assert(not bool(game_state.get("fruit_ready")), "fruit_ready false after harvest")
	failed += _assert(bool(game_state.call("can_ascend")), "can_ascend without purchase")
	failed += _assert(int(game_state.call("harvest_fruit")) == 0, "harvest disabled while pending")
	var w_block: Dictionary = game_state.call("apply_water_pulse")
	failed += _assert(not bool(w_block.get("ok", true)), "water blocked after fruit commit")
	failed += _assert(str(w_block.get("reason", "")) == "pending_ascend", "water deny reason pending_ascend")
	# Costs: SYSTEMS v0.2.5 SHOP_BASE=400 → cost = 400 * (rank + 1)
	failed += _assert(int(game_state.call("get_upgrade_cost", "keeper_stride")) == 400, "stride cost 400*(rank+1)")
	failed += _assert(int(game_state.call("get_upgrade_cost", "green_thumb")) == 400, "thumb cost 400*(rank+1)")
	failed += _assert(int(game_state.call("get_upgrade_cost", "shard_sight")) == 400, "sight cost 400*(rank+1)")
	failed += _assert(int(game_state.call("get_upgrade_cost", "deep_roots")) == 400, "roots cost 400 at rank 0")
	failed += _assert(int(game_state.call("get_upgrade_cost", "forager")) == 400, "forager cost 400 at rank 0")
	game_state.call("ascend")
	failed += _assert(str(game_state.get("stage_id")) == "sapling", "ascend → sapling (no buy)")
	failed += _assert(int(game_state.get("wood")) == 0, "soft wood cleared")
	failed += _assert(int(game_state.get("stone")) == 0, "soft stone cleared")
	failed += _assert(int(game_state.get("food")) == 0, "soft food cleared")
	failed += _assert(int(game_state.get("manashards")) == 0, "soft shards cleared")
	failed += _assert(int(game_state.get("essence")) == 0, "essence wiped on ascend")
	failed += _assert(not bool(game_state.get("fruit_harvested_pending_ascend")), "pending false after ascend")
	failed += _assert(not bool(game_state.get("fruit_committed")), "committed false after ascend")
	failed += _assert(int(game_state.get("ascensions")) == 1, "ascensions +1")
	failed += _assert(not bool(game_state.call("can_buy_upgrade", "keeper_stride")), "shop locked after ascend")

	# Path B: harvest → multi-buy with Manashards → ascend; ranks+essence persist; shards wipe
	game_state.call("reset_for_new_game")
	game_state.call("_set_stage", &"ancient")
	game_state.call("set_resource", &"essence", 10)
	game_state.call("set_resource", &"manashards", 1500)
	game_state.call("set_resource", &"wood", 2)
	var gained: int = int(game_state.call("harvest_fruit"))
	failed += _assert(gained >= 1, "fruit commit ok B: %d" % gained)
	failed += _assert(bool(game_state.call("can_ascend")), "pending ascend B")
	var ess_pre_buy: int = int(game_state.get("essence"))
	failed += _assert(ess_pre_buy == 10, "no Essence bank on Fruit commit B")
	var shards_pre: int = int(game_state.get("manashards"))
	failed += _assert(bool(game_state.call("buy_upgrade", "keeper_stride")), "buy stride rank0 (400)")
	failed += _assert(int(game_state.call("get_upgrade_cost", "keeper_stride")) == 800, "stride cost 800 at rank 1")
	failed += _assert(bool(game_state.call("buy_upgrade", "keeper_stride")), "buy stride rank1 (800) multi-buy")
	failed += _assert(int(game_state.call("get_upgrade_rank", "keeper_stride")) == 2, "stride rank 2")
	failed += _assert(int(game_state.get("manashards")) < shards_pre, "manashards spent on blessings")
	failed += _assert(int(game_state.get("essence")) == ess_pre_buy, "essence untouched by shop")
	var ess_kept: int = int(game_state.get("essence"))
	var leftover_shards: int = int(game_state.get("manashards"))
	failed += _assert(leftover_shards > 0, "leftover shards before ascend")
	game_state.call("ascend")
	failed += _assert(str(game_state.get("stage_id")) == "sapling", "ascend reset B")
	failed += _assert(int(game_state.get("wood")) == 0, "soft mats 0 after ascend B")
	failed += _assert(int(game_state.get("manashards")) == 0, "leftover shards wiped on ascend")
	failed += _assert(int(game_state.get("essence")) == 0, "essence wiped on ascend B")
	failed += _assert(int(game_state.call("get_upgrade_rank", "keeper_stride")) == 2, "blessings kept")
	failed += _assert(not bool(game_state.get("fruit_harvested_pending_ascend")), "pending false B")
	failed += _assert(not bool(game_state.get("fruit_committed")), "committed false B")

	# fruit_committed persists on SAVE_VERSION 5; migrate from fruit_harvested_pending_ascend
	game_state.call("reset_for_new_game")
	game_state.call("_set_stage", &"ancient")
	game_state.call("set_resource", &"essence", 8)
	var gained_save: int = int(game_state.call("harvest_fruit"))
	failed += _assert(gained_save >= 1, "harvest for save field")
	var committed_payload: Dictionary = game_state.call("to_save_dict")
	failed += _assert(bool(committed_payload.get("fruit_committed", false)), "to_save_dict fruit_committed")
	failed += _assert(bool(committed_payload.get("fruit_harvested_pending_ascend", false)), "to_save_dict alias")
	failed += _assert(int(save_service.get("SAVE_VERSION")) == 6, "SAVE_VERSION stays 6 with fruit_committed")
	game_state.call("reset_for_new_game")
	failed += _assert(not bool(game_state.get("fruit_committed")), "reset clears fruit_committed")
	game_state.call("apply_save_dict", committed_payload)
	failed += _assert(bool(game_state.get("fruit_committed")), "apply_save_dict fruit_committed")
	failed += _assert(bool(game_state.get("fruit_harvested_pending_ascend")), "apply_save_dict alias sync")
	var alias_only_payload: Dictionary = committed_payload.duplicate(true)
	alias_only_payload.erase("fruit_committed")
	alias_only_payload["fruit_harvested_pending_ascend"] = true
	game_state.call("reset_for_new_game")
	game_state.call("apply_save_dict", alias_only_payload)
	failed += _assert(bool(game_state.get("fruit_committed")), "migrate pending_ascend → fruit_committed")
	failed += _assert(not bool(game_state.get("fruit_ready")), "committed load clears fruit_ready")

	# Main scene: 3 harvestables, ClickLayer IGNORE, care PayButton, no Offer buttons
	var packed: PackedScene = load("res://scenes/main.tscn") as PackedScene
	failed += _assert(packed != null, "main.tscn load")
	if packed:
		var inst: Node = packed.instantiate()
		var harvest_count: int = 0
		for child: Node in inst.get_node("World").get_children():
			var scr: Variant = child.get_script()
			if scr != null and str(scr.resource_path).ends_with("gatherable.gd"):
				harvest_count += 1
		failed += _assert(harvest_count == 3, "expected exactly 3 harvestables, got %d" % harvest_count)
		var click_layer: ColorRect = inst.get_node_or_null("ClickLayer") as ColorRect
		failed += _assert(click_layer != null, "ClickLayer missing")
		if click_layer:
			failed += _assert(
				click_layer.mouse_filter == Control.MOUSE_FILTER_IGNORE,
				"ClickLayer must IGNORE so harvest Area2D clicks work (got %d)" % click_layer.mouse_filter
			)
		var hud: Node = inst.get_node_or_null("HUD")
		failed += _assert(hud != null, "HUD missing")
		if hud:
			failed += _assert(hud.get_node_or_null("WelcomePanel") != null, "WelcomePanel missing")
			failed += _assert(hud.get_node_or_null("CarePanel/CareNeedsLabel") != null, "CareNeedsLabel missing")
			failed += _assert(hud.get_node_or_null("CarePanel/ActionBand/PayButton") != null, "PayButton missing")
			failed += _assert(hud.get_node_or_null("Panel/BackpackButton") != null, "BackpackButton missing")
			failed += _assert(hud.get_node_or_null("Panel/BackpackButton/BackpackIcon") != null, "BackpackIcon ColorRect missing")
			failed += _assert(hud.get_node_or_null("BackpackPanel") != null, "BackpackPanel missing")
			failed += _assert(hud.get_node_or_null("BackpackPanel/CraftScroll/CraftList") != null, "CraftList missing")
			failed += _assert(hud.get_node_or_null("CarePanel/CareGrowCosts/FertilizerIcon") != null, "Grow FertilizerIcon missing")
			failed += _assert(hud.get_node_or_null("CarePanel/CareGrowCosts/EssenceIcon") != null, "Grow EssenceIcon missing")
			failed += _assert(FileAccess.file_exists("res://docs/ART_NEEDED_BACKPACK.md"), "ART_NEEDED_BACKPACK.md")
			failed += _assert(FileAccess.file_exists("res://data/handcraft_recipes.json"), "handcraft_recipes.json")
			failed += _assert(FileAccess.file_exists("res://data/hub_map.json"), "hub_map.json")
			var hub_file := FileAccess.open("res://data/hub_map.json", FileAccess.READ)
			failed += _assert(hub_file != null, "open hub_map.json")
			if hub_file:
				var hub_parsed: Variant = JSON.parse_string(hub_file.get_as_text())
				hub_file.close()
				failed += _assert(typeof(hub_parsed) == TYPE_DICTIONARY, "hub_map json dict")
				if typeof(hub_parsed) == TYPE_DICTIONARY:
					var hub: Dictionary = hub_parsed
					failed += _assert(abs(float(hub.get("map_width_mult", 0)) - 2.0) < 0.01, "MAP_WIDTH_MULT 2")
					failed += _assert(abs(float(hub.get("map_height_mult", 0)) - 3.0) < 0.01, "MAP_HEIGHT_MULT 3")
					failed += _assert(bool(hub.get("edge_scroll", true)) == false, "EDGE_SCROLL false")
			failed += _assert(hud.get_node_or_null("CarePanel/ActionBand/HarvestFruitButton") != null, "HarvestFruitButton missing")
			failed += _assert(hud.get_node_or_null("CarePanel/ActionBand/WaterButton") != null, "WaterButton missing")
			failed += _assert(hud.get_node_or_null("CarePanel/Header/CareCloseButton") != null, "care dismiss Close")
			failed += _assert(hud.get_node_or_null("CarePanel/UpgradeList") == null, "care must not embed UpgradeList")
			failed += _assert(hud.get_node_or_null("CarePanel/ShopScroll") == null, "care must not embed ShopScroll")
			failed += _assert(hud.get_node_or_null("CarePanel/Footer") == null, "care must not use shop footer")
			failed += _assert(hud.get_node_or_null("CarePanel/AscendButton") == null, "care must not have Ascend")
			failed += _assert(hud.get_node_or_null("CarePanel/OfferWoodButton") == null, "OfferWoodButton must be gone")
			failed += _assert(hud.get_node_or_null("Panel/PauseButton") != null, "PauseButton missing")
			failed += _assert(hud.get_node_or_null("PrestigePanel") == null, "old PrestigePanel must be gone")
			failed += _assert(hud.get_node_or_null("AscensionPanel/ShopScroll") != null, "Ascension ShopScroll missing")
			failed += _assert(hud.get_node_or_null("AscensionPanel/Footer/AscendButton") != null, "Ascend footer missing")
			failed += _assert(hud.get_node_or_null("AscensionPanel/Footer/CloseButton") != null, "Close footer missing")
			failed += _assert(hud.get_node_or_null("AscensionPanel/Header/ShardChip") != null, "shard chip missing")
			failed += _assert(hud.get_node_or_null("AscensionPanel/Layout") == null, "old Layout container retired")
			failed += _assert(hud.get_node_or_null("FruitConfirmPanel") != null, "FruitConfirmPanel missing")
			failed += _assert(hud.get_node_or_null("FruitConfirmPanel/UpgradeList") == null, "fruit modal must not have shop list")
			failed += _assert(int(hud.process_mode) == 3, "HUD PROCESS_MODE_ALWAYS")
			failed += _assert(FileAccess.file_exists("res://assets/art/ui/ASCENSION_SHOP_LAYOUT_V01.md"), "layout spec")
			failed += _assert(FileAccess.file_exists("res://assets/art/ui/ascension_shop_layout_meta.json"), "layout meta")
			failed += _assert(FileAccess.file_exists("res://assets/art/ui/MANATREE_CARE_PANEL_V01.md"), "care layout spec")
			failed += _assert(FileAccess.file_exists("res://assets/art/ui/manatree_care_panel_meta.json"), "care layout meta")
		var pause_menu: Node = inst.get_node_or_null("PauseMenu")
		failed += _assert(pause_menu != null, "PauseMenu missing")
		if pause_menu:
			failed += _assert(int(pause_menu.process_mode) == 3, "PauseMenu PROCESS_MODE_ALWAYS")
			failed += _assert(pause_menu.has_method("open_pause"), "open_pause")
			failed += _assert(pause_menu.has_method("resume_game"), "resume_game")
			failed += _assert(pause_menu.get_node_or_null("OptionsPanel/MusicSlider") != null, "Options MusicSlider")
			failed += _assert(pause_menu.get_node_or_null("OptionsPanel/SfxSlider") != null, "Options SfxSlider")
			failed += _assert(pause_menu.get_node_or_null("OptionsPanel/OptionsReset") != null, "Options Reset")
			failed += _assert(pause_menu.get_node_or_null("OptionsPanel/OptionsLabel") == null, "Options stub label retired")
		inst.free()

	var cues: PackedStringArray = game_audio.call("list_cue_ids")
	failed += _assert(cues.size() >= 28, "audio cue table too small (%d)" % cues.size())
	failed += _assert(ResourceLoader.exists("res://assets/audio/sfx_water_pulse.ogg"), "sfx_water_pulse missing")
	failed += _assert(ResourceLoader.exists("res://assets/audio/sfx_stage_up.ogg"), "sfx_stage_up missing")
	failed += _assert(ResourceLoader.exists("res://assets/audio/sfx_channel_start.ogg"), "sfx_channel_start missing")
	failed += _assert(ResourceLoader.exists("res://assets/audio/mus_hub_forest_haex.mp3"), "hub haex.mp3 missing")
	failed += _assert(ResourceLoader.exists("res://assets/audio/mus_hub_forest_haex_loop.ogg"), "hub haex_loop.ogg fallback missing")
	# Cue primary = Haex MP3 (Director); ogg haex_loop is GameAudio fallback
	var hub_cues_raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/audio_cues.json"))
	var hub_root: Dictionary = hub_cues_raw as Dictionary
	var hub_cues_tbl: Dictionary = hub_root.get("cues", {}) as Dictionary
	var hub_meta: Dictionary = hub_cues_tbl.get("mus_hub_forest", {}) as Dictionary
	var hub_path: String = str(hub_meta.get("path", ""))
	failed += _assert(hub_path.ends_with("mus_hub_forest_haex.mp3"), "mus_hub_forest cue path: %s" % hub_path)
	failed += _assert(bool(hub_meta.get("loop", false)), "mus_hub_forest loop=true")
	failed += _assert(str(hub_meta.get("bus", "")) == "Music", "mus_hub_forest Music bus")
	game_audio.call("play_hub_music")
	failed += _assert(game_audio.call("get_cue_path", &"mus_hub_forest").ends_with("mus_hub_forest_haex.mp3"), "get_cue_path haex.mp3")
	var hub_stream: Variant = game_audio.call("get_hub_stream")
	failed += _assert(hub_stream != null, "play_hub_music sets stream")
	failed += _assert(bool(game_audio.call("is_hub_music_playing")), "hub playing after play_hub_music")
	failed += _assert(int(game_audio.process_mode) == 3, "GameAudio PROCESS_MODE_ALWAYS")
	failed += _assert(bool(game_audio.call("is_hub_player_always")), "hub MusicPlayer ALWAYS")
	failed += _assert(hub_stream is AudioStreamMP3 or hub_stream is AudioStreamOggVorbis or hub_stream is AudioStreamWAV, "hub stream type")
	if hub_stream is AudioStreamMP3:
		failed += _assert(bool((hub_stream as AudioStreamMP3).loop), "AudioStreamMP3.loop forced true")
	# Stings must not silence Music bus forever — second sting player; hub stays up
	game_audio.call("play", &"mus_fruit_sting")
	failed += _assert(bool(game_audio.call("is_hub_music_playing")), "hub still playing under fruit sting")
	game_audio.call("play", &"mus_ascend_sting")
	failed += _assert(bool(game_audio.call("is_hub_music_playing")), "hub still playing under ascend sting")
	game_audio.call("clear_played_log")
	game_audio.call("play_ui_confirm")
	failed += _assert(bool(game_audio.call("did_play", &"sfx_ui_confirm")), "Fruit intent cue sfx_ui_confirm")
	game_audio.call("clear_played_log")
	game_audio.call("play_fruit_harvest")
	failed += _assert(bool(game_audio.call("did_play", &"sfx_fruit_harvest")), "commit sfx_fruit_harvest")
	failed += _assert(bool(game_audio.call("did_play", &"mus_fruit_sting")), "commit mus_fruit_sting")
	failed += _assert(bool(game_audio.call("is_hub_music_playing")), "hub still playing after fruit harvest cues")
	game_audio.call("clear_played_log")
	game_audio.call("play_upgrade_buy")
	failed += _assert(bool(game_audio.call("did_play", &"sfx_upgrade_buy")), "bless buy sfx_upgrade_buy")
	game_audio.call("clear_played_log")
	game_audio.call("play_ascend")
	failed += _assert(bool(game_audio.call("did_play", &"sfx_ascend")), "ascend sfx_ascend")
	failed += _assert(bool(game_audio.call("did_play", &"mus_ascend_sting")), "ascend mus_ascend_sting")
	failed += _assert(bool(game_audio.call("is_hub_music_playing")), "hub still playing after ascend cues")
	game_audio.call("play", &"sfx_gather_wood")
	game_audio.call("play", &"sfx_water_pulse")
	game_audio.call("play", &"sfx_stage_up")
	game_audio.call("play", &"sfx_channel_start")
	game_audio.call("play", &"sfx_wisp_assign")
	game_audio.call("play", &"sfx_wisp_deny")
	game_audio.call("play", &"sfx_wisp_unassign")
	game_audio.call("play", &"sfx_wisp_pulse")
	failed += _assert(ResourceLoader.exists("res://assets/audio/sfx_wisp_assign.ogg"), "sfx_wisp_assign missing")
	failed += _assert(ResourceLoader.exists("res://assets/audio/sfx_wisp_deny.ogg"), "sfx_wisp_deny missing")
	failed += _assert(ResourceLoader.exists("res://assets/audio/sfx_wisp_unassign.ogg"), "sfx_wisp_unassign missing")
	failed += _assert(ResourceLoader.exists("res://assets/audio/sfx_wisp_pulse.ogg"), "sfx_wisp_pulse missing")
	failed += _assert(game_audio.call("get_cue_path", &"sfx_wisp_assign").ends_with("sfx_wisp_assign.ogg"), "sfx_wisp_assign cue path")
	failed += _assert(game_audio.call("get_cue_path", &"sfx_wisp_deny").ends_with("sfx_wisp_deny.ogg"), "sfx_wisp_deny cue path")
	failed += _assert(game_audio.call("get_cue_path", &"sfx_wisp_unassign").ends_with("sfx_wisp_unassign.ogg"), "sfx_wisp_unassign cue path")
	failed += _assert(game_audio.call("get_cue_path", &"sfx_wisp_pulse").ends_with("sfx_wisp_pulse.ogg"), "sfx_wisp_pulse cue path")
	failed += _assert(bool(game_audio.call("is_hub_music_playing")), "hub still playing after wisp sfx stubs")

	failed += _assert(AudioServer.get_bus_index("Music") >= 0, "Music bus missing")
	failed += _assert(AudioServer.get_bus_index("SFX_World") >= 0, "SFX_World bus missing")
	failed += _assert(AudioServer.get_bus_index("SFX_UI") >= 0, "SFX_UI bus missing")
	failed += _assert(AudioServer.get_bus_index("SFX_Progress") >= 0, "SFX_Progress bus missing")
	# Mix lock defaults: Music ~-9 dB at linear 1.0; SFX at 0 dB
	game_audio.call("reset_volumes_to_defaults")
	var music_db: float = float(game_audio.call("get_music_bus_volume_db"))
	failed += _assert(music_db <= -7.5 and music_db >= -10.5, "Music default dB in [-10,-8] got %s" % music_db)
	var sfx_w_idx: int = AudioServer.get_bus_index("SFX_World")
	failed += _assert(abs(AudioServer.get_bus_volume_db(sfx_w_idx) - 0.0) < 0.01, "SFX_World default 0 dB")
	# Volume settings persist roundtrip (ConfigFile) — volume only, hub stays
	game_audio.call("set_music_volume_linear", 0.42)
	game_audio.call("set_sfx_volume_linear", 0.73)
	game_audio.call("save_settings")
	failed += _assert(bool(game_audio.call("is_hub_music_playing")), "hub still after volume change")
	game_audio.set("music_volume_linear", 1.0)
	game_audio.set("sfx_volume_linear", 1.0)
	game_audio.call("load_settings")
	failed += _assert(abs(float(game_audio.get("music_volume_linear")) - 0.42) < 0.001, "music vol persist")
	failed += _assert(abs(float(game_audio.get("sfx_volume_linear")) - 0.73) < 0.001, "sfx vol persist")
	game_audio.call("apply_volumes")
	game_audio.call("reset_volumes_to_defaults")


	# --- SYSTEMS v0.3.2 / Content v0.3.3: RTS LMB/RMB + assigned wisp orbit + Manatree shards ---
	failed += _assert(str(content_strings.call("get_text", "controls_lmb_select")) == "Left-click: select", "controls_lmb_select")
	failed += _assert(str(content_strings.call("get_text", "controls_rmb_command")) == "Right-click: command", "controls_rmb_command")
	failed += _assert(str(content_strings.call("get_text", "controls_lmb_deselect")).find("deselect") >= 0, "controls_lmb_deselect")
	failed += _assert(str(content_strings.call("get_text", "controls_hint")).find("LMB") >= 0, "controls_hint")
	failed += _assert(str(content_strings.call("get_text", "keeper_select_hint")).find("Left-click") >= 0, "keeper_select_hint")
	failed += _assert(str(content_strings.call("get_text", "keeper_required")).find("Select the Keeper") >= 0, "keeper_required")
	failed += _assert(str(content_strings.call("get_text", "keeper_required_harvest")).find("right-click") >= 0, "keeper_required_harvest RMB")
	failed += _assert(str(content_strings.call("get_text", "keeper_deselect_toast")) == "Cleared.", "keeper_deselect_toast")
	failed += _assert(str(content_strings.call("get_text", "wisp_assign_to_manatree")) == "Gather Manashards", "wisp_assign_to_manatree")
	failed += _assert(str(content_strings.call("get_text", "wisp_orbit_hint")).find("Assigned Wisps orbit") >= 0, "wisp_orbit_hint assigned orbit")
	failed += _assert(str(content_strings.call("get_text", "wisp_assigned_hud")).find("Orbiting") >= 0, "wisp_assigned_hud")
	failed += _assert(str(content_strings.call("get_text", "wisp_assign_manatree_ok")).find("Manashards") >= 0, "wisp_assign_manatree_ok")
	failed += _assert(str(content_strings.call("get_text", "wisp_idle_hud")) == "Nearby", "wisp_idle_hud Nearby")
	failed += _assert(str(content_strings.call("get_text", "wisp_assign_ok")).find("Wisp") >= 0, "wisp_assign_ok")
	failed += _assert(str(content_strings.call("get_text", "upgrade_wisp_haste_name")).find("Swift") >= 0, "Swift Wisps name")
	failed += _assert(str(content_strings.call("get_text", "upgrade_bonus_wisp_name")).find("Extra") >= 0, "Extra Wisp name")
	failed += _assert(FileAccess.file_exists("res://assets/art/wisps/wisp_idle_0000.png"), "wisp idle art")
	failed += _assert(FileAccess.file_exists("res://assets/art/wisps/wisp_selected_0000.png"), "wisp selected art")
	failed += _assert(FileAccess.file_exists("res://assets/art/wisps/wisp_parked_0000.png"), "wisp parked art")
	failed += _assert(FileAccess.file_exists("res://assets/art/wisps/wisp_orbit_0000.png"), "wisp orbit art")
	failed += _assert(FileAccess.file_exists("res://assets/art/wisps/wisp_fly_0000.png"), "wisp fly art")
	failed += _assert(FileAccess.file_exists("res://assets/art/wisps/wisp_fly.png"), "wisp fly strip")
	failed += _assert(FileAccess.file_exists("res://assets/art/wisps/wisp_node_orbit_0000.png"), "wisp node_orbit art")
	failed += _assert(FileAccess.file_exists("res://assets/art/wisps/wisp_node_orbit.png"), "wisp node_orbit strip")
	var wisp_meta_file := FileAccess.open("res://assets/art/wisps/wisp_meta.json", FileAccess.READ)
	failed += _assert(wisp_meta_file != null, "open wisp_meta")
	if wisp_meta_file:
		var wisp_meta_parsed: Variant = JSON.parse_string(wisp_meta_file.get_as_text())
		wisp_meta_file.close()
		failed += _assert(typeof(wisp_meta_parsed) == TYPE_DICTIONARY, "wisp meta dict")
		if typeof(wisp_meta_parsed) == TYPE_DICTIONARY:
			var wm: Dictionary = wisp_meta_parsed
			failed += _assert(str(wm.get("version", "")) == "v0.1.10-node-orbit", "wisp meta v0.1.10-node-orbit")
			failed += _assert(wm.has("behavior_summary"), "wisp behavior_summary")
			var nlayout: Variant = wm.get("node_orbit_layout", {})
			failed += _assert(typeof(nlayout) == TYPE_DICTIONARY, "node_orbit_layout")
			if typeof(nlayout) == TYPE_DICTIONARY:
				failed += _assert(int((nlayout as Dictionary).get("radius_px", 0)) == 28, "node orbit r=28")
			var clips_m: Variant = wm.get("clips", {})
			if typeof(clips_m) == TYPE_DICTIONARY:
				var parked_c: Dictionary = (clips_m as Dictionary).get("parked", {}) as Dictionary
				failed += _assert(str(parked_c.get("alias_of", "")) == "node_orbit", "parked alias node_orbit")
				var assigned_c: Dictionary = (clips_m as Dictionary).get("assigned", {}) as Dictionary
				failed += _assert(str(assigned_c.get("alias_of", "")) == "node_orbit", "assigned alias node_orbit")
	failed += _assert(FileAccess.file_exists("res://assets/art/keeper/keeper_select_ring.png"), "keeper select ring")
	failed += _assert(ResourceLoader.exists("res://scenes/wisp.tscn"), "wisp.tscn")

	var haste_def: Dictionary = game_state.call("get_upgrade_def", "wisp_haste")
	failed += _assert(str(haste_def.get("display_name", "")) == "Swift Wisps", "wisp_haste display")
	failed += _assert(str(haste_def.get("effect", "")) == "wisp_pulse_reduce", "wisp_haste effect")
	failed += _assert(int(haste_def.get("max_rank", 0)) == 5, "wisp_haste max 5")
	var bonus_def: Dictionary = game_state.call("get_upgrade_def", "bonus_wisp")
	failed += _assert(str(bonus_def.get("display_name", "")) == "Extra Wisp", "bonus_wisp display")
	failed += _assert(int(bonus_def.get("max_rank", 0)) == 3, "bonus_wisp max 3")
	failed += _assert(int(game_state.call("param_int", "WISP_PER_NODE", -1)) == 0, "WISP_PER_NODE unlimited")
	failed += _assert(int(game_state.call("param_int", "WISP_PER_MANATREE", -1)) == 0, "WISP_PER_MANATREE unlimited")
	failed += _assert(int(game_state.call("param_float", "WISP_PULSE_SEC", 0.0)) == 10, "WISP_PULSE_SEC 10")
	failed += _assert(int(game_state.call("param_int", "WISP_PULSE_GRANT", 0)) == 1, "WISP_PULSE_GRANT")

	# Stage Grow grants +1 wisp
	game_state.call("reset_for_new_game")
	failed += _assert(int(game_state.get("wisp_count")) == 0, "start 0 wisps")
	game_state.call("set_resource", &"essence", 20)
	backpack.call("add_item", "fertilizer", 3)
	failed += _assert(str(game_state.call("try_grow_stage")) == "ok", "grow young for wisp")
	failed += _assert(int(game_state.get("wisp_count")) == 1, "wisp +1 after young")
	game_state.call("set_resource", &"essence", 40)
	backpack.call("add_item", "fertilizer", 6)
	failed += _assert(str(game_state.call("try_grow_stage")) == "ok", "grow mature")
	failed += _assert(int(game_state.get("wisp_count")) == 2, "wisp +1 after mature")

	# Assign + simulate 10s pulse → +1 resource (no gather_mult)
	game_state.call("reset_for_new_game")
	game_state.set("wisp_count", 1)
	game_state.call("_ensure_wisp_slots")
	var wood0: int = int(game_state.get("wood"))
	failed += _assert(str(game_state.call("try_assign_wisp", 0, "harvest_tree")) == "ok", "assign wisp to tree")
	failed += _assert(str(game_state.call("get_wisp_assignment", 0)) == "harvest_tree", "assignment stored")
	# Second wisp stacks on same node
	game_state.set("wisp_count", 2)
	game_state.call("_ensure_wisp_slots")
	failed += _assert(str(game_state.call("try_assign_wisp", 1, "harvest_tree")) == "join", "stack join harvest_tree")
	failed += _assert(int(game_state.call("count_wisps_on_node", "harvest_tree")) == 2, "two wisps on tree")
	# Pulse accum — each wisp own timer → +2 wood after ~10s
	failed += _assert(abs(float(game_state.call("get_wisp_pulse_sec")) - 10.0) < 0.01, "pulse sec base 10")
	game_state.call("apply_wisp_pulses", 9.9)
	failed += _assert(int(game_state.get("wood")) == wood0, "no grant before 10s")
	game_state.call("apply_wisp_pulses", 0.2)
	failed += _assert(int(game_state.get("wood")) == wood0 + 2, "stacked wisps pulse +2 wood after ~10s")
	# wisp_haste reduces interval
	var ranks_h: Dictionary = game_state.get("upgrade_ranks")
	ranks_h["wisp_haste"] = 3
	game_state.set("upgrade_ranks", ranks_h)
	failed += _assert(abs(float(game_state.call("get_wisp_pulse_sec")) - 7.0) < 0.01, "haste rank3 → 7s")
	ranks_h["wisp_haste"] = 5
	game_state.set("upgrade_ranks", ranks_h)
	failed += _assert(abs(float(game_state.call("get_wisp_pulse_sec")) - 5.0) < 0.01, "haste min 5s")
	# Unassign
	failed += _assert(bool(game_state.call("unassign_wisp", 0)), "unassign")
	failed += _assert(str(game_state.call("get_wisp_assignment", 0)) == "", "cleared assignment")

	# Keeper selection state
	game_state.call("reset_for_new_game")
	failed += _assert(bool(game_state.get("keeper_selected")) == false, "keeper not selected by default")
	game_state.call("set_keeper_selected", true)
	failed += _assert(bool(game_state.get("keeper_selected")) == true, "keeper selected")
	game_state.call("select_wisp", 0)  # no wisps — no-op
	game_state.set("wisp_count", 1)
	game_state.call("_ensure_wisp_slots")
	game_state.call("select_wisp", 0)
	failed += _assert(int(game_state.get("selected_wisp_id")) == 0, "wisp select without needing keeper")
	game_state.call("clear_selection")
	failed += _assert(bool(game_state.get("keeper_selected")) == false and int(game_state.get("selected_wisp_id")) == -1, "clear selection")

	# Ascend resets wisps to bonus_wisp rank
	game_state.call("reset_for_new_game")
	game_state.call("_set_stage", &"ancient")
	game_state.set("wisp_count", 4)
	game_state.call("_ensure_wisp_slots")
	game_state.call("try_assign_wisp", 0, "harvest_tree")
	var ranks_b: Dictionary = game_state.get("upgrade_ranks")
	ranks_b["bonus_wisp"] = 2
	game_state.set("upgrade_ranks", ranks_b)
	game_state.call("set_resource", &"manashards", 100)
	game_state.call("harvest_fruit")
	game_state.call("ascend")
	failed += _assert(int(game_state.get("wisp_count")) == 2, "ascend → bonus_wisp count")
	failed += _assert(str(game_state.call("get_wisp_assignment", 0)) == "", "assignments cleared on ascend")

	# Shop costs for wisp blessings
	game_state.call("reset_for_new_game")
	game_state.call("_set_stage", &"ancient")
	game_state.call("harvest_fruit")
	failed += _assert(int(game_state.call("get_upgrade_cost", "wisp_haste")) == 400, "wisp_haste cost 400")
	failed += _assert(int(game_state.call("get_upgrade_cost", "bonus_wisp")) == 400, "bonus_wisp cost 400")
	game_state.call("set_resource", &"manashards", 400)
	failed += _assert(bool(game_state.call("buy_upgrade", "bonus_wisp")), "buy bonus_wisp")
	failed += _assert(int(game_state.call("get_upgrade_rank", "bonus_wisp")) == 1, "bonus_wisp rank 1")

	# Save roundtrip includes wisps
	game_state.call("reset_for_new_game")
	game_state.set("wisp_count", 3)
	game_state.call("_ensure_wisp_slots")
	game_state.call("try_assign_wisp", 1, "harvest_stone")
	game_state.set("welcome_shown", true)
	failed += _assert(bool(save_service.call("save_game", 3)), "save slot 3 wisps")
	game_state.call("reset_for_new_game")
	failed += _assert(bool(save_service.call("load_game", 3)), "load slot 3 wisps")
	failed += _assert(int(game_state.get("wisp_count")) == 3, "loaded wisp_count")
	failed += _assert(str(game_state.call("get_wisp_assignment", 1)) == "harvest_stone", "loaded assignment")

	# LMB select semantics: Keeper XOR Wisp; LMB ground deselects
	game_state.call("reset_for_new_game")
	game_state.set("wisp_count", 2)
	game_state.call("_ensure_wisp_slots")
	game_state.call("select_keeper")
	failed += _assert(bool(game_state.get("keeper_selected")), "select_keeper")
	failed += _assert(int(game_state.get("selected_wisp_id")) == -1, "keeper select clears wisp")
	game_state.call("select_wisp", 0)
	failed += _assert(int(game_state.get("selected_wisp_id")) == 0, "LMB wisp select")
	failed += _assert(bool(game_state.get("keeper_selected")) == false, "wisp select deselects keeper")
	game_state.call("select_wisp", 0)
	failed += _assert(int(game_state.get("selected_wisp_id")) == 0, "LMB same wisp stays selected")
	game_state.call("select_wisp", 1)
	failed += _assert(int(game_state.get("selected_wisp_id")) == 1, "LMB other wisp replaces")
	game_state.call("clear_selection")
	failed += _assert(bool(game_state.get("keeper_selected")) == false and int(game_state.get("selected_wisp_id")) == -1, "LMB ground deselect")

	# Manatree assign + pulse manashards @ 1/10s
	failed += _assert(str(game_state.call("node_id_for_resource", &"manashards")) == "manatree", "manashards node id is manatree")
	failed += _assert(str(content_strings.call("get_text", "wisp_assign_join_ok")).find("joins") >= 0, "wisp_assign_join_ok")
	failed += _assert(str(content_strings.call("get_text", "wisp_node_shared_hint")).find("share") >= 0, "wisp_node_shared_hint")
	failed += _assert(str(content_strings.call("get_text", "ascend_essence_reset_toast")).find("Essence") >= 0, "ascend_essence_reset_toast")
	failed += _assert(str(content_strings.call("get_text", "ascend_confirm")).find("Essence") >= 0, "ascend_confirm Essence wipe")
	failed += _assert(str(content_strings.call("get_text", "fruit_harvest_toast")).find("Essence +") < 0, "fruit_harvest_toast no Essence bank")
	failed += _assert(str(content_strings.call("get_text", "wisp_assign_hint")).find("Right-click") >= 0, "wisp_assign_hint RMB")
	game_state.call("reset_for_new_game")
	game_state.set("wisp_count", 2)
	game_state.call("_ensure_wisp_slots")
	var shards0: int = int(game_state.get("manashards"))
	failed += _assert(str(game_state.call("try_assign_wisp", 0, "manatree")) == "ok", "assign wisp to manatree")
	failed += _assert(str(game_state.call("get_wisp_assignment", 0)) == "manatree", "manatree assignment stored")
	failed += _assert(str(game_state.call("resource_for_node_id", "manatree")) == "manashards", "manatree → manashards")
	failed += _assert(str(game_state.call("try_assign_wisp", 1, "manatree")) == "join", "Manatree stack join")
	failed += _assert(int(game_state.call("count_wisps_on_node", "manatree")) == 2, "two wisps on manatree")
	game_state.call("apply_wisp_pulses", 9.9)
	failed += _assert(int(game_state.get("manashards")) == shards0, "no manashards before 10s")
	game_state.call("apply_wisp_pulses", 0.2)
	failed += _assert(int(game_state.get("manashards")) == shards0 + 2, "stacked manatree pulse +2 manashards")
	failed += _assert(bool(game_state.call("unassign_wisp", 0)), "unassign from manatree")
	failed += _assert(str(game_state.call("get_wisp_assignment", 0)) == "", "manatree assignment cleared")

	# Save roundtrip manatree assignment (SAVE_VERSION 5, no bump)
	game_state.call("reset_for_new_game")
	game_state.set("wisp_count", 1)
	game_state.call("_ensure_wisp_slots")
	game_state.call("try_assign_wisp", 0, "manatree")
	game_state.set("welcome_shown", true)
	failed += _assert(bool(save_service.call("save_game", 4)), "save slot 4 manatree wisp")
	game_state.call("reset_for_new_game")
	failed += _assert(bool(save_service.call("load_game", 4)), "load slot 4 manatree wisp")
	failed += _assert(str(game_state.call("get_wisp_assignment", 0)) == "manatree", "loaded manatree assignment")

	# Live Main: LMB/RMB helpers, harvest+manatree command, assigned orbit (not parked)
	save_service.call("delete_save")
	game_state.call("reset_for_new_game")
	game_state.set("welcome_shown", true)
	game_state.set("wisp_count", 2)
	game_state.call("_ensure_wisp_slots")
	if packed:
		var live: Node = packed.instantiate()
		tree_root.add_child(live)
		await process_frame
		await process_frame
		var deco_n: int = live.get_tree().get_nodes_in_group("forest_prop").size()
		failed += _assert(deco_n >= 80, "dense forest ring (got %d props)" % deco_n)
		failed += _assert(live.get_node_or_null("Camera2D") != null, "Camera2D present")
		failed += _assert(live.has_method("get_play_size"), "Main.get_play_size")
		if live.has_method("get_play_size"):
			var play: Vector2 = live.call("get_play_size") as Vector2
			failed += _assert(abs(play.x - 2560.0) < 0.5 and abs(play.y - 2160.0) < 0.5, "play area 2560x2160 (got %s)" % play)
		if live.has_method("pan_camera") and live.has_method("camera_min") and live.has_method("camera_max"):
			var cam_min: Vector2 = live.call("camera_min") as Vector2
			var cam_max: Vector2 = live.call("camera_max") as Vector2
			live.call("pan_camera", Vector2(-9999, -9999))
			var clamped_lo: Vector2 = live.call("get_camera_position_clamped") as Vector2
			failed += _assert(clamped_lo.distance_to(cam_min) < 1.5, "camera clamps to min (got %s want %s)" % [clamped_lo, cam_min])
			live.call("pan_camera", Vector2(9999, 9999))
			var clamped_hi: Vector2 = live.call("get_camera_position_clamped") as Vector2
			failed += _assert(clamped_hi.distance_to(cam_max) < 1.5, "camera clamps to max (got %s want %s)" % [clamped_hi, cam_max])
		var tree_cols: int = 0
		var bush_cols: int = 0
		var canopy_ok: int = 0
		for prop: Node in live.get_tree().get_nodes_in_group("forest_prop"):
			var kind: String = str(prop.get_meta("prop_kind", ""))
			var bodies: Array = []
			for ch: Node in prop.get_children():
				if ch is StaticBody2D:
					bodies.append(ch)
			if bodies.is_empty():
				continue
			if kind == "tree":
				tree_cols += 1
				var csz: Vector2 = prop.get_meta("collider_size", Vector2.ZERO) as Vector2
				var spr: Sprite2D = null
				for ch2: Node in prop.get_children():
					if ch2 is Sprite2D:
						spr = ch2
						break
				if spr and spr.texture:
					var tex_h: float = float(spr.texture.get_height())
					if csz.y > 0.0 and csz.y <= tex_h * 0.20 + 2.0:
						canopy_ok += 1
			elif kind == "bush" or kind == "tuft":
				bush_cols += 1
		failed += _assert(tree_cols >= 40, "trees have trunk collision (got %d)" % tree_cols)
		failed += _assert(bush_cols >= 20, "bushes have small collision (got %d)" % bush_cols)
		failed += _assert(canopy_ok >= 20, "tree colliders stay on bottom trunk (got %d)" % canopy_ok)
		var live_keeper: Node = live.get_node_or_null("World/Keeper")
		failed += _assert(live_keeper != null, "live Keeper")
		if live_keeper:
			var kspr: Node = live_keeper.get_node_or_null("Sprite")
			failed += _assert(kspr != null, "Keeper Sprite")
			if kspr:
				var sframes: SpriteFrames = kspr.get("sprite_frames") as SpriteFrames
				failed += _assert(sframes != null, "Keeper SpriteFrames")
				if sframes:
					failed += _assert(sframes.has_animation(&"walk_south"), "walk_south anim")
					failed += _assert(sframes.has_animation(&"idle_south"), "idle_south anim")
					failed += _assert(sframes.get_frame_count(&"walk_south") == 9, "walk_south frame count")
					failed += _assert(sframes.get_frame_count(&"idle_south") == 1, "idle_south frame count")
				failed += _assert(str(kspr.get("animation")) == "idle_south", "idle faces south at boot")
			if live_keeper.has_method("move_to"):
				var kpos: Vector2 = live_keeper.get("global_position") as Vector2
				live_keeper.call("move_to", kpos + Vector2(0, 180), null)
				for _i: int in range(10):
					await physics_frame
				if kspr:
					failed += _assert(str(kspr.get("animation")) == "walk_south", "south move uses walk_south (got %s)" % str(kspr.get("animation")))
		failed += _assert(live.has_method("handle_lmb_ground"), "Main.handle_lmb_ground")
		failed += _assert(live.has_method("handle_rmb_ground"), "Main.handle_rmb_ground")
		if live.has_method("handle_lmb_ground") and live.has_method("handle_rmb_ground"):
			game_state.call("select_keeper")
			failed += _assert(bool(game_state.get("keeper_selected")), "keeper selected before LMB ground")
			live.call("handle_lmb_ground")
			failed += _assert(bool(game_state.get("keeper_selected")) == false, "LMB empty ground deselects keeper")
			game_state.call("select_wisp", 0)
			await process_frame
			var hud: Node = live.get_node_or_null("HUD")
			failed += _assert(hud != null, "HUD present")
			if hud:
				var ch: Node = hud.get_node_or_null("Panel/ControlsHint")
				failed += _assert(ch != null, "HUD ControlsHint")
				if ch:
					var controls_text: String = str(ch.get("text"))
					failed += _assert(controls_text.find("Left-click: select") >= 0, "HUD wires controls_lmb_select")
					failed += _assert(controls_text.find("Right-click: command") >= 0, "HUD wires controls_rmb_command")
					failed += _assert(controls_text.find("deselect") >= 0, "HUD wires controls_lmb_deselect")
					failed += _assert(controls_text.find("pan camera") >= 0, "HUD wires controls_camera_pan")
				var sh: Node = hud.get_node_or_null("Panel/SelectionHint")
				failed += _assert(sh != null, "HUD SelectionHint")
				if sh:
					failed += _assert(str(sh.get("text")).find("Assigned Wisps orbit") >= 0, "HUD wires wisp_orbit_hint")
					failed += _assert(str(sh.get("text")).find("share") >= 0, "HUD wires wisp_node_shared_hint")
			var harvest_tree: Node = live.get_node_or_null("World/HarvestTree")
			failed += _assert(harvest_tree != null and harvest_tree.has_method("apply_player_command"), "HarvestTree command")
			if harvest_tree:
				var ht_label: Node = harvest_tree.get_node_or_null("Label")
				if ht_label:
					failed += _assert(str(ht_label.get("text")).find("Gather Wood") >= 0, "harvest prompt wisp_assign_to_tree")
			var mana: Node = live.get_node_or_null("World/Manatree")
			if mana:
				var mt_label: Node = mana.get_node_or_null("Label")
				if mt_label:
					failed += _assert(str(mt_label.get("text")).find("Gather Manashards") >= 0, "manatree prompt wisp_assign_to_manatree")
			if harvest_tree and harvest_tree.has_method("apply_player_command"):
				harvest_tree.call("apply_player_command")
			failed += _assert(str(game_state.call("get_wisp_assignment", 0)) == "harvest_tree", "RMB harvest assigns wisp")
			game_state.call("select_wisp", 1)
			failed += _assert(mana != null and mana.has_method("apply_player_command"), "Manatree command")
			if mana and mana.has_method("apply_player_command"):
				mana.call("apply_player_command")
			failed += _assert(str(game_state.call("get_wisp_assignment", 1)) == "manatree", "RMB Manatree assigns wisp")
			# Second wisp onto occupied Manatree → stack (join)
			game_state.call("unassign_wisp", 0)
			game_state.call("select_wisp", 0)
			if mana and mana.has_method("apply_player_command"):
				mana.call("apply_player_command")
			failed += _assert(str(game_state.call("get_wisp_assignment", 0)) == "manatree", "second wisp stacks on manatree")
			failed += _assert(str(game_state.call("get_wisp_assignment", 1)) == "manatree", "first keeps manatree")
			failed += _assert(int(game_state.call("count_wisps_on_node", "manatree")) == 2, "live two on manatree")
			await process_frame
			var wisp_orbs: Array[Node] = live.get_tree().get_nodes_in_group("wisp")
			failed += _assert(wisp_orbs.size() == 2, "two wisp orbs spawned (got %d)" % wisp_orbs.size())
			var found_orbit_assign: bool = false
			var found_parked_anim: bool = false
			var found_fly_or_node: bool = false
			var node_r: float = 0.0
			for wo: Node in wisp_orbs:
				if wo.has_method("is_orbiting_assigned_target") and bool(wo.call("is_orbiting_assigned_target")):
					found_orbit_assign = true
					var spr: Node = wo.get_node_or_null("Sprite")
					var anim_name: String = ""
					if spr:
						anim_name = str(spr.get("animation"))
					if anim_name == "parked":
						found_parked_anim = true
					if anim_name == "fly" or anim_name == "node_orbit":
						found_fly_or_node = true
					if wo.has_method("get_node_orbit_radius"):
						node_r = float(wo.call("get_node_orbit_radius"))
			failed += _assert(found_orbit_assign, "assigned wisp reports orbit-assigned state")
			failed += _assert(not found_parked_anim, "assigned wisp must not use parked anim")
			failed += _assert(found_fly_or_node, "assigned wisp uses fly or node_orbit clip")
			# Two stacked on Manatree → base 28 + 10 per extra = 38
			failed += _assert(abs(node_r - 38.0) < 0.01, "stacked node orbit radius 38 (got %s)" % node_r)
			# RMB ground unassign
			game_state.call("select_wisp", 1)
			live.call("handle_rmb_ground", Vector2(80, 80))
			failed += _assert(str(game_state.call("get_wisp_assignment", 1)) == "", "RMB ground unassigns wisp")
		live.queue_free()
		await process_frame

	# --- Art v0.1.12 care vs shop + Content v0.3.4 / SYSTEMS v0.3.3 ---
	game_state.call("reset_for_new_game")
	var hud_packed: PackedScene = load("res://scenes/hud.tscn") as PackedScene
	failed += _assert(hud_packed != null, "hud.tscn load for fruit flow")
	if hud_packed:
		var test_hud: Node = hud_packed.instantiate()
		tree_root.add_child(test_hud)
		await process_frame
		paused = false
		game_audio.call("play_hub_music")
		test_hud.call("show_care_menu")
		await process_frame
		failed += _assert(bool(test_hud.call("is_care_open")), "pre-ancient care open")
		failed += _assert(not bool(test_hud.call("care_embeds_shop_rows")), "pre-ancient care has no shop rows")
		var pay_pre: Button = test_hud.get_node_or_null("CarePanel/ActionBand/PayButton") as Button
		var harvest_pre_anc: Button = test_hud.get_node_or_null("CarePanel/ActionBand/HarvestFruitButton") as Button
		var water_pre_anc: Button = test_hud.get_node_or_null("CarePanel/ActionBand/WaterButton") as Button
		failed += _assert(pay_pre != null and pay_pre.visible, "pre-ancient Pay shown")
		failed += _assert(water_pre_anc != null and water_pre_anc.visible, "pre-ancient Water shown")
		failed += _assert(harvest_pre_anc != null and not harvest_pre_anc.visible, "pre-ancient no Fruit CTA")
		var care_metrics: Dictionary = test_hud.call("get_care_layout_metrics")
		var care_sz_v: Variant = care_metrics.get("size", Vector2.ZERO)
		failed += _assert(care_sz_v is Vector2, "care size is Vector2")
		var care_sz: Vector2 = care_sz_v as Vector2
		failed += _assert(abs(care_sz.x - 520.0) < 1.5 and abs(care_sz.y - 420.0) < 1.5, "care 520x420 (got %s)" % care_sz)
		failed += _assert(abs(float(care_metrics.get("header_h", 0)) - 64.0) < 1.5, "care header 64")
		failed += _assert(abs(float(care_metrics.get("action_band_h", 0)) - 56.0) < 1.5, "care action band 56")
		test_hud.call("hide_care_menu")
		game_state.call("_set_stage", &"ancient")
		failed += _assert(bool(game_state.get("fruit_ready")), "hud test fruit ready")
		failed += _assert(not bool(game_state.get("fruit_harvested_pending_ascend")), "hud test not pending yet")
		failed += _assert(not bool(game_state.get("fruit_committed")), "hud test not committed yet")
		test_hud.call("show_care_menu")
		await process_frame
		failed += _assert(not bool(test_hud.call("is_ascension_shop_open")), "pre-commit shop hidden")
		failed += _assert(not bool(test_hud.call("is_shop_list_visible")), "pre-commit no shop list")
		failed += _assert(not bool(test_hud.call("care_embeds_shop_rows")), "ancient care has no shop rows")
		var harvest_cta: Button = test_hud.get_node_or_null("CarePanel/ActionBand/HarvestFruitButton") as Button
		failed += _assert(harvest_cta != null and harvest_cta.visible, "pre-commit fruit CTA")
		var water_cta: Button = test_hud.get_node_or_null("CarePanel/ActionBand/WaterButton") as Button
		failed += _assert(water_cta != null and water_cta.visible, "pre-commit water still shown")
		var pay_anc: Button = test_hud.get_node_or_null("CarePanel/ActionBand/PayButton") as Button
		failed += _assert(pay_anc != null and not pay_anc.visible, "ancient hides Pay")
		if water_cta and harvest_cta:
			failed += _assert(water_cta.position.x < harvest_cta.position.x, "action band Water left of Fruit")
		var pre_hint: Label = test_hud.get_node_or_null("CarePanel/FruitReadyCard/PrecommitHint") as Label
		failed += _assert(pre_hint != null and str(pre_hint.text).find("Keep watering") >= 0, "care hint tree_ancient_care_hint")
		failed += _assert(pre_hint != null and str(pre_hint.text).find("still water") >= 0, "care hint tree_water_ancient_note")
		var ascend_pre: Button = test_hud.get_node_or_null("AscensionPanel/Footer/AscendButton") as Button
		failed += _assert(ascend_pre != null and not ascend_pre.is_visible_in_tree(), "Ascend hidden pre-commit")
		var e_pre_ui: int = int(game_state.get("essence"))
		var w_pre_ui: Dictionary = game_state.call("apply_water_pulse")
		failed += _assert(bool(w_pre_ui.get("ok", false)), "water pays until commit")
		failed += _assert(int(game_state.get("essence")) > e_pre_ui, "water essence until commit")
		game_state.call("set_resource", &"manashards", 1500)
		game_audio.call("clear_played_log")
		test_hud.call("open_fruit_confirm")
		await process_frame
		failed += _assert(int(test_hud.call("get_fruit_confirm_step")) == 1, "fruit modal step 1")
		failed += _assert(not bool(game_state.get("fruit_committed")), "step 1 does not commit")
		failed += _assert(paused == false, "world running during fruit step 1")
		failed += _assert(not bool(test_hud.call("is_ascension_shop_open")), "shop closed during fruit modal")
		failed += _assert(not bool(test_hud.call("is_care_open")), "care closed during fruit confirm")
		failed += _assert(bool(game_audio.call("did_play", &"sfx_ui_confirm")), "fruit intent plays sfx_ui_confirm")
		failed += _assert(not bool(game_audio.call("did_play", &"sfx_fruit_harvest")), "intent does not harvest")
		var harvest_modal: Button = test_hud.get_node_or_null("FruitConfirmPanel/ConfirmYes") as Button
		var cancel_modal: Button = test_hud.get_node_or_null("FruitConfirmPanel/ConfirmNo") as Button
		failed += _assert(harvest_modal != null and str(harvest_modal.text) == "Continue", "step 1 Continue")
		failed += _assert(cancel_modal != null and str(cancel_modal.text).find("watering") >= 0, "step 1 Keep watering")
		failed += _assert(test_hud.get_node_or_null("FruitConfirmPanel/UpgradeList") == null, "no Buy list on fruit modal")
		test_hud.call("confirm_fruit_step")
		await process_frame
		failed += _assert(int(test_hud.call("get_fruit_confirm_step")) == 2, "fruit modal step 2")
		failed += _assert(not bool(game_state.get("fruit_committed")), "step 2 prompt does not commit")
		failed += _assert(paused == false, "world running during fruit step 2")
		failed += _assert(not bool(test_hud.call("is_ascension_shop_open")), "shop still closed at step 2")
		failed += _assert(harvest_modal != null and str(harvest_modal.text) == "Harvest", "step 2 Harvest")
		failed += _assert(cancel_modal != null and str(cancel_modal.text) == "Not yet", "step 2 Not yet")
		test_hud.call("cancel_fruit_confirm")
		await process_frame
		failed += _assert(int(test_hud.call("get_fruit_confirm_step")) == 1, "Not yet returns to step 1")
		failed += _assert(not bool(game_state.get("fruit_committed")), "Not yet does not commit")
		test_hud.call("confirm_fruit_step")
		await process_frame
		failed += _assert(int(test_hud.call("get_fruit_confirm_step")) == 2, "Continue again reaches step 2")
		test_hud.call("confirm_fruit_step")
		await process_frame
		await process_frame
		failed += _assert(bool(game_state.get("fruit_harvested_pending_ascend")), "Harvest confirm commits fruit")
		failed += _assert(bool(game_state.get("fruit_committed")), "Harvest confirm sets fruit_committed")
		failed += _assert(paused == true, "commit pauses world")
		failed += _assert(bool(game_audio.call("did_play", &"sfx_fruit_harvest")), "commit plays sfx_fruit_harvest")
		failed += _assert(bool(game_audio.call("did_play", &"mus_fruit_sting")), "commit plays mus_fruit_sting")
		failed += _assert(bool(game_audio.call("is_hub_music_playing")), "hub BGM stays on at Fruit commit pause")
		failed += _assert(bool(game_audio.call("is_hub_stream_playing")), "hub player.playing during paused shop")
		failed += _assert(bool(test_hud.call("is_ascension_shop_open")), "shop opens on commit")
		failed += _assert(not bool(test_hud.call("is_care_open")), "care closed after Fruit commit")
		failed += _assert(not bool(test_hud.call("care_embeds_shop_rows")), "care still has no shop rows after commit")
		failed += _assert(bool(test_hud.call("is_shop_list_visible")), "shop list after commit")
		var shop_banner: Label = test_hud.get_node_or_null("AscensionPanel/Header/Subtitle") as Label
		failed += _assert(shop_banner != null and str(shop_banner.text).find("blessing shop only") >= 0, "shop uses fruit_shop_only_banner")
		var reopen_copy: Button = test_hud.get_node_or_null("Panel/AscensionReopenButton") as Button
		failed += _assert(reopen_copy != null, "reopen control exists")
		var scroll: ScrollContainer = test_hud.get_node_or_null("AscensionPanel/ShopScroll") as ScrollContainer
		failed += _assert(scroll != null, "ShopScroll present")
		if scroll:
			failed += _assert(
				scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_SHOW_ALWAYS,
				"shop scrollbar SHOW_ALWAYS (got %d)" % int(scroll.vertical_scroll_mode)
			)
			failed += _assert(scroll.clip_contents, "shop list clips")
			failed += _assert(scroll.get_node_or_null("UpgradeList") != null, "list inside scroll")
		failed += _assert(bool(test_hud.call("shop_list_clears_footer")), "buy rows sit above footer")
		var metrics: Dictionary = test_hud.call("get_shop_layout_metrics")
		var shop_sz_v: Variant = metrics.get("size", Vector2.ZERO)
		failed += _assert(shop_sz_v is Vector2, "shop size is Vector2")
		var shop_sz: Vector2 = shop_sz_v as Vector2
		failed += _assert(abs(shop_sz.x - 720.0) < 1.5 and abs(shop_sz.y - 500.0) < 1.5, "shop 720x500 (got %s)" % shop_sz)
		failed += _assert(abs(float(metrics.get("header_h", 0)) - 64.0) < 1.5, "header 64")
		failed += _assert(abs(float(metrics.get("footer_h", 0)) - 72.0) < 1.5, "footer 72")
		failed += _assert(shop_sz.x + 0.1 >= 640.0 and shop_sz.y + 0.1 >= 420.0, "shop meets min 640x420")
		var close_post: Button = test_hud.get_node_or_null("AscensionPanel/Footer/CloseButton") as Button
		var ascend_post: Button = test_hud.get_node_or_null("AscensionPanel/Footer/AscendButton") as Button
		failed += _assert(close_post != null and ascend_post != null, "footer Close+Ascend")
		if close_post and ascend_post:
			failed += _assert(close_post.position.x < ascend_post.position.x, "Close left, Ascend right")
			failed += _assert(ascend_post.visible and not ascend_post.disabled, "Ascend only post-commit")
		failed += _assert(not bool(test_hud.call("shop_has_harvest_button")), "Harvest never on shop")
		var list_node: VBoxContainer = test_hud.get_node_or_null("AscensionPanel/ShopScroll/UpgradeList") as VBoxContainer
		if list_node and list_node.get_child_count() > 0:
			var row0: Control = list_node.get_child(0) as Control
			failed += _assert(row0 != null and abs(row0.custom_minimum_size.y - 48.0) < 0.1, "row height 48")
			var described: int = 0
			for child: Node in list_node.get_children():
				if child is Control and str((child as Control).tooltip_text) != "":
					described += 1
			failed += _assert(described == list_node.get_child_count(), "each blessing row has tooltip desc (%d/%d)" % [described, list_node.get_child_count()])
			failed += _assert(str(row0.tooltip_text).length() > 8, "blessing tooltip is a short description")
		var w_post_ui: Dictionary = game_state.call("apply_water_pulse")
		failed += _assert(not bool(w_post_ui.get("ok", true)), "water blocked after UI commit")
		failed += _assert(bool(game_audio.call("is_hub_music_playing")), "hub BGM stays on during ascension pause")
		failed += _assert(bool(game_audio.call("is_hub_stream_playing")), "hub stream still playing while shop paused")
		game_audio.call("clear_played_log")
		test_hud.call("_on_buy", "forager")
		await process_frame
		failed += _assert(bool(game_audio.call("did_play", &"sfx_upgrade_buy")), "bless buy plays sfx_upgrade_buy")
		failed += _assert(bool(game_audio.call("is_hub_music_playing")), "hub BGM stays on after bless buy")
		game_audio.call("clear_played_log")
		game_audio.call("play_ascend")
		failed += _assert(bool(game_audio.call("did_play", &"sfx_ascend")), "ascend plays sfx_ascend")
		failed += _assert(bool(game_audio.call("did_play", &"mus_ascend_sting")), "ascend plays mus_ascend_sting")
		failed += _assert(bool(game_audio.call("is_hub_music_playing")), "hub BGM stays on under ascend sting while paused")
		test_hud.call("hide_ascension_shop")
		await process_frame
		failed += _assert(paused == true, "close shop keeps world paused")
		failed += _assert(not bool(test_hud.call("is_ascension_shop_open")), "close hides shop")
		failed += _assert(bool(game_audio.call("is_hub_music_playing")), "hub BGM stays on after shop Close")
		var reopen: Button = test_hud.get_node_or_null("Panel/AscensionReopenButton") as Button
		failed += _assert(reopen != null and reopen.visible, "reopen chip after close")
		test_hud.call("show_care_menu")
		await process_frame
		failed += _assert(paused == true, "care reopen after commit stays paused")
		failed += _assert(bool(test_hud.call("is_ascension_shop_open")), "post-commit care opens shop, not care")
		failed += _assert(not bool(test_hud.call("is_care_open")), "care stays closed until next cycle")
		test_hud.call("show_ascension_shop")
		await process_frame
		failed += _assert(paused == true, "reopen stays paused")
		failed += _assert(bool(test_hud.call("is_ascension_shop_open")), "shop reopens")
		test_hud.queue_free()
		paused = false
		await process_frame
		game_state.call("reset_for_new_game")

	# --- SYSTEMS v0.4.0: backpack, handcraft, tools, Grow, Keep Tools, can shard_roll ×2 ---
	failed += _assert(int((backpack.get("recipes_data") as Array).size()) == 11, "11 handcraft recipes (weapon rod added)")
	failed += _assert(int((backpack.get("items_data") as Array).size()) == 11, "11 backpack items (weapon rod added)")
	failed += _assert(not bool(backpack.call("recipe_has_manashards", "fertilizer")), "fertilizer recipe no manashards")
	var fert_def: Dictionary = backpack.call("get_recipe_def", "fertilizer")
	var fert_ings: Dictionary = fert_def.get("ingredients", {}) as Dictionary
	failed += _assert(int(fert_ings.get("wood", 0)) == 10 and int(fert_ings.get("stone", 0)) == 10 and int(fert_ings.get("food", 0)) == 10, "fertilizer wood+stone+food 10/10/10")
	failed += _assert(int(fert_ings.get("manashards", 0)) == 0, "fertilizer manashards 0")
	var fert_live: Dictionary = backpack.call("get_recipe_ingredients", "fertilizer")
	failed += _assert(int(fert_live.get("wood", 0)) == 10, "fertilizer live wood 10 without thumb")
	failed += _assert(str(content_strings.call("get_text", "item_fertilizer")) == "Fertilizer", "item_fertilizer")
	failed += _assert(str(content_strings.call("get_text", "fertilizer_name")) == "Fertilizer", "fertilizer_name")
	failed += _assert(str(content_strings.call("get_text", "fertilizer_hint")).find("Wood") >= 0, "fertilizer_hint")
	failed += _assert(str(content_strings.call("get_text", "fertilizer_craft_ok")).find("Fertilizer") >= 0, "fertilizer_craft_ok")
	failed += _assert(str(content_strings.call("get_text", "btn_backpack")) == "Backpack", "btn_backpack")
	failed += _assert(str(content_strings.call("get_text", "backpack_open")) == "Backpack", "backpack_open")
	failed += _assert(str(content_strings.call("get_text", "backpack_empty")) == "Nothing crafted yet.", "backpack_empty")
	failed += _assert(str(content_strings.call("get_text", "backpack_hint")).find("Fertilizer") >= 0, "backpack_hint")
	failed += _assert(str(content_strings.call("get_text", "backpack_tab_all")) == "All", "backpack_tab_all")
	failed += _assert(str(content_strings.call("get_text", "backpack_tab_tools")) == "Tools", "backpack_tab_tools")
	failed += _assert(str(content_strings.call("get_text", "backpack_tab_materials")) == "Parts", "backpack_tab_materials")
	failed += _assert(str(content_strings.call("get_text", "backpack_craft")) == "Craft", "backpack_craft")
	failed += _assert(str(content_strings.call("get_text", "handcraft_title")) == "Handcraft", "handcraft_title")
	failed += _assert(str(content_strings.call("get_text", "handcraft_prompt")) == "Craft", "handcraft_prompt")
	failed += _assert(str(content_strings.call("get_text", "handcraft_ok")).find("{item}") >= 0, "handcraft_ok")
	failed += _assert(str(content_strings.call("get_text", "handcraft_cant_afford")).find("{costs}") >= 0, "handcraft_cant_afford")
	failed += _assert(str(content_strings.call("get_text", "handcraft_owned_unique")).find("already") >= 0, "handcraft_owned_unique")
	failed += _assert(str(content_strings.call("get_text", "part_wood_plank")) == "Wood Plank", "part_wood_plank")
	failed += _assert(str(content_strings.call("get_text", "part_stone_fragment")) == "Stone Fragment", "part_stone_fragment")
	failed += _assert(str(content_strings.call("get_text", "part_wood_rod")) == "Wood Rod", "part_wood_rod")
	failed += _assert(str(content_strings.call("get_text", "part_stone_head")) == "Stone Head", "part_stone_head")
	failed += _assert(str(content_strings.call("get_text", "part_stone_axe_head")) == "Stone Axe Head", "part_stone_axe_head")
	failed += _assert(str(content_strings.call("get_text", "part_stone_pickaxe_head")) == "Stone Pickaxe Head", "part_stone_pickaxe_head")
	failed += _assert(str(content_strings.call("get_text", "part_stone_axe_head_examine")).find("Axe") >= 0, "part_stone_axe_head_examine")
	failed += _assert(str(content_strings.call("get_text", "part_stone_pickaxe_head_examine")).find("Pickaxe") >= 0, "part_stone_pickaxe_head_examine")
	failed += _assert(str(content_strings.call("get_text", "item_axe_head")) == "Stone Axe Head", "item_axe_head")
	failed += _assert(str(content_strings.call("get_text", "item_pickaxe_head")) == "Stone Pickaxe Head", "item_pickaxe_head")
	failed += _assert(str(backpack.call("item_display_name", "axe_head")) == "Stone Axe Head", "display Stone Axe Head")
	failed += _assert(str(backpack.call("item_display_name", "pickaxe_head")) == "Stone Pickaxe Head", "display Stone Pickaxe Head")
	failed += _assert(str(content_strings.call("get_text", "upgrade_deep_roots_desc")).find("Essence") >= 0, "deep_roots desc")
	failed += _assert(str(content_strings.call("get_text", "upgrade_forager_desc")).find("Harvest") >= 0, "forager desc")
	failed += _assert(str(content_strings.call("get_text", "upgrade_shard_sight_desc")).find("Manashards") >= 0, "shard_sight desc")
	failed += _assert(str(content_strings.call("get_text", "upgrade_keeper_stride_desc")).find("faster") >= 0, "keeper_stride desc")
	failed += _assert(str(content_strings.call("get_text", "controls_camera_pan")).find("pan") >= 0, "controls_camera_pan")
	failed += _assert(str(content_strings.call("get_text", "handcraft_row_watering_can_short")).find("20") >= 0, "handcraft_row_watering_can_short")
	failed += _assert(str(content_strings.call("get_text", "handcraft_row_wooden_basket_short")).find("20") >= 0, "handcraft_row_wooden_basket_short")
	failed += _assert(str(content_strings.call("get_text", "handcraft_row_fertilizer_short")).find("{wood}") >= 0, "handcraft_row_fertilizer_short")
	failed += _assert(str(content_strings.call("get_text", "fertilizer_craft_cost_default")).find("10") >= 0, "fertilizer_craft_cost_default ×10")
	failed += _assert(str(content_strings.call("get_text", "upgrade_keep_tools_cost_default")).find("3000") >= 0, "keep_tools cost default 3000")
	failed += _assert(str(content_strings.call("get_text", "tool_stone_watering_can_craft_cost")).find("20") >= 0, "tool_stone_watering_can_craft_cost")
	failed += _assert(str(content_strings.call("get_text", "tool_wooden_basket_craft_cost")).find("20") >= 0, "tool_wooden_basket_craft_cost")
	failed += _assert(str(content_strings.call("get_text", "upgrade_keep_tools_cost")).find("{cost}") >= 0, "upgrade_keep_tools_cost token")
	failed += _assert(str(content_strings.call("get_text", "backpack_wiped_toast")).find("forest") >= 0, "backpack_wiped_toast")
	failed += _assert(str(content_strings.call("get_text", "backpack_wiped_keep_tools_toast")).find("tools") >= 0, "backpack_wiped_keep_tools_toast")
	failed += _assert(str(content_strings.call("get_text", "upgrade_green_thumb_desc")).find("Fertilizer") >= 0, "green_thumb desc retarget")
	failed += _assert(str(content_strings.call("get_text", "upgrade_green_thumb_desc")).find("Needs") < 0, "green_thumb drops soft-mat Needs")
	failed += _assert(str(thumb.get("description", "")).find("Fertilizer") >= 0, "green_thumb json desc retarget")
	failed += _assert(str(content_strings.call("get_text", "upgrade_keep_tools_tooltip")).find("survive") >= 0, "upgrade_keep_tools_tooltip")
	failed += _assert(str(content_strings.call("get_text", "upgrade_green_thumb_tooltip")).find("Fertilizer") >= 0, "green_thumb tooltip retarget")
	failed += _assert(str(content_strings.call("get_text", "upgrade_deep_roots_tooltip")).find("Essence") >= 0, "upgrade_deep_roots_tooltip")
	failed += _assert(str(content_strings.call("get_text", "upgrade_forager_tooltip")).find("Harvest") >= 0, "upgrade_forager_tooltip")
	failed += _assert(str(content_strings.call("get_text", "upgrade_shard_sight_tooltip")).find("Manashards") >= 0, "upgrade_shard_sight_tooltip")
	failed += _assert(str(content_strings.call("get_text", "upgrade_keeper_stride_tooltip")).find("faster") >= 0, "upgrade_keeper_stride_tooltip")
	failed += _assert(str(content_strings.call("get_text", "upgrade_wisp_haste_tooltip")).find("Wisps") >= 0, "upgrade_wisp_haste_tooltip")
	failed += _assert(str(content_strings.call("get_text", "upgrade_bonus_wisp_tooltip")).find("Wisp") >= 0, "upgrade_bonus_wisp_tooltip")
	failed += _assert(str(content_strings.call("get_text", "welcome_hint")).find("Arrow") >= 0, "welcome_hint camera pan")
	failed += _assert(str(content_strings.call("get_text", "tree_grow_cost_young")).find("×3") >= 0, "tree_grow_cost_young fert 3")
	failed += _assert(str(content_strings.call("get_text", "tree_grow_cost_ancient")).find("×24") >= 0, "tree_grow_cost_ancient fert 24")
	failed += _assert(str(content_strings.call("get_text", "part_woven_fiber")) == "Woven Fiber", "part_woven_fiber")
	failed += _assert(str(content_strings.call("get_text", "tool_stone_axe")) == "Stone Axe", "tool_stone_axe")
	failed += _assert(str(content_strings.call("get_text", "tool_stone_pickaxe")) == "Stone Pickaxe", "tool_stone_pickaxe")
	failed += _assert(str(content_strings.call("get_text", "tool_wooden_basket")) == "Wooden Basket", "tool_wooden_basket")
	failed += _assert(str(content_strings.call("get_text", "tool_stone_watering_can")) == "Stone Watering Can", "tool_stone_watering_can")
	failed += _assert(str(content_strings.call("get_text", "tool_wood_hint")).find("Stone Axe") >= 0, "tool_wood_hint")
	failed += _assert(str(content_strings.call("get_text", "tool_stone_hint")).find("Stone Pickaxe") >= 0, "tool_stone_hint")
	failed += _assert(str(content_strings.call("get_text", "tool_food_hint")).find("Wooden Basket") >= 0, "tool_food_hint")
	failed += _assert(str(content_strings.call("get_text", "tool_water_hint")).find("Manashards") >= 0, "tool_water_hint")
	failed += _assert(str(content_strings.call("get_text", "tool_water_hint")).find("Essence") >= 0, "tool_water_hint essence unchanged")
	failed += _assert(str(content_strings.call("get_text", "tool_water_hint")).find("twice") >= 0, "tool_water_hint amount not speed")
	failed += _assert(str(content_strings.call("get_text", "tree_grow_cost_fertilizer")).find("Fertilizer") >= 0, "tree_grow_cost_fertilizer")
	failed += _assert(str(content_strings.call("get_text", "tree_grow_cost_essence")).find("Essence") >= 0, "tree_grow_cost_essence")
	failed += _assert(str(content_strings.call("get_text", "fertilizer_craft_cost_wood")).find("{have}") >= 0, "fertilizer_craft_cost_wood")
	failed += _assert(str(content_strings.call("get_text", "fertilizer_craft_cost_stone")).find("{need}") >= 0, "fertilizer_craft_cost_stone")
	failed += _assert(str(content_strings.call("get_text", "fertilizer_craft_cost_food")).find("Food") >= 0, "fertilizer_craft_cost_food")
	failed += _assert(str(content_strings.call("get_text", "fertilizer_craft_cost_line")).find("{item}") >= 0, "fertilizer_craft_cost_line")
	failed += _assert(str(content_strings.call("get_text", "ascend_backpack_wipe_toast")).find("Keep Tools") >= 0, "ascend_backpack_wipe_toast")
	failed += _assert(str(content_strings.call("get_text", "welcome_body")).find("Grow") >= 0, "welcome Grow not Pay")
	failed += _assert(str(content_strings.call("get_text", "welcome_body")).find("Pay its Needs") < 0, "welcome drops needs-only Pay")
	failed += _assert(str(content_strings.call("get_text", "tool_never_gate")).find("hands") >= 0, "tool_never_gate")
	failed += _assert(str(content_strings.call("get_text", "tool_wiped_on_ascend")).find("Keep Tools") >= 0, "tool_wiped_on_ascend")
	failed += _assert(str(content_strings.call("get_text", "upgrade_keep_tools_name")) == "Keep Tools", "Keep Tools name")
	failed += _assert(str(content_strings.call("get_text", "upgrade_keep_tools_desc")).find("survive") >= 0, "upgrade_keep_tools_desc")
	failed += _assert(str(content_strings.call("get_text", "upgrade_keep_tools_toast")).find("tools") >= 0, "upgrade_keep_tools_toast")
	failed += _assert(str(content_strings.call("get_text", "keep_tools_regrant_toast")).find("backpack") >= 0, "keep_tools_regrant_toast")
	failed += _assert(str(backpack.call("item_display_name", "wooden_planks")) == "Wood Plank", "display plank via part_")
	failed += _assert(str(backpack.call("item_display_name", "stone_axe")) == "Stone Axe", "display axe via tool_")
	failed += _assert(str(backpack.call("item_string_key", "fertilizer")) == "fertilizer_name", "fertilizer string_key")
	var keep_def: Dictionary = game_state.call("get_upgrade_def", "keep_tools")
	failed += _assert(str(keep_def.get("effect", "")) == "keep_tools", "keep_tools effect")
	failed += _assert(int(keep_def.get("max_rank", 0)) == 1, "keep_tools max 1")
	game_state.call("reset_for_new_game")
	game_state.call("_set_stage", &"ancient")
	game_state.call("harvest_fruit")
	failed += _assert(int(game_state.call("get_upgrade_cost", "keep_tools")) == 3000, "Keep Tools ≈3000 shards")
	failed += _assert(not bool(game_state.call("can_buy_upgrade", "keep_tools")), "Keep Tools unaffordable at 0 shards")
	game_state.call("set_resource", &"manashards", 3000)
	failed += _assert(bool(game_state.call("can_buy_upgrade", "keep_tools")), "Keep Tools affordable at 3000")

	game_state.call("reset_for_new_game")
	game_state.call("set_resource", &"wood", 3)
	failed += _assert(str(backpack.call("try_craft", "wooden_planks")) == "ok", "craft planks")
	failed += _assert(int(backpack.call("get_count", "wooden_planks")) == 1, "1 plank")
	failed += _assert(int(game_state.get("wood")) == 0, "wood spent on planks")
	game_state.call("set_resource", &"stone", 3)
	failed += _assert(str(backpack.call("try_craft", "stone_fragments")) == "ok", "craft fragments")
	game_state.call("set_resource", &"wood", 10)
	game_state.call("set_resource", &"stone", 10)
	game_state.call("set_resource", &"food", 10)
	game_state.call("set_resource", &"manashards", 99)
	var shards_pre_fert: int = int(game_state.get("manashards"))
	failed += _assert(str(backpack.call("try_craft", "fertilizer")) == "ok", "craft fertilizer")
	failed += _assert(int(backpack.call("get_count", "fertilizer")) == 1, "fertilizer stacked")
	failed += _assert(int(game_state.get("manashards")) == shards_pre_fert, "fertilizer ignores manashards")

	# Unique tools: own 1
	game_state.call("reset_for_new_game")
	backpack.call("set_count", "wooden_tool_rod", 2)
	backpack.call("set_count", "axe_head", 2)
	failed += _assert(str(backpack.call("try_craft", "stone_axe")) == "ok", "craft stone axe")
	failed += _assert(int(backpack.call("get_count", "stone_axe")) == 1, "axe unique 1")
	failed += _assert(str(backpack.call("try_craft", "stone_axe")) == "unique", "second axe blocked")
	failed += _assert(bool(backpack.call("owns_tool_for_resource", &"wood")), "axe boosts wood")
	failed += _assert(not bool(backpack.call("owns_tool_for_resource", &"stone")), "axe does not boost stone")
	failed += _assert(abs(float(game_state.call("get_keeper_harvest_pulse_sec", &"wood")) - 0.5) < 0.01, "axe halves wood wait")
	failed += _assert(abs(float(game_state.call("get_keeper_harvest_pulse_sec", &"stone")) - 1.0) < 0.01, "no pickaxe: stone wait 1s")
	failed += _assert(abs(float(game_state.call("get_wisp_pulse_sec")) - 10.0) < 0.01, "tools do not change wisp pulse")

	var basket_def: Dictionary = backpack.call("get_recipe_def", "wooden_basket")
	var basket_ings: Dictionary = basket_def.get("ingredients", {}) as Dictionary
	failed += _assert(int(basket_ings.get("wooden_planks", 0)) == 20, "basket 20 planks")
	var can_def: Dictionary = backpack.call("get_recipe_def", "stone_watering_can")
	var can_ings: Dictionary = can_def.get("ingredients", {}) as Dictionary
	failed += _assert(int(can_ings.get("stone_fragments", 0)) == 20, "watering can 20 fragments")
	failed += _assert(int(can_ings.get("wooden_tool_rod", 0)) == 0, "watering can no rod")
	backpack.call("set_count", "stone_fragments", 20)
	failed += _assert(str(backpack.call("try_craft", "stone_watering_can")) == "ok", "craft watering can")
	failed += _assert(bool(backpack.call("owns_watering_can")), "owns watering can")
	failed += _assert(abs(float(game_state.call("get_water_shard_pulse_sec")) - 1.0) < 0.01, "can leaves shard wait")
	failed += _assert(abs(float(game_state.call("get_water_essence_pulse_sec")) - 1.0) < 0.01, "can leaves essence wait")
	failed += _assert(int(game_state.call("get_water_shard_roll_mult")) == 2, "can doubles shard_roll")

	# shard_roll ×2: even U{2,4,6}; Essence still +1
	game_state.call("reset_for_new_game")
	failed += _assert(int(game_state.call("get_water_shard_roll_mult")) == 1, "no can: roll mult 1")
	var bare_pulse: Dictionary = game_state.call("apply_water_pulse")
	var bare_shards: int = int(bare_pulse.get("shards", 0))
	failed += _assert(bare_shards >= 1 and bare_shards <= 3, "bare shard_roll U{1,3}")
	failed += _assert(int(bare_pulse.get("essence", 0)) == 1, "bare essence +1")
	backpack.call("set_count", "stone_watering_can", 1)
	failed += _assert(int(game_state.call("get_water_shard_roll_mult")) == 2, "owned can: roll mult 2")
	var can_ok: int = 0
	var i_can: int = 0
	while i_can < 16:
		var can_pulse: Dictionary = game_state.call("apply_water_pulse")
		var can_shards: int = int(can_pulse.get("shards", 0))
		failed += _assert(can_shards == 2 or can_shards == 4 or can_shards == 6, "can shard_roll*2 in {2,4,6} got %d" % can_shards)
		failed += _assert(int(can_pulse.get("essence", 0)) == 1, "can leaves essence +1")
		can_ok += 1
		i_can += 1
	failed += _assert(can_ok == 16, "16 can pulses checked")
	# Can doubles (roll + shard_sight): U{1,3}+1 → {4,6,8}
	var ranks_ss: Dictionary = game_state.get("upgrade_ranks")
	ranks_ss["shard_sight"] = 1
	game_state.set("upgrade_ranks", ranks_ss)
	var ss_i: int = 0
	while ss_i < 12:
		var ss_pulse: Dictionary = game_state.call("apply_water_pulse")
		var ss_shards: int = int(ss_pulse.get("shards", 0))
		failed += _assert(ss_shards == 4 or ss_shards == 6 or ss_shards == 8, "can*(roll+sight) in {4,6,8} got %d" % ss_shards)
		failed += _assert(int(ss_pulse.get("essence", 0)) == 1, "can+sight essence still +1")
		ss_i += 1

	# Split water pulse flags still isolate grants
	game_state.call("reset_for_new_game")
	var e_split: int = int(game_state.get("essence"))
	var m_split: int = int(game_state.get("manashards"))
	var shard_only: Dictionary = game_state.call("apply_water_pulse", true, false)
	failed += _assert(bool(shard_only.get("ok", false)), "shard-only pulse ok")
	failed += _assert(int(shard_only.get("essence", -1)) == 0, "shard-only essence 0")
	failed += _assert(int(game_state.get("essence")) == e_split, "essence unchanged on shard-only")
	failed += _assert(int(game_state.get("manashards")) > m_split, "shards granted shard-only")
	var ess_only: Dictionary = game_state.call("apply_water_pulse", false, true)
	failed += _assert(int(ess_only.get("shards", -1)) == 0, "essence-only shards 0")
	failed += _assert(int(game_state.get("essence")) == e_split + 1, "essence-only +1")

	# Ascend wipe backpack; Keep Tools regrants finished tools only
	game_state.call("reset_for_new_game")
	game_state.call("_set_stage", &"ancient")
	backpack.call("set_count", "fertilizer", 7)
	backpack.call("set_count", "wooden_planks", 4)
	backpack.call("set_count", "stone_axe", 1)
	backpack.call("set_count", "stone_pickaxe", 1)
	backpack.call("set_count", "wooden_basket", 1)
	backpack.call("set_count", "stone_watering_can", 1)
	game_state.call("harvest_fruit")
	game_state.call("ascend")
	failed += _assert(int(backpack.call("get_count", "fertilizer")) == 0, "ascend wipes fertilizer")
	failed += _assert(int(backpack.call("get_count", "wooden_planks")) == 0, "ascend wipes intermediates")
	failed += _assert(int(backpack.call("get_count", "stone_axe")) == 0, "ascend wipes tools without blessing")

	game_state.call("reset_for_new_game")
	game_state.call("_set_stage", &"ancient")
	var ranks_kt: Dictionary = game_state.get("upgrade_ranks")
	ranks_kt["keep_tools"] = 1
	game_state.set("upgrade_ranks", ranks_kt)
	backpack.call("set_count", "fertilizer", 3)
	backpack.call("set_count", "wooden_planks", 2)
	backpack.call("set_count", "stone_axe", 1)
	backpack.call("set_count", "stone_pickaxe", 1)
	backpack.call("set_count", "wooden_basket", 1)
	backpack.call("set_count", "stone_watering_can", 1)
	game_state.call("harvest_fruit")
	game_state.call("ascend")
	failed += _assert(int(backpack.call("get_count", "stone_axe")) == 1, "Keep Tools regrants axe")
	failed += _assert(int(backpack.call("get_count", "stone_pickaxe")) == 1, "Keep Tools regrants pickaxe")
	failed += _assert(int(backpack.call("get_count", "wooden_basket")) == 1, "Keep Tools regrants basket")
	failed += _assert(int(backpack.call("get_count", "stone_watering_can")) == 1, "Keep Tools regrants can")
	failed += _assert(int(backpack.call("get_count", "fertilizer")) == 0, "Keep Tools does not keep fertilizer")
	failed += _assert(int(backpack.call("get_count", "wooden_planks")) == 0, "Keep Tools does not keep planks")

	# Save backpack + migrate empty from v5
	game_state.call("reset_for_new_game")
	backpack.call("set_count", "fertilizer", 6)
	backpack.call("set_count", "stone_axe", 1)
	game_state.set("welcome_shown", true)
	failed += _assert(bool(save_service.call("save_game", 5)), "save slot 5 backpack")
	game_state.call("reset_for_new_game")
	failed += _assert(int(backpack.call("get_count", "fertilizer")) == 0, "reset clears backpack")
	failed += _assert(bool(save_service.call("load_game", 5)), "load slot 5 backpack")
	failed += _assert(int(backpack.call("get_count", "fertilizer")) == 6, "loaded fertilizer")
	failed += _assert(int(backpack.call("get_count", "stone_axe")) == 1, "loaded axe")
	var v5_state: Dictionary = game_state.call("to_save_dict")
	v5_state.erase("backpack")
	var migrated: Dictionary = save_service.call("_migrate", 5, v5_state)
	failed += _assert(typeof(migrated.get("backpack", null)) == TYPE_DICTIONARY, "v5 migrate empty backpack dict")
	failed += _assert((migrated.get("backpack", {}) as Dictionary).is_empty(), "v5 migrate backpack empty")
	failed += _assert(bool(migrated.get("owns_stone_axe", true)) == false, "v5 migrate axe flag false")
	failed += _assert(bool(migrated.get("owns_stone_watering_can", true)) == false, "v5 migrate can flag false")
	game_state.call("reset_for_new_game")
	game_state.call("apply_save_dict", migrated)
	failed += _assert(int(backpack.call("get_count", "fertilizer")) == 0, "migrated empty backpack")
	var saved_flags: Dictionary = game_state.call("to_save_dict")
	failed += _assert(saved_flags.has("owns_stone_axe"), "save writes owns_stone_axe")
	failed += _assert(saved_flags.has("owns_stone_watering_can"), "save writes owns_stone_watering_can")
	failed += _assert(abs(float(backpack.call("get_fertilizer_craft_cost_mult")) - 1.0) < 0.01, "FERTILIZER_CRAFT_COST_MULT default 1")

	# HUD backpack + Grow chrome
	if hud_packed:
		var pack_hud: Node = hud_packed.instantiate()
		tree_root.add_child(pack_hud)
		await process_frame
		failed += _assert(pack_hud.has_method("open_backpack"), "HUD.open_backpack")
		failed += _assert(pack_hud.has_method("is_backpack_open"), "HUD.is_backpack_open")
		var fert_icon: ColorRect = pack_hud.get_node_or_null("CarePanel/CareGrowCosts/FertilizerIcon") as ColorRect
		var ess_icon: ColorRect = pack_hud.get_node_or_null("CarePanel/CareGrowCosts/EssenceIcon") as ColorRect
		var pack_icon: ColorRect = pack_hud.get_node_or_null("Panel/BackpackButton/BackpackIcon") as ColorRect
		failed += _assert(fert_icon != null and fert_icon.color.a > 0.5, "Grow fertilizer ColorRect")
		failed += _assert(ess_icon != null and ess_icon.color.a > 0.5, "Grow essence ColorRect")
		failed += _assert(pack_icon != null and pack_icon.color.a > 0.5, "Backpack button ColorRect")
		pack_hud.call("open_backpack")
		await process_frame
		failed += _assert(bool(pack_hud.call("is_backpack_open")), "backpack opens")
		var craft_box: VBoxContainer = pack_hud.get_node_or_null("BackpackPanel/CraftScroll/CraftList") as VBoxContainer
		failed += _assert(craft_box != null and craft_box.get_child_count() >= 10, "craft rows built (%d)" % (craft_box.get_child_count() if craft_box else 0))
		var pack_metrics: Dictionary = pack_hud.call("get_backpack_layout_metrics")
		failed += _assert(bool(pack_metrics.get("fits", false)), "craft scroll width ≤ backpack panel")
		failed += _assert(float(pack_metrics.get("panel_w", 0)) >= 630.0, "backpack panel widened")
		if craft_box:
			var fluff: int = 0
			for row: Node in craft_box.get_children():
				var txt: String = ""
				for n: Node in row.get_children():
					if n is VBoxContainer:
						for lbl: Node in n.get_children():
							if lbl is Label:
								txt += " " + str((lbl as Label).text)
				if txt.find("Essence stays") >= 0 or txt.find("Used with Essence") >= 0 or txt.find("Craft from Wood") >= 0:
					fluff += 1
			failed += _assert(fluff == 0, "craft rows are costs only (no watering-can/fertilizer fluff)")
		if pack_hud.has_method("_craft_row_cost_text"):
			failed += _assert(str(pack_hud.call("_craft_row_cost_text", "stone_watering_can")).find("20") >= 0, "HUD can row uses Content short")
			failed += _assert(str(pack_hud.call("_craft_row_cost_text", "stone_watering_can")).find("Rod") < 0, "HUD can row no Rod")
			failed += _assert(str(pack_hud.call("_craft_row_cost_text", "wooden_basket")).find("20") >= 0, "HUD basket row uses Content short")
			failed += _assert(str(pack_hud.call("_craft_row_cost_text", "fertilizer")).find("10") >= 0, "HUD fert row uses Content 10/10/10")
		var grow_btn: Button = pack_hud.get_node_or_null("CarePanel/ActionBand/PayButton") as Button
		failed += _assert(grow_btn != null and str(grow_btn.text) == "Grow", "care CTA Grow")
		failed += _assert(pack_hud.get_node_or_null("BackpackPanel/TabRow/TabAll") != null, "backpack tab All")
		failed += _assert(pack_hud.get_node_or_null("BackpackPanel/TabRow/TabTools") != null, "backpack tab Tools")
		failed += _assert(pack_hud.get_node_or_null("BackpackPanel/TabRow/TabParts") != null, "backpack tab Parts")
		var pack_btn: Button = pack_hud.get_node_or_null("Panel/BackpackButton") as Button
		failed += _assert(pack_btn != null and str(pack_btn.text) == "Backpack", "HUD backpack_open")
		pack_hud.call("close_backpack")
		await process_frame
		failed += _assert(not bool(pack_hud.call("is_backpack_open")), "backpack closes")
		pack_hud.queue_free()
		await process_frame
		game_state.call("reset_for_new_game")

	# --- Character sheet, Runestones, Stone Sword, Manatree visual scale (Haex greenlight) ---
	var keeper_stats: Node = tree_root.get_node_or_null("KeeperStats")
	var equipment: Node = tree_root.get_node_or_null("Equipment")
	failed += _assert(keeper_stats != null, "KeeperStats autoload missing")
	failed += _assert(equipment != null, "Equipment autoload missing")
	if keeper_stats != null and equipment != null:
		game_state.call("reset_for_new_game")
		failed += _assert(int(save_service.get("SAVE_VERSION")) == 6, "SAVE_VERSION stays 6 with stats/gear")
		var stat_order: Array = keeper_stats.get("STAT_ORDER")
		failed += _assert(stat_order.size() == 7, "seven combat stats")
		failed += _assert(str(stat_order[0]) == "might" and str(stat_order[6]) == "fate", "stat order might..fate")
		failed += _assert(int(keeper_stats.call("get_next_cost", "might")) == 50, "first runestone cost 50")
		failed += _assert(int(keeper_stats.call("power_per_rank")) == 1, "stat power +1 per rank")
		failed += _assert(not bool(keeper_stats.call("affects_gather", "fate")), "fate does not affect gather")
		failed += _assert(not bool(keeper_stats.call("affects_wisps", "fate")), "fate does not affect wisps")
		failed += _assert(not bool(keeper_stats.call("affects_craft", "fate")), "fate does not affect craft")
		var grant_before: int = int(game_state.call("get_harvest_grant", &"wood"))
		var pulse_before: float = float(game_state.call("get_wisp_pulse_sec"))
		var fert_before: float = float(backpack.call("get_fertilizer_craft_cost_mult"))
		keeper_stats.call("set_rank", "fate", 12)
		failed += _assert(int(game_state.call("get_harvest_grant", &"wood")) == grant_before, "fate rank leaves gather grant")
		failed += _assert(abs(float(game_state.call("get_wisp_pulse_sec")) - pulse_before) < 0.01, "fate rank leaves wisp pulse")
		failed += _assert(abs(float(backpack.call("get_fertilizer_craft_cost_mult")) - fert_before) < 0.01, "fate rank leaves craft mult")
		keeper_stats.call("set_rank", "fate", 0)
		game_state.call("set_resource", &"manashards", 49)
		failed += _assert(str(keeper_stats.call("try_buy", "might")) == "cant_afford", "runestone denies 49")
		failed += _assert(int(keeper_stats.call("get_rank", "might")) == 0, "rank unchanged when short")
		game_state.call("set_resource", &"manashards", 50)
		failed += _assert(str(keeper_stats.call("try_buy", "might")) == "ok", "runestone buys might")
		failed += _assert(int(keeper_stats.call("get_rank", "might")) == 1, "might rank 1")
		failed += _assert(int(keeper_stats.call("get_base", "might")) == 1, "might base is flat +1")
		failed += _assert(int(game_state.get("manashards")) == 0, "50 shards spent")
		failed += _assert(int(keeper_stats.call("get_next_cost", "might")) == 100, "second point costs 100")
		failed += _assert(int(keeper_stats.call("get_next_cost", "arcana")) == 50, "other stats stay at first cost")
		var slot_order: Array = equipment.get("SLOT_ORDER")
		failed += _assert(slot_order.size() == 10, "ten equipment slots")
		failed += _assert(bool(equipment.call("is_slot_unlocked", "weapon")), "weapon slot unlocked")
		failed += _assert(not bool(equipment.call("is_slot_unlocked", "relic")), "relic stays locked")
		var locked_slots: int = 0
		for slot_name: Variant in slot_order:
			if not bool(equipment.call("is_slot_unlocked", str(slot_name))):
				locked_slots += 1
		failed += _assert(locked_slots == 9, "nine slots locked at start")
		failed += _assert(str(equipment.call("slot_lock_short", "relic")) == "Forge Key", "relic lock hint")
		var rod_ings: Dictionary = backpack.call("get_recipe_ingredients", "weapon_rod")
		failed += _assert(int(rod_ings.get("wooden_planks", 0)) == 10, "weapon rod is 10 planks")
		failed += _assert(str(backpack.call("item_display_name", "weapon_rod")) == "Weapon Rod", "weapon rod name")
		var sword_ings: Dictionary = equipment.call("get_recipe_ingredients", "stone_sword")
		failed += _assert(int(sword_ings.get("stone_fragments", 0)) == 30, "stone sword 30 fragments")
		failed += _assert(int(sword_ings.get("weapon_rod", 0)) == 1, "stone sword 1 weapon rod")
		failed += _assert(not backpack.call("is_known_item", "stone_sword"), "sword is not a backpack item")
		game_state.call("set_resource", &"wood", 30)
		for _i: int in range(10):
			backpack.call("try_craft", "wooden_planks")
		failed += _assert(int(backpack.call("get_count", "wooden_planks")) == 10, "10 planks for the rod")
		failed += _assert(str(backpack.call("try_craft", "weapon_rod")) == "ok", "craft weapon rod")
		failed += _assert(int(backpack.call("get_count", "weapon_rod")) == 1, "rod in backpack")
		failed += _assert(int(backpack.call("get_count", "wooden_planks")) == 0, "planks spent")
		backpack.call("set_count", "stone_fragments", 30)
		failed += _assert(str(equipment.call("try_craft", "stone_sword")) == "ok", "craft stone sword")
		failed += _assert(int(backpack.call("get_count", "weapon_rod")) == 0, "rod spent into the sword")
		failed += _assert(int(backpack.call("get_count", "stone_fragments")) == 0, "fragments spent")
		failed += _assert(bool(equipment.call("owns_anywhere", "stone_sword")), "sword owned as gear")
		failed += _assert(int(backpack.call("get_count", "stone_sword")) == 0, "sword not in backpack stacks")
		var stacked: Array = backpack.call("stacked_items")
		var sword_in_pack: bool = false
		for stack_v: Variant in stacked:
			if typeof(stack_v) == TYPE_DICTIONARY and str((stack_v as Dictionary).get("id", "")) == "stone_sword":
				sword_in_pack = true
		failed += _assert(not sword_in_pack, "backpack list hides the sword")
		failed += _assert(str(equipment.call("try_equip", "stone_sword")) == "ok", "click-equip sword")
		failed += _assert(str(equipment.call("equipped_id", "weapon")) == "stone_sword", "sword in weapon slot")
		failed += _assert(int(equipment.call("unequipped_count", "stone_sword")) == 0, "equipped sword leaves the bag")
		failed += _assert(int(equipment.call("gear_bonus", "might")) == 2, "sword +2 might")
		failed += _assert(int(equipment.call("total_for", "might")) == 3, "base 1 + gear 2 = 3")
		failed += _assert(int(equipment.call("preview_gear_bonus", "might", "stone_sword")) == 2, "preview keeps sword might")
		failed += _assert(str(equipment.call("try_equip_to_slot", "stone_sword", "head")) == "wrong_slot", "sword does not fit the head slot")
		failed += _assert(str(equipment.call("try_craft", "stone_sword")) == "unique", "second sword blocked")
		failed += _assert(str(equipment.call("try_unequip", "weapon")) == "ok", "unequip sword")
		failed += _assert(str(equipment.call("try_equip_to_slot", "stone_sword", "relic")) == "wrong_slot", "sword refuses relic")
		failed += _assert(str(equipment.call("try_equip_to_slot", "stone_sword", "head")) == "wrong_slot", "sword refuses the head slot")
		failed += _assert(str(equipment.call("equipped_id", "weapon")) == "", "weapon empty after refusals")
		failed += _assert(str(equipment.call("try_equip_to_slot", "stone_sword", "weapon")) == "ok", "drag-equip onto weapon")
		backpack.call("set_count", "weapon_rod", 1)
		game_state.set("fruit_committed", true)
		game_state.set("fruit_harvested_pending_ascend", true)
		game_state.call("set_resource", &"manashards", 80)
		game_state.call("ascend")
		failed += _assert(int(game_state.get("manashards")) == 0, "ascend still wipes manashards")
		failed += _assert(int(keeper_stats.call("get_rank", "might")) == 1, "might persists through ascend")
		failed += _assert(int(keeper_stats.call("get_rank", "fate")) == 0, "fate reset only on new game")
		failed += _assert(str(equipment.call("equipped_id", "weapon")) == "stone_sword", "sword persists through ascend")
		failed += _assert(int(backpack.call("get_count", "weapon_rod")) == 0, "rod does not survive ascend")
		var save_payload: Dictionary = game_state.call("to_save_dict")
		failed += _assert(typeof(save_payload.get("keeper_stats", null)) == TYPE_DICTIONARY, "save writes keeper_stats")
		failed += _assert(int((save_payload.get("keeper_stats", {}) as Dictionary).get("might", 0)) == 1, "save keeps might")
		failed += _assert(typeof(save_payload.get("equipment", null)) == TYPE_DICTIONARY, "save writes equipment")
		failed += _assert(bool(save_service.call("save_game", 6)), "save slot 6 stats")
		game_state.call("reset_for_new_game")
		failed += _assert(int(keeper_stats.call("get_rank", "might")) == 0, "new game clears ranks")
		failed += _assert(str(equipment.call("equipped_id", "weapon")) == "", "new game clears gear")
		failed += _assert(bool(save_service.call("load_game", 6)), "load slot 6 stats")
		failed += _assert(int(keeper_stats.call("get_rank", "might")) == 1, "loaded might rank")
		failed += _assert(str(equipment.call("equipped_id", "weapon")) == "stone_sword", "loaded sword")
		var legacy: Dictionary = save_payload.duplicate(true)
		legacy.erase("keeper_stats")
		legacy.erase("equipment")
		game_state.call("apply_save_dict", legacy)
		failed += _assert(int(keeper_stats.call("get_rank", "might")) == 0, "legacy save without stats starts at 0")
		failed += _assert(str(equipment.call("equipped_id", "weapon")) == "", "legacy save without gear starts empty")
		game_state.call("reset_for_new_game")
		var scale_scene: PackedScene = load("res://scenes/manatree.tscn") as PackedScene
		var scale_tree: Node = scale_scene.instantiate()
		tree_root.add_child(scale_tree)
		await process_frame
		failed += _assert(abs(float(scale_tree.call("visual_scale_for", &"sapling")) - 0.5) < 0.01, "sapling visual 0.5")
		failed += _assert(abs(float(scale_tree.call("visual_scale_for", &"young")) - 1.0) < 0.01, "young visual 1")
		failed += _assert(abs(float(scale_tree.call("visual_scale_for", &"mature")) - 2.0) < 0.01, "mature visual 2")
		failed += _assert(abs(float(scale_tree.call("visual_scale_for", &"elder")) - 2.0) < 0.01, "elder visual 2")
		failed += _assert(abs(float(scale_tree.call("visual_scale_for", &"ancient")) - 1.5) < 0.01, "ancient visual 1.5")
		var sap_sprite: Sprite2D = scale_tree.get_node_or_null("Sprite") as Sprite2D
		failed += _assert(sap_sprite != null and abs(sap_sprite.scale.x - 0.5) < 0.01, "sapling sprite scale 0.5")
		game_state.set("stage_id", &"ancient")
		scale_tree.call("_refresh_visual")
		failed += _assert(sap_sprite != null and abs(sap_sprite.scale.x - 1.5) < 0.01 and abs(sap_sprite.scale.y - 1.5) < 0.01, "ancient sprite scale 1.5")
		var ancient_def: Dictionary = game_state.call("get_stage_def", &"ancient")
		var ancient_sz: Variant = ancient_def.get("size", [])
		failed += _assert(typeof(ancient_sz) == TYPE_ARRAY and int((ancient_sz as Array)[0]) == 512, "ancient canvas size unchanged")
		scale_tree.free()
		game_state.call("reset_for_new_game")
		save_service.call("delete_save")
		var sheet_main: PackedScene = load("res://scenes/main.tscn") as PackedScene
		var live_sheet: Node = sheet_main.instantiate()
		tree_root.add_child(live_sheet)
		await process_frame
		var stones: Node = live_sheet.get_node_or_null("World/Runestones")
		failed += _assert(stones != null and stones.get_child_count() == 7, "seven runestones in the hub")
		if stones:
			var seen: Dictionary = {}
			for stone_node: Node in stones.get_children():
				seen[str(stone_node.get("stat_id"))] = true
				failed += _assert(stone_node.is_in_group("interactable"), "runestone is interactable")
				failed += _assert(stone_node.get_node_or_null("Stone") is Polygon2D, "runestone placeholder poly")
			for stat_need: String in ["might", "arcana", "resilience", "ward", "vitality", "swiftness", "fate"]:
				failed += _assert(bool(seen.get(stat_need, false)), "runestone for %s" % stat_need)
		var live_tree: Node = live_sheet.get_node_or_null("World/Manatree")
		var live_sprite: Sprite2D = null
		if live_tree:
			live_sprite = live_tree.get_node_or_null("Sprite") as Sprite2D
		failed += _assert(live_sprite != null and abs(live_sprite.scale.x - 0.5) < 0.01, "live sapling scale 0.5")
		var sheet_hud: Node = live_sheet.get_node_or_null("HUD")
		failed += _assert(sheet_hud != null and sheet_hud.has_method("open_character_sheet"), "HUD character sheet")
		var char_btn: Button = null
		var char_icon: ColorRect = null
		if sheet_hud:
			char_btn = sheet_hud.get_node_or_null("Panel/CharacterButton") as Button
			char_icon = sheet_hud.get_node_or_null("Panel/CharacterButton/CharacterIcon") as ColorRect
			if sheet_hud.has_method("hide_welcome"):
				sheet_hud.call("hide_welcome")
		failed += _assert(char_btn != null and str(char_btn.text) == "Character", "HUD Character button")
		failed += _assert(char_icon != null and char_icon.color.a > 0.5, "Character button ColorRect")
		sheet_hud.call("open_character_sheet")
		await process_frame
		failed += _assert(bool(sheet_hud.call("is_character_open")), "character sheet opens")
		var portrait: TextureRect = sheet_hud.get_node_or_null("CharacterSheet/Sheet/PortraitHost/Portrait") as TextureRect
		failed += _assert(portrait != null and portrait.texture != null, "keeper portrait")
		failed += _assert(portrait != null and str(portrait.texture.resource_path).find("keeper_idle_south") >= 0, "portrait uses idle_south")
		var weapon_slot: Node = sheet_hud.get_node_or_null("CharacterSheet/Sheet/PortraitHost/Slot_weapon")
		var relic_slot: Node = sheet_hud.get_node_or_null("CharacterSheet/Sheet/PortraitHost/Slot_relic")
		var relic_lock: ColorRect = sheet_hud.get_node_or_null("CharacterSheet/Sheet/PortraitHost/Slot_relic/Lock") as ColorRect
		var weapon_lock: ColorRect = sheet_hud.get_node_or_null("CharacterSheet/Sheet/PortraitHost/Slot_weapon/Lock") as ColorRect
		failed += _assert(weapon_slot != null and relic_slot != null, "weapon and relic slots")
		failed += _assert(relic_lock != null and relic_lock.visible, "relic grey lock")
		failed += _assert(weapon_lock != null and not weapon_lock.visible, "weapon lock hidden")
		var relic_hint: Label = sheet_hud.get_node_or_null("CharacterSheet/Sheet/PortraitHost/Slot_relic/Hint") as Label
		failed += _assert(relic_hint != null and str(relic_hint.text) == "Forge Key", "relic short hint")
		var might_line: Label = sheet_hud.get_node_or_null("CharacterSheet/Sheet/Stats/Stat_might/Line") as Label
		failed += _assert(might_line != null and str(might_line.text).find("+") >= 0 and str(might_line.text).find("=") >= 0, "stat line base + gear = total")
		var gear_list: Node = sheet_hud.get_node_or_null("CharacterSheet/Sheet/GearColumn/GearScroll/GearList")
		failed += _assert(gear_list != null, "equipment inventory column")
		equipment.call("grant_item", "stone_sword")
		await process_frame
		failed += _assert(gear_list.get_child_count() >= 1, "sword listed in equipment inventory")
		sheet_hud.get_node("CharacterSheet").call("request_equip", "stone_sword")
		await process_frame
		failed += _assert(str(equipment.call("equipped_id", "weapon")) == "stone_sword", "sheet click equips sword")
		might_line = sheet_hud.get_node_or_null("CharacterSheet/Sheet/Stats/Stat_might/Line") as Label
		failed += _assert(might_line != null and str(might_line.text).find("0 + 2 = 2") >= 0, "sheet shows 0 + 2 = 2")
		var slot_plate: Node = sheet_hud.get_node("CharacterSheet/Sheet/PortraitHost/Slot_weapon")
		sheet_hud.get_node("CharacterSheet").call("request_unequip", "weapon")
		await process_frame
		failed += _assert(str(equipment.call("equipped_id", "weapon")) == "", "sheet unequip")
		slot_plate.call("_drop_data", Vector2.ZERO, {"kind": "gear", "item_id": "stone_sword", "from_slot": ""})
		await process_frame
		failed += _assert(str(equipment.call("equipped_id", "weapon")) == "stone_sword", "sheet drag-drop equips")
		var head_plate: Node = sheet_hud.get_node("CharacterSheet/Sheet/PortraitHost/Slot_head")
		failed += _assert(not bool(head_plate.call("_can_drop_data", Vector2.ZERO, {"kind": "gear", "item_id": "stone_sword", "from_slot": ""})), "locked head rejects drop")
		var gear_col: Node = sheet_hud.get_node("CharacterSheet/Sheet/GearColumn")
		failed += _assert(bool(gear_col.call("_can_drop_data", Vector2.ZERO, {"kind": "gear", "item_id": "stone_sword", "from_slot": "weapon"})), "gear column accepts an unequip drag")
		gear_col.call("_drop_data", Vector2.ZERO, {"kind": "gear", "item_id": "stone_sword", "from_slot": "weapon"})
		await process_frame
		failed += _assert(str(equipment.call("equipped_id", "weapon")) == "", "drag onto the gear list unequips")
		sheet_hud.get_node("CharacterSheet").call("request_equip", "stone_sword")
		var c_key := InputEventKey.new()
		c_key.keycode = KEY_C
		c_key.pressed = true
		sheet_hud.call("_unhandled_input", c_key)
		await process_frame
		failed += _assert(not bool(sheet_hud.call("is_character_open")), "C closes the sheet")
		sheet_hud.call("_unhandled_input", c_key)
		await process_frame
		failed += _assert(bool(sheet_hud.call("is_character_open")), "C opens the sheet")
		sheet_hud.call("close_character_sheet")
		live_sheet.free()
		paused = false
		await process_frame
		game_state.call("reset_for_new_game")
		save_service.call("delete_save")

	if failed == 0:
		print("VERIFY_OK: all headless assertions passed")
		quit(0)
	else:
		print("VERIFY_FAIL: %d assertion(s) failed" % failed)
		quit(1)


func _assert(cond: bool, msg: String) -> int:
	if cond:
		return 0
	printerr("ASSERT FAIL: %s" % msg)
	return 1
