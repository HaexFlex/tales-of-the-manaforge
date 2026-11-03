# cleanup_r1_2026-11-03 — Puff planted idle

Date: 2026-11-03 (Europe/Zurich). Worktree ref: origin/sprint/cleanup-r1 @ 8f3eed0 (read-only). **Not committed / not pushed.**

## Format (matches live loader)

`scripts/companion.gd` + `data/companions.json` load Puff idle as **single stills** via `_add_still`:

- `anim.root` = `res://assets/art/companions/puff`
- `anim.idle.south/north/east/west` → `idle_s.png` / `idle_n.png` / `idle_e.png` | 1 still | 100 hold | hand-painted from walk_e **frame_0001** (passing; span 32→planted) |
- `idle_hold_ms` = 100

Primary deliverables therefore replace those four stills. Optional breathe strips are additive (code does not load them yet).

## What changed

| Path | Frames | ms | Source |
|---|---|---|---|
| `assets/art/companions/puff/idle_s.png` | 1 still | 100 hold | videos/idle_south.mp4 frame **73** (1-based) |
| `assets/art/companions/puff/idle_n.png` | 1 still | 100 hold | videos/idle_north.mp4 frame **69** |
| `assets/art/companions/puff/idle_e.png` | 1 still | 100 hold | hand-painted from walk_e **frame_0001** (passing; span 32→planted) |
| `assets/art/companions/puff/idle_w.png` | 1 still | 100 hold | hand-painted from walk_w **frame_0008** (passing; not a mirror of e) |
| `assets/art/companions/puff/idle_{s,n,e,w}_strip/frame_0000..0011.png` | 12 | 100 each | breathe samples from same videos (optional) |

Pipeline: sample corner magenta → `animlib.key_magenta` + figure mask → hard alpha → nearest downscale (BOX stepwise + NEAREST) to walk frame0 bbox height → sole y=123, feet_x≈63.5 → Lab snap to that facing’s walk palette (22 colours) → despeck + fill interior holes ≤20 px → kill magenta.

Canvas 128×128, scale 1, nearest. Target heights: s=73, n=75, e=77, w=77 (walk frame 0).

## Legacy move (planned; not applied in live repo)

When shipping, move current live stills (which are byte-copies of `walk_{d}/frame_0000.png`) to:

`assets/library/legacy/cleanup_r1_2026-11-03/idle_{s,n,e,w}.png`

See `REPLACED.md` staged beside this plan under `out/`.

## Facing QA notes

- **South:** many Imagine frames still show a foot lift / march. Frame 73 is a settled both-feet plant; residual mild asymmetry may remain vs a perfect T-pose idle.
- **East:** side idle holds a slight forward lean / staggered feet (profile plant). Body colour after palette snap matches walk_e (hist overlap ~0.97).
- **West:** similar profile plant; body colour matches walk_w (~0.94).
- **North:** rear plant looks clean; basket on viewer-right.

Old `idle_*.png` were identical to `walk_*/frame_0000.png` (stride copies) — replaced here with planted sources.

## Hole policy

Walk frames already enclose a transparent **basket-handle** gap (n/e/w). Speck holes (area ≤8) are filled; the design handle gap is kept so identity matches walk.

## Palette / hist vs walk0

After Lab snap to each facing’s walk palette (22 colours, identical set): hist overlap {'s': 0.956, 'n': 0.94, 'e': 0.977, 'w': 0.942}.


## E/W planted fix (2026-11-03)

Walk_w is **not** a mirror of walk_e (no frame pair matches). Passing bases: walk_e f1 (foot span 32px), walk_w f8 (span 33px).
Hand-painted: delete lifted foot, clone planted foot column beside it under torso, soles on y=123, walk palette snap.
New spans: e=21px, w=17px (was video-idle stride ~constant 230+ src / prior out 36/31).
Magenta x8 Imagine refs: `01_puff_planted_idle/ref_planted_{e,w}_x8.png`.
