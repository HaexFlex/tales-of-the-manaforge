# Keeper idle, 4 directions: v2 (live hair + smaller back rune)

**Status:** experiment only. Not wired into the game; the live Keeper art in `assets/art/keeper/` is untouched.
v1 (commit e3dff07) stays unchanged one folder up. This folder is self-contained.

**Haex feedback on v1:**
> I really liked the hair on the old one. The glyph on the back is a bit too big, 30% smaller would look better. Rest is fine.

**Changes in v2, all from the same Imagine sheet (cand A3, FH8sM.png):**
1. The live Keeper's hair on all 4 directions.
2. The north rune shrunk to ~70 %.

Everything else follows v1:
- Body, coat and design.
- 12 frames x 150 ms and the same motion tables.
- Shared 48-colour palette built the same way.
- 128x128, anchor (64,128), sole row 123, hard alpha.
- The same check, with all 48/48 frames passing.

## Files
| path | content |
|---|---|
| `idle_<south/north/east/west>/` | 12 frames each, strip, meta json, `.gif` (x1), `_x2.gif` |
| `keeper_idle_4dir_v2_compare.gif` / `_x2.gif` | live idle_south, v1 S, v2 S, N, E, W, in sync (x2 labelled with frame numbers) |
| `keeper_idle_4dir.gif` / `_x2.gif` | live idle_south + v2 S, N, E, W |
| `contact_sheet.png` / `_x2.png` | rows S, N, E, W, frames 1-12, live idle_south in column 1 |
| `v1_vs_v2_x3.png` | live S, v1 S, v2 S, v1 N, v2 N, v1 E, v2 E (frame 1, x3) |
| `palette.json` / `palette.png` | the v2 shared palette (48) |
| `alpha_check.md` / `.json` | per-frame check |
| `source/keys_cand_A3v2/` | the S/N/E keys before palette and animation; `source/eyes_A3v2.json` = hand-set blink boxes |
| `tools/` | `build_v2.sh` (one command reproduces the keys and frames byte-identically), `hair_s.py`, `hair_n.py`, `hair_e.py`, `rune_n.py`, `fill_holes.py`, `clean_temple.py`, `stray_green.py`, `make_combined.py`, plus the shared `ingest_turnaround.py` (`--height` added), `build_idles.py`, `check_frames.py` |

## 1. Hair
**Source:** the live `assets/art/keeper/keeper_idle_south_0000.png`, i.e. exactly the in-game pixels of the native painted idle. The hair is never redrawn or resampled: every hair pixel in v2 is a live hair pixel or a live hair colour.

**Scale:** the live face matches the new face almost exactly (eye spacing 11.5 px live vs 12 px v1). The live hair, however, is ~5 px taller above the eyes than the v1 hair (v1: head + hair 37 px wide, live 42 px).
- Transplanting it 1:1 onto the v1 body would make him ~127 px tall, which clips the 128 frame and breaks the 122 px rule.
- So the same sheet was re-ingested with a **shared scale 5 % smaller** (S body 116 px instead of 122).
- The new face is now exactly the live face size (eye spacing 11.4 px). The live hair sits on it 1:1 and the total height is back to 122 px (live 122).
- Side effect: the body/coat is 5 % smaller than v1 (coat hem 43 px wide vs 45 in v1 and 51 live). Head + hair is now 42 px wide, the same as live.

**S (front):** live hair transplanted pixel-exact.
- The hair mask is the green hair components connected to the crown, plus the dark/olive outline pixels around them. Eyes, skin, coat and trim are excluded.
- The v1 hair was removed and the live hair placed by eye alignment (dx +1, dy -1).
- Forehead pinholes left where the v1 bangs were are filled from the nearest skin.

