# Hub v3 art: notes for Code (2026-09-30)

This delivery is **additive**. Every file is new and sits at a new path next to the live art. No scene, script, data or existing
asset was touched. Code does the swap in its own push. **After that swap lands**, Haex moves the replaced and now-unused files to
`assets/library/legacy/hub_v3_2026-09-30/`. Don't move or delete anything yourself.

Contact sheet: `assets/library/hub_v3_2026-09-30/contact_hub_v3.png`. It shows the icons at x1 and x2 with a mock shop, every deco family at display
scale on the live Ground tiles, a mock clearing around the native Elder, Manatree live vs native, and the berry before/after.

Line numbers below are as of `7d7dcc9` (Pass G).

Density everywhere: **1 art px = 1 display px**, nearest filter, `sprite_scale` / `display_scale` **1**.

## 1. New paths

| Family | Paths (under `res://assets/art/`) | Count | Canvas |
|---|---|---|---|
| Ascension icons | `ui/icons/icon_asc_{deep_roots,forager,green_thumb,shard_sight,keeper_stride,wisp_haste,bonus_wisp,keep_tools,keep_forge_intermediates,keep_forge_jobs}.png` | 10 | 32x32 |
| Large ring trees | `hub/trees/ring_tree_large_01..03.png` | 3 | 320x400 |
| Medium ring trees | `hub/trees/ring_tree_medium_01..02.png` | 2 | 256x288 |
| Slim ring tree | `hub/trees/ring_tree_slim_01.png` | 1 | 160x320 |
| Big bushes | `hub/bushes/ring_bush_big_01..03.png` | 3 | 192x144 |
| Small bushes | `hub/bushes/ring_bush_small_01..03.png` | 3 | 120x72 |
| Grass tufts | `hub/ground/grass_tuft_01..09.png` | 9 | 64x48 |
| Ferns | `hub/ground/fern_01..06.png` | 6 | 64x64 |
| Plain mushrooms | `hub/props/mushroom_plain_01..03.png` (01 brown cluster, 02 red toadstool, 03 shelf fungus on a log) | 3 | 48x48 |
| Glowing mushrooms | `hub/props/mushroom_glow_01..03.png` (01 teal cluster, 02 single, 03 fairy ring) | 3 | 48x48 |
| Glow sprites | `hub/props/mushroom_glow_01..03_glow.png` | 3 | 96x96 |
| Mossy rocks | `hub/props/rock_mossy_01..06.png` | 6 | 48x40 |
| Flowers | `hub/props/flower_01..06.png` (daisies, buttercups, bluebells, orange lilies, teal blooms, mixed) | 6 | 48x48 |
| Manatree native strips | `manatree/native/anim/manatree_{sapling,young,mature,elder,ancient}_strip.png` | 5 | see section 3 |
| Manatree native stills (fallback) | `manatree/native/manatree_{sapling,young,mature,elder,ancient}.png` | 5 | see section 3 |
| Berry bush native | `props/native/berry_harvest_node.png`, `props/native/harvest_berry_spent.png` | 2 | 86x128 |

Meta files (new):
- `res://assets/art/hub/hub_deco_meta.json` (version `v0.3.0-hub-v3`). It covers all deco families. `file` paths are relative to `res://assets/art/`.
- `res://assets/art/manatree/native/manatree_meta.json` (version `v0.1.9-A2-native`). `file` / `still_file` are relative to `res://assets/art/manatree/`, the same convention `manatree.gd` already uses.

Canvas notes: no mushroom needed a wider canvas. The shelf-fungus log is 46 px wide and the fairy ring 42 px, both inside 48 at the shared
mushroom scale. If a canvas is ever widened, the meta tags it with `canvas_widened_from`; nothing has that tag today. The glow sprites went to `hub/props/`
(beside their mushrooms) rather than a separate `hub/deco/` folder.

## 2. Deco families: size, anchor, offset

Every sprite is anchored at **base centre**: the content's bottom row sits on the canvas's last row, centred horizontally. The offset is
`(-w/2, -h)`, which is exactly what `ForestProp._apply_visual()` already sets (`spr.offset = (-w*0.5, -h)`, `centered = false`). So a
retexture keeps every node's position as the foot point.

| meta family | kind | size | offset | collider (meta) | visual_only |
|---|---|---|---|---|---|
| ring_tree_large | tree | 320x400 | (-160,-400) | 36x40 (trunk) | no |
| ring_tree_medium | tree | 256x288 | (-128,-288) | 36x28.8 | no |
| ring_tree_slim | tree | 160x320 | (-80,-320) | 25.6x32 | no |
| ring_bush_big | bush | 192x144 | (-96,-144) | 16x10 | no |
| ring_bush_small | bush | 120x72 | (-60,-72) | 16x10 | no |
| grass_tuft | grass_tuft | 64x48 | (-32,-48) | none | yes |
| fern | fern | 64x64 | (-32,-64) | none | yes |
| mushroom_plain | mushroom_plain | 48x48 | (-24,-48) | none | yes |
| mushroom_glow | mushroom_glow | 48x48 | (-24,-48) | none | yes |
| rock_mossy | rock_mossy | 48x40 | (-24,-40) | none | yes (visual only, no collision, by design) |
| flower | flower | 48x48 | (-24,-48) | none | yes |

