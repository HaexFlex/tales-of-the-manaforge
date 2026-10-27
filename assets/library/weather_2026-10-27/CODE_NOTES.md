# Weather FX (2026-10-27)

## Particle sheets (`assets/art/fx/weather/`)
| Sheet | Size | Frames | Use |
|---|---|---|---|
| rain_streak_strip_2x6x4.png | 8×6 | 4 | soft rain, NEAREST, scale 1 |
| mist_puff_strip_8x6x4.png | 32×6 | 4 | low mist, dither fade |
| snow_flake_small_strip_3x3x4.png | 12×3 | 4 | light snow (small) |
| snow_flake_large_strip_5x5x4.png | 20×5 | 4 | light snow (large) |
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

## NE outer-hem fill pass 3 (Art ringcheck 2026-10-27)

Pass-2 HemR6 trunks at y≈148–240 put tall-tree crowns **above** the NE camera top
(visible world y starts ≈120). Only ~0.3% of NE pixels changed. Gaps remain as grass
between trunks in the top ~200 px of `*_ne`.

**Fix:** place dense low/wide bushes with trunk bases further **south** so the sprite
span `[y-H, y]` covers the gap band (world y ≈ 130–280). Prefer hem walls / understory
pads over more tall trees.

New art (native 1×, hard alpha):
- `assets/art/hub/bushes/ring_bush_hem_wall_01.png` (474×118)
- `assets/art/hub/bushes/ring_bush_hem_wall_02.png` (427×103)
- `assets/art/hub/bushes/ring_bush_understory_pad_01.png` (244×157)

### Suggested placements (seed `r6_ne_hem_20261027_p3`)

Keep HemR6_0001–0012. **Add** these (do not delete pass-2). `sprite_scale=1.0`,
`y_sort_enabled=true`, trunk base = `position.y`.

| # | sprite | world x | world y | prop_kind | collider_size | covers gap ≈ |
|---|---|---|---|---|---|---|
| 13 | `ring_bush_hem_wall_01.png` | 3865 | 230 | bush | (80, 14) | (3865,140) top patch |
| 14 | `ring_bush_hem_wall_02.png` | 3940 | 310 | bush | (72, 14) | (3940,250) big mid |
| 15 | `ring_bush_understory_pad_01.png` | 3833 | 280 | bush | (48, 14) | (3833,192) |
| 16 | `ring_bush_hem_wall_01.png` | 3758 | 250 | bush | (80, 14) | (3758,167) |
| 17 | `ring_bush_hem_wall_02.png` | 3795 | 220 | bush | (72, 14) | (3795,134) |
| 18 | `ring_bush_understory_pad_01.png` | 3926 | 270 | bush | (48, 14) | (3926,190) |
| 19 | `ring_bush_big_01_flip.png` | 3816 | 300 | bush | (40, 14) | (3816,235) |
| 20 | `ring_bush_cluster_fill_02.png` | 4000 | 290 | bush | (56, 14) | east densify |
| 21 | `ring_tree_slim_01_flip.png` | 3900 | 420 | tree | (22, 14) | canopy into gap band (H=320 → span 100–420) |
| 22 | `ring_tree_conifer_02_flip.png` | 3980 | 450 | tree | (28, 16) | canopy into gap band (H=352 → span 98–450) |
| 23 | `ring_bush_hem_wall_01.png` | 3600 | 280 | bush | (80, 14) | west NE shoulder (3595,311) |
| 24 | `ring_bush_low_01_flip.png` | 4050 | 260 | bush | (32, 10) | NE densify |

Also **nudge** pass-2 tall trees south if easy (same sprites):
- HemR6_0001 conifer: (3848, 148) → **(3848, 380)**
- HemR6_0002 slim: (3920, 168) → **(3920, 400)**
- HemR6_0003 tall: (4088, 152) → **(4088, 420)**
- HemR6_0012 slim: (4160, 240) → **(4160, 430)**

Bushes HemR6_0004–0011 can stay. Keep `FOREST_SEAL leaked=no`. Stay outside clearing ellipse.

## NE canopy backdrop band (Director ring-fix, 2026-10-27)

