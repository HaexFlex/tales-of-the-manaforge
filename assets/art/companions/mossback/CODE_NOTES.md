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
| `battle_attack/frame_0000..0007.png` | 8 | 125 each | west; hit_frame=3; **canvas 152×128** native h=90 |
| `battle_hit/frame_0000..0003.png` | 4 | 100 each | west; **canvas 128×128** native h=90 |
| `portrait_52.png` | 1 | — | 52×52 HUD |
| `portrait_160.png` | 1 | — | 160×160 sheet |
| `work_stone/frame_0000..0007.png` | 8 | 100 each | east; **canvas 146×128** native h=90 |

## Missing (no existing source)

- ~~`work_stone`~~ **SHIPPED** 2026-10-28 (stone gathering body motion).
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

## Work ship — work_stone (2026-10-28)

Side view (east, like `idle_e.png`). Body motion only (head/front-feet nudge loop).

| clip | frames | ms | source indices | runs | gate |
|---|---|---|---|---|---|
| work_stone | 8 | 100 | 7,19,30,42,54,66,77,89 | 1 | PASS hist_mean=0.858 vs clean24(idle_e); h≈90; sole=123; clean |

Contacts: `assets/library/companions_r7_2026-10-28/mossback_work_stone_contact_{1x,4x}.png`

- `work_stone/frame_0000.png` — 128×128 RGBA
- `work_stone/frame_0001.png` — 128×128 RGBA
- `work_stone/frame_0002.png` — 128×128 RGBA
- `work_stone/frame_0003.png` — 128×128 RGBA
- `work_stone/frame_0004.png` — 128×128 RGBA
- `work_stone/frame_0005.png` — 128×128 RGBA
- `work_stone/frame_0006.png` — 128×128 RGBA
- `work_stone/frame_0007.png` — 128×128 RGBA

## Clean refs restore (2026-10-28 true-size fix)

Root cause: `battle_idle` / `idle_*` were already noisy (1000–3000 colours) on art-r5 source branches; `b1b6695` copied them. Bad copies → `assets/library/legacy/companions_bad_refs_2026-10-28/`.
New refs derived from legacy `moss_tortoise/anim/walk8/{dir}/frame_0000` (≤40 colours). Locked `walk_*` unchanged.


## True-size fix (2026-10-28)

battle_attack/hit/work_stone true-size fix 2026-10-28: gated vs clean walk8-derived battle_idle/idle_e. See legacy/companions_bad_clips_2026-10-28/.


## Native-scale refs (2026-10-28, replaces 9defc7c 0.78 shrink)

Non-integer scale forbidden. Restored legacy `walk8` **1:1** onto 128×128:
- `battle_idle` / `idle_w`: walk8 west — h=90, sole=123, 40 colours, bbox x 3–116
- `idle_e`: walk8 east — h=90, sole=123, 40 colours, bbox x 11–124
- `idle_s`/`idle_n`: walk8 south/north — h=96

Canvas remains **128×128** for stills (fits native walk8 with ≥1px margin).
Clip animations may use a wider canvas if motion overhangs; see clip CODE_NOTES.
Scaled-078 refs → `assets/library/legacy/companions_scaled078_2026-10-28/`.


## Native-scale clips (2026-10-28, replaces 0.78 + mid-clip flip)

**Rule:** finished Mossback art never uses non-integer scale. Body stays walk-native **h=90**, sole **y=123**, feet centre x. If motion overhangs 128, **widen canvas** (never shrink the sprite).

| clip | canvas | facing (every frame) | hist mean (vs walk) | min hist | colours | gate |
|---|---|---|---|---|---|---|
| battle_attack | **152×128** | WEST ×8 | 0.862 | 0.832 | ≤40 | PASS |
| battle_hit | **128×128** | WEST ×4 | 0.904 | 0.872 | ≤40 | PASS |
| work_stone | **146×128** | EAST ×8 | 0.852 | 0.820 | ≤40 | PASS |

Per-frame facing gate: extremity (neck-band left_ext vs right_ext) vs walk_w / walk_e frame 0; auto-flip before place if wrong.

**Code:** stills stay 128×128 → offset `(-64, -128)`. Wider clips keep feet near canvas centre — use offset `(-canvas_w/2, -128)` (attack −76, work_stone −73). Replaced 0.78/flip clips → `assets/library/legacy/companions_scaled078_clips_2026-10-28/`.
Contacts: `assets/library/companions_r7_2026-10-28/mossback_{battle_attack,battle_hit,work_stone}_contact_{1x,4x}.png` and `/workspace/sprint_art/previews/`.

