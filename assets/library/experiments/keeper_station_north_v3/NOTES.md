# Keeper: station work, north (seen from behind), v3: hands low in front (experiment, not wired)

v3 replaces v2. Feedback on v2: hands at shoulder height with open palms read as waving/conducting. The v1 and v2 folders are unchanged.

This is one generic "busy working at a station" loop facing **north** for all forge stations.
- **Hands:** low and in front of him, hidden by his body.
- **Motion:** from behind you see the elbows and shoulders working, with the head bowed over the work.
- **Objects:** none.

## Result
| | |
|---|---|
| frames | `station_work_north_0000..0009.png` (10 frames) + `_strip.png`, `_x3.gif` (on green 78,128,52), `_contact.png` (incl. Option A N still), `_v2_vs_v3_x3.gif` |
| canvas | **128x128**, feet anchor **(64,124)**: soles row 123, feet edge-centre x 64.0. The working stance is wider than the still's: feet x 40..87 vs 42..85 |
| timing | 110, 110, 80, 80, 80, 110, 80, 110, 90, 90 ms = **940 ms** (source real time for the 14 poses = 1167 ms; sped up slightly for a busier feel) |
| palette | `palette.json` = Option A 48, **no extras** |
| height / scale | Same scale as the N still: fixed 120/348 transform, coat hem lowest row 103 vs 102 in the still. Clip height is **107** (hair top row 17 vs 4) because the **head is bowed** over the work. That is a pose change, not a scale change |
| checks | `alpha_check.md`: **10/10 PASS** |

The check covers everything from v2: RGBA, alpha only 0/255, transparent corners and border, alpha-0 RGB = 0, no magenta or edge tint or fringe, 0 off-palette pixels, soles 123 with feet x 64. It also runs:
- **Object check:** 1 component, no specks, 0 white, 0 light-grey, 0 stray green, 0 stray cyan.
- **Bench check:** in the source's plank rows (canvas 72..82) there is only one run, the coat.
- **Scale check:** the hem row is within 1 px of the still's.

## Source choice (all three clips reviewed; overviews in preview/)
- **`keeper_station_generic2.mp4` (clip a), USED.**
  - **f101..f140** are exactly the requested look: hands low and hidden in front, elbows alternating in and out, shoulders working, head bowed. The hair is on-model (short, spiky).
  - The one-arm outward reaches (f37, f61, f85) are outside the window.
  - Imagine redrew the rune as an "F"; it is replaced by the N still's diamond.
  - Imagine output here is effectively **12 fps**: video frames come in identical pairs.
- **`keeper_station_generic2_b.mp4` (b), rejected** despite the downloader's pick. Reasons:
  - Its hair grew long, down to mid-back, and covers the coat and rune (off-model).
  - Every ~21 frames the right hand reaches out sideways at waist height, holding something, with flying particles: the green artifact plus more items detached in f34-40, f55-59, f78-84, f99-100, f109-117, f127-142.
  - Its hands-low stretches have no clean loop seam (best >= 3300 px vs 206 in a).
- **`keeper_station_generic2_c.mp4` (c), rejected:**
  - An arm rises to chest/shoulder height every 24 frames.
  - Its hands-low stretches have no clean loop seam (best >= 2265 px).
- **All three again drew a bench.** In a it is two small two-plank bench ends beside his waist (video rows ~246..272). It is removed (below).

## Loop (clip a)
- **Window f108..f135:** 14 poses (pairs), 28 video frames. f136 ~= f108 (alpha diff 206 video px, the best hands-low seam of all three clips).
- **10 poses by phase.** The dropped poses (f110, f114, f124, f130) are in-betweens of their neighbours. Frame time = (i-1)/24.

| # | video frame | t (s) | phase | ms |
|---|---|---|---|---|
| 0 | f108 | 4.458 | rest: elbows in, hands at the counter | 110 |
| 1 | f112 | 4.625 | both elbows out (push / work) | 110 |
| 2 | f116 | 4.792 | elbows coming in | 80 |
| 3 | f118 | 4.875 | elbows in, shoulders down | 80 |
| 4 | f120 | 4.958 | both elbows out again | 80 |
| 5 | f122 | 5.042 | right elbow up/out | 110 |
| 6 | f126 | 5.208 | left elbow out, right in | 80 |
| 7 | f128 | 5.292 | left elbow wide | 110 |
| 8 | f132 | 5.458 | right elbow out, left in | 90 |
| 9 | f134 | 5.542 | settle | 90 |

Elbow travel is about 7 px left and 5 px right at 128 px.

## Pipeline
`tools/convert_station3.py`:
- Magenta key + despill.
- **Bench removal** (video px, rows 246..276):
  - Only the coat's blue run around the body centre is kept, +-2 px.
  - Wood-coloured pixels go, along with the planks' dark outline next to them.
  - Only the largest component is kept.
- Fixed transform: feet centre 339 for this clip's wider stance -> x 64, soles 398 -> row 123.
- Then hard alpha, despeck, defringe, Option A palette (nearest Lab) and keep main.

`tools/build_station3.py` (same passes as v2, with v3 settings):
- **Hand tints:** practically nothing here; the hands are hidden.
- **Head lock:** the head is static in this window (measured shift 0 in every frame), so there is no sway to keep. A **1 px down-nod is added** on the three push poses (f112, f120, f128) to keep the head alive. This is set in `NOD` and can be removed.
- **Rune:** the F glyph is refilled with coat blue, and the N still's cyan diamond is pasted at the glyph's centre.
- **Locks:** boots (rows >= 112) are locked to f118. In the lower coat (rows 78..111), shading colours come from f118 while the silhouette stays live.

## Verdict (honest)
- **Reads as working at a station from behind?** Yes, much more than v2. Head bowed, hands out of sight in front, elbows and shoulders alternately pushing out and coming in: it reads as working at a counter, anvil or press in front of him, and it is generic. The bench is gone; the band check is clean on every frame.
- **Busy enough?** Moderately. The elbow motion is small (5-7 px at 128) and only the arms move; the torso is static in the source. It reads as steady work rather than frantic. I sped the poses up about 1.24x versus the source (940 vs 1167 ms) to add energy.
- **Flicker:** none.
  - Head locked: only the added 1 px nod moves it.
  - Boots and lower coat stable (0-4 px changes per frame).
  - Arm and shoulder shading changes with the motion.
- **Model notes:**
  - The head reads smaller and lower because it is bowed (clip height 107 vs 120 at the same scale).
  - The stance is wider than the still's.
  - Both ears show at the sides of the hair.

## Rebuild
Paths assume the box layout under `/workspace/keeper_idle/`; dependencies are copied to `tools/`. The raw frames come from the mp4 via `ffmpeg -i source/keeper_station_generic2.mp4 frames/a/f_%03d.png`.
```
python tools/convert_station3.py a 106 138
python tools/build_station3.py
python tools/check_frames_station3.py <dir>
python tools/sidebyside.py        # v2 vs v3 x3 GIF on the common 42.3 s LCM timeline (both loops seamless)
```
