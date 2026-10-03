# Keeper harvest – side view v3 (video route), Option A

Clips: axe, pickaxe, berries (v1b: no berry pixels), water (watering can, added 2026-10-03; 208×136, see below).

Experiment only. **Not wired into the game.** Three right-facing (east) harvest loops, with west as an exact mirror. They were made the same way as walk_v3: Imagine image-to-video clips → frames → key → one clean cycle → native pixel frames.

| clip | frames | ms per frame | loop | impact / key frame | source frames (1-based, 24 fps) |
|---|---|---|---|---|---|
| harvest_axe_{east,west} | 9 | 140,70,60,**180**,90,90,90,90,90 | 900 ms | **3** (axe blade at ground) | 35,37,38,39,41,45,49,53,55 (t = 1.417 … 2.250 s) |
| harvest_pickaxe_{east,west} | 9 | 100,90,90,150,70,60,60,**180**,100 | 900 ms | **7** (tip at ground) | 40,43,47,50,54,57,59,61,64 (t = 1.625 … 2.625 s) |
| harvest_berries_{east,west} | 8 | 160,90,90,100,**160**,100,90,110 | 900 ms | **4** (pluck: hand closes at the bush; no berry pixels since v1b) | 66,71,75,79,82,86,93,99 (t = 2.708 … 4.083 s) |

Phases are listed per frame in each clip JSON (`phases`). `impact_frame` is a 0-based index into `files`. Per-frame durations are in `durations_ms`.

## Water (2026-10-03): watering the Manatree, side view
Source: `source/keeper_harvest_water.mp4`, a 6.04 s Imagine clip made from the Option A E still on magenta. He holds a wood/copper watering can, tilts it, a light-blue stream arcs down to the right, he holds, then tilts back.

| clip | frames | ms per frame | loop | key / pour | source frames (1-based, 24 fps) |
|---|---|---|---|---|---|
| harvest_water_{east,west} | 10 | 170,100,90,90,110,**250**,**250**,100,90,100 | 1350 ms | pour_start **2**, stream at ground **4–6** (held 110+250+250 ms), pour_end **7**, impact_frame (main pour) **5** | 113,123,129,133,137,59,75,91,95,101 (t = 4.667, 5.083, 5.333, 5.500, 5.667, 2.417, 3.083, 3.750, 3.917, 4.167 s) |

Phases: rest (can level) → tilt → stream leaves the spout → stream arcs → stream reaches the ground → pour hold A → pour hold B → tilt back, stream detaches → tail falling → last drops land.

**Cycle.** In f1–25 the whole figure turns and slides 38 video px to the left (an Imagine drift), so those frames are not used. From f25 on the feet stay planted (feet band x 272..339).
- Pour 2 matches pour 1: f139 ≈ f59 (silhouette diff 70, versus 100 between adjacent frames during the pour). So the loop is pour 1 hold → stop → rest → tilt → pour 2 start, then back to pour 1 hold.
- The seam f137 → f59 is a body diff of about 13 on the 168×112 mask, against 3.4 between adjacent frames.

**Loop length.** 1350 ms = 1.5× the 900 ms harvest loops, which keeps the combined preview short (LCM 2700 ms).

**Canvas: 208×136**, feet anchor **(104, 132)**, soles on row 131.
- The stream lands 102 px right of the feet, which does not fit in 192 (it would need x ≥ 198). 208 is the smallest width that keeps the feet horizontally centred (needed for the W mirror) and leaves the 1 px border clear: the stream reaches x 206 east, x 1 west.
- Because the feet are centred and the height is the same 136, a centred sprite lines up with the 192×136 clips.
- Body height 119 (Option A E still).

**Pipeline.** `tools/convert_water.py` uses the same fixed transform as convert_harv, with this clip's feet at video x 306 and the 208 canvas.
- Water-aware isolate: the figure plus free stream dashes.
- Ground splash removed: below video y 372, only the stream's own column range (±4 px) is kept.
- Water pixels (blue/cyan right of the hand) map only to the 3 water tones; everything else maps to Option A.
- `build_harvest.water_clean`:
  - Stream clipped at the ground (row ≤ 131). At rows ≥ 127, only water inside the stream's own columns is kept, so there is no splash pool.
  - Water drops < 3 px and body islands < 10 px are dropped.
  - Lone water-coloured pixels inside the sleeve or can become the neighbouring colour.
- Head lock from the rest frame f113 against hair shimmer: rows 13–24 x ≤ 136 and rows 25–43 x ≤ 113. The tilted can never enters this zone. Pixels replaced per frame: 0, 121, 153, 171, 159, 242, 210, 192, 181, 162 (mostly hair-spike shimmer).
- West = mirror x → 207 − x.

**Palette** (`palette_water.json`, 51): Option A 48 + water_dark (44,118,214), water_mid (64,196,240), water_light (150,240,252).
- The water tones are set from the stream's lightness percentiles. k-means gave a magenta-blended periwinkle (100,117,218), which was rejected.
- **No can colours added:** the wood/copper/iron-band can maps cleanly onto the Option A browns, golds and greys.
- The stream is solid, hard-alpha pixels.

**Check:** 20/20 water frames pass (72/72 for the whole folder): RGBA, corners and border transparent, alpha 0/255 only, no magenta or tint, 0 off-palette, soles row 131, feet x 104.0. Axe, pickaxe and berries frames are unchanged from b21e8e3 (pixel diff 0).

**Verdict.** Reads clearly as watering: lift and tilt, a glowing stream arcs to the ground on the right and holds, then he tilts back with a trailing tail. Loops cleanly. Can shape and colours stay consistent. No visible flicker after the head lock (the body is static in this part of the clip). On-model.
- The stream is an Imagine 3-strand band, so at 1× it reads as a light-blue ribbon with small gaps.
- The last frame's drops (3–6 px specks) can look like stray pixels at 1×.
- The stream lands about 100 px in front of the feet, so the Manatree trunk has to stand there.

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
- `palette_harvest_all.json` holds the union (54 = 48 + 3 iron + 3 water).

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
- `preview/`: per-clip strip (1×) and x3 GIF, `harvest_side_combined_east_x2.gif` (all 4 clips side by side: axe, pickaxe, berries, water; 2700 ms common timeline = LCM of 900/1350 on a 20 ms grid), `harvest_side_contact.png` (E/W rows for all 4 clips with the E still for reference, feet-centred cells). All previews are on a green backdrop; the frames themselves are transparent.
- `source/`: the 4 Imagine mp4s (all <1.7 MB; `keeper_harvest_pickaxe_original.mp4` is the unused alternate), metrics, convert logs and extra-colour derivation.