**N (back):** the live hair has no back painting at this scale. The back ref (`refs/keeper_back.png`) has a much smaller, rounder head; scaled to match it would be blurry and not the liked silhouette.
- **Silhouette and outer spikes:** the live S hair layer mirrored about the head axis (x' = 127 - x; seen from behind, the sweep flips side). Brow/ear/skin pixels picked up with the S hair are dropped.
- **Back of head** (the S layer's face opening): filled by continuing the strands already in the hair downward.
  - Each column starts from the colour of the live hair pixel just above the opening (the bangs point down, so they become back-of-head strands).
  - The strands darken toward the nape, with irregular darker separations and jagged strand tips at the nape.
  - The dark bang-tip outline that bordered the opening is refilled so no "mask" edge shows.
  - Only live hair-ramp colours are used.

**E (profile, facing right):** no live side view exists, so the profile is **cut from the live hair itself**.
- The live S hair layer is placed with its head axis at x 61, a few px in front of the profile ear (x 57). Its left half (spikes pointing sideways) becomes the back of the head; its right half (side spikes and bangs) becomes the top/front.
- Hair that would cover the face (below the brow line, in front of x 62, and around the eye) is cut away.
- The part of the face opening behind the ear is filled with the same strand method as N.
- The A3 key's own hair is removed; temple pinholes and brow remnants are recoloured to nearest skin.
- This held up well enough that no extra Imagine side-view generation was needed.

**W:** every derived E frame mirrored, exactly as in v1.

**In motion:** the hair is identical from frame to frame apart from the existing animation: the head's 1 px breathing rise and the spike-tip sway (±1 px).

## 2. North rune at ~70 %
| | core diamond incl. outer bright line (bbox) | size |
|---|---|---|
| v1 | x 51-77, y 47-83 | **27 x 37 px** |
| v2 | x 55-73, y 53-77 | **19 x 25 px** (70 % x 68 %) |

The centre is the same (64, 65).

**Method** (`tools/rune_n.py`, mode `axis`):
1. Mask = cyan + white core, the light-blue glow halo, and the dark rim around it. This is 520 px, all of which is repainted.
2. **Coat repaint:** harmonic fill (4-neighbour diffusion) from the surrounding coat-blue pixels only. Trim, shoulder pads, arms and outline are never sampled or touched, and the old rune's dark diamond shadow is gone.
3. **Rune redrawn at 0.7** about the same centre using its own colours:
   - each pixel at normalised diamond distance u takes the colour the original has at the same u along its horizontal profile, so the rings are clean (glow → bright outer line → dark gap → inner ring → bright fill);
   - the inner star/core (u < 0.36) is sampled nearest from the original.
4. Rejected attempts (in `tools/rune_n.py` as other modes):
   - plain LANCZOS shrink: blurred into a blob;
   - nearest-neighbour shrink: dotted outer line;
   - "brightest pixel" pooling: lost the rings;
   - supersampled averaging: flat.

## 3. Palette
- The material-aware k-means palette from v1 is rebuilt from the 3 new keys (W = mirror of E), at 48 colours.
- It now contains the live hair ramp. Hair colour error vs the keys is mean ΔE 4.1-4.3, p95 ~8.
- I tried 56 colours (mean ΔE 3.5-4.0). The gain was invisible at x1/x2, so it stayed at 48.

Colours: `#032704 #032967 #03337b #040b1a #051636 #051d49 #060d26 #06400a #07340c #084697 #086890 #095613 #0a1a07 #0a620e #0c4fa8 #120a04 #1764b8 #187412 #1eccd5 #251208 #265084 #2b7dd2 #2e8b19 #351a0c #4196e7 #48220d #485a74 #48a31b #533925 #5d5e65 #613118 #635122 #69be1f #753818 #78fcfa #8f4c1f #8f7054 #ab5a1d #b0c079 #b3e646 #bd7741 #d8822e #dd9058 #e8f6f4 #eb9a44 #f0aa72 #f2d9c2 #f9c28c`

## 4. Frame / alpha check
**48/48 PASS** (full per-frame table in `alpha_check.md`).

| clip | pass | semi px | alpha-0 with RGB | magenta (edge/any) | purple tint edge | light fringe | non-palette | sole row | feet x | height |
|---|---|---|---|---|---|---|---|---|---|---|
| idle_south | 12/12 | 0 | 0 | 0/0 | 0 | 0 | 0 | 123 | 64.0 | 122-123 |
| idle_north | 12/12 | 0 | 0 | 0/0 | 0 | 0 | 0 | 123 | 63.5 | 122-123 |
| idle_east | 12/12 | 0 | 0 | 0/0 | 0 | 0 | 0 | 123 | 63.0 | 122-123 |
| idle_west | 12/12 | 0 | 0 | 0/0 | 0 | 0 | 0 | 123 | 64.0 | 122-123 |

Hard 0/255 alpha, no baked background, no fringe. Live is 122 px tall (soles on row 123, feet at x 63.5).

## 5. Self-review (x1 and x2, against the live idle_south)
- **S: good, the main win.** The hair is the live hair, pixel for pixel: same spikes, same silhouette and same colours. At x1 the head reads like the live Keeper on the slimmer v2 body. The blink reads; no seams.
- **N: good at x1, OK at x2.**
  - The outline and spikes are the live hair mirrored, so S → N turns read as the same head. The rune at 70 % sits better on the back and no longer dominates.
  - At x2 the back-of-head fill is visibly a set of vertical strands (slightly "combed") and a little darker than the crown. It is less painterly than the live crown above it.
- **E/W: acceptable, the weakest of the four.**
  - The silhouette and colours are clearly the live hair, and the profile face stays clean.
  - The head reads a bit top-heavy / "mushroom", because the front-view spikes are reused as profile spikes: forward spikes reach ~10 px past the nose and the back volume is ~19 px behind the ear.
  - The back-of-head strip behind the ear has the same combed look as N.
  - It is a believable spiky-hair profile, not a painted one. If Haex wants it closer to a hand-drawn profile, the next step would be one Imagine side-view generation with the live hair attached (prompt below), keyed and checked the same way.
- **Body:** 5 % smaller than v1, so that the live hair fits at 1:1 inside the 122 px height.

### If E/W need a painted profile later (not run; would need a computerUse dispatch)
- **Attach:**
  - `source/keys_cand_A3v2/key_S.png` and `key_N.png` (v2 front/back with the live hair; upscale x4 nearest on magenta);
  - `prompts/attach/ref_keeper_front_x3_magenta.png` from v1.
- **Prompt:**
  > Side view (facing right) of the attached character, full body, standing idle, on a flat solid magenta #FF00FF background. Keep EXACTLY the attached hair: big spiky bright-green hair, same spikes, same volume and the same colours as the attached front and back views, seen from the side (spikes sweep back, a few bangs point forward over the forehead). Same blue long coat with gold trim, green tunic, brown boots, same proportions and scale as the attached views. Soft painted pixel art, soft dark outline, top-left light. No pink or magenta on the character, no shadow, no text.

## Phase 2 (walk) plan
Unchanged from v1 `NOTES.md`. The walk would be derived from these v2 keys, so the live hair carries over automatically.
