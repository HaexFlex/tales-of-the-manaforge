# Keeper walk v5 HYBRID (south): v4 casual upper body + v3 march legs with lower lift; 8 frames, 1000 ms

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
