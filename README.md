# Tales of the Manaforge — Restart Edition

Cozy top-down pixel adventure inspired by *Secret of Mana*. You are the **Keeper**, tending a living **Manatree** in the last fragment of a fairy-forest.

**Canon:** `VISION_RESTART` + briefs (`SYSTEMS_V01` **v0.4.0 LIVE**, `CONTENT_STRINGS_V01` **v0.4.0**, `VISUAL_BIBLE_RESTART_V01`). **Grow** = Fertilizer + Essence (needs-only Pay superseded). Pause menu + **7 save slots**. Art harvest nodes **v0.1.4**. Audio channels **v0.1.2**. Old forge/combat drafts are non-canon.

## Stack

- **Godot 4.3** · GDScript only · **fully typed**
- Playable forest hub: **64² grass TileMap**, dense Y-sorted **decorative** Haex forest ring (Art **v0.1.13-assets-upload**) around a larger glade, **exactly 3** harvest channels, Manatree landmark; view **1280×720** nearest-neighbor
- Autoloads: `ContentStrings`, `GameAudio`, `GameState`, `Backpack`, `SaveService`
- Pause (**ESC** / HUD **Pause**): Resume, New Game, Save/Load (**7 slots**), Options stub, Exit
- Saves `user://manaforge_save_slot_{1..7}.json` (`save_version: **6**`; backpack stacks; legacy single-file migrates → slot 1; old `growth` ignored)

## Prototype loop (Haex Grow + backpack)

1. Click ground to move (cancels an active channel if you leave range).
2. Click **Harvest Tree / Stone / Berry** → starts a **harvest channel**. While in range: **+1 wood / stone / food per second** (pulse SFX quiet under hub music).
3. Click **Manatree** → care menu. **Water** starts a **water channel**: each second **+rand(1..3) manashards** and **+1 essence** (income only). **Grow** spends **Fertilizer + Essence** (one click) to advance.
4. Placeholder Grow costs: Young **1 Fertilizer + 20 Essence** → Mature **2+40** → Elder **3+60** → Ancient **4+80**. Handcraft Fertilizer (wood+stone+food) in the **Backpack**.
5. At **ancient**, harvest **Primordial Fruit** → Manashard blessings (including **Keep Tools**) → **Ascend** (backpack wipe; tools return only with Keep Tools).

Essence comes from **watering ticks**. Soft mats feed **handcraft**, not Grow. Gathering tools never gate hands; they 2× Keeper channel speed. Stone Watering Can doubles the Manashard **roll** (`shard_roll ×2`); Essence water is unchanged.

## Run

```bash
/home/box/tools/godot/godot --path /workspace/tales-of-the-manaforge
```

## Headless verify

```bash
/home/box/tools/godot/godot --headless --path /workspace/tales-of-the-manaforge -s res://scripts/verify_headless.gd
```

Expect `VERIFY_OK` and exit code `0`.

## Hub BGM (after pull)

Cue `mus_hub_forest` plays **`assets/audio/mus_hub_forest_haex.mp3`** (Director primary) on the **Music** bus with loop. Fallback chain in `GameAudio`: **mp3 → ogg (`mus_hub_forest_haex_loop.ogg`) → wav**. After `git pull`, **reopen the project in Godot** so assets reimport. If the hub is silent, delete `.godot/imported/*haex*` (mp3/ogg/wav imports) and let Godot reimport — do not point the cue back at the short legacy `mus_hub_forest.wav`.

Music stings (`mus_fruit_sting`, `mus_ascend_sting`) use a second Music player so the hub bed never stops. Music bus defaults ~−9 dB; SFX buses 0 dB; Progress→Music duck only. Runtime forces `AudioStreamMP3.loop` / Ogg loop / WAV `LOOP_FORWARD`. If saved `music_volume` is `0` (bug: silent Music, SFX still OK), load treats it as reset-to-default once.

**Pause → Options → Audio:** Music / Sounds sliders + Reset. Persists in `user://manaforge_settings.cfg` (volume only — never restarts the hub stream).

## Out of scope (v0.2)

Growth bar / Offers, Forge interact, combat, whisps, WASD, equipment, HTML5.
