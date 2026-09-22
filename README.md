# Tales of the Manaforge — Restart Edition

Cozy top-down pixel adventure inspired by *Secret of Mana*. You are the **Keeper**, tending a living **Manatree** in the last fragment of a fairy-forest.

**Canon:** `VISION_RESTART` + briefs (`SYSTEMS_V01` **v0.5.0 LIVE**, `CONTENT_STRINGS_V01` **v0.5.0**, `VISUAL_BIBLE_RESTART_V01`). **Grow** = Fertilizer + Essence (needs-only Pay superseded). Pause menu + **7 save slots**. Art harvest nodes **v0.1.4**. Audio channels **v0.1.2**. Old forge/combat drafts are non-canon.

## Stack

- **Godot 4.7.2** · GDScript only · **fully typed**
- Playable forest hub: **2560×2160** play area (**2× × 3×** of the original 1280×720 hub), **64² grass TileMap**, dense Y-sorted **decorative** Haex forest ring around an open glade, **exactly 3** harvest channels, Manatree landmark; view **1280×720** nearest-neighbor; **arrow keys** pan the camera (clamped to play bounds)
- Autoloads: `ContentStrings`, `GameAudio`, `GameState`, `Backpack`, `KeeperStats`, `Equipment`, `SaveService`
- Pause (**ESC** / HUD **Pause**): Resume, New Game, Save/Load (**7 slots**), Options stub, Exit
- Saves `user://manaforge_save_slot_{1..7}.json` (`save_version: **8**`; backpack stacks; keeper stats store Runestone ranks starting at **0**; the sheet base is **5 + rank**; missing ranks load as 0; v6 saves still start gear empty; legacy single-file migrates → slot 1; old `growth` ignored; v8 adds Echo portal / fee / key / companion flag)

## Prototype loop (Haex Grow + backpack)

1. Click ground to move (cancels an active channel if you leave range).
2. Click **Harvest Tree / Stone / Berry** → starts a **harvest channel**. While in range: **+1 wood / stone / food per second** (pulse SFX quiet under hub music).
3. Click **Manatree** → care menu. **Water** starts a **water channel**: each second **+rand(1..3) manashards** and **+1 essence** (income only). **Grow** spends **Fertilizer + Essence** (one click) to advance.
4. Grow costs: Young **3 Fertilizer + 20 Essence** → Mature **6+40** → Elder **12+60** → Ancient **24+80**. Handcraft Fertilizer (10 wood+stone+food) in the **Backpack**.
5. At **ancient**, harvest **Primordial Fruit** → Manashard blessings (including **Keep Tools**) → **Ascend** (backpack wipe; tools return only with Keep Tools).
6. **Character** (HUD button or **C**): paper-doll equipment and seven combat stats (base + gear = total). Slots are weapon, relic, head, body, hands, pants, feet, cape, ring1, ring2. Only **weapon** starts unlocked. Slots are half-transparent squares with no gold border. An empty weapon reads **Weapon**; a locked slot reads **Locked** under the square. Handcraft a **Weapon Rod** (10 Wooden Planks) and a **Stone Sword** (`stone_sword`: 30 Stone Fragments + 1 Weapon Rod). Both land in the gear inventory, not the backpack. The rod is consumed into the sword.
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

## Hub BGM (after pull)

Cue `mus_hub_forest` plays **`assets/audio/mus_hub_forest_haex.mp3`** (Director primary) on the **Music** bus with loop. Fallback chain in `GameAudio`: **mp3 → ogg (`mus_hub_forest_haex_loop.ogg`) → wav**. After `git pull`, **reopen the project in Godot** so assets reimport. If the hub is silent, delete `.godot/imported/*haex*` (mp3/ogg/wav imports) and let Godot reimport — do not point the cue back at the short legacy `mus_hub_forest.wav`.

Music stings (`mus_fruit_sting`, `mus_ascend_sting`) use a second Music player so the hub bed never stops. Music bus defaults ~−9 dB; SFX buses 0 dB; Progress→Music duck only. Runtime forces `AudioStreamMP3.loop` / Ogg loop / WAV `LOOP_FORWARD`. If saved `music_volume` is `0` (bug: silent Music, SFX still OK), load treats it as reset-to-default once.

**Pause → Options → Audio:** Music / Sounds sliders + Reset. Persists in `user://manaforge_settings.cfg` (volume only — never restarts the hub stream).

7. After the first **Ascend**, an **Echo** portal stands in the glade. Select the Keeper and right-click it. **30 Essence** opens a 1v1 with **Elaia**. Strike or Flee; Spare appears only under 10% HP. A win grants a **Forge Key** (relic slot) and Manashards. The Manatree care menu's **Enter Forge** says the door is not built yet.

## Out of scope (v0.2)

Growth bar / Offers, Forge interior, companions in combat, Echo 2+, armor recipes, real Runestone art, edge camera, WASD, HTML5.
