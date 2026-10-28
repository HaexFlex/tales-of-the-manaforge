extends RefCounted
## Hub-life checks. Loaded after autoloads so Keeper can see GameState.

var host: SceneTree


func _assert(ok: bool, message: String) -> int:
	return int(host.call("_assert", ok, message))


func weather(tree_root: Window, game_state: Node, save_service: Node, backpack: Node, content_strings: Node) -> int:
	var failed: int = 0
	game_state.call("reset_for_new_game")
	WeatherState.reset_default()
	failed += _assert(WeatherState.get_state() == "clear", "weather defaults to clear")
	var keys: PackedStringArray = PackedStringArray([
		"item_frostberry", "frostberry_tooltip",
		"weather_clear", "weather_soft_rain", "weather_mist", "weather_snow", "weather_blossom",
	])
	var expect_v2: Dictionary = {
		"item_frostberry": "Frostberry",
		"frostberry_tooltip": "Frostberry. A snow-kissed berry, kept for brewing.",
		"weather_clear": "Clear",
		"weather_soft_rain": "Soft rain",
		"weather_mist": "Mist",
		"weather_snow": "Light snow",
		"weather_blossom": "Blossom fall",
	}
	for key: String in keys:
		failed += _assert(str(content_strings.call("get_text", key)) == str(expect_v2.get(key, "TODO:%s" % key)), "string %s" % key)
	failed += _assert(str(content_strings.call("get_text", WeatherState.label_key())) == "Clear", "weather label key")
	failed += _assert(bool(backpack.call("is_known_item", "frostberry")), "frostberry is a known item")
	failed += _assert(str(backpack.call("item_kind", "frostberry")) == "brew_ingredient", "frostberry is a brewing ingredient")
	var frost_def: Dictionary = backpack.call("get_item_def", "frostberry")
	failed += _assert(bool(frost_def.get("brew_only", false)), "frostberry is brewing-only")
	failed += _assert(not (&"frostberry" in game_state.get("HARVEST_IDS")), "frostberry is not a harvest resource")
	# Soft rain trickles, and it does not add on top of active watering.
	WeatherState.set_state("soft_rain")
	game_state.call("set_resource", &"essence", 0)
	WeatherState.tick_rain(8.0)
	var rain_essence: int = int(game_state.get("essence"))
	failed += _assert(rain_essence > 0, "soft rain waters the tree")
	game_state.call("set_resource", &"essence", 0)
	for _i: int in range(8):
		game_state.call("apply_water_pulse", true, true, 1.0, "")
	var active_essence: int = int(game_state.get("essence"))
	failed += _assert(rain_essence < active_essence, "soft rain stays under active watering (%d vs %d)" % [rain_essence, active_essence])
	var jobs: Node = tree_root.get_node_or_null("ForgeJobs")
	failed += _assert(jobs != null, "weather jobs")
	if jobs != null:
		game_state.call("set_resource", &"essence", 0)
		jobs.call("set_keeper_task", "water", "manatree", true)
		WeatherState.tick_rain(8.0)
		failed += _assert(int(game_state.get("essence")) == 0, "soft rain does not stack on active watering")
		jobs.call("note_keeper_idle")
	# Mist raises Glowcap weight only while the game is open.
	WeatherState.set_state("mist")
	var mist_weights: Array = RoomLoot.herb_type_weights()
	failed += _assert(int(mist_weights[0]) == 75 and int(mist_weights[1]) == 50, "mist glowcap weight is 50 x 1.5")
	var mist_glow: int = 0
	var clear_glow: int = 0
	for seed: int in range(1, 81):
		WeatherState.set_state("mist")
		mist_glow += int(RoomLoot.roll(4, 2, false, RoomLoot.loot_rng(seed)).get("glowcap", 0))
		WeatherState.set_state("clear")
		clear_glow += int(RoomLoot.roll(4, 2, false, RoomLoot.loot_rng(seed)).get("glowcap", 0))
	failed += _assert(mist_glow > clear_glow, "mist reach rooms drop more glowcaps (%d vs %d)" % [mist_glow, clear_glow])
	WeatherState.set_state("mist")
	WeatherState.push_offline()
	var offline_weights: Array = RoomLoot.herb_type_weights()
	failed += _assert(int(offline_weights[0]) == 50 and int(offline_weights[1]) == 50, "mist does not change offline herb weights")
	WeatherState.pop_offline()
	# Snow can add a frostberry on a live berry harvest, never offline.
	WeatherState.set_state("snow")
	WeatherState.set_frostberry_chance_override(1.0)
	backpack.call("set_count", "frostberry", 0)
	game_state.set("harvest_accum", {})
	game_state.call("set_resource", &"food", 0)
	game_state.call("accumulate_keeper_harvest", &"food", 2.0, 1.0)
	failed += _assert(int(backpack.call("get_count", "frostberry")) == 1, "snow adds one frostberry per berry harvest")
	WeatherState.push_offline()
	game_state.call("apply_offline_keeper_harvest", 20.0, &"food", 1.0)
	failed += _assert(int(backpack.call("get_count", "frostberry")) == 1, "snow does not add frostberries offline")
	WeatherState.pop_offline()
	WeatherState.set_frostberry_chance_override(0.0)
	var before_none: int = int(backpack.call("get_count", "frostberry"))
	game_state.call("accumulate_keeper_harvest", &"food", 2.0, 1.0)
	failed += _assert(int(backpack.call("get_count", "frostberry")) == before_none, "chance 0 adds no frostberry")
	# Blossom is +10% Essence on watering, live only.
	WeatherState.reset_default()
	game_state.call("set_resource", &"essence", 0)
	game_state.set("elaia_water_essence_frac", 0.0)
	for _pulse: int in range(10):
		game_state.call("apply_water_pulse", true, true, 1.0, "")
	failed += _assert(int(game_state.get("essence")) == 10, "clear watering is 10 essence")
	WeatherState.set_state("blossom")
	game_state.call("set_resource", &"essence", 0)
	game_state.set("elaia_water_essence_frac", 0.0)
	for _pulse2: int in range(10):
		game_state.call("apply_water_pulse", true, true, 1.0, "")
	failed += _assert(int(game_state.get("essence")) == 11, "blossom watering is +10 percent (got %d)" % int(game_state.get("essence")))
	var jobs_water: Node = tree_root.get_node_or_null("ForgeJobs")
	if jobs_water != null:
		game_state.call("set_resource", &"essence", 0)
		var offline_water: Dictionary = jobs_water.call("_offline_water", 10.0, 1.0, "")
		failed += _assert(int(offline_water.get("essence", -1)) == 10, "blossom does not change offline watering")
	# Load rerolls. Headless with no queued roll returns to clear.
	WeatherState.set_state("snow")
	failed += _assert(bool(save_service.call("save_game", 7)), "weather save")
	WeatherState.push_test_roll("blossom")
	failed += _assert(bool(save_service.call("load_game", 7)), "weather load")
	failed += _assert(WeatherState.get_state() == "blossom", "load consumes the reroll")
	WeatherState.set_state("snow")
	failed += _assert(bool(save_service.call("load_game", 7)), "weather load again")
	failed += _assert(WeatherState.get_state() == "clear", "headless reroll returns to clear")
	save_service.call("delete_save")
	game_state.call("reset_for_new_game")
	WeatherState.reset_default()
	if failed == 0:
		print("WEATHER_HARVESTS_OK")
	else:
		print("WEATHER_HARVESTS_FAIL: %d" % failed)
	return failed


