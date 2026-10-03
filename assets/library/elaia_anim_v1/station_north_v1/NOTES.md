# Elaia: station work, north (seen from behind), v1

Experiment, not wired. This is a generic "busy at a station" loop facing north, built like keeper_station_north_v3: hands low and in front (hidden by the body), elbows and shoulders working, no objects.

| | |
|---|---|
| frames | `station_work_north_0000..0009.png` (10) + `_strip.png`, `_x3.gif`, `_contact.png` |
| canvas | **128x128**, feet anchor **(64,124)**: soles row 123, feet edge-centre x 64.0 |
| timing | 80,120,85,85,120,85,85,80,120,80 ms = **940 ms**. Each frame's duration follows the source pose hold (2 or 3 video frames) |
| palette | `palette.json` = Elaia 40, no extras |
| scale | fixed 115/334 transform (same as the N still). Clip height 112-114 px (top row 10-12); she leans slightly into the work |
| checks | `alpha_check.json`: **10/10 PASS**: RGBA, alpha 0/255, border clear, no magenta/tint, 0 off-palette, soles 123, feet x 64.0, 1 component |

## Source (`source/elaia_station_generic.mp4`)
- Back view, camera locked, feet planted (feet band x 302..369, sole 397 in every frame). Poses are held 2-3 frames (~10 fps).
- **Objects:**
  - Imagine drew small bench/table ends beside her waist from f12 on. They are removed per row: in rows 60-75 only the robe's contiguous run through x 64 is kept (~200-250 px per frame).
  - About every 24-30 frames her right hand rises to shoulder/face height holding a small dark tool/vial: f29-33, 41-45, 65-71, 84-88, 96-100, 108-113, 120-126, 132-139. Those frames are not used.
  - A tool tip and fingers that still peek over the right shoulder (rows < 47, x >= 81) are cleared (2-24 px per frame).
- **Loop:** 10 object-free poses from four hands-low runs, joined at the lowest silhouette jumps: f101,103,106 | f58,60,63 | f89,91 | f115,118 (-> f101).
  - Every jump (60-101 mask px) is smaller than a normal adjacent pose change in the clip (median 120).
- **Hair:** her long hair sways and shimmers, and the head turns slightly. Hair and head are locked (rows top..top+44, x 48-80) from f101. The elbows and shoulders outside the hair keep their own motion.

## Verdict / weak spots
- Reads as working at a counter from behind (elbows in and out, shoulders), with no objects visible. The motion is subtle: most of it is in the sleeves and elbows, because the hair covers the back.
- The loop is stitched from four runs, not one continuous take. The jumps are small, but the pose sequence is not strictly "physical".
- Locked hair means no hair sway while she works.
