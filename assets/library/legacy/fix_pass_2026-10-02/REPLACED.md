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
| `assets/art/props/harvest_stone.png` | `assets/library/legacy/fix_pass_2026-10-02/props/harvest_stone.png` → replaced by `assets/art/props/native/harvest_stone.png` | 46x48 file shown at `HARVEST_SCALE.stone = 2.0`. Code repointed `gatherable.gd:51` and `verify_headless.gd:164` to the native file (moved 2026-10-02, after Code merged art/fix-pass-native into fix/waypoint-pass @ dd12793). |
| `assets/art/props/harvest_stone_spent.png` | `assets/library/legacy/fix_pass_2026-10-02/props/harvest_stone_spent.png` → replaced by `assets/art/props/native/harvest_stone_spent.png` | 64x64 spent state. `main.tscn:29` ext_resource now points at the native file. |
| `assets/art/props/runestones/runestones_sheet.png` | `assets/library/legacy/fix_pass_2026-10-02/props/runestones/runestones_sheet.png` → replaced by `assets/art/props/runestones/native/runestones_sheet.png` | 256x256 atlas, 32 px cells. `runestone.gd:17` `RUNE_SHEET` now loads the 512x512 native sheet (64 px cells). |
| `assets/art/ui/manaforge_hud_icons_sheet.png` | `assets/library/legacy/fix_pass_2026-10-02/ui/manaforge_hud_icons_sheet.png` → replaced by the single icons (`assets/library/fix_pass_2026-10-02/CODE_NOTES.md` §4) | HUD icon atlas. `hud_icons.gd`, `verify_headless.gd` and `scene_sanity.gd` no longer read it. |

Moved 2026-10-02 (second batch, on fix/waypoint-pass). Before each move the old path was searched with `rg` across the repo,
excluding `assets/library/legacy/`, `docs/` and the `*.md` notes. Results:
- No script, scene, `.tres`, VERIFY or SANITY reference remains. `scene_sanity.gd:236` / `verify_headless.gd:2072` only check `ends_with("harvest_stone.png")` on the *native* texture path.
- Stale strings remain only in files that no game code reads:
  - `assets/art/props/props_meta.json:29-30` and `assets/art/props/harvest_nodes_meta.json:19-20` (old `harvest_stone.png` / `harvest_stone_spent.png` entries; provenance meta, not loaded by any script);
  - the one-shot build scripts `assets/library/fix_pass_2026-10-02/build/build_fix_pass_misc.py:8,39` and `contact_fix_pass.py:28,43`, which read the old sheets by path. To re-run them, point them at this folder.

## Swap back

`git mv assets/library/legacy/fix_pass_2026-10-02/<sub-path> assets/art/<sub-path>` (sub-paths `props/…`, `props/runestones/…`, `ui/…` mirror `assets/art/`). Swapping back the four second-batch files also needs Code to revert the repoints listed above.


`git mv assets/library/legacy/fix_pass_2026-10-02/props/runestones/runestone_<stat>.png assets/art/props/runestones/runestone_<stat>.png`