Prop passes left grass still showing between ring crowns in the NE. New approach:
one continuous canopy backdrop band behind the ring trees so gaps read as deep
forest interior, not ground.

### Art (native 1×, hard alpha only — alpha ∈ {0,255})

| file | size (W×H) | role |
|---|---|---|
| `assets/art/hub/canopy_band/canopy_band_north_01.png` | **256×288** | repeats along **x** |
| `assets/art/hub/canopy_band/canopy_band_east_01.png` | **192×256** | repeats along **y** |
| `assets/art/hub/canopy_band/canopy_band_ne_corner_01.png` | **192×288** | NE join where the two bands meet |

South / inward edges are a ragged leaf silhouette, dithered whole pixels,
~16–24 px deep (no semi-transparent pixels). Outer edges (north top, east right)
stay fully opaque against the world edge.

3× seam proofs (Art local): `previews/canopy_band_north_3x.png`,
`previews/canopy_band_east_3x.png`, `previews/canopy_band_3x_seamcheck.png`.
Mock under current NE caps: `previews/ne_canopy_band_contact.png`.

### World extents (covers measured NE gaps; slightly bigger than the
Director minimum x 3300–4140 / y 180–450)

Play area is 4320×3780; camera limits L180 T180 R4140 B3600. NE cam parks
~(3720, 390). Measured gap world samples clustered around x≈3320–4060,
y≈130–230 (grass between crowns inside the limits).

| band | x0 .. x1 | y0 .. y1 | notes |
|---|---|---|---|
| **North** | **3300 .. 3948** | **162 .. 450** | height = tile H (288). Starts 18 px above cam-limit top for margin. |
| **NE corner** | **3948 .. 4140** | **162 .. 450** | one corner sprite; same y span as north. |
| **East** | **3948 .. 4140** | **450 .. 1100** | continues south along the east ring past the NE view so the band does not end in-frame when the camera pans. |

Together the north+corner span **x 3300–4140, y 162–450** (bigger than the
requested y 180–450 by 18 px on the north side). East extends to **y 1100**.

Tile placement (Sprite2D or TextureRect under a non-Y-sorted node):
- North: place tiles at `x = 3300 + n*256`, `y = 162`, for `n = 0..2` (covers to 3300+768=4068; clip/overlap under corner as needed). Prefer a single `Sprite2D` with region/repeat if available, else 3 instances.
- Corner: one sprite at `(3948, 162)`, texture `canopy_band_ne_corner_01.png`. Centered vs top-left: use **top-left** origin for band sprites (not ForestProp foot origin).
- East: tiles at `x = 3948`, `y = 450 + m*256`, for `m = 0..2` (450..1218; stop by y 1100).

### Z-order / Y-sort

- **Do not** put the band under the `World` Y-sort root (`y_sort_enabled = true`, `z_index = 1`).
- Place a sibling node of `World`, e.g. `CanopyBand` on the scene root:
  - `z_index = 0` (Ground / world-edge stay at/below this; ring props in `World` stay at `z_index = 1`)
  - `y_sort_enabled = false`
  - no CanvasLayer required; a plain `Node2D` is enough
- Band draws **behind** ring trees / HemR6 props and **in front of** ground + world edge.
- Band **does not** participate in Y-sort.

Tracked as its own ring fix — not a weather-PR blocker.

## NE canopy band extension — mid-right fill (2026-10-27)

After placing the north/east/corner band @ 88eb948, NE top reads solid, but
bright grass still shows **mid-right** between broadleaf and conifer crowns,
mostly **below y 450 and west of the east strip (x < 3948)**, plus east-feather
holes around x 3990–4120. Upper slivers (mist/snow/blossom) remain inside the
existing north band footprint — this extension does **not** claim to close those.

### New art

| file | size (W×H) |
|---|---|
| `assets/art/hub/canopy_band/canopy_band_ext_mid_01.png` | **384×320** |

Native 1×, hard alpha only. West + south edges: ragged leaf silhouette ~16–24 px
(dithered whole pixels). North edge opaque (tucks under north band). East edge
opaque above the south feather (joins/overlaps the east column).

