extends RefCounted
class_name RosterTests
## Generic roster and save v16. Runnable from the default VERIFY suite and alone.

const BattleViewScript := preload("res://scripts/battle/battle_view.gd")


func generic(tree_root: Window, game_state: Node, save_service: Node) -> int:
	var failed: int = 0
	_quiet_reset(game_state)
	failed += _join_flags(tree_root, game_state)
	var ids: Array[String] = []
	for n: int in range(1, 13):
		var actor_id: String = "dummy_%02d" % n
		ids.append(actor_id)
		CompanionRoster.push_test_companion(actor_id, {
			"display_name": "D%02d" % n,
			"sheet_traits": [],
			"walk_ref_speed": 80,
			"move_speed_mult": 1.0,
			"work_rate": 1.0,
			"water_reward_mult": 1.0,
			"attack": "physical",
			"mechanic": null,
			"hub_body": false,
			"join": {"kind": "flag", "default": true},
		})
		game_state.call("set_companion_joined", actor_id, true)
	var reach: Node = tree_root.get_node_or_null("Reach")
	if reach == null:
		failed += 1
		print("ROSTER_GENERIC_FAIL: no Reach")
		_cleanup(game_state)
		return failed
	reach.call("reset_for_new_game")
	game_state.set("echo_02_resolved", true)
	var packed: PackedScene = load("res://scenes/expedition_board.tscn") as PackedScene
	var board: Node = packed.instantiate()
	tree_root.add_child(board)
	board.call("open_shell")
	board.call("_on_party_slot_pressed", "front", 1)
	var shell: Node = tree_root.get_node_or_null("ExpeditionShell")
	failed += _assert(shell != null, "picker shell")
	var visible_rows: int = 0
	if shell != null:
		for i: int in range(24):
			var row: Button = shell.find_child("PickerRow%d" % i, true, false) as Button
			if row != null and row.visible:
				visible_rows += 1
		var grid: GridContainer = shell.find_child("PickerList", true, false) as GridContainer
		failed += _assert(grid != null and grid.columns == 2, "12 companions use a two-column picker (cols %s)" % str(grid.columns if grid != null else -1))
		var scroll: ScrollContainer = shell.find_child("PickerScroll", true, false) as ScrollContainer
		failed += _assert(scroll != null and scroll.size.y <= 228.5, "picker scroll stays clamped")
		failed += _assert(visible_rows >= 12, "picker lists the dummy roster (%d)" % visible_rows)
	for n: int in range(7):
		board.call("toggle_member", ids[n])
	var party: Array = board.call("selected_party")
	failed += _assert(party.size() == 6, "party cap stays 6 (got %d)" % party.size())
	if shell != null and shell.has_method("hide_picker"):
		shell.call("hide_picker")
	board.free()
	var leftover: Node = tree_root.get_node_or_null("ExpeditionShell")
	if leftover != null and is_instance_valid(leftover):
		leftover.free()
	CompanionChores.set_assignment(ids[0], "harvest_tree")
	failed += _assert(CompanionChores.assignment_of(ids[0]) == "harvest_tree", "chore assignment follows the roster id")
	CompanionChores.set_assignment(ids[0], "")
	failed += _assert(CompanionSchedule.place_for(ids[0], 0.1) == "tree", "unassigned companion uses the schedule")
	var shown: String = str(game_state.call("hero_display_name", ids[0]))
	failed += _assert(shown == "D01", "display name comes from companions data (%s)" % shown)
	var label: String = CompanionChores.node_label(ids[0], "harvest_berry")
	var place: String = CompanionSchedule.place_label(ids[0], "bench")
	failed += _assert(label.find("{name}") < 0 and place.find("{name}") < 0, "labels do not leave {name} unformatted (%s / %s)" % [label, place])
	var strings: Node = tree_root.get_node_or_null("ContentStrings")
	var raw_chore: String = str(strings.call("get_text", "companion_chore_berries")) if strings != null else ""
	var raw_place: String = str(strings.call("get_text", "companion_schedule_bench")) if strings != null else ""
	if raw_chore.find("{name}") >= 0:
		failed += _assert(label.find(shown) >= 0, "chore label uses the roster display name (%s)" % label)
	if raw_place.find("{name}") >= 0:
		failed += _assert(place.find(shown) >= 0, "schedule label uses the roster display name (%s)" % place)
	game_state.call("companion_record", ids[0])["level"] = 4
	var before: Dictionary = game_state.call("to_save_dict")
	var block: Dictionary = (before.get("companions", {}) as Dictionary).get(ids[0], {})
	failed += _assert(bool(block.get("joined", false)) and int(block.get("level", 0)) == 4, "save writes companions{id}")
	game_state.call("reset_for_new_game")
	for actor_id: String in ids:
		if not CompanionRoster.ids().has(actor_id):
			CompanionRoster.push_test_companion(actor_id, {"display_name": actor_id, "hub_body": false, "attack": "physical"})
	game_state.call("apply_save_dict", before)
	var again: Dictionary = (game_state.call("to_save_dict").get("companions", {}) as Dictionary).get(ids[0], {})
	failed += _assert(bool(again.get("joined", false)) and int(again.get("level", 0)) == 4, "companions block round-trips")
	var stats: Dictionary = SlotEngine.member_stats(ids[0])
	var room: Array[Dictionary] = [{"beast": "wilt_wisp", "slot": 0, "row": "front"}]
	var fight: FightState = SlotEngine.fight_for_room([{"member": ids[0], "row": "front", "stats": stats}], {}, room, 3)
	var blow: Dictionary = fight.strike(ids[0], "wilt_wisp") if fight != null else {}
	failed += _assert(not stats.is_empty() and fight != null and not blow.is_empty(), "one battle resolves a roster companion")
	_cleanup(game_state)
	if failed == 0:
		print("ROSTER_GENERIC_OK")
	else:
		print("ROSTER_GENERIC_FAIL: %d" % failed)
	return failed


