# Tales of the Manaforge — Restart Edition

Cozy top-down pixel adventure inspired by *Secret of Mana*. You are the **Keeper**, tending a living **Manatree** in the last fragment of a fairy-forest.

**Canon:** `VISION_RESTART` + day-1 briefs (`SYSTEMS_V01`, `CONTENT_STRINGS_V01`, `VISUAL_BIBLE_RESTART_V01`). **v0.1.1** overnight playable hub (sprites, forest tiles/trees, audio). Old forge/combat drafts are non-canon. *Manaforge* is **title-only** in-world for v0.1.

## Stack

- **Godot 4.3** · GDScript only · **fully typed**
- Windows-first (`export_presets.cfg` stub)
- Playable forest hub: **64² grass TileMap**, Y-sorted trees (imagine/oak/pine/autumn/bush/stump), Keeper **AnimatedSprite2D** 128×128 feet-anchored; gatherables + Manatree landmark; view **1280×720** nearest-neighbor
- Autoloads: `ContentStrings`, `GameAudio`, `GameState`, `SaveService`
- Audio: full `.ogg` pack + looping `mus_hub_forest` on hub load (Music bus); cue IDs in `data/audio_cues.json`; buses Music / SFX_UI / SFX_World / SFX_Progress · save `user://manaforge_save.json` (`save_version: 2`)

## Prototype loop

1. Click ground to move; click gather nodes / Manatree to walk and interact.
2. Gather **Wood, Stone, Food, Manashards** (Essence only from Fruit).
3. **Water** the Manatree (free) and **Offer** mats for growth; stage-up when growth + offer gates met: **sapling → young → mature → elder → ancient**.
4. At **ancient**, harvest **Primordial Fruit** → spend **Essence** on blessings → **Ascend** (soft mats reset; Essence + ranks persist).

### Fruit upgrades (`data/fruit_upgrades.json`)

| Id | Effect |
|----|--------|
| `deep_roots` | +2 water growth / rank |
| `forager` | +0.05 gather mult / rank |
| `green_thumb` | −1 growth_required / rank (min 10) |
| `shard_sight` | +1 manashards from shard nodes / rank |
| `keeper_stride` | +6% move speed / rank |

Ancient door ColorRect is **art-only / non-interactive** (Forge later).

## Run

```bash
/home/box/tools/godot/godot --path /workspace/tales-of-the-manaforge
```

## Headless verify

```bash
/home/box/tools/godot/godot --headless --path /workspace/tales-of-the-manaforge -s res://scripts/verify_headless.gd
```

Expect `VERIFY_OK` and exit code `0`.

## Windows export

Install Godot 4.3 export templates → Project → Export → **Windows Desktop** (`export_presets.cfg`). Output: `builds/tales-of-the-manaforge.exe`.

## Layout

```
scripts/autoload/   ContentStrings, GameAudio, GameState, SaveService
scripts/            keeper, manatree, gatherable, hud, main, verify_headless
scenes/             main + stubs
data/               manatree_stages.json, fruit_upgrades.json, strings_v01.json
docs/               copied day-1 briefs (reference)
assets/refs/        design refs only (not runtime sprites)
```

## Out of scope (v0.1)

Forge interact, combat, whisps, WASD, equipment, HTML5.
