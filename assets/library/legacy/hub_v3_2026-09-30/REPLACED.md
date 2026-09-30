# Legacy move: hub v3 (2026-09-30)

Two parts. Part 1 (`95ab394`) moved the old Manatree stills. Part 2 moved everything else, after Code's Pass I (`6d669c6`) dropped the last live references.

# Part 1

Moved after Code's hub v3 swap landed (Pass H, `0f821e6`). Files keep their subpath under `assets/art/`, mirrored under this folder.
The rule: move only files with **zero live references**. The search covered scripts, scenes, `.tres`, data and meta JSON (including
`assets/art/MANIFEST.json`), `verify_headless.gd`, `scene_sanity.gd`, `polish_smoke.gd`, `playtest_ship.gd` and the tools. `docs/`, `*.md` and
`assets/library/` were excluded. A reference inside the never-run bake path, or inside a still-referenced meta, counts as a reference.

## Moved

| old path | new path | reason |
|---|---|---|
| `assets/art/manatree/manatree_sapling.png` | `assets/art/manatree/native/manatree_sapling.png` | Old v0.1.8-A2 fallback still. `manatree.gd` `STAGE_TEXTURES` and VERIFY 108-112 now use the native still (Pass H, 0f821e6). No live reference left. |
| `assets/art/manatree/manatree_young.png` | `assets/art/manatree/native/manatree_young.png` | Old v0.1.8-A2 fallback still. `manatree.gd` `STAGE_TEXTURES` and VERIFY 108-112 now use the native still (Pass H, 0f821e6). No live reference left. |
| `assets/art/manatree/manatree_mature.png` | `assets/art/manatree/native/manatree_mature.png` | Old v0.1.8-A2 fallback still. `manatree.gd` `STAGE_TEXTURES` and VERIFY 108-112 now use the native still (Pass H, 0f821e6). No live reference left. |
| `assets/art/manatree/manatree_elder.png` | `assets/art/manatree/native/manatree_elder.png` | Old v0.1.8-A2 fallback still. `manatree.gd` `STAGE_TEXTURES` and VERIFY 108-112 now use the native still (Pass H, 0f821e6). No live reference left. |
| `assets/art/manatree/manatree_ancient.png` | `assets/art/manatree/native/manatree_ancient.png` | Old v0.1.8-A2 fallback still. `manatree.gd` `STAGE_TEXTURES` and VERIFY 108-112 now use the native still (Pass H, 0f821e6). No live reference left. |

Hits that don't count as references to these files: `native/manatree_<stage>.png` paths (`manatree.gd` 31-35, `verify_headless.gd` 108-112,
`native/manatree_meta.json` `still_file`), and `scripts/capture_art_ship.gd` 64/68/120 `_shot("manatree_<stage>.png")`, which are screenshot
output filenames.

## Swap back

1. `git mv assets/library/legacy/hub_v3_2026-09-30/manatree/manatree_<stage>.png assets/art/manatree/manatree_<stage>.png` for each stage.
2. Point `scripts/manatree.gd` `STAGE_TEXTURES` (lines 30-36) back to `res://assets/art/manatree/manatree_<stage>.png`, along with
   `META_PATH` (line 29) -> `res://assets/art/manatree/manatree_meta.json`. The old meta and strips moved in part 2, so restore them first (see the part 2 swap-back).
   Also point `verify_headless.gd` 108-114 (plus the version and ancient-frame checks right after) back at the old files.
3. Run the Godot import (`godot --headless --path . --import`), then VERIFY and SANITY.
Or simply `git revert` the legacy-move commit.

# Part 2

Code's Pass I (`6d669c6`) repointed MANIFEST.json, props_meta.json, harvest_nodes_meta.json, main.gd (bake path retired),
pass_f_playthrough.gd, manatree.gd and slice_haex_inbox.py. The part 1 kept list was re-scanned with the same rules (docs, `*.md` and
`assets/library/` excluded). The only remaining mentions were the old catalogs naming their own frames, which moved together. Other matches
were `native/` counterparts, `tiles/grass_0N.png` in `tiles/tiles_meta.json` (a different file), and filename-only checks that now match the native files.

Moved: 178 files (bushes 114, decor 36, manatree 6, props 2, trees 20). Subpaths under `assets/art/` are mirrored below this folder.

**Kept in place:** `assets/art/trees/tree_mana_02..04.png`. They're still live, referenced directly by 84 `texture_path` entries in `scenes/main.tscn`.
Their old catalog entries were inside `trees_meta.json`, which moved because nothing live reads it.