func migration(tree_root: Window, game_state: Node, save_service: Node) -> int:
	var failed: int = 0
	_quiet_reset(game_state)
	var fixture: Dictionary = {
		"wood": 3,
		"stone": 4,
		"food": 5,
		"manashards": 80,
		"essence": 7,
		"echo_01_redeemed": true,
		"first_relic_crafted": true,
		"elaia_join_seen": true,
		"elaia_legacy_joined": false,
		"elaia_area": "forge",
		"elaia_pos_x": 12.0,
		"elaia_pos_y": 18.0,
		"elaia_has_pos": true,
		"elaia_facing": "east",
		"elaia_equipped": {},
		"keeper_stats": {"might": 2},
		"companion_chores": {
			"elaia": "manatree",
			"puff": "harvest_berry",
			"tortoise": "harvest_stone",
		},
	}
	var migrated: Dictionary = save_service.call("migrate_state", 15, fixture)
	var chores: Dictionary = migrated.get("companion_chores", {})
	var companions: Dictionary = migrated.get("companions", {})
	var moss: Dictionary = companions.get("mossback", {})
	failed += _assert(str(chores.get("mossback", "")) == "harvest_stone", "v15 tortoise chore lands on mossback")
	failed += _assert(not chores.has("tortoise"), "migrated chores drop tortoise")
	failed += _assert(str(moss.get("chore", "")) == "harvest_stone" and int(moss.get("level", 0)) == 1, "mossback companion record")
	failed += _assert(not companions.has("tortoise"), "migrated companions drop tortoise")
	failed += _assert(not bool(moss.get("joined", true)), "mossback stays unjoined without a join event")
	failed += _assert(bool((companions.get("elaia", {}) as Dictionary).get("joined", false)), "elaia joined matches the relic gate")
	failed += _assert(not bool((companions.get("puff", {}) as Dictionary).get("joined", false)), "puff stays unjoined without a flag")
	game_state.call("apply_save_dict", migrated)
	var written: Dictionary = game_state.call("to_save_dict")
	failed += _assert(not (written.get("companions", {}) as Dictionary).has("tortoise"), "a v16 save does not write a tortoise companion")
	failed += _assert(not (written.get("companion_chores", {}) as Dictionary).has("tortoise"), "a v16 save does not write a tortoise chore")
	var first: Dictionary = _play_snapshot(game_state)
	_quiet_reset(game_state)
	game_state.call("apply_save_dict", migrated)
	var second: Dictionary = _play_snapshot(game_state)
	failed += _assert(first == second, "v16 load is stable in play")
	failed += _assert(bool(first.get("elaia_joined", false)), "play party keeps Elaia")
	failed += _assert(str(first.get("elaia_area", "")) == "forge" and is_equal_approx(float(first.get("elaia_x", 0.0)), 12.0), "elaia pose survives")
	failed += _assert(int(first.get("might", -1)) == 2, "runestone rank survives")
	failed += _assert(int(first.get("wood", -1)) == 3 and int(first.get("food", -1)) == 5 and int(first.get("essence", -1)) == 7, "resources survive")
	failed += _assert(str(first.get("moss_chore", "")) == "harvest_stone" and str(first.get("tortoise_chore", "")) == "harvest_stone", "stone chore follows mossback and the tortoise alias")
	failed += _assert(str(first.get("tortoise_name", "")) == "Mossback", "tortoise alias shows Mossback")
	failed += _assert(int(first.get("elaia_level", 0)) == 1 and not bool(first.get("puff_joined", true)) and not bool(first.get("moss_joined", true)), "levels stay, and puff and mossback stay unjoined")
	var gated: Dictionary = save_service.call("migrate_state", 15, {
		"echo_01_redeemed": true,
		"first_relic_crafted": true,
		"echo_02_outcome": "spare",
		"reach": {"reaches_cleared": 40},
		"companion_chores": {"tortoise": "harvest_stone"},
	})
	var gated_companions: Dictionary = gated.get("companions", {})
	var gated_chores: Dictionary = gated.get("companion_chores", {})
	failed += _assert(bool((gated_companions.get("elaia", {}) as Dictionary).get("joined", false)), "spare-and-relic save still joins elaia")
	failed += _assert(bool((gated_companions.get("bramble", {}) as Dictionary).get("joined", false)), "spare plus 40 clears still joins bramble")
	failed += _assert(not bool((gated_companions.get("puff", {}) as Dictionary).get("joined", true)), "that save does not join puff in the blob")
	failed += _assert(not bool((gated_companions.get("mossback", {}) as Dictionary).get("joined", true)), "migration blob keeps mossback joined false")
	failed += _assert(not gated_companions.has("tortoise") and not gated_chores.has("tortoise"), "gated migrate keeps tortoise off the live maps")
	failed += _assert(str((gated_companions.get("mossback", {}) as Dictionary).get("chore", "")) == "harvest_stone", "gated tortoise chore lands on mossback")
	_quiet_reset(game_state)
	if failed == 0:
		print("SAVE_V16_MIGRATION_OK")
	else:
		print("SAVE_V16_MIGRATION_FAIL: %d" % failed)
	return failed


