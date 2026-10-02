# Keeper harvest animations v2 (walk-matched experiment, not wired into the game)

v1 (`../keeper_harvest_anims/`, Imagine key poses) drifted in style. v2 is built from the live walk art instead.

## What the walk actually is (checked on main @ 25047b2)
- `assets/art/keeper/keeper_walk_south_0001..0009.png`, strip `keeper_walk_south.png` (1152x128). `keeper_meta.json`: `walk_south` has **9 frames at 100 ms**; `keeper.gd` builds SpriteFrames at fps = 1000/hold_ms with loop on. So it's a **9-frame, 900 ms loop**.
- 128x128 frames, feet anchor (64,128), `sprite.offset (-64,-128)`, nearest filter.
- The game frames are exactly `fit_keeper_128()` (tools/slice_haex_inbox.py) of the painted natives `native/keeper_walk_south_000N_256.png` (170x256): an NN x0.5 resize pasted with its own alpha as mask. I re-ran that on the native 0001 and got a pixel-identical match.
- Frame 0001 == `keeper_idle_south_0000`. Sole row 123. The edges are soft: 227-274 semi-transparent dark edge pixels per frame (a side effect of the paste-with-mask).

## Method
1. **Rig from the walk, not new art.** Native walk frame 0001 is cut into body and viewer-right sleeve+hand (`tools/rig.py`). The coat side under the sleeve is rebuilt by re-mapping the coat-skirt rows across the gap, with the skirt's own dark outline. A small "cape" patch is redrawn over the shoulder joint so the sleeve comes out from under the cape.
2. **Posing at native resolution (170x256).** The sleeve rotates about the shoulder with a RotSprite-lite (NN x4, rotate, sample back). The upper body bobs ±1 game px by shifting the rows above the waist. Head, hair, coat, legs and feet are the walk's own pixels; in each clip the head is pixel-identical to walk 0001 in every frame except where the tool overlaps it.
3. **One fixed tool sprite per tool** (`tools/tools_v2.py`): one stone axe and one stone pickaxe, drawn at native scale with walk greys/browns. Both have the same haft length (overall 42 game px, about 1/3 of the 122 px Keeper). The same sprite is rotated and pasted each frame, so tool size can't jump. No Imagine art is used anywhere in v2.
4. **Walk pipeline to game size.** The composed native frame goes through the exact `fit_keeper_128` method (NN x0.5, paste-with-mask), so the Keeper keeps the walk's scale, density and edge softness.
5. **Palette.** Every visible pixel is mapped to the nearest colour that occurs in walk frames 0001-0009 (the walk's own ~25k-colour set). Keeper pixels map to themselves; the tool, berry and FX snap to walk colours. The check script verifies 0 non-walk colours per frame.
6. **Clean alpha.** Fully transparent pixels are stored as (0,0,0,0). The walk leaves 28-47 transparent pixels with leftover RGB per frame; v2 leaves none. Semi-transparent pixels exist only in the 2 px silhouette edge band, like the walk's soft edge. Edge pixels the walk has 0-6 of further inside are made opaque.

## Clips (all south-facing, 9 frames x 100 ms = 900 ms, same as walk_south)
| clip | canvas / anchor | frames | strike frame |
|---|---|---|---|
| `chop_south` (tree on the right) | 192x128, feet (96,128) | ready, lift, raise, windup, cocked, swing, **impact**+chips, bite+chips, recover | 7 (600 ms) |
| `mine_south` (rock on the right, on the ground) | 192x128, feet (96,128) | ready, lift, raise, windup, cocked (pick behind head), swing, **impact**+sparks, rebound, recover | 7 (600 ms) |
| `pluck_south` (bush on the right) | 128x128, feet (64,128), same as the walk | ready, reach, reach, grab, grip, **pluck**+berry pop, bring, hold, stow | 6 (500 ms) |

- **Canvas:** chop and mine need 192 px of width because the extended axe or pick reaches x 175. The Keeper is still the walk's exact 128 frame, shifted 32 px right; the check confirms the legs are pixel-identical at that offset. Code would set `sprite.offset (-96,-128)` while those two clips play. Pluck fits in 128 px.
- **Pulse sync:** the tool harvest pulse is 1000 ms but the walk timing gives a 900 ms loop. Either restart the clip on each pulse (the last frame then holds about 100 ms longer), or play it at speed_scale 0.9. Both are recorded in each json; I kept 9 frames x 100 ms as requested.
- **East/west: not made.** The game has no side-view walk or idle art, and a convincing profile can't be rigged from a front-facing painting (the face, hair, coat and boots would all have to be repainted). Mirroring the south clips only gives "tree on the left" (flip_h), which is still south-facing. That's why there is no labelled attempt.

## Files
Per clip: `keeper_<clip>_0001..0009.png`, horizontal strip `keeper_<clip>.png`, `keeper_<clip>.json` (canvas, anchor, hold_ms, strike frame, pulse note), `keeper_<clip>.gif` (1x on hub grass next to the target) and `_x2.gif`.
`compare/compare_walk_vs_<clip>[_x2].gif` and `compare_walk_vs_all[_x2].gif`: live walk beside the clips, same scale, both 9 x 100 ms and frame-locked. Labelled at x2.
`contact_sheet.png` / `contact_sheet_x2.png`: walk row plus one row per clip, feet aligned, strike frame highlighted.
`alpha_check.md` / `.json`: per-frame results from `tools/check_frames.py`. `tools/` holds the build scripts (paths point at the art box).

## Alpha / frame check: 27/27 frames PASS
All frames are RGBA with a transparent border (no baked background, nothing clipped). There are 0 transparent pixels with leftover RGB, 0 semi pixels off the edge band, 0 magenta or light fringe pixels, and near-black semi pixels stay within the walk's own maximum (38). Every frame has 0 non-walk colours and sole row 123. Legs are 93.6-99.6% pixel-identical to walk 0001; it's under 100% only where the tool hangs over a boot. Semi-transparent edge pixels number 250-276 per frame (walk: 227-274).

## Honest verdict
- **Style match: good.** It is the walk's own painting at the walk's own scale, so silhouette, proportions, palette, softness and outline match by construction. There's no hair or coat flicker (head pixels identical every frame), and the tool is the same sprite in every frame.
- **Animation quality: stiff.** Only one arm moves. The legs and the other arm stay planted, and the body only bobs 1 px. The walk swings the coat and legs, so the harvest clips look stiffer than the walk next to it. A two-handed swing would need the other sleeve rigged too, plus some coat repainting.
- **Rig seams:**
  - At x2 you can see the rebuilt coat panel under the raised arm (slightly repetitive texture, one notch at hip level).
  - The rotated sleeve gets RotSprite jaggies at about 45°.
  - The shoulder joint is covered by the cape patch, but it's a little abrupt at the highest windup.
- **Tool art is cleaner and harder-edged than the painted Keeper.** Its colours are walk colours, but the shapes are crisp pixel art, not painterly.
- **Frame fit:**
  - The windup can't go higher than head height in a 128 px tall canvas; with the arm raised higher the axe would leave the frame. So the backswing is modest.
  - The pick's windup frame partly hides the pick behind the head.
  - The chop impact hits the trunk sideways at a diagonal; it reads at x1/x2 but isn't a real horizontal swing.
- **FX** (chips, sparks, berry pop, impact cross) are small 1 px clusters in walk colours. They read at x2 but are simple.
- **What would make it production-grade:** a painter doing the 3 strike/windup keys as paint-overs on top of these frames (especially the second arm and the coat swing), then rerunning `check_frames.py`. Or more time on the rig: rig the left arm, add a coat-skirt sway, and add a leg shift borrowed from walk frames 3 and 7.
