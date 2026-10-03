# Keeper harvest – side view v3 (video route), Option A

Experiment only. **Not wired into the game.** Three right-facing (east) harvest loops, with west as an exact mirror. They were made the same way as walk_v3: Imagine image-to-video clips → frames → key → one clean cycle → native pixel frames.

| clip | frames | ms per frame | loop | impact / key frame | source frames (1-based, 24 fps) |
|---|---|---|---|---|---|
| harvest_axe_{east,west} | 9 | 140,70,60,**180**,90,90,90,90,90 | 900 ms | **3** (axe blade at ground) | 35,37,38,39,41,45,49,53,55 (t = 1.417 … 2.250 s) |
| harvest_pickaxe_{east,west} | 9 | 100,90,90,150,70,60,60,**180**,100 | 900 ms | **7** (tip at ground) | 40,43,47,50,54,57,59,61,64 (t = 1.625 … 2.625 s) |
| harvest_berries_{east,west} | 8 | 160,90,90,100,**160**,100,90,110 | 900 ms | **4** (pluck: hand closes at the bush; no berry pixels since v1b) | 66,71,75,79,82,86,93,99 (t = 2.708 … 4.083 s) |

Phases are listed per frame in each clip JSON (`phases`). `impact_frame` is a 0-based index into `files`. Per-frame durations are in `durations_ms`.

## v1b (2026-10-03): berries without berries
Haex's feedback: the movement is OK, but the red berry pixels made it look like he puts berries ON the bush instead of picking them. Every berry pixel is now removed from `harvest_berries_{east,west}`, including the berries in the pouch, so there is no red anywhere.
- **Motion, timing, frame choice, anchor and canvas are unchanged.** Axe and pickaxe frames are byte-for-byte unchanged (pixel diff 0).
- `build_harvest.deberry()`, applied after the head and pouch locks:
  - All berry_dark (132,10,10) and berry_red (186,14,12) pixels are found.
  - Each is filled from its 8 neighbours, working from the outside in. If it has more opaque than transparent neighbours, it takes the most common neighbour colour (glove/hand, pouch interior, coat). Otherwise it becomes transparent.
  - The berry cluster hanging on its stem below the hand in frame 4 (f82; box rows 62–67, x 133–141), and the berry tip under the fingers in frame 3 (f79; (62,136)), are cleared to transparent.
  - Light specks left in the pouch opening (berry highlights that had been mapped to browns) become the pouch-interior dark brown, so the pouch reads empty.
  - West is re-mirrored from east.
- Pixels changed per frame (east; west identical): 3, 12, 17, 17, 38, 12, 13, 14. Details are in `assembly.json` → `berries.deberry_v1b`.
- The berries palette is now **Option A 48 only** (`palette_berries.json`). The berry colours are gone from the berries meta, `palette_harvest_all.json` (51 = 48 + 3 iron) and `harvest_side_v3.json`. `palette_berry.json` is deleted. `source/extra_colors.json` keeps the original derivation for history.
- Check: 52/52 frames pass (alpha 0/255, transparent corners and border, no magenta or tint, 0 off-palette against the 48-colour palette). 0 berry-colour pixels and 0 saturated-red pixels remain in all 16 berries frames.
  - The 8 maroon (80,21,33) pixels per frame are the Option A hair/face outline colour (the still has 25). They sit in the locked head, rows 13–52, and are not berries.
- Frame 4 is now "the hand closes at the bush". The pluck reads only from the motion (reach, close the hand, retract to the pouch).

## Canvas / anchor
- **Canvas: 192×136 RGBA.** The 192×128 spec does not fit. At the matched body height of 119 px, the overhead axe and pickaxe frames reach row 2, which is 8 rows above a 128 canvas. 136 is the smallest even height that fits with a clear 1 px border.
  - Berries fits in 128 (its top row is 13). It is still delivered at 192×136 so all harvest clips share one canvas. Crop the top 8 rows if 192×128 is wanted.
- **Feet anchor:** bottom-centre of the planted feet is at pixel edge **(96, 132)**. Soles sit on **row 131**, keeping the same 4 px bottom margin as the 128 conventions. Feet x 84..107 is identical in every frame (planted). West mirrors x → 191−x, so the anchor is unchanged.
- **Body height:** the upright frames are 119 px from hair top to sole (Option A E still: 119; walk_v3 E: 117–119). Scale = 119/344 video px. The body crouches with the swing, as in the video: axe 109–119 px, pickaxe 105–121 px (121 in the raise frame, where the hair is stretched up). This is the action's body motion, not a resampled bob.
- Width use: x 54..161 east, 30..137 west. Nothing touches the edges.

## Pipeline (tools/)
1. `analyse_harvest.py`: key (ingest_turnaround.key), then isolate the figure: the largest component plus anything touching it within 4 px. This drops wood chips, debris and floating berries.
   - Per-frame metrics are in `source/metrics_*.json`: bbox, hair centroid, sole 395 constant, so there is no vertical drift.
   - Silhouette masks give the cycle and seam differences.
