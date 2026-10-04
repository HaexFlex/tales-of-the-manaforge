# Fix pass 2026-10-02: native scale-1 art, notes for Code

Branch `art/fix-pass-native` (from main `25047b2`). **Additive only**: new files at new paths, no script or scene edits. Merge this into the fix branch, then swap references.
Rule: 1 art px = 1 screen px at scale 1, nearest filtering. Every new file is RGBA with hard alpha (0/255), transparent RGB = 0, no magenta.
Contact sheet (old as drawn in game vs new native, shown x2): `assets/library/fix_pass_2026-10-02/contact_fix_pass.png`.

## 1. Stone node

| new file | size | replaces |
|---|---|---|
| `res://assets/art/props/native/harvest_stone.png` | 92x96 | `props/harvest_stone.png` 46x48 at `HARVEST_SCALE.stone = 2.0` |
| `res://assets/art/props/native/harvest_stone_spent.png` | 92x96 | `props/harvest_stone_spent.png` 64x64 (spent now shares the normal canvas + placement, so a swap does not jump) |

* Re-rendered from the same HD cutout that produced the 46x48 file (`/workspace/art_refresh/new/raw/nodes/harvest_stone.png` 739x739 → cut 568x596; re-running the old 46x48 target from it is byte-identical to the committed file, so provenance is confirmed). Content 88x92, 40 colours (spent 32). Real 2x detail, not an upscale.
* Code: `gatherable.gd` `HARVEST_TEXTURES.stone` → `res://assets/art/props/native/harvest_stone.png`, `HARVEST_SCALE.stone` → `1.0`; `main.tscn:29` ext_resource `26_stone_spent` → `res://assets/art/props/native/harvest_stone_spent.png`.
* Offset is unchanged in code terms: `_apply_art()` already does `offset = (-w/2, -h)` → **(-46, -96)**, bottom centre, on-screen size stays 92x96. Click box = 92x96 as before.
* File names are kept (`…/native/harvest_stone.png`), so `verify_headless.gd:2076` / `scene_sanity.gd:234-235` `ends_with("harvest_stone.png")` / `("harvest_stone_spent.png")` still pass; `verify_headless.gd:164` checks the old path by name (fine until the old file moves).
* Meta: `assets/art/props/harvest_nodes_meta.json` → new key `native_fix_pass_2026-10-02`.

## 2. Runestones

| new file | size |
|---|---|
| `res://assets/art/props/runestones/native/runestones_sheet.png` | 512x512, 8x8 cells of **64** (same cell layout as the 256x256 sheet) |
| `res://assets/art/props/runestones/native/runestone_<stat>.png` (might, arcana, resilience, ward, vitality, swiftness, fate) | 64x64 each = exactly the cell `runestone.gd sheet_cell()` draws |

* **No HD raw exists for the runestones.** The source is Haex's original 256x256 pixel-art sheet (`Runestones.png`, art drop c9fda76) with the vivid glyph recolour of b95d7dc; no Grok/HD version was ever made (checked `/workspace/art_refresh/nodes_v2`, `new/raw`, `art-drop-c9fda76`, library). So the native files are a **clean nearest x2** (labelled fallback): identical on screen to today, but scale 1. A pixel-art-aware Scale2x (EPX) alternative is in `assets/library/fix_pass_2026-10-02/runestones_sheet_scale2x_REVIEW_ONLY.png` (not wired, for Haex to judge).
* Code (sheet route, minimal): `RUNE_SHEET` → `res://assets/art/props/runestones/native/runestones_sheet.png`, `RUNE_CELL` → `64`, `stone.scale` → `Vector2(1, 1)`, `stone.offset` → **`Vector2(-32, -64)`** (in `_ready`, `_apply_editor_preview` and `runestone.tscn`). Label/pick rect unchanged (on-screen size is still 64x64).
* Or the single-file route: `stone.texture = load("res://assets/art/props/runestones/native/runestone_%s.png" % stat_id)`, same scale 1 / offset (-32,-64).
* The old loose `runestones/runestone_<stat>.png` (32x32, not drawn, mostly different cells) moved to `assets/library/legacy/fix_pass_2026-10-02/props/runestones/` (zero references).