func join_hooks(tree_root: Window, game_state: Node, save_service: Node) -> int:
	var failed: int = 0
	CompanionRoster.reload()
	_quiet_reset(game_state)
	var reach: Node = tree_root.get_node_or_null("Reach")
	failed += _assert(not bool(game_state.call("companion_joined", "puff")), "puff waits for Elder")
	failed += _assert(not bool(game_state.call("companion_joined", "mossback")), "mossback waits for a reach clear")
	game_state.call("_set_stage", &"elder")
	failed += _assert(bool(game_state.call("companion_joined", "puff")), "Elder joins puff live")
	failed += _assert(not bool(game_state.call("companion_joined", "mossback")), "Elder alone does not join mossback")
	if reach != null:
		reach.set("reaches_cleared", 1)
		game_state.call("notify_companion_reach_progress")
	failed += _assert(bool(game_state.call("companion_joined", "mossback")), "one clear joins mossback live")
	_quiet_reset(game_state)
	var past: Dictionary = {
		"stage_id": "elder",
		"reach": {"reaches_cleared": 3, "deepest_depth": 0, "running": false},
		"companions": {
			"puff": {"joined": false, "level": 1, "chore": "", "gear": {}},
			"mossback": {"joined": false, "level": 1, "chore": "", "gear": {}},
		},
	}
	game_state.call("apply_save_dict", past)
	failed += _assert(bool(game_state.call("companion_joined", "puff")), "Elder save joins puff on load")
	failed += _assert(bool(game_state.call("companion_joined", "mossback")), "cleared save joins mossback on load")
	failed += _hub_body_frame_ok(tree_root, game_state, "puff")
	failed += _hub_body_frame_ok(tree_root, game_state, "mossback")
	_quiet_reset(game_state)
	if failed == 0:
		print("COMPANION_JOIN_HOOKS_OK")
	else:
		print("COMPANION_JOIN_HOOKS_FAIL: %d" % failed)
	return failed


