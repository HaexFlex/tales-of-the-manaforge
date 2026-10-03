# Keeper walk v5 (hybrid): S final + N; E pending a new video

Status (2026-10-03 13:21 CEST):
- **SOUTH: variant A (`walk_south/`, lift 55%) is the CHOSEN final front walk** (Haex).
  - Variant B (`variant_b_70/`, lift 70%) is kept for reference only.
- **NORTH: `walk_north/`** is built from walk_v3 north with the same movement rules. See the "North" section below.
- **EAST: not built.** The walk_v3 side source can't give a clean result (see "East"). A new Imagine video is specified there.
- **WEST:** will be E mirrored, once E exists.

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

# EAST: not built from v3 (new video needed)

**Why walk_v3 east can't be adjusted into this movement** (measured on `walk_v3_optA/walk_east`):
- **Arms:** a full horizontal forward reach.
  - On k1, k2, k5 and k6 the front fist is at x 99-100, chest height (rows 52-58). That is 27 px in front of the E still's body front (x 72-73), with the arm about 85 deg from vertical.
  - The back hand swings out to x 35-43.
  - South v5A arms stay about 15-20 deg from vertical. Getting there means removing and redrawing both arms and repainting the coat behind them in every stride frame. That is hand animation, not toning down, and blends between those poses don't read.
- **Legs:** the front leg is kicked out nearly horizontal: the forward foot's lowest row is 108-111 (12-15 px lift), with the boot at x 100-105.
  - A straight vertical drop like in S/N would fatten the horizontal leg. A shear could lower it, but the pose stays a kick.
  - The rear foot also kicks up (k3/k7, 6-9 px).
- **Torso:** leans forward in the stride frames, and the coat skirt flares, so an upright relaxed torso can't be swapped in at the waist without a visible step.

Shipping that would have been weak, so E and W are left for a new source.

**Requested Grok Imagine video (image-to-video, 6 s):**
- **Reference image:** `/workspace/keeper_idle/prompts8/attach/ref_e_optA_x5_magenta.png`. This is the Option A E still at x5 on magenta, the same family of refs used for `keeper_walkvid_side.mp4` and `keeper_walk_casual_front.mp4`.
- **Prompt:**
  > Side view, the character faces right. He walks in place on an invisible treadmill at a relaxed, casual pace, locked camera, no zoom, no pan; he stays in the same spot and size. Natural full strides with low feet: the front heel touches down, the back foot rolls off the toe; feet lift only slightly off the ground, knees bend gently - no marching, no high knees, no kicking the leg forward. Arms hang relaxed and swing loosely and gently close to the body, opposite to the legs (left arm forward when the right leg is forward), hands stay at or below the belt and never reach forward. Upright posture, head level and steady, hair and coat sway slightly. Keep the exact pixel-art style, colours, outfit and long green hair of the reference. Plain solid magenta background.
- **Plan with it:**
  - Upper body and arms from the new clip.
  - Legs from the new clip if its steps are straight and planted. Otherwise v3 east legs with a sheared 55% lift, composited like south.
  - Same timing, bob, head lock and checks. W = E mirrored.