func chores(tree_root: Window, game_state: Node, save_service: Node) -> int:
	var failed: int = 0
	game_state.call("reset_for_new_game")
	WeatherState.reset_default()
	CompanionChores.clear_forced()
	var strings: Node = tree_root.get_node_or_null("ContentStrings")
	for key: String in ["companion_chore_manatree", "companion_chore_berries", "companion_chore_stone"]:
		var node_id: String = "manatree"
		var companion_id: String = "elaia"
		if key == "companion_chore_berries":
			node_id = "harvest_berry"
			companion_id = "puff"
		elif key == "companion_chore_stone":
			node_id = "harvest_stone"
			companion_id = "tortoise"
		var line: String = CompanionChores.node_label(companion_id, node_id)
		failed += _assert(line.find("{name}") < 0 and line.find(GameState.hero_display_name(companion_id)) >= 0, "string %s (%s)" % [key, line])
	failed += _assert(is_equal_approx(CompanionChores.rate_mult(), 0.5), "chore rate_mult is 0.5")
	failed += _assert(CompanionChores.assignment_of("elaia") == "manatree", "elaia defaults to the manatree")
	failed += _assert(CompanionChores.assignment_of("puff") == "harvest_berry", "puff defaults to berries")
	failed += _assert(CompanionChores.assignment_of("tortoise") == "harvest_stone", "tortoise defaults to stone")
	# 50% of the Keeper's gather rate.
	game_state.call("clear_rested_hands_bench_buff")
	game_state.set("harvest_accum", {})
	game_state.call("set_resource", &"food", 0)
	game_state.call("accumulate_keeper_harvest", &"food", 4.0, 1.0)
	var keeper_food: int = int(game_state.get("food"))
	game_state.set("harvest_accum", {})
	game_state.call("set_resource", &"food", 0)
	CompanionChores.set_forced_present("puff", true)
	CompanionChores.grant_online_seconds(4.0)
	var chore_food: int = int(game_state.get("food"))
	failed += _assert(keeper_food == 2 and chore_food == 1, "berry chore is half the keeper (keeper %d chore %d)" % [keeper_food, chore_food])
	# One companion per node.
	CompanionChores.set_forced_present("elaia", true)
	CompanionChores.set_assignment("elaia", "harvest_berry")
	CompanionChores.set_assignment("puff", "harvest_berry")
	failed += _assert(CompanionChores.assignment_of("elaia") == "harvest_berry", "first companion keeps the berry node")
	failed += _assert(CompanionChores.assignment_of("puff") == "", "second companion is refused on that node")
	failed += _assert(CompanionChores.active_ids().size() == 1, "only one companion works a node")
	# Chores stack with wisps.
	game_state.call("reset_for_new_game")
	WeatherState.reset_default()
	CompanionChores.set_forced_present("puff", true)
	CompanionChores.set_assignment("puff", "harvest_berry")
	game_state.set("harvest_accum", {})
	game_state.call("set_resource", &"food", 0)
	CompanionChores.grant_online_seconds(40.0)
	var only_chore: int = int(game_state.get("food"))
	game_state.set("harvest_accum", {})
	game_state.call("set_resource", &"food", 0)
	CompanionChores.clear_forced()
	game_state.call("accumulate_wisp_harvest", &"food", 40.0)
	var only_wisp: int = int(game_state.get("food"))
	game_state.set("harvest_accum", {})
	game_state.call("set_resource", &"food", 0)
	CompanionChores.set_forced_present("puff", true)
	CompanionChores.grant_online_seconds(40.0)
	game_state.call("accumulate_wisp_harvest", &"food", 40.0)
	var stacked: int = int(game_state.get("food"))
	failed += _assert(only_chore > 0 and only_wisp > 0 and stacked == only_chore + only_wisp, "chore stacks with wisps (%d + %d = %d)" % [only_chore, only_wisp, stacked])
	# Offline uses the locked curve, at 50%, and ignores weather.
	game_state.call("reset_for_new_game")
	WeatherState.set_state("snow")
	WeatherState.set_frostberry_chance_override(1.0)
	var backpack: Node = tree_root.get_node_or_null("Backpack")
	if backpack != null:
		backpack.call("set_count", "frostberry", 0)
	CompanionChores.set_forced_present("puff", true)
	var closed: float = 8.0 * 3600.0
	var eff: float = float(game_state.call("offline_effective_seconds", closed))
	var report: Dictionary = {}
	CompanionChores.apply_offline(eff, report)
	var curved: int = int(game_state.get("food"))
	game_state.set("harvest_accum", {})
	game_state.call("set_resource", &"food", 0)
	var matched: int = int(game_state.call("apply_offline_keeper_harvest", eff, &"food", 0.5))
	game_state.set("harvest_accum", {})
	game_state.call("set_resource", &"food", 0)
	var raw_half: int = int(game_state.call("apply_offline_keeper_harvest", closed, &"food", 0.5))
	failed += _assert(eff < closed, "eight hours is inside the offline curve")
	failed += _assert(curved == matched and curved > 0 and curved < raw_half, "offline chore uses the curve at 50 percent (%d vs raw %d)" % [curved, raw_half])
	if backpack != null:
		failed += _assert(int(backpack.call("get_count", "frostberry")) == 0, "offline chore does not grant frostberries")
	# Old saves gain the defaults.
	var migrated: Dictionary = save_service.call("migrate_state", 15, {"wood": 4})
	var chores: Dictionary = migrated.get("companion_chores", {})
	failed += _assert(str(chores.get("elaia", "")) == "manatree", "v15 migrate defaults elaia")
	failed += _assert(str(chores.get("puff", "")) == "harvest_berry", "v15 migrate defaults puff")
	failed += _assert(str(chores.get("tortoise", "")) == "harvest_stone", "v15 migrate defaults tortoise")
	var custom: Dictionary = save_service.call("migrate_state", 15, {"companion_chores": {"elaia": "harvest_stone"}})
	var custom_chores: Dictionary = custom.get("companion_chores", {})
	failed += _assert(str(custom_chores.get("elaia", "")) == "harvest_stone", "migrate keeps a saved chore")
	failed += _assert(str(custom_chores.get("puff", "")) == "harvest_berry", "migrate fills a missing puff chore")
	game_state.call("apply_save_dict", custom)
	failed += _assert(CompanionChores.assignment_of("elaia") == "harvest_stone", "loaded save keeps elaia's chore")
	failed += _assert(CompanionChores.assignment_of("tortoise") == "", "one node drops the later tortoise")
	game_state.call("reset_for_new_game")
	WeatherState.reset_default()
	CompanionChores.clear_forced()
	if failed == 0:
		print("COMPANION_CHORES_OK")
	else:
		print("COMPANION_CHORES_FAIL: %d" % failed)
	return failed


