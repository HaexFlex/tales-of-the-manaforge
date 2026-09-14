extends SceneTree
## Headless verification per SYSTEMS_V01 + AUDIO_RESTART_V01.
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

	save_service.call("delete_save")
	game_state.call("reset_for_new_game")
	failed += _assert(str(game_state.get("stage_id")) == "sapling", "expected sapling")
	failed += _assert(int(game_state.get("growth")) == 0, "growth should be 0")

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
	game_state.set("lifetime_food_watered", 120)
	game_state.set("lifetime_fruit_harvested", 1)

	failed += _assert(bool(save_service.call("save_game")), "save_game failed")
	game_state.call("reset_for_new_game")
	failed += _assert(int(game_state.get("wood")) == 0, "wood not cleared")
	failed += _assert(bool(save_service.call("load_game")), "load_game failed")
	failed += _assert(int(game_state.get("wood")) == 42, "wood mismatch")
	failed += _assert(int(game_state.get("stone")) == 17, "stone mismatch")
	failed += _assert(int(game_state.get("food")) == 9, "food mismatch")
	failed += _assert(int(game_state.get("manashards")) == 6, "manashards mismatch")
	failed += _assert(int(game_state.get("essence")) == 4, "essence mismatch")
	failed += _assert(int(game_state.get("growth")) == 33, "growth mismatch")
	failed += _assert(str(game_state.get("stage_id")) == "mature", "stage mismatch")
	failed += _assert(int(game_state.call("get_upgrade_rank", "deep_roots")) == 2, "upgrade rank")
	failed += _assert(int(game_state.get("ascensions")) == 1, "ascensions")
	failed += _assert(int(game_state.get("lifetime_food_watered")) == 120, "lifetime_food_watered")

	game_state.call("reset_for_new_game")
	game_state.call("set_resource", &"food", 500)
	game_state.call("set_resource", &"wood", 500)
	game_state.call("set_resource", &"stone", 500)
	game_state.call("set_resource", &"manashards", 500)
	var guard: int = 0
	while str(game_state.get("stage_id")) != "ancient" and guard < 200:
		guard += 1
		game_state.set("_water_cooldown_until", 0.0)
		game_state.call("try_water")
	failed += _assert(str(game_state.get("stage_id")) == "ancient", "failed to reach ancient (stage=%s growth=%d)" % [str(game_state.get("stage_id")), int(game_state.get("growth"))])
	failed += _assert(bool(game_state.get("fruit_ready")), "fruit should be ready at ancient")

	var gained: int = int(game_state.call("harvest_fruit"))
	failed += _assert(gained >= 3, "essence gain too low: %d" % gained)
	failed += _assert(bool(game_state.call("can_ascend")), "should be pending ascend")
	failed += _assert(bool(game_state.call("buy_upgrade", "keeper_stride")), "buy keeper_stride failed")
	failed += _assert(int(game_state.call("get_upgrade_rank", "keeper_stride")) == 1, "stride rank")
	var base_speed: float = float(game_state.call("param_float", "BASE_MOVE_SPEED", 180.0))
	failed += _assert(float(game_state.call("get_move_speed")) > base_speed, "speed mult")

	game_state.call("ascend")
	failed += _assert(str(game_state.get("stage_id")) == "sapling", "ascend reset stage")
	failed += _assert(int(game_state.get("wood")) == 0, "soft mats reset")
	failed += _assert(int(game_state.get("essence")) > 0, "essence kept")
	failed += _assert(int(game_state.call("get_upgrade_rank", "keeper_stride")) == 1, "ranks persist")
	failed += _assert(int(game_state.get("ascensions")) == 1, "ascensions incremented")

	save_service.call("save_game")
	game_state.call("reset_for_new_game")
	save_service.call("load_game")
	failed += _assert(int(game_state.call("get_upgrade_rank", "keeper_stride")) == 1, "persisted upgrade")
	failed += _assert(str(content_strings.call("get_text", "game_title")) == "Tales of the Manaforge", "title string")
	failed += _assert(str(content_strings.call("get_text", "fruit_panel_title")).find("Blessings") >= 0, "fruit panel string")

	for uid: String in ["deep_roots", "forager", "green_thumb", "shard_sight", "keeper_stride"]:
		var def: Variant = game_state.call("get_upgrade_def", uid)
		failed += _assert(typeof(def) == TYPE_DICTIONARY and not (def as Dictionary).is_empty(), "missing upgrade %s" % uid)

	var cues: PackedStringArray = game_audio.call("list_cue_ids")
	failed += _assert(cues.size() >= 10, "audio cue table too small (%d)" % cues.size())
	game_audio.call("play", &"mus_hub_forest")
	game_audio.call("play", &"sfx_gather_wood")
	game_audio.call("play", &"sfx_tree_water")
	game_audio.call("play", &"sfx_stage_up")
	game_audio.call("play_fruit_harvest")
	game_audio.call("play_ascend")

	failed += _assert(AudioServer.get_bus_index("Music") >= 0, "Music bus missing")
	failed += _assert(AudioServer.get_bus_index("SFX_UI") >= 0, "SFX_UI bus missing")
	failed += _assert(AudioServer.get_bus_index("SFX_World") >= 0, "SFX_World bus missing")
	failed += _assert(AudioServer.get_bus_index("SFX_Progress") >= 0, "SFX_Progress bus missing")

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
