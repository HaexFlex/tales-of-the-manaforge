# Frame / alpha / object check (tools/check_frames_station2.py)

Hard 0/255 alpha, transparent background, 128x128, feet anchor (64,124) = soles row 123 / feet edge-centre x 64; palette = Option A 48 (no extras); object check = 1 component, no white / light-grey (metal, paper) / stray green / stray cyan px.

| frame | mode | size | corners a=0 | border clear | alpha not 0/255 | alpha0 RGB!=0 | magenta | purple tint edge | light fringe | non-palette | components | specks | white | light grey | green outside hair | stray cyan | sole / feet x / body h / top / x range | PASS |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| station_work_north_0000.png | RGBA | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 123 / 64.0 / 118 / 5 / [26, 101] | PASS |
| station_work_north_0001.png | RGBA | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 123 / 64.0 / 118 / 5 / [9, 101] | PASS |
| station_work_north_0002.png | RGBA | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 123 / 64.0 / 118 / 5 / [6, 101] | PASS |
| station_work_north_0003.png | RGBA | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 123 / 64.0 / 118 / 5 / [24, 101] | PASS |
| station_work_north_0004.png | RGBA | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 123 / 64.0 / 118 / 5 / [13, 102] | PASS |
| station_work_north_0005.png | RGBA | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 123 / 64.0 / 118 / 5 / [16, 115] | PASS |
| station_work_north_0006.png | RGBA | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 123 / 64.0 / 118 / 5 / [25, 121] | PASS |
| station_work_north_0007.png | RGBA | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 123 / 64.0 / 118 / 5 / [26, 105] | PASS |
| station_work_north_0008.png | RGBA | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 123 / 64.0 / 118 / 5 / [26, 117] | PASS |
| station_work_north_0009.png | RGBA | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 123 / 64.0 / 118 / 5 / [26, 113] | PASS |

ALL PASS: True (10/10), clip upright body height 118
