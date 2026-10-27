# Weather FX (2026-10-27)

## Particle sheets (`assets/art/fx/weather/`)
| Sheet | Size | Frames | Use |
|---|---|---|---|
| rain_streak_strip_2x6x4.png | 8×6 | 4 | soft rain, NEAREST, scale 1 |
| mist_puff_strip_8x6x4.png | 32×6 | 4 | low mist, dither fade |
| snow_flake_strip_3x3x4.png | 12×3 | 4 | light snow |
| blossom_petal_strip_4x4x4.png | 16×4 | 4 | blossom fall (pink; not leaf_fall) |
| puddle_sparkle_strip_12x8x4.png | 48×8 | 4 | ground sparkles after rain |

## Wet ground
- Overlay: `wet_ground_tint_64.png` (cool darkened grass sample) OR modulate TileMap ~ `(0.72, 0.75, 0.82)` with hue nudge blue.
- Optional puddle decals along path tiles only.

## Emission / forest-ring rule
Emit **only in the ring band** (outer ~10–25% of clearing radius). Never over the clearing centre.
`clearing_emit_map_160x90.png` shows the band (blue dots) vs open centre (green) and the 4 camera corner markers (gold).
CPUParticles2D: EMISSION_SHAPE_POINTS along ring tree/bush canopy edges; amount rain 40–60 / mist 12 / snow 20 / blossom 10 across the visible ring; whole-pixel snap on; z above ground, below canopy tops.
Corners: keep emitters wrapping the ring so a camera parked in any corner still sees particles in-frame — no void.


## NE outer-hem fill (Art ringcheck 2026-10-27 pass 2)

Camera `ne` parks at world ~(3720, 390). See-through grass gaps remain in the **outer NE hem**
(north of the eight EdgeTree_0468–0475 fills, which sit ~y 590–880). Measured gap centroids
from `clear_ne.png` (screen → world at zoom 1):

| label | screen (x,y) | world (x,y) |
|---|---|---|
| top | 607, 21 | 3847, 141 |
| NE_corner | 853, 15 | 4093, 135 |
| big | 684, 117 | 3924, 237 |
| mid | 571, 224 | 3811, 344 |

Code places these (Art does not edit scenes). Use `ForestProp` / EdgeTree pattern,
`sprite_scale = 1.0`, `y_sort_enabled = true`. Trunk base = node `position.y` (sprite offset
puts feet at position; see `forest_prop.gd` offset `-sz.y`).

### Suggested placements (seed `r6_ne_hem_20261027`)

| # | sprite | world x | world y (trunk base) | prop_kind | collider_size | notes |
|---|---|---|---|---|---|---|
| 1 | `res://assets/art/hub/trees/ring_tree_conifer_02_flip.png` | 3848 | 148 | tree | (28, 16) | plug top gap |
| 2 | `res://assets/art/hub/trees/ring_tree_slim_01_flip.png` | 3920 | 168 | tree | (22, 14) | between top/big |
| 3 | `res://assets/art/hub/trees/ring_tree_tall_02_flip.png` | 4088 | 152 | tree | (24, 16) | NE_corner gap |
| 4 | `res://assets/art/hub/bushes/ring_bush_cluster_fill_01.png` | 3910 | 250 | bush | (48, 14) | under big gap canopy |
| 5 | `res://assets/art/hub/bushes/ring_bush_cluster_fill_02.png` | 4005 | 220 | bush | (56, 14) | east of big gap |
| 6 | `res://assets/art/hub/bushes/ring_bush_big_01_flip.png` | 3815 | 360 | bush | (40, 14) | mid gap |
| 7 | `res://assets/art/hub/bushes/ring_bush_big_02_flip.png` | 3975 | 310 | bush | (40, 14) | densify hem |
| 8 | `res://assets/art/hub/bushes/ring_bush_spiky_01_flip.png` | 4055 | 280 | bush | (32, 12) | densify hem |
| 9 | `res://assets/art/hub/bushes/ring_bush_round_01_flip.png` | 3880 | 200 | bush | (28, 12) | low fill |
| 10 | `res://assets/art/hub/bushes/ring_bush_low_01_flip.png` | 4120 | 190 | bush | (32, 10) | map-edge hem |
| 11 | `res://assets/art/hub/bushes/ring_bush_small_02_flip.png` | 3785 | 280 | bush | (24, 10) | west shoulder |
| 12 | `res://assets/art/hub/trees/ring_tree_slim_01_flip.png` | 4160 | 240 | tree | (22, 14) | far NE hem |

Ring-angle hint (clearing center 2160,2025): these sit near map north, angle ≈ −80° to −95°
from center (outer hem, not the clearing ellipse edge at norm 1.0). Keep `FOREST_SEAL leaked=no`.
Do not place into the playable clearing (inside rx/ry). Nudge ±8–16 px if a trunk collides.

### New art files (native 1×, hard alpha)
- bushes: `ring_bush_*_flip.png`, `ring_bush_cluster_fill_01.png`, `ring_bush_cluster_fill_02.png`
- trees: `ring_tree_slim_01_flip.png`, `ring_tree_tall_02_flip.png`, `ring_tree_conifer_02_flip.png`