## 3. Ring trees / bushes (main.tscn sprite_scale jitter)

* 622 tree/bush ForestProps in `main.tscn` have sprite_scale != 1 (0.78–1.539); ground deco, flowers, rocks and mushrooms are all 1.0/default and need nothing.
* **62 new files** in `res://assets/art/hub/trees/sized/` and `res://assets/art/hub/bushes/sized/`, named `<name>_sNNN.png` (NNN = display scale x100). Re-rendered from the hub v3 HD raw slices (`/workspace/hub_v3/work/*/slices`, raws `/workspace/hub_v3/raw/hub_trees_A|B.png`, `hub_bushes_A.png`) with the exact hub v3 pipeline (scale 1 re-render is byte-identical to the committed originals), factor x bucket. Not upscales of the 1x PNGs.
* Buckets: 0.80, 0.85 … 1.55 in 0.05 steps, **rounded UP** (no tree ever gets smaller than today: a nearest-bucket version shrank some trees by ≤2.6 % and `scene_sanity` then found 5 forest-coverage holes; rounded up it passes). Max size difference 5.15 %, mean ~2.5 %. Bucket 1.00 = the original file.
* Only `ring_tree_large_02_s120` (+1.9 %) and `ring_tree_large_03_s125` (+5.9 %) needed the HD slice slightly upscaled (large trees were rendered at 0.85 raw px/px); still smooth, flagged in the meta.
* Anchor unchanged: base centre, `forest_prop.gd` offset `(-w*0.5, -h)` works as is (all widths even). Colliders (`collider_size` per node) are not scaled by sprite_scale today, so they stay.
* **Mapping JSON:** `res://assets/library/fix_pass_2026-10-02/hub_native_size_map.json` (`rules`: texture → {old sprite_scale string → new texture}; `placements`: all 622 nodes with old/new and % error; `files`: sizes).
* **Rewrite script:** `tools/apply_hub_native_sizes.py` (python3 stdlib). From repo root: `python3 tools/apply_hub_native_sizes.py` (dry run) then `python3 tools/apply_hub_native_sizes.py scenes/main.tscn --write`. It only edits `texture_path` + `sprite_scale` lines of matched blocks (1098 lines; positions/ids/colliders untouched). I did **not** run it on the branch's main.tscn. Trial on a throw-away copy: 622 repointed, 0 missing, `scene_sanity.gd` → SANITY_OK (forest seal + no void).
* Meta: `res://assets/art/hub/hub_deco_sized_meta.json` (v0.3.1-hub-native-sizes: file, variant_of, display_scale, size, content, anchor, offset, collider, raw factor). `hub_deco_meta.json` is untouched (VERIFY asserts version v0.3.0-hub-v3 and 6/6/9 family counts).

Per texture (old scale range → file):

