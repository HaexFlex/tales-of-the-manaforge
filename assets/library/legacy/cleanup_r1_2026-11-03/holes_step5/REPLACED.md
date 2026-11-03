# REPLACED — interior hole fill (cleanup_r1 2026-11-03 step 5)

Archived pre-fill PNG frames (and matching `.import` where present) before overwriting live paths with enclosed-hole fills.

**Rule applied:** fill enclosed transparent holes only; components ≤8 px always; larger only where a neighbour frame is opaque at the same xy; fill colour from nearest opaque neighbour frame else nearest in-frame opaque neighbour; hard alpha on fills; no other pixels / dims / anchors / frame counts changed.

**Scope:** remaining Puff clips with holes (battle_*, work_brew, walk_e/n/w — skipped idle/harvest/portraits/walk_s), every Elaia harvest clip, audit-flagged modular Elaia/Keeper combat clips.

| Legacy tree (under this folder) | Was live path |
|---|---|
| `assets/art/battle/modular/elaia/attack/` | `assets/art/battle/modular/elaia/attack/` |
| `assets/art/battle/modular/elaia/cast/` | `assets/art/battle/modular/elaia/cast/` |
| `assets/art/battle/modular/elaia/hit/` | `assets/art/battle/modular/elaia/hit/` |
| `assets/art/battle/modular/keeper/attack/` | `assets/art/battle/modular/keeper/attack/` |
| `assets/art/battle/modular/keeper/attack_bow/` | `assets/art/battle/modular/keeper/attack_bow/` |
| `assets/art/battle/modular/keeper/attack_wand/` | `assets/art/battle/modular/keeper/attack_wand/` |
| `assets/art/battle/modular/keeper/hit/` | `assets/art/battle/modular/keeper/hit/` |
| `assets/art/companions/puff/battle_attack/` | `assets/art/companions/puff/battle_attack/` |
| `assets/art/companions/puff/battle_hit/` | `assets/art/companions/puff/battle_hit/` |
| `assets/art/companions/puff/walk_e/` | `assets/art/companions/puff/walk_e/` |
| `assets/art/companions/puff/walk_n/` | `assets/art/companions/puff/walk_n/` |
| `assets/art/companions/puff/walk_w/` | `assets/art/companions/puff/walk_w/` |
| `assets/art/companions/puff/work_brew/` | `assets/art/companions/puff/work_brew/` |
| `assets/art/elaia/anim/harvest/axe/east/` | `assets/art/elaia/anim/harvest/axe/east/` |
| `assets/art/elaia/anim/harvest/axe/west/` | `assets/art/elaia/anim/harvest/axe/west/` |
| `assets/art/elaia/anim/harvest/berries/east/` | `assets/art/elaia/anim/harvest/berries/east/` |
| `assets/art/elaia/anim/harvest/berries/west/` | `assets/art/elaia/anim/harvest/berries/west/` |
| `assets/art/elaia/anim/harvest/pickaxe/east/` | `assets/art/elaia/anim/harvest/pickaxe/east/` |
| `assets/art/elaia/anim/harvest/pickaxe/west/` | `assets/art/elaia/anim/harvest/pickaxe/west/` |

Replaced by filled frames from `05_holes_puff_clips_elaia_harvest/out/`. See `assets/library/cleanup_r1_2026-11-03/CODE_NOTES_holes_step5.md`.

Mossback walks (step 4) remain parked / not in this commit.