func schedule(tree_root: Window, game_state: Node, save_service: Node) -> int:
	var failed: int = 0
	game_state.call("reset_for_new_game")
	WeatherState.reset_default()
	CompanionChores.clear_forced()
	var strings: Node = tree_root.get_node_or_null("ContentStrings")
	for key: String in ["companion_schedule_bench", "companion_schedule_runestone", "companion_schedule_tree", "companion_schedule_chore"]:
		var place: String = "bench"
		if key == "companion_schedule_runestone":
			place = "runestone"
		elif key == "companion_schedule_tree":
			place = "tree"
		elif key == "companion_schedule_chore":
			place = "chore"
		var line: String = CompanionSchedule.place_label("elaia", place)
		failed += _assert(line.find("{name}") < 0 and line.find("Elaia") >= 0, "string %s (%s)" % [key, line])
	failed += _assert(not CompanionChores.follows_routine("elaia"), "a chore companion does not follow the clock")
	failed += _assert(CompanionSchedule.place_for("elaia", 0.10) == "chore", "chore companion stays put by day")
	failed += _assert(CompanionSchedule.place_for("elaia", 0.60) == "chore", "chore companion stays put at night")
	CompanionChores.set_assignment("elaia", "")
	failed += _assert(CompanionChores.follows_routine("elaia"), "an unassigned companion follows the routine")
	failed += _assert(CompanionSchedule.place_for("elaia", 0.10) == "tree", "day place is the tree")
	failed += _assert(CompanionSchedule.place_for("elaia", 0.40) == "bench", "dusk place is the bench")
	failed += _assert(CompanionSchedule.place_for("elaia", 0.60) == "runestone", "night place is a runestone")
	failed += _assert(CompanionSchedule.place_for("elaia", 0.90) == "chore", "dawn place is the chore node")
	var save_boot: String = str(save_service.get("boot_intent"))
	save_service.set("boot_intent", "new")
	var packed: PackedScene = load("res://scenes/main.tscn") as PackedScene
	failed += _assert(packed != null, "schedule hub scene")
	if packed != null:
		var live: Node = packed.instantiate()
		tree_root.add_child(live)
		await host.process_frame
		await host.process_frame
		var elaia: Keeper = live.get_node_or_null("World/Elaia") as Keeper
		failed += _assert(elaia != null and elaia.y_sort_enabled, "elaia y-sorts with the hub")
		for place: String in ["bench", "runestone", "tree", "chore"]:
			var anchor: Vector2 = CompanionSchedule._anchor(place, "puff")
			if anchor != Vector2.INF:
				var stand: Vector2 = CompanionSchedule.cleared_stand(anchor, place, "puff")
				failed += _assert(CompanionSchedule.stand_is_clear(stand, "puff"), "schedule stand %s stays off the bench, door, and work spots" % place)
		if elaia != null:
			game_state.set("echo_01_redeemed", true)
			game_state.set("first_relic_crafted", true)
			game_state.set("elaia_join_seen", true)
			game_state.set("elaia_area", "clearing")
			elaia.call("_apply_presence")
			CompanionChores.set_assignment("elaia", "")
			HubTimePhase.set_driven_phase01(0.40)
			CompanionSchedule.set_force_drive(true)
			CompanionSchedule.tick(0.016)
			failed += _assert(bool(elaia.get("_moving")), "routine companion walks with the existing move")
			var walk_name: String = Keeper.walk_anim_for_velocity(elaia.get("_target") - elaia.global_position, "south")
			failed += _assert(walk_name.begins_with("walk_"), "routine uses a walk clip (%s)" % walk_name)
			CompanionChores.set_assignment("elaia", "manatree")
			HubTimePhase.set_driven_phase01(0.40)
			elaia.call("halt")
			CompanionSchedule.tick(0.016)
			var chore_target: Vector2 = elaia.get("_target")
			var tree_node: Node2D = live.get_node_or_null("World/Manatree") as Node2D
			var bench: Node2D = live.get_node_or_null("World/KeepersBench") as Node2D
			failed += _assert(tree_node != null and bench != null, "chore anchors")
			if tree_node != null and bench != null:
				failed += _assert(chore_target.distance_to(tree_node.global_position) < chore_target.distance_to(bench.global_position), "chore companion stays at the tree instead of the dusk bench")
		CompanionSchedule.set_force_drive(false)
		HubTimePhase.set_driven_phase01(0.0)
		live.free()
	save_service.set("boot_intent", save_boot)
	game_state.call("reset_for_new_game")
	CompanionChores.clear_forced()
	if failed == 0:
		print("COMPANION_SCHEDULE_OK")
	else:
		print("COMPANION_SCHEDULE_FAIL: %d" % failed)
	return failed


