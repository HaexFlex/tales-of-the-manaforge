# Forest ring variants: Grok Imagine prompts (image mode)

Branch `fix/waypoint-pass` @ de35caa. Nothing committed. Use the same style block as hub v3. It's the forge SPEC §7.0 block used for `hub_trees_A/B` and `hub_bushes_A`, the prompts that produced the current ring art, copied verbatim at the end of every prompt.

**Attach:**
- Tree prompts: `/workspace/forest_variants/attach/ref_trees_x4_magenta.png`
- Bush prompt: `/workspace/forest_variants/attach/ref_bushes_x4_magenta.png`

Ideally generate landscape (about 3:2, like the hub v3 raws at 1168x784).

**Why the trees are split into 2 sheets of 3:**
- The large ring trees are 400 px tall at native size. A 6-tree sheet (3x2) at about 1168x784 gives each tree only about 330-350 raw px of height, so processing would have to upscale them and the pixel grid would no longer match.
- With 3 per sheet, each tree gets about 700 raw px, about 0.55 raw px per native px, like hub v3.
- Bushes are small (144 px max), so 8 fit on one sheet.

**Save raws as:**
- `/home/box/Downloads/forest_trees_A_<n>.png`
- `/home/box/Downloads/forest_trees_B_<n>.png`
- `/home/box/Downloads/forest_bushes_A_<n>.png`

Any extension is fine. Several tries each are welcome. I'll pick, slice, pixelize and check them.

---

## Prompt 1: trees A (2 conifers + 1 tall narrow), file `forest_trees_A`

```
A 3×1 grid of 3 separate new forest-ring trees for the edge of a forest clearing, matching the attached reference sheet exactly in pixel scale, pixel grid, bark and leaf rendering, colours and top-left light, each centred in its own equal cell with a wide empty magenta gap around it, none touching, all drawn at ONE consistent pixel scale, each standing upright on an invisible ground line near the bottom of its cell with the trunk base centred in the cell. 1) a tall evergreen conifer (spruce/fir) filling the full cell height: a straight brown trunk visible only near the base with small flared mossy roots, and stacked layered tiers of dense dark-green needle boughs that droop slightly at the tips, narrowing to a pointed top, lit on the top-left edges of each tier with fresh green, deep shadow green under each tier. 2) a shorter, fuller conifer about 80% of the first one's height, broad cone shape with softer rounded tiers, a little moss on the lower boughs. 3) a tall narrow deciduous tree filling the full cell height: a long slender slightly curved trunk with fine vertical bark ridges, bare for the lower third, with a tall narrow oval crown of clustered small leaf clumps on top, like the attached slim tree but with a higher crown and a visible bare trunk. All three share the reference's warm brown bark and its fresh-green small-clump leaf rendering (needles on the conifers drawn with the same pixel size and the same greens, a touch deeper). No door, no face, no fruit, no flowers, no berries, no glowing leaves, no teal or blue foliage. 16-bit SNES-style pixel art matching the Tales of the Manaforge style board: crisp dark outlines, limited palette, clean hand-placed pixels, soft top-left light, no blur, no smooth gradients, no photo texture. Manatree A2 look: warm brown bark (#3f2c14, #5a3f20, #76522d), fresh green leaves and moss (#29570f, #336010, #5f831d), glowing teal mana veins (#12816d, #1f9c87, #2fbea8, bright #4de0cd). It belongs in the enchanted forest clearing of the title screen: roots, moss, small leaves. Classic SNES RPG 3/4 top-down prop view. Flat solid #FF00FF magenta background filling the whole image. No ground, no floor, no cast shadow, no text, no letters, no numbers, no border, no frame, no other objects. No pink, magenta, rose or hot purple anywhere on the subject.
```

Sidecar `grid=3x1`, names in reading order: `ring_tree_conifer_01`, `ring_tree_conifer_02`, `ring_tree_tall_01`.

---

## Prompt 2: trees B (2 dark old gnarled + 1 short wide), file `forest_trees_B`

```
A 3×1 grid of 3 separate new forest-ring trees for the edge of a forest clearing, matching the attached reference sheet exactly in pixel scale, pixel grid, bark and leaf rendering and top-left light, each centred in its own equal cell with a wide empty magenta gap around it, none touching, all drawn at ONE consistent pixel scale, each standing upright on an invisible ground line near the bottom of its cell with the trunk base centred in the cell. 1) an ancient dark gnarled tree filling the full cell height: a massive twisted trunk with deep bark furrows in darker, older browns, thick moss patches, big knotted roots spreading over the ground line, crooked heavy branches, and a dense but slightly ragged crown of clustered small leaf clumps in deeper, darker greens than the reference (shadow-heavy, fewer bright highlights), still alive and leafy. 2) a second old gnarled tree about 85% of the first one's height, its trunk leaning and splitting into two crooked limbs, a hollow knot, hanging moss strands, a darker smaller crown in deep greens. 3) a short wide spreading tree about 60% of the first one's height but as wide as its cell: a short thick trunk, long low horizontal branches, and a broad flat-topped umbrella crown of clustered small leaf clumps in the reference's fresh greens. All three share the reference's warm-brown bark family and small-clump leaf rendering, the old ones just darker and mossier. No door, no face, no fruit, no flowers, no berries, no dead bare branches, no glowing leaves, no teal or blue foliage, no glowing mana veins. 16-bit SNES-style pixel art matching the Tales of the Manaforge style board: crisp dark outlines, limited palette, clean hand-placed pixels, soft top-left light, no blur, no smooth gradients, no photo texture. Manatree A2 look: warm brown bark (#3f2c14, #5a3f20, #76522d), fresh green leaves and moss (#29570f, #336010, #5f831d), glowing teal mana veins (#12816d, #1f9c87, #2fbea8, bright #4de0cd). It belongs in the enchanted forest clearing of the title screen: roots, moss, small leaves. Classic SNES RPG 3/4 top-down prop view. Flat solid #FF00FF magenta background filling the whole image. No ground, no floor, no cast shadow, no text, no letters, no numbers, no border, no frame, no other objects. No pink, magenta, rose or hot purple anywhere on the subject.
```

