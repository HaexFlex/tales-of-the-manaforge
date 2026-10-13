# Tales of the Manaforge — Restart Edition

Cozy top-down pixel adventure inspired by *Secret of Mana*. You are the **Keeper**, tending a living **Manatree** in the last fragment of a fairy-forest.

**Canon:** `VISION_RESTART` + briefs (`SYSTEMS_V01` **v0.6.1 LIVE**, `CONTENT_STRINGS_V01` **v0.6.2**, `VISUAL_BIBLE_RESTART_V01`, `ECHO_CHAMBER_COLORRECT_V01`). **Grow** = Fertilizer + Essence (needs-only Pay superseded). Pause menu + **7 save slots**. Art harvest nodes **v0.1.4**. Audio channels **v0.1.2**. Echo Chamber v1 LIVE. Old forge/combat drafts are non-canon.

## Stack

- **Godot 4.7.2** · GDScript only · **fully typed**
- Playable forest hub: **3200×2800** play area, irregular oval clearing (~32% more walkable ground than the old rectangle), **64² grass TileMap**, dense Y-sorted forest ring with grass/fern scatter (no collision), **exactly 3** harvest channels, animated Manatree; view **1280×720** nearest-neighbor; **arrow keys** pan the camera (clamped to play bounds). Boot opens the **title screen** (Continue / New Game / Load / Options / Quit). Pause **Return to Title** replaces quit; quit lives on the title.
- Autoloads: `ContentStrings`, `GameAudio`, `GameState`, `Backpack`, `KeeperStats`, `Equipment`, `SaveService`
- Pause (**ESC** / HUD **Pause**): Resume, New Game, Save/Load (**7 slots**), Options (audio), **Return to Title**
- Saves `user://manaforge_save_slot_{1..7}.json` (`save_version: **8**`; backpack stacks; keeper stats store Runestone ranks starting at **0**; the sheet base is **5 + rank**; missing ranks load as 0; v6 saves still start gear empty; legacy single-file migrates → slot 1; old `growth` ignored; v8 adds Echo portal / fee / key / companion flag)

## Prototype loop (Haex Grow + backpack)

1. Click ground to move (cancels an active channel if you leave range).
2. Click **Harvest Tree / Stone / Berry** → starts a **harvest channel**. While in range: **+1 wood / stone / food per second** (pulse SFX quiet under hub music).
3. Click **Manatree** → care menu. **Water** starts a **water channel**: each second **+rand(1..3) manashards** and **+1 essence** (income only). **Grow** spends **Fertilizer + Essence** (one click) to advance.
4. Grow costs: Young **3 Fertilizer + 20 Essence** → Mature **6+40** → Elder **12+60** → Ancient **24+80**. Handcraft Fertilizer (10 wood+stone+food) in the **Backpack**.
5. At **ancient**, harvest **Primordial Fruit** → Manashard blessings (including **Keep Tools**) → **Ascend** (backpack wipe; tools return only with Keep Tools).
6. **Character** (HUD button or **C**): paper-doll equipment and seven combat stats (base + gear = total). Slots are weapon, relic, head, body, hands, pants, feet, cape, ring1, ring2. Only **weapon** starts unlocked. Slots are half-transparent squares with no gold border. An empty weapon reads **Weapon**; a locked slot reads **Locked** under the square. Handcraft a **Weapon Rod** (10 Wooden Planks) and a **Flintblade** (`stone_sword`: 30 Stone Fragments + 1 Weapon Rod). Both land in the gear inventory, not the backpack. The rod is consumed into the sword.
7. Seven **Runestones** in the hub spend the same Manashard pool as the Ascension shop. Select the Keeper, right-click a stone, and they walk in range. Confirm, then +1 rank in that stat; the confirm stays open so you can raise again until you click No or walk away. The sheet base is **5 + rank** (a new game shows `5 + 0 = 5`). Cost is `floor(100 × 1.65^rank)` (PLACEHOLDER) — rank 0 still costs 100. Ranks, equipped gear, and the gear inventory persist through Ascend. Unspent Manashards and the backpack still wipe. Keep Tools returns tools only. Fate does not change gather, Wisps, or handcraft.

Essence comes from **watering ticks**. Soft mats feed **handcraft**, not Grow. Gathering tools never gate hands; they 2× Keeper channel speed. Stone Watering Can doubles the Manashard **roll** (`shard_roll ×2`); Essence water is unchanged.

## Run

```bash
godot --path .
```

## Headless verify

```bash
godot --headless --path . -s res://scripts/verify_headless.gd
```

Expect `VERIFY_OK` and exit code `0`.

### Regression rule

Every bug Haex reports that has been fixed before, or that comes back, gets a permanent named test in the default VERIFY suite (named like `SCENE_TRANSITIONS_OK`). The test drives the real user path and must fail on the old buggy build.

**Two Windows zips, one release page.** After VERIFY is green and Haex says merge, ship to `main`, then refresh the **EXPERIMENTAL** zip (debug tools on). Refresh the **Stable** zip (debug tools off) only when Haex says the experimental build feels solid. Both assets live on the same GitHub release page once both exist. Do not replace Stable with an experimental pack.

### Permanent named tests

Tokens below are printed by the run that owns them. Listed only where the code prints them.

**Default VERIFY** (`scripts/verify_headless.gd`):