### Placement (same CanopyBand node)

- Parent: `CanopyBand` (`z_index = 0`, `y_sort_enabled = false`) — unchanged.
- Sprite2D `Ext_Mid_00`: texture `canopy_band_ext_mid_01.png`, `centered = false`,
  `texture_filter = 0`, **position = Vector2(3700, 430)**.
- World coverage: **x 3700 .. 4084**, **y 430 .. 750**.
- Outside clearing ellipse (sample corners all > 1.8). Stays off paths / features.
- Does not participate in Y-sort. Draws behind ring props (World z=1).

Measured mid-right gap union (cam NE ~(3720,390), vp 960×540) was roughly
world (3680,400)–(4159,564); this panel covers that band through the east join.

## NE camera + opaque-interior harden (2026-10-27)

### Cause of “gaps inside north band footprint”

**Primary cause: (d) camera mapping was wrong in Art measurement.**

Capture parks NE at `camera_max().x, camera_min().y`. With Camera2D limits
L180/T180/R4140/B3600 and view 960×540 (half=480,270):

- `camera_min` = (660, 450)
- `camera_max` = (3660, 3330)
- **NE cam = (3660, 450)** — not ~(3720, 390)

World from screen: `wx = 3180 + sx`, `wy = 180 + sy`.
Prior Art reports used `wx = 3240 + sx`, `wy = 120 + sy` (offset −60x / +60y),
which misplaced mid-right / below-band grass as “inside” y162–450.

Remapped cited examples (clear_ne):
| cited (wrong) | screen | true world | note |
|---|---|---|---|
| (3483,212) | (243,92) | (3423,272) | band opaque; pixel is dark canopy, not grass |
| (3591,241) | (351,121) | (3531,301) | band opaque; bright pixel is prop leaf highlight (high local std) |
| (3861,418) | (621,298) | (3801,478) | **below** north band (y>450); needs ext panel |
| (3680,407) | (440,287) | (3620,467) | **outside** north band; no tile |

**(b)** Placement matches CODE_NOTES (North at 3300/3556/3812×162, corner 3948×162,
east 3948×450/706/962, centered=false). **(c)** CanopyBand z=0 after Ground in tree
order; World z=1 — band is above ground, behind props. No Code z change.

### Code-side follow-ups

1. Place `Ext_Mid_00` Sprite2D under `CanopyBand`: texture
   `canopy_band_ext_mid_01.png`, `centered=false`, `position=Vector2(3700, 430)`.
2. No camera/z change required. When logging caps, print `cam.position` so Art
   does not re-assume NE ~(3720,390).
3. Optional: Art CODE_NOTES NE note is now (3660, 450).

### Opaque-interior harden (secondary)

Interior opaque coverage (excluding south ~24 px feather, and west ~24 px on
east/corner/ext) was 99.55–99.85%, not 100%. Retimed same filenames with
**100% opaque interiors**; ragged feather only on south (north tile) or
south+west (east/corner/ext). Hard alpha preserved.

## Snow flakes (readable @1x, 2026-10-27)

Old `snow_flake_strip_3x3x4.png` (pure white) → `assets/library/legacy/snow_flake_3x3x4_2026-10-27/` (+ REPLACED.md).

| Sheet | Cell | Strip | Frames |
|---|---|---|---|
| `snow_flake_small_strip_3x3x4.png` | 3×3 | 12×3 | 4 horizontal |
| `snow_flake_large_strip_5x5x4.png` | 5×5 | 20×5 | 4 horizontal |

**Frame layout** (both sizes, left→right):
0. rest — bright + / diamond with cool-blue outline
1. soft — same pose, lighter outline / gentler
2. twinkle — smaller spark (center-weighted)
3. rotate — X / diagonal pose

Palette: near-white `#f4f8fc` body, darker core `#b8c4d4`, soft cool-blue outline `#7a8ea8` / `#9aacc0`. Hard alpha (0/255). Cozy, not stormy.

Code: mix small + large on the Snow emitter (e.g. two ParticleProcessMaterial textures or random atlas). **Amount and spread stay Design's** — art only swapped the texture readability.
