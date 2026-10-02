# Frame / alpha check (tools/check_frames.py)

Hard 0/255 alpha; reference anchor = live keeper_walk_south / idle_south (sole row 123, feet x 63.5, height 122).

| frame | RGBA | 128x128 | border clear | alpha0 RGB!=0 | semi px | magenta on edge | magenta anywhere | purple tint on edge | light fringe | non-palette | sole/feet x/height | PASS |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| option_a/keeper_still_s.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/63.5/119 | PASS |
| option_a/keeper_still_se.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/63.5/120 | PASS |
| option_a/keeper_still_e.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/63.0/119 | PASS |
| option_a/keeper_still_ne.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/63.0/118 | PASS |
| option_a/keeper_still_n.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/63.5/120 | PASS |
| option_a/keeper_still_nw.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/64.0/118 | PASS |
| option_a/keeper_still_w.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/63.0/122 | PASS |
| option_a/keeper_still_sw.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/63.5/123 | PASS |

ALL PASS: True (8/8)
