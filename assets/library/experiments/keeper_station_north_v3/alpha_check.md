# Frame / alpha / object check (tools/check_frames_station3.py)

Hard 0/255 alpha, transparent background, 128x128, feet anchor (64,124) = soles row 123 / feet edge-centre x 64; palette = Option A 48 (no extras); bench band = source plank rows (canvas 72..82); object check = 1 component, no white / light-grey (metal, paper) / stray green / stray cyan px.

| frame | mode | size | corners a=0 | border clear | alpha not 0/255 | alpha0 RGB!=0 | magenta | purple tint edge | light fringe | non-palette | components | specks | white | light grey | green outside hair | stray cyan | bench band 1 run | hem row (still 102) | sole / feet x / body h / top / x range | PASS |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| station_work_north_0000.png | RGBA | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | True | 103 | 123 / 64.0 / 107 / 17 / [40, 87] | PASS |
| station_work_north_0001.png | RGBA | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | True | 103 | 123 / 64.0 / 106 / 18 / [35, 89] | PASS |
| station_work_north_0002.png | RGBA | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | True | 103 | 123 / 64.0 / 107 / 17 / [39, 87] | PASS |
| station_work_north_0003.png | RGBA | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | True | 103 | 123 / 64.0 / 107 / 17 / [40, 87] | PASS |
| station_work_north_0004.png | RGBA | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | True | 103 | 123 / 64.0 / 106 / 18 / [38, 89] | PASS |
| station_work_north_0005.png | RGBA | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | True | 103 | 123 / 64.0 / 107 / 17 / [40, 90] | PASS |
| station_work_north_0006.png | RGBA | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | True | 103 | 123 / 64.0 / 107 / 17 / [38, 87] | PASS |
| station_work_north_0007.png | RGBA | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | True | 103 | 123 / 64.0 / 106 / 18 / [35, 87] | PASS |
| station_work_north_0008.png | RGBA | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | True | 103 | 123 / 64.0 / 107 / 17 / [37, 90] | PASS |
| station_work_north_0009.png | RGBA | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | True | 103 | 123 / 64.0 / 107 / 17 / [40, 87] | PASS |

ALL PASS: True (10/10), clip upright body height 107
