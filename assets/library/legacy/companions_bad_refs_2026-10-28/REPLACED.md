# Bad companion refs replaced 2026-10-28

## Root cause
`battle_idle.png` and `idle_{s,n,e,w}.png` for both Puff and Mossback were already
corrupted on the source branches (`sprint/art-r5-puff`, `sprint/art-r5-companion`):
1000–3000 unique colours, noisy speckle, broken silhouettes. Commit `b1b6695`
(relayout into `companions/<id>/`) copied those bad files as-is; it did not introduce
the corruption. Same bad bytes live in `companions_relayout_2026-10-28/` archives.

Mossback locked `walk_*` (from source `anim/walk/`) is also noisy; clean tortoise
walk lives in legacy `anim/walk8/` (~36–41 colours). Puff `walk_*` was already clean (22 colours).

## Replacement
| Bad live path | New source |
|---|---|
| puff/battle_idle, idle_w | puff/walk_w/frame_0000 (Imagine walk9, west) |
| puff/idle_e | puff/walk_e/frame_0000 |
| puff/idle_s | puff/walk_s/frame_0000 |
| puff/idle_n | puff/walk_n/frame_0000 |
| mossback/battle_idle, idle_w | legacy moss_tortoise/anim/walk8/west/frame_0000 |
| mossback/idle_e | walk8/east/frame_0000 |
| mossback/idle_s | walk8/south/frame_0000 |
| mossback/idle_n | walk8/north/frame_0000 |

New refs: ≤64 colours, hard alpha, sole y=123. Mossback locked walk_* left unchanged (Haex keep).