func mood(tree_root: Window, game_state: Node) -> int:
	var failed: int = 0
	game_state.call("reset_for_new_game")
	var packed: PackedScene = load("res://scenes/manatree.tscn") as PackedScene
	failed += _assert(packed != null, "manatree scene")
	if packed == null:
		print("MANATREE_MOOD_HOOK_FAIL: %d" % (failed + 1))
		return failed + 1
	var tree: Manatree = packed.instantiate() as Manatree
	tree_root.add_child(tree)
	await host.process_frame
	failed += _assert(tree.mood_stage_number(&"sapling") == 1, "sapling is mood stage 1")
	failed += _assert(tree.mood_stage_number(&"ancient") == 5, "ancient is mood stage 5")
	failed += _assert(tree.mood_idle_frame_paths(1).is_empty(), "no mood art is shipped")
	failed += _assert(not tree.using_mood_idle(), "missing mood frames keep the current visual")
	var sprite: Sprite2D = tree.get_node_or_null("Sprite") as Sprite2D
	var current_path: String = ""
	if sprite != null and sprite.texture != null:
		current_path = str(sprite.texture.resource_path)
	failed += _assert(current_path.find("manatree_") >= 0, "stage art stays in use")
	var red := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	red.fill(Color(1, 0, 0, 1))
	var blue := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	blue.fill(Color(0, 0, 1, 1))
	var frame_a: Texture2D = ImageTexture.create_from_image(red)
	var frame_b: Texture2D = ImageTexture.create_from_image(blue)
	tree.debug_set_mood_frames([frame_a, frame_b])
	failed += _assert(tree.using_mood_idle() and sprite.texture == frame_a, "present mood frames replace the stage strip")
	tree._process(1.0)
	failed += _assert(sprite.texture == frame_b, "mood frames loop")
	tree.debug_set_mood_frames([])
	failed += _assert(not tree.using_mood_idle(), "clearing the hook restores the stage visual")
	if sprite.texture != null:
		failed += _assert(str(sprite.texture.resource_path).find("manatree_") >= 0, "stage art returns")
	tree.free()
	if failed == 0:
		print("MANATREE_MOOD_HOOK_OK")
	else:
		print("MANATREE_MOOD_HOOK_FAIL: %d" % failed)
	return failed


