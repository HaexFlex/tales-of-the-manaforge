# Weapon icon pass (2026-09-30): replaced files

Moved here with `git mv` (history kept). Sub-paths mirror `assets/art/`. To swap one back, `git mv` it to the
same sub-path under `assets/art/` (the new 32x32 file at that path has to move out first).

| legacy file | was | replaced by |
|---|---|---|
| `ui/icon_sapstaff.png` | 784x1168 opaque cream-box raw (drawn shrunk into the 32 px slot) | new 32x32 icon, transparent, at `assets/art/ui/icon_sapstaff.png` |
| `ui/icon_thornbow.png` | 784x1168 opaque cream-box raw | new 32x32 icon at `assets/art/ui/icon_thornbow.png` |
| `ui/icon_rootsteel_edge.png` | 784x1168 opaque cream-box raw | new 32x32 icon at `assets/art/ui/icon_rootsteel_edge.png` |
| `ui/icon_heartwand.png` | 784x1168 opaque cream-box raw (pink heart crystal) | new 32x32 icon (teal crystal) at `assets/art/ui/icon_heartwand.png` |
| `ui/icon_switchshaft.png` | 784x1168 opaque cream-box raw | new 32x32 icon at `assets/art/ui/icon_switchshaft.png` |
| — (not moved) | Stone Sword = cell 6 of `assets/art/ui/manaforge_hud_icons_sheet.png` | sheet left untouched; new standalone Flintblade icon `assets/art/ui/icon_stone_sword.png` (Code switches `hud_icons.gd` to it) |

Contact sheet: `assets/library/weapon_icons_2026-09-30/contact_weapons_wisp.png`.
Also added in the same pass (new, nothing replaced): `assets/art/wisps/wisp_portrait.png` (128x128 Wisp portrait for the HUD selection panel).
