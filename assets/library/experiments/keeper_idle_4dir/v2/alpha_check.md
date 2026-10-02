# Frame / alpha check (tools/check_frames.py)

Hard 0/255 alpha; reference anchor = live keeper_walk_south / idle_south (sole row 123, feet x 63.5, height 122).

| frame | RGBA | 128x128 | border clear | alpha0 RGB!=0 | semi px | magenta on edge | magenta anywhere | purple tint on edge | light fringe | non-palette | sole/feet x/height | PASS |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| idle_east/keeper_idle_east_0001.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/63.0/122 | PASS |
| idle_east/keeper_idle_east_0002.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/63.0/122 | PASS |
| idle_east/keeper_idle_east_0003.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/63.0/122 | PASS |
| idle_east/keeper_idle_east_0004.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/63.0/123 | PASS |
| idle_east/keeper_idle_east_0005.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/63.0/123 | PASS |
| idle_east/keeper_idle_east_0006.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/63.0/123 | PASS |
| idle_east/keeper_idle_east_0007.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/63.0/123 | PASS |
| idle_east/keeper_idle_east_0008.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/63.0/123 | PASS |
| idle_east/keeper_idle_east_0009.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/63.0/123 | PASS |
| idle_east/keeper_idle_east_0010.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/63.0/122 | PASS |
| idle_east/keeper_idle_east_0011.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/63.0/122 | PASS |
| idle_east/keeper_idle_east_0012.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/63.0/122 | PASS |
| idle_north/keeper_idle_north_0001.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/63.5/122 | PASS |
| idle_north/keeper_idle_north_0002.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/63.5/122 | PASS |
| idle_north/keeper_idle_north_0003.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/63.5/122 | PASS |
| idle_north/keeper_idle_north_0004.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/63.5/123 | PASS |
| idle_north/keeper_idle_north_0005.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/63.5/123 | PASS |
| idle_north/keeper_idle_north_0006.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/63.5/123 | PASS |
| idle_north/keeper_idle_north_0007.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/63.5/123 | PASS |
| idle_north/keeper_idle_north_0008.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/63.5/123 | PASS |
| idle_north/keeper_idle_north_0009.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/63.5/123 | PASS |
| idle_north/keeper_idle_north_0010.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/63.5/122 | PASS |
| idle_north/keeper_idle_north_0011.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/63.5/122 | PASS |
| idle_north/keeper_idle_north_0012.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/63.5/122 | PASS |
| idle_south/keeper_idle_south_0001.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/64.0/122 | PASS |
| idle_south/keeper_idle_south_0002.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/64.0/122 | PASS |
| idle_south/keeper_idle_south_0003.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/64.0/122 | PASS |
| idle_south/keeper_idle_south_0004.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/64.0/123 | PASS |
| idle_south/keeper_idle_south_0005.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/64.0/123 | PASS |
| idle_south/keeper_idle_south_0006.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/64.0/123 | PASS |
| idle_south/keeper_idle_south_0007.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/64.0/123 | PASS |
| idle_south/keeper_idle_south_0008.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/64.0/123 | PASS |
| idle_south/keeper_idle_south_0009.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/64.0/123 | PASS |
| idle_south/keeper_idle_south_0010.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/64.0/122 | PASS |
| idle_south/keeper_idle_south_0011.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/64.0/122 | PASS |
| idle_south/keeper_idle_south_0012.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/64.0/122 | PASS |
| idle_west/keeper_idle_west_0001.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/64.0/122 | PASS |
| idle_west/keeper_idle_west_0002.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/64.0/122 | PASS |
| idle_west/keeper_idle_west_0003.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/64.0/122 | PASS |
| idle_west/keeper_idle_west_0004.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/64.0/123 | PASS |
| idle_west/keeper_idle_west_0005.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/64.0/123 | PASS |
| idle_west/keeper_idle_west_0006.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/64.0/123 | PASS |
| idle_west/keeper_idle_west_0007.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/64.0/123 | PASS |
| idle_west/keeper_idle_west_0008.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/64.0/123 | PASS |
| idle_west/keeper_idle_west_0009.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/64.0/123 | PASS |
| idle_west/keeper_idle_west_0010.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/64.0/122 | PASS |
| idle_west/keeper_idle_west_0011.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/64.0/122 | PASS |
| idle_west/keeper_idle_west_0012.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/64.0/122 | PASS |

ALL PASS: True (48/48)
