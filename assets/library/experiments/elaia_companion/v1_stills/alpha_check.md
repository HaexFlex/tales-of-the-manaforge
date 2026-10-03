# Frame / alpha check (tools/check_frames.py)

Hard 0/255 alpha; reference anchor = live keeper_walk_south / idle_south (sole row 123, feet x 63.5, height 122).

| frame | RGBA | 128x128 | border clear | alpha0 RGB!=0 | semi px | magenta on edge | magenta anywhere | purple tint on edge | light fringe | non-palette | sole/feet x/height | PASS |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| elaia_still_s.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/63.0/116 | PASS |
| elaia_still_n.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/63.5/115 | PASS |
| elaia_still_e.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/63.5/115 | PASS |
| elaia_still_w.png | True | True | True | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 123/63.5/115 | PASS |

ALL PASS: True (4/4)