func companion_clips(tree_root: Window, game_state: Node, save_service: Node) -> int:
	var failed: int = 0
	CompanionRoster.reload()
	for actor_id: String in ["puff", "mossback"]:
		var anim_v: Variant = CompanionRoster.row(actor_id).get("anim", {})
		var clips_v: Variant = anim_v.get("clips", {}) if typeof(anim_v) == TYPE_DICTIONARY else {}
		if typeof(clips_v) != TYPE_DICTIONARY:
			failed += _assert(false, "%s anim.clips missing" % actor_id)
			continue
		for clip_name_v: Variant in (clips_v as Dictionary).keys():
			var clip_name: String = str(clip_name_v)
			var clip_v: Variant = (clips_v as Dictionary)[clip_name_v]
			if typeof(clip_v) != TYPE_DICTIONARY:
				continue
			var clip: Dictionary = clip_v as Dictionary
			var dir_path: String = CompanionClips.frame_dir(actor_id, clip_name)
			var disk: int = CompanionClips.count_frames_on_disk(dir_path)
			var declared: int = CompanionClips.declared_frame_count(clip)
			failed += _assert(disk > 0 and ResourceLoader.exists(CompanionClips.frame_path(dir_path, 0)), "%s/%s loads" % [actor_id, clip_name])
			failed += _assert(disk == declared, "%s/%s frames data/disk (%d vs %d)" % [actor_id, clip_name, declared, disk])
			if clip_name == "battle_attack":
				failed += _assert(CompanionClips.hit_frame_index(clip) == 3, "%s attack hit_frame is 3" % actor_id)
				var want_hit: float = CompanionClips.hit_time_sec(clip)
				failed += _assert(is_equal_approx(want_hit, 0.375), "%s attack hit time" % actor_id)
		var idle_path: String = CompanionRoster.battle_pose(actor_id, "idle")
		failed += _assert(idle_path != "" and ResourceLoader.exists(idle_path), "%s battle idle still" % actor_id)
	failed += _companion_clip_hit_in_arena(tree_root, game_state, "puff")
	failed += _companion_clip_hit_in_arena(tree_root, game_state, "mossback")
	var body_packed: PackedScene = load("res://scenes/companion.tscn") as PackedScene
	if body_packed != null:
		game_state.call("_set_stage", &"elder")
		var reach: Node = tree_root.get_node_or_null("Reach")
		if reach != null:
			reach.set("reaches_cleared", 1)
		var moss: Companion = body_packed.instantiate() as Companion
		if moss != null:
			moss.companion_id = "mossback"
			tree_root.add_child(moss)
			failed += _assert(moss.sprite.sprite_frames != null and moss.sprite.sprite_frames.has_animation(&"work_stone"), "mossback work_stone clip registered")
			if moss.sprite.sprite_frames != null and moss.sprite.sprite_frames.has_animation(&"work_stone"):
				failed += _assert(moss.sprite.sprite_frames.get_frame_count(&"work_stone") == 8, "mossback work_stone has 8 frames")
			moss.sprite.play(&"work_stone")
			moss.call("_play_loop", &"work_stone", 1.0, moss.call("actor_work_anim_offset", "work_stone"))
			var work_tex: Texture2D = moss.sprite.sprite_frames.get_frame_texture(&"work_stone", 0) if moss.sprite.sprite_frames != null else null
			failed += _assert(work_tex != null and _texture_has_visible_pixels(work_tex), "mossback work_stone hub clip draws")
			var layout: Dictionary = CompanionClips.layout(CompanionClips.clip_spec("mossback", "work_stone"))
			failed += _assert((layout.get("offset", Vector2.ZERO) as Vector2).is_equal_approx(Vector2(-73, -128)), "mossback work_stone offset from data")
			failed += _assert(moss.sprite.offset.is_equal_approx(Vector2(-73, -128)), "mossback work_stone sprite offset")
			moss.queue_free()
	if failed == 0:
		print("COMPANION_CLIPS_OK")
	else:
		print("COMPANION_CLIPS_FAIL: %d" % failed)
	return failed


