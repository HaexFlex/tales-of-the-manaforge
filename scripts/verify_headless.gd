extends SceneTree
## Headless verification per SYSTEMS_V01 v0.1.2 (channels) + AUDIO.
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
	failed += _assert(int(save_service.get("SAVE_VERSION")) == 3, "SAVE_VERSION should be 3")
	failed += _assert(int(game_state.call("param_int", "WATER_GROWTH", 0)) == 8, "WATER_GROWTH default 8")
	failed += _assert(int(game_state.call("param_int", "HARVEST_WOOD_PER_SEC", 0)) == 1, "HARVEST_WOOD_PER_SEC")
	failed += _assert(int(game_state.call("param_int", "WATER_ESSENCE_PER_SEC", 0)) == 1, "WATER_ESSENCE_PER_SEC")
	failed += _assert(str(content_strings.call("get_text", "tree_offer_wood")).find("Offer") >= 0, "offer strings")
	failed += _assert(str(content_strings.call("get_text", "tree_stage_blocked_food")).find("Food") >= 0, "food gate string")
	failed += _assert(str(content_strings.call("get_text", "tooltip_essence")).find("watering") >= 0, "essence not fruit-only")
	failed += _assert(str(content_strings.call("get_text", "node_wood_busy")).find("Harvesting") >= 0, "harvest channel HUD")
	failed += _assert(str(content_strings.call("get_text", "tree_water_pulse_hud")).find("Manashards") >= 0, "water pulse HUD")
	failed += _assert(str(content_strings.call("get_text", "tree_water_no_food")) == "tree_water_no_food", "tree_water_no_food must be removed")

	# Art harvest nodes
	failed += _assert(ResourceLoader.exists("res://assets/art/props/harvest_tree.png"), "harvest_tree art")
	failed += _assert(ResourceLoader.exists("res://assets/art/props/harvest_stone.png"), "harvest_stone art")
	failed += _assert(ResourceLoader.exists("res://assets/art/props/harvest_berry.png"), "harvest_berry art")

	save_service.call("delete_save")
	game_state.call("reset_for_new_game")
	failed += _assert(str(game_state.get("stage_id")) == "sapling", "expected sapling")
	failed += _assert(int(game_state.get("growth")) == 0, "growth should be 0")

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

	# Simulate water tick: manashards + essence + growth
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
	failed += _assert(int(game_state.get("growth")) == g0 + int(game_state.call("get_water_growth_amount")), "water growth")
	failed += _assert(int(game_state.get("lifetime_waters")) == 1, "lifetime_waters")
	failed += _assert(int(game_state.get("lifetime_shards_from_water")) == shards, "lifetime_shards_from_water")
	failed += _assert(int(game_state.get("lifetime_essence_from_water")) == 1, "lifetime_essence_from_water")

	# Ancient water still pays (no growth stage)
	game_state.call("set_resource", &"wood", 500)
	game_state.call("set_resource", &"stone", 500)
	game_state.call("set_resource", &"food", 500)
	game_state.call("set_resource", &"manashards", 500)
	var guard: int = 0
	while str(game_state.get("stage_id")) != "ancient" and guard < 400:
		guard += 1
		game_state.call("apply_water_pulse")
	failed += _assert(str(game_state.get("stage_id")) == "ancient", "reach ancient")
	var e_a: int = int(game_state.get("essence"))
	var m_a: int = int(game_state.get("manashards"))
	var w_anc: Dictionary = game_state.call("apply_water_pulse")
	failed += _assert(bool(w_anc.get("ok", false)), "ancient water still ok")
	failed += _assert(int(game_state.get("essence")) > e_a, "ancient water essence")
	failed += _assert(int(game_state.get("manashards")) > m_a, "ancient water shards")

	# Save roundtrip v3
	game_state.call("reset_for_new_game")
	game_state.call("set_resource", &"wood", 42)
	game_state.call("set_resource", &"stone", 17)
	game_state.call("set_resource", &"food", 9)
	game_state.call("set_resource", &"manashards", 6)
	game_state.call("set_resource", &"essence", 4)
	game_state.set("growth", 33)
	game_state.call("_set_stage", &"mature")
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
	failed += _assert(bool(save_service.call("load_game")), "load_game failed")
	failed += _assert(int(game_state.get("wood")) == 42, "wood mismatch")
	failed += _assert(int(game_state.get("lifetime_shards_from_water")) == 200, "shards lifetime")
	failed += _assert(int(game_state.get("lifetime_essence_from_water")) == 120, "essence lifetime")
	failed += _assert(int((game_state.get("lifetime_harvested") as Dictionary).get("wood", 0)) == 11, "harvested wood lifetime")

	# Offer wood
	game_state.call("reset_for_new_game")
	game_state.call("set_resource", &"wood", 3)
	game_state.set("_offer_cooldown_until", 0.0)
	var offer_res: String = str(game_state.call("try_offer", &"wood"))
	failed += _assert(offer_res == "ok", "offer wood ok (got %s)" % offer_res)

	# Fruit / ascend
	game_state.call("reset_for_new_game")
	game_state.call("set_resource", &"food", 500)
	game_state.call("set_resource", &"wood", 500)
	game_state.call("set_resource", &"stone", 500)
	game_state.call("set_resource", &"manashards", 500)
	guard = 0
	while str(game_state.get("stage_id")) != "ancient" and guard < 400:
		guard += 1
		game_state.call("apply_water_pulse")
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