| old path | new path | reason |
|---|---|---|
| `assets/art/bushes/bush_big_01.png` | `assets/art/hub/bushes/ring_bush_big_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_big_02.png` | `assets/art/hub/bushes/ring_bush_big_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_big_03.png` | `assets/art/hub/bushes/ring_bush_big_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_big_04.png` | `assets/art/hub/bushes/ring_bush_big_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_big_05.png` | `assets/art/hub/bushes/ring_bush_big_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_big_06.png` | `assets/art/hub/bushes/ring_bush_big_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_big_07.png` | `assets/art/hub/bushes/ring_bush_big_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_big_08.png` | `assets/art/hub/bushes/ring_bush_big_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_big_09.png` | `assets/art/hub/bushes/ring_bush_big_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_big_10.png` | `assets/art/hub/bushes/ring_bush_big_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_big_11.png` | `assets/art/hub/bushes/ring_bush_big_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_big_12.png` | `assets/art/hub/bushes/ring_bush_big_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_01.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_02.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_03.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_04.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_05.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_06.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_07.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_08.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_09.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_10.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_11.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_12.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_13.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_14.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_15.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_16.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_17.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_18.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_19.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_20.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_21.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_22.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_23.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_24.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_25.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_26.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_27.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_28.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_29.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_30.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_31.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_32.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_33.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_34.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_35.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_36.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_37.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_38.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_39.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_40.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_41.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_42.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_43.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_44.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_45.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_46.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_47.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_48.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_49.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_50.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_51.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_52.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_53.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_54.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_55.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_56.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bush_small_57.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/bushes_meta.json` | `assets/art/hub/hub_deco_meta.json` (families ring_bush_*) | Old bush catalog. Nothing live read it after Pass I. |
| `assets/art/bushes/native/bush_native_01.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/native/bush_native_02.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/native/bush_native_03.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/native/bush_native_04.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/native/bush_native_05.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/native/bush_native_06.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/native/bush_native_07.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/native/bush_native_08.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/native/bush_native_09.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/native/bush_native_10.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/native/bush_native_11.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/native/bush_native_12.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/native/bush_native_13.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/native/bush_native_14.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/native/bush_native_15.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/native/bush_native_16.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/native/bush_native_17.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/native/bush_native_18.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/native/bush_native_19.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/native/bush_native_20.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/native/bush_native_21.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/native/bush_native_22.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/native/bush_native_23.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/native/bush_native_24.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/native/bush_native_25.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/native/bush_native_26.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/native/bush_native_27.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/native/bush_native_28.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/native/bush_native_29.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/native/bush_native_30.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/native/bush_native_31.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/native/bush_native_32.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/native/bush_native_33.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/native/bush_native_34.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/native/bush_native_35.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/native/bush_native_36.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/native/bush_native_37.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/native/bush_native_38.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/native/bush_native_39.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/native/bush_native_40.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/native/bush_native_41.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/native/bush_native_42.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/native/bush_native_43.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/bushes/native/bush_native_44.png` | `assets/art/hub/bushes/ring_bush_small_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/decor/decor_meta.json` | `assets/art/hub/hub_deco_meta.json` (ground and props families) | Old decor catalog. Nothing live read it after Pass I. |
| `assets/art/decor/grass_01.png` | `assets/art/hub/ground/grass_tuft_01..09.png` (+ `fern_01..06`) | Decor grass nodes retextured (Pass H) |
| `assets/art/decor/grass_02.png` | `assets/art/hub/ground/grass_tuft_01..09.png` (+ `fern_01..06`) | Decor grass nodes retextured (Pass H) |
| `assets/art/decor/grass_03.png` | `assets/art/hub/ground/grass_tuft_01..09.png` (+ `fern_01..06`) | Decor grass nodes retextured (Pass H) |
| `assets/art/decor/grass_04.png` | `assets/art/hub/ground/grass_tuft_01..09.png` (+ `fern_01..06`) | Decor grass nodes retextured (Pass H) |
| `assets/art/decor/grass_05.png` | `assets/art/hub/ground/grass_tuft_01..09.png` (+ `fern_01..06`) | Decor grass nodes retextured (Pass H) |
| `assets/art/decor/grass_06.png` | `assets/art/hub/ground/grass_tuft_01..09.png` (+ `fern_01..06`) | Decor grass nodes retextured (Pass H) |
| `assets/art/decor/grass_07.png` | `assets/art/hub/ground/grass_tuft_01..09.png` (+ `fern_01..06`) | Decor grass nodes retextured (Pass H) |
| `assets/art/decor/grass_08.png` | `assets/art/hub/ground/grass_tuft_01..09.png` (+ `fern_01..06`) | Decor grass nodes retextured (Pass H) |
| `assets/art/decor/grass_09.png` | `assets/art/hub/ground/grass_tuft_01..09.png` (+ `fern_01..06`) | Decor grass nodes retextured (Pass H) |
| `assets/art/decor/grass_10.png` | `assets/art/hub/ground/grass_tuft_01..09.png` (+ `fern_01..06`) | Decor grass nodes retextured (Pass H) |
| `assets/art/decor/grass_11.png` | `assets/art/hub/ground/grass_tuft_01..09.png` (+ `fern_01..06`) | Decor grass nodes retextured (Pass H) |
| `assets/art/decor/grass_12.png` | `assets/art/hub/ground/grass_tuft_01..09.png` (+ `fern_01..06`) | Decor grass nodes retextured (Pass H) |
| `assets/art/decor/grass_13.png` | `assets/art/hub/ground/grass_tuft_01..09.png` (+ `fern_01..06`) | Decor grass nodes retextured (Pass H) |
| `assets/art/decor/grass_14.png` | `assets/art/hub/ground/grass_tuft_01..09.png` (+ `fern_01..06`) | Decor grass nodes retextured (Pass H) |
| `assets/art/decor/grass_15.png` | `assets/art/hub/ground/grass_tuft_01..09.png` (+ `fern_01..06`) | Decor grass nodes retextured (Pass H) |
| `assets/art/decor/grass_16.png` | `assets/art/hub/ground/grass_tuft_01..09.png` (+ `fern_01..06`) | Decor grass nodes retextured (Pass H) |
| `assets/art/decor/misc_01.png` | unused (superseded by `hub/props/mushroom_*`, `flower_*`) | Catalogued but never placed |
| `assets/art/decor/misc_02.png` | unused (superseded by `hub/props/mushroom_*`, `flower_*`) | Catalogued but never placed |
| `assets/art/decor/misc_03.png` | unused (superseded by `hub/props/mushroom_*`, `flower_*`) | Catalogued but never placed |
| `assets/art/decor/misc_04.png` | unused (superseded by `hub/props/mushroom_*`, `flower_*`) | Catalogued but never placed |
| `assets/art/decor/misc_05.png` | unused (superseded by `hub/props/mushroom_*`, `flower_*`) | Catalogued but never placed |
| `assets/art/decor/misc_06.png` | unused (superseded by `hub/props/mushroom_*`, `flower_*`) | Catalogued but never placed |
| `assets/art/decor/misc_07.png` | unused (superseded by `hub/props/mushroom_*`, `flower_*`) | Catalogued but never placed |
| `assets/art/decor/misc_08.png` | unused (superseded by `hub/props/mushroom_*`, `flower_*`) | Catalogued but never placed |
| `assets/art/decor/misc_09.png` | unused (superseded by `hub/props/mushroom_*`, `flower_*`) | Catalogued but never placed |
| `assets/art/decor/misc_10.png` | unused (superseded by `hub/props/mushroom_*`, `flower_*`) | Catalogued but never placed |
| `assets/art/decor/misc_11.png` | unused (superseded by `hub/props/mushroom_*`, `flower_*`) | Catalogued but never placed |
| `assets/art/decor/misc_12.png` | unused (superseded by `hub/props/mushroom_*`, `flower_*`) | Catalogued but never placed |
| `assets/art/decor/misc_13.png` | unused (superseded by `hub/props/mushroom_*`, `flower_*`) | Catalogued but never placed |
| `assets/art/decor/misc_14.png` | unused (superseded by `hub/props/mushroom_*`, `flower_*`) | Catalogued but never placed |
| `assets/art/decor/misc_15.png` | unused (superseded by `hub/props/mushroom_*`, `flower_*`) | Catalogued but never placed |
| `assets/art/decor/misc_16.png` | unused (superseded by `hub/props/mushroom_*`, `flower_*`) | Catalogued but never placed |
| `assets/art/decor/stone_01.png` | unused (superseded by `hub/props/rock_mossy_*`) | Catalogued but never placed |
| `assets/art/decor/stone_02.png` | unused (superseded by `hub/props/rock_mossy_*`) | Catalogued but never placed |
| `assets/art/decor/stone_03.png` | unused (superseded by `hub/props/rock_mossy_*`) | Catalogued but never placed |
| `assets/art/manatree/anim/manatree_ancient_strip.png` | `assets/art/manatree/native/anim/manatree_ancient_strip.png` | Old v0.1.8-A2 strip (upscaled in-engine). Replaced by the native strip. |
| `assets/art/manatree/anim/manatree_elder_strip.png` | `assets/art/manatree/native/anim/manatree_elder_strip.png` | Old v0.1.8-A2 strip (upscaled in-engine). Replaced by the native strip. |
| `assets/art/manatree/anim/manatree_mature_strip.png` | `assets/art/manatree/native/anim/manatree_mature_strip.png` | Old v0.1.8-A2 strip (upscaled in-engine). Replaced by the native strip. |
| `assets/art/manatree/anim/manatree_sapling_strip.png` | `assets/art/manatree/native/anim/manatree_sapling_strip.png` | Old v0.1.8-A2 strip (upscaled in-engine). Replaced by the native strip. |
| `assets/art/manatree/anim/manatree_young_strip.png` | `assets/art/manatree/native/anim/manatree_young_strip.png` | Old v0.1.8-A2 strip (upscaled in-engine). Replaced by the native strip. |
| `assets/art/manatree/manatree_meta.json` | `assets/art/manatree/native/manatree_meta.json` | Old v0.1.8-A2 meta. Every reader was repointed to the native meta (Pass I). |
| `assets/art/props/berry_harvest_node.png` | `assets/art/props/native/berry_harvest_node.png` | Old berry art (784x1168 at x0.1096). Replaced by the native 86x128. |
| `assets/art/props/harvest_berry_spent.png` | `assets/art/props/native/harvest_berry_spent.png` | Old berry art (784x1168 at x0.1096). Replaced by the native 86x128. |
| `assets/art/trees/bush_a.png` | unused | Catalogued but never placed |
| `assets/art/trees/stump_a.png` | unused | Catalogued but never placed |
| `assets/art/trees/tree_autumn_a.png` | unused | Catalogued but never placed |
| `assets/art/trees/tree_big_01.png` | `assets/art/hub/trees/ring_tree_large_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/trees/tree_big_02.png` | `assets/art/hub/trees/ring_tree_large_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/trees/tree_big_03.png` | `assets/art/hub/trees/ring_tree_large_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/trees/tree_big_04.png` | `assets/art/hub/trees/ring_tree_large_01..03.png` | Baked nodes retextured (Pass H) |
| `assets/art/trees/tree_forest_imagine.png` | unused | Catalogued but never placed |
| `assets/art/trees/tree_native_01.png` | `assets/art/hub/trees/ring_tree_medium_01..02.png` | Baked nodes retextured (Pass H) |
| `assets/art/trees/tree_native_02.png` | `assets/art/hub/trees/ring_tree_medium_01..02.png` | Baked nodes retextured (Pass H) |
| `assets/art/trees/tree_native_03.png` | `assets/art/hub/trees/ring_tree_medium_01..02.png` | Baked nodes retextured (Pass H) |
| `assets/art/trees/tree_native_04.png` | `assets/art/hub/trees/ring_tree_medium_01..02.png` | Baked nodes retextured (Pass H) |
| `assets/art/trees/tree_oak_a.png` | unused | Catalogued but never placed |
| `assets/art/trees/tree_oak_b.png` | unused | Catalogued but never placed |
| `assets/art/trees/tree_pine_a.png` | unused | Catalogued but never placed |
| `assets/art/trees/tree_small_01.png` | `assets/art/hub/trees/ring_tree_medium_01..02.png` / `ring_tree_slim_01.png` | Baked nodes retextured (Pass H) |
| `assets/art/trees/tree_small_02.png` | `assets/art/hub/trees/ring_tree_medium_01..02.png` / `ring_tree_slim_01.png` | Baked nodes retextured (Pass H) |
| `assets/art/trees/tree_small_03.png` | `assets/art/hub/trees/ring_tree_medium_01..02.png` / `ring_tree_slim_01.png` | Baked nodes retextured (Pass H) |
| `assets/art/trees/tree_small_04.png` | `assets/art/hub/trees/ring_tree_medium_01..02.png` / `ring_tree_slim_01.png` | Baked nodes retextured (Pass H) |
| `assets/art/trees/trees_meta.json` | `assets/art/hub/hub_deco_meta.json` (families ring_tree_*) | Old tree catalog, including the unused frames and the three tree_mana entries. Nothing live read it after Pass I. `tree_mana_*.png` stays in `assets/art/trees/` because `main.tscn` references it directly. |

## Swap back (part 2)

1. Restore the files, for example for everything:
   `for f in $(git ls-files assets/library/legacy/hub_v3_2026-09-30 | grep -v REPLACED.md | grep -v '/manatree/manatree_[a-z]*\.png$'); do rel=${f#assets/library/legacy/hub_v3_2026-09-30/}; mkdir -p assets/art/$(dirname $rel); git mv $f assets/art/$rel; done`
   Narrow the list to swap back one family.
2. Revert Code's repoints for that family: Pass I `6d669c6` (catalogs, MANIFEST, prop metas, Manatree meta path) and Pass H `0f821e6` (the
   `main.tscn` texture_path values, berry paths, and verify/sanity expectations).
3. Run the Godot import, then VERIFY and SANITY.
Or `git revert` this commit together with Pass I and Pass H.
