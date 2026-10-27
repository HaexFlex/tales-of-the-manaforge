# Surprises: firefly jar + Manatree canopy tints (2026-10-27)

## Firefly jar (Bench prop)
`assets/art/hub/bench_props/firefly_jar_{empty,1,10,50}_10x14.png` — 10×14, warm glow only (no cyan).
Levels match Design catches: empty, then brighter at **1 / 10 / 50**.
Placement (KeepersBench origin = bench feet, `centered=false`):
- Teacup (r3): (46, -100)
- **Jar top-left: (58, -102)** — just right of the teacup / near the lantern
- z_index +1 over bench. Swap texture by catch count thresholds: 0 → empty; 1–9 → `_1`; 10–49 → `_10`; 50+ → `_50`.

## Manatree canopy tints (cosmetic seed swap)
`assets/art/manatree/native/tints/{default,blossom,autumn}/manatree_<stage>.png` for sapling..ancient.
- **default** — live greens
- **blossom** — pink-rose canopy
- **autumn** — amber canopy
Bark browns and cyan mana veins are unchanged (HSV classifier).
Shader LUT: `assets/art/manatree/native/tints/canopy_tint_lut.json` (sample swaps + hue targets). Prefer a canvas_item shader that recolours only canopy-class texels; full PNG swaps are the fallback.
