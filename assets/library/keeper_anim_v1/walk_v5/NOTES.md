# Keeper walk v5 (hybrid): all 4 directions (S final, N, E, W)

Status (2026-10-03 13:31 CEST): all four directions are built and pass the checks (walk mode 32/32, extra checks all OK).
- **SOUTH: variant A (`walk_south/`, lift 55%) is the CHOSEN final front walk** (Haex).
  - Variant B (`variant_b_70/`, lift 70%) is kept for reference only.
- **NORTH: `walk_north/`** is built from walk_v3 north with the same movement rules. See the "North" section below.
- **EAST: `walk_east/`** is built from the new casual side clip `source/keeper_walk_casual_east.mp4`, using its own legs and arms. See "East (v5)" below.
- **WEST: `walk_west/`** is an exact horizontal mirror of E (x -> 127 - x).
- Previews: `previews/walk_v5_directions_S_N_E_W_x3.gif` (S|N|E|W), `walk_v5_E_W_x3.gif`, `walk_v5_S_N_E_W_contact_x2.png`, `east_legs_clip_vs_v5.png`.
  - `walk_v5_directions_S_N_E_x3.gif` is superseded (its E column is the old v3 march placeholder).

Movement rules for every direction:
- Relaxed, loose arm swing, opposite to the legs.
- Straight up-and-down steps (no foot arc).
- Foot lift at about 55% of v3.
- 8 frames, 120/125/130/125/120/125/130/125 ms (1000 ms loop).
- Bob 0-2 px following the leg phase.
- Head locked; soles on row 123.

# SOUTH (v4 casual upper body + v3 march legs with lower lift)

Not wired into the game. `walk_v3_optA` and `walk_v4_casual` are unchanged.

Haex's feedback on v4 was that the upper body and arms are very good, but the feet move in a curve (heel peel and slide arc). He preferred v3's steps: almost the same leg movement, with a little less knee and foot lift.

Variants:
- **`walk_south/` = variant A:** lift at 55% of v3. This is the requested 50-60%.
- **`variant_b_70/walk_south/` = variant B:** lift at 70%.

## Pairing: arms opposite the legs
v5 frame j = v4 frame j (upper body) + v3 frame j (legs).

The pairing is the identity, and that is what puts the arms opposite the legs. The forward arm was identified from the v4 source video: an arm swinging toward the camera shows a bigger, higher glove; the back arm hides behind the coat. Glove area is in video px (`measurements.json`).

| v5 j | arms (v4) | his R glove / his L glove | forward arm | legs (v3) |
|---|---|---|---|---|
| 0 | k0 f36 | 177 / 434 | L | k0: his R foot planting forward |
| 1 | k1 f40 | 323 / 354 | crossing | k1: his L knee starting up |
| 2 | k2 f44 | 463 / 316 | R | k2: his L knee up |
| 3 | k3 f48 | 458 / 269 | R | k3: his L knee up |
| 4 | k4 f52 | 453 / 207 | R | k4: his L foot planting forward |
| 5 | k5 f56 | 351 / 320 | crossing | k5: his R knee starting up |
| 6 | k6 f60 | 308 / 367 | L | k6: his R knee up |
| 7 | k7 f64 | 301 / 471 | L | k7: his R knee up |

The right arm is forward across j2-j4 while the left leg is forward; the left arm across j6-j0 with the right leg. Shifting by one frame (v3 j+1) moved the arm peak half a frame away from the leg peak.

**Timing (ms):** 120, 125, 130, 125, 120, 125, 130, 125 = 1000. The foot plants are shortest, the knee peaks (k2/k6) longest.

**Bob:** the legs drive it, using v3's bob (0, 2, 1, 1, 0, 2, 1, 1). The v4 upper layer is shifted rigidly by -2..+1 px to match; inside the frame it is pixel-identical to v4.

## Build (`tools/build_v5.py`)
1. **L0, v3 legs:**
   - Leg-colour pixels in rows 78 and below, connected to the boots.
   - Holes and notches are closed, and boot highlights are kept.
   - Coat-blue key spill on boot edges below row 105 becomes the darkest brown.
2. **Lift compression** for the lifted leg (its columns are detected per frame):
   - The bottom 12 rows of the boot are kept rigid (shape intact) and moved down by (1 - factor) x lift.
   - The rows between the knee row (about 84-89, under the coat hem) and the boot are stretched by nearest-row duplication. Nothing gaps, and the motion stays purely vertical, keeping v3's straight up-and-down step with no arc.
   - The planted foot stays on row 123.
