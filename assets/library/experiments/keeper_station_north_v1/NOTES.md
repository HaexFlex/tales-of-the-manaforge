# Keeper: station work, north (seen from behind), v1 (experiment, not wired)

One generic "working at a crafting station" loop facing **north**, for all stations. **Only the Keeper is drawn**: no
workbench, paper or items. The station sprite is meant to be drawn in front of him (north). The only object kept is the
**hammer in his right hand**.

## Result
| | |
|---|---|
| frames | `station_work_north_0000..0008.png` (9 frames) + `_strip.png`, `_x3.gif` (on green 78,128,52), `_contact.png` (incl. Option A N still) |
| canvas | **128x128**, feet anchor **(64,124)**: soles row 123, feet edge-centre x 64.5 (same as walk_v3 / the stills; body x 43..101, top row 6) |
| timing | 120, 100, 100, 100, 120, 100, 70, 70, 130 ms = **910 ms** loop, one hammer strike per loop |
| palette | `palette.json` = Option A 48 + 2 iron greys (100,105,108), (143,151,155) for the hammer head (same tones as the harvest iron) |
| body height | 118 px (hair top row 6 -> soles 123). The N still is 120 because he bends his head forward slightly while working. The scale is identical to the still: 120/348 video px |
| checks | `alpha_check.md`: **9/9 PASS** |

The check covers: RGBA, alpha only 0/255, transparent corners and border, alpha-0 RGB = 0, no magenta, no purple edge tint,
no light fringe, 0 off-palette pixels, soles row 123 with feet within 2 px of x 64. It adds these bench checks:
- In the source's plank rows (canvas 69..78) there is only one opaque run, the coat. A leftover plank would add a second run or widen the run.
- 0 white pixels outside the hammer head.
- 0 rune-cyan pixels outside the rune box (no sparks).
- No specks under 4 px.

## Source
- `source/keeper_station_north_b.mp4` (Imagine image-to-video from the Option A N still on magenta; 24 fps, 145 frames, 6.04 s) is **the clip used**.
  - **Video frames f114..f122** (1-based; t = 4.708..5.042 s, frame time = (i-1)/24) form one strike.
  - The strike period in this stretch is 9 frames: f123 ~= f114 (alpha diff 37 px), so the seam f122 -> f114 is clean.
  - Phases:
    - f114 contact/rebound
    - f115-117 lift
    - f118-119 top
    - f120-121 down-swing (70 ms, fast)
    - f122 impact (held 130 ms)
- `source/keeper_station_north.mp4` (clip a) was **rejected**:
  - The hammer taps are tiny and fast (about 6-frame period near the shoulder), so they read poorly.
  - The bench is bigger, with paper.
  - The hammer disappears in later frames.
- Clip b was also avoided elsewhere:
  - f58-67 and f95-103: Imagine switches the hammer to the left side.
  - f139-145: the pose morphs back to the still.
- `source/frames_b_f114_f123/` holds the raw video frames; `source/converted_b/` holds them after `convert_station.py`.
- `source/convert_b.json` and `metrics_st_{a,b}.json` are the per-frame analysis.

## Bench removal (Imagine drew a bench despite the prompt)
The bench in b is a thin static plank (video rows 239-261, x 234-439) behind his waist, plus paper on it between the torso
and the raised arm. The hammer never touches the plank, and **the arm and hands never overlap the plank**, so nothing had
to be sacrificed. The left arm is hidden in front of his body in the source, so the work reads one-handed (right hand plus hammer).

The steps (in `tools/convert_station.py` and `tools/build_station.py`):
1. **Plank rows 236..263:** only the coat's blue run around the body centre is kept. Gaps up to 40 px are bridged, so the cyan rune does not split the coat.
2. **Paper:** near-white pixels in rows 200..263 are removed. After the downscale, low-saturation light leftovers under the raised arm are also removed.
3. **Keep main:** the main component plus nearby parts (the hammer) are kept.
4. **Waist notch:** the plank overlapped the coat's **left contour** by about 10 video px in its rows, leaving a 1-3 px notch. The contour is re-run straight between the clean rows 67 and 81.

## Other fixes
- **Rune:** Imagine redrew the coat-back rune as an "F" glyph.
  - Its pixels (rune cyan plus its 2 glow colours) are refilled with the nearest coat blue.
  - The **N still's diamond rune** is pasted in their place, 1 px lower to follow the torso.
- **Hammer tint:** the hammer head had green/teal blur tints. It is mapped to grey of the same lightness on the grey/iron ramp. Teal blur on the sleeve becomes sleeve blue. Hair and rune are never touched.
- **Head and body lock:**
  - The head and body do not move in the source: head top constant, body alpha diff <= 3 px, **no nod**. But their colours shimmered by 5-130 px per frame.
  - The head (rows < 42, x < 84) and body (rows >= 70, plus x < 75 above that) are locked to the cleaned f118.
  - Only the right shoulder, arm and hammer animate.
- The hammer hue fix runs only outside the still's body core, so the rune keeps its cyan.

## Verdict (honest)
- **What reads well:** from behind, it reads clearly as hammering at something in front of him. The right arm raises and lowers the hammer by the right shoulder and the head stays bowed toward the work.
- **Bench:** fully gone; the plank-band and white-pixel checks are 0.
- **Flicker:** none in the head or body (locked). The arm and hammer carry the source's motion blur: the f115 and f122 hammer heads are darker and noisier.
- **Limitations:**
  - The work happens at chest/shoulder height, not waist height.
  - The left hand is not visible.
  - Because the arm and hammer are the only moving parts, it is a generic "hammering" loop. That suits a forge or anvil, and works as a stand-in at other stations.

## Rebuild
These scripts use the box paths under `/workspace/keeper_idle/` (see sys.path at the top of each). Dependencies are copied to `tools/`.
```
python tools/convert_station.py b 114 123     # video frames -> station/work/b/g_###.png (debench, scale, palette)
python tools/build_station.py                 # cleanup passes + final frames / strip / gif / meta / contact sheet
python tools/check_frames_station.py <dir>    # alpha / palette / anchor / bench checks -> alpha_check.{json,md}
```
`preview/` contains review images:
- `review_bench_removed.png`: source vs final.
- `final_zoom2.png`.
- `rune.png`: still diamond vs Imagine's F.
- `left_edge.png`: plank overlap on the coat contour.
- `hz.png`: hammer tints before the fix.
- Clip overviews.
