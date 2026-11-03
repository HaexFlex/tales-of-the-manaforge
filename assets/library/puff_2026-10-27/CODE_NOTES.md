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


## Walk from Imagine video (2026-10-27) — replace
Source: `/workspace/combat_imagine/walks/puff_{south,north,east}.mp4` (6 s treadmill on hot-pink; west = mirror of east).
Corner-sampled plate key, RGB tol **58**, hard alpha 0/255. Nearest downscale after BOX chain. Sole row 123, feet ≈ x 63.5. Palette-snapped to live Puff + Keeper/Elaia outline language.

**Source frame indices** (0-based, 145-frame extract @ 24 fps; period 24 = 1.00 s):
| dir | indices |
|---|---|
| south | 97, 100, 103, 106, 109, 112, 115, 118 |
| north | 116, 119, 122, 125, 128, 131, 134, 137 |
| east | 115, 118, 121, 124, 127, 130, 133, 136 |
| west | mirror of east |

Plate RGB (corner median): S ≈ (232,8,130), N ≈ (241,5,131), E ≈ (246,10,218).
Legacy v1 sheets moved to `assets/library/legacy/puff_walk_imagine_v1_2026-10-27/`.
Timing: Keeper `WALK_MS` 8 frames / 1000 ms. Magenta leftover: **0**.
