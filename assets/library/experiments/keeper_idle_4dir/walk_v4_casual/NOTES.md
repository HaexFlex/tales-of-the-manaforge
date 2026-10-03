# Keeper walk v4: CASUAL walk, south only (Option A look, video-derived), 8 frames, 1000 ms loop

Not wired into the game. `walk_v3_optA` stays unchanged; it may become the run cycle.

Haex's spec:
- Less of a march, more casual.
- Arms swing loosely.
- Legs make full steps but never lift more than 45 degrees forward or back.

## Source
`source/keeper_walk_casual_front.mp4`:
- Grok Imagine image-to-video from the Option A S still.
- 6.04 s at 24 fps, 672x448, 145 frames.
- Relaxed walk in place, front-facing, planted.

Frame numbers are 1-based ffmpeg frames; time = (n - 1) / 24 s.

The clip holds every pose for 2 frames, so it effectively runs at 12 fps. It is very periodic:
- **Cycle:** 32 video frames (1.333 s) = two steps = 16 unique poses.
- **Mask auto-difference:** minimum at lag 32 (12.8 vs 245 at lag 16, the other leg).
- **Chosen window f36-f67:** f68 matches f36 (mask diff 13), so the loop is seamless.

## Chosen frames (8, every 2nd unique pose = evenly spaced phases)

| k | video frame | t (s) | phase | bob px | ms |
|---|---|---|---|---|---|
| 0 | f36 | 1.458 | his L foot (screen right) lifted, peak (heel back, 8 px) | 2 | 130 |
| 1 | f40 | 1.625 | L foot setting down | 1 | 120 |
| 2 | f44 | 1.792 | double support (forward foot under the body) | 0 | 120 |
| 3 | f48 | 1.958 | weight shift, R heel starting | 1 | 130 |
| 4 | f52 | 2.125 | his R foot (screen left) lifted, peak (7 px) | 2 | 130 |
| 5 | f56 | 2.292 | R foot setting down | 1 | 120 |
| 6 | f60 | 2.458 | double support | 0 | 120 |
| 7 | f64 | 2.625 | weight shift, L heel starting | 1 | 130 |

- **Loop = 1000 ms** for two steps. That is 1.33x the source's 1333 ms; the source pace is very slow.
- The lift peaks and heel starts hold 130 ms, the transfers 120 ms.

**Why 8 frames and not 10-12:**
- The cycle has 16 unique poses, so 8 is the only even sub-sampling that fits 100-130 ms per frame.
- 10 or 12 frames would need uneven pose spacing or duplicate poses, which makes the step rhythm hitch.
- 16 frames would need about 62 ms per frame.

## Pipeline (tools/)
These are the walk_v3 tools, unchanged, plus `assemble_v4.py`.

1. **`analyse_video.py`, `period.py`:** magenta key and per-frame metrics, then the period from mask auto-difference.
2. **`convert_video.py`:**
   - One scale: the tallest cycle frame = the S still's 119 px (scale 0.342).
   - Premultiplied BOX downscale, hard alpha at 50%, despeck, defringe.
   - Option A 48-colour palette (nearest Lab, no dither).
   - Soles on row 123.
3. **`assemble_v4.py`** reuses `assemble_v3.py`'s helpers:
   - **Bob:** the video's natural bob is at most ±3 video px (under 1 game px), so a designed 0-2 px bob is used: high on single support (lift peaks), low on double support. Built with `fit_top` (shift above the hip, resample hip to sole); soles stay on row 123.
   - **Head x lock:** 0 px shift was needed.
   - **Head lock:** the top 34 rows (hair and face) come from f36, because the video redraws the face and hair spikes every frame (about 800 px of change otherwise).
   - **Chest lock (new):** rows top+34 to top+63, x 53-72 (shirt, medallion, lapel trims) also come from f36. This cut the torso shimmer from 400-580 to 120-170 changed px per step. The shoulders, sleeves, hands, belt and coat skirt still move.
   - **Boot maroon:** remapped to dark brown below the head (17-25 px per frame).
4. **`export_walk4.py`:** frames, strip, json (per-frame `durations_ms`), x3 GIF, contact sheet, and the v3-vs-v4 side-by-side.
   - The side-by-side runs on the LCM timeline: 4000 ms, so both loops stay seamless at their own timing.
5. **`check_frames.py`** (walk mode, `"anchor": "loop"`) plus **`check_extra.py`**.
6. **`measure.py`:** the spec measurements below. They are saved in `measurements.json`.

## Spec measurements (game px; 128x128 frames)

**Arms** (glove blob beside the coat, rows 66-100):

| | hand centre x range (L / R) | hand centre y range | hand outer edge from centre line |
|---|---|---|---|
| S still (rest) | - | - | 24.5 |
| **v4 casual** | **8.5 / 8.5** | **2.1 / 3.3** | **22.5-30.5** (at most 6 px beyond rest) |
| v3 march | 18.6 / 20.0 | 20.0 / 23.4 | 14.5-36.5 (hands rise about 15 px) |

The v4 hands stay at rest height (centre rows 81-84 vs the still's 84-85) and within about 5-6 px of their rest x. The swing happens mostly in depth, so from the front it shows as a small sideways sway, staying close to the body.

**Legs.** Hip row about 79.6 (belt centre + 6), so leg length L is about 43 px.

*Rear lift* (visible from the front as the foot leaving the ground line):
- Peaks are 8 px (his L, f36) and 7 px (his R, f52). Other frames are 0-4 px.
- Hip-to-foot line angle = acos(1 - 8/43.4) = **35 deg** at most. This is an upper bound: a bent knee gives a smaller line angle for the same lift.
- 45 deg would need a lift of 12.7 px or more.
- If you count the shin alone (thigh vertical), the knee bend is about 51 deg. That is knee flexion, not leg lift.

*Forward swing:*
- It cannot be measured directly from the front: the foot comes toward the camera and the thigh is under the coat.
- The forward foot stays on the ground line (lowest row 123 in k2/k6).
- The coat hem (where the knee sits) never rises more than 1 px relative to the belt (hem - belt 29.5-31.5 vs the still's 30.5). A 45 deg thigh would raise the knee by about 6.4 px. Proxy estimate: thigh 17.5 deg or less.
- This proxy is weak: it reads only 2 px for v3, whose knee-up is visible to the eye.

## Checks

**`alpha_check.md`: 8/8 PASS.**
- RGBA 128x128, border clear.
- 0 semi-transparent px, 0 RGB under alpha 0.
- 0 magenta, 0 tint, 0 fringe, 0 non-palette colours.
- Soles on row 123, heights 117-119.
- Loop feet mean within 2 px of 63.5; head-x range 0.

**`extra_check.json`: all OK.**
- 1 connected component per frame (no specks or objects).
- Heights 117-119.
- Bob range 2 px.
- Timing: 120-130 ms per frame, 1000 ms loop.
- Loop seam change (k7 to k0: 3547 px) is within the in-cycle steps (3491-3837).
- Locked head rows change 0 px.

## Verdict
- **Casual vs march:** clearly casual. No knee-up, the feet stay low, the heels peel back a little, and the forward foot slides under the body. It reads as an easy stroll.
- **Arms:** loose and close to the body, compared with v3's flappy outward and upward swing (about 2.3x less sideways travel, about 8x less vertical).
- **Loop:** seamless; the source repeats exactly.
- **Caveats:**
  - From the front the step is subtle; it reads mostly from the alternating heel lifts and the boot passing.
  - The coat skirt and belt still shimmer slightly from the video redraw, below the locked chest.
  - The stance is a little narrower than the still's.
