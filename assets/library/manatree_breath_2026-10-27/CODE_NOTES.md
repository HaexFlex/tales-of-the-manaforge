# Manatree breath: leaf drift sprite + sway review (2026-10-27)

## New art (assets/art/manatree/leaf_drift/)
- leaf_drift_atlas_4x3.png: 24x15, 4 flutter frames (6x5 each) x 3 rows: green, amber, mana-cyan.
- leaf_drift_{green,amber,mana}_strip.png: 24x5, 4 frames each. leaf_drift_{green,amber,mana}.png: single 6x5 frame.
- Colours sampled from manatree_mature.png leaves/bark and the cyan veins. Hard alpha.

## Swap for Code (scripts/manatree.gd)
- `_leaf_placeholder_tex()` (2x2 Image) -> `res://assets/art/manatree/leaf_drift/leaf_drift_atlas_4x3.png`.
- For the flutter: give LeafDrift a CanvasItemMaterial with particles_animation=true, particles_anim_h_frames=4,
  particles_anim_v_frames=3, loop on; set `anim_speed_min/max` ~0.8-1.2 and `anim_offset_max=1.0` so the
  row (colour) and phase vary per leaf. With v_frames=3 an offset spread picks rows; if you want mostly
  green, use the green strip (h_frames=4, v_frames=1) and a second 1-amount emitter with the mana strip.
- Keep texture_filter NEAREST; do not set scale_amount != 1.

## Sway verdict
The shader moves the quad's vertices (a Sprite2D is 4 verts), so it is NOT pixel-snapped: it is a
sub-pixel shear. With nearest sampling you get one horizontal "tear" row per px of offset that crawls
up/down the crown as the sine runs - shimmer, not sway. Amps below 1 px only produce that tear line
in the crown top, never a clean move. Also, w = -VERTEX.y/crown_h means the trunk/roots shear too unless
the sprite's origin sits at the canopy base. And frequency currently RISES with size (0.18 -> 0.30 Hz),
which reads backwards: big trees should move slower.

Recommended: snap in the shader -> `VERTEX.x += round(sin(TIME*sway_hz*TAU) * sway_amp_px * w);`
(or step w into 2-3 bands so the crown moves in whole-pixel blocks), then:

| stage   | amp px | Hz   | leaves | reason |
|---------|--------|------|--------|--------|
| sapling | 1      | 0.30 | 1      | 0.6 px never reaches a whole pixel when snapped; 1 px is the minimum visible step, quick like a twig |
| young   | 1      | 0.26 | 2      | still light wood, slightly slower |
| mature  | 1      | 0.22 | 3      | 1 px over a taller crown already reads as sway; 4 leaves on a mid tree is busy at 6x5 px |
| elder   | 2      | 0.19 | 5      | heavier crown, bigger arc, slower |
| ancient | 2      | 0.16 | 7      | slowest, largest; 2 px max keeps the leaf art intact (3+ px tears visibly) |

Leaf counts: lifetime 5 s, so N leaves = N on screen; 1/2/3/5/7 keeps it calm. Your 1/2/4/6/8 is fine
if the canopy is wide.
