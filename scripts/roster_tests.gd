extends RefCounted
class_name RosterTests
## Generic roster and save v16. Runnable from the default VERIFY suite and alone.


func generic(tree_root: Window, game_state: Node, save_service: Node) -> int:
	var failed: int = 0
	_quiet_reset(game_state)
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
	failed += _assert(bool((companions.get("elaia", {}) as Dictionary).get("joined", false)), "elaia joined matches the relic gate")
	failed += _assert(not bool((companions.get("puff", {}) as Dictionary).get("joined", false)), "puff stays unjoined without a flag")
	game_state.call("apply_save_dict", migrated)
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
	failed += _assert(int(first.get("elaia_level", 0)) == 1 and not bool(first.get("puff_joined", true)), "levels and puff join flag")
	_quiet_reset(game_state)
	if failed == 0:
		print("SAVE_V16_MIGRATION_OK")
	else:
		print("SAVE_V16_MIGRATION_FAIL: %d" % failed)
	return failed


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
		"elaia_level": int(game_state.call("companion_level", "elaia")),
		"puff_joined": bool(game_state.call("companion_joined", "puff")),
	}


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