3. **L1, v4 frame minus v4's own legs:** the same leg mask, closed. It is shifted for the bob.
4. **Layering:**
   - L1 (coat, shirt, belt, hands) is drawn over L0.
   - Exception: inside the leg zone (between the coat's inner gold trims, rows 84-123) the legs are drawn over the coat lining. The trim and shirt stay in front.
   - The shirt hem simply covers the top of the v3 trousers. v3's hips sit about 2 px higher than v4's, so there is no gap and no horizontal cut line anywhere.
5. **Clean-up:**
   - New 1-4 px pinholes in the leg area are filled with the neighbour colour; v4's own arm-to-coat gaps stay open.
   - Exactly 1 component per frame.
   - The real gaps between the legs stay open.

## Foot lift (game px above the ground line; knee-lift frames v3 k1, k2, k3, k5, k6, k7)

| | per frame | max | mean | vs v3 |
|---|---|---|---|---|
| v3 march | 10, 16, 16, 11, 18, 15 | 18 | 14.3 | 100% |
| **v5A (55%)** | **6, 9, 9, 6, 10, 8** | **10** | **8.0** | **56%** |
| v5B (70%) | 7, 11, 11, 8, 13, 10 | 13 | 10.0 | 70% |
| v4 casual | rear heel peel only, peaks 8 / 7 | 8 | - | different motion |

## Checks (A and B identical results)

**`alpha_check.md` (walk mode): 8/8 PASS.**
- RGBA 128x128, border clear.
- 0 semi-transparent px, 0 RGB under alpha 0.
- 0 magenta, 0 tint, 0 fringe, 0 non-palette colours.
- Soles on row 123.
- Loop feet mean within 2 px of 63.5; head-x range at most 1.5 px.

**`extra_check.json`: all OK.**
- 1 component per frame.
- Heights 117-119; bob 0-2 (0, 2, 1, 1, 0, 2, 1, 1).
- 120-130 ms per frame, 1000 ms loop.
- Loop seam change within the in-cycle steps.
- Upper body rows 0-83: 0 px different from v4 (shifted). This excludes v4's own trouser pixels in rows 78-83, which are replaced by design.
- Head rows identical across frames.
- 0 new pinholes.

## Verdict
- **Seam:** invisible at 1x and 3x. There is no cut line; the shirt hem and coat flaps overlap the v3 legs like clothing.
- **Legs:** read like v3 (straight knee-up steps, foot plants), but lower. The lifted boot hangs 6-10 px above the ground instead of 10-18.
- **Arms:** opposite the legs, per the table.
- **Caveats:**
  - The v3 foot-plant frames (j0, j4) keep v3's dark, slightly blobby forward foot.
  - j1 has a 1-2 px dark stub beside the lifted boot at the coat edge.
  - Bob is now 2 px on the knee-up frames (v3 rhythm), while the arms keep v4's relaxed swing.

# NORTH (`walk_north/`)

**Source:** `walk_v3_optA/walk_north`, the video-derived back cycle (`keeper_walkvid_back.mp4` f16, 18, 20, 24, 26, 30, 32, 36). v3 phases are kept: k0/k4 contacts, k2/k6 lift peaks. Bob 0, 1, 2, 1, 0, 1, 2, 1 comes from v3 (high at the lift peaks).

**Arms:**
- **Phase:** the v3 back arms are already opposite the legs. Checked in the source video by visible glove area (the arm swinging back toward the camera shows a bigger glove):
  - His right glove (screen right) peaks at f22-f26 (354-359 px) while his right foot lifts (f18-f20) and plants (f24). His right arm is back while his right leg is forward.
  - His left glove peaks at f36/f14 (246-260 px), around his left foot's lift (f30-f32) and plant (f36).
- **Amplitude:** about the same as south v5A. Outer silhouette x across rows 70-97:
  - N: left 33-42, right 84-93 (travel 9 px).
  - S v5A: left 34-40, right 87-94 (travel 6-7 px).
  - S v3 march: left 27-39, right 89-100 (11-12 px).
- No arm redraw was needed.

**Lift (`tools/lift.py`, `tools/build_north.py`):**
- The lifted boot's columns were read off zoomed frames (k1, k2, k3 his right; k5, k6, k7 his left).
- Below the coat hem only, the boot's bottom block (10 rows or fewer) moves straight down by round(lift x 0.45). Rows between the hem and the boot are stretched; where the boot sits right under the hem, the top visible row repeats.
- The coat stays in front, untouched. Purely vertical, so there is no arc.

| frame | k1 | k2 | k3 | k5 | k6 | k7 |
|---|---|---|---|---|---|---|
| v3 lift px | 9 | 14 | 4 | 10 | 12 | 4 |
| **v5 N lift px** | **5** | **8** | **2** | **6** | **7** | **2** |

Main lifts (k1, k2, k5, k6): mean 11.25 -> 6.5 px (58%), max 14 -> 8. N's v3 steps were already lower than S's, so the N boots end up 5-8 px off the ground versus S v5A's 6-10.

**Head lock:**
- The top 34 rows come from k0. The video redraws the hair, about 500 px per frame otherwise.
- Rows 34-47 are also locked inside the hair's x-span (50-76), where the hair hangs over the collar.
- Shoulders and arms are not locked.

**Checks:** walk mode 16/16 PASS for N and S (`alpha_check.md`).
- RGBA, border clear, hard alpha, no magenta/tint/fringe, palette only, soles on row 123, loop feet within 2 px of 63.5, head-x stable.
- `walk_north/extra_check.json`: 1 component, heights 118-120 (N still 120), bob 0-2, ms 120-130 / 1000, loop seam within steps, head rows identical.

**Verdict:**
- Reads as the same walk as S v5A seen from behind: low alternating boot lifts, arms swinging loosely opposite the legs.
- **Weak spots:**
  - The k2/k6 lifted boots sit right under the coat hem, so their extra length repeats the top boot row. They read as a slightly blocky boot shaft at 3x; fine at 1x.
  - The arms travel a little more than S (9 vs 6-7 px).
  - Below the locked hair rows, the shoulders still carry the video's redraw texture.

# EAST (v5) from the casual side clip, WEST = mirror

**Source check** (`source/keeper_walk_casual_east.mp4`, 672x448, 6.04 s, 145 frames, i2v from the Option A E still on magenta):
- Locked camera: head x constant (336-337 video px), soles steady at rows 391-395, no zoom or pan, no props or extra objects.
- Exact loop: period 24 video frames (1.0 s), 12 unique poses each held for 2 frames. Lag-24 mask diff is about 7 px (noise); lag-12 is about 70 px (the other leg).
- Relaxed side walk: arms hang close to the body, no marching, low steps, upright, on-model. The clip's legs are clean and planted, so **they are used directly** (no v3 fallback).

**Build** (`tools/build_east.py`, `tools/legfix.py`; video -> 128 px with `tools/convert_video.py`: scale 0.3439, fixed anchor_x 59.98, defringe, Option A palette, soles on row 123):
- **Cycle frames:** video f48(=f24), f28, f30, f34 | f36, f40, f42, f46, sampled every 3 video frames. Each half is the other step (lag 12).
  - k0/k4 passing, k1/k5 reach, k2/k6 heel contact, k3/k7 rear boot swinging up.
  - 12 unique poses -> 8 frames means the pose gaps alternate 2/1 (4/2 video frames).
- **Bob:** per-step 0/1/2/1 (passing high, contact low) via `fit_top` (only rows below the hip stretch). The clip's own bob was a once-per-cycle 0..3 px.
- **Head + mane lock:** top 34 rows from k0. Also locked: the long mane's hair pixels in rows top+34..top+56, x 42-60 (the mane hangs down the back).
- **Boots:** video key spill cleaned (sparse blue, green and olive pixels under the hem -> neighbour median, re-snapped to the palette).
- **Leg edits** (all vertical, coat always in front):
  - k2 contact heel put down 2 px (it hovered at 121).
  - k6 rear toe put down 1 px.
  - Swing/reach boots raised: k3 +4, k5 +2, k7 +2. In the clip they skimmed the ground at 1-3 px.
- **Stance re-timing:** in the two passing frames k0/k4, only the legs (rows >= 107, under the hem) are moved 2 px back. Body and coat are not touched.
  - Why: the 4/2 sampling with near-even timing made the planted boot travel 7 px then 13 px.
- MS 120/125/130/125/120/125/130/125 (1000 ms). 128x128, hard alpha, Option A 48 colours, soles on row 123.

**Measurements** (`walk_east/measure.txt`):
- **Foot lift** (lowest row of the moving boot vs row 123):
  - Clip as sampled: k1 5, k3 1, k5 3, k7 3. The contact heel hovered 2 px; at passing (k0/k4) the swing toe touched down behind the stance boot.
  - v5: k1 5, k3 5, k5 5, k7 5. Contact frames k2/k6 have both feet on 123. Passing k0/k4: the swing boot is tucked behind the stance boot (0).
  - That puts it at the low end of the requested 5-10 range: lower than N (5-8 peaks) and S v5A, which suits the casual side gait.
- **Planted boot (toe x)** moves straight back on row 123, no forward slip:
  - Boot B: k7 82 -> k0 72 -> k1 62 -> k2 54.
  - Boot A: k2 94 (heel strike) -> k3 83 -> k4 74 -> k5 63 -> k6 54.
  - Per frame: 10, 8, 11, 9, 11, 9, 11, 10 px = **79 px per loop**.
  - **Suggested move speed about 80 px/s at 1x** (128-px sprite, 1000 ms loop). Scale it with the sprite scale.
  - At 80 px/s the planted boot's ground-relative wobble stays at 1.6 px or less during stance.
- **Feet centre** over the loop: 63.2 (E), 63.8 (W). **Bob:** 0-2 px. **Height:** 117-119 (still 119).
- **Arms:** the near arm is forward in k0-k3 (reach/contact of boot A) and back in k4-k7, where the far hand shows in front (k5/k6). That gives one arm cycle per two steps, in antiphase with the steps.
  - The clip draws both legs identically (same colours; the stance boot is always drawn in front), so no leg cue contradicts "arm opposite leg".

**Checks:**
- `check_frames.py` walk mode: 32/32 PASS (S, N, E, W).
  - Covers RGBA 128x128, clear border, zero-RGB alpha, no semi-alpha, no magenta/purple/light fringe, palette-only, sole row 123, feet centred.
- `check_extra_dir.py walk_east 119` / `walk_west 119`: all OK.
  - Covers one component, height 116-119, bob <= 2, 100-130 ms, 1000 ms loop, seam within step sizes, head rows identical.

**Verdict:**
- A real relaxed walk: upright, loose close arm swing, low planted steps, clean silhouette. It matches the S v5A/N rhythm in the 4-direction preview.
- The best of the walk sources so far, because legs and arms come from one coherent motion (no compositing seam).

**Weak spots:**
- **Raised boots:** the k3/k7 swing boots were lifted by script (k3 by 4 px), so the shin between hem and boot is shorter. At 3x the k3 boot reads a little blocky and tucked under the hem; it's fine at 1x.
- **Sampling:** the pose spacing alternates 2/1 unique poses. With the requested even timing, the passing frames would hit slightly late; the 2 px leg shift fixes the foot travel, not the pose timing. Uneven timing (about 160/85 ms) would be smoother but changes the requested rhythm.
- **Passing frames:** the swing boot hides behind the stance boot, so the step reads as low at mid-swing.
- **West mirror:** the coat closure and the near/far arm swap sides; that's normal for a mirrored side walk.

**Tools:** `tools/build_east.py`, `legfix.py`, `export_east.py`, `measure_east.py`, `convert_video.py`, `period.py`, `analyse_video.py`, `zoomlegs.py`, `strip.py`.
**Source:** `source/keeper_walk_casual_east.mp4`, `source/build_east.json`, `source/convert_east.json`.

## History: why E was not built from walk_v3

**Why walk_v3 east can't be adjusted into this movement** (measured on `walk_v3_optA/walk_east`):
- **Arms:** a full horizontal forward reach.
  - On k1, k2, k5 and k6 the front fist is at x 99-100, chest height (rows 52-58). That is 27 px in front of the E still's body front (x 72-73), with the arm about 85 deg from vertical.
  - The back hand swings out to x 35-43.
  - South v5A arms stay about 15-20 deg from vertical. Getting there means removing and redrawing both arms and repainting the coat behind them in every stride frame. That is hand animation, not toning down, and blends between those poses don't read.
- **Legs:** the front leg is kicked out nearly horizontal: the forward foot's lowest row is 108-111 (12-15 px lift), with the boot at x 100-105.
  - A straight vertical drop like in S/N would fatten the horizontal leg. A shear could lower it, but the pose stays a kick.
  - The rear foot also kicks up (k3/k7, 6-9 px).
- **Torso:** leans forward in the stride frames, and the coat skirt flares, so an upright relaxed torso can't be swapped in at the waist without a visible step.

Shipping that would have been weak, so E and W waited for a new source (now `keeper_walk_casual_east.mp4`, prompt below).

**Requested Grok Imagine video (image-to-video, 6 s):**
- **Reference image:** `/workspace/keeper_idle/prompts8/attach/ref_e_optA_x5_magenta.png`. This is the Option A E still at x5 on magenta, the same family of refs used for `keeper_walkvid_side.mp4` and `keeper_walk_casual_front.mp4`.
- **Prompt:**
  > Side view, the character faces right. He walks in place on an invisible treadmill at a relaxed, casual pace, locked camera, no zoom, no pan; he stays in the same spot and size. Natural full strides with low feet: the front heel touches down, the back foot rolls off the toe; feet lift only slightly off the ground, knees bend gently - no marching, no high knees, no kicking the leg forward. Arms hang relaxed and swing loosely and gently close to the body, opposite to the legs (left arm forward when the right leg is forward), hands stay at or below the belt and never reach forward. Upright posture, head level and steady, hair and coat sway slightly. Keep the exact pixel-art style, colours, outfit and long green hair of the reference. Plain solid magenta background.
- **Plan with it:**
  - Upper body and arms from the new clip.
  - Legs from the new clip if its steps are straight and planted. Otherwise v3 east legs with a sheared 55% lift, composited like south.
  - Same timing, bob, head lock and checks. W = E mirrored.
