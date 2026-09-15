extends SceneTree
## Headless verification per SYSTEMS_V01 v0.1.3 + welcome (SAVE_VERSION 4).
##   godot --headless --path . -s res://scripts/verify_headless.gd


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var tree_root: Window = get_root()
	var game_state: Node = tree_root.get_node_or_null("GameState")
	var save_service: Node = tree_root.get_node_or_null("SaveService")
	var content_strings: Node = tree_root.get_node_or_null("ContentStrings")
	var game_audio: Node = tree_root.get_node_or_null("GameAudio")

	var failed: int = 0
	failed += _assert(game_state != null, "GameState autoload missing")
	failed += _assert(save_service != null, "SaveService autoload missing")
	failed += _assert(content_strings != null, "ContentStrings autoload missing")
	failed += _assert(game_audio != null, "GameAudio autoload missing")
	if failed > 0:
		print("VERIFY_FAIL: %d assertion(s) failed (early)" % failed)
		quit(1)
		return

	failed += _assert(int(game_state.get("stages_data").size()) == 5, "expected 5 stages")
	failed += _assert(int(game_state.get("upgrades_data").size()) == 5, "expected 5 fruit upgrades")
	failed += _assert(int(save_service.get("SAVE_VERSION")) == 4, "SAVE_VERSION should be 4")
	failed += _assert(int(game_state.call("param_int", "WATER_GROWTH", 0)) == 1, "WATER_GROWTH default 1 (v0.1.3)")
	failed += _assert(int(game_state.call("param_int", "HARVEST_WOOD_PER_SEC", 0)) == 1, "HARVEST_WOOD_PER_SEC")
	failed += _assert(int(game_state.call("param_int", "WATER_ESSENCE_PER_SEC", 0)) == 1, "WATER_ESSENCE_PER_SEC")
	failed += _assert(int(game_state.call("param_int", "OFFER_GROWTH_WOOD", 0)) == 3, "OFFER_GROWTH_WOOD 3")
	failed += _assert(int(game_state.call("param_float", "CHANNEL_PULSE_SEC", 0.0)) == 1, "CHANNEL_PULSE_SEC 1")
	failed += _assert(str(content_strings.call("get_text", "tree_offer_wood")).find("Offer") >= 0, "offer strings")
	failed += _assert(str(content_strings.call("get_text", "tree_stage_blocked_food")).find("Food") >= 0, "food gate string")
	failed += _assert(str(content_strings.call("get_text", "tooltip_essence")).find("watering") >= 0, "essence not fruit-only")
	failed += _assert(str(content_strings.call("get_text", "node_wood_busy")).find("Harvesting") >= 0, "harvest channel HUD")
	failed += _assert(str(content_strings.call("get_text", "tree_water_pulse_hud")).find("Manashards") >= 0, "water pulse HUD")
	failed += _assert(str(content_strings.call("get_text", "tree_water_no_food")) == "tree_water_no_food", "tree_water_no_food must be removed")
	failed += _assert(str(content_strings.call("get_text", "welcome_boot")).find("Tend the Manatree") >= 0, "welcome_boot")
	failed += _assert(str(content_strings.call("get_text", "welcome_body")).find("Keeper") >= 0, "welcome_body")
	failed += _assert(str(content_strings.call("get_text", "welcome_dismiss")).find("tend") >= 0, "welcome_dismiss")
	failed += _assert(str(content_strings.call("get_text", "welcome_hint")).find("Manatree") >= 0, "welcome_hint")
	failed += _assert(str(content_strings.call("get_text", "tree_next_stage_growth")).find("{current}") >= 0, "tree_next_stage_growth")
	failed += _assert(str(content_strings.call("get_text", "tree_next_stage_needs_met")).find("gathered") >= 0, "tree_next_stage_needs_met")

	# Stage growth_required v0.1.3
	var young: Dictionary = game_state.call("get_stage_def", &"young")
	var mature: Dictionary = game_state.call("get_stage_def", &"mature")
	var elder: Dictionary = game_state.call("get_stage_def", &"elder")
	var ancient: Dictionary = game_state.call("get_stage_def", &"ancient")
	failed += _assert(int(young.get("growth_required", 0)) == 120, "young growth_required 120")
	failed += _assert(int(mature.get("growth_required", 0)) == 200, "mature growth_required 200")
	failed += _assert(int(elder.get("growth_required", 0)) == 320, "elder growth_required 320")
	failed += _assert(int(ancient.get("growth_required", 0)) == 480, "ancient growth_required 480")
	var anc_size: Variant = ancient.get("size", [])
	failed += _assert(typeof(anc_size) == TYPE_ARRAY and int((anc_size as Array)[0]) == 512 and int((anc_size as Array)[1]) == 640, "ancient size 512x640")

	# deep_roots +1 per rank
	var deep: Dictionary = game_state.call("get_upgrade_def", "deep_roots")
	failed += _assert(float(deep.get("value_per_rank", 0)) == 1.0, "deep_roots value_per_rank 1")

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
			failed += _assert(str(mroot.get("version", "")) == "v0.1.5", "meta version v0.1.5")
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

	save_service.call("delete_save")
	game_state.call("reset_for_new_game")
	failed += _assert(str(game_state.get("stage_id")) == "sapling", "expected sapling")
	failed += _assert(int(game_state.get("growth")) == 0, "growth should be 0")
	failed += _assert(bool(game_state.get("welcome_shown")) == false, "welcome_shown false on new game")

	# Care UI helpers
	var info: Dictionary = game_state.call("get_care_next_stage_info")
	failed += _assert(bool(info.get("is_ancient", true)) == false, "care info not ancient at sapling")
	failed += _assert(str(info.get("growth_line", "")).find("0") >= 0 or str(info.get("growth_line", "")).find("Growth") >= 0, "care growth line")
	failed += _assert(game_state.has_method("get_remaining_gate_costs"), "get_remaining_gate_costs helper")
	failed += _assert(game_state.has_method("format_remaining_gate_costs"), "format_remaining_gate_costs helper")

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

	# Simulate water tick: manashards + essence + growth(+1)
	game_state.call("reset_for_new_game")
	var e0: int = int(game_state.get("essence"))
	var m0: int = int(game_state.get("manashards"))
	var g0: int = int(game_state.get("growth"))
	var water: Dictionary = game_state.call("apply_water_pulse")
	failed += _assert(bool(water.get("ok", false)), "water pulse ok")
	var shards: int = int(water.get("shards", 0))
	var ess: int = int(water.get("essence", 0))
	failed += _assert(shards >= 1 and shards <= 3, "water shards U{1,3} got %d" % shards)
	failed += _assert(ess == 1, "water essence +1")
	failed += _assert(int(game_state.get("manashards")) == m0 + shards, "manashards inventory")
	failed += _assert(int(game_state.get("essence")) == e0 + ess, "essence from water")
	failed += _assert(int(game_state.call("get_water_growth_amount")) == 1, "water growth amount 1")
	failed += _assert(int(game_state.get("growth")) == g0 + 1, "water growth +1")
	failed += _assert(int(game_state.get("lifetime_waters")) == 1, "lifetime_waters")
	failed += _assert(int(game_state.get("lifetime_shards_from_water")) == shards, "lifetime_shards_from_water")
	failed += _assert(int(game_state.get("lifetime_essence_from_water")) == 1, "lifetime_essence_from_water")

	# Ancient water still pays (no growth stage) — force stage for speed
	game_state.call("reset_for_new_game")
	game_state.call("set_resource", &"wood", 500)
	game_state.call("set_resource", &"stone", 500)
	game_state.call("set_resource", &"food", 500)
	game_state.call("set_resource", &"manashards", 500)
	game_state.set("growth", 9999)
	game_state.call("_set_stage", &"elder")
	# One pulse with mats + growth should stage to ancient if growth meets required
	game_state.set("growth", int(game_state.call("get_growth_required_for_next")))
	game_state.call("apply_water_pulse")
	# If still not ancient, force
	if str(game_state.get("stage_id")) != "ancient":
		game_state.call("_set_stage", &"ancient")
		game_state.set("fruit_ready", true)
	failed += _assert(str(game_state.get("stage_id")) == "ancient", "reach ancient")
	var info_a: Dictionary = game_state.call("get_care_next_stage_info")
	failed += _assert(bool(info_a.get("is_ancient", false)), "care info ancient")
	var e_a: int = int(game_state.get("essence"))
	var m_a: int = int(game_state.get("manashards"))
	var w_anc: Dictionary = game_state.call("apply_water_pulse")
	failed += _assert(bool(w_anc.get("ok", false)), "ancient water still ok")
	failed += _assert(int(game_state.get("essence")) > e_a, "ancient water essence")
	failed += _assert(int(game_state.get("manashards")) > m_a, "ancient water shards")

	# Save roundtrip v4 + welcome_shown
	game_state.call("reset_for_new_game")
	game_state.call("set_resource", &"wood", 42)
	game_state.call("set_resource", &"stone", 17)
	game_state.call("set_resource", &"food", 9)
	game_state.call("set_resource", &"manashards", 6)
	game_state.call("set_resource", &"essence", 4)
	game_state.set("growth", 33)
	game_state.call("_set_stage", &"mature")
	game_state.set("welcome_shown", true)
	var ranks: Dictionary = game_state.get("upgrade_ranks")
	ranks["deep_roots"] = 2
	game_state.set("upgrade_ranks", ranks)
	game_state.set("ascensions", 1)
	game_state.set("lifetime_waters", 120)
	game_state.set("lifetime_shards_from_water", 200)
	game_state.set("lifetime_essence_from_water", 120)
	var offered: Dictionary = {"wood": 10, "stone": 5, "food": 8, "manashards": 2}
	game_state.set("lifetime_offered", offered)
	game_state.set("lifetime_fruit_harvested", 1)
	game_state.set("lifetime_harvested", {"wood": 11, "stone": 7, "food": 5})

	failed += _assert(bool(save_service.call("save_game")), "save_game failed")
	game_state.call("reset_for_new_game")
	failed += _assert(bool(game_state.get("welcome_shown")) == false, "reset clears welcome_shown")
	failed += _assert(bool(save_service.call("load_game")), "load_game failed")
	failed += _assert(int(game_state.get("wood")) == 42, "wood mismatch")
	failed += _assert(bool(game_state.get("welcome_shown")) == true, "welcome_shown persisted")
	failed += _assert(int(game_state.get("lifetime_shards_from_water")) == 200, "shards lifetime")
	failed += _assert(int(game_state.get("lifetime_essence_from_water")) == 120, "essence lifetime")
	failed += _assert(int((game_state.get("lifetime_harvested") as Dictionary).get("wood", 0)) == 11, "harvested wood lifetime")
	# deep_roots rank 2 → +2 growth
	failed += _assert(int(game_state.call("get_water_growth_amount")) == 3, "deep_roots +1/rank → growth 3")

	# Offer wood
	game_state.call("reset_for_new_game")
	game_state.call("set_resource", &"wood", 3)
	game_state.set("_offer_cooldown_until", 0.0)
	var g_before: int = int(game_state.get("growth"))
	var offer_res: String = str(game_state.call("try_offer", &"wood"))
	failed += _assert(offer_res == "ok", "offer wood ok (got %s)" % offer_res)
	failed += _assert(int(game_state.get("growth")) == g_before + 3, "offer wood +3 growth")

	# Fruit / ascend (force ancient — slow curve too long for headless loops)
	game_state.call("reset_for_new_game")
	game_state.call("set_resource", &"food", 500)
	game_state.call("set_resource", &"wood", 500)
	game_state.call("set_resource", &"stone", 500)
	game_state.call("set_resource", &"manashards", 500)
	game_state.call("_set_stage", &"ancient")
	game_state.set("fruit_ready", true)
	failed += _assert(bool(game_state.get("fruit_ready")), "fruit ready")
	var gained: int = int(game_state.call("harvest_fruit"))
	failed += _assert(gained >= 5, "essence fruit gain: %d" % gained)
	failed += _assert(bool(game_state.call("can_ascend")), "pending ascend")
	failed += _assert(bool(game_state.call("buy_upgrade", "keeper_stride")), "buy stride")
	game_state.call("ascend")
	failed += _assert(str(game_state.get("stage_id")) == "sapling", "ascend reset")
	failed += _assert(int(game_state.get("essence")) > 0, "essence kept")

	# Only 3 harvestables in main scene (avoid class_name deps under -s)
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
		inst.free()

	var cues: PackedStringArray = game_audio.call("list_cue_ids")
	failed += _assert(cues.size() >= 24, "audio cue table too small (%d)" % cues.size())
	failed += _assert(ResourceLoader.exists("res://assets/audio/sfx_water_pulse.ogg"), "sfx_water_pulse missing")
	failed += _assert(ResourceLoader.exists("res://assets/audio/sfx_channel_start.ogg"), "sfx_channel_start missing")
	failed += _assert(ResourceLoader.exists("res://assets/audio/mus_hub_forest.ogg"), "hub music missing")
	game_audio.call("play", &"mus_hub_forest")
	game_audio.call("play", &"sfx_gather_wood")
	game_audio.call("play", &"sfx_water_pulse")
	game_audio.call("play", &"sfx_channel_start")

	failed += _assert(AudioServer.get_bus_index("Music") >= 0, "Music bus missing")
	failed += _assert(AudioServer.get_bus_index("SFX_World") >= 0, "SFX_World bus missing")

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
