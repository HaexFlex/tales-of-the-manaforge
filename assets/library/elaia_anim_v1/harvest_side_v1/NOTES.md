# Elaia harvest – side view v1 (video route)

Experiment only, **not wired into the game**. Built to the Keeper harvest_side_v3 conventions. Each clip ships as east, with west as an exact mirror (x -> W-1-x). Elaia palette, hard alpha, no key.

| clip | frames | ms per frame | loop | key frame | source frames (1-based, 24 fps) |
|---|---|---|---|---|---|
| harvest_axe_{east,west} | 9 | 140,70,60,**180**,90,90,90,90,90 | 900 | impact **3** (blade low, stump height, row 116) | 45,55,57,61,65,67,71,75,49 of elaia_harvest_axe_retry.mp4 |
| harvest_pickaxe_{east,west} | 9 | 100,90,90,150,70,60,60,**180**,100 | 900 | impact **7** (tip in the ground) | 89,94,101,105,110,117,121,125,133 |
| harvest_berries_{east,west} | 8 | 160,90,90,100,**160**,100,90,110 | 900 | pluck **4** (hand closes at the bush) | 65,9,33,39,43,47,51,57 |
| harvest_water_{east,west} | 10 | 170,100,90,90,110,**250**,**250**,100,90,100 | 1350 | pour_start 1, stream at ground 4-6, pour_end 7, impact 5 | 19,20,21,23,25,45,65,79,79(+f83 tail),79(+f87 drops) |

Phases are listed per frame in each clip JSON.

## Canvas / anchor
- Axe, pickaxe, berries: **192x136**, feet anchor **(96,132)**, soles on row 131.
- Water: **208x136**, feet anchor **(104,132)**.
- Body height: one fixed transform per clip, scale 115/334 (the Elaia E still is 115 px; standing height in these clips is 334 video px).
  - Upright frames are 115 px (berries top row 17).
  - Overhead frames reach row 6 (axe) and row 4 (pickaxe).
- Feet are planted (fixed transform, no per-frame recentring). Measured feet edge-centre:
  - Axe: 96.0-96.5.
  - Pickaxe: 96.0.
  - Berries: 95.0-96.0.
  - Water: 104.0.

## Sources and cleanup
- **Axe:** uses `elaia_harvest_axe_retry.mp4`. The non-retry clip (tree trunk) was not needed.
  - Window f41-f83: she widens her stance at f37-41, then the feet stay planted.
  - f51-54 are skipped because the axe touches the video top. After f85 she turns toward the camera (unused).
  - Axe frames f45/f49 are snapped down 1 px (their video sole is 2 px higher).
  - The chop lands at stump height (blade lowest row 116, 15 px above the soles), not on the ground. That is what the clip does.
- **Pickaxe:** the clip spawns rocks/debris at each impact.
  - f125 (impact): the rock under the tip (169 px) is removed, and the buried tip is redrawn as a 4-row point continuing the blade (rows 122-125).
  - f133: the loose rock (58 px) is removed.
  - In the crouch the robe slit showed a bare thigh (65 px), recoloured to the inner-robe blues (as in walk v1 E).
  - The raise frames f95-98 and f111-116 reach the video top and are not used.
- **Berries:** Imagine put a dark berry in her hand at the start of the reach (f7-f29), and berry bunches in the pouch/hand after f73.
  - Only f9-f65 are used. The berry in f9's fingers is removed (26 px).
  - The used pouch frames contain no berries, and there is 0 red anywhere (the palette has no red).
  - Head lock: head rows from f65 are pasted per frame at the best-matching offset (dx 0..5, IoU >= 0.95) because she leans into the reach.
- **Water:** her rear foot steps back as she tilts (f14-21) and returns as she tilts back (f79-89). The loop stays in the pour stance.
  - Legs are locked: rows 113+ (hem + boots), x < 124, from f45 in every frame.
  - Head lock rows 0-34 (x 60-112) from f45.
  - k0 = f19 with the first drip removed (tilt). k8/k9 = f79's body with the falling tail of f83 / last drops of f87 (the can holds its tilt-back).
  - Stream pixels (right of the robe/can, below the spout) map only to 3 water tones; everything else maps to the Elaia palette.
  - The whole frame is shifted (-1, +1) so the f45 boots sit on row 131 at x 104. The stream is clipped at row 131.

## Palette
- `palette_elaia40.json`: Elaia 40, used by axe, pickaxe and berries.
- `palette_water.json`: Elaia 40 + water_dark (44,118,214), water_mid (64,196,240), water_light (150,240,252) (same tones as Keeper water).
- Axe/pickaxe steel and handles map cleanly onto the Elaia greys and browns, so no iron extras were needed.

## Checks (`alpha_check.json`, `tools/check_harv.py`): **72/72 PASS**
- RGBA, size, alpha 0/255 only, border clear, alpha-0 RGB = 0, no magenta, 0 violet tint, 0 off-palette.
- Soles row 131 (non-water pixels), feet centre within 3 px of the anchor, nothing below the sole row.
- One body component. Water may add free stream pieces, and those are water tones only.

## Verdict / weak spots
- **Axe:** reads clearly as raise, 2-frame swing, held impact, recoil, lift, re-raise.
  - The re-raise (k8, axe overhead) follows "axe up front" (k7) with no in-between. The loop jump is about one swing step.
  - The impact is at stump height.
- **Pickaxe:** reads clearly.
  - The impact tip is partly redrawn and stops 5 px above the soles (row 126), so it reads as biting the ground slightly behind the feet.
  - The k8 pick is lying on the ground.
- **Berries:** reach, pinch, pluck, retract to the pouch. Hands are empty.
  - The head stays locked but shifts with the lean (0-5 px). There may be a faint seam at the neck in the reach frames.
- **Water:** reads as watering.
  - k7-k9 hold the can still while the tail falls.
  - Legs are locked (boots identical in all frames).
  - The stream is a thin Imagine ribbon.
- All harvest clips: body texture re-quantises frame to frame (no full-body lock on moving bodies, same as Keeper harvest v3).

## Previews (`preview/`)
- `elaia_harvest_side_v1_E_x2.gif` (4 clips, LCM 2700 ms).
- `elaia_harvest_water_station_all_x2.gif`: all harvest + station. 2700 ms timeline, so the 940 ms station loop restarts mid-cycle at the GIF wrap.
- `elaia_harvest_axe_pickaxe_E_W_x2.gif`, `elaia_harvest_berries_water_E_W_x2.gif`, `elaia_harvest_side_v1_E_contact.png`.
- Per clip: `*_x3.gif` and `*_strip.png`.
