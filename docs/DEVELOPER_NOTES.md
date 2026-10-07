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
7. Seven **Runestones** in the hub spend the same Manashard pool as the Ascension shop. Select the Keeper, right-click a stone, and they walk in range. Confirm, then +1 rank in that stat. The sheet base is **5 + rank** (a new game shows `5 + 0 = 5`). Cost is `floor(100 × 1.65^rank)` (PLACEHOLDER) — rank 0 still costs 100. Ranks, equipped gear, and the gear inventory persist through Ascend. Unspent Manashards and the backpack still wipe. Keep Tools returns tools only. Fate does not change gather, Wisps, or handcraft.

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
| `NO_OLD_KEEPER_IDLE_OK` | Old Keeper idle filenames are not referenced. The same check prints `IDLE_MISSING` (`none`, or the facings that have no idle frames). |
| `JOBS_SURVIVE_SWITCH_OK` | Watering, Elaia's stone harvest, the wood wisp, and station jobs keep paying across a hub/Forge switch, and the work animations are still playing on the way back. |
| `AUTOSAVE_THROTTLE_OK` | An event autosave waits 60 seconds before it writes again. Closing the window still saves inside that window. |
| `ELAIA_JOIN_OK` | Spare without a relic does not bring Elaia in. The first relic craft does. Her portrait waits for the clearing dialogue. An old save that already had her keeps her, and a relic without Spare does not. |
| `DEBUG_STRIPPED_OK` | The Windows Release / Stable preset strips the debug panel, the four debug snapshots, and AnimPreview. When `builds/stable/TalesOfTheManaforge.pck` and the experimental pack are on disk, the check reads those file tables. `MANAFORGE_DEBUG_STRIP=1` requires both packs. |
| `PORTRAIT_SWITCH_FORGE_OK` | With Elaia joined, a double-click on the Keeper portrait while she is in the Forge (and the reverse, Elaia's portrait while the Keeper is in the Forge) changes view without freeing the HUD inside the click. `MANAFORGE_PORTRAIT_SWITCH=1` runs it alone. |
| `FORGE_ARCH_DRAW_ORDER_OK` | After a real door transfer, ArchFront's opaque frame covers the Keeper at the Forge spawn and its draw z stays above the heroes. `MANAFORGE_FORGE_ARCH=1` runs it alone. |
| `FORGE_YSORT_OK` | In the Forge, a hero south of a station draws over it and a hero north of it draws under it. The arch stays above both. Station walk boxes use the opaque sprite width. `MANAFORGE_FORGE_YSORT=1` runs it alone. |
| `MANATREE_DOOR_CLEAR_OK` | At every growth stage, no Manatree walk box sits south of the door sill and the corridor up to the door is open. `MANAFORGE_MANATREE_DOOR=1` runs it alone. |
| `COMPANION_DOOR_TRANSFER_OK` | Keeper and Elaia go clearing → Forge → clearing twice. Both stay visible and can walk after each hop. `MANAFORGE_COMPANION_DOOR=1` runs it alone. |
| `FORGE_ENTRY_ONE_CLICK_OK` | One click on the Manatree door walks to the sill and enters the Forge. The same run checks the watering stand at every growth stage. `MANAFORGE_FORGE_ENTRY=1` runs it alone. |
| `KEEP_TOOLS_COST_OK` | Keep Tools costs 4000 Manashards, and the shop fallback string says 4000. |
| `THORN_PATH_LOCKED_OK` | The north thorn wall blocks the road until Bramble is passed. An early click shows the tease line. |
| `THORN_PATH_OPENS_OK` | Spare and defeat both open the road, play `sfx_path_open`, and drop the centre gate. The side hedges stay. |
| `BRAMBLE_ECHO_FEE_OK` | Bramble's fee is an Anvil weapon plus 50 Essence. Flee keeps the fee. A loss clears it. |
| `EXPEDITION_BOARD_SHELL_OK` | The trailhead board picks the Keeper and the open road. Depart stays disabled while the road is shut. |
| `REACH_IDLE_ROLL_OK` | Idle rooms roll d20 + bonus against 6. Natural 20 clears, natural 1 fails. Offline catch-up of a run stays at 1× while the speed button is at 8×. |
| `REACH_FAIL_REST_OK` | A failed room grants nothing, then rests 24 minutes, then opens the next room. |
| `REACH_PUSH_STOP_OK` | Push stops and switches to Hold when the next room's clear chance drops below 75%. |
| `REACH_DEPTH_ASCEND_OK` | Deepest depth, the lifetime reach counter, and the dojo pool survive Ascension. A new game clears them. |
| `REACH_MANUAL_DEFEAT_OK` | A manual defeat loses the room and returns to the trailhead with no rest and no reward. |
| `REACH_REWARDS_OK` | Briarwood and herbs are 0–1 at 50% and do not scale with depth. Exp goes to the dojo pool. Rooms grant no Essence. |
| `REACH_BOSS_ROOM_OK` | The 10th room attempted in an expedition is the boss at that depth, cleared or failed. A new expedition starts the counter over. Depth 10's first room is not a boss. |
| `REACH_MIGRATION_OK` | A version 11 save gains an empty reach block. A version 12 save gains `rooms_attempted`. New saves write version 13. |
| `SPEED_BUTTON_OK` | The player speed button is 1×, 2×, 4×, 8× during an open session, including the Stable HUD. Offline and idle catch-up stay on the 1× curve at 8×. The value is not in the save. Launch resets it. The debug 16× button is unchanged. |

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
| `Windows Testing / Experimental` | `manaforge_debug` | Debug panel, four snapshot saves, AnimPreview, Ctrl+F8 and F9. Docs, archive, library, verify, and capture scripts stay out. `tools/*` is **not** excluded; the baker, scene sanity, and `tools/legacy/*` still are. |
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

- **Load snapshots:** Pre-Echo, Forge unlocked, Elaia joined, Ancient ready. Real save-version 10 fixtures under `tools/debug/snapshots/`, excluded from Stable.
- **Forge:** free Sapsteel, Heartwood, and Amberbind (no cost, no wait) and **Skip station work** (finishes the current station timers).
- **Add items:** a search box, a quantity, and every raw material, handcraft item, and piece of gear from the data tables. Raw materials go to the resource counts. Gear goes to the equipment bag. Everything else goes to the backpack.
- Options **Show speed-up button** stays. Its hint is `options_speedup_toggle_hint`.
- **Jump to Echo** and **Open Ascension shop** are optional shortcuts.

## Animation preview

Debug / testing only. Keeper and Elaia stand side by side at an integer scale with nearest filtering, in every clip their SpriteFrames carry (idle and walk in N/E/S/W, run when it exists, harvest, water, station work, and anything added later).

```bash
godot --path . res://tools/AnimPreview.tscn
```

**F9** opens the same scene from the title, the clearing, or the Forge when debug tools are on (`manaforge_debug`, or an editor debug run). Windows Release / Stable sets `manaforge_stable` and excludes `tools/*`, `tools/AnimPreview.tscn`, and `tools/anim_preview.gd`, so the packed Stable build does not contain it.

## Hub BGM (after pull)

Cue `mus_hub_forest` plays **`assets/audio/mus_hub_forest_haex.mp3`** on the **Music** bus with loop. The fallback is that JSON path, then the shipped MP3 only. Older beds live in `assets/library/legacy/` and are not imported. After `git pull`, **reopen the project in Godot** so the MP3 reimports.

Music stings (`mus_fruit_sting`, `mus_ascend_sting`) use a second Music player so the hub bed never stops. Music bus defaults ~−9 dB; SFX buses 0 dB; Progress→Music duck only. Runtime forces `AudioStreamMP3.loop` / Ogg loop / WAV `LOOP_FORWARD`. If saved `music_volume` is `0` (bug: silent Music, SFX still OK), load treats it as reset-to-default once.

**Pause → Options → Audio:** Music / Sounds sliders + Reset. Persists in `user://manaforge_settings.cfg` (volume only — never restarts the hub stream).

7. After the first **Ascend**, an **Echo** portal stands in the glade. Select the Keeper and right-click it. **30 Essence** opens a 1v1 with **Elaia**. Strike or Flee; Spare appears only under 10% HP. A win grants a **Forge Key** Relic (**+2 Swiftness**, **+2 Fate**) and Manashards. On **Elder** or **Ancient** Manatree stages, care menu **Enter Forge** appears (hidden earlier); with the Key it says the door is not built yet.

## Assets upload

Drop new art in `Assets upload/`. Every coding ship must leave that folder **empty** (README-only) after sorting into `assets/art/` or `assets/library/`. See `ASSETS_UPLOAD.md`.

## Out of scope (v0.2)

Growth bar / Offers, Forge interior, companions in combat, Echo 2+, armor recipes, real Runestone art, edge camera, WASD, HTML5.
