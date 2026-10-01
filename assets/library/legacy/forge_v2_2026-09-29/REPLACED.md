# Forge v2 art pass (2026-09-29): replaced / retired files

Moved here with `git mv` (history kept). Sub-paths mirror `assets/art/`. To swap one back, `git mv` it to the
same sub-path under `assets/art/`.

| legacy file | was | replaced by |
|---|---|---|
| `forge/forge_bark_chamber_bg.png` | PR #15 placeholder plate, 1168x784 (wells + fire pit) | new plate 1600x1200 at the same path |
| `forge/prop_{crucible,mill,anvil}_{idle,busy}.png` | PR #15 placeholders 588/580x784 | new 192x192 frames at the same paths |
| `forge/bench_{idle,busy}.png` | Pass B placeholders 96x112 | new 192x192 bench frames at the same paths |
| `forge/forge_stations_sheet.png`, `forge/prop_{crucible,mill,anvil}_sheet.png` | PR #15 sheets, unreferenced | retired (no replacement) |
| `ui/icon_sapsteel.png`, `ui/icon_heartwood_bits.png` | PR #15 placeholders 784x1168 opaque | new 32x32 icons at the same paths |
| `ui/forge_icons_sheet.png` | PR #15 icon sheet, unreferenced | retired (icons are single files now) |

Contact sheet: `assets/library/forge_v2_2026-09-29/contact_forge.png`. Art meta: `assets/art/forge/forge_meta.json`.
