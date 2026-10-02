# Frame / alpha check (tools/check_frames.py)

Reference: live walk_south frames - sole row 123; walk semi-transparent edge px 227-274, near-black semi px up to 38, alpha-0 pixels with leftover RGB 28-47 (the walk is not cleaned; v2 is).

| frame | RGBA | size | bg/border clear | alpha0 RGB!=0 | semi px | semi off-edge | magenta semi | light semi | dark semi | non-walk colours | sole row / legs identical to walk | PASS |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| keeper_chop_south_0001.png | True | 192x128 | True | 0 | 251 | 0 | 0 | 0 | 27 | 0 | 123 / 0.936 | PASS |
| keeper_chop_south_0002.png | True | 192x128 | True | 0 | 271 | 0 | 0 | 0 | 28 | 0 | 123 / 0.996 | PASS |
| keeper_chop_south_0003.png | True | 192x128 | True | 0 | 269 | 0 | 0 | 0 | 28 | 0 | 123 / 0.996 | PASS |
| keeper_chop_south_0004.png | True | 192x128 | True | 0 | 270 | 0 | 0 | 0 | 29 | 0 | 123 / 0.996 | PASS |
| keeper_chop_south_0005.png | True | 192x128 | True | 0 | 258 | 0 | 0 | 0 | 29 | 0 | 123 / 0.996 | PASS |
| keeper_chop_south_0006.png | True | 192x128 | True | 0 | 268 | 0 | 0 | 0 | 29 | 0 | 123 / 0.996 | PASS |
| keeper_chop_south_0007.png | True | 192x128 | True | 0 | 270 | 0 | 0 | 0 | 28 | 0 | 123 / 0.996 | PASS |
| keeper_chop_south_0008.png | True | 192x128 | True | 0 | 276 | 0 | 0 | 0 | 29 | 0 | 123 / 0.996 | PASS |
| keeper_chop_south_0009.png | True | 192x128 | True | 0 | 274 | 0 | 0 | 0 | 28 | 0 | 123 / 0.996 | PASS |
| keeper_mine_south_0001.png | True | 192x128 | True | 0 | 250 | 0 | 0 | 0 | 28 | 0 | 123 / 0.959 | PASS |
| keeper_mine_south_0002.png | True | 192x128 | True | 0 | 272 | 0 | 0 | 0 | 30 | 0 | 123 / 0.996 | PASS |
| keeper_mine_south_0003.png | True | 192x128 | True | 0 | 272 | 0 | 0 | 0 | 30 | 0 | 123 / 0.996 | PASS |
| keeper_mine_south_0004.png | True | 192x128 | True | 0 | 270 | 0 | 0 | 0 | 30 | 0 | 123 / 0.996 | PASS |
| keeper_mine_south_0005.png | True | 192x128 | True | 0 | 255 | 0 | 0 | 0 | 29 | 0 | 123 / 0.996 | PASS |
| keeper_mine_south_0006.png | True | 192x128 | True | 0 | 270 | 0 | 0 | 0 | 28 | 0 | 123 / 0.996 | PASS |
| keeper_mine_south_0007.png | True | 192x128 | True | 0 | 275 | 0 | 0 | 0 | 28 | 0 | 123 / 0.996 | PASS |
| keeper_mine_south_0008.png | True | 192x128 | True | 0 | 270 | 0 | 0 | 0 | 29 | 0 | 123 / 0.996 | PASS |
| keeper_mine_south_0009.png | True | 192x128 | True | 0 | 265 | 0 | 0 | 0 | 27 | 0 | 123 / 0.984 | PASS |
| keeper_pluck_south_0001.png | True | 128x128 | True | 0 | 266 | 0 | 0 | 0 | 29 | 0 | 123 / 0.996 | PASS |
| keeper_pluck_south_0002.png | True | 128x128 | True | 0 | 270 | 0 | 0 | 0 | 28 | 0 | 123 / 0.996 | PASS |
| keeper_pluck_south_0003.png | True | 128x128 | True | 0 | 274 | 0 | 0 | 0 | 29 | 0 | 123 / 0.996 | PASS |
| keeper_pluck_south_0004.png | True | 128x128 | True | 0 | 274 | 0 | 0 | 0 | 31 | 0 | 123 / 0.996 | PASS |
| keeper_pluck_south_0005.png | True | 128x128 | True | 0 | 271 | 0 | 0 | 0 | 29 | 0 | 123 / 0.996 | PASS |
| keeper_pluck_south_0006.png | True | 128x128 | True | 0 | 269 | 0 | 0 | 0 | 30 | 0 | 123 / 0.996 | PASS |
| keeper_pluck_south_0007.png | True | 128x128 | True | 0 | 263 | 0 | 0 | 0 | 29 | 0 | 123 / 0.996 | PASS |
| keeper_pluck_south_0008.png | True | 128x128 | True | 0 | 263 | 0 | 0 | 0 | 29 | 0 | 123 / 0.996 | PASS |
| keeper_pluck_south_0009.png | True | 128x128 | True | 0 | 269 | 0 | 0 | 0 | 29 | 0 | 123 / 0.996 | PASS |

ALL PASS: True
