# Puff companion art (2026-10-27)
Display name **Puff** (was Corvane filenames). Short mushroom folk ~66% Keeper height.

## Paths `assets/art/puff/`
| Asset | Path | Spec |
|---|---|---|
| Walk 4-dir | `anim/walk/<dir>/frame_0000..0007.png` | 128², **8 frames**, use Keeper `WALK_MS` |
| Idle 4-dir | `anim/idle/<dir>/puff_idle_<dir>_0001..0012.png` | 128², 12×~160 ms (promoted + fringe cleaned) |
| Battle idle | `battle_puff_idle.png` | 128² west |
| Portrait | `puff_portrait.png` / `_sheet.png` | 52² / 160² |

Sole row **123**, feet ≈ x 63.5, west = mirror of east. Magenta/pink key fringe removed.
Wire `companions.json` → portrait_path `res://assets/art/puff/puff_portrait.png`, walk_ref_speed ~70.
Walk is Imagine→nearest downscale; expect some silhouette grit vs hand-pixel Keeper.
