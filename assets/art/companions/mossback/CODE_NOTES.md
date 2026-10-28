# Mossback (`mossback`) — locked companion layout

Root: `assets/art/companions/mossback/`
Pixels: scale 1, hard alpha, unchanged from source.
Anchor: Keeper feet — sole row **y=123** on 128×128 canvas, feet centre ≈ x 63.5. Godot sprite offset `(-64, -128)` (matches `scenes/companion.tscn`).

## Code expectation vs locked names

`scripts/companion.gd` loads from `anim.root` in `data/companions.json`:
- idle stills: `{root}/{rel}` (e.g. `idle_s.png`)
- clips: `{root}/{dir}/frame_%04d.png` starting at 0

Locked folder names use `walk_{s,n,e,w}/` and `idle_{s,n,e,w}.png` (not Elaia's `walk/south/` + `idle/south.png`).
When Code wires paths, set e.g. `anim.root = res://assets/art/companions/mossback` and clip `dir` = `walk_s` etc.
**This ship does not edit data/*.json** — art paths for puff/mossback remain empty until a Code follow-up.

## Files

| File | Frames | ms | Notes |
|---|---|---|---|
| `walk_s/frame_0000..0008.png` | 9 | 100 each | 128×128 RGBA |
| `walk_n/frame_0000..0008.png` | 9 | 100 each | 128×128 RGBA |
| `walk_e/frame_0000..0008.png` | 9 | 100 each | 128×128 RGBA |
| `walk_w/frame_0000..0008.png` | 9 | 100 each | 128×128 RGBA |
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

- `work_<mechanic>` (mechanic null; no work loop source) — ~2–3 Imagine runs when mechanic lands.
- ~~`battle_attack`, `battle_hit`~~ **SHIPPED** 2026-10-28.
- Animated idle loops (12f) + `walk8/` archived in legacy; locked walk uses 9×100 from source `anim/walk/`.

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


## Battle ship (2026-10-28)

West-facing like `battle_idle.png`. No mirroring.

| clip | frames | ms | hit_frame | source indices | runs | gate |
|---|---|---|---|---|---|---|
| battle_attack | 8 | 125 | 3 | 5,14,23,32,40,49,58,67 (try2) | 2 (try1 style-drift; try2 shipped) | PASS hist_mean=0.818 vs clean24; h=93; sole=123; clean |
| battle_hit | 4 | 100 | — | 3,17,31,45 (try1) | 1 | PASS hist_mean=0.731 vs clean24; h=93; sole=123; clean |

Note: raw battle_idle has ~3000 unique colours; identity hist gated vs median-cut clean24. Anchor sole y=123.
Contacts: `assets/library/companions_r7_2026-10-28/mossback_battle_contact_{1x,4x}.png`

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