Sidecar `grid=3x1`, names: `ring_tree_old_01`, `ring_tree_old_02`, `ring_tree_wide_01`.

---

## Prompt 3: bushes (8: small/medium/large; round, spiky, low spread; 2 with tiny pale blossoms), file `forest_bushes_A`

```
A 4×2 grid of 8 separate new forest bushes, matching the attached reference sheet exactly in pixel scale, pixel grid, leaf rendering, colours and top-left light, each centred in its own equal cell with a wide empty magenta gap around it, none touching, all drawn at ONE consistent pixel scale, each standing upright on an invisible ground line near the bottom of its cell with a little moss and brown root at the base. Top row (larger): 1) a large round bush as big as the reference's big bushes but with a lumpier, three-dome outline; 2) a large low spreading bush, twice as wide as it is tall, flat-topped, its edges creeping outward; 3) a medium spiky bush about 75% as tall, with pointed holly/juniper-like leaf tips poking out of the silhouette; 4) a medium bush about 75% as tall dotted with a few tiny pale cream-white blossoms (single 1-2 pixel specks, about a dozen, scattered sparsely over the leaves). Bottom row (small, about half as tall as the top row's large bushes, same pixel scale): 5) a small round tuft bush; 6) a small spiky bush with pointed leaf tips; 7) a small low creeping bush, wide and flat; 8) a small bush with a few tiny pale cream-white blossom specks. All foliage in the reference's fresh greens with dark shadow pockets and light top-left leaf edges; the spiky ones may lean slightly olive. The blossoms are tiny, flat, pale cream or off-white, never round fruit, never blue, teal, indigo or purple, never glowing, so none of these bushes can be mistaken for the harvestable magic berry bush (a dark indigo bush with big glowing blue berries). No berries, no fruit, no glow. 16-bit SNES-style pixel art matching the Tales of the Manaforge style board: crisp dark outlines, limited palette, clean hand-placed pixels, soft top-left light, no blur, no smooth gradients, no photo texture. Manatree A2 look: warm brown bark (#3f2c14, #5a3f20, #76522d), fresh green leaves and moss (#29570f, #336010, #5f831d), glowing teal mana veins (#12816d, #1f9c87, #2fbea8, bright #4de0cd). It belongs in the enchanted forest clearing of the title screen: roots, moss, small leaves. Classic SNES RPG 3/4 top-down prop view. Flat solid #FF00FF magenta background filling the whole image. No ground, no floor, no cast shadow, no text, no letters, no numbers, no border, no frame, no other objects. No pink, magenta, rose or hot purple anywhere on the subject.
```

Sidecar `grid=4x2`, names: `ring_bush_big_04`, `ring_bush_low_01`, `ring_bush_spiky_01`, `ring_bush_bloom_01`, `ring_bush_small_04`, `ring_bush_spiky_02`, `ring_bush_low_02`, `ring_bush_bloom_02`.

---

## Processing plan (after generation)
- **Pipeline:** `/workspace/hub_v3/tools/build_hub_v3.py`, the same one that built the current ring set.
  - Key the magenta, slice equal cells, then pixelize (box) at ONE shared factor per sheet, so the relative heights hold.
  - Canvas: bottom-centred, base on the bottom row, pad 1 on the sides and top.
  - Per-file palette like hub v3: trees 40 colours, big bushes about 27, small bushes 20.
  - No outline, hard alpha, no magenta or pink fringe.
- **Proposed native canvases:**

  | file | native canvas (px) |
  |---|---|
  | conifer_01 | 192x400 |
  | conifer_02 | 192x320 |
  | tall_01 | 160x400 |
  | old_01 | 320x400 |
  | old_02 | 288x352 |
  | wide_01 | 320x256 |
  | big_04, low_01 | 192x144 |
  | spiky_01, bloom_01 | 160x112 |
  | small_04, spiky_02, low_02, bloom_02 | 120x72 |

  Final sizes follow the content at the shared factor, with widths kept even.
- **Optional sized copies:** `sized/` copies like the existing `_s095..s135` (Code's map), if Code wants height jitter at scale 1.
- **Checks:**
  - Size and even width, base row = bottom row, trunk base centred within ±6 px.
  - Hard alpha, transparent RGB 0, no magenta/pink, colour count.
  - Berry lookalike: no blue/teal/indigo hue clusters.
  - Contact sheet next to the existing set and the berry node.
