# Project map: Tales of the Manaforge

This is a fast index for coding agents. It says where things live and which functions to read first. The details live in the existing docs:
[DEVELOPER_NOTES.md](DEVELOPER_NOTES.md) covers run, VERIFY tokens and exports. [SYSTEMS_V01.md](SYSTEMS_V01.md) is the design ledger. [forge_v2.md](forge_v2.md) covers the Forge, [idle_rework.md](idle_rework.md) the idle loop, [CONTENT_STRINGS_V01.md](CONTENT_STRINGS_V01.md) the strings, [AUDIO_RESTART_V01.md](AUDIO_RESTART_V01.md) and [CUE_NOTES_ECHO_V1.md](CUE_NOTES_ECHO_V1.md) the audio, and [ASSETS_UPLOAD.md](ASSETS_UPLOAD.md) the art inbox.

## At a glance

- **What:** a cozy idle/RTS game. Tend the Manatree in a forest clearing, gather, craft in the Forge, fight Echoes, Ascend, and send expeditions up the north road.
- **Engine:** Godot **4.7.2**, typed GDScript (`project.godot` features `4.7`). The main scene is `res://scenes/title_screen.tscn` and the hub is `res://scenes/main.tscn`.
- **Two builds from one tip** (`export_presets.cfg`, both with `embed_pck=false`):
  - `Windows Testing / Experimental` (feature `manaforge_debug`) keeps the debug panel, the snapshots and AnimPreview.
  - `Windows Release / Stable` (feature `manaforge_stable`) excludes `tools/*`. It also excludes the debug panel, every snapshot JSON and AnimPreview by name.
  - Feature gates are in `scripts/autoload/anim_preview_hotkey.gd` (`debug_tools_enabled`) and `Reach.debug_tools()`.
- **Autoloads** (in `project.godot` order): ContentStrings, GameAudio, GameState, Backpack, KeeperStats, Equipment, SaveService, EchoChamber, ForgeJobs, Reach, AnimPreviewHotkey. Each one is in `scripts/autoload/<snake_name>.gd`.

## Systems

