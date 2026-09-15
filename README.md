# Tales of the Manaforge — Restart Edition

Cozy top-down pixel adventure inspired by *Secret of Mana*. You are the **Keeper**, tending a living **Manatree** in the last fragment of a fairy-forest.

**Canon:** `VISION_RESTART` + briefs (`SYSTEMS_V01` **v0.2.0**, `CONTENT_STRINGS_V01` **v0.2.0**, `VISUAL_BIBLE_RESTART_V01`). **Needs-only** stage-up (no growth bar / Offers). Pause menu + **7 save slots**. Art harvest nodes **v0.1.4**. Audio channels **v0.1.2**. Old forge/combat drafts are non-canon.

## Stack

- **Godot 4.3** · GDScript only · **fully typed**
- Playable forest hub: **64² grass TileMap**, many Y-sorted **decorative** trees, **exactly 3** harvest channels, Manatree landmark; view **1280×720** nearest-neighbor
- Autoloads: `ContentStrings`, `GameAudio`, `GameState`, `SaveService`
- Pause (**ESC** / HUD **Pause**): Resume, New Game, Save/Load (**7 slots**), Options stub, Exit
- Saves `user://manaforge_save_slot_{1..7}.json` (`save_version: **4**`; legacy single-file migrates → slot 1; old `growth` ignored)

## Prototype loop (Haex needs-only)

1. Click ground to move (cancels an active channel if you leave range).
2. Click **Harvest Tree / Stone / Berry** → starts a **harvest channel**. While in range: **+1 wood / stone / food per second** (pulse SFX quiet under hub music).
3. Click **Manatree** → care menu. **Water** starts a **water channel**: each second **+rand(1..3) manashards** and **+1 essence** (income only). Checklist shows next-stage **Needs**; **Pay** when affordable (confirm) to advance.
4. Stage costs: Young **20 essence** → Mature **40e+10 food** → Elder **60e+20f+10 wood** → Ancient **80e+40f+20w+10 stone**.
5. At **ancient**, harvest **Primordial Fruit** (Essence burst) → blessings → **Ascend**.

Essence comes from **watering ticks** and Fruit — not Fruit-only. Soft mats are spent only via **Pay**.

## Run

```bash
/home/box/tools/godot/godot --path /workspace/tales-of-the-manaforge
```

## Headless verify

```bash
/home/box/tools/godot/godot --headless --path /workspace/tales-of-the-manaforge -s res://scripts/verify_headless.gd
```

Expect `VERIFY_OK` and exit code `0`.

## Out of scope (v0.2)

Growth bar / Offers, Forge interact, combat, whisps, WASD, equipment, HTML5.