2. Cycle choice (seam = silhouette diff of the loop's last to first frame, compared with the mean adjacent-video-frame diff):
   - **Axe:** cycle f35→f57 (P = 22, 0.92 s): overhead → chop → impact f39 → recoil → lift → overhead. diff(35,57) = 176, versus 297 between adjacent video frames. The seam step 55→35 = 312, about one video-frame step.
   - **Pickaxe:** cycle f38→f64 (P = 26): diff(38,64) = 60, versus 393 adjacent. The seam step 64→40 = 419.
   - **Berries:** the natural cycle is ~58 frames (2.4 s) with a long idle, so only the active part is used: rest at the pouch → reach → pluck → retract → hand at pouch. The seam step 99→66 = 35 is near the adjacent-frame diff of 22. f102 ≈ f66 (diff 10.8).
3. `convert_harv.py`: one **fixed transform** per clip, with no per-frame recentring. The camera is locked and the feet are planted, so feet cannot slide and the scale cannot change.
   - Mapping: video x 344 → canvas x 96, video y 396 → canvas y 132, scale 119/344.
   - Downscale: premultiplied BOX (area), then hard alpha at ≥50%, despeck (<4 px), defringe.
   - Tool hue fix (axe/pickaxe only): Imagine motion blur tints the steel purple, teal or pale blue and the handle pink. Medium/bright purple and teal pixels, and blue with saturation between .2 and .62, become grey of the same lightness. Pink becomes wood brown.
   - Palette mapping (nearest Lab), then maroon below head+40 → dark brown (as in walk_v3).
   - Pickaxe: the small static rock (isolated in f48, dilated 3 px) is masked out of every frame before isolating the figure.
4. `build_harvest.py`: assembles the clips.
   - Drops islands <10 px.
   - Ground-zone clean for axe/pickaxe (x ≥ 113, rows ≥ 119, right of the feet): keeps only steel and its dark outline, nothing more than 1 px below the steel, and no chips (<25 px).
   - Hair-edge despill: blue key-spill pixels on the hair outline become hair outline (17,25,7).
   - Berries head lock (rows top..top+40 from f66; the body is static in that clip) and pouch lock in frames 1–6.
   - Also mirrors to west and writes meta and previews.
5. `check_frames_harv.py`: transparency and anchor check on every frame (see below). `extra_colors.py` derives the tool colours.

## Palette
Option A 48 colours (`palette_optionA_base48.json`) plus only these extras:
- **axe / pickaxe** (`palette_iron.json`, 51): iron_dark (100,105,108), iron_mid (143,151,155), iron_light (187,202,205).
- **berries** (`palette_berries.json`, 48): Option A only since v1b. The berry_dark (132,10,10) and berry_red (186,14,12) used in v1 were dropped.
- Wood: the existing Option A browns were enough, so no wood colour was added.
- `palette_harvest_all.json` holds the union (51).

## Transparency check (`alpha_check.md`)
**52/52 frames PASS.** Every frame:
- PNG mode RGBA with all four corners at alpha 0 and the whole border clear.
- Alpha strictly 0/255: 0 semi-transparent pixels, and alpha-0 pixels are (0,0,0,0).
- No magenta, no purple tint on the edges, no light fringe, 0 off-palette pixels (against the clip's palette).
- Soles on row 131; feet centre at x 96.0.

## Honest verdict
- **Axe:** reads clearly: a big overhead raise, a fast 2-frame swing, a held impact, recoil, then lift.
  - The impact lands low (blade at ground level / stump height), not at waist height on a tree trunk. That is what the clip does.
  - Loops well (overhead → overhead). The axe keeps its shape and colours. Some blur-frame cleanup was needed (f38/f50 handle and blade tints, fixed).
  - Hair shows slight per-frame shimmer, because the head moves and tilts with the lean so no head lock was used. It is on-model with walk_v3 E: same height, palette and outline style.
- **Pickaxe:** reads as an overhead strike. In the wind-up frames 3–4 the body turns slightly toward three-quarter back view (from the clip).
  - Impact (7) and recoil (8/0) look alike because the pick rests at the ground for about 380 ms. The impact accent is weaker than the axe's.
  - Rock removal also trims the bottom tip of the pick a little at impact.
  - Loops cleanly. The pick head shape varies slightly between frames (video), but colours are consistent after the hue fix.
- **Berries:** (v1 verdict; see v1b above for the berry removal) subtle but readable: reach to the right, berries visible in hand on the pluck frame, retract, hand to pouch.
  - The berries are only ~3–6 px and only frames 2–4 show red at the hand, so the pluck is small at 1×.
  - No flicker (head and pouch locked, the body is static). Loops seamlessly. On-model.

## Files
- `harvest_{axe,pickaxe,berries}_{east,west}/`: frames `harvest_<act>_<dir>_0000.png …` plus a clip meta JSON with frame_size, feet_anchor, durations_ms, impact_frame, phases, source frames/times and palette.
- `harvest_side_v3.json`: summary meta.
- `preview/`: per-clip strip (1×) and x3 GIF, `harvest_side_combined_east_x2.gif` (3 clips side by side, 900 ms common loop on a 20 ms grid), `harvest_side_contact.png` (E/W rows with the E still for reference). All previews are on a green backdrop; the frames themselves are transparent.
- `source/`: the 4 Imagine mp4s (all <1.7 MB; `keeper_harvest_pickaxe_original.mp4` is the unused alternate), metrics, convert logs and extra-colour derivation.
