# Legacy move: fix pass native (2026-10-02)

Rule: move only files with zero live references (scripts, scenes, .tres, data/meta JSON, verify_headless.gd, scene_sanity.gd,
playtest/capture scripts, tools). `docs/`, `*.md` and `assets/library/` excluded.

## Moved

| old path | new path (replacement) | reason |
|---|---|---|
| `assets/art/props/runestones/runestone_might.png` | `assets/art/props/runestones/native/runestone_might.png` | Loose 32x32 file, not drawn by the game (it showed sheet cell (0,4), the code draws (0,0)). No reference. Native 64x64 replacement = the cell `runestone.gd` actually draws. |
| `assets/art/props/runestones/runestone_arcana.png` | `assets/art/props/runestones/native/runestone_arcana.png` | Loose 32x32 (already equal to code cell (2,5)). No reference. |
| `assets/art/props/runestones/runestone_resilience.png` | `assets/art/props/runestones/native/runestone_resilience.png` | Loose, different cell than the code's (3,3). No reference. |
| `assets/art/props/runestones/runestone_ward.png` | `assets/art/props/runestones/native/runestone_ward.png` | Loose, different cell than the code's (1,3). No reference. |
| `assets/art/props/runestones/runestone_vitality.png` | `assets/art/props/runestones/native/runestone_vitality.png` | Loose, different cell than the code's (3,5). No reference. |
| `assets/art/props/runestones/runestone_swiftness.png` | `assets/art/props/runestones/native/runestone_swiftness.png` | Loose, different cell than the code's (0,3). No reference. |
| `assets/art/props/runestones/runestone_fate.png` | `assets/art/props/runestones/native/runestone_fate.png` | Loose, different cell than the code's (2,3). No reference. |

## Move after swap (still referenced; move here once Code repoints)

| file | live references today | native replacement |
|---|---|---|
| `assets/art/props/harvest_stone.png` | `gatherable.gd:51`, `verify_headless.gd:164` (path) | `assets/art/props/native/harvest_stone.png` |
| `assets/art/props/harvest_stone_spent.png` | `main.tscn:29` ext_resource | `assets/art/props/native/harvest_stone_spent.png` |
| `assets/art/props/runestones/runestones_sheet.png` | `runestone.gd:17` | `assets/art/props/runestones/native/runestones_sheet.png` |
| `assets/art/ui/manaforge_hud_icons_sheet.png` | `hud_icons.gd:6`, `verify_headless.gd:168,1410,2061-2175`, `scene_sanity.gd:370` | single icons, see `assets/library/fix_pass_2026-10-02/CODE_NOTES.md` §4 |

## Swap back

`git mv assets/library/legacy/fix_pass_2026-10-02/props/runestones/runestone_<stat>.png assets/art/props/runestones/runestone_<stat>.png`