| Token | What it guards |
| --- | --- |
| `VERIFY_OK` | The whole default suite passed. |
| `SCENE_TRANSITIONS_OK` | Hub and Forge hops (nav, Escape, door, portraits, footsteps, `exit_forge`), solo and with Elaia, stay off the title screen and keep wood and positions. A bare launch still opens the title. The export strip still ships the play scenes. |
| `WORKBENCH_REACH_OK` | Keeper and Elaia can stand just north of the bench, facing south, inside the click area and clear of the legs. |
| `WORKBENCH_NORTH_ROUTE_OK` | Walking to the bench from the north or sides uses flank waypoints instead of a straight line through the legs. `MANAFORGE_WORKBENCH_ROUTE=1` runs it alone. |
| `MANATREE_WATER_RMB_OK` | Right-clicking the Manatree while the selected hero is watering cancels the channel; Water in the care menu resumes it. `MANAFORGE_WATER_RMB=1` runs it alone. |
| `WORKBENCH_WISP_VISIBLE_OK` / `STATION_WISP_ORBIT_OK` / `MANATREE_ELDER_ORBIT_OK` | Wisps orbit stations and the Manatree on ellipses (`rx = ry/2`; Elder Manatree `140×280`). Keeper orbit wisps share phase slots and pass behind the sprite on the north arc. `MANAFORGE_WORKBENCH_WISP=1` runs the hub/forge slice alone. |
| `NO_OLD_KEEPER_IDLE_OK` | Old Keeper idle filenames are not referenced. The same check prints `IDLE_MISSING` (`none`, or the facings that have no idle frames). |
| `JOBS_SURVIVE_SWITCH_OK` | Watering, Elaia's stone harvest, the wood wisp, and station jobs keep paying across a hub/Forge switch, and the work animations are still playing on the way back. |
| `AUTOSAVE_THROTTLE_OK` | An event autosave waits 60 seconds before it writes again. Closing the window still saves inside that window. |
| `ELAIA_JOIN_OK` | Spare without a relic does not bring Elaia in. The first relic craft does. Her portrait waits for the clearing dialogue. An old save that already had her keeps her, and a relic without Spare does not. |
| `ELAIA_JOIN_FLOW_OK` | First relic craft closes the station, then the Forge footsteps popup; Go look moves the Keeper to the Manatree, shows Elaia, plays the join lines, then the HUD portrait (no extra click). Equipping sapstaff and a relic on Elaia's sheet right after join must not error. `MANAFORGE_ELAIA_JOIN_FLOW=1` runs it alone. |
| `ROD_NOT_WEAPON_OK` | Weapon Rod stays in the gear bag as a refined material: not equippable and not listed on the character sheet gear tabs. `MANAFORGE_ROD_NOT_WEAPON=1` runs it alone. |
| `DEBUG_STRIPPED_OK` | The Windows Release / Stable preset strips the debug panel, all nine debug snapshots, and AnimPreview. Eight snapshots are excluded by name; `mid_fight.json` is excluded through `tools/*` and kept by the Testing preset. No shipped script calls `SaveService.write_adventure_raw` outside a `Reach.debug_tools()` guard (the method itself refuses without it). When `builds/stable/TalesOfTheManaforge.pck` and the experimental pack are on disk, the check reads those file tables. `MANAFORGE_DEBUG_STRIP=1` requires both packs. |
| `DEBUG_SNAPSHOTS_REACH_OK` | The five Experimental reach snapshots (Echo 2 ready, North road open, Pre-boss, Veteran reacher, Mid-fight) are listed in the debug panel and load into a valid state through the panel's path. The first four boot the hub with the arch, wall, and Depart matching that state. Pre-boss is room 9 of a run and finishing it opens the boss room. North road open and Veteran reacher are save_version 14 files (Echo 2 ready stays 13). Mid-fight is a manual run at depth 2 whose loader writes the adventure file (round 3, owned by the snapshot's `save_id`). Stable strips them (`DEBUG_STRIPPED_OK`). `MANAFORGE_DEBUG_SNAPSHOTS=1` runs it alone. |
| `PORTRAIT_SWITCH_FORGE_OK` | With Elaia joined, a double-click on the Keeper portrait while she is in the Forge (and the reverse, Elaia's portrait while the Keeper is in the Forge) changes view without freeing the HUD inside the click. `MANAFORGE_PORTRAIT_SWITCH=1` runs it alone. |
| `FORGE_ARCH_DRAW_ORDER_OK` | After a real door transfer, ArchFront (`forge_arch_front_haex.png`, scale **1**, position **800, 1116**) aligns with the bark-chamber arch, covers the Keeper at the Forge spawn, and its draw z stays above the heroes. `MANAFORGE_FORGE_ARCH=1` runs it alone. |
| `FORGE_YSORT_OK` | In the Forge, a hero south of a station draws over it and a hero north of it draws under it. The arch stays above both. Station walk boxes use the opaque sprite width. `MANAFORGE_FORGE_YSORT=1` runs it alone. |
| `MANATREE_DOOR_CLEAR_OK` | At every growth stage, no Manatree walk box sits south of the door sill and the corridor up to the door is open. `MANAFORGE_MANATREE_DOOR=1` runs it alone. |
| `COMPANION_DOOR_TRANSFER_OK` | Keeper and Elaia go clearing → Forge → clearing twice. Both stay visible and can walk after each hop. `MANAFORGE_COMPANION_DOOR=1` runs it alone. |
| `FORGE_ENTRY_ONE_CLICK_OK` | One click on the Manatree door walks to the sill and enters the Forge. The same run checks the watering stand at every growth stage. `MANAFORGE_FORGE_ENTRY=1` runs it alone. |
| `KEEP_TOOLS_COST_OK` | Keep Tools costs 4000 Manashards, and the shop fallback string says 4000. |
| `THORN_PATH_LOCKED_OK` | The north thorn wall blocks the road until Bramble is passed. An early click shows the tease line. |
| `THORN_PATH_OPENS_OK` | Spare and defeat both open the road, play `sfx_path_open`, and drop the centre gate. The side hedges stay. |
| `BRAMBLE_ECHO_FEE_OK` | Bramble's fee is an Anvil weapon plus 50 Essence. Flee keeps the fee. A loss clears it. |
| `ECHO2_PORTAL_VISIBLE_OK` | The hub portal arch closes after Elaia's Echo and leaves no bare walk box. After the first Anvil craft it comes back for Bramble: visible sprite, live click area, and a right-click walks the Keeper in, opens Bramble's 50 Essence confirm, and enters Echo 2. A save already in that state restores the arch, both on load and on a fresh boot. `MANAFORGE_ECHO2_PORTAL=1` runs it alone. |
| `EXPEDITION_BOARD_SHELL_OK` | The trailhead board picks the Keeper and the open road. Depart stays disabled while the road is shut. |
| `EXPEDITION_BOARD_TEASE_OK` | Right-clicking the north board with the Keeper selected walks him to its stand point and, while the road is shut, shows the wall's `path_east_tease` line without opening the shell. Once Bramble is spared the same click opens the shell. `MANAFORGE_BOARD_TEASE=1` runs it alone. |
| `REACH_DEPTH_ASCEND_OK` | Deepest depth, the lifetime reach counter, and the dojo pool survive Ascension. A new game clears them. |
| `IDLE_SLOTS_OK` | One hour departs as 5 idle slots. Five 12-minute advances end the run (unless an Overwhelmed rest ends it early), `room_log` plus two slots per rest accounts for all 5, the Backpack stays put mid-run and then gains exactly `last_summary.banked`, dojo exp is `room_exp` times wins, and the same seed repeats. A forced-win run's loot matches `RoomLoot`. `MANAFORGE_IDLE_SLOTS=1` runs it alone. |
| `IDLE_RESOLVE_AT_END_OK` | 719 seconds leave the room unresolved. The next second resolves it. Three slot-lengths of a 4-room run resolve exactly 3 rooms. `MANAFORGE_IDLE_RESOLVE_AT_END=1` runs it alone. |
| `IDLE_REST_SLOTS_OK` | Idle Overwhelmed clears the pack and rests 2 slots (a rest is not an attempt). Flee halves the pack and continues. Overwhelmed with fewer than 2 slots left ends the run. `MANAFORGE_IDLE_REST_SLOTS=1` runs it alone. |
| `IDLE_BOSS_PAYBACK_OK` | Room 10 of a 10-room run is the boss, pays 15 Essence once (`boss_paid` is `[10]`), never into the pack, and doubles that room's exp. Saving and continuing does not pay again. `MANAFORGE_IDLE_BOSS_PAYBACK=1` runs it alone. |
| `BOARD_V4_OK` | Expedition board (mockup layout): depth/rooms fields with +/- and clamping, room idle duration at 20 rooms, two-slot loadout caps, Essence 20 depart gates, `depart_slots` matches `board_config`, running labels, no Cancel and no percent. `MANAFORGE_BOARD_V4=1` runs it alone. |
| `BOARD_CLOSE_OK` | Expedition shell has a **Close** button (not Cancel); `close_shell` hides the panel so `shell_open()` is false; Esc closes via the pause-menu chain without opening pause; works during a running reach. `MANAFORGE_BOARD_CLOSE=1` runs it alone (default suite). |
| `BOARD_COMPANION_ONLY_OK` | Formation picker: Elaia-only party departs from back mid; empty party is blocked; Elaia is not pickable before join. `MANAFORGE_BOARD_COMPANION_ONLY=1` runs it alone. |
| `PICKER_JOINED_ONLY_OK` | Party picker lists Bramble only after `GameState.bramble_joined()` (no locked preview row); extra members scroll inside the picker popup when rows exceed the layout max height. `MANAFORGE_PICKER_JOINED_ONLY=1` runs it alone. |
| `DEPTH_PASSTHROUGH_OK` | Board depth 3 and **Go deeper** reach `Reach.depth`, depth-3 spawn tables, and the arena **Depth** plate (`DepthText`). `MANAFORGE_DEPTH_PASSTHROUGH=1` runs it alone. |
| `BOARD_FORMATION_OK` | `place_member` cells flow through `board_config` into `BattleView` soles (`SLOT_SOLES`). `MANAFORGE_BOARD_FORMATION=1` runs it alone. |
| `BOARD_SIM_WINDOW_OK` | Simulate opens a scrollable results modal (`SimulateResult` inside); Close dismisses it. `MANAFORGE_BOARD_SIM_WINDOW=1` runs it alone. |
| `BOARD_DEPTH_ROOMS_OK` | Depth and rooms fields clamp and step correctly. `MANAFORGE_BOARD_DEPTH_ROOMS=1` runs it alone. |
| `BOARD_ESSENCE_ICON_OK` | Depart cost chip uses `icon_essence.png` with `GameHUD.ESSENCE_TINT`. `MANAFORGE_BOARD_ESSENCE_ICON=1` runs it alone. |
| `SIMULATE_OK` | `RunSim.simulate` is deterministic (except `ms`), matches a real idle `depart_slots` run per-room outcomes for the same seed, formats lost-room reasons, opens the simulate modal with per-room lines (no percent), uses a sim seed different from `Reach.run_seed` during a run, and a 50-room depth-1 duo finishes within the perf budget (`SIMULATE_MS`). `MANAFORGE_SIMULATE=1` runs it alone. |
| `SIMULATE_NO_SIDE_EFFECTS_OK` | Five `SimulateButton` presses leave `GameState`, `Reach`, the Backpack, Essence, save mtimes, and `Reach.running` unchanged. `MANAFORGE_SIMULATE_NO_SIDE_EFFECTS=1` runs it alone. |
| `REACH_MIGRATION_OK` | A version 11 save gains an empty reach block. A version 12 save gains `rooms_attempted`. New saves write version 14. |
| `REACH_MIX_RELOAD_OK` | Idle depart, save/load, Join manual opens a fight whose beasts match `SlotEngine.build_room`, and one Strike does not end the run. `MANAFORGE_REACH_MIX=1` runs it alone. |
| `END_PANEL_OK` | Manual reach fights show the pack counter and end panel (win choices, Go deeper, Head home, flee half-bank, last-room Head home). `MANAFORGE_END_PANEL=1` runs it alone. |
| `MANUAL_OVERWHELMED_OK` | Manual Overwhelmed ends the run, loses the pack, skips rest, and shows the overwhelmed panel. `MANAFORGE_MANUAL_OVERWHELMED=1` runs it alone. |
| `DEPART_ESSENCE_OK` | `depart_slots` costs 20 Essence, moves loadout into the run, returns leftovers on every ending, and blocks bad loadouts without spending. `MANAFORGE_DEPART_ESSENCE=1` runs it alone. |
| `PARTY_LOCK_SAVE_OK` | Party stats freeze at depart, fights and save/load keep them, `member_away` / `away_members` track who is out, and the next depart re-freezes. `MANAFORGE_PARTY_LOCK_SAVE=1` runs it alone. |
| `KEEPER_AWAY_HUB_OK` | Keeper on a run vanishes from the hub, cannot be selected, his portrait hides, his harvest stops, wisps keep working, and he returns when the run ends. `MANAFORGE_KEEPER_AWAY_HUB=1` runs it alone. |
| `PARTY_AWAY_HUB_OK` | Elaia-only depart hides her in the clearing and Forge, blocks selection and portrait, Keeper still walks, save/load mid-run keeps her away, and she returns when the run ends. `MANAFORGE_PARTY_AWAY_HUB=1` runs it alone. |
| `KEEPER_AWAY_JOIN_FIGHT_OK` | With the Keeper away, a board LMB opens the shell while the run is live: progress, formation from `Reach.party`, and **Join the fight** (`Reach.set_control("manual")`, `BattleView` open). The same button works during an Overwhelmed rest without spending extra slots. `MANAFORGE_KEEPER_AWAY_JOIN_FIGHT=1` runs it alone. |
| `WISP_MISCLICK_KEEPS_JOB_OK` | Keeper away: RMB ground in the clearing and Forge keeps wisp jobs and toasts; at home RMB unassigns again. `MANAFORGE_WISP_MISCLICK_KEEPS_JOB=1` runs it alone. |
| `WISP_REASSIGN_SAME_SCENE_OK` | Keeper away: wisps reassign within the clearing or within Forge craft spots. `MANAFORGE_WISP_REASSIGN_SAME_SCENE=1` runs it alone. |
| `WISP_NO_CROSS_SCENE_OK` | Keeper away: cross-scene wisp sends are blocked; unassigned wisps may go anywhere; at home cross-scene works. `MANAFORGE_WISP_NO_CROSS_SCENE=1` runs it alone. |
| `OFFLINE_REACH_ONEPASS_OK` | A closed expedition resolves in one pass: Forge, then the run. Ten forced wins over a 3-hour gap emit `room_resolved` ten times, `changed` once, finish the run, and bank the pack. Time past the last slot is dropped. The same seed without forced outcomes matches a live clock stepped by 720s. An Overwhelmed plus wins spends the rest slots. `MANAFORGE_OFFLINE_REACH_ONEPASS=1` runs it alone. |
| `OFFLINE_SAVE_BLOCKED_OK` | During that pass `save_game` and `save_autosave` return false and `set_control` changes nothing. After the load, a save writes the finished run. `MANAFORGE_OFFLINE_SAVE_BLOCKED=1` runs it alone. |
| `BIG_DELTA_CATCHUP_OK` | A live frame over 5s uses `catch_up` (`source` frame). Three slot-lengths resolve three rooms. A 1s frame does not. The same span as one-second frames matches `slots_used` and `room_log`. `MANAFORGE_BIG_DELTA_CATCHUP=1` runs it alone. |
| `SAVE_NEWER_REFUSED_OK` | A save newer than this build is refused with a message naming both versions and leaves the game untouched. Continue skips it, and autosave never overwrites a newer autosave. `MANAFORGE_SAVE_NEWER=1` runs it alone. |
| `REACH_LEGACY_GONE_OK` | The legacy `ReachFight` scripts are deleted, removed Reach APIs are gone, saves no longer write `pace` / `mix` / `salve_used`, older saves with those keys still load, and no script under `scripts/` or `tools/` references the old engine. `MANAFORGE_REACH_LEGACY_GONE=1` runs it alone. |
| `DEBUG_SNAPSHOTS_MIGRATE_OK` | All nine debug snapshots load through `SaveService.migrate_state`, so the version 10 ones gain a current reach block. A newer snapshot is refused. `MANAFORGE_SNAPSHOT_MIGRATE=1` runs it alone. |
| `BEAST_DATA_OK` | `data/beasts.json` holds the ten §10 species plus the dark imp and dark moth. Threat and roles recompute from the stats, HP is 10 + 3 × Vitality, variants follow the variant rule (tier 1 about +30%), every name has a string, and Briar Warden is now Briar Hulk. The resolver fixtures come from the poison-refresh sim and their §4 example uses this imp. `MANAFORGE_BEAST_DATA=1` runs it alone. |
| `SPAWN_DATA_OK` | `data/spawn_tables.json` matches the §10 budget (90 / 108 / 138 at depth 1 / 10 / 15) and weights. Every beast exists and may spawn at that depth, and each depth has the draft's number of different rooms, room for room the same as the sim's `compositions()` in `tests/fixtures/resolver_compositions.json`. Amberbind is the manual jackpot and never a bonus drop. The approved job 23 loot tables are pinned: g(D) = 1 + 0.25·log2(D); herbs solo 0–1 @50% / duo 1–2 plus floor/frac extras on base avg × (g−1), Glowcap/Bitterroot 50/50; Briarwood flat; bonus bundle weights per band D1–4 / D5–14 / D15+ (each sums to 100), qty = round half up of base × g(D), boss ×2, party size no effect, no Amberbind and no Essence. `MANAFORGE_SPAWN_DATA=1` runs it alone. |
| `SPAWN_ROLLER_OK` | `SpawnRoller` budgets and `compositions()` match `tests/fixtures/resolver_compositions.json` at every fixture depth. `roll_room` over seeded draws stays within budget, lands on a fixture room, and respects front/back row rules. Depth 3 over 2,000 seeds hits `wilt_wisp` or `root_snapper` at least once. `MANAFORGE_SPAWN_ROLLER=1` runs it alone. |
| `SPAWN_SEED_OK` | The same room seed yields the same room twice; depth 3 varies across 50 consecutive seeds; `boss=true` marks exactly one beast (highest threat, lowest slot on ties). Room seeds 1, 2 and 1000 at depth 5 are pinned. `MANAFORGE_SPAWN_SEED=1` runs it alone. |
| `STRINGS_ADVENTURE_V4_OK` | The BATTLE_SCENE_DRAFT v4 `adv_*` strings exist and read right (Overwhelmed, Calmed, trailhead, Strike for me, None packed, the ability tooltip, item loadout, 20 Essence, the pre-departure warning). Adventure copy never says slain, killed, or (for `adv_*` / `beast_*`) defeat, and no string says Rootweave. `MANAFORGE_STRINGS_V4=1` runs it alone. |
| `SPEED_BUTTON_OK` | The player speed button is 1×, 2×, 4×, 8× during an open session, including the Stable HUD. Offline and idle catch-up stay on the 1× curve at 8×. The value is not in the save. Launch resets it. The debug 16× button is unchanged. |
| `SAVE_V14_INVENTORY_MERGE_OK` | A v13 reach's Briarwood, herbs, Heart Salve and Bile Vial add into the Backpack (they do not overwrite a stack already there) and leave the reach block. A zero total adds no stack. An idle slot does not bank Briarwood before the run ends, a manual fight spends a Salve from the Backpack, and Ascend keeps the four. `MANAFORGE_SAVE_V14_INVENTORY=1` runs it alone. |
| `SAVE_V14_HOME_OK` | A v13 save with no run migrates to `expedition.status` home. Cyan with no run is `finished_unseen` ("from an older save"). A running v13 run is cleared and comes home (job 25 cut; see `SAVE_V14_LEGACY_RUN_CLEARED_OK`). A new save writes version 14 and an expedition block. A live slot run writes `out`. `MANAFORGE_SAVE_V14_HOME=1` runs it alone. |
| `SAVE_V14_LEGACY_RUN_CLEARED_OK` | Job 25 is cut (Haex 2026-10-10). A v13 save with a run out (idle room, rest or manual) loads with that run cleared, no conversion: `SaveService.clear_legacy_run` ends it, the lantern goes dark, and the expedition is `home` with `legacy_run_cleared`. Depth, clears, dojo exp and the banked reach items (merged into the Backpack) stay; no Essence moves; a re-save stays home. A v14 old-engine run with no `slots_total` is cleared the same way (home, dark, kept items). A slot-engine mid-run resumes. `MANAFORGE_SAVE_V14_LEGACY_RUN=1` runs it alone. |
| `SAVE_V14_FROM_MAIN_OK` | A v11 main-save fixture and the v10 batch fixture both load through to v14: resources and Backpack intact, an empty reach block, expedition home. `MANAFORGE_SAVE_V14_FROM_MAIN=1` runs it alone. |
| `PACK_BANKING_OK` | `Pack` banks wood/stone/food through `GameState` and other ids through the Backpack at 100% / 50% / 0%, then clears. `halve()` rounds down per item. Essence and exp never sit in the pack. `to_dict` / `from_dict` round-trip through JSON. `MANAFORGE_PACK_BANKING=1` runs it alone. |
| `PACK_LOOT_TABLE_OK` | `RoomLoot` reads the approved `loot` block: `depth_g`, deterministic rolls, solo/duo means, depth-16 herb mean, bonus-drop rate and no `sapsteel` at depth 1, boss ×2 on briarwood/herbs only, and `glowcap` / `bitterroot` as known items. `MANAFORGE_PACK_LOOT_TABLE=1` runs it alone. |
| `RESOLVER_DICE_OK` | The §4 worked example (`s4_line1`, `s4_line2`, `s4_line4`) through `FightState.strike` with injected dice: totals, bands, damage 24 / 4 / 52, the Fate crit, and HP after. A beast attacker consumes no Fate roll. `MANAFORGE_RESOLVER_DICE=1` runs it alone. |
| `RESOLVER_MARGIN_OK` | Every `strikes` case in `tests/fixtures/resolver_cases.json` matches its `expect` block. At `hp * 10 <= max_hp` a party member is knocked out and a beast is Calmed, on both sides, including exactly 10%. `MANAFORGE_RESOLVER_MARGIN=1` runs it alone. |
| `RESOLVER_DIE_TABLE_OK` | Every `die_table` and `round_half_up` row matches. The integer half-up helper agrees with `floor(x + 0.5)` for raw × 1/2, 3/2 and 2. `MANAFORGE_RESOLVER_DIE_TABLE=1` runs it alone. |
| `RESOLVER_SEED_OK` | Combat seeds stay inside 0..2^31−1. The same seed repeats. The four room streams differ, and the spawn, combat and loot mixes for room 1000 are pinned. RNG state saved as a String survives JSON and repeats the next draws. `MANAFORGE_RESOLVER_SEED=1` runs it alone. |
| `RESOLVER_STATE_ROUNDTRIP_OK` | A seeded fight (Keeper at unlock vs an acorn imp and a spore moth) survives `to_dict` → JSON → `from_dict`: the dicts match, and the next strikes match. Party Weave is 30. `MANAFORGE_RESOLVER_STATE=1` runs it alone. |
| `RESOLVER_TURN_ORDER_OK` | Turn order is Swiftness, then party, then slot, rebuilt each round through `effective_swiftness`. Ambush puts beasts first in round 1 only. KO and Calmed fighters are skipped, including one that drops mid-round. The fight flees after round 60. A mid-round save continues on the same seed. `MANAFORGE_RESOLVER_TURN_ORDER=1` runs it alone. |
| `RESOLVER_ROWS_OK` | Melee reaches only the front row while it stands, then the back row once it is empty. Ranged reaches both, at −2 to hit into the back row only while the front stands. A back-row melee beast can still attack. An illegal party target spends no dice and no turn. `MANAFORGE_RESOLVER_ROWS=1` runs it alone. |
| `RESOLVER_TARGETING_OK` | Both `beast_targeting` fixture cases. Ties break to the front row, then slot. Only a reachable member is picked. `MANAFORGE_RESOLVER_TARGETING=1` runs it alone. |
| `RESOLVER_BRACE_OK` | Brace through a real step: the §4 line keeps 6+5 and misses, a landed blow is halved (half up, minimum 1), Brace ends at the bracer's next turn, and the third defense die is rolled only while braced. `MANAFORGE_RESOLVER_BRACE=1` runs it alone. |
| `RESOLVER_SHIELD_ORDER_OK` | Brace halves a blow before the shield absorbs it. The shield also absorbs a poison tick. Sap Spring gives each member `round_half_up(max_hp / 5)`. A spent shield stays at 0. `MANAFORGE_RESOLVER_SHIELD_ORDER=1` runs it alone. |
| `RESOLVER_POISON_REFRESH_OK` | Every `poison_refresh` op. A tick at turn start can knock out or Calm and that turn is lost. A poison move deals no strike and picks the Ward-weakest reachable member. `MANAFORGE_RESOLVER_POISON=1` runs it alone. |
| `RESOLVER_TWISTS_OK` | Thicket reorders a floored tie and lowers defense through `effective_swiftness`. Fog takes 2 off both sides' attack totals. `twist = ambush` puts beasts first in round 1. Sap Spring shields. Rich Hollow changes a seeded fight only by storing the name. `MANAFORGE_RESOLVER_TWISTS=1` runs it alone. |
| `RESOLVER_BOSS_OK` | A boss gains half its max HP again (half up) and the Calm line uses that max. A no-move boss shows Heavy ×1.5 on its 3rd and 6th turns. A poison boss uses the move on its 2nd and 4th. A normal beast with a move uses it on its 3rd and 6th. The intent is set before the beast acts. `MANAFORGE_RESOLVER_BOSS=1` runs it alone. |
| `RESOLVER_SALVE_OK` | Heart Salve heals 30% of max HP (half up), caps at max, spends no dice, allows 2 per fight, and needs a loadout dose. A knocked-out target is refused, and so is Bile Vial. `MANAFORGE_RESOLVER_SALVE=1` runs it alone. |
| `AUTO_FLEE_KO_ZERO_OK` | `flee_check` counts a knocked-out member with HP left as 0, ignores shields, and uses the integer edges: exactly half does not flee, and exactly one third does not flee. `MANAFORGE_AUTO_FLEE_KO_ZERO=1` runs it alone. |
| `RESOLVER_LOG_OK` | `step()` emits every fight event kind with the listed fields, appends `BattleLog` strike lines with roll vs target text (2d6 sum + stat/mod, braced `[6,5,1 → 6+5]` when braced, Fate crit suffix), keeps `log_tail` at 200, and keeps the new `resolve()` dice splits. `MANAFORGE_RESOLVER_LOG=1` runs it alone. `MANAFORGE_RESOLVER=1` runs all sixteen resolver tokens. |
| `AUTO_POLICY_OK` | `AutoPolicy` Strike for me, idle salve rules, `should_flee` (round 2+ only), and `run_idle` through the step API: front-row strike targeting, salve thresholds and caps, flee edges, deterministic seeded fights, win/flee/overwhelmed, and the step guard. `MANAFORGE_AUTO_POLICY=1` runs it alone. |
| `SIM_PARITY_OK` | `BatchSim.run_batch` on four Director sim cells (unlock/duo × depth 1/8, 3000 fights each, seed 20261010): win, flee, and overwhelmed rates within ±3.0 points of the sim MILESTONES table, deterministic repeats, and a one-line measured table per cell in the log. Not in the default VERIFY list (~31 s). `MANAFORGE_SIM_PARITY=1` runs it alone. |
| `RESOLVER_PERF_OK` | Fifty `duo` depth-8 rooms through `run_batch` finish fast (best of three timed runs; all three times print). Under 100 ms passes cleanly; 100–150 ms passes but prints `RESOLVER_PERF_WARN <ms>`; above 150 ms fails. `MANAFORGE_RESOLVER_PERF=1` runs it alone. |
| `BATTLE_SHELL_OK` | The arena overlay is closed at boot. `BattleView.open_arena` (the debug button's call) shows one CanvasLayer above Echo and below the pause menu, and the tree stays unpaused while the hub clock advances. Clicks do not move the Keeper; Escape closes the overlay without opening pause, and the same right-click then moves the Keeper. The forest backdrop and foreground are the arena art, the twelve slot marks sit on its sole points, Keeper and Elaia stand in battle poses (every pose loads), and every beast hurt frame is imported. Opening twice does not stack. A real mouse click on Close (pushed through the viewport, not a direct call) closes it. A save while it is open loads with it closed. `MANAFORGE_BATTLE_SHELL=1` runs it alone. |
| `BATTLE_ECHO_EXCLUSIVE_OK` | An open arena keeps `EchoChamber.open_battle` from starting Echo. An open Echo refuses the arena, and dismissing Echo lets it open again. A manual reach fight also refuses it. The debug panel's "Battle arena (test)" button, next to Jump to Echo, opens the overlay. `MANAFORGE_BATTLE_ECHO=1` runs it alone. |
| `ECHO_V4_MATH_OK` | Elaia and Bramble data match `tests/fixtures/echo_duel_cases.json` (no `crit_multiplier` / `swift_tie_favors_foe`). Every fixture replay matches `EchoBattle.turn_log`, rounds, outcomes, and dice consumption through `BattleResolver`. Spare and Strike in the window still finish as `spare` / `defeat`. Keeper max HP is 25 at all 5s; Elaia 31; Bramble 46. `MANAFORGE_ECHO_V4_MATH=1` runs it alone. |
| `ECHO_V4_PARITY_OK` | Six keeper sheets: 1,500 seeded duels each; win = spare window opened. Rates within ±4.5 pp of `win_rates` (`e1_fresh` ≤ 1.5%). Order `e1_rootsteel > e1_flint_2ranks > e1_flintblade > e1_fresh` and `e2_unlock > e2_rootsteel`. Prints `ECHO_V4_RATE` lines and ms (not gated). `MANAFORGE_ECHO_V4_PARITY=1` runs it alone. |
| `ECHO_SUITE_OK` | `_verify_echo` plus `_adventure_batch1` together. `MANAFORGE_ECHO_SUITE=1` runs them without the full VERIFY. |
| `BATTLE_PLATES_OK` | `BattleView.show_fight` places fighters on the v7 sole points and builds a 56×24 plate under every fighter (`Arena/Plates/PartyPlate_*` / `BeastPlate_*`: name, level slot, HP bar, Weave on the party only, Calmed / Knocked out, intent bubble on beasts). `set_active` / `refresh_fight` update the gold plate, active arrow and Calmed visuals. There is no party bar any more. Placeholder Keeper and Elaia stay until a fight is shown. Close sits top-right. `MANAFORGE_BATTLE_PLATES=1` runs it alone. |
| `BATTLE_MENU_OK` | Experimental arena test fight: `start_test_fight`, the six bottom-bar actions (Strike, Ability, Items/Salve, Brace, Flee, Strike for me) inside `BottomBar`, `SideActions/IdleButton`, the hidden `AbilityRow` picker, target mode, log panel, playback (instant headless), and no backpack / save spend. `MANAFORGE_BATTLE_MENU=1` runs it alone. |
| `BATTLE_TARGET_REACH_OK` | Melee vs magic targeting overlays match `legal_targets`; illegal clicks do not step; hub clicks stay blocked. `MANAFORGE_BATTLE_TARGET_REACH=1` runs it alone. |
| `BATTLE_STRIKE_FOR_ME_OK` | Test fight `StrikeForMeToggle`: auto Strike only via `AutoPolicy.strike_for_me_action`, front-row targeting, toggle reset, off after one action returns the menu, and `strike_for_me_on()`. `MANAFORGE_BATTLE_STRIKE_FOR_ME=1` runs it alone. |
| `BATTLE_PLAYBACK_OK` | `BattlePlayback` strike gaps are **1 s** at 1× (2 s at 2×, 0.5 s at 4×), speed scaling, Strike-for-me 1× lock, floats, status pause. `MANAFORGE_BATTLE_PLAYBACK=1` runs it alone. |
| `BRAMBLE_HIDDEN_UNTIL_JOIN_OK` | After Echo 2 Spare, `BrambleWarden` stays hidden until `Reach.reaches_cleared >= 30` (`GameState.bramble_joined()`); defeat or no outcome never shows him; save/load and boot restore visibility at 30. `MANAFORGE_BRAMBLE_HIDDEN=1` runs it alone (default suite). |
| `BATTLE_POSE_RESET_OK` | Timed playback (not instant): after each strike, item, or brace event the actor returns to `rest_pose_for` (idle, brace while braced, or ko); react/hurt-end thresholds are frozen at event start so a mid-event speed change cannot skip hurt-end; Salve targets and post-brace stances recover; paced fights at 1×/2×/4×, a speed drop mid-swing, Strike-for-me mid-swing, and fight end mid-event. `MANAFORGE_BATTLE_POSE_RESET=1` runs it alone (also in the default suite). |
| `BATTLE_ART_OK` | Every art-backed species in `beasts.json` (the eight in `BEAST_IDLE` / `BEAST_HURT`; stump_ogre and stag_spirit are art-pending) has a 128×128 idle and hurt that load; dark variants reuse the base sprite with the tint; a live fight never falls back to the grey ColorRect placeholder; timed hurt→idle still holds. `MANAFORGE_BATTLE_ART=1` runs it alone. |
| `BATTLE_UI_V7_OK` | Battle UI v7 final art on the live arena with a 6 vs 6 fight: all 12 `SLOT_SOLES` and ground marks equal `tests/fixtures/battle_ui_v7_layout.json` (battle540: soles on rows 206 / 286 / 366, middle steps 80, beast columns 216 apart vs the party's 148, not a mirror), party plates 56×24 and beast plates 56×20 at (x − 28, y + 10) with Weave hidden on beasts, `UI_ART_DIR` under `assets/art/battle/ui/`, depth/round/speed top bar (speed selected texture), no `battle_plate_outline`, `Arena/Fighters` draw in ascending feet y, plates above the foreground, no `PartyBar` and no `TextureProgressBar` outside a plate, `BottomBar` (-24, 400, 1008, 164) clear of the bottom-line plates with six action buttons plus scrollable `LogPanel` (`LogScroll`), intent bubbles at (visible centre x − 10, visible top − 28). `ui_placeholder/` must be gone. `MANAFORGE_BATTLE_UI_V7=1` runs it alone. |
| `BATTLE_ICONS_OK` | Battle UI status row (poison/brace icons from `FightState`, max 3 under the plate), twist chip at (142, 20) with tooltip, boss plate + crown (no Boss label), `intent_heavy_16.png`, keycaps on all six action buttons, hotkey `1` → Strike on the party turn only, `TestFightBar` clear of depth/twist chip. Ends with a `BATTLE_UI_V7_OK` regression pass. `MANAFORGE_BATTLE_ICONS=1` runs it alone. |
| `BATTLE_AUDIO_SOLE_CALLER_OK` | Only `battle_playback.gd` names battle SFX; `cues_for_event` rules. `MANAFORGE_BATTLE_AUDIO_SOLE_CALLER=1` runs it alone. |
| `HEADLESS_SILENT_OK` | Full test fight headless plays no battle SFX. `MANAFORGE_HEADLESS_SILENT=1` runs it alone. |
| `ADVENTURE_SLOT_RESUME_OK` | A manual fight saved mid-run reloads the same round, turn, HP and `rng_combat_state`, with the BattleView open. `MANAFORGE_ADVENTURE_SLOT_RESUME=1` runs it alone. |
| `ADVENTURE_NO_SCUM_OK` | Quitting and loading mid-fight repeats the next Strike (damage, faces, band) twice. Each of 5 actions updates `user://manaforge_adventure.json` and leaves the 7 slots and 3 autosaves untouched. `MANAFORGE_ADVENTURE_NO_SCUM=1` runs it alone. |
| `SAVE_REWIND_OK` | Loading an older slot ignores the adventure file owned by a newer save and restores that slot's room, pack and Backpack. Loading the newer slot returns to its own room. `MANAFORGE_SAVE_REWIND=1` runs it alone. |
| `BANK_ONCE_OK` | Finishing a run banks once. Applying a stale copy of that same run and finishing again leaves the Backpack alone. A new `run_id` still banks. `MANAFORGE_BANK_ONCE=1` runs it alone. |
| `SAVE_SEED_ROUNDTRIP_OK` | `run_seed` `0x7FFFFFF0`, a `room_seed` at 2^31−1, and `rng_combat_state` survive the main save and the adventure file. The next 20 d20s match a copy that was never saved. `MANAFORGE_SAVE_SEED_ROUNDTRIP=1` runs it alone. |
| `ADVENTURE_NEWER_REFUSED_OK` | An adventure file with `adv_version` 2 is ignored: the main save's run loads, `last_load_error` names the adventure, and the file stays on disk. `MANAFORGE_ADVENTURE_NEWER_REFUSED=1` runs it alone. |
| `HANDOFF_JOIN_FRESH_OK` | Joining manual on the current idle room, including a boss, starts that room fresh: same beasts, full HP, Salves unused, `rooms_attempted` unchanged. After that fight is handed off and the 12 minutes pass, Manual opens the next room fresh. `MANAFORGE_HANDOFF_JOIN_FRESH=1` runs it alone. |
| `HANDOFF_RESUME_OK` | Idle mid-fight, then Manual within 12 minutes, resumes the same round, turn, HP, `salves_used` and `rng_combat_state`. A save and load with no offline time still resumes. `MANAFORGE_HANDOFF_RESUME=1` runs it alone. |
| `HANDOFF_EXPIRED_OK` | 719 seconds do not resolve a handed-off fight. At 720 seconds the room log matches `AutoPolicy.run_idle` on the fight from the press, `slots_used` increases, and Manual opens the next room. `MANAFORGE_HANDOFF_EXPIRED=1` runs it alone. |
| `HANDOFF_IDLE_OK` | A handed-off fight keeps manual Salves inside the cap of 2, the Idle button is disabled in the test fight and enabled on a reach party turn, Strike for me stays at 1×, and Go deeper / Head home still work after a resumed win. `MANAFORGE_HANDOFF_IDLE=1` runs it alone. |
| `DEBUG_ADVENTURE_OK` | Experimental debug panel, through its real buttons: each **Force next room** button (Flee, Overwhelmed, Win) confirms on the status line and the next idle room resolves as forced. **Fight at depth** (1–40, Boss, With Elaia, **Open fight**) opens the arena test fight with beasts from `SpawnRoller.table_for(depth)`, and still refuses during a live reach fight. **Batch-sim 200** writes win / flee / overwhelmed counts that sum to 200, plus the ms. **Mid-fight** loads the hub with `Reach.fight_active()`, round 3 and the BattleView open on the hub. Every reach snapshot file except the Bramble-era Echo 2 ready is save_version 14, and Add items lists Glowcap and Bitterroot. `MANAFORGE_DEBUG_ADVENTURE=1` runs it alone. |

Retired tokens (no longer printed or expected anywhere): `REACH_MANUAL_DEFEAT_OK` retired by job 26, replaced by `MANUAL_OVERWHELMED_OK`. `REACH_TURN_ORDER_OK` retired by job 35, replaced by `RESOLVER_TURN_ORDER_OK`. `REACH_IDLE_ROLL_OK`, `REACH_FAIL_REST_OK`, `REACH_PUSH_STOP_OK`, `REACH_REWARDS_OK`, and `REACH_BOSS_ROOM_OK` retired by job 24, replaced by `IDLE_SLOTS_OK`, `IDLE_RESOLVE_AT_END_OK`, `IDLE_REST_SLOTS_OK`, and `IDLE_BOSS_PAYBACK_OK`.

### Offline order

Loading a save whose expedition is still out resolves the closed gap in one pass. Forge jobs run first (`ForgeJobs.apply_saved_offline_gap`), then the expedition (`Reach.catch_up`: real headless fights on the raw gap, no play speed). Time after the run's last slot is dropped. A manual room has no clock, including a fight restored from the adventure file, so that gap does not step it. A fight handed to idle is stored on the run (`handoff`) and is an idle room, so the same gap resolves it at 12 minutes. `save_game`, `save_autosave`, and `save_on_quit` refuse until that pass finishes, then saves unblock. A live frame longer than 5 seconds of game time uses the same pass.

`CHECK_ONLY_OK`, `DURATION_OK`, and `ELAIA_OK` are opt-in shortcuts (`--check-only`, `MANAFORGE_DURATION_ONLY`, `MANAFORGE_ELAIA_ONLY`). They are not extra regression tests. `ELAIA_OK` runs the same join check as `ELAIA_JOIN_OK`.

**SANITY** (`tools/scene_sanity.gd`), the short load check beside VERIFY:

| Token | What it guards |
| --- | --- |
| `SANITY_OK` | The hub load, Echo view, gear, content keys, and scene-exit audit all passed. |
| `FOREST_SEAL` | A walk from the Keeper's spawn cannot leak out of the clearing. The harvest nodes, the bench, and the Forge door stay reachable inside the seal. The north thorn-path mouth is an exception: the corridor is walkable in that check, and it still cannot reach the map edge. |
| `WORK_REACH` | Keeper and Elaia each have a stand at the harvest nodes, the bench, the Manatree door and water spot, every runestone, the portal, and the five Forge stations. |
| `SCENE_EXITS` | The only scripts that both name the title scene and change to it are the allow-list, and that list includes the pause menu. The Forge exit returns to the hub. Echo battle stays an overlay. |

SANITY's `pause menu can reach the title` check (inside `SCENE_EXITS`) reads `.gd` source. A release pck ships compiled scripts, so that scan cannot run against the pack. On a packed build, rely on `SCENE_TRANSITIONS_OK` for that path. The suite does not print an `EXPORT_PLAY_OK` token.

## Two Windows exports

Same tip, two presets in `export_presets.cfg`. Both keep `binary_format/embed_pck=false`, so a playtest zip is the `.exe` plus the sibling `.pck`. Do not turn embed on for those zips.

| Preset | Feature tag | What the pack contains |
| --- | --- | --- |
| `Windows Testing / Experimental` | `manaforge_debug` | Debug panel, nine snapshot saves, AnimPreview, Ctrl+F8 and F9. Docs, archive, library, verify, and capture scripts stay out. `tools/*` is **not** excluded; the baker, scene sanity, and `tools/legacy/*` still are. |
| `Windows Release / Stable` | `manaforge_stable` | Today's stripped playtest. `tools/*` plus AnimPreview, the debug panel, and `tools/debug/snapshots/` by name. No debug panel, snapshots, or AnimPreview in the pack file table. |

```bash
godot --headless --path . --export-release "Windows Testing / Experimental" builds/experimental/TalesOfTheManaforge.exe
godot --headless --path . --export-release "Windows Release / Stable" builds/stable/TalesOfTheManaforge.exe
```

Each command writes the exe and `TalesOfTheManaforge.pck` in that folder. Zip those two files together. The editor and the Testing preset run debug tools. The Stable preset does not, even if it was exported with the debug template.

Pack check (also part of default VERIFY; this form requires the two `.pck` files above):

```bash
MANAFORGE_DEBUG_STRIP=1 godot --headless --path . -s res://scripts/verify_headless.gd
```

Expect `DEBUG_STRIPPED_OK`.

## Debug panel

Testing builds only. **Ctrl+F8**, or Options → **Show debug tools**. Bare F8 does nothing (that key stops the game in the Godot editor). The row and the key stay hidden when `manaforge_stable` is set or the panel scene is missing.

- **Load snapshots:** Pre-Echo, Forge unlocked, Elaia joined, Ancient ready (save-version 10 fixtures), then Echo 2 ready (13), North road open, Pre-boss, Veteran reacher and Mid-fight (14), under `tools/debug/snapshots/` and excluded from Stable. **Mid-fight** carries an `adventure` key: the loader writes it with `SaveService.write_adventure_raw` (debug tools only), owned by the snapshot's `save_id`, and the hub reopens the depth-2 fight at round 3.
- **Forge:** free Sapsteel, Heartwood, and Amberbind (no cost, no wait) and **Skip station work** (finishes the current station timers).
- **Add items:** a search box, a quantity, and every raw material, handcraft item, and piece of gear from the data tables. Raw materials go to the resource counts. Gear goes to the equipment bag. Everything else goes to the backpack.
- Options **Show speed-up button** stays. Its hint is `options_speedup_toggle_hint`.
- **Jump to Echo** and **Open Ascension shop** are optional shortcuts.
- **Expedition:** **Force next room: Flee / Overwhelmed / Win** queue that outcome for the next idle room (`Reach.debug_force_outcomes`). **Fight at depth** (1–40, Boss, With Elaia, **Open fight**) opens the arena test fight at that depth with a random 31-bit seed; Echo or a live reach fight refuses it. **Batch-sim 200** runs `BatchSim.run_batch("duo", depth, 200, seed)` at the same depth and shows win / flee / overwhelmed counts and the ms. The panel scrolls.

## Animation preview

Debug / testing only. Keeper and Elaia stand side by side at an integer scale with nearest filtering, in every clip their SpriteFrames carry (idle and walk in N/E/S/W, run when it exists, harvest, water, station work, and anything added later).

```bash
godot --path . res://tools/AnimPreview.tscn
```

**F9** opens the same scene from the title, the clearing, or the Forge when debug tools are on (`manaforge_debug`, or an editor debug run). Windows Release / Stable sets `manaforge_stable` and excludes `tools/*`, `tools/AnimPreview.tscn`, and `tools/anim_preview.gd`, so the packed Stable build does not contain it.

## Hub BGM (after pull)

Cue `mus_hub_forest` plays **`assets/audio/mus_hub_forest_haex.mp3`** on the **Music** bus with loop. The fallback is that JSON path, then the shipped MP3 only. Older beds live in `assets/library/legacy/` and are not imported. After `git pull`, **reopen the project in Godot** so the MP3 reimports.

Reach manual fights (`BattleView.open_reach_fight`) suspend the hub bed and play cue **`mus_battle_forest`** (`assets/audio/mus_battle_forest.ogg`, loop, “Bramble Dance”). Closing the reach arena calls `resume_hub_after_battle`. If the OGG is not in the tree yet, `GameAudio.play` logs `cue_missing` and continues (no crash). Echo chamber hub suspend is unchanged.

Music stings (`mus_fruit_sting`, `mus_ascend_sting`) use a second Music player so the hub bed never stops. Music bus defaults ~−9 dB; SFX buses 0 dB; Progress→Music duck only. Runtime forces `AudioStreamMP3.loop` / Ogg loop / WAV `LOOP_FORWARD`. If saved `music_volume` is `0` (bug: silent Music, SFX still OK), load treats it as reset-to-default once.

**Pause → Options → Audio:** Music / Sounds sliders + Reset. Persists in `user://manaforge_settings.cfg` (volume only — never restarts the hub stream).

7. After the first **Ascend**, an **Echo** portal stands in the glade. Select the Keeper and right-click it. **30 Essence** opens a 1v1 with **Elaia**. Strike or Flee; Spare appears only under 10% HP. A win grants a **Forge Key** Relic (**+2 Swiftness**, **+2 Fate**) and Manashards. On **Elder** or **Ancient** Manatree stages, care menu **Enter Forge** appears (hidden earlier); with the Key it says the door is not built yet.

**Echo combat math (Bundle 10 job 36):** `EchoBattle` uses the same §4 resolver as reach fights (`BattleResolver` + `BattleRng`). Dice-exact regressions live in `tests/fixtures/echo_duel_cases.json`, exported from `echo_sim.py` on Haex's box. The pending Switchshaft/Thornbow **+5/+5** weapon tweak is **not** in this branch (`data/equipment.json` unchanged).

## Assets upload

Drop new art in `Assets upload/`. Every coding ship must leave that folder **empty** (README-only) after sorting into `assets/art/` or `assets/library/`. See `ASSETS_UPLOAD.md`.

## Out of scope (v0.2)

Growth bar / Offers, Forge interior, companions in combat, Echo 2+, armor recipes, real Runestone art, edge camera, WASD, HTML5.
