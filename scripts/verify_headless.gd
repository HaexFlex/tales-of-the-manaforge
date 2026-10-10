extends SceneTree
const EchoBattleScript := preload("res://scripts/echo_battle.gd")
const ReachFightScript := preload("res://scripts/reach_fight.gd")
const FightStateScript := preload("res://scripts/battle/fight_state.gd")
const AutoPolicyScript := preload("res://scripts/battle/auto_policy.gd")
const BatchSimScript := preload("res://scripts/battle/batch_sim.gd")
const BattleRngScript := preload("res://scripts/battle/battle_rng.gd")
const BattleResolverScript := preload("res://scripts/battle/resolver.gd")
const BattleViewScript := preload("res://scripts/battle/battle_view.gd")
const BattlePlaybackScript := preload("res://scripts/battle/battle_playback.gd")
## Headless verification: Echo, Forge v2, waypoint freeze, autosaves, SAVE_VERSION 10.
## Hub and Forge scene changes are part of this run (SCENE_TRANSITIONS_OK).
## Regression rule: every bug Haex reports that has been fixed before, or that
## comes back, gets a permanent named test in this default suite (named like
## SCENE_TRANSITIONS_OK). The test drives the real user path and must fail on
## the old buggy build. The living list is in docs/DEVELOPER_NOTES.md.
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

	if _wants_check_only():
		failed += _check_only_load()
		if failed > 0:
			print("CHECK_ONLY_FAIL: %d" % failed)
			quit(1)
		else:
			print("CHECK_ONLY_OK")
			quit(0)
		return

	# Workbench stand. The full suite still runs this near the end.
	# MANAFORGE_WORKBENCH=1 skips every other assertion.
	if OS.get_environment("MANAFORGE_WORKBENCH") == "1":
		var bench_failed: int = await _workbench_reach(tree_root, save_service)
		if bench_failed > 0:
			print("WORKBENCH_REACH_FAIL: %d" % bench_failed)
			quit(1)
		else:
			quit(0)
		return

	# Same hub↔Forge check the full suite runs near the end.
	# MANAFORGE_SCENE_TRANSITIONS=1 skips every other assertion.
	if OS.get_environment("MANAFORGE_SCENE_TRANSITIONS") == "1":
		var hop_failed: int = await _scene_transitions(tree_root, game_state, save_service)
		if hop_failed > 0:
			print("SCENE_TRANSITIONS_FAIL: %d" % hop_failed)
			quit(1)
		else:
			quit(0)
		return

	# Isolated Pass J clock. The full suite still runs this test near the end.
	# MANAFORGE_DURATION_ONLY=1 skips every other assertion.
	if OS.get_environment("MANAFORGE_DURATION_ONLY") == "1":
		var dur_failed: int = _forge_duration_ticks(tree_root, game_state, backpack)
		if dur_failed > 0:
			print("DURATION_FAIL: %d assertion(s) failed" % dur_failed)
			quit(1)
		else:
			print("DURATION_OK")
			quit(0)
		return

	if OS.get_environment("MANAFORGE_DEBUG_STRIP") == "1":
		var strip_failed: int = _debug_stripped_ok()
		if strip_failed > 0:
			print("DEBUG_STRIPPED_FAIL: %d" % strip_failed)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_SPEED_BUTTON") == "1":
		var speed_only: int = await _speed_button_ok(tree_root, game_state, save_service, game_audio)
		if speed_only > 0:
			print("SPEED_BUTTON_FAIL: %d" % speed_only)
			quit(1)
		else:
			quit(0)
		return

	# Echo 2 hub arch regression. The full suite still runs it after the adventure batch.
	# MANAFORGE_ECHO2_PORTAL=1 skips every other assertion.
	if OS.get_environment("MANAFORGE_ECHO2_PORTAL") == "1":
		var echo2_only: int = await _echo2_portal_visible(tree_root, game_state, save_service)
		if echo2_only > 0:
			print("ECHO2_PORTAL_VISIBLE_FAIL: %d" % echo2_only)
			quit(1)
		else:
			quit(0)
		return

	# Board tease. The full suite still runs it after the Echo 2 arch check.
	# MANAFORGE_BOARD_TEASE=1 skips every other assertion.
	if OS.get_environment("MANAFORGE_BOARD_TEASE") == "1":
		var tease_only: int = await _expedition_board_tease(tree_root, game_state, save_service)
		if tease_only > 0:
			print("EXPEDITION_BOARD_TEASE_FAIL: %d" % tease_only)
			quit(1)
		else:
			quit(0)
		return

	# Experimental reach snapshots. The full suite still runs this near the end.
	# MANAFORGE_DEBUG_SNAPSHOTS=1 skips every other assertion.
	if OS.get_environment("MANAFORGE_DEBUG_SNAPSHOTS") == "1":
		var snaps_only: int = await _debug_snapshots_reach(tree_root, game_state, save_service)
		if snaps_only > 0:
			print("DEBUG_SNAPSHOTS_REACH_FAIL: %d" % snaps_only)
			quit(1)
		else:
			quit(0)
		return

	# Bundle 1 regressions. The full suite runs them after the reach checks.
	# Battle Bundle 2 data checks. The full suite runs them after the Bundle 1 regressions.
	if OS.get_environment("MANAFORGE_BEAST_DATA") == "1":
		var _beast_data_only: int = _beast_data(tree_root)
		if _beast_data_only > 0:
			print("BEAST_DATA_FAIL: %d" % _beast_data_only)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_SPAWN_DATA") == "1":
		var _spawn_data_only: int = _spawn_data(tree_root)
		if _spawn_data_only > 0:
			print("SPAWN_DATA_FAIL: %d" % _spawn_data_only)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_SPAWN_ROLLER") == "1":
		var _spawn_roller_only: int = _spawn_roller(tree_root)
		if _spawn_roller_only > 0:
			print("SPAWN_ROLLER_FAIL: %d" % _spawn_roller_only)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_SPAWN_SEED") == "1":
		var _spawn_seed_only: int = _spawn_seed(tree_root)
		if _spawn_seed_only > 0:
			print("SPAWN_SEED_FAIL: %d" % _spawn_seed_only)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_STRINGS_V4") == "1":
		var _strings_adventure_v4_only: int = _strings_adventure_v4(tree_root)
		if _strings_adventure_v4_only > 0:
			print("STRINGS_ADVENTURE_V4_FAIL: %d" % _strings_adventure_v4_only)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_REACH_MIX") == "1":
		var mix_only: int = _reach_mix_reload(tree_root, game_state, save_service)
		if mix_only > 0:
			print("REACH_MIX_RELOAD_FAIL: %d" % mix_only)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_SAVE_NEWER") == "1":
		var newer_only: int = _save_newer_refused(tree_root, game_state, save_service)
		if newer_only > 0:
			print("SAVE_NEWER_REFUSED_FAIL: %d" % newer_only)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_TURN_ORDER") == "1":
		var order_only: int = _reach_turn_order()
		if order_only > 0:
			print("REACH_TURN_ORDER_FAIL: %d" % order_only)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_SNAPSHOT_MIGRATE") == "1":
		var snap_mig_only: int = _debug_snapshots_migrate(tree_root, game_state, save_service)
		if snap_mig_only > 0:
			print("DEBUG_SNAPSHOTS_MIGRATE_FAIL: %d" % snap_mig_only)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_REACH") == "1":
		var reach_only: int = _reach_checks(tree_root, game_state, save_service)
		if reach_only > 0:
			print("REACH_FAIL: %d" % reach_only)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_SAVE_V14_INVENTORY") == "1":
		var inv_only: int = _save_v14_inventory_merge(tree_root, game_state, save_service)
		if inv_only > 0:
			print("SAVE_V14_INVENTORY_MERGE_FAIL: %d" % inv_only)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_SAVE_V14_HOME") == "1":
		var home_only: int = _save_v14_home(tree_root, game_state, save_service)
		if home_only > 0:
			print("SAVE_V14_HOME_FAIL: %d" % home_only)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_SAVE_V14_FROM_MAIN") == "1":
		var from_main_only: int = _save_v14_from_main(tree_root, game_state, save_service)
		if from_main_only > 0:
			print("SAVE_V14_FROM_MAIN_FAIL: %d" % from_main_only)
			quit(1)
		else:
			quit(0)
		return

	# Bundle 3 resolver. The full suite runs these at the end.
	if OS.get_environment("MANAFORGE_RESOLVER_DICE") == "1":
		var resolver_dice_only: int = _resolver_dice()
		if resolver_dice_only > 0:
			print("RESOLVER_DICE_FAIL: %d" % resolver_dice_only)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_RESOLVER_MARGIN") == "1":
		var resolver_margin_only: int = _resolver_margin()
		if resolver_margin_only > 0:
			print("RESOLVER_MARGIN_FAIL: %d" % resolver_margin_only)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_RESOLVER_DIE_TABLE") == "1":
		var resolver_die_only: int = _resolver_die_table()
		if resolver_die_only > 0:
			print("RESOLVER_DIE_TABLE_FAIL: %d" % resolver_die_only)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_RESOLVER_SEED") == "1":
		var resolver_seed_only: int = _resolver_seed()
		if resolver_seed_only > 0:
			print("RESOLVER_SEED_FAIL: %d" % resolver_seed_only)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_RESOLVER_STATE") == "1":
		var resolver_state_only: int = _resolver_state_roundtrip()
		if resolver_state_only > 0:
			print("RESOLVER_STATE_ROUNDTRIP_FAIL: %d" % resolver_state_only)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_RESOLVER") == "1":
		var resolver_all_only: int = _resolver_all()
		if resolver_all_only > 0:
			print("RESOLVER_FAIL: %d" % resolver_all_only)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_RESOLVER_TURN_ORDER") == "1":
		var resolver_order_only: int = _resolver_turn_order()
		if resolver_order_only > 0:
			print("RESOLVER_TURN_ORDER_FAIL: %d" % resolver_order_only)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_RESOLVER_ROWS") == "1":
		var resolver_rows_only: int = _resolver_rows()
		if resolver_rows_only > 0:
			print("RESOLVER_ROWS_FAIL: %d" % resolver_rows_only)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_RESOLVER_TARGETING") == "1":
		var resolver_targeting_only: int = _resolver_targeting()
		if resolver_targeting_only > 0:
			print("RESOLVER_TARGETING_FAIL: %d" % resolver_targeting_only)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_RESOLVER_BRACE") == "1":
		var resolver_brace_only: int = _resolver_brace()
		if resolver_brace_only > 0:
			print("RESOLVER_BRACE_FAIL: %d" % resolver_brace_only)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_RESOLVER_SHIELD_ORDER") == "1":
		var resolver_shield_only: int = _resolver_shield_order()
		if resolver_shield_only > 0:
			print("RESOLVER_SHIELD_ORDER_FAIL: %d" % resolver_shield_only)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_RESOLVER_POISON") == "1":
		var resolver_poison_only: int = _resolver_poison_refresh()
		if resolver_poison_only > 0:
			print("RESOLVER_POISON_REFRESH_FAIL: %d" % resolver_poison_only)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_RESOLVER_TWISTS") == "1":
		var resolver_twists_only: int = _resolver_twists()
		if resolver_twists_only > 0:
			print("RESOLVER_TWISTS_FAIL: %d" % resolver_twists_only)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_RESOLVER_BOSS") == "1":
		var resolver_boss_only: int = _resolver_boss()
		if resolver_boss_only > 0:
			print("RESOLVER_BOSS_FAIL: %d" % resolver_boss_only)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_RESOLVER_SALVE") == "1":
		var resolver_salve_only: int = _resolver_salve()
		if resolver_salve_only > 0:
			print("RESOLVER_SALVE_FAIL: %d" % resolver_salve_only)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_AUTO_FLEE_KO_ZERO") == "1":
		var auto_flee_only: int = _auto_flee_ko_zero()
		if auto_flee_only > 0:
			print("AUTO_FLEE_KO_ZERO_FAIL: %d" % auto_flee_only)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_RESOLVER_LOG") == "1":
		var resolver_log_only: int = _resolver_log()
		if resolver_log_only > 0:
			print("RESOLVER_LOG_FAIL: %d" % resolver_log_only)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_AUTO_POLICY") == "1":
		var auto_policy_only: int = _auto_policy()
		if auto_policy_only > 0:
			print("AUTO_POLICY_FAIL: %d" % auto_policy_only)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_SIM_PARITY") == "1":
		var sim_parity_only: int = _sim_parity()
		if sim_parity_only > 0:
			print("SIM_PARITY_FAIL: %d" % sim_parity_only)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_RESOLVER_PERF") == "1":
		var resolver_perf_only: int = _resolver_perf()
		if resolver_perf_only > 0:
			print("RESOLVER_PERF_FAIL: %d" % resolver_perf_only)
			quit(1)
		else:
			quit(0)
		return

	# Battle arena shell. The full suite runs these at the end.
	if OS.get_environment("MANAFORGE_BATTLE_SHELL") == "1":
		var battle_shell_only: int = await _battle_shell(tree_root, game_state, save_service)
		if battle_shell_only > 0:
			print("BATTLE_SHELL_FAIL: %d" % battle_shell_only)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_BATTLE_ECHO") == "1":
		var battle_echo_only: int = await _battle_echo_exclusive(tree_root, game_state, save_service)
		if battle_echo_only > 0:
			print("BATTLE_ECHO_EXCLUSIVE_FAIL: %d" % battle_echo_only)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_BATTLE_PLATES") == "1":
		var battle_plates_only: int = await _battle_plates(tree_root, game_state, save_service)
		if battle_plates_only > 0:
			print("BATTLE_PLATES_FAIL: %d" % battle_plates_only)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_BATTLE_MENU") == "1":
		var battle_menu_only: int = await _battle_menu(tree_root, game_state, save_service)
		if battle_menu_only > 0:
			print("BATTLE_MENU_FAIL: %d" % battle_menu_only)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_BATTLE_TARGET_REACH") == "1":
		var battle_target_only: int = await _battle_target_reach(tree_root, game_state, save_service)
		if battle_target_only > 0:
			print("BATTLE_TARGET_REACH_FAIL: %d" % battle_target_only)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_BATTLE_STRIKE_FOR_ME") == "1":
		var battle_strike_only: int = await _battle_strike_for_me(tree_root, game_state, save_service)
		if battle_strike_only > 0:
			print("BATTLE_STRIKE_FOR_ME_FAIL: %d" % battle_strike_only)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_BATTLE_PLAYBACK") == "1":
		var battle_playback_only: int = await _battle_playback(tree_root, game_state, save_service)
		if battle_playback_only > 0:
			print("BATTLE_PLAYBACK_FAIL: %d" % battle_playback_only)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_BATTLE_ART") == "1":
		var battle_art_only: int = await _battle_art(tree_root, game_state, save_service)
		if battle_art_only > 0:
			print("BATTLE_ART_FAIL: %d" % battle_art_only)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_BATTLE_AUDIO_SOLE_CALLER") == "1":
		var battle_audio_only: int = _battle_audio_sole_caller(tree_root, game_audio)
		if battle_audio_only > 0:
			print("BATTLE_AUDIO_SOLE_CALLER_FAIL: %d" % battle_audio_only)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_HEADLESS_SILENT") == "1":
		var headless_silent_only: int = await _headless_silent(tree_root, game_state, save_service, game_audio)
		if headless_silent_only > 0:
			print("HEADLESS_SILENT_FAIL: %d" % headless_silent_only)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_ELAIA_ONLY") == "1":
		var elaia_failed: int = await _elaia_join_check(tree_root, game_state, backpack)
		if elaia_failed > 0:
			print("ELAIA_FAIL: %d assertion(s) failed" % elaia_failed)
			quit(1)
		else:
			print("ELAIA_OK")
			quit(0)
		return

	if OS.get_environment("MANAFORGE_PORTRAIT_SWITCH") == "1":
		var portrait_failed: int = await _portrait_switch_forge(tree_root, game_state, save_service)
		if portrait_failed > 0:
			print("PORTRAIT_SWITCH_FORGE_FAIL: %d" % portrait_failed)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_FORGE_ARCH") == "1":
		var arch_failed: int = await _forge_arch_draw_order(tree_root)
		if arch_failed > 0:
			print("FORGE_ARCH_DRAW_ORDER_FAIL: %d" % arch_failed)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_FORGE_ENTRY") == "1":
		var entry_failed: int = await _forge_entry_one_click(tree_root, game_state, save_service)
		if entry_failed > 0:
			print("FORGE_ENTRY_ONE_CLICK_FAIL: %d" % entry_failed)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_FORGE_YSORT") == "1":
		var ysort_failed: int = await _forge_ysort(tree_root)
		if ysort_failed > 0:
			print("FORGE_YSORT_FAIL: %d" % ysort_failed)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_MANATREE_DOOR") == "1":
		var door_clear_failed: int = await _manatree_door_clear(tree_root, game_state, save_service)
		if door_clear_failed > 0:
			print("MANATREE_DOOR_CLEAR_FAIL: %d" % door_clear_failed)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_COMPANION_DOOR") == "1":
		var companion_failed: int = await _companion_door_transfer(tree_root, game_state, save_service)
		if companion_failed > 0:
			print("COMPANION_DOOR_TRANSFER_FAIL: %d" % companion_failed)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_DOOR_ACTIVE") == "1":
		var active_failed: int = await _door_transfer_active_only(tree_root, game_state, save_service)
		if active_failed > 0:
			print("DOOR_TRANSFER_ACTIVE_ONLY_FAIL: %d" % active_failed)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_WORKBENCH_CLICK") == "1":
		var click_failed: int = await _workbench_click_panel(tree_root)
		if click_failed > 0:
			print("WORKBENCH_CLICK_PANEL_FAIL: %d" % click_failed)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_WORKBENCH_PAUSE") == "1":
		var pause_failed: int = await _workbench_panel_no_pause(tree_root, game_state)
		if pause_failed > 0:
			print("WORKBENCH_PANEL_NO_PAUSE_FAIL: %d" % pause_failed)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_WORKBENCH_WISP") == "1":
		var wisp_vis_failed: int = await _workbench_wisp_visible(tree_root, game_state, save_service)
		if wisp_vis_failed > 0:
			print("WORKBENCH_WISP_VISIBLE_FAIL: %d" % wisp_vis_failed)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_FORGED_ITEM") == "1":
		var forged_failed: int = _forged_item_any_character(tree_root)
		if forged_failed > 0:
			print("FORGED_ITEM_ANY_CHARACTER_FAIL: %d" % forged_failed)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_WORKBENCH_ROUTE") == "1":
		var route_failed: int = _workbench_north_route()
		if route_failed > 0:
			print("WORKBENCH_NORTH_ROUTE_FAIL: %d" % route_failed)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_CRAFT_DURATION") == "1":
		var duration_label_failed: int = await _craft_duration_labels(tree_root, game_state, backpack)
		if duration_label_failed > 0:
			print("CRAFT_DURATION_LABEL_FAIL: %d" % duration_label_failed)
			quit(1)
		else:
			quit(0)
		return

	if OS.get_environment("MANAFORGE_BATCH_REFUND") == "1":
		var refund_failed: int = await _batch_refund(tree_root, game_state, save_service, backpack, content_strings)
		if refund_failed > 0:
			print("BATCH_REFUND_FAIL: %d" % refund_failed)
			quit(1)
		else:
			print("BATCH_REFUND_OK")
			quit(0)
		return

	if OS.get_environment("MANAFORGE_BATCH_OFFLINE") == "1":
		var offline_failed: int = await _batch_offline(tree_root, game_state, save_service, backpack, content_strings)
		if offline_failed > 0:
			print("BATCH_OFFLINE_FAIL: %d" % offline_failed)
			quit(1)
		else:
			print("BATCH_OFFLINE_OK")
			quit(0)
		return

	if OS.get_environment("MANAFORGE_BATCH_ASCEND") == "1":
		var ascend_failed: int = await _batch_ascend_wipe(tree_root, game_state, save_service, backpack, content_strings)
		if ascend_failed > 0:
			print("BATCH_ASCEND_WIPE_FAIL: %d" % ascend_failed)
			quit(1)
		else:
			print("BATCH_ASCEND_WIPE_OK")
			quit(0)
		return

	if OS.get_environment("MANAFORGE_BATCH_MIGRATION") == "1":
		var migration_failed: int = await _batch_migration(tree_root, game_state, save_service, backpack)
		if migration_failed > 0:
			print("BATCH_MIGRATION_FAIL: %d" % migration_failed)
			quit(1)
		else:
			print("BATCH_MIGRATION_OK")
			quit(0)
		return

	failed += _assert(int(game_state.get("stages_data").size()) == 5, "expected 5 stages")
	var jobs: Node = tree_root.get_node_or_null("ForgeJobs")
	if jobs:
		jobs.call("set_dev_speed_override", 1.0)
		jobs.call("set_autosave_enabled", false)
	failed += _assert(jobs != null, "ForgeJobs autoload missing")
	failed += _assert(int(game_state.get("upgrades_data").size()) == 10, "expected 10 fruit upgrades")
	failed += _assert(int(save_service.get("SAVE_VERSION")) == 14, "SAVE_VERSION should be 14")
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
	failed += _debug_stripped_ok()
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
	failed += _assert(FileAccess.file_exists("res://assets/art/manatree/native/manatree_sapling.png"), "sapling texture")
	failed += _assert(FileAccess.file_exists("res://assets/art/manatree/native/manatree_young.png"), "young texture")
	failed += _assert(FileAccess.file_exists("res://assets/art/manatree/native/manatree_mature.png"), "mature texture")
	failed += _assert(FileAccess.file_exists("res://assets/art/manatree/native/manatree_elder.png"), "elder texture")
	failed += _assert(FileAccess.file_exists("res://assets/art/manatree/native/manatree_ancient.png"), "ancient texture")
	failed += _assert(FileAccess.file_exists("res://assets/art/manatree/native/manatree_meta.json"), "manatree_meta.json")
	var meta_file := FileAccess.open("res://assets/art/manatree/native/manatree_meta.json", FileAccess.READ)
	failed += _assert(meta_file != null, "open manatree_meta")
	if meta_file:
		var meta_parsed: Variant = JSON.parse_string(meta_file.get_as_text())
		meta_file.close()
		failed += _assert(typeof(meta_parsed) == TYPE_DICTIONARY, "meta dict")
		if typeof(meta_parsed) == TYPE_DICTIONARY:
			var mroot: Dictionary = meta_parsed
			failed += _assert(str(mroot.get("version", "")) == "v0.1.9-A2-native-glow-only", "meta version v0.1.9-A2-native-glow-only")
			var stages_m: Variant = mroot.get("stages", [])
			failed += _assert(typeof(stages_m) == TYPE_ARRAY and (stages_m as Array).size() == 5, "meta 5 stages")
			if typeof(stages_m) == TYPE_ARRAY:
				for entry: Variant in stages_m:
					if typeof(entry) != TYPE_DICTIONARY:
						continue
					var ed: Dictionary = entry
					if str(ed.get("stage_id", "")) == "ancient":
						var asz: Variant = ed.get("size", [])
						failed += _assert(typeof(asz) == TYPE_ARRAY and int((asz as Array)[0]) == 1024 and int((asz as Array)[1]) == 1024, "meta ancient frame 1024")
						failed += _assert(int(ed.get("frames", 0)) == 8, "ancient strip has 8 frames")
						failed += _assert(absf(float(ed.get("display_scale", 0.0)) - 1.0) < 0.01, "ancient display_scale 1")
						var ancient_strip: Texture2D = load("res://assets/art/manatree/native/anim/manatree_ancient_strip.png") as Texture2D
						var elder_strip: Texture2D = load("res://assets/art/manatree/native/anim/manatree_elder_strip.png") as Texture2D
						failed += _assert(ancient_strip != null and ancient_strip.get_width() == 8192 and ancient_strip.get_height() == 1024, "ancient strip 8192x1024")
						failed += _assert(elder_strip != null and elder_strip.get_width() == 8192 and elder_strip.get_height() == 1024, "elder strip 8192x1024")

	# Art harvest nodes
	failed += _assert(ResourceLoader.exists("res://assets/art/props/harvest_tree.png"), "harvest_tree art")
	failed += _assert(ResourceLoader.exists("res://assets/art/props/native/harvest_stone.png"), "harvest_stone art")
	failed += _assert(ResourceLoader.exists("res://assets/art/props/harvest_berry.png"), "harvest_berry art")
	failed += _assert(FileAccess.file_exists("res://assets/art/props/native/berry_harvest_node.png"), "berry_harvest_node art")
	failed += _assert(FileAccess.file_exists("res://assets/art/props/echo_portal_hub.png"), "echo_portal_hub art")
	failed += _assert(FileAccess.file_exists("res://assets/art/ui/icons/hud_character.png"), "hud character icon")

	# Art v0.1.13 — cleaned inbox forest + Keeper south walk
	failed += _assert(FileAccess.file_exists("res://assets/art/hub/trees/ring_tree_large_01.png"), "ring_tree_large_01")
	failed += _assert(FileAccess.file_exists("res://assets/art/hub/trees/ring_tree_large_03.png"), "ring_tree_large_03")
	failed += _assert(FileAccess.file_exists("res://assets/art/hub/trees/ring_tree_medium_01.png"), "ring_tree_medium_01")
	failed += _assert(FileAccess.file_exists("res://assets/art/hub/trees/ring_tree_slim_01.png"), "ring_tree_slim_01")
	failed += _assert(FileAccess.file_exists("res://assets/art/hub/bushes/ring_bush_big_01.png"), "ring_bush_big_01")
	failed += _assert(FileAccess.file_exists("res://assets/art/hub/bushes/ring_bush_big_03.png"), "ring_bush_big_03")
	failed += _assert(FileAccess.file_exists("res://assets/art/hub/bushes/ring_bush_small_01.png"), "ring_bush_small_01")
	failed += _assert(FileAccess.file_exists("res://assets/art/hub/bushes/ring_bush_small_03.png"), "ring_bush_small_03")
	failed += _assert(FileAccess.file_exists("res://assets/art/hub/hub_deco_meta.json"), "hub_deco_meta.json")
	failed += _assert(FileAccess.file_exists("res://assets/art/keeper/idle/south/keeper_idle_south_0001.png"), "keeper idle south frame")
	failed += _assert(FileAccess.file_exists("res://assets/art/keeper/idle/north/keeper_idle_north_0001.png"), "keeper idle north frame")
	failed += _assert(FileAccess.file_exists("res://assets/art/keeper/idle/east/keeper_idle_east_0001.png"), "keeper idle east frame")
	failed += _assert(FileAccess.file_exists("res://assets/art/keeper/idle/west/keeper_idle_west_0001.png"), "keeper idle west frame")
	failed += _assert(FileAccess.file_exists("res://assets/art/keeper/keeper_walk_south_0001.png"), "keeper walk_south 1")
	failed += _assert(FileAccess.file_exists("res://assets/art/keeper/keeper_walk_south_0009.png"), "keeper walk_south 9")
	failed += _assert(FileAccess.file_exists("res://assets/art/keeper/keeper_walk_south.png"), "keeper walk_south strip")
	var walk_strip: Texture2D = load("res://assets/art/keeper/keeper_walk_south.png") as Texture2D
	failed += _assert(walk_strip != null, "load walk_south strip")
	if walk_strip:
		failed += _assert(walk_strip.get_width() == 1152 and walk_strip.get_height() == 128, "walk strip 1152x128 (got %dx%d)" % [walk_strip.get_width(), walk_strip.get_height()])
	var tree_big: Texture2D = load("res://assets/art/hub/trees/ring_tree_large_01.png") as Texture2D
	failed += _assert(tree_big != null and tree_big.get_width() == 320 and tree_big.get_height() == 400, "ring_tree_large_01 is 320x400")
	var old_live_idle := "res://assets/art/keeper/" + "keeper_idle_" + "south.png"
	failed += _assert(not FileAccess.file_exists(old_live_idle), "old keeper idle left the live art folder")
	## Big Trees.png and keeper_inbox/ move to legacy with Art. Do not assert them here.
	## docs/, Assets upload/, and assets/library/ are .gdignored, so res:// cannot see them.
	failed += _assert(FileAccess.file_exists(ProjectSettings.globalize_path("res://assets/library/raw_refs/Big Trees.jpg")), "library raw_refs JPG")
	failed += _assert(FileAccess.file_exists(ProjectSettings.globalize_path("res://docs/ASSETS_UPLOAD.md")), "ASSETS_UPLOAD docs")
	var inbox_dir := DirAccess.open(ProjectSettings.globalize_path("res://Assets upload"))
	failed += _assert(inbox_dir != null, "Assets upload dir")
	if inbox_dir:
		inbox_dir.list_dir_begin()
		var loose: int = 0
		var entry: String = inbox_dir.get_next()
		while entry != "":
			if entry != "." and entry != ".." and entry != "README.md":
				loose += 1
			entry = inbox_dir.get_next()
		inbox_dir.list_dir_end()
		failed += _assert(loose == 0, "Assets upload empty after ship (got %d loose)" % loose)
	failed += _assert(FileAccess.file_exists(ProjectSettings.globalize_path("res://Assets upload/README.md")), "Assets upload README only")
	var project_text: String = FileAccess.get_file_as_string("res://project.godot")
	failed += _assert(project_text.find("res://scenes/title_screen.tscn") >= 0, "main scene is the title screen")
	failed += _assert(
		str(ProjectSettings.get_setting("application/run/main_scene", "")) == "res://scenes/title_screen.tscn",
		"ProjectSettings boots the title screen"
	)
	save_service.call("delete_save")
	var title_packed: PackedScene = load("res://scenes/title_screen.tscn") as PackedScene
	failed += _assert(title_packed != null, "title_screen.tscn loads")
	if title_packed:
		var title: Node = title_packed.instantiate()
		tree_root.add_child(title)
		await process_frame
		var cont: Button = title.get_node_or_null("Menu/BtnContinue") as Button
		var new_btn: Button = title.get_node_or_null("Menu/BtnNewGame") as Button
		var load_btn: Button = title.get_node_or_null("Menu/BtnLoad") as Button
		var opt_btn: Button = title.get_node_or_null("Menu/BtnOptions") as Button
		var quit_btn: Button = title.get_node_or_null("Menu/BtnQuit") as Button
		failed += _assert(cont != null and not cont.visible, "Continue hidden with no save")
		failed += _assert(new_btn != null and new_btn.visible, "New Game on title")
		failed += _assert(load_btn != null and load_btn.visible, "Load on title")
		failed += _assert(opt_btn != null and opt_btn.visible, "Options on title")
		failed += _assert(quit_btn != null and quit_btn.visible, "Quit on title")
		failed += _assert(title.get_node_or_null("Background") is TextureRect, "title background")
		title.queue_free()
		await process_frame
		save_service.set("boot_intent", "auto")
		save_service.set("boot_slot", 0)
		game_state.call("set_resource", &"wood", 42)
		game_state.call("set_resource", &"stone", 7)
		game_state.call("set_resource", &"food", 5)
		game_state.call("set_resource", &"manashards", 11)
		game_state.call("set_resource", &"essence", 9)
		save_service.set("boot_intent", "new")
		var boot_packed: PackedScene = load("res://scenes/main.tscn") as PackedScene
		var boot_live: Node = boot_packed.instantiate() if boot_packed else null
		if boot_live:
			tree_root.add_child(boot_live)
			await process_frame
			var wood_lbl: Label = boot_live.get_node_or_null("HUD/Panel/IconRow/WoodChip/NumWood") as Label
			var stone_lbl: Label = boot_live.get_node_or_null("HUD/Panel/IconRow/StoneChip/NumStone") as Label
			var food_lbl: Label = boot_live.get_node_or_null("HUD/Panel/IconRow/FoodChip/NumFood") as Label
			var shard_lbl: Label = boot_live.get_node_or_null("HUD/Panel/IconRow/ShardChip/NumShards") as Label
			var ess_lbl: Label = boot_live.get_node_or_null("HUD/Panel/IconRow/EssenceChip/NumEssence") as Label
			failed += _assert(int(game_state.get("wood")) == 0 and int(game_state.get("essence")) == 0, "new game boot clears resources")
			failed += _assert(wood_lbl != null and wood_lbl.text == "0", "new game HUD wood is 0 before harvest")
			failed += _assert(stone_lbl != null and stone_lbl.text == "0", "new game HUD stone is 0")
			failed += _assert(food_lbl != null and food_lbl.text == "0", "new game HUD food is 0")
			failed += _assert(shard_lbl != null and shard_lbl.text == "0", "new game HUD shards are 0")
			failed += _assert(ess_lbl != null and ess_lbl.text == "0", "new game HUD essence is 0")
			failed += _assert(str(game_state.get("stage_id")) == "sapling", "new game boot is sapling")
			boot_live.free()
			await process_frame
		paused = false
		save_service.set("boot_intent", "auto")
		save_service.set("boot_slot", 0)
	var deco_meta_f := FileAccess.open("res://assets/art/hub/hub_deco_meta.json", FileAccess.READ)
	failed += _assert(deco_meta_f != null, "open hub_deco_meta")
	if deco_meta_f:
		var deco_parsed: Variant = JSON.parse_string(deco_meta_f.get_as_text())
		deco_meta_f.close()
		failed += _assert(typeof(deco_parsed) == TYPE_DICTIONARY, "hub deco meta dict")
		if typeof(deco_parsed) == TYPE_DICTIONARY:
			var deco_root: Dictionary = deco_parsed
			failed += _assert(str(deco_root.get("version", "")) == "v0.3.0-hub-v3", "hub deco meta v0.3.0-hub-v3")
			var families: Dictionary = deco_root.get("families", {}) as Dictionary
			var tree_n: int = (families.get("ring_tree_large", []) as Array).size() + (families.get("ring_tree_medium", []) as Array).size() + (families.get("ring_tree_slim", []) as Array).size()
			var bush_n: int = (families.get("ring_bush_big", []) as Array).size() + (families.get("ring_bush_small", []) as Array).size()
			failed += _assert(tree_n == 6, "hub deco trees 6 (got %d)" % tree_n)
			failed += _assert(bush_n == 6, "hub deco bushes 6 (got %d)" % bush_n)
			failed += _assert((families.get("grass_tuft", []) as Array).size() == 9, "hub deco grass tufts 9")
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
	# Confirm written save_version is 10 and no growth in payload
	var slot1_path: String = str(save_service.call("slot_path", 1))
	var s1f := FileAccess.open(slot1_path, FileAccess.READ)
	failed += _assert(s1f != null, "read slot 1")
	if s1f:
		var s1root: Variant = JSON.parse_string(s1f.get_as_text())
		s1f.close()
		if typeof(s1root) == TYPE_DICTIONARY:
			failed += _assert(int((s1root as Dictionary).get("save_version", 0)) == 14, "written save_version 14")
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
	failed += _assert(int(game_state.call("get_upgrade_cost", "shard_sight")) == 800, "sight cost 800*(rank+1)")
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
	failed += _assert(int(save_service.get("SAVE_VERSION")) == 14, "SAVE_VERSION stays 14 with fruit_committed")
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
			failed += _assert(hud.get_node_or_null("BackpackPanel/CraftScroll/CraftList") == null, "backpack has no handcraft list")
			failed += _assert(hud.get_node_or_null("BackpackPanel/HandcraftTitle") == null, "backpack has no handcraft title")
			failed += _assert(hud.get_node_or_null("BenchPanel/CraftScroll/CraftList") != null, "bench CraftList missing")
			failed += _assert(inst.get_node_or_null("World/KeepersBench") != null, "KeepersBench missing")
			failed += _assert(inst.get_node_or_null("Paths/ToBench") is Line2D, "ToBench path missing")
			failed += _assert(hud.get_node_or_null("CarePanel/CareGrowCosts/FertilizerIcon") != null, "Grow FertilizerIcon missing")
			failed += _assert(hud.get_node_or_null("CarePanel/CareGrowCosts/EssenceIcon") != null, "Grow EssenceIcon missing")
			failed += _assert(FileAccess.file_exists(ProjectSettings.globalize_path("res://docs/ART_NEEDED_BACKPACK.md")), "ART_NEEDED_BACKPACK.md")
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
					failed += _assert(abs(float(hub.get("map_width_mult", 0)) - 3.375) < 0.01, "MAP_WIDTH_MULT 3.375")
					failed += _assert(abs(float(hub.get("map_height_mult", 0)) - 5.25) < 0.01, "MAP_HEIGHT_MULT 5.25")
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
	failed += _assert(ResourceLoader.exists("res://assets/audio/mus_hub_forest_haex.mp3"), "hub bed mp3")
	var legacy_ignore: String = ProjectSettings.globalize_path("res://assets/library/legacy/.gdignore")
	failed += _assert(FileAccess.file_exists(legacy_ignore), "legacy folder is gdignored")
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
	failed += _assert(int(game_state.call("param_float", "WISP_PULSE_SEC", 0.0)) == 20, "WISP_PULSE_SEC 20")
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
	# Continuous: one wisp is 1/20s. Remainder stays under a whole unit until 20s.
	failed += _assert(abs(float(game_state.call("get_wisp_pulse_sec")) - 20.0) < 0.01, "wisp interval base 20")
	game_state.call("unassign_wisp", 1)
	game_state.call("apply_wisp_pulses", 19.0)
	failed += _assert(int(game_state.get("wood")) == wood0, "one wisp banks nothing before 20s")
	game_state.call("apply_wisp_pulses", 1.0)
	failed += _assert(int(game_state.get("wood")) == wood0 + 1, "one wisp banks 1 wood at 20s")
	var ranks_h: Dictionary = game_state.get("upgrade_ranks")
	ranks_h["wisp_haste"] = 3
	game_state.set("upgrade_ranks", ranks_h)
	failed += _assert(abs(float(game_state.call("get_wisp_pulse_sec")) - 14.0) < 0.01, "haste rank3 → 14s")
	ranks_h["wisp_haste"] = 5
	game_state.set("upgrade_ranks", ranks_h)
	failed += _assert(abs(float(game_state.call("get_wisp_pulse_sec")) - 10.0) < 0.01, "haste min 10s")
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

	# Two wisps share the manatree accumulator: 1 yield per 20s each.
	# 9.9s × 2 = 0.99 (no bank). +0.2s crosses 1.0 → +1 shard.
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
	failed += _assert(int(game_state.get("manashards")) == shards0, "no manashards before the shared unit")
	game_state.call("apply_wisp_pulses", 0.2)
	failed += _assert(int(game_state.get("manashards")) == shards0 + 1, "two wisps bank 1 manashard near 10s")
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
			failed += _assert(abs(play.x - 4320.0) < 0.5 and abs(play.y - 3780.0) < 0.5, "play area 4320x3780 (got %s)" % play)
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
		var ground_tm: TileMap = live.get_node_or_null("Ground") as TileMap
		failed += _assert(ground_tm != null, "ground tilemap")
		if ground_tm:
			var path_cells: int = 0
			for cell: Vector2i in ground_tm.get_used_cells(0):
				var atlas: Vector2i = ground_tm.get_cell_atlas_coords(0, cell)
				if atlas.y != 0:
					path_cells += 1
			failed += _assert(path_cells == 0, "clearing ground is grass only (non-grass cells %d)" % path_cells)
		var decor_nodes: Array[Node] = live.get_tree().get_nodes_in_group("forest_decor")
		failed += _assert(decor_nodes.size() >= 20 and decor_nodes.size() <= 60, "sparse flora decor (got %d)" % decor_nodes.size())
		var decor_bad: int = 0
		var decor_on_landmark: int = 0
		for decor_node: Node in decor_nodes:
			var dspr: Sprite2D = null
			for dch: Node in decor_node.get_children():
				if dch is Sprite2D:
					dspr = dch
					break
			var dpath: String = ""
			if dspr and dspr.texture:
				dpath = str(dspr.texture.resource_path)
			if dpath.find("/hub/ground/grass_tuft_") < 0 or dpath.find("stone_") >= 0 or dpath.find("/nodes/") >= 0 or dpath.find("harvest") >= 0:
				decor_bad += 1
			if decor_node is Node2D and live.has_method("decor_spot_allowed"):
				if not bool(live.call("decor_spot_allowed", (decor_node as Node2D).global_position)):
					decor_on_landmark += 1
		failed += _assert(decor_bad == 0, "decor is flora grass only (bad %d)" % decor_bad)
		failed += _assert(decor_on_landmark == 0, "decor stays off node footprints (hits %d)" % decor_on_landmark)
		var ground_deco: Array[Node] = live.get_tree().get_nodes_in_group("hub_ground_deco")
		failed += _assert(ground_deco.size() == 150, "hub ground deco count (got %d)" % ground_deco.size())
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
					failed += _assert(sframes.get_frame_count(&"walk_south") == 8, "walk_south frame count")
					failed += _assert(sframes.get_frame_count(&"idle_south") == 12, "idle_south frame count")
					failed += _assert(sframes.has_animation(&"idle_north") and sframes.get_frame_count(&"idle_north") == 12, "idle_north frames")
					failed += _assert(sframes.has_animation(&"idle_east") and sframes.get_frame_count(&"idle_east") == 12, "idle_east frames")
					failed += _assert(sframes.has_animation(&"idle_west") and sframes.get_frame_count(&"idle_west") == 12, "idle_west frames")
					failed += _keeper_clip_asserts(sframes)
				failed += _assert(str(kspr.get("animation")) == "idle_south", "idle faces south at boot")
			if live_keeper.has_method("move_to"):
				var kpos: Vector2 = live_keeper.get("global_position") as Vector2
				live_keeper.call("move_to", kpos + Vector2(0, 180), null)
				for _i: int in range(10):
					await physics_frame
				if kspr:
					failed += _assert(str(kspr.get("animation")) == "walk_south", "south move uses walk_south (got %s)" % str(kspr.get("animation")))
					failed += _assert((kspr.get("offset") as Vector2).distance_to(Vector2(-64, -128)) < 0.5, "walk keeps the idle foot offset")
			if live_keeper.has_method("preview_station_work"):
				live_keeper.call("preview_station_work", "anvil")
				await physics_frame
				if kspr:
					failed += _assert(str(kspr.get("animation")) == "station_work_north", "station work faces north (got %s)" % str(kspr.get("animation")))
				if live_keeper.has_method("clear_work_preview"):
					live_keeper.call("clear_work_preview")
				if live_keeper.has_method("halt"):
					live_keeper.call("halt")
			failed += _keeper_work_spot_asserts()
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
			var expect_r: float = 0.0
			if mana and mana.has_method("wisp_orbit_radius"):
				expect_r = float(mana.call("wisp_orbit_radius"))
			failed += _assert(abs(node_r - expect_r) < 0.01, "stacked orbit uses the trunk radius (got %s want %s)" % [node_r, expect_r])
			var orbit_jobs: Node = get_root().get_node_or_null("ForgeJobs")
			if orbit_jobs:
				orbit_jobs.call("debug_set_wisp_orbit_phase", 0.4)
			var behind: int = 0
			var front: int = 0
			for wo2: Node in wisp_orbs:
				if wo2.has_method("place_on_shared_orbit"):
					wo2.call("place_on_shared_orbit")
				if int(wo2.get("z_index")) < 0:
					behind += 1
				elif int(wo2.get("z_index")) > 0:
					front += 1
			failed += _assert(behind == 1 and front == 1, "shared orbit puts one wisp behind and one in front")
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
		game_state.call("set_resource", &"essence", 200)
		backpack.call("set_count", "fertilizer", 45)
		test_hud.call("show_care_menu")
		await process_frame
		var pay_young: Button = test_hud.get_node_or_null("CarePanel/ActionBand/PayButton") as Button
		failed += _assert(pay_young != null and pay_young.visible and not pay_young.disabled, "sapling Grow is ready")
		if pay_young:
			pay_young.pressed.emit()
		await process_frame
		var confirm_early: Control = test_hud.get_node_or_null("AncientGrowConfirm") as Control
		failed += _assert(str(game_state.get("stage_id")) == "young", "non-ancient Grow stays one click")
		failed += _assert(confirm_early == null or not confirm_early.visible, "non-ancient Grow skips the Ancient dialog")
		failed += _assert(str(game_state.call("try_grow_stage")) == "ok", "direct grow to mature")
		failed += _assert(str(game_state.call("try_grow_stage")) == "ok", "direct grow to elder")
		failed += _assert(str(game_state.get("stage_id")) == "elder", "staged at elder before Ancient confirm")
		test_hud.call("show_care_menu")
		await process_frame
		var pay_elder: Button = test_hud.get_node_or_null("CarePanel/ActionBand/PayButton") as Button
		failed += _assert(pay_elder != null and pay_elder.visible and not pay_elder.disabled, "elder Grow is ready")
		if pay_elder:
			pay_elder.pressed.emit()
		await process_frame
		var confirm: Control = test_hud.get_node_or_null("AncientGrowConfirm") as Control
		failed += _assert(confirm != null and confirm.visible, "Ancient Grow opens the confirm")
		failed += _assert(str(game_state.get("stage_id")) == "elder", "confirm does not grow yet")
		var confirm_body: Label = test_hud.get_node_or_null("AncientGrowConfirm/Body") as Label
		var minutes_ui: int = int(game_state.call("ancient_duration_minutes"))
		failed += _assert(confirm_body != null and str(confirm_body.text).find("%d minutes" % minutes_ui) >= 0, "confirm body minutes from duration")
		failed += _assert(confirm_body != null and str(confirm_body.text).find("{minutes}") < 0, "confirm body token filled")
		var confirm_title: Label = test_hud.get_node_or_null("AncientGrowConfirm/Title") as Label
		failed += _assert(confirm_title != null and str(confirm_title.text) == "Grow to Ancient?", "confirm title on the dialog")
		test_hud.call("hide_ancient_grow_confirm")
		await process_frame
		failed += _assert(confirm != null and not confirm.visible, "confirm can close")
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
		failed += _assert(pre_hint != null and str(pre_hint.text).find("still water") < 0, "care hint hides tree_water_ancient_note")
		failed += _assert(pre_hint != null and str(pre_hint.text).find("Fruit waits") < 0, "care hint does not say the Fruit waits")
		var timer_label: Label = test_hud.get_node_or_null("AncientCountdown") as Label
		failed += _assert(timer_label != null and str(timer_label.text).begins_with("Fruit falls in "), "HUD timer uses tree_ancient_timer_label (got %s)" % (str(timer_label.text) if timer_label else ""))
		failed += _assert(timer_label != null and str(timer_label.text).find("PLACEHOLDER") < 0, "HUD timer is not the placeholder")
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
		failed += _assert(int(test_hud.call("get_fruit_confirm_step")) == 1, "fruit modal is one step")
		failed += _assert(not bool(game_state.get("fruit_committed")), "opening the box does not commit")
		failed += _assert(paused == false, "world running during fruit confirm")
		failed += _assert(not bool(test_hud.call("is_ascension_shop_open")), "shop closed during fruit modal")
		failed += _assert(not bool(test_hud.call("is_care_open")), "care closed during fruit confirm")
		failed += _assert(bool(game_audio.call("did_play", &"sfx_ui_confirm")), "fruit intent plays sfx_ui_confirm")
		failed += _assert(not bool(game_audio.call("did_play", &"sfx_fruit_harvest")), "intent does not harvest")
		var harvest_modal: Button = test_hud.get_node_or_null("FruitConfirmPanel/ConfirmYes") as Button
		var cancel_modal: Button = test_hud.get_node_or_null("FruitConfirmPanel/ConfirmNo") as Button
		var fruit_body: Label = test_hud.get_node_or_null("FruitConfirmPanel/ConfirmBody") as Label
		failed += _assert(harvest_modal != null and str(harvest_modal.text) == "Harvest", "one box Harvest")
		failed += _assert(cancel_modal != null and str(cancel_modal.text).find("watering") >= 0, "one box Keep watering")
		failed += _assert(fruit_body != null and str(fruit_body.text).find("still water") >= 0 and str(fruit_body.text).find("must Ascend") >= 0, "one box holds both copies")
		failed += _assert(test_hud.get_node_or_null("FruitConfirmPanel/UpgradeList") == null, "no Buy list on fruit modal")
		test_hud.call("cancel_fruit_confirm")
		await process_frame
		failed += _assert(int(test_hud.call("get_fruit_confirm_step")) == 0, "Keep watering closes the box")
		failed += _assert(not bool(game_state.get("fruit_committed")), "Keep watering does not commit")
		test_hud.call("open_fruit_confirm")
		await process_frame
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
			var icon_rows: int = 0
			for shop_row: Node in list_node.get_children():
				var asc_icon: TextureRect = shop_row.find_child("AscIcon", true, false) as TextureRect
				if asc_icon and asc_icon.texture and str(asc_icon.texture.resource_path).find("icon_asc_") >= 0 and asc_icon.custom_minimum_size == Vector2(32, 32):
					icon_rows += 1
			failed += _assert(list_node.get_child_count() == 10 and icon_rows == 10, "every blessing row has a 32 icon (%d/%d)" % [icon_rows, list_node.get_child_count()])
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
		test_hud.call("_on_shop_close")
		await process_frame
		failed += _assert(paused == false, "close shop returns to play")
		failed += _assert(not bool(game_state.get("fruit_committed")), "close clears the harvest lock")
		failed += _assert(not bool(game_state.get("fruit_harvested_pending_ascend")), "close clears pending ascend")
		failed += _assert(bool(game_state.get("fruit_ready")), "fruit is ready again after cancel")
		failed += _assert(not bool(test_hud.call("is_ascension_shop_open")), "close hides shop")
		failed += _assert(bool(game_audio.call("is_hub_music_playing")), "hub BGM stays on after shop Close")
		var reopen: Button = test_hud.get_node_or_null("Panel/AscensionReopenButton") as Button
		failed += _assert(reopen != null and not reopen.visible, "reopen chip hidden after cancel")
		var water_after_cancel: Dictionary = game_state.call("apply_water_pulse")
		failed += _assert(bool(water_after_cancel.get("ok", false)), "water works after cancelling the shop")
		test_hud.call("show_care_menu")
		await process_frame
		failed += _assert(paused == false, "care after cancel stays in play")
		failed += _assert(not bool(test_hud.call("is_ascension_shop_open")), "cancel does not reopen the shop")
		failed += _assert(bool(test_hud.call("is_care_open")), "care opens after cancel")
		var harvest_again: int = int(game_state.call("harvest_fruit"))
		failed += _assert(harvest_again >= 1, "fruit can be harvested again")
		failed += _assert(bool(game_state.get("fruit_committed")), "second harvest commits again")
		game_state.call("cancel_fruit_commit")
		failed += _assert(not bool(game_state.get("fruit_committed")) and bool(game_state.get("fruit_ready")), "cancel_fruit_commit restores play")
		test_hud.queue_free()
		paused = false
		await process_frame
		game_state.call("reset_for_new_game")

	# --- SYSTEMS v0.4.0: backpack, handcraft, tools, Grow, Keep Tools, can shard_roll ×2 ---
	failed += _assert(int((backpack.get("recipes_data") as Array).size()) == 10, "10 handcraft recipes")
	failed += _assert(int((backpack.get("items_data") as Array).size()) == 17, "17 backpack items")
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
	failed += _assert(str(content_strings.call("get_text", "btn_backpack")) == "Inventory", "btn_backpack")
	failed += _assert(str(content_strings.call("get_text", "backpack_open")) == "Inventory", "backpack_open")
	failed += _assert(str(content_strings.call("get_text", "backpack_title")) == "Inventory", "backpack_title")
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
	failed += _assert(str(content_strings.call("get_text", "thornbow_craft_cost")).find("Stone Fragments") >= 0, "thornbow cost says Stone Fragments")
	var bow_eq: Node = tree_root.get_node_or_null("Equipment")
	var bow_lines: PackedStringArray = bow_eq.call("recipe_ingredient_lines", "thornbow") if bow_eq else PackedStringArray()
	var bow_text: String = ", ".join(bow_lines)
	failed += _assert(bow_text.find("Stone Fragments") >= 0 and bow_text.find("Wood Planks") >= 0, "thornbow row have/need (%s)" % bow_text)
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
	failed += _assert(str(content_strings.call("get_text", "upgrade_keep_tools_cost_default")).find("4000") >= 0, "keep_tools cost default 4000")
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
	failed += _assert(int(game_state.call("get_upgrade_cost", "keep_tools")) == 4000, "Keep Tools costs 4000 shards")
	for asc_id: String in ["deep_roots", "forager", "green_thumb", "shard_sight", "keeper_stride", "wisp_haste", "bonus_wisp", "keep_tools", "keep_forge_intermediates", "keep_forge_jobs"]:
		var asc_art: String = str(game_state.call("upgrade_art_path", asc_id))
		failed += _assert(asc_art.ends_with("icon_asc_%s.png" % asc_id), "ascension icon %s" % asc_id)
	failed += _assert(not bool(game_state.call("can_buy_upgrade", "keep_tools")), "Keep Tools unaffordable at 0 shards")
	game_state.call("set_resource", &"manashards", 4000)
	failed += _assert(bool(game_state.call("can_buy_upgrade", "keep_tools")), "Keep Tools affordable at 4000")
	if int(game_state.call("get_upgrade_cost", "keep_tools")) == 4000 and str(content_strings.call("get_text", "upgrade_keep_tools_cost_default")).find("4000") >= 0 and bool(game_state.call("can_buy_upgrade", "keep_tools")):
		print("KEEP_TOOLS_COST_OK")

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
	failed += _assert(abs(float(game_state.call("get_keeper_harvest_pulse_sec", &"wood")) - 1.0) < 0.01, "axe sets wood interval to 1s")
	failed += _assert(abs(float(game_state.call("get_keeper_harvest_pulse_sec", &"stone")) - 2.0) < 0.01, "no pickaxe: stone interval 2s")
	failed += _assert(abs(float(game_state.call("get_wisp_pulse_sec")) - 20.0) < 0.01, "tools do not change wisp interval")

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
	# Can doubles (roll + 0.5): U{1,3}+0.5 → {3,5,7}
	var ranks_ss: Dictionary = game_state.get("upgrade_ranks")
	ranks_ss["shard_sight"] = 1
	game_state.set("upgrade_ranks", ranks_ss)
	var ss_i: int = 0
	while ss_i < 12:
		var ss_pulse: Dictionary = game_state.call("apply_water_pulse")
		var ss_shards: int = int(ss_pulse.get("shards", 0))
		failed += _assert(ss_shards == 3 or ss_shards == 5 or ss_shards == 7, "can*(roll+0.5) in {3,5,7} got %d" % ss_shards)
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
		var fert_icon: TextureRect = pack_hud.get_node_or_null("CarePanel/CareGrowCosts/FertilizerIcon") as TextureRect
		var ess_icon: TextureRect = pack_hud.get_node_or_null("CarePanel/CareGrowCosts/EssenceIcon") as TextureRect
		var pack_icon: TextureRect = pack_hud.get_node_or_null("Panel/BackpackButton/BackpackIcon") as TextureRect
		failed += _assert(fert_icon != null and fert_icon.texture != null, "Grow fertilizer sprite")
		failed += _assert(ess_icon != null and ess_icon.texture != null, "Grow essence sprite")
		failed += _assert(pack_icon != null and pack_icon.texture != null, "Backpack button sprite")
		pack_hud.call("open_backpack")
		await process_frame
		failed += _assert(bool(pack_hud.call("is_backpack_open")), "backpack opens")
		failed += _assert(pack_hud.get_node_or_null("BackpackPanel/CraftScroll/CraftList") == null, "open backpack stays inventory")
		pack_hud.call("open_bench_panel")
		await process_frame
		failed += _assert(bool(pack_hud.call("is_bench_open")), "bench panel opens from the station")
		failed += _assert(not bool(pack_hud.call("is_backpack_open")), "bench closes the backpack")
		var craft_box: VBoxContainer = pack_hud.get_node_or_null("BenchPanel/CraftScroll/CraftList") as VBoxContainer
		failed += _assert(craft_box != null and craft_box.get_child_count() >= 14, "bench craft rows built (%d)" % (craft_box.get_child_count() if craft_box else 0))
		var pack_metrics: Dictionary = pack_hud.call("get_backpack_layout_metrics")
		var bench_metrics: Dictionary = pack_hud.call("get_bench_layout_metrics")
		failed += _assert(bool(bench_metrics.get("fits", false)), "craft scroll width ≤ bench panel")
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
		failed += _assert(pack_hud.get_node_or_null("BackpackPanel/TabRow/TabRaw") != null, "backpack tab Raw")
		failed += _assert(pack_hud.get_node_or_null("BackpackPanel/TabRow/TabRefined") != null, "backpack tab Refined")
		failed += _assert(pack_hud.get_node_or_null("BackpackPanel/TabRow/TabTools") != null, "backpack tab Tools")
		failed += _assert(pack_hud.get_node_or_null("BackpackPanel/TabRow/TabWeapons") != null, "backpack tab Weapons")
		failed += _assert(pack_hud.get_node_or_null("BackpackPanel/TabRow/TabRelics") != null, "backpack tab Relics")
		failed += _assert(pack_hud.get_node_or_null("BackpackPanel/TabRow/TabParts") == null, "parts tab removed")
		var pack_btn: Button = pack_hud.get_node_or_null("Panel/BackpackButton") as Button
		failed += _assert(pack_btn != null and str(pack_btn.text) == "" and str(pack_btn.tooltip_text).find("Inventory") >= 0, "HUD inventory sprite button")
		pack_hud.call("close_bench")
		pack_hud.call("close_backpack")
		await process_frame
		failed += _assert(not bool(pack_hud.call("is_backpack_open")), "backpack closes")
		failed += _assert(not bool(pack_hud.call("is_bench_open")), "bench closes")
		pack_hud.queue_free()
		await process_frame
		game_state.call("reset_for_new_game")

	# --- Character sheet, Runestones, Flintblade, Manatree visual scale (Haex greenlight) ---
	var keeper_stats: Node = tree_root.get_node_or_null("KeeperStats")
	var equipment: Node = tree_root.get_node_or_null("Equipment")
	failed += _assert(keeper_stats != null, "KeeperStats autoload missing")
	failed += _assert(equipment != null, "Equipment autoload missing")
	if keeper_stats != null and equipment != null:
		game_state.call("reset_for_new_game")
		failed += _assert(int(save_service.get("SAVE_VERSION")) == 14, "SAVE_VERSION is 14")
		failed += _assert(str(content_strings.call("get_text", "char_sheet_title")) == "Keeper", "char_sheet_title")
		failed += _assert(str(content_strings.call("get_text", "char_sheet_open")) == "Character", "char_sheet_open")
		failed += _assert(str(content_strings.call("get_text", "hud_btn_character")) == "Character", "hud_btn_character")
		failed += _assert(str(content_strings.call("get_text", "char_sheet_hotkey_hint")) == "C — Character", "char_sheet_hotkey_hint")
		failed += _assert(str(content_strings.call("get_text", "gear_title")) == "Gear", "gear_title")
		failed += _assert(str(content_strings.call("get_text", "gear_empty")) == "No gear yet.", "gear_empty")
		failed += _assert(str(content_strings.call("get_text", "gear_hint")).find("Backpack") >= 0, "gear_hint")
		failed += _assert(str(content_strings.call("get_text", "stone_sword_craft_cost")).find("30") >= 0, "stone_sword_craft_cost")
		failed += _assert(str(content_strings.call("get_text", "char_sheet_stats_header")) == "Stats", "char_sheet_stats_header")
		failed += _assert(str(content_strings.call("get_text", "stat_might_tooltip")) == "Physical Attack", "stat_might_tooltip")
		failed += _assert(str(content_strings.call("get_text", "stat_base_note")) == "Starts at 5 — Runestones raise it further.", "stat_base_note")
		failed += _assert(str(content_strings.call("get_text", "stat_value_breakdown")) == "{base} + {ranks}", "stat_value_breakdown")
		failed += _assert(str(content_strings.call("get_text", "stat_fate_tooltip")).find("rare finds") >= 0, "stat_fate_tooltip")
		failed += _assert(str(content_strings.call("get_text", "runestone_ok")).find("grows stronger") >= 0, "runestone_ok")
		failed += _assert(str(content_strings.call("get_text", "runestone_confirm")).find("{cost}") >= 0, "runestone_confirm")
		failed += _assert(str(content_strings.call("get_text", "runestone_bank_hint")).find("Ascension") >= 0, "runestone_bank_hint")
		failed += _assert(str(content_strings.call("get_text", "runestone_cant_afford")) == "Not enough Manashards", "runestone_cant_afford")
		failed += _assert(str(content_strings.call("get_text", "equip_bare_stone")) == "Bare Stone", "equip_bare_stone")
		failed += _assert(str(content_strings.call("get_text", "equip_locked")) == "Locked", "equip_locked")
		failed += _assert(str(content_strings.call("get_text", "equip_locked_relic")).find("Forge Key") >= 0, "equip_locked_relic")
		failed += _assert(str(content_strings.call("get_text", "equip_locked_armor")).find("Forge") >= 0, "equip_locked_armor")
		failed += _assert(str(content_strings.call("get_text", "equip_locked_hint")).find("not open") >= 0, "equip_locked_hint")
		failed += _assert(str(content_strings.call("get_text", "equip_unequip_ok")).find("Put away") >= 0, "equip_unequip_ok")
		failed += _assert(str(content_strings.call("get_text", "weapon_rod_name")) == "Weapon Rod", "weapon_rod_name")
		failed += _assert(str(content_strings.call("get_text", "stone_sword_name")) == "Flintblade", "stone_sword_name")
		failed += _assert(str(content_strings.call("get_text", "stone_sword_tooltip")).find("flint") >= 0, "stone_sword_tooltip")
		failed += _assert(str(content_strings.call("get_text", "weapon_rod")) == "Weapon Rod", "weapon_rod alias")
		failed += _assert(str(content_strings.call("get_text", "stone_sword")) == "Stone Sword", "stone_sword id string")
		var stat_order: Array = keeper_stats.get("STAT_ORDER")
		failed += _assert(stat_order.size() == 7, "seven combat stats")
		failed += _assert(str(stat_order[0]) == "might" and str(stat_order[6]) == "fate", "stat order might..fate")
		failed += _assert(int(keeper_stats.get("STAT_BASE_START")) == 5, "STAT_BASE_START is 5")
		failed += _assert(int(keeper_stats.call("stat_base_start")) == 5, "stat base start is 5")
		for stat_need: String in ["might", "arcana", "resilience", "ward", "vitality", "swiftness", "fate"]:
			failed += _assert(int(keeper_stats.call("get_rank", stat_need)) == 0, "new game %s rank is 0" % stat_need)
			failed += _assert(int(keeper_stats.call("get_base", stat_need)) == 5, "new game %s base is 5" % stat_need)
		failed += _assert(int(keeper_stats.call("get_next_cost", "might")) == 100, "first runestone cost 100")
		keeper_stats.call("set_rank", "might", 1)
		failed += _assert(int(keeper_stats.call("get_next_cost", "might")) == 165, "second point costs 165")
		keeper_stats.call("set_rank", "might", 2)
		failed += _assert(int(keeper_stats.call("get_next_cost", "might")) == 272, "third point costs 272")
		keeper_stats.call("set_rank", "might", 3)
		failed += _assert(int(keeper_stats.call("get_next_cost", "might")) == 449, "fourth point costs 449")
		keeper_stats.call("set_rank", "might", 4)
		failed += _assert(int(keeper_stats.call("get_next_cost", "might")) == 741, "fifth point costs 741")
		keeper_stats.call("set_rank", "might", 0)
		failed += _assert(int(keeper_stats.call("power_per_rank")) == 1, "stat power +1 per rank")
		failed += _assert(not bool(keeper_stats.call("affects_gather", "fate")), "fate does not affect gather")
		failed += _assert(not bool(keeper_stats.call("affects_wisps", "fate")), "fate does not affect wisps")
		failed += _assert(not bool(keeper_stats.call("affects_craft", "fate")), "fate does not affect craft")
		var grant_before: float = float(game_state.call("active_harvest_factor"))
		var pulse_before: float = float(game_state.call("get_wisp_pulse_sec"))
		var fert_before: float = float(backpack.call("get_fertilizer_craft_cost_mult"))
		keeper_stats.call("set_rank", "fate", 12)
		failed += _assert(abs(float(game_state.call("active_harvest_factor")) - grant_before) < 0.001, "fate rank leaves gather factor")
		failed += _assert(abs(float(game_state.call("get_wisp_pulse_sec")) - pulse_before) < 0.01, "fate rank leaves wisp pulse")
		failed += _assert(abs(float(backpack.call("get_fertilizer_craft_cost_mult")) - fert_before) < 0.01, "fate rank leaves craft mult")
		keeper_stats.call("set_rank", "fate", 0)
		game_state.call("set_resource", &"manashards", 99)
		failed += _assert(str(keeper_stats.call("try_buy", "might")) == "cant_afford", "runestone denies 99")
		failed += _assert(int(keeper_stats.call("get_rank", "might")) == 0, "rank unchanged when short")
		game_state.call("set_resource", &"manashards", 100)
		failed += _assert(str(keeper_stats.call("try_buy", "might")) == "ok", "runestone buys might")
		failed += _assert(int(keeper_stats.call("get_rank", "might")) == 1, "might rank 1 after one buy")
		failed += _assert(int(keeper_stats.call("get_base", "might")) == 6, "might base is 5 + 1")
		failed += _assert(int(game_state.get("manashards")) == 0, "100 shards spent")
		failed += _assert(int(keeper_stats.call("get_next_cost", "might")) == 165, "next point costs 165 after buy")
		failed += _assert(int(keeper_stats.call("get_next_cost", "arcana")) == 100, "other stats stay at first cost")
		var slot_order: Array = equipment.get("SLOT_ORDER")
		failed += _assert(slot_order.size() == 10, "ten equipment slots")
		failed += _assert(bool(equipment.call("is_slot_unlocked", "weapon")), "weapon slot unlocked")
		failed += _assert(not bool(equipment.call("is_slot_unlocked", "relic")), "relic stays locked")
		var locked_slots: int = 0
		for slot_name: Variant in slot_order:
			if not bool(equipment.call("is_slot_unlocked", str(slot_name))):
				locked_slots += 1
		failed += _assert(locked_slots == 9, "nine slots locked at start")
		failed += _assert(str(equipment.call("slot_lock_short", "relic")) == "Locked", "relic lock chip")
		failed += _assert(str(equipment.call("slot_lock_hint", "relic")) == "Relic locked — needs a Forge Key.", "relic lock hint")
		failed += _assert(str(equipment.call("slot_lock_hint", "head")) == "Not yet — the Forge still sleeps.", "armor lock hint")
		failed += _assert(str(equipment.call("item_display_name", "stone_sword")) == "Flintblade", "stone_sword display id")
		failed += _assert(not backpack.call("is_known_item", "weapon_rod"), "weapon rod is not a backpack item")
		failed += _assert((backpack.call("get_recipe_def", "weapon_rod") as Dictionary).is_empty(), "weapon rod recipe is not backpack")
		var rod_ings: Dictionary = equipment.call("get_recipe_ingredients", "weapon_rod")
		failed += _assert(int(rod_ings.get("wooden_planks", 0)) == 10, "weapon rod is 10 planks")
		failed += _assert(str(equipment.call("item_display_name", "weapon_rod")) == "Weapon Rod", "weapon rod name")
		var sword_ings: Dictionary = equipment.call("get_recipe_ingredients", "stone_sword")
		failed += _assert(int(sword_ings.get("stone_fragments", 0)) == 30, "stone sword 30 fragments")
		failed += _assert(int(sword_ings.get("weapon_rod", 0)) == 1, "stone sword 1 weapon rod")
		failed += _assert(not backpack.call("is_known_item", "stone_sword"), "sword is not a backpack item")
		game_state.call("set_resource", &"wood", 30)
		for _i: int in range(10):
			backpack.call("try_craft", "wooden_planks")
		failed += _assert(int(backpack.call("get_count", "wooden_planks")) == 10, "10 planks for the rod")
		failed += _assert(str(equipment.call("try_craft", "weapon_rod")) == "ok", "craft weapon rod")
		failed += _assert(int(equipment.call("unequipped_count", "weapon_rod")) == 1, "rod in gear inventory")
		failed += _assert(int(backpack.call("get_count", "weapon_rod")) == 0, "rod stays out of the backpack")
		failed += _assert(int(backpack.call("get_count", "wooden_planks")) == 0, "planks spent")
		backpack.call("set_count", "stone_fragments", 30)
		failed += _assert(str(equipment.call("try_craft", "stone_sword")) == "ok", "craft stone sword")
		failed += _assert(int(equipment.call("unequipped_count", "weapon_rod")) == 0, "rod spent into the sword")
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
		failed += _assert(int(equipment.call("total_for", "might")) == 8, "base 6 + gear 2 = 8")
		failed += _assert(int(equipment.call("preview_gear_bonus", "might", "stone_sword")) == 2, "preview keeps sword might")
		failed += _assert(str(equipment.call("try_equip_to_slot", "stone_sword", "head")) == "locked", "sword does not open the head slot")
		failed += _assert(str(equipment.call("try_craft", "stone_sword")) == "unique", "second sword blocked")
		failed += _assert(str(equipment.call("try_unequip", "weapon")) == "ok", "unequip sword")
		failed += _assert(str(equipment.call("try_equip_to_slot", "stone_sword", "relic")) == "locked", "sword refuses relic")
		failed += _assert(str(equipment.call("try_equip_to_slot", "stone_sword", "head")) == "locked", "sword refuses the head slot")
		failed += _assert(str(equipment.call("equipped_id", "weapon")) == "", "weapon empty after refusals")
		failed += _assert(str(equipment.call("try_equip_to_slot", "stone_sword", "weapon")) == "ok", "drag-equip onto weapon")
		failed += _assert(bool(equipment.call("grant_item", "weapon_rod")), "spare rod in gear bag")
		backpack.call("set_count", "wooden_planks", 4)
		game_state.set("fruit_committed", true)
		game_state.set("fruit_harvested_pending_ascend", true)
		game_state.call("set_resource", &"manashards", 80)
		game_state.call("ascend")
		failed += _assert(int(game_state.get("manashards")) == 0, "ascend still wipes manashards")
		failed += _assert(int(keeper_stats.call("get_rank", "might")) == 1, "might persists through ascend")
		failed += _assert(int(keeper_stats.call("get_base", "might")) == 6, "ascend keeps might base at 6")
		failed += _assert(int(keeper_stats.call("get_rank", "fate")) == 0, "fate rank stays 0 through ascend")
		failed += _assert(int(keeper_stats.call("get_base", "fate")) == 5, "fate base stays 5 through ascend")
		failed += _assert(str(equipment.call("equipped_id", "weapon")) == "stone_sword", "sword persists through ascend")
		failed += _assert(int(equipment.call("unequipped_count", "weapon_rod")) == 1, "gear rod persists through ascend")
		failed += _assert(int(backpack.call("get_count", "wooden_planks")) == 0, "ascend still wipes backpack planks")
		failed += _assert(int(backpack.call("get_count", "weapon_rod")) == 0, "rod is not a backpack stack")
		var save_payload: Dictionary = game_state.call("to_save_dict")
		failed += _assert(typeof(save_payload.get("keeper_stats", null)) == TYPE_DICTIONARY, "save writes keeper_stats")
		failed += _assert(int((save_payload.get("keeper_stats", {}) as Dictionary).get("might", -1)) == 1, "save keeps might rank")
		failed += _assert(typeof(save_payload.get("equipment_equipped", null)) == TYPE_DICTIONARY, "save writes equipment_equipped")
		failed += _assert(str((save_payload.get("equipment_equipped", {}) as Dictionary).get("weapon", "")) == "stone_sword", "save keeps equipped sword")
		failed += _assert(typeof(save_payload.get("gear_inventory", null)) == TYPE_DICTIONARY, "save writes gear_inventory")
		failed += _assert(int((save_payload.get("gear_inventory", {}) as Dictionary).get("weapon_rod", 0)) == 1, "save keeps gear rod")
		failed += _assert(bool((save_payload.get("equipment_unlocked", {}) as Dictionary).get("weapon", false)), "save unlocks weapon")
		failed += _assert(not bool((save_payload.get("equipment_unlocked", {}) as Dictionary).get("relic", true)), "save keeps relic locked")
		failed += _assert(bool(save_service.call("save_game", 6)), "save slot 6 stats")
		game_state.call("reset_for_new_game")
		failed += _assert(int(keeper_stats.call("get_rank", "might")) == 0, "new game ranks start at 0")
		failed += _assert(int(keeper_stats.call("get_base", "arcana")) == 5, "new game arcana base is 5")
		failed += _assert(str(equipment.call("equipped_id", "weapon")) == "", "new game clears gear")
		failed += _assert(bool(save_service.call("load_game", 6)), "load slot 6 stats")
		failed += _assert(int(keeper_stats.call("get_rank", "might")) == 1, "loaded might rank")
		failed += _assert(int(keeper_stats.call("get_base", "might")) == 6, "loaded might base is 5 + 1")
		failed += _assert(str(equipment.call("equipped_id", "weapon")) == "stone_sword", "loaded sword")
		failed += _assert(int(equipment.call("unequipped_count", "weapon_rod")) == 1, "loaded gear rod")
		var legacy: Dictionary = save_payload.duplicate(true)
		legacy.erase("keeper_stats")
		legacy.erase("equipment")
		legacy.erase("equipment_unlocked")
		legacy.erase("equipment_equipped")
		legacy.erase("gear_inventory")
		game_state.call("apply_save_dict", legacy)
		failed += _assert(int(keeper_stats.call("get_rank", "might")) == 0, "legacy save without stats ranks at 0")
		failed += _assert(int(keeper_stats.call("get_base", "fate")) == 5, "legacy save fate displays 5")
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
		failed += _assert(sap_sprite != null and abs(sap_sprite.scale.x - 1.0) < 0.01, "sapling sprite scale 1")
		failed += _assert(sap_sprite != null and sap_sprite.hframes == 8, "sapling anim 8 frames")
		game_state.set("stage_id", &"ancient")
		scale_tree.call("_refresh_visual")
		failed += _assert(sap_sprite != null and abs(sap_sprite.scale.x - 1.0) < 0.01 and abs(sap_sprite.scale.y - 1.0) < 0.01, "ancient sprite scale 1")
		for stage_name: String in ["sapling", "young", "mature", "elder", "ancient"]:
			game_state.set("stage_id", StringName(stage_name))
			scale_tree.call("_refresh_visual")
			var expect_door: Dictionary = {
				"sapling": Vector2(62, 102),
				"young": Vector2(150, 255),
				"mature": Vector2(368, 536),
				"elder": Vector2(512, 916),
				"ancient": Vector2(504, 936),
			}
			var door_px: Vector2 = scale_tree.call("door_floor_px")
			failed += _assert(door_px.distance_to(expect_door[stage_name]) < 0.51, "door floor %s (got %s)" % [stage_name, door_px])
			failed += _assert(abs(sap_sprite.scale.x - 1.0) < 0.01, "native scale 1 on %s" % stage_name)
			var frame_sz: Vector2 = scale_tree.call("_stage_size", StringName(stage_name))
			var anchor: Vector2 = scale_tree.call("door_anchor_offset")
			failed += _assert(door_px.y < frame_sz.y - 1.0, "door sill above frame bottom on %s (y %.0f h %.0f)" % [stage_name, door_px.y, frame_sz.y])
			failed += _assert(anchor.length() < 0.75, "door floor stays on the node for %s (offset %s)" % [stage_name, anchor])
			var door_shape: CollisionShape2D = scale_tree.get_node_or_null("CollisionShape2D") as CollisionShape2D
			var door_rect: RectangleShape2D = door_shape.shape as RectangleShape2D if door_shape else null
			if door_shape and door_rect:
				var covers: bool = abs(door_shape.position.x) <= door_rect.size.x * 0.5 + 1.0 and abs(door_shape.position.y) <= door_rect.size.y * 0.5 + 1.0
				failed += _assert(covers, "hitbox still covers the door on %s" % stage_name)
			var door_label: Label = scale_tree.get_node_or_null("Label") as Label
			if door_label and sap_sprite:
				var sprite_top: float = sap_sprite.offset.y * sap_sprite.scale.y
				failed += _assert(door_label.position.y < sprite_top, "label stays above the crown on %s" % stage_name)
		game_state.set("stage_id", &"sapling")
		scale_tree.call("_refresh_visual")
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
				var rune_sprite: Sprite2D = stone_node.get_node_or_null("Stone") as Sprite2D
				failed += _assert(rune_sprite != null and rune_sprite.texture != null, "runestone sprite")
			for stat_need: String in ["might", "arcana", "resilience", "ward", "vitality", "swiftness", "fate"]:
				failed += _assert(bool(seen.get(stat_need, false)), "runestone for %s" % stat_need)
			var frame_seen: Dictionary = {}
			game_state.call("set_resource", &"manashards", 500)
			for stone_node: Node in stones.get_children():
				var cell: Vector2i = stone_node.call("sheet_cell")
				var cell_key: String = "%d,%d" % [cell.x, cell.y]
				failed += _assert(not bool(frame_seen.get(cell_key, false)), "distinct runestone frame %s" % cell_key)
				frame_seen[cell_key] = true
				var sid: String = str(stone_node.get("stat_id"))
				var tint: Color = keeper_stats.call("stat_color", sid)
				var glow: Color = stone_node.call("glow_modulate", tint, true)
				failed += _assert(
					absf(glow.r - 1.0) < 0.02 and absf(glow.g - 1.0) < 0.02 and absf(glow.b - 1.0) < 0.02,
					"runestone glow stays white so the glyph colour reads for %s" % sid
				)
				var rune_sprite2: Sprite2D = stone_node.get_node_or_null("Stone") as Sprite2D
				var glow_match: float = 1.0
				if rune_sprite2:
					glow_match = absf(rune_sprite2.modulate.r - glow.r) + absf(rune_sprite2.modulate.g - glow.g) + absf(rune_sprite2.modulate.b - glow.b)
				failed += _assert(rune_sprite2 != null and glow_match < 0.05, "live stone stays neutral for %s" % sid)
				var atlas_tex: AtlasTexture = rune_sprite2.texture as AtlasTexture if rune_sprite2 else null
				failed += _assert(atlas_tex != null, "runestone uses the sheet atlas for %s" % sid)
				if atlas_tex:
					var expect := Rect2(cell.x * 64, cell.y * 64, 64, 64)
					failed += _assert(atlas_tex.region == expect, "runestone region matches %s cell %s" % [sid, cell])
			game_state.call("set_resource", &"manashards", 0)
		var live_tree: Node = live_sheet.get_node_or_null("World/Manatree")
		var live_sprite: Sprite2D = null
		if live_tree:
			live_sprite = live_tree.get_node_or_null("Sprite") as Sprite2D
		failed += _assert(live_sprite != null and abs(live_sprite.scale.x - 1.0) < 0.01, "live sapling scale 1")
		var sheet_hud: Node = live_sheet.get_node_or_null("HUD")
		failed += _assert(sheet_hud != null and sheet_hud.has_method("open_character_sheet"), "HUD character sheet")
		var char_btn: Button = null
		var char_icon: TextureRect = null
		var ascension_icon: TextureRect = null
		if sheet_hud:
			char_btn = sheet_hud.get_node_or_null("Panel/CharacterButton") as Button
			char_icon = sheet_hud.get_node_or_null("Panel/CharacterButton/CharacterIcon") as TextureRect
			ascension_icon = sheet_hud.get_node_or_null("Panel/AscensionReopenButton/AscensionIcon") as TextureRect
			if sheet_hud.has_method("hide_welcome"):
				sheet_hud.call("hide_welcome")
		failed += _assert(char_btn != null and str(char_btn.text) == "", "HUD Character button is icon-only")
		failed += _assert(char_icon != null and char_icon.texture == HudIcons.cell(HudIcons.CHARACTER), "Character button uses sheet cell")
		failed += _assert(ascension_icon != null and ascension_icon.texture == HudIcons.cell(HudIcons.ASCENSION), "Ascension reopen uses sheet cell")
		var help_icon: TextureRect = null
		if sheet_hud:
			help_icon = sheet_hud.get_node_or_null("Panel/HelpButton/HelpIcon") as TextureRect
		failed += _assert(help_icon != null and help_icon.texture == HudIcons.cell(HudIcons.HELP), "Help button uses sheet cell")
		var berry_sprite: Sprite2D = live_sheet.get_node_or_null("World/HarvestBerry/Sprite") as Sprite2D
		var tree_sprite: Sprite2D = live_sheet.get_node_or_null("World/HarvestTree/Sprite") as Sprite2D
		var stone_sprite: Sprite2D = live_sheet.get_node_or_null("World/HarvestStone/Sprite") as Sprite2D
		failed += _assert(berry_sprite != null and berry_sprite.texture != null and str(berry_sprite.texture.resource_path).ends_with("berry_harvest_node.png"), "berry node uses berry_harvest_node")
		if berry_sprite and berry_sprite.texture:
			var berry_disp: Vector2 = berry_sprite.texture.get_size() * berry_sprite.scale
			failed += _assert(abs(berry_disp.y - 128.0) < 1.0 and berry_disp.x <= 128.0 + 0.5, "berry scaled to twice the 64 harvest box")
			failed += _assert(berry_sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "berry nearest filter")
		failed += _assert(tree_sprite != null and tree_sprite.texture != null and str(tree_sprite.texture.resource_path).ends_with("harvest_tree.png"), "tree harvest art unchanged")
		failed += _assert(stone_sprite != null and stone_sprite.texture != null and str(stone_sprite.texture.resource_path).ends_with("harvest_stone.png"), "stone harvest art unchanged")
		sheet_hud.call("open_character_sheet")
		await process_frame
		failed += _assert(bool(sheet_hud.call("is_character_open")), "character sheet opens")
		var portrait: TextureRect = sheet_hud.get_node_or_null("CharacterSheet/SheetFit/Sheet/PortraitHost/Portrait") as TextureRect
		failed += _assert(portrait != null and portrait.texture != null, "keeper portrait")
		failed += _assert(portrait != null and str(portrait.texture.resource_path).find("keeper_still_south_frame0") >= 0, "portrait uses the v4 south still")
		var weapon_slot: Node = sheet_hud.get_node_or_null("CharacterSheet/SheetFit/Sheet/PortraitHost/Slot_weapon")
		var relic_slot: Node = sheet_hud.get_node_or_null("CharacterSheet/SheetFit/Sheet/PortraitHost/Slot_relic")
		var relic_square: TextureRect = sheet_hud.get_node_or_null("CharacterSheet/SheetFit/Sheet/PortraitHost/Slot_relic/Square") as TextureRect
		var weapon_square: TextureRect = sheet_hud.get_node_or_null("CharacterSheet/SheetFit/Sheet/PortraitHost/Slot_weapon/Square") as TextureRect
		failed += _assert(weapon_slot != null and relic_slot != null, "weapon and relic slots")
		failed += _assert(relic_square != null and relic_square.texture == HudIcons.cell(HudIcons.EQUIP_LOCKED), "relic slot uses locked chrome")
		failed += _assert(weapon_square != null and weapon_square.texture == HudIcons.cell(HudIcons.EQUIP_EMPTY), "empty weapon slot uses empty chrome")
		var relic_style: StyleBoxFlat = relic_slot.get_theme_stylebox("panel") as StyleBoxFlat if relic_slot != null else null
		var weapon_style: StyleBoxFlat = weapon_slot.get_theme_stylebox("panel") as StyleBoxFlat if weapon_slot != null else null
		failed += _assert(relic_style != null and relic_style.get_border_width(SIDE_LEFT) == 0, "locked slot has no gold border")
		failed += _assert(weapon_style != null and weapon_style.get_border_width(SIDE_TOP) == 0, "weapon slot has no gold border")
		failed += _assert(relic_slot.get_node_or_null("Lock") == null, "locked slot has no inner lock chip")
		var relic_hint: Label = sheet_hud.get_node_or_null("CharacterSheet/SheetFit/Sheet/PortraitHost/Slot_relic/CaptionHost/Hint") as Label
		var relic_cap: Control = sheet_hud.get_node_or_null("CharacterSheet/SheetFit/Sheet/PortraitHost/Slot_relic/CaptionHost") as Control
		failed += _assert(relic_hint != null and str(relic_hint.text) == "Locked", "relic lock caption")
		failed += _assert(relic_cap != null and relic_square != null and relic_cap.position.y >= relic_square.position.y + relic_square.size.y - 0.5, "Locked sits under the square")
		failed += _assert(str(relic_slot.get("tooltip_text")).find("Forge Key") >= 0, "relic tooltip names Forge Key")
		var weapon_hint: Label = sheet_hud.get_node_or_null("CharacterSheet/SheetFit/Sheet/PortraitHost/Slot_weapon/CaptionHost/Hint") as Label
		var weapon_cap: Control = sheet_hud.get_node_or_null("CharacterSheet/SheetFit/Sheet/PortraitHost/Slot_weapon/CaptionHost") as Control
		failed += _assert(weapon_hint != null and str(weapon_hint.text) == "Weapon", "empty weapon reads Weapon")
		failed += _assert(weapon_cap != null and weapon_square != null and weapon_cap.position.y >= weapon_square.position.y + weapon_square.size.y - 0.5, "weapon caption sits under the square")
		var head_hint: Label = sheet_hud.get_node_or_null("CharacterSheet/SheetFit/Sheet/PortraitHost/Slot_head/CaptionHost/Hint") as Label
		var head_cap: Control = sheet_hud.get_node_or_null("CharacterSheet/SheetFit/Sheet/PortraitHost/Slot_head/CaptionHost") as Control
		var head_square: TextureRect = sheet_hud.get_node_or_null("CharacterSheet/SheetFit/Sheet/PortraitHost/Slot_head/Square") as TextureRect
		failed += _assert(head_square != null and head_square.texture == HudIcons.cell(HudIcons.EQUIP_LOCKED), "locked head slot uses locked chrome")
		failed += _assert(head_hint != null and str(head_hint.text) == "Locked", "locked slot caption")
		failed += _assert(head_square != null and head_cap != null and head_cap.position.y >= head_square.position.y + head_square.size.y - 0.5, "head Locked sits under the square")
		var hotkey_lbl: Label = sheet_hud.get_node_or_null("CharacterSheet/SheetFit/Sheet/HotkeyHint") as Label
		failed += _assert(hotkey_lbl != null and str(hotkey_lbl.text) == "C — Character", "sheet hotkey hint")
		failed += _assert(char_btn != null and str(char_btn.tooltip_text) == "C — Character", "HUD hotkey hint")
		var gear_title_lbl: Label = sheet_hud.get_node_or_null("CharacterSheet/SheetFit/Sheet/GearColumn/GearTitle") as Label
		failed += _assert(gear_title_lbl != null and str(gear_title_lbl.text) == "Gear", "gear column title")
		var gear_empty: Label = sheet_hud.get_node_or_null("CharacterSheet/SheetFit/Sheet/GearColumn/GearScroll/GearList/Empty") as Label
		failed += _assert(gear_empty != null and str(gear_empty.text) == "No gear yet.", "gear empty copy")
		var might_line: Label = sheet_hud.get_node_or_null("CharacterSheet/SheetFit/Sheet/Stats/Stat_might/Line/Text") as Label
		var might_name: Control = sheet_hud.get_node_or_null("CharacterSheet/SheetFit/Sheet/Stats/Stat_might/Name") as Control
		var might_role: Control = sheet_hud.get_node_or_null("CharacterSheet/SheetFit/Sheet/Stats/Stat_might/Role") as Control
		var might_nums: Control = sheet_hud.get_node_or_null("CharacterSheet/SheetFit/Sheet/Stats/Stat_might/Line") as Control
		var arcana_name: Label = sheet_hud.get_node_or_null("CharacterSheet/SheetFit/Sheet/Stats/Stat_arcana/Name/Text") as Label
		var might_block: Control = sheet_hud.get_node_or_null("CharacterSheet/SheetFit/Sheet/Stats/Stat_might") as Control
		var arcana_block: Control = sheet_hud.get_node_or_null("CharacterSheet/SheetFit/Sheet/Stats/Stat_arcana") as Control
		failed += _assert(might_line != null and str(might_line.text) == "5 + 0 = 5", "new game might is 5 + 0 = 5")
		failed += _assert(might_line != null and str(might_line.tooltip_text).find("Starts at 5") >= 0, "stat line notes the base of 5")
		failed += _assert(might_name != null and might_role != null and might_nums != null, "stat name, role, and numbers")
		# Role starts in the name row's empty descent so the words sit flush under the name.
		var name_bottom: float = 0.0
		if might_name != null:
			name_bottom = might_name.position.y + might_name.size.y
		failed += _assert(might_role != null and might_name != null and might_role.position.y > might_name.position.y and might_role.position.y < name_bottom and might_role.position.y + might_role.size.y > name_bottom + 4.0, "role sits directly under the name")
		failed += _assert(might_nums != null and might_role != null and might_nums.position.y >= might_role.position.y + might_role.size.y + 4.0, "small gap before the numbers")
		failed += _assert(might_block != null and arcana_block != null and might_nums != null, "stat blocks stacked")
		if might_block != null and arcana_block != null and might_nums != null and might_role != null:
			var gap_small: float = might_nums.position.y - (might_role.position.y + might_role.size.y)
			var gap_large: float = arcana_block.position.y - (might_block.position.y + might_nums.position.y + might_nums.size.y)
			failed += _assert(gap_large > gap_small + 4.0, "larger gap before the next stat")
			var fate_block: Control = sheet_hud.get_node_or_null("CharacterSheet/SheetFit/Sheet/Stats/Stat_fate") as Control
			var stats_root: Control = sheet_hud.get_node_or_null("CharacterSheet/SheetFit/Sheet/Stats") as Control
			failed += _assert(fate_block != null and stats_root != null and fate_block.position.y + might_nums.position.y + might_nums.size.y <= stats_root.size.y, "seven stats fit the panel")
		var arcana_line: Label = sheet_hud.get_node_or_null("CharacterSheet/SheetFit/Sheet/Stats/Stat_arcana/Line/Text") as Label
		failed += _assert(arcana_line != null and str(arcana_line.text) == "5 + 0 = 5", "new game arcana is 5 + 0 = 5")
		failed += _assert(arcana_name != null and str(arcana_name.text) == "Arcana", "arcana name")
		var gear_list: Node = sheet_hud.get_node_or_null("CharacterSheet/SheetFit/Sheet/GearColumn/GearScroll/GearList")
		failed += _assert(gear_list != null, "equipment inventory column")
		equipment.call("grant_item", "stone_sword")
		await process_frame
		failed += _assert(gear_list.get_child_count() >= 1, "sword listed in equipment inventory")
		var sword_row: Node = gear_list.get_child(0)
		var sword_icon: TextureRect = null
		if sword_row.get_child_count() > 0 and sword_row.get_child(0).get_child_count() > 0:
			sword_icon = sword_row.get_child(0).get_child(0) as TextureRect
		var flint_icon: Texture2D = load("res://assets/art/ui/icon_stone_sword.png") as Texture2D
		failed += _assert(HudIcons.index_for_item("stone_sword") < 0, "stone_sword leaves sheet cell 6")
		failed += _assert(CharacterSheet.gear_icon_path("stone_sword") == "res://assets/art/ui/icon_stone_sword.png", "flintblade icon path")
		failed += _assert(CharacterSheet.gear_icon_path("rootsteel_edge") == "res://assets/art/ui/icon_rootsteel_edge.png", "rootsteel icon path")
		failed += _assert(CharacterSheet.gear_icon_path("heartwand") == "res://assets/art/ui/icon_heartwand.png", "heartwand icon path")
		failed += _assert(CharacterSheet.gear_icon_path("switchshaft") == "res://assets/art/ui/icon_switchshaft.png", "switchshaft icon path")
		failed += _assert(sword_icon != null and flint_icon != null and sword_icon.texture == flint_icon, "gear bag sword uses flintblade icon")
		sheet_hud.get_node("CharacterSheet").call("request_equip", "stone_sword")
		await process_frame
		failed += _assert(str(equipment.call("equipped_id", "weapon")) == "stone_sword", "sheet click equips sword")
		might_line = sheet_hud.get_node_or_null("CharacterSheet/SheetFit/Sheet/Stats/Stat_might/Line/Text") as Label
		weapon_hint = sheet_hud.get_node_or_null("CharacterSheet/SheetFit/Sheet/PortraitHost/Slot_weapon/CaptionHost/Hint") as Label
		failed += _assert(might_line != null and str(might_line.text).find("5 + 2 = 7") >= 0, "sheet shows 5 + 2 = 7")
		failed += _assert(int(equipment.call("gear_bonus", "might")) == 2, "equipped sword still adds +2 might")
		failed += _assert(weapon_hint != null and str(weapon_hint.text) == "Flintblade", "equipped weapon shows the item name")
		weapon_square = sheet_hud.get_node_or_null("CharacterSheet/SheetFit/Sheet/PortraitHost/Slot_weapon/Square") as TextureRect
		failed += _assert(weapon_square != null and flint_icon != null and weapon_square.texture == flint_icon, "equipped sword shows flintblade icon")
		var slot_plate: Node = sheet_hud.get_node("CharacterSheet/SheetFit/Sheet/PortraitHost/Slot_weapon")
		sheet_hud.get_node("CharacterSheet").call("request_unequip", "weapon")
		await process_frame
		failed += _assert(str(equipment.call("equipped_id", "weapon")) == "", "sheet unequip")
		weapon_square = sheet_hud.get_node_or_null("CharacterSheet/SheetFit/Sheet/PortraitHost/Slot_weapon/Square") as TextureRect
		failed += _assert(weapon_square != null and weapon_square.texture == HudIcons.cell(HudIcons.EQUIP_EMPTY), "unequipped weapon returns to empty chrome")
		slot_plate.call("_drop_data", Vector2.ZERO, {"kind": "gear", "item_id": "stone_sword", "from_slot": ""})
		await process_frame
		failed += _assert(str(equipment.call("equipped_id", "weapon")) == "stone_sword", "sheet drag-drop equips")
		var head_plate: Node = sheet_hud.get_node("CharacterSheet/SheetFit/Sheet/PortraitHost/Slot_head")
		failed += _assert(not bool(head_plate.call("_can_drop_data", Vector2.ZERO, {"kind": "gear", "item_id": "stone_sword", "from_slot": ""})), "locked head rejects drop")
		var gear_col: Node = sheet_hud.get_node("CharacterSheet/SheetFit/Sheet/GearColumn")
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
		game_state.call("reset_for_new_game")
		game_state.call("set_resource", &"manashards", 100)
		var might_stone: Node = null
		if stones:
			for stone_node: Node in stones.get_children():
				if str(stone_node.get("stat_id")) == "might":
					might_stone = stone_node
					break
		failed += _assert(might_stone != null and might_stone.has_method("begin_spend"), "runestone spend confirm")
		failed += _assert(might_stone != null and might_stone.has_method("apply_player_command"), "runestone RMB command")
		if might_stone:
			game_state.call("clear_selection")
			might_stone.call("apply_player_command")
			failed += _assert(not bool(might_stone.call("is_spend_confirm_open")), "runestone ignores command without keeper")
			game_state.set("selected_wisp_id", 0)
			might_stone.call("apply_player_command")
			failed += _assert(not bool(might_stone.call("is_spend_confirm_open")), "wisp command does not raise a runestone")
			game_state.call("select_keeper")
			var lmb_stone := InputEventMouseButton.new()
			lmb_stone.button_index = MOUSE_BUTTON_LEFT
			lmb_stone.pressed = true
			might_stone.call("_on_input_event", null, lmb_stone, 0)
			failed += _assert(not bool(might_stone.call("is_spend_confirm_open")), "LMB on a runestone does not spend")
			might_stone.call("apply_player_command")
			failed += _assert(not bool(might_stone.call("is_spend_confirm_open")), "RMB walks in range before the confirm")
			var rmb_stone := InputEventMouseButton.new()
			rmb_stone.button_index = MOUSE_BUTTON_RIGHT
			rmb_stone.pressed = true
			might_stone.call("_on_input_event", null, rmb_stone, 0)
			might_stone.call("on_interact", null)
			failed += _assert(bool(might_stone.call("is_spend_confirm_open")), "in-range interact opens the confirm")
			might_stone.call("cancel_spend")
			game_state.call("set_resource", &"manashards", 0)
			failed += _assert(str(might_stone.call("begin_spend")) == "cant_afford", "poor keeper still sees the confirm")
			failed += _assert(bool(might_stone.call("is_spend_confirm_open")), "confirm stays open when short")
			var poor_body: Label = might_stone.get_tree().root.get_node_or_null("RunestoneConfirm/Panel/Body") as Label
			failed += _assert(poor_body != null and str(poor_body.text).find("Not enough") >= 0, "confirm says not enough")
			might_stone.call("cancel_spend")
			game_state.call("set_resource", &"manashards", 100)
			failed += _assert(str(might_stone.call("begin_spend")) == "confirm", "runestone opens confirm")
			failed += _assert(bool(might_stone.call("is_spend_confirm_open")), "confirm panel visible")
			failed += _assert(int(keeper_stats.call("get_rank", "might")) == 0, "confirm does not spend yet")
			failed += _assert(int(keeper_stats.call("get_base", "might")) == 5, "confirm sheet base is still 5")
			var bank_lbl: Label = might_stone.get_tree().root.get_node_or_null("RunestoneConfirm/Panel/Bank") as Label
			failed += _assert(bank_lbl != null and str(bank_lbl.text).find("Ascension") >= 0, "confirm shows bank hint")
			failed += _assert(str(might_stone.call("confirm_spend")) == "ok", "confirm raises the stat")
			failed += _assert(int(keeper_stats.call("get_rank", "might")) == 1, "confirm spend raises might by 1")
			failed += _assert(int(keeper_stats.call("get_base", "might")) == 6, "confirm spend base is 5 + 1")
			failed += _assert(int(game_state.get("manashards")) == 0, "confirm spent 100 shards")
			failed += _assert(not bool(might_stone.call("is_spend_confirm_open")), "confirm closes after raise")
		var v6_state: Dictionary = game_state.call("to_save_dict")
		v6_state["backpack"] = {"fertilizer": 4, "weapon_rod": 2, "wooden_planks": 3}
		v6_state["keeper_stats"] = {"might": 3}
		v6_state["equipment"] = {
			"owned": [{"id": "stone_sword", "level": 1, "runes": []}],
			"equipped": {},
		}
		v6_state.erase("gear_inventory")
		v6_state.erase("equipment_equipped")
		v6_state.erase("equipment_unlocked")
		var v6_migrated: Dictionary = save_service.call("_migrate", 6, v6_state)
		var v6_pack: Dictionary = v6_migrated.get("backpack", {})
		failed += _assert(int(v6_pack.get("fertilizer", 0)) == 4, "v6 migrate keeps fertilizer")
		failed += _assert(int(v6_pack.get("wooden_planks", 0)) == 3, "v6 migrate keeps planks")
		failed += _assert(int(v6_pack.get("weapon_rod", 0)) == 2, "v6 migrate leaves backpack rod key untouched")
		failed += _assert((v6_migrated.get("gear_inventory", {}) as Dictionary).is_empty(), "v6 gear inventory starts empty")
		failed += _assert((v6_migrated.get("equipment_equipped", {}) as Dictionary).get("weapon", "x") == null, "v6 weapon slot starts null")
		failed += _assert(bool((v6_migrated.get("equipment_unlocked", {}) as Dictionary).get("weapon", false)), "v6 unlocks weapon only")
		failed += _assert(not bool((v6_migrated.get("equipment_unlocked", {}) as Dictionary).get("relic", true)), "v6 relic stays locked")
		failed += _assert(int((v6_migrated.get("keeper_stats", {}) as Dictionary).get("might", -1)) == 0, "v6 migrate ranks might at 0")
		failed += _assert(int((v6_migrated.get("keeper_stats", {}) as Dictionary).get("fate", -1)) == 0, "v6 migrate ranks fate at 0")
		game_state.call("apply_save_dict", v6_migrated)
		failed += _assert(int(backpack.call("get_count", "fertilizer")) == 4, "applied v6 fertilizer")
		failed += _assert(int(equipment.call("unequipped_count", "weapon_rod")) == 0, "v6 rod is not gear")
		failed += _assert(int(equipment.call("unequipped_count", "stone_sword")) == 0, "v6 sword is not kept")
		failed += _assert(int(keeper_stats.call("get_rank", "might")) == 0, "applied v6 might rank is 0")
		failed += _assert(int(keeper_stats.call("get_base", "might")) == 5, "applied v6 might displays 5")
		var v7_state: Dictionary = {"keeper_stats": {"might": 2, "arcana": 0, "resilience": 8, "ward": 5}}
		var v7_migrated: Dictionary = save_service.call("_migrate", 7, v7_state)
		var v7_stats: Dictionary = v7_migrated.get("keeper_stats", {})
		failed += _assert(int(v7_stats.get("might", -1)) == 2, "v7 might 2 stays a rank")
		failed += _assert(int(v7_stats.get("arcana", -1)) == 0, "v7 arcana 0 stays a rank")
		failed += _assert(int(v7_stats.get("resilience", -1)) == 8, "v7 resilience 8 is not wiped")
		failed += _assert(int(v7_stats.get("ward", -1)) == 5, "v7 ward 5 stays")
		failed += _assert(int(v7_stats.get("swiftness", -1)) == 0, "v7 missing swiftness becomes 0")
		failed += _assert(int(v7_stats.get("fate", -1)) == 0, "v7 missing fate becomes 0")
		game_state.call("apply_save_dict", v7_migrated)
		failed += _assert(int(keeper_stats.call("get_rank", "might")) == 2, "applied might rank stays 2")
		failed += _assert(int(keeper_stats.call("get_base", "might")) == 7, "absolute 2 displays as base 7")
		failed += _assert(int(keeper_stats.call("get_base", "arcana")) == 5, "absolute 0 displays as base 5")
		failed += _assert(int(keeper_stats.call("get_rank", "resilience")) == 8, "rank 8 is not wiped")
		failed += _assert(int(keeper_stats.call("get_base", "resilience")) == 13, "rank 8 displays as base 13")
		failed += _assert(int(keeper_stats.call("get_rank", "swiftness")) == 0, "missing swiftness rank is 0")
		failed += _assert(int(keeper_stats.call("get_base", "swiftness")) == 5, "missing swiftness displays 5")
		live_sheet.free()
		paused = false
		await process_frame
		game_state.call("reset_for_new_game")
		save_service.call("delete_save")

	failed += await _verify_echo(tree_root, game_state, save_service, content_strings, game_audio)
	failed += _forge_pass_a(tree_root, game_state, save_service, backpack)
	failed += _forge_duration_ticks(tree_root, game_state, backpack)
	failed += await _party_bar_check(tree_root, game_state)
	failed += await _elaia_join_check(tree_root, game_state, backpack)
	failed += _elaia_companion_asserts(tree_root, game_state, backpack)
	failed += _pass_e_idle(tree_root, game_state, save_service, backpack, content_strings)
	failed += await _forge_pass_b(tree_root, game_state, backpack)
	failed += await _forge_pass_c(tree_root, game_state, backpack)
	failed += await _waypoint_pass(tree_root, game_state, save_service, backpack, content_strings, game_audio)
	failed += await _scene_transitions(tree_root, game_state, save_service)
	failed += await _workbench_reach(tree_root, save_service)
	failed += await _portrait_switch_forge(tree_root, game_state, save_service)
	failed += await _forge_arch_draw_order(tree_root)
	failed += await _forge_ysort(tree_root)
	failed += await _manatree_door_clear(tree_root, game_state, save_service)
	failed += await _companion_door_transfer(tree_root, game_state, save_service)
	failed += await _door_transfer_active_only(tree_root, game_state, save_service)
	failed += await _workbench_click_panel(tree_root)
	failed += await _workbench_panel_no_pause(tree_root, game_state)
	failed += await _workbench_wisp_visible(tree_root, game_state, save_service)
	failed += _forged_item_any_character(tree_root)
	failed += _workbench_north_route()
	failed += await _craft_duration_labels(tree_root, game_state, backpack)
	failed += await _forge_entry_one_click(tree_root, game_state, save_service)
	failed += await _batch_refund(tree_root, game_state, save_service, backpack, content_strings)
	failed += await _batch_offline(tree_root, game_state, save_service, backpack, content_strings)
	failed += await _batch_ascend_wipe(tree_root, game_state, save_service, backpack, content_strings)
	failed += await _batch_migration(tree_root, game_state, save_service, backpack)
	failed += _no_old_keeper_idle()
	failed += await _jobs_survive_switch(tree_root, game_state, save_service)
	failed += _autosave_event_throttle(save_service)
	failed += await _adventure_batch1(tree_root, game_state, save_service, content_strings, game_audio)
	failed += await _echo2_portal_visible(tree_root, game_state, save_service)
	failed += await _expedition_board_tease(tree_root, game_state, save_service)
	failed += await _debug_snapshots_reach(tree_root, game_state, save_service)
	failed += await _speed_button_ok(tree_root, game_state, save_service, game_audio)
	failed += _reach_checks(tree_root, game_state, save_service)
	failed += _reach_mix_reload(tree_root, game_state, save_service)
	failed += _save_newer_refused(tree_root, game_state, save_service)
	failed += _reach_turn_order()
	failed += _debug_snapshots_migrate(tree_root, game_state, save_service)
	failed += _beast_data(tree_root)
	failed += _spawn_data(tree_root)
	failed += _spawn_roller(tree_root)
	failed += _spawn_seed(tree_root)
	failed += _strings_adventure_v4(tree_root)
	failed += _save_v14_inventory_merge(tree_root, game_state, save_service)
	failed += _save_v14_home(tree_root, game_state, save_service)
	failed += _save_v14_from_main(tree_root, game_state, save_service)
	failed += _resolver_dice()
	failed += _resolver_margin()
	failed += _resolver_die_table()
	failed += _resolver_seed()
	failed += _resolver_state_roundtrip()
	failed += await _battle_shell(tree_root, game_state, save_service)
	failed += await _battle_echo_exclusive(tree_root, game_state, save_service)
	failed += await _battle_plates(tree_root, game_state, save_service)
	failed += await _battle_menu(tree_root, game_state, save_service)
	failed += await _battle_target_reach(tree_root, game_state, save_service)
	failed += await _battle_strike_for_me(tree_root, game_state, save_service)
	failed += await _battle_playback(tree_root, game_state, save_service)
	failed += await _battle_art(tree_root, game_state, save_service)
	failed += _battle_audio_sole_caller(tree_root, game_audio)
	failed += await _headless_silent(tree_root, game_state, save_service, game_audio)
	failed += _resolver_turn_order()
	failed += _resolver_rows()
	failed += _resolver_targeting()
	failed += _resolver_brace()
	failed += _resolver_shield_order()
	failed += _resolver_poison_refresh()
	failed += _resolver_twists()
	failed += _resolver_boss()
	failed += _resolver_salve()
	failed += _auto_flee_ko_zero()
	failed += _resolver_log()
	failed += _auto_policy()
	# SIM_PARITY is switch-only (~31 s for 12k idle fights); see MANAFORGE_SIM_PARITY.
	failed += _resolver_perf()

	if failed == 0:
		print("VERIFY_OK: all headless assertions passed")
		quit(0)
	else:
		print("VERIFY_FAIL: %d assertion(s) failed" % failed)
		quit(1)


func _verify_echo(tree_root: Window, game_state: Node, save_service: Node, content_strings: Node, game_audio: Node) -> int:
	var failed: int = 0
	var keeper_stats: Node = tree_root.get_node_or_null("KeeperStats")
	var equipment: Node = tree_root.get_node_or_null("Equipment")
	var echo: Node = tree_root.get_node_or_null("EchoChamber")
	failed += _assert(keeper_stats != null and equipment != null and echo != null, "echo autoloads")
	if failed > 0:
		return failed
	game_state.call("reset_for_new_game")
	save_service.call("delete_save")
	echo.set("in_battle", false)
	var echo_def: Dictionary = echo.call("echo_def")
	failed += _assert(str(echo.call("echo_display_name")) == "Elaia", "Elaia display name")
	failed += _assert(str(echo_def.get("id", "")) == "echo_keeper_01", "echo id")
	var estats: Dictionary = echo_def.get("stats", {})
	failed += _assert(int(estats.get("vitality", 0)) == 6 and int(estats.get("arcana", 0)) == 7, "Elaia vit 6 arcana 7")
	failed += _assert(int(estats.get("swiftness", 0)) == 6 and int(estats.get("might", 0)) == 4, "Elaia swift 6 might 4")
	failed += _assert(str(content_strings.call("get_text", "echo_elaia_name")) == "Elaia", "echo_elaia_name")
	failed += _assert(str(content_strings.call("get_text", "echo_elaia_subtitle")).find("Echo") >= 0, "echo_elaia_subtitle")
	failed += _assert(str(content_strings.call("get_text", "portal_confirm")).find("{cost}") >= 0, "portal_confirm")
	failed += _assert(str(content_strings.call("get_text", "portal_cant_afford")).find("{cost}") >= 0, "portal_cant_afford")
	failed += _assert(str(content_strings.call("get_text", "battle_mercy_hint")).find("{enemy}") >= 0, "battle_mercy_hint")
	failed += _assert(str(content_strings.call("get_text", "battle_fists_toast")).find("weapon") >= 0, "battle_fists_toast")
	failed += _assert(str(content_strings.call("get_text", "battle_spare_ok")).find("{enemy}") >= 0, "battle_spare_ok")
	failed += _assert(str(content_strings.call("get_text", "battle_defeat_ok")).find("{enemy}") >= 0, "battle_defeat_ok")
	failed += _assert(str(content_strings.call("get_text", "battle_key_grant")).find("+2 Swiftness") >= 0, "battle_key_grant")
	failed += _assert(str(content_strings.call("get_text", "forge_no_key")) == "You have no key.", "no key popup")
	failed += _assert(str(content_strings.call("get_text", "forge_not_built")) == "Congratulations, you finished the Trial! What secrets await you in the Forge? Stay tuned.", "forge not built")
	failed += _assert(str(content_strings.call("get_text", "echo_01_narrator")).find("does not raise her voice") >= 0, "echo_01_narrator")
	failed += _assert(str(content_strings.call("get_text", "echo_01_intro")).find("should not have opened this") >= 0, "echo_01_intro")
	failed += _assert(str(content_strings.call("get_text", "echo_01_intro")).find("another Keeper fail") >= 0, "echo_01_intro full line")
	failed += _assert(str(content_strings.call("get_text", "echo_01_return")).find("You came back") >= 0, "echo_01_return")
	failed += _assert(str(content_strings.call("get_text", "echo_01_mercy")).find("Wait. Please") >= 0, "echo_01_mercy")
	failed += _assert(str(content_strings.call("get_text", "echo_01_mercy")).find("worth following") >= 0, "echo_01_mercy full line")
	failed += _assert(str(content_strings.call("get_text", "echo_01_spare")).find("Then I stay") >= 0, "echo_01_spare")
	failed += _assert(str(content_strings.call("get_text", "echo_01_defeat")).find("I can sleep") >= 0, "echo_01_defeat")
	failed += _assert(str(content_strings.call("get_text", "echo_01_flee")).find("clearing still needs you") >= 0, "echo_01_flee")
	failed += _assert(str(content_strings.call("get_text", "forge_key_relic_name")) == "Forge Key", "forge_key_relic_name")
	failed += _assert(str(equipment.call("item_tooltip", "forge_key_relic")).find("+2 Swiftness") >= 0, "forge_key relic tooltip stats")
	failed += _assert(str(content_strings.call("get_text", "forge_key_relic_grant")).find("settles with you") >= 0, "forge_key_relic_grant")
	failed += _assert(str(content_strings.call("get_text", "battle_log_title")) == "Battle", "battle_log_title")
	failed += _assert(str(content_strings.call("get_text", "battle_log_strike_you")) == "You strike.", "battle_log_strike_you")
	failed += _assert(str(content_strings.call("get_text", "battle_log_strike_enemy")).find("{enemy}") >= 0, "battle_log_strike_enemy")
	failed += _assert(str(content_strings.call("get_text", "battle_log_crit_you")) == "A sharp hit!", "battle_log_crit_you")
	failed += _assert(str(content_strings.call("get_text", "battle_log_miss")).find("no purchase") >= 0, "battle_log_miss")
	failed += _assert(str(content_strings.call("get_text", "battle_log_fists")).find("Bare hands") >= 0, "battle_log_fists")
	failed += _assert(str(content_strings.call("get_text", "forge_enter_stage_locked")).find("Elder or Ancient") >= 0, "forge_enter_stage_locked")
	failed += _assert(str(content_strings.call("get_text", "battle_save_disabled")).find("Cannot save") >= 0, "battle_save_disabled")
	failed += _assert(str(content_strings.call("get_text", "battle_paused_hint")).find("Flee") >= 0, "battle_paused_hint")
	failed += _assert(EchoBattleScript.raw_damage(5, 5) == 0, "fists raw 0")
	failed += _assert(EchoBattleScript.raw_damage(4, 9) == 0, "negative raw is 0")
	failed += _assert(EchoBattleScript.raw_damage(7, 5) == 20, "sword raw 20")
	failed += _assert(EchoBattleScript.hp_max_for(5) == 50 and EchoBattleScript.hp_max_for(6) == 60, "hp from vitality")
	failed += _assert(EchoBattleScript.rank_cost(0) == 100 and EchoBattleScript.rank_cost(1) == 165, "rank cost curve")
	failed += _assert(EchoBattleScript.rank_cost(4) == 741 and EchoBattleScript.rank_cost(5) == 1222, "rank cost 741/1222")
	var ranks0: Dictionary = {
		"might": 0, "arcana": 0, "resilience": 0, "ward": 0, "vitality": 0, "swiftness": 0, "fate": 0
	}
	failed += _assert(EchoBattleScript.payout("spare", ranks0, 5) == 105, "generalist spare 105")
	failed += _assert(EchoBattleScript.payout("defeat", ranks0, 5) == 278, "generalist defeat 278")
	var ranks_might: Dictionary = ranks0.duplicate()
	ranks_might["might"] = 4
	failed += _assert(EchoBattleScript.payout("defeat", ranks_might, 5) == 2061, "specialist defeat 2061")
	failed += _assert(EchoBattleScript.payout("spare", ranks_might, 5) == 105, "specialist spare still third rank 0")
	var ordered: Array[String] = EchoBattleScript.ranked_stat_ids(ranks_might)
	failed += _assert(ordered[0] == "might" and ordered[1] == "arcana" and ordered[2] == "resilience", "might leads and the third tie is resilience")
	# Fists: 0 damage. Enemy still hits after.
	var fists: Variant = EchoBattleScript.new()
	fists.force_crit = 0
	fists.configure(_echo_totals(5, 9), echo_def)
	fists.choose("strike")
	failed += _assert(fists.last_keeper_damage == 0 and fists.echo_hp == 60, "fists deal 0")
	# Turn-1 floor: a lethal first cast leaves the Keeper at 1, then Flee succeeds.
	var lethal: Dictionary = echo_def.duplicate(true)
	(lethal["stats"] as Dictionary)["arcana"] = 40
	(lethal["stats"] as Dictionary)["swiftness"] = 9
	var t1: Variant = EchoBattleScript.new()
	t1.force_crit = 0
	t1.configure(_echo_totals(5, 1, 0), lethal)
	failed += _assert(t1.choose("flee") == "flee", "flee after her first hit")
	failed += _assert(t1.keeper_hp == 1 and t1.outcome == "flee" and t1.enemy_attacks == 1, "T1 cannot KO")
	var t1_strike: Variant = EchoBattleScript.new()
	t1_strike.force_crit = 0
	t1_strike.configure(_echo_totals(5, 1, 0), lethal)
	t1_strike.choose("strike")
	failed += _assert(t1_strike.keeper_hp == 1 and t1_strike.outcome == "", "T1 strike still cannot KO")
	# Crit does not bypass the mercy floor.
	var floored: Variant = EchoBattleScript.new()
	floored.force_crit = 1
	floored.configure(_echo_totals(20, 12), echo_def)
	floored.choose("strike")
	failed += _assert(floored.echo_hp == 1 and floored.spare_window, "10% floor holds on a crit")
	failed += _assert(not floored.available_actions().has("flee"), "spare window has no Flee")
	failed += _assert(floored.choose("flee") == "no_flee" and floored.outcome == "", "flee is refused in the window")
	failed += _assert(floored.available_actions().has("spare") and floored.available_actions().has("strike"), "window offers spare and strike")
	# No sword: she kills on her third hit. Echo never reaches the window.
	var bare: Variant = EchoBattleScript.new()
	bare.force_crit = 0
	bare.configure(_echo_totals(5, 1), echo_def)
	bare.choose("strike")
	bare.choose("strike")
	failed += _assert(bare.choose("strike") == "ko" and bare.enemy_attacks == 3 and bare.echo_hp == 60, "fists die on her third hit")
	# Sword only: die on her third action, before the window.
	var sword: Variant = EchoBattleScript.new()
	sword.force_crit = 0
	sword.configure(_echo_totals(7, 5), echo_def)
	sword.choose("strike")
	sword.choose("strike")
	failed += _assert(sword.choose("strike") == "ko" and sword.echo_hp == 20 and sword.enemy_attacks == 3, "sword dies before spare")
	# Sword + 1 Swift: tie, Keeper first, floor then window before her kill.
	var swift: Variant = EchoBattleScript.new()
	swift.force_crit = 0
	swift.configure(_echo_totals(7, 6), echo_def)
	swift.choose("strike")
	swift.choose("strike")
	failed += _assert(swift.choose("strike") == "spare_window", "swift reaches the window")
	failed += _assert(swift.echo_hp == 1 and swift.keeper_hp == 10 and swift.enemy_attacks == 2, "swift floor before her third hit")
	failed += _assert(swift.choose("strike") == "defeat" and swift.echo_hp == 0, "strike inside the window is defeat")
	# Sword + 1 Might, she is faster: window on the Keeper's second strike.
	var might_plus: Variant = EchoBattleScript.new()
	might_plus.force_crit = 0
	might_plus.configure(_echo_totals(8, 5), echo_def)
	might_plus.choose("strike")
	failed += _assert(might_plus.choose("strike") == "spare_window" and might_plus.echo_hp == 1, "might reaches 1 HP")
	var window_view_battle: Variant = EchoBattleScript.new()
	window_view_battle.force_crit = 0
	window_view_battle.configure(_echo_totals(7, 6), echo_def)
	window_view_battle.spare_window = true
	echo.set("battle", window_view_battle)
	echo.set("in_battle", true)
	echo.set("reentry", false)
	var view_packed: PackedScene = load("res://scenes/echo_battle.tscn") as PackedScene
	var view: Node = view_packed.instantiate()
	tree_root.add_child(view)
	await process_frame
	failed += _assert(not bool(view.call("is_flee_shown")), "battle UI hides Flee in the spare window")
	failed += _assert(bool(view.call("is_spare_shown")) and bool(view.call("is_strike_shown")), "battle UI shows Spare and Strike")
	failed += _assert(str(view.call("speech_text")).find("Wait. Please") >= 0, "mercy flavour in the window")
	failed += _assert(str(view.call("speech_text")).find("worth following") >= 0, "mercy uses the full line")
	var psize: Vector2 = view.call("portrait_size")
	failed += _assert(abs(psize.x - 384.0) < 0.5 and abs(psize.y - 384.0) < 0.5, "portraits 384x384")
	failed += _assert(bool(view.call("keeper_uses_idle_texture")), "keeper portrait uses battle_keeper_idle_e")
	failed += _assert(bool(view.call("echo_uses_key_texture")), "spare window uses battle_elaia_key_w")
	failed += _assert(FileAccess.file_exists("res://assets/art/echo/battle_elaia_idle_w.png"), "battle_elaia_idle_w.png shipped")
	failed += _assert(FileAccess.file_exists("res://assets/art/echo/battle_elaia_key_w.png"), "battle_elaia_key_w.png shipped")
	failed += _assert(float(view.call("speech_top")) < float(view.call("log_top")), "flavour above battle log")
	failed += _assert(bool(view.call("speech_between_portraits")), "flavour box sits between the portraits")
	var ssize: Vector2 = view.call("speech_band_size")
	failed += _assert(ssize.y >= 80.0 and ssize.y <= 100.0, "flavour band 80-100")
	var lsize: Vector2 = view.call("log_band_size")
	failed += _assert(lsize.y >= 100.0 and lsize.y <= 140.0, "battle log band 100-140")
	var csize: Vector2 = view.call("command_band_size")
	failed += _assert(abs(csize.x - 720.0) < 0.5 and abs(csize.y - 120.0) < 0.5, "command band 720x120")
	view.free()
	echo.set("battle", null)
	echo.set("in_battle", false)
	# Opening flavour: narrator + intro on a new fee; return when the fee is already paid.
	game_state.call("reset_for_new_game")
	var open_battle: Variant = EchoBattleScript.new()
	open_battle.force_crit = 0
	open_battle.configure(_echo_totals(7, 6), echo_def)
	echo.set("battle", open_battle)
	echo.set("in_battle", true)
	echo.set("reentry", false)
	var open_view: Node = view_packed.instantiate()
	tree_root.add_child(open_view)
	await process_frame
	failed += _assert(str(open_view.call("speech_text")).find("does not raise her voice") >= 0, "narrator on first enter")
	failed += _assert(str(open_view.call("speech_text")).find("should not have opened this") >= 0, "intro on first enter")
	failed += _assert(bool(open_view.call("echo_uses_elaia_texture")) and not bool(open_view.call("echo_uses_key_texture")), "opening face-off uses battle_elaia_idle_w")
	open_view.free()
	echo.set("reentry", true)
	var reentry_view: Node = view_packed.instantiate()
	tree_root.add_child(reentry_view)
	await process_frame
	failed += _assert(str(reentry_view.call("speech_text")).find("You came back") >= 0, "return flavour on reentry")
	failed += _assert(str(reentry_view.call("speech_text")).find("should not have opened this") < 0, "return does not repeat the intro")
	reentry_view.free()
	echo.set("battle", null)
	echo.set("in_battle", false)
	echo.set("reentry", false)
	# Payout snapshot uses live ranks at the moment of the ending.
	game_state.call("reset_for_new_game")
	game_state.call("set_resource", &"manashards", 0)
	var spare_pay: Dictionary = echo.call("apply_outcome", "spare")
	failed += _assert(int(spare_pay.get("shards", -1)) == 105, "spare snapshot 105")
	failed += _assert(int(game_state.get("manashards")) == 105, "spare shards enter the pool")
	failed += _assert(bool(game_state.get("forge_key")) and bool(game_state.get("echo_01_redeemed")), "spare grants key and companion flag")
	failed += _assert(bool(game_state.get("echo_01_resolved")) and not bool(game_state.get("portal_fee_paid")), "spare closes the fee")
	failed += _assert(bool(equipment.call("is_slot_unlocked", "relic")), "relic unlocks with the key")
	failed += _assert(str(equipment.call("equipped_id", "relic")) == "forge_key_relic", "spare equips Forge Key relic")
	failed += _assert(int(equipment.call("gear_bonus", "swiftness")) == 2, "Forge Key +2 Swiftness")
	failed += _assert(int(equipment.call("gear_bonus", "fate")) == 2, "Forge Key +2 Fate")
	failed += _assert(int(equipment.call("total_for", "swiftness")) == 7, "base 5 + key swift 2 = 7")
	failed += _assert(int(equipment.call("total_for", "fate")) == 7, "base 5 + key fate 2 = 7")
	# Auto-equip only if empty: unequip → leave in bag → ensure keeps inventory when slot filled again after re-equip path.
	failed += _assert(str(equipment.call("try_unequip", "relic")) == "ok", "unequip key to bag")
	failed += _assert(int(equipment.call("unequipped_count", "forge_key_relic")) == 1, "key sits in gear inventory")
	equipment.call("ensure_forge_key_equipped")
	failed += _assert(str(equipment.call("equipped_id", "relic")) == "forge_key_relic", "ensure re-equips when empty")
	game_state.call("reset_for_new_game")
	keeper_stats.call("set_rank", "might", 4)
	game_state.call("set_resource", &"manashards", 0)
	var defeat_pay: Dictionary = echo.call("apply_outcome", "defeat")
	failed += _assert(int(defeat_pay.get("shards", -1)) == 2061, "defeat snapshot 2061")
	failed += _assert(not bool(game_state.get("echo_01_redeemed")) and bool(game_state.get("forge_key")), "defeat grants key, not the companion")
	failed += _assert(str(equipment.call("equipped_id", "relic")) == "forge_key_relic", "defeat equips Forge Key relic")
	game_state.call("reset_for_new_game")
	game_state.set("portal_fee_paid", true)
	game_state.call("set_resource", &"manashards", 11)
	echo.call("apply_outcome", "ko")
	failed += _assert(int(game_state.get("manashards")) == 11 and not bool(game_state.get("portal_fee_paid")), "KO clears the fee and pays nothing")
	failed += _assert(not bool(game_state.get("forge_key")) and not bool(game_state.get("echo_01_resolved")), "KO does not close the portal")
	game_state.set("portal_fee_paid", true)
	var shards_before: int = int(game_state.get("manashards"))
	echo.call("apply_outcome", "flee")
	failed += _assert(bool(game_state.get("portal_fee_paid")) and int(game_state.get("manashards")) == shards_before, "flee keeps the fee and pays nothing")
	failed += _assert(str(echo.call("try_pay_fee")) == "closed", "fee reject while the portal is locked")
	game_state.set("portal_unlocked", true)
	game_state.set("echo_01_resolved", false)
	game_state.set("portal_fee_paid", false)
	game_state.call("set_resource", &"essence", 29)
	failed += _assert(str(echo.call("try_pay_fee")) == "reject", "fee reject under 30 Essence")
	failed += _assert(int(game_state.get("essence")) == 29 and not bool(game_state.get("portal_fee_paid")), "rejected fee does not spend")
	game_state.call("set_resource", &"essence", 30)
	failed += _assert(str(echo.call("try_pay_fee")) == "paid", "fee spends 30")
	failed += _assert(int(game_state.get("essence")) == 0 and bool(game_state.get("portal_fee_paid")), "fee flag after pay")
	failed += _assert(str(echo.call("try_pay_fee")) == "already_paid", "no second fee")
	# Ascend keeps a paid fee and the key.
	game_state.set("fruit_committed", true)
	game_state.set("fruit_harvested_pending_ascend", true)
	game_state.set("forge_key", true)
	game_state.set("echo_01_redeemed", true)
	game_state.call("set_resource", &"essence", 15)
	game_state.call("ascend")
	failed += _assert(bool(game_state.get("portal_unlocked")) and int(game_state.get("ascensions")) == 1, "ascend unlocks the portal")
	failed += _assert(bool(game_state.get("portal_fee_paid")) and bool(game_state.get("forge_key")), "ascend keeps fee and key")
	failed += _assert(bool(game_state.get("echo_01_redeemed")) and int(game_state.get("essence")) == 0, "ascend keeps the companion flag and wipes essence")
	var payload: Dictionary = game_state.call("to_save_dict")
	failed += _assert(not payload.has("keeper_hp") and not payload.has("echo_hp"), "fight HP is not saved")
	failed += _assert(bool(payload.get("portal_unlocked", false)) and bool(payload.get("forge_key", false)), "save payload has portal and key")
	failed += _assert(bool(save_service.call("save_game", 7)), "save slot 7 echo flags")
	var slot_file := FileAccess.open(str(save_service.call("slot_path", 7)), FileAccess.READ)
	failed += _assert(slot_file != null, "open slot 7")
	if slot_file:
		var slot_root: Variant = JSON.parse_string(slot_file.get_as_text())
		slot_file.close()
		failed += _assert(typeof(slot_root) == TYPE_DICTIONARY and int((slot_root as Dictionary).get("save_version", 0)) == 14, "slot writes save_version 14")
	game_state.call("reset_for_new_game")
	failed += _assert(not bool(game_state.get("portal_unlocked")) and not bool(game_state.get("forge_key")), "new game clears echo flags")
	failed += _assert(bool(save_service.call("load_game", 7)), "load slot 7 echo flags")
	failed += _assert(bool(game_state.get("portal_unlocked")) and bool(game_state.get("portal_fee_paid")), "loaded fee and portal")
	failed += _assert(bool(game_state.get("forge_key")) and bool(game_state.get("echo_01_redeemed")), "loaded key and companion flag")
	failed += _assert(bool(equipment.call("is_slot_unlocked", "relic")), "loaded key unlocks relic")
	failed += _assert(str(equipment.call("equipped_id", "relic")) == "forge_key_relic", "loaded Forge Key is equipped")
	failed += _assert(int(equipment.call("gear_bonus", "swiftness")) == 2 and int(equipment.call("gear_bonus", "fate")) == 2, "loaded key still +2/+2")
	var v7_echo: Dictionary = save_service.call("_migrate", 7, {"ascensions": 1, "essence": 4})
	failed += _assert(bool(v7_echo.get("portal_unlocked", false)), "v7 ascend migrates the portal open")
	failed += _assert(not bool(v7_echo.get("forge_key", true)) and not bool(v7_echo.get("portal_fee_paid", true)), "v7 migrate does not invent a key or a fee")
	echo.set("in_battle", true)
	failed += _assert(not bool(save_service.call("save_game", 7)), "save disabled during battle")
	echo.set("in_battle", false)
	# Hub scene: portal, fee confirm, Enter Forge, battle silence.
	game_state.call("reset_for_new_game")
	save_service.call("delete_save")
	var main_packed: PackedScene = load("res://scenes/main.tscn") as PackedScene
	var live: Node = main_packed.instantiate()
	tree_root.add_child(live)
	await process_frame
	await process_frame
	var portal: Node = live.get_node_or_null("World/EchoPortal")
	var hud: Node = live.get_node_or_null("HUD")
	var pause_menu: Node = live.get_node_or_null("PauseMenu")
	failed += _assert(portal != null and not portal.visible, "portal hidden before the first Ascend")
	if portal:
		var portal_marker: Sprite2D = portal.get_node_or_null("Visual/Marker") as Sprite2D
		failed += _assert(portal_marker != null and portal_marker.texture != null and str(portal_marker.texture.resource_path).ends_with("echo_portal_hub_v2.png"), "portal uses echo_portal_hub_v2")
		if portal_marker and portal_marker.texture:
			var portal_disp: Vector2 = portal_marker.texture.get_size() * portal_marker.scale
			failed += _assert(abs(portal_disp.x - 160.0) < 1.0 and abs(portal_disp.y - 200.0) < 1.0, "portal art is native 160x200")
			failed += _assert(portal_marker.offset.distance_to(Vector2(-80, -200)) < 0.5, "portal offset (-80,-200)")
			failed += _assert(portal_marker.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "portal nearest filter")
		var walk: CollisionShape2D = portal.get_node_or_null("WalkBody/CollisionShape2D") as CollisionShape2D
		var walk_rect: RectangleShape2D = walk.shape as RectangleShape2D if walk else null
		var portal_box: Vector2 = FeetBox.size_for(Vector2(160, 200))
		failed += _assert(walk_rect != null and walk_rect.size.distance_to(portal_box) < 0.5, "portal base collision is the feet box %s" % portal_box)
		var portal_label: Label = portal.get_node_or_null("Label") as Label
		failed += _assert(portal_label != null and abs(portal_label.offset_top + 228.0) < 1.0, "portal label sits near -228")
	failed += _assert(hud != null and pause_menu != null, "hud and pause for echo")
	if hud and portal and pause_menu:
		if hud.has_method("hide_welcome"):
			hud.call("hide_welcome")
		hud.call("show_care_menu")
		var forge_btn: Button = hud.get_node_or_null("CarePanel/ForgeButton") as Button
		failed += _assert(forge_btn != null and not bool(hud.call("is_forge_entry_visible")), "Enter Forge hidden on Sapling")
		game_state.set("stage_id", &"young")
		game_state.emit_signal("stage_changed", &"young")
		hud.call("_refresh_forge_entry")
		failed += _assert(not bool(hud.call("is_forge_entry_visible")), "Enter Forge hidden on Young")
		game_state.set("stage_id", &"mature")
		game_state.emit_signal("stage_changed", &"mature")
		hud.call("_refresh_forge_entry")
		failed += _assert(not bool(hud.call("is_forge_entry_visible")), "Enter Forge hidden on Mature")
		game_state.set("stage_id", &"elder")
		game_state.emit_signal("stage_changed", &"elder")
		hud.call("_refresh_forge_entry")
		failed += _assert(bool(hud.call("is_forge_entry_visible")) and not forge_btn.disabled, "Enter Forge visible on Elder")
		failed += _assert(bool(hud.call("is_forge_entry_gray")), "Enter Forge is gray without a key")
		game_audio.call("clear_played_log")
		failed += _assert(str(hud.call("open_forge_entry")) == "You have no key.", "gray forge popup")
		failed += _assert(bool(hud.call("is_forge_popup_open")), "forge popup open")
		failed += _assert(not bool(game_audio.call("did_play", &"mus_fruit_sting")), "no fruit sting on forge popup")
		failed += _assert(not bool(game_audio.call("did_play", &"mus_ascend_sting")), "no ascend sting on forge popup")
		game_state.set("forge_key", true)
		game_state.emit_signal("echo_flags_changed")
		failed += _assert(not bool(hud.call("is_forge_entry_gray")), "Enter Forge wakes up with the key")
		var forge_jobs: Node = tree_root.get_node_or_null("ForgeJobs")
		failed += _assert(forge_jobs != null and bool(forge_jobs.call("can_enter_forge")), "key can enter the forge")
		hud.call("hide_forge_popup")
		game_state.set("stage_id", &"ancient")
		game_state.emit_signal("stage_changed", &"ancient")
		hud.call("_refresh_forge_entry")
		failed += _assert(bool(hud.call("is_forge_entry_visible")), "Enter Forge visible on Ancient")
		hud.call("hide_care_menu")
		game_state.set("forge_key", false)
		game_state.set("stage_id", &"sapling")
		game_state.emit_signal("stage_changed", &"sapling")
		game_state.set("portal_unlocked", true)
		game_state.set("echo_01_resolved", false)
		game_state.emit_signal("echo_flags_changed")
		failed += _assert(portal.visible, "portal shows after unlock")
		game_state.set("echo_01_resolved", true)
		game_state.emit_signal("echo_flags_changed")
		failed += _assert(not portal.visible, "portal closes after a win")
		game_state.set("echo_01_resolved", false)
		game_state.set("portal_fee_paid", false)
		game_state.call("set_resource", &"essence", 10)
		game_state.emit_signal("echo_flags_changed")
		game_audio.call("clear_played_log")
		failed += _assert(str(portal.call("begin_entry")) == "reject", "portal confirm rejects a short fee")
		failed += _assert(bool(game_audio.call("did_play", &"sfx_ui_deny")), "short fee plays sfx_ui_deny")
		failed += _assert(not bool(game_audio.call("did_play", &"sfx_tree_deny")), "short fee does not use the tree deny")
		failed += _assert(not bool(game_audio.call("did_play", &"mus_fruit_sting")), "short fee has no fruit sting")
		failed += _assert(not bool(game_audio.call("did_play", &"mus_ascend_sting")), "short fee has no ascend sting")
		failed += _assert(int(game_state.get("essence")) == 10, "short confirm does not spend")
		failed += _assert(bool(portal.call("is_fee_confirm_open")), "reject keeps the confirm open")
		var yes_btn: Button = tree_root.get_node_or_null("EchoPortalConfirm/Panel/Yes") as Button
		var no_btn: Button = tree_root.get_node_or_null("EchoPortalConfirm/Panel/No") as Button
		var fee_panel: Control = tree_root.get_node_or_null("EchoPortalConfirm/Panel") as Control
		failed += _assert(yes_btn != null and yes_btn.disabled, "confirm yes disabled when short")
		failed += _assert(no_btn != null and no_btn.text == "Not now" and not no_btn.disabled, "Not now is enabled")
		if no_btn and fee_panel:
			var panel_h: float = fee_panel.offset_bottom - fee_panel.offset_top
			if panel_h < 1.0:
				panel_h = fee_panel.size.y
			failed += _assert(
				no_btn.position.y + no_btn.size.y <= panel_h + 1.0,
				"Not now sits inside the fee panel (btn y %.0f h %.0f panel %.0f)" % [no_btn.position.y, no_btn.size.y, panel_h]
			)
		# Drop the live wiring, then reopen so a stale portal cannot keep the click.
		if no_btn:
			var stale: Array = no_btn.pressed.get_connections()
			for stale_v: Variant in stale:
				if typeof(stale_v) == TYPE_DICTIONARY:
					var stale_cb: Callable = (stale_v as Dictionary).get("callable", Callable())
					if no_btn.pressed.is_connected(stale_cb):
						no_btn.pressed.disconnect(stale_cb)
		failed += _assert(str(portal.call("begin_entry")) == "reject", "reopen still rejects a short fee")
		no_btn = tree_root.get_node_or_null("EchoPortalConfirm/Panel/No") as Button
		failed += _assert(no_btn != null and no_btn.pressed.get_connections().size() >= 1, "Not now rebound to the live portal")
		if no_btn:
			no_btn.pressed.emit()
		await process_frame
		failed += _assert(not bool(portal.call("is_fee_confirm_open")), "Not now closes the fee UI")
		failed += _assert(not bool(live.call("world_input_blocked")), "Not now unblocks world clicks")
		game_state.call("set_resource", &"essence", 30)
		failed += _assert(bool(game_audio.call("is_hub_music_playing")), "hub bed before the echo")
		failed += _assert(str(portal.call("begin_entry")) == "confirm", "30 Essence opens the fee confirm")
		failed += _assert(int(game_state.get("essence")) == 30, "confirm alone does not spend")
		game_audio.call("clear_played_log")
		failed += _assert(str(portal.call("confirm_fee")) == "enter", "confirm enters the battle")
		failed += _assert(not bool(game_audio.call("did_play", &"mus_fruit_sting")), "no fruit sting on the fee")
		failed += _assert(not bool(game_audio.call("did_play", &"mus_ascend_sting")), "no ascend sting on the fee")
		failed += _assert(int(game_state.get("essence")) == 0 and bool(game_state.get("portal_fee_paid")), "entry spends 30 once")
		failed += _assert(bool(echo.get("in_battle")) and bool(game_audio.call("is_hub_suspended")), "battle suspends the hub bed")
		failed += _assert(not bool(game_audio.call("is_hub_stream_playing")), "battle is silent")
		failed += _assert(bool(game_audio.call("is_hub_bed_paused")), "battle pauses the hub bed in place")
		game_audio.call("clear_played_log")
		game_audio.call("play", &"mus_fruit_sting")
		game_audio.call("play", &"mus_ascend_sting")
		failed += _assert(not bool(game_audio.call("did_play", &"mus_fruit_sting")), "battle blocks the fruit sting")
		failed += _assert(not bool(game_audio.call("did_play", &"mus_ascend_sting")), "battle blocks the ascend sting")
		pause_menu.call("_on_save_pressed")
		failed += _assert(bool(game_audio.call("did_play", &"sfx_ui_cancel")), "battle save deny is sfx_ui_cancel")
		failed += _assert(not bool(game_audio.call("did_play", &"sfx_tree_deny")), "battle save deny is not the tree deny")
		var battle_view: Node = tree_root.get_node_or_null("EchoBattle")
		failed += _assert(battle_view != null and bool(battle_view.call("is_flee_shown")), "battle offers Flee outside the window")
		failed += _assert(not bool(battle_view.call("is_spare_shown")), "Spare stays hidden above 10%")
		failed += _assert(str(battle_view.call("speech_text")).find("does not raise her voice") >= 0, "opening narrator")
		failed += _assert(str(battle_view.call("speech_text")).find("should not have opened this") >= 0, "opening uses echo_01_intro")
		var echo_name_lbl: Label = battle_view.get_node_or_null("EchoName") as Label
		failed += _assert(echo_name_lbl != null and echo_name_lbl.text.find("Elaia") >= 0, "opening names Elaia")
		var pause_save: Button = pause_menu.get_node_or_null("Panel/BtnSave") as Button
		pause_menu.call("open_pause")
		failed += _assert(pause_save != null and pause_save.disabled, "Save disabled while the echo is open")
		pause_menu.call("resume_game")
		failed += _assert(bool(game_audio.call("is_hub_suspended")), "pause resume does not restart the bed")
		echo.call("finish_battle", "flee")
		await process_frame
		failed += _assert(not bool(echo.get("in_battle")), "flee leaves the battle")
		failed += _assert(bool(game_state.get("portal_fee_paid")) and not bool(game_state.get("forge_key")), "flee keeps the paid fee")
		failed += _assert(not bool(game_audio.call("is_hub_suspended")) and bool(game_audio.call("is_hub_music_playing")), "hub bed resumes after the echo")
		game_state.call("set_resource", &"essence", 4)
		failed += _assert(str(portal.call("begin_entry")) == "enter", "re-entry skips the fee")
		failed += _assert(int(game_state.get("essence")) == 4, "re-entry does not spend")
		var return_view: Node = tree_root.get_node_or_null("EchoBattle")
		failed += _assert(return_view != null and str(return_view.call("speech_text")).find("You came back") >= 0, "re-entry return flavour")
		echo.call("finish_battle", "flee")
		await process_frame
		game_state.call("set_resource", &"manashards", 4)
		game_state.set("forge_key", false)
		failed += _assert(bool(save_service.call("save_game", 1)), "save the paid portal")
		game_state.call("set_resource", &"manashards", 90)
		game_state.set("forge_key", true)
		echo.set("in_battle", true)
		pause_menu.call("_do_load_slot", "manual", 1)
		failed += _assert(not bool(echo.get("in_battle")), "load abandons the fight")
		failed += _assert(int(game_state.get("manashards")) == 4 and not bool(game_state.get("forge_key")), "load does not keep battle rewards")
		failed += _assert(bool(game_state.get("portal_fee_paid")), "loaded fee stays paid")
	var leftover_battle: Node = tree_root.get_node_or_null("EchoBattle")
	if leftover_battle:
		leftover_battle.free()
	if is_instance_valid(live):
		live.free()
	paused = false
	echo.set("in_battle", false)
	echo.set("battle", null)
	if bool(game_audio.call("is_hub_suspended")):
		game_audio.call("resume_hub_after_battle")
	game_state.call("reset_for_new_game")
	save_service.call("delete_save")
	return failed


func _echo_totals(might: int, swift: int, ward: int = 5) -> Dictionary:
	return {
		"might": might,
		"arcana": 5,
		"resilience": 5,
		"ward": ward,
		"vitality": 5,
		"swiftness": swift,
		"fate": 5,
	}


func _pass_e_idle(tree_root: Window, game_state: Node, save_service: Node, backpack: Node, content_strings: Node) -> int:
	var failed: int = 0
	var jobs: Node = tree_root.get_node_or_null("ForgeJobs")
	if jobs == null:
		return _assert(false, "pass e forge jobs")
	jobs.call("set_autosave_enabled", false)
	jobs.call("set_dev_speed_override", 1.0)
	var minutes: int = int(game_state.call("ancient_duration_minutes"))
	var raw_body: String = str(content_strings.call("get_text", "tree_grow_ancient_confirm_body"))
	failed += _assert(raw_body.find("{minutes}") >= 0 and raw_body.find("10") < 0, "minutes token is not hardcoded")
	var body: String = str(content_strings.call("get_text", "tree_grow_ancient_confirm_body", {"minutes": minutes}))
	failed += _assert(body.find("PLACEHOLDER") < 0 and body.find("%d minutes" % minutes) >= 0, "ancient confirm minutes come from duration")
	failed += _assert(minutes == 10, "600s duration is 10 minutes")
	failed += _assert(int(float(game_state.call("ancient_duration_sec")) / 60.0) == minutes, "minutes helper matches duration")
	failed += _assert(str(content_strings.call("get_text", "tree_grow_ancient_confirm_title")) == "Grow to Ancient?", "ancient confirm title")
	failed += _assert(str(content_strings.call("get_text", "tree_grow_ancient_confirm_yes")) == "Grow to Ancient", "ancient confirm yes")
	failed += _assert(str(content_strings.call("get_text", "tree_grow_ancient_confirm_no")) == "Not yet", "ancient confirm no")
	failed += _assert(str(content_strings.call("get_text", "tree_ancient_timer_label", {"time": "9:05"})) == "Fruit falls in 9:05", "timer label")
	failed += _assert(str(content_strings.call("get_text", "tree_grow_confirm")) == "Grow into {next_stage}?", "generic grow confirm unchanged")
	failed += _assert(str(content_strings.call("get_text", "tree_at_ancient_idle")).find("waiting") >= 0, "tree_at_ancient_idle kept")
	failed += _assert(str(content_strings.call("get_text", "ancient_grow_confirm_body")).find("PLACEHOLDER") >= 0, "placeholder key kept unused")
	failed += _assert(str(content_strings.call("get_text", "fruit_harvest_toast")).find("Primordial Fruit") >= 0, "timer end reuses fruit_harvest_toast")
	failed += _assert(absf(float(game_state.call("ancient_duration_sec")) - 600.0) < 0.01, "ancient duration config is 600")
	failed += _assert(absf(float(game_state.call("offline_reset_active_sec")) - 180.0) < 0.01, "offline reset active sec is 180")
	var sight: Dictionary = game_state.call("get_upgrade_def", "shard_sight")
	failed += _assert(absf(float(sight.get("value_per_rank", 0.0)) - 0.5) < 0.001, "shard sight +0.5 per rank")
	failed += _assert(int(sight.get("cost_base", 0)) == 800, "shard sight cost base 800")
	game_state.call("reset_for_new_game")
	var ranks_ss: Dictionary = game_state.get("upgrade_ranks")
	ranks_ss["shard_sight"] = 1
	game_state.set("upgrade_ranks", ranks_ss)
	failed += _assert(int(game_state.call("get_upgrade_cost", "shard_sight")) == 1600, "shard sight rank 1 costs 1600")
	var sight_pulse: Dictionary = game_state.call("apply_water_pulse")
	var sight_shards: int = int(sight_pulse.get("shards", 0))
	failed += _assert(sight_shards >= 1 and sight_shards <= 3, "sight rank 1 without can grants the whole part")
	var sight_rem: float = float((game_state.get("harvest_accum") as Dictionary).get("manashards", -1.0))
	failed += _assert(absf(sight_rem - 0.5) < 0.001, "sight rank 1 keeps a 0.5 remainder")
	## Tier checkpoints.
	var m30: float = 30.0 * 60.0
	var h2: float = 2.0 * 3600.0
	var h8: float = 8.0 * 3600.0
	var h24: float = 24.0 * 3600.0
	failed += _assert(absf(float(game_state.call("offline_effective_seconds", m30)) - 180.0) < 0.02, "tier 30min → 180")
	failed += _assert(absf(float(game_state.call("offline_effective_seconds", h2)) - 270.0) < 0.02, "tier 2h → 270")
	failed += _assert(absf(float(game_state.call("offline_effective_seconds", h8)) - 356.4) < 0.02, "tier 8h → 356.4")
	failed += _assert(absf(float(game_state.call("offline_effective_seconds", h24)) - 452.4) < 0.02, "tier 24h → 452.4")
	## Nothing moves offline while Ancient.
	game_state.call("reset_for_new_game")
	game_state.call("set_resource", &"wood", 4)
	game_state.call("set_resource", &"essence", 6)
	game_state.call("set_resource", &"manashards", 8)
	game_state.set("wisp_count", 1)
	game_state.call("_ensure_wisp_slots")
	game_state.call("try_assign_wisp", 0, "harvest_tree")
	jobs.call("set_keeper_task", "harvest", "wood", true)
	game_state.call("set_resource", &"stone", 40)
	jobs.call("try_begin_job", "crucible", "sapsteel")
	var prog_before: float = float(jobs.call("job_progress", "crucible"))
	game_state.call("_set_stage", &"ancient")
	game_state.set("ancient_remaining_sec", 400.0)
	game_state.set("offline_closed_sec", 50.0)
	var blocked: Variant = jobs.call("apply_offline_seconds", h2)
	failed += _assert(typeof(blocked) == TYPE_DICTIONARY and int((blocked as Dictionary).get("harvest", -1)) == 0, "ancient offline harvest is 0")
	jobs.call("apply_saved_offline_gap", h2)
	failed += _assert(int(game_state.get("wood")) == 4, "ancient offline does not bank wood")
	failed += _assert(int(game_state.get("essence")) == 6, "ancient offline does not bank essence")
	failed += _assert(int(game_state.get("manashards")) == 8, "ancient offline does not bank shards")
	failed += _assert(absf(float(game_state.get("ancient_remaining_sec")) - 400.0) < 0.01, "ancient timer ignores offline")
	failed += _assert(absf(float(jobs.call("job_progress", "crucible")) - prog_before) < 0.01, "ancient offline does not advance the forge")
	failed += _assert(absf(float(game_state.get("offline_closed_sec")) - 50.0) < 0.01, "ancient offline does not consume the curve")
	## Timer hits 0 → Fruit commits.
	game_state.call("reset_for_new_game")
	game_state.call("_set_stage", &"ancient")
	failed += _assert(absf(float(game_state.get("ancient_remaining_sec")) - 600.0) < 0.01, "grow to ancient starts at 600")
	game_state.set("ancient_remaining_sec", 0.4)
	game_state.call("tick_ancient", 0.2)
	failed += _assert(not bool(game_state.get("fruit_committed")), "timer still running at 0.2s left")
	game_state.call("tick_ancient", 0.3)
	failed += _assert(bool(game_state.get("fruit_committed")), "timer at 0 auto-harvests")
	failed += _assert(absf(float(game_state.get("ancient_remaining_sec"))) < 0.001, "timer stays at 0")
	failed += _assert(int(game_state.get("lifetime_fruit_harvested")) >= 1, "auto-harvest counts the fruit")
	## 1 wisp × 200s = 10 wood. Keeper with a tool × 10s = 10 wood.
	game_state.call("reset_for_new_game")
	game_state.set("wisp_count", 1)
	game_state.call("_ensure_wisp_slots")
	game_state.call("try_assign_wisp", 0, "harvest_tree")
	game_state.call("apply_wisp_pulses", 200.0)
	failed += _assert(int(game_state.get("wood")) == 10, "1 wisp for 200s gives 10 wood")
	game_state.call("reset_for_new_game")
	backpack.call("set_count", "stone_axe", 1)
	game_state.call("accumulate_keeper_harvest", &"wood", 10.0)
	failed += _assert(int(game_state.get("wood")) == 10, "keeper with a tool for 10s gives 10 wood")
	## v8 Ancient loads the full 600.
	var v8: Dictionary = {"stage_id": "ancient", "fruit_ready": true}
	var migrated: Dictionary = save_service.call("_migrate", 8, v8)
	game_state.call("apply_save_dict", migrated)
	failed += _assert(str(game_state.get("stage_id")) == "ancient", "v8 ancient stage")
	failed += _assert(absf(float(game_state.get("ancient_remaining_sec")) - 600.0) < 0.01, "v8 ancient loads 600")
	## Curve continues under 180s of play, and restarts at 180s.
	game_state.call("reset_for_new_game")
	jobs.call("set_keeper_task", "harvest", "wood", true)
	game_state.set("offline_closed_sec", 1200.0)
	game_state.set("active_since_load_sec", 60.0)
	var continued: Variant = jobs.call("apply_saved_offline_gap", 1200.0)
	failed += _assert(typeof(continued) == TYPE_DICTIONARY and int((continued as Dictionary).get("harvest", -1)) == 35, "reopen under 180s prices minutes 20-40")
	failed += _assert(int(game_state.get("wood")) == 35, "continued curve banks 35 wood")
	failed += _assert(absf(float(game_state.get("offline_closed_sec")) - 2400.0) < 0.01, "continued curve stores 40 minutes")
	failed += _assert(absf(float(game_state.get("active_since_load_sec"))) < 0.01, "load clears active time")
	game_state.call("reset_for_new_game")
	jobs.call("set_keeper_task", "harvest", "wood", true)
	game_state.set("offline_closed_sec", 1200.0)
	game_state.set("active_since_load_sec", 180.0)
	var restarted: Variant = jobs.call("apply_saved_offline_gap", 1200.0)
	failed += _assert(typeof(restarted) == TYPE_DICTIONARY and int((restarted as Dictionary).get("harvest", -1)) == 60, "180s of play restarts the curve")
	failed += _assert(int(game_state.get("wood")) == 60, "reset curve banks 60 wood")
	failed += _assert(absf(float(game_state.get("offline_closed_sec")) - 1200.0) < 0.01, "reset curve stores only the new closure")
	game_state.call("reset_for_new_game")
	save_service.call("delete_save")
	return failed


func _forge_duration_ticks(tree_root: Window, game_state: Node, backpack: Node) -> int:
	var failed: int = 0
	var jobs: Node = tree_root.get_node_or_null("ForgeJobs")
	var equipment: Node = tree_root.get_node_or_null("Equipment")
	failed += _assert(jobs != null and equipment != null, "duration nodes")
	if jobs == null or equipment == null:
		return failed
	jobs.call("set_autosave_enabled", false)
	jobs.call("set_dev_speed_override", -1.0)
	failed += _assert(absf(float(jobs.call("dev_time_scale")) - 1.0) < 0.01, "duration playtest scale is 1")
	var rows: Array = [
		["crucible", "sapsteel", 60.0, false],
		["mill", "heartwood_bits", 60.0, false],
		["press", "amberbind", 45.0, false],
		["anvil", "rootsteel_edge", 600.0, true],
		["reliquary", "oakheart_knot", 600.0, true],
	]
	for row: Array in rows:
		var station: String = str(row[0])
		var recipe: String = str(row[1])
		var spec: float = float(row[2])
		var gear: bool = bool(row[3])
		failed += _forge_one_clock(jobs, game_state, backpack, equipment, station, recipe, spec, gear, 1.0, 0)
		failed += _forge_one_clock(jobs, game_state, backpack, equipment, station, recipe, spec, gear, 1.0, 2)
		failed += _forge_one_clock(jobs, game_state, backpack, equipment, station, recipe, spec, gear, 60.0, 0)
	jobs.call("set_dev_speed_override", 1.0)
	game_state.call("reset_for_new_game")
	return failed


func _forge_one_clock(jobs: Node, game_state: Node, backpack: Node, equipment: Node, station: String, recipe: String, spec: float, gear: bool, bug_scale: float, wisps: int) -> int:
	var failed: int = 0
	game_state.call("reset_for_new_game")
	if bug_scale > 1.5:
		jobs.call("set_dev_speed_override", bug_scale)
	else:
		jobs.call("set_dev_speed_override", -1.0)
	failed += _assert(absf(float(jobs.call("dev_time_scale")) - bug_scale) < 0.05, "%s dev scale %.0f" % [station, bug_scale])
	_forge_stock(game_state, backpack, station)
	if wisps > 0:
		game_state.set("wisp_count", wisps)
		game_state.call("_ensure_wisp_slots")
		for i: int in wisps:
			var joined: String = str(game_state.call("try_assign_wisp", i, station))
			failed += _assert(joined != "full" and joined != "invalid", "%s wisp %d joins" % [station, i])
	jobs.call("set_keeper_working", station, true)
	var worker: float = 1.0 + 0.1 * float(wisps)
	failed += _assert(absf(float(jobs.call("station_speed_mult", station)) - worker) < 0.02, "%s speed with %d wisps" % [station, wisps])
	failed += _assert(str(jobs.call("try_begin_job", station, recipe)) == "ok", "%s job starts" % station)
	var expected: float = spec / (bug_scale * worker)
	var margin: float = minf(0.5, expected * 0.25)
	if margin < 0.02:
		margin = 0.02
	_forge_tick(jobs, expected - margin)
	var early_ok: bool = bool(jobs.call("has_job", station)) and float(jobs.call("job_progress", station)) + 0.01 < spec and str(jobs.call("job_line", station)) != ""
	var who: String = "keeper alone" if wisps == 0 else "keeper+%d wisps" % wisps
	if station == "anvil" and bug_scale <= 1.5:
		failed += _assert(early_ok, "anvil %s not done just before spec" % who)
	else:
		failed += _assert(early_ok, "%s %s not done just before duration" % [station, who])
	var elapsed: float = expected - margin
	var steps: int = 0
	while bool(jobs.call("has_job", station)) and steps < 80:
		jobs.call("_process", 0.05)
		elapsed += 0.05
		steps += 1
	var finished: bool = not bool(jobs.call("has_job", station))
	if station == "anvil" and bug_scale <= 1.5:
		failed += _assert(finished, "anvil %s done just after spec" % who)
	else:
		failed += _assert(finished, "%s %s done just after duration" % [station, who])
	if gear:
		failed += _assert(int(equipment.call("unequipped_count", recipe)) == 1, "%s output" % station)
	else:
		failed += _assert(int(backpack.call("get_count", recipe)) == 1, "%s output" % station)
	var factor: float = spec / maxf(elapsed, 0.01)
	var want: float = bug_scale * worker
	print("FORGE_DUR station=%s wisps=%d scale=%.0f spec=%.2f measured=%.2f factor=%.2f" % [station, wisps, bug_scale, spec, elapsed, factor])
	failed += _assert(absf(factor - want) / want < 0.12, "%s factor %.2f vs %.2f" % [station, factor, want])
	return failed


func _forge_stock(game_state: Node, backpack: Node, station: String) -> void:
	if station == "crucible":
		game_state.call("set_resource", &"stone", 20)
	elif station == "mill":
		game_state.call("set_resource", &"wood", 20)
	elif station == "press":
		game_state.call("set_resource", &"food", 15)
	elif station == "anvil":
		backpack.call("set_count", "sapsteel", 12)
		backpack.call("set_count", "heartwood_bits", 6)
		backpack.call("set_count", "amberbind", 4)
		game_state.call("set_resource", &"essence", 150)
	else:
		backpack.call("set_count", "sapsteel", 6)
		backpack.call("set_count", "heartwood_bits", 6)
		backpack.call("set_count", "amberbind", 6)
		game_state.call("set_resource", &"essence", 100)


func _forge_tick(jobs: Node, seconds: float) -> void:
	var left: float = seconds
	while left > 0.001:
		var step: float = minf(0.25, left)
		jobs.call("_process", step)
		left -= step


func _wants_check_only() -> bool:
	if OS.get_environment("MANAFORGE_CHECK_ONLY") == "1":
		return true
	var args: PackedStringArray = OS.get_cmdline_user_args()
	args.append_array(OS.get_cmdline_args())
	return args.has("--check-only")


func _check_only_load() -> int:
	## Compile and load the companion scripts. Does not run the suite.
	var failed: int = 0
	var paths: PackedStringArray = PackedStringArray([
		"res://scripts/feet_box.gd",
		"res://scripts/keeper.gd",
		"res://scripts/elaia.gd",
		"res://scripts/character_sheet.gd",
		"res://scripts/hud.gd",
		"res://scripts/main.gd",
		"res://scripts/forge_room.gd",
		"res://scripts/gatherable.gd",
		"res://scripts/manatree.gd",
		"res://scripts/forge_station.gd",
		"res://scripts/runestone.gd",
		"res://scripts/autoload/game_state.gd",
		"res://scripts/autoload/forge_jobs.gd",
		"res://scripts/batch_job.gd",
		"res://scripts/batch_panel.gd",
		"res://scripts/batch_world_bars.gd",
		"res://scripts/keepers_bench.gd",
		"res://scripts/autoload/anim_preview_hotkey.gd",
		"res://tools/anim_preview.gd",
		"res://tools/debug/debug_panel.gd",
		"res://scripts/pause_menu.gd",
		"res://scripts/battle/battle_view.gd",
		"res://scripts/battle/battle_rng.gd",
		"res://scripts/battle/spawn_roller.gd",
	])
	for path: String in paths:
		var loaded: Resource = load(path)
		failed += _assert(loaded != null, "check-only loads %s" % path)
		if loaded is GDScript:
			failed += _assert((loaded as GDScript).can_instantiate(), "check-only compiles %s" % path)
	var gs: Node = root.get_node_or_null("GameState")
	failed += _assert(gs != null and is_equal_approx(float(gs.call("actor_work_rate", "elaia", "")), 0.8), "check-only elaia work rate")
	failed += _assert(gs != null and is_equal_approx(float(gs.call("actor_work_rate", "elaia", "reliquary")), 1.5), "check-only elaia reliquary rate")
	return failed


func _elaia_companion_asserts(tree_root: Window, game_state: Node, backpack: Node) -> int:
	var failed: int = 0
	var jobs: Node = tree_root.get_node_or_null("ForgeJobs")
	failed += _assert(jobs != null, "elaia companion jobs")
	if jobs == null:
		return failed
	game_state.call("reset_for_new_game")
	jobs.call("set_autosave_enabled", false)
	var keeper_cls = load("res://scripts/keeper.gd")
	var bare: float = float(game_state.call("get_move_speed"))
	failed += _assert(is_equal_approx(keeper_cls.walk_speed_scale_for(bare), bare / 80.0), "walk scale is velocity / 80 before Stride")
	var ranks: Dictionary = game_state.get("upgrade_ranks")
	ranks["keeper_stride"] = 1
	game_state.set("upgrade_ranks", ranks)
	var strode: float = float(game_state.call("get_move_speed"))
	failed += _assert(strode > bare, "Keeper's Stride raises get_move_speed")
	failed += _assert(is_equal_approx(keeper_cls.walk_speed_scale_for(strode), strode / 80.0), "walk scale follows Stride")
	failed += _assert(is_equal_approx(float(game_state.call("actor_walk_ref_speed", "elaia")), 88.0), "elaia walk reference is 88")
	failed += _assert(is_equal_approx(float(game_state.call("actor_move_mult", "elaia")), 1.0), "elaia move_speed_mult is 1")
	game_state.call("reset_for_new_game")
	backpack.call("reset_for_new_game")
	game_state.set("harvest_accum", {})
	var full: int = int(game_state.call("accumulate_keeper_harvest", &"wood", 4.0, 1.0))
	failed += _assert(full == 2, "4s harvest at rate 1 grants 2 wood")
	game_state.call("reset_for_new_game")
	backpack.call("reset_for_new_game")
	game_state.set("harvest_accum", {})
	var scaled: int = int(game_state.call("accumulate_keeper_harvest", &"wood", 4.0, 0.8))
	var accum: Dictionary = game_state.get("harvest_accum")
	failed += _assert(scaled == 1, "4s harvest at 0.8 grants 1 wood")
	failed += _assert(is_equal_approx(float(accum.get("wood", -1.0)), 0.6), "0.8 harvest banks the 0.6 remainder")
	jobs.call("set_elaia_working", "mill", true)
	failed += _assert(is_equal_approx(float(jobs.call("station_speed_mult", "mill")), 1.0), "elaia mill crafting speed is 1.0")
	jobs.call("note_elaia_idle")
	jobs.call("set_elaia_working", "reliquary", true)
	failed += _assert(is_equal_approx(float(jobs.call("station_speed_mult", "reliquary")), 1.0), "elaia reliquary crafting speed is 1.0")
	failed += _assert(is_equal_approx(float(jobs.call("station_speed_mult", "mill")), 0.0), "mill is idle after Elaia moves to the Reliquary")
	game_state.set("wisp_count", 5)
	game_state.call("_ensure_wisp_slots")
	for i: int in range(4):
		game_state.call("try_assign_wisp", i, "mill")
	var with_wisps: float = float(jobs.call("station_speed_mult", "mill"))
	failed += _assert(is_equal_approx(with_wisps, 0.4), "four wisps add 0.4 on the mill (got %s)" % with_wisps)
	failed += _assert(str(game_state.call("try_assign_wisp", 4, "mill")) == "full", "fifth wisp on her target is full")
	jobs.call("note_elaia_idle")
	game_state.call("reset_for_new_game")
	jobs.call("set_elaia_task", "harvest", "wood", true)
	var elaia_off: Dictionary = jobs.call("apply_offline_seconds", 1800.0)
	var elaia_wood: int = int(elaia_off.get("harvest", -1))
	game_state.call("reset_for_new_game")
	jobs.call("set_keeper_task", "harvest", "wood", true)
	var keeper_off: Dictionary = jobs.call("apply_offline_seconds", 1800.0)
	var keeper_wood: int = int(keeper_off.get("harvest", -1))
	failed += _assert(elaia_wood > 0 and elaia_wood < keeper_wood, "offline elaia harvest is the reduced rate")
	game_state.call("reset_for_new_game")
	game_state.set("stage_id", &"ancient")
	game_state.set("fruit_committed", true)
	jobs.call("set_elaia_task", "harvest", "wood", true)
	var blocked: Dictionary = jobs.call("apply_offline_seconds", 1800.0)
	failed += _assert(int(blocked.get("harvest", -1)) == 0, "ancient or frozen offline yields nothing")
	game_state.call("reset_for_new_game")
	jobs.call("note_elaia_idle")
	var idle: Dictionary = jobs.call("elaia_task")
	failed += _assert(not bool(idle.get("working", true)), "no job leaves Elaia idle")
	game_state.set("echo_01_redeemed", true)
	game_state.set("first_relic_crafted", true)
	jobs.call("set_elaia_task", "harvest", "wood", true)
	jobs.call("prepare_ascend")
	var after: Dictionary = jobs.call("elaia_task")
	failed += _assert(not bool(after.get("working", true)), "ascension clears her job")
	failed += _assert(bool(game_state.call("elaia_in_party")), "ascension keeps her in the party")
	game_state.set("elaia_area", "forge")
	game_state.set("elaia_pos", Vector2(120.0, 340.0))
	game_state.set("elaia_has_pos", true)
	game_state.set("elaia_facing", "east")
	jobs.call("set_elaia_task", "forge", "reliquary", true)
	var blob: Dictionary = game_state.call("to_save_dict")
	game_state.call("reset_for_new_game")
	game_state.call("apply_save_dict", blob)
	failed += _assert(str(game_state.get("elaia_area")) == "forge", "save round-trip area")
	failed += _assert(bool(game_state.get("elaia_has_pos")), "save round-trip has pos")
	var loaded_pos: Vector2 = game_state.get("elaia_pos")
	failed += _assert(is_equal_approx(loaded_pos.x, 120.0) and is_equal_approx(loaded_pos.y, 340.0), "save round-trip position")
	failed += _assert(str(game_state.get("elaia_facing")) == "east", "save round-trip facing")
	var loaded_task: Dictionary = jobs.call("elaia_task")
	failed += _assert(bool(loaded_task.get("working", false)) and str(loaded_task.get("target", "")) == "reliquary", "save round-trip job")
	var spared_only: Dictionary = {"stage_id": "sapling", "echo_01_redeemed": true}
	game_state.call("apply_save_dict", spared_only)
	failed += _assert(bool(game_state.call("elaia_in_party")), "v9 spared save infers the join")
	failed += _assert(bool(game_state.get("elaia_join_seen")), "migrated join does not replay the dialogue")
	var fresh: Dictionary = {"stage_id": "sapling", "echo_01_redeemed": false, "first_relic_crafted": false, "elaia_join_seen": false}
	game_state.call("apply_save_dict", fresh)
	failed += _assert(not bool(game_state.call("elaia_in_party")), "explicit unjoined save stays unjoined")
	failed += _assert(not bool(game_state.call("elaia_join_pending")), "unjoined save has no dialogue")
	game_state.call("reset_for_new_game")
	return failed


func _elaia_join_check(tree_root: Window, game_state: Node, backpack: Node) -> int:
	var failed: int = 0
	var jobs: Node = tree_root.get_node_or_null("ForgeJobs")
	var equipment: Node = tree_root.get_node_or_null("Equipment")
	failed += _assert(jobs != null and equipment != null, "elaia join nodes")
	if jobs == null or equipment == null:
		return failed
	var packed: PackedScene = load("res://scenes/hud.tscn") as PackedScene
	failed += _assert(packed != null, "elaia party hud loads")
	if packed == null:
		return failed
	var hud: Node = packed.instantiate()
	tree_root.add_child(hud)
	await process_frame
	game_state.call("reset_for_new_game")
	jobs.call("set_autosave_enabled", false)
	jobs.call("set_dev_speed_override", 1.0)
	game_state.set("echo_01_redeemed", true)
	game_state.set("first_relic_crafted", false)
	game_state.set("elaia_legacy_joined", false)
	hud.call("_refresh_party_bar")
	var elaia_slot: Control = hud.get_node_or_null("PartyBar/Column/Elaia") as Control
	var keeper_slot: Control = hud.get_node_or_null("PartyBar/Column/Keeper") as Control
	var wisp_slot: Control = hud.get_node_or_null("PartyBar/Column/Wisps") as Control
	failed += _assert(not bool(game_state.call("elaia_in_party")), "Spare with no Relic does not join Elaia")
	failed += _assert(elaia_slot != null and not elaia_slot.visible, "no Elaia portrait after Spare with no Relic")
	hud.call("party_click", "elaia")
	failed += _assert(str(game_state.get("selected_companion_id")) == "", "Spare alone does not select Elaia")
	_forge_stock(game_state, backpack, "reliquary")
	jobs.call("set_keeper_working", "reliquary", true)
	failed += _assert(str(jobs.call("try_begin_job", "reliquary", "oakheart_knot")) == "ok", "first relic job starts")
	jobs.call("_process", 600.0)
	failed += _assert(not bool(jobs.call("has_job", "reliquary")), "first relic craft completes")
	failed += _assert(int(equipment.call("unequipped_count", "oakheart_knot")) == 1, "first relic is in the inventory")
	failed += _assert(bool(game_state.get("first_relic_crafted")), "first relic sets the flag")
	failed += _assert(bool(game_state.call("elaia_in_party")), "Elaia joins after the first Relic craft")
	hud.call("_refresh_party_bar")
	failed += _assert(not elaia_slot.visible and keeper_slot.visible, "Elaia portrait waits for the Clearing dialogue")
	failed += _assert(bool(game_state.call("elaia_in_party")), "her body is in the party before the dialogue")
	game_state.set("elaia_join_seen", true)
	hud.call("_refresh_party_bar")
	failed += _assert(elaia_slot.visible and keeper_slot.visible, "Elaia portrait shows after the dialogue")
	failed += _assert(wisp_slot.get_index() < keeper_slot.get_index() and keeper_slot.get_index() < elaia_slot.get_index(), "portrait order is Wisps, Keeper, then Elaia")
	var old_save: Dictionary = {
		"stage_id": "sapling",
		"echo_01_redeemed": true,
		"forge_key": false,
		"gear_inventory": {},
		"equipment_equipped": {},
	}
	game_state.call("apply_save_dict", old_save)
	hud.call("_refresh_party_bar")
	failed += _assert(bool(game_state.get("echo_01_redeemed")) and not bool(game_state.get("first_relic_crafted")), "old join does not invent a relic craft")
	failed += _assert(bool(game_state.call("elaia_in_party")), "old save with Elaia joined and no Relic keeps her")
	failed += _assert(elaia_slot.visible, "old save still shows her portrait")
	var relic_save: Dictionary = {
		"stage_id": "sapling",
		"echo_01_redeemed": false,
		"forge_key": false,
		"gear_inventory": {"oakheart_knot": 1},
		"equipment_equipped": {},
	}
	game_state.call("apply_save_dict", relic_save)
	failed += _assert(bool(game_state.get("first_relic_crafted")), "missing flag defaults true when the save holds a relic")
	failed += _assert(not bool(game_state.call("elaia_in_party")), "a relic without Spare does not join Elaia")
	hud.queue_free()
	await process_frame
	game_state.call("reset_for_new_game")
	jobs.call("set_dev_speed_override", 1.0)
	if failed == 0:
		print("ELAIA_JOIN_OK")
	return failed


func _party_bar_check(tree_root: Window, game_state: Node) -> int:
	var failed: int = 0
	var packed: PackedScene = load("res://scenes/hud.tscn") as PackedScene
	failed += _assert(packed != null, "party bar hud loads")
	if packed == null:
		return failed
	var hud: Node = packed.instantiate()
	tree_root.add_child(hud)
	await process_frame
	game_state.call("reset_for_new_game")
	game_state.call("clear_selection")
	await process_frame
	var bar: Control = hud.get_node_or_null("PartyBar") as Control
	var keeper_slot: Control = hud.get_node_or_null("PartyBar/Column/Keeper") as Control
	var wisp_slot: Control = hud.get_node_or_null("PartyBar/Column/Wisps") as Control
	var elaia_slot: Control = hud.get_node_or_null("PartyBar/Column/Elaia") as Control
	failed += _assert(bar != null and bar.visible, "party bar visible with nothing selected")
	failed += _assert(keeper_slot != null and keeper_slot.visible, "keeper portrait with nothing selected")
	failed += _assert(wisp_slot != null and not wisp_slot.visible, "wisp portrait hidden with nothing selected")
	failed += _assert(hud.get_node_or_null("SelectionPanel") == null, "no gray selection box")
	hud.call("party_click", "keeper")
	failed += _assert(bool(game_state.get("keeper_selected")), "click keeper portrait selects the keeper")
	game_state.set("wisp_count", 2)
	game_state.call("_ensure_wisp_slots")
	game_state.call("select_group", [0, 1], false)
	await process_frame
	var count_label: Label = wisp_slot.get_node_or_null("Count") as Label
	failed += _assert(wisp_slot.visible, "wisp portrait while wisps are selected")
	failed += _assert(count_label != null and count_label.text == "x2", "wisp stack shows xN")
	failed += _assert(not bool(game_state.get("keeper_selected")), "wisp group does not keep the keeper")
	game_state.call("clear_selection")
	await process_frame
	failed += _assert(not wisp_slot.visible, "wisp portrait hides when selection clears")
	failed += _assert(keeper_slot.visible, "keeper portrait stays when selection clears")
	game_state.set("echo_01_redeemed", true)
	game_state.set("first_relic_crafted", false)
	game_state.set("elaia_legacy_joined", false)
	hud.call("_refresh_party_bar")
	failed += _assert(elaia_slot != null and not elaia_slot.visible, "no Elaia portrait after Spare without a Relic")
	game_state.set("first_relic_crafted", true)
	hud.call("_refresh_party_bar")
	failed += _assert(not elaia_slot.visible, "Elaia portrait waits for the Clearing dialogue")
	game_state.set("elaia_join_seen", true)
	hud.call("_refresh_party_bar")
	failed += _assert(elaia_slot.visible, "Elaia portrait after the Clearing dialogue")
	var order_column: Node = hud.get_node_or_null("PartyBar/Column")
	failed += _assert(order_column != null and wisp_slot.get_index() < keeper_slot.get_index() and keeper_slot.get_index() < elaia_slot.get_index(), "portrait order is Wisps, Keeper, Elaia")
	hud.call("party_click", "elaia")
	failed += _assert(str(game_state.get("selected_companion_id")) == "elaia", "click Elaia portrait selects her")
	failed += await _party_activity_check(hud, game_state, tree_root)
	hud.queue_free()
	await process_frame
	game_state.call("reset_for_new_game")
	return failed


func _party_activity_check(hud: Node, game_state: Node, tree_root: Window) -> int:
	var failed: int = 0
	var jobs: Node = tree_root.get_node_or_null("ForgeJobs")
	var strings: Node = tree_root.get_node_or_null("ContentStrings")
	var keeper_slot: Control = hud.get_node_or_null("PartyBar/Column/Keeper") as Control
	var elaia_slot: Control = hud.get_node_or_null("PartyBar/Column/Elaia") as Control
	var keeper_act: Label = hud.get_node_or_null("PartyBar/KeeperActivity") as Label
	var elaia_act: Label = hud.get_node_or_null("PartyBar/ElaiaActivity") as Label
	var info: Control = hud.get_node_or_null("PartyBar/Info") as Control
	var task: Label = hud.get_node_or_null("PartyBar/Info/Task") as Label
	failed += _assert(jobs != null and keeper_act != null and elaia_act != null and info != null and task != null, "activity labels exist")
	if jobs == null or keeper_act == null or elaia_act == null or info == null or task == null:
		return failed
	var selected_word: String = str(strings.call("get_text", "hud_activity_selected"))
	var idle_word: String = str(strings.call("get_text", "hud_activity_idle"))
	var stone_word: String = str(strings.call("get_text", "hud_activity_harvest_stone"))
	var berry_word: String = str(strings.call("get_text", "hud_activity_harvest_food"))
	game_state.set("elaia_join_seen", false)
	game_state.call("clear_selection")
	hud.call("_refresh_party_bar")
	await process_frame
	failed += _assert(not elaia_slot.visible and not elaia_act.visible and elaia_act.text == "", "no Elaia activity before she joins")
	failed += _assert(keeper_act.visible and is_equal_approx(keeper_act.position.y, keeper_slot.position.y), "keeper activity stays on the keeper row before Elaia joins — y %s slot %s" % [keeper_act.position.y, keeper_slot.position.y])
	failed += _assert(not info.visible and task.text == "", "shared info box shows no activity before Elaia joins")
	game_state.set("elaia_join_seen", true)
	jobs.call("set_keeper_task", "harvest", "stone", true)
	jobs.call("set_elaia_task", "harvest", "food", true)
	game_state.call("select_keeper")
	hud.call("_refresh_party_bar")
	await process_frame
	failed += _assert(is_equal_approx(keeper_act.position.y, keeper_slot.position.y), "keeper activity row matches the portrait when selected — y %s slot %s" % [keeper_act.position.y, keeper_slot.position.y])
	failed += _assert(is_equal_approx(elaia_act.position.y, elaia_slot.position.y), "elaia activity row matches the portrait when the keeper is selected — y %s slot %s" % [elaia_act.position.y, elaia_slot.position.y])
	failed += _assert(keeper_act.text == "%s\n%s" % [selected_word, stone_word], "selected keeper activity is beside the keeper — %s" % keeper_act.text)
	failed += _assert(elaia_act.text == " \n%s" % berry_word, "elaia activity stays on her row while the keeper is selected — %s" % elaia_act.text)
	failed += _assert(not info.visible and task.text == "", "shared info box shows no activity while someone is selected")
	var keeper_y: float = keeper_act.position.y
	var elaia_y: float = elaia_act.position.y
	game_state.call("clear_selection")
	hud.call("_refresh_party_bar")
	await process_frame
	failed += _assert(is_equal_approx(keeper_act.position.y, keeper_y) and is_equal_approx(elaia_act.position.y, elaia_y), "activity rows do not shift when selection clears")
	failed += _assert(keeper_act.text == " \n%s" % stone_word, "keeper keeps harvesting stone with nobody selected — %s" % keeper_act.text)
	failed += _assert(elaia_act.text == " \n%s" % berry_word, "elaia keeps harvesting berries with nobody selected — %s" % elaia_act.text)
	failed += _assert(keeper_act.text.find(selected_word) < 0 and elaia_act.text.find(selected_word) < 0, "nobody selected means no Selected line")
	failed += _assert(not info.visible and task.text == "", "shared info box shows no activity with nobody selected")
	game_state.call("select_keeper")
	hud.call("_refresh_party_bar")
	failed += _assert(keeper_act.text.begins_with(selected_word) and elaia_act.text.find(idle_word) < 0, "selecting the keeper does not rewrite Elaia's activity")
	jobs.call("set_keeper_task", "harvest", "stone", false)
	jobs.call("set_elaia_task", "harvest", "food", false)
	game_state.call("clear_selection")
	game_state.set("elaia_join_seen", true)
	return failed


func _forge_pass_a(tree_root: Window, game_state: Node, save_service: Node, backpack: Node) -> int:
	var failed: int = 0
	var jobs: Node = tree_root.get_node_or_null("ForgeJobs")
	var equipment: Node = tree_root.get_node_or_null("Equipment")
	failed += _assert(jobs != null and equipment != null, "forge pass a nodes")
	if jobs == null or equipment == null:
		return failed
	jobs.call("set_autosave_enabled", false)
	jobs.call("set_dev_speed_override", -1.0)
	failed += _assert(absf(float(jobs.call("dev_time_scale")) - 1.0) < 0.01, "playtest forge speed is 1")
	jobs.call("set_dev_speed_override", 1.0)
	failed += _assert(absf(float(jobs.call("dev_time_scale")) - 1.0) < 0.01, "verify pins forge speed at 1")
	game_state.call("reset_for_new_game")
	var h8: float = 8.0 * 3600.0
	var h24: float = 24.0 * 3600.0
	var m30: float = 30.0 * 60.0
	var h2: float = 2.0 * 3600.0
	failed += _assert(absf(float(jobs.call("offline_effective_seconds", 0.0))) < 0.001, "offline zero")
	failed += _assert(absf(float(jobs.call("offline_effective_seconds", m30)) - 180.0) < 0.02, "offline 30min is 180s")
	failed += _assert(absf(float(jobs.call("offline_effective_seconds", h2)) - 270.0) < 0.02, "offline 2h is 270s")
	failed += _assert(absf(float(jobs.call("offline_effective_seconds", h8)) - 356.4) < 0.02, "offline 8h is 356.4s")
	failed += _assert(absf(float(jobs.call("offline_effective_seconds", h24)) - 452.4) < 0.02, "offline 24h is 452.4s")
	jobs.call("set_keeper_task", "water", "manatree", true)
	var water: Variant = jobs.call("apply_offline_seconds", h8)
	failed += _assert(typeof(water) == TYPE_DICTIONARY and int((water as Dictionary).get("shards", -1)) == 712, "offline water shards use the midpoint")
	failed += _assert(typeof(water) == TYPE_DICTIONARY and int((water as Dictionary).get("essence", -1)) == 356, "offline water essence follows the curve")
	var task: Variant = jobs.call("keeper_task")
	failed += _assert(typeof(task) == TYPE_DICTIONARY and not bool((task as Dictionary).get("working", true)), "offline clears the keeper task")
	game_state.call("reset_for_new_game")
	jobs.call("set_keeper_task", "harvest", "wood", true)
	var gathered: Variant = jobs.call("apply_offline_seconds", 20.0)
	failed += _assert(typeof(gathered) == TYPE_DICTIONARY and int((gathered as Dictionary).get("harvest", -1)) == 1, "20s closed harvest banks one wood")
	failed += _assert(int(game_state.get("wood")) == 1, "offline harvest banks wood")
	game_state.call("reset_for_new_game")
	game_state.set("wisp_count", 1)
	game_state.call("_ensure_wisp_slots")
	game_state.call("try_assign_wisp", 0, "manatree")
	var wisp_off: Variant = jobs.call("apply_offline_seconds", h8)
	failed += _assert(typeof(wisp_off) == TYPE_DICTIONARY and int((wisp_off as Dictionary).get("shards", -1)) == 17, "manatree wisp 8h banks 17 shards")
	game_state.call("reset_for_new_game")
	game_state.call("set_resource", &"stone", 40)
	failed += _assert(str(jobs.call("try_begin_job", "crucible", "sapsteel")) == "ok", "crucible starts")
	failed += _assert(int(game_state.get("stone")) == 20, "crucible spends 20 stone")
	jobs.call("advance_seconds", 30.0)
	failed += _assert(absf(float(jobs.call("job_progress", "crucible"))) < 0.01, "paused job stays put")
	jobs.call("set_keeper_working", "crucible", true)
	failed += _assert(absf(float(jobs.call("station_speed_mult", "crucible")) - 1.0) < 0.01, "keeper works at 1x")
	jobs.call("advance_seconds", 30.0)
	failed += _assert(absf(float(jobs.call("job_progress", "crucible")) - 30.0) < 0.01, "worked job advances")
	jobs.call("set_keeper_working", "crucible", false)
	game_state.set("wisp_count", 4)
	game_state.call("_ensure_wisp_slots")
	for i: int in range(4):
		var joined: String = str(game_state.call("try_assign_wisp", i, "crucible"))
		failed += _assert(joined != "full" and joined != "invalid", "wisp %d can work the crucible" % i)
	failed += _assert(absf(float(jobs.call("station_speed_mult", "crucible")) - 0.4) < 0.01, "four wisps are 0.4x")
	game_state.set("wisp_count", 5)
	game_state.call("_ensure_wisp_slots")
	failed += _assert(str(game_state.call("try_assign_wisp", 4, "crucible")) == "full", "a fifth wisp is refused")
	game_state.call("reset_for_new_game")
	game_state.call("set_resource", &"stone", 40)
	jobs.call("try_begin_job", "crucible", "sapsteel")
	jobs.call("set_keeper_working", "crucible", true)
	jobs.call("advance_seconds", 120.0)
	failed += _assert(int(backpack.call("get_count", "sapsteel")) == 1, "a batch of 1 finishes one sapsteel")
	failed += _assert(int(game_state.get("stone")) == 20, "a batch of 1 leaves the unpaid stone")
	failed += _assert(not bool(jobs.call("has_job", "crucible")), "a finished batch clears the station")
	game_state.call("reset_for_new_game")
	backpack.call("set_count", "sapsteel", 24)
	backpack.call("set_count", "heartwood_bits", 12)
	backpack.call("set_count", "amberbind", 8)
	game_state.call("set_resource", &"essence", 300)
	failed += _assert(str(jobs.call("try_begin_job", "anvil", "rootsteel_edge")) == "ok", "anvil starts")
	jobs.call("set_keeper_working", "anvil", true)
	jobs.call("advance_seconds", 1200.0)
	failed += _assert(int(equipment.call("unequipped_count", "rootsteel_edge")) == 1, "anvil finishes one weapon")
	failed += _assert(not bool(jobs.call("has_job", "anvil")), "anvil does not repeat")
	failed += _assert(int(backpack.call("get_count", "sapsteel")) == 12, "anvil leaves the next batch")
	failed += _assert(int(game_state.get("essence")) == 150, "anvil leaves the next essence")
	failed += _assert(str(jobs.call("try_begin_job", "anvil", "rootsteel_edge")) == "owned", "a owned weapon is refused")
	backpack.call("set_count", "sapsteel", 6)
	backpack.call("set_count", "heartwood_bits", 6)
	backpack.call("set_count", "amberbind", 6)
	game_state.call("set_resource", &"essence", 100)
	game_state.set("forge_key", true)
	jobs.call("set_keeper_working", "reliquary", true)
	failed += _assert(str(jobs.call("try_begin_job", "reliquary", "oakheart_knot")) == "ok", "reliquary starts")
	jobs.call("advance_seconds", 600.0)
	failed += _assert(str(equipment.call("try_equip", "oakheart_knot")) == "ok", "oakheart equips")
	failed += _assert(int(equipment.call("gear_bonus", "might")) == 3, "oakheart +3 might")
	failed += _assert(int(equipment.call("gear_bonus", "resilience")) == 2, "oakheart +2 resilience")
	game_state.call("reset_for_new_game")
	var v8: Dictionary = {
		"forge_key": true,
		"equipment_equipped": {"relic": "forge_key_relic", "weapon": null},
		"gear_inventory": {},
	}
	var migrated: Dictionary = save_service.call("_migrate", 8, v8)
	var eq: Dictionary = migrated.get("equipment_equipped", {})
	failed += _assert(eq.get("relic", "stuck") == null, "v8 equipped key leaves the relic slot")
	var bag: Dictionary = migrated.get("gear_inventory", {})
	failed += _assert(int(bag.get("forge_key_relic", 0)) == 1, "v8 key moves into inventory")
	failed += _assert(typeof(migrated.get("forge_jobs", null)) == TYPE_DICTIONARY, "v8 gains forge jobs")
	failed += _assert(typeof(migrated.get("keeper_task", null)) == TYPE_DICTIONARY, "v8 gains the keeper task")
	failed += _assert(typeof(migrated.get("item_categories", null)) == TYPE_DICTIONARY, "v8 gains item categories")
	game_state.call("apply_save_dict", migrated)
	failed += _assert(str(equipment.call("equipped_id", "relic")) == "", "loaded v8 key is not re-equipped")
	failed += _assert(int(equipment.call("unequipped_count", "forge_key_relic")) == 1, "loaded v8 key sits in the bag")
	game_state.call("reset_for_new_game")
	game_state.call("set_resource", &"stone", 20)
	jobs.call("try_begin_job", "crucible", "sapsteel")
	backpack.call("set_count", "sapsteel", 4)
	failed += _assert(str(jobs.call("ascend_warning")) != "", "ascend warns about forge losses")
	game_state.set("fruit_committed", true)
	game_state.set("fruit_harvested_pending_ascend", true)
	game_state.call("ascend")
	failed += _assert(not bool(jobs.call("has_job", "crucible")), "ascend clears forge jobs")
	failed += _assert(int(backpack.call("get_count", "sapsteel")) == 0, "ascend clears forge materials")
	game_state.call("reset_for_new_game")
	backpack.call("set_count", "sapsteel", 7)
	(game_state.get("upgrade_ranks") as Dictionary)["keep_forge_intermediates"] = 1
	game_state.set("fruit_committed", true)
	game_state.set("fruit_harvested_pending_ascend", true)
	game_state.call("ascend")
	failed += _assert(int(backpack.call("get_count", "sapsteel")) == 7, "keep materials holds sapsteel")
	game_state.call("reset_for_new_game")
	game_state.call("set_resource", &"stone", 20)
	jobs.call("try_begin_job", "crucible", "sapsteel")
	jobs.call("set_keeper_working", "crucible", true)
	jobs.call("advance_seconds", 12.0)
	var kept: float = float(jobs.call("job_progress", "crucible"))
	(game_state.get("upgrade_ranks") as Dictionary)["keep_forge_jobs"] = 1
	game_state.set("fruit_committed", true)
	game_state.set("fruit_harvested_pending_ascend", true)
	game_state.call("ascend")
	failed += _assert(bool(jobs.call("has_job", "crucible")), "keep jobs holds the station")
	failed += _assert(absf(float(jobs.call("job_progress", "crucible")) - kept) < 0.05, "kept job keeps its progress")
	failed += _assert(absf(float(jobs.call("station_speed_mult", "crucible"))) < 0.01, "a kept job waits for a worker")
	var copy_src: String = FileAccess.get_file_as_string("res://data/forge_copy.json")
	failed += _assert(copy_src.to_lower().find("companion") < 0, "player copy never says companion")
	jobs.call("set_companion_working", "mill", "hook", true)
	failed += _assert(absf(float(jobs.call("station_speed_mult", "mill")) - 1.0) < 0.01, "companion hook can work a station")
	jobs.call("set_companion_working", "mill", "", false)
	var packed: PackedScene = load("res://scenes/forge_room.tscn") as PackedScene
	failed += _assert(packed != null, "forge room loads")
	if packed:
		var room: Node = packed.instantiate()
		tree_root.add_child(room)
		var poly: CollisionPolygon2D = room.get_node_or_null("Walls/CollisionPolygon2D") as CollisionPolygon2D
		var point_count: int = poly.polygon.size() if poly != null else 0
		failed += _assert(poly != null and point_count == 68, "round room wall has 68 points (got %d)" % point_count)
		var floor: PackedVector2Array = poly.polygon.slice(0, point_count / 2) if poly != null else PackedVector2Array()
		if floor.size() >= 2:
			failed += _assert(floor[0].distance_to(Vector2(880, 1161)) < 0.5, "east door point is x880 y1161")
			failed += _assert(floor[floor.size() - 1].distance_to(Vector2(720, 1161)) < 0.5, "west door point is x720 y1161")
		var stations: int = 0
		for node: Node in room.get_tree().get_nodes_in_group("forge_station"):
			if str(node.get("station_id")) == "":
				continue
			stations += 1
			var station: Node2D = node as Node2D
			var stand: Node2D = station.get_node_or_null("KeeperStand") as Node2D
			failed += _assert(_on_forge_floor(floor, station.global_position), "%s base is on the floor" % station.name)
			failed += _assert(stand != null and _on_forge_floor(floor, stand.global_position), "%s stand is on the floor" % station.name)
			var sprite: Sprite2D = station.get_node_or_null("Sprite") as Sprite2D
			failed += _assert(sprite != null and sprite.texture != null and sprite.texture.get_width() == 192 and sprite.texture.get_height() == 192, "%s frame is 192" % station.name)
			var station_scale: float = 0.75 if str(station.name) == "Anvil" else 0.8
			failed += _assert(sprite != null and not sprite.centered and sprite.offset.distance_to(Vector2(-96, -192)) < 0.1 and sprite.scale.distance_to(Vector2(station_scale, station_scale)) < 0.01, "%s sprite setup" % station.name)
			failed += _assert(sprite != null and sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "%s nearest filter" % station.name)
			failed += _assert(station.z_index > 0, "%s draws above the swirl" % station.name)
			failed += _assert(station.get("idle_texture") != null and station.get("busy_texture") != null, "%s idle and busy textures" % station.name)
			failed += _assert(station.get("paused_badge") != null and station.get("busy_badge") != null, "%s badges" % station.name)
			var badge_art: Sprite2D = station.get_node_or_null("BadgeArt") as Sprite2D
			failed += _assert(badge_art != null, "%s badge anchor" % station.name)
		failed += _assert(stations == 5, "five station scenes")
		var keeper_spawn: Node2D = room.get_node_or_null("Keeper") as Node2D
		failed += _assert(keeper_spawn != null and _on_forge_floor(floor, keeper_spawn.global_position), "spawn is on the floor")
		failed += _assert(keeper_spawn != null and keeper_spawn.z_index > 0, "keeper draws above the swirl")
		var exit_door: Node2D = room.get_node_or_null("ExitDoor") as Node2D
		failed += _assert(exit_door != null, "south exit")
		if exit_door:
			var exit_shape: CollisionShape2D = exit_door.get_node_or_null("CollisionShape2D") as CollisionShape2D
			var exit_rect: RectangleShape2D = null
			if exit_shape:
				exit_rect = exit_shape.shape as RectangleShape2D
			failed += _assert(exit_rect != null and _on_forge_floor(floor, exit_door.global_position), "exit is on the floor")
			failed += _assert(_on_forge_floor(floor, Vector2(800, 1100)) and _on_forge_floor(floor, Vector2(750, 1160)) and _on_forge_floor(floor, Vector2(850, 1160)), "door corridor stays walkable")
			if exit_rect:
				var half: Vector2 = exit_rect.size * 0.5
				for corner: Vector2 in [Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(-half.x, half.y), Vector2(half.x, half.y)]:
					failed += _assert(_on_forge_floor(floor, exit_door.global_position + corner), "exit corner on the floor")
		var swirl: Sprite2D = room.get_node_or_null("SwirlOverlay") as Sprite2D
		failed += _assert(swirl != null and swirl.texture != null, "swirl texture loads")
		failed += _assert(swirl != null and swirl.z_index == 0 and swirl.modulate.is_equal_approx(Color(1, 1, 1, 1)), "swirl draws full strength under the stations")
		var plate: Sprite2D = room.get_node_or_null("FloorPlate") as Sprite2D
		failed += _assert(plate != null and plate.texture != null and plate.texture.get_width() == 1600 and plate.texture.get_height() == 1200, "plate is 1600x1200")
		failed += _assert(plate != null and plate.position.distance_to(Vector2(800, 600)) < 1.0 and plate.scale.distance_to(Vector2.ONE) < 0.01, "plate scale 1 at (800, 600)")
		var cam: Camera2D = room.get_node_or_null("Camera2D") as Camera2D
		failed += _assert(cam != null and cam.limit_left == 0 and cam.limit_top == 0 and cam.limit_right == 1600 and cam.limit_bottom == 1200, "camera limits fit the plate")
		room.free()
	game_state.call("reset_for_new_game")
	return failed


func _forge_pass_b(tree_root: Window, game_state: Node, backpack: Node) -> int:
	var failed: int = 0
	var jobs: Node = tree_root.get_node_or_null("ForgeJobs")
	var equipment: Node = tree_root.get_node_or_null("Equipment")
	var audio: Node = tree_root.get_node_or_null("GameAudio")
	failed += _assert(jobs != null and equipment != null and audio != null, "pass b nodes")
	if jobs == null or equipment == null or audio == null:
		return failed
	game_state.call("reset_for_new_game")
	var fresh: Dictionary = {}
	var hud_probe: PackedScene = load("res://scenes/hud.tscn") as PackedScene
	if hud_probe:
		var hud_node: Node = hud_probe.instantiate()
		tree_root.add_child(hud_node)
		await process_frame
		fresh = hud_node.call("filter_owned_counts")
		print("FRESH_FILTER_COUNTS %s" % str(fresh))
		for key: Variant in fresh.keys():
			failed += _assert(int(fresh[key]) == 0, "fresh %s count is 0" % str(key))
		hud_node.queue_free()
		await process_frame
	var catalog: Dictionary = {
		"raw": ["wood", "stone", "food", "manashards", "essence"],
		"refined": ["fertilizer", "wooden_tool_rod", "sapsteel", "heartwood_bits", "amberbind", "weapon_rod"],
		"tools": ["stone_axe", "stone_pickaxe", "wooden_basket", "stone_watering_can"],
		"weapons": ["stone_sword", "sapstaff", "thornbow", "rootsteel_edge", "heartwand", "switchshaft"],
		"relics": ["forge_key_relic", "oakheart_knot", "shardlens", "windthorn_bead"],
	}
	for filter_id: Variant in catalog.keys():
		for item_id: String in catalog[filter_id]:
			failed += _assert(bool(backpack.call("matches_filter", item_id, str(filter_id))), "%s is %s" % [item_id, filter_id])
			failed += _assert(bool(backpack.call("matches_filter", item_id, "all")), "all matches %s" % item_id)
	failed += _assert(bool(backpack.call("matches_filter", "wooden_planks", "all")), "planks are in all")
	failed += _assert(not bool(backpack.call("matches_filter", "wooden_planks", "refined")), "planks are not refined")
	failed += _assert(not bool(backpack.call("matches_filter", "wooden_planks", "tools")), "planks are not tools")
	failed += _assert(not bool(backpack.call("matches_filter", "stone_sword", "tools")), "sword is not a tool")
	failed += _assert(not bool(backpack.call("matches_filter", "fertilizer", "raw")), "fertilizer is not raw")
	game_state.call("set_resource", &"wood", 4)
	backpack.call("set_count", "fertilizer", 2)
	backpack.call("set_count", "stone_axe", 1)
	equipment.call("add_gear", "stone_sword", 1)
	equipment.call("add_gear", "forge_key_relic", 1)
	var hud_counts: PackedScene = load("res://scenes/hud.tscn") as PackedScene
	if hud_counts:
		var hud_node2: Node = hud_counts.instantiate()
		tree_root.add_child(hud_node2)
		await process_frame
		var owned: Dictionary = hud_node2.call("filter_owned_counts")
		failed += _assert(int(owned.get("raw", 0)) == 1, "raw shows wood")
		failed += _assert(int(owned.get("refined", 0)) == 1, "refined shows fertilizer")
		failed += _assert(int(owned.get("tools", 0)) == 1, "tools shows the axe")
		failed += _assert(int(owned.get("weapons", 0)) == 1, "weapons shows the sword")
		failed += _assert(int(owned.get("relics", 0)) == 1, "relics shows the key")
		failed += _assert(int(owned.get("all", 0)) >= 5, "all shows every granted stack")
		hud_node2.call("open_bench_panel")
		await process_frame
		var craft_box: VBoxContainer = hud_node2.get_node_or_null("BenchPanel/CraftScroll/CraftList") as VBoxContainer
		var seen: Dictionary = {}
		if craft_box:
			for row: Node in craft_box.get_children():
				seen[str(row.get_meta("recipe_id", ""))] = true
		var recipe_ids: PackedStringArray = PackedStringArray([
			"wooden_planks", "stone_fragments", "wooden_tool_rod", "axe_head", "pickaxe_head",
			"stone_axe", "stone_pickaxe", "wooden_basket", "stone_watering_can", "fertilizer",
			"weapon_rod", "stone_sword", "sapstaff", "thornbow",
		])
		for recipe_id: String in recipe_ids:
			failed += _assert(bool(seen.get(recipe_id, false)), "bench lists %s" % recipe_id)
		var plank_before: int = int(backpack.call("get_count", "wooden_planks"))
		for row2: Node in craft_box.get_children():
			if str(row2.get_meta("recipe_id", "")) != "wooden_planks":
				continue
			for sub: Node in row2.get_children():
				if sub is Button and not (sub as Button).disabled:
					(sub as Button).emit_signal("pressed")
		await process_frame
		failed += _assert(int(backpack.call("get_count", "wooden_planks")) == plank_before, "bench row selects a batch instead of crafting immediately")
		var bench_panel: Node = hud_node2.get_node_or_null("BenchPanel/BatchPanel")
		failed += _assert(bench_panel != null and str(bench_panel.call("selected_recipe")) == "wooden_planks", "bench row binds the plank recipe")
		hud_node2.call("close_bench")
		hud_node2.queue_free()
		await process_frame
	var bench_scene: PackedScene = load("res://scenes/keepers_bench.tscn") as PackedScene
	var keeper_scene: PackedScene = load("res://scenes/keeper.tscn") as PackedScene
	var bench_hud_scene: PackedScene = load("res://scenes/hud.tscn") as PackedScene
	if bench_scene and keeper_scene and bench_hud_scene:
		var bench: Node = bench_scene.instantiate()
		var keeper: Node2D = keeper_scene.instantiate() as Node2D
		var bench_hud: Node = bench_hud_scene.instantiate()
		tree_root.add_child(bench)
		tree_root.add_child(keeper)
		tree_root.add_child(bench_hud)
		await process_frame
		keeper.global_position = (bench.call("stand_global") as Vector2) + Vector2(400, 0)
		audio.call("clear_played_log")
		bench.call("try_open")
		await process_frame
		failed += _assert(not bool(bench_hud.call("is_bench_open")), "bench stays shut away from the stand")
		failed += _assert(not bool(audio.call("did_play", &"sfx_bench_open")), "bench_open waits for arrival")
		keeper.global_position = bench.call("stand_global")
		bench.set("_awaiting_arrival", false)
		bench.call("_on_keeper_arrived")
		await process_frame
		failed += _assert(not bool(bench_hud.call("is_bench_open")), "arrival without a walk does not open")
		bench.set("_awaiting_arrival", true)
		bench.call("_on_keeper_arrived")
		await process_frame
		failed += _assert(bool(bench_hud.call("is_bench_open")), "bench opens when the keeper arrives")
		failed += _assert(bool(audio.call("did_play", &"sfx_bench_open")), "sfx_bench_open plays")
		bench_hud.call("close_bench")
		bench.queue_free()
		keeper.queue_free()
		bench_hud.queue_free()
		await process_frame
	for cue_id: String in ["sfx_bench_open", "sfx_door_bark", "sfx_forge_big_done", "sfx_press_squeeze"]:
		failed += _assert(FileAccess.file_exists("res://assets/audio/%s.ogg" % cue_id), "%s imported" % cue_id)
	failed += _assert(str(audio.call("cue_bus", "sfx_forge_craft_start")) == "SFX_World", "craft_start on SFX_World")
	failed += _assert(str(audio.call("cue_bus", "sfx_forge_craft_done")) == "SFX_World", "craft_done on SFX_World")
	failed += _assert(str(audio.call("cue_bus", "sfx_press_squeeze")) == "SFX_World", "press_squeeze on SFX_World")
	failed += _assert(str(audio.call("cue_bus", "sfx_forge_big_done")) == "SFX_Progress", "big_done on SFX_Progress")
	failed += _assert(str(audio.call("cue_bus", "sfx_bench_open")) == "SFX_UI", "bench_open on SFX_UI")
	failed += _assert(absf(float(jobs.call("audio_lowpass_hz")) - 1500.0) < 1.0, "forge low-pass is 1.5 kHz")
	failed += _assert(absf(float(jobs.call("audio_music_db")) + 3.0) < 0.01, "forge music is -3 dB")
	audio.call("set_forge_room_mix", false)
	jobs.call("set_scene_changes_enabled", false)
	game_state.call("reset_for_new_game")
	game_state.set("stage_id", &"elder")
	game_state.set("forge_key", true)
	audio.call("clear_played_log")
	failed += _assert(str(jobs.call("try_enter_forge")) == "entered", "door enter")
	failed += _assert(bool(audio.call("did_play", &"sfx_door_bark")), "door bark on enter")
	failed += _assert(bool(audio.call("forge_mix_on")), "forge mix on")
	failed += _assert(absf(float(audio.call("forge_lowpass_hz")) - 1500.0) < 1.0, "live low-pass is 1.5 kHz")
	failed += _assert(absf(float(audio.call("forge_music_offset_db")) + 3.0) < 0.01, "live music offset is -3 dB")
	audio.call("clear_played_log")
	jobs.call("exit_forge")
	failed += _assert(bool(audio.call("did_play", &"sfx_door_bark")), "door bark on exit")
	failed += _assert(not bool(audio.call("forge_mix_on")), "forge mix restored")
	failed += _assert(absf(float(audio.call("forge_music_offset_db"))) < 0.01, "music offset restored")
	failed += _assert(absf(float(audio.call("forge_lowpass_hz"))) < 0.01, "low-pass removed")
	jobs.call("take_clearing_return")
	jobs.call("set_in_forge_override", 0)
	game_state.call("reset_for_new_game")
	game_state.call("set_resource", &"wood", 20)
	jobs.call("set_keeper_working", "mill", true)
	audio.call("clear_played_log")
	jobs.call("try_begin_job", "mill", "heartwood_bits")
	jobs.call("advance_seconds", 60.0)
	failed += _assert(not bool(audio.call("did_play", &"sfx_forge_craft_done")), "upcycle is silent outside the forge")
	jobs.call("set_in_forge_override", 1)
	game_state.call("set_resource", &"wood", 20)
	jobs.call("set_keeper_working", "mill", true)
	audio.call("clear_played_log")
	jobs.call("try_begin_job", "mill", "heartwood_bits")
	jobs.call("advance_seconds", 60.0)
	failed += _assert(bool(audio.call("did_play", &"sfx_forge_craft_done")), "upcycle plays craft_done inside")
	failed += _assert(absf(float(audio.get("last_cue_volume_db")) + 8.0) < 0.51, "craft_done is about -8 dB")
	game_state.call("set_resource", &"food", 15)
	jobs.call("set_keeper_working", "press", true)
	audio.call("clear_played_log")
	failed += _assert(str(jobs.call("try_begin_job", "press", "amberbind")) == "ok", "press queues")
	failed += _assert(bool(audio.call("did_play", &"sfx_press_squeeze")), "press squeeze on queue")
	audio.call("clear_played_log")
	jobs.call("advance_seconds", 45.0)
	failed += _assert(bool(audio.call("did_play", &"sfx_forge_craft_done")), "press completion is craft_done")
	failed += _assert(not bool(audio.call("did_play", &"sfx_forge_big_done")), "press is not big_done")
	jobs.call("set_in_forge_override", -1)
	game_state.call("reset_for_new_game")
	backpack.call("set_count", "sapsteel", 12)
	backpack.call("set_count", "heartwood_bits", 6)
	backpack.call("set_count", "amberbind", 4)
	game_state.call("set_resource", &"essence", 150)
	jobs.call("set_keeper_working", "anvil", true)
	jobs.set("_last_big_done_msec", Time.get_ticks_msec() - 4000)
	audio.call("clear_played_log")
	jobs.call("try_begin_job", "anvil", "rootsteel_edge")
	jobs.call("advance_seconds", 600.0)
	failed += _assert(bool(audio.call("did_play", &"sfx_forge_big_done")), "anvil plays big_done outside the forge")
	audio.call("clear_played_log")
	jobs.call("_play_big_done")
	failed += _assert(not bool(audio.call("did_play", &"sfx_forge_big_done")), "big_done throttles inside 3s")
	jobs.set("_last_big_done_msec", Time.get_ticks_msec() - 4000)
	jobs.call("_play_big_done")
	failed += _assert(bool(audio.call("did_play", &"sfx_forge_big_done")), "big_done plays again after 3s")
	var crucible_img := Image.new()
	var img_err: Error = crucible_img.load(ProjectSettings.globalize_path("res://assets/art/forge/prop_crucible_idle.png"))
	failed += _assert(img_err == OK and crucible_img.get_width() == 192 and crucible_img.get_height() == 192, "crucible frame is 192")
	if img_err == OK:
		var corner: Color = crucible_img.get_pixel(0, 0)
		failed += _assert(corner.a < 0.05, "crucible frame corner is clear")
	var reliquary: Node2D = null
	var room_packed: PackedScene = load("res://scenes/forge_room.tscn") as PackedScene
	if room_packed:
		var room: Node = room_packed.instantiate()
		reliquary = room.get_node_or_null("Reliquary") as Node2D
		failed += _assert(reliquary != null and reliquary.position.distance_to(Vector2(420, 800)) < 1.0, "reliquary left the north doorway")
		room.free()
	audio.call("set_forge_room_mix", false)
	jobs.call("set_scene_changes_enabled", true)
	jobs.call("set_in_forge_override", -1)
	game_state.call("reset_for_new_game")
	return failed


func _forge_pass_c(tree_root: Window, game_state: Node, backpack: Node) -> int:
	var failed: int = 0
	var equipment: Node = tree_root.get_node_or_null("Equipment")
	failed += _assert(equipment != null and backpack != null, "pass c nodes")
	if equipment == null:
		return failed
	var art_paths: Dictionary = {
		"res://assets/art/ui/icon_amberbind.png": Vector2i(32, 32),
		"res://assets/art/ui/icon_sapsteel.png": Vector2i(32, 32),
		"res://assets/art/ui/icon_heartwood_bits.png": Vector2i(32, 32),
		"res://assets/art/ui/icons/icon_oakheart_knot.png": Vector2i(32, 32),
		"res://assets/art/ui/icons/icon_shardlens.png": Vector2i(32, 32),
		"res://assets/art/ui/icons/icon_windthorn_bead.png": Vector2i(32, 32),
		"res://assets/art/ui/badge_station_paused.png": Vector2i(32, 32),
		"res://assets/art/ui/badge_station_busy.png": Vector2i(32, 32),
		"res://assets/art/ui/relic_slot_empty.png": Vector2i(44, 44),
		"res://assets/art/forge/bench_idle.png": Vector2i(192, 192),
		"res://assets/art/forge/bench_busy.png": Vector2i(192, 192),
		"res://assets/art/forge/prop_press_idle.png": Vector2i(192, 192),
		"res://assets/art/forge/prop_reliquary_idle.png": Vector2i(192, 192),
	}
	for path: String in art_paths.keys():
		var tex: Texture2D = load(path) as Texture2D
		var want: Vector2i = art_paths[path]
		failed += _assert(tex != null and tex.get_width() == want.x and tex.get_height() == want.y, "texture %s" % path)
	var hud_scene: PackedScene = load("res://scenes/hud.tscn") as PackedScene
	if hud_scene:
		var hud_node: Node = hud_scene.instantiate()
		tree_root.add_child(hud_node)
		await process_frame
		for item_id: String in ["amberbind", "sapsteel", "heartwood_bits", "oakheart_knot", "shardlens", "windthorn_bead"]:
			var icon: TextureRect = hud_node.call("_make_item_icon", item_id, item_id) as TextureRect
			failed += _assert(icon != null and icon.texture != null and icon.texture.get_width() == 32, "%s icon is wired" % item_id)
		game_state.set("forge_key", true)
		equipment.call("try_unequip", "relic")
		hud_node.call("open_character_sheet")
		await process_frame
		var relic_square: TextureRect = hud_node.get_node_or_null("CharacterSheet/SheetFit/Sheet/PortraitHost/Slot_relic/Square") as TextureRect
		var empty_frame: Texture2D = load("res://assets/art/ui/relic_slot_empty.png") as Texture2D
		failed += _assert(relic_square != null and relic_square.texture == empty_frame and relic_square.size.distance_to(Vector2(44, 44)) < 0.5, "empty relic slot uses the 44 frame")
		equipment.call("grant_item", "oakheart_knot")
		failed += _assert(str(equipment.call("try_equip", "oakheart_knot")) == "ok", "oakheart equips")
		var relic_slot: Node = hud_node.get_node_or_null("CharacterSheet/SheetFit/Sheet/PortraitHost/Slot_relic")
		if relic_slot:
			relic_slot.call("refresh")
		var glyph: TextureRect = hud_node.get_node_or_null("CharacterSheet/SheetFit/Sheet/PortraitHost/Slot_relic/Square/RelicGlyph") as TextureRect
		failed += _assert(glyph != null and glyph.visible and glyph.texture != null and glyph.texture.get_width() == 32, "relic icon is 32px")
		failed += _assert(glyph != null and glyph.position.distance_to(Vector2(6, 6)) < 0.5 and glyph.size.distance_to(Vector2(32, 32)) < 0.5, "relic icon sits centred in the frame")
		failed += _assert(relic_square != null and relic_square.texture == empty_frame, "equipped relic keeps the frame")
		hud_node.call("close_character_sheet")
		paused = false
		hud_node.queue_free()
		await process_frame
	var bench_scene: PackedScene = load("res://scenes/keepers_bench.tscn") as PackedScene
	if bench_scene:
		var bench: Node2D = bench_scene.instantiate() as Node2D
		var bench_sprite: Sprite2D = bench.get_node_or_null("Sprite") as Sprite2D
		failed += _assert(bench_sprite != null and bench_sprite.texture != null and not bench_sprite.centered, "bench sprite")
		failed += _assert(bench_sprite != null and bench_sprite.offset.distance_to(Vector2(-96, -192)) < 0.1 and bench_sprite.scale.distance_to(Vector2.ONE) < 0.01, "bench offset (-96,-192)")
		failed += _assert(bench_sprite != null and bench_sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "bench nearest")
		failed += _assert(bench.get("idle_texture") != null and bench.get("busy_texture") != null, "bench idle and busy")
		var stand: Node2D = bench.get_node_or_null("KeeperStand") as Node2D
		failed += _assert(stand != null and stand.position.distance_to(Vector2(0, 48)) < 0.5, "bench stand is just south of the tabletop")
		bench.free()
	game_state.call("reset_for_new_game")
	return failed


func _on_forge_floor(floor: PackedVector2Array, point: Vector2) -> bool:
	if floor.size() < 3:
		return false
	return Geometry2D.is_point_in_polygon(point, floor)


func _keeper_clip_asserts(sframes: SpriteFrames) -> int:
	var failed: int = 0
	failed += _assert(sframes.has_animation(&"walk_north") and sframes.has_animation(&"walk_east") and sframes.has_animation(&"walk_west"), "walk four directions")
	failed += _assert(sframes.has_animation(&"walk_back") and sframes.get_frame_count(&"walk_back") == 6, "walk_back kept")
	failed += _assert(sframes.has_animation(&"run_south") and sframes.get_frame_count(&"run_south") == 8, "run placeholder clip is loaded")
	failed += _assert(sframes.has_animation(&"run_north") and sframes.has_animation(&"run_east") and sframes.has_animation(&"run_west"), "run four directions unused")
	var walk_ms: Array[float] = [120.0, 125.0, 130.0, 125.0, 120.0, 125.0, 130.0, 125.0]
	var run_ms: Array[float] = [100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0]
	var axe_ms: Array[float] = [140.0, 70.0, 60.0, 180.0, 90.0, 90.0, 90.0, 90.0, 90.0]
	var pick_ms: Array[float] = [100.0, 90.0, 90.0, 150.0, 70.0, 60.0, 60.0, 180.0, 100.0]
	var berry_ms: Array[float] = [160.0, 90.0, 90.0, 100.0, 160.0, 100.0, 90.0, 110.0]
	var water_ms: Array[float] = [170.0, 100.0, 90.0, 90.0, 110.0, 250.0, 250.0, 100.0, 90.0, 100.0]
	var station_ms: Array[float] = [110.0, 110.0, 80.0, 80.0, 80.0, 110.0, 80.0, 110.0, 90.0, 90.0]
	failed += _assert(_timed_clip(sframes, &"walk_south", walk_ms), "walk_south durations")
	failed += _assert(_timed_clip(sframes, &"walk_east", walk_ms), "walk_east durations")
	failed += _assert(_timed_clip(sframes, &"run_east", run_ms), "run_east durations")
	failed += _assert(_timed_clip(sframes, &"harvest_axe_east", axe_ms), "axe east durations")
	failed += _assert(_timed_clip(sframes, &"harvest_axe_west", axe_ms), "axe west durations")
	failed += _assert(_timed_clip(sframes, &"harvest_pickaxe_west", pick_ms), "pickaxe west durations")
	failed += _assert(_timed_clip(sframes, &"harvest_berries_east", berry_ms), "berries east durations")
	failed += _assert(_timed_clip(sframes, &"harvest_water_east", water_ms), "water east durations")
	failed += _assert(_timed_clip(sframes, &"harvest_water_west", water_ms), "water west durations")
	failed += _assert(_timed_clip(sframes, &"station_work_north", station_ms), "station durations")
	failed += _assert(is_equal_approx(_duration_sum(sframes, &"walk_north"), 1000.0), "walk loop is 1000 ms")
	failed += _assert(is_equal_approx(_duration_sum(sframes, &"run_south"), 800.0), "run loop is 800 ms")
	failed += _assert(is_equal_approx(_duration_sum(sframes, &"harvest_axe_east"), 900.0), "axe loop is 900 ms")
	failed += _assert(is_equal_approx(_duration_sum(sframes, &"harvest_pickaxe_east"), 900.0), "pickaxe loop is 900 ms")
	failed += _assert(is_equal_approx(_duration_sum(sframes, &"harvest_berries_west"), 900.0), "berries loop is 900 ms")
	failed += _assert(is_equal_approx(_duration_sum(sframes, &"harvest_water_west"), 1350.0), "water loop is 1350 ms")
	failed += _assert(is_equal_approx(_duration_sum(sframes, &"station_work_north"), 940.0), "station loop is 940 ms")
	var jobs: Node = (Engine.get_main_loop() as SceneTree).root.get_node_or_null("ForgeJobs")
	failed += _assert(jobs != null and is_equal_approx(float(jobs.call("station_work_anim_speed")), 0.5), "station_work_anim_speed is 0.5")
	return failed


func _timed_clip(sframes: SpriteFrames, anim: StringName, expected: Array[float]) -> bool:
	if not sframes.has_animation(anim):
		return false
	if not is_equal_approx(sframes.get_animation_speed(anim), 1000.0):
		return false
	if sframes.get_frame_count(anim) != expected.size():
		return false
	for i: int in range(expected.size()):
		if not is_equal_approx(sframes.get_frame_duration(anim, i), expected[i]):
			return false
	return true


func _duration_sum(sframes: SpriteFrames, anim: StringName) -> float:
	var total := 0.0
	if not sframes.has_animation(anim):
		return -1.0
	for i: int in range(sframes.get_frame_count(anim)):
		total += sframes.get_frame_duration(anim, i)
	return total


func _no_old_keeper_idle() -> int:
	## Built in pieces so this file does not itself contain the old paths.
	var stem := "keeper_idle_"
	var banned: PackedStringArray = PackedStringArray([
		stem + "south.png",
		stem + "south_0000",
		stem + "front",
		stem + "back",
		stem + "south_256",
	])
	var hits: PackedStringArray = PackedStringArray()
	_scan_old_idle(ProjectSettings.globalize_path("res://"), banned, hits)
	var failed: int = _assert(hits.is_empty(), "old keeper idle still referenced (%s)" % ", ".join(hits))
	var keeper_script = load("res://scripts/keeper.gd")
	var missing: PackedStringArray = keeper_script.idle_missing_directions()
	var missing_text: String = "none" if missing.is_empty() else ", ".join(missing)
	print("IDLE_MISSING %s" % missing_text)
	if failed == 0:
		print("NO_OLD_KEEPER_IDLE_OK")
	return failed


func _scan_old_idle(dir_path: String, banned: PackedStringArray, hits: PackedStringArray) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if name == "." or name == ".." or name == ".git":
			name = dir.get_next()
			continue
		var full := dir_path.path_join(name)
		if dir.current_is_dir():
			if name != "_archive":
				_scan_old_idle(full, banned, hits)
		else:
			var ext := name.get_extension()
			if ext in ["gd", "tscn", "json", "cfg", "md"]:
				var text := FileAccess.get_file_as_string(full)
				for needle: String in banned:
					if text.find(needle) >= 0:
						hits.append("%s (%s)" % [full, needle])
						break
		name = dir.get_next()
	dir.list_dir_end()


func _autosave_event_throttle(save_service: Node) -> int:
	var failed: int = 0
	failed += _assert(is_equal_approx(float(save_service.get("AUTOSAVE_THROTTLE_SEC")), 60.0), "event autosave throttle is 60s")
	var tuning := FileAccess.get_file_as_string("res://data/forge_tuning.json")
	failed += _assert(tuning.find("\"autosave_sec\": 300") >= 0, "autosave_sec is 300")
	save_service.call("note_session_started")
	save_service.call("set_autosave_coalesce", 0.0)
	save_service.call("debug_set_last_autosave_age", 999.0)
	save_service.call("save_autosave", false)
	var first: float = _autosave_stamp_sum(save_service)
	save_service.call("debug_set_last_autosave_age", 3.0)
	save_service.call("save_autosave", false)
	var held: float = _autosave_stamp_sum(save_service)
	failed += _assert(is_equal_approx(held, first), "an event save inside 60s does not take another slot")
	save_service.call("debug_set_last_autosave_age", 61.0)
	save_service.call("save_autosave", false)
	var later: float = _autosave_stamp_sum(save_service)
	failed += _assert(later > first + 0.0001, "an event save after 60s writes")
	save_service.call("debug_set_last_autosave_age", 1.0)
	var before_quit: float = _autosave_stamp_sum(save_service)
	save_service.call("save_on_quit")
	var after_quit: float = _autosave_stamp_sum(save_service)
	failed += _assert(after_quit > before_quit + 0.0001, "window close saves inside the throttle")
	save_service.call("set_autosave_coalesce", 1.2)
	if failed == 0:
		print("AUTOSAVE_THROTTLE_OK")
	return failed


func _autosave_stamp_sum(save_service: Node) -> float:
	var total: float = 0.0
	for slot: int in range(1, 4):
		var info: Dictionary = save_service.call("get_autosave_info", slot)
		total += float(info.get("timestamp", 0.0))
	return total


func _jobs_survive_switch(tree_root: Window, game_state: Node, save_service: Node) -> int:
	var failed: int = 0
	var jobs: Node = tree_root.get_node_or_null("ForgeJobs")
	failed += _assert(jobs != null, "ForgeJobs for job survival")
	if jobs == null:
		return failed
	jobs.call("set_autosave_enabled", false)
	failed += await _boot_play(game_state, save_service, true)
	if failed > 0:
		return failed
	var hub: Node = current_scene
	var elaia: Node = hub.get_node_or_null("World/Elaia")
	if elaia and elaia.has_method("_apply_presence"):
		elaia.call("_apply_presence")
	var keeper: Node = hub.get_node_or_null("World/Keeper")
	var tree: Node = hub.get_node_or_null("World/Manatree")
	var stone: Node = hub.get_node_or_null("World/HarvestStone")
	failed += _assert(keeper != null and tree != null and elaia != null and stone != null, "clearing workers exist")
	if failed > 0:
		return failed
	var water_spot: Dictionary = keeper.call("plan_work", tree, "manatree")
	keeper.set("global_position", water_spot.get("position", keeper.get("global_position")))
	keeper.call("start_water_channel", tree)
	var stone_spot: Dictionary = elaia.call("plan_work", stone, "stone")
	elaia.set("global_position", stone_spot.get("position", elaia.get("global_position")))
	elaia.call("start_harvest_channel", stone)
	game_state.set("wisp_count", 1)
	failed += _assert(str(game_state.call("try_assign_wisp", 0, "harvest_tree")) == "ok", "wisp takes the tree")
	var keeper_task: Dictionary = jobs.call("keeper_task")
	var elaia_task: Dictionary = jobs.call("elaia_task")
	failed += _assert(str(keeper_task.get("kind", "")) == "water" and bool(keeper_task.get("working", false)), "keeper is watering")
	failed += _assert(str(elaia_task.get("kind", "")) == "harvest" and str(elaia_task.get("target", "")) == "stone", "elaia is on stone")
	var essence_0: int = int(game_state.get("essence"))
	var shards_0: int = int(game_state.get("manashards"))
	var stone_0: int = int(game_state.get("stone"))
	var wood_0: int = int(game_state.get("wood"))
	failed += await _enter_forge_view()
	if failed > 0:
		return failed
	await process_frame
	for wisp: Node in get_nodes_in_group("wisp"):
		if str(game_state.call("get_wisp_assignment", int(wisp.get("wisp_id")))) == "harvest_tree":
			failed += _assert(not bool(wisp.get("visible")), "clearing wisp stays out of the forge")
	jobs.call("step_jobs", 20.0)
	game_state.call("apply_wisp_pulses", 20.0)
	failed += _assert(int(game_state.get("essence")) > essence_0, "essence keeps accruing in the forge")
	failed += _assert(int(game_state.get("manashards")) > shards_0, "mana shards keep accruing in the forge")
	failed += _assert(int(game_state.get("stone")) > stone_0, "elaia stone keeps accruing in the forge")
	failed += _assert(int(game_state.get("wood")) > wood_0, "wisp wood keeps accruing in the forge")
	failed += await _press_nav("jobs_back_clearing", _HUB_SCENE)
	if failed > 0:
		return failed
	keeper = current_scene.get_node_or_null("World/Keeper")
	elaia = current_scene.get_node_or_null("World/Elaia")
	keeper_task = jobs.call("keeper_task")
	elaia_task = jobs.call("elaia_task")
	failed += _assert(str(keeper_task.get("kind", "")) == "water" and bool(keeper_task.get("working", false)), "watering survives the round trip")
	failed += _assert(str(elaia_task.get("target", "")) == "stone" and bool(elaia_task.get("working", false)), "stone job survives the round trip")
	failed += _assert(str(game_state.call("get_wisp_assignment", 0)) == "harvest_tree", "wisp job survives the round trip")
	failed += _work_anim_playing(keeper, "harvest_water", "keeper watering")
	failed += _work_anim_playing(elaia, "harvest_pickaxe", "elaia stone")
	var essence_1: int = int(game_state.get("essence"))
	if keeper and keeper.has_method("step_channel"):
		keeper.call("step_channel", 8.0)
	failed += _assert(int(game_state.get("essence")) > essence_1, "watering still pays after the return")
	game_state.call("set_resource", &"stone", 80)
	game_state.call("set_resource", &"wood", 80)
	game_state.call("set_resource", &"food", 80)
	_place_actor(game_state, "keeper", "forge", Vector2(520, 700))
	_place_actor(game_state, "elaia", "forge", Vector2(680, 540))
	jobs.call("set_keeper_task", "forge", "crucible", true)
	jobs.call("set_elaia_task", "forge", "mill", true)
	failed += await _enter_forge_view()
	if failed > 0:
		return failed
	failed += _assert(str(jobs.call("try_begin_job", "crucible", "sapsteel")) == "ok", "crucible job starts")
	failed += _assert(str(jobs.call("try_begin_job", "mill", "heartwood_bits")) == "ok", "mill job starts")
	keeper = current_scene.get_node_or_null("Keeper")
	elaia = current_scene.get_node_or_null("Elaia")
	if keeper and keeper.has_method("apply_keeper_presence"):
		keeper.call("apply_keeper_presence")
	if elaia and elaia.has_method("_apply_presence"):
		elaia.call("_apply_presence")
	var crucible_0: float = float(jobs.call("job_state", "crucible").get("progress", 0.0))
	var mill_0: float = float(jobs.call("job_state", "mill").get("progress", 0.0))
	failed += await _press_nav("jobs_forge_to_clearing", _HUB_SCENE)
	jobs.call("step_jobs", 10.0)
	var crucible_1: float = float(jobs.call("job_state", "crucible").get("progress", 0.0))
	var mill_1: float = float(jobs.call("job_state", "mill").get("progress", 0.0))
	failed += _assert(crucible_1 > crucible_0, "crucible keeps running in the clearing")
	failed += _assert(mill_1 > mill_0, "mill keeps running in the clearing")
	failed += _assert(str(jobs.call("keeper_task").get("target", "")) == "crucible", "keeper stays on the crucible")
	failed += _assert(str(jobs.call("elaia_task").get("target", "")) == "mill", "elaia stays on the mill")
	failed += await _enter_forge_view()
	keeper = current_scene.get_node_or_null("Keeper")
	elaia = current_scene.get_node_or_null("Elaia")
	failed += _work_anim_playing(keeper, "station_work", "keeper crucible")
	failed += _work_anim_playing(elaia, "station_work", "elaia mill")
	_drop_current_scene()
	save_service.call("note_session_ended")
	game_state.call("reset_for_new_game")
	jobs.call("set_autosave_enabled", true)
	if failed == 0:
		print("JOBS_SURVIVE_SWITCH_OK")
	return failed


func _work_anim_playing(body: Node, prefix: String, label: String) -> int:
	if body == null:
		printerr("ASSERT FAIL: %s body missing" % label)
		return 1
	var sprite: Node = body.get_node_or_null("Sprite")
	if sprite == null:
		printerr("ASSERT FAIL: %s sprite missing" % label)
		return 1
	var anim: String = str(sprite.get("animation"))
	var playing: bool = bool(sprite.call("is_playing"))
	var failed: int = _assert(anim.begins_with(prefix), "%s plays %s (got %s)" % [label, prefix, anim])
	failed += _assert(playing, "%s animation is playing" % label)
	return failed


func _workbench_reach(tree_root: Window, save_service: Node) -> int:
	## Both heroes stand south of the bench, inside the click area and clear of the legs.
	var failed: int = 0
	save_service.call("note_session_ended")
	save_service.set("boot_intent", "new")
	var packed: PackedScene = load("res://scenes/main.tscn") as PackedScene
	var live: Node = packed.instantiate() if packed else null
	if live == null:
		return _assert(false, "workbench hub loads")
	tree_root.add_child(live)
	await process_frame
	await process_frame
	var bench: Node2D = live.get_node_or_null("World/KeepersBench") as Node2D
	failed += _assert(bench != null, "workbench is in the clearing")
	if bench == null:
		live.free()
		return failed
	var keeper_cls = load("res://scripts/keeper.gd")
	var footprint: Rect2 = Rect2(bench.global_position, Vector2(32, 32))
	if bench.has_method("work_footprint"):
		footprint = bench.call("work_footprint")
	var pick: CollisionShape2D = bench.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var walk: CollisionShape2D = bench.get_node_or_null("WalkBody/CollisionShape2D") as CollisionShape2D
	failed += _assert(pick != null and walk != null, "workbench has a click area and a leg collision")
	for actor_id: String in ["keeper", "elaia"]:
		var solved: Dictionary = keeper_cls.solve_work_spot(
			footprint, bench.global_position, "bench", Callable(), "", actor_id
		)
		var pos: Vector2 = solved.get("position", Vector2.ZERO)
		var facing: String = str(solved.get("facing", ""))
		var inside_click: bool = _rect_shape_contains(pick, pos)
		var inside_legs: bool = _rect_shape_contains(walk, pos)
		var body_blocked: bool = _workbench_body_blocked(live, pos)
		failed += _assert(facing == "north", "%s faces the bench from the south (got %s)" % [actor_id, facing])
		failed += _assert(pos.y > footprint.position.y + footprint.size.y - 1.0, "%s stands south of the bench" % actor_id)
		failed += _assert(inside_click, "%s bench spot is inside the interaction area %s" % [actor_id, pos])
		failed += _assert(not inside_legs, "%s bench spot is outside the collision %s" % [actor_id, pos])
		failed += _assert(not body_blocked and not bool(solved.get("fallback", false)), "%s can stand at the bench %s" % [actor_id, pos])
	live.free()
	save_service.call("note_session_ended")
	save_service.set("boot_intent", "auto")
	if failed == 0:
		print("WORKBENCH_REACH_OK")
	return failed


func _rect_shape_contains(shape_node: CollisionShape2D, point: Vector2) -> bool:
	if shape_node == null or not (shape_node.shape is RectangleShape2D):
		return false
	var rect: RectangleShape2D = shape_node.shape as RectangleShape2D
	var local: Vector2 = shape_node.global_transform.affine_inverse() * point
	var half: Vector2 = rect.size * 0.5
	return absf(local.x) <= half.x + 0.5 and absf(local.y) <= half.y + 0.5


func _workbench_body_blocked(live: Node, pos: Vector2) -> bool:
	var space: PhysicsDirectSpaceState2D = live.get_world_2d().direct_space_state
	if space == null:
		return true
	if live.has_method("_in_clearing") and not bool(live.call("_in_clearing", pos)):
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
	params.exclude = exclude
	return not space.intersect_shape(params, 1).is_empty()


func _keeper_work_spot_asserts() -> int:
	var failed: int = 0
	# Loaded at runtime so this SceneTree script does not compile keeper.gd before autoloads exist.
	var keeper_cls = load("res://scripts/keeper.gd")
	var open_gate = keeper_cls.WorkSpotGate.new()
	var wood_fp := Rect2(Vector2(100, -30), Vector2(40, 30))
	var from_west: Dictionary = keeper_cls.solve_work_spot(wood_fp, Vector2(0, 0), "wood", Callable(open_gate, "gate"))
	var from_east: Dictionary = keeper_cls.solve_work_spot(wood_fp, Vector2(400, 0), "wood", Callable(open_gate, "gate"))
	failed += _assert(str(from_west.get("side", "")) == "east" and str(from_west.get("facing", "")) == "west", "wood is forced to the right side, facing left")
	failed += _assert(str(from_east.get("side", "")) == "east" and str(from_east.get("facing", "")) == "west", "wood ignores the nearer left side")
	failed += _assert(bool(from_west.get("fallback", true)) == false, "forced wood side is not a fallback")
	var wood_contact: Vector2 = from_west.get("contact", Vector2.ZERO)
	var wood_feet: Vector2 = from_west.get("position", Vector2.ZERO)
	failed += _assert(keeper_cls.distance_to_rect(wood_contact, wood_fp) <= keeper_cls.REACH_SLACK, "axe contact reaches the trunk (dist %s)" % str(keeper_cls.distance_to_rect(wood_contact, wood_fp)))
	failed += _assert(wood_contact.x < wood_feet.x, "west facing points back at the tree")
	var elaia_wood: Dictionary = keeper_cls.solve_work_spot(wood_fp, Vector2(0, 0), "wood", Callable(open_gate, "gate"), "", "elaia")
	failed += _assert(str(elaia_wood.get("side", "")) == "east" and str(elaia_wood.get("facing", "")) == "west", "elaia wood uses the same forced side")
	var stone_fp := Rect2(Vector2(100, -30), Vector2(40, 30))
	var stone_from_west: Dictionary = keeper_cls.solve_work_spot(stone_fp, Vector2(0, 0), "stone", Callable(open_gate, "gate"))
	failed += _assert(str(stone_from_west.get("side", "")) == "west" and str(stone_from_west.get("facing", "")) == "east", "stone still picks the near side")
	var blocked_west = keeper_cls.WorkSpotGate.new()
	blocked_west.block_west_of = stone_fp.position.x
	var other_side: Dictionary = keeper_cls.solve_work_spot(stone_fp, Vector2(0, 0), "stone", Callable(blocked_west, "gate"))
	failed += _assert(str(other_side.get("side", "")) == "east" and str(other_side.get("facing", "")) == "west", "blocked west side picks east")
	failed += _assert(bool(other_side.get("fallback", true)) == false, "the open side is a real spot")
	failed += _assert((other_side.get("contact", Vector2.ZERO) as Vector2).x < (other_side.get("position", Vector2.ZERO) as Vector2).x, "west facing points back at the target")
	var block_all = keeper_cls.WorkSpotGate.new()
	block_all.block_all = true
	var fallback: Dictionary = keeper_cls.solve_work_spot(wood_fp, Vector2(0, 0), "wood", Callable(block_all, "gate"))
	failed += _assert(bool(fallback.get("fallback", false)), "blocked forced side sets fallback")
	failed += _assert(str(fallback.get("side", "")) == "east", "blocked wood stays on the forced side")
	var tree_fp := Rect2(Vector2(200, 0), Vector2.ZERO)
	var water: Dictionary = keeper_cls.solve_work_spot(tree_fp, Vector2(0, 0), "manatree", Callable(open_gate, "gate"))
	var water_far: Dictionary = keeper_cls.solve_work_spot(tree_fp, Vector2(900, 40), "manatree", Callable(open_gate, "gate"))
	var water_feet: Vector2 = water.get("position", Vector2(9999, 9999))
	failed += _assert(is_equal_approx(water_feet.x, 98.0) and is_equal_approx(water_feet.y, 35.0), "watering stands so the stream ends on the soil in front of the base")
	failed += _assert(str(water.get("facing", "")) == "east" and str(water.get("side", "")) == "west", "watering uses the single west stand")
	failed += _assert((water_far.get("position", Vector2.ZERO) as Vector2).is_equal_approx(water_feet), "watering ignores approach and stage size")
	var water_contact: Vector2 = water.get("contact", Vector2(9999, 9999))
	failed += _assert(absf(water_contact.x - 200.0) <= keeper_cls.REACH_SLACK, "spout reaches the trunk base")
	failed += _assert(is_equal_approx(water_feet.y - 5.0, 30.0), "stream ends 30px south of the sill")
	var elaia_water: Dictionary = keeper_cls.solve_work_spot(tree_fp, Vector2(0, 0), "manatree", Callable(open_gate, "gate"), "", "elaia")
	var elaia_water_feet: Vector2 = elaia_water.get("position", Vector2(9999, 9999))
	failed += _assert(is_equal_approx(elaia_water_feet.x, 118.0) and is_equal_approx(elaia_water_feet.y, 35.0), "elaia stream also ends on that soil")
	var station_fp := Rect2(Vector2(-80, -160), Vector2(160, 160))
	var station: Dictionary = keeper_cls.solve_work_spot(station_fp, Vector2(0, 200), "station", Callable(open_gate, "gate"), "anvil")
	var station_feet: Vector2 = station.get("position", Vector2(9999, 9999))
	failed += _assert(str(station.get("side", "")) == "south" and str(station.get("facing", "")) == "north", "station work stands south and faces north")
	failed += _assert(is_equal_approx(station_feet.y, 28.0), "station feet are 28 px south of the sprite")
	failed += _assert(keeper_cls.distance_to_rect(station.get("contact", Vector2(0, 99)), station_fp) <= keeper_cls.REACH_SLACK, "station hands reach the work surface")
	for pair: Array in [["wood", "axe"], ["stone", "pickaxe"], ["food", "berries"], ["runestone", "berries"], ["manatree", "water"], ["station", "station"]]:
		failed += _assert(keeper_cls.tool_for_type(str(pair[0])) == str(pair[1]), "%s uses %s" % [str(pair[0]), str(pair[1])])
	failed += _assert(keeper_cls.work_anim_for("axe", "west") == "harvest_axe_west", "axe west clip")
	failed += _assert(keeper_cls.work_anim_for("berries", "east") == "harvest_berries_east", "berries east clip")
	failed += _assert(keeper_cls.work_anim_for("water", "west") == "harvest_water_west", "water west clip")
	failed += _assert(keeper_cls.work_anim_for("station", "north") == "station_work_north", "station clip")
	failed += _assert(keeper_cls.work_anim_for("unknown", "east") == "idle_south", "unmatched work falls back to idle")
	failed += _assert(keeper_cls.facing_for_velocity(Vector2.ZERO, "west") == "west", "zero velocity keeps the last facing")
	failed += _assert(keeper_cls.facing_for_velocity(Vector2(1, 1), "south") == "east", "equal axes prefer horizontal")
	failed += _assert(keeper_cls.facing_for_velocity(Vector2(0, 4), "east") == "south", "south velocity")
	failed += _assert(keeper_cls.facing_for_velocity(Vector2(-3, 1), "south") == "west", "west velocity")
	failed += _assert(keeper_cls.facing_for_velocity(Vector2(1, -4), "south") == "north", "north velocity")
	failed += _assert(keeper_cls.walk_anim_for_velocity(Vector2(0, 4), "east") == "walk_south", "south walk clip")
	failed += _assert(is_equal_approx(keeper_cls.walk_speed_scale_for(180.0), 2.25), "default walk speed_scale is 180/80")
	var stone: Dictionary = keeper_cls.solve_work_spot(Rect2(Vector2(0, -96), Vector2(92, 96)), Vector2(-200, 0), "stone", Callable(open_gate, "gate"))
	failed += _assert(keeper_cls.distance_to_rect(stone.get("contact", Vector2(9999, 9999)), Rect2(Vector2(0, -96), Vector2(92, 96))) <= keeper_cls.REACH_SLACK, "pickaxe reaches stone")
	var food: Dictionary = keeper_cls.solve_work_spot(Rect2(Vector2(0, -128), Vector2(86, 128)), Vector2(400, 0), "food", Callable(open_gate, "gate"))
	failed += _assert(str(food.get("facing", "")) == "west", "berries approached from the east face west")
	failed += _assert(keeper_cls.distance_to_rect(food.get("contact", Vector2(-999, 0)), Rect2(Vector2(0, -128), Vector2(86, 128))) <= keeper_cls.REACH_SLACK, "hands reach the bush")
	return failed


func _assert(cond: bool, msg: String) -> int:
	if cond:
		return 0
	printerr("ASSERT FAIL: %s" % msg)
	return 1


func _waypoint_pass(tree_root: Window, game_state: Node, save_service: Node, backpack: Node, content_strings: Node, game_audio: Node) -> int:
	var failed: int = 0
	var jobs: Node = tree_root.get_node("ForgeJobs")
	var equipment: Node = tree_root.get_node("Equipment")
	game_state.call("reset_for_new_game")
	failed += _assert(int(game_state.call("get_water_essence_amount")) == 1, "deep roots rank 0 → 1")
	var ranks: Dictionary = game_state.get("upgrade_ranks")
	ranks["deep_roots"] = 1
	game_state.set("upgrade_ranks", ranks)
	failed += _assert(int(game_state.call("get_water_essence_amount")) == 1, "deep roots rank 1 → 1")
	ranks["deep_roots"] = 2
	game_state.set("upgrade_ranks", ranks)
	failed += _assert(int(game_state.call("get_water_essence_amount")) == 2, "deep roots rank 2 → 2")
	ranks["deep_roots"] = 10
	game_state.set("upgrade_ranks", ranks)
	failed += _assert(int(game_state.call("get_water_essence_amount")) == 6, "deep roots rank 10 → 6")
	var deep: Dictionary = game_state.call("get_upgrade_def", "deep_roots")
	failed += _assert(absf(float(deep.get("value_per_rank", 0.0)) - 0.5) < 0.001, "deep roots value_per_rank 0.5")
	failed += _assert(absf(float(game_audio.call("duck_amount_db")) + 5.0) < 0.01, "duck amount -5")
	failed += _assert(absf(float(game_audio.call("duck_attack_sec")) - 0.05) < 0.001, "duck attack 0.05")
	failed += _assert(absf(float(game_audio.call("duck_release_sec")) - 0.6) < 0.001, "duck release 0.6")
	failed += _assert(str(game_audio.call("duck_hold")) == "while_playing", "duck holds while playing")
	game_audio.call("clear_played_log")
	game_audio.call("play_quiet", &"sfx_ui_confirm", -14.0)
	failed += _assert(absf(float(game_audio.get("last_cue_volume_db")) + 14.0) < 0.01, "quiet sets its own dB")
	game_audio.call("play", &"sfx_ui_cancel")
	failed += _assert(absf(float(game_audio.get("last_cue_volume_db"))) < 0.01, "next play resets volume_db")
	game_state.call("reset_for_new_game")
	game_audio.call("clear_played_log")
	# An earlier keeper harvest in this process can still be inside the 0.9s global gap.
	await game_state.get_tree().create_timer(1.0, true).timeout
	game_state.call("accumulate_keeper_harvest", &"wood", 2.0)
	failed += _assert(bool(game_audio.call("did_play", &"sfx_gather_wood")), "keeper wood gather ticks")
	game_audio.call("clear_played_log")
	game_state.call("accumulate_keeper_harvest", &"stone", 2.0)
	failed += _assert(not bool(game_audio.call("did_play", &"sfx_gather_stone")), "gather gap skips the next tick")
	game_audio.call("clear_played_log")
	game_state.call("accumulate_wisp_harvest", &"food", 20.0)
	failed += _assert(not bool(game_audio.call("did_play", &"sfx_gather_food")), "wisp harvest stays silent")
	game_audio.call("clear_played_log")
	game_state.call("apply_save_dict", {"stage_id": "young", "wood": 3})
	await game_state.get_tree().process_frame
	failed += _assert(not bool(game_audio.call("did_play", &"sfx_stage_up")), "load does not play stage_up")
	failed += _assert(not bool(game_audio.call("did_play", &"sfx_fruit_ready")), "load does not play fruit_ready")
	game_audio.call("clear_played_log")
	game_state.call("reset_for_new_game")
	game_state.call("_set_stage", &"ancient")
	failed += _assert(bool(game_audio.call("did_play", &"sfx_stage_up")), "ancient plays stage_up now")
	failed += _assert(not bool(game_audio.call("did_play", &"sfx_fruit_ready")), "fruit_ready waits")
	await game_state.get_tree().create_timer(0.85, true).timeout
	failed += _assert(bool(game_audio.call("did_play", &"sfx_fruit_ready")), "fruit_ready follows stage_up")
	game_state.call("reset_for_new_game")
	game_state.call("_set_stage", &"ancient")
	game_state.set("ancient_remaining_sec", 0.2)
	game_state.call("tick_ancient", 0.3)
	failed += _assert(bool(game_state.get("ancient_frozen")), "timeout freezes the clearing")
	failed += _assert(bool(game_state.get("fruit_committed")), "timeout keeps the fruit committed")
	game_state.call("cancel_fruit_commit")
	failed += _assert(bool(game_state.get("fruit_committed")), "frozen commit cannot be cancelled")
	game_state.call("reset_for_new_game")
	game_state.call("_set_stage", &"ancient")
	game_state.call("harvest_fruit")
	failed += _assert(not bool(game_state.get("ancient_frozen")), "manual harvest stays cancelable")
	game_state.call("cancel_fruit_commit")
	failed += _assert(not bool(game_state.get("fruit_committed")), "manual close clears the commit")
	var frozen_save: Dictionary = save_service.call("_migrate", 9, {
		"stage_id": "ancient",
		"ancient_remaining_sec": 0.0,
		"fruit_committed": false,
	})
	failed += _assert(bool(frozen_save.get("ancient_frozen", false)), "v9 timer at 0 becomes frozen")
	failed += _assert(bool(frozen_save.get("fruit_committed", false)), "v9 timer at 0 commits the fruit")
	var open_save: Dictionary = save_service.call("_migrate", 9, {
		"stage_id": "ancient",
		"ancient_remaining_sec": 40.0,
		"fruit_committed": true,
	})
	failed += _assert(not bool(open_save.get("ancient_frozen", true)), "v9 live timer is not frozen")
	var visited: Dictionary = save_service.call("_migrate", 9, {"forge_key": true, "stage_id": "sapling"})
	failed += _assert(bool(visited.get("forge_visited", false)), "old forge key infers a visit")
	save_service.call("delete_save")
	save_service.set("session_active", true)
	save_service.call("set_autosave_coalesce", 0.0)
	failed += _assert(bool(save_service.call("save_game", 2)), "manual slot 2 writes")
	failed += _assert(bool(save_service.call("has_slot", 2)), "manual slot 2 exists")
	failed += _assert(bool(save_service.call("save_autosave", true)), "autosave 1")
	failed += _assert(bool(save_service.call("save_autosave", true)), "autosave 2")
	failed += _assert(bool(save_service.call("save_autosave", true)), "autosave 3")
	var ts1: float = float(save_service.call("get_autosave_info", 1).get("timestamp", 0.0))
	var ts2: float = float(save_service.call("get_autosave_info", 2).get("timestamp", 0.0))
	var ts3: float = float(save_service.call("get_autosave_info", 3).get("timestamp", 0.0))
	failed += _assert(ts1 > 0.0 and ts2 > ts1 and ts3 > ts2, "three autosaves keep distinct timestamps")
	var before: Dictionary = save_service.call("get_autosave_info", 1)
	failed += _assert(bool(save_service.call("save_autosave", true)), "autosave rotates")
	var after: Dictionary = save_service.call("get_autosave_info", 1)
	failed += _assert(float(after.get("timestamp", 0.0)) > float(before.get("timestamp", 1.0)), "oldest autosave was replaced")
	save_service.call("set_autosave_coalesce", 1.2)
	var burst_before: float = float(save_service.call("get_autosave_info", 2).get("timestamp", 0.0))
	save_service.call("save_autosave", true)
	save_service.call("save_autosave", true)
	failed += _assert(is_equal_approx(float(save_service.call("get_autosave_info", 2).get("timestamp", 0.0)), burst_before), "a burst writes one autosave slot")
	failed += _assert(bool(save_service.call("has_slot", 2)), "autosave left the manual slot")
	failed += _assert(not bool(save_service.call("has_slot", 1)), "new game path did not write slot 1")
	var recent: Dictionary = save_service.call("get_most_recent_record")
	failed += _assert(str(recent.get("kind", "")) == "autosave", "continue sees the newest autosave")
	jobs.call("set_scene_changes_enabled", false)
	jobs.call("set_in_forge_override", 1)
	game_state.call("reset_for_new_game")
	game_state.call("set_resource", &"wood", 80)
	jobs.call("set_keeper_working", "mill", true)
	game_audio.call("clear_played_log")
	failed += _assert(str(jobs.call("try_begin_job", "mill", "heartwood_bits")) == "ok", "manual mill start")
	failed += _assert(bool(game_audio.call("did_play", &"sfx_forge_craft_start")), "manual start plays craft_start")
	game_audio.call("clear_played_log")
	jobs.call("advance_seconds", 60.0)
	failed += _assert(bool(game_audio.call("did_play", &"sfx_forge_craft_done")), "repeat still finishes with craft_done")
	failed += _assert(not bool(game_audio.call("did_play", &"sfx_forge_craft_start")), "auto-repeat does not replay craft_start")
	var tip: String = str(equipment.call("item_tooltip", "rootsteel_edge"))
	failed += _assert(tip.find("Rootsteel") < 0 or tip.find("blade") >= 0, "rootsteel flavour")
	failed += _assert(tip.find("+5") >= 0 and tip != "rootsteel_edge", "rootsteel tooltip is not the id")
	var mat: String = str(backpack.call("item_tooltip", "sapsteel"))
	failed += _assert(mat.find("Sapsteel") >= 0 or mat.find("Stone warmed") >= 0, "sapsteel flavour")
	failed += _assert(mat != "sapsteel", "sapsteel tooltip is not the id")
	failed += _assert(str(content_strings.call("get_text", "ascend_frozen_button")) == "Ascend", "frozen button label")
	failed += _assert(str(content_strings.call("get_text", "nav_to_clearing")) == "To the Clearing", "clearing nav label")
	save_service.call("delete_save")
	game_state.call("reset_for_new_game")
	jobs.call("set_in_forge_override", -1)
	jobs.call("set_scene_changes_enabled", true)
	save_service.set("session_active", false)
	return failed


const _HUB_SCENE: String = "res://scenes/main.tscn"
const _FORGE_SCENE: String = "res://scenes/forge_room.tscn"
const _TITLE_SCENE: String = "res://scenes/title_screen.tscn"


func _scene_transitions(tree_root: Window, game_state: Node, save_service: Node) -> int:
	## Every way between the Clearing and the Forge. The active scene must never
	## become the title screen unless this process is actually starting.
	var failed: int = 0
	var jobs: Node = tree_root.get_node_or_null("ForgeJobs")
	var echo: Node = tree_root.get_node_or_null("EchoChamber")
	failed += _assert(jobs != null, "ForgeJobs for scene transitions")
	if jobs == null:
		return failed
	failed += _export_strip_keeps_scenes()
	if echo:
		echo.set("in_battle", false)
	game_state.set("ancient_frozen", false)
	jobs.call("set_in_forge_override", -1)
	jobs.call("set_scene_changes_enabled", true)
	paused = false
	var party: Array[bool] = [false, true]
	for joined: bool in party:
		for round_i: int in 3:
			failed += await _transition_round(game_state, save_service, jobs, joined, round_i)
			if failed > 0:
				break
		if failed > 0:
			break
	if failed == 0:
		failed += await _transition_footsteps_popup(game_state, save_service, jobs)
	if failed == 0:
		failed += await _transition_after_continue(game_state, save_service, jobs)
	if failed == 0:
		failed += await _transition_bare_launch_still_title(game_state, save_service)
	_drop_current_scene()
	save_service.call("note_session_ended")
	save_service.set("boot_intent", "auto")
	save_service.set("boot_slot", 0)
	save_service.call("delete_save")
	game_state.call("reset_for_new_game")
	jobs.call("set_in_forge_override", -1)
	jobs.call("set_scene_changes_enabled", true)
	paused = false
	if failed == 0:
		print("SCENE_TRANSITIONS_OK")
	return failed


const _STABLE_PRESET: String = "Windows Release / Stable"
const _TESTING_PRESET: String = "Windows Testing / Experimental"
const _SPEED_HINT: String = "Test only. Cycles 1× → 2× → 4× → 8× → 16×. Speeds harvest, growth, Ancient, crafting and Wisps. Turning the option off resets to 1×."


func _stripped_paths() -> PackedStringArray:
	return PackedStringArray([
		"tools/AnimPreview.tscn",
		"tools/anim_preview.gd",
		"tools/debug/debug_panel.tscn",
		"tools/debug/debug_panel.gd",
		"tools/debug/snapshots/pre_echo.json",
		"tools/debug/snapshots/forge_unlocked.json",
		"tools/debug/snapshots/elaia_joined.json",
		"tools/debug/snapshots/ancient_ready.json",
		"tools/debug/snapshots/echo2_ready.json",
		"tools/debug/snapshots/north_road_open.json",
		"tools/debug/snapshots/pre_boss.json",
		"tools/debug/snapshots/veteran_reacher.json",
	])


func _debug_stripped_ok() -> int:
	## Stable pack must not contain the debug panel, its snapshots, or AnimPreview.
	## The file table is read when the exported .pck is on disk. Preset excludes
	## are always checked, the same way the play-scene strip is checked.
	var failed: int = 0
	var content: Node = get_root().get_node_or_null("ContentStrings")
	var game_state: Node = get_root().get_node_or_null("GameState")
	failed += _assert(content != null, "ContentStrings for debug strip")
	if content != null:
		failed += _assert(str(content.call("get_text", "options_speedup_toggle")) == "Show speed-up button", "options_speedup_toggle")
		failed += _assert(str(content.call("get_text", "options_speedup_toggle_hint")) == _SPEED_HINT, "options_speedup_toggle_hint")
		failed += _assert(str(content.call("get_text", "options_debug_tools_toggle")) == "Show debug tools", "options_debug_tools_toggle")
	var presets: Dictionary = _parse_export_presets(FileAccess.get_file_as_string("res://export_presets.cfg"))
	var stable: Dictionary = presets.get(_STABLE_PRESET, {}) as Dictionary
	var testing: Dictionary = presets.get(_TESTING_PRESET, {}) as Dictionary
	failed += _assert(not stable.is_empty(), "stable preset present")
	failed += _assert(not testing.is_empty(), "testing preset present")
	failed += _assert(not presets.has("Windows Desktop"), "old Windows Desktop preset is gone")
	if stable.is_empty() or testing.is_empty():
		return failed
	var stable_exclude: PackedStringArray = _exclude_tokens(str(stable.get("exclude", "")))
	var testing_exclude: PackedStringArray = _exclude_tokens(str(testing.get("exclude", "")))
	failed += _assert(stable_exclude.has("tools/*"), "stable excludes tools/*")
	failed += _assert(not testing_exclude.has("tools/*"), "testing keeps tools for the debug pack")
	failed += _assert(str(stable.get("features", "")) == "manaforge_stable", "stable feature manaforge_stable")
	failed += _assert(str(testing.get("features", "")) == "manaforge_debug", "testing feature manaforge_debug")
	failed += _assert(bool(stable.get("embed_pck", true)) == false, "stable embed_pck false")
	failed += _assert(bool(testing.get("embed_pck", true)) == false, "testing embed_pck false")
	var stripped_paths: PackedStringArray = _stripped_paths()
	for path: String in stripped_paths:
		failed += _assert(stable_exclude.has(path), "stable exclude lists %s" % path)
		failed += _assert(not testing_exclude.has(path), "testing exclude leaves %s" % path)
		failed += _assert(FileAccess.file_exists("res://%s" % path), "debug resource exists %s" % path)
	failed += _assert(testing_exclude.has("tools/bake_hub_layout.gd"), "testing still excludes the baker")
	failed += _assert(testing_exclude.has("scripts/verify_headless.gd"), "testing still excludes verify")
	failed += _assert(stable_exclude.has("docs/*"), "stable excludes docs")
	var stable_pck: String = _preset_pck_path(str(stable.get("export_path", "")))
	var testing_pck: String = _preset_pck_path(str(testing.get("export_path", "")))
	var require_pck: bool = OS.get_environment("MANAFORGE_DEBUG_STRIP") == "1"
	if stable_pck != "" and FileAccess.file_exists(stable_pck):
		var stable_files: PackedStringArray = _read_pck_paths(stable_pck)
		failed += _assert(stable_files.size() > 0, "stable pck has a file table")
		for path: String in stripped_paths:
			failed += _assert(not _pck_has(stable_files, path), "stable pck omits %s" % path)
		print("DEBUG_STRIPPED_PCK %s files=%d" % [stable_pck, stable_files.size()])
	elif require_pck:
		failed += _assert(false, "stable pck missing at %s" % stable_pck)
	if testing_pck != "" and FileAccess.file_exists(testing_pck):
		var testing_files: PackedStringArray = _read_pck_paths(testing_pck)
		failed += _assert(testing_files.size() > 0, "testing pck has a file table")
		failed += _assert(_pck_has(testing_files, "tools/debug/debug_panel.tscn"), "testing pck keeps the debug panel")
		failed += _assert(_pck_has(testing_files, "tools/AnimPreview.tscn"), "testing pck keeps AnimPreview")
		failed += _assert(_pck_has(testing_files, "tools/debug/snapshots/pre_echo.json"), "testing pck keeps snapshots")
		for reach_snap: String in _REACH_SNAPSHOTS.values():
			failed += _assert(_pck_has(testing_files, reach_snap.trim_prefix("res://")), "testing pck keeps %s" % reach_snap)
		print("DEBUG_KEPT_PCK %s files=%d" % [testing_pck, testing_files.size()])
	elif require_pck:
		failed += _assert(false, "testing pck missing at %s" % testing_pck)
	if game_state != null:
		failed += _probe_debug_snapshots(game_state)
	if failed == 0:
		print("DEBUG_STRIPPED_OK")
	return failed


func _probe_debug_snapshots(game_state: Node) -> int:
	var failed: int = 0
	var jobs: Node = get_root().get_node_or_null("ForgeJobs")
	failed += _probe_one(game_state, "res://tools/debug/snapshots/pre_echo.json")
	failed += _assert(bool(game_state.get("portal_unlocked")), "pre-echo portal is up")
	failed += _assert(not bool(game_state.get("echo_01_resolved")), "pre-echo is not resolved")
	failed += _assert(not bool(game_state.call("elaia_in_party")), "pre-echo has no Elaia")
	failed += _assert(String(game_state.get("stage_id")) == "sapling", "pre-echo is a sapling")
	failed += _assert(int(game_state.get("essence")) >= 30, "pre-echo can pay the Echo fee")
	failed += _probe_one(game_state, "res://tools/debug/snapshots/forge_unlocked.json")
	failed += _assert(String(game_state.get("stage_id")) == "elder", "forge snapshot is elder")
	failed += _assert(bool(game_state.get("forge_key")), "forge snapshot has the key")
	failed += _assert(bool(game_state.get("echo_01_resolved")), "forge snapshot finished the echo")
	failed += _assert(not bool(game_state.get("echo_01_redeemed")), "forge snapshot did not spare")
	failed += _assert(not bool(game_state.call("elaia_in_party")), "forge snapshot has no Elaia")
	if jobs != null:
		failed += _assert(bool(jobs.call("can_enter_forge")), "forge snapshot can enter")
	failed += _probe_one(game_state, "res://tools/debug/snapshots/elaia_joined.json")
	failed += _assert(bool(game_state.call("elaia_in_party")), "elaia snapshot joined")
	failed += _assert(bool(game_state.get("elaia_join_seen")), "elaia snapshot saw the join")
	failed += _assert(bool(game_state.get("first_relic_crafted")), "elaia snapshot crafted a relic")
	failed += _probe_one(game_state, "res://tools/debug/snapshots/ancient_ready.json")
	failed += _assert(String(game_state.get("stage_id")) == "ancient", "ancient snapshot stage")
	failed += _assert(bool(game_state.get("fruit_ready")), "ancient snapshot fruit is ready")
	failed += _assert(not bool(game_state.get("fruit_committed")), "ancient snapshot has not committed")
	failed += _assert(not bool(game_state.get("ancient_frozen")), "ancient snapshot is not frozen")
	game_state.call("reset_for_new_game")
	return failed


func _probe_one(game_state: Node, path: String, want_version: int = 10, through_panel: bool = false) -> int:
	var failed: int = 0
	failed += _assert(FileAccess.file_exists(path), "snapshot file %s" % path)
	if not FileAccess.file_exists(path):
		return failed
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	failed += _assert(typeof(parsed) == TYPE_DICTIONARY, "snapshot json %s" % path)
	if typeof(parsed) != TYPE_DICTIONARY:
		return failed
	var root: Dictionary = parsed
	failed += _assert(int(root.get("save_version", 0)) == want_version, "snapshot save_version %d %s" % [want_version, path])
	var state_v: Variant = root.get("state", {})
	failed += _assert(typeof(state_v) == TYPE_DICTIONARY, "snapshot state %s" % path)
	if typeof(state_v) != TYPE_DICTIONARY:
		return failed
	game_state.call("reset_for_new_game")
	if through_panel:
		## Same path as the debug panel button: read, migrate, then apply.
		var panel_script: Script = load("res://tools/debug/debug_panel.gd") as Script
		var loaded: Dictionary = panel_script.call("load_snapshot_state", path) if panel_script != null else {}
		var migrated: Dictionary = loaded.get("state", {}) as Dictionary
		failed += _assert(not migrated.is_empty(), "panel loader migrates %s (%s)" % [path, str(loaded.get("error", ""))])
		if not migrated.is_empty():
			game_state.call("apply_save_dict", migrated)
		return failed
	game_state.call("apply_save_dict", state_v)
	return failed


func _parse_export_presets(text: String) -> Dictionary:
	var by_index: Dictionary = {}
	var current := ""
	var in_options := false
	for raw_line: String in text.split("\n"):
		var line := raw_line.strip_edges()
		if line.begins_with("[") and line.ends_with("]"):
			var body := line.substr(1, line.length() - 2)
			if body.begins_with("preset.") and body.ends_with(".options"):
				in_options = true
				current = body.trim_prefix("preset.").trim_suffix(".options")
			elif body.begins_with("preset."):
				in_options = false
				current = body.trim_prefix("preset.")
				if not by_index.has(current):
					by_index[current] = {
						"name": "",
						"exclude": "",
						"export_path": "",
						"features": "",
						"embed_pck": true,
					}
			else:
				in_options = false
				current = ""
			continue
		if current == "" or not by_index.has(current):
			continue
		var row: Dictionary = by_index[current]
		if not in_options:
			if line.begins_with("name="):
				row["name"] = _cfg_string(line)
			elif line.begins_with("exclude_filter="):
				row["exclude"] = _cfg_string(line)
			elif line.begins_with("export_path="):
				row["export_path"] = _cfg_string(line)
			elif line.begins_with("custom_features="):
				row["features"] = _cfg_string(line)
		elif line.begins_with("binary_format/embed_pck="):
			row["embed_pck"] = line.ends_with("true")
		by_index[current] = row
	var named: Dictionary = {}
	for key: Variant in by_index.keys():
		var row: Dictionary = by_index[key]
		var preset_name: String = str(row.get("name", ""))
		if preset_name != "":
			named[preset_name] = row
	return named


func _cfg_string(line: String) -> String:
	var value := line.substr(line.find("=") + 1).strip_edges()
	if value.begins_with("\"") and value.ends_with("\"") and value.length() >= 2:
		value = value.substr(1, value.length() - 2)
	return value


func _exclude_tokens(filter: String) -> PackedStringArray:
	var out := PackedStringArray()
	for part: String in filter.split(","):
		var token := part.strip_edges()
		if token != "":
			out.append(token)
	return out


func _preset_pck_path(export_path: String) -> String:
	if export_path == "":
		return ""
	var root_path := ProjectSettings.globalize_path("res://")
	return root_path.path_join(export_path).get_basename() + ".pck"


func _pck_has(files: PackedStringArray, path: String) -> bool:
	## Export writes res://scripts/foo.gd plus foo.gdc, and scenes as foo.tscn.remap.
	var needle := path.trim_prefix("res://").replace("\\", "/")
	var needle_base := needle.get_basename()
	for entry: String in files:
		var cleaned := entry.trim_prefix("res://").replace("\\", "/")
		var bare := cleaned.trim_suffix(".remap")
		if cleaned == needle or bare == needle or bare.get_basename() == needle_base:
			return true
	return false


func _read_pck_paths(path: String) -> PackedStringArray:
	## Godot 4.7 pack directory (format v2, v3, or v4). Paths only.
	var out := PackedStringArray()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return out
	var magic := file.get_32()
	if magic != 0x43504447:
		file.close()
		return out
	var version := file.get_32()
	file.get_32()
	file.get_32()
	file.get_32()
	var pack_flags := file.get_32()
	file.get_64()
	if version == 3 or version == 4:
		var dir_offset := file.get_64()
		if (pack_flags & 1) != 0:
			file.close()
			push_error("encrypted pck directory is not inspected: %s" % path)
			return out
		file.seek(dir_offset)
	elif version == 2:
		for _pad: int in 16:
			file.get_32()
	else:
		file.close()
		push_error("unsupported pck version %d in %s" % [version, path])
		return out
	var count := file.get_32()
	if count < 0 or count > 200000:
		file.close()
		return out
	for _i: int in count:
		var length := int(file.get_32())
		if length < 0 or length > 4096:
			break
		var raw := file.get_buffer(length)
		while raw.size() > 0 and raw[raw.size() - 1] == 0:
			raw.resize(raw.size() - 1)
		var entry := raw.get_string_from_utf8()
		file.get_64()
		file.get_64()
		file.get_buffer(16)
		file.get_32()
		out.append(entry)
	file.close()
	return out


func _export_strip_keeps_scenes() -> int:
	var failed: int = 0
	var preset: String = FileAccess.get_file_as_string("res://export_presets.cfg")
	var paths: PackedStringArray = PackedStringArray([
		"res://scenes/main.tscn",
		"res://scenes/forge_room.tscn",
		"res://scenes/title_screen.tscn",
		"res://scenes/hud.tscn",
		"res://scripts/main.gd",
		"res://scripts/forge_room.gd",
		"res://scripts/hud.gd",
		"res://scripts/autoload/forge_jobs.gd",
		"res://scripts/autoload/save_service.gd",
	])
	for path: String in paths:
		failed += _assert(ResourceLoader.exists(path), "scene transition resource %s" % path)
		failed += _assert(preset.find(path.trim_prefix("res://")) < 0, "export strip leaves %s" % path)
	failed += _assert(preset.find("exclude_filter") >= 0, "export preset has a strip list")
	return failed


func _transition_round(game_state: Node, save_service: Node, jobs: Node, joined: bool, round_i: int) -> int:
	var tag: String = "joined" if joined else "solo"
	var failed: int = await _boot_play(game_state, save_service, joined)
	if failed > 0:
		return failed
	var wood_before: int = 19 + round_i
	game_state.call("set_resource", &"wood", wood_before)
	var keeper_spot: Vector2 = Vector2(800, 1048)
	var elaia_forge: Vector2 = Vector2(860, 1040)
	var elaia_clear: Vector2 = Vector2(560, 540)
	var keeper_clear: Vector2 = Vector2(480, 520)
	_place_actor(game_state, "keeper", "forge", keeper_spot)
	if joined:
		_place_actor(game_state, "elaia", "clearing", elaia_clear)
	failed += await _enter_forge_view()
	if failed > 0:
		return failed
	failed += await _press_nav("nav_hub/%s/%d" % [tag, round_i], _HUB_SCENE)
	failed += _live_unchanged(game_state, "keeper", "forge", keeper_spot, wood_before)
	if joined:
		failed += _live_unchanged(game_state, "elaia", "clearing", elaia_clear, wood_before)
	failed += await _bodies_where(game_state, joined)
	if failed > 0:
		return failed
	failed += await _press_nav("nav_forge/%s/%d" % [tag, round_i], _FORGE_SCENE)
	failed += _live_unchanged(game_state, "keeper", "forge", keeper_spot, wood_before)
	failed += await _bodies_where(game_state, joined)
	if failed > 0:
		return failed
	failed += await _press_escape("escape_hub/%s/%d" % [tag, round_i], _HUB_SCENE)
	failed += _live_unchanged(game_state, "keeper", "forge", keeper_spot, wood_before)
	failed += await _bodies_where(game_state, joined)
	if failed > 0:
		return failed
	# Hub Escape opens the pause menu. It must not dump the player on the title.
	failed += await _press_hub_escape("escape_stays/%s/%d" % [tag, round_i])
	if failed > 0:
		return failed
	failed += await _enter_forge_view()
	failed += await _press_footsteps("footsteps_hub/%s/%d" % [tag, round_i])
	failed += _live_unchanged(game_state, "keeper", "forge", keeper_spot, wood_before)
	failed += _assert(not _scene_path().ends_with("title_screen.tscn"), "footsteps avoided the title")
	if failed > 0:
		return failed
	_place_actor(game_state, "keeper", "forge", keeper_spot)
	if joined:
		_place_actor(game_state, "elaia", "clearing", elaia_clear)
	failed += await _enter_forge_view()
	var stand: Vector2 = jobs.call("clearing_door_stand")
	failed += await _walk_out("door_keeper/%s/%d" % [tag, round_i], "keeper", stand)
	failed += _assert(int(game_state.get("wood")) == wood_before, "door keeps wood")
	if joined:
		failed += _live_unchanged(game_state, "elaia", "clearing", elaia_clear, wood_before)
	failed += await _bodies_where(game_state, joined)
	if failed > 0:
		return failed
	if joined:
		_place_actor(game_state, "keeper", "clearing", keeper_clear)
		_place_actor(game_state, "elaia", "forge", elaia_forge)
		failed += await _enter_forge_view()
		stand = jobs.call("clearing_door_stand")
		failed += await _walk_out("door_elaia/%s/%d" % [tag, round_i], "elaia", stand)
		failed += _live_unchanged(game_state, "keeper", "clearing", keeper_clear, wood_before)
		failed += await _bodies_where(game_state, joined)
		if failed > 0:
			return failed
	# Portraits follow whoever is in the other scene, and they do not move that character.
	if _scene_path() != _HUB_SCENE:
		failed += await _press_nav("portrait_setup_hub/%s/%d" % [tag, round_i], _HUB_SCENE)
	_place_actor(game_state, "keeper", "forge", keeper_spot)
	failed += await _portrait("portrait_keeper_to_forge/%s/%d" % [tag, round_i], "keeper", _FORGE_SCENE)
	failed += _live_unchanged(game_state, "keeper", "forge", keeper_spot, wood_before)
	failed += await _bodies_where(game_state, joined)
	_place_actor(game_state, "keeper", "clearing", keeper_clear)
	failed += await _portrait("portrait_keeper_to_hub/%s/%d" % [tag, round_i], "keeper", _HUB_SCENE)
	failed += _live_unchanged(game_state, "keeper", "clearing", keeper_clear, wood_before)
	failed += await _bodies_where(game_state, joined)
	if joined:
		_place_actor(game_state, "elaia", "forge", elaia_forge)
		failed += await _portrait("portrait_elaia_to_forge/%s/%d" % [tag, round_i], "elaia", _FORGE_SCENE)
		failed += _live_unchanged(game_state, "elaia", "forge", elaia_forge, wood_before)
		failed += _live_unchanged(game_state, "keeper", "clearing", keeper_clear, wood_before)
		failed += await _bodies_where(game_state, joined)
		_place_actor(game_state, "elaia", "clearing", elaia_clear)
		failed += await _portrait("portrait_elaia_to_hub/%s/%d" % [tag, round_i], "elaia", _HUB_SCENE)
		failed += _live_unchanged(game_state, "elaia", "clearing", elaia_clear, wood_before)
		failed += _live_unchanged(game_state, "keeper", "clearing", keeper_clear, wood_before)
		failed += await _bodies_where(game_state, joined)
	# The old door path still has to land in the clearing, not on the title.
	_place_actor(game_state, "keeper", "forge", keeper_spot)
	failed += await _enter_forge_view()
	jobs.call("exit_forge")
	failed += await _expect_scene("exit_forge/%s/%d" % [tag, round_i], _HUB_SCENE)
	failed += _assert(int(game_state.get("wood")) == wood_before, "exit_forge keeps wood")
	return failed


func _transition_footsteps_popup(game_state: Node, save_service: Node, _jobs: Node) -> int:
	var failed: int = await _boot_play(game_state, save_service, false)
	if failed > 0:
		return failed
	game_state.set("echo_01_redeemed", true)
	game_state.set("first_relic_crafted", true)
	game_state.set("elaia_join_seen", false)
	game_state.set("elaia_footsteps_seen", false)
	game_state.set("forge_visited", true)
	_place_actor(game_state, "keeper", "forge", Vector2(800, 1048))
	failed += await _enter_forge_view()
	var hud: Node = current_scene.get_node_or_null("HUD") if current_scene else null
	var popup: Node = hud.get_node_or_null("ElaiaFootsteps") if hud else null
	var go: Button = popup.get_node_or_null("Go") as Button if popup else null
	failed += _assert(popup != null and popup.visible and go != null, "footsteps popup offers Go and see")
	if go == null:
		return failed
	go.emit_signal("pressed")
	failed += await _expect_scene("footsteps_popup", _HUB_SCENE)
	failed += _assert(bool(game_state.get("elaia_footsteps_seen")), "Go and see marks the footsteps seen")
	failed += _assert(str(game_state.get("keeper_area")) == "forge", "Go and see leaves the Keeper in the Forge")
	return failed


func _transition_after_continue(game_state: Node, save_service: Node, _jobs: Node) -> int:
	var failed: int = await _boot_play(game_state, save_service, true)
	if failed > 0:
		return failed
	var keeper_spot: Vector2 = Vector2(811, 1048)
	var elaia_spot: Vector2 = Vector2(333, 222)
	_place_actor(game_state, "keeper", "forge", keeper_spot)
	_place_actor(game_state, "elaia", "clearing", elaia_spot)
	game_state.set("forge_visited", true)
	game_state.call("set_resource", &"wood", 17)
	failed += _assert(bool(save_service.call("save_game")), "transition continue save")
	save_service.call("note_session_ended")
	save_service.set("boot_intent", "continue")
	save_service.set("boot_slot", 0)
	change_scene_to_file(_HUB_SCENE)
	failed += await _expect_scene("continue_load", _HUB_SCENE)
	failed += _assert(int(game_state.get("wood")) == 17, "continue restored wood")
	failed += _live_unchanged(game_state, "keeper", "forge", keeper_spot, 17)
	failed += _live_unchanged(game_state, "elaia", "clearing", elaia_spot, 17)
	failed += await _bodies_where(game_state, true)
	game_state.call("set_resource", &"wood", 21)
	for round_i: int in 3:
		failed += await _portrait("continue_keeper/%d" % round_i, "keeper", _FORGE_SCENE)
		failed += _live_unchanged(game_state, "keeper", "forge", keeper_spot, 21)
		failed += await _press_nav("continue_nav_hub/%d" % round_i, _HUB_SCENE)
		failed += _live_unchanged(game_state, "elaia", "clearing", elaia_spot, 21)
		failed += await _portrait("continue_elaia/%d" % round_i, "elaia", _HUB_SCENE)
		failed += await _bodies_where(game_state, true)
		if failed > 0:
			return failed
	return failed


func _transition_bare_launch_still_title(game_state: Node, save_service: Node) -> int:
	save_service.call("note_session_ended")
	save_service.set("boot_intent", "auto")
	save_service.set("boot_slot", 0)
	change_scene_to_file(_HUB_SCENE)
	var failed: int = await _expect_scene("bare_launch", _TITLE_SCENE)
	save_service.set("boot_intent", "new")
	change_scene_to_file(_HUB_SCENE)
	failed += await _expect_scene("explicit_new", _HUB_SCENE)
	failed += _assert(int(game_state.get("wood")) == 0, "explicit new game still clears wood")
	failed += _assert(bool(save_service.get("session_active")), "explicit new game starts a session")
	return failed


func _boot_play(game_state: Node, save_service: Node, joined: bool) -> int:
	save_service.call("note_session_ended")
	save_service.call("delete_save")
	save_service.set("boot_intent", "new")
	save_service.set("boot_slot", 0)
	change_scene_to_file(_HUB_SCENE)
	var failed: int = await _expect_scene("boot", _HUB_SCENE)
	if failed > 0:
		return failed
	game_state.set("forge_visited", true)
	game_state.set("ancient_frozen", false)
	if joined:
		game_state.set("echo_01_redeemed", true)
		game_state.set("first_relic_crafted", true)
		game_state.set("elaia_legacy_joined", false)
		game_state.set("elaia_join_seen", true)
		game_state.set("elaia_footsteps_seen", true)
		_place_actor(game_state, "elaia", "clearing", Vector2(640, 640))
	else:
		game_state.set("echo_01_redeemed", false)
		game_state.set("first_relic_crafted", false)
		game_state.set("elaia_legacy_joined", false)
		game_state.set("elaia_join_seen", false)
		game_state.set("elaia_footsteps_seen", false)
	failed += _assert(bool(save_service.get("session_active")), "boot started a session")
	return failed


func _enter_forge_view() -> int:
	if _scene_path() == _FORGE_SCENE:
		return 0
	return await _press_nav("enter_forge", _FORGE_SCENE)


func _press_nav(label: String, expect: String) -> int:
	var hud: Node = current_scene.get_node_or_null("HUD") if current_scene else null
	if hud == null or not hud.has_method("_on_nav_pressed"):
		printerr("ASSERT FAIL: %s nav button missing on %s" % [label, _scene_path()])
		return 1
	hud.call("_on_nav_pressed")
	return await _expect_scene(label, expect)


func _press_escape(label: String, expect: String) -> int:
	if _scene_path() != _FORGE_SCENE:
		var entered: int = await _enter_forge_view()
		if entered > 0:
			return entered
	var room: Node = current_scene
	if room == null or not room.has_method("_on_escape"):
		printerr("ASSERT FAIL: %s escape missing" % label)
		return 1
	room.call("_on_escape")
	return await _expect_scene(label, expect)


func _press_hub_escape(label: String) -> int:
	if _scene_path() != _HUB_SCENE:
		var back: int = await _press_nav(label + "_setup", _HUB_SCENE)
		if back > 0:
			return back
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	Input.parse_input_event(event)
	var failed: int = await _expect_scene(label, _HUB_SCENE)
	var pause_menu: Node = current_scene.get_node_or_null("PauseMenu") if current_scene else null
	if pause_menu and pause_menu.has_method("is_open") and bool(pause_menu.call("is_open")):
		pause_menu.call("resume_game")
		await process_frame
	return failed


func _press_footsteps(label: String) -> int:
	if _scene_path() != _FORGE_SCENE:
		var entered: int = await _enter_forge_view()
		if entered > 0:
			return entered
	var hud: Node = current_scene.get_node_or_null("HUD") if current_scene else null
	if hud == null or not hud.has_method("_on_footsteps_go"):
		printerr("ASSERT FAIL: %s footsteps missing" % label)
		return 1
	hud.call("_on_footsteps_go")
	return await _expect_scene(label, _HUB_SCENE)


func _walk_out(label: String, actor: String, stand: Vector2) -> int:
	var room: Node = current_scene
	var body: Node2D = null
	if room:
		body = room.get_node_or_null("Keeper") as Node2D if actor == "keeper" else room.get_node_or_null("Elaia") as Node2D
	if room == null or body == null or not room.has_method("_on_exit_body"):
		printerr("ASSERT FAIL: %s door missing" % label)
		return 1
	room.call("_on_exit_body", body)
	var failed: int = await _expect_scene(label, _HUB_SCENE)
	var game_state: Node = root.get_node("GameState")
	var area_name: String = "keeper_area" if actor == "keeper" else "elaia_area"
	var pos_name: String = "keeper_pos" if actor == "keeper" else "elaia_pos"
	failed += _assert(str(game_state.get(area_name)) == "clearing", "%s area is the clearing" % label)
	var got: Variant = game_state.get(pos_name)
	var dist: float = (got as Vector2).distance_to(stand) if typeof(got) == TYPE_VECTOR2 else 9999.0
	failed += _assert(dist <= 1.0, "%s stands at the Manatree door (off by %.1f)" % [label, dist])
	return failed


func _portrait(label: String, unit: String, expect: String) -> int:
	var hud: Node = current_scene.get_node_or_null("HUD") if current_scene else null
	if hud == null or not hud.has_method("party_focus"):
		printerr("ASSERT FAIL: %s portrait missing on %s" % [label, _scene_path()])
		return 1
	hud.call("party_focus", unit)
	return await _expect_scene(label, expect)


func _expect_scene(label: String, expect: String) -> int:
	var got: String = await _await_stable_scene()
	var title: bool = got.ends_with("title_screen.tscn")
	var unwanted_title: bool = title and expect != _TITLE_SCENE
	if got != expect or unwanted_title:
		printerr("ASSERT FAIL: %s scene %s, expected %s" % [label, got, expect])
		return 1
	return 0


func _await_stable_scene() -> String:
	var stable: String = ""
	var same: int = 0
	for _i: int in 90:
		await process_frame
		var got: String = _scene_path()
		if got == "" or got == "<null>":
			stable = ""
			same = 0
			continue
		if got == stable:
			same += 1
			if same >= 3:
				return got
		else:
			stable = got
			same = 1
	return _scene_path()


func _scene_path() -> String:
	if current_scene == null:
		return "<null>"
	return str(current_scene.scene_file_path)


func _place_actor(game_state: Node, actor: String, area: String, pos: Vector2) -> void:
	if actor == "keeper":
		game_state.set("keeper_area", area)
		game_state.set("keeper_has_pos", true)
		game_state.set("keeper_pos", pos)
		game_state.set("keeper_facing", "south" if area == "clearing" else "north")
	else:
		game_state.set("elaia_area", area)
		game_state.set("elaia_has_pos", true)
		game_state.set("elaia_pos", pos)
		game_state.set("elaia_facing", "south" if area == "clearing" else "north")


func _live_unchanged(game_state: Node, actor: String, area: String, pos: Vector2, wood: int) -> int:
	var area_name: String = "keeper_area" if actor == "keeper" else "elaia_area"
	var pos_name: String = "keeper_pos" if actor == "keeper" else "elaia_pos"
	var failed: int = _assert(str(game_state.get(area_name)) == area, "%s stays in the %s" % [actor, area])
	var got: Variant = game_state.get(pos_name)
	var dist: float = (got as Vector2).distance_to(pos) if typeof(got) == TYPE_VECTOR2 else 9999.0
	failed += _assert(dist <= 1.0, "%s stays put (off by %.1f)" % [actor, dist])
	failed += _assert(int(game_state.get("wood")) == wood, "wood stays %d (got %d)" % [wood, int(game_state.get("wood"))])
	failed += _assert(not _scene_path().ends_with("title_screen.tscn"), "play did not return to the title")
	return failed


func _bodies_where(game_state: Node, joined: bool) -> int:
	var failed: int = 0
	var home: String = "forge" if _scene_path() == _FORGE_SCENE else "clearing"
	var keeper: Node2D = get_first_node_in_group("keeper") as Node2D
	failed += _assert(keeper != null, "keeper body in %s" % home)
	if keeper:
		var show_keeper: bool = str(game_state.get("keeper_area")) == home
		failed += _assert(keeper.visible == show_keeper, "keeper visibility in the %s" % home)
		if show_keeper and bool(game_state.get("keeper_has_pos")):
			var want: Vector2 = game_state.get("keeper_pos")
			failed += _assert(keeper.global_position.distance_to(want) <= 2.0, "keeper body matches his spot in the %s" % home)
	var elaia: Node2D = get_first_node_in_group("elaia") as Node2D
	if elaia == null and current_scene:
		elaia = current_scene.get_node_or_null("Elaia") as Node2D
	if elaia:
		var show_elaia: bool = joined and str(game_state.get("elaia_area")) == home
		failed += _assert(elaia.visible == show_elaia, "elaia visibility in the %s" % home)
		if show_elaia and bool(game_state.get("elaia_has_pos")):
			var elaia_want: Vector2 = game_state.get("elaia_pos")
			failed += _assert(elaia.global_position.distance_to(elaia_want) <= 2.0, "elaia body matches her spot in the %s" % home)
	return failed


func _drop_current_scene() -> void:
	var scene: Node = current_scene
	if scene == null:
		return
	current_scene = null
	scene.free()


func _portrait_switch_forge(tree_root: Window, game_state: Node, save_service: Node) -> int:
	## Double-clicking the other hero's portrait swaps the view. Both directions
	## used to free the HUD inside the click and remove a CollisionObject mid-physics.
	var failed: int = 0
	var jobs: Node = tree_root.get_node_or_null("ForgeJobs")
	failed += _assert(jobs != null, "ForgeJobs for portrait switch")
	if jobs == null:
		return failed
	var echo: Node = tree_root.get_node_or_null("EchoChamber")
	if echo:
		echo.set("in_battle", false)
	game_state.call("reset_for_new_game")
	game_state.set("ancient_frozen", false)
	game_state.set("echo_01_redeemed", true)
	game_state.set("first_relic_crafted", true)
	game_state.set("elaia_join_seen", true)
	game_state.set("forge_key", true)
	game_state.set("forge_visited", true)
	game_state.set("stage_id", &"elder")
	jobs.call("set_in_forge_override", -1)
	jobs.call("set_scene_changes_enabled", true)
	save_service.set("boot_intent", "auto")
	save_service.call("note_session_started")
	paused = false
	failed += await _portrait_direction(game_state, "keeper", "clearing", "elaia", "forge")
	failed += await _portrait_direction(game_state, "elaia", "clearing", "keeper", "forge")
	_drop_current_scene()
	save_service.call("note_session_ended")
	game_state.call("reset_for_new_game")
	jobs.call("set_in_forge_override", -1)
	paused = false
	if failed == 0:
		print("PORTRAIT_SWITCH_FORGE_OK")
	return failed


func _portrait_direction(game_state: Node, unit: String, unit_area: String, other: String, other_area: String) -> int:
	## The clicked portrait's hero is in unit_area. The camera is in the Forge.
	var failed: int = 0
	_place_actor(game_state, unit, unit_area, Vector2(2160, 2140) if unit_area == "clearing" else Vector2(800, 1048))
	_place_actor(game_state, other, other_area, Vector2(800, 1048) if other_area == "forge" else Vector2(2200, 2140))
	change_scene_to_file(_FORGE_SCENE)
	var stable: String = await _await_stable_scene()
	failed += _assert(stable == _FORGE_SCENE, "portrait setup opens the forge for %s (got %s)" % [unit, stable])
	if current_scene == null:
		return failed + 1
	var hud: Node = current_scene.get_node_or_null("HUD")
	var slot: Control = null
	if hud != null:
		slot = hud.find_child(unit.capitalize(), true, false) as Control
	if hud == null or slot == null or not hud.has_method("_on_party_slot_input"):
		printerr("ASSERT FAIL: portrait slot missing for %s" % unit)
		return failed + 1
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.double_click = true
	hud.call("_on_party_slot_input", click, unit, slot)
	failed += _assert(is_instance_valid(hud), "double-click %s does not free the HUD inside the handler" % unit)
	failed += await _expect_scene("portrait %s to the clearing" % unit, _HUB_SCENE)
	var area_name: String = "keeper_area" if unit == "keeper" else "elaia_area"
	failed += _assert(str(game_state.get(area_name)) == unit_area, "portrait switch leaves %s in the %s" % [unit, unit_area])
	return failed


func _forge_arch_draw_order(tree_root: Window) -> int:
	## The playtest spawn is the arch mouth after a door transfer, not a pose
	## parked on the root lip. ArchFront has to cover the body there, and its
	## draw key has to stay above the heroes on the live scene.
	var failed: int = 0
	var game_state: Node = tree_root.get_node_or_null("GameState")
	var jobs: Node = tree_root.get_node_or_null("ForgeJobs")
	var save_service: Node = tree_root.get_node_or_null("SaveService")
	failed += _assert(game_state != null and jobs != null, "arch transfer needs GameState and ForgeJobs")
	if game_state == null or jobs == null:
		return failed
	var packed: PackedScene = load(_FORGE_SCENE) as PackedScene
	failed += _assert(packed != null, "forge room packed scene")
	if packed != null:
		var cold: Node2D = packed.instantiate() as Node2D
		var cold_arch: Sprite2D = cold.get_node_or_null("ArchFront") as Sprite2D
		var cold_keeper: CanvasItem = cold.get_node_or_null("Keeper") as CanvasItem
		failed += _assert(cold.y_sort_enabled, "packed forge y-sorts heroes against stations")
		failed += _assert(cold_arch != null and cold_keeper != null, "packed forge has ArchFront and Keeper")
		if cold_arch != null and cold_keeper != null:
			failed += _assert(_effective_z(cold_arch) > _effective_z(cold_keeper), "packed ArchFront draws above the Keeper")
			failed += _assert(cold_arch.texture != null and str(cold_arch.texture.resource_path).find("forge_arch_front") >= 0, "packed arch uses forge_arch_front")
		cold.free()
	game_state.call("reset_for_new_game")
	if save_service != null:
		save_service.call("note_session_ended")
	jobs.call("set_scene_changes_enabled", true)
	jobs.call("set_in_forge_override", -1)
	paused = false
	game_state.set("forge_visited", true)
	game_state.set("forge_key", true)
	_place_actor(game_state, "keeper", "clearing", Vector2(2160, 2200))
	var entered: String = str(jobs.call("commit_actor_enter", "keeper"))
	failed += _assert(entered == "entered", "door transfer queues the forge (got %s)" % entered)
	var stable: String = await _await_stable_scene()
	failed += _assert(stable == _FORGE_SCENE, "door transfer opens the forge (got %s)" % stable)
	var room: Node2D = current_scene as Node2D
	if room == null:
		return failed + 1
	var arch: Sprite2D = room.get_node_or_null("ArchFront") as Sprite2D
	var keeper: Node2D = room.get_node_or_null("Keeper") as Node2D
	var elaia: Node2D = room.get_node_or_null("Elaia") as Node2D
	failed += _assert(arch != null and keeper != null and elaia != null, "live forge has arch, keeper, and elaia")
	if arch == null or keeper == null or elaia == null:
		_drop_current_scene()
		return failed
	await process_frame
	var spawn: Vector2 = jobs.call("forge_arch_spawn")
	failed += _assert(keeper.global_position.distance_to(spawn) <= 2.0, "keeper stands at the post-transfer spawn")
	failed += _assert(keeper.get_parent() == room, "keeper stays on the forge room after the transfer")
	failed += _assert(_canvas_layer_above(keeper) == null, "keeper is not reparented onto a CanvasLayer")
	failed += _assert(room.y_sort_enabled, "forge room y-sorts stations and heroes")
	var keeper_item: CanvasItem = keeper as CanvasItem
	var elaia_item: CanvasItem = elaia as CanvasItem
	failed += _assert(_effective_z(arch) > _effective_z(keeper_item), "live arch z stays above the keeper")
	failed += _assert(_effective_z(arch) > _effective_z(elaia_item), "live arch z stays above elaia")
	var covered: int = _arch_body_overlap(arch, keeper.global_position)
	failed += _assert(covered > 40, "arch frame covers the keeper at the door spawn (opaque samples %d)" % covered)
	var deep: int = _arch_body_overlap(arch, Vector2(800, 700))
	failed += _assert(deep == 0, "arch frame does not cover a keeper deep in the room (samples %d)" % deep)
	var lip: int = _arch_body_overlap(arch, Vector2(800, 1160))
	failed += _assert(lip > 40, "arch lip still covers a keeper in the doorway (samples %d)" % lip)
	failed += _assert(_draws_over(arch, keeper_item), "rendered order keeps the arch over the keeper at the spawn")
	failed += _arch_fill_and_floor(arch)
	_drop_current_scene()
	game_state.call("reset_for_new_game")
	jobs.call("set_in_forge_override", -1)
	paused = false
	if failed == 0:
		print("FORGE_ARCH_DRAW_ORDER_OK")
	return failed


func _forge_ysort(tree_root: Window) -> int:
	## Feet order against stations. The arch is a higher z, so it still wins
	## when a hero stands under it (south of the arch node's origin).
	var failed: int = 0
	var packed: PackedScene = load(_FORGE_SCENE) as PackedScene
	failed += _assert(packed != null, "forge room for y-sort")
	if packed == null:
		return failed
	change_scene_to_packed(packed)
	var stable: String = await _await_stable_scene()
	failed += _assert(stable == _FORGE_SCENE, "y-sort check is in the forge")
	var room: Node2D = current_scene as Node2D
	if room == null:
		return failed + 1
	failed += _assert(room.y_sort_enabled, "forge room y-sort is on")
	var arch: CanvasItem = room.get_node_or_null("ArchFront") as CanvasItem
	var keeper: Node2D = room.get_node_or_null("Keeper") as Node2D
	var elaia: Node2D = room.get_node_or_null("Elaia") as Node2D
	var station: Node2D = room.get_node_or_null("Reliquary") as Node2D
	failed += _assert(arch != null and keeper != null and elaia != null and station != null, "y-sort nodes exist")
	if arch == null or keeper == null or elaia == null or station == null:
		_drop_current_scene()
		return failed
	var station_sprite: CanvasItem = station.get_node_or_null("Sprite") as CanvasItem
	var keeper_sprite: CanvasItem = keeper.get_node_or_null("Sprite") as CanvasItem
	var elaia_sprite: CanvasItem = elaia.get_node_or_null("Sprite") as CanvasItem
	failed += _assert(station_sprite != null and keeper_sprite != null and elaia_sprite != null, "station and hero sprites")
	if station_sprite == null or keeper_sprite == null or elaia_sprite == null:
		_drop_current_scene()
		return failed
	var feet_y: float = station.global_position.y
	keeper.global_position = Vector2(station.global_position.x, feet_y + 48.0)
	elaia.global_position = Vector2(station.global_position.x + 36.0, feet_y + 48.0)
	await process_frame
	failed += _assert(_draws_over(keeper_sprite, station_sprite), "keeper south of the Reliquary draws over it")
	failed += _assert(_draws_over(elaia_sprite, station_sprite), "elaia south of the Reliquary draws over it")
	failed += _assert(_draws_over(arch, keeper_sprite), "arch still draws over a hero who is south of the arch node")
	keeper.global_position = Vector2(station.global_position.x, feet_y - 48.0)
	elaia.global_position = Vector2(station.global_position.x + 36.0, feet_y - 48.0)
	await process_frame
	failed += _assert(_draws_over(station_sprite, keeper_sprite), "keeper north of the Reliquary draws under it")
	failed += _assert(_draws_over(station_sprite, elaia_sprite), "elaia north of the Reliquary draws under it")
	for station_node: Node in room.get_children():
		if not station_node.is_in_group("forge_station"):
			continue
		failed += _assert_station_walk_width(station_node)
	_drop_current_scene()
	if failed == 0:
		print("FORGE_YSORT_OK")
	return failed


func _assert_station_walk_width(station_node: Node) -> int:
	var failed: int = 0
	var sprite: Sprite2D = station_node.get_node_or_null("Sprite") as Sprite2D
	var shape_node: CollisionShape2D = station_node.get_node_or_null("WalkBody/CollisionShape2D") as CollisionShape2D
	var pick: CollisionShape2D = station_node.get_node_or_null("CollisionShape2D") as CollisionShape2D
	failed += _assert(sprite != null and sprite.texture != null and shape_node != null, "%s walk box exists" % station_node.name)
	if sprite == null or sprite.texture == null or shape_node == null or not (shape_node.shape is RectangleShape2D):
		return failed + 1
	var rect: RectangleShape2D = shape_node.shape as RectangleShape2D
	var shown_w: float = float(sprite.texture.get_width()) * absf(sprite.scale.x)
	var shown_h: float = float(sprite.texture.get_height()) * absf(sprite.scale.y)
	var img: Image = sprite.texture.get_image()
	var opaque_w: float = shown_w
	if img != null:
		if img.is_compressed():
			img.decompress()
		var used: Rect2i = img.get_used_rect()
		if used.size.x >= 4:
			opaque_w = float(used.size.x) * absf(sprite.scale.x)
	failed += _assert(absf(rect.size.x - opaque_w) <= 1.5, "%s walk width is the opaque span (got %.1f want %.1f)" % [station_node.name, rect.size.x, opaque_w])
	failed += _assert(rect.size.x < shown_w - 8.0, "%s walk width is narrower than the PNG canvas" % station_node.name)
	var want_h: float = maxf(8.0, shown_h / 3.0)
	failed += _assert(absf(rect.size.y - want_h) <= 1.5, "%s walk height stays a third of the canvas" % station_node.name)
	var bottom: float = shape_node.position.y + rect.size.y * 0.5
	failed += _assert(absf(bottom) <= 1.5, "%s walk box still sits on the station feet" % station_node.name)
	if pick != null and pick.shape is RectangleShape2D:
		var pick_rect: RectangleShape2D = pick.shape as RectangleShape2D
		failed += _assert(absf(pick_rect.size.x - rect.size.x) > 1.0 or absf(pick_rect.size.y - rect.size.y) > 1.0, "%s pick shape stays separate from the walk box" % station_node.name)
	return failed


func _manatree_door_clear(tree_root: Window, game_state: Node, save_service: Node) -> int:
	var failed: int = 0
	var jobs: Node = tree_root.get_node_or_null("ForgeJobs")
	failed += _assert(jobs != null, "ForgeJobs for the manatree door")
	if jobs == null:
		return failed
	game_state.call("reset_for_new_game")
	save_service.call("note_session_ended")
	save_service.set("boot_intent", "new")
	jobs.call("set_scene_changes_enabled", true)
	paused = false
	change_scene_to_file(_HUB_SCENE)
	var stable: String = await _await_stable_scene()
	failed += _assert(stable == _HUB_SCENE, "manatree door check starts in the clearing")
	var live: Node = current_scene
	if live == null:
		return failed + 1
	var tree: Node2D = live.get_node_or_null("World/Manatree") as Node2D
	failed += _assert(tree != null, "manatree exists")
	if tree == null:
		_drop_current_scene()
		return failed
	var keeper_cls = load("res://scripts/keeper.gd")
	for stage_name: String in ["sapling", "young", "mature", "elder", "ancient"]:
		game_state.set("stage_id", StringName(stage_name))
		game_state.emit_signal("stage_changed", StringName(stage_name))
		await process_frame
		var trunk: Node = tree.get_node_or_null("Trunk")
		failed += _assert(trunk != null, "%s trunk body" % stage_name)
		if trunk == null:
			continue
		var blocked_south: bool = false
		var blocked_side: bool = false
		var cap_hit: bool = false
		for child: Node in trunk.get_children():
			var shape_node: CollisionShape2D = child as CollisionShape2D
			if shape_node == null or not (shape_node.shape is RectangleShape2D):
				continue
			var rect: RectangleShape2D = shape_node.shape as RectangleShape2D
			var south_edge: float = shape_node.position.y + rect.size.y * 0.5
			if south_edge > 0.5:
				blocked_south = true
		failed += _assert(not blocked_south, "%s has no collision south of the sill" % stage_name)
		var probes: Array[Vector2] = [
			Vector2(0, 8), Vector2(0, 36), Vector2(48, 20), Vector2(-48, 20),
			Vector2(36, -24), Vector2(-36, -24), Vector2(0, -20),
		]
		for probe: Vector2 in probes:
			if _trunk_contains(trunk, probe):
				blocked_side = true
		failed += _assert(not blocked_side, "%s corridor to the door is open" % stage_name)
		cap_hit = _trunk_contains(trunk, Vector2(0, -52))
		failed += _assert(cap_hit, "%s trunk still blocks above the doorway" % stage_name)
		var footprint: Rect2 = tree.call("work_footprint")
		for actor_id: String in ["keeper", "elaia"]:
			var solved: Dictionary = keeper_cls.solve_work_spot(footprint, tree.global_position, "manatree", Callable(), "", actor_id)
			var pos: Vector2 = solved.get("position", Vector2.ZERO)
			var hit: bool = _actor_box_hits(live, pos, actor_id)
			failed += _assert(not hit and not bool(solved.get("fallback", false)), "%s watering stays reachable at %s" % [actor_id, stage_name])
	_drop_current_scene()
	save_service.call("note_session_ended")
	game_state.call("reset_for_new_game")
	paused = false
	if failed == 0:
		print("MANATREE_DOOR_CLEAR_OK")
	return failed


func _trunk_contains(trunk: Node, local: Vector2) -> bool:
	for child: Node in trunk.get_children():
		var shape_node: CollisionShape2D = child as CollisionShape2D
		if shape_node == null or not (shape_node.shape is RectangleShape2D):
			continue
		var rect: RectangleShape2D = shape_node.shape as RectangleShape2D
		var half: Vector2 = rect.size * 0.5
		var delta: Vector2 = local - shape_node.position
		if absf(delta.x) <= half.x and absf(delta.y) <= half.y:
			return true
	return false


func _companion_door_transfer(tree_root: Window, game_state: Node, save_service: Node) -> int:
	## Only the hero who uses the door changes scene. The other stays and keeps working.
	var failed: int = _sheet_users(tree_root)
	var jobs: Node = tree_root.get_node_or_null("ForgeJobs")
	failed += _assert(jobs != null, "ForgeJobs for companion transfer")
	if jobs == null:
		return failed
	jobs.call("set_scene_changes_enabled", true)
	jobs.call("set_in_forge_override", -1)
	paused = false
	failed += await _boot_play(game_state, save_service, true)
	if failed > 0:
		return failed
	for trip_i: int in 2:
		var tag: String = "trip %d" % (trip_i + 1)
		failed += await _party_ready_in_clearing(game_state, tag)
		if failed > 0:
			return failed
		var elaia_before: Vector2 = game_state.get("elaia_pos") as Vector2
		jobs.call("set_elaia_task", "harvest", "wood", true)
		var hopped: String = str(jobs.call("try_door_entry", "keeper"))
		failed += _assert(hopped == "entered", "%s door entry (got %s)" % [tag, hopped])
		failed += await _expect_scene("%s forge" % tag, _FORGE_SCENE)
		failed += await _hold_scene("%s stays in the forge" % tag, _FORGE_SCENE)
		var forge_spot: Vector2 = jobs.call("forge_arch_spawn")
		var keeper_body: Node2D = get_first_node_in_group("keeper") as Node2D
		var elaia_body: Node2D = get_first_node_in_group("elaia") as Node2D
		failed += _assert(str(game_state.get("keeper_area")) == "forge", "%s keeper entered" % tag)
		failed += _assert(str(game_state.get("elaia_area")) == "clearing", "%s elaia stays in the clearing" % tag)
		failed += _assert(keeper_body != null and keeper_body.visible and keeper_body.global_position.distance_to(forge_spot) <= 24.0, "%s keeper is at the forge door" % tag)
		failed += _assert(elaia_body != null and not elaia_body.visible, "%s elaia is not shown in the forge" % tag)
		var stayed: Dictionary = jobs.call("elaia_task")
		failed += _assert(bool(stayed.get("working", false)) and str(stayed.get("target", "")) == "wood", "%s elaia keeps her job" % tag)
		var elaia_pos_now: Vector2 = game_state.get("elaia_pos") as Vector2
		failed += _assert(elaia_pos_now.distance_to(elaia_before) <= 1.0, "%s elaia was not moved" % tag)
		if failed > 0:
			return failed
		var room: Node = current_scene
		var leader: Node2D = null
		if room != null:
			leader = room.get_node_or_null("Keeper") as Node2D
		if room == null or leader == null or not room.has_method("_on_exit_body"):
			failed += _assert(false, "%s forge exit missing" % tag)
			return failed
		room.call("_on_exit_body", leader)
		failed += await _expect_scene("%s clearing" % tag, _HUB_SCENE)
		failed += await _hold_scene("%s stays in the clearing" % tag, _HUB_SCENE)
		var stand: Vector2 = jobs.call("clearing_door_stand")
		keeper_body = get_first_node_in_group("keeper") as Node2D
		elaia_body = get_first_node_in_group("elaia") as Node2D
		failed += _assert(str(game_state.get("keeper_area")) == "clearing" and str(game_state.get("elaia_area")) == "clearing", "%s both session areas are the clearing" % tag)
		failed += _assert(keeper_body != null and keeper_body.visible and keeper_body.global_position.distance_to(stand) <= 24.0, "%s keeper is back at the door" % tag)
		failed += _assert(elaia_body != null and elaia_body.visible, "%s elaia is still in the clearing" % tag)
		elaia_pos_now = game_state.get("elaia_pos") as Vector2
		failed += _assert(elaia_pos_now.distance_to(stand + Vector2(72, 0)) > 48.0, "%s elaia did not follow the keeper out" % tag)
		stayed = jobs.call("elaia_task")
		failed += _assert(bool(stayed.get("working", false)) and str(stayed.get("target", "")) == "wood", "%s elaia is still on her job" % tag)
		if failed > 0:
			return failed
	_drop_current_scene()
	save_service.call("note_session_ended")
	game_state.call("reset_for_new_game")
	jobs.call("set_in_forge_override", -1)
	paused = false
	if failed == 0:
		print("COMPANION_DOOR_TRANSFER_OK")
	return failed


func _sheet_users(tree_root: Window) -> int:
	var failed: int = 0
	var gear: Node = tree_root.get_node_or_null("Equipment")
	failed += _assert(gear != null, "Equipment for the character sheet")
	if gear == null:
		return failed
	gear.call("reset_for_new_game")
	failed += _assert(bool(gear.call("add_gear", "stone_sword", 1)), "bag sword")
	failed += _assert(bool(gear.call("add_gear", "sapstaff", 1)), "bag staff")
	failed += _assert(bool(gear.call("add_gear", "thornbow", 1)), "bag bow")
	var keeper_ids: PackedStringArray = _sheet_ids(gear, "keeper")
	var elaia_ids: PackedStringArray = _sheet_ids(gear, "elaia")
	failed += _assert(keeper_ids.has("stone_sword") and keeper_ids.has("thornbow"), "keeper sheet lists his weapons")
	failed += _assert(not keeper_ids.has("sapstaff"), "keeper sheet hides Elaia's staff")
	failed += _assert(elaia_ids.has("sapstaff") and elaia_ids.has("thornbow"), "elaia sheet lists her weapons")
	failed += _assert(not elaia_ids.has("stone_sword"), "elaia sheet hides the Keeper's sword")
	failed += _assert(str(gear.call("try_equip", "sapstaff", "keeper")) == "wrong_user", "equipping the staff on the keeper is refused")
	gear.call("reset_for_new_game")
	return failed


func _sheet_ids(gear: Node, actor: String) -> PackedStringArray:
	var ids := PackedStringArray()
	var rows: Array = gear.call("list_for_sheet", actor)
	for row: Variant in rows:
		if typeof(row) == TYPE_DICTIONARY:
			ids.append(str((row as Dictionary).get("id", "")))
	return ids


func _party_ready_in_clearing(game_state: Node, tag: String) -> int:
	var failed: int = 0
	if _scene_path() != _HUB_SCENE:
		failed += await _expect_scene(tag + " hub", _HUB_SCENE)
	var live: Node = current_scene
	var tree: Node2D = null
	var keeper: Node = null
	var elaia: Node = null
	if live != null:
		tree = live.get_node_or_null("World/Manatree") as Node2D
		keeper = live.get_node_or_null("World/Keeper")
		elaia = live.get_node_or_null("World/Elaia")
	failed += _assert(tree != null and keeper != null and elaia != null, "%s clearing bodies" % tag)
	if tree == null or keeper == null or elaia == null:
		return failed
	var origin: Vector2 = tree.global_position
	_place_actor(game_state, "keeper", "clearing", origin + Vector2(-16, 90))
	_place_actor(game_state, "elaia", "clearing", origin + Vector2(56, 96))
	if keeper.has_method("apply_keeper_presence"):
		keeper.call("apply_keeper_presence")
	if elaia.has_method("_apply_presence"):
		elaia.call("_apply_presence")
	await process_frame
	failed += _assert((keeper as CanvasItem).visible and (elaia as CanvasItem).visible, "%s both visible before the door" % tag)
	return failed


func _party_present(game_state: Node, area: String, keeper_spot: Vector2, elaia_spot: Vector2) -> int:
	var failed: int = 0
	var keeper: Node2D = get_first_node_in_group("keeper") as Node2D
	var elaia: Node2D = get_first_node_in_group("elaia") as Node2D
	if elaia == null and current_scene != null:
		elaia = current_scene.find_child("Elaia", true, false) as Node2D
	failed += _assert(keeper != null and elaia != null, "%s bodies exist" % area)
	if keeper == null or elaia == null:
		return failed
	failed += _assert(str(game_state.get("keeper_area")) == area and str(game_state.get("elaia_area")) == area, "%s session areas" % area)
	failed += _assert(keeper.visible and elaia.visible, "%s both visible" % area)
	failed += _assert(keeper.is_physics_processing() and elaia.is_physics_processing(), "%s both simulate" % area)
	failed += _assert(keeper.global_position.distance_to(keeper_spot) <= 24.0, "%s keeper beside the door (off %.1f)" % [area, keeper.global_position.distance_to(keeper_spot)])
	failed += _assert(elaia.global_position.distance_to(elaia_spot) <= 24.0, "%s elaia beside the keeper (off %.1f)" % [area, elaia.global_position.distance_to(elaia_spot)])
	return failed


func _party_can_walk(area: String) -> int:
	var failed: int = 0
	var keeper: Node2D = get_first_node_in_group("keeper") as Node2D
	var elaia: Node2D = get_first_node_in_group("elaia") as Node2D
	if keeper == null or elaia == null:
		return failed + 1
	var step: Vector2 = Vector2(0, -70) if area == "forge" else Vector2(0, 80)
	var keeper_from: Vector2 = keeper.global_position
	var elaia_from: Vector2 = elaia.global_position
	if keeper.has_method("move_to"):
		keeper.call("move_to", keeper_from + step, null)
	if elaia.has_method("move_to"):
		elaia.call("move_to", elaia_from + step, null)
	for _step_i: int in 25:
		await physics_frame
	failed += _assert(keeper.global_position.distance_to(keeper_from) > 8.0, "%s keeper can walk" % area)
	failed += _assert(elaia.global_position.distance_to(elaia_from) > 8.0, "%s elaia can walk" % area)
	return failed


func _hold_scene(label: String, expect: String) -> int:
	for _hold_i: int in 10:
		await process_frame
		await physics_frame
		if _scene_path() != expect:
			printerr("ASSERT FAIL: %s bounced to %s" % [label, _scene_path()])
			return 1
	return 0


func _effective_z(item: CanvasItem) -> int:
	var z: int = item.z_index
	if not item.z_as_relative:
		return z
	var parent: Node = item.get_parent()
	while parent is CanvasItem:
		var canvas: CanvasItem = parent as CanvasItem
		z += canvas.z_index
		if not canvas.z_as_relative:
			break
		parent = parent.get_parent()
	return z


func _canvas_layer_above(node: Node) -> Node:
	var parent: Node = node.get_parent()
	while parent != null:
		if parent is CanvasLayer:
			return parent
		parent = parent.get_parent()
	return null


func _draws_over(front: CanvasItem, back: CanvasItem) -> bool:
	var front_z: int = _effective_z(front)
	var back_z: int = _effective_z(back)
	if front_z != back_z:
		return front_z > back_z
	var front_body: Node2D = front as Node2D
	var back_body: Node2D = back as Node2D
	if front_body != null and back_body != null and _under_ysort(front_body) and _under_ysort(back_body):
		if absf(front_body.global_position.y - back_body.global_position.y) > 0.5:
			return front_body.global_position.y > back_body.global_position.y
	return front.get_index() > back.get_index()


func _under_ysort(node: Node) -> bool:
	var parent: Node = node.get_parent()
	while parent != null:
		if parent is CanvasItem and (parent as CanvasItem).y_sort_enabled:
			return true
		parent = parent.get_parent()
	return false


func _arch_body_overlap(arch: Sprite2D, feet: Vector2) -> int:
	if arch.texture == null:
		return 0
	var arch_img: Image = arch.texture.get_image()
	var still: Texture2D = load("res://assets/art/keeper/stills/keeper_still_south_frame0.png") as Texture2D
	if arch_img == null or still == null:
		return 0
	var body: Image = still.get_image()
	if body == null:
		return 0
	if arch_img.is_compressed():
		arch_img.decompress()
	if body.is_compressed():
		body.decompress()
	var arch_size: Vector2 = arch.texture.get_size()
	var arch_origin: Vector2 = arch.global_position - arch_size * 0.5
	if not arch.centered:
		arch_origin = arch.global_position + arch.offset
	var body_origin: Vector2 = feet + Vector2(-64, -128)
	var hits: int = 0
	var step: int = 2
	for py: int in range(0, body.get_height(), step):
		for px: int in range(0, body.get_width(), step):
			if body.get_pixel(px, py).a < 0.2:
				continue
			var world: Vector2 = body_origin + Vector2(px, py)
			var tex: Vector2 = world - arch_origin
			var tx: int = int(tex.x)
			var ty: int = int(tex.y)
			if tx < 0 or ty < 0 or tx >= arch_img.get_width() or ty >= arch_img.get_height():
				continue
			if arch_img.get_pixel(tx, ty).a > 0.2:
				hits += 1
	return hits


func _arch_fill_and_floor(arch: Sprite2D) -> int:
	## The mouth is opaque black. Floor that used to sit above the arch is gone.
	var failed: int = 0
	if arch.texture == null:
		return _assert(false, "arch texture for the fill check")
	var img: Image = arch.texture.get_image()
	if img == null:
		return _assert(false, "arch image")
	if img.is_compressed():
		img.decompress()
	var mouth: Color = img.get_pixel(800, 1050)
	var side_l: Color = img.get_pixel(760, 1080)
	var side_r: Color = img.get_pixel(840, 1080)
	var floor_px: Color = img.get_pixel(800, 964)
	var lip: Color = img.get_pixel(800, 1172)
	failed += _assert(mouth.a > 0.9 and mouth.r < 0.08 and mouth.g < 0.08 and mouth.b < 0.08, "arch mouth is opaque black")
	failed += _assert(side_l.a > 0.9 and side_l.r < 0.08 and side_r.a > 0.9 and side_r.r < 0.08, "arch mouth stays black toward the jambs")
	failed += _assert(floor_px.a < 0.05, "floor above the arch is not painted into the foreground")
	failed += _assert(lip.a > 0.9 and lip.r + lip.g + lip.b > 0.05, "arch lip is still the wooden frame")
	return failed


func _forge_entry_one_click(tree_root: Window, game_state: Node, save_service: Node) -> int:
	## One click on the door walks to the sill and enters. A second click must not be required.
	## Also checks the watering stand is clear of the trunk at every growth stage.
	var failed: int = 0
	var jobs: Node = tree_root.get_node_or_null("ForgeJobs")
	failed += _assert(jobs != null, "ForgeJobs for one-click entry")
	if jobs == null:
		return failed
	game_state.call("reset_for_new_game")
	save_service.call("note_session_ended")
	save_service.set("boot_intent", "new")
	jobs.call("set_scene_changes_enabled", true)
	jobs.call("set_in_forge_override", -1)
	paused = false
	change_scene_to_file(_HUB_SCENE)
	var stable: String = await _await_stable_scene()
	failed += _assert(stable == _HUB_SCENE, "entry check starts in the clearing")
	var live: Node = current_scene
	if live == null:
		return failed + 1
	var hud: Node = live.get_node_or_null("HUD")
	if hud != null and hud.has_method("hide_welcome"):
		hud.call("hide_welcome")
	game_state.set("welcome_shown", true)
	var tree: Node2D = live.get_node_or_null("World/Manatree") as Node2D
	var keeper: Node2D = live.get_node_or_null("World/Keeper") as Node2D
	failed += _assert(tree != null and keeper != null, "tree and keeper for the door")
	if tree == null or keeper == null:
		_drop_current_scene()
		return failed
	var keeper_cls = load("res://scripts/keeper.gd")
	for stage_name: String in ["sapling", "young", "mature", "elder", "ancient"]:
		game_state.set("stage_id", StringName(stage_name))
		game_state.emit_signal("stage_changed", StringName(stage_name))
		await process_frame
		var footprint: Rect2 = tree.call("work_footprint")
		for actor_id: String in ["keeper", "elaia"]:
			var solved: Dictionary = keeper_cls.solve_work_spot(footprint, tree.global_position, "manatree", Callable(), "", actor_id)
			var pos: Vector2 = solved.get("position", Vector2.ZERO)
			var blocked: bool = _actor_box_hits(live, pos, actor_id)
			failed += _assert(not blocked and not bool(solved.get("fallback", false)), "%s watering stand is reachable at %s (%s)" % [actor_id, stage_name, pos])
		var door: Vector2 = tree.global_position + Vector2(0, 8)
		failed += _assert(not _actor_box_hits(live, door, "keeper"), "forge sill is walkable at %s" % stage_name)
	game_state.set("stage_id", &"elder")
	game_state.emit_signal("stage_changed", &"elder")
	game_state.set("forge_key", true)
	game_state.set("forge_visited", true)
	game_state.call("select_keeper")
	await process_frame
	var far: Vector2 = tree.global_position + Vector2(0, 240)
	keeper.global_position = far
	game_state.set("keeper_area", "clearing")
	game_state.set("keeper_has_pos", true)
	game_state.set("keeper_pos", far)
	var started: String = str(jobs.call("request_door_walk"))
	failed += _assert(started == "walking", "one click from the south starts the walk (got %s)" % started)
	var entered: bool = false
	for _step: int in 240:
		await physics_frame
		await process_frame
		if _scene_path() == _FORGE_SCENE or str(game_state.get("keeper_area")) == "forge":
			entered = true
			break
	if str(game_state.get("keeper_area")) == "forge" and _scene_path() != _FORGE_SCENE:
		var hopped: String = await _await_stable_scene()
		entered = hopped == _FORGE_SCENE
	failed += _assert(entered and _scene_path() == _FORGE_SCENE, "one door click enters the forge (scene %s area %s)" % [_scene_path(), str(game_state.get("keeper_area"))])
	_drop_current_scene()
	save_service.call("note_session_ended")
	game_state.call("reset_for_new_game")
	jobs.call("set_in_forge_override", -1)
	paused = false
	if failed == 0:
		print("FORGE_ENTRY_ONE_CLICK_OK")
	return failed


func _actor_box_hits(live: Node, pos: Vector2, actor_id: String) -> bool:
	var space: PhysicsDirectSpaceState2D = live.get_world_2d().direct_space_state
	if space == null:
		return true
	var shape := RectangleShape2D.new()
	var box: Vector2 = FeetBox.actor_box(actor_id)
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
	params.exclude = exclude
	return not space.intersect_shape(params, 1).is_empty()


func _batch_string_table() -> Dictionary:
	return {
		"batch_make": "Make",
		"batch_max": "Max",
		"batch_cancel": "Cancel",
		"batch_amount": "Amount",
		"batch_bar_current": "Current",
		"batch_bar_total": "Batch {done}/{total}",
		"batch_tooltip_current": "Current: {percent}% · {time} left",
		"batch_tooltip_total": "Batch {done}/{total}: {percent}% · {time} left",
		"batch_tooltip_paused": "{percent}% · paused, no one is working here",
		"batch_busy": "This station is already working. Cancel the batch to start a new one.",
		"batch_unstaffed": "No one is working here.",
		"batch_done_toast": "{item} ×{count} finished.",
		"batch_away_note": "Batches keep working while you're away, if someone is working the station.",
		"batch_cancel_confirm_title": "Cancel this batch?",
		"batch_cancel_confirm_body": "Finished items stay in your inventory. Half the materials for the rest come back ({refund}).",
		"batch_cancel_confirm_yes": "Cancel batch",
		"batch_cancel_confirm_no": "Keep working",
		"ascend_warning_batches": "Running batches stop on Ascend, and their materials return to the forest.",
	}


func _batch_refund(tree_root: Window, game_state: Node, save_service: Node, backpack: Node, content_strings: Node) -> int:
	var failed: int = 0
	var jobs: Node = tree_root.get_node_or_null("ForgeJobs")
	var equipment: Node = tree_root.get_node_or_null("Equipment")
	failed += _assert(jobs != null and equipment != null and content_strings != null, "batch refund nodes")
	if jobs == null:
		return failed
	jobs.call("set_autosave_enabled", false)
	jobs.call("set_dev_speed_override", 1.0)
	var expected: Dictionary = _batch_string_table()
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/strings_v01.json"))
	failed += _assert(typeof(raw) == TYPE_DICTIONARY, "strings table parses")
	var table: Dictionary = raw if typeof(raw) == TYPE_DICTIONARY else {}
	failed += _assert(expected.size() == 18, "FINAL copy has 18 keys")
	failed += _assert(not table.has("batch_cant_afford"), "no batch_cant_afford key")
	for key: Variant in expected.keys():
		var id: String = str(key)
		failed += _assert(str(table.get(id, "")) == str(expected[id]), "strings_v01 %s matches FINAL" % id)
		failed += _assert(str(content_strings.call("get_text", id)) == str(expected[id]), "ContentStrings %s matches FINAL" % id)
	var batch_script: GDScript = load("res://scripts/batch_job.gd") as GDScript
	failed += _assert(batch_script != null, "batch job script loads")
	if batch_script != null:
		failed += _assert(int(batch_script.call("refund_qty", 1, 1)) == 1, "odd 1 rounds up to 1")
		failed += _assert(int(batch_script.call("refund_qty", 3, 1)) == 2, "odd 3 rounds up to 2")
		failed += _assert(int(batch_script.call("refund_qty", 1, 20)) == 10, "half of 20 is 10")
		failed += _assert(int(batch_script.call("refund_qty", 3, 20)) == 30, "half of 60 rounds up to 30")
	game_state.call("reset_for_new_game")
	backpack.call("reset_for_new_game")
	game_state.call("set_resource", &"stone", 40)
	failed += _assert(int(jobs.call("slider_limit", "sapsteel")) == 2, "slider max is the affordable count")
	failed += _assert(str(jobs.call("try_begin_batch", "crucible", "sapsteel", 3)) == "cant_afford", "a count past affordable is refused")
	game_state.call("set_resource", &"stone", 20 * 1000)
	failed += _assert(int(jobs.call("slider_limit", "sapsteel")) == 999, "slider max hard-caps at 999")
	game_state.call("set_resource", &"stone", 0)
	failed += _assert(int(jobs.call("slider_limit", "sapsteel")) == 0, "nothing affordable keeps the slider at 0")
	var panel_scene: PackedScene = load("res://scenes/ui/batch_panel.tscn") as PackedScene
	var panel: Node = panel_scene.instantiate() if panel_scene != null else null
	failed += _assert(panel != null, "batch panel scene loads")
	if panel != null:
		tree_root.add_child(panel)
		panel.call("setup", "crucible")
		panel.call("bind_recipe", "sapsteel")
		await process_frame
		var slider: HSlider = panel.find_child("Slider", true, false) as HSlider
		var make: Button = panel.find_child("Make", true, false) as Button
		failed += _assert(slider != null and make != null, "panel has a slider and Make")
		if slider != null and make != null:
			failed += _assert(is_equal_approx(slider.max_value, 0.0), "unaffordable slider stays at 0")
			failed += _assert(slider.value <= slider.max_value + 0.001, "slider value never passes its max")
			failed += _assert(make.disabled, "Make is disabled when nothing is affordable")
		game_state.call("set_resource", &"stone", 40)
		panel.call("bind_recipe", "heartwood_bits")
		panel.call("bind_recipe", "sapsteel")
		await process_frame
		if slider != null:
			failed += _assert(is_equal_approx(slider.max_value, 2.0), "panel slider max is 2 when 40 stone buys 2")
			failed += _assert(slider.value <= slider.max_value + 0.001, "panel slider stays within affordable")
		panel.free()
	game_state.call("reset_for_new_game")
	backpack.call("reset_for_new_game")
	game_state.call("set_resource", &"wood", 9)
	failed += _assert(str(jobs.call("try_begin_batch", "workbench", "wooden_planks", 3)) == "ok", "three planks are paid up front")
	failed += _assert(int(game_state.get("wood")) == 0, "plank batch spends 9 wood")
	failed += _assert(str(jobs.call("cancel_batch", "workbench")) == "ok", "cancel returns materials")
	failed += _assert(int(game_state.get("wood")) == 5, "odd plank wood refund rounds up to 5")
	failed += _assert(int(backpack.call("get_count", "wooden_planks")) == 0, "cancel grants no finished planks")
	game_state.call("reset_for_new_game")
	backpack.call("reset_for_new_game")
	game_state.call("set_resource", &"wood", 6)
	jobs.call("try_begin_batch", "workbench", "wooden_planks", 2)
	jobs.call("set_keeper_working", "workbench", true)
	jobs.call("advance_seconds", 6.0)
	failed += _assert(int(backpack.call("get_count", "wooden_planks")) == 1, "the finished plank is already in the inventory")
	var state: Dictionary = jobs.call("job_state", "workbench")
	failed += _assert(int(state.get("done", -1)) == 1 and int(state.get("remaining_count", -1)) == 1, "the in-progress plank is unfinished")
	jobs.call("cancel_batch", "workbench")
	failed += _assert(int(game_state.get("wood")) == 2, "refund uses the unfinished item, not the finished one")
	failed += _assert(int(backpack.call("get_count", "wooden_planks")) == 1, "cancel keeps the finished plank")
	game_state.call("reset_for_new_game")
	backpack.call("reset_for_new_game")
	game_state.call("set_resource", &"wood", 10)
	game_state.call("set_resource", &"stone", 10)
	game_state.call("set_resource", &"food", 10)
	failed += _assert(str(jobs.call("try_begin_batch", "workbench", "fertilizer", 1)) == "ok", "fertilizer batch starts")
	jobs.call("advance_seconds", 1.0)
	jobs.call("cancel_batch", "workbench")
	failed += _assert(int(game_state.get("wood")) == 5 and int(game_state.get("stone")) == 5 and int(game_state.get("food")) == 5, "refund is per material")
	var refund_line: String = str(jobs.call("refund_text", "workbench"))
	failed += _assert(refund_line == "", "a cleared batch has no refund left")
	game_state.call("set_resource", &"wood", 10)
	game_state.call("set_resource", &"stone", 10)
	game_state.call("set_resource", &"food", 10)
	jobs.call("try_begin_batch", "workbench", "fertilizer", 1)
	var live_refund: String = str(jobs.call("refund_text", "workbench"))
	failed += _assert(live_refund.find("5") >= 0 and live_refund.find(",") >= 0, "refund text lists each material (%s)" % live_refund)
	jobs.call("cancel_batch", "workbench")
	game_state.call("reset_for_new_game")
	backpack.call("reset_for_new_game")
	save_service.call("delete_save")
	return failed


func _batch_offline(tree_root: Window, game_state: Node, save_service: Node, backpack: Node, content_strings: Node) -> int:
	var failed: int = 0
	var jobs: Node = tree_root.get_node_or_null("ForgeJobs")
	failed += _assert(jobs != null and content_strings != null, "batch offline nodes")
	if jobs == null:
		return failed
	jobs.call("set_autosave_enabled", false)
	jobs.call("set_dev_speed_override", 1.0)
	failed += _assert(str(jobs.call("format_duration_words", 5.0)) == "0m 05s", "short waits still show minutes")
	failed += _assert(str(jobs.call("format_duration_words", 125.0)) == "2m 05s", "minutes plus zero-padded seconds")
	failed += _assert(str(jobs.call("format_duration_words", 3725.0)) == "1h 02m 05s", "hours join the clock")
	game_state.call("reset_for_new_game")
	backpack.call("reset_for_new_game")
	game_state.call("set_resource", &"stone", 20)
	jobs.call("try_begin_job", "crucible", "sapsteel")
	jobs.call("set_keeper_working", "crucible", true)
	jobs.call("advance_seconds", 17.0)
	var before: float = float(jobs.call("job_progress", "crucible"))
	var zero: Dictionary = jobs.call("apply_offline_seconds", 0.0)
	failed += _assert(int(zero.get("forge_completed", -1)) == 0, "zero seconds completes nothing")
	failed += _assert(absf(float(jobs.call("job_progress", "crucible")) - before) < 0.01, "zero seconds leaves the item where it was")
	failed += _assert(bool((jobs.call("keeper_task") as Dictionary).get("working", false)), "zero seconds does not clear the worker")
	game_state.call("reset_for_new_game")
	backpack.call("reset_for_new_game")
	game_state.call("set_resource", &"stone", 20)
	jobs.call("try_begin_job", "crucible", "sapsteel")
	jobs.call("set_keeper_working", "crucible", true)
	var one: Dictionary = jobs.call("apply_offline_seconds", 60.0)
	failed += _assert(int(one.get("forge_completed", -1)) == 1, "exactly one item finishes")
	failed += _assert(int(backpack.call("get_count", "sapsteel")) == 1, "the finished item is granted")
	failed += _assert(not bool(jobs.call("has_job", "crucible")), "an exact finish clears the batch")
	game_state.call("reset_for_new_game")
	backpack.call("reset_for_new_game")
	game_state.call("set_resource", &"stone", 40)
	jobs.call("try_begin_batch", "crucible", "sapsteel", 2)
	jobs.call("set_keeper_working", "crucible", true)
	var mid: Dictionary = jobs.call("apply_offline_seconds", 90.0)
	var mid_state: Dictionary = jobs.call("job_state", "crucible")
	failed += _assert(int(mid.get("forge_completed", -1)) == 1, "ninety seconds finishes the first item")
	failed += _assert(int(mid_state.get("done", -1)) == 1 and int(mid_state.get("total", -1)) == 2, "the batch still has its second item")
	failed += _assert(absf(float(mid_state.get("progress", -1.0)) - 30.0) < 0.05, "the second item is 30 seconds in")
	failed += _assert(int(backpack.call("get_count", "sapsteel")) == 1, "only the finished item was granted")
	game_state.call("reset_for_new_game")
	backpack.call("reset_for_new_game")
	game_state.call("set_resource", &"stone", 100)
	jobs.call("try_begin_batch", "crucible", "sapsteel", 5)
	jobs.call("set_keeper_working", "crucible", true)
	var month: float = 30.0 * 86400.0
	var long_gap: Dictionary = jobs.call("apply_offline_seconds", month)
	failed += _assert(int(long_gap.get("forge_completed", -1)) == 5, "a 30 day absence clamps to the remaining count")
	failed += _assert(int(backpack.call("get_count", "sapsteel")) == 5, "the clamp grants only the batch")
	failed += _assert(not bool(jobs.call("has_job", "crucible")), "the clamped batch is finished")
	game_state.call("reset_for_new_game")
	backpack.call("reset_for_new_game")
	game_state.call("set_resource", &"stone", 20)
	jobs.call("try_begin_job", "crucible", "sapsteel")
	jobs.call("set_keeper_working", "crucible", true)
	jobs.call("advance_seconds", 10.0)
	var ancient_before: float = float(jobs.call("job_progress", "crucible"))
	game_state.call("_set_stage", &"ancient")
	game_state.set("ancient_remaining_sec", 400.0)
	var frozen: Dictionary = jobs.call("apply_offline_seconds", 3600.0)
	failed += _assert(int(frozen.get("forge_completed", -1)) == 0, "ancient offline finishes nothing")
	failed += _assert(absf(float(jobs.call("job_progress", "crucible")) - ancient_before) < 0.01, "ancient offline freezes the batch")
	game_state.set("ancient_frozen", false)
	game_state.set("fruit_committed", false)
	jobs.call("set_keeper_working", "crucible", true)
	jobs.call("advance_seconds", 8.0)
	failed += _assert(float(jobs.call("job_progress", "crucible")) > ancient_before + 7.0, "an open Ancient still runs the batch")
	game_state.set("fruit_committed", true)
	var committed_at: float = float(jobs.call("job_progress", "crucible"))
	jobs.call("advance_seconds", 20.0)
	failed += _assert(absf(float(jobs.call("job_progress", "crucible")) - committed_at) < 0.01, "a committed Fruit sets station speed to 0")
	game_state.call("reset_for_new_game")
	backpack.call("reset_for_new_game")
	game_state.call("set_resource", &"stone", 20)
	jobs.call("try_begin_job", "crucible", "sapsteel")
	jobs.call("note_keeper_idle")
	var idle_gap: Dictionary = jobs.call("apply_offline_seconds", 3600.0)
	failed += _assert(int(idle_gap.get("forge_completed", -1)) == 0, "an unstaffed batch finishes nothing offline")
	failed += _assert(absf(float(jobs.call("job_progress", "crucible"))) < 0.01, "an unstaffed batch does not move")
	failed += _assert(int(backpack.call("get_count", "sapsteel")) == 0, "unstaffed offline grants nothing")
	var paused_tip: String = str(jobs.call("bar_tooltip", "crucible", "current"))
	failed += _assert(paused_tip.find("paused") >= 0, "the paused tooltip names the unstaffed state")
	var panel_scene: PackedScene = load("res://scenes/ui/batch_panel.tscn") as PackedScene
	var panel: Node = panel_scene.instantiate() if panel_scene != null else null
	if panel != null:
		tree_root.add_child(panel)
		panel.call("setup", "crucible")
		await process_frame
		var status: Label = panel.find_child("Status", true, false) as Label
		var want: String = str(content_strings.call("get_text", "batch_unstaffed"))
		failed += _assert(status != null and str(status.text) == want, "the panel shows the unstaffed line")
		jobs.call("advance_seconds", 30.0)
		failed += _assert(absf(float(jobs.call("job_progress", "crucible"))) < 0.01, "the unstaffed panel's bars do not move")
		panel.free()
	game_state.call("reset_for_new_game")
	backpack.call("reset_for_new_game")
	save_service.call("delete_save")
	return failed


func _batch_ascend_wipe(tree_root: Window, game_state: Node, save_service: Node, backpack: Node, content_strings: Node) -> int:
	var failed: int = 0
	var jobs: Node = tree_root.get_node_or_null("ForgeJobs")
	failed += _assert(jobs != null and content_strings != null, "batch ascend nodes")
	if jobs == null:
		return failed
	jobs.call("set_autosave_enabled", false)
	jobs.call("set_dev_speed_override", 1.0)
	game_state.call("reset_for_new_game")
	backpack.call("reset_for_new_game")
	game_state.call("set_resource", &"stone", 60)
	failed += _assert(str(jobs.call("try_begin_batch", "crucible", "sapsteel", 3)) == "ok", "ascend sample batch starts")
	failed += _assert(int(game_state.get("stone")) == 0, "the sample batch was paid")
	var warning: String = str(content_strings.call("get_text", "ascend_warning_batches"))
	var confirm: String = str(jobs.call("ascend_confirm_text"))
	failed += _assert(confirm.find(warning) >= 0, "the confirm includes the batch warning")
	failed += _assert(confirm.find("Sapsteel") >= 0 and confirm.find("3") >= 0, "the confirm lists the item and the remaining count")
	game_state.set("fruit_committed", true)
	game_state.set("fruit_harvested_pending_ascend", true)
	var hud_scene: PackedScene = load("res://scenes/hud.tscn") as PackedScene
	var hud: Node = hud_scene.instantiate() if hud_scene != null else null
	failed += _assert(hud != null, "ascend dialog hud loads")
	if hud != null:
		tree_root.add_child(hud)
		await process_frame
		hud.call("show_ascension_shop")
		hud.call("_on_ascend")
		await process_frame
		var dialog: Node = hud.find_child("AscendBatchDialog", true, false)
		var body: Label = dialog.find_child("Body", true, false) as Label if dialog != null else null
		failed += _assert(dialog != null and dialog.visible, "ascend confirm dialog is visible")
		failed += _assert(body != null and str(body.text).find(warning) >= 0, "dialog shows the batch warning")
		failed += _assert(body != null and str(body.text).find("Sapsteel") >= 0 and str(body.text).find("3") >= 0, "dialog lists the running batch")
		hud.free()
	var stone_paid: int = int(game_state.get("stone"))
	jobs.call("prepare_ascend")
	failed += _assert(not bool(jobs.call("has_job", "crucible")), "ascend wipes the batch")
	failed += _assert(int(game_state.get("stone")) == stone_paid, "ascend does not refund the batch")
	failed += _assert(int(backpack.call("get_count", "sapsteel")) == 0, "a wiped batch grants nothing")
	game_state.call("reset_for_new_game")
	backpack.call("reset_for_new_game")
	game_state.call("set_resource", &"stone", 20)
	jobs.call("try_begin_job", "crucible", "sapsteel")
	jobs.call("set_keeper_working", "crucible", true)
	jobs.call("advance_seconds", 12.0)
	var kept: float = float(jobs.call("job_progress", "crucible"))
	(game_state.get("upgrade_ranks") as Dictionary)["keep_forge_jobs"] = 1
	failed += _assert(str(jobs.call("ascend_confirm_text")) == "", "Keep Forge Jobs does not list batches it will hold")
	jobs.call("prepare_ascend")
	failed += _assert(bool(jobs.call("has_job", "crucible")), "Keep Forge Jobs keeps the batch")
	failed += _assert(absf(float(jobs.call("job_progress", "crucible")) - kept) < 0.05, "Keep Forge Jobs keeps the progress")
	failed += _assert(int(game_state.get("stone")) == 0, "keeping the job still does not refund it")
	game_state.call("reset_for_new_game")
	backpack.call("reset_for_new_game")
	save_service.call("delete_save")
	return failed


func _batch_migration(tree_root: Window, game_state: Node, save_service: Node, backpack: Node) -> int:
	var failed: int = 0
	var jobs: Node = tree_root.get_node_or_null("ForgeJobs")
	failed += _assert(jobs != null and backpack != null, "batch migration nodes")
	if jobs == null:
		return failed
	jobs.call("set_autosave_enabled", false)
	jobs.call("set_dev_speed_override", 1.0)
	game_state.call("reset_for_new_game")
	var fixture: String = FileAccess.get_file_as_string("res://tests/fixtures/batch_migration_6efbcab.json")
	var parsed: Variant = JSON.parse_string(fixture)
	failed += _assert(typeof(parsed) == TYPE_DICTIONARY, "6efbcab fixture parses")
	if typeof(parsed) != TYPE_DICTIONARY:
		return failed
	var root: Dictionary = parsed
	root["timestamp"] = Time.get_unix_time_from_system()
	var path: String = str(save_service.call("slot_path", 1))
	var file := FileAccess.open(path, FileAccess.WRITE)
	failed += _assert(file != null, "fixture slot writes")
	if file == null:
		return failed
	file.store_string(JSON.stringify(root))
	file.close()
	failed += _assert(bool(save_service.call("load_game", 1)), "6efbcab fixture loads")
	var state: Dictionary = jobs.call("job_state", "crucible")
	failed += _assert(str(state.get("recipe_id", "")) == "sapsteel", "migrated job is still sapsteel")
	failed += _assert(int(state.get("total", -1)) == 1 and int(state.get("done", -1)) == 0, "a Keep-going job becomes a batch of 1")
	failed += _assert(absf(float(state.get("progress", -1.0)) - 17.0) < 0.05, "migration keeps the 17 seconds already worked")
	failed += _assert(int(game_state.get("stone")) == 20, "migration does not spend the stone again")
	failed += _assert(int(backpack.call("get_count", "sapsteel")) == 0, "the in-progress item is not granted on load")
	var task: Dictionary = jobs.call("keeper_task")
	failed += _assert(bool(task.get("working", false)) and str(task.get("target", "")) == "crucible", "the loaded keeper is still on the Crucible")
	save_service.call("delete_save")
	game_state.call("reset_for_new_game")
	return failed


func _door_transfer_active_only(tree_root: Window, game_state: Node, save_service: Node) -> int:
	## Either hero can use the door. The one who did not stays in their scene and keeps their job.
	var failed: int = 0
	var jobs: Node = tree_root.get_node_or_null("ForgeJobs")
	failed += _assert(jobs != null, "ForgeJobs for active-only transfer")
	if jobs == null:
		return failed
	jobs.call("set_scene_changes_enabled", true)
	jobs.call("set_in_forge_override", -1)
	paused = false
	failed += await _boot_play(game_state, save_service, true)
	if failed > 0:
		return failed
	failed += await _party_ready_in_clearing(game_state, "active door")
	jobs.call("set_keeper_working", "workbench", true)
	var keeper_pos: Vector2 = game_state.get("keeper_pos") as Vector2
	var entered: String = str(jobs.call("try_door_entry", "elaia"))
	failed += _assert(entered == "entered", "elaia door entry (got %s)" % entered)
	failed += await _expect_scene("elaia forge", _FORGE_SCENE)
	failed += _assert(str(game_state.get("elaia_area")) == "forge", "elaia entered the forge")
	failed += _assert(str(game_state.get("keeper_area")) == "clearing", "keeper stays in the clearing")
	var keeper_now: Vector2 = game_state.get("keeper_pos") as Vector2
	failed += _assert(keeper_now.distance_to(keeper_pos) <= 1.0, "keeper was not pulled through the door")
	var keeper_task: Dictionary = jobs.call("keeper_task")
	failed += _assert(bool(keeper_task.get("working", false)) and str(keeper_task.get("target", "")) == "workbench", "keeper keeps the workbench")
	var forge_keeper: CanvasItem = get_first_node_in_group("keeper") as CanvasItem
	var forge_elaia: CanvasItem = get_first_node_in_group("elaia") as CanvasItem
	failed += _assert(forge_elaia != null and forge_elaia.visible, "elaia is shown in the forge")
	failed += _assert(forge_keeper != null and not forge_keeper.visible, "keeper is not shown in the forge")
	_place_actor(game_state, "keeper", "forge", Vector2(900, 860))
	_place_actor(game_state, "elaia", "forge", Vector2(660, 524))
	if forge_keeper != null and forge_keeper.has_method("apply_keeper_presence"):
		forge_keeper.call("apply_keeper_presence")
	if forge_elaia != null and forge_elaia.has_method("_apply_presence"):
		forge_elaia.call("_apply_presence")
	jobs.call("set_elaia_working", "mill", true)
	var elaia_pos: Vector2 = game_state.get("elaia_pos") as Vector2
	jobs.call("commit_actor_exit", "keeper")
	failed += await _expect_scene("keeper clearing", _HUB_SCENE)
	failed += _assert(str(game_state.get("keeper_area")) == "clearing", "keeper left the forge")
	failed += _assert(str(game_state.get("elaia_area")) == "forge", "elaia stays in the forge")
	var elaia_now: Vector2 = game_state.get("elaia_pos") as Vector2
	failed += _assert(elaia_now.distance_to(elaia_pos) <= 1.0, "elaia was not pulled out of the forge")
	var elaia_task: Dictionary = jobs.call("elaia_task")
	failed += _assert(bool(elaia_task.get("working", false)) and str(elaia_task.get("target", "")) == "mill", "elaia keeps the mill")
	var hub_keeper: CanvasItem = get_first_node_in_group("keeper") as CanvasItem
	var hub_elaia: CanvasItem = get_first_node_in_group("elaia") as CanvasItem
	failed += _assert(hub_keeper != null and hub_keeper.visible, "keeper is shown in the clearing")
	failed += _assert(hub_elaia != null and not hub_elaia.visible, "elaia is not shown in the clearing")
	_drop_current_scene()
	save_service.call("note_session_ended")
	game_state.call("reset_for_new_game")
	jobs.call("reset_for_new_game")
	jobs.call("set_in_forge_override", -1)
	paused = false
	if failed == 0:
		print("DOOR_TRANSFER_ACTIVE_ONLY_OK")
	return failed


func _workbench_click_panel(tree_root: Window) -> int:
	var failed: int = 0
	var bench_scene: PackedScene = load("res://scenes/keepers_bench.tscn") as PackedScene
	var hud_scene: PackedScene = load("res://scenes/hud.tscn") as PackedScene
	failed += _assert(bench_scene != null and hud_scene != null, "bench click scenes")
	if bench_scene == null or hud_scene == null:
		return failed
	var bench: Node = bench_scene.instantiate()
	var hud: Node = hud_scene.instantiate()
	tree_root.add_child(bench)
	tree_root.add_child(hud)
	await process_frame
	paused = false
	bench.call("_on_left_click")
	await process_frame
	failed += _assert(bool(hud.call("is_bench_open")), "left click opens the workbench batch panel")
	failed += _assert(not paused, "clicking the workbench does not pause")
	var panel: Node = hud.get_node_or_null("BenchPanel/BatchPanel")
	failed += _assert(panel != null and str(panel.call("spot_id")) == "workbench", "the opened panel is the workbench batch")
	hud.call("close_bench")
	bench.free()
	hud.free()
	paused = false
	if failed == 0:
		print("WORKBENCH_CLICK_PANEL_OK")
	return failed


func _workbench_panel_no_pause(tree_root: Window, game_state: Node) -> int:
	var failed: int = 0
	var hud_scene: PackedScene = load("res://scenes/hud.tscn") as PackedScene
	failed += _assert(hud_scene != null, "hud for the pause check")
	if hud_scene == null:
		return failed
	var hud: Node = hud_scene.instantiate()
	tree_root.add_child(hud)
	await process_frame
	paused = false
	var before: float = float(game_state.get("run_time_sec"))
	hud.call("open_bench_panel")
	await process_frame
	failed += _assert(bool(hud.call("is_bench_open")), "workbench panel is open")
	failed += _assert(not paused, "the workbench panel leaves the tree running")
	for _tick: int in 6:
		await process_frame
	var after: float = float(game_state.get("run_time_sec"))
	failed += _assert(after > before + 0.01, "game time advances while the workbench panel is open (%.3f -> %.3f)" % [before, after])
	hud.call("close_bench")
	hud.call("open_backpack")
	await process_frame
	failed += _assert(paused, "the backpack still pauses")
	hud.call("close_backpack")
	await process_frame
	failed += _assert(not paused, "closing the backpack resumes")
	hud.free()
	paused = false
	if failed == 0:
		print("WORKBENCH_PANEL_NO_PAUSE_OK")
	return failed


func _workbench_wisp_visible(tree_root: Window, game_state: Node, save_service: Node) -> int:
	var failed: int = 0
	var jobs: Node = tree_root.get_node_or_null("ForgeJobs")
	failed += _assert(jobs != null, "ForgeJobs for wisp orbits")
	if jobs == null:
		return failed
	jobs.call("set_scene_changes_enabled", true)
	jobs.call("set_in_forge_override", -1)
	paused = false
	game_state.call("reset_for_new_game")
	save_service.call("note_session_ended")
	save_service.set("boot_intent", "new")
	change_scene_to_file(_HUB_SCENE)
	failed += await _expect_scene("wisp hub", _HUB_SCENE)
	var live: Node = current_scene
	if live == null:
		return failed + 1
	game_state.set("wisp_count", 1)
	if live.has_method("_sync_wisps"):
		live.call("_sync_wisps")
	await process_frame
	await process_frame
	var bench: Node2D = live.get_node_or_null("World/KeepersBench") as Node2D
	failed += _assert(bench != null, "workbench for the wisp")
	failed += _assert(str(game_state.call("try_assign_wisp", 0, "workbench")) == "ok", "wisp assigns to the workbench")
	await process_frame
	var wisp: Node2D = get_first_node_in_group("wisp") as Node2D
	failed += _assert(wisp != null and wisp.visible, "workbench wisp is in the clearing")
	if wisp != null and wisp.has_method("place_on_shared_orbit"):
		wisp.call("place_on_shared_orbit")
	var center: Vector2 = bench.call("wisp_orbit_center") if bench != null else Vector2.ZERO
	var radius: float = float(bench.call("wisp_orbit_radius")) if bench != null else 0.0
	if wisp != null:
		var gap: float = wisp.global_position.distance_to(center)
		failed += _assert(absf(gap - radius) < 20.0, "workbench wisp orbits the bench (off %.1f radius %.1f)" % [gap, radius])
		failed += _assert(wisp.visible, "workbench wisp stays visible on the ring")
	var mana: Node = live.get_node_or_null("World/Manatree")
	failed += _assert(mana != null and mana.has_method("wisp_orbit_radius"), "manatree orbit")
	if mana != null:
		game_state.set("stage_id", StringName("mature"))
		var mature_r: float = float(mana.call("wisp_orbit_radius"))
		game_state.set("stage_id", StringName("elder"))
		var elder_r: float = float(mana.call("wisp_orbit_radius"))
		game_state.set("stage_id", StringName("ancient"))
		var ancient_r: float = float(mana.call("wisp_orbit_radius"))
		game_state.set("stage_id", StringName("sapling"))
		failed += _assert(elder_r >= 280.0 and elder_r >= mature_r * 3.0, "elder manatree orbit is much larger (%.1f vs mature %.1f)" % [elder_r, mature_r])
		failed += _assert(ancient_r < 120.0 and absf(ancient_r - elder_r) > 100.0, "ancient keeps the trunk orbit (%.1f)" % ancient_r)
	jobs.call("set_in_forge_override", -1)
	change_scene_to_file(_FORGE_SCENE)
	failed += await _expect_scene("wisp forge", _FORGE_SCENE)
	var room: Node = current_scene
	if room != null and room.has_method("_sync_wisps"):
		room.call("_sync_wisps")
	await process_frame
	var station: Node2D = room.get_node_or_null("Crucible") as Node2D if room != null else null
	failed += _assert(station != null, "crucible for the station orbit")
	game_state.call("unassign_wisp", 0)
	failed += _assert(str(game_state.call("try_assign_wisp", 0, "crucible")) == "ok", "wisp assigns to the crucible")
	await process_frame
	wisp = get_first_node_in_group("wisp") as Node2D
	failed += _assert(wisp != null and wisp.visible, "station wisp is in the forge")
	if station != null and wisp != null:
		var shown: Vector2 = station.call("_sprite_shown_size")
		var half_w: float = shown.x * 0.5
		jobs.call("debug_set_wisp_orbit_phase", 0.0)
		wisp.call("place_on_shared_orbit")
		failed += _assert(int(wisp.z_index) >= 1, "east side stays in front")
		failed += _assert(wisp.global_position.x > station.global_position.x + half_w, "east side clears the sprite")
		jobs.call("debug_set_wisp_orbit_phase", PI)
		wisp.call("place_on_shared_orbit")
		failed += _assert(int(wisp.z_index) >= 1, "west side stays in front")
		failed += _assert(wisp.global_position.x < station.global_position.x - half_w, "west side clears the sprite")
		jobs.call("debug_set_wisp_orbit_phase", PI * 0.5)
		wisp.call("place_on_shared_orbit")
		failed += _assert(int(wisp.z_index) >= 2, "south side draws in front of the station")
		failed += _assert(wisp.global_position.y > station.global_position.y, "south side is in front of the station feet")
		failed += _assert(wisp.visible, "south side stays visible")
	_drop_current_scene()
	game_state.call("reset_for_new_game")
	jobs.call("reset_for_new_game")
	jobs.call("set_in_forge_override", -1)
	paused = false
	if failed == 0:
		print("WORKBENCH_WISP_VISIBLE_OK")
		print("STATION_WISP_ORBIT_OK")
		print("MANATREE_ELDER_ORBIT_OK")
	return failed


func _forged_item_any_character(tree_root: Window) -> int:
	var failed: int = 0
	var gear: Node = tree_root.get_node_or_null("Equipment")
	failed += _assert(gear != null, "Equipment for forged items")
	if gear == null:
		return failed
	gear.call("reset_for_new_game")
	var forged: PackedStringArray = PackedStringArray(["rootsteel_edge", "heartwand", "oakheart_knot", "shardlens", "switchshaft", "windthorn_bead"])
	for item_id: String in forged:
		failed += _assert(bool(gear.call("add_gear", item_id, 1)), "bag %s" % item_id)
		failed += _assert(bool(gear.call("usable_by", item_id, "keeper")) and bool(gear.call("usable_by", item_id, "elaia")), "%s has no character lock" % item_id)
	var keeper_ids: PackedStringArray = _sheet_ids(gear, "keeper")
	var elaia_ids: PackedStringArray = _sheet_ids(gear, "elaia")
	for item_id: String in forged:
		failed += _assert(keeper_ids.has(item_id) and elaia_ids.has(item_id), "%s is on both sheets" % item_id)
	failed += _assert(str(gear.call("try_equip", "rootsteel_edge", "keeper")) == "ok", "keeper equips the edge")
	elaia_ids = _sheet_ids(gear, "elaia")
	failed += _assert(not elaia_ids.has("rootsteel_edge"), "elaia does not see the edge while the keeper wears it")
	failed += _assert(str(gear.call("try_equip", "rootsteel_edge", "elaia")) == "missing", "elaia cannot take the worn edge")
	failed += _assert(str(gear.call("try_unequip", "weapon", "keeper")) == "ok", "keeper puts the edge down")
	failed += _assert(str(gear.call("try_equip", "rootsteel_edge", "elaia")) == "ok", "elaia equips the edge once it is free")
	keeper_ids = _sheet_ids(gear, "keeper")
	failed += _assert(not keeper_ids.has("rootsteel_edge"), "keeper does not see the edge while elaia wears it")
	gear.call("reset_for_new_game")
	gear.call("add_gear", "stone_sword", 1)
	gear.call("add_gear", "sapstaff", 1)
	failed += _assert(not bool(gear.call("usable_by", "stone_sword", "elaia")), "handcraft sword stays keeper-only")
	failed += _assert(not bool(gear.call("usable_by", "sapstaff", "keeper")), "handcraft staff stays elaia-only")
	gear.call("reset_for_new_game")
	if failed == 0:
		print("FORGED_ITEM_ANY_CHARACTER_OK")
	return failed


func _workbench_north_route() -> int:
	var failed: int = 0
	var keeper_cls: GDScript = load("res://scripts/keeper.gd") as GDScript
	failed += _assert(keeper_cls != null, "keeper script for the bench route")
	if keeper_cls == null:
		return failed
	var footprint := Rect2(Vector2(100, 100), Vector2(176, 104))
	var spot := Vector2(footprint.get_center().x, footprint.position.y + footprint.size.y + 28.0)
	var from_west: Array = keeper_cls.call("bench_approach_route", Vector2(120, 40), spot, footprint)
	var from_east: Array = keeper_cls.call("bench_approach_route", Vector2(280, 40), spot, footprint)
	var from_south: Array = keeper_cls.call("bench_approach_route", Vector2(spot.x, spot.y + 40.0), spot, footprint)
	failed += _assert(from_west.size() >= 2, "north-west approach has a waypoint")
	failed += _assert(from_east.size() >= 2, "north-east approach has a waypoint")
	if from_west.size() >= 2 and from_east.size() >= 2:
		var west_pt: Vector2 = from_west[0]
		var east_pt: Vector2 = from_east[0]
		var west_end: Vector2 = from_west[from_west.size() - 1]
		var east_end: Vector2 = from_east[from_east.size() - 1]
		failed += _assert(west_pt.x < footprint.position.x, "north-west route uses the west side")
		failed += _assert(east_pt.x > footprint.position.x + footprint.size.x, "north-east route uses the east side")
		failed += _assert(west_end.distance_to(spot) <= 0.1 and east_end.distance_to(spot) <= 0.1, "both routes end on the south stand")
	failed += _assert(from_south.size() == 1, "a south approach goes straight to the stand")
	if failed == 0:
		print("WORKBENCH_NORTH_ROUTE_OK")
	return failed


func _craft_duration_labels(tree_root: Window, game_state: Node, backpack: Node) -> int:
	var failed: int = 0
	var jobs: Node = tree_root.get_node_or_null("ForgeJobs")
	failed += _assert(jobs != null and backpack != null, "duration label nodes")
	if jobs == null:
		return failed
	jobs.call("set_autosave_enabled", false)
	jobs.call("reset_for_new_game")
	game_state.call("reset_for_new_game")
	backpack.call("reset_for_new_game")
	game_state.call("set_resource", &"wood", 6)
	var panel_scene: PackedScene = load("res://scenes/ui/batch_panel.tscn") as PackedScene
	var panel: Node = panel_scene.instantiate() if panel_scene != null else null
	failed += _assert(panel != null, "duration panel")
	if panel == null:
		return failed
	tree_root.add_child(panel)
	panel.call("setup", "workbench")
	panel.call("bind_recipe", "wooden_planks")
	await process_frame
	var count: Label = panel.find_child("Count", true, false) as Label
	failed += _assert(count != null and count.text.find("0m 12s") >= 0, "workbench slider shows the craft duration (got %s)" % (count.text if count else ""))
	failed += _assert(str(jobs.call("try_begin_batch", "workbench", "wooden_planks", 2)) == "ok", "plank batch starts")
	jobs.call("set_keeper_working", "workbench", true)
	await process_frame
	var current: Label = panel.find_child("CurrentLabel", true, false) as Label
	var total: Label = panel.find_child("TotalLabel", true, false) as Label
	failed += _assert(current != null and current.text.find("0m 06s") >= 0, "workbench current bar shows the item time (got %s)" % (current.text if current else ""))
	failed += _assert(total != null and total.text.find("0m 12s") >= 0, "workbench batch bar shows the remaining time (got %s)" % (total.text if total else ""))
	jobs.call("cancel_batch", "workbench")
	jobs.call("note_keeper_idle")
	game_state.call("set_resource", &"stone", 20)
	panel.call("setup", "crucible")
	panel.call("bind_recipe", "sapsteel")
	await process_frame
	count = panel.find_child("Count", true, false) as Label
	failed += _assert(count != null and count.text.find("1m 00s") >= 0, "forge slider shows the craft duration (got %s)" % (count.text if count else ""))
	failed += _assert(str(jobs.call("try_begin_batch", "crucible", "sapsteel", 1)) == "ok", "sapsteel batch starts")
	jobs.call("set_keeper_working", "crucible", true)
	await process_frame
	current = panel.find_child("CurrentLabel", true, false) as Label
	total = panel.find_child("TotalLabel", true, false) as Label
	failed += _assert(current != null and current.text.find("1m 00s") >= 0, "forge current bar shows the item time (got %s)" % (current.text if current else ""))
	failed += _assert(total != null and total.text.find("1m 00s") >= 0, "forge batch bar shows the remaining time (got %s)" % (total.text if total else ""))
	var tip: String = str(jobs.call("bar_tooltip", "crucible", "current"))
	game_state.call("set_resource", &"wood", 6)
	jobs.call("note_keeper_idle")
	failed += _assert(str(jobs.call("try_begin_batch", "workbench", "wooden_planks", 1)) == "ok", "tooltip plank batch starts")
	jobs.call("set_keeper_working", "workbench", true)
	var bench_tip: String = str(jobs.call("bar_tooltip", "workbench", "current"))
	failed += _assert(tip.find("%") >= 0 and tip.find("left") >= 0, "station bar tooltip has percent and time")
	failed += _assert(bench_tip.find("%") >= 0 and bench_tip.find("left") >= 0, "workbench bar tooltip has percent and time")
	var host := Node2D.new()
	tree_root.add_child(host)
	var bars: Node = load("res://scripts/batch_world_bars.gd").new()
	host.add_child(bars)
	bars.call("bind", host, "workbench")
	await process_frame
	var bar: Control = bars.find_child("CurrentBar", true, false) as Control
	failed += _assert(bar != null and bar.tooltip_text == bench_tip and bench_tip != "", "workbench in-world bar uses the station tooltip")
	host.free()
	panel.free()
	jobs.call("reset_for_new_game")
	game_state.call("reset_for_new_game")
	backpack.call("reset_for_new_game")
	if failed == 0:
		print("CRAFT_DURATION_LABEL_OK")
		print("WORKBENCH_BAR_TOOLTIP_OK")
	return failed


func _adventure_batch1(tree_root: Window, game_state: Node, save_service: Node, content_strings: Node, game_audio: Node) -> int:
	var failed: int = 0
	var echo: Node = tree_root.get_node_or_null("EchoChamber")
	var equipment: Node = tree_root.get_node_or_null("Equipment")
	failed += _assert(echo != null and equipment != null, "echo and equipment autoloads")
	if echo == null or equipment == null:
		return failed
	var exact: Dictionary = {
		"path_east_tease": "The thorns are knotted tight. Something is holding them shut.",
		"path_east_open_toast": "The knots slip loose. The road is open.",
		"echo_02_intro": "Stop there. Every road out of this place, I tied shut. The rot was running them, so I snared them all, one knot at a time. The groves behind me starved quietly instead. You want them open? With that axe? I have seen better tools left out in the rain.",
		"echo_02_mercy": "Enough. You are quicker than you look, even with tools like those. Cut me down, and the snares fall with me. Spare me, and I will untie the roads myself. Knot by knot.",
		"adventure_echo2_toast_spare": "Bramble is spared. The snares go slack. The road is open.",
		"expedition_board_hint": "Choose who goes, and which road.",
		"lantern_done": "The lantern flickers. They are home, and they brought something back.",
		"bramble_join_3": "Then I will run with you. Someone should know where the old roads went.",
	}
	for key: String in exact.keys():
		failed += _assert(str(content_strings.call("get_text", key)) == str(exact[key]), "draft line %s" % key)
	var bramble: Dictionary = echo.call("bramble_def")
	var stats: Dictionary = bramble.get("stats", {}) as Dictionary
	failed += _assert(str(bramble.get("attack_profile", "")) == "hybrid", "Bramble is hybrid")
	failed += _assert(int(stats.get("resilience", 9)) <= 3 and int(stats.get("ward", 9)) <= 3, "Bramble is not a tank")
	failed += _assert(int(stats.get("swiftness", 0)) >= 8 and int(stats.get("vitality", 9)) <= 5, "Bramble is nimble")
	var scrap: Variant = EchoBattleScript.new()
	scrap.force_crit = 0
	scrap.configure({"might": 5, "arcana": 5, "resilience": 5, "ward": 5, "vitality": 5, "swiftness": 5, "fate": 5}, bramble)
	failed += _assert(not scrap.keeper_acts_first(), "Bramble acts before a default Keeper")
	failed += _assert(scrap.choose("strike") == "continue", "snare does not end the fight")
	failed += _assert(str(scrap.last_foe_swing) == "snare", "first hybrid swing is a snare")
	failed += _assert(scrap.choose("strike") == "continue", "knot does not end the fight")
	failed += _assert(str(scrap.last_foe_swing) == "knot", "second hybrid swing is a knot")
	game_state.call("reset_for_new_game")
	equipment.call("reset_for_new_game")
	var before_fee: int = failed
	failed += _assert(str(echo.call("try_pay_bramble")) == "closed", "no fee without an Anvil weapon")
	failed += _assert(bool(equipment.call("grant_item", "rootsteel_edge")), "grant first Anvil weapon")
	game_state.call("set_resource", &"essence", 49)
	failed += _assert(str(echo.call("try_pay_bramble")) == "reject", "49 Essence is short")
	failed += _assert(int(game_state.get("essence")) == 49, "rejected Bramble fee spends nothing")
	game_state.call("set_resource", &"essence", 50)
	failed += _assert(str(echo.call("try_pay_bramble")) == "paid", "50 Essence pays the Bramble fee")
	failed += _assert(int(game_state.get("essence")) == 0 and bool(game_state.get("echo_02_fee_paid")), "fee flag after 50")
	echo.set("battle_context", "echo2")
	echo.call("apply_outcome", "flee")
	failed += _assert(bool(game_state.get("echo_02_fee_paid")) and str(game_state.get("echo_02_outcome")) == "flee", "flee keeps the Bramble fee")
	failed += _assert(not bool(game_state.get("echo_02_resolved")), "flee does not open the road")
	echo.set("battle_context", "echo2")
	echo.call("apply_outcome", "ko")
	failed += _assert(not bool(game_state.get("echo_02_fee_paid")) and str(game_state.get("echo_02_outcome")) == "ko", "a loss clears the Bramble fee")
	game_state.set("forge_key", false)
	echo.set("battle_context", "echo2")
	var spare_pay: Dictionary = echo.call("apply_outcome", "spare")
	failed += _assert(int(spare_pay.get("shards", -1)) == 0, "Bramble spare pays no shards")
	failed += _assert(bool(game_state.get("echo_02_resolved")) and str(game_state.get("echo_02_outcome")) == "spare", "spare opens the road")
	failed += _assert(not bool(game_state.get("forge_key")), "Bramble spare does not grant the Forge Key")
	game_state.set("echo_02_resolved", false)
	game_state.set("echo_02_outcome", "")
	echo.set("battle_context", "echo2")
	echo.call("apply_outcome", "defeat")
	failed += _assert(bool(game_state.get("echo_02_resolved")) and str(game_state.get("echo_02_outcome")) == "defeat", "defeat opens the road")
	if failed == before_fee:
		print("BRAMBLE_ECHO_FEE_OK")
	game_state.call("reset_for_new_game")
	equipment.call("reset_for_new_game")
	save_service.set("boot_intent", "new")
	game_state.set("welcome_shown", true)
	var packed: PackedScene = load("res://scenes/main.tscn") as PackedScene
	failed += _assert(packed != null, "main scene")
	if packed == null:
		return failed
	var live: Node = packed.instantiate()
	tree_root.add_child(live)
	await process_frame
	await process_frame
	var wall: Node2D = live.get_node_or_null("World/ThornWall") as Node2D
	var board: Node2D = live.get_node_or_null("World/ExpeditionBoard") as Node2D
	var warden: Node2D = live.get_node_or_null("World/BrambleWarden") as Node2D
	var trail: Line2D = live.get_node_or_null("Paths/ThornTrail") as Line2D
	var stone_path: Line2D = live.get_node_or_null("Paths/StoneToResilience") as Line2D
	var before_locked: int = failed
	failed += _assert(wall != null and wall.position.distance_to(Vector2(2140, 620)) < 0.5, "thorn wall feet")
	failed += _assert(bool(wall.call("collider_enabled")), "closed wall blocks the centre")
	failed += _assert(bool(wall.call("sides_blocked")), "hedge sides stay solid")
	var box_v: Variant = wall.call("walk_box_size") if wall else Vector2.ZERO
	var box: Vector2 = box_v
	failed += _assert(abs(box.x - 62.0) < 0.5 and abs(box.y - 19.0) < 0.5, "centre gate 62x19 (got %s)" % box)
	failed += _assert(str(wall.call("begin_entry")) == "tease", "early click teases")
	failed += _assert(trail != null and trail.get_point_count() == 4, "thorn trail points")
	if trail:
		failed += _assert(trail.get_point_position(0).distance_to(Vector2(2000, 1000)) < 0.5, "trail start")
		failed += _assert(trail.get_point_position(3).distance_to(Vector2(2140, 690)) < 0.5, "trail end")
	failed += _assert(stone_path != null and stone_path.get_point_count() == 5, "StoneToResilience is one path again")
	failed += _assert(live.get_node_or_null("Paths/StoneToThornFork") == null, "east fork is gone")
	failed += _assert(not bool(game_state.get("echo_02_resolved")), "path starts closed")
	if failed == before_locked:
		print("THORN_PATH_LOCKED_OK")
	var before_board: int = failed
	failed += _assert(board != null and board.position.distance_to(Vector2(2304, 780)) < 0.5, "board feet")
	var board_box_v: Variant = board.call("walk_box_size") if board else Vector2.ZERO
	var board_box: Vector2 = board_box_v
	failed += _assert(abs(board_box.x - 128.0) < 0.5 and abs(board_box.y - 45.0) < 1.0, "board walk box")
	board.call("open_shell")
	failed += _assert(bool(board.call("shell_open")), "expedition shell opens")
	failed += _assert(bool(board.call("depart_disabled")), "Depart stays disabled while the road is shut")
	failed += _assert(str(board.call("try_depart")) == "closed", "a shut road does not depart")
	failed += _assert(bool(board.call("shell_starts_reach")), "the board can start a reach")
	failed += _assert(str(board.call("lantern_state")) == "dark", "lantern starts dark")
	board.call("set_lantern", "amber")
	failed += _assert(str(board.call("lantern_state")) == "amber" and not bool(board.call("exclaim_visible")), "amber lantern, no mark")
	board.call("set_lantern", "cyan")
	failed += _assert(str(board.call("lantern_state")) == "cyan" and bool(board.call("exclaim_visible")), "cyan lantern shows the mark")
	board.call("set_lantern", "dark")
	var party: Variant = board.call("selected_party") if board else []
	failed += _assert(party is Array and (party as Array).has("keeper") and not (party as Array).has("bramble"), "party shell has no Bramble join")
	board.call("close_shell")
	if failed == before_board:
		print("EXPEDITION_BOARD_SHELL_OK")
	var before_open: int = failed
	failed += _assert(bool(equipment.call("grant_item", "heartwand")), "second Anvil weapon still counts")
	game_state.call("set_resource", &"essence", 50)
	game_audio.call("clear_played_log")
	failed += _assert(str(wall.call("begin_entry")) == "confirm", "weapon opens the Echo confirm")
	wall.call("cancel_fee")
	failed += _assert(str(echo.call("try_pay_bramble")) == "paid", "scene pays 50")
	failed += _assert(str(wall.call("begin_entry")) == "enter", "paid fee re-enters")
	echo.call("finish_battle", "spare")
	await process_frame
	failed += _assert(bool(game_state.get("echo_02_resolved")), "spare resolved in the clearing")
	failed += _assert(not bool(wall.call("collider_enabled")), "open wall drops the centre gate")
	failed += _assert(bool(wall.call("sides_blocked")), "open wall keeps the side hedges")
	failed += _assert(bool(game_audio.call("did_play", &"sfx_path_open")), "path open plays sfx_path_open")
	failed += _assert(warden != null and warden.visible, "spared Bramble watches the trailhead")
	warden.call("on_interact", null)
	failed += _assert(str(content_strings.call("get_text", "adventure_promised")).find("Not yet at your side") >= 0, "spared Bramble is not a companion yet")
	if failed == before_open:
		print("THORN_PATH_OPENS_OK")
	live.free()
	game_state.call("reset_for_new_game")
	equipment.call("reset_for_new_game")
	return failed


const _ECHO2_SAVE_SLOT: int = 6


func _echo2_portal_visible(tree_root: Window, game_state: Node, save_service: Node) -> int:
	## Haex playtest at 247121f: after the first Anvil weapon, Echo 2's portal was an
	## invisible, unclickable collision box. The hub arch hid itself after Elaia's Echo
	## (it only knew Echo 1) and never came back for Bramble, while its walk body kept
	## colliding. Drives the real path: Elaia done, Anvil job finishes, save + reload,
	## right-click the arch, the Keeper walks in, the fee confirm opens, Yes enters Bramble.
	var failed: int = 0
	var echo: Node = tree_root.get_node_or_null("EchoChamber")
	var equipment: Node = tree_root.get_node_or_null("Equipment")
	var jobs: Node = tree_root.get_node_or_null("ForgeJobs")
	var backpack: Node = tree_root.get_node_or_null("Backpack")
	var content_strings: Node = tree_root.get_node_or_null("ContentStrings")
	failed += _assert(echo != null and equipment != null and jobs != null and backpack != null and content_strings != null, "echo2 portal autoloads")
	if failed > 0:
		return failed
	jobs.call("set_dev_speed_override", 1.0)
	jobs.call("set_autosave_enabled", false)
	paused = false
	game_state.call("reset_for_new_game")
	save_service.call("delete_slot", _ECHO2_SAVE_SLOT)
	save_service.set("boot_intent", "new")
	game_state.set("welcome_shown", true)
	var live: Node = await _echo2_boot_hub(tree_root)
	var portal: Area2D = live.get_node_or_null("World/EchoPortal") as Area2D if live else null
	failed += _assert(portal != null, "hub has the Echo portal")
	if portal == null:
		if live:
			live.free()
		return failed
	# State right after Elaia's Echo (Echo 1): Forge Key, no Anvil weapon yet.
	game_state.set("ascensions", 1)
	game_state.set("portal_unlocked", true)
	game_state.set("portal_fee_paid", false)
	game_state.set("echo_01_resolved", true)
	game_state.set("echo_01_redeemed", true)
	game_state.set("forge_key", true)
	game_state.emit_signal("echo_flags_changed")
	failed += _assert(not portal.visible and not portal.input_pickable, "arch is closed between Elaia and the first Anvil weapon")
	failed += _assert(not bool(portal.call("walk_collision_enabled")), "a closed arch leaves no bare walk box")
	failed += _assert(str(portal.call("begin_entry")) == "closed", "a closed arch does not open an Echo")
	# First Anvil weapon through the real Anvil job.
	backpack.call("set_count", "sapsteel", 24)
	backpack.call("set_count", "heartwood_bits", 12)
	backpack.call("set_count", "amberbind", 8)
	game_state.call("set_resource", &"essence", 300)
	failed += _assert(str(jobs.call("try_begin_job", "anvil", "rootsteel_edge")) == "ok", "first Anvil craft starts")
	jobs.call("set_keeper_working", "anvil", true)
	jobs.call("advance_seconds", 1200.0)
	failed += _assert(bool(echo.call("owns_anvil_weapon")), "first Anvil craft finishes a weapon")
	game_state.call("set_resource", &"essence", 50)
	await physics_frame
	await process_frame
	failed += await _echo2_arch_ready(live, portal, "after the first Anvil craft")
	# A save that is already portal-ready must restore the arch, live and on a fresh boot.
	failed += _assert(bool(save_service.call("save_game", _ECHO2_SAVE_SLOT)), "save the portal-ready state")
	game_state.call("reset_for_new_game")
	failed += _assert(not portal.visible and not bool(portal.call("walk_collision_enabled")), "a new game closes the arch")
	failed += _assert(bool(save_service.call("load_game", _ECHO2_SAVE_SLOT)), "load the portal-ready save")
	await physics_frame
	await process_frame
	failed += await _echo2_arch_ready(live, portal, "after loading the save")
	live.free()
	save_service.set("boot_intent", "load")
	save_service.set("boot_slot", _ECHO2_SAVE_SLOT)
	save_service.set("boot_slot_kind", "manual")
	live = await _echo2_boot_hub(tree_root)
	portal = live.get_node_or_null("World/EchoPortal") as Area2D if live else null
	failed += _assert(portal != null, "booted hub has the Echo portal")
	if portal == null:
		if live:
			live.free()
		save_service.call("delete_slot", _ECHO2_SAVE_SLOT)
		game_state.call("reset_for_new_game")
		return failed
	failed += await _echo2_arch_ready(live, portal, "on a boot from the save")
	failed += _assert(int(game_state.get("essence")) == 50 and not bool(game_state.get("echo_02_fee_paid")), "save kept 50 Essence and no Bramble fee")
	# Right-click the arch with the Keeper selected. The Keeper walks in and the fee confirm opens.
	var hud: Node = live.get_node_or_null("HUD")
	if hud != null and hud.has_method("hide_welcome"):
		hud.call("hide_welcome")
	var keeper: Node2D = live.get_node_or_null("World/Keeper") as Node2D
	failed += _assert(keeper != null, "keeper for the arch walk")
	if keeper != null:
		keeper.global_position = portal.global_position + Vector2(0, 110)
		game_state.call("select_keeper")
		await process_frame
		var rmb := InputEventMouseButton.new()
		rmb.button_index = MOUSE_BUTTON_RIGHT
		rmb.pressed = true
		portal.input_event.emit(tree_root, rmb, 0)
		var opened: bool = false
		for _step: int in 360:
			await physics_frame
			await process_frame
			if bool(portal.call("is_fee_confirm_open")):
				opened = true
				break
		failed += _assert(opened, "right-click walks the Keeper in and opens the fee confirm")
		var title: Label = tree_root.get_node_or_null("EchoPortalConfirm/Panel/Title") as Label
		var yes_btn: Button = tree_root.get_node_or_null("EchoPortalConfirm/Panel/Yes") as Button
		var bramble_title: String = str(content_strings.call("get_text", "bramble_name"))
		failed += _assert(title != null and title.text == bramble_title, "the arch confirm is Bramble's (got %s)" % (title.text if title else "none"))
		failed += _assert(yes_btn != null and not yes_btn.disabled, "50 Essence enables Yes")
		if opened and yes_btn != null:
			yes_btn.pressed.emit()
			await process_frame
		failed += _assert(bool(echo.get("in_battle")) and str(echo.get("battle_context")) == "echo2", "Yes enters Bramble's Echo")
		failed += _assert(int(game_state.get("essence")) == 0 and bool(game_state.get("echo_02_fee_paid")), "entry spends the 50 Essence Bramble fee")
		failed += _assert(not bool(game_state.get("portal_fee_paid")), "Bramble entry does not touch Elaia's fee")
		if bool(echo.get("in_battle")):
			echo.call("dismiss_battle_without_reward")
		await process_frame
		failed += _assert(portal.visible and bool(portal.call("serves_bramble")), "arch stays open for a paid Bramble re-entry")
		game_state.set("echo_02_resolved", true)
		game_state.emit_signal("echo_flags_changed")
		failed += _assert(not portal.visible and not bool(portal.call("walk_collision_enabled")), "arch closes once Bramble is resolved")
	paused = false
	live.free()
	save_service.call("delete_slot", _ECHO2_SAVE_SLOT)
	game_state.call("reset_for_new_game")
	if failed == 0:
		print("ECHO2_PORTAL_VISIBLE_OK")
	return failed


func _echo2_boot_hub(tree_root: Window) -> Node:
	var packed: PackedScene = load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		return null
	var live: Node = packed.instantiate()
	tree_root.add_child(live)
	await process_frame
	await process_frame
	await physics_frame
	return live


func _echo2_arch_ready(live: Node, portal: Area2D, when: String) -> int:
	var failed: int = 0
	failed += _assert(portal.visible and portal.is_visible_in_tree(), "arch is visible %s" % when)
	var marker: Sprite2D = portal.get_node_or_null("Visual/Marker") as Sprite2D
	failed += _assert(marker != null and marker.texture != null and marker.is_visible_in_tree(), "arch sprite draws %s" % when)
	if marker != null:
		failed += _assert(marker.modulate.a > 0.5 and portal.modulate.a > 0.5, "arch sprite is opaque %s" % when)
	failed += _assert(portal.input_pickable, "arch takes clicks %s" % when)
	var pick: CollisionShape2D = portal.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var pick_rect: RectangleShape2D = pick.shape as RectangleShape2D if pick else null
	failed += _assert(pick != null and not pick.disabled and pick_rect != null and pick_rect.size.x >= 100.0, "arch click area is live %s" % when)
	failed += _assert(bool(portal.call("walk_collision_enabled")), "arch base still blocks walking %s" % when)
	failed += _assert(bool(portal.call("serves_bramble")), "arch serves Bramble %s" % when)
	var arch_mid: Vector2 = portal.global_position + Vector2(0, -100)
	failed += _assert(bool(live.call("_interactable_under_point", arch_mid)), "a click on the arch hits it %s" % when)
	return failed


func _expedition_board_tease(tree_root: Window, game_state: Node, save_service: Node) -> int:
	## Haex playtest at 247121f: clicking the north board before Bramble was passed
	## opened the shell silently. It must tease the shut road like the thorn wall
	## (path_east_tease), and open the shell once the road is open.
	var failed: int = 0
	var content_strings: Node = tree_root.get_node_or_null("ContentStrings")
	failed += _assert(content_strings != null, "strings for the board tease")
	if content_strings == null:
		return failed
	var tease: String = str(content_strings.call("get_text", "path_east_tease"))
	failed += _assert(tease == "The thorns are knotted tight. Something is holding them shut.", "board reuses the wall tease line")
	paused = false
	game_state.call("reset_for_new_game")
	save_service.set("boot_intent", "new")
	game_state.set("welcome_shown", true)
	var live: Node = await _echo2_boot_hub(tree_root)
	var board: Area2D = live.get_node_or_null("World/ExpeditionBoard") as Area2D if live else null
	var wall: Node = live.get_node_or_null("World/ThornWall") if live else null
	var keeper: Node2D = live.get_node_or_null("World/Keeper") as Node2D if live else null
	failed += _assert(board != null and wall != null and keeper != null, "board, wall and keeper in the hub")
	if board == null or wall == null or keeper == null:
		if live:
			live.free()
		return failed
	var hud: Node = live.get_node_or_null("HUD")
	if hud != null and hud.has_method("hide_welcome"):
		hud.call("hide_welcome")
	var seen: Array[String] = []
	var grab := func(text: String) -> void:
		seen.append(text)
	game_state.status_message.connect(grab)
	failed += _assert(not bool(game_state.get("echo_02_resolved")), "road starts shut")
	failed += _assert(str(wall.call("begin_entry")) == "tease" and seen.has(tease), "the wall teases with path_east_tease")
	seen.clear()
	# Right-click the board with the Keeper selected. The Keeper walks over and the tease shows.
	var opened: bool = await _board_click(board, keeper, game_state, tree_root, seen, tease)
	failed += _assert(seen.has(tease), "a shut-road board click shows path_east_tease (got %s)" % [seen])
	failed += _assert(not opened and not bool(board.call("shell_open")), "a shut-road board click does not open the shell")
	failed += _assert(str(board.call("begin_entry")) == "tease", "board begin_entry teases while the road is shut")
	if bool(board.call("shell_open")):
		board.call("close_shell")
	# Bramble spared: the same click opens the shell, with no tease.
	game_state.set("echo_02_resolved", true)
	game_state.set("echo_02_outcome", "spare")
	game_state.emit_signal("echo_flags_changed")
	seen.clear()
	opened = await _board_click(board, keeper, game_state, tree_root, seen, tease)
	failed += _assert(opened and bool(board.call("shell_open")), "an open-road board click opens the shell")
	failed += _assert(not seen.has(tease), "an open-road board click does not tease")
	failed += _assert(not bool(board.call("depart_disabled")), "Depart is live once the road is open")
	board.call("close_shell")
	game_state.status_message.disconnect(grab)
	live.free()
	game_state.call("reset_for_new_game")
	if failed == 0:
		print("EXPEDITION_BOARD_TEASE_OK")
	return failed


func _board_click(board: Area2D, keeper: Node2D, game_state: Node, tree_root: Window, seen: Array[String], tease: String) -> bool:
	## Returns true when the shell opened. Stops early on the tease line.
	keeper.global_position = board.global_position + Vector2(0, 110)
	if keeper.has_method("halt"):
		keeper.call("halt")
	game_state.call("select_keeper")
	await process_frame
	var rmb := InputEventMouseButton.new()
	rmb.button_index = MOUSE_BUTTON_RIGHT
	rmb.pressed = true
	board.input_event.emit(tree_root, rmb, 0)
	for _step: int in 360:
		await physics_frame
		await process_frame
		if bool(board.call("shell_open")):
			return true
		if seen.has(tease):
			# Give a wrong shell open a few frames to show up.
			for _extra: int in 5:
				await process_frame
			return bool(board.call("shell_open"))
	return bool(board.call("shell_open"))


## Experimental-only snapshots for Bramble / reach playtests. Menu label -> file.
## Stable strips them (see _stripped_paths). The debug panel lists the same labels.
const _REACH_SNAPSHOTS: Dictionary = {
	"Echo 2 ready": "res://tools/debug/snapshots/echo2_ready.json",
	"North road open": "res://tools/debug/snapshots/north_road_open.json",
	"Pre-boss": "res://tools/debug/snapshots/pre_boss.json",
	"Veteran reacher": "res://tools/debug/snapshots/veteran_reacher.json",
}


func _debug_snapshots_reach(tree_root: Window, game_state: Node, save_service: Node) -> int:
	## Each of the four reach snapshots loads the way the debug panel loads it
	## (migrate, apply_save_dict on the state, then the hub) and lands in a valid state.
	var failed: int = 0
	var echo: Node = tree_root.get_node_or_null("EchoChamber")
	var reach: Node = tree_root.get_node_or_null("Reach")
	var equipment: Node = tree_root.get_node_or_null("Equipment")
	var pack: Node = tree_root.get_node_or_null("Backpack")
	failed += _assert(echo != null and reach != null and equipment != null and pack != null, "autoloads for the reach snapshots")
	if failed > 0:
		return failed
	## The four reach files stay version 13. migrate_state applies v14; do not re-save them.
	var want_version: int = 13
	failed += _assert(int(save_service.get("SAVE_VERSION")) > want_version, "v13 reach snapshots migrate forward")
	var panel_src: String = FileAccess.get_file_as_string("res://tools/debug/debug_panel.gd")
	for label: String in _REACH_SNAPSHOTS.keys():
		var path: String = str(_REACH_SNAPSHOTS[label])
		failed += _assert(panel_src.find("\"%s\": \"%s\"" % [label, path]) >= 0, "debug panel lists %s" % label)
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(parsed) == TYPE_DICTIONARY:
			failed += _assert(str((parsed as Dictionary).get("label", "")) == label, "snapshot label %s" % label)
	# a. Echo 2 ready: first Anvil weapon, 50 Essence, hub arch open for Bramble.
	failed += _probe_one(game_state, str(_REACH_SNAPSHOTS["Echo 2 ready"]), want_version, true)
	failed += _assert(bool(echo.call("owns_anvil_weapon")), "echo2 ready owns an Anvil weapon")
	failed += _assert(int(game_state.get("essence")) == 50, "echo2 ready has 50 Essence")
	failed += _assert(bool(game_state.get("echo_01_resolved")) and not bool(game_state.get("echo_02_resolved")), "echo2 ready: Elaia done, Bramble open")
	failed += _assert(bool(echo.call("bramble_gate_open")) and str(echo.call("hub_portal_context")) == "echo2", "echo2 ready opens the hub arch for Bramble")
	failed += _assert(not bool(game_state.get("echo_02_fee_paid")), "echo2 ready has not paid yet")
	failed += _assert(not bool(reach.get("running")) and int(reach.get("deepest_depth")) == 0, "echo2 ready has no reach yet")
	failed += await _snapshot_hub_check(tree_root, game_state, save_service, "Echo 2 ready")
	# b. North road open: Bramble spared, board live, no runs.
	failed += _probe_one(game_state, str(_REACH_SNAPSHOTS["North road open"]), want_version, true)
	failed += _assert(bool(game_state.get("echo_02_resolved")) and str(game_state.get("echo_02_outcome")) == "spare", "north road: Bramble spared")
	failed += _assert(str(echo.call("hub_portal_context")) == "", "north road: the hub arch is closed")
	failed += _assert(not bool(reach.get("running")) and int(reach.get("reaches_cleared")) == 0 and int(reach.get("deepest_depth")) == 0, "north road: no runs yet")
	failed += _assert(str(game_state.get("expedition_lantern")) == "dark", "north road: lantern dark")
	failed += await _snapshot_hub_check(tree_root, game_state, save_service, "North road open")
	# c. Pre-boss: room 9 of the run in progress, the next room is the boss.
	failed += _probe_one(game_state, str(_REACH_SNAPSHOTS["Pre-boss"]), want_version, true)
	failed += _assert(bool(reach.get("running")) and str(reach.get("phase")) == "idle_room", "pre-boss: an idle room is running")
	failed += _assert(int(reach.get("rooms_attempted")) == 9 and not bool(reach.call("is_boss_room")), "pre-boss: room 9, not the boss yet")
	failed += _assert(int(reach.call("rooms_until_boss")) == 1, "pre-boss: rooms until boss is 1 (got %d)" % int(reach.call("rooms_until_boss")))
	failed += _assert(float(reach.get("room_left")) > 0.0 and float(reach.call("_length_left")) > float(reach.get("room_left")) + 720.0, "pre-boss: the run is long enough to reach the boss")
	failed += _assert(str(game_state.get("expedition_lantern")) == "amber", "pre-boss: lantern amber")
	failed += await _snapshot_hub_check(tree_root, game_state, save_service, "Pre-boss")
	failed += _probe_one(game_state, str(_REACH_SNAPSHOTS["Pre-boss"]), want_version, true)
	reach.call("push_faces", [20])
	reach.call("advance_clock", float(reach.get("room_left")) + 0.001)
	failed += _assert(bool(reach.get("running")) and int(reach.get("rooms_attempted")) == 10 and bool(reach.call("is_boss_room")), "pre-boss: finishing room 9 opens the boss room")
	failed += _assert(int(reach.call("rooms_until_boss")) == 0, "pre-boss: board shows the boss room")
	# d. Veteran reacher: depth 25, mats, dojo exp, counter 19.
	failed += _probe_one(game_state, str(_REACH_SNAPSHOTS["Veteran reacher"]), want_version, true)
	failed += _assert(int(reach.get("deepest_depth")) == 25 and int(reach.call("max_start_depth")) == 25, "veteran: deepest depth 25")
	failed += _assert(int(reach.get("reaches_cleared")) == 19, "veteran: reach counter 19")
	failed += _assert(int(pack.call("get_count", "briarwood")) > 0 and int(pack.call("get_count", "herbs")) > 0 and int(reach.get("dojo_exp")) > 0, "veteran: Briarwood, herbs and dojo exp")
	failed += _assert(not bool(reach.get("running")) and bool(game_state.get("echo_02_resolved")), "veteran: idle at home with the road open")
	failed += await _snapshot_hub_check(tree_root, game_state, save_service, "Veteran reacher")
	# Round trip: the veteran state survives a save and load.
	var blob: Dictionary = game_state.call("to_save_dict")
	game_state.call("reset_for_new_game")
	game_state.call("apply_save_dict", blob)
	failed += _assert(int(reach.get("deepest_depth")) == 25 and int(reach.get("reaches_cleared")) == 19, "veteran survives a save round trip")
	paused = false
	game_state.call("reset_for_new_game")
	if failed == 0:
		print("DEBUG_SNAPSHOTS_REACH_OK")
	return failed


func _snapshot_hub_check(tree_root: Window, game_state: Node, save_service: Node, label: String) -> int:
	## The debug panel applies the state, starts the session, and swaps to the hub, which
	## keeps the live state. A child hub here would read "auto" as a bare boot and load the
	## newest disk save, so use the boot that keeps state without loading.
	var failed: int = 0
	var before: Dictionary = game_state.call("to_save_dict")
	save_service.call("note_session_started")
	save_service.set("boot_intent", "forge_return")
	var live: Node = await _echo2_boot_hub(tree_root)
	failed += _assert(live != null, "%s loads the hub" % label)
	if live == null:
		return failed
	var after: Dictionary = game_state.call("to_save_dict")
	for key: String in ["essence", "echo_01_resolved", "echo_02_resolved", "echo_02_outcome", "expedition_lantern", "gear_inventory"]:
		failed += _assert(str(after.get(key)) == str(before.get(key)), "%s hub keeps %s" % [label, key])
	var reach_before: Dictionary = before.get("reach", {}) as Dictionary
	var reach_after: Dictionary = after.get("reach", {}) as Dictionary
	for key: String in ["deepest_depth", "reaches_cleared", "running", "rooms_attempted", "phase"]:
		failed += _assert(str(reach_after.get(key)) == str(reach_before.get(key)), "%s hub keeps reach %s" % [label, key])
	var portal: Node = live.get_node_or_null("World/EchoPortal")
	var board: Node = live.get_node_or_null("World/ExpeditionBoard")
	var wall: Node = live.get_node_or_null("World/ThornWall")
	failed += _assert(portal != null and board != null and wall != null, "%s hub has portal, board and wall" % label)
	if portal != null and board != null and wall != null:
		var reach: Node = tree_root.get_node_or_null("Reach")
		var road: bool = bool(game_state.get("echo_02_resolved"))
		failed += _assert(portal.visible == (str(tree_root.get_node("EchoChamber").call("hub_portal_context")) != ""), "%s arch matches its state" % label)
		failed += _assert(bool(wall.call("collider_enabled")) == (not road), "%s wall matches the road" % label)
		var running: bool = reach != null and bool(reach.get("running"))
		failed += _assert(bool(board.call("depart_disabled")) == (not road or running), "%s Depart matches the road and run" % label)
		if label == "Echo 2 ready":
			failed += _assert(portal.visible and bool(portal.call("serves_bramble")), "Echo 2 ready shows Bramble's arch")
		if label == "Pre-boss":
			board.call("open_shell")
			failed += _assert(bool(board.call("shell_open")), "Pre-boss board shell opens")
			board.call("close_shell")
	live.free()
	await process_frame
	return failed


func _speed_button_ok(tree_root: Window, game_state: Node, save_service: Node, game_audio: Node) -> int:
	## Player speed is 1/2/4/8 during an open session. Offline and idle catch-up stay on the 1x curve.
	var failed: int = 0
	var session_was: bool = bool(save_service.get("session_active"))
	var scale_was: float = Engine.time_scale
	var run0: float = float(game_state.get("run_time_sec"))
	var idle0: float = float(game_state.get("active_since_load_sec"))
	game_state.call("reset_play_speed")
	failed += _assert(int(game_state.get("play_speed")) == 1, "launch speed is 1x")
	game_state.call("set_play_speed", 16)
	failed += _assert(int(game_state.get("play_speed")) == 1, "play speed has no 16x step")
	game_state.call("set_play_speed", 8)
	failed += _assert(int(game_state.get("play_speed")) == 8, "button reaches 8x")
	failed += _assert(is_equal_approx(Engine.time_scale, scale_was), "play speed leaves the debug time scale alone")
	save_service.set("session_active", false)
	failed += _assert(is_equal_approx(float(game_state.call("active_play_delta", 1.0)), 1.0), "a closed session stays 1x at 8x")
	save_service.set("session_active", true)
	failed += _assert(is_equal_approx(float(game_state.call("active_play_delta", 1.0)), 8.0), "open play uses 8x")
	game_state.call("advance_open_play", 1.0)
	failed += _assert(is_equal_approx(float(game_state.get("run_time_sec")) - run0, 8.0), "open frame advances play at 8x")
	failed += _assert(is_equal_approx(float(game_state.get("active_since_load_sec")) - idle0, 1.0), "idle clock stays 1x at 8x")
	var curve: float = float(game_state.call("offline_effective_seconds", 1800.0))
	var idle: float = float(game_state.call("idle_catch_up_seconds", 1800.0))
	failed += _assert(is_equal_approx(curve, 180.0), "30 min offline curve is 180s at 1x (got %s)" % curve)
	failed += _assert(is_equal_approx(idle, curve), "idle catch-up matches the 1x curve")
	var eight_hours: float = float(game_state.call("offline_effective_seconds", 1800.0 * 8.0))
	failed += _assert(not is_equal_approx(curve, eight_hours), "8x must not stretch the offline curve")
	var jobs: Node = tree_root.get_node_or_null("ForgeJobs")
	failed += _assert(jobs != null, "ForgeJobs for offline catch-up")
	if jobs != null:
		var off: Dictionary = jobs.call("apply_offline_seconds", 1800.0)
		failed += _assert(is_equal_approx(float(off.get("effective_sec", -1.0)), curve), "offline catch-up stays 1x at 8x")
		var fields: Dictionary = jobs.call("capture_save_fields")
		failed += _assert(not fields.has("play_speed"), "forge save has no play speed")
	var blob: Dictionary = game_state.call("to_save_dict")
	failed += _assert(not blob.has("play_speed"), "play speed is not in the save")
	failed += _assert(JSON.stringify(blob).find("play_speed") < 0, "save text has no play speed")
	game_audio.call("save_settings")
	var cfg := ConfigFile.new()
	var cfg_err: Error = cfg.load("user://manaforge_settings.cfg")
	failed += _assert(cfg_err == OK, "settings file loads")
	if cfg_err == OK:
		failed += _assert(not cfg.has_section_key("audio", "play_speed"), "settings do not store play speed")
	var title_src: String = FileAccess.get_file_as_string("res://scripts/title_screen.gd")
	var state_src: String = FileAccess.get_file_as_string("res://scripts/autoload/game_state.gd")
	var hud_src: String = FileAccess.get_file_as_string("res://scripts/hud.gd")
	failed += _assert(title_src.find("reset_play_speed()") >= 0, "title launch resets play speed")
	failed += _assert(state_src.find("reset_play_speed()") >= 0, "autoload launch resets play speed")
	failed += _assert(hud_src.find("[1, 2, 4, 8, 16]") >= 0, "debug speed still cycles to 16x")
	failed += _assert(bool(game_state.call("play_speed_in_stable")), "play speed ships in Stable")
	var stable_body: String = _func_body(state_src, "func play_speed_in_stable")
	failed += _assert(stable_body.find("manaforge") < 0, "stable inclusion is not feature-gated")
	var ensure_body: String = _func_body(hud_src, "func _ensure_play_speed_button")
	failed += _assert(ensure_body.find("PlaySpeedButton") >= 0, "HUD builds the play speed button")
	failed += _assert(ensure_body.find("manaforge") < 0, "play speed button is not stripped for Stable")
	var presets: Dictionary = _parse_export_presets(FileAccess.get_file_as_string("res://export_presets.cfg"))
	var stable: Dictionary = presets.get(_STABLE_PRESET, {}) as Dictionary
	var stable_exclude: PackedStringArray = _exclude_tokens(str(stable.get("exclude", "")))
	for shipped: String in ["scripts/hud.gd", "scenes/hud.tscn", "scripts/autoload/game_state.gd", "assets/art/ui/buttons/speed_1x_normal.png", "assets/art/ui/buttons/speed_8x_normal.png"]:
		failed += _assert(not _preset_excludes(stable_exclude, shipped), "stable ships %s" % shipped)
	var packed: PackedScene = load("res://scenes/hud.tscn") as PackedScene
	failed += _assert(packed != null, "hud scene")
	if packed != null:
		var hud: Node = packed.instantiate()
		tree_root.add_child(hud)
		await process_frame
		var btn: TextureButton = hud.find_child("PlaySpeedButton", true, false) as TextureButton
		failed += _assert(btn != null and btn.visible, "play speed button is on the HUD")
		if btn != null:
			failed += _assert(btn.tooltip_text == "8x", "button shows 8x (got %s)" % btn.tooltip_text)
			btn.pressed.emit()
			failed += _assert(int(game_state.get("play_speed")) == 1, "8x cycles back to 1x")
		var debug_btn: TextureButton = hud.find_child("SpeedButton", true, false) as TextureButton
		failed += _assert(debug_btn != null and debug_btn != btn, "debug speed button stays separate")
		hud.free()
	game_state.set("run_time_sec", run0)
	game_state.set("active_since_load_sec", idle0)
	game_state.call("reset_play_speed")
	save_service.set("session_active", session_was)
	Engine.time_scale = scale_was
	if failed == 0:
		print("SPEED_BUTTON_OK")
	return failed


func _func_body(source: String, signature: String) -> String:
	var at: int = source.find(signature)
	if at < 0:
		return ""
	var nxt: int = source.find("\nfunc ", at + signature.length())
	if nxt < 0:
		return source.substr(at)
	return source.substr(at, nxt - at)


func _preset_excludes(tokens: PackedStringArray, res_path: String) -> bool:
	var path: String = res_path.trim_prefix("res://")
	for token: String in tokens:
		if token == path:
			return true
		if token.begins_with("*."):
			if path.ends_with(token.substr(1)):
				return true
		elif token.ends_with("/*"):
			var prefix: String = token.trim_suffix("*")
			if path.begins_with(prefix):
				return true
	return false


func _reach_checks(tree_root: Window, game_state: Node, save_service: Node) -> int:
	## Idle d20 rooms, Push's 75% stop, Ascension memory, manual defeat, flat rewards.
	var failed: int = 0
	var reach: Node = tree_root.get_node_or_null("Reach")
	var pack: Node = tree_root.get_node_or_null("Backpack")
	failed += _assert(reach != null, "Reach autoload")
	failed += _assert(pack != null, "Backpack autoload")
	if reach == null or pack == null:
		return failed
	var session_was: bool = bool(save_service.get("session_active"))
	var scale_was: float = Engine.time_scale
	var speed_was: int = int(game_state.get("play_speed"))
	var echo_was: bool = bool(game_state.get("echo_02_resolved"))
	var essence_was: int = int(game_state.get("essence"))
	var lantern_was: String = str(game_state.get("expedition_lantern"))
	var fruit_was: bool = bool(game_state.get("fruit_committed"))
	var before_idle: int = failed
	reach.call("reset_for_new_game")
	failed += _assert(bool(reach.call("idle_clears", 1, 10)) == false, "natural 1 fails")
	failed += _assert(bool(reach.call("idle_clears", 20, -10)), "natural 20 clears")
	failed += _assert(bool(reach.call("idle_clears", 5, 0)) == false, "5 + 0 misses DC 6")
	failed += _assert(bool(reach.call("idle_clears", 6, 0)), "6 + 0 clears")
	failed += _assert(is_equal_approx(float(reach.call("clear_chance", 0)), 0.75), "bonus 0 is 75%")
	failed += _assert(is_equal_approx(float(reach.call("clear_chance", 3)), 0.90), "bonus +3 is 90%")
	var level1: float = float(reach.call("room_level", 1))
	failed += _assert(int(reach.call("idle_bonus", 5.2, level1)) == 0, "matched depth 1 bonus is 0")
	failed += _assert(int(reach.call("idle_bonus", 100.0, 1.0)) == 10, "bonus clamps at +10")
	failed += _assert(int(reach.call("idle_bonus", 0.0, 100.0)) == -10, "bonus clamps at -10")
	failed += _assert(str(reach.call("odds_line", 3)) == "Clear chance 90% (d20 +3 vs 6)", "odds line")
	reach.call("grant_salve", 1)
	reach.call("push_faces", [1, 20])
	failed += _assert(str(reach.call("depart", 1, 1, "hold", "idle")) == "ok", "idle depart")
	reach.call("advance_clock", 720.0)
	failed += _assert(int(reach.get("reaches_cleared")) == 1, "one salve reroll clears a natural 1")
	failed += _assert(int(pack.call("get_count", "heart_salve")) == 0, "the reroll drinks the salve")
	reach.call("reset_for_new_game")
	reach.call("grant_salve", 1)
	reach.call("push_faces", [1, 1])
	reach.call("depart", 1, 1, "hold", "idle")
	reach.call("advance_clock", 720.0)
	failed += _assert(int(reach.get("reaches_cleared")) == 0, "a second salve is not spent in the same room")
	failed += _assert(int(pack.call("get_count", "heart_salve")) == 0, "the one salve was the reroll")
	failed += _assert(int(pack.call("get_count", "briarwood")) == 0, "a failed room grants nothing")
	failed += _assert(str(reach.get("phase")) == "rest", "a failed roll rests")
	reach.call("reset_for_new_game")
	game_state.call("set_play_speed", 8)
	save_service.set("session_active", true)
	var scale_at_speed: float = Engine.time_scale
	reach.call("push_faces", [20])
	reach.call("push_drops", [1, 0])
	reach.call("depart", 1, 8, "hold", "idle")
	reach.call("apply_offline_seconds", 720.0)
	failed += _assert(int(reach.get("reaches_cleared")) == 1, "offline catch-up clears one room")
	failed += _assert(is_equal_approx(float(reach.get("elapsed")), 720.0), "offline room time stays 720s at 8x (got %s)" % str(reach.get("elapsed")))
	failed += _assert(is_equal_approx(Engine.time_scale, scale_at_speed), "reach catch-up leaves the debug time scale alone")
	game_state.call("reset_play_speed")
	save_service.set("session_active", session_was)
	if failed == before_idle:
		print("REACH_IDLE_ROLL_OK")
	var before_rest: int = failed
	reach.call("reset_for_new_game")
	reach.call("push_faces", [1])
	reach.call("depart", 1, 1, "hold", "idle")
	reach.call("advance_clock", 720.0)
	failed += _assert(int(reach.get("reaches_cleared")) == 0, "a natural 1 clears nothing")
	failed += _assert(int(pack.call("get_count", "briarwood")) == 0, "a natural 1 grants no briarwood")
	failed += _assert(str(reach.get("phase")) == "rest", "fail opens the 24 min rest")
	failed += _assert(is_equal_approx(float(reach.get("room_left")), 1440.0), "rest is 24 minutes")
	reach.call("advance_clock", 1440.0)
	failed += _assert(str(reach.get("phase")) == "idle_room", "rest opens the next room")
	failed += _assert(int(reach.get("depth")) == 1, "hold stays on the farmed depth")
	if failed == before_rest:
		print("REACH_FAIL_REST_OK")
	var before_push: int = failed
	reach.call("reset_for_new_game")
	reach.call("set_test_pp", 5.2)
	failed += _assert(float(reach.call("clear_chance", int(reach.call("preview_bonus", 1)))) >= 0.75, "depth 1 at matched power stays at 75% or better")
	failed += _assert(float(reach.call("clear_chance", int(reach.call("preview_bonus", 2)))) < 0.75, "depth 2 drops below 75%")
	reach.call("push_faces", [20])
	reach.call("depart", 1, 1, "push", "idle")
	reach.call("advance_clock", 720.0)
	failed += _assert(str(reach.get("pace")) == "hold", "push switches to hold")
	failed += _assert(int(reach.get("depth")) == 1, "push stops on the last safe depth")
	failed += _assert(int(reach.get("reaches_cleared")) == 1, "the safe room still counts")
	reach.call("set_test_pp", -1.0)
	if failed == before_push:
		print("REACH_PUSH_STOP_OK")
	var before_ascend: int = failed
	reach.call("reset_for_new_game")
	reach.set("deepest_depth", 7)
	failed += _assert(str(reach.call("depart", 3, 1, "hold", "idle")) == "ok", "depart an unlocked depth")
	failed += _assert(int(reach.get("depth")) == 3, "any unlocked depth can be farmed")
	reach.call("on_ascend")
	reach.set("reaches_cleared", 4)
	reach.set("dojo_exp", 100)
	reach.set("deepest_depth", 7)
	reach.call("depart", 7, 1, "hold", "idle")
	game_state.set("fruit_committed", true)
	game_state.call("ascend")
	failed += _assert(int(reach.get("deepest_depth")) == 7, "deepest depth survives ascension")
	failed += _assert(int(reach.get("reaches_cleared")) == 4, "the reach counter survives ascension")
	failed += _assert(int(reach.get("dojo_exp")) == 100, "dojo exp survives ascension")
	failed += _assert(bool(reach.get("running")) == false, "ascension cancels the outing")
	game_state.call("reset_for_new_game")
	failed += _assert(int(reach.get("deepest_depth")) == 0, "a new game clears deepest depth")
	failed += _assert(int(reach.get("reaches_cleared")) == 0, "a new game clears the reach counter")
	failed += _assert(int(reach.get("dojo_exp")) == 0, "a new game clears dojo exp")
	if failed == before_ascend:
		print("REACH_DEPTH_ASCEND_OK")
	var before_manual: int = failed
	reach.call("reset_for_new_game")
	var before_briar: int = int(pack.call("get_count", "briarwood"))
	reach.call("depart", 1, 1, "hold", "idle")
	reach.call("set_control", "manual")
	failed += _assert(bool(reach.call("fight_active")), "switching to manual opens the room's fight")
	reach.call("set_control", "idle")
	failed += _assert(bool(reach.call("fight_active")) == false, "switching back leaves the fight")
	failed += _assert(bool(reach.get("running")), "switching control keeps the outing")
	failed += _assert(int(pack.call("get_count", "briarwood")) == before_briar, "leaving a fight grants nothing")
	reach.call("reset_for_new_game")
	var briar_before: int = int(pack.call("get_count", "briarwood"))
	var clears_before: int = int(reach.get("reaches_cleared"))
	reach.call("depart", 1, 1, "hold", "manual")
	failed += _assert(bool(reach.call("fight_active")), "manual depart opens a fight")
	failed += _assert(int(ReachFightScript.road_damage(1.0, 10.0, 10.0, 0.0, 1.0)) == 5, "road damage is k*A^2/(A+D)")
	failed += _assert(str(reach.call("debug_wound", 10000)) == "defeat", "a lethal hit is a defeat")
	failed += _assert(bool(reach.get("running")) == false, "defeat ends the outing")
	failed += _assert(str(reach.get("phase")) == "home", "defeat returns to the trailhead")
	failed += _assert(is_equal_approx(float(reach.get("room_left")), 0.0), "defeat does not start a rest")
	failed += _assert(int(reach.get("reaches_cleared")) == clears_before, "defeat does not count a reach")
	failed += _assert(int(pack.call("get_count", "briarwood")) == briar_before, "defeat grants no briarwood")
	failed += _assert(str(game_state.get("expedition_lantern")) != "amber", "the lantern is no longer out")
	failed += _assert(ResourceLoader.exists("res://assets/art/echo/battle_root_snapper_idle.png"), "thornling art is packed")
	if failed == before_manual:
		print("REACH_MANUAL_DEFEAT_OK")
	var before_rewards: int = failed
	reach.call("reset_for_new_game")
	game_state.call("set_resource", &"essence", 40)
	reach.call("push_faces", [20])
	reach.call("push_drops", [1, 0])
	reach.call("depart", 1, 1, "hold", "idle")
	reach.call("advance_clock", 720.0)
	var exp1: int = int(reach.call("room_exp", 1))
	failed += _assert(int(pack.call("get_count", "briarwood")) == 1, "solo briarwood is the 0-1 roll")
	failed += _assert(int(pack.call("get_count", "herbs")) == 0, "herbs use the same 0-1 roll")
	failed += _assert(int(reach.get("dojo_exp")) == exp1, "exp goes to the dojo pool")
	failed += _assert(int(game_state.get("essence")) == 40, "a room grants no essence")
	reach.call("on_ascend")
	reach.set("deepest_depth", 11)
	var briar_deep: int = int(pack.call("get_count", "briarwood"))
	var herb_deep: int = int(pack.call("get_count", "herbs"))
	var dojo_deep: int = int(reach.get("dojo_exp"))
	reach.call("push_faces", [20])
	reach.call("push_drops", [1, 1])
	reach.call("depart", 11, 1, "hold", "idle")
	reach.call("advance_clock", 720.0)
	var exp11: int = int(reach.call("room_exp", 11))
	failed += _assert(int(pack.call("get_count", "briarwood")) == briar_deep + 1, "briarwood stays 0-1 at a deeper room")
	failed += _assert(int(pack.call("get_count", "herbs")) == herb_deep + 1, "herbs stay 0-1 at a deeper room")
	failed += _assert(int(reach.get("dojo_exp")) == dojo_deep + exp11, "deeper rooms pay their own exp")
	failed += _assert(exp11 != exp1, "exp changes with depth")
	failed += _assert(int(game_state.get("essence")) == 40, "a deep room grants no essence")
	if failed == before_rewards:
		print("REACH_REWARDS_OK")
	var before_boss: int = failed
	reach.call("reset_for_new_game")
	failed += _assert(str(reach.call("boss_line")) == "Rooms until boss: 10", "a new expedition is 10 rooms from a boss")
	reach.set("deepest_depth", 4)
	for _room: int in range(10):
		reach.call("push_faces", [20])
		reach.call("push_drops", [1, 0])
	reach.call("depart", 4, 4, "hold", "idle")
	failed += _assert(int(reach.get("rooms_attempted")) == 1, "depart counts the first room")
	failed += _assert(int(reach.call("rooms_until_boss")) == 9, "room 1 leaves 9 through the boss")
	failed += _assert(bool(reach.call("is_boss_room")) == false, "room 1 is not a boss")
	reach.call("advance_clock", 720.0 * 8.0)
	failed += _assert(int(reach.get("rooms_attempted")) == 9, "eight more clears reach room 9")
	failed += _assert(bool(reach.call("is_boss_room")) == false, "room 9 is not a boss")
	reach.call("advance_clock", 720.0)
	failed += _assert(int(reach.get("rooms_attempted")) == 10, "the next clear is room 10")
	failed += _assert(bool(reach.call("is_boss_room")), "room 10 is the boss")
	failed += _assert(str(reach.call("boss_line")) == "Boss room", "the board names the boss room")
	failed += _assert(int(reach.get("depth")) == 4, "the boss stays at the run's depth")
	var only_minion: Array[String] = ["minion"]
	reach.set("mix", only_minion)
	reach.call("set_control", "manual")
	var boss_snap: Dictionary = reach.call("fight_snapshot")
	var boss_rows: Array = boss_snap.get("enemies", []) as Array
	var boss_level: float = float(reach.call("room_level", 4))
	var champ_hp: int = int(round(float(int(round(2.9 * boss_level))) * 1.5))
	failed += _assert(boss_rows.size() == 1, "the boss check uses one minion")
	if boss_rows.size() == 1:
		var boss_row: Dictionary = boss_rows[0]
		failed += _assert(str(boss_row.get("name", "")).find("Champion") >= 0, "the first foe is the champion")
		failed += _assert(int(boss_row.get("max_hp", 0)) == champ_hp, "the champion has 50 percent more HP (got %s, want %d)" % [str(boss_row.get("max_hp", 0)), champ_hp])
	reach.call("set_control", "idle")
	var briar_before_boss: int = int(pack.call("get_count", "briarwood"))
	var dojo_before_boss: int = int(reach.get("dojo_exp"))
	var exp4: int = int(reach.call("room_exp", 4))
	reach.call("advance_clock", 720.0)
	failed += _assert(int(pack.call("get_count", "briarwood")) == briar_before_boss + 2, "the boss doubles the material roll")
	failed += _assert(int(reach.get("dojo_exp")) == dojo_before_boss + exp4 * 2, "the boss doubles dojo exp")
	reach.call("on_ascend")
	failed += _assert(int(reach.get("rooms_attempted")) == 0, "ending the expedition clears the room counter")
	failed += _assert(str(reach.call("boss_line")) == "Rooms until boss: 10", "the next expedition starts 10 rooms out")
	reach.set("deepest_depth", 10)
	reach.call("push_faces", [20])
	reach.call("push_drops", [1, 0])
	reach.call("depart", 10, 1, "hold", "idle")
	failed += _assert(bool(reach.call("is_boss_room")) == false, "depth 10's first room is not a boss")
	var briar_depth10: int = int(pack.call("get_count", "briarwood"))
	reach.call("advance_clock", 720.0)
	failed += _assert(int(pack.call("get_count", "briarwood")) == briar_depth10 + 1, "depth 10's first room pays a single drop")
	reach.call("reset_for_new_game")
	for _fail: int in range(9):
		reach.call("push_faces", [1])
	reach.call("push_faces", [20])
	reach.call("push_drops", [1, 0])
	reach.call("depart", 1, 8, "hold", "idle")
	reach.call("advance_clock", 720.0)
	failed += _assert(str(reach.get("phase")) == "rest", "a failed attempt still spends the room")
	failed += _assert(int(reach.get("rooms_attempted")) == 1, "a failed room counts")
	failed += _assert(int(pack.call("get_count", "briarwood")) == 0, "a failed boss-counter room grants nothing")
	reach.call("advance_clock", 1440.0 + 2160.0 * 8.0)
	failed += _assert(int(reach.get("rooms_attempted")) == 10, "nine failures make the next room the boss")
	failed += _assert(bool(reach.call("is_boss_room")), "the 10th attempt is the boss after failures")
	reach.call("advance_clock", 720.0)
	failed += _assert(int(pack.call("get_count", "briarwood")) == 2, "a boss clear after failures still doubles")
	reach.call("on_ascend")
	reach.call("push_faces", [20])
	reach.call("push_drops", [1, 0])
	reach.call("depart", 1, 1, "hold", "idle")
	failed += _assert(int(reach.get("rooms_attempted")) == 1 and bool(reach.call("is_boss_room")) == false, "a new expedition does not inherit the boss counter")
	if failed == before_boss:
		print("REACH_BOSS_ROOM_OK")
	var before_mig: int = failed
	var migrated: Variant = save_service.call("_migrate", 11, {"wood": 3, "stage_id": "sapling"})
	failed += _assert(migrated is Dictionary, "v11 migration returns a state")
	if migrated is Dictionary:
		var state: Dictionary = migrated
		var reach_block: Variant = state.get("reach", null)
		failed += _assert(reach_block is Dictionary, "a v11 save gains a reach block")
		if reach_block is Dictionary:
			var block: Dictionary = reach_block
			failed += _assert(int(block.get("reaches_cleared", -1)) == 0, "migrated reaches start at 0")
			failed += _assert(int(block.get("deepest_depth", -1)) == 0, "migrated depth starts at 0")
			failed += _assert(bool(block.get("running", true)) == false, "migration does not send the party out")
			failed += _assert(int(block.get("rooms_attempted", -1)) == 0, "a v11 save starts with no rooms attempted")
	var kept: Variant = save_service.call("_migrate", 12, {"wood": 1, "stage_id": "sapling", "reach": {"reaches_cleared": 9, "deepest_depth": 4, "running": false}})
	if kept is Dictionary:
		var kept_reach: Variant = (kept as Dictionary).get("reach", {})
		if kept_reach is Dictionary:
			failed += _assert(int((kept_reach as Dictionary).get("reaches_cleared", -1)) == 9, "a v12 reach block is kept")
			failed += _assert(int((kept_reach as Dictionary).get("rooms_attempted", -1)) == 0, "a finished v12 run gains a zero room counter")
	var mid_run: Variant = save_service.call("_migrate", 12, {"wood": 1, "stage_id": "sapling", "reach": {"reaches_cleared": 2, "running": true, "phase": "idle_room"}})
	if mid_run is Dictionary:
		var mid_reach: Variant = (mid_run as Dictionary).get("reach", {})
		if mid_reach is Dictionary:
			failed += _assert(int((mid_reach as Dictionary).get("rooms_attempted", -1)) == 1, "an in-progress v12 room counts as the first attempt")
	failed += _assert(int(save_service.get("SAVE_VERSION")) == 14, "saves write version 14")
	var project_text: String = FileAccess.get_file_as_string("res://project.godot")
	failed += _assert(project_text.find("Reach=\"*res://scripts/autoload/reach.gd\"") >= 0, "Reach autoload is registered")
	var presets: Dictionary = _parse_export_presets(FileAccess.get_file_as_string("res://export_presets.cfg"))
	var stable: Dictionary = presets.get(_STABLE_PRESET, {}) as Dictionary
	var stable_exclude: PackedStringArray = _exclude_tokens(str(stable.get("exclude", "")))
	for shipped: String in ["scripts/autoload/reach.gd", "scripts/reach_fight.gd", "scripts/reach_fight_view.gd", "scripts/expedition_board.gd"]:
		failed += _assert(not _preset_excludes(stable_exclude, shipped), "stable ships %s" % shipped)
	if failed == before_mig:
		print("REACH_MIGRATION_OK")
	var before_board: int = failed
	reach.call("reset_for_new_game")
	game_state.set("echo_02_resolved", true)
	var packed: PackedScene = load("res://scenes/expedition_board.tscn") as PackedScene
	failed += _assert(packed != null, "expedition board scene")
	if packed != null:
		var board: Node = packed.instantiate()
		tree_root.add_child(board)
		board.call("open_shell")
		failed += _assert(bool(board.call("depart_disabled")) == false, "Depart is enabled once the road is open")
		var shell: Node = tree_root.get_node_or_null("ExpeditionShell")
		var odds: Label = shell.find_child("Odds", true, false) as Label if shell != null else null
		failed += _assert(odds != null and str(odds.text).find("Clear chance") >= 0 and str(odds.text).find("vs 6") >= 0, "the board shows per-room odds")
		failed += _assert(odds != null and str(odds.text).find("Rooms until boss: 10") >= 0, "the board shows rooms until boss")
		var hours_btn: Button = shell.find_child("Hours", true, false) as Button if shell != null else null
		failed += _assert(hours_btn != null and hours_btn.text == "1 hour", "length starts at 1 hour")
		failed += _assert(str(board.call("try_depart")) == "ok", "Depart starts the reach")
		failed += _assert(bool(reach.get("running")), "the party is out")
		failed += _assert(str(game_state.get("expedition_lantern")) == "amber", "the lantern shows a run out")
		board.free()
		shell = tree_root.get_node_or_null("ExpeditionShell")
		if shell != null and is_instance_valid(shell):
			shell.free()
	reach.call("reset_for_new_game")
	if failed == before_board:
		print("REACH_BOARD_OK")
	reach.call("set_test_pp", -1.0)
	reach.call("reset_for_new_game")
	if speed_was == 1:
		game_state.call("reset_play_speed")
	else:
		game_state.call("set_play_speed", speed_was)
	save_service.set("session_active", session_was)
	Engine.time_scale = scale_was
	game_state.set("echo_02_resolved", echo_was)
	game_state.set("fruit_committed", fruit_was)
	game_state.call("set_resource", &"essence", essence_was)
	game_state.set("expedition_lantern", lantern_was)
	return failed



func _reach_mix_reload(tree_root: Window, game_state: Node, save_service: Node) -> int:
	## Haex bug: a mid-run save lost the room's beasts, so Join manual after a load opened an
	## empty fight and the first Strike won it for free. The mix is saved, an old save rerolls
	## it, and a fight never starts or wins with no beasts.
	var failed: int = 0
	var reach: Node = tree_root.get_node_or_null("Reach")
	failed += _assert(reach != null, "Reach autoload for the mix reload")
	if reach == null:
		return failed
	var session_was: bool = bool(save_service.get("session_active"))
	var lantern_was: String = str(game_state.get("expedition_lantern"))
	reach.call("reset_for_new_game")
	failed += _assert(str(reach.call("depart", 1, 1, "hold", "idle")) == "ok", "mix reload: idle depart")
	var picked: Array[String] = ["brute", "minion"]
	reach.set("mix", picked.duplicate())
	failed += _assert(bool(save_service.call("save_game", 7)), "mix reload: save mid-run to slot 7")
	reach.call("reset_for_new_game")
	failed += _assert((reach.get("mix") as Array).is_empty(), "mix reload: reset clears the mix")
	failed += _assert(bool(save_service.call("load_game", 7)), "mix reload: load slot 7")
	failed += _assert(bool(reach.get("running")) and str(reach.get("phase")) == "idle_room", "mix reload: the run is still out")
	var loaded_mix: Array = reach.get("mix") as Array
	failed += _assert(str(loaded_mix) == str(picked), "mix reload: the room keeps its beasts (got %s)" % str(loaded_mix))
	reach.call("set_control", "manual")
	failed += _assert(bool(reach.call("fight_active")), "mix reload: Join manual opens the fight")
	var snap: Dictionary = reach.call("fight_snapshot")
	failed += _assert((snap.get("enemies", []) as Array).size() == 2, "mix reload: Join manual shows both beasts")
	var first: String = str(reach.call("fight_choose", "strike", 0))
	failed += _assert(first != "victory", "mix reload: the first Strike does not win the room (got %s)" % first)
	failed += _assert(bool(reach.get("running")), "mix reload: the run continues after one Strike")
	# An older save without the mix field rerolls a real room instead of an empty one.
	reach.call("set_control", "idle")
	var blob: Dictionary = game_state.call("to_save_dict")
	var reach_blob: Dictionary = (blob.get("reach", {}) as Dictionary).duplicate(true)
	reach_blob.erase("mix")
	blob["reach"] = reach_blob
	reach.call("reset_for_new_game")
	game_state.call("apply_save_dict", blob)
	failed += _assert(not (reach.get("mix") as Array).is_empty(), "mix reload: a save without a mix rerolls one")
	reach.call("set_control", "manual")
	var old_snap: Dictionary = reach.call("fight_snapshot")
	failed += _assert((old_snap.get("enemies", []) as Array).size() >= 1, "mix reload: the rerolled room has beasts")
	failed += _assert(str(reach.call("fight_choose", "strike", 0)) != "victory", "mix reload: no free win after an old load")
	# The fight itself refuses an empty room.
	var empty_fight: RefCounted = ReachFightScript.new()
	empty_fight.call("setup", 1, 5.2, {"vitality": 5, "swiftness": 5, "offense": 10.0}, [], -1, {}, {})
	failed += _assert(str(empty_fight.call("choose", "strike", 0)) == "invalid", "an empty fight refuses a Strike")
	failed += _assert(str(empty_fight.get("outcome")) == "", "an empty fight is never a victory")
	reach.call("reset_for_new_game")
	save_service.call("delete_slot", 7)
	save_service.set("session_active", session_was)
	game_state.set("expedition_lantern", lantern_was)
	if failed == 0:
		print("REACH_MIX_RELOAD_OK")
	return failed


func _save_newer_refused(tree_root: Window, game_state: Node, save_service: Node) -> int:
	## A build never loads a save newer than its own version (unknown fields would be lost),
	## says why, skips it for Continue, and never rotates an autosave over it.
	var failed: int = 0
	var version: int = int(save_service.get("SAVE_VERSION"))
	failed += _assert(int(save_service.get("SAVE_VERSION_MAX_READ")) == version, "the read cap equals SAVE_VERSION")
	var wood_was: int = int(game_state.get("wood"))
	var newer_root: Dictionary = {
		"save_version": version + 1,
		"timestamp": Time.get_unix_time_from_system() + 100000.0,
		"slot": 7,
		"kind": "manual",
		"state": {"wood": 987654, "stage_id": "sapling", "future_field": {"pack": {"briarwood": 3}}},
	}
	var slot_file: String = str(save_service.call("slot_path", 7))
	var fh := FileAccess.open(slot_file, FileAccess.WRITE)
	fh.store_string(JSON.stringify(newer_root))
	fh.close()
	var info: Dictionary = save_service.call("get_slot_info", 7)
	failed += _assert(bool(info.get("newer", false)), "slot info flags the newer save")
	var record: Dictionary = save_service.call("get_most_recent_record")
	failed += _assert(str(record.get("path", "")) != slot_file, "Continue skips a save from a newer build")
	failed += _assert(not bool(save_service.call("load_game", 7)), "a newer save is refused")
	failed += _assert(int(game_state.get("wood")) == wood_was, "a refused load leaves the game untouched")
	var why: String = str(save_service.get("last_load_error"))
	failed += _assert(why.find("v%d" % (version + 1)) >= 0 and why.find("newer") >= 0, "the refusal says why (got %s)" % why)
	failed += _assert(str(tree_root.get_node("ContentStrings").call("get_text", "save_newer_build")).find("{found}") >= 0, "save_newer_build string")
	save_service.call("delete_slot", 7)
	# Autosave rotation never writes over a newer build's autosave.
	var backups: Dictionary = {}
	for slot: int in range(1, 4):
		var path: String = str(save_service.call("autosave_path", slot))
		backups[path] = FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else null
		var newer_auto: Dictionary = newer_root.duplicate(true)
		newer_auto["slot"] = slot
		newer_auto["kind"] = "autosave"
		var ah := FileAccess.open(path, FileAccess.WRITE)
		ah.store_string(JSON.stringify(newer_auto))
		ah.close()
	var session_was: bool = bool(save_service.get("session_active"))
	save_service.set("session_active", true)
	failed += _assert(int(save_service.call("_next_autosave_slot")) == 0, "no autosave slot is writable over newer saves")
	failed += _assert(not bool(save_service.call("save_autosave", true)), "autosave refuses to overwrite newer saves")
	for path: String in backups.keys():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		failed += _assert(typeof(parsed) == TYPE_DICTIONARY and int((parsed as Dictionary).get("save_version", 0)) == version + 1, "newer autosave kept %s" % path)
		if backups[path] == null:
			DirAccess.remove_absolute(path)
		else:
			var rh := FileAccess.open(path, FileAccess.WRITE)
			rh.store_string(str(backups[path]))
			rh.close()
	save_service.set("session_active", session_was)
	save_service.call("debug_set_last_autosave_age", 0.0)
	if failed == 0:
		print("SAVE_NEWER_REFUSED_OK")
	return failed


func _reach_turn_order() -> int:
	## Turn order is a total order: Swiftness first, the keeper wins ties, then slot. sort_custom is not
	## stable, so a big room of equal-speed foes must still come out in slot order every time.
	var failed: int = 0
	var fight: RefCounted = ReachFightScript.new()
	fight.call("setup", 1, 5.0, {"vitality": 5, "swiftness": 5, "offense": 10.0}, ["minion"], -1, {}, {})
	var rows: Array[Dictionary] = []
	for i: int in range(24):
		var row: Dictionary = (fight.get("enemies") as Array)[0].duplicate()
		row["swift"] = 5.0
		row["hp"] = 10
		rows.append(row)
	rows[20]["swift"] = 9.0
	rows[3]["swift"] = 1.0
	fight.set("enemies", rows)
	var keeper: Dictionary = fight.get("keeper")
	keeper["swiftness"] = 5
	fight.set("keeper", keeper)
	for _attempt: int in range(5):
		var order: Array = fight.call("_turn_order")
		failed += _assert(order.size() == 25, "turn order lists the keeper and 24 foes")
		if order.size() != 25:
			break
		failed += _assert(str((order[0] as Dictionary).get("side")) == "foe" and int((order[0] as Dictionary).get("index")) == 20, "the fastest foe acts first")
		failed += _assert(str((order[1] as Dictionary).get("side")) == "keeper", "the keeper wins the Swiftness tie")
		var want: Array[int] = []
		for i: int in range(24):
			if i != 20 and i != 3:
				want.append(i)
		var got: Array[int] = []
		for k: int in range(2, 24):
			got.append(int((order[k] as Dictionary).get("index")))
		failed += _assert(str(got) == str(want), "tied foes act in slot order (got %s)" % str(got))
		failed += _assert(int((order[24] as Dictionary).get("index")) == 3, "the slowest foe acts last")
	# Float noise on Swiftness is still a tie that goes to the keeper.
	rows = []
	for i: int in range(3):
		var r2: Dictionary = (fight.get("enemies") as Array)[0].duplicate()
		r2["swift"] = 5.0000001
		rows.append(r2)
	fight.set("enemies", rows)
	var near: Array = fight.call("_turn_order")
	failed += _assert(near.size() == 4 and str((near[0] as Dictionary).get("side")) == "keeper", "float noise still ties to the keeper")
	if failed == 0:
		print("REACH_TURN_ORDER_OK")
	return failed


func _debug_snapshots_migrate(tree_root: Window, game_state: Node, save_service: Node) -> int:
	## Every debug snapshot loads through SaveService migration, the same path as a slot load.
	## An old snapshot gains the fields its migration adds; a newer one is refused.
	var failed: int = 0
	var panel_script: Script = load("res://tools/debug/debug_panel.gd") as Script
	failed += _assert(panel_script != null, "debug panel script loads")
	if panel_script == null:
		return failed
	var panel_src: String = FileAccess.get_file_as_string("res://tools/debug/debug_panel.gd")
	var press_body: String = _func_body(panel_src, "func _on_snapshot_pressed")
	failed += _assert(press_body.find("load_snapshot_state(") >= 0, "the snapshot button uses the migrating loader")
	failed += _assert(_func_body(panel_src, "static func load_snapshot_state").find("migrate_state") >= 0, "the loader calls SaveService.migrate_state")
	var snapshots: Dictionary = panel_script.get_script_constant_map().get("SNAPSHOTS", {}) as Dictionary
	failed += _assert(snapshots.size() == 8, "eight debug snapshots (got %d)" % snapshots.size())
	for label: String in snapshots.keys():
		var path: String = str(snapshots[label])
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		var raw_state: Dictionary = (raw as Dictionary).get("state", {}) as Dictionary if typeof(raw) == TYPE_DICTIONARY else {}
		var raw_version: int = int((raw as Dictionary).get("save_version", 0)) if typeof(raw) == TYPE_DICTIONARY else 0
		var loaded: Dictionary = panel_script.call("load_snapshot_state", path)
		var state: Dictionary = loaded.get("state", {}) as Dictionary
		failed += _assert(not state.is_empty(), "%s migrates (%s)" % [label, str(loaded.get("error", ""))])
		if state.is_empty():
			continue
		var reach_v: Variant = state.get("reach", null)
		failed += _assert(reach_v is Dictionary and (reach_v as Dictionary).has("rooms_attempted"), "%s has a current reach block" % label)
		if raw_version < 12:
			failed += _assert(not raw_state.has("reach"), "%s file is an old schema (no reach block)" % label)
		game_state.call("reset_for_new_game")
		game_state.call("apply_save_dict", state)
	var newer_path: String = "user://verify_newer_snapshot.json"
	var nh := FileAccess.open(newer_path, FileAccess.WRITE)
	nh.store_string(JSON.stringify({"save_version": int(save_service.get("SAVE_VERSION")) + 1, "state": {"wood": 1}}))
	nh.close()
	var refused: Dictionary = panel_script.call("load_snapshot_state", newer_path)
	failed += _assert((refused.get("state", {}) as Dictionary).is_empty(), "a newer snapshot is refused")
	failed += _assert(str(refused.get("error", "")).find("newer") >= 0, "the refusal names the newer build")
	DirAccess.remove_absolute(newer_path)
	game_state.call("reset_for_new_game")
	if failed == 0:
		print("DEBUG_SNAPSHOTS_MIGRATE_OK")
	return failed


func _json_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary if parsed is Dictionary else {}


func _half_up(x: float) -> int:
	## The battle draft rounds half up. Values here are never negative.
	return floori(x + 0.5 + 0.000001)


func _beast_threat(row: Dictionary, rule: Dictionary) -> Dictionary:
	## Recompute a beast's roles and threat from its stats with the §10 rule in beasts.json.
	var raw: int = 0
	for stat_v: Variant in rule.get("stats", []) as Array:
		raw += int(row.get(str(stat_v), 0)) * int(rule.get("per_stat_point", 1))
	var roles: Array[String] = ["damage"]
	var vit: int = int(row.get("vitality", 0))
	var res_ward: float = float(int(row.get("resilience", 0)) + int(row.get("ward", 0))) / 2.0
	if vit >= 12 or res_ward >= 8.0:
		roles.append("tank")
	var move: Variant = row.get("move", null)
	if move is Dictionary:
		var kind: String = str((move as Dictionary).get("kind", ""))
		var level: int = 1
		if kind == "poison":
			level = maxi(1, _half_up(float((move as Dictionary).get("total", 0)) / 6.0))
			roles.append("utility")
		elif kind == "heavy":
			level = maxi(1, _half_up(float((move as Dictionary).get("mult", 0.0))))
		raw += int(rule.get("move_base", 5)) + level
	var mult: float = pow(float(rule.get("role_mult", 1.1)), roles.size() - 1)
	return {"threat": maxi(1, _half_up(float(raw) * mult)), "roles": roles}


func _beast_data(_tree_root: Window) -> int:
	## data/beasts.json carries the BATTLE_SCENE_DRAFT v4 §10 table. Threat recomputes to the table,
	## HP is 10 + 3 x Vitality, the dark imp and moth follow the tier-1 variant rule, and every name
	## has a string. Briar Warden is now Briar Hulk.
	var failed: int = 0
	var path: String = "res://data/beasts.json"
	var data: Dictionary = _json_dict(path)
	failed += _assert(not data.is_empty(), "beasts.json parses")
	if data.is_empty():
		return failed
	var strings: Dictionary = _json_dict("res://data/strings_v01.json")
	var rule: Dictionary = data.get("threat_rule", {}) as Dictionary
	var hp_rule: Dictionary = data.get("hp_rule", {}) as Dictionary
	# The §10 table, as Haex reviewed it: id -> [tier, from depth, threat, hp].
	var table: Dictionary = {
		"acorn_imp": [1, 1, 33, 37], "spore_moth": [1, 1, 45, 40],
		"wilt_wisp": [2, 3, 47, 40], "root_snapper": [2, 3, 46, 43],
		"thorn_boar": [3, 12, 54, 46], "vine_serpent": [3, 12, 58, 43],
		"briar_hulk": [4, 18, 61, 49], "moss_brute": [4, 18, 63, 52],
		"stump_ogre": [5, 22, 67, 55], "stag_spirit": [5, 22, 74, 52],
	}
	var by_id: Dictionary = {}
	var species: Array = data.get("species", []) as Array
	failed += _assert(species.size() == table.size(), "beasts.json lists the ten §10 species (got %d)" % species.size())
	for row_v: Variant in species:
		var row: Dictionary = row_v as Dictionary
		var bid: String = str(row.get("id", ""))
		by_id[bid] = row
		failed += _assert(table.has(bid), "known species id %s" % bid)
		if not table.has(bid):
			continue
		var want: Array = table[bid]
		failed += _assert(int(row.get("tier", 0)) == int(want[0]) and int(row.get("from_depth", 0)) == int(want[1]), "%s tier and first depth" % bid)
		failed += _assert(int(row.get("threat", 0)) == int(want[2]), "%s threat is the table's %d" % [bid, int(want[2])])
		failed += _assert(int(row.get("hp", 0)) == int(want[3]), "%s HP is the table's %d" % [bid, int(want[3])])
		failed += _assert(int(row.get("hp", 0)) == int(hp_rule.get("base", 10)) + int(hp_rule.get("per_vitality", 3)) * int(row.get("vitality", 0)), "%s HP = 10 + 3 x Vitality" % bid)
		failed += _assert(int(row.get("fate", -1)) == 0, "%s has Fate 0" % bid)
		failed += _assert(["physical", "magic"].has(str(row.get("attack", ""))), "%s attack type" % bid)
		var re: Dictionary = _beast_threat(row, rule)
		failed += _assert(int(re["threat"]) == int(row.get("threat", 0)), "%s threat recomputes (%d vs %d)" % [bid, int(re["threat"]), int(row.get("threat", 0))])
		failed += _assert(str(re["roles"]) == str(row.get("roles", [])), "%s roles recompute" % bid)
		failed += _assert(strings.has(str(row.get("name_key", ""))), "%s name string" % bid)
	failed += _assert(str((by_id.get("briar_hulk", {}) as Dictionary).get("name", "")) == "Briar Hulk", "Briar Hulk is the name")
	failed += _assert(FileAccess.get_file_as_string(path).to_lower().find("warden") < 0, "no Briar Warden left in beasts.json")
	# Variants: tier 1 is about +30% (at least +1), poison x1.3 (at least +2). Others +50% / +2.
	var vrule: Dictionary = data.get("variant_rule", {}) as Dictionary
	var dark_want: Dictionary = {"acorn_imp_dark": [48, 46, 5], "spore_moth_dark": [62, 49, 5]}
	var variants: Array = data.get("variants", []) as Array
	failed += _assert(variants.size() == dark_want.size(), "two dark variants by depth 15 (got %d)" % variants.size())
	for var_v: Variant in variants:
		var vrow: Dictionary = var_v as Dictionary
		var vid: String = str(vrow.get("id", ""))
		var base: Dictionary = by_id.get(str(vrow.get("variant_of", "")), {}) as Dictionary
		failed += _assert(not base.is_empty() and dark_want.has(vid), "variant %s has a known base" % vid)
		if base.is_empty() or not dark_want.has(vid):
			continue
		var tier_rule: Dictionary = (vrule.get("tier_1", {}) if int(base.get("tier", 0)) == 1 else vrule.get("default", {})) as Dictionary
		for stat_v: Variant in vrule.get("stats", []) as Array:
			var b: int = int(base.get(str(stat_v), 0))
			var want_stat: int = maxi(b + int(tier_rule.get("stat_min_add", 0)), _half_up(float(b) * float(tier_rule.get("stat_mult", 1.0))))
			failed += _assert(int(vrow.get(str(stat_v), 0)) == want_stat, "%s %s follows the variant rule" % [vid, str(stat_v)])
		var bmove: Variant = base.get("move", null)
		if bmove is Dictionary and str((bmove as Dictionary).get("kind", "")) == "poison":
			var bt: int = int((bmove as Dictionary).get("total", 0))
			var want_p: int = maxi(bt + int(tier_rule.get("poison_min_add", 0)), _half_up(float(bt) * float(tier_rule.get("poison_mult", 1.0))))
			failed += _assert(int(((vrow.get("move", {}) as Dictionary)).get("total", 0)) == want_p, "%s poison follows the variant rule" % vid)
		failed += _assert(int(_beast_threat(vrow, rule)["threat"]) == int(vrow.get("threat", 0)), "%s threat recomputes" % vid)
		failed += _assert(int(vrow.get("threat", 0)) == int(dark_want[vid][0]) and int(vrow.get("hp", 0)) == int(dark_want[vid][1]), "%s matches the §10 note" % vid)
		failed += _assert(int(vrow.get("from_depth", 0)) == int(dark_want[vid][2]), "%s first spawns at depth 5" % vid)
		failed += _assert(strings.has(str(vrow.get("name_key", ""))), "%s name string" % vid)
	# Resolver fixtures (job 8): exported from the poison-refresh sim, and the §4 example uses this imp.
	var cases: Dictionary = _json_dict("res://tests/fixtures/resolver_cases.json")
	failed += _assert(not cases.is_empty(), "tests/fixtures/resolver_cases.json parses")
	if not cases.is_empty():
		failed += _assert(str((cases.get("source", {}) as Dictionary).get("poison", "")).begins_with("refresh"), "fixtures come from the poison-refresh sim")
		var imp: Dictionary = by_id.get("acorn_imp", {}) as Dictionary
		var seen_example: bool = false
		for case_v: Variant in cases.get("strikes", []) as Array:
			var c: Dictionary = case_v as Dictionary
			var ex: Dictionary = c.get("expect", {}) as Dictionary
			failed += _assert(ex.has("band") and ex.has("damage") and ex.has("margin"), "fixture %s has an expected result" % str(c.get("id", "")))
			if str(c.get("id", "")) == "s4_line1":
				seen_example = true
				var d: Dictionary = c.get("defender", {}) as Dictionary
				failed += _assert(int(d.get("mig", 0)) == int(imp.get("might", -1)) and int(d.get("res", 0)) == int(imp.get("resilience", -1)) and int(d.get("hp", 0)) == int(imp.get("hp", -1)), "the §4 example imp matches beasts.json")
				failed += _assert(str(ex.get("band", "")) == "crush" and int(ex.get("damage", 0)) == 24, "the §4 example opens with a crushing blow for 24")
		failed += _assert(seen_example, "the §4 worked example is in the fixtures")
		var one_poison: bool = true
		for step_v: Variant in cases.get("poison_refresh", []) as Array:
			if ((step_v as Dictionary).get("ticks_left", []) as Array).size() > 3:
				one_poison = false
		failed += _assert(one_poison and (cases.get("poison_refresh", []) as Array).size() > 0, "fixture poison never stacks past one 3-tick poison")
	if failed == 0:
		print("BEAST_DATA_OK")
	return failed


func _room_budget(depth: int, budget: Dictionary) -> int:
	if depth <= 10:
		return int(budget.get("base", 0)) + int(budget.get("per_depth_to_10", 0)) * (depth - 1)
	return int(budget.get("at_10", 0)) + int(budget.get("per_depth_after_10", 0)) * (depth - 10)


func _spawn_table_for(depth: int, tables: Array) -> Array:
	## The latest table at or below the depth.
	var best: Array = []
	for t_v: Variant in tables:
		var t: Dictionary = t_v as Dictionary
		if int(t.get("depth", 0)) <= depth:
			best = t.get("weights", []) as Array
	return best


func _room_compositions(pool: Array[Dictionary], budget: int, max_beasts: int) -> Array[String]:
	## Distinct maximal rooms: nothing else fits, or the room is full. Same rule as compositions().
	var found: Dictionary = {}
	_room_rec(pool, budget, max_beasts, 0, [], 0, found)
	var keys: Array[String] = []
	for k: Variant in found.keys():
		keys.append(str(k))
	keys.sort()
	return keys


func _room_rec(pool: Array[Dictionary], budget: int, max_beasts: int, start: int, chosen: Array, total: int, found: Dictionary) -> void:
	var rem: int = budget - total
	if not chosen.is_empty():
		var nothing_fits: bool = true
		for b: Dictionary in pool:
			if int(b["threat"]) <= rem:
				nothing_fits = false
		if chosen.size() == max_beasts or nothing_fits:
			var ids: Array = chosen.duplicate()
			ids.sort()
			found[",".join(PackedStringArray(ids))] = true
			return
	for i: int in range(start, pool.size()):
		var b: Dictionary = pool[i]
		if total + int(b["threat"]) <= budget:
			var next: Array = chosen.duplicate()
			next.append(str(b["id"]))
			_room_rec(pool, budget, max_beasts, i, next, total + int(b["threat"]), found)


func _spawn_data(_tree_root: Window) -> int:
	## data/spawn_tables.json carries the §10 budget curve and per-depth weights. Every beast exists and
	## may spawn at that depth, the room counts match the draft, and Amberbind is never a bonus drop.
	var failed: int = 0
	var data: Dictionary = _json_dict("res://data/spawn_tables.json")
	var beasts: Dictionary = _json_dict("res://data/beasts.json")
	failed += _assert(not data.is_empty() and not beasts.is_empty(), "spawn_tables.json and beasts.json parse")
	if data.is_empty() or beasts.is_empty():
		return failed
	var by_id: Dictionary = {}
	for row_v: Variant in (beasts.get("species", []) as Array) + (beasts.get("variants", []) as Array):
		by_id[str((row_v as Dictionary).get("id", ""))] = row_v
	var budget: Dictionary = data.get("budget", {}) as Dictionary
	var fill: Dictionary = data.get("fill", {}) as Dictionary
	var max_beasts: int = int(fill.get("max_beasts", 0))
	failed += _assert(max_beasts == 6, "rooms hold up to 6 beasts")
	failed += _assert(is_equal_approx(float(fill.get("variety_bias", 0.0)), 2.0), "variety bias x2")
	# The §10 table: depth -> [budget, weights, different rooms].
	var want: Dictionary = {
		1: [90, "acorn_imp:1,spore_moth:1", 3],
		3: [94, "acorn_imp:8,spore_moth:8,wilt_wisp:1,root_snapper:1", 10],
		5: [98, "acorn_imp:12,spore_moth:12,wilt_wisp:4,root_snapper:4,acorn_imp_dark:1,spore_moth_dark:1", 16],
		8: [104, "acorn_imp:4,spore_moth:4,wilt_wisp:6,root_snapper:6,acorn_imp_dark:1,spore_moth_dark:1", 16],
		10: [108, "acorn_imp:2,spore_moth:2,wilt_wisp:6,root_snapper:6,acorn_imp_dark:2,spore_moth_dark:1", 18],
		12: [120, "wilt_wisp:4,root_snapper:4,acorn_imp_dark:2,spore_moth_dark:1,thorn_boar:1,vine_serpent:1", 20],
		15: [138, "wilt_wisp:3,root_snapper:3,acorn_imp_dark:2,spore_moth_dark:2,thorn_boar:2,vine_serpent:2", 21],
	}
	var tables: Array = data.get("tables", []) as Array
	failed += _assert(tables.size() == want.size(), "seven spawn tables (got %d)" % tables.size())
	var last_depth: int = 0
	for t_v: Variant in tables:
		var t: Dictionary = t_v as Dictionary
		var depth: int = int(t.get("depth", 0))
		failed += _assert(depth > last_depth, "tables are in depth order (%d)" % depth)
		last_depth = depth
		failed += _assert(want.has(depth), "table at depth %d is in the draft" % depth)
		if not want.has(depth):
			continue
		var b: int = _room_budget(depth, budget)
		failed += _assert(b == int(want[depth][0]), "budget at depth %d is %d (got %d)" % [depth, int(want[depth][0]), b])
		var parts: PackedStringArray = []
		var pool: Array[Dictionary] = []
		var cheapest: int = 1 << 30
		for w_v: Variant in t.get("weights", []) as Array:
			var w: Dictionary = w_v as Dictionary
			var bid: String = str(w.get("beast", ""))
			parts.append("%s:%d" % [bid, int(w.get("weight", 0))])
			failed += _assert(int(w.get("weight", 0)) > 0, "depth %d weight for %s is positive" % [depth, bid])
			failed += _assert(by_id.has(bid), "depth %d beast %s is in beasts.json" % [depth, bid])
			if not by_id.has(bid):
				continue
			var row: Dictionary = by_id[bid]
			failed += _assert(int(row.get("from_depth", 99)) <= depth, "%s may spawn at depth %d" % [bid, depth])
			cheapest = mini(cheapest, int(row.get("threat", 0)))
			pool.append({"id": bid, "threat": int(row.get("threat", 0))})
		failed += _assert(",".join(parts) == str(want[depth][1]), "depth %d weights match the draft (%s)" % [depth, ",".join(parts)])
		failed += _assert(cheapest <= b, "a beast fits the depth %d budget" % depth)
		var rooms: Array[String] = _room_compositions(pool, b, max_beasts)
		failed += _assert(rooms.size() == int(want[depth][2]), "depth %d has %d different rooms (got %d)" % [depth, int(want[depth][2]), rooms.size()])
	# Spawn-roller oracle (job 8): the sim's compositions() per depth match this data exactly.
	var comps: Dictionary = _json_dict("res://tests/fixtures/resolver_compositions.json")
	failed += _assert(not comps.is_empty() and (comps.get("depths", []) as Array).size() >= 7, "tests/fixtures/resolver_compositions.json parses")
	for dep_v: Variant in comps.get("depths", []) as Array:
		var dep: Dictionary = dep_v as Dictionary
		var depth: int = int(dep.get("depth", 0))
		var b: int = _room_budget(depth, budget)
		failed += _assert(b == int(dep.get("budget", -1)), "fixture budget at depth %d" % depth)
		var pool: Array[Dictionary] = []
		for w_v: Variant in _spawn_table_for(depth, tables):
			var bid: String = str((w_v as Dictionary).get("beast", ""))
			pool.append({"id": bid, "threat": int((by_id.get(bid, {}) as Dictionary).get("threat", 0))})
		var mine: Array[String] = _room_compositions(pool, b, max_beasts)
		var theirs: Array[String] = []
		for room_v: Variant in dep.get("rooms", []) as Array:
			theirs.append(",".join(PackedStringArray((room_v as Dictionary).get("beasts", []) as Array)))
		theirs.sort()
		failed += _assert(str(mine) == str(theirs) and int(dep.get("count", -1)) == theirs.size(), "depth %d rooms match the sim's compositions() (%d vs %d)" % [depth, mine.size(), theirs.size()])
	failed += _assert(_room_budget(1, budget) == 90 and _room_budget(10, budget) == 108 and _room_budget(15, budget) == 138, "budget 90 / 108 / 138 at depth 1 / 10 / 15")
	failed += _assert(_spawn_table_for(2, tables).size() == 2 and _spawn_table_for(14, tables).size() == 6, "a depth uses the latest table at or below it")
	# Loot: Amberbind stays the manual jackpot; job 23 numbers are not approved, so they stay empty.
	var loot: Dictionary = data.get("loot", {}) as Dictionary
	failed += _assert(is_equal_approx(float(loot.get("bonus_drop_chance", 0.0)), 0.10), "bonus drop chance stays 10%")
	failed += _assert(str(loot.get("manual_jackpot", "")) == "amberbind", "Amberbind is the manual jackpot")
	failed += _assert((loot.get("bonus_drop_never", []) as Array).has("amberbind"), "Amberbind is listed as never a bonus drop")
	var contents: Variant = loot.get("bonus_drop_contents", null)
	failed += _assert(contents == null or JSON.stringify(contents).find("amberbind") < 0, "bonus-drop contents carry no Amberbind")
	failed += _assert(contents == null and loot.get("herbs_by_depth", null) == null, "unapproved job 23 numbers stay empty")
	if failed == 0:
		print("SPAWN_DATA_OK")
	return failed


func _spawn_room_key(room: Array) -> String:
	var ids: PackedStringArray = PackedStringArray()
	for e_v: Variant in room:
		var e: Dictionary = e_v as Dictionary
		ids.append(str(e.get("beast", "")))
	ids.sort()
	return ",".join(ids)


func _spawn_room_threat(room: Array) -> int:
	var total: int = 0
	for e_v: Variant in room:
		total += int((e_v as Dictionary).get("threat", 0))
	return total


func _spawn_attack_by_id() -> Dictionary:
	var beasts: Dictionary = _json_dict("res://data/beasts.json")
	var by_id: Dictionary = {}
	for row_v: Variant in (beasts.get("species", []) as Array) + (beasts.get("variants", []) as Array):
		var row: Dictionary = row_v as Dictionary
		by_id[str(row.get("id", ""))] = str(row.get("attack", "physical"))
	return by_id


func _spawn_roller(_tree_root: Window) -> int:
	## SpawnRoller matches the sim oracle in tests/fixtures/resolver_compositions.json and roll_room rows.
	var failed: int = 0
	var fixture: Dictionary = _json_dict("res://tests/fixtures/resolver_compositions.json")
	failed += _assert(not fixture.is_empty(), "resolver_compositions.json parses")
	if fixture.is_empty():
		return failed
	var by_attack: Dictionary = _spawn_attack_by_id()
	var beasts: Dictionary = _json_dict("res://data/beasts.json")
	var threat_by_id: Dictionary = {}
	for row_v: Variant in (beasts.get("species", []) as Array) + (beasts.get("variants", []) as Array):
		var row: Dictionary = row_v as Dictionary
		threat_by_id[str(row.get("id", ""))] = int(row.get("threat", 0))
	var depths: Array = fixture.get("depths", []) as Array
	for dep_v: Variant in depths:
		var dep: Dictionary = dep_v as Dictionary
		var depth: int = int(dep.get("depth", 0))
		failed += _assert(SpawnRoller.budget(depth) == int(dep.get("budget", -1)), "budget at depth %d" % depth)
		var mine: Array = SpawnRoller.compositions(depth)
		var theirs: Array = []
		for room_v: Variant in dep.get("rooms", []) as Array:
			var room: Dictionary = room_v as Dictionary
			theirs.append(room.get("beasts", []))
			var threat_sum: int = 0
			for id_v: Variant in room.get("beasts", []) as Array:
				threat_sum += int(threat_by_id.get(str(id_v), 0))
			failed += _assert(threat_sum == int(room.get("threat", -1)), "fixture threat at depth %d" % depth)
		failed += _assert(str(mine) == str(theirs) and mine.size() == int(dep.get("count", -1)), "compositions at depth %d" % depth)
	var oracle_depths: Array[int] = [1, 3, 8, 15]
	for depth: int in oracle_depths:
		var allowed: Dictionary = {}
		for dep_v: Variant in depths:
			var dep: Dictionary = dep_v as Dictionary
			if int(dep.get("depth", 0)) != depth:
				continue
			for room_v: Variant in dep.get("rooms", []) as Array:
				var beast_ids: Array = (room_v as Dictionary).get("beasts", []) as Array
				var key_parts: PackedStringArray = PackedStringArray()
				for b_v: Variant in beast_ids:
					key_parts.append(str(b_v))
				key_parts.sort()
				allowed[",".join(key_parts)] = true
		var room_budget: int = SpawnRoller.budget(depth)
		for seed: int in range(300):
			var room: Array = SpawnRoller.roll_room(depth, SpawnRoller.room_seed_rng(seed))
			failed += _assert(room.size() <= 6, "depth %d seed %d at most 6 beasts" % [depth, seed])
			failed += _assert(_spawn_room_threat(room) <= room_budget, "depth %d seed %d within budget" % [depth, seed])
			failed += _assert(allowed.has(_spawn_room_key(room)), "depth %d seed %d is a fixture room" % [depth, seed])
			var phys: int = 0
			var mag: int = 0
			for e_v: Variant in room:
				var e: Dictionary = e_v as Dictionary
				var atk: String = str(by_attack.get(str(e.get("beast", "")), "physical"))
				if atk == "magic":
					mag += 1
				else:
					phys += 1
				failed += _assert(int(e.get("slot", -1)) >= 0 and int(e.get("slot", -1)) < room.size(), "slot in range depth %d" % depth)
			for e_v: Variant in room:
				var e: Dictionary = e_v as Dictionary
				var atk: String = str(by_attack.get(str(e.get("beast", "")), "physical"))
				var row: String = str(e.get("row", ""))
				if atk != "magic" and phys <= 3:
					failed += _assert(row == "front", "physical in front depth %d seed %d" % [depth, seed])
				if atk == "magic" and mag <= 3:
					failed += _assert(row == "back", "magic in back depth %d seed %d" % [depth, seed])
			for i: int in range(room.size()):
				var found: bool = false
				for e_v: Variant in room:
					if int((e_v as Dictionary).get("slot", -1)) == i:
						found = true
				failed += _assert(found, "slot %d present depth %d seed %d" % [i, depth, seed])
	var saw_rare: bool = false
	for seed: int in range(2000):
		var room: Array = SpawnRoller.roll_room(3, SpawnRoller.room_seed_rng(seed))
		for e_v: Variant in room:
			var bid: String = str((e_v as Dictionary).get("beast", ""))
			if bid == "wilt_wisp" or bid == "root_snapper":
				saw_rare = true
	failed += _assert(saw_rare, "depth 3 draws wilt_wisp or root_snapper over 2000 seeds")
	if failed == 0:
		print("SPAWN_ROLLER_OK")
	return failed


func _spawn_seed(_tree_root: Window) -> int:
	var failed: int = 0
	for seed: int in range(3):
		var a: Array = SpawnRoller.roll_room(3, SpawnRoller.room_seed_rng(42))
		var b: Array = SpawnRoller.roll_room(3, SpawnRoller.room_seed_rng(42))
		failed += _assert(str(a) == str(b), "room seed 42 repeats")
	var keys: Dictionary = {}
	for seed: int in range(50):
		keys[_spawn_room_key(SpawnRoller.roll_room(3, SpawnRoller.room_seed_rng(seed)))] = true
	failed += _assert(keys.size() >= 2, "depth 3 varies across 50 consecutive room seeds")
	for seed: int in range(20):
		var room: Array = SpawnRoller.roll_room(5, SpawnRoller.room_seed_rng(500 + seed), true)
		var bosses: int = 0
		var best_i: int = -1
		for i: int in room.size():
			if bool((room[i] as Dictionary).get("boss", false)):
				bosses += 1
		for i: int in room.size():
			var cur: Dictionary = room[i] as Dictionary
			if best_i < 0:
				best_i = i
				continue
			var best: Dictionary = room[best_i] as Dictionary
			if int(cur.get("threat", 0)) > int(best.get("threat", 0)):
				best_i = i
			elif int(cur.get("threat", 0)) == int(best.get("threat", 0)) and int(cur.get("slot", 0)) < int(best.get("slot", 0)):
				best_i = i
		failed += _assert(bosses == 1, "exactly one boss flag")
		failed += _assert(bool((room[best_i] as Dictionary).get("boss", false)), "boss is highest threat (lowest slot on ties)")
	const PIN_DEPTH: int = 5
	var pin_1: Array = [
		{"beast": "root_snapper", "row": "front", "slot": 0, "boss": false, "threat": 46},
		{"beast": "acorn_imp", "row": "front", "slot": 1, "boss": false, "threat": 33},
	]
	var pin_2: Array = [
		{"beast": "spore_moth", "row": "back", "slot": 0, "boss": false, "threat": 45},
		{"beast": "wilt_wisp", "row": "back", "slot": 1, "boss": false, "threat": 47},
	]
	var pin_1000: Array = [
		{"beast": "acorn_imp", "row": "front", "slot": 0, "boss": false, "threat": 33},
		{"beast": "spore_moth_dark", "row": "back", "slot": 1, "boss": false, "threat": 62},
	]
	failed += _assert(str(SpawnRoller.roll_room(PIN_DEPTH, SpawnRoller.room_seed_rng(1))) == str(pin_1), "pinned room seed 1 depth 5")
	failed += _assert(str(SpawnRoller.roll_room(PIN_DEPTH, SpawnRoller.room_seed_rng(2))) == str(pin_2), "pinned room seed 2 depth 5")
	failed += _assert(str(SpawnRoller.roll_room(PIN_DEPTH, SpawnRoller.room_seed_rng(1000))) == str(pin_1000), "pinned room seed 1000 depth 5")
	if failed == 0:
		print("SPAWN_SEED_OK")
	return failed


func _strings_adventure_v4(tree_root: Window) -> int:
	## The BATTLE_SCENE_DRAFT v4 strings (DRAFT copy) exist and read right through ContentStrings.
	## Beasts are Calmed and the party is Overwhelmed: no "slain", "killed" or "defeat" in adventure
	## copy, and "Rootweave" nowhere in the game.
	var failed: int = 0
	var cs: Node = tree_root.get_node_or_null("ContentStrings")
	failed += _assert(cs != null, "ContentStrings autoload")
	if cs == null:
		return failed
	var exact: Dictionary = {
		"adv_overwhelmed_title": "Overwhelmed",
		"adv_knocked_out": "Knocked out",
		"adv_calmed": "Calmed",
		"adv_trailhead": "Trailhead",
		"adv_strike_for_me": "Strike for me",
		"adv_item_none_packed": "None packed",
		"adv_ability_empty_tip": "Abilities draw on Weave. You have none yet.",
		"adv_loadout_title": "Item loadout",
	}
	for key: String in exact.keys():
		failed += _assert(str(cs.call("get_text", key)) == str(exact[key]), "%s reads \"%s\"" % [key, str(exact[key])])
	var present: Array[String] = ["adv_overwhelmed_body", "adv_overwhelmed_log", "adv_knocked_out_log", "adv_calmed_log",
		"adv_calmed_tip", "adv_back_at_trailhead", "adv_strike_for_me_tip", "adv_item_count", "adv_loadout_hint",
		"adv_loadout_empty_slot", "adv_depart_cost", "adv_predeparture_warning"]
	for key: String in present:
		var text: String = str(cs.call("get_text", key))
		failed += _assert(text != key and not text.strip_edges().is_empty(), "%s exists" % key)
	failed += _assert(str(cs.call("get_text", "adv_calmed_log", {"beast": "Acorn imp"})) == "Acorn imp is Calmed.", "Calmed log line fills the beast name")
	failed += _assert(str(cs.call("get_text", "adv_item_count", {"item": "Heart Salve", "count": 0})) == "Heart Salve ×0", "item count reads Heart Salve ×0")
	failed += _assert(str(cs.call("get_text", "adv_depart_cost")).find("20 Essence") >= 0, "departure cost names 20 Essence")
	failed += _assert(str(cs.call("get_text", "adv_predeparture_warning")).find("no Cancel") >= 0, "pre-departure warning says there is no Cancel")
	failed += _assert(str(cs.call("get_text", "adv_strike_for_me_tip")).find("1×") >= 0, "Strike for me plays at 1×")
	var table: Dictionary = _json_dict("res://data/strings_v01.json")
	var raw: String = FileAccess.get_file_as_string("res://data/strings_v01.json").to_lower()
	failed += _assert(raw.find("rootweave") < 0, "no Rootweave in any string")
	var prefixes: Array[String] = ["adv_", "beast_", "adventure_", "expedition_", "path_east_", "lantern_", "reach_"]
	var checked: int = 0
	for key_v: Variant in table.keys():
		var key: String = str(key_v)
		var adventure: bool = false
		for pre: String in prefixes:
			if key.begins_with(pre):
				adventure = true
		if not adventure:
			continue
		checked += 1
		var text: String = str(table[key_v]).to_lower()
		for banned: String in ["slain", "slay", "killed", "kill "]:
			failed += _assert(text.find(banned) < 0, "%s avoids \"%s\"" % [key, banned])
		if key.begins_with("adv_") or key.begins_with("beast_"):
			failed += _assert(text.find("defeat") < 0, "%s says Overwhelmed or Calmed, not defeat" % key)
	failed += _assert(checked >= 30, "adventure strings were checked (%d)" % checked)
	if failed == 0:
		print("STRINGS_ADVENTURE_V4_OK")
	return failed


func _write_versioned_slot(save_service: Node, slot: int, version: int, state: Dictionary) -> bool:
	var root: Dictionary = {
		"save_version": version,
		"timestamp": Time.get_unix_time_from_system(),
		"slot": slot,
		"kind": "manual",
		"state": state,
	}
	var path: String = str(save_service.call("slot_path", slot))
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(root))
	file.close()
	return true


func _read_slot_root(save_service: Node, slot: int) -> Dictionary:
	var path: String = str(save_service.call("slot_path", slot))
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary if parsed is Dictionary else {}


func _reach_item_keys_gone(reach_block: Dictionary) -> bool:
	for item_id: String in ["briarwood", "herbs", "heart_salve", "bile_vial"]:
		if reach_block.has(item_id):
			return false
	return true


func _save_v14_inventory_merge(tree_root: Window, game_state: Node, save_service: Node) -> int:
	## A v13 reach's items add into a backpack that already holds some, then the live
	## idle reward, manual Salve and Ascend all use that one backpack.
	var failed: int = 0
	var reach: Node = tree_root.get_node_or_null("Reach")
	var pack: Node = tree_root.get_node_or_null("Backpack")
	var gear: Node = tree_root.get_node_or_null("Equipment")
	failed += _assert(reach != null and pack != null and gear != null, "v14 inventory nodes")
	if reach == null or pack == null or gear == null:
		return failed
	failed += _assert(bool(pack.call("is_known_item", "briarwood")) and bool(pack.call("is_known_item", "herbs")), "road materials are backpack items")
	failed += _assert(bool(pack.call("is_known_item", "heart_salve")) and bool(pack.call("is_known_item", "bile_vial")), "potions are backpack items")
	failed += _assert(str(pack.call("item_display_name", "heart_salve")) == "Heart Salve", "Heart Salve name")
	failed += _assert(str(pack.call("item_display_name", "bile_vial")) == "Bile Vial", "Bile Vial name")
	failed += _assert(str(pack.call("item_display_name", "briarwood")) == "Briarwood", "Briarwood name")
	failed += _assert(str(pack.call("item_display_name", "herbs")) == "Herbs", "Herbs name")
	failed += _assert(str(pack.call("item_kind", "heart_salve")) == "consumable" and str(pack.call("item_kind", "bile_vial")) == "consumable", "potions are consumable")
	failed += _assert(str(gear.call("item_art_path", "heart_salve")).ends_with("icon_heart_salve.png"), "salve icon")
	failed += _assert(str(gear.call("item_art_path", "bile_vial")).ends_with("icon_bile_vial.png"), "vial icon")
	failed += _assert(str(gear.call("item_art_path", "briarwood")) == "" and str(gear.call("item_art_path", "herbs")) == "", "materials use the colour fallback")
	var clamped: Dictionary = save_service.call("migrate_state", 13, {
		"stage_id": "sapling",
		"backpack": {"heart_salve": -2, "herbs": 4},
		"reach": {
			"briarwood": -3,
			"heart_salve": 1,
			"running": false,
			"reaches_cleared": 0,
			"rooms_attempted": 0,
		},
	})
	var clamped_pack: Dictionary = clamped.get("backpack", {}) as Dictionary
	var clamped_reach: Dictionary = clamped.get("reach", {}) as Dictionary
	failed += _assert(int(clamped_pack.get("heart_salve", -1)) == 1, "a negative backpack count becomes 0 before the add")
	failed += _assert(not clamped_pack.has("briarwood"), "a negative reach count adds no stack")
	failed += _assert(not clamped_pack.has("bile_vial"), "a zero total adds no stack")
	failed += _assert(int(clamped_pack.get("herbs", -1)) == 4, "a backpack count with nothing to move stays")
	failed += _assert(_reach_item_keys_gone(clamped_reach), "clamped migration removes the item keys")
	save_service.call("delete_slot", 7)
	var state: Dictionary = {
		"wood": 12,
		"stage_id": "sapling",
		"backpack": {"heart_salve": 1},
		"reach": {
			"briarwood": 3,
			"herbs": 2,
			"heart_salve": 4,
			"bile_vial": 1,
			"running": false,
			"reaches_cleared": 0,
			"deepest_depth": 0,
			"rooms_attempted": 0,
			"dojo_exp": 0,
		},
	}
	failed += _assert(_write_versioned_slot(save_service, 7, 13, state), "v13 inventory fixture writes slot 7")
	failed += _assert(bool(save_service.call("load_game", 7)), "v13 inventory fixture loads")
	failed += _assert(int(pack.call("get_count", "heart_salve")) == 5, "salves add (1 already in the backpack)")
	failed += _assert(int(pack.call("get_count", "bile_vial")) == 1, "bile moves across")
	failed += _assert(int(pack.call("get_count", "briarwood")) == 3, "briarwood moves across")
	failed += _assert(int(pack.call("get_count", "herbs")) == 2, "herbs move across")
	failed += _assert(bool(save_service.call("save_game", 7)), "re-save the merged inventory")
	var written: Dictionary = _read_slot_root(save_service, 7)
	var written_state: Dictionary = written.get("state", {}) as Dictionary
	var written_reach: Dictionary = written_state.get("reach", {}) as Dictionary
	var written_pack: Dictionary = written_state.get("backpack", {}) as Dictionary
	failed += _assert(int(written.get("save_version", 0)) == 14, "the re-save is version 14")
	failed += _assert(_reach_item_keys_gone(written_reach), "the re-saved reach block has no item keys")
	failed += _assert(int(written_pack.get("heart_salve", 0)) == 5, "re-saved salve count")
	failed += _assert(int(written_pack.get("briarwood", 0)) == 3, "re-saved briarwood count")
	reach.call("push_faces", [20])
	reach.call("push_drops", [1, 0])
	failed += _assert(str(reach.call("depart", 1, 1, "hold", "idle")) == "ok", "idle depart after the merge")
	reach.call("advance_clock", 720.0)
	failed += _assert(int(pack.call("get_count", "briarwood")) == 4, "an idle room grants Briarwood into the backpack")
	var salve_before: int = int(pack.call("get_count", "heart_salve"))
	reach.call("set_control", "manual")
	failed += _assert(bool(reach.call("fight_active")), "manual opens the fight")
	var spent: String = str(reach.call("fight_choose", "salve", 0))
	failed += _assert(spent != "empty" and spent != "invalid", "the fight accepts the salve (got %s)" % spent)
	failed += _assert(int(pack.call("get_count", "heart_salve")) == salve_before - 1, "a manual Salve spends one from the backpack")
	pack.call("set_count", "fertilizer", 3)
	var kept_salve: int = int(pack.call("get_count", "heart_salve"))
	var kept_bile: int = int(pack.call("get_count", "bile_vial"))
	var kept_briar: int = int(pack.call("get_count", "briarwood"))
	var kept_herbs: int = int(pack.call("get_count", "herbs"))
	var ascensions_before: int = int(game_state.get("ascensions"))
	game_state.set("fruit_committed", true)
	game_state.call("ascend")
	failed += _assert(int(game_state.get("ascensions")) == ascensions_before + 1, "ascend runs")
	failed += _assert(int(pack.call("get_count", "fertilizer")) == 0, "ascend still wipes other backpack stacks")
	failed += _assert(int(pack.call("get_count", "heart_salve")) == kept_salve, "ascend keeps Heart Salve")
	failed += _assert(int(pack.call("get_count", "bile_vial")) == kept_bile, "ascend keeps Bile Vial")
	failed += _assert(int(pack.call("get_count", "briarwood")) == kept_briar, "ascend keeps Briarwood")
	failed += _assert(int(pack.call("get_count", "herbs")) == kept_herbs, "ascend keeps Herbs")
	reach.call("reset_for_new_game")
	game_state.call("reset_for_new_game")
	save_service.call("delete_slot", 7)
	if failed == 0:
		print("SAVE_V14_INVENTORY_MERGE_OK")
	return failed


func _save_v14_home(tree_root: Window, game_state: Node, save_service: Node) -> int:
	## No run is home. A cyan lantern with no run is an unseen finish. A running v13 run stays out.
	var failed: int = 0
	var reach: Node = tree_root.get_node_or_null("Reach")
	failed += _assert(reach != null, "v14 home needs Reach")
	if reach == null:
		return failed
	save_service.call("delete_slot", 7)
	var home_state: Dictionary = {
		"wood": 3,
		"stage_id": "sapling",
		"expedition_lantern": "dark",
		"reach": {"running": false, "reaches_cleared": 0, "rooms_attempted": 0, "deepest_depth": 0},
	}
	failed += _assert(_write_versioned_slot(save_service, 7, 13, home_state), "home v13 writes")
	failed += _assert(bool(save_service.call("load_game", 7)), "home v13 loads")
	var home_exp: Dictionary = reach.get("expedition") as Dictionary
	failed += _assert(str(home_exp.get("status", "")) == "home", "no run migrates to home")
	failed += _assert(not home_exp.has("summary"), "home has no summary")
	var cyan_state: Dictionary = {
		"wood": 3,
		"stage_id": "sapling",
		"expedition_lantern": "cyan",
		"reach": {"running": false, "reaches_cleared": 2, "rooms_attempted": 0, "deepest_depth": 1},
	}
	failed += _assert(_write_versioned_slot(save_service, 7, 13, cyan_state), "cyan v13 writes")
	failed += _assert(bool(save_service.call("load_game", 7)), "cyan v13 loads")
	var cyan_exp: Dictionary = reach.get("expedition") as Dictionary
	failed += _assert(str(cyan_exp.get("status", "")) == "finished_unseen", "a cyan lantern with no run is finished unseen")
	failed += _assert(str(cyan_exp.get("summary", "")) == "from an older save", "the unseen summary text")
	var resaved: Dictionary = game_state.call("to_save_dict")
	var resaved_exp: Dictionary = resaved.get("expedition", {}) as Dictionary
	failed += _assert(str(resaved_exp.get("status", "")) == "finished_unseen", "a re-save keeps finished unseen")
	failed += _assert(str(resaved_exp.get("summary", "")) == "from an older save", "a re-save keeps the summary")
	var out_state: Dictionary = {
		"wood": 3,
		"stage_id": "sapling",
		"expedition_lantern": "amber",
		"reach": {
			"running": true,
			"phase": "idle_room",
			"rooms_attempted": 6,
			"reaches_cleared": 4,
			"deepest_depth": 3,
			"depth": 2,
			"hours": 4.0,
			"elapsed": 100.0,
			"room_left": 400.0,
			"dojo_exp": 20,
			"briarwood": 1,
			"herbs": 1,
			"heart_salve": 0,
			"bile_vial": 0,
		},
	}
	failed += _assert(_write_versioned_slot(save_service, 7, 13, out_state), "running v13 writes")
	failed += _assert(bool(save_service.call("load_game", 7)), "running v13 loads")
	var out_exp: Dictionary = reach.get("expedition") as Dictionary
	failed += _assert(str(out_exp.get("status", "")) == "out_legacy", "a running run is out_legacy")
	failed += _assert(not out_exp.has("summary"), "out_legacy has no summary")
	failed += _assert(bool(reach.get("running")), "the old run is still running")
	failed += _assert(int(reach.get("rooms_attempted")) == 6, "rooms_attempted is kept")
	failed += _assert(str(reach.get("phase")) == "idle_room", "the idle room is still open")
	game_state.call("reset_for_new_game")
	failed += _assert(bool(save_service.call("save_game", 7)), "a fresh v14 save writes")
	var fresh: Dictionary = _read_slot_root(save_service, 7)
	var fresh_state: Dictionary = fresh.get("state", {}) as Dictionary
	var fresh_exp: Dictionary = fresh_state.get("expedition", {}) as Dictionary
	var fresh_reach: Dictionary = fresh_state.get("reach", {}) as Dictionary
	failed += _assert(int(fresh.get("save_version", 0)) == 14, "new saves write version 14")
	failed += _assert(str(fresh_exp.get("status", "")) == "home", "a new game expedition is home")
	failed += _assert(_reach_item_keys_gone(fresh_reach), "a new save's reach block has no item keys")
	reach.call("depart", 1, 1, "hold", "idle")
	failed += _assert(bool(save_service.call("save_game", 7)), "a running v14 save writes")
	var running_save: Dictionary = _read_slot_root(save_service, 7)
	var running_state: Dictionary = running_save.get("state", {}) as Dictionary
	var running_exp: Dictionary = running_state.get("expedition", {}) as Dictionary
	var running_reach: Dictionary = running_state.get("reach", {}) as Dictionary
	failed += _assert(str(running_exp.get("status", "")) == "out_legacy", "a fresh running save is out_legacy")
	failed += _assert(bool(running_reach.get("running", false)), "the fresh save still has the run")
	failed += _assert(_reach_item_keys_gone(running_reach), "the running save has no item keys in reach")
	game_state.call("reset_for_new_game")
	save_service.call("delete_slot", 7)
	if failed == 0:
		print("SAVE_V14_HOME_OK")
	return failed


func _save_v14_from_main(tree_root: Window, game_state: Node, save_service: Node) -> int:
	## A real v11 main save, and the v10 batch fixture, both arrive at v14 with the road still at home.
	var failed: int = 0
	var reach: Node = tree_root.get_node_or_null("Reach")
	var pack: Node = tree_root.get_node_or_null("Backpack")
	failed += _assert(reach != null and pack != null, "v14 from-main nodes")
	if reach == null or pack == null:
		return failed
	save_service.call("delete_slot", 7)
	var fixture: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/save_v11_main.json"))
	failed += _assert(fixture is Dictionary, "v11 main fixture parses")
	if fixture is Dictionary:
		var root: Dictionary = (fixture as Dictionary).duplicate(true)
		failed += _assert(int(root.get("save_version", 0)) == 11, "fixture is a v11 save")
		failed += _assert(not (root.get("state", {}) as Dictionary).has("reach"), "v11 main has no reach block")
		root["timestamp"] = Time.get_unix_time_from_system()
		root["slot"] = 7
		var path: String = str(save_service.call("slot_path", 7))
		var file := FileAccess.open(path, FileAccess.WRITE)
		failed += _assert(file != null, "v11 fixture slot writes")
		if file != null:
			file.store_string(JSON.stringify(root))
			file.close()
			failed += _assert(bool(save_service.call("load_game", 7)), "v11 main fixture loads")
			failed += _assert(int(game_state.get("wood")) == 37, "v11 wood survives")
			failed += _assert(int(game_state.get("stone")) == 11, "v11 stone survives")
			failed += _assert(int(game_state.get("food")) == 4, "v11 food survives")
			failed += _assert(int(game_state.get("essence")) == 8, "v11 essence survives")
			failed += _assert(int(game_state.get("manashards")) == 6, "v11 manashards survive")
			failed += _assert(int(pack.call("get_count", "wooden_planks")) == 6, "v11 planks survive")
			failed += _assert(int(pack.call("get_count", "fertilizer")) == 2, "v11 fertilizer survives")
			var blob: Dictionary = game_state.call("to_save_dict")
			var reach_block: Dictionary = blob.get("reach", {}) as Dictionary
			var exp: Dictionary = blob.get("expedition", {}) as Dictionary
			failed += _assert(not reach_block.is_empty(), "v11 gains a reach block")
			failed += _assert(int(reach_block.get("reaches_cleared", -1)) == 0 and bool(reach_block.get("running", true)) == false, "the migrated reach is empty")
			failed += _assert(_reach_item_keys_gone(reach_block), "the empty reach has no item keys")
			failed += _assert(str(exp.get("status", "")) == "home", "a v11 save is home")
			failed += _assert(int(reach.get("deepest_depth")) == 0 and int(reach.get("dojo_exp")) == 0, "v11 did not invent a run")
			failed += _assert(int(pack.call("get_count", "briarwood")) == 0 and int(pack.call("get_count", "heart_salve")) == 0, "v11 had no reach items to move")
	var v10: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/batch_migration_6efbcab.json"))
	failed += _assert(v10 is Dictionary, "v10 fixture parses")
	if v10 is Dictionary:
		var old: Dictionary = (v10 as Dictionary).duplicate(true)
		old["timestamp"] = Time.get_unix_time_from_system()
		old["slot"] = 7
		var old_path: String = str(save_service.call("slot_path", 7))
		var old_file := FileAccess.open(old_path, FileAccess.WRITE)
		failed += _assert(old_file != null, "v10 fixture slot writes")
		if old_file != null:
			old_file.store_string(JSON.stringify(old))
			old_file.close()
			failed += _assert(bool(save_service.call("load_game", 7)), "v10 fixture loads through to v14")
			failed += _assert(int(game_state.get("wood")) == 20 and int(game_state.get("stone")) == 20, "v10 resources survive")
			failed += _assert(int(pack.call("get_count", "sapsteel")) == 0, "v10 does not grant the in-progress sapsteel")
			var old_blob: Dictionary = game_state.call("to_save_dict")
			var old_reach: Dictionary = old_blob.get("reach", {}) as Dictionary
			var old_exp: Dictionary = old_blob.get("expedition", {}) as Dictionary
			failed += _assert(old_reach.has("rooms_attempted") and int(old_reach.get("reaches_cleared", -1)) == 0, "v10 gains an empty reach block")
			failed += _assert(_reach_item_keys_gone(old_reach), "v10 reach has no item keys")
			failed += _assert(str(old_exp.get("status", "")) == "home", "v10 expedition is home")
	game_state.call("reset_for_new_game")
	save_service.call("delete_slot", 7)
	if failed == 0:
		print("SAVE_V14_FROM_MAIN_OK")
	return failed


func _resolver_all() -> int:
	return _resolver_dice() + _resolver_margin() + _resolver_die_table() + _resolver_seed() + _resolver_state_roundtrip() + _resolver_turn_order() + _resolver_rows() + _resolver_targeting() + _resolver_brace() + _resolver_shield_order() + _resolver_poison_refresh() + _resolver_twists() + _resolver_boss() + _resolver_salve() + _auto_flee_ko_zero() + _resolver_log()


func _resolver_dice() -> int:
	## §4 worked example through FightState.strike, plus a beast that must not eat a Fate roll.
	var failed: int = 0
	var cases: Dictionary = _json_dict("res://tests/fixtures/resolver_cases.json")
	var by_id: Dictionary = {}
	for case_v: Variant in cases.get("strikes", []) as Array:
		var c: Dictionary = case_v as Dictionary
		by_id[str(c.get("id", ""))] = c
	var want_damage: Dictionary = {"s4_line1": 24, "s4_line2": 4, "s4_line4": 52}
	var want_crit: Dictionary = {"s4_line1": false, "s4_line2": false, "s4_line4": true}
	var want_band: Dictionary = {"s4_line1": "crush", "s4_line2": "graze", "s4_line4": "crush"}
	for cid: String in ["s4_line1", "s4_line2", "s4_line4"]:
		failed += _assert(by_id.has(cid), "fixture %s" % cid)
		if not by_id.has(cid):
			continue
		var case: Dictionary = by_id[cid] as Dictionary
		var packed: Dictionary = _resolver_run_case(case, [])
		var result: Dictionary = packed["result"] as Dictionary
		var expect: Dictionary = case.get("expect", {}) as Dictionary
		failed += _resolver_expect(cid, result, expect, packed["fight"])
		failed += _assert(int(result.get("damage", -1)) == int(want_damage[cid]), "%s damage is the worked example" % cid)
		failed += _assert(bool(result.get("fate_crit", false)) == bool(want_crit[cid]), "%s crit flag" % cid)
		failed += _assert(str(result.get("band", "")) == str(want_band[cid]), "%s band" % cid)
		failed += _assert(int(packed["remaining"]) == 0, "%s used every injected face" % cid)
		failed += _assert(int(packed["underrun"]) == 0, "%s did not read past the injected faces" % cid)
	if by_id.has("s4_line2"):
		var beast_case: Dictionary = by_id["s4_line2"] as Dictionary
		var extra: Array[int] = [77]
		var packed_beast: Dictionary = _resolver_run_case(beast_case, extra)
		var expect_beast: Dictionary = beast_case.get("expect", {}) as Dictionary
		failed += _resolver_expect("s4_line2 fate", packed_beast["result"], expect_beast, packed_beast["fight"])
		failed += _assert(int(packed_beast["remaining"]) == 1, "beast attacker leaves the Fate roll unconsumed")
		failed += _assert(int(packed_beast["underrun"]) == 0, "beast attacker did not underrun")
		var left: Array = packed_beast["queue"] as Array
		failed += _assert(left.size() == 1 and int(left[0]) == 77, "the unconsumed face is the Fate roll")
	if failed == 0:
		print("RESOLVER_DICE_OK")
	return failed


func _resolver_margin() -> int:
	## Every fixed-dice strike, plus the 10% KO / Calmed line on both sides.
	var failed: int = 0
	var cases: Dictionary = _json_dict("res://tests/fixtures/resolver_cases.json")
	var strikes: Array = cases.get("strikes", []) as Array
	failed += _assert(strikes.size() >= 12, "fixture strikes (got %d)" % strikes.size())
	var checked: int = 0
	for case_v: Variant in strikes:
		var case: Dictionary = case_v as Dictionary
		var cid: String = str(case.get("id", ""))
		var packed: Dictionary = _resolver_run_case(case, [])
		var result: Dictionary = packed["result"] as Dictionary
		var expect: Dictionary = case.get("expect", {}) as Dictionary
		failed += _resolver_expect(cid, result, expect, packed["fight"])
		failed += _assert(int(packed["remaining"]) == 0, "%s left injected faces unused" % cid)
		failed += _assert(int(packed["underrun"]) == 0, "%s consumed a die the fixture does not roll" % cid)
		var att: Dictionary = case.get("attacker", {}) as Dictionary
		var attack_type: String = str(case.get("attack_type", "physical"))
		var offense: int = int(att.get("arc", att.get("arcana", 0))) if attack_type == "magic" else int(att.get("mig", att.get("might", 0)))
		var die_block: Dictionary = case.get("dice", {}) as Dictionary
		failed += _assert(int(BattleResolverScript.die_size(offense)) == int(die_block.get("damage_die", -1)), "%s damage die" % cid)
		var card: Dictionary = (packed["fight"] as FightState).fighter_dict("defender")
		var hp_after: int = int(result.get("defender_hp_after", 0))
		var max_hp: int = int(card.get("max_hp", 0))
		var want_status: String = "active"
		if hp_after * 10 <= max_hp:
			want_status = "ko" if str(packed["defender_side"]) == "party" else "calmed"
		failed += _assert(str(result.get("defender_status", "")) == want_status, "%s status %s vs %s (hp %d / %d)" % [cid, str(result.get("defender_status", "")), want_status, hp_after, max_hp])
		failed += _assert(str(card.get("status", "")) == want_status, "%s stored status" % cid)
		checked += 1
	failed += _assert(checked == strikes.size() and checked > 0, "ran every strike")
	# min-damage graze (1) across the threshold. vit 10 => max 40, so 4 HP is exactly 10%.
	var bounds: Array = [
		["party", 6, 3, "ko"],
		["party", 6, 4, "active"],
		["beast", 9, 4, "calmed"],
		["beast", 9, 5, "active"],
		["party", 10, 5, "ko"],
		["party", 10, 6, "active"],
		["beast", 10, 5, "calmed"],
		["beast", 10, 6, "active"],
	]
	for row_v: Variant in bounds:
		var row: Array = row_v as Array
		var side: String = str(row[0])
		var vit: int = int(row[1])
		var hp_before: int = int(row[2])
		var want: String = str(row[3])
		var hit: Dictionary = _resolver_threshold_hit(side, vit, hp_before)
		var result_b: Dictionary = hit["result"] as Dictionary
		failed += _assert(int(result_b.get("damage", 0)) == 1, "threshold probe deals 1 (%s vit %d)" % [side, vit])
		failed += _assert(int(result_b.get("defender_hp_after", 0)) == hp_before - 1, "threshold hp (%s vit %d)" % [side, vit])
		failed += _assert(str(result_b.get("defender_status", "")) == want, "%s vit %d from %d -> %s, got %s" % [side, vit, hp_before, want, str(result_b.get("defender_status", ""))])
		failed += _assert(int(hit["max_hp"]) == 10 + 3 * vit, "threshold max hp")
		failed += _assert(int(hit["underrun"]) == 0 and int(hit["remaining"]) == 0, "threshold dice")
	if failed == 0:
		print("RESOLVER_MARGIN_OK")
	return failed


func _resolver_die_table() -> int:
	var failed: int = 0
	var cases: Dictionary = _json_dict("res://tests/fixtures/resolver_cases.json")
	var table: Array = cases.get("die_table", []) as Array
	var rounding: Array = cases.get("round_half_up", []) as Array
	failed += _assert(not table.is_empty() and not rounding.is_empty(), "die fixture rows")
	for row_v: Variant in table:
		var row: Dictionary = row_v as Dictionary
		var offense: int = int(row.get("offense", 0))
		var got: int = int(BattleResolverScript.die_size(offense))
		failed += _assert(got == int(row.get("die", -1)), "die %d -> %d, want %s" % [offense, got, str(row.get("die"))])
	for round_row_v: Variant in rounding:
		var row2: Dictionary = round_row_v as Dictionary
		var got2: int = int(BattleResolverScript.round_half_up_number(float(row2.get("x", 0.0))))
		failed += _assert(got2 == int(row2.get("rounded", -1)), "round %s -> %d, want %s" % [str(row2.get("x")), got2, str(row2.get("rounded"))])
	var ratios: Array = [[1, 2], [3, 2], [2, 1]]
	var sweep_bad: int = 0
	var sample: String = ""
	for raw: int in range(0, 401):
		for ratio_v: Variant in ratios:
			var ratio: Array = ratio_v as Array
			var num: int = int(ratio[0])
			var den: int = int(ratio[1])
			var got3: int = int(BattleResolverScript.round_half_up(raw, num, den))
			var x: float = float(raw) * float(num) / float(den)
			var want: int = floori(x + 0.5)
			if got3 != want:
				sweep_bad += 1
				if sample == "":
					sample = "raw %d x %d/%d -> %d vs floor %d" % [raw, num, den, got3, want]
	failed += _assert(sweep_bad == 0, "half-up sweep mismatches %d (%s)" % [sweep_bad, sample])
	if failed == 0:
		print("RESOLVER_DIE_TABLE_OK")
	return failed


func _resolver_seed() -> int:
	## FNV-1a 32 of "1000:<stream>", then & 0x7FFFFFFF. These pins are the mix,
	## not Godot's hash(); do not retune them to follow an engine change.
	var failed: int = 0
	var samples: Array = [0, 1, 2, 42, 0x7FFFFFFF, -1, -50, 1 << 40, 9999999999]
	for sample_v: Variant in samples:
		var masked: int = int(BattleRngScript.mask_seed(int(sample_v)))
		failed += _assert(masked >= 0 and masked <= 0x7FFFFFFF, "seed %s masks into 31 bits (%d)" % [str(sample_v), masked])
	var neg: BattleRng = BattleRngScript.new()
	neg.set_seed(-1)
	var pos: BattleRng = BattleRngScript.new()
	pos.set_seed(0x7FFFFFFF)
	failed += _assert(neg.seed_value() == 0x7FFFFFFF, "negative seeds mask to 31 bits")
	var masked_match: bool = true
	for _i: int in 8:
		if neg.roll_die(6) != pos.roll_die(6):
			masked_match = false
	failed += _assert(masked_match, "a masked seed draws the same sequence")
	var zero_rng: BattleRng = BattleRngScript.new()
	zero_rng.set_seed(0)
	var zero_face: int = zero_rng.roll_die(6)
	failed += _assert(zero_face >= 1 and zero_face <= 6, "seed 0 rolls a d6")
	var left: BattleRng = BattleRngScript.new()
	var right: BattleRng = BattleRngScript.new()
	left.set_seed(42)
	right.set_seed(42)
	var same: bool = true
	for _j: int in 16:
		if left.roll_die(6) != right.roll_die(6) or left.roll_fate() != right.roll_fate():
			same = false
	for _k: int in 8:
		if left.roll_die(20) != right.roll_die(20):
			same = false
	failed += _assert(same, "the same seed repeats")
	var pinned: Dictionary = {"spawn": 1141270305, "combat": 1745004102, "loot": 1908542868}
	var seen: Dictionary = {}
	var streams: Array = BattleRngScript.STREAMS
	failed += _assert(streams.size() == 4, "four streams")
	for stream_v: Variant in streams:
		var stream: String = str(stream_v)
		var once: int = int(BattleRngScript.mix_stream(1000, stream))
		var twice: int = int(BattleRngScript.mix_stream(1000, stream))
		failed += _assert(once == twice, "%s mix is stable" % stream)
		failed += _assert(once >= 0 and once <= 0x7FFFFFFF, "%s mix stays in 31 bits" % stream)
		seen[stream] = once
		if pinned.has(stream):
			failed += _assert(once == int(pinned[stream]), "%s mix is the pinned FNV value (got %d)" % [stream, once])
	var unique: Dictionary = {}
	for stream_key: Variant in seen.keys():
		unique[seen[stream_key]] = true
	failed += _assert(unique.size() == 4, "the four streams from room 1000 differ")
	failed += _assert(int(BattleRngScript.mix_stream(1, "spawn")) != int(seen["spawn"]), "a different room seed mixes differently")
	var rng: BattleRng = BattleRngScript.new()
	rng.set_seed(99)
	for _n: int in 7:
		rng.roll_die(12)
	var saved: String = rng.state_string()
	failed += _assert(saved.is_valid_int(), "rng state string is an integer (%s)" % saved)
	var wrapped: String = JSON.stringify({"rng_combat_state": saved})
	var parsed: Variant = JSON.parse_string(wrapped)
	failed += _assert(parsed is Dictionary, "rng state json")
	if parsed is Dictionary:
		var body: Dictionary = parsed as Dictionary
		failed += _assert(typeof(body.get("rng_combat_state")) == TYPE_STRING, "json keeps rng state as a string")
		failed += _assert(str(body.get("rng_combat_state", "")) == saved, "json state string is unchanged")
		var restored: BattleRng = BattleRngScript.new()
		restored.set_seed(99)
		restored.set_state_string(str(body.get("rng_combat_state", "")))
		var twin: BattleRng = BattleRngScript.new()
		twin.set_seed(99)
		twin.set_state_string(saved)
		var draws_match: bool = true
		for _m: int in 12:
			var die_a: int = rng.roll_die(8)
			var die_b: int = restored.roll_die(8)
			var die_c: int = twin.roll_die(8)
			var fate_a: int = rng.roll_fate()
			var fate_b: int = restored.roll_fate()
			var fate_c: int = twin.roll_fate()
			if die_a != die_b or die_b != die_c or fate_a != fate_b or fate_b != fate_c:
				draws_match = false
		failed += _assert(draws_match, "restoring the state string repeats the next draws")
	if failed == 0:
		print("RESOLVER_SEED_OK")
	return failed


func _resolver_state_roundtrip() -> int:
	## Keeper at the unlock line (the §4 example) versus the catalog imp and moth.
	var failed: int = 0
	var fight: FightState = FightStateScript.new()
	fight.set_combat_seed(20261009)
	var keeper_stats: Dictionary = {
		"might": 11, "arcana": 5, "resilience": 6, "ward": 5,
		"vitality": 6, "swiftness": 7, "fate": 7, "attack": "physical",
	}
	failed += _assert(fight.add_member("keeper", keeper_stats, 0, "front") == "keeper", "keeper id")
	failed += _assert(fight.add_beast("acorn_imp", 0, "front") == "acorn_imp", "imp id")
	failed += _assert(fight.add_beast("spore_moth", 1, "back") == "spore_moth", "moth id")
	var beasts: Dictionary = _resolver_beast_rows()
	var fresh: Dictionary = fight.to_dict()
	var keeper_row: Dictionary = _resolver_fighter_row(fresh, "keeper")
	var imp_row: Dictionary = _resolver_fighter_row(fresh, "acorn_imp")
	var moth_row: Dictionary = _resolver_fighter_row(fresh, "spore_moth")
	var imp_spec: Dictionary = beasts.get("acorn_imp", {}) as Dictionary
	var moth_spec: Dictionary = beasts.get("spore_moth", {}) as Dictionary
	failed += _assert(not imp_spec.is_empty() and not moth_spec.is_empty(), "catalog has the imp and the moth")
	failed += _assert(int(keeper_row.get("might", 0)) == 11 and int(keeper_row.get("resilience", 0)) == 6, "keeper might and resilience")
	failed += _assert(int(keeper_row.get("swiftness", 0)) == 7 and int(keeper_row.get("vitality", 0)) == 6 and int(keeper_row.get("fate", 0)) == 7, "keeper swift, vit, fate")
	failed += _assert(int(keeper_row.get("weave", 0)) == 30 and str(keeper_row.get("side", "")) == "party", "party weave is 30")
	failed += _assert(int(keeper_row.get("max_hp", 0)) == 10 + 3 * 6, "keeper max hp")
	failed += _assert(int(imp_row.get("might", -1)) == int(imp_spec.get("might", -2)), "imp might comes from beasts.json")
	failed += _assert(int(imp_row.get("hp", -1)) == int(imp_spec.get("hp", -2)), "imp hp comes from beasts.json")
	failed += _assert(int(imp_row.get("max_hp", 0)) == 10 + 3 * int(imp_spec.get("vitality", 0)), "imp max hp is 10 + 3 x Vitality")
	failed += _assert(str(imp_row.get("attack", "")) == str(imp_spec.get("attack", "")), "imp attack comes from beasts.json")
	failed += _assert(int(imp_row.get("fate", -1)) == int(imp_spec.get("fate", -2)) and int(imp_row.get("weave", -1)) == 0, "beasts have Fate from the file and no weave")
	failed += _assert(int(moth_row.get("arcana", -1)) == int(moth_spec.get("arcana", -2)), "moth arcana comes from beasts.json")
	failed += _assert(str(moth_row.get("attack", "")) == "magic" and str(moth_row.get("row", "")) == "back" and int(moth_row.get("slot", -1)) == 1, "moth is the back-row caster")
	failed += _assert(int(moth_row.get("weave", -1)) == 0, "moth has no weave")
	failed += _assert(str(fresh.get("controller", "")) == "manual" and int(fresh.get("resolver_version", 0)) == 1, "manual controller, resolver version 1")
	failed += _assert(typeof(fresh.get("rng_combat_state")) == TYPE_STRING, "rng state is stored as a string")
	var ids: Array = fresh.get("order", []) as Array
	failed += _assert(ids.size() == 3 and str(ids[0]) == "keeper" and str(ids[1]) == "acorn_imp" and str(ids[2]) == "spore_moth", "order is keeper, imp, moth")
	var pairs: Array = [["keeper", "acorn_imp"], ["spore_moth", "keeper"], ["keeper", "spore_moth"]]
	for pair_v: Variant in pairs:
		var pair: Array = pair_v as Array
		fight.strike(str(pair[0]), str(pair[1]), 0, 1)
	var snap: Dictionary = fight.to_dict()
	failed += _assert(str(snap.get("rng_combat_state", "")) != str(fresh.get("rng_combat_state", "")), "strikes advance the combat rng")
	var parsed: Variant = JSON.parse_string(JSON.stringify(snap))
	failed += _assert(parsed is Dictionary, "fight json")
	if parsed is Dictionary:
		var copy: FightState = FightStateScript.from_dict(parsed)
		var again: Dictionary = copy.to_dict()
		if again != snap:
			print("STATE A ", JSON.stringify(snap))
			print("STATE B ", JSON.stringify(again))
		failed += _assert(again == snap, "fight dict survives json")
		for n: int in 4:
			var pair_n: Array = pairs[n % pairs.size()] as Array
			var left: Dictionary = fight.strike(str(pair_n[0]), str(pair_n[1]), 0, 1)
			var right: Dictionary = copy.strike(str(pair_n[0]), str(pair_n[1]), 0, 1)
			if left != right:
				print("STRIKE A ", JSON.stringify(left))
				print("STRIKE B ", JSON.stringify(right))
			failed += _assert(left == right, "strike %d matches after reload" % n)
		var kept: Dictionary = copy.to_dict()
		failed += _assert(int(_resolver_fighter_row(kept, "keeper").get("weave", 0)) == 30, "weave is still 30 after the reload")
		var schema: Dictionary = snap.duplicate(true)
		schema["round"] = 3
		schema["turn_cursor"] = 2
		schema["ambush"] = true
		schema["twist"] = "briar"
		schema["salves_used"] = 2
		schema["log_tail"] = [{"note": "tail"}]
		var schema_keeper: Dictionary = _resolver_fighter_row(schema, "keeper")
		schema_keeper["shield"] = 4
		schema_keeper["brace"] = true
		schema_keeper["turns"] = 1
		schema_keeper["weave"] = 22
		schema_keeper["status"] = "ko"
		schema_keeper["poison"] = {"ticks": [2, 2], "left": 2}
		schema_keeper["intent"] = {"move": "heavy", "mult": 2}
		var schema_imp: Dictionary = _resolver_fighter_row(schema, "acorn_imp")
		schema_imp["boss"] = true
		var schema_parsed: Variant = JSON.parse_string(JSON.stringify(schema))
		if schema_parsed is Dictionary:
			var schema_back: Dictionary = FightStateScript.from_dict(schema_parsed).to_dict()
			if schema_back != schema:
				print("SCHEMA A ", JSON.stringify(schema))
				print("SCHEMA B ", JSON.stringify(schema_back))
			failed += _assert(schema_back == schema, "schema fields survive json")
		var cap_state: Dictionary = snap.duplicate(true)
		var tail: Array = []
		for i: int in 25:
			tail.append({"i": i})
		cap_state["log_tail"] = tail
		var cap_parsed: Variant = JSON.parse_string(JSON.stringify(cap_state))
		if cap_parsed is Dictionary:
			var capped: Dictionary = FightStateScript.from_dict(cap_parsed).to_dict()
			var got_tail: Array = capped.get("log_tail", []) as Array
			failed += _assert(got_tail.size() == 20, "log tail caps at 20 (got %d)" % got_tail.size())
			if got_tail.size() == 20:
				failed += _assert(int((got_tail[0] as Dictionary).get("i", -1)) == 5, "log tail keeps the latest 20")
				failed += _assert(int((got_tail[19] as Dictionary).get("i", -1)) == 24, "log tail ends at the latest entry")
	if failed == 0:
		print("RESOLVER_STATE_ROUNDTRIP_OK")
	return failed


class _ResolverSwiftHook extends FightState:
	var bumped_id: String = ""
	var bonus: int = 0

	func effective_swiftness(id: String) -> int:
		var base: int = super.effective_swiftness(id)
		if id == bumped_id:
			return base + bonus
		return base


func _resolver_turn_order() -> int:
	## Fixture order, tie-breaks, the Swiftness hook, Ambush, skips, the round cap, and a mid-round save.
	var failed: int = 0
	var cases: Dictionary = _json_dict("res://tests/fixtures/resolver_cases.json")
	var block: Dictionary = cases.get("turn_order", {}) as Dictionary
	var expect: Array = block.get("expect", []) as Array
	failed += _assert(expect.size() == 6, "turn_order fixture has six names")
	var plain: FightState = _resolver_order_fight(false)
	failed += _resolver_same_ids(plain.order, expect, "fixture order")
	failed += _assert(plain.current_actor() == str(expect[0]) if expect.size() == 6 else false, "first actor is the head of the order")
	failed += _assert(plain.round == 1 and plain.outcome() == "", "a fresh fight is round 1 with no outcome")
	var ambush_expect: Array = ["Spore moth A", "Wilt Wisp A", "Acorn imp A", "Root Snapper A", "Keeper", "Elaia"]
	var ambush: FightState = _resolver_order_fight(true)
	failed += _resolver_same_ids(ambush.order, ambush_expect, "ambush round 1")
	ambush.set_scripted_dice(_resolver_miss_faces(6))
	var ambush_actors: Array[String] = []
	for _step_i: int in 6:
		var ambush_step: Dictionary = _resolver_step_auto(ambush)
		failed += _assert(str(ambush_step.get("error", "")) == "", "ambush step error %s" % str(ambush_step.get("error", "")))
		ambush_actors.append(str(ambush_step.get("actor", "")))
	failed += _resolver_same_ids(ambush_actors, ambush_expect, "ambush actors")
	failed += _assert(ambush.scripted_underrun() == 0 and ambush.scripted_remaining() == 0, "ambush round used one miss per actor")
	failed += _assert(ambush.round == 2 and ambush.outcome() == "", "ambush ends after round 1")
	failed += _resolver_same_ids(ambush.order, expect, "ambush round 2 is the normal order")
	failed += _assert(ambush.current_actor() == str(expect[0]) if expect.size() == 6 else false, "round 2 starts at the normal head")
	for name_v: Variant in ambush_expect:
		failed += _assert(int(ambush.fighter_dict(str(name_v)).get("turns", -1)) == 1, "%s acted once in the ambush round" % str(name_v))
	failed += _resolver_tie_order()
	failed += _resolver_swift_hook()
	failed += _resolver_skip_ko()
	failed += _resolver_round_cap()
	failed += _resolver_midround_save()
	failed += _resolver_fight_ends()
	if failed == 0:
		print("RESOLVER_TURN_ORDER_OK")
	return failed


func _resolver_tie_order() -> int:
	var failed: int = 0
	var fight: FightState = FightStateScript.new()
	fight.add_fighter("b0", "beast", _resolver_tank(4), 0, "front", "physical")
	fight.add_fighter("p2", "party", _resolver_tank(4), 2, "front", "physical", "", "keeper")
	fight.add_fighter("p0", "party", _resolver_tank(4), 0, "front", "physical", "", "elaia")
	fight.add_fighter("b1", "beast", _resolver_tank(4), 1, "front", "physical")
	fight.add_fighter("pfast", "party", _resolver_tank(9), 1, "front", "physical", "", "keeper")
	fight.start_fight()
	failed += _resolver_same_ids(fight.order, ["pfast", "p0", "p2", "b0", "b1"], "ties: party, then slot")
	return failed


func _resolver_swift_hook() -> int:
	## The bonus is applied after round 1 is built, so only the next rebuild sees it.
	var failed: int = 0
	var fight := _ResolverSwiftHook.new()
	fight.add_fighter("brute", "beast", _resolver_tank(5), 0, "front", "physical")
	fight.add_fighter("keeper", "party", _resolver_tank(4), 0, "front", "physical", "", "keeper")
	fight.start_fight()
	var round1: Array = fight.order.duplicate()
	failed += _resolver_same_ids(round1, ["brute", "keeper"], "hook fight round 1")
	fight.bumped_id = "keeper"
	fight.bonus = 10
	failed += _resolver_same_ids(fight.order, round1, "swiftness hook does not rebuild the current round")
	fight.set_scripted_dice(_resolver_miss_faces(2))
	var actors: Array[String] = []
	for _i: int in 2:
		var stepped: Dictionary = _resolver_step_auto(fight)
		failed += _assert(str(stepped.get("error", "")) == "", "hook step error")
		actors.append(str(stepped.get("actor", "")))
	failed += _resolver_same_ids(actors, ["brute", "keeper"], "round 1 actors stay on the old order")
	failed += _assert(fight.round == 2, "hook fight reached round 2 (got %d)" % fight.round)
	failed += _resolver_same_ids(fight.order, ["keeper", "brute"], "next round uses effective_swiftness")
	failed += _assert(fight.current_actor() == "keeper", "round 2 opens on the hooked fighter")
	failed += _assert(fight.scripted_underrun() == 0 and fight.scripted_remaining() == 0, "hook fight dice")
	return failed


func _resolver_skip_ko() -> int:
	var failed: int = 0
	var already: FightState = FightStateScript.new()
	already.add_fighter("down", "party", _resolver_tank(20), 0, "front", "physical", "", "keeper")
	already.add_fighter("up", "party", _resolver_tank(5), 1, "front", "physical", "", "elaia")
	already.add_fighter("mob", "beast", _resolver_tank(1), 0, "front", "physical")
	already.set_hp("down", 0)
	already.start_fight()
	already.set_scripted_dice(_resolver_miss_faces(2))
	var already_actors: Array[String] = []
	for _i: int in 2:
		var stepped: Dictionary = _resolver_step_auto(already)
		failed += _assert(str(stepped.get("error", "")) == "", "pre-ko step error %s" % str(stepped.get("error", "")))
		already_actors.append(str(stepped.get("actor", "")))
	failed += _resolver_same_ids(already_actors, ["up", "mob"], "a fighter who starts knocked out never acts")
	failed += _assert(int(already.fighter_dict("down").get("turns", -1)) == 0, "knocked-out fighter gains no turns")
	failed += _assert(str(already.fighter_dict("down").get("status", "")) == "ko", "party at the threshold is knocked out")
	failed += _assert(already.scripted_remaining() == 0 and already.scripted_underrun() == 0, "skipped fighter consumes no dice")
	var mid: FightState = FightStateScript.new()
	var striker: Dictionary = _resolver_tank(10)
	striker["might"] = 30
	mid.add_fighter("striker", "party", striker, 0, "front", "physical", "", "keeper")
	var victim: Dictionary = _resolver_tank(5)
	victim["resilience"] = 0
	victim["ward"] = 0
	victim["vitality"] = 1
	mid.add_fighter("victim", "beast", victim, 0, "front", "physical")
	mid.add_fighter("other", "beast", _resolver_tank(3), 1, "front", "physical")
	var mid_faces: Array = [6, 6, 1, 1, 10]
	mid_faces.append_array(_resolver_miss_faces(1))
	mid.set_scripted_dice(mid_faces)
	mid.start_fight()
	var mid_actors: Array[String] = []
	for _j: int in 2:
		var mid_step: Dictionary = _resolver_step_auto(mid)
		failed += _assert(str(mid_step.get("error", "")) == "", "mid-round step error %s" % str(mid_step.get("error", "")))
		mid_actors.append(str(mid_step.get("actor", "")))
	failed += _resolver_same_ids(mid_actors, ["striker", "other"], "a beast calmed mid-round loses that turn")
	failed += _assert(str(mid.fighter_dict("victim").get("status", "")) == "calmed", "the dropped beast is Calmed")
	failed += _assert(int(mid.fighter_dict("victim").get("turns", -1)) == 0, "calmed beast gains no turns")
	failed += _assert(mid.outcome() == "" and mid.round == 2, "the other beast keeps the fight going")
	failed += _assert(mid.scripted_underrun() == 0 and mid.scripted_remaining() == 0, "mid-round skip dice")
	var party_drop: FightState = FightStateScript.new()
	var bruiser: Dictionary = _resolver_tank(10)
	bruiser["might"] = 30
	party_drop.add_fighter("bruiser", "beast", bruiser, 0, "front", "physical")
	var keeper_stats: Dictionary = _resolver_tank(5)
	keeper_stats["resilience"] = 0
	keeper_stats["ward"] = 0
	keeper_stats["vitality"] = 1
	party_drop.add_fighter("keeper", "party", keeper_stats, 0, "front", "physical", "", "keeper")
	party_drop.add_fighter("elaia", "party", _resolver_tank(1), 1, "front", "physical", "", "elaia")
	var drop_faces: Array = [6, 6, 1, 1, 10]
	drop_faces.append_array(_resolver_miss_faces(1))
	party_drop.set_scripted_dice(drop_faces)
	party_drop.start_fight()
	var drop_actors: Array[String] = []
	for _k: int in 2:
		var drop_step: Dictionary = _resolver_step_auto(party_drop)
		failed += _assert(str(drop_step.get("error", "")) == "", "party drop step error %s" % str(drop_step.get("error", "")))
		drop_actors.append(str(drop_step.get("actor", "")))
	failed += _resolver_same_ids(drop_actors, ["bruiser", "elaia"], "a party member knocked out mid-round loses that turn")
	failed += _assert(str(party_drop.fighter_dict("keeper").get("status", "")) == "ko", "the dropped party member is knocked out")
	failed += _assert(int(party_drop.fighter_dict("keeper").get("turns", -1)) == 0, "knocked-out member gains no turns")
	failed += _assert(party_drop.scripted_underrun() == 0 and party_drop.scripted_remaining() == 0, "party drop dice")
	return failed


func _resolver_round_cap() -> int:
	var failed: int = 0
	var fight: FightState = FightStateScript.new()
	fight.set_combat_seed(60)
	fight.add_fighter("a", "party", _resolver_tank(3), 0, "front", "physical", "", "keeper")
	fight.add_fighter("b", "beast", _resolver_tank(2), 0, "front", "physical")
	fight.start_fight()
	var seen_at: int = -1
	var seen_outcome: String = ""
	var closing: Dictionary = {}
	for n: int in range(1, 130):
		var stepped: Dictionary = _resolver_step_auto(fight)
		if fight.outcome() != "":
			seen_at = n
			seen_outcome = fight.outcome()
			closing = stepped
			break
		failed += _assert(str(stepped.get("error", "")) == "", "cap step %d error %s" % [n, str(stepped.get("error", ""))])
		failed += _assert(fight.round <= 60, "round stayed within the cap during step %d" % n)
	failed += _assert(seen_outcome == "flee", "round cap outcome is flee (got %s at step %d)" % [seen_outcome, seen_at])
	failed += _assert(seen_at == 120, "flee after both fighters have acted for 60 rounds (step %d)" % seen_at)
	failed += _assert(fight.round == 60, "flee leaves the round at 60 (got %d)" % fight.round)
	failed += _assert(str(closing.get("round", "")) == "60" and str(closing.get("outcome", "")) == "flee", "the closing step reports round 60 and flee")
	failed += _assert(str(closing.get("actor", "")) != "" and str(closing.get("error", "")) == "", "the closing step still resolved an action")
	failed += _assert(fight.current_actor() == "", "no actor after flee")
	var hp_a: int = int(fight.fighter_dict("a").get("hp", -1))
	var hp_b: int = int(fight.fighter_dict("b").get("hp", -1))
	failed += _assert(hp_a == int(fight.fighter_dict("a").get("max_hp", -2)) and hp_b == int(fight.fighter_dict("b").get("max_hp", -2)), "the cap pair never hurt each other")
	var state_before: String = str(fight.to_dict().get("rng_combat_state", ""))
	var extra: Dictionary = fight.step({})
	failed += _assert(str(extra.get("error", "")) == "fight over" and str(extra.get("outcome", "")) == "flee", "no step runs after flee")
	failed += _assert(str(fight.to_dict().get("rng_combat_state", "")) == state_before, "a step after flee consumes no dice")
	var parsed: Variant = JSON.parse_string(JSON.stringify(fight.to_dict()))
	failed += _assert(parsed is Dictionary, "flee save json")
	if parsed is Dictionary:
		var copy: FightState = FightStateScript.from_dict(parsed)
		failed += _assert(copy.outcome() == "flee" and copy.current_actor() == "" and copy.round == 60, "a flee save resumes ended")
		var copy_step: Dictionary = copy.step({})
		failed += _assert(str(copy_step.get("error", "")) == "fight over", "a loaded flee save does not take another step")
		failed += _assert(int(copy.fighter_dict("a").get("hp", -1)) == hp_a, "loading the flee save does not change hp")
	return failed


func _resolver_midround_save() -> int:
	var failed: int = 0
	var fight: FightState = FightStateScript.new()
	fight.set_combat_seed(20261010)
	fight.add_fighter("keeper", "party", _resolver_tank(9), 0, "front", "physical", "", "keeper")
	fight.add_fighter("imp", "beast", _resolver_tank(6), 0, "front", "physical")
	fight.add_fighter("moth", "beast", _resolver_tank(7), 1, "front", "physical")
	fight.start_fight()
	var first: Dictionary = _resolver_step_auto(fight)
	failed += _assert(str(first.get("error", "")) == "" and str(first.get("actor", "")) == "keeper", "save setup acts as the keeper")
	failed += _assert(fight.current_actor() == "moth" and fight.round == 1, "the save is mid-round")
	var snap: Dictionary = fight.to_dict()
	var parsed: Variant = JSON.parse_string(JSON.stringify(snap))
	failed += _assert(parsed is Dictionary, "mid-round json")
	if parsed is not Dictionary:
		return failed + 1
	var copy: FightState = FightStateScript.from_dict(parsed)
	failed += _assert(copy.current_actor() == fight.current_actor(), "reloaded next actor")
	failed += _assert(copy.round == fight.round and copy.turn_cursor == fight.turn_cursor, "reloaded round and cursor")
	failed += _assert(copy.outcome() == "", "reloaded fight is still going")
	failed += _resolver_same_ids(copy.order, fight.order, "reloaded order")
	for n: int in 4:
		var left: Dictionary = _resolver_step_auto(fight)
		var right: Dictionary = _resolver_step_auto(copy)
		if left != right:
			print("STEP A ", JSON.stringify(left))
			print("STEP B ", JSON.stringify(right))
		failed += _assert(left == right, "step %d matches after a mid-round reload" % n)
	var again: Dictionary = copy.to_dict()
	var live: Dictionary = fight.to_dict()
	if again != live:
		print("SAVE A ", JSON.stringify(live))
		print("SAVE B ", JSON.stringify(again))
	failed += _assert(again == live, "fight dict matches after the reloaded steps")
	return failed


func _resolver_fight_ends() -> int:
	var failed: int = 0
	var win: FightState = FightStateScript.new()
	var keeper: Dictionary = _resolver_tank(10)
	keeper["might"] = 30
	win.add_fighter("keeper", "party", keeper, 0, "front", "physical", "", "keeper")
	var imp: Dictionary = _resolver_tank(1)
	imp["resilience"] = 0
	imp["ward"] = 0
	imp["vitality"] = 1
	win.add_fighter("imp", "beast", imp, 0, "front", "physical")
	win.set_scripted_dice([6, 6, 1, 1, 10])
	win.start_fight()
	var won: Dictionary = win.step({"kind": "strike", "target": "imp"})
	failed += _assert(str(won.get("outcome", "")) == "win" and win.outcome() == "win", "all beasts Calmed is a win")
	failed += _assert(str(win.fighter_dict("imp").get("status", "")) == "calmed", "win calms the beast")
	failed += _assert(win.current_actor() == "", "win has no next actor")
	failed += _assert(int(win.fighter_dict("imp").get("turns", -1)) == 0, "a calmed beast does not act after the winning blow")
	failed += _assert(win.scripted_underrun() == 0 and win.scripted_remaining() == 0, "winning blow dice")
	var idle: Dictionary = win.step({})
	failed += _assert(str(idle.get("error", "")) == "fight over" and win.scripted_remaining() == 0 and win.scripted_underrun() == 0, "no step runs after a win")
	var loss: FightState = FightStateScript.new()
	var bruiser: Dictionary = _resolver_tank(10)
	bruiser["might"] = 30
	loss.add_fighter("bruiser", "beast", bruiser, 0, "front", "physical")
	var fallen: Dictionary = _resolver_tank(1)
	fallen["resilience"] = 0
	fallen["ward"] = 0
	fallen["vitality"] = 1
	loss.add_fighter("keeper", "party", fallen, 0, "front", "physical", "", "keeper")
	loss.set_scripted_dice([6, 6, 1, 1, 10, 9])
	loss.start_fight()
	var lost: Dictionary = loss.step({})
	failed += _assert(str(lost.get("actor", "")) == "bruiser" and str(lost.get("outcome", "")) == "overwhelmed", "all party knocked out is overwhelmed")
	failed += _assert(str(loss.fighter_dict("keeper").get("status", "")) == "ko", "overwhelmed knocks the party out")
	failed += _assert(loss.current_actor() == "" and int(loss.fighter_dict("keeper").get("turns", -1)) == 0, "overwhelmed ends before the party acts")
	failed += _assert(loss.scripted_remaining() == 1 and loss.scripted_underrun() == 0, "overwhelmed does not roll a die past the blow")
	var idle_loss: Dictionary = loss.step({"kind": "strike", "target": "bruiser"})
	failed += _assert(str(idle_loss.get("error", "")) == "fight over" and loss.scripted_remaining() == 1, "no step runs after overwhelmed")
	return failed


func _resolver_rows() -> int:
	var failed: int = 0
	var fight: FightState = FightStateScript.new()
	fight.add_fighter("melee", "party", _resolver_tank(9), 0, "front", "physical", "", "keeper")
	var ranged_stats: Dictionary = _resolver_tank(8)
	ranged_stats["arcana"] = 8
	fight.add_fighter("ranged", "party", ranged_stats, 1, "back", "magic", "", "elaia")
	fight.add_fighter("front", "beast", _resolver_tank(2), 0, "front", "physical")
	fight.add_fighter("back", "beast", _resolver_tank(1), 1, "back", "physical")
	fight.add_fighter("asleep", "beast", _resolver_tank(1), 2, "front", "physical")
	fight.set_hp("asleep", 0)
	fight.start_fight()
	failed += _resolver_same_ids(fight.legal_targets("melee"), ["front"], "melee reaches only the standing front row")
	failed += _resolver_same_ids(fight.legal_targets("ranged"), ["front", "back"], "ranged reaches both rows")
	failed += _assert(fight.to_hit_mod_for("ranged", "front") == 0, "ranged into the front row is +0")
	failed += _assert(fight.to_hit_mod_for("ranged", "back") == -2, "ranged into the back row is -2 while the front stands")
	failed += _assert(fight.to_hit_mod_for("melee", "back") == 0, "melee carries no row penalty")
	failed += _assert(not fight.legal_targets("melee").has("asleep") and not fight.legal_targets("ranged").has("asleep"), "a Calmed beast is not a target")
	fight.set_scripted_dice([1, 1, 6, 6, 2, 2])
	var before: int = fight.scripted_remaining()
	var cursor: int = fight.turn_cursor
	var bad: Dictionary = fight.step({"kind": "strike", "target": "back"})
	failed += _assert(str(bad.get("error", "")) == "illegal target", "melee into the back row is refused (got %s)" % str(bad.get("error", "")))
	failed += _assert(fight.scripted_remaining() == before and fight.scripted_underrun() == 0, "an illegal target consumes no dice")
	failed += _assert(int(fight.fighter_dict("melee").get("turns", -1)) == 0, "an illegal target spends no turn")
	failed += _assert(fight.current_actor() == "melee" and fight.turn_cursor == cursor and fight.round == 1, "an illegal target leaves the cursor")
	var bad_kind: Dictionary = fight.step({"kind": "focus"})
	failed += _assert(str(bad_kind.get("error", "")) == "illegal action", "an unknown action is refused")
	var bad_ally: Dictionary = fight.step({"kind": "strike", "target": "ranged"})
	failed += _assert(str(bad_ally.get("error", "")) == "illegal target", "an ally is not a target")
	var bad_asleep: Dictionary = fight.step({"kind": "strike", "target": "asleep"})
	failed += _assert(str(bad_asleep.get("error", "")) == "illegal target", "a Calmed beast is refused")
	var bad_missing: Dictionary = fight.step({"kind": "strike", "target": "nobody"})
	failed += _assert(str(bad_missing.get("error", "")) == "illegal target", "a missing id is refused")
	failed += _assert(fight.scripted_remaining() == before and fight.current_actor() == "melee", "refused actions leave the dice and the turn")
	var good: Dictionary = fight.step({"kind": "strike", "target": "front"})
	failed += _assert(str(good.get("error", "")) == "" and str(good.get("target", "")) == "front", "melee can strike the front row")
	failed += _assert(fight.scripted_remaining() == 2 and fight.scripted_underrun() == 0, "the legal strike consumes the miss and nothing more")
	failed += _assert(int(fight.fighter_dict("melee").get("turns", -1)) == 1, "the legal strike spends the turn")
	fight.set_hp("front", 0)
	failed += _resolver_same_ids(fight.legal_targets("melee"), ["back"], "melee reaches the back row once the front is empty")
	failed += _resolver_same_ids(fight.legal_targets("ranged"), ["back"], "ranged no longer lists the Calmed front")
	failed += _assert(fight.to_hit_mod_for("ranged", "back") == 0, "the back-row penalty drops once the front is empty")
	var opened: FightState = FightStateScript.new()
	opened.add_fighter("melee", "party", _resolver_tank(9), 0, "front", "physical", "", "keeper")
	opened.add_fighter("front", "beast", _resolver_tank(1), 0, "front", "physical")
	opened.add_fighter("back", "beast", _resolver_tank(1), 1, "back", "physical")
	opened.set_hp("front", 0)
	opened.start_fight()
	opened.set_scripted_dice(_resolver_miss_faces(1))
	var opened_step: Dictionary = opened.step({"kind": "strike", "target": "back"})
	failed += _assert(str(opened_step.get("error", "")) == "" and str(opened_step.get("target", "")) == "back", "melee can strike the back row once the front is empty")
	failed += _assert(opened.scripted_remaining() == 0 and opened.scripted_underrun() == 0, "that back-row strike consumes the miss")
	failed += _resolver_ranged_penalty(true, 15)
	failed += _resolver_ranged_penalty(false, 17)
	failed += _resolver_back_row_beast()
	if failed == 0:
		print("RESOLVER_ROWS_OK")
	return failed


func _resolver_ranged_penalty(front_alive: bool, want_total: int) -> int:
	var failed: int = 0
	var fight: FightState = FightStateScript.new()
	var ranged: Dictionary = _resolver_tank(10)
	ranged["arcana"] = 8
	fight.add_fighter("ranged", "party", ranged, 0, "front", "magic", "", "keeper")
	var beast: Dictionary = _resolver_tank(1)
	beast["ward"] = 3
	beast["resilience"] = 1
	fight.add_fighter("front", "beast", beast, 0, "front", "physical")
	fight.add_fighter("back", "beast", beast.duplicate(), 1, "back", "physical")
	if not front_alive:
		fight.set_hp("front", 0)
	fight.start_fight()
	failed += _assert(fight.to_hit_mod_for("ranged", "back") == (-2 if front_alive else 0), "row penalty flag")
	fight.set_scripted_dice([4, 5, 1, 1, 3])
	var stepped: Dictionary = fight.step({"kind": "strike", "target": "back"})
	var blow: Dictionary = stepped.get("strike", {}) as Dictionary
	var label: String = "front standing" if front_alive else "front empty"
	failed += _assert(str(stepped.get("error", "")) == "", "ranged shot (%s) error %s" % [label, str(stepped.get("error", ""))])
	failed += _assert(int(blow.get("attack_total", -1)) == want_total, "ranged attack total %s got %s want %d" % [label, str(blow.get("attack_total")), want_total])
	failed += _assert(fight.scripted_remaining() == 0 and fight.scripted_underrun() == 0, "ranged shot dice (%s)" % label)
	return failed


func _resolver_back_row_beast() -> int:
	var failed: int = 0
	var fight: FightState = FightStateScript.new()
	var lurker: Dictionary = _resolver_tank(10)
	lurker["might"] = 12
	fight.add_fighter("lurker", "beast", lurker, 0, "back", "physical")
	var keeper: Dictionary = _resolver_tank(1)
	keeper["resilience"] = 4
	fight.add_fighter("keeper", "party", keeper, 0, "front", "physical", "", "keeper")
	var elaia: Dictionary = _resolver_tank(1)
	elaia["resilience"] = 1
	fight.add_fighter("elaia", "party", elaia, 1, "back", "physical", "", "elaia")
	fight.start_fight()
	failed += _assert(str(fight.fighter_dict("lurker").get("row", "")) == "back", "the melee beast stands in the back row")
	failed += _resolver_same_ids(fight.legal_targets("lurker"), ["keeper"], "a back-row melee beast reaches the front row")
	failed += _assert(fight.beast_target("lurker") == "keeper", "the back-row beast does not skip the fight to hit a softer back row")
	fight.set_scripted_dice([6, 6, 1, 1, 4])
	var elaia_hp: int = int(fight.fighter_dict("elaia").get("hp", -1))
	var stepped: Dictionary = fight.step({"kind": "strike", "target": "elaia"})
	failed += _assert(str(stepped.get("error", "")) == "" and str(stepped.get("kind", "")) == "strike", "a back-row melee beast can attack")
	failed += _assert(str(stepped.get("actor", "")) == "lurker" and str(stepped.get("target", "")) == "keeper", "the beast ignores the passed target and strikes the front")
	failed += _assert(int((stepped.get("strike", {}) as Dictionary).get("damage", 0)) > 0, "the back-row attack lands")
	failed += _assert(int(fight.fighter_dict("elaia").get("hp", -2)) == elaia_hp, "the unreachable back row is untouched")
	failed += _assert(int(fight.fighter_dict("lurker").get("turns", -1)) == 1, "the beast's attack spends its turn")
	failed += _assert(fight.scripted_remaining() == 0 and fight.scripted_underrun() == 0, "back-row beast dice")
	return failed


func _resolver_targeting() -> int:
	var failed: int = 0
	var cases: Dictionary = _json_dict("res://tests/fixtures/resolver_cases.json")
	var rows: Array = cases.get("beast_targeting", []) as Array
	failed += _assert(rows.size() == 2, "beast_targeting fixture has two cases")
	for row_v: Variant in rows:
		var row: Dictionary = row_v as Dictionary
		var built: Dictionary = _resolver_targeting_case(row)
		var fight: FightState = built.get("fight") as FightState
		var beast_id: String = str(built.get("beast_id", ""))
		failed += _resolver_same_ids(fight.legal_targets(beast_id), row.get("reachable", []) as Array, "%s reachable" % beast_id)
		failed += _assert(fight.beast_target(beast_id) == str(row.get("expect_target", "")), "%s targets %s, got %s" % [beast_id, str(row.get("expect_target", "")), fight.beast_target(beast_id)])
	failed += _resolver_target_ties()
	failed += _resolver_beast_ignores_action()
	if failed == 0:
		print("RESOLVER_TARGETING_OK")
	return failed


func _resolver_target_ties() -> int:
	var failed: int = 0
	var physical: FightState = FightStateScript.new()
	physical.add_fighter("imp", "beast", _resolver_tank(4), 0, "front", "physical")
	physical.add_member("p1", _resolver_target_stats(5, 9), 2, "front", "p1")
	physical.add_member("p0", _resolver_target_stats(5, 9), 0, "front", "p0")
	physical.add_member("pb", _resolver_target_stats(5, 9), 0, "back", "pb")
	physical.add_member("pweak", _resolver_target_stats(1, 1), 1, "back", "pweak")
	physical.start_fight()
	failed += _resolver_same_ids(physical.legal_targets("imp"), ["p0", "p1"], "melee tie reach is the front row only")
	failed += _assert(physical.beast_target("imp") == "p0", "equal Resilience breaks to the front row, then the lower slot")
	physical.set_hp("p0", 0)
	physical.set_hp("p1", 0)
	failed += _resolver_same_ids(physical.legal_targets("imp"), ["pb", "pweak"], "once the front drops, the back row is reachable")
	failed += _assert(physical.beast_target("imp") == "pweak", "the newly reachable weaker member is picked")
	var magic: FightState = FightStateScript.new()
	var moth: Dictionary = _resolver_tank(8)
	moth["attack"] = "magic"
	magic.add_fighter("moth", "beast", moth, 0, "front", "magic")
	magic.add_member("front_hi", _resolver_target_stats(1, 4), 2, "front", "front_hi")
	magic.add_member("front_lo", _resolver_target_stats(9, 4), 0, "front", "front_lo")
	magic.add_member("back_lo", _resolver_target_stats(1, 4), 0, "back", "back_lo")
	magic.start_fight()
	failed += _resolver_same_ids(magic.legal_targets("moth"), ["front_lo", "front_hi", "back_lo"], "magic reach lists both rows")
	failed += _assert(magic.beast_target("moth") == "front_lo", "equal Ward breaks to the front row, then slot")
	return failed


func _resolver_beast_ignores_action() -> int:
	var failed: int = 0
	var fight: FightState = _resolver_targeting_case({"beast": "acorn_imp", "party": [{"name": "Keeper", "row": "front", "res": 6, "ward": 5}, {"name": "Elaia", "row": "back", "res": 5, "ward": 7}]})["fight"] as FightState
	fight.set_scripted_dice([6, 6, 1, 1, 6])
	var elaia_hp: int = int(fight.fighter_dict("Elaia").get("hp", -1))
	failed += _assert(fight.current_actor() == "acorn_imp", "the imp acts first in the ignore-action setup")
	var stepped: Dictionary = fight.step({"kind": "strike", "target": "Elaia"})
	failed += _assert(str(stepped.get("error", "")) == "", "beast step error %s" % str(stepped.get("error", "")))
	failed += _assert(str(stepped.get("target", "")) == "Keeper", "a beast strikes its own target, not the passed one")
	failed += _assert(int(fight.fighter_dict("Elaia").get("hp", -2)) == elaia_hp, "the passed target is not struck")
	failed += _assert(int(fight.fighter_dict("Keeper").get("hp", 999)) < int(fight.fighter_dict("Keeper").get("max_hp", 0)), "the chosen target lost HP")
	failed += _assert(fight.scripted_remaining() == 0 and fight.scripted_underrun() == 0, "beast strike dice")
	return failed


func _resolver_targeting_case(row: Dictionary) -> Dictionary:
	var fight: FightState = FightStateScript.new()
	var party: Array = row.get("party", []) as Array
	var slot: int = 0
	for member_v: Variant in party:
		var member: Dictionary = member_v as Dictionary
		var stats: Dictionary = _resolver_target_stats(int(member.get("res", 0)), int(member.get("ward", 0)))
		stats["swiftness"] = 1
		var member_name: String = str(member.get("name", ""))
		fight.add_member(member_name, stats, slot, str(member.get("row", "front")), member_name)
		slot += 1
	var beast_id: String = str(row.get("beast", ""))
	fight.add_beast(beast_id, 0, "front")
	fight.start_fight()
	return {"fight": fight, "beast_id": beast_id}


func _resolver_target_stats(resilience: int, ward: int) -> Dictionary:
	return {
		"might": 1, "arcana": 1, "resilience": resilience, "ward": ward,
		"vitality": 8, "swiftness": 4, "fate": 0,
	}


func _resolver_order_fight(use_ambush: bool) -> FightState:
	var fight: FightState = FightStateScript.new()
	fight.ambush = use_ambush
	var cases: Dictionary = _json_dict("res://tests/fixtures/resolver_cases.json")
	var block: Dictionary = cases.get("turn_order", {}) as Dictionary
	for row_v: Variant in block.get("fighters", []) as Array:
		var row: Dictionary = row_v as Dictionary
		var fighter_name: String = str(row.get("name", ""))
		var stats: Dictionary = _resolver_tank(int(row.get("swiftness", 0)))
		var slot: int = int(row.get("slot", 0))
		if str(row.get("side", "")) == "party":
			fight.add_member(fighter_name, stats, slot, "front", fighter_name)
		else:
			fight.add_fighter(fighter_name, "beast", stats, slot, "front", "physical")
	fight.start_fight()
	return fight


func _resolver_tank(swiftness: int) -> Dictionary:
	return {
		"might": 1, "arcana": 1, "resilience": 40, "ward": 40,
		"vitality": 8, "swiftness": swiftness, "fate": 0,
	}


func _resolver_miss_faces(actions: int) -> Array:
	var faces: Array = []
	for _i: int in actions:
		faces.append_array([1, 1, 6, 6])
	return faces


func _resolver_brace() -> int:
	## Braced defense through a real step, halving, and the die that exists only while braced.
	var failed: int = 0
	failed += _resolver_brace_fixture()
	failed += _resolver_brace_best_two()
	failed += _resolver_brace_halve()
	failed += _resolver_brace_minimum()
	if failed == 0:
		print("RESOLVER_BRACE_OK")
	return failed


func _resolver_brace_fixture() -> int:
	## s4_line3 through Brace, then the same keeper's next turn drops it.
	var failed: int = 0
	var fight: FightState = FightStateScript.new()
	var keeper: Dictionary = {
		"might": 1, "arcana": 1, "resilience": 6, "ward": 5,
		"vitality": 8, "swiftness": 7, "fate": 0,
	}
	fight.add_member("Keeper", keeper, 0, "front", "Keeper")
	fight.add_beast("acorn_imp", 0, "front", "Acorn imp A")
	fight.start_fight()
	failed += _assert(fight.current_actor() == "Keeper", "the keeper braces before the imp swings")
	var queued: Array = [4, 5, 6, 5, 1, 1, 1, 6, 6, 1, 1, 6, 6, 9]
	fight.set_scripted_dice(queued)
	var braced: Dictionary = fight.step({"kind": "brace"})
	failed += _assert(str(braced.get("error", "")) == "" and str(braced.get("kind", "")) == "brace", "brace spends the turn")
	failed += _assert(bool(fight.fighter_dict("Keeper").get("brace", false)), "brace is up after the action")
	failed += _assert(int(fight.fighter_dict("Keeper").get("turns", -1)) == 1, "brace counts as the keeper's turn")
	failed += _assert(fight.scripted_remaining() == queued.size() and fight.scripted_underrun() == 0, "brace consumes no dice")
	var blow_step: Dictionary = fight.step({})
	var blow: Dictionary = blow_step.get("strike", {}) as Dictionary
	failed += _assert(str(blow_step.get("actor", "")) == "Acorn imp A" and str(blow_step.get("error", "")) == "", "the imp strikes the braced keeper")
	failed += _assert(int(blow.get("attack_total", -1)) == 16, "brace example attack total (got %s)" % str(blow.get("attack_total", "")))
	failed += _assert(int(blow.get("defense_total", -1)) == 17, "brace example defense total (got %s)" % str(blow.get("defense_total", "")))
	failed += _assert(str(blow.get("band", "")) == "miss" and int(blow.get("damage", -1)) == 0, "keeping 6+5 misses the attack of 16")
	failed += _assert(bool(fight.fighter_dict("Keeper").get("brace", false)), "brace holds through the enemies' turns")
	failed += _assert(fight.scripted_remaining() == 9 and fight.scripted_underrun() == 0, "the braced defense consumed the third die")
	var keeper_turn: Dictionary = fight.step({"kind": "strike", "target": "Acorn imp A"})
	failed += _assert(str(keeper_turn.get("error", "")) == "", "the keeper's next turn resolves (%s)" % str(keeper_turn.get("error", "")))
	failed += _assert(not bool(fight.fighter_dict("Keeper").get("brace", true)), "brace clears when that turn starts")
	var open_step: Dictionary = fight.step({})
	var open_blow: Dictionary = open_step.get("strike", {}) as Dictionary
	failed += _assert(str(open_step.get("error", "")) == "" and str(open_blow.get("band", "")) == "miss", "the later swing is an ordinary miss")
	failed += _assert(fight.scripted_remaining() == 1 and fight.scripted_underrun() == 0, "an unbraced defense leaves the extra die")
	var left: Array = fight.scripted_queue()
	failed += _assert(left.size() == 1 and int(left[0]) == 9, "the spare face is the die Brace would have rolled")
	return failed


func _resolver_brace_best_two() -> int:
	## [1, 2, 6] keeps 8. The first two alone would be a graze and would roll damage.
	var failed: int = 0
	var fight: FightState = FightStateScript.new()
	var keeper: Dictionary = {
		"might": 1, "arcana": 1, "resilience": 6, "ward": 1,
		"vitality": 8, "swiftness": 7, "fate": 0,
	}
	var imp: Dictionary = {
		"might": 7, "arcana": 1, "resilience": 1, "ward": 1,
		"vitality": 8, "swiftness": 1, "fate": 0,
	}
	fight.add_member("keeper", keeper, 0, "front", "keeper")
	fight.add_fighter("imp", "beast", imp, 0, "front", "physical")
	fight.start_fight()
	var setup: Dictionary = fight.step({"kind": "brace"})
	failed += _assert(str(setup.get("error", "")) == "", "best-two setup braces")
	fight.set_scripted_dice([1, 1, 1, 2, 6])
	var stepped: Dictionary = fight.step({})
	var blow: Dictionary = stepped.get("strike", {}) as Dictionary
	failed += _assert(int(blow.get("attack_total", -1)) == 9, "best-two attack total")
	failed += _assert(int(blow.get("defense_total", -1)) == 14, "best two of 1,2,6 is 8 plus guard 6 (got %s)" % str(blow.get("defense_total", "")))
	failed += _assert(str(blow.get("band", "")) == "miss" and int(blow.get("damage", -1)) == 0, "the kept third die is a miss, not a graze")
	failed += _assert(fight.scripted_remaining() == 0 and fight.scripted_underrun() == 0, "best-two consumes three defense dice and no damage die")
	return failed


func _resolver_brace_halve() -> int:
	## Same graze: 3 unbraced, 2 braced (3 / 2 rounds half up).
	var failed: int = 0
	var open: Dictionary = _resolver_fixed_blow(false, 4, 0, [4, 4, 6, 6, 1])
	var shut: Dictionary = _resolver_fixed_blow(true, 4, 0, [4, 4, 6, 6, 1, 1])
	failed += _assert(int(open.get("damage", -1)) == 3, "unbraced graze of raw 5 is 3 (got %s)" % str(open.get("damage", "")))
	failed += _assert(int(shut.get("damage", -1)) == 2, "brace halves 3 to 2 (got %s)" % str(shut.get("damage", "")))
	failed += _assert(int(open.get("hp", -1)) == int(open.get("max_hp", 0)) - 3, "unbraced HP drops by 3")
	failed += _assert(int(shut.get("hp", -1)) == int(shut.get("max_hp", 0)) - 2, "braced HP drops by 2")
	failed += _assert(int(shut.get("underrun", -1)) == 0 and int(shut.get("remaining", -1)) == 0, "halve probe dice")
	return failed


func _resolver_brace_minimum() -> int:
	## Half of 1 rounds to 1, so a braced chip still lands.
	var failed: int = 0
	var shut: Dictionary = _resolver_fixed_blow(true, 1, 12, [6, 6, 1, 1, 1, 1])
	failed += _assert(int(shut.get("damage", -1)) == 1, "brace keeps a minimum of 1 (got %s)" % str(shut.get("damage", "")))
	failed += _assert(int(shut.get("hp", -1)) == int(shut.get("max_hp", 0)) - 1, "the minimum chip still comes off HP")
	failed += _assert(int(shut.get("underrun", -1)) == 0 and int(shut.get("remaining", -1)) == 0, "minimum probe dice")
	return failed


func _resolver_fixed_blow(use_brace: bool, might: int, resilience: int, faces: Array) -> Dictionary:
	var fight: FightState = FightStateScript.new()
	var keeper: Dictionary = {
		"might": 1, "arcana": 1, "resilience": resilience, "ward": 0,
		"vitality": 8, "swiftness": 0, "fate": 0,
	}
	var imp: Dictionary = {
		"might": might, "arcana": 1, "resilience": 40, "ward": 40,
		"vitality": 8, "swiftness": 0, "fate": 0,
	}
	fight.add_member("keeper", keeper, 0, "front", "keeper")
	fight.add_fighter("imp", "beast", imp, 0, "front", "physical")
	fight.start_fight()
	if use_brace:
		var setup: Dictionary = fight.step({"kind": "brace"})
		if str(setup.get("error", "")) != "":
			return {"damage": -1, "hp": -1, "max_hp": 0, "underrun": 1, "remaining": 1}
		fight.set_scripted_dice(faces)
		var stepped: Dictionary = fight.step({})
		var blow: Dictionary = stepped.get("strike", {}) as Dictionary
		var card: Dictionary = fight.fighter_dict("keeper")
		return {
			"damage": blow.get("damage", -1),
			"hp": card.get("hp", -1),
			"max_hp": card.get("max_hp", 0),
			"underrun": fight.scripted_underrun(),
			"remaining": fight.scripted_remaining(),
		}
	fight.set_scripted_dice(faces)
	var direct: Dictionary = fight.strike("imp", "keeper", 0, 1)
	var open_card: Dictionary = fight.fighter_dict("keeper")
	return {
		"damage": direct.get("damage", -1),
		"hp": open_card.get("hp", -1),
		"max_hp": open_card.get("max_hp", 0),
		"underrun": fight.scripted_underrun(),
		"remaining": fight.scripted_remaining(),
	}


func _resolver_shield_order() -> int:
	## Brace halves, then the shield absorbs. The other order leaves a different HP.
	var failed: int = 0
	failed += _resolver_sap_amounts()
	var soft: Dictionary = {
		"might": 1, "arcana": 1, "resilience": 0, "ward": 0,
		"vitality": 1, "swiftness": 0, "fate": 0,
	}
	var hitter: Dictionary = {
		"might": 8, "arcana": 1, "resilience": 40, "ward": 40,
		"vitality": 8, "swiftness": 0, "fate": 0,
	}
	var control: FightState = FightStateScript.new()
	control.twist = "sap_spring"
	control.add_member("keeper", soft, 0, "front", "keeper")
	control.add_fighter("imp", "beast", hitter, 0, "front", "physical")
	control.start_fight()
	failed += _assert(int(control.fighter_dict("keeper").get("shield", -1)) == 3, "the order probe starts with shield 3")
	control.set_scripted_dice([3, 3, 6, 6, 1])
	var open: Dictionary = control.strike("imp", "keeper", 0, 1)
	failed += _assert(int(open.get("damage", -1)) == 5, "unbraced blow is 5 (got %s)" % str(open.get("damage", "")))
	failed += _assert(int(control.fighter_dict("keeper").get("hp", -1)) == 11, "shield 3 of 5 leaves HP 11 (got %s)" % str(control.fighter_dict("keeper").get("hp", "")))
	failed += _assert(int(control.fighter_dict("keeper").get("shield", -1)) == 0, "the unbraced shield is spent")
	failed += _assert(control.scripted_underrun() == 0 and control.scripted_remaining() == 0, "unbraced shield dice")
	var braced: FightState = FightStateScript.new()
	braced.twist = "sap_spring"
	braced.add_member("keeper", soft, 0, "front", "keeper")
	braced.add_fighter("imp", "beast", hitter, 0, "front", "physical")
	braced.start_fight()
	var setup: Dictionary = braced.step({"kind": "brace"})
	failed += _assert(str(setup.get("error", "")) == "", "shield-order brace")
	braced.set_scripted_dice([3, 3, 6, 6, 1, 1])
	var shut_step: Dictionary = braced.step({})
	var shut: Dictionary = shut_step.get("strike", {}) as Dictionary
	failed += _assert(int(shut.get("damage", -1)) == 3, "brace halves 5 to 3 before the shield (got %s)" % str(shut.get("damage", "")))
	failed += _assert(int(braced.fighter_dict("keeper").get("hp", -1)) == 13, "halve-then-shield leaves HP full (shield-then-halve would leave 12)")
	failed += _assert(int(braced.fighter_dict("keeper").get("shield", -1)) == 0, "the shield absorbed the halved 3")
	failed += _assert(braced.scripted_underrun() == 0 and braced.scripted_remaining() == 0, "braced shield dice")
	braced.set_scripted_dice([3, 3, 6, 6, 1, 1])
	braced.strike("imp", "keeper", 0, 1)
	failed += _assert(int(braced.fighter_dict("keeper").get("shield", -1)) == 0, "a spent shield stays at 0")
	failed += _assert(int(braced.fighter_dict("keeper").get("hp", -1)) == 10, "the next blow lands on HP once the shield is gone")
	var ticked: FightState = FightStateScript.new()
	ticked.twist = "sap_spring"
	var bulky: Dictionary = {
		"might": 1, "arcana": 1, "resilience": 40, "ward": 40,
		"vitality": 5, "swiftness": 5, "fate": 0,
	}
	ticked.add_member("keeper", bulky, 0, "front", "keeper")
	ticked.add_fighter("imp", "beast", _resolver_tank(1), 0, "front", "physical")
	ticked.start_fight()
	failed += _assert(int(ticked.fighter_dict("keeper").get("shield", -1)) == 5, "poison shield starts at 5")
	ticked.apply_poison("keeper", 9)
	ticked.set_scripted_dice([1, 1, 6, 6])
	var poisoned: Dictionary = ticked.step({"kind": "strike", "target": "imp"})
	failed += _assert(str(poisoned.get("error", "")) == "", "a covered tick still lets them strike")
	failed += _assert(int(ticked.fighter_dict("keeper").get("hp", -1)) == 25, "the shield absorbs the poison tick")
	failed += _assert(int(ticked.fighter_dict("keeper").get("shield", -1)) == 2, "tick 3 leaves shield 2 (got %s)" % str(ticked.fighter_dict("keeper").get("shield", "")))
	failed += _assert(int(ticked.fighter_dict("keeper").get("turns", -1)) == 1, "the absorbed tick did not cost the turn")
	failed += _assert(ticked.scripted_remaining() == 0 and ticked.scripted_underrun() == 0, "poison-shield strike dice")
	if failed == 0:
		print("RESOLVER_SHIELD_ORDER_OK")
	return failed


func _resolver_sap_amounts() -> int:
	var failed: int = 0
	var fight: FightState = FightStateScript.new()
	fight.twist = "sap_spring"
	var small: Dictionary = _resolver_tank(3)
	small["vitality"] = 1
	var large: Dictionary = _resolver_tank(2)
	large["vitality"] = 9
	fight.add_member("small", small, 0, "front", "small")
	fight.add_member("large", large, 1, "front", "large")
	fight.add_fighter("imp", "beast", _resolver_tank(1), 0, "front", "physical")
	fight.start_fight()
	failed += _assert(int(fight.fighter_dict("small").get("max_hp", 0)) == 13, "sap small max")
	failed += _assert(int(fight.fighter_dict("small").get("shield", -1)) == 3, "round_half_up(13 / 5) is 3")
	failed += _assert(int(fight.fighter_dict("large").get("max_hp", 0)) == 37, "sap large max")
	failed += _assert(int(fight.fighter_dict("large").get("shield", -1)) == 7, "round_half_up(37 / 5) is 7")
	failed += _assert(int(fight.fighter_dict("imp").get("shield", -1)) == 0, "Sap Spring does not shield beasts")
	return failed


func _resolver_poison_refresh() -> int:
	var failed: int = 0
	var cases: Dictionary = _json_dict("res://tests/fixtures/resolver_cases.json")
	var ops: Array = cases.get("poison_refresh", []) as Array
	failed += _assert(ops.size() == 11, "poison_refresh has 11 ops (got %d)" % ops.size())
	var fight: FightState = FightStateScript.new()
	var keeper: Dictionary = {
		"might": 1, "arcana": 1, "resilience": 1, "ward": 1,
		"vitality": 30, "swiftness": 1, "fate": 0, "hp": 100,
	}
	fight.add_member("keeper", keeper, 0, "front", "keeper")
	var index: int = 0
	for op_v: Variant in ops:
		var op: Dictionary = op_v as Dictionary
		var name: String = str(op.get("op", ""))
		if name == "apply":
			fight.apply_poison("keeper", int(op.get("total", 0)))
		else:
			fight.tick_poison("keeper")
		var card: Dictionary = fight.fighter_dict("keeper")
		failed += _assert(int(card.get("hp", -1)) == int(op.get("hp_after", -2)), "poison op %d hp %s vs %s" % [index, str(card.get("hp", "")), str(op.get("hp_after", ""))])
		var want_ticks: Array = op.get("ticks_left", []) as Array
		failed += _resolver_same_ints(_resolver_ticks(fight, "keeper"), want_ticks, "poison op %d ticks" % index)
		failed += _assert(_resolver_kept(card) == int(op.get("kept_total", -1)), "poison op %d kept %d vs %s" % [index, _resolver_kept(card), str(op.get("kept_total", ""))])
		index += 1
	failed += _resolver_poison_turn_start()
	failed += _resolver_poison_move()
	failed += _resolver_poison_continuation()
	if failed == 0:
		print("RESOLVER_POISON_REFRESH_OK")
	return failed


func _resolver_poison_turn_start() -> int:
	var failed: int = 0
	var ko: FightState = FightStateScript.new()
	var fragile: Dictionary = {
		"might": 30, "arcana": 1, "resilience": 0, "ward": 0,
		"vitality": 10, "swiftness": 9, "fate": 0,
	}
	var bystander: Dictionary = {
		"might": 1, "arcana": 1, "resilience": 0, "ward": 0,
		"vitality": 8, "swiftness": 1, "fate": 0, "hp": 20,
	}
	ko.add_member("keeper", fragile, 0, "front", "keeper")
	ko.add_fighter("imp", "beast", bystander, 0, "front", "physical")
	ko.start_fight()
	ko.set_hp("keeper", 5)
	ko.apply_poison("keeper", 9)
	ko.set_scripted_dice([6, 6, 1, 1, 8])
	var lost: Dictionary = ko.step({"kind": "strike", "target": "imp"})
	failed += _assert(str(ko.fighter_dict("keeper").get("status", "")) == "ko", "a tick can knock a member out")
	failed += _assert(int(ko.fighter_dict("keeper").get("hp", -1)) == 2, "the tick landed before the action (got %s)" % str(ko.fighter_dict("keeper").get("hp", "")))
	failed += _assert(int(ko.fighter_dict("keeper").get("turns", -1)) == 0, "the knocked-out member loses that turn")
	failed += _assert(ko.outcome() == "overwhelmed", "the tick can end the fight (got %s)" % ko.outcome())
	failed += _assert(int(ko.fighter_dict("imp").get("hp", -1)) == 20, "the lost turn deals no strike")
	failed += _assert(str(lost.get("outcome", "")) == "overwhelmed", "the step reports overwhelmed")
	failed += _assert(ko.scripted_remaining() == 5 and ko.scripted_underrun() == 0, "a lost turn consumes no dice")
	var calm: FightState = FightStateScript.new()
	var sturdy: Dictionary = _resolver_tank(1)
	sturdy["hp"] = 40
	var weak: Dictionary = {
		"might": 1, "arcana": 1, "resilience": 0, "ward": 0,
		"vitality": 1, "swiftness": 9, "fate": 0, "hp": 4,
	}
	calm.add_member("keeper", sturdy, 0, "front", "keeper")
	calm.add_fighter("imp", "beast", weak, 0, "front", "physical")
	calm.start_fight()
	calm.apply_poison("imp", 9)
	var keeper_hp: int = int(calm.fighter_dict("keeper").get("hp", -1))
	calm.set_scripted_dice([6, 6, 1, 1, 8])
	var ended: Dictionary = calm.step({})
	failed += _assert(str(calm.fighter_dict("imp").get("status", "")) == "calmed", "a tick can Calm a beast")
	failed += _assert(int(calm.fighter_dict("imp").get("hp", -1)) == 1, "beast tick hp (got %s)" % str(calm.fighter_dict("imp").get("hp", "")))
	failed += _assert(int(calm.fighter_dict("imp").get("turns", -1)) == 0, "a Calmed beast loses that turn")
	failed += _assert(calm.outcome() == "win" and str(ended.get("outcome", "")) == "win", "Calming the last beast wins")
	failed += _assert(int(calm.fighter_dict("keeper").get("hp", -2)) == keeper_hp, "the Calmed beast dealt no strike")
	failed += _assert(calm.scripted_remaining() == 5 and calm.scripted_underrun() == 0, "a Calmed turn consumes no dice")
	return failed


func _resolver_poison_move() -> int:
	## A magic poison move picks the lowest Ward it can reach and rolls no strike.
	var failed: int = 0
	var fight: FightState = FightStateScript.new()
	var front: Dictionary = {
		"might": 1, "arcana": 1, "resilience": 4, "ward": 8,
		"vitality": 10, "swiftness": 1, "fate": 0,
	}
	var back: Dictionary = {
		"might": 1, "arcana": 1, "resilience": 9, "ward": 2,
		"vitality": 10, "swiftness": 1, "fate": 0,
	}
	fight.add_member("front", front, 0, "front", "front")
	fight.add_member("back", back, 1, "back", "back")
	fight.add_beast("spore_moth", 0, "front", "moth")
	fight.set_boss("moth")
	fight.start_fight()
	failed += _assert(fight.beast_target("moth") == "back", "the moth's target is the lower Ward, in the back row")
	fight.set_scripted_dice(_resolver_miss_faces(5))
	var opening: Dictionary = fight.step({})
	failed += _assert(str(opening.get("kind", "")) == "strike" and str(opening.get("error", "")) == "", "turn 1 is still a strike")
	var front_step: Dictionary = fight.step({"kind": "strike", "target": "moth"})
	var back_step: Dictionary = fight.step({"kind": "strike", "target": "moth"})
	failed += _assert(str(front_step.get("error", "")) == "" and str(back_step.get("error", "")) == "", "the party answers the opening strike")
	var intent: Dictionary = _resolver_intent(fight, "moth")
	failed += _assert(str(intent.get("move", "")) == "poison", "a poison boss shows the move before turn 2")
	var back_hp: int = int(fight.fighter_dict("back").get("hp", -1))
	var front_hp: int = int(fight.fighter_dict("front").get("hp", -1))
	var before: int = fight.scripted_remaining()
	var poisoned: Dictionary = fight.step({})
	failed += _assert(str(poisoned.get("kind", "")) == "poison" and str(poisoned.get("target", "")) == "back", "the move poisons the Ward-weakest reachable member")
	failed += _assert(int(fight.fighter_dict("back").get("hp", -2)) == back_hp, "a poison move deals no strike")
	failed += _assert(int(fight.fighter_dict("front").get("hp", -2)) == front_hp, "the higher Ward is not the target")
	failed += _resolver_same_ids(_resolver_ticks(fight, "back"), [3, 3, 3], "spore moth poison is 9, split 3/3/3")
	failed += _assert(_resolver_ticks(fight, "front").is_empty(), "the other member stays clean")
	failed += _assert(fight.scripted_remaining() == before and fight.scripted_underrun() == 0, "a poison move consumes no dice")
	return failed


func _resolver_poison_continuation() -> int:
	## A ticked poison keeps its total across a save, and the next step matches.
	var failed: int = 0
	var fight: FightState = FightStateScript.new()
	fight.twist = "sap_spring"
	fight.loadout = {"heart_salve": 2}
	var keeper: Dictionary = _resolver_tank(9)
	keeper["vitality"] = 10
	fight.add_member("keeper", keeper, 0, "front", "keeper")
	fight.add_beast("acorn_imp", 0, "front", "imp")
	fight.set_boss("imp")
	fight.start_fight()
	fight.apply_poison("keeper", 12)
	fight.tick_poison("keeper")
	var braced: Dictionary = fight.step({"kind": "brace"})
	failed += _assert(str(braced.get("error", "")) == "", "continuation brace")
	var card: Dictionary = fight.fighter_dict("keeper")
	failed += _assert(bool(card.get("brace", false)), "continuation brace flag")
	failed += _assert(_resolver_kept(card) == 12, "the kept total survives the tick")
	failed += _resolver_same_ids(_resolver_ticks(fight, "keeper"), [4], "one tick of 12 remains")
	failed += _assert(int(card.get("shield", -1)) == 0, "two ticks of 4 spent the shield of 8")
	failed += _assert(int(fight.fighter_dict("imp").get("max_hp", 0)) == 56, "the boss max is in the save")
	var snap: Dictionary = fight.to_dict()
	var parsed: Variant = JSON.parse_string(JSON.stringify(snap))
	failed += _assert(parsed is Dictionary, "continuation json")
	if parsed is Dictionary:
		var copy: FightState = FightStateScript.from_dict(parsed)
		var again: Dictionary = copy.to_dict()
		if again != snap:
			print("POISON A ", JSON.stringify(snap))
			print("POISON B ", JSON.stringify(again))
		failed += _assert(again == snap, "poison, brace, shield, loadout, boss and twist survive json")
		fight.set_scripted_dice([1, 1, 6, 6, 1])
		copy.set_scripted_dice([1, 1, 6, 6, 1])
		var left: Dictionary = fight.step({})
		var right: Dictionary = copy.step({})
		if left != right:
			print("POISON STEP A ", JSON.stringify(left))
			print("POISON STEP B ", JSON.stringify(right))
		failed += _assert(left == right, "the next step matches after the reload")
		failed += _assert(copy.to_dict() == fight.to_dict(), "the fights still match after that step")
		failed += _assert(fight.scripted_underrun() == 0 and fight.scripted_remaining() == 0, "continuation dice")
	return failed


func _resolver_twists() -> int:
	var failed: int = 0
	failed += _resolver_thicket()
	failed += _resolver_fog()
	failed += _resolver_twist_ambush()
	failed += _resolver_sap_amounts()
	failed += _resolver_rich_hollow()
	if failed == 0:
		print("RESOLVER_TWISTS_OK")
	return failed


func _resolver_thicket() -> int:
	var failed: int = 0
	var plain: FightState = FightStateScript.new()
	plain.add_member("keeper", _resolver_tank(0), 0, "front", "keeper")
	plain.add_fighter("imp", "beast", _resolver_tank(1), 0, "front", "physical")
	plain.start_fight()
	failed += _resolver_same_ids(plain.order, ["imp", "keeper"], "without Thicket the swifter beast goes first")
	var thick: FightState = FightStateScript.new()
	thick.twist = "thicket"
	thick.add_member("keeper", _resolver_tank(0), 0, "front", "keeper")
	thick.add_fighter("imp", "beast", _resolver_tank(1), 0, "front", "physical")
	thick.start_fight()
	failed += _assert(thick.effective_swiftness("keeper") == 0 and thick.effective_swiftness("imp") == 0, "Thicket floors both at 0")
	failed += _resolver_same_ids(thick.order, ["keeper", "imp"], "the new tie goes to the party")
	failed += _assert(int(thick.fighter_dict("imp").get("swiftness", -1)) == 1, "Thicket does not rewrite the stored Swiftness")
	var open: Dictionary = _resolver_guard_blow(false, 7)
	var shut: Dictionary = _resolver_guard_blow(true, 7)
	failed += _assert(int(open.get("defense_total", -1)) == 8, "unguarded defense is 8 (got %s)" % str(open.get("defense_total", "")))
	failed += _assert(int(shut.get("defense_total", -1)) == 7, "Thicket drops that defense by 1 (got %s)" % str(shut.get("defense_total", "")))
	failed += _assert(int(open.get("attack_total", -1)) == int(shut.get("attack_total", -2)), "Thicket does not change the attack total")
	var clamped: Dictionary = _resolver_guard_blow(true, 1)
	failed += _assert(int(clamped.get("defense_total", -1)) == 4, "Swiftness 1 floored at 0 still guards with Resilience 4 (got %s)" % str(clamped.get("defense_total", "")))
	return failed


func _resolver_guard_blow(use_thicket: bool, swiftness: int) -> Dictionary:
	var fight: FightState = FightStateScript.new()
	if use_thicket:
		fight.twist = "thicket"
	var attacker: Dictionary = {
		"might": 4, "arcana": 1, "resilience": 1, "ward": 1,
		"vitality": 4, "swiftness": 1, "fate": 0,
	}
	var resilience: int = 6 if swiftness >= 2 else 4
	var defender: Dictionary = {
		"might": 1, "arcana": 1, "resilience": resilience, "ward": 1,
		"vitality": 8, "swiftness": swiftness, "fate": 0,
	}
	fight.add_fighter("attacker", "beast", attacker, 0, "front", "physical")
	fight.add_fighter("defender", "party", defender, 0, "front", "physical", "", "keeper")
	fight.set_scripted_dice([1, 1, 1, 1])
	return fight.strike("attacker", "defender", 0, 1)


func _resolver_fog() -> int:
	var failed: int = 0
	var open_party: Dictionary = _resolver_fog_blow(false, "party")
	var fog_party: Dictionary = _resolver_fog_blow(true, "party")
	var open_beast: Dictionary = _resolver_fog_blow(false, "beast")
	var fog_beast: Dictionary = _resolver_fog_blow(true, "beast")
	failed += _assert(int(open_party.get("attack_total", -1)) == 18 and int(fog_party.get("attack_total", -1)) == 16, "Fog takes 2 off a party attack")
	failed += _assert(int(open_beast.get("attack_total", -1)) == 18 and int(fog_beast.get("attack_total", -1)) == 16, "Fog takes 2 off a beast attack")
	failed += _assert(int(open_party.get("defense_total", -1)) == int(fog_party.get("defense_total", -2)), "Fog leaves party defense alone")
	failed += _assert(int(open_beast.get("defense_total", -1)) == int(fog_beast.get("defense_total", -2)), "Fog leaves beast defense alone")
	failed += _assert(str(open_party.get("band", "")) == "crush" and str(fog_party.get("band", "")) == "crush", "a solid hit stays a hit")
	failed += _assert(int(open_party.get("damage", -1)) == int(fog_party.get("damage", -2)) and int(open_party.get("damage", 0)) > 0, "Fog is not a flat miss")
	var graze: Dictionary = _resolver_fog_edge(false)
	var miss: Dictionary = _resolver_fog_edge(true)
	failed += _assert(str(graze.get("band", "")) == "graze" and int(graze.get("damage", 0)) > 0, "without Fog the edge is a graze")
	failed += _assert(str(miss.get("band", "")) == "miss" and int(miss.get("damage", -1)) == 0, "Fog's -2 turns that graze into a miss")
	failed += _assert(int(miss.get("underrun", -1)) == 0 and int(miss.get("remaining", -1)) == 0, "the Fog miss does not roll a damage die")
	return failed


func _resolver_fog_blow(use_fog: bool, attacker_side: String) -> Dictionary:
	var fight: FightState = FightStateScript.new()
	if use_fog:
		fight.twist = "fog"
	var big: Dictionary = {
		"might": 11, "arcana": 1, "resilience": 0, "ward": 0,
		"vitality": 8, "swiftness": 1, "fate": 0,
	}
	var soft: Dictionary = {
		"might": 1, "arcana": 1, "resilience": 0, "ward": 0,
		"vitality": 8, "swiftness": 0, "fate": 0,
	}
	if attacker_side == "party":
		fight.add_member("attacker", big, 0, "front", "attacker")
		fight.add_fighter("defender", "beast", soft, 0, "front", "physical")
	else:
		fight.add_fighter("attacker", "beast", big, 0, "front", "physical")
		fight.add_member("defender", soft, 0, "front", "defender")
	fight.set_scripted_dice([3, 4, 2, 2, 3])
	return fight.strike("attacker", "defender", 0, 1)


func _resolver_fog_edge(use_fog: bool) -> Dictionary:
	var fight: FightState = FightStateScript.new()
	if use_fog:
		fight.twist = "fog"
	var attacker: Dictionary = {
		"might": 4, "arcana": 1, "resilience": 1, "ward": 1,
		"vitality": 4, "swiftness": 1, "fate": 0,
	}
	var defender: Dictionary = {
		"might": 1, "arcana": 1, "resilience": 0, "ward": 0,
		"vitality": 8, "swiftness": 0, "fate": 0,
	}
	fight.add_fighter("attacker", "beast", attacker, 0, "front", "physical")
	fight.add_member("defender", defender, 0, "front", "defender")
	var faces: Array = [4, 4, 6, 6]
	if not use_fog:
		faces.append(1)
	fight.set_scripted_dice(faces)
	var blow: Dictionary = fight.strike("attacker", "defender", 0, 1)
	blow["underrun"] = fight.scripted_underrun()
	blow["remaining"] = fight.scripted_remaining()
	return blow


func _resolver_twist_ambush() -> int:
	var failed: int = 0
	var fight: FightState = FightStateScript.new()
	fight.twist = "ambush"
	failed += _assert(fight.ambush, "twist ambush sets the ambush flag")
	var cases: Dictionary = _json_dict("res://tests/fixtures/resolver_cases.json")
	var block: Dictionary = cases.get("turn_order", {}) as Dictionary
	for row_v: Variant in block.get("fighters", []) as Array:
		var row: Dictionary = row_v as Dictionary
		var fighter_name: String = str(row.get("name", ""))
		var stats: Dictionary = _resolver_tank(int(row.get("swiftness", 0)))
		var slot: int = int(row.get("slot", 0))
		if str(row.get("side", "")) == "party":
			fight.add_member(fighter_name, stats, slot, "front", fighter_name)
		else:
			fight.add_fighter(fighter_name, "beast", stats, slot, "front", "physical")
	fight.start_fight()
	var ambush_expect: Array = ["Spore moth A", "Wilt Wisp A", "Acorn imp A", "Root Snapper A", "Keeper", "Elaia"]
	failed += _resolver_same_ids(fight.order, ambush_expect, "twist ambush puts beasts first in round 1")
	fight.set_scripted_dice(_resolver_miss_faces(6))
	for _i: int in 6:
		var stepped: Dictionary = _resolver_step_auto(fight)
		failed += _assert(str(stepped.get("error", "")) == "", "ambush twist step %s" % str(stepped.get("error", "")))
	failed += _resolver_same_ids(fight.order, block.get("expect", []) as Array, "round 2 drops the ambush order")
	failed += _assert(fight.scripted_underrun() == 0 and fight.scripted_remaining() == 0, "ambush twist dice")
	return failed


func _resolver_rich_hollow() -> int:
	var failed: int = 0
	var plain: FightState = _resolver_seeded_pair("")
	var rich: FightState = _resolver_seeded_pair("rich_hollow")
	failed += _assert(rich.twist == "rich_hollow" and plain.twist == "", "Rich Hollow is stored")
	failed += _resolver_same_ids(rich.order, plain.order, "Rich Hollow does not reorder")
	for _i: int in 4:
		var left: Dictionary = _resolver_step_auto(plain)
		var right: Dictionary = _resolver_step_auto(rich)
		if left != right:
			print("HOLLOW A ", JSON.stringify(left))
			print("HOLLOW B ", JSON.stringify(right))
		failed += _assert(left == right, "Rich Hollow changes no roll")
	failed += _assert(int(rich.fighter_dict("keeper").get("hp", -1)) == int(plain.fighter_dict("keeper").get("hp", -2)), "Rich Hollow HP matches")
	failed += _assert(int(rich.fighter_dict("keeper").get("shield", -1)) == 0 and int(rich.fighter_dict("imp").get("shield", -1)) == 0, "Rich Hollow grants no shield")
	failed += _assert(int(rich.fighter_dict("keeper").get("swiftness", -1)) == int(plain.fighter_dict("keeper").get("swiftness", -2)), "Rich Hollow leaves Swiftness")
	failed += _assert(str(rich.to_dict().get("rng_combat_state", "")) == str(plain.to_dict().get("rng_combat_state", "x")), "Rich Hollow leaves the combat rng")
	return failed


func _resolver_seeded_pair(twist_name: String) -> FightState:
	var fight: FightState = FightStateScript.new()
	fight.set_combat_seed(424242)
	if twist_name != "":
		fight.twist = twist_name
	fight.add_member("keeper", _resolver_tank(7), 0, "front", "keeper")
	fight.add_fighter("imp", "beast", _resolver_tank(6), 0, "front", "physical")
	fight.start_fight()
	return fight


func _resolver_boss() -> int:
	var failed: int = 0
	failed += _resolver_boss_hp()
	var heavy: Array = ["strike", "strike", "heavy", "strike", "strike", "heavy"]
	failed += _resolver_walk_moves("acorn_imp", true, heavy, 27)
	var poison_boss: Array = ["strike", "poison", "strike", "poison", "strike", "poison"]
	failed += _resolver_walk_moves("spore_moth", true, poison_boss, -1)
	var poison_plain: Array = ["strike", "strike", "poison", "strike", "strike", "poison"]
	failed += _resolver_walk_moves("spore_moth", false, poison_plain, -1)
	if failed == 0:
		print("RESOLVER_BOSS_OK")
	return failed


func _resolver_boss_hp() -> int:
	var failed: int = 0
	var fight: FightState = FightStateScript.new()
	fight.add_beast("acorn_imp", 0, "front", "boss")
	fight.set_boss("boss")
	fight.add_beast("acorn_imp", 1, "front", "plain")
	fight.add_member("keeper", _resolver_tank(1), 0, "front", "keeper")
	fight.start_fight()
	failed += _assert(int(fight.fighter_dict("boss").get("max_hp", 0)) == 56, "boss max is round_half_up(37 * 3 / 2)")
	failed += _assert(int(fight.fighter_dict("boss").get("hp", 0)) == 56, "boss HP is filled to the new max")
	failed += _assert(int(fight.fighter_dict("plain").get("max_hp", 0)) == 37, "a normal imp keeps 37")
	fight.set_hp("boss", 6)
	failed += _assert(str(fight.fighter_dict("boss").get("status", "")) == "active", "6 HP is above 10% of 56")
	fight.set_hp("boss", 5)
	failed += _assert(str(fight.fighter_dict("boss").get("status", "")) == "calmed", "5 HP is Calmed on the boosted max")
	fight.set_hp("plain", 5)
	failed += _assert(str(fight.fighter_dict("plain").get("status", "")) == "active", "5 HP is still active on the unboosted max")
	fight.set_hp("plain", 3)
	failed += _assert(str(fight.fighter_dict("plain").get("status", "")) == "calmed", "3 HP Calms the unboosted imp")
	return failed


func _resolver_walk_moves(species: String, as_boss: bool, moves: Array, heavy_damage: int) -> int:
	## Intents are read before the beast acts, and again the moment its turn ends.
	var failed: int = 0
	var fight: FightState = FightStateScript.new()
	var keeper: Dictionary = {
		"might": 1, "arcana": 1, "resilience": 0, "ward": 40,
		"vitality": 30, "swiftness": 0, "fate": 0,
	}
	fight.add_member("keeper", keeper, 0, "front", "keeper")
	fight.add_beast(species, 0, "front", "beast")
	if as_boss:
		fight.set_boss("beast")
	fight.start_fight()
	var faces: Array = []
	for move_v: Variant in moves:
		var move_name: String = str(move_v)
		if move_name == "heavy":
			faces.append_array([3, 3, 1, 1, 2])
		elif move_name == "strike":
			faces.append_array([1, 1, 6, 6])
		faces.append_array([1, 1, 6, 6])
	fight.set_scripted_dice(faces)
	var label: String = species
	if as_boss:
		label = "%s boss" % species
	for i: int in moves.size():
		var expect: String = str(moves[i])
		failed += _assert(fight.current_actor() == "beast", "%s turn %d is the beast" % [label, i + 1])
		var intent: Dictionary = _resolver_intent(fight, "beast")
		failed += _assert(str(intent.get("move", "")) == expect, "%s intent before turn %d is %s (got %s)" % [label, i + 1, expect, str(intent.get("move", ""))])
		if expect == "heavy":
			var ratio: Vector2i = FightStateScript.telegraph_ratio(intent.get("mult", 1))
			failed += _assert(ratio == Vector2i(3, 2), "%s heavy is x1.5 before turn %d" % [label, i + 1])
		var before: int = fight.scripted_remaining()
		var hp_before: int = int(fight.fighter_dict("keeper").get("hp", -1))
		var stepped: Dictionary = fight.step({})
		failed += _assert(str(stepped.get("error", "")) == "", "%s turn %d error %s" % [label, i + 1, str(stepped.get("error", ""))])
		if expect == "poison":
			failed += _assert(str(stepped.get("kind", "")) == "poison", "%s uses poison on turn %d" % [label, i + 1])
			failed += _assert(fight.scripted_remaining() == before, "%s poison spends no dice on turn %d" % [label, i + 1])
			failed += _assert(int(fight.fighter_dict("keeper").get("hp", -2)) == hp_before, "%s poison deals no strike on turn %d" % [label, i + 1])
		elif expect == "heavy":
			var blow: Dictionary = stepped.get("strike", {}) as Dictionary
			failed += _assert(str(stepped.get("kind", "")) == "strike", "%s heavy is a strike" % label)
			if heavy_damage > 0:
				failed += _assert(int(blow.get("damage", -1)) == heavy_damage, "%s heavy damage %s vs %d" % [label, str(blow.get("damage", "")), heavy_damage])
		else:
			failed += _assert(str(stepped.get("kind", "")) == "strike", "%s turn %d is a plain strike" % [label, i + 1])
		if i + 1 < moves.size():
			var nxt: Dictionary = _resolver_intent(fight, "beast")
			failed += _assert(str(nxt.get("move", "")) == str(moves[i + 1]), "%s shows the next intent before it acts again" % label)
		var answer: Dictionary = fight.step({"kind": "strike", "target": "beast"})
		failed += _assert(str(answer.get("error", "")) == "", "%s party answer %s" % [label, str(answer.get("error", ""))])
	failed += _assert(fight.scripted_underrun() == 0 and fight.scripted_remaining() == 0, "%s dice" % label)
	return failed


func _resolver_salve() -> int:
	## Heart Salve. Its own token so Brace stays about the stance.
	var failed: int = 0
	var fight: FightState = FightStateScript.new()
	var keeper: Dictionary = {
		"might": 1, "arcana": 1, "resilience": 1, "ward": 1,
		"vitality": 30, "swiftness": 8, "fate": 0, "hp": 100,
	}
	var elaia: Dictionary = {
		"might": 1, "arcana": 1, "resilience": 1, "ward": 1,
		"vitality": 30, "swiftness": 2, "fate": 0, "hp": 50,
	}
	fight.add_member("keeper", keeper, 0, "front", "keeper")
	fight.add_member("elaia", elaia, 1, "front", "elaia")
	fight.add_fighter("imp", "beast", _resolver_tank(1), 0, "front", "physical")
	fight.loadout = {"heart_salve": 1, "bile_vial": 1}
	fight.start_fight()
	fight.set_scripted_dice([7])
	var healed: Dictionary = fight.step({"kind": "item", "item": "heart_salve", "target": "elaia"})
	failed += _assert(str(healed.get("error", "")) == "" and str(healed.get("kind", "")) == "item", "salve spends the turn")
	failed += _assert(int(fight.fighter_dict("elaia").get("hp", -1)) == 80, "30% of 100 is 30 (got %s)" % str(fight.fighter_dict("elaia").get("hp", "")))
	failed += _assert(int(fight.fighter_dict("keeper").get("hp", -1)) == 100, "the salve does not heal the user unless targeted")
	failed += _assert(fight.salves_used == 1, "salves_used counts the dose")
	failed += _assert(int(fight.loadout.get("heart_salve", -1)) == 0, "the dose leaves the loadout")
	failed += _assert(fight.scripted_remaining() == 1 and fight.scripted_underrun() == 0, "a salve consumes no dice")
	var empty: Dictionary = fight.step({"kind": "item", "item": "heart_salve", "target": "elaia"})
	failed += _assert(str(empty.get("error", "")) == "illegal action", "a second dose needs stock")
	failed += _assert(fight.current_actor() == "elaia", "no stock leaves the next actor waiting")
	failed += _assert(int(fight.fighter_dict("keeper").get("turns", -1)) == 1, "the spent dose still counts")
	failed += _assert(int(fight.fighter_dict("elaia").get("turns", -1)) == 0, "the refused salve spends no turn")
	var capped: FightState = FightStateScript.new()
	var low: Dictionary = {
		"might": 1, "arcana": 1, "resilience": 1, "ward": 1,
		"vitality": 30, "swiftness": 8, "fate": 0, "hp": 90,
	}
	capped.add_member("keeper", low, 0, "front", "keeper")
	capped.add_fighter("imp", "beast", _resolver_tank(1), 0, "front", "physical")
	capped.loadout = {"heart_salve": 5}
	capped.start_fight()
	capped.set_scripted_dice(_resolver_miss_faces(2))
	var first: Dictionary = capped.step({"kind": "item", "item": "heart_salve", "target": "keeper"})
	failed += _assert(str(first.get("error", "")) == "" and int(capped.fighter_dict("keeper").get("hp", -1)) == 100, "the heal caps at max HP")
	var beast_one: Dictionary = capped.step({})
	failed += _assert(str(beast_one.get("error", "")) == "", "the beast acts between salves")
	var second: Dictionary = capped.step({"kind": "item", "item": "heart_salve", "target": "keeper"})
	failed += _assert(str(second.get("error", "")) == "" and capped.salves_used == 2, "the second salve is the last")
	var beast_two: Dictionary = capped.step({})
	failed += _assert(str(beast_two.get("error", "")) == "", "the beast acts again")
	var third: Dictionary = capped.step({"kind": "item", "item": "heart_salve", "target": "keeper"})
	failed += _assert(str(third.get("error", "")) == "illegal action", "the third salve is refused")
	failed += _assert(capped.salves_used == 2 and int(capped.fighter_dict("keeper").get("turns", -1)) == 2, "the refused salve spends no turn and no dose")
	failed += _assert(capped.current_actor() == "keeper", "the refused salve leaves the cursor")
	failed += _assert(capped.scripted_underrun() == 0 and capped.scripted_remaining() == 0, "salve cap dice")
	var blocked: FightState = FightStateScript.new()
	blocked.add_member("keeper", _resolver_tank(8), 0, "front", "keeper")
	blocked.add_member("elaia", _resolver_tank(2), 1, "front", "elaia")
	blocked.add_fighter("imp", "beast", _resolver_tank(1), 0, "front", "physical")
	blocked.start_fight()
	blocked.set_hp("elaia", 0)
	var no_stock: Dictionary = blocked.step({"kind": "item", "item": "heart_salve", "target": "keeper"})
	failed += _assert(str(no_stock.get("error", "")) == "illegal action", "salve without a loadout is refused")
	var bile: Dictionary = blocked.step({"kind": "item", "item": "bile_vial", "target": "imp"})
	failed += _assert(str(bile.get("error", "")) == "illegal action", "Bile Vial is refused")
	blocked.loadout = {"heart_salve": 1}
	var down: Dictionary = blocked.step({"kind": "item", "item": "heart_salve", "target": "elaia"})
	failed += _assert(str(down.get("error", "")) == "illegal action", "a knocked-out target is refused")
	var beast_target: Dictionary = blocked.step({"kind": "item", "item": "heart_salve", "target": "imp"})
	failed += _assert(str(beast_target.get("error", "")) == "illegal action", "a beast is not a salve target")
	failed += _assert(blocked.salves_used == 0 and int(blocked.fighter_dict("keeper").get("turns", -1)) == 0, "refused salves spend nothing")
	failed += _assert(int(blocked.loadout.get("heart_salve", -1)) == 1, "a refused salve keeps the stock")
	if failed == 0:
		print("RESOLVER_SALVE_OK")
	return failed


func _auto_flee_ko_zero() -> int:
	var failed: int = 0
	var ko: FightState = FightStateScript.new()
	var down: Dictionary = _resolver_tank(1)
	down["vitality"] = 10
	down["hp"] = 4
	var up: Dictionary = _resolver_tank(2)
	up["vitality"] = 30
	up["hp"] = 50
	ko.add_member("down", down, 0, "front", "down")
	ko.add_member("up", up, 1, "front", "up")
	ko.add_fighter("imp", "beast", _resolver_tank(1), 0, "front", "physical")
	var ko_row: Dictionary = ko.flee_check()
	failed += _assert(str(ko.fighter_dict("down").get("status", "")) == "ko", "4 HP on max 40 is knocked out")
	failed += _assert(int(ko_row.get("party_hp", -1)) == 50, "a KO member with leftover HP counts as 0 (got %s)" % str(ko_row.get("party_hp", "")))
	failed += _assert(int(ko_row.get("party_max", -1)) == 140, "party max still sums the knocked-out member")
	var shielded: FightState = FightStateScript.new()
	shielded.twist = "sap_spring"
	var body: Dictionary = _resolver_tank(3)
	body["vitality"] = 30
	body["hp"] = 40
	shielded.add_member("keeper", body, 0, "front", "keeper")
	var healthy: Dictionary = _resolver_tank(1)
	healthy["vitality"] = 7
	healthy["hp"] = 31
	shielded.add_fighter("imp", "beast", healthy, 0, "front", "physical")
	shielded.start_fight()
	var shield_row: Dictionary = shielded.flee_check()
	failed += _assert(int(shielded.fighter_dict("keeper").get("shield", -1)) == 20, "the flee probe is wearing a shield of 20")
	failed += _assert(int(shield_row.get("party_hp", -1)) == 40, "the shield is not added to party HP")
	failed += _assert(bool(shield_row.get("should_flee", false)), "40/100 and a healthy beast should flee; counting the shield would not")
	var half: FightState = FightStateScript.new()
	var even: Dictionary = _resolver_tank(1)
	even["vitality"] = 30
	even["hp"] = 50
	half.add_member("keeper", even, 0, "front", "keeper")
	var foe: Dictionary = _resolver_tank(1)
	foe["vitality"] = 7
	foe["hp"] = 31
	half.add_fighter("imp", "beast", foe, 0, "front", "physical")
	var even_row: Dictionary = half.flee_check()
	failed += _assert(int(even_row.get("party_hp", -1)) == 50 and int(even_row.get("party_max", -1)) == 100, "the 50% probe")
	failed += _assert(not bool(even_row.get("should_flee", true)), "exactly half does not flee")
	half.set_hp("keeper", 49)
	var under: Dictionary = half.flee_check()
	failed += _assert(bool(under.get("should_flee", false)), "one HP under half does flee")
	var third: FightState = FightStateScript.new()
	var hurting: Dictionary = _resolver_tank(1)
	hurting["vitality"] = 30
	hurting["hp"] = 40
	third.add_member("keeper", hurting, 0, "front", "keeper")
	for i: int in 3:
		var beast: Dictionary = _resolver_tank(1)
		beast["vitality"] = 7
		beast["hp"] = 31 if i == 0 else 0
		third.add_fighter("b%d" % i, "beast", beast, i, "front", "physical")
	var third_row: Dictionary = third.flee_check()
	failed += _assert(int(third_row.get("beast_hp", -1)) == 31 and int(third_row.get("beast_max", -1)) == 93, "exactly one third of the beasts")
	failed += _assert(not bool(third_row.get("should_flee", true)), "exactly one third does not flee")
	third.set_hp("b0", 32)
	var over: Dictionary = third.flee_check()
	failed += _assert(bool(over.get("should_flee", false)), "one HP over one third does flee")
	var bossed: FightState = FightStateScript.new()
	bossed.add_member("keeper", hurting, 0, "front", "keeper")
	bossed.add_beast("acorn_imp", 0, "front", "boss")
	bossed.set_boss("boss")
	bossed.start_fight()
	bossed.set_hp("boss", 5)
	var boss_row: Dictionary = bossed.flee_check()
	failed += _assert(int(boss_row.get("beast_max", -1)) == 56, "beast max includes the boss max")
	failed += _assert(int(boss_row.get("beast_hp", -1)) == 0, "a Calmed boss adds no HP")
	failed += _assert(not bool(boss_row.get("should_flee", true)), "Calmed beasts cannot force a flee by themselves")
	if failed == 0:
		print("AUTO_FLEE_KO_ZERO_OK")
	return failed


func _auto_policy_keeper_unlock_stats() -> Dictionary:
	return {
		"might": 11, "arcana": 5, "resilience": 6, "ward": 5,
		"vitality": 6, "swiftness": 7, "fate": 7, "attack": "physical",
	}


func _auto_policy_strike_fight() -> FightState:
	var fight: FightState = FightStateScript.new()
	fight.add_member("keeper", _auto_policy_keeper_unlock_stats(), 0, "front", "keeper")
	fight.add_beast("acorn_imp", 2, "front", "imp_hi")
	fight.add_beast("acorn_imp", 0, "front", "imp_lo")
	fight.add_beast("acorn_imp", 1, "back", "imp_back")
	fight.start_fight()
	return fight


func _auto_policy() -> int:
	var failed: int = 0
	var strike_fight: FightState = _auto_policy_strike_fight()
	var strike_act: Dictionary = AutoPolicyScript.strike_for_me_action(strike_fight, "keeper")
	failed += _assert(str(strike_act.get("kind", "")) == "strike", "strike for me is always a strike")
	failed += _assert(str(strike_act.get("target", "")) == "imp_lo", "front row, lowest slot first (got %s)" % str(strike_act.get("target", "")))
	var back_only: FightState = FightStateScript.new()
	back_only.add_member("keeper", _auto_policy_keeper_unlock_stats(), 0, "front", "keeper")
	back_only.add_beast("acorn_imp", 1, "back", "imp_back")
	back_only.start_fight()
	var back_act: Dictionary = AutoPolicyScript.strike_for_me_action(back_only, "keeper")
	failed += _assert(str(back_act.get("target", "")) == "imp_back", "empty front row reaches the back")
	var hurt: FightState = FightStateScript.new()
	hurt.add_member("keeper", {"vitality": 10, "hp": 3, "swiftness": 7, "attack": "physical"}, 0, "front", "keeper")
	hurt.add_beast("acorn_imp", 0, "front", "imp")
	hurt.loadout = {"heart_salve": 2}
	hurt.start_fight()
	var hurt_act: Dictionary = AutoPolicyScript.strike_for_me_action(hurt, "keeper")
	failed += _assert(str(hurt_act.get("kind", "")) == "strike", "strike for me never salves even below 40%")

	var salve_base: FightState = FightStateScript.new()
	salve_base.add_member("keeper", {"vitality": 30, "hp": 39, "swiftness": 7, "attack": "physical"}, 0, "front", "keeper")
	salve_base.add_beast("acorn_imp", 0, "front", "imp")
	salve_base.loadout = {"heart_salve": 1}
	salve_base.start_fight()
	var at_39: Dictionary = AutoPolicyScript.idle_action(salve_base, "keeper")
	failed += _assert(str(at_39.get("kind", "")) == "item" and str(at_39.get("item", "")) == "heart_salve", "39% drinks a salve")
	failed += _assert(str(at_39.get("target", "")) == "keeper", "salve targets the lowest-ratio active member")

	var at_40: FightState = FightStateScript.new()
	at_40.add_member("keeper", {"vitality": 30, "hp": 40, "swiftness": 7, "attack": "physical"}, 0, "front", "keeper")
	at_40.add_beast("acorn_imp", 0, "front", "imp")
	at_40.loadout = {"heart_salve": 1}
	at_40.start_fight()
	var forty: Dictionary = AutoPolicyScript.idle_action(at_40, "keeper")
	failed += _assert(str(forty.get("kind", "")) == "strike", "exactly 40% does not salve")

	var cap: FightState = FightStateScript.new()
	cap.add_member("keeper", {"vitality": 30, "hp": 10, "swiftness": 7, "attack": "physical"}, 0, "front", "keeper")
	cap.add_beast("acorn_imp", 0, "front", "imp")
	cap.salves_used = 2
	cap.loadout = {"heart_salve": 1}
	cap.start_fight()
	failed += _assert(str(AutoPolicyScript.idle_action(cap, "keeper").get("kind", "")) == "strike", "two salves already used")

	var empty_load: FightState = FightStateScript.new()
	empty_load.add_member("keeper", {"vitality": 30, "hp": 10, "swiftness": 7, "attack": "physical"}, 0, "front", "keeper")
	empty_load.add_beast("acorn_imp", 0, "front", "imp")
	empty_load.loadout = {"heart_salve": 0}
	empty_load.start_fight()
	failed += _assert(str(AutoPolicyScript.idle_action(empty_load, "keeper").get("kind", "")) == "strike", "zero salves in loadout")

	var ko_pick: FightState = FightStateScript.new()
	ko_pick.add_member("keeper", {"vitality": 10, "hp": 4, "swiftness": 7, "attack": "physical"}, 0, "front", "keeper")
	ko_pick.add_member("elaia", {"vitality": 30, "hp": 39, "swiftness": 6, "attack": "physical"}, 1, "front", "elaia")
	ko_pick.add_beast("acorn_imp", 0, "front", "imp")
	ko_pick.loadout = {"heart_salve": 1}
	ko_pick.start_fight()
	var ko_act: Dictionary = AutoPolicyScript.idle_action(ko_pick, "keeper")
	failed += _assert(str(ko_act.get("target", "")) == "elaia", "a knocked-out member is never the salve target (got %s)" % str(ko_act.get("target", "")))

	var ratio_pick: FightState = FightStateScript.new()
	ratio_pick.add_member("keeper", {"vitality": 30, "hp": 35, "swiftness": 7, "attack": "physical"}, 1, "front", "keeper")
	ratio_pick.add_member("elaia", {"vitality": 30, "hp": 40, "swiftness": 6, "attack": "physical"}, 0, "front", "elaia")
	ratio_pick.add_beast("acorn_imp", 0, "front", "imp")
	ratio_pick.loadout = {"heart_salve": 1}
	ratio_pick.start_fight()
	var ratio_act: Dictionary = AutoPolicyScript.idle_action(ratio_pick, "keeper")
	failed += _assert(str(ratio_act.get("target", "")) == "keeper", "lowest HP ratio wins over slot (got %s)" % str(ratio_act.get("target", "")))

	var flee_early: FightState = FightStateScript.new()
	var hurting: Dictionary = _resolver_tank(1)
	hurting["vitality"] = 30
	hurting["hp"] = 40
	flee_early.add_member("keeper", hurting, 0, "front", "keeper")
	var foe: Dictionary = _resolver_tank(1)
	foe["vitality"] = 7
	foe["hp"] = 31
	flee_early.add_fighter("imp", "beast", foe, 0, "front", "physical")
	flee_early.start_fight()
	failed += _assert(not AutoPolicyScript.should_flee(flee_early), "should_flee is false in round 1 even when the numbers say flee")

	var flee_late: FightState = FightStateScript.new()
	var party_49: Dictionary = _resolver_tank(1)
	party_49["vitality"] = 30
	party_49["hp"] = 49
	flee_late.add_member("keeper", party_49, 0, "front", "keeper")
	var beast_34: Dictionary = _resolver_tank(1)
	beast_34["vitality"] = 7
	beast_34["hp"] = 34
	flee_late.add_fighter("imp", "beast", beast_34, 0, "front", "physical")
	flee_late.start_fight()
	var late_snap: Dictionary = flee_late.to_dict()
	late_snap["round"] = 2
	flee_late = FightStateScript.from_dict(late_snap)
	failed += _assert(AutoPolicyScript.should_flee(flee_late), "should_flee is true in round 2 at party 49% / beasts 34%")

	var flee_half: FightState = FightStateScript.new()
	var even: Dictionary = _resolver_tank(1)
	even["vitality"] = 30
	even["hp"] = 50
	flee_half.add_member("keeper", even, 0, "front", "keeper")
	var beast_half: Dictionary = _resolver_tank(1)
	beast_half["vitality"] = 7
	beast_half["hp"] = 31
	flee_half.add_fighter("imp", "beast", beast_half, 0, "front", "physical")
	var half_snap: Dictionary = flee_half.to_dict()
	half_snap["round"] = 2
	flee_half = FightStateScript.from_dict(half_snap)
	failed += _assert(not AutoPolicyScript.should_flee(flee_half), "exactly 50% party does not flee in round 2")

	var flee_third: FightState = FightStateScript.new()
	flee_third.add_member("keeper", hurting, 0, "front", "keeper")
	for i: int in 3:
		var beast: Dictionary = _resolver_tank(1)
		beast["vitality"] = 7
		beast["hp"] = 31 if i == 0 else 0
		flee_third.add_fighter("b%d" % i, "beast", beast, i, "front", "physical")
	var third_snap: Dictionary = flee_third.to_dict()
	third_snap["round"] = 2
	flee_third = FightStateScript.from_dict(third_snap)
	failed += _assert(not AutoPolicyScript.should_flee(flee_third), "exactly one third beast HP does not flee in round 2")

	var seeded_a: FightState = FightStateScript.new()
	seeded_a.set_combat_seed(31415926)
	seeded_a.add_member("keeper", _auto_policy_keeper_unlock_stats(), 0, "front", "keeper")
	seeded_a.add_beast("acorn_imp", 0, "front", "acorn_imp")
	var out_a: String = AutoPolicyScript.run_idle(seeded_a)
	var seeded_b: FightState = FightStateScript.new()
	seeded_b.set_combat_seed(31415926)
	seeded_b.add_member("keeper", _auto_policy_keeper_unlock_stats(), 0, "front", "keeper")
	seeded_b.add_beast("acorn_imp", 0, "front", "acorn_imp")
	var out_b: String = AutoPolicyScript.run_idle(seeded_b)
	failed += _assert(out_a != "" and out_a == out_b, "seeded keeper vs imp is deterministic (%s vs %s)" % [out_a, out_b])

	var easy: FightState = FightStateScript.new()
	easy.set_combat_seed(7)
	var titan: Dictionary = _auto_policy_keeper_unlock_stats()
	titan["might"] = 99
	titan["vitality"] = 30
	easy.add_member("keeper", titan, 0, "front", "keeper")
	var crumb: Dictionary = _resolver_tank(1)
	crumb["vitality"] = 1
	crumb["hp"] = 1
	easy.add_fighter("imp", "beast", crumb, 0, "front", "physical")
	failed += _assert(AutoPolicyScript.run_idle(easy) == "win", "an overpowered party wins idle auto")

	var grim: FightState = FightStateScript.new()
	grim.set_combat_seed(99)
	var glass: Dictionary = _resolver_tank(1)
	glass["vitality"] = 1
	glass["hp"] = 1
	grim.add_member("keeper", glass, 0, "front", "keeper")
	for slot: int in 4:
		grim.add_beast("acorn_imp", slot, "front", "imp_%d" % slot)
	var grim_out: String = AutoPolicyScript.run_idle(grim)
	failed += _assert(grim_out == "flee" or grim_out == "overwhelmed", "a hopeless fight flees or is overwhelmed (got %s)" % grim_out)

	var guard_fight: FightState = FightStateScript.new()
	guard_fight.set_combat_seed(12345)
	guard_fight.add_member("keeper", _auto_policy_keeper_unlock_stats(), 0, "front", "keeper")
	guard_fight.add_beast("acorn_imp", 0, "front", "acorn_imp")
	AutoPolicyScript.run_idle(guard_fight)
	failed += _assert(guard_fight.outcome() != "" or guard_fight.round > 0, "run_idle finishes a normal fight without tripping the guard")

	if failed == 0:
		print("AUTO_POLICY_OK")
	return failed


func _sim_parity() -> int:
	var failed: int = 0
	# Source: Director sim MILESTONES, 20,000 fights per cell, box run 2026-10-10.
	var cells: Array[Dictionary] = [
		{"sheet": "unlock", "depth": 1, "win": 15.5, "flee": 62.1, "overwhelmed": 22.4},
		{"sheet": "unlock", "depth": 8, "win": 5.7, "flee": 64.6, "overwhelmed": 29.7},
		{"sheet": "duo", "depth": 1, "win": 73.4, "flee": 23.2, "overwhelmed": 3.4},
		{"sheet": "duo", "depth": 8, "win": 44.0, "flee": 47.9, "overwhelmed": 8.1},
	]
	const BATCH_N: int = 3000
	const BASE_SEED: int = 20261010
	const TOL: float = 3.0
	for cell: Dictionary in cells:
		var sheet: String = str(cell["sheet"])
		var depth: int = int(cell["depth"])
		var measured_a: Dictionary = BatchSimScript.run_batch(sheet, depth, BATCH_N, BASE_SEED)
		var measured_b: Dictionary = BatchSimScript.run_batch(sheet, depth, BATCH_N, BASE_SEED)
		print(
			"SIM_PARITY %s depth %d: win=%.1f flee=%.1f overwhelmed=%.1f (n=%d)"
			% [
				sheet,
				depth,
				float(measured_a["win"]),
				float(measured_a["flee"]),
				float(measured_a["overwhelmed"]),
				int(measured_a["n"]),
			]
		)
		failed += _assert(measured_a == measured_b, "batch determinism %s depth %d" % [sheet, depth])
		for key: String in ["win", "flee", "overwhelmed"]:
			var got: float = float(measured_a[key])
			var want: float = float(cell[key])
			var delta: float = absf(got - want)
			if delta > TOL:
				failed += _assert(
					false,
					"%s depth %d %s %.1f vs target %.1f (off by %.1f)"
					% [sheet, depth, key, got, want, delta]
				)
	if failed == 0:
		print("SIM_PARITY_OK")
	return failed


func _resolver_perf() -> int:
	var failed: int = 0
	var times_usec: Array[int] = []
	for _run: int in 3:
		var t0: int = Time.get_ticks_usec()
		BatchSimScript.run_batch("duo", 8, 50, 20261010)
		times_usec.append(Time.get_ticks_usec() - t0)
	var best_usec: int = times_usec[0]
	for t: int in times_usec:
		if t < best_usec:
			best_usec = t
	print(
		"RESOLVER_PERF trio ms: %.2f %.2f %.2f (best %.2f)"
		% [
			float(times_usec[0]) / 1000.0,
			float(times_usec[1]) / 1000.0,
			float(times_usec[2]) / 1000.0,
			float(best_usec) / 1000.0,
		]
	)
	# Fail above 150 ms; 100-150 ms passes with a warning (slower computers).
	failed += _assert(best_usec <= 150_000, "50 duo depth-8 rooms within 150 ms (best %d us)" % best_usec)
	if best_usec >= 100_000 and best_usec <= 150_000:
		print("RESOLVER_PERF_WARN %.2f" % (float(best_usec) / 1000.0))
	if failed == 0:
		print("RESOLVER_PERF_OK")
	return failed


func _resolver_log() -> int:
	var failed: int = 0
	var cases: Dictionary = _json_dict("res://tests/fixtures/resolver_cases.json")
	var by_id: Dictionary = {}
	for case_v: Variant in cases.get("strikes", []) as Array:
		var row: Dictionary = case_v as Dictionary
		by_id[str(row.get("id", ""))] = row
	for doc_v: Variant in cases.get("doc_cases", []) as Array:
		var doc: Dictionary = doc_v as Dictionary
		by_id[str(doc.get("id", ""))] = doc
	var line1: String = "Keeper 7+11=18 vs Acorn imp 5+6=11 → crushing blow for 24"
	var line2: String = "Acorn imp 6+7=13 vs Keeper 7+6=13 → graze for 4"
	var line4_suffix: String = "crushing blow for 52 (Fate crit)"
	var seen_kinds: Dictionary = {}
	for cid: String in ["s4_line1", "s4_line2", "s4_line4"]:
		failed += _assert(by_id.has(cid), "fixture %s" % cid)
		if not by_id.has(cid):
			continue
		var case: Dictionary = by_id[cid] as Dictionary
		var fight: FightState = _resolver_log_case_fight(case, cid == "s4_line2")
		fight.set_scripted_dice(_resolver_faces(case))
		var actor_id: String = fight.current_actor()
		var stepped: Dictionary = {}
		if cid == "s4_line2":
			failed += _assert(actor_id == "attacker", "s4_line2 lets the imp act first")
			stepped = fight.step({})
		else:
			failed += _assert(actor_id == "attacker", "%s lets the keeper act first" % cid)
			stepped = fight.step({"kind": "strike", "target": "defender"})
		_resolver_log_collect_events(stepped.get("events", []) as Array, seen_kinds)
		failed += _resolver_log_assert_sums(stepped.get("events", []) as Array, cid)
		var want_line: String = line1 if cid == "s4_line1" else (line2 if cid == "s4_line2" else "")
		if want_line != "":
			failed += _assert(_resolver_log_has_line(fight, want_line), "%s log line" % cid)
		if cid == "s4_line4":
			failed += _assert(_resolver_log_has_line(fight, line4_suffix), "s4_line4 fate suffix")
	var brace_case: Dictionary = by_id.get("s4_line3_brace", {}) as Dictionary
	if not brace_case.is_empty():
		var brace_fight: FightState = FightStateScript.new()
		var keeper: Dictionary = {
			"might": 1, "arcana": 1, "resilience": 6, "ward": 5,
			"vitality": 8, "swiftness": 7, "fate": 0,
		}
		brace_fight.add_member("keeper", keeper, 0, "front", "keeper")
		brace_fight.add_beast("acorn_imp", 0, "front", "imp")
		brace_fight.start_fight()
		brace_fight.set_scripted_dice([4, 5, 6, 5, 1])
		var braced: Dictionary = brace_fight.step({"kind": "brace"})
		_resolver_log_collect_events(braced.get("events", []) as Array, seen_kinds)
		var braced_blow: Dictionary = brace_fight.step({})
		_resolver_log_collect_events(braced_blow.get("events", []) as Array, seen_kinds)
		failed += _assert(_resolver_log_has_line(brace_fight, "[6,5,1 → 6+5]"), "braced miss shows kept dice")
		failed += _assert(_resolver_log_has_line(brace_fight, "Keeper braces (3d6 keep 2, damage halved)"), "brace line uses the §4 wording")
	var hit_fight: FightState = FightStateScript.new()
	hit_fight.add_member("keeper", {
		"might": 1, "arcana": 1, "resilience": 6, "ward": 5,
		"vitality": 8, "swiftness": 7, "fate": 0,
	}, 0, "front", "keeper")
	hit_fight.add_beast("acorn_imp", 0, "front", "imp")
	hit_fight.start_fight()
	hit_fight.set_scripted_dice([6, 6, 2, 1, 1, 4, 99, 99])
	hit_fight.step({"kind": "brace"})
	var hp_before: int = int(hit_fight.fighter_dict("keeper").get("hp", 0))
	var braced_hit: Dictionary = hit_fight.step({})
	var hit_ev: Dictionary = {}
	for ev_v: Variant in braced_hit.get("events", []) as Array:
		if ev_v is Dictionary and str((ev_v as Dictionary).get("kind", "")) == "strike":
			hit_ev = ev_v as Dictionary
	var raw: int = int(hit_ev.get("resolver_damage", -1))
	var landed: int = int(hit_ev.get("damage", -1))
	var hp_lost: int = hp_before - int(hit_fight.fighter_dict("keeper").get("hp", 0))
	failed += _assert(bool(hit_ev.get("braced", false)) and str(hit_ev.get("band", "miss")) != "miss", "braced hit lands")
	failed += _assert(raw > 1 and landed == maxi(1, BattleResolver.round_half_up(raw, 1, 2)), "braced hit: damage is resolver_damage halved (%d from %d)" % [landed, raw])
	failed += _assert(hp_lost + int(hit_ev.get("shield_absorbed", 0)) == landed, "braced hit: damage is what lands before the shield")
	failed += _assert(_resolver_log_has_line(hit_fight, "[2,1,1 → 2+1]") and _resolver_log_has_line(hit_fight, " for %d" % landed), "braced hit line: bracketed dice, halved damage")
	print("RESOLVER_LOG braced hit line: ", hit_fight.log_tail[hit_fight.log_tail.size() - 1])
	var salve_fight: FightState = FightStateScript.new()
	salve_fight.add_member("keeper", _resolver_tank(8), 0, "front", "keeper")
	salve_fight.add_member("elaia", _resolver_tank(2), 1, "front", "elaia")
	salve_fight.add_beast("acorn_imp", 0, "front", "imp")
	salve_fight.loadout = {"heart_salve": 1}
	salve_fight.start_fight()
	var salve: Dictionary = salve_fight.step({"kind": "item", "item": "heart_salve", "target": "elaia"})
	_resolver_log_collect_events(salve.get("events", []) as Array, seen_kinds)
	var poison_fight: FightState = FightStateScript.new()
	var slow_keeper: Dictionary = _resolver_tank(0)
	slow_keeper["swiftness"] = 0
	var quick_moth: Dictionary = _resolver_tank(1)
	quick_moth["swiftness"] = 10
	poison_fight.add_member("keeper", slow_keeper, 0, "front", "keeper")
	poison_fight.add_fighter("moth", "beast", quick_moth, 0, "front", "physical", "spore_moth", "")
	poison_fight.start_fight()
	# The moth's poison move comes on its 3rd own turn. Keeper braces on his turns.
	for _i: int in 12:
		if poison_fight.outcome() != "" or seen_kinds.has("poison_apply"):
			break
		var poison_action: Dictionary = {"kind": "brace"} if poison_fight.current_actor() == "keeper" else {}
		var poisoned: Dictionary = poison_fight.step(poison_action)
		_resolver_log_collect_events(poisoned.get("events", []) as Array, seen_kinds)
	poison_fight.apply_poison("keeper", 6)
	var tick_fight: FightState = FightStateScript.new()
	tick_fight.add_member("keeper", _resolver_tank(9), 0, "front", "keeper")
	tick_fight.add_beast("acorn_imp", 0, "front", "imp")
	tick_fight.start_fight()
	tick_fight.apply_poison("keeper", 3)
	var ticked: Dictionary = tick_fight.step({"kind": "brace"})
	_resolver_log_collect_events(ticked.get("events", []) as Array, seen_kinds)
	var win_fight: FightState = FightStateScript.new()
	var smasher: Dictionary = _resolver_tank(10)
	smasher["might"] = 30
	win_fight.add_member("keeper", smasher, 0, "front", "keeper")
	var prey: Dictionary = _resolver_tank(1)
	prey["resilience"] = 0
	prey["ward"] = 0
	prey["vitality"] = 1
	win_fight.add_beast("acorn_imp", 0, "front", "imp")
	win_fight.set_scripted_dice([6, 6, 1, 1, 10])
	win_fight.start_fight()
	var won: Dictionary = win_fight.step({"kind": "strike", "target": "imp"})
	_resolver_log_collect_events(won.get("events", []) as Array, seen_kinds)
	var loss_fight: FightState = FightStateScript.new()
	var bruiser: Dictionary = _resolver_tank(10)
	bruiser["might"] = 30
	loss_fight.add_beast("acorn_imp", 0, "front", "imp")
	var fallen: Dictionary = _resolver_tank(1)
	fallen["resilience"] = 0
	fallen["ward"] = 0
	fallen["vitality"] = 1
	loss_fight.add_member("keeper", fallen, 0, "front", "keeper")
	loss_fight.set_scripted_dice([6, 6, 1, 1, 10, 9])
	loss_fight.start_fight()
	var lost: Dictionary = loss_fight.step({})
	_resolver_log_collect_events(lost.get("events", []) as Array, seen_kinds)
	var cap: FightState = FightStateScript.new()
	cap.set_combat_seed(60)
	cap.add_member("keeper", _resolver_tank(3), 0, "front", "keeper")
	cap.add_beast("acorn_imp", 0, "front", "imp")
	cap.start_fight()
	for _n: int in range(1, 130):
		var cap_step: Dictionary = _resolver_step_auto(cap)
		if cap.outcome() == "flee":
			_resolver_log_collect_events(cap_step.get("events", []) as Array, seen_kinds)
			break
	var need: Array[String] = [
		"round_start", "poison_tick", "brace", "item", "intent_reveal", "poison_apply",
		"strike", "knocked_out", "calmed", "outcome",
	]
	for kind: String in need:
		failed += _assert(seen_kinds.has(kind), "event kind %s appeared" % kind)
		if seen_kinds.has(kind):
			var sample: Dictionary = seen_kinds[kind] as Dictionary
			match kind:
				"round_start":
					failed += _assert(sample.has("round"), "round_start.round")
				"poison_tick":
					for key: String in ["target", "amount", "shield_absorbed", "hp_after"]:
						failed += _assert(sample.has(key), "poison_tick.%s" % key)
				"brace":
					failed += _assert(sample.has("actor"), "brace.actor")
				"item":
					for key: String in ["actor", "item", "target", "healed"]:
						failed += _assert(sample.has(key), "item.%s" % key)
				"intent_reveal":
					for key: String in ["actor", "move", "mult"]:
						failed += _assert(sample.has(key), "intent_reveal.%s" % key)
				"poison_apply":
					for key: String in ["actor", "target", "total"]:
						failed += _assert(sample.has(key), "poison_apply.%s" % key)
				"strike":
					for key: String in ["actor", "target", "attack_total", "attack_dice", "attack_stat", "attack_mod", "defense_total", "defense_dice", "defense_stat", "defense_faces", "damage", "damage_face", "band", "to_hit_mod", "telegraph_mult", "braced", "shield_absorbed", "hp_after", "target_side"]:
						failed += _assert(sample.has(key), "strike.%s" % key)
				"knocked_out", "calmed":
					failed += _assert(sample.has("target"), "%s.target" % kind)
				"outcome":
					failed += _assert(sample.has("result"), "outcome.result")
	var spam: FightState = FightStateScript.new()
	spam.add_member("keeper", _resolver_tank(8), 0, "front", "keeper")
	spam.add_beast("acorn_imp", 0, "front", "imp")
	spam.start_fight()
	for _spam: int in 30:
		if spam.outcome() != "":
			break
		spam.step({"kind": "brace"})
		if spam.outcome() != "":
			break
		spam.step({})
	failed += _assert(spam.log_tail.size() <= 20, "log_tail stays capped at 20 (got %d)" % spam.log_tail.size())
	var tree_root: Window = root as Window
	var cs: Node = tree_root.get_node_or_null("ContentStrings")
	failed += _assert(cs != null, "ContentStrings for log strings")
	var log_keys: Array[String] = [
		"adv_log_strike", "adv_log_miss", "adv_band_graze", "adv_band_hit", "adv_band_crush",
		"adv_log_crit_suffix", "adv_log_shield_suffix", "adv_log_brace", "adv_log_salve",
		"adv_log_heavy_reveal", "adv_log_poison_apply", "adv_log_poison_tick", "adv_log_round",
		"adv_log_victory",
	]
	for key: String in log_keys:
		var text: String = str(cs.call("get_text", key))
		failed += _assert(text != key and not text.strip_edges().is_empty(), "%s resolves" % key)
		var lower: String = text.to_lower()
		for banned: String in ["slain", "killed", "rootweave"]:
			failed += _assert(lower.find(banned) < 0, "%s avoids %s" % [key, banned])
	if failed == 0:
		print("RESOLVER_LOG_OK")
	return failed


func _resolver_log_case_fight(case: Dictionary, imp_first: bool) -> FightState:
	var fight: FightState = FightStateScript.new()
	var att: Dictionary = (case.get("attacker", {}) as Dictionary).duplicate(true)
	var dfn: Dictionary = (case.get("defender", {}) as Dictionary).duplicate(true)
	if imp_first:
		# Faster than the Keeper's 7 so the imp acts first; the Keeper's own
		# Swiftness stays as in the fixture because it feeds his defense.
		att["swi"] = 10
	var attack_type: String = str(case.get("attack_type", "physical"))
	var att_side: String = _resolver_side(str(att.get("name", "")))
	var dfn_side: String = _resolver_side(str(dfn.get("name", "")))
	var att_member: String = ""
	var dfn_member: String = ""
	var att_species: String = ""
	var dfn_species: String = ""
	if att_side == "party":
		att_member = "elaia" if str(att.get("name", "")) == "Elaia" else "keeper"
	else:
		att_species = "acorn_imp"
	if dfn_side == "party":
		dfn_member = "elaia" if str(dfn.get("name", "")) == "Elaia" else "keeper"
	else:
		dfn_species = "acorn_imp"
	var dfn_kind: String = str(dfn.get("kind", "phys"))
	var dfn_attack: String = "magic" if dfn_kind == "mag" else "physical"
	fight.add_fighter("attacker", att_side, att, 0, "front", attack_type, att_species, att_member)
	fight.add_fighter("defender", dfn_side, dfn, 0, "front", dfn_attack, dfn_species, dfn_member)
	if dfn.has("hp"):
		fight.set_hp("defender", int(dfn["hp"]))
	fight.start_fight()
	return fight


func _resolver_log_has_line(fight: FightState, fragment: String) -> bool:
	for entry: Variant in fight.log_tail:
		if str(entry).find(fragment) >= 0:
			return true
	return false


func _resolver_log_collect_events(events: Array, seen: Dictionary) -> void:
	for entry: Variant in events:
		if entry is Dictionary:
			var ev: Dictionary = entry as Dictionary
			var kind: String = str(ev.get("kind", ""))
			if kind != "" and not seen.has(kind):
				seen[kind] = ev


func _resolver_log_assert_sums(events: Array, label: String) -> int:
	var failed: int = 0
	for entry: Variant in events:
		if not (entry is Dictionary):
			continue
		var ev: Dictionary = entry as Dictionary
		if str(ev.get("kind", "")) != "strike":
			continue
		var total: int = int(ev.get("attack_total", -1))
		var dice: int = int(ev.get("attack_dice", -1))
		var stat: int = int(ev.get("attack_stat", -1))
		var mod: int = int(ev.get("attack_mod", -1))
		failed += _assert(total == dice + stat + mod, "%s attack_total splits (%d vs %d+%d+%d)" % [label, total, dice, stat, mod])
		var def_total: int = int(ev.get("defense_total", -1))
		var def_dice: int = int(ev.get("defense_dice", -1))
		var def_stat: int = int(ev.get("defense_stat", -1))
		failed += _assert(def_total == def_dice + def_stat, "%s defense_total splits" % label)
	return failed


func _resolver_intent(fight: FightState, fighter_id: String) -> Dictionary:
	var card: Dictionary = fight.fighter_dict(fighter_id)
	var intent_v: Variant = card.get("intent", {})
	if intent_v is Dictionary:
		return intent_v
	return {}


func _resolver_ticks(fight: FightState, fighter_id: String) -> Array:
	var card: Dictionary = fight.fighter_dict(fighter_id)
	var poison_v: Variant = card.get("poison", {})
	if poison_v is Dictionary:
		var ticks_v: Variant = (poison_v as Dictionary).get("ticks", [])
		if ticks_v is Array:
			return ticks_v
	return []


func _resolver_kept(card: Dictionary) -> int:
	var poison_v: Variant = card.get("poison", {})
	if not (poison_v is Dictionary):
		return 0
	var poison: Dictionary = poison_v
	var ticks_v: Variant = poison.get("ticks", [])
	var tick_sum: int = 0
	if ticks_v is Array:
		for tick_v: Variant in ticks_v:
			tick_sum += int(tick_v)
	if poison.has("total"):
		return int(poison.get("total", 0))
	return tick_sum


func _resolver_step_auto(fight: FightState) -> Dictionary:
	var actor_id: String = fight.current_actor()
	if actor_id == "":
		return fight.step({})
	if str(fight.fighter_dict(actor_id).get("side", "")) == "beast":
		return fight.step({})
	var targets: Array[String] = fight.legal_targets(actor_id)
	var target_id: String = targets[0] if not targets.is_empty() else ""
	return fight.step({"kind": "strike", "target": target_id})


func _resolver_same_ints(got: Array, expect: Array, label: String) -> int:
	var failed: int = 0
	failed += _assert(got.size() == expect.size(), "%s size %d vs %d (%s vs %s)" % [label, got.size(), expect.size(), str(got), str(expect)])
	if got.size() == expect.size():
		for i: int in got.size():
			failed += _assert(int(got[i]) == int(expect[i]), "%s [%d] %s vs %s" % [label, i, str(got[i]), str(expect[i])])
	return failed


func _resolver_same_ids(got: Variant, expect: Variant, label: String) -> int:
	var failed: int = 0
	var got_ids: Array = got as Array if got is Array else []
	var expect_ids: Array = expect as Array if expect is Array else []
	failed += _assert(got is Array and expect is Array, "%s ids are lists" % label)
	failed += _assert(got_ids.size() == expect_ids.size(), "%s size %d vs %d (%s vs %s)" % [label, got_ids.size(), expect_ids.size(), str(got_ids), str(expect_ids)])
	if got_ids.size() == expect_ids.size():
		for i: int in got_ids.size():
			failed += _assert(str(got_ids[i]) == str(expect_ids[i]), "%s [%d] %s vs %s" % [label, i, str(got_ids[i]), str(expect_ids[i])])
	return failed


func _resolver_run_case(case: Dictionary, extra: Array[int]) -> Dictionary:
	var fight: FightState = FightStateScript.new()
	var att: Dictionary = case.get("attacker", {}) as Dictionary
	var dfn: Dictionary = case.get("defender", {}) as Dictionary
	var attack_type: String = str(case.get("attack_type", "physical"))
	var att_side: String = _resolver_side(str(att.get("name", "")))
	var dfn_side: String = _resolver_side(str(dfn.get("name", "")))
	var att_member: String = ""
	var dfn_member: String = ""
	if att_side == "party":
		att_member = "elaia" if str(att.get("name", "")) == "Elaia" else "keeper"
	if dfn_side == "party":
		dfn_member = "elaia" if str(dfn.get("name", "")) == "Elaia" else "keeper"
	var dfn_kind: String = str(dfn.get("kind", "phys"))
	var dfn_attack: String = "magic" if dfn_kind == "mag" else "physical"
	fight.add_fighter("attacker", att_side, att, 0, "front", attack_type, "", att_member)
	fight.add_fighter("defender", dfn_side, dfn, 0, "front", dfn_attack, "", dfn_member)
	var faces: Array[int] = _resolver_faces(case)
	for face: int in extra:
		faces.append(face)
	fight.set_scripted_dice(faces)
	var result: Dictionary = fight.strike("attacker", "defender", int(case.get("to_hit_mod", 0)), case.get("telegraph_mult", 1))
	return {
		"result": result,
		"remaining": fight.scripted_remaining(),
		"underrun": fight.scripted_underrun(),
		"queue": fight.scripted_queue(),
		"fight": fight,
		"defender_side": dfn_side,
	}


func _resolver_expect(cid: String, result: Dictionary, expect: Dictionary, fight: FightState) -> int:
	var failed: int = 0
	for key: String in ["attack_total", "defense_total", "margin", "damage", "defender_hp_after"]:
		failed += _assert(int(result.get(key, -99999)) == int(expect.get(key, -88888)), "%s %s got %s want %s" % [cid, key, str(result.get(key)), str(expect.get(key))])
	failed += _assert(str(result.get("band", "")) == str(expect.get("band", "")), "%s band got %s want %s" % [cid, str(result.get("band")), str(expect.get("band"))])
	failed += _assert(bool(result.get("fate_crit", false)) == bool(expect.get("fate_crit", false)), "%s fate_crit got %s want %s" % [cid, str(result.get("fate_crit")), str(expect.get("fate_crit"))])
	var card: Dictionary = fight.fighter_dict("defender")
	failed += _assert(int(card.get("hp", 99999)) == int(expect.get("defender_hp_after", -88888)), "%s defender hp stored" % cid)
	return failed


func _resolver_faces(case: Dictionary) -> Array[int]:
	var dice: Dictionary = case.get("dice", {}) as Dictionary
	var faces: Array[int] = []
	for key: String in ["attack_2d6", "defense_2d6"]:
		var rolls: Variant = dice.get(key, [])
		if rolls is Array:
			for face_v: Variant in rolls:
				faces.append(int(face_v))
	if dice.get("damage_face", null) != null:
		faces.append(int(dice.get("damage_face")))
	if dice.get("fate_roll_0_100", null) != null:
		faces.append(int(dice.get("fate_roll_0_100")))
	return faces


func _resolver_side(fighter_name: String) -> String:
	if fighter_name == "Keeper" or fighter_name == "Elaia":
		return "party"
	return "beast"


func _resolver_threshold_hit(side: String, vitality: int, hp: int) -> Dictionary:
	## The min_damage_1 dice: graze for exactly 1, no Fate roll.
	var fight: FightState = FightStateScript.new()
	var att: Dictionary = {
		"might": 1, "arcana": 1, "resilience": 7, "ward": 3, "vitality": 9,
		"swiftness": 6, "fate": 0,
	}
	var dfn: Dictionary = {
		"might": 11, "arcana": 5, "resilience": 12, "ward": 5, "vitality": vitality,
		"swiftness": 7, "fate": 7, "hp": hp,
	}
	var member: String = "keeper" if side == "party" else ""
	var species: String = "" if side == "party" else "acorn_imp"
	fight.add_fighter("attacker", "beast", att, 0, "front", "physical", "", "")
	fight.add_fighter("defender", side, dfn, 0, "front", "physical", species, member)
	fight.set_scripted_dice([6, 6, 1, 1, 1])
	var result: Dictionary = fight.strike("attacker", "defender", 0, 1)
	return {
		"result": result,
		"max_hp": int(fight.fighter_dict("defender").get("max_hp", 0)),
		"remaining": fight.scripted_remaining(),
		"underrun": fight.scripted_underrun(),
	}


func _resolver_beast_rows() -> Dictionary:
	var data: Dictionary = _json_dict("res://data/beasts.json")
	var by_id: Dictionary = {}
	for key: String in ["species", "variants"]:
		for row_v: Variant in data.get(key, []) as Array:
			if row_v is Dictionary:
				var row: Dictionary = row_v as Dictionary
				by_id[str(row.get("id", ""))] = row
	return by_id


func _resolver_fighter_row(state: Dictionary, fighter_id: String) -> Dictionary:
	for row_v: Variant in state.get("fighters", []) as Array:
		if row_v is Dictionary:
			var row: Dictionary = row_v as Dictionary
			if str(row.get("id", "")) == fighter_id:
				return row
	return {}


const _BATTLE_SHELL_SLOT: int = 6


func _battle_shell(tree_root: Window, game_state: Node, save_service: Node) -> int:
	## The arena is a fullscreen shell over a live hub. It opens only through
	## BattleView.open_arena, the call the debug button makes.
	var failed: int = 0
	paused = false
	game_state.call("reset_for_new_game")
	save_service.set("boot_intent", "new")
	save_service.call("delete_slot", _BATTLE_SHELL_SLOT)
	var live: Node = await _echo2_boot_hub(tree_root)
	failed += _assert(live != null, "hub boots for the arena shell")
	if live == null:
		paused = false
		return failed
	var hud: Node = live.get_node_or_null("HUD")
	if hud != null and hud.has_method("hide_welcome"):
		hud.call("hide_welcome")
	game_state.set("welcome_shown", true)
	failed += _assert(not bool(BattleViewScript.is_open()), "arena is closed at boot")
	failed += _assert(get_nodes_in_group("battle_overlay").is_empty(), "boot does not add an arena")
	failed += _assert(not bool(live.call("world_input_blocked")), "hub input is open before the arena")
	var keeper: Node2D = live.get_node_or_null("World/Keeper") as Node2D
	var pause_menu: Node = live.get_node_or_null("PauseMenu")
	failed += _assert(keeper != null and pause_menu != null, "hub has a Keeper and a pause menu")
	if keeper == null or pause_menu == null:
		live.free()
		game_state.call("reset_for_new_game")
		paused = false
		return failed
	failed += _assert(bool(BattleViewScript.open_arena()), "open_arena opens the shell")
	var views: Array[Node] = get_nodes_in_group("battle_overlay")
	failed += _assert(views.size() == 1, "one arena overlay")
	var view: CanvasLayer = null
	if views.size() == 1:
		view = views[0] as CanvasLayer
	failed += _assert(view != null, "arena is a CanvasLayer")
	if view == null:
		live.free()
		game_state.call("reset_for_new_game")
		paused = false
		return failed
	var pause_layer: int = int(pause_menu.get("layer"))
	var arena_layer: int = int(view.layer)
	failed += _assert(view.visible, "arena layer is visible")
	failed += _assert(arena_layer > 50 and arena_layer < pause_layer, "arena layer is above Echo and below pause (got %d, pause %d)" % [arena_layer, pause_layer])
	failed += _assert(not paused, "opening the arena does not pause the tree")
	var bg: ColorRect = view.get_node_or_null("Background") as ColorRect
	failed += _assert(bg != null and bg.is_visible_in_tree(), "arena backdrop is on screen")
	if bg != null:
		var col: Color = bg.color
		failed += _assert(col.g > col.r and col.g > col.b and col.g < 0.35 and col.a > 0.9, "arena backdrop is dark green")
	var placeholder: Label = view.get_node_or_null("Arena/Placeholder") as Label
	failed += _assert(placeholder != null and not placeholder.visible, "the art-coming line is hidden now that the arena art is in")
	var backdrop: TextureRect = view.get_node_or_null("Arena/Backdrop") as TextureRect
	var foreground: TextureRect = view.get_node_or_null("Arena/Foreground") as TextureRect
	failed += _assert(backdrop != null and backdrop.texture != null and backdrop.texture.get_size() == Vector2(1600, 900), "the forest backdrop is the 1600x900 arena art")
	failed += _assert(foreground != null and foreground.texture != null and foreground.get_index() > (view.get_node("Arena/Fighters") as Node).get_index(), "the foreground draws over the fighters")
	failed += _assert(backdrop != null and backdrop.mouse_filter == Control.MOUSE_FILTER_IGNORE and foreground != null and foreground.mouse_filter == Control.MOUSE_FILTER_IGNORE, "arena art takes no clicks")
	for member: String in ["keeper", "elaia"]:
		var fighter: Node = view.get_node_or_null("Arena/Fighters/Fighter_%s" % member)
		var sprite: TextureRect = fighter.get_node_or_null("Sprite") as TextureRect if fighter != null else null
		failed += _assert(sprite != null and sprite.texture != null and sprite.texture.get_size() == Vector2(128, 128), "%s stands in the arena in a battle pose" % member)
		for pose: String in ["attack", "brace", "hurt", "ko"]:
			failed += _assert(bool(view.call("set_fighter_pose", member, pose)), "%s %s pose loads" % [member, pose])
		view.call("set_fighter_pose", member, "idle")
	var keeper_node: Control = view.get_node_or_null("Arena/Fighters/Fighter_keeper") as Control
	var elaia_node: Control = view.get_node_or_null("Arena/Fighters/Fighter_elaia") as Control
	failed += _assert(keeper_node != null and keeper_node.position == Vector2(448, 512), "Keeper stands on the front middle slot")
	failed += _assert(elaia_node != null and elaia_node.position == Vector2(328, 482), "Elaia stands on the back middle slot")
	for beast_id: String in BattleViewScript.BEAST_HURT.keys():
		failed += _assert(ResourceLoader.exists(str(BattleViewScript.BEAST_HURT[beast_id])), "%s hurt frame is imported" % beast_id)
	var close_btn: Button = view.get_node_or_null("Arena/CloseButton") as Button
	failed += _assert(close_btn != null and close_btn.visible and close_btn.text == "Close", "Close is visible")
	failed += _assert(get_nodes_in_group("battle_slot_outline").size() == 12, "front and back rows mark twelve slots")
	var slot_root: Node = view.get_node_or_null("Arena/Slots")
	var slot_nodes: Array[Node] = slot_root.get_children() if slot_root != null else []
	failed += _assert(slot_nodes.size() == 12, "slot outlines live under the arena")
	if slot_nodes.size() == 12:
		var party_front: Control = slot_nodes[0] as Control
		var party_back: Control = slot_nodes[3] as Control
		var beast_front: Control = slot_nodes[6] as Control
		var beast_back: Control = slot_nodes[9] as Control
		failed += _assert(party_front != null and party_back != null and beast_front != null and beast_back != null, "row outlines are controls")
		if party_front != null and party_back != null and beast_front != null and beast_back != null:
			var half: Vector2 = party_front.size * 0.5
			failed += _assert(party_front.position + half == Vector2(448, 452) and beast_back.position + half == Vector2(952, 422), "slot marks sit on the arena art's sole points")
			failed += _assert(party_back.position.x < party_front.position.x, "party back column stands behind the front")
			failed += _assert(party_back.position.y < party_front.position.y, "party back row sits behind the front row")
			failed += _assert(beast_back.position.x > beast_front.position.x, "beast back column stands behind the front")
			failed += _assert(beast_back.position.y < beast_front.position.y, "beast back row sits behind the front row")
			failed += _assert(beast_front.position.x > party_front.position.x + 300.0, "beasts stand on the right")
	var clock_before: float = float(game_state.get("run_time_sec"))
	for _frame: int in 60:
		await process_frame
	var clock_after: float = float(game_state.get("run_time_sec"))
	failed += _assert(clock_after > clock_before, "hub clock moves while the arena is open (%.4f -> %.4f)" % [clock_before, clock_after])
	failed += _assert(not paused, "the hub is still running after a minute of frames")
	game_state.call("select_keeper")
	if keeper.has_method("halt"):
		keeper.call("halt")
	var origin: Vector2 = keeper.global_position
	var point: Vector2 = _battle_walk_point(live, origin)
	_battle_click(live, point, MOUSE_BUTTON_LEFT)
	_battle_click(live, point, MOUSE_BUTTON_RIGHT)
	for _blocked: int in 8:
		await physics_frame
	failed += _assert(keeper.global_position.distance_to(origin) < 1.0, "clicks do not move the Keeper")
	failed += _assert(not bool(keeper.get("_moving")), "clicks do not command the Keeper")
	failed += _assert(bool(game_state.get("keeper_selected")), "a blocked left click does not deselect the Keeper")
	_battle_escape(live)
	await process_frame
	failed += _assert(not bool(BattleViewScript.is_open()), "Escape closes the arena")
	failed += _assert(get_nodes_in_group("battle_overlay").is_empty(), "Escape frees the overlay")
	failed += _assert(not bool(pause_menu.call("is_open")), "Escape does not open the pause menu")
	failed += _assert(not paused, "closing the arena leaves the hub running")
	var still: Vector2 = keeper.global_position
	_battle_click(live, point, MOUSE_BUTTON_RIGHT)
	for _walk: int in 20:
		await physics_frame
	var moved: float = keeper.global_position.distance_to(still)
	failed += _assert(bool(keeper.get("_moving")) or moved > 4.0, "the same right-click moves the Keeper after Escape (moved %.1f)" % moved)
	if keeper.has_method("halt"):
		keeper.call("halt")
	failed += _assert(bool(BattleViewScript.open_arena()), "the arena opens again")
	failed += _assert(bool(BattleViewScript.open_arena()), "a second open is the same overlay")
	failed += _assert(get_nodes_in_group("battle_overlay").size() == 1, "opening twice does not stack")
	failed += _assert(get_nodes_in_group("battle_slot_outline").size() == 12, "a second open adds no rows")
	# A real mouse click on Close (GUI path, not close_overlay()) closes the arena.
	var again: Array[Node] = get_nodes_in_group("battle_overlay")
	var close_again: Button = (again[0] as Node).get_node_or_null("Arena/CloseButton") as Button if again.size() == 1 else null
	failed += _assert(close_again != null, "Close button exists on the reopened arena")
	if close_again != null:
		var vp_close: Viewport = live.get_viewport()
		var at: Vector2 = close_again.get_global_rect().get_center()
		vp_close.warp_mouse(at)
		var hover := InputEventMouseMotion.new()
		hover.position = at
		hover.global_position = at
		vp_close.push_input(hover, true)
		for pressed_v: bool in [true, false]:
			var press := InputEventMouseButton.new()
			press.button_index = MOUSE_BUTTON_LEFT
			press.pressed = pressed_v
			press.position = at
			press.global_position = at
			vp_close.push_input(press, true)
		await process_frame
		failed += _assert(not bool(BattleViewScript.is_open()), "a mouse click on Close closes the arena")
	if not bool(BattleViewScript.is_open()):
		failed += _assert(bool(BattleViewScript.open_arena()), "the arena opens after Close")
	var wood_before: int = int(game_state.get("wood"))
	failed += _assert(bool(save_service.call("save_game", _BATTLE_SHELL_SLOT)), "save works while the arena is open")
	var slot_text: String = FileAccess.get_file_as_string(str(save_service.call("slot_path", _BATTLE_SHELL_SLOT)))
	failed += _assert(slot_text.find("BattleArena") < 0 and slot_text.find("battle_overlay") < 0, "the save does not store the arena")
	failed += _assert(bool(save_service.call("load_game", _BATTLE_SHELL_SLOT)), "load the arena save")
	await process_frame
	failed += _assert(not bool(BattleViewScript.is_open()), "load closes the arena")
	failed += _assert(get_nodes_in_group("battle_overlay").is_empty(), "load frees the overlay")
	failed += _assert(int(game_state.get("wood")) == wood_before, "load keeps the hub wood")
	failed += _assert(not paused, "load does not leave the tree paused")
	live.free()
	await process_frame
	game_state.call("reset_for_new_game")
	save_service.call("delete_slot", _BATTLE_SHELL_SLOT)
	paused = false
	if failed == 0:
		print("BATTLE_SHELL_OK")
	return failed


func _battle_plates(tree_root: Window, game_state: Node, save_service: Node) -> int:
	## Formation, party bar, beast plates, and intent markers on the live arena shell.
	var failed: int = 0
	paused = false
	game_state.call("reset_for_new_game")
	save_service.set("boot_intent", "new")
	var live: Node = await _echo2_boot_hub(tree_root)
	failed += _assert(live != null, "hub boots for battle plates")
	if live == null:
		paused = false
		return failed
	var hud: Node = live.get_node_or_null("HUD")
	if hud != null and hud.has_method("hide_welcome"):
		hud.call("hide_welcome")
	game_state.set("welcome_shown", true)
	failed += _assert(bool(BattleViewScript.open_arena()), "open_arena for plates")
	var views: Array[Node] = get_nodes_in_group("battle_overlay")
	failed += _assert(views.size() == 1, "one arena overlay for plates")
	var view: BattleView = views[0] as BattleView if views.size() == 1 else null
	failed += _assert(view != null, "arena is a BattleView")
	if view == null:
		live.free()
		game_state.call("reset_for_new_game")
		paused = false
		return failed
	var keeper_node: Control = view.get_node_or_null("Arena/Fighters/Fighter_keeper") as Control
	var elaia_node: Control = view.get_node_or_null("Arena/Fighters/Fighter_elaia") as Control
	failed += _assert(keeper_node != null and keeper_node.position == Vector2(448, 512), "placeholder Keeper on front middle")
	failed += _assert(elaia_node != null and elaia_node.position == Vector2(328, 482), "placeholder Elaia on back middle")
	var fight: FightState = FightStateScript.new()
	var keeper_stats: Dictionary = {
		"might": 11, "arcana": 5, "resilience": 6, "ward": 5,
		"vitality": 6, "swiftness": 7, "fate": 7, "attack": "physical",
	}
	failed += _assert(fight.add_member("keeper", keeper_stats, 0, "front") == "keeper", "keeper joins the fight")
	var elaia_stats: Dictionary = {
		"might": 4, "arcana": 7, "resilience": 5, "ward": 7,
		"vitality": 6, "swiftness": 6, "fate": 5, "attack": "magic",
	}
	failed += _assert(fight.add_member("elaia", elaia_stats, 1, "back", "elaia") == "elaia", "elaia joins the fight")
	failed += _assert(fight.add_beast("acorn_imp", 0, "front") == "acorn_imp", "first imp")
	failed += _assert(fight.add_beast("spore_moth", 1, "back") == "spore_moth", "moth")
	failed += _assert(fight.add_beast("acorn_imp", 1, "front") == "acorn_imp_2", "second imp")
	view.call("show_fight", fight)
	await process_frame
	var imp_a: Control = view.get_node_or_null("Arena/Fighters/Fighter_acorn_imp") as Control
	var imp_b: Control = view.get_node_or_null("Arena/Fighters/Fighter_acorn_imp_2") as Control
	var keeper_f: Control = view.get_node_or_null("Arena/Fighters/Fighter_keeper") as Control
	failed += _assert(keeper_f != null and keeper_f.position == Vector2(448, 512), "Keeper alone uses front middle sole")
	failed += _assert(imp_a != null and imp_b != null, "both imps spawned")
	if imp_a != null and imp_b != null:
		var front_soles: Array = BattleViewScript.SLOT_SOLES["beast_front"]
		failed += _assert(imp_a.position == front_soles[0] and imp_b.position == front_soles[2], "front imps on soles 0 and 2")
	var keeper_sprite: TextureRect = keeper_f.get_node_or_null("Sprite") as TextureRect if keeper_f != null else null
	failed += _assert(keeper_sprite != null and keeper_sprite.texture != null and keeper_sprite.texture.get_size() == Vector2(128, 128), "keeper idle 128x128")
	failed += _assert(bool(view.call("set_fighter_pose", "keeper", "brace")), "keeper brace pose")
	var party_bar: PanelContainer = view.get_node_or_null("Arena/PartyBar") as PanelContainer
	failed += _assert(party_bar != null, "PartyBar exists")
	if party_bar != null:
		var keeper_plate: Node = party_bar.find_child("PartyPlate_keeper", true, false)
		var elaia_plate: Node = party_bar.find_child("PartyPlate_elaia", true, false)
		failed += _assert(keeper_plate != null and elaia_plate != null, "two party plates")
		if keeper_plate != null:
			var hp_label: Label = keeper_plate.find_child("HpLabel", true, false) as Label
			failed += _assert(hp_label != null and hp_label.text == "HP 28/28", "keeper HP line on the bar")
	for beast_id: String in ["acorn_imp", "acorn_imp_2", "spore_moth"]:
		var plate: Control = view.get_node_or_null("Arena/BeastPlate_%s" % beast_id) as Control
		failed += _assert(plate != null, "beast plate %s" % beast_id)
		if plate != null:
			var intent: Control = plate.get_node_or_null("IntentMarker") as Control
			failed += _assert(intent != null, "intent marker on %s" % beast_id)
	var imp_a_plate: Control = view.get_node_or_null("Arena/BeastPlate_acorn_imp") as Control
	var imp_b_plate: Control = view.get_node_or_null("Arena/BeastPlate_acorn_imp_2") as Control
	if imp_a_plate != null and imp_b_plate != null:
		var name_a: Label = imp_a_plate.get_node_or_null("NameLabel") as Label
		var name_b: Label = imp_b_plate.get_node_or_null("NameLabel") as Label
		failed += _assert(name_a != null and name_b != null and name_a.text == "Acorn imp A" and name_b.text == "Acorn imp B", "imp plate names")
	view.call("set_active", "elaia")
	await process_frame
	var outlines: Array[Node] = get_nodes_in_group("battle_plate_outline")
	failed += _assert(outlines.size() == 1, "one active outline")
	if outlines.size() == 1:
		var on_plate: Node = outlines[0].get_parent()
		failed += _assert(on_plate != null and on_plate.name == "PartyPlate_elaia", "outline on Elaia's plate")
	fight.set_hp("acorn_imp", 1)
	view.call("refresh_fight", fight)
	await process_frame
	if imp_a != null:
		var imp_sprite: CanvasItem = imp_a.get_node_or_null("Sprite") as CanvasItem
		failed += _assert(imp_sprite != null and is_equal_approx(imp_sprite.modulate.a, 0.35), "calmed imp fades")
	if imp_a_plate != null:
		var calm: Label = imp_a_plate.get_node_or_null("StatusLabel") as Label
		failed += _assert(calm != null and calm.text == "Calmed", "imp plate shows Calmed")
	var close_btn: Button = view.get_node_or_null("Arena/CloseButton") as Button
	failed += _assert(close_btn != null, "Close button present")
	if close_btn != null:
		failed += _assert(is_equal_approx(close_btn.offset_left, 1140.0) and is_equal_approx(close_btn.offset_top, 16.0), "Close sits top-right")
		failed += _assert(is_equal_approx(close_btn.offset_right, 1264.0) and is_equal_approx(close_btn.offset_bottom, 52.0), "Close rect matches art")
	BattleViewScript.close_arena()
	await process_frame
	failed += _assert(not bool(BattleViewScript.is_open()), "close_arena still closes")
	live.free()
	await process_frame
	game_state.call("reset_for_new_game")
	paused = false
	if failed == 0:
		print("BATTLE_PLATES_OK")
	return failed


func _battle_menu_clear_of_party_bar(view: Node, label: String) -> int:
	var failed: int = 0
	var bar: Control = view.get_node_or_null("Arena/PartyBar") as Control
	var menu: Control = view.get_node_or_null("Arena/ActionMenu") as Control
	failed += _assert(bar != null and menu != null, "%s: party bar and menu exist" % label)
	if bar == null or menu == null:
		return failed
	var bar_top: float = bar.get_global_rect().position.y
	var seen: int = 0
	for node: Node in menu.find_children("*", "Button", true, false):
		var button: Button = node as Button
		if not button.is_visible_in_tree():
			continue
		seen += 1
		var rect: Rect2 = button.get_global_rect()
		failed += _assert(rect.end.y <= bar_top and rect.position.y >= 0.0, "%s: %s sits above the party bar (%.0f > %.0f)" % [label, button.name, rect.end.y, bar_top])
	failed += _assert(seen > 0, "%s: menu has visible buttons" % label)
	return failed


func _battle_menu(tree_root: Window, game_state: Node, save_service: Node) -> int:
	var failed: int = 0
	paused = false
	game_state.call("reset_for_new_game")
	save_service.set("boot_intent", "new")
	var content_strings: Node = tree_root.get_node_or_null("ContentStrings")
	var backpack: Node = tree_root.get_node_or_null("Backpack")
	var live: Node = await _echo2_boot_hub(tree_root)
	failed += _assert(live != null and backpack != null, "hub boots for battle menu")
	if live == null:
		paused = false
		return failed
	var hud: Node = live.get_node_or_null("HUD")
	if hud != null and hud.has_method("hide_welcome"):
		hud.call("hide_welcome")
	game_state.set("welcome_shown", true)
	var wood_before: int = int(game_state.get("wood"))
	var salve_before: int = int(backpack.call("get_count", "heart_salve"))
	failed += _assert(bool(BattleViewScript.open_arena()), "open_arena for menu")
	var views: Array[Node] = get_nodes_in_group("battle_overlay")
	failed += _assert(views.size() == 1, "one arena overlay for menu")
	var view: BattleView = views[0] as BattleView if views.size() == 1 else null
	failed += _assert(view != null, "arena is a BattleView")
	if view == null:
		live.free()
		game_state.call("reset_for_new_game")
		paused = false
		return failed
	view.call("start_test_fight", 1, false, true, 12345)
	await process_frame
	var menu: VBoxContainer = view.get_node_or_null("Arena/ActionMenu") as VBoxContainer
	failed += _assert(menu != null and menu.visible, "menu on first party turn")
	var idle_btn: Button = view.get_node_or_null("Arena/ActionMenu/IdleButton") as Button
	failed += _assert(idle_btn != null and idle_btn.disabled, "Idle is disabled")
	var ability_row: Node = menu.get_node_or_null("AbilityRow")
	for n: int in 4:
		var ab: Button = null
		if ability_row != null:
			ab = ability_row.get_node_or_null("AbilityButton%d" % (n + 1)) as Button
		failed += _assert(ab != null and ab.disabled and ab.text == "—", "ability %d empty" % (n + 1))
		failed += _assert(ab != null and ab.tooltip_text.find("Weave") >= 0, "ability %d tooltip" % (n + 1))
	var salve_btn: Button = view.get_node_or_null("Arena/ActionMenu/SalveButton") as Button
	failed += _assert(salve_btn != null and salve_btn.text.find("Heart Salve") >= 0 and salve_btn.text.find("×2") >= 0, "salve shows ×2")
	failed += _assert(ability_row != null and not (ability_row as CanvasItem).is_visible_in_tree(), "no empty ability row is visible")
	failed += _battle_menu_clear_of_party_bar(view, "first party turn")
	var sfm_toggle: Button = view.get_node_or_null("Arena/ActionMenu/StrikeForMeToggle") as Button
	failed += _assert(sfm_toggle != null and sfm_toggle.is_visible_in_tree(), "Strike for me toggle shows in the menu")
	var brace_btn: Button = view.get_node_or_null("Arena/ActionMenu/BraceButton") as Button
	failed += _assert(brace_btn != null, "Brace button")
	if brace_btn != null:
		brace_btn.emit_signal("pressed")
	await process_frame
	var fight: FightState = view._fight
	failed += _assert(fight != null, "fight state")
	if fight != null:
		var braced: bool = false
		for line: Variant in fight.log_tail:
			if str(line).find("braces") >= 0:
				braced = true
				break
		failed += _assert(braced, "brace log line")
	var salve_done: bool = false
	var strike_presses: int = 0
	while fight != null and fight.outcome() == "" and strike_presses < 300:
		await process_frame
		var actor: String = fight.current_actor()
		if actor == "":
			view.call("_advance")
			continue
		if str(fight.fighter_dict(actor).get("side", "")) != "party":
			view.call("_advance")
			continue
		if actor == "keeper" and not salve_done:
			fight.set_hp("keeper", 5)
			view.call("refresh_fight", fight)
			salve_btn = view.get_node_or_null("Arena/ActionMenu/SalveButton") as Button
			if salve_btn != null:
				salve_btn.emit_signal("pressed")
			await process_frame
			var salve_target: Button = view.get_node_or_null("Arena/TargetLayer/TargetButton_keeper") as Button
			failed += _assert(salve_target != null, "salve target on Keeper")
			if salve_target != null:
				salve_target.emit_signal("pressed")
			await process_frame
			salve_btn = view.get_node_or_null("Arena/ActionMenu/SalveButton") as Button
			failed += _assert(salve_btn != null and salve_btn.text.find("×1") >= 0, "salve count drops to ×1")
			var keeper_hp: int = int(fight.fighter_dict("keeper").get("hp", 0))
			failed += _assert(keeper_hp > 5, "salve heals Keeper")
			salve_done = true
			continue
		var strike_btn: Button = view.get_node_or_null("Arena/ActionMenu/StrikeButton") as Button
		if strike_btn != null and strike_btn.visible:
			strike_btn.emit_signal("pressed")
		await process_frame
		var target_layer: Node = view.get_node_or_null("Arena/TargetLayer")
		var picked: Button = null
		if target_layer != null:
			for child: Node in target_layer.get_children():
				if str(child.name).begins_with("TargetButton_"):
					picked = child as Button
					break
		if picked != null:
			picked.emit_signal("pressed")
			strike_presses += 1
		await process_frame
	var result: Label = view.get_node_or_null("Arena/ResultLabel") as Label
	failed += _assert(fight != null and fight.outcome() != "", "fight reaches an outcome")
	failed += _assert(result != null and result.text != "", "ResultLabel shows a result")
	failed += _assert(strike_presses < 300, "fight ends within 300 strikes")
	var start_btn: Button = view.get_node_or_null("Arena/TestFightBar/StartFightButton") as Button
	failed += _assert(start_btn != null and not start_btn.disabled, "Start fight is enabled after the fight")
	if start_btn != null:
		var vp: Viewport = live.get_viewport()
		var at: Vector2 = start_btn.get_global_rect().get_center()
		vp.warp_mouse(at)
		var hover := InputEventMouseMotion.new()
		hover.position = at
		hover.global_position = at
		vp.push_input(hover, true)
		for pressed_v: bool in [true, false]:
			var press := InputEventMouseButton.new()
			press.button_index = MOUSE_BUTTON_LEFT
			press.pressed = pressed_v
			press.position = at
			press.global_position = at
			vp.push_input(press, true)
		await process_frame
	view.call("start_test_fight", 1, false, true, 54321)
	await process_frame
	var flee_btn: Button = view.get_node_or_null("Arena/ActionMenu/FleeButton") as Button
	if flee_btn != null:
		flee_btn.emit_signal("pressed")
	await process_frame
	failed += _assert(view._fight != null and view._fight.outcome() == "flee", "flee outcome")
	result = view.get_node_or_null("Arena/ResultLabel") as Label
	var trail: String = str(content_strings.call("get_text", "adv_back_at_trailhead"))
	failed += _assert(result != null and result.text == trail, "flee ResultLabel")
	failed += _assert(int(backpack.call("get_count", "heart_salve")) == salve_before, "backpack salve unchanged")
	failed += _assert(int(game_state.get("wood")) == wood_before, "wood unchanged")
	BattleViewScript.close_arena()
	live.free()
	game_state.call("reset_for_new_game")
	paused = false
	if failed == 0:
		print("BATTLE_MENU_OK")
	return failed


func _battle_click_control(live: Node, control: Control) -> void:
	if control == null:
		return
	var vp: Viewport = live.get_viewport()
	var at: Vector2 = control.get_global_rect().get_center()
	vp.warp_mouse(at)
	var hover := InputEventMouseMotion.new()
	hover.position = at
	hover.global_position = at
	vp.push_input(hover, true)
	for pressed_v: bool in [true, false]:
		var press := InputEventMouseButton.new()
		press.button_index = MOUSE_BUTTON_LEFT
		press.pressed = pressed_v
		press.position = at
		press.global_position = at
		vp.push_input(press, true)


func _battle_strike_for_me(tree_root: Window, game_state: Node, save_service: Node) -> int:
	const ROOM_SEED: int = 482901
	const ROOM_SEED_OFF: int = 918273
	var failed: int = 0
	paused = false
	game_state.call("reset_for_new_game")
	save_service.set("boot_intent", "new")
	var live: Node = await _echo2_boot_hub(tree_root)
	failed += _assert(live != null, "hub boots for strike for me")
	if live == null:
		paused = false
		return failed
	var hud: Node = live.get_node_or_null("HUD")
	if hud != null and hud.has_method("hide_welcome"):
		hud.call("hide_welcome")
	game_state.set("welcome_shown", true)
	failed += _assert(bool(BattleViewScript.open_arena()), "open_arena for strike for me")
	var views: Array[Node] = get_nodes_in_group("battle_overlay")
	var view: BattleView = views[0] as BattleView if views.size() == 1 else null
	failed += _assert(view != null, "BattleView for strike for me")
	if view == null:
		live.free()
		game_state.call("reset_for_new_game")
		paused = false
		return failed
	var toggle: Button = view.get_node_or_null("Arena/ActionMenu/StrikeForMeToggle") as Button
	failed += _assert(toggle != null and toggle.toggle_mode, "StrikeForMeToggle exists")
	if toggle != null:
		failed += _assert(toggle.text.find("Strike for me") >= 0, "toggle text adv_strike_for_me")
		failed += _assert(toggle.tooltip_text.find("1×") >= 0, "toggle tooltip adv_strike_for_me_tip")
	var party_packets: Array[Dictionary] = []
	var on_party_step := func(packet: Dictionary) -> void:
		party_packets.append(packet)
	view.strike_for_me_party_stepped.connect(on_party_step)
	view.call("start_test_fight", 1, false, true, ROOM_SEED)
	await process_frame
	failed += _assert(not bool(view.call("strike_for_me_on")), "toggle starts off on new fight")
	var fight: FightState = view._fight
	failed += _assert(fight != null and fight.outcome() == "", "fight begins")
	if fight != null:
		var keeper_row: Dictionary = fight.fighter_dict("keeper")
		var low_hp: int = maxi(1, int(keeper_row.get("max_hp", 1)) / 5)
		fight.set_hp("keeper", low_hp)
	if toggle != null:
		_battle_click_control(live, toggle)
		toggle.emit_signal("pressed")
		toggle.set_block_signals(true)
		toggle.button_pressed = true
		toggle.set_block_signals(false)
		view.call("_on_strike_for_me_toggled", true)
	var frames: int = 0
	fight = view._fight
	while fight != null and fight.outcome() == "" and frames < 600:
		await process_frame
		frames += 1
		fight = view._fight
	failed += _assert(fight != null and fight.outcome() != "", "strike for me reaches an outcome")
	failed += _assert(frames < 600, "strike for me finishes within frame budget")
	failed += _assert(party_packets.size() > 0, "party steps recorded")
	for packet: Dictionary in party_packets:
		var kind: String = str(packet.get("kind", ""))
		failed += _assert(kind == "strike", "party only strikes (got %s)" % kind)
		for ev: Variant in packet.get("events", []):
			var ev_kind: String = str((ev as Dictionary).get("kind", ""))
			failed += _assert(ev_kind != "brace" and ev_kind != "flee" and ev_kind != "item", "no brace/flee/item events")
		failed += _assert(
			str(packet.get("target", "")) == str(packet.get("strike_for_me_target", "")),
			"strike targets front row then slot (got %s want %s)" % [str(packet.get("target", "")), str(packet.get("strike_for_me_target", ""))],
		)
	failed += _assert(bool(view.call("strike_for_me_on")), "toggle still on after auto fight")
	view.strike_for_me_party_stepped.disconnect(on_party_step)
	view.call("start_test_fight", 1, false, true, ROOM_SEED_OFF)
	await process_frame
	failed += _assert(not bool(view.call("strike_for_me_on")), "new fight resets toggle off")
	failed += _assert(toggle != null and not toggle.button_pressed, "toggle button reset")
	party_packets.clear()
	var off_party_steps: Array[int] = [0]
	var count_party_step := func(_packet: Dictionary) -> void:
		off_party_steps[0] += 1
	view.call("start_test_fight", 1, false, true, ROOM_SEED)
	await process_frame
	fight = view._fight
	view.strike_for_me_party_stepped.connect(count_party_step)
	var party_actor: String = fight.current_actor() if fight != null else ""
	failed += _assert(
		party_actor != "" and str(fight.fighter_dict(party_actor).get("side", "")) == "party",
		"party turn before strike-for-me off test",
	)
	var steps_at_party_turn: int = off_party_steps[0]
	if toggle != null:
		toggle.set_block_signals(true)
		toggle.button_pressed = true
		toggle.set_block_signals(false)
	if party_actor != "":
		view.call("_strike_for_me_party_step", party_actor)
	failed += _assert(
		off_party_steps[0] == steps_at_party_turn + 1,
		"one party strike while strike for me is on (got %d want %d)" % [off_party_steps[0], steps_at_party_turn + 1],
	)
	if toggle != null:
		toggle.set_block_signals(true)
		toggle.button_pressed = false
		toggle.set_block_signals(false)
	view.call("_advance")
	var off_frames: int = 0
	while fight != null and fight.outcome() == "" and off_frames < 400:
		await process_frame
		off_frames += 1
		fight = view._fight
		if not bool(view.call("strike_for_me_on")):
			break
	failed += _assert(
		off_party_steps[0] == steps_at_party_turn + 1,
		"exactly one party action before toggle off (got %d)" % off_party_steps[0],
	)
	failed += _assert(fight != null and fight.outcome() == "", "fight continues after turning strike for me off")
	var menu: VBoxContainer = view.get_node_or_null("Arena/ActionMenu") as VBoxContainer
	failed += _assert(menu != null and menu.visible, "menu visible for manual party turn")
	var next_actor: String = fight.current_actor() if fight != null else ""
	failed += _assert(next_actor != "" and str(fight.fighter_dict(next_actor).get("side", "")) == "party", "next actor is party")
	failed += _assert(bool(view.call("strike_for_me_on")) == (toggle != null and toggle.button_pressed), "strike_for_me_on matches toggle")
	if view.strike_for_me_party_stepped.is_connected(on_party_step):
		view.strike_for_me_party_stepped.disconnect(on_party_step)
	if view.strike_for_me_party_stepped.is_connected(count_party_step):
		view.strike_for_me_party_stepped.disconnect(count_party_step)
	BattleViewScript.close_arena()
	live.free()
	game_state.call("reset_for_new_game")
	paused = false
	if failed == 0:
		print("BATTLE_STRIKE_FOR_ME_OK")
	return failed


func _battle_target_reach(tree_root: Window, game_state: Node, save_service: Node) -> int:
	var failed: int = 0
	paused = false
	game_state.call("reset_for_new_game")
	save_service.set("boot_intent", "new")
	var live: Node = await _echo2_boot_hub(tree_root)
	failed += _assert(live != null, "hub boots for target reach")
	if live == null:
		paused = false
		return failed
	var hud: Node = live.get_node_or_null("HUD")
	if hud != null and hud.has_method("hide_welcome"):
		hud.call("hide_welcome")
	game_state.set("welcome_shown", true)
	failed += _assert(bool(BattleViewScript.open_arena()), "open_arena for target reach")
	var views: Array[Node] = get_nodes_in_group("battle_overlay")
	var view: BattleView = views[0] as BattleView if views.size() == 1 else null
	failed += _assert(view != null, "BattleView")
	if view == null:
		live.free()
		paused = false
		return failed
	var fight: FightState = FightStateScript.new()
	var keeper_stats: Dictionary = {
		"might": 11, "arcana": 5, "resilience": 6, "ward": 5,
		"vitality": 6, "swiftness": 7, "fate": 7, "attack": "physical",
	}
	fight.add_member("keeper", keeper_stats, 0, "front", "keeper")
	var elaia_stats: Dictionary = {
		"might": 4, "arcana": 7, "resilience": 5, "ward": 7,
		"vitality": 6, "swiftness": 6, "fate": 5, "attack": "magic",
	}
	fight.add_member("elaia", elaia_stats, 1, "back", "elaia")
	fight.add_beast("acorn_imp", 0, "front", "acorn_imp")
	fight.add_beast("spore_moth", 1, "back", "spore_moth")
	fight.loadout = {"heart_salve": 2}
	fight.start_fight()
	view._fight = fight
	view.call("show_fight", fight)
	view.call("_advance")
	await process_frame
	failed += _assert(await _battle_wait_actor(view, fight, "keeper", 120), "reach keeper turn")
	view.call("_on_strike_pressed")
	await process_frame
	failed += _assert(view.get_node_or_null("Arena/TargetLayer/TargetButton_acorn_imp") != null, "keeper melee targets front imp")
	failed += _assert(view.get_node_or_null("Arena/TargetLayer/TargetButton_spore_moth") == null, "keeper cannot reach back moth yet")
	view.call("_exit_target_mode")
	failed += _assert(await _battle_wait_actor(view, fight, "elaia", 120), "reach Elaia turn")
	view.call("_on_strike_pressed")
	await process_frame
	failed += _assert(view.get_node_or_null("Arena/TargetLayer/TargetButton_acorn_imp") != null, "Elaia sees imp")
	failed += _assert(view.get_node_or_null("Arena/TargetLayer/TargetButton_spore_moth") != null, "Elaia sees moth")
	var layer: Node = view.get_node_or_null("Arena/TargetLayer")
	if layer != null:
		for child: Node in layer.get_children():
			if str(child.name).begins_with("TargetButton_"):
				var tid: String = str(child.name).substr(13)
				failed += _assert(fight.legal_targets("elaia").has(tid), "target %s is legal for Elaia" % tid)
	view.call("_exit_target_mode")
	fight.set_hp("acorn_imp", 0)
	view.call("refresh_fight", fight)
	failed += _assert(await _battle_wait_actor(view, fight, "keeper", 120), "keeper turn after Calmed imp")
	view.call("_on_strike_pressed")
	await process_frame
	failed += _assert(view.get_node_or_null("Arena/TargetLayer/TargetButton_spore_moth") != null, "keeper can target moth after imp Calmed")
	failed += _assert(view.get_node_or_null("Arena/TargetLayer/TargetButton_acorn_imp") == null, "no target on Calmed imp")
	view.call("_exit_target_mode")
	var steps_before: int = fight.round
	view.call("_on_strike_pressed")
	await process_frame
	var imp_sprite: Control = view.get_node_or_null("Arena/Fighters/Fighter_acorn_imp") as Control
	if imp_sprite != null:
		var at: Vector2 = imp_sprite.get_global_rect().get_center()
		var vp: Viewport = live.get_viewport()
		vp.warp_mouse(at)
		var press := InputEventMouseButton.new()
		press.button_index = MOUSE_BUTTON_LEFT
		press.pressed = true
		press.position = at
		press.global_position = at
		vp.push_input(press, true)
		press.pressed = false
		vp.push_input(press, true)
		await process_frame
	failed += _assert(fight.round == steps_before, "click on non-target sprite does not step")
	var keeper: Node2D = live.get_node_or_null("World/Keeper") as Node2D
	if keeper != null and keeper.has_method("halt"):
		keeper.call("halt")
	var origin: Vector2 = keeper.global_position if keeper != null else Vector2.ZERO
	var point: Vector2 = _battle_walk_point(live, origin)
	_battle_click(live, point, MOUSE_BUTTON_RIGHT)
	for _blocked: int in 8:
		await physics_frame
	failed += _assert(keeper != null and keeper.global_position.distance_to(origin) < 1.0, "world click still blocked with arena open")
	BattleViewScript.close_arena()
	live.free()
	game_state.call("reset_for_new_game")
	paused = false
	if failed == 0:
		print("BATTLE_TARGET_REACH_OK")
	return failed


func _battle_wait_actor(view: BattleView, fight: FightState, actor_id: String, max_steps: int) -> bool:
	for _step: int in max_steps:
		if fight.outcome() != "":
			return false
		if fight.current_actor() == actor_id:
			return true
		var cur: String = fight.current_actor()
		if cur == "":
			view.call("_advance")
		elif str(fight.fighter_dict(cur).get("side", "")) == "beast":
			view.call("_advance")
		else:
			fight.step({"kind": "brace"})
			view.call("_advance")
		await process_frame
	return false


func _battle_echo_exclusive(tree_root: Window, game_state: Node, save_service: Node) -> int:
	## Echo and the arena refuse each other. A manual reach fight refuses the arena.
	## The debug button is the only Experimental opener.
	var failed: int = 0
	paused = false
	var echo: Node = tree_root.get_node_or_null("EchoChamber")
	var reach: Node = tree_root.get_node_or_null("Reach")
	failed += _assert(echo != null and reach != null, "Echo and Reach are loaded")
	if echo == null or reach == null:
		return failed
	if bool(echo.get("in_battle")):
		echo.call("dismiss_battle_without_reward")
	game_state.call("reset_for_new_game")
	save_service.set("boot_intent", "new")
	var live: Node = await _echo2_boot_hub(tree_root)
	failed += _assert(live != null, "hub boots for the arena lock")
	if live == null:
		paused = false
		return failed
	var hud: Node = live.get_node_or_null("HUD")
	if hud != null and hud.has_method("hide_welcome"):
		hud.call("hide_welcome")
	game_state.set("welcome_shown", true)
	failed += _assert(bool(BattleViewScript.open_arena()), "arena opens before the Echo check")
	var echo_before: int = _echo_battle_count(tree_root)
	echo.call("open_battle", true)
	failed += _assert(not bool(echo.get("in_battle")), "an open arena keeps Echo closed")
	failed += _assert(_echo_battle_count(tree_root) == echo_before, "an open arena adds no Echo view")
	failed += _assert(not paused, "a refused Echo does not pause the hub")
	BattleViewScript.close_arena()
	await process_frame
	echo.call("open_battle", true)
	failed += _assert(bool(echo.get("in_battle")), "Echo opens once the arena is closed")
	failed += _assert(_echo_battle_count(tree_root) == 1, "Echo adds one battle view")
	failed += _assert(not bool(BattleViewScript.open_arena()), "Echo refuses the arena")
	failed += _assert(not bool(BattleViewScript.is_open()), "Echo leaves the arena closed")
	failed += _assert(_echo_battle_count(tree_root) == 1, "a refused arena does not add a second Echo")
	echo.call("dismiss_battle_without_reward")
	await process_frame
	paused = false
	failed += _assert(not bool(echo.get("in_battle")), "dismiss leaves Echo")
	failed += _assert(_echo_battle_count(tree_root) == 0, "dismiss removes the Echo view")
	failed += _assert(bool(BattleViewScript.open_arena()), "the arena opens again after Echo")
	BattleViewScript.close_arena()
	await process_frame
	failed += _assert(str(reach.call("depart", 1, 1.0, "hold", "manual")) == "ok", "manual depart for the arena lock")
	failed += _assert(bool(reach.call("fight_active")), "manual depart opened a reach fight")
	failed += _assert(not bool(BattleViewScript.open_arena()), "a reach fight refuses the arena")
	failed += _assert(not bool(BattleViewScript.is_open()), "a refused arena adds no overlay")
	game_state.call("reset_for_new_game")
	await process_frame
	paused = false
	failed += _assert(not bool(reach.call("fight_active")), "reset leaves the reach fight")
	var panel_src: String = FileAccess.get_file_as_string("res://tools/debug/debug_panel.gd")
	var echo_at: int = panel_src.find("\"Jump to Echo\"")
	var arena_at: int = panel_src.find("\"Battle arena (test)\"")
	failed += _assert(echo_at >= 0 and arena_at > echo_at, "the test button sits with Jump to Echo")
	var panel_packed: PackedScene = load("res://tools/debug/debug_panel.tscn") as PackedScene
	failed += _assert(panel_packed != null, "debug panel scene loads")
	if panel_packed == null:
		live.free()
		game_state.call("reset_for_new_game")
		paused = false
		return failed
	var panel: Node = panel_packed.instantiate()
	tree_root.add_child(panel)
	await process_frame
	var arena_button: Button = null
	for node: Node in panel.find_children("*", "Button", true, false):
		var button: Button = node as Button
		if button != null and button.text == "Battle arena (test)":
			arena_button = button
			break
	failed += _assert(arena_button != null, "debug panel has Battle arena (test)")
	if arena_button != null:
		arena_button.pressed.emit()
	failed += _assert(bool(BattleViewScript.is_open()), "the test button opens the arena")
	await process_frame
	BattleViewScript.close_arena()
	await process_frame
	var leftover: Node = tree_root.get_node_or_null("DebugToolsPanel")
	if leftover != null and is_instance_valid(leftover):
		leftover.free()
	var echo_left: Node = tree_root.get_node_or_null("EchoBattle")
	if echo_left != null:
		echo_left.free()
	if bool(echo.get("in_battle")):
		echo.call("dismiss_battle_without_reward")
	live.free()
	await process_frame
	game_state.call("reset_for_new_game")
	paused = false
	if failed == 0:
		print("BATTLE_ECHO_EXCLUSIVE_OK")
	return failed


func _echo_battle_count(tree_root: Window) -> int:
	var count: int = 0
	for child: Node in tree_root.get_children():
		if str(child.name).begins_with("EchoBattle"):
			count += 1
	return count


func _battle_walk_point(live: Node, origin: Vector2) -> Vector2:
	## A clearing point on screen, off the Keeper, and off any clickable node.
	var camera: Node2D = live.get_node_or_null("Camera2D") as Node2D
	var center: Vector2 = camera.global_position if camera != null else origin
	var offsets: Array[Vector2] = [
		Vector2(280, 160),
		Vector2(-260, 140),
		Vector2(220, -180),
		Vector2(-200, 200),
		Vector2(0, 220),
	]
	for off: Vector2 in offsets:
		var point: Vector2 = center + off
		if point.distance_to(origin) < 80.0:
			continue
		if not bool(live.call("_in_clearing", point)):
			continue
		if bool(live.call("_interactable_under_point", point)):
			continue
		var screen: Vector2 = live.get_viewport().get_canvas_transform() * point
		if screen.x < 160.0 or screen.x > 1120.0 or screen.y < 120.0 or screen.y > 600.0:
			continue
		return point
	return center + Vector2(280, 160)


func _battle_click(live: Node, world_pos: Vector2, button: int) -> void:
	## The hub's real click path: a viewport mouse event, not a direct move_to.
	var vp: Viewport = live.get_viewport()
	var screen: Vector2 = vp.get_canvas_transform() * world_pos
	vp.warp_mouse(screen)
	var motion := InputEventMouseMotion.new()
	motion.position = screen
	motion.global_position = screen
	vp.push_input(motion)
	var down := InputEventMouseButton.new()
	down.button_index = button
	down.pressed = true
	down.position = screen
	down.global_position = screen
	vp.push_input(down)
	if button != MOUSE_BUTTON_LEFT:
		return
	var up := InputEventMouseButton.new()
	up.button_index = button
	up.pressed = false
	up.position = screen
	up.global_position = screen
	vp.push_input(up)


func _battle_escape(live: Node) -> void:
	var key := InputEventKey.new()
	key.keycode = KEY_ESCAPE
	key.pressed = true
	live.get_viewport().push_input(key)


func _battle_strike_event(packet: Dictionary) -> Dictionary:
	for ev: Variant in packet.get("events", []):
		if ev is Dictionary and str((ev as Dictionary).get("kind", "")) == "strike":
			return ev as Dictionary
	return {}


func _battle_wait_fight_actor(fight: FightState, actor_id: String, max_steps: int) -> bool:
	for _i: int in max_steps:
		if fight.outcome() != "":
			return false
		if fight.current_actor() == actor_id:
			return true
		fight.step()
	return false


func _battle_playback(tree_root: Window, game_state: Node, save_service: Node) -> int:
	var failed: int = 0
	paused = false
	game_state.call("reset_for_new_game")
	save_service.set("boot_intent", "new")
	var live: Node = await _echo2_boot_hub(tree_root)
	if live == null:
		return failed + 1
	BattleViewScript.open_arena()
	await process_frame
	var view: BattleView = get_nodes_in_group("battle_overlay")[0] as BattleView
	var playback: BattlePlayback = view.get_playback()
	playback.instant = false
	view.call("start_test_fight", 1, false, true, 88001)
	await process_frame
	var fight: FightState = view._fight
	var actor: String = fight.current_actor()
	var targets: Array = fight.legal_targets(actor)
	var packet: Dictionary = fight.step({"kind": "strike", "target": str(targets[0])})
	var strike_ev: Dictionary = _battle_strike_event(packet)
	failed += _assert(not strike_ev.is_empty(), "strike event")
	var menu: VBoxContainer = view.get_node_or_null("Arena/ActionMenu") as VBoxContainer
	menu.visible = false
	playback.enqueue_events([strike_ev])
	failed += _assert(playback.is_busy(), "one event playing")
	for row: Dictionary in [{"speed": 1, "pre": 1.99, "post": 0.2}, {"speed": 2, "pre": 0.99, "post": 0.2}, {"speed": 4, "pre": 0.49, "post": 0.1}]:
		playback.speed = int(row["speed"])
		view.call("_apply_battle_speed", int(row["speed"]))
		playback.reset_for_fight()
		playback.bind_view(view, fight)
		playback.enqueue_events([strike_ev])
		playback.advance(float(row["pre"]))
		failed += _assert(playback.is_busy(), "%dx gap timing" % int(row["speed"]))
		playback.advance(float(row["post"]))
		failed += _assert(not playback.is_busy(), "%dx gap ends" % int(row["speed"]))
	view.call("_apply_battle_speed", 4)
	if view._strike_for_me_toggle != null:
		view._strike_for_me_toggle.button_pressed = true
	view.call("_refresh_speed_buttons")
	var speed2: Button = view.get_node_or_null("Arena/SpeedBar/Speed2x") as Button
	failed += _assert(bool(view.call("strike_for_me_on")) and int(playback.speed) == 1 and speed2.disabled, "strike for me locks 1x")
	playback.reset_for_fight()
	playback.enqueue_events([strike_ev])
	playback.advance(0.45)
	var floats: int = 0
	for child: Node in view.get_node_or_null("Arena").get_children():
		if child is Label and child.has_meta("battle_float"):
			floats += 1
	failed += _assert(floats > 0, "floating number")
	playback.advance(1.0)
	await process_frame
	await process_frame
	var ko_ev: Dictionary = {"kind": "calmed", "target": "x"}
	playback.reset_for_fight()
	var t0: float = playback.clock_sec
	playback.enqueue_events([ko_ev])
	while playback.is_busy():
		playback.advance(0.05)
	failed += _assert(playback.clock_sec - t0 >= 0.75, "status pause")
	BattleViewScript.close_arena()
	live.free()
	game_state.call("reset_for_new_game")
	paused = false
	if failed == 0:
		print("BATTLE_PLAYBACK_OK")
	return failed


func _battle_art(tree_root: Window, game_state: Node, save_service: Node) -> int:
	var failed: int = 0
	for beast_id: String in BattleViewScript.BEAST_HURT.keys():
		var tex: Texture2D = load(str(BattleViewScript.BEAST_HURT[beast_id])) as Texture2D
		failed += _assert(tex != null and tex.get_size() == Vector2(128, 128), "hurt %s" % beast_id)
	for member: String in ["keeper", "elaia"]:
		for pose: String in ["attack", "brace", "hurt", "ko"]:
			var path: String = str((BattleViewScript.PARTY_POSES.get(member, {}) as Dictionary).get(pose, ""))
			if path == "":
				continue
			var ptex: Texture2D = load(path) as Texture2D
			failed += _assert(ptex != null and ptex.get_size() == Vector2(128, 128), "%s %s" % [member, pose])
	game_state.call("reset_for_new_game")
	save_service.set("boot_intent", "new")
	var live: Node = await _echo2_boot_hub(tree_root)
	BattleViewScript.open_arena()
	var view: BattleView = get_nodes_in_group("battle_overlay")[0] as BattleView
	var playback: BattlePlayback = view.get_playback()
	playback.instant = false
	var stats: Dictionary = {"might": 11, "arcana": 5, "resilience": 6, "ward": 5, "vitality": 6, "swiftness": 7, "fate": 7, "attack": "physical"}
	var fight: FightState = FightStateScript.new()
	fight.add_member("keeper", stats, 0, "front", "keeper")
	fight.add_beast("moss_brute", 0, "front")
	fight.start_fight()
	view.call("show_fight", fight)
	view._fight = fight
	playback.bind_view(view, fight)
	var strike_ev: Dictionary = {"kind": "strike", "actor": "keeper", "target": "moss_brute", "band": "hit", "damage": 1, "target_side": "beast"}
	playback.enqueue_events([strike_ev])
	playback.advance(0.5)
	var sprite: TextureRect = view.get_node_or_null("Arena/Fighters/Fighter_moss_brute/Sprite") as TextureRect
	failed += _assert(sprite != null and str(sprite.texture.resource_path).ends_with("battle_moss_brute_hurt.png"), "beast hurt")
	playback.advance(0.35)
	failed += _assert(str(sprite.texture.resource_path).ends_with("battle_moss_brute_idle.png"), "beast idle")
	var dark_species: String = "acorn_imp_dark"
	var dark_base: String = dark_species.substr(0, dark_species.length() - 5) if dark_species.ends_with("_dark") else dark_species
	failed += _assert(dark_base == "acorn_imp", "dark variant base species")
	failed += _assert(str(BattleViewScript.BEAST_HURT.get(dark_base, "")).ends_with("battle_acorn_imp_hurt.png"), "dark uses base hurt art")
	strike_ev = {"kind": "strike", "actor": "moss_brute", "target": "keeper", "band": "hit", "damage": 1, "target_side": "party"}
	playback.reset_for_fight()
	playback.enqueue_events([strike_ev])
	playback.advance(0.5)
	var keeper_sprite: TextureRect = view.get_node_or_null("Arena/Fighters/Fighter_keeper/Sprite") as TextureRect
	failed += _assert(keeper_sprite != null and str(keeper_sprite.texture.resource_path).ends_with("battle_keeper_hurt.png"), "party hurt")
	playback.advance(0.35)
	failed += _assert(str(keeper_sprite.texture.resource_path).ends_with("battle_keeper_idle_e.png") or str(keeper_sprite.texture.resource_path).ends_with("battle_keeper_idle.png"), "party idle")
	view.call("set_fighter_pose", "keeper", "ko")
	failed += _assert(str(keeper_sprite.texture.resource_path).ends_with("battle_keeper_ko.png"), "ko pose")
	BattleViewScript.close_arena()
	live.free()
	if failed == 0:
		print("BATTLE_ART_OK")
	return failed


func _battle_audio_sole_caller(tree_root: Window, game_audio: Node) -> int:
	var failed: int = 0
	failed += _scan_battle_sfx_refs("res://scripts")
	failed += _scan_battle_sfx_refs("res://tools")
	var strike: Dictionary = {"kind": "strike", "band": "graze", "fate_crit": true, "damage": 2, "target_side": "beast"}
	var cues: Array[Dictionary] = BattlePlaybackScript.cues_for_event(strike, 1)
	var ids: Array[String] = []
	for c: Dictionary in cues:
		ids.append(str(c.get("id", "")))
	failed += _assert(ids.has("sfx_battle_graze") and ids.has("sfx_battle_crit"), "impact+crit")
	var fast_crit: bool = false
	for c2: Dictionary in BattlePlaybackScript.cues_for_event(strike, 2):
		if str(c2.get("id", "")) == "sfx_battle_crit":
			fast_crit = true
	failed += _assert(not fast_crit, "no crit at 2x")
	failed += _assert(BattlePlaybackScript.cues_for_event({"kind": "poison_tick"}, 1).is_empty(), "poison silent")
	for c: Dictionary in cues:
		failed += _assert(game_audio.list_cue_ids().has(str(c.get("id", ""))), "cue id")
	var pb: BattlePlayback = BattlePlaybackScript.new()
	pb._load_rules()
	pb._throttle_last["sfx_battle_turn"] = 0.0
	failed += _assert(not pb.throttle_allows("sfx_battle_turn"), "turn throttle")
	pb.clock_sec = 0.31
	failed += _assert(pb.throttle_allows("sfx_battle_turn"), "turn gap")
	if failed == 0:
		print("BATTLE_AUDIO_SOLE_CALLER_OK")
	return failed


func _scan_battle_sfx_refs(dir_path: String) -> int:
	var failed: int = 0
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return 0
	dir.list_dir_begin()
	while true:
		var name: String = dir.get_next()
		if name == "":
			break
		if name.begins_with("."):
			continue
		var full: String = "%s/%s" % [dir_path, name]
		if dir.current_is_dir():
			failed += _scan_battle_sfx_refs(full)
		elif name.ends_with(".gd") and full != "res://scripts/verify_headless.gd":
			var text: String = FileAccess.get_file_as_string(full)
			if text.find("sfx_battle_") >= 0:
				failed += _assert(full == "res://scripts/battle/battle_playback.gd", "sole caller %s" % full)
	dir.list_dir_end()
	return failed


func _headless_silent(tree_root: Window, game_state: Node, save_service: Node, game_audio: Node) -> int:
	var failed: int = 0
	game_audio.clear_played_log()
	game_state.call("reset_for_new_game")
	save_service.set("boot_intent", "new")
	var live: Node = await _echo2_boot_hub(tree_root)
	BattleViewScript.open_arena()
	var view: BattleView = get_nodes_in_group("battle_overlay")[0] as BattleView
	view.call("start_test_fight", 1, false, true, 88003)
	for _i: int in 600:
		if view._fight == null or view._fight.outcome() != "":
			break
		view.call("_advance")
		await process_frame
	var prefix: String = "sfx_battle_"
	for suffix: String in ["hit", "graze", "crush", "crit", "miss", "brace", "salve", "flee", "beast_hurt", "ko", "overwhelmed", "victory", "turn", "select", "confirm"]:
		failed += _assert(not game_audio.did_play(prefix + suffix), "silent %s" % suffix)
	BattleViewScript.close_arena()
	live.free()
	if failed == 0:
		print("HEADLESS_SILENT_OK")
	return failed
