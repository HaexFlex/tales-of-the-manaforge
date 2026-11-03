# Brewing station art (2026-10-27)
## Files
- `assets/art/props/brewing_stand.png` — Phase 0 stand, 64×80, feet on node origin (offset (-32,-80) if centered=false).
- `assets/art/fx/brewing/brew_bubbles_strip_24x32x6.png` (144×32) — 6 frames rising bubbles. Match `sfx_brew_bubble`: loop ~150 ms/frame (~0.9 s), emit while brewing.
- `assets/art/fx/brewing/brew_done_glint_strip_12x12x4.png` (48×12) — warm gold flash. Match `sfx_brew_done`: one-shot 80–100 ms/frame (~0.35 s).
- `assets/art/fx/brewing/wisp_work_spot_18x10.png` — cyan ring decal under the Wisp work pose.

## Offsets (from KeepersBench-style: node origin = stand feet, sprite top-left)
Stand sprite: offset (-32, -80) when `centered=false`, or (0,0) with centered=true and OFFSET=(-32,-80).
| Child | top-left (x,y) | notes |
|---|---|---|
| Bubbles | (-12, -72) | over cauldron mouth (~stand local 20,8) |
| Done glint | (-6, -76) | above cauldron, show on complete |
| Wisp work spot | (-9, -8) | just in front of stand feet; Wisp stands on it facing the stand |

Timings: bubbles loop while job active; glint plays once on done then hide; spot visible when a Wisp is assigned.
