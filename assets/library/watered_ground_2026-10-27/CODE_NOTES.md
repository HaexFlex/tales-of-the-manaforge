# Watered-ground damp decal (2026-10-27)
assets/art/hub/ground/damp/damp_soil_<size>_<step>.png, steps 0_full, 1_66, 2_33, 3_faint
(fade done by 4x4 Bayer dither, hard alpha only; edges also dithered).
Sizes from the live glow-strip frames (manatree_meta.json, display_scale 1), root spread at/below door_floor:
| decal   | px      | fits stage(s) | measured root spread (w x h below door) |
|---------|---------|---------------|------------------------------------------|
| sapling | 56x16   | sapling       | ~42 x 8                                  |
| young   | 80x22   | young         | ~60 x 8                                  |
| mature  | 420x100 | mature        | ~400 x 76                                |
| ancient | 576x120 | elder, ancient| ~550 x 68 / ~560 x 72                    |
Colours: hub tileset greens/path browns, value x0.72 and hue nudged ~12% toward blue.
Code: centre the decal on the tree's door_floor x, top edge ~4 px above door_floor y (so it peeks out past the roots).
Draw BELOW the tree: a Sprite2D sibling under the Y-sort root with a lower z_index (or put it on the ground layer),
not inside the tree's sort. After watering show step 0, then step to 1/2/3 at ~8 s, 16 s, 24 s and hide at ~30 s.