func _companion_clip_hit_in_arena(tree_root: Window, game_state: Node, member: String) -> int:
	var failed: int = 0
	game_state.call("reset_for_new_game")
	if not bool(BattleViewScript.open_arena()):
		return _assert(false, "arena opens for %s clip hit" % member)
	var views: Array[Node] = tree_root.get_tree().get_nodes_in_group("battle_overlay")
	if views.is_empty():
		BattleViewScript.close_arena()
		return _assert(false, "arena overlay for %s" % member)
	var view: BattleView = views[0] as BattleView
	view._last_clip_hit_sec = -1.0
	failed += _assert(bool(view.set_fighter_pose(member, "attack")), "%s battle attack clip starts" % member)
	var elapsed: float = 0.0
	while elapsed < 0.55 and view.clip_hit_last_sec() < 0.0:
		view.playback_tick_fighter_clips(0.05)
		elapsed += 0.05
	failed += _assert(view.clip_hit_last_sec() >= 0.0, "%s battle_attack hit_frame fires" % member)
	BattleViewScript.close_arena()
	return failed


func _hub_body_frame_ok(tree_root: Window, game_state: Node, actor_id: String) -> int:
	game_state.call("_set_stage", &"elder")
	var reach: Node = tree_root.get_node_or_null("Reach")
	if reach != null:
		reach.set("reaches_cleared", 1)
	var packed: PackedScene = load("res://scenes/companion.tscn") as PackedScene
	if packed == null:
		return _assert(false, "%s hub scene loads" % actor_id)
	var body: Companion = packed.instantiate() as Companion
	if body == null:
		return _assert(false, "%s hub body instantiates" % actor_id)
	body.companion_id = actor_id
	tree_root.add_child(body)
	body.sprite.play(&"idle_south")
	var tex: Texture2D = body.sprite.sprite_frames.get_frame_texture(&"idle_south", 0) if body.sprite.sprite_frames != null else null
	var ok: bool = _texture_has_visible_pixels(tex)
	body.queue_free()
	return _assert(ok, "%s hub idle_south draws visible pixels" % actor_id)


func _texture_has_visible_pixels(tex: Texture2D) -> bool:
	if tex == null:
		return false
	var img: Image = tex.get_image()
	if img == null or img.is_empty():
		return false
	for y: int in img.get_height():
		for x: int in img.get_width():
			if img.get_pixel(x, y).a > 0.01:
				return true
	return false


func _play_snapshot(game_state: Node) -> Dictionary:
	return {
		"wood": int(game_state.get("wood")),
		"stone": int(game_state.get("stone")),
		"food": int(game_state.get("food")),
		"manashards": int(game_state.get("manashards")),
		"essence": int(game_state.get("essence")),
		"elaia_joined": bool(game_state.call("elaia_in_party")),
		"elaia_area": str(game_state.get("elaia_area")),
		"elaia_x": float(game_state.get("elaia_pos").x),
		"elaia_y": float(game_state.get("elaia_pos").y),
		"elaia_facing": str(game_state.get("elaia_facing")),
		"might": int(game_state.get_node("/root/KeeperStats").call("get_rank", "might")) if game_state.get_node_or_null("/root/KeeperStats") != null else -1,
		"moss_chore": CompanionChores.assignment_of("mossback"),
		"tortoise_chore": CompanionChores.assignment_of("tortoise"),
		"tortoise_name": str(game_state.call("hero_display_name", "tortoise")),
		"elaia_level": int(game_state.call("companion_level", "elaia")),
		"puff_joined": bool(game_state.call("companion_joined", "puff")),
		"moss_joined": bool(game_state.call("companion_joined", "mossback")),
	}


