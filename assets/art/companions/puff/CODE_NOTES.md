# Puff (`puff`) — locked companion layout

Root: `assets/art/companions/puff/`
Pixels: scale 1, hard alpha, unchanged from source.
Anchor: Keeper feet — sole row **y=123** on 128×128 canvas, feet centre ≈ x 63.5. Godot sprite offset `(-64, -128)` (matches `scenes/companion.tscn`).

## Code expectation vs locked names

`scripts/companion.gd` loads from `anim.root` in `data/companions.json`:
- idle stills: `{root}/{rel}` (e.g. `idle_s.png`)
- clips: `{root}/{dir}/frame_%04d.png` starting at 0

Locked folder names use `walk_{s,n,e,w}/` and `idle_{s,n,e,w}.png` (not Elaia's `walk/south/` + `idle/south.png`).
When Code wires paths, set e.g. `anim.root = res://assets/art/companions/puff` and clip `dir` = `walk_s` etc.
**This ship does not edit data/*.json** — art paths for puff/mossback remain empty until a Code follow-up.

## Files

| File | Frames | ms | Notes |
|---|---|---|---|
| `walk_s/frame_0000..0008.png` | 9 | 100 each | 128×128 RGBA; Imagine try1 |
| `walk_n/frame_0000..0008.png` | 9 | 100 each | 128×128 RGBA; Imagine try1 |
| `walk_e/frame_0000..0008.png` | 9 | 100 each | 128×128 RGBA; Imagine try1 |
| `walk_w/frame_0000..0008.png` | 9 | 100 each | 128×128 RGBA; Imagine try1 |
| `idle_s.png` | 1 still | 100 hold | 128×128; from source idle/still |
| `idle_n.png` | 1 still | 100 hold | 128×128; from source idle/still |
| `idle_e.png` | 1 still | 100 hold | 128×128; from source idle/still |
| `idle_w.png` | 1 still | 100 hold | 128×128; from source idle/still |
| `battle_idle.png` | 1 | — | 128×128 west-facing |
| `battle_attack/frame_0000..0007.png` | 8 | 125 each | west; hit_frame=3; Imagine try2 |
| `battle_hit/frame_0000..0003.png` | 4 | 100 each | west; Imagine try1 |
| `portrait_52.png` | 1 | — | 52×52 HUD |
| `portrait_160.png` | 1 | — | 160×160 sheet |

## Missing (no existing source)

- ~~`walk_*` 9th frame~~ **SHIPPED** 2026-10-28: 9×100 ms from Imagine treadmill videos (try1 each dir). Old 8f → `assets/library/legacy/puff_walk8_2026-10-28/`.
  Source indices (1-based ffmpeg): s `[4,15,26,37,48,59,70,81,92]`; n/e/w `[7,17,28,38,48,58,68,79,89]`. Anchor sole y=123, feet_x≈63.5.
- `work_brew` (sheet_traits includes brew; mechanic null) — ~2–3 Imagine runs.
- ~~`battle_attack`, `battle_hit`~~ **SHIPPED** 2026-10-28.
- Animated idle loops (12f) exist in legacy; locked idle is still-only per `companion.gd` `_add_still`.

## Inventory

- `battle_idle.png` — 128×128 RGBA
- `idle_e.png` — 128×128 RGBA
- `idle_n.png` — 128×128 RGBA
- `idle_s.png` — 128×128 RGBA
- `idle_w.png` — 128×128 RGBA
- `portrait_160.png` — 160×160 RGBA
- `portrait_52.png` — 52×52 RGBA
- `walk_e/frame_0000.png` — 128×128 RGBA
- `walk_e/frame_0001.png` — 128×128 RGBA
- `walk_e/frame_0002.png` — 128×128 RGBA
- `walk_e/frame_0003.png` — 128×128 RGBA
- `walk_e/frame_0004.png` — 128×128 RGBA
- `walk_e/frame_0005.png` — 128×128 RGBA
- `walk_e/frame_0006.png` — 128×128 RGBA
- `walk_e/frame_0007.png` — 128×128 RGBA
- `walk_e/frame_0008.png` — 128×128 RGBA
- `walk_n/frame_0000.png` — 128×128 RGBA
- `walk_n/frame_0001.png` — 128×128 RGBA
- `walk_n/frame_0002.png` — 128×128 RGBA
- `walk_n/frame_0003.png` — 128×128 RGBA
- `walk_n/frame_0004.png` — 128×128 RGBA
- `walk_n/frame_0005.png` — 128×128 RGBA
- `walk_n/frame_0006.png` — 128×128 RGBA
- `walk_n/frame_0007.png` — 128×128 RGBA
- `walk_n/frame_0008.png` — 128×128 RGBA
- `walk_s/frame_0000.png` — 128×128 RGBA
- `walk_s/frame_0001.png` — 128×128 RGBA
- `walk_s/frame_0002.png` — 128×128 RGBA
- `walk_s/frame_0003.png` — 128×128 RGBA
- `walk_s/frame_0004.png` — 128×128 RGBA
- `walk_s/frame_0005.png` — 128×128 RGBA
- `walk_s/frame_0006.png` — 128×128 RGBA
- `walk_s/frame_0007.png` — 128×128 RGBA
- `walk_s/frame_0008.png` — 128×128 RGBA
- `walk_w/frame_0000.png` — 128×128 RGBA
- `walk_w/frame_0001.png` — 128×128 RGBA
- `walk_w/frame_0002.png` — 128×128 RGBA
- `walk_w/frame_0003.png` — 128×128 RGBA
- `walk_w/frame_0004.png` — 128×128 RGBA
- `walk_w/frame_0005.png` — 128×128 RGBA
- `walk_w/frame_0006.png` — 128×128 RGBA
- `walk_w/frame_0007.png` — 128×128 RGBA
- `walk_w/frame_0008.png` — 128×128 RGBA

## Walk 9×100 ship (2026-10-28)

| dir | frames | ms | source indices (ffmpeg 1-based) | runs | gate hist mean | sole | h |
|---|---|---|---|---|---|---|---|
| walk_s | 9 | 100 | 4,15,26,37,48,59,70,81,92 | 1 | 0.901 | 123 | 73 |
| walk_n | 9 | 100 | 7,17,28,38,48,58,68,79,89 | 1 | 0.932 | 123 | 75 |
| walk_e | 9 | 100 | 7,17,28,38,48,58,68,79,89 | 1 | 0.939 | 123 | 77 |
| walk_w | 9 | 100 | 7,17,28,38,48,58,68,79,89 | 1 | 0.940 | 123 | 77 |

Contacts: `assets/library/companions_r7_2026-10-28/puff_walk9_contact_{1x,4x}.png`


## Battle ship (2026-10-28)

West-facing like `battle_idle.png`. No mirroring.

| clip | frames | ms | hit_frame | source indices (ffmpeg 1-based) | runs | gate |
|---|---|---|---|---|---|---|
| battle_attack | 8 | 125 | 3 | 1,7,22,43,46,49,55,61 (try2) | 2 (try1 wrong identity discarded) | PASS hist_mean=0.568 vs clean24(battle_idle); h=77; sole=123; clean |
| battle_hit | 4 | 100 | — | 3,17,31,45 (try1) | 1 | PASS hist_mean=0.518 vs clean24; h=77; sole=123; clean |

Note: raw `battle_idle.png` has 1000+ unique colours; identity hist gated against median-cut clean24 of the same sprite (silhouette/pose unchanged). Anchor sole y=123, feet_x≈63.5.
Contacts: `assets/library/companions_r7_2026-10-28/puff_battle_contact_{1x,4x}.png`

- `battle_attack/frame_0000.png` — 128×128 RGBA
- `battle_attack/frame_0001.png` — 128×128 RGBA
- `battle_attack/frame_0002.png` — 128×128 RGBA
- `battle_attack/frame_0003.png` — 128×128 RGBA
- `battle_attack/frame_0004.png` — 128×128 RGBA
- `battle_attack/frame_0005.png` — 128×128 RGBA
- `battle_attack/frame_0006.png` — 128×128 RGBA
- `battle_attack/frame_0007.png` — 128×128 RGBA
- `battle_hit/frame_0000.png` — 128×128 RGBA
- `battle_hit/frame_0001.png` — 128×128 RGBA
- `battle_hit/frame_0002.png` — 128×128 RGBA
- `battle_hit/frame_0003.png` — 128×128 RGBA