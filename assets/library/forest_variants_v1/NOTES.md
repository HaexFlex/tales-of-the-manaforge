# Forest ring variants v1: 9 trees + 10 bushes (+85 sized copies)

Additive art for the thick forest ring (Code's ring: de35caa).
- `assets/art/hub/hub_deco_meta.json` is untouched (verify_headless asserts 6 + 6). The new pieces are described in
  `assets/art/hub/hub_deco_variants_meta.json`.
- Nothing in `scenes/` or `scripts/` changed.

## Variants (native size, sprite_scale 1)
| file | size | content | source |
|---|---|---|---|
| trees/ring_tree_conifer_01 | 232x400 | 226x398 | trees_A_1 cell 1 (spruce) |
| trees/ring_tree_conifer_02 | 224x352 | 215x351 | trees_A_1 cell 2 (fuller conifer) |
| trees/ring_tree_tall_01 | 128x400 | 118x397 | trees_A_1 cell 3 (long bare trunk, small crown) |
| trees/ring_tree_tall_02 | 136x400 | 120x398 | trees_A_3 cell 3 (longer crown) |
| trees/ring_tree_old_01 | 344x368 | 333x360 | trees_B_3 cell 1 (ancient gnarled) |
| trees/ring_tree_old_02 | 296x336 | 282x334 | trees_B_3 cell 2 (leaning split, hollow knot) |
| trees/ring_tree_old_03 | 344x344 | 332x340 | trees_B_1 cell 1 (darker, hanging moss) |
| trees/ring_tree_old_04 | 272x312 | 260x308 | trees_B_1 cell 2 (smaller leaning split) |
| trees/ring_tree_wide_01 | 368x280 | 357x272 | trees_B_3 cell 3 (umbrella) |
| bushes/ring_bush_round_01 | 120x120 | 116x118 | bushes_A_1 cell 1 |
| bushes/ring_bush_low_01 | 136x96 | 125x89 | bushes_A_1 cell 2 |
| bushes/ring_bush_spiky_01 | 128x112 | 116x105 | bushes_A_1 cell 3 (holly-star) |
| bushes/ring_bush_round_02 | 88x80 | 76x72 | bushes_A_1 cell 5 |
| bushes/ring_bush_spiky_02 | 88x72 | 81x66 | bushes_A_1 cell 6 |
| bushes/ring_bush_low_02 | 96x64 | 89x58 | bushes_A_1 cell 7 |
| bushes/ring_bush_spiky_03 | 120x104 | 114x103 | bushes_A_3 cell 3 (ivy-like) |
| bushes/ring_bush_bloom_01 | 112x96 | 101x90 | bushes_A_3 cell 4 (about 11 cream specks) |
| bushes/ring_bush_spiky_04 | 104x80 | 97x73 | bushes_A_3 cell 6 |
| bushes/ring_bush_bloom_02 | 80x64 | 72x60 | bushes_A_3 cell 8 |

For comparison, the existing set: large 320x400, medium 256x288, slim 160x320, big bush 192x144 (content up to 121x117), small bush 120x72.

## Take selection (both takes used where they differ)
Near-duplicates were judged by silhouette IoU (same height, base-aligned, best of flip_h; `tools/dupes.py`, run on the
pre-selection build) plus a visual check:

| pair | IoU | decision |
|---|---|---|
| conifer A_1 / A_3 | 0.82 / 0.87 | A_3 dropped |
| tall A_1 / A_3 | 0.78 | both kept |
| old B_3 / B_1 | 0.80 | both kept (borderline; B_1 is darker with hanging moss) |
| split B_3 / B_1 | 0.72 | both kept |
| wide B_3 / B_1 | 0.81 | B_1 dropped (B_3 is larger) |
| bushes round / low / bloom | 0.885-0.905 | one each: A_1 round and low, A_3 bloom (sparser blossoms) |
| bushes spiky | 0.84-0.85 | both kept (holly-star vs ivy-like) |

For comparison, two intended-different conifers from the same sheet score 0.79-0.83.

## Pipeline (`tools/build_variants.py`, hub v3 helpers from /workspace/hub_v3/tools/build_hub_v3.py and /workspace/art_refresh/tools)
1. Key: the live #FF00FF keyer (C.remove_background, corner-sampled bg, despill, islands under 40 px dropped).
2. Slice: `slice_by_blobs` on the 3x1 or 4x2 grid.
3. Scale: ONE shared factor per sheet. The tallest cell of the sheet (including dropped cells) gets the target content height:
   - trees_A_1 / A_3: 398 (tall conifer and tall narrow about 400, like large_*)
   - trees_B_3: 360 (old_01 360, wide 272)
   - trees_B_1: 340
   - bushes A_1 / A_3: 118 (the big round bush is the size of big_01; the small row lands at 58-73 like small_*)
4. Pixelize: `C.pixelize` box filter, per-file palette (cap 40 trees / 27 big / 24 medium / 20 small bushes;
   trees land at 34, bushes 19-24), no outline, hard alpha.
5. Teal strip: teal/cyan-hued px -> nearest non-teal colour (0 found). `clean_magenta` removes pink/jpg fringe (0 left).
6. Anchor: the trunk base (midpoint of the bottom 3% band) is centred on the canvas, base on the bottom row.
   - Width and height are rounded up to multiples of 8, with at least 1 px pad on the sides and top.
   - The node origin = trunk base, matching forest_prop.gd's `offset = (-w/2, -h)`.
7. Checks (build.json, all 104 files pass):
   - hard alpha, transparent RGB 0, magenta 0, pinkish 0, teal 0, blue/indigo 0
   - base row = bottom row, base centre within 1 px of canvas centre, even width
8. Berry lookalike check: `previews/bloom_vs_berry_node_x2.png`.
   - The blossoms are tiny cream 4-petal specks on fresh green.
   - The berry node is an indigo bush with big blue and teal orbs.
   - Clearly different at 1x.

## Sized copies (`sized/<name>_sNNN.png`, 85 files)
- Trees: buckets 0.95, 1.05, 1.10, 1.15, 1.25. Bushes: buckets 0.95, 1.05, 1.10, 1.15.
- Each copy is re-rendered from the raw slice at factor x bucket (never an upscale of the 1x PNG), base-centred like the base files.
- Listed in the meta under `sized` with `variant_of` + `display_scale`. Bucket 1.00 = the base file.

## Colliders (meta `collider`)
- Rule from `data/hub_map.json` `collision`: trees `[clamp(0.16 * canvas_w, 14, 36), 16]`, bushes `[16, 10]`.
- Ring fill (ThickTree_/ThickBush_, forest_visual.tscn) has no collider. Edge pieces (forest_solid.tscn) use collider_size.

## Godot import
- `.import` files are included. They were generated with the box's Godot 4.3 `--import` (fresh uids), and their [params] block
  was normalised to the repo's 4.7 format: the same keys as ring_tree_large_01.png.import, lossless, no mipmaps.
- 4.3 rewrote 605 unrelated .import files. All of those changes were reverted; only the new files are committed.
