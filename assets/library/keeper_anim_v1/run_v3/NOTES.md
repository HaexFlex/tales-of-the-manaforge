# Keeper walk v3 (Option A look, video-derived): S / N / E / W, 8 frames x 100 ms, looping

Not wired into the game. Sources (`source/`) are three Grok Imagine image-to-video clips, each 6.04 s at 24 fps, 672x448, 145 frames:
- `keeper_walkvid_side.mp4`
- `keeper_walkvid_front.mp4`
- `keeper_walkvid_back.mp4`

Each was made from the Option A still (x5 on magenta) with a "walk in place on an invisible treadmill, locked camera" prompt.

Frame numbers below are 1-based ffmpeg frames (`f_###.png`); time = (n - 1) / 24 s. The clips hold every pose for 2 frames, so there are 12 unique poses per second.

## Pipeline (tools/)
1. **`analyse_video.py`**
   - Keys the sampled magenta (tolerance plus despill) and keeps the largest figure.
   - Per-frame metrics: top, sole, height, head/torso centroid, leg-band extents, feet runs.
2. **`period.py`** finds the cycle length by mask auto-difference:
   - Side: exactly 24 frames (1.0 s). Lag 12 differs (the other leg), so these really are two different steps.
   - Front and back: about 22 frames.
   - The best clean window = the smallest start-to-end mask difference. There is no scale drift: head width is constant within ±4 video px.
3. **`convert_video.py`**
   - **Scale:** ONE scale per direction, with the tallest frame of the cycle = the Option A still height (S 119, N 120, E 119).
   - **Downscale:** premultiplied AREA (BOX) straight to game size, hard alpha at 50%, no dither.
   - **Clean-up:** despeck (islands under 4 px), defringe, then Option A's 48-colour palette (nearest Lab).
   - **Placement:** soles on row 123.
4. **`assemble_v3.py`**
   - **Sampling:** 8 frames by phase from one cycle.
   - **Head x lock:** the head centroid x is held fixed, so there is no sideways jitter.
   - **Bob damping:** the video's natural bob is 5-9 px. It is damped to a designed 0-2 px bob by shifting the rows above the hip and resampling the hip-to-sole band, with soles kept on row 123.
   - **Head lock (S/E):** hair and face rows come from one frame, because the video redraws faces and hair spikes slightly every frame.
   - **Boot clean-up:** key spill on moving boots and gloves picks the palette's maroon (80,21,33). Below the head this is remapped to the palette's dark brown (54,26,12).
   - W = E mirrored.
5. **`export_walk3.py`:** frames, strips, GIFs, contact sheet and the v2-vs-v3 GIF.
6. **`check_frames.py`** gained a walk mode: `"anchor": "loop"` in the clip json. For walks the feet anchor is checked over the loop (mean feet centre within 2 px of 63.5, head-x range at most 1.5 px), because the planted foot travels under the body by design.

## Chosen frames

| dir | video | frames (1-based) | time (s) | bob px | head lock |
|---|---|---|---|---|---|
| E | side | 97, 100, 102, 106, 108, 112, 114, 118 | 4.000-4.875 | 2,1,0,1,2,1,0,1 | f97, top 42 rows |
| S | front | 110, 112, 116, 118, 122, 124, 128, 130 | 4.542-5.375 | 0,2,1,1,0,2,1,1 | f124, top 34 rows |
| N | back | 16, 18, 20, 24, 26, 30, 32, 36 | 0.625-1.458 | 0,1,2,1,0,1,2,1 | none (already stable) |
| W | E mirrored | | | | |

Phases:
- **E:** 97 and 108 = passing (legs together, leg span 95-97 video px). 102 and 114 = contact (span 213-215).
- **N:** right-foot lift peaks at f20; left-foot lift peaks at f32. Contacts are f16 and f26.
- **S:** f110 and f122 have both feet down; f112 and f124 are knee-up (march style).

## Checks
32/32 frames pass (`alpha_check.md`):
- RGBA 128x128, border clear.
- 0 semi-transparent px, 0 RGB under alpha 0.
- 0 magenta, 0 tint, 0 fringe, 0 non-palette colours.
- Soles on row 123. Heights: S 117-119, N 118-120, E/W 117-119.
- Loop feet mean: S 63.9, N 65.1, E 62.8, W 64.3.
- Head-x range: 0 px for S/E/W, 0.9 px for N.

## Verdict / picks: video-derived for all three directions (beats walk_v2 everywhere)
- **E/W:** a real walk at last. The legs pass (contact, down, passing, up for both legs), the arms swing, and it is on-model with still E (closed coat, long mane). The feet travel backwards under the body like a treadmill, which is correct for an in-place sprite. Minor issues:
  - The mane's lower edge changes a little below the locked head rows.
  - The area-downscaled video is slightly softer than hand pixel art.
- **N:** clear alternating foot lifts, steady, on-model with still N.
- **S:** reads as walking, but in a march style: knees come up and the arms swing out wide from the body, which is a bit "flappy". The head is locked, so the face does not flicker. On-model with still S.
- **12 frames:** the clips hold 12 unique poses per side cycle and about 11 per front/back cycle, so a 12-frame version is possible from the same windows.
- **Not used:** `keeper_side_passing_a/b.jpg` and `keeper_side_walk_video_a.mp4`. The side video already contains clean passing poses.
