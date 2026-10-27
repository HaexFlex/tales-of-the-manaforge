# moss_tortoise companion (PLACEHOLDER) — 2026-10-27

Small slow tortoise with a moss garden + faint cyan mana glints on the shell. Warm bark / moss palette, Keeper–Elaia style language. Imagine → magenta key → nearest downscale. Hard alpha.

## Paths (assets/art/moss_tortoise/)
| Asset | Path | Size / frames |
|---|---|---|
| Walk S/N/E/W | `anim/walk/<dir>/frame_0000..0008.png` | 128×128, **9 × 100 ms** (briefed standard) |
| Idle breathe 4dir | `anim/idle/<dir>/moss_tortoise_idle_<dir>_0001..0012.png` | 128×128, 12 × ~160 ms (synthetic 1 px bob) |
| Battle idle | `battle_moss_tortoise_idle.png` | 128×128, west-facing |
| Portrait HUD | `moss_tortoise_portrait.png` | 52×52 |
| Portrait sheet | `moss_tortoise_portrait_sheet.png` | 160×160 |
| Still | `stills/moss_tortoise_still_south.png` | 128×128 |

## Anchor / scale
- Canvas 128×128, scale 1, nearest. Feet sole row **y=123**, feet centre ≈ x 63.5 (same as Keeper/Elaia).
- Godot offset: `(-64, -128)`. Content height ≈ 90–96 px (a bit under Keeper ~117).
- West walk/idle = exact mirror of east.

## Timing note
Brief asked 9×100 ms walk. Live Keeper/Elaia walk is **8 frames** with `WALK_MS = [120,125,130,125,…]`. Ship as 9×100 unless Code prefers `--keeper-timing` (then drop to 8 and retarget).

## Code hooks
- Add `moss_tortoise` to `data/companions.json` (portrait_path → `res://assets/art/moss_tortoise/moss_tortoise_portrait.png`, walk_ref_speed ~40–50 for a slow gait).
- Actor script can mirror Elaia/Keeper: load `anim/walk/<dir>` and `anim/idle/<dir>`.

## Quality (placeholder)
- Imagine grit: softer than hand-pixel Keeper/Elaia; some frame-to-frame silhouette wobble in walk strips.
- Idle breathe is a light synthetic bob, not a reshot Imagine settle.
- East/west side views are shorter (target_h 90) to keep the long shell readable; south/north use 96.


## Walk8 (live Keeper WALK_MS) — additive
Also at `anim/walk8/<dir>/frame_0000..0007.png` (8 frames).
Retimed from the 9×100 set by dropping the middle frame (indices 0,1,2,3,5,6,7,8).
Use with Keeper/Elaia `WALK_MS = [120,125,130,125,120,125,130,125]` (1000 ms loop).
Keep `anim/walk/` (9×100) until Code picks one.
