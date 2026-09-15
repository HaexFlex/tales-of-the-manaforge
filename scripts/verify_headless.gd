extends SceneTree
## Headless verification per SYSTEMS_V01 v0.2.0 — needs-only stage-up, SAVE_VERSION 4.
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
	failed += _assert(int(save_service.get("SAVE_SLOT_COUNT")) == 7, "SAVE_SLOT_COUNT should be 7")
	failed += _assert(not (game_state.get("params") as Dictionary).has("WATER_GROWTH"), "WATER_GROWTH removed")
	failed += _assert(int(game_state.call("param_int", "HARVEST_WOOD_PER_SEC", 0)) == 1, "HARVEST_WOOD_PER_SEC")
	failed += _assert(int(game_state.call("param_int", "WATER_ESSENCE_PER_SEC", 0)) == 1, "WATER_ESSENCE_PER_SEC")
	failed += _assert(int(game_state.call("param_float", "CHANNEL_PULSE_SEC", 0.0)) == 1, "CHANNEL_PULSE_SEC 1")
	failed += _assert(str(content_strings.call("get_text", "tree_pay")) == "Pay", "tree_pay")
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
	failed += _assert(str(content_strings.call("get_text", "welcome_hint")).find("Manatree") >= 0, "welcome_hint")
	failed += _assert(str(content_strings.call("get_text", "tree_next_stage_needs_met")).find("Pay") >= 0, "tree_next_stage_needs_met")
	failed += _assert(str(content_strings.call("get_text", "tree_pay_ok")).find("{next_stage}") >= 0, "tree_pay_ok")
	# Offers retired from Content UI
	failed += _assert(str(content_strings.call("get_text", "tree_offer_wood")) == "tree_offer_wood", "tree_offer_wood must be removed")

	# Pause menu content
	failed += _assert(str(content_strings.call("get_text", "pause_title")) == "Pause", "pause_title")
	failed += _assert(str(content_strings.call("get_text", "pause_resume")).find("Resume") >= 0, "pause_resume")
	failed += _assert(str(content_strings.call("get_text", "pause_new_game_confirm")).find("Keeper") >= 0, "pause_new_game_confirm")
	failed += _assert(str(content_strings.call("get_text", "pause_options_stub")).find("later") >= 0, "pause_options_stub")
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
	failed += _assert(int(young.get("cost_essence", 0)) == 20, "young cost_essence 20")
	failed += _assert(int(mature.get("cost_essence", 0)) == 40 and int(mature.get("cost_food", 0)) == 10, "mature 40e+10f")
	failed += _assert(int(elder.get("cost_essence", 0)) == 60 and int(elder.get("cost_food", 0)) == 20 and int(elder.get("cost_wood", 0)) == 10, "elder 60e+20f+10w")
	failed += _assert(
		int(ancient.get("cost_essence", 0)) == 80
		and int(ancient.get("cost_food", 0)) == 40
		and int(ancient.get("cost_wood", 0)) == 20
		and int(ancient.get("cost_stone", 0)) == 10,
		"ancient 80e+40f+20w+10s"
	)
	failed += _assert(not young.has("growth_required"), "growth_required removed from young")
	var anc_size: Variant = ancient.get("size", [])
	failed += _assert(typeof(anc_size) == TYPE_ARRAY and int((anc_size as Array)[0]) == 512 and int((anc_size as Array)[1]) == 640, "ancient size 512x640")

	# deep_roots = water essence bonus; green_thumb = soft need reduction
	var deep: Dictionary = game_state.call("get_upgrade_def", "deep_roots")
	failed += _assert(str(deep.get("effect", "")) == "water_essence_bonus", "deep_roots water_essence_bonus")
	var thumb: Dictionary = game_state.call("get_upgrade_def", "green_thumb")
	failed += _assert(str(thumb.get("effect", "")) == "soft_need_reduction", "green_thumb soft_need_reduction")

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

	# Pay Young: 20 essence
	game_state.call("reset_for_new_game")
	game_state.call("set_resource", &"essence", 20)
	failed += _assert(bool(game_state.call("can_pay_stage")), "can pay young at 20e")
	var pay_y: String = str(game_state.call("try_pay_stage"))
	failed += _assert(pay_y == "ok", "pay young ok (got %s)" % pay_y)
	failed += _assert(str(game_state.get("stage_id")) == "young", "stage young after pay")
	failed += _assert(int(game_state.get("essence")) == 0, "essence spent for young")

	# Pay Mature: 40e + 10 food
	game_state.call("set_resource", &"essence", 40)
	game_state.call("set_resource", &"food", 10)
	failed += _assert(str(game_state.call("try_pay_stage")) == "ok", "pay mature")
	failed += _assert(str(game_state.get("stage_id")) == "mature", "stage mature")

	# Pay Elder: 60e + 20f + 10w
	game_state.call("set_resource", &"essence", 60)
	game_state.call("set_resource", &"food", 20)
	game_state.call("set_resource", &"wood", 10)
	failed += _assert(str(game_state.call("try_pay_stage")) == "ok", "pay elder")
	failed += _assert(str(game_state.get("stage_id")) == "elder", "stage elder")

	# Pay Ancient: 80e + 40f + 20w + 10s
	game_state.call("set_resource", &"essence", 80)
	game_state.call("set_resource", &"food", 40)
	game_state.call("set_resource", &"wood", 20)
	game_state.call("set_resource", &"stone", 10)
	failed += _assert(str(game_state.call("try_pay_stage")) == "ok", "pay ancient")
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
	failed += _assert(str(game_state.call("try_pay_stage")) == "cant_afford", "cant afford young")
	failed += _assert(str(game_state.get("stage_id")) == "sapling", "still sapling")

	# Save roundtrip slot 1 (SAVE_VERSION 4, no growth)
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
	# Confirm written save_version is 4 and no growth in payload
	var slot1_path: String = str(save_service.call("slot_path", 1))
	var s1f := FileAccess.open(slot1_path, FileAccess.READ)
	failed += _assert(s1f != null, "read slot 1")
	if s1f:
		var s1root: Variant = JSON.parse_string(s1f.get_as_text())
		s1f.close()
		if typeof(s1root) == TYPE_DICTIONARY:
			failed += _assert(int((s1root as Dictionary).get("save_version", 0)) == 4, "written save_version 4")
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

	# green_thumb soft-mat reduction (10% per rank, min 1)
	game_state.call("reset_for_new_game")
	game_state.call("_set_stage", &"mature")  # next = elder needs food 20 wood 10
	var ranks2: Dictionary = game_state.get("upgrade_ranks")
	ranks2["green_thumb"] = 1
	game_state.set("upgrade_ranks", ranks2)
	var needs_gt: Dictionary = game_state.call("get_next_stage_needs")
	failed += _assert(int(needs_gt.get("essence", 0)) == 60, "green_thumb leaves essence alone")
	failed += _assert(int(needs_gt.get("food", 0)) == 18, "green_thumb food 20*0.9=18")
	failed += _assert(int(needs_gt.get("wood", 0)) == 9, "green_thumb wood 10*0.9=9")

	# Fruit / Ascend cycle (SYSTEMS v0.2.4 — Manashard shop; Ascension-only; Ascend optional)
	failed += _assert(str(content_strings.call("get_text", "fruit_step_1")).find("Harvest") >= 0, "fruit_step_1")
	failed += _assert(str(content_strings.call("get_text", "fruit_step_2")).find("Bless") >= 0, "fruit_step_2")
	failed += _assert(str(content_strings.call("get_text", "fruit_step_3")).find("Ascend") >= 0, "fruit_step_3")
	failed += _assert(str(content_strings.call("get_text", "fruit_flow_hint")).find("Manashards") >= 0, "fruit_flow_hint")
	failed += _assert(str(content_strings.call("get_text", "fruit_panel_title")).find("Ascension") >= 0, "fruit_panel_title")
	failed += _assert(str(content_strings.call("get_text", "fruit_shards_hud")).find("Manashards") >= 0, "fruit_shards_hud")
	failed += _assert(str(content_strings.call("get_text", "upgrade_cost")).find("Manashards") >= 0, "upgrade_cost shards")
	failed += _assert(str(content_strings.call("get_text", "upgrade_cant_afford")).find("Manashards") >= 0, "upgrade_cant_afford")
	failed += _assert(str(content_strings.call("get_text", "ascend_hint")).find("Manashards") >= 0, "ascend_hint")
	failed += _assert(str(content_strings.call("get_text", "ascend_before_bless_hint")).find("Manashards") >= 0, "ascend_before_bless_hint")
	failed += _assert(str(content_strings.call("get_text", "fruit_confirm")).find("Manashards") >= 0, "fruit_confirm v0.2.4")
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
	failed += _assert(gained_a >= 5, "essence fruit gain A: %d" % gained_a)
	failed += _assert(int(game_state.get("essence")) == ess_before_a + gained_a, "essence up after harvest")
	failed += _assert(bool(game_state.get("fruit_harvested_pending_ascend")), "pending after harvest")
	failed += _assert(not bool(game_state.get("fruit_ready")), "fruit_ready false after harvest")
	failed += _assert(bool(game_state.call("can_ascend")), "can_ascend without purchase")
	failed += _assert(int(game_state.call("harvest_fruit")) == 0, "harvest disabled while pending")
	# Costs: keeper_stride rank0 = 1 shard
	failed += _assert(int(game_state.call("get_upgrade_cost", "keeper_stride")) == 1, "stride cost 1+rank")
	failed += _assert(int(game_state.call("get_upgrade_cost", "green_thumb")) == 2, "thumb cost 2+rank")
	failed += _assert(int(game_state.call("get_upgrade_cost", "shard_sight")) == 2, "sight cost 2+2*rank at 0")
	game_state.call("ascend")
	failed += _assert(str(game_state.get("stage_id")) == "sapling", "ascend → sapling (no buy)")
	failed += _assert(int(game_state.get("wood")) == 0, "soft wood cleared")
	failed += _assert(int(game_state.get("stone")) == 0, "soft stone cleared")
	failed += _assert(int(game_state.get("food")) == 0, "soft food cleared")
	failed += _assert(int(game_state.get("manashards")) == 0, "soft shards cleared")
	failed += _assert(int(game_state.get("essence")) == ess_before_a + gained_a, "essence kept on ascend")
	failed += _assert(not bool(game_state.get("fruit_harvested_pending_ascend")), "pending false after ascend")
	failed += _assert(int(game_state.get("ascensions")) == 1, "ascensions +1")
	failed += _assert(not bool(game_state.call("can_buy_upgrade", "keeper_stride")), "shop locked after ascend")

	# Path B: harvest → multi-buy with Manashards → ascend; ranks+essence persist; shards wipe
	game_state.call("reset_for_new_game")
	game_state.call("_set_stage", &"ancient")
	game_state.call("set_resource", &"essence", 10)
	game_state.call("set_resource", &"manashards", 20)
	game_state.call("set_resource", &"wood", 2)
	var gained: int = int(game_state.call("harvest_fruit"))
	failed += _assert(gained >= 5, "essence fruit gain B: %d" % gained)
	failed += _assert(bool(game_state.call("can_ascend")), "pending ascend B")
	var ess_pre_buy: int = int(game_state.get("essence"))
	var shards_pre: int = int(game_state.get("manashards"))
	failed += _assert(bool(game_state.call("buy_upgrade", "keeper_stride")), "buy stride 1 shards")
	failed += _assert(bool(game_state.call("buy_upgrade", "keeper_stride")), "buy stride 2 multi-buy")
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
	failed += _assert(int(game_state.get("essence")) == ess_kept, "essence remainder kept")
	failed += _assert(int(game_state.call("get_upgrade_rank", "keeper_stride")) == 2, "blessings kept")
	failed += _assert(not bool(game_state.get("fruit_harvested_pending_ascend")), "pending false B")

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
			failed += _assert(hud.get_node_or_null("CarePanel/PayButton") != null, "PayButton missing")
			failed += _assert(hud.get_node_or_null("CarePanel/OfferWoodButton") == null, "OfferWoodButton must be gone")
			failed += _assert(hud.get_node_or_null("Panel/PauseButton") != null, "PauseButton missing")
		var pause_menu: Node = inst.get_node_or_null("PauseMenu")
		failed += _assert(pause_menu != null, "PauseMenu missing")
		if pause_menu:
			failed += _assert(int(pause_menu.process_mode) == 3, "PauseMenu PROCESS_MODE_ALWAYS")
			failed += _assert(pause_menu.has_method("open_pause"), "open_pause")
			failed += _assert(pause_menu.has_method("resume_game"), "resume_game")
		inst.free()

	var cues: PackedStringArray = game_audio.call("list_cue_ids")
	failed += _assert(cues.size() >= 24, "audio cue table too small (%d)" % cues.size())
	failed += _assert(ResourceLoader.exists("res://assets/audio/sfx_water_pulse.ogg"), "sfx_water_pulse missing")
	failed += _assert(ResourceLoader.exists("res://assets/audio/sfx_stage_up.ogg"), "sfx_stage_up missing")
	failed += _assert(ResourceLoader.exists("res://assets/audio/sfx_channel_start.ogg"), "sfx_channel_start missing")
	failed += _assert(ResourceLoader.exists("res://assets/audio/mus_hub_forest.ogg"), "hub music missing")
	game_audio.call("play", &"mus_hub_forest")
	game_audio.call("play", &"sfx_gather_wood")
	game_audio.call("play", &"sfx_water_pulse")
	game_audio.call("play", &"sfx_stage_up")
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
