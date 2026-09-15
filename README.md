# Tales of the Manaforge — Restart Edition

Cozy top-down pixel adventure inspired by *Secret of Mana*. You are the **Keeper**, tending a living **Manatree** in the last fragment of a fairy-forest.

**Canon:** `VISION_RESTART` + day-1 briefs (`SYSTEMS_V01` **v0.1.2**, `CONTENT_STRINGS_V01` **v0.1.2**, `VISUAL_BIBLE_RESTART_V01`). Art harvest nodes **v0.1.4**. Audio channels **v0.1.2**. Old forge/combat drafts are non-canon.

## Stack

- **Godot 4.3** · GDScript only · **fully typed**
- Playable forest hub: **64² grass TileMap**, many Y-sorted **decorative** trees, **exactly 3** harvest channels, Manatree landmark; view **1280×720** nearest-neighbor
- Autoloads: `ContentStrings`, `GameAudio`, `GameState`, `SaveService`
- Save `user://manaforge_save.json` (`save_version: **3**`)

## Prototype loop (Haex channels)

1. Click ground to move (cancels an active channel if you leave range).
2. Click **Harvest Tree / Stone / Berry** → starts a **harvest channel**. While in range: **+1 wood / stone / food per second** (pulse SFX quiet under hub music).
3. Click **Manatree** → care menu. **Water** starts a **water channel**: each second **+rand(1..3) manashards**, **+1 essence**, and growth (still works at Ancient for shards/essence; Offers blocked at Ancient). Offers are instant.
4. At **ancient**, harvest **Primordial Fruit** (Essence burst) → blessings → **Ascend**.

Essence comes from **watering ticks** and Fruit — not Fruit-only.

## Run

```bash
/home/box/tools/godot/godot --path /workspace/tales-of-the-manaforge
```

## Headless verify

```bash
/home/box/tools/godot/godot --headless --path /workspace/tales-of-the-manaforge -s res://scripts/verify_headless.gd
```

Expect `VERIFY_OK` and exit code `0`.

## Out of scope (v0.1)

Forge interact, combat, whisps, WASD, equipment, HTML5.