func weather_audio(tree_root: Window, game_state: Node) -> int:
	var failed: int = 0
	var audio: Node = tree_root.get_node_or_null("GameAudio")
	failed += _assert(audio != null, "GameAudio for weather beds")
	if audio == null:
		print("HUB_WEATHER_AUDIO_FAIL: %d" % failed)
		return failed
	var harvest_v: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/weather_harvests.json"))
	var harvest: Dictionary = harvest_v if typeof(harvest_v) == TYPE_DICTIONARY else {}
	var block_v: Variant = harvest.get("audio", {})
	var block: Dictionary = block_v if typeof(block_v) == TYPE_DICTIONARY else {}
	var fade: float = float(block.get("crossfade_sec", -1.0))
	var bed_in: float = float(block.get("bed_fade_in_sec", -1.0))
	var bed_out: float = float(block.get("bed_fade_out_sec", -1.0))
	failed += _assert(is_equal_approx(fade, 2.0), "weather crossfade is 2 s in data")
	failed += _assert(is_equal_approx(bed_in, 3.0), "weather bed fade in is 3 s in data")
	failed += _assert(is_equal_approx(bed_out, 4.0), "weather bed fade out is 4 s in data")
	var rain_level: float = -6.0
	var mist_level: float = -8.0
	var hub_v: Variant = block.get("hub_bed", {})
	var hub: Dictionary = hub_v if typeof(hub_v) == TYPE_DICTIONARY else {}
	var rain_row: Dictionary = hub.get("soft_rain", {})
	var mist_row: Dictionary = hub.get("mist", {})
	var snow_row: Dictionary = hub.get("snow", {})
	var blossom_row: Dictionary = hub.get("blossom", {})
	var clear_row: Dictionary = hub.get("clear", {})
	failed += _assert(is_equal_approx(float(rain_row.get("lowpass_hz", -1.0)), 3000.0) and is_equal_approx(float(rain_row.get("gain_db", 0.0)), -3.0), "soft rain hub row")
	failed += _assert(is_equal_approx(float(mist_row.get("lowpass_hz", -1.0)), 2500.0) and is_equal_approx(float(mist_row.get("gain_db", 0.0)), -2.0), "mist hub row")
	for row: Dictionary in [snow_row, blossom_row]:
		failed += _assert(
			is_equal_approx(float(row.get("reverb_room", -1.0)), 0.35)
			and is_equal_approx(float(row.get("reverb_wet", -1.0)), 0.12)
			and is_equal_approx(float(row.get("reverb_damp", -1.0)), 0.6),
			"snow and blossom reverb row",
		)
	failed += _assert(clear_row.is_empty(), "clear hub row has no effect")
	var beds_v: Variant = block.get("beds", {})
	var beds: Dictionary = beds_v if typeof(beds_v) == TYPE_DICTIONARY else {}
	var rain_id: String = str(beds.get("soft_rain", ""))
	var mist_id: String = str(beds.get("mist", ""))
	failed += _assert(rain_id == "sfx_weather_rain_bed" and mist_id == "sfx_weather_mist_bed", "bed cue ids")
	var cues_v: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/audio_cues.json"))
	var cues_root: Dictionary = cues_v if typeof(cues_v) == TYPE_DICTIONARY else {}
	var cues: Dictionary = cues_root.get("cues", {})
	for cue_id: String in [rain_id, mist_id]:
		var cue: Dictionary = cues.get(cue_id, {})
		failed += _assert(str(cue.get("bus", "")) == "SFX_World" and bool(cue.get("loop", false)), "bed %s bus and loop" % cue_id)
		failed += _assert(FileAccess.file_exists(str(cue.get("path", ""))), "bed file %s" % cue_id)
	failed += _assert(is_equal_approx(float((cues.get(rain_id, {}) as Dictionary).get("volume_db", -99.0)), rain_level), "rain bed level")
	failed += _assert(is_equal_approx(float((cues.get(mist_id, {}) as Dictionary).get("volume_db", -99.0)), mist_level), "mist bed level")
	var chore_v: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/companion_chores.json"))
	var chore_root: Dictionary = chore_v if typeof(chore_v) == TYPE_DICTIONARY else {}
	var payout: Dictionary = chore_root.get("payout_audio", {})
	var by_node: Dictionary = payout.get("by_node", {})
	failed += _assert(is_equal_approx(float(payout.get("offset_db", 0.0)), -6.0), "chore cue offset -6 dB")
	failed += _assert(is_equal_approx(float(payout.get("gap_sec", 0.0)), 2.0), "chore cue gap 2 s")
	failed += _assert(str(payout.get("bus", "")) == "SFX_World", "chore cue bus")
	failed += _assert(str(by_node.get("harvest_berry", "")) == "sfx_gather_food", "berry chore uses the food gather cue")
	failed += _assert(str(by_node.get("harvest_stone", "")) == "sfx_gather_stone", "stone chore uses the stone gather cue")
	failed += _assert(str(by_node.get("manatree", "")) == "sfx_water_pulse", "manatree chore uses the water cue")
	game_state.call("reset_for_new_game")
	WeatherState.reset_default()
	CompanionChores.clear_forced()
	var half: float = fade * 0.5
	var open_hz: float = HubTimePhase.HUB_AMBIENCE_DAY_CUTOFF_HZ
	audio.call("advance_weather_audio", 0.0)
	var clear_now: Dictionary = audio.call("weather_hub_bus_params")
	failed += _assert(not bool(clear_now.get("lowpass_enabled", true)) and not bool(clear_now.get("gain_enabled", true)) and not bool(clear_now.get("reverb_enabled", true)), "clear bus effect is off")
	failed += _assert(not bool(audio.call("weather_bed_playing", rain_id)) and not bool(audio.call("weather_bed_playing", mist_id)), "clear plays no weather bed")
	WeatherState.set_state("soft_rain")
	audio.call("advance_weather_audio", fade * 0.5)
	var mid_rain: Dictionary = audio.call("weather_hub_bus_params")
	var silence: float = float(audio.call("weather_bed_silence_db"))
	failed += _assert(bool(mid_rain.get("lowpass_enabled", false)) and is_equal_approx(float(mid_rain.get("lowpass_hz", 0.0)), lerpf(open_hz, 3000.0, 0.5)), "rain low-pass is halfway through 2 s (got %s)" % str(mid_rain.get("lowpass_hz", 0.0)))
	failed += _assert(bool(mid_rain.get("gain_enabled", false)) and is_equal_approx(float(mid_rain.get("gain_db", 0.0)), -1.5), "rain gain is halfway to -3 dB")
	failed += _assert(bool(audio.call("weather_bed_playing", rain_id)) and not bool(audio.call("weather_bed_playing", mist_id)), "only the rain bed is in the rain crossfade")
	failed += _assert(is_equal_approx(float(audio.call("weather_bed_volume_db", rain_id)), lerpf(silence, rain_level, (fade * 0.5) / bed_in)), "rain bed is one third up at 1 s")
	failed += _assert(str(audio.call("weather_bed_bus", rain_id)) == "SFX_World", "rain bed bus")
	audio.call("advance_weather_audio", fade * 0.5)
	var rain_done: Dictionary = audio.call("weather_hub_bus_params")
	failed += _assert(is_equal_approx(float(rain_done.get("lowpass_hz", 0.0)), 3000.0) and is_equal_approx(float(rain_done.get("gain_db", 0.0)), -3.0) and not bool(rain_done.get("reverb_enabled", true)), "soft rain bus effect settled")
	failed += _assert(bool(audio.call("weather_bed_playing", rain_id)) and is_equal_approx(float(audio.call("weather_bed_volume_db", rain_id)), lerpf(silence, rain_level, (fade * 2.0) / bed_in)), "rain bed is two thirds up at 2 s")
	audio.call("advance_weather_audio", bed_in - (fade * 2.0))
	failed += _assert(bool(audio.call("weather_bed_playing", rain_id)) and is_equal_approx(float(audio.call("weather_bed_volume_db", rain_id)), rain_level), "rain bed is fully up")
	WeatherState.set_state("mist")
	audio.call("advance_weather_audio", half)
	var mid_mist: Dictionary = audio.call("weather_hub_bus_params")
	failed += _assert(bool(audio.call("weather_bed_playing", rain_id)) and bool(audio.call("weather_bed_playing", mist_id)), "rain and mist crossfade together")
	failed += _assert(is_equal_approx(float(mid_mist.get("lowpass_hz", 0.0)), lerpf(3000.0, 2500.0, 0.5)) and is_equal_approx(float(mid_mist.get("gain_db", 0.0)), lerpf(-3.0, -2.0, 0.5)), "mist bus effect is halfway")
	audio.call("advance_weather_audio", half)
	var mist_done: Dictionary = audio.call("weather_hub_bus_params")
	failed += _assert(not bool(audio.call("weather_bed_playing", rain_id)) and bool(audio.call("weather_bed_playing", mist_id)), "mist bed plays only in mist")
	failed += _assert(is_equal_approx(float(audio.call("weather_bed_volume_db", mist_id)), mist_level), "mist bed is fully up")
	failed += _assert(is_equal_approx(float(mist_done.get("lowpass_hz", 0.0)), 2500.0) and is_equal_approx(float(mist_done.get("gain_db", 0.0)), -2.0), "mist bus effect settled")
	WeatherState.set_state("snow")
	audio.call("advance_weather_audio", bed_out)
	var snow_fx: Dictionary = audio.call("weather_hub_bus_params")
	failed += _assert(not bool(audio.call("weather_bed_playing", rain_id)) and not bool(audio.call("weather_bed_playing", mist_id)), "snow plays no weather bed")
	failed += _assert(not bool(snow_fx.get("lowpass_enabled", true)) and not bool(snow_fx.get("gain_enabled", true)) and bool(snow_fx.get("reverb_enabled", false)), "snow uses reverb only")
	failed += _assert(
		is_equal_approx(float(snow_fx.get("reverb_room", 0.0)), 0.35)
		and is_equal_approx(float(snow_fx.get("reverb_wet", 0.0)), 0.12)
		and is_equal_approx(float(snow_fx.get("reverb_damp", 0.0)), 0.6),
		"snow reverb params",
	)
	WeatherState.set_state("blossom")
	audio.call("advance_weather_audio", fade)
	var blossom_fx: Dictionary = audio.call("weather_hub_bus_params")
	failed += _assert(
		bool(blossom_fx.get("reverb_enabled", false))
		and is_equal_approx(float(blossom_fx.get("reverb_room", 0.0)), 0.35)
		and is_equal_approx(float(blossom_fx.get("reverb_wet", 0.0)), 0.12)
		and is_equal_approx(float(blossom_fx.get("reverb_damp", 0.0)), 0.6)
		and not bool(audio.call("weather_bed_playing", rain_id))
		and not bool(audio.call("weather_bed_playing", mist_id)),
		"blossom reverb matches snow and beds stay off",
	)
	WeatherState.set_state("clear")
	audio.call("advance_weather_audio", fade)
	var cleared: Dictionary = audio.call("weather_hub_bus_params")
	failed += _assert(not bool(cleared.get("lowpass_enabled", true)) and not bool(cleared.get("gain_enabled", true)) and not bool(cleared.get("reverb_enabled", true)), "clear removes the hub effect")
	failed += _assert(not bool(audio.call("weather_bed_playing", rain_id)) and not bool(audio.call("weather_bed_playing", mist_id)), "clear stops both beds")
	game_state.call("reset_for_new_game")
	game_state.call("clear_rested_hands_bench_buff")
	WeatherState.reset_default()
	var params: Dictionary = (game_state.get("params") as Dictionary).duplicate()
	var saved_chance: Variant = params.get("LUCKY_HARVEST_CHANCE", 0.04)
	params["LUCKY_HARVEST_CHANCE"] = 0.0
	game_state.set("params", params)
	CompanionChores.clear_forced()
	CompanionChores.set_forced_present("elaia", false)
	CompanionChores.set_assignment("elaia", "")
	CompanionChores.set_forced_present("puff", true)
	CompanionChores.set_forced_present("tortoise", true)
	CompanionChores.set_assignment("puff", "harvest_berry")
	CompanionChores.set_assignment("tortoise", "harvest_stone")
	game_state.set("harvest_accum", {})
	game_state.call("set_resource", &"food", 0)
	game_state.call("set_resource", &"stone", 0)
	audio.call("clear_played_log")
	audio.call("clear_chore_cues")
	CompanionChores.grant_online_seconds(4.0)
	failed += _assert(int(game_state.get("food")) == 1 and int(game_state.get("stone")) == 1, "both chores pay out (food %d stone %d)" % [int(game_state.get("food")), int(game_state.get("stone"))])
	var food_cue: bool = audio.call("did_play", &"sfx_gather_food")
	var stone_cue: bool = audio.call("did_play", &"sfx_gather_stone")
	failed += _assert(food_cue and stone_cue, "each companion plays its gather cue")
	failed += _assert(is_equal_approx(float(audio.get("last_cue_volume_db")), -6.0), "chore cue is -6 dB")
	failed += _assert(str(audio.get("last_cue_bus")) == "SFX_World", "chore cue bus is SFX_World")
	failed += _assert(not bool(audio.call("did_play", &"sfx_mana_chime_1")), "chore payout does not play the keeper chime")
	audio.call("clear_played_log")
	audio.call("age_chore_cue", "puff", 1999)
	audio.call("age_chore_cue", "tortoise", 1999)
	CompanionChores.grant_online_seconds(4.0)
	failed += _assert(not bool(audio.call("did_play", &"sfx_gather_food")) and not bool(audio.call("did_play", &"sfx_gather_stone")), "chore cue stays quiet inside 2 s")
	audio.call("clear_played_log")
	audio.call("age_chore_cue", "puff", 2000)
	audio.call("age_chore_cue", "tortoise", 2000)
	CompanionChores.grant_online_seconds(4.0)
	failed += _assert(bool(audio.call("did_play", &"sfx_gather_food")) and bool(audio.call("did_play", &"sfx_gather_stone")), "chore cue plays again after 2 s")
	audio.call("clear_played_log")
	var played_tree: bool = bool(audio.call("play_chore_payout", "elaia", "manatree"))
	failed += _assert(played_tree and bool(audio.call("did_play", &"sfx_water_pulse")) and is_equal_approx(float(audio.get("last_cue_volume_db")), -6.0), "manatree chore uses the water cue at -6 dB")
	audio.call("clear_played_log")
	failed += _assert(not bool(audio.call("play_chore_payout", "elaia", "manatree")) and not bool(audio.call("did_play", &"sfx_water_pulse")), "one companion's cue does not block another, and her own 2 s still holds")
	audio.call("clear_played_log")
	WeatherState.push_offline()
	audio.call("age_chore_cue", "puff", 2000)
	CompanionChores.grant_online_seconds(4.0)
	failed += _assert(not bool(audio.call("did_play", &"sfx_gather_food")), "offline catch-up does not play the chore cue")
	WeatherState.pop_offline()
	var before_food: int = int(game_state.get("food"))
	audio.call("clear_played_log")
	var closed: float = 8.0 * 3600.0
	var eff: float = float(game_state.call("offline_effective_seconds", closed))
	CompanionChores.apply_offline(eff, {})
	failed += _assert(int(game_state.get("food")) > before_food, "offline chore still pays")
	failed += _assert(not bool(audio.call("did_play", &"sfx_gather_food")) and not bool(audio.call("did_play", &"sfx_gather_stone")), "offline apply does not play gather cues")
	params["LUCKY_HARVEST_CHANCE"] = saved_chance
	game_state.set("params", params)
	game_state.call("reset_for_new_game")
	WeatherState.reset_default()
	CompanionChores.clear_forced()
	audio.call("advance_weather_audio", fade)
	if failed == 0:
		print("HUB_WEATHER_AUDIO_OK")
	else:
		print("HUB_WEATHER_AUDIO_FAIL: %d" % failed)
	return failed
