# Frame / alpha check (tools/check_frames.py)

Hard 0/255 alpha; reference anchor = live keeper_walk_south / idle_south (sole row 123, feet x 63.5, height 122).

| frame | RGBA | 128x128 | border clear | alpha0 RGB!=0 | semi px | magenta on edge | magenta anywhere | purple tint on edge | light fringe | non-palette | sole/feet x/height | PASS |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| walk_east/walk_east_0000.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/62.0/119 | PASS |
| walk_east/walk_east_0001.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/65.0/118 | PASS |
| walk_east/walk_east_0002.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/65.0/117 | PASS |
| walk_east/walk_east_0003.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/62.5/118 | PASS |
| walk_east/walk_east_0004.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/61.0/119 | PASS |
| walk_east/walk_east_0005.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/65.5/118 | PASS |
| walk_east/walk_east_0006.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/64.5/117 | PASS |
| walk_east/walk_east_0007.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/63.5/118 | PASS |
| walk_north/walk_north_0000.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/65.0/118 | PASS |
| walk_north/walk_north_0001.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/66.0/119 | PASS |
| walk_north/walk_north_0002.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/68.0/120 | PASS |
| walk_north/walk_north_0003.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/65.0/119 | PASS |
| walk_north/walk_north_0004.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/63.0/118 | PASS |
| walk_north/walk_north_0005.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/59.5/119 | PASS |
| walk_north/walk_north_0006.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/61.5/120 | PASS |
| walk_north/walk_north_0007.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/64.0/119 | PASS |
| walk_south/walk_south_0000.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/61.5/117 | PASS |
| walk_south/walk_south_0001.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/63.5/119 | PASS |
| walk_south/walk_south_0002.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/65.0/118 | PASS |
| walk_south/walk_south_0003.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/66.0/118 | PASS |
| walk_south/walk_south_0004.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/65.5/117 | PASS |
| walk_south/walk_south_0005.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/64.5/119 | PASS |
| walk_south/walk_south_0006.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/67.0/118 | PASS |
| walk_south/walk_south_0007.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/62.0/118 | PASS |
| walk_west/walk_west_0000.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/65.0/119 | PASS |
| walk_west/walk_west_0001.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/62.0/118 | PASS |
| walk_west/walk_west_0002.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/62.0/117 | PASS |
| walk_west/walk_west_0003.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/64.5/118 | PASS |
| walk_west/walk_west_0004.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/66.0/119 | PASS |
| walk_west/walk_west_0005.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/61.5/118 | PASS |
| walk_west/walk_west_0006.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/62.5/117 | PASS |
| walk_west/walk_west_0007.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/63.5/118 | PASS |

ALL PASS: True (32/32)
