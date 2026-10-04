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

`CHECK_ONLY_OK`, `DURATION_OK`, and `ELAIA_OK` are opt-in shortcuts (`--check-only`, `MANAFORGE_DURATION_ONLY`, `MANAFORGE_ELAIA_ONLY`). They are not extra regression tests. `ELAIA_OK` runs the same join check as `ELAIA_JOIN_OK`.

**SANITY** (`tools/scene_sanity.gd`), the short load check beside VERIFY:

| Token | What it guards |
| --- | --- |
| `SANITY_OK` | The hub load, Echo view, gear, content keys, and scene-exit audit all passed. |
| `FOREST_SEAL` | A walk from the Keeper's spawn cannot leak out of the clearing. The harvest nodes, the bench, and the Forge door stay reachable inside the seal. |
| `WORK_REACH` | Keeper and Elaia each have a stand at the harvest nodes, the bench, the Manatree door and water spot, every runestone, the portal, and the five Forge stations. |
| `SCENE_EXITS` | The only scripts that both name the title scene and change to it are the allow-list, and that list includes the pause menu. The Forge exit returns to the hub. Echo battle stays an overlay. |

SANITY's `pause menu can reach the title` check (inside `SCENE_EXITS`) reads `.gd` source. A release pck ships compiled scripts, so that scan cannot run against the pack. On a packed build, rely on `SCENE_TRANSITIONS_OK` for that path. The suite does not print an `EXPORT_PLAY_OK` token.

## Animation preview

Debug only. Keeper and Elaia stand side by side at an integer scale with nearest filtering, in every clip their SpriteFrames carry (idle and walk in N/E/S/W, run when it exists, harvest, water, station work, and anything added later).

```bash
godot --path . res://tools/AnimPreview.tscn
```

In a debug build, **F9** opens the same scene from the title, the clearing, or the Forge. The key checks `OS.is_debug_build()` and does nothing in a release export. The scene lives in `tools/`, which the export strip already excludes (`tools/*`, and the scene and script by name), so a packed build does not contain it.

## Hub BGM (after pull)

Cue `mus_hub_forest` plays **`assets/audio/mus_hub_forest_haex.mp3`** on the **Music** bus with loop. The fallback is that JSON path, then the shipped MP3 only. Older beds live in `assets/library/legacy/` and are not imported. After `git pull`, **reopen the project in Godot** so the MP3 reimports.

Music stings (`mus_fruit_sting`, `mus_ascend_sting`) use a second Music player so the hub bed never stops. Music bus defaults ~−9 dB; SFX buses 0 dB; Progress→Music duck only. Runtime forces `AudioStreamMP3.loop` / Ogg loop / WAV `LOOP_FORWARD`. If saved `music_volume` is `0` (bug: silent Music, SFX still OK), load treats it as reset-to-default once.

**Pause → Options → Audio:** Music / Sounds sliders + Reset. Persists in `user://manaforge_settings.cfg` (volume only — never restarts the hub stream).

7. After the first **Ascend**, an **Echo** portal stands in the glade. Select the Keeper and right-click it. **30 Essence** opens a 1v1 with **Elaia**. Strike or Flee; Spare appears only under 10% HP. A win grants a **Forge Key** Relic (**+2 Swiftness**, **+2 Fate**) and Manashards. On **Elder** or **Ancient** Manatree stages, care menu **Enter Forge** appears (hidden earlier); with the Key it says the door is not built yet.

## Assets upload

Drop new art in `Assets upload/`. Every coding ship must leave that folder **empty** (README-only) after sorting into `assets/art/` or `assets/library/`. See `ASSETS_UPLOAD.md`.

## Out of scope (v0.2)

Growth bar / Offers, Forge interior, companions in combat, Echo 2+, armor recipes, real Runestone art, edge camera, WASD, HTML5.
