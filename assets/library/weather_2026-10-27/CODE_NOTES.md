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
