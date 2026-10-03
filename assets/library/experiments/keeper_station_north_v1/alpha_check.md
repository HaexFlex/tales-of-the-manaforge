# Frame / alpha / bench check (tools/check_frames_station.py)

Hard 0/255 alpha, transparent background, 128x128, feet anchor (64,124) = soles row 123 / feet edge-centre x 64; palette = Option A 48 + the iron greys used by the hammer head; bench band = source plank rows (canvas 69..78).

| frame | mode | size | corners a=0 | border clear | alpha not 0/255 | alpha0 RGB!=0 | magenta | purple tint edge | light fringe | non-palette | bench band 1 run | white px | stray cyan | specks | sole / feet x / body h / top / x range | PASS |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| station_work_north_0000.png | RGBA | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | True | 0 | 0 | 0 | 123 / 64.5 / 118 / 6 / [43, 101] | PASS |
| station_work_north_0001.png | RGBA | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | True | 0 | 0 | 0 | 123 / 64.5 / 118 / 6 / [43, 101] | PASS |
| station_work_north_0002.png | RGBA | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | True | 0 | 0 | 0 | 123 / 64.5 / 118 / 6 / [43, 101] | PASS |
| station_work_north_0003.png | RGBA | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | True | 0 | 0 | 0 | 123 / 64.5 / 118 / 6 / [43, 101] | PASS |
| station_work_north_0004.png | RGBA | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | True | 0 | 0 | 0 | 123 / 64.5 / 118 / 6 / [43, 100] | PASS |
| station_work_north_0005.png | RGBA | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | True | 0 | 0 | 0 | 123 / 64.5 / 118 / 6 / [43, 100] | PASS |
| station_work_north_0006.png | RGBA | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | True | 0 | 0 | 0 | 123 / 64.5 / 118 / 6 / [43, 100] | PASS |
| station_work_north_0007.png | RGBA | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | True | 0 | 0 | 0 | 123 / 64.5 / 118 / 6 / [43, 101] | PASS |
| station_work_north_0008.png | RGBA | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | True | 0 | 0 | 0 | 123 / 64.5 / 118 / 6 / [43, 101] | PASS |

ALL PASS: True (9/9), clip upright body height 118
