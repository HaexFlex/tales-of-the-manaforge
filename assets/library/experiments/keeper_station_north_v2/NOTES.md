# Keeper: station work, north (seen from behind), v2: generic busy loop (experiment, not wired)

v2 replaces v1, which Haex rejected because its hammer made it anvil-specific. The v1 folder is kept unchanged.

This is ONE generic "very busy working" loop facing **north** for all forge stations (anvil, press, reliquiary, ...).
- **Only the Keeper**: empty hands, no tool, no object. The station sprite is drawn in front of him (north).
- **Both arms move.** They alternate reaching and sweeping out to the sides and coming back up, with a slight body/head sway.

## Result
| | |
|---|---|
| frames | `station_work_north_0000..0009.png` (10 frames) + `_strip.png`, `_x3.gif` (on green 78,128,52), `_contact.png` (incl. Option A N still) |
| canvas | **128x128**, feet anchor **(64,124)**: soles row 123, feet edge-centre x 64.0. Widest reach x 6..121 (still fits with the 1 px clear border). Top row 5 |
| timing | 80, 70, 90, 110, 80, 80, 90, 100, 90, 110 ms = **900 ms**, which is close to the source's real time (the 22-frame window = 917 ms) |
| palette | `palette.json` = Option A 48, **no extras** |
| body height | 118 px (hair top row 6 -> soles 123). The scale is the same as the N still (120/348 video px, same transform as v1); he leans his head slightly forward |
| checks | `alpha_check.md`: **10/10 PASS** |

The check covers: RGBA, alpha only 0/255, transparent corners and border, alpha-0 RGB = 0, no magenta, no edge tint, no fringe, 0 off-palette pixels, soles 123 with feet x 64. It adds an **object check**:
- 1 opaque component.
- No specks.
- 0 white pixels and 0 light-grey (metal/paper) pixels.
- 0 green pixels outside the hair.
- 0 rune cyan outside the rune box.

## Source and loop
`source/keeper_station_generic.mp4`: Imagine image-to-video from the Option A N still on magenta; 24 fps, 145 frames, 6.04 s.
- **No object in any of the 145 source frames.** Keying gives one component per frame, except single-pixel key noise at the fingers in f14, f28 and f58, and f58 is not used.
- The motion is irregular. The best seamless window is **f42..f63**: f64 ~= f42, upper-body alpha diff 655 video px, the lowest of all 18-29 frame windows. That is 22 frames = 0.917 s, which matches "~1 cycle/s".
- **Frames used, by phase** (1-based video frame; t = (i-1)/24):

| # | video frame | t (s) | phase | ms |
|---|---|---|---|---|
| 0 | f42 | 1.708 | both hands up (rest) | 80 |
| 1 | f44 | 1.792 | left arm sweeps out | 70 |
| 2 | f45 | 1.833 | left arm extended | 90 |
| 3 | f47 | 1.917 | left hand back up high | 110 |
| 4 | f50 | 2.042 | left reaches out again | 80 |
| 5 | f52 | 2.125 | right arm sweeps out | 80 |
| 6 | f54 | 2.208 | right arm extended | 90 |
| 7 | f56 | 2.292 | right hand back up | 100 |
| 8 | f59 | 2.417 | right reaches half out | 90 |
| 9 | f61 | 2.500 | both up, settle | 110 |

- **Seam:** f61 -> f42.

## Pipeline (`tools/convert_station2.py`, `tools/build_station2.py`)
- **Convert:** magenta key + despill, then a premultiplied BOX downscale with a fixed transform (same as v1), hard alpha, despeck, defringe, Option A palette (nearest Lab), and keep main. There is no bench to remove, and no tool hue fix (it would grey the rune).
- **Clean-up:**
  0. **Hand tints:** green and pale grey-green motion-blur tints on the hands and cuffs become skin/gold-ramp colours of the same lightness.
  1. **Head lock, sway kept:** Imagine redraws the spiky hair every frame (60-70% of hair pixels change = boil). The f42 hair (greens, outline, strand tips) is pasted at each frame's measured head shift.
     - The sway is damped x0.5: the source steps up to 4 px per sampled frame. The used dx is 0, 0, 0, -2, +1, +1, 0, -2, -2, -1.
     - Hands in front of the hair are never overwritten.
  2. **Rune:** the source keeps a diamond, but its inner detail wobbles. It is replaced by the **N still's cyan diamond**, centred on the frame's own rune centre, so it follows the torso twist (offset -3..+2 px).
  3. **Boots** (rows >= 112) are locked to f42. In the **lower coat** (rows 74..111, below the arms), shading colours come from f42 (that area boiled ~30% of its pixels per frame) while the silhouette (hem sway) stays live.
- **Left live** (the motion): arms, elbows, shoulders, the upper back and the twisting rune position.

## Verdict (honest)
- **Reads as busy from behind?** Yes, clearly. Both arms work constantly and alternate (left sweep, left again, right sweep, right half), with a slight sway, and it is generic.
- **The catch:** the source gestures with the hands at shoulder height, palms open, reaching out to the sides. So it reads more as "busily handling / reaching for things around him" than "working at a bench in front of him". A station drawn in front can hide little of this, because the hands are beside and above the shoulders.
- **Both arms visible?** Yes, in every frame.
- **Empty hands?** Yes. No object or item in any frame, and the object check is 0 on all frames.
- **Flicker:** the head and lower body are stable. Arm and upper-back shading changes with the motion, and the shading on fast-moving hands (frames 3-5) is a bit soft or blotchy from the motion blur.

## Rebuild
Paths assume the box layout under `/workspace/keeper_idle/`; dependencies are copied to `tools/`.
```
python tools/convert_station2.py 40 66
python tools/build_station2.py
python tools/check_frames_station2.py <dir>
```
`preview/` contains:
- `source_overview.png`: the whole clip.
- `loop_window_f42_f64.png`.
- `final_upper_zoom.png`, `final_torso_zoom.png`.
- `head_lock_zoom.png`.
- `hand_tints_before_fix.png`.
- `rune_still_vs_source.png`.