| System | Key files | Key functions / signals |
| --- | --- | --- |
| Core state | `scripts/autoload/game_state.gd` (~1.9k lines) | Signals: `resources_changed`, `stage_changed`, `needs_changed`, `fruit_ready_changed`, `upgrades_changed`, `status_message(text)` (all toasts), `load_completed`, `wisps_changed`, `selection_changed`, `echo_flags_changed`, `ancient_expired`, `keeper_harvested`. Functions: `add_resource`, `set_resource`, `try_grow_stage`, `apply_water_pulse`, `to_save_dict`, `apply_save_dict`, `reset_for_new_game`, `is_world_frozen`, `select_keeper` |
| Hub / clearing | `scenes/main.tscn`, `scripts/main.gd`, `data/hub_map.json`, `scripts/trampled_paths.gd`, `scripts/forest_prop.gd`, `scenes/hub/forest_*.tscn` | `main.gd`: `_enter_tree` then `_apply_boot_intent` (new / continue / load / forge_return / auto), `_spawn_runestones`, `_spawn_echo_portal`, `world_input_blocked`, `handle_rmb_ground`, `_interactable_under_point` (pick mask 4), `focus_manatree`. Nodes live under `World/` (Manatree, Keeper, Elaia, KeepersBench, EchoPortal, ThornWall, ExpeditionBoard, BrambleWarden). `HUD` and `PauseMenu` sit at the root |
| Manatree / gathering / wisps | `scripts/manatree.gd`, `scripts/gatherable.gd`, `scripts/wisp.gd`, `scripts/runestone.gd`, `data/manatree_stages.json`, `data/keeper_work_spots.json` | `Manatree.do_water`, `do_pay_stage`, signals `care_menu_requested` / `fruit_menu_requested`. `Gatherable.on_harvest_pulse`. `GameState.try_assign_wisp`, `apply_wisp_pulses`. `Runestone.begin_spend` / `confirm_spend` (stat ranks) |
| Interaction pattern | `echo_portal.gd`, `thorn_wall.gd`, `expedition_board.gd`, `runestone.gd`, `bramble_warden.gd` | RMB → `apply_player_command()` → `Keeper.move_to(global_position + ENTRY_OFFSET, self)` → on arrival `Keeper._try_interact` → `on_interact()` → `begin_entry()`. The stand point must be within `ARRIVE_DIST` (12) of where the keeper's feet box actually stops. Walk boxes come from `scripts/feet_box.gd` (`FeetBox.apply`, `apply_size`) |
| Forge (room + travel) | `scenes/forge_room.tscn`, `scripts/forge_room.gd`, `scenes/forge/{crucible,mill,press,anvil,reliquary}.tscn`, `scripts/forge_station.gd`, `data/forge_tuning.json`, `data/forge_copy.json` | `ForgeJobs.can_enter_forge`, `try_enter_forge`, `request_door_walk`, `travel_to_forge`, `exit_forge`, `switch_view`, `set_scene_changes_enabled`. `ForgeRoom.open_station_panel`, `walk_keeper_to_station` |
| Crafting / batch / workbench | `scripts/autoload/forge_jobs.gd` (~2k lines), `scripts/batch_job.gd`, `scripts/batch_panel.gd` + `scenes/ui/batch_panel.tscn`, `scripts/batch_world_bars.gd`, `scripts/keepers_bench.gd`, `scripts/forge_recipe_button.gd`, `data/handcraft_recipes.json` | `ForgeJobs.try_begin_job(station, recipe)`, `try_begin_batch`, `cancel_batch`, `affordable_count`, `advance_seconds`, `set_keeper_working`, `job_state`, `station_speed_mult`, `capture_save_fields` / `apply_save_fields`, `migrate_saved_jobs`. `BatchJob.refund_map`. `KeepersBench.try_open`. Handcraft: `Backpack.try_craft`, `Equipment.try_craft`. Station ids: `crucible mill press anvil reliquary` |
| Items / gear / stats | `scripts/autoload/backpack.gd` (`inventory_changed`), `equipment.gd` (`equipment_changed`), `keeper_stats.gd` (`ranks_changed`), `scripts/character_sheet.gd`, `data/equipment.json`, `data/keeper_stats.json` | `Backpack.add_item`, `get_count`, `set_count`, `try_spend`. `Equipment.grant_item`, `owns_anywhere`, `try_equip`, `total_for(stat)`, `ensure_forge_key_equipped`. `KeeperStats.try_buy`, `get_rank` |
| Echo chamber / portals / battles | `scripts/autoload/echo_chamber.gd`, `scripts/echo_portal.gd` + `scenes/echo_portal.tscn`, `scripts/thorn_wall.gd`, `scripts/echo_battle.gd` (rules), `scripts/echo_battle_view.gd` + `scenes/echo_battle.tscn`, `data/echo_keeper_01.json` (Elaia), `data/echo_bramble_02.json` (Bramble) | `EchoChamber.hub_portal_context()` returns `"echo1"` (Elaia), `"echo2"` (first Anvil weapon, Bramble unresolved) or `""`. Also `portal_visible`, `bramble_gate_open`, `owns_anvil_weapon`, `try_pay_fee` (30), `try_pay_bramble` (50), `open_battle`, `open_bramble`, `apply_outcome`, `finish_battle`, `dismiss_battle_without_reward`. `EchoPortal.refresh_visibility` (sprite, click and walk box together), `begin_entry`, `confirm_fee`. `ThornWall.begin_entry` / `path_is_open` |
| Companions | `scripts/keeper.gd` (`class_name Keeper`, signals `arrived`, `interaction_finished`, `channel_changed`), `scripts/elaia.gd` (Elaia's node instances `keeper.tscn` with this script), `scripts/bramble_warden.gd`, `data/companions.json` | `Keeper.move_to`, `command_work`, `command_station`. Elaia joins after Echo 1 is redeemed and the first relic is crafted: `GameState.elaia_in_party`, `elaia_join_pending`, `note_first_relic_crafted`. Bramble is only a trailhead warden after a spare (`refresh_presence`). Joining at 20 reach clears is not built yet. **Puff is not on this branch** (no code or data). Puff art and content sit on other PR branches |
| Adventure / reach | `scripts/autoload/reach.gd` (signal `changed`), `scripts/expedition_board.gd` + `scenes/expedition_board.tscn`, `scripts/reach_fight.gd` (manual rules), `scripts/reach_fight_view.gd` | Board: `begin_entry` (shut road → `path_east_tease`), `open_shell`, `try_depart`, `depart_disabled`, `set_lantern`. Reach: `depart`, `advance_clock`, `idle_bonus` / `idle_clears` / `clear_chance` (d20 + bonus vs `DC` 6), `_roll_idle` (Heart Salve reroll), `_grant_room` (Briarwood, herbs, dojo exp; boss ×2), `is_boss_room` / `rooms_until_boss` (every 10th room attempted per run), `set_control` (idle/manual), `fight_choose`, `push_would_stop` (<75%), `max_start_depth`, `on_ascend`. Constants: `ROOM_SEC` 720, `REST_SEC` 1440. Lifetime counter: `reaches_cleared` |
| Save / load / migration | `scripts/autoload/save_service.gd` | `SAVE_VERSION` **13** (`SAVE_VERSION_MAX_READ` equals it: a newer save is refused with `save_newer_build` in `last_load_error`, Continue skips it, and autosave rotation never overwrites it). Slots are `user://manaforge_save_slot_{1..7}.json` plus three rotating `user://manaforge_autosave_%d.json`. Functions: `save_game(slot)` (slot ≤ 0 means autosave), `save_autosave`, `load_game`, `load_autosave`, `_load_path` → `_migrate(version, state)` (`_migrate_v10` … `_migrate_v13`, `_migrate_gear_v7`) → `GameState.apply_save_dict`. `migrate_state(version, state)` is the public migration (empty for a newer save). Signals `save_completed`, `load_completed(ok)`. Saving is blocked during a battle |
| Offline catch-up | `save_service.gd` `_apply_offline_catchup`, `game_state.gd`, `forge_jobs.gd`, `reach.gd` | Uses the raw closed gap from the save `timestamp`. `GameState.offline_effective_seconds`, `commit_offline_gap`, `idle_catch_up_seconds`, `ForgeJobs.apply_saved_offline_gap` / `apply_offline_seconds`, `Reach.apply_offline_seconds`. Always 1×, never play speed |
| Ascension / shop / blessings | `game_state.gd`, `scripts/hud.gd` (shop UI), `data/fruit_upgrades.json` (blessings, e.g. `keep_tools` at 4000) | `GameState.harvest_fruit`, `can_ascend`, `ascend`, `buy_upgrade`, `get_upgrade_rank`, `can_afford_any_ascension`. `ForgeJobs.prepare_ascend` / `finish_ascend`, plus `on_ascend` on Backpack, Equipment, KeeperStats and Reach. `Backpack.grant_kept_tools`. HUD: `show_prestige_menu`, `is_ascension_shop_open` |
| Play speed | `game_state.gd`, `hud.gd` | Player button steps are 1/2/4/8, ships in Stable, not saved, reset on launch: `reset_play_speed`, `set_play_speed`, `cycle_play_speed`, `active_play_delta`, `advance_open_play`, `play_speed_in_stable`. HUD `_ensure_play_speed_button` (`PlaySpeedButton`). The debug 1–16× speed-up is a separate HUD option. `ForgeJobs.dev_time_scale` / `set_dev_speed_override` exist for dev runs |
| UI / HUD | `scripts/hud.gd` (`class_name GameHUD`, ~3k lines) + `scenes/hud.tscn`, `scripts/hud_icons.gd`, `scripts/pause_menu.gd` + `scenes/pause_menu.tscn`, `scripts/title_screen.gd`, `scripts/character_sheet.gd` | HUD: `show_care_menu`, `hide_welcome`, `open_forge_entry`, `show_prestige_menu`, `party_click`. Pause: `open_pause`, `resume_game`, signals `new_game_started`, `game_loaded`, `standalone_load_requested` |
| Audio | `scripts/autoload/game_audio.gd`, `data/audio_cues.json`, `assets/audio/` (+ `MANIFEST.json`) | `GameAudio.play(cue_id)` and helpers (`play_ui_confirm`, `play_ui_deny`, …), `suspend_hub_for_battle` / `resume_hub_after_battle`, `did_play` / `clear_played_log` (tests), signals `cue_played`, `cue_missing`, `volumes_changed`. Settings live in `user://manaforge_settings.cfg` |
| Strings / content | `scripts/autoload/content_strings.gd`, `data/strings_v01.json` | `ContentStrings.get_text(key, {token: value})` (a missing key returns the key itself). Adventure copy comes from cast_adventure DRAFT v3 (`path_east_*`, `expedition_*`, `lantern_*`, `echo_02_*`, `bramble_*`). That draft is not FINAL. Battle copy from BATTLE_SCENE_DRAFT v4 is `adv_*` (DRAFT, nothing shows it yet), and beast names are `beast_*_name` |
| Debug panel + snapshots | `tools/debug/debug_panel.gd` + `.tscn`, `tools/debug/snapshots/*.json`, `scripts/autoload/anim_preview_hotkey.gd`, `tools/AnimPreview.tscn` | Ctrl+F8 or the pause-menu Options `DebugToolsToggle` (`AnimPreviewHotkey.set_debug_panel`; Experimental only). `SNAPSHOTS` / `SNAPSHOT_ORDER`: Pre-Echo, Forge unlocked, Elaia joined, Ancient ready (save_version 10), then Echo 2 ready, North road open, Pre-boss, Veteran reacher (save_version 13, with a `reach` block). Loading goes through `load_snapshot_state` → `SaveService.migrate_state` (newer versions refused) → `GameState.apply_save_dict`, then swaps to the hub. A new snapshot must also go into the Stable `exclude_filter` and `_stripped_paths()` in `verify_headless.gd` |

## Where data lives

- **Gameplay JSON:** `data/`. The table below lists each file's only readers. Edit the JSON, not hard-coded constants, where a key exists.

| File | Read by |
| --- | --- |
| `strings_v01.json` | ContentStrings |
| `hub_map.json` (marks, paths, runestones) | `main.gd`, `tools/scene_sanity.gd` |
| `forge_tuning.json`, `forge_copy.json` | ForgeJobs (tuning is also read by GameState and the debug panel) |
| `handcraft_recipes.json` | Backpack |
| `equipment.json` | Equipment |
| `fruit_upgrades.json`, `manatree_stages.json`, `companions.json` | GameState |
| `keeper_stats.json` | KeeperStats |
| `keeper_work_spots.json` | `keeper.gd` |
| `echo_keeper_01.json`, `echo_bramble_02.json` | EchoChamber |
| `audio_cues.json` | GameAudio |
| `beasts.json` (BATTLE_SCENE_DRAFT v4 §10: species, threat rule, variant rule) | nothing in the game yet; VERIFY `BEAST_DATA_OK` |
| `spawn_tables.json` (§10 room budget, per-depth weights, loot rules; bonus-drop contents and herbs by depth left empty until approved) | nothing in the game yet; VERIFY `SPAWN_DATA_OK` |

- **Art:** `assets/art/` (subfolders `bramble echo elaia forge fx hub keeper manatree nodes portraits props tiles title trees ui wisps`; manifest in `assets/art/MANIFEST.json`). Hub props are in `assets/art/props/` (e.g. `thorn/`, `expedition_board/`, `echo_portal_hub_v2.png`). Kept-but-unused sheets go in `assets/library/` and refs in `assets/refs/`. Both are `.gdignore`d, as is `docs/`.
- **Audio:** `assets/audio/*.ogg|mp3`. Cue ids map to files in `data/audio_cues.json`.
- **`Assets upload/` is a drop folder only.** Haex drops art here. Sort it into the folders above. Every ship must leave it holding only `README.md` and `.gdignore`. See `Assets upload/README.md` and [ASSETS_UPLOAD.md](ASSETS_UPLOAD.md).
- **Saves and settings:** `user://` (see Save above).

## Running checks

Use the **4.7.2** binary. On this box that is `/home/box/tools/godot/Godot_v4.7.2-stable_linux.x86_64`. `/home/box/bin/godot` is 4.3: it rewrites hundreds of `.import` files, so don't use it. In the commands below, `G` is the 4.7.2 binary.

```bash
G=/home/box/tools/godot/Godot_v4.7.2-stable_linux.x86_64
$G --headless --path . --import                                          # import / compile; grep the log for "SCRIPT ERROR"
MANAFORGE_CHECK_ONLY=1 $G --headless --path . -s res://scripts/verify_headless.gd  # CHECK_ONLY_OK (loads the main scripts)
$G --headless --path . -s res://tools/scene_sanity.gd                    # SANITY: SANITY_OK, FOREST_SEAL, WORK_REACH, SCENE_EXITS
$G --headless --path . -s res://scripts/verify_headless.gd               # full VERIFY: VERIFY_OK (only after 22:30 Zurich)
MANAFORGE_ECHO2_PORTAL=1 $G --headless --path . -s res://scripts/verify_headless.gd  # one test (see the list below)
```

- **After any import, revert the uid churn:** `git checkout -- assets/art/echo/battle_moss_brute_idle.png.import assets/art/echo/battle_root_snapper_idle.png.import assets/art/echo/battle_wilt_wisp_idle.png.import`. Godot 4.7.2 rewrites their invalid uids on every import. Don't commit that.
- **Single-test env vars** (each runs only its own block in `verify_headless.gd`):
  - `MANAFORGE_WORKBENCH`, `MANAFORGE_SCENE_TRANSITIONS`, `MANAFORGE_DURATION_ONLY`, `MANAFORGE_SPEED_BUTTON`, `MANAFORGE_ECHO2_PORTAL`, `MANAFORGE_BOARD_TEASE`, `MANAFORGE_DEBUG_SNAPSHOTS`, `MANAFORGE_REACH`
  - `MANAFORGE_ELAIA_ONLY`, `MANAFORGE_PORTRAIT_SWITCH`, `MANAFORGE_FORGE_ARCH`, `MANAFORGE_FORGE_ENTRY`, `MANAFORGE_FORGE_YSORT`, `MANAFORGE_MANATREE_DOOR`, `MANAFORGE_COMPANION_DOOR`, `MANAFORGE_DOOR_ACTIVE`
  - `MANAFORGE_WORKBENCH_CLICK`, `MANAFORGE_WORKBENCH_PAUSE`, `MANAFORGE_WORKBENCH_WISP`, `MANAFORGE_FORGED_ITEM`, `MANAFORGE_WORKBENCH_ROUTE`, `MANAFORGE_CRAFT_DURATION`
  - `MANAFORGE_BATCH_REFUND`, `MANAFORGE_BATCH_OFFLINE`, `MANAFORGE_BATCH_ASCEND`, `MANAFORGE_BATCH_MIGRATION`
  - Grep `OS.get_environment("MANAFORGE_` for the current list. Which token each one prints is in DEVELOPER_NOTES.
- **Debug-strip check (dual build):** `DEBUG_STRIPPED_OK` always checks the preset excludes. Running with `MANAFORGE_DEBUG_STRIP=1` also reads both pack file tables and fails if they are missing. Build the packs without templates or a zip (`builds/` is gitignored), then delete them afterwards:

```bash
$G --headless --path . --export-pack "Windows Release / Stable" builds/stable/TalesOfTheManaforge.pck
$G --headless --path . --export-pack "Windows Testing / Experimental" builds/experimental/TalesOfTheManaforge.pck
MANAFORGE_DEBUG_STRIP=1 $G --headless --path . -s res://scripts/verify_headless.gd   # DEBUG_STRIPPED_PCK / DEBUG_KEPT_PCK / DEBUG_STRIPPED_OK
```

- **Screenshots** need a real renderer: `xvfb-run -a $G --display-driver x11 --rendering-driver opengl3 --path . -s res://scripts/capture_*.gd` (see `scripts/capture_echo.gd`). Headless mode cannot read back the viewport.
- **Test scaffolding in `verify_headless.gd`:** `_assert(cond, msg)` prints `ASSERT FAIL: …`. A live hub is `load("res://scenes/main.tscn").instantiate()` added to root, then two `process_frame` awaits. Set `SaveService.boot_intent = "new"` first. An `"auto"` child hub reloads the newest disk save.

## Conventions

- Tests print `*_OK` markers on success (and `*_FAIL: n` from the single-test gates). Every token and what it guards is listed in DEVELOPER_NOTES → "Permanent named tests". Add a row there with each new test.
- **Regression rule:** every bug Haex reports gets a permanent named test in the **default VERIFY** list (`_run()` in `verify_headless.gd`). It should drive the real user path and fail on the old build. A `MANAFORGE_*` gate to run it alone is the usual extra.
- **No full VERIFY before 22:30 Zurich.** During the day run compile + SANITY + the single tests you touched.
- Ship rules: work on PR branches, don't touch `main` unless told to, no release zips unless asked, `Assets upload/` stays empty. Cast strings marked DRAFT need Haex's FINAL before they count as final.
