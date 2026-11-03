# CODE_NOTES — step 5 hole cleanup (no push)

Fill rule: enclosed transparent holes only (not exterior / design gaps open to the edge).
Components ≤8px always filled (incl. leftovers after large partial fills); larger only where a neighbour frame is opaque at same xy.
Fill colour: same pixel from nearest opaque neighbour frame, else nearest opaque neighbour in-frame. Hard alpha (255) on fills only; no other pixels touched.
Skipped: Puff idle/harvest/portraits (already shipped), walk_s (quality bar), Mossback (parked).

| clip | frames | holes before | holes after | px changed |
|---|---:|---:|---:|---:|
| `assets/art/companions/puff/battle_attack` | 8 | 233 | 22 | 211 |
| `assets/art/companions/puff/battle_hit` | 4 | 119 | 28 | 91 |
| `assets/art/companions/puff/work_brew` | 8 | 260 | 0 | 260 |
| `assets/art/companions/puff/walk_e` | 9 | 282 | 0 | 282 |
| `assets/art/companions/puff/walk_n` | 9 | 226 | 0 | 226 |
| `assets/art/companions/puff/walk_w` | 9 | 238 | 0 | 238 |
| `assets/art/elaia/anim/harvest/berries/east` | 8 | 10 | 0 | 10 |
| `assets/art/elaia/anim/harvest/berries/west` | 8 | 10 | 0 | 10 |
| `assets/art/elaia/anim/harvest/axe/east` | 9 | 390 | 162 | 228 |
| `assets/art/elaia/anim/harvest/axe/west` | 9 | 390 | 162 | 228 |
| `assets/art/elaia/anim/harvest/pickaxe/east` | 9 | 193 | 44 | 149 |
| `assets/art/elaia/anim/harvest/pickaxe/west` | 9 | 193 | 44 | 149 |
| `assets/art/battle/modular/elaia/attack` | 8 | 37 | 0 | 37 |
| `assets/art/battle/modular/elaia/cast` | 4 | 16 | 0 | 16 |
| `assets/art/battle/modular/elaia/hit` | 4 | 16 | 0 | 16 |
| `assets/art/battle/modular/keeper/attack` | 8 | 56 | 0 | 56 |
| `assets/art/battle/modular/keeper/attack_bow` | 10 | 101 | 0 | 101 |
| `assets/art/battle/modular/keeper/attack_wand` | 8 | 114 | 0 | 114 |
| `assets/art/battle/modular/keeper/hit` | 4 | 4 | 0 | 4 |

Total holes 2888 → 462; px changed 2426.
Remaining holes are enclosed regions transparent in every frame of the clip (kept as design gaps: arm/handle/leg pockets).
Staged under `05_holes_puff_clips_elaia_harvest/out/` (repo layout). No push.