The tree colliders follow the existing trunk rule. They stay well under the `tex_h * 0.20 + 2` canopy check in `verify_headless.gd` (around line 1068).

Glowing mushroom entries also carry:
`glow: true`, `glow_file` (`hub/props/mushroom_glow_0N_glow.png`), `glow_size` [96,96], `glow_offset` [-48,-72] relative to the node foot point
(that's `-w/2-24, -h-24`, so the 96x96 glow is centred on the 48x48 sprite), `glow_blend: "add"`, `glow_color: "#4de0cd"`, and
`glow_pulse_hint` (alpha 0.55 to 1.0 sine, about 3-4 s period, desynced per node).
The glow PNG is RGB #4de0cd everywhere with a soft radial alpha (peak about 0.55, zero at the edges), so it's premultiplied-friendly. Add it as a child
`Sprite2D` (`centered = false`, `offset = glow_offset`) with a `CanvasItemMaterial` set to `blend_mode = BLEND_MODE_ADD`. Pulse `modulate.a`.

## 3. Manatree swap (native, Haex approved, all 5 stages)

Same A2 art, crop and door anchor as v0.1.8-A2, re-exported at native display size so `display_scale` is 1. The sway amplitude scales with it.

| stage | old frame x display_scale | native frame | strip | door_floor | still (fallback) |
|---|---|---|---|---|---|
| sapling | 64x64 x2 | 128x128 | 1024x128 | (62,102) | 256x384 |
| young | 96x96 x3 | 288x288 | 2304x288 | (150,255) | 576x864 |
| mature | 184x184 x4 | 736x736 | 5888x736 | (368,536) | 1024x1536 |
| elder | 256x256 x4 | 1024x1024 | 8192x1024 | (512,916) | 1536x2048 |
| ancient | 256x256 x4 | 1024x1024 | 8192x1024 | (504,936) | 2048x2560 |

`door_floor`, `anchor_px` and the stills are the old values times the old display_scale (recorded per stage as `native_from_display_scale`), so the on-screen footprint is unchanged. `display_scale` is 1 for every stage.
All strips are 8 frames horizontal at 7 fps. The widest is 8192 px, which is within Godot's texture limit.

Code changes:
1. `scripts/manatree.gd` line 29: `META_PATH` -> `"res://assets/art/manatree/native/manatree_meta.json"`.
2. `scripts/manatree.gd` lines 30-36: `STAGE_TEXTURES` fallback stills -> `"res://assets/art/manatree/native/manatree_<stage>.png"`.
3. Nothing else in `manatree.gd` should need changing. It already reads `file`, `size`, `frames`, `fps`, `display_scale` (now 1) and `door_floor` per stage.
   Check that the door, hitbox and label land on the same world pixels (they did in my offline comparison: exact).
4. `scripts/verify_headless.gd`:
   - **line 122**: version `"v0.1.8-A2"` -> `"v0.1.9-A2-native"` (and the meta path at lines 113-114 -> the native meta).
   - **line 132**: ancient frame `256 x 256` -> `1024 x 1024`.
   - Lines 108-112 check the old stills by path. Point them at `native/manatree_<stage>.png` before the legacy move.
5. `scene_sanity.gd` and `tools/shrink_clearing_once.gd`: the exclusion math is unchanged because the display footprint is identical.

## 4. Berry bush swap (native 86x128, Haex approved)

- `scripts/gatherable.gd` line 52, `HARVEST_TEXTURES["food"]` -> `"res://assets/art/props/native/berry_harvest_node.png"`.
- `scenes/main.tscn` ext_resource `25_berry_spent` (line 28) -> `"res://assets/art/props/native/harvest_berry_spent.png"`.
- The food scale rule then gives scale 1.0 and a 128 px display height. The existing checks still pass: filename `ends_with("berry_harvest_node.png")` /
  `"harvest_berry_spent.png"`, 128 px height, click rect = visual (`scene_sanity.gd` 220-229, 352-356; `verify_headless.gd` 2028-2031).
- `verify_headless.gd` line 139 checks the old `props/berry_harvest_node.png` by path. Retarget it to the native path before the legacy move.

## 5. Ascension icons hookup

- Add `"art_name": "icon_asc_<id>"` to each entry in `data/fruit_upgrades.json` (deep_roots, forager, green_thumb, shard_sight,
  keeper_stride, wisp_haste, bonus_wisp, keep_tools) and in `data/forge_tuning.json` `ascend_upgrades`
  (keep_forge_intermediates, keep_forge_jobs).
- Resolve the path the same way `scripts/autoload/equipment.gd` `item_art_path()` does (lines 162-176): `res://assets/art/ui/<art_name>.png`, then
  `res://assets/art/ui/icons/<art_name>.png`. These files are in `ui/icons/`.
- `scripts/hud.gd` `_rebuild_upgrades()` (line 2092, `SHOP_ROW_H` 48): add a 32x32 `TextureRect` with nearest filter
  (`expand_mode = EXPAND_IGNORE_SIZE`, `stretch_mode = STRETCH_KEEP_CENTERED`, `custom_minimum_size = (32,32)`) as the first child of `inner` for **every** row.
  This replaces the keep_tools special case at line 2121 (`HudIcons.KEEP_TOOLS`).
- Green Thumb uses the seed pouch (Haex's pick). The icons use a tight medallion: symbol about 22-24 px, thin ring, dark outline.

## 6. Deco swap plan

**Retexture the existing baked nodes in `scenes/main.tscn`.** Keep every node and its position. Do not re-run `tools/bake_hub_layout.gd`.
Only change the `ForestProp` exports (`texture_path`, `sprite_scale`, `sprite_modulate`, `collider_size`):

| current `texture_path` prefix | nodes (approx.) | new family |
|---|---|---|
| `trees/tree_big_*` | 120 | `ring_tree_large` |
| `trees/tree_small_*` | 121 | `ring_tree_medium` + `ring_tree_slim` |
| `trees/tree_native_*` | 119 | `ring_tree_medium` |
| `trees/tree_mana_*` | 84 | **keep as is** (the mana-tree grid was skipped) |
| `bushes/bush_big_*` | 371 | `ring_bush_big` |
| `bushes/bush_small_*` | 704 | `ring_bush_small` |
| `bushes/native/bush_native_*` | 464 | `ring_bush_small` |
| `decor/grass_*` (forest_decor) | 40 | `grass_tuft` |

- Pick the variant by a **position hash** so it's stable and not stripy. For example, `idx = abs(hash(Vector2i(pos.round()))) % n`, or a cheap
  `(int(x)*73856093 ^ int(y)*19349663)`. Pick slim with about 1 in 3 chance in the tree_small pool.
- Set `sprite_scale = 1` (623 nodes currently carry `2.0`), clear the decor `sprite_modulate` (40 nodes) to white, and set `collider_size` from the
  meta family collider (trees: trunk values above; bushes 16x10). `prop_kind` stays as is.
- **Add-only placement pass** for the new ground families (suggested counts: grass_tuft +60, fern 30, mushroom 16 (split plain/glow
  about 10/6), rock_mossy 20, flower 24). Respect `main.gd` `decor_spot_allowed()` (line 784), the Manatree exclusion used by
  `scene_sanity.gd` / `shrink_clearing_once.gd`, and the path lines. Use a new group (for example `hub_ground_deco`) and no body, so they
  don't inflate `forest_decor` (the checks cap it at 20-60).
- **Rocks are visual only**: no StaticBody.
- Glowing mushrooms get the additive glow child and slow pulse from section 2.

## 7. Checks that reference the old art (update in the same push)

- `verify_headless.gd` 108-114, 122, 132: manatree stills, meta path, version, ancient frame (section 3).
- `verify_headless.gd` 139: old berry path (section 4).
- `verify_headless.gd` 143-152: old `trees/tree_big_01/04`, `tree_small_01/03`, `bushes/bush_big_01/12`, `bush_small_01/57`, `bushes_meta.json`.
- `verify_headless.gd` 162-163: `tree_big_01` width >= 400. Retarget to `hub/trees/ring_tree_large_01.png` (320x400) or drop it.
- `verify_headless.gd` 238-261: `trees_meta.json` / `bushes_meta.json` version `v0.1.13-assets-upload`, `spawn trees >= 8`, `69 bush frames`.
  Point these at `hub/hub_deco_meta.json` `v0.3.0-hub-v3` and its family counts (trees 6, bushes 6).
- `verify_headless.gd` 1084-1102: `forest_decor` 20-60 and "decor is flora grass only" (path must contain `/decor/grass_`) must accept
  `/hub/ground/grass_tuft_`.
- `tools/scene_sanity.gd` 102-119: same grass-only rule (line 115 `"/decor/grass_"`) and the 20-60 decor count.
- `scripts/polish_smoke.gd:56` and `scripts/playtest_ship.gd:755/779` also count `forest_decor` / `forest_prop`, so check them after the swap.
- `main.gd` `_spawn_forest_props()` (bake path only) still reads the old tree/bush metas. It only runs under `MANAFORGE_BAKE=1`. Leave it or
  point it at the new meta, but don't re-bake.

## 8. Current test state

On `7d7dcc9` (Pass G) plus these files: **VERIFY_OK** and **SANITY_OK**. The earlier VERIFY failure "stacked manatree pulse +2 manashards" also failed
on a clean `1c7dafe` (Pass E), so it was pre-existing and not caused by this art. It no longer shows after Pass F's shared 20 s accumulator fix.

## 9. After Code's swap

Haex legacy-moves the replaced and unused files (old trees/bushes/decor grass in the swapped families, old manatree stills/strips/meta v0.1.8-A2,
old berry pair) to `assets/library/legacy/hub_v3_2026-09-30/`. Update the checks in section 7 first so nothing points at the moved paths.