func _join_flags(tree_root: Window, game_state: Node) -> int:
	var failed: int = 0
	failed += _assert(CompanionRoster.canonical_id("tortoise") == "mossback", "tortoise alias is mossback")
	failed += _assert(CompanionRoster.ids().has("mossback") and not CompanionRoster.ids().has("tortoise"), "live roster id is mossback")
	failed += _assert(not CompanionRoster.row("mossback").has("legacy_id"), "mossback data has no tortoise id")
	var companions: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/companions.json"))
	var chores_file: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/companion_chores.json"))
	var schedule_file: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/companion_schedule.json"))
	var chore_map: Dictionary = {}
	if typeof(chores_file) == TYPE_DICTIONARY:
		var raw_chores: Variant = (chores_file as Dictionary).get("assignments", {})
		if typeof(raw_chores) == TYPE_DICTIONARY:
			chore_map = raw_chores
	var schedule_map: Dictionary = {}
	if typeof(schedule_file) == TYPE_DICTIONARY:
		var raw_schedule: Variant = (schedule_file as Dictionary).get("companions", {})
		if typeof(raw_schedule) == TYPE_DICTIONARY:
			schedule_map = raw_schedule
	var data_clean: bool = typeof(companions) == TYPE_DICTIONARY and not (companions as Dictionary).has("tortoise")
	failed += _assert(data_clean and not chore_map.has("tortoise") and not schedule_map.has("tortoise"), "companions, chores, and schedule have no tortoise id")
	failed += _assert(str(game_state.call("hero_display_name", "tortoise")) == "Mossback", "alias display name is Mossback")
	failed += _assert(CompanionChores.assignment_of("tortoise") == CompanionChores.assignment_of("mossback"), "alias chore matches mossback")
	failed += _assert(not bool(game_state.call("companion_joined", "puff")) and not bool(game_state.call("companion_joined", "mossback")), "a fresh game leaves puff and mossback unjoined")
	game_state.set("echo_01_redeemed", true)
	game_state.set("first_relic_crafted", true)
	game_state.set("echo_02_resolved", true)
	game_state.set("echo_02_outcome", "spare")
	var reach: Node = tree_root.get_node_or_null("Reach")
	if reach != null and reach.has_method("reset_for_new_game"):
		reach.call("reset_for_new_game")
	if reach != null:
		reach.set("reaches_cleared", 40)
	failed += _assert(bool(game_state.call("companion_joined", "elaia")), "the relic gate still joins elaia")
	failed += _assert(bool(game_state.call("companion_joined", "bramble")), "spare plus 40 clears still joins bramble")
	failed += _assert(not bool(game_state.call("companion_joined", "puff")), "echo spare and reach do not join puff")
	failed += _assert(bool(game_state.call("companion_joined", "mossback")), "one reach clear joins mossback")
	_quiet_reset(game_state)
	if reach != null and reach.has_method("reset_for_new_game"):
		reach.call("reset_for_new_game")
	WeatherState.reset_default()
	game_state.set("harvest_accum", {})
	game_state.call("set_resource", &"food", 0)
	game_state.call("set_resource", &"stone", 0)
	CompanionChores.clear_forced()
	CompanionChores.grant_online_seconds(40.0)
	failed += _assert(int(game_state.get("food")) == 0 and int(game_state.get("stone")) == 0, "unjoined puff and mossback chores do not pay")
	game_state.call("_set_stage", &"elder")
	if reach != null:
		reach.set("reaches_cleared", 1)
	CompanionChores.grant_online_seconds(40.0)
	var paid_food: int = int(game_state.get("food"))
	var paid_stone: int = int(game_state.get("stone"))
	failed += _assert(paid_food > 0 and paid_stone > 0, "join hooks pay the berry and stone chores (%d food, %d stone)" % [paid_food, paid_stone])
	game_state.call("_set_stage", &"sapling")
	if reach != null:
		reach.set("reaches_cleared", 0)
	CompanionChores.grant_online_seconds(40.0)
	failed += _assert(int(game_state.get("food")) == paid_food and int(game_state.get("stone")) == paid_stone, "dropping below the hooks stops chore payout")
	_quiet_reset(game_state)
	WeatherState.reset_default()
	CompanionChores.clear_forced()
	return failed


func _quiet_reset(game_state: Node) -> void:
	CompanionRoster.clear_test_companions()
	CompanionChores.clear_forced()
	game_state.call("reset_for_new_game")


func _cleanup(game_state: Node) -> void:
	_quiet_reset(game_state)


func _assert(ok: bool, message: String) -> int:
	if ok:
		return 0
	push_error("ROSTER %s" % message)
	print("ROSTER_FAIL: %s" % message)
	return 1