| texture (res://assets/art/hub/…) | old sprite_scale range | count | new texture @ scale 1 | size |
|---|---|---|---|---|
| `bushes/ring_bush_big_01.png` | 0.780–0.780 | 1 | `bushes/sized/ring_bush_big_01_s080.png` | 154x115 |
| `bushes/ring_bush_big_01.png` | 0.953–0.999 | 10 | same file (bucket 1.00) | original |
| `bushes/ring_bush_big_01.png` | 1.003–1.028 | 3 | `bushes/sized/ring_bush_big_01_s105.png` | 202x151 |
| `bushes/ring_bush_big_01.png` | 1.073–1.097 | 3 | `bushes/sized/ring_bush_big_01_s110.png` | 212x158 |
| `bushes/ring_bush_big_01.png` | 1.105–1.117 | 4 | `bushes/sized/ring_bush_big_01_s115.png` | 220x166 |
| `bushes/ring_bush_big_01.png` | 1.539–1.539 | 1 | `bushes/sized/ring_bush_big_01_s155.png` | 298x223 |
| `bushes/ring_bush_big_02.png` | 0.950–0.950 | 1 | `bushes/sized/ring_bush_big_02_s095.png` | 182x137 |
| `bushes/ring_bush_big_02.png` | 0.958–0.993 | 10 | same file (bucket 1.00) | original |
| `bushes/ring_bush_big_02.png` | 1.015–1.046 | 6 | `bushes/sized/ring_bush_big_02_s105.png` | 202x151 |
| `bushes/ring_bush_big_02.png` | 1.076–1.100 | 5 | `bushes/sized/ring_bush_big_02_s110.png` | 212x158 |
| `bushes/ring_bush_big_02.png` | 1.101–1.102 | 2 | `bushes/sized/ring_bush_big_02_s115.png` | 220x166 |
| `bushes/ring_bush_big_03.png` | 0.941–0.942 | 3 | `bushes/sized/ring_bush_big_03_s095.png` | 182x137 |
| `bushes/ring_bush_big_03.png` | 0.958–0.987 | 6 | same file (bucket 1.00) | original |
| `bushes/ring_bush_big_03.png` | 1.008–1.044 | 7 | `bushes/sized/ring_bush_big_03_s105.png` | 202x151 |
| `bushes/ring_bush_big_03.png` | 1.055–1.098 | 11 | `bushes/sized/ring_bush_big_03_s110.png` | 212x158 |
| `bushes/ring_bush_big_03.png` | 1.104–1.118 | 3 | `bushes/sized/ring_bush_big_03_s115.png` | 220x166 |
| `bushes/ring_bush_small_01.png` | 0.942–0.949 | 4 | `bushes/sized/ring_bush_small_01_s095.png` | 114x68 |
| `bushes/ring_bush_small_01.png` | 0.953–0.997 | 9 | same file (bucket 1.00) | original |
| `bushes/ring_bush_small_01.png` | 1.001–1.044 | 6 | `bushes/sized/ring_bush_small_01_s105.png` | 126x76 |
| `bushes/ring_bush_small_01.png` | 1.051–1.099 | 5 | `bushes/sized/ring_bush_small_01_s110.png` | 132x79 |
| `bushes/ring_bush_small_01.png` | 1.103–1.118 | 6 | `bushes/sized/ring_bush_small_01_s115.png` | 138x83 |
| `bushes/ring_bush_small_02.png` | 0.943–0.943 | 1 | `bushes/sized/ring_bush_small_02_s095.png` | 114x68 |
| `bushes/ring_bush_small_02.png` | 0.959–0.989 | 8 | same file (bucket 1.00) | original |
| `bushes/ring_bush_small_02.png` | 1.002–1.049 | 10 | `bushes/sized/ring_bush_small_02_s105.png` | 126x76 |
| `bushes/ring_bush_small_02.png` | 1.068–1.096 | 7 | `bushes/sized/ring_bush_small_02_s110.png` | 132x79 |
| `bushes/ring_bush_small_03.png` | 0.941–0.947 | 2 | `bushes/sized/ring_bush_small_03_s095.png` | 114x68 |
| `bushes/ring_bush_small_03.png` | 0.958–0.999 | 9 | same file (bucket 1.00) | original |
| `bushes/ring_bush_small_03.png` | 1.009–1.045 | 8 | `bushes/sized/ring_bush_small_03_s105.png` | 126x76 |
| `bushes/ring_bush_small_03.png` | 1.054–1.081 | 2 | `bushes/sized/ring_bush_small_03_s110.png` | 132x79 |
| `bushes/ring_bush_small_03.png` | 1.107–1.110 | 2 | `bushes/sized/ring_bush_small_03_s115.png` | 138x83 |
| `trees/ring_tree_large_01.png` | 0.941–0.950 | 2 | `trees/sized/ring_tree_large_01_s095.png` | 304x380 |
| `trees/ring_tree_large_01.png` | 0.952–0.999 | 28 | same file (bucket 1.00) | original |
| `trees/ring_tree_large_01.png` | 1.003–1.050 | 25 | `trees/sized/ring_tree_large_01_s105.png` | 336x420 |
| `trees/ring_tree_large_01.png` | 1.054–1.099 | 15 | `trees/sized/ring_tree_large_01_s110.png` | 352x440 |
| `trees/ring_tree_large_01.png` | 1.101–1.118 | 15 | `trees/sized/ring_tree_large_01_s115.png` | 368x460 |
| `trees/ring_tree_large_02.png` | 0.941–0.941 | 1 | `trees/sized/ring_tree_large_02_s095.png` | 304x380 |
| `trees/ring_tree_large_02.png` | 0.956–0.998 | 14 | same file (bucket 1.00) | original |
| `trees/ring_tree_large_02.png` | 1.001–1.047 | 17 | `trees/sized/ring_tree_large_02_s105.png` | 336x420 |
| `trees/ring_tree_large_02.png` | 1.053–1.100 | 15 | `trees/sized/ring_tree_large_02_s110.png` | 352x440 |
| `trees/ring_tree_large_02.png` | 1.104–1.137 | 10 | `trees/sized/ring_tree_large_02_s115.png` | 368x460 |
| `trees/ring_tree_large_02.png` | 1.162–1.162 | 1 | `trees/sized/ring_tree_large_02_s120.png` | 384x480 |
| `trees/ring_tree_large_03.png` | 0.942–0.949 | 4 | `trees/sized/ring_tree_large_03_s095.png` | 304x380 |
| `trees/ring_tree_large_03.png` | 0.951–0.998 | 15 | same file (bucket 1.00) | original |
| `trees/ring_tree_large_03.png` | 1.001–1.050 | 24 | `trees/sized/ring_tree_large_03_s105.png` | 336x420 |
| `trees/ring_tree_large_03.png` | 1.051–1.100 | 21 | `trees/sized/ring_tree_large_03_s110.png` | 352x440 |
| `trees/ring_tree_large_03.png` | 1.101–1.127 | 11 | `trees/sized/ring_tree_large_03_s115.png` | 368x460 |
| `trees/ring_tree_large_03.png` | 1.216–1.216 | 1 | `trees/sized/ring_tree_large_03_s125.png` | 400x500 |
| `trees/ring_tree_medium_01.png` | 0.941–0.950 | 3 | `trees/sized/ring_tree_medium_01_s095.png` | 244x274 |
| `trees/ring_tree_medium_01.png` | 0.951–0.999 | 17 | same file (bucket 1.00) | original |
| `trees/ring_tree_medium_01.png` | 1.004–1.050 | 18 | `trees/sized/ring_tree_medium_01_s105.png` | 268x302 |
| `trees/ring_tree_medium_01.png` | 1.052–1.098 | 23 | `trees/sized/ring_tree_medium_01_s110.png` | 282x317 |
| `trees/ring_tree_medium_01.png` | 1.102–1.133 | 7 | `trees/sized/ring_tree_medium_01_s115.png` | 294x331 |
| `trees/ring_tree_medium_01.png` | 1.220–1.220 | 1 | `trees/sized/ring_tree_medium_01_s125.png` | 320x360 |
| `trees/ring_tree_medium_01.png` | 1.340–1.340 | 3 | `trees/sized/ring_tree_medium_01_s135.png` | 346x389 |
| `trees/ring_tree_medium_02.png` | 0.940–0.949 | 4 | `trees/sized/ring_tree_medium_02_s095.png` | 244x274 |
| `trees/ring_tree_medium_02.png` | 0.952–0.997 | 22 | same file (bucket 1.00) | original |
| `trees/ring_tree_medium_02.png` | 1.007–1.047 | 20 | `trees/sized/ring_tree_medium_02_s105.png` | 268x302 |
| `trees/ring_tree_medium_02.png` | 1.053–1.097 | 15 | `trees/sized/ring_tree_medium_02_s110.png` | 282x317 |
| `trees/ring_tree_medium_02.png` | 1.101–1.115 | 8 | `trees/sized/ring_tree_medium_02_s115.png` | 294x331 |
| `trees/ring_tree_medium_02.png` | 1.194–1.194 | 1 | `trees/sized/ring_tree_medium_02_s120.png` | 308x346 |
| `trees/ring_tree_medium_02.png` | 1.206–1.218 | 2 | `trees/sized/ring_tree_medium_02_s125.png` | 320x360 |
| `trees/ring_tree_medium_02.png` | 1.320–1.348 | 5 | `trees/sized/ring_tree_medium_02_s135.png` | 346x389 |
| `trees/ring_tree_slim_01.png` | 0.780–0.800 | 39 | `trees/sized/ring_tree_slim_01_s080.png` | 128x256 |
| `trees/ring_tree_slim_01.png` | 0.944–0.944 | 1 | `trees/sized/ring_tree_slim_01_s095.png` | 152x304 |
| `trees/ring_tree_slim_01.png` | 0.958–0.984 | 8 | same file (bucket 1.00) | original |
| `trees/ring_tree_slim_01.png` | 1.012–1.045 | 8 | `trees/sized/ring_tree_slim_01_s105.png` | 168x336 |
| `trees/ring_tree_slim_01.png` | 1.057–1.100 | 16 | `trees/sized/ring_tree_slim_01_s110.png` | 176x352 |
| `trees/ring_tree_slim_01.png` | 1.112–1.118 | 2 | `trees/sized/ring_tree_slim_01_s115.png` | 184x368 |
| `trees/ring_tree_slim_01.png` | 1.157–1.159 | 2 | `trees/sized/ring_tree_slim_01_s120.png` | 192x384 |
| `trees/ring_tree_slim_01.png` | 1.220–1.227 | 17 | `trees/sized/ring_tree_slim_01_s125.png` | 200x400 |
| `trees/ring_tree_slim_01.png` | 1.263–1.272 | 2 | `trees/sized/ring_tree_slim_01_s130.png` | 208x416 |
| `trees/ring_tree_slim_01.png` | 1.340–1.348 | 2 | `trees/sized/ring_tree_slim_01_s135.png` | 216x432 |
| `trees/ring_tree_slim_01.png` | 1.372–1.372 | 1 | `trees/sized/ring_tree_slim_01_s140.png` | 224x448 |
| `trees/ring_tree_slim_01.png` | 1.465–1.465 | 1 | `trees/sized/ring_tree_slim_01_s150.png` | 240x480 |


## 4. HUD icons (HudIcons cells → single 32x32 files)

The sheet (1280x512) is an exact nearest x8 of 32 px art (checked: every 8x8 block is flat), so cutting every 8th pixel gives the true native 32x32 art, lossless, clean hard alpha. Existing single files are kept as they are (no renames).

| cell | const | used by | single 32x32 file |
|---|---|---|---|
| 0 | CHARACTER | hud.gd:359 | `res://assets/art/ui/icons/hud_character.png` (new) |
| 1 | HELP | hud.gd:361, pass_f_playthrough.gd:424 | `res://assets/art/ui/icons/hud_help.png` (new) |
| 2 | ASCENSION | hud.gd:363 | `res://assets/art/ui/icons/hud_ascension.png` (new) |
| 3 | KEEP_TOOLS | unused | `res://assets/art/ui/icons/hud_keep_tools.png` (new, exact cell; the Ascension medallion `ui/icons/icon_asc_keep_tools.png` is different art) |
| 4 | WOODEN_BASKET | index_for_item("wooden_basket") | `res://assets/art/ui/icons/hud_wooden_basket.png` (new) |
| 5 | WATERING_CAN | index_for_item("stone_watering_can") | `res://assets/art/ui/icons/hud_watering_can.png` (new) |
| 6 | STONE_SWORD | old sword art; Flintblade already uses `ui/icon_stone_sword.png` | `res://assets/art/ui/icons/hud_stone_sword_old.png` (new, exact cell, only if anything still wants the old sword) |
| 7 | WEAPON_ROD | index_for_item("weapon_rod") | `res://assets/art/ui/icons/icon_weapon_rod.png` (**existing**, same art and alpha; 154 px differ by palette rounding, mean 0.6/255) |
| 8 | EQUIP_EMPTY | character_sheet.gd:753,775 | `res://assets/art/ui/icons/hud_equip_empty.png` (new) |
| 9 | EQUIP_LOCKED | character_sheet.gd:763 | `res://assets/art/ui/icons/hud_equip_locked.png` (new) |

Other single icons already in use (unchanged): `ui/icon_wood.png`, `ui/icon_stone.png`, `ui/icon_food.png`, `ui/icon_manashards.png` (also title cursor), `ui/icon_essence.png`, `ui/icon_fertilizer.png`, `ui/icon_stone_sword.png` (Flintblade), `ui/icons/icon_*`.
No old→new renames: every existing file keeps its name. Note VERIFY 2061-2175 compare textures to `HudIcons.cell(...)`, so those asserts follow whatever `cell()` returns.

## 5. Library tidy

Moved (git mv) to `assets/library/legacy/library_tidy_2026-10-02/` (see its `REPLACED.md`): `Big Bushes.png`, `Small Trees.png`, `small bushes.png`, `art_drop_c9fda76/` (23 files). `.import` files are git-ignored in this repo, so none were tracked to move. `assets/library/_art_refresh/` does not exist on main.
**Kept for now (VERIFY asserts them):** `assets/library/Big Trees.png` (`verify_headless.gd:192`) and `assets/library/keeper_inbox/` (`verify_headless.gd:193`). Drop/repoint those two asserts, then move both to the same folder.
References Code/docs should update: `tools/slice_haex_inbox.py:21,154-216,335,349` (sheet + keeper_inbox paths), `docs/ASSETS_UPLOAD.md:13` (keeper_inbox), `assets/art/ASSETS_UPLOAD_HANDOFF.md:18-41` (historical sheet names), `assets/art/MANIFEST.json:13,24,87` and `assets/art/keeper/keeper_meta.json:76` (provenance strings only). `assets/library/README.md` updated here.
Not touched: `assets/library/manatree_tries/` (undated, not in the task's list; Haex's call).

## Move after swap (still referenced; git mv to `assets/library/legacy/fix_pass_2026-10-02/` once Code repoints)

| file | live references | replacement |
|---|---|---|
| `assets/art/props/harvest_stone.png` | gatherable.gd:51, verify_headless.gd:164 | `props/native/harvest_stone.png` |
| `assets/art/props/harvest_stone_spent.png` | main.tscn:29 | `props/native/harvest_stone_spent.png` |
| `assets/art/props/runestones/runestones_sheet.png` | runestone.gd:17 | `props/runestones/native/runestones_sheet.png` |
| `assets/art/ui/manaforge_hud_icons_sheet.png` | hud_icons.gd:6, verify_headless.gd:168/1410/2061+, scene_sanity.gd:370 | §4 single icons (keep until SANITY/VERIFY stop reading it) |
| `assets/library/Big Trees.png`, `assets/library/keeper_inbox/` | verify_headless.gd:192-193 | → `assets/library/legacy/library_tidy_2026-10-02/` |

Left in place on purpose: `props/harvest_berry.png` (SANITY/VERIFY), `nodes/harvest_stone.png` and `props/prop_stone.png` (46x48/64x64 aliases, not part of this pass), ring tree/bush originals (bucket 1.00 still uses them).

## Checks run

* Every new PNG: RGBA, alpha only 0/255, transparent RGB = 0, 0 magenta px; dark edge share matches the originals (the art's own outline, not a fringe).
* Godot 4.3 `--headless --import` clean; `tools/scene_sanity.gd` → SANITY_OK on the branch, and SANITY_OK on a throw-away copy with `apply_hub_native_sizes.py --write` applied. Full VERIFY **not** run (not before 22:30 Zurich).
* Build scripts (box paths, for re-runs): `assets/library/fix_pass_2026-10-02/build/`.
