# 540p redraw list, rebuilt from Code's VISUAL_INVENTORY (575 entries)

Base 1280×720 → 960×540, shown at 2× on 1080p. Sprites and art stay 1 art px = 1 base px.

Rules:
- World art is REUSABLE.
- Screen-space plates stay at 1:1 and are re-centred (CROP/EXTEND).
- No scaling except by whole numbers.
- A full-frame painting that cannot be cropped is a FULL REDRAW.

Source: `/workspace/res960/VISUAL_INVENTORY.md`, generated from `/workspace/pr33_local`. Every one of Code's 575 visual entries is covered below. The 202 forest-ring pieces and the 57 icons are grouped into rows; everything else has one row per file. Code's 5 hard-coded-layout entries are listed separately as Code work. Inventory only: nothing was redrawn, committed or pushed.

## Counts (575 visual entries)

| Verdict | Entries |
|---|---:|
| FULL REDRAW | 1 |
| CROP/EXTEND | 7 |
| REUSABLE | 567 |
| Code-only hard-coded layout entries (not art) | 5 |

## FULL REDRAW

| Path | Size | Evidence / reason |
|---|---|---|
| `assets/art/title/titlescreen.png` | 1248×832 | Screen-space cover-stretched painting (TextureRect stretch 6, already 1.026x today). A 1:1 960x540 crop cuts the baked-in logo (T/E edges) and the side runes; 0.77x is non-integer. Redraw at 960x540 (+overscan) with the logo as its own layer. |

## CROP/EXTEND

| Path | Size | Evidence / reason |
|---|---|---|
| `assets/art/battle/arena/arena_forest_bg_a.png` | 1600×900 | Screen-space plate drawn at 1:1 (battle_scene.tscn Arena/Backdrop TextureRect, stretch_mode 0, offsets -160/-90..1440/810). The centre 960x540 is open clearing; the framing trees sit outside it. Keep 1:1, re-centre a ~1120x630 crop (960x540 + overscan), and pull the framing trees in. |
| `assets/art/battle/arena/arena_forest_bg_b.png` | 1600×900 | Alternate plate at 1600x900, not referenced by battle_scene.tscn or battle_view.gd (grep shows only bg_a and fg). If it is kept, it gets the same 1:1 re-centred crop as bg_a. |
| `assets/art/battle/arena/arena_forest_fg.png` | 1600×900 | Screen-space overlay at 1:1 (Arena/Foreground, same offsets). The corner ferns fall outside 960x540. Re-centre the crop and move the ferns inward. |
| `assets/art/echo/echo_chamber_bg.png` | 1280×720 | Opaque 1280x720 screen plate (echo_battle_view.gd CHAMBER_BG, stretch_mode 0). A 1:1 centre crop keeps the arch but halves the side rune stones. Move them in and crop to 960x540 (+overscan). |
| `assets/art/ui/minigames/kit/frame_720x448.png` | 720×448 | Fixed 720x448 frame = 83% of 540 tall. Crop to ~640x400, or use frame_9s_96 (9-slice). |
| `assets/art/battle/ui/bottom_panel_1280x136.png` | 1280×136 | Fixed 1280-wide bar (BOTTOM_BAR_RECT 0,584,1280,136), 25% of a 540 frame. Crop to 960 wide and ~100-110 tall, or replace with the existing bottom_panel_9s_48. |
| `assets/art/battle/ui/log_panel_732x108.png` | 732×108 | Fixed 732-wide panel = 76% of 960. Crop narrower, or replace with log_panel_9s_12. |

## Where this list and Code's differ, and how each was settled

| Code's entry | Code's flag | Evidence checked | Settled verdict |
|---|---|---|---|
| "Battle arenas" (8 entries) | needs redo | The section holds 3 plates + 5 small pieces, not 8 arenas: `arena_forest_bg_a` 1600×900, `arena_forest_bg_b` 1600×900, `arena_forest_fg` 1600×900, `shadow_l` 96×24, `shadow_m` 64×16, `shadow_s` 40×10, `slot_mark` 56×16, `slot_mark_target` 56×16. `battle_scene.tscn` draws bg_a (Backdrop) and fg (Foreground) as TextureRects with stretch_mode 0 (1:1) at offsets −160/−90 → 1440/810, which is 160/90 of overscan around 1280×720. bg_b is not referenced in scenes or battle scripts. Shadows and slot marks are drawn per fighter by `battle_view.gd` (SHADOW_*, SLOT_MARK_PATH). | bg_a, fg, bg_b → **CROP/EXTEND** (keep 1:1, re-centre ~1120×630, pull the framing trees and ferns in; never scale 0.75). The 5 shadow/slot pieces → **REUSABLE**. Fighter sole points (x 80..1176) and ARENA_SIZE are Code's job. |
| `forge/forge_bark_chamber_bg.png` 1600×1200 | hot spot #7 / redo | `forge_room.tscn` FloorPlate is a **Sprite2D** (world, not a Control) at (800,600), scale 1, under Camera2D limits 0..1600 × 0..1200. `forge_room.gd` clamps the camera with the live viewport half-size. A 960×540 view inside 1600×1200 just pans more (640×660 of travel instead of 320×480). | **REUSABLE**. Side note: FloorPlate has `texture_filter = 1` (linear). It should be nearest; that is a one-line Code fix. |
| `battle/ui/bottom_panel_1280x136.png` | "must redraw/reflow" | Fixed 1280 wide. A 9-slice twin `bottom_panel_9s_48.png` already exists. | **CROP/EXTEND**, not a redraw. |
| `minigames/kit/frame_720x448.png` | hot spot #10 | 720×448 fits 960×540 but leaves 46 px top/bottom. | **CROP/EXTEND** (or swap to frame_9s_96). |
| `echo/echo_chamber_bg.png` 1280×720 | hot spot #6 | Opaque 1:1 plate. The arch is centred; the side stones are at the edges. | **CROP/EXTEND** (same as before). |
| `title/titlescreen.png` 1248×832 | hot spot #5 | Cover-stretched; the logo is baked in. | **FULL REDRAW** (agreed). |
| Fonts / Theme: "none in repo, default font 10–28" | – | Expected: Silver, Jersey and the v8c theme live only in `ui_restyle/theme_pkg`. | No art verdict. Keep the font proposal (below). |
| Mockups (v9b title, pause, options, save/load, HUD, board refs) | not in Code's list | Not shipped art | Listed under "Outside Code's list". |

## Fonts (unchanged proposal)
- **Silver** is native 19 px/em (1900 units per em, 100-unit grid). Use body **19** and hero **38** (2×), and nothing below 19.
- **Jersey 10** is native 18.67 px/em (1400 units per em, 75-unit grid). Use **19** for planks and plates and **37** (≈2×) for big headers. Retire 30, which is off-grid.
- All 11 default-font sizes in Code's list (10, 11, 12, 13, 14, 15, 16, 18, 20, 22, 28) map to Silver 19 / Jersey 19 / 37.
- For in-game primary buttons, Silver 19 bold is proposed, with 38 kept for title hero buttons (Q3).

## Full list: every Code entry

### Full-screen images (title / splash) (1)

| Path | Size | Draws in | Verdict | Reason |
|---|---|---|---|---|
| `assets/art/title/titlescreen.png` | 1248×832 | Screen | FULL REDRAW | Screen-space cover-stretched painting (TextureRect stretch 6, already 1.026x today). A 1:1 960x540 crop cuts the baked-in logo (T/E edges) and the side runes; 0.77x is non-integer. Redraw at 960x540 (+overscan) with the logo as its own layer. |

### Backgrounds & floor plates — Hub / clearing (28)

| Path | Size | Draws in | Verdict | Reason |
|---|---|---|---|---|
| `assets/art/hub/ground/fern_01.png` | 64×64 | World | REUSABLE | World art at 1:1. Only the visible area shrinks. |
| `assets/art/hub/ground/fern_02.png` | 64×64 | World | REUSABLE | World art at 1:1. Only the visible area shrinks. |
| `assets/art/hub/ground/fern_03.png` | 64×64 | World | REUSABLE | World art at 1:1. Only the visible area shrinks. |
| `assets/art/hub/ground/fern_04.png` | 64×64 | World | REUSABLE | World art at 1:1. Only the visible area shrinks. |
| `assets/art/hub/ground/fern_05.png` | 64×64 | World | REUSABLE | World art at 1:1. Only the visible area shrinks. |
| `assets/art/hub/ground/fern_06.png` | 64×64 | World | REUSABLE | World art at 1:1. Only the visible area shrinks. |
| `assets/art/hub/ground/grass_tuft_01.png` | 64×48 | World | REUSABLE | World art at 1:1. Only the visible area shrinks. |
| `assets/art/hub/ground/grass_tuft_02.png` | 64×48 | World | REUSABLE | World art at 1:1. Only the visible area shrinks. |
| `assets/art/hub/ground/grass_tuft_03.png` | 64×48 | World | REUSABLE | World art at 1:1. Only the visible area shrinks. |
| `assets/art/hub/ground/grass_tuft_04.png` | 64×48 | World | REUSABLE | World art at 1:1. Only the visible area shrinks. |
| `assets/art/hub/ground/grass_tuft_05.png` | 64×48 | World | REUSABLE | World art at 1:1. Only the visible area shrinks. |
| `assets/art/hub/ground/grass_tuft_06.png` | 64×48 | World | REUSABLE | World art at 1:1. Only the visible area shrinks. |
| `assets/art/hub/ground/grass_tuft_07.png` | 64×48 | World | REUSABLE | World art at 1:1. Only the visible area shrinks. |
| `assets/art/hub/ground/grass_tuft_08.png` | 64×48 | World | REUSABLE | World art at 1:1. Only the visible area shrinks. |
| `assets/art/hub/ground/grass_tuft_09.png` | 64×48 | World | REUSABLE | World art at 1:1. Only the visible area shrinks. |
| `assets/art/props/trample/trample_patch_01.png` | 96×64 | World | REUSABLE | World art at 1:1. Only the visible area shrinks. |
| `assets/art/props/trample/trample_patch_02.png` | 96×64 | World | REUSABLE | World art at 1:1. Only the visible area shrinks. |
| `assets/art/props/trample/trample_patch_03.png` | 96×64 | World | REUSABLE | World art at 1:1. Only the visible area shrinks. |
| `assets/art/props/trample/trample_path_strip.png` | 128×48 | World | REUSABLE | World art at 1:1. Only the visible area shrinks. |
| `assets/art/tiles/grass_00.png` | 64×64 | World | REUSABLE | World art at 1:1. Only the visible area shrinks. (Code: not directly referenced.) |
| `assets/art/tiles/grass_01.png` | 64×64 | World | REUSABLE | World art at 1:1. Only the visible area shrinks. (Code: not directly referenced.) |
| `assets/art/tiles/grass_02.png` | 64×64 | World | REUSABLE | World art at 1:1. Only the visible area shrinks. (Code: not directly referenced.) |
| `assets/art/tiles/grass_03.png` | 64×64 | World | REUSABLE | World art at 1:1. Only the visible area shrinks. (Code: not directly referenced.) |
| `assets/art/tiles/grass_path_cross.png` | 64×64 | World | REUSABLE | World art at 1:1. Only the visible area shrinks. (Code: not directly referenced.) |
| `assets/art/tiles/grass_path_h.png` | 64×64 | World | REUSABLE | World art at 1:1. Only the visible area shrinks. (Code: not directly referenced.) |
| `assets/art/tiles/grass_path_v.png` | 64×64 | World | REUSABLE | World art at 1:1. Only the visible area shrinks. (Code: not directly referenced.) |
| `assets/art/tiles/grass_source_nn.png` | 256×128 | World | REUSABLE | World art at 1:1. Only the visible area shrinks. (Code: not directly referenced.) |
| `assets/art/tiles/tileset_grass_64.png` | 256×128 | World | REUSABLE | World art at 1:1. Only the visible area shrinks. |

### Backgrounds & floor plates — Forest ring deco (trees, bushes, props) (202)

| Path | Size | Draws in | Verdict | Reason |
|---|---|---|---|---|
| `assets/art/hub/bushes/` (16 files) | 80×64 – 192×144 | World | REUSABLE | World art at 1:1 (ForestVisual props, hub deco). Only the visible area shrinks. |
| `assets/art/hub/bushes/sized/` (64 files) | 88×56 – 298×223 | World | REUSABLE | World art at 1:1 (ForestVisual props, hub deco). Only the visible area shrinks. |
| `assets/art/hub/props/` (21 files) | 48×40 – 96×96 | World | REUSABLE | World art at 1:1 (ForestVisual props, hub deco). Only the visible area shrinks. |
| `assets/art/hub/trees/` (15 files) | 160×320 – 320×400 | World | REUSABLE | World art at 1:1 (ForestVisual props, hub deco). Only the visible area shrinks. |
| `assets/art/hub/trees/sized/` (83 files) | 128×256 – 400×500 | World | REUSABLE | World art at 1:1 (ForestVisual props, hub deco). Only the visible area shrinks. |
| `assets/art/trees/` (3 files) | 87×98 – 91×112 | World | REUSABLE | World art at 1:1 (ForestVisual props, hub deco). Only the visible area shrinks. |

### Backgrounds & floor plates — Forge (5)

| Path | Size | Draws in | Verdict | Reason |
|---|---|---|---|---|
| `assets/art/forge/forge_arch_front.png` | 1600×1200 | World | REUSABLE | World piece in the Forge room, 1:1. (Code: not directly referenced.) |
| `assets/art/forge/forge_arch_front_haex.png` | 212×144 | World | REUSABLE | World piece in the Forge room, 1:1. |
| `assets/art/forge/forge_bark_chamber_bg.png` | 1600×1200 | World | REUSABLE | World FloorPlate Sprite2D at (800,600), scale 1, under Camera2D limits 0..1600x0..1200. 1600x1200 > 960x540, so the camera just pans more. Note texture_filter=1 (linear) on the node: set it to nearest (Code). |
| `assets/art/forge/forge_floor_mask.png` | 1600×1200 | World | REUSABLE | Data mask in room space, not drawn. Unaffected. |
| `assets/art/forge/forge_room_swirls.png` | 1600×1200 | World | REUSABLE | World overlay matching the 1600x1200 room. Camera-limited. |

### Forge station props (anvil, mill, crucible, press, reliquary, bench) (12)

| Path | Size | Draws in | Verdict | Reason |
|---|---|---|---|---|
| `assets/art/forge/bench_busy.png` | 192×192 | World | REUSABLE | World prop at 1:1 in the Forge room. |
| `assets/art/forge/bench_idle.png` | 192×192 | World | REUSABLE | World prop at 1:1 in the Forge room. |
| `assets/art/forge/prop_anvil_busy.png` | 192×192 | World | REUSABLE | World prop at 1:1 in the Forge room. |
| `assets/art/forge/prop_anvil_idle.png` | 192×192 | World | REUSABLE | World prop at 1:1 in the Forge room. |
| `assets/art/forge/prop_crucible_busy.png` | 192×192 | World | REUSABLE | World prop at 1:1 in the Forge room. |
| `assets/art/forge/prop_crucible_idle.png` | 192×192 | World | REUSABLE | World prop at 1:1 in the Forge room. |
| `assets/art/forge/prop_mill_busy.png` | 192×192 | World | REUSABLE | World prop at 1:1 in the Forge room. |
| `assets/art/forge/prop_mill_idle.png` | 192×192 | World | REUSABLE | World prop at 1:1 in the Forge room. |
| `assets/art/forge/prop_press_busy.png` | 192×192 | World | REUSABLE | World prop at 1:1 in the Forge room. |
| `assets/art/forge/prop_press_idle.png` | 192×192 | World | REUSABLE | World prop at 1:1 in the Forge room. |
| `assets/art/forge/prop_reliquary_busy.png` | 192×192 | World | REUSABLE | World prop at 1:1 in the Forge room. |
| `assets/art/forge/prop_reliquary_idle.png` | 192×192 | World | REUSABLE | World prop at 1:1 in the Forge room. |

### Backgrounds & floor plates — Battle arenas (8)

| Path | Size | Draws in | Verdict | Reason |
|---|---|---|---|---|
| `assets/art/battle/arena/arena_forest_bg_a.png` | 1600×900 | Screen | CROP/EXTEND | Screen-space plate drawn at 1:1 (battle_scene.tscn Arena/Backdrop TextureRect, stretch_mode 0, offsets -160/-90..1440/810). The centre 960x540 is open clearing; the framing trees sit outside it. Keep 1:1, re-centre a ~1120x630 crop (960x540 + overscan), and pull the framing trees in. |
| `assets/art/battle/arena/arena_forest_bg_b.png` | 1600×900 | Screen | CROP/EXTEND | Alternate plate at 1600x900, not referenced by battle_scene.tscn or battle_view.gd (grep shows only bg_a and fg). If it is kept, it gets the same 1:1 re-centred crop as bg_a. |
| `assets/art/battle/arena/arena_forest_fg.png` | 1600×900 | Screen | CROP/EXTEND | Screen-space overlay at 1:1 (Arena/Foreground, same offsets). The corner ferns fall outside 960x540. Re-centre the crop and move the ferns inward. |
| `assets/art/battle/arena/shadow_l.png` | 96×24 | Screen | REUSABLE | Small sprite-scale pieces that follow fighters. Not resolution-bound. |
| `assets/art/battle/arena/shadow_m.png` | 64×16 | Screen | REUSABLE | Small sprite-scale pieces that follow fighters. Not resolution-bound. |
| `assets/art/battle/arena/shadow_s.png` | 40×10 | Screen | REUSABLE | Small sprite-scale pieces that follow fighters. Not resolution-bound. |
| `assets/art/battle/arena/slot_mark.png` | 56×16 | Screen | REUSABLE | Small sprite-scale pieces that follow fighters. Not resolution-bound. |
| `assets/art/battle/arena/slot_mark_target.png` | 56×16 | Screen | REUSABLE | Small sprite-scale pieces that follow fighters. Not resolution-bound. |

### Backgrounds & floor plates — Echo chamber (1)

| Path | Size | Draws in | Verdict | Reason |
|---|---|---|---|---|
| `assets/art/echo/echo_chamber_bg.png` | 1280×720 | Screen | CROP/EXTEND | Opaque 1280x720 screen plate (echo_battle_view.gd CHAMBER_BG, stretch_mode 0). A 1:1 centre crop keeps the arch but halves the side rune stones. Move them in and crop to 960x540 (+overscan). |

### UI textures (panels, frames, nine-patches, buttons, minigame kit) (74)

| Path | Size | Draws in | Verdict | Reason |
|---|---|---|---|---|
| `assets/art/ui/badge_station_busy.png` | 32×32 | World | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/badge_station_paused.png` | 32×32 | World | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/bubble_body_9s_hover_24x26.png` | 24×26 | Screen | REUSABLE | Nine-/three-slice with small margins (2-24 px). Still fine at 540p. |
| `assets/art/ui/minigames/kit/bubble_body_9s_normal_24x26.png` | 24×26 | Screen | REUSABLE | Nine-/three-slice with small margins (2-24 px). Still fine at 540p. |
| `assets/art/ui/minigames/kit/bubble_hand_18x14.png` | 18×14 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/bubble_hover_128x33.png` | 128×33 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/bubble_normal_128x33.png` | 128×33 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/bubble_pop_128x40_3f.png` | 384×40 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/bubble_tail_hover_13x10.png` | 13×10 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/bubble_tail_normal_13x10.png` | 13×10 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/deco_leaf_8x5.png` | 8×5 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/deco_vine_br.png` | 58×47 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/deco_vine_tl.png` | 64×54 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/fb_good_48x22.png` | 48×22 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/fb_miss_44x22.png` | 44×22 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/fb_perfect_72x22.png` | 72×22 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/frame_720x448.png` | 720×448 | Screen | CROP/EXTEND | Fixed 720x448 frame = 83% of 540 tall. Crop to ~640x400, or use frame_9s_96 (9-slice). |
| `assets/art/ui/minigames/kit/frame_9s_96.png` | 96×96 | Screen | REUSABLE | Nine-/three-slice with small margins (2-24 px). Still fine at 540p. |
| `assets/art/ui/minigames/kit/fx_good_24x24_4f.png` | 96×24 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/fx_miss_24x24_3f.png` | 72×24 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/fx_perfect_32x32_4f.png` | 128×32 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/gauge_arrow_l_6x11.png` | 6×11 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/gauge_arrow_r_6x11.png` | 6×11 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/gauge_band_9s_40x12.png` | 40×12 | Screen | REUSABLE | Nine-/three-slice with small margins (2-24 px). Still fine at 540p. |
| `assets/art/ui/minigames/kit/gauge_frame_40x240.png` | 40×240 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/gauge_frame_9s_40x24.png` | 40×24 | Screen | REUSABLE | Nine-/three-slice with small margins (2-24 px). Still fine at 540p. |
| `assets/art/ui/minigames/kit/keycap_1_14x15.png` | 14×15 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/keycap_2_14x15.png` | 14×15 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/keycap_3_14x15.png` | 14×15 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/keycap_4_14x15.png` | 14×15 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/keycap_5_14x15.png` | 14×15 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/keycap_6_14x15.png` | 14×15 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/keycap_9s_14x15.png` | 14×15 | Screen | REUSABLE | Nine-/three-slice with small margins (2-24 px). Still fine at 540p. |
| `assets/art/ui/minigames/kit/keycap_a_14x15.png` | 14×15 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/keycap_d_14x15.png` | 14×15 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/keycap_down_14x15.png` | 14×15 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/keycap_esc.png` | 28×20 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/keycap_esc_28x15.png` | 28×15 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/keycap_left_14x15.png` | 14×15 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/keycap_right_14x15.png` | 14×15 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/keycap_s_14x15.png` | 14×15 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/keycap_space_40x15.png` | 40×15 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/keycap_up_14x15.png` | 14×15 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/keycap_w_14x15.png` | 14×15 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/kit_palette.png` | 336×8 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/mouse_circle_14x14.png` | 14×14 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/mouse_drag_16x10.png` | 16×10 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/mouse_hold_12x10.png` | 12×10 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/mouse_l_8x10.png` | 8×10 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/mouse_r_8x10.png` | 8×10 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/num_8x11_sheet.png` | 137×11 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/pace_fill_gold_132x8.png` | 132×8 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/pace_fill_good_132x8.png` | 132×8 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/pace_tick_5x4.png` | 5×4 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/pace_track_136x18.png` | 136×18 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/pip_empty_12.png` | 12×12 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/pip_good_12.png` | 12×12 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/pip_miss_12.png` | 12×12 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/pip_perfect_12.png` | 12×12 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/pip_pop_16x16_3f.png` | 48×16 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/play_bevel_9s_6x6.png` | 6×6 | Screen | REUSABLE | Nine-/three-slice with small margins (2-24 px). Still fine at 540p. |
| `assets/art/ui/minigames/kit/stop_button_disabled_104x28.png` | 104×28 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/stop_button_hover_104x28.png` | 104×28 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/stop_button_normal_104x28.png` | 104×28 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/stop_button_pressed_104x28.png` | 104×28 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/title_plank_3s_48x40.png` | 48×40 | Screen | REUSABLE | Nine-/three-slice with small margins (2-24 px). Still fine at 540p. |
| `assets/art/ui/minigames/kit/title_plate_312x46.png` | 312×46 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/title_sprig_26x20.png` | 26×20 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/minigames/kit/toast_9s_40x30.png` | 40×30 | Screen | REUSABLE | Nine-/three-slice with small margins (2-24 px). Still fine at 540p. |
| `assets/art/ui/minigames/kit/wood_button_9s_disabled_32x28.png` | 32×28 | Screen | REUSABLE | Nine-/three-slice with small margins (2-24 px). Still fine at 540p. |
| `assets/art/ui/minigames/kit/wood_button_9s_hover_32x28.png` | 32×28 | Screen | REUSABLE | Nine-/three-slice with small margins (2-24 px). Still fine at 540p. |
| `assets/art/ui/minigames/kit/wood_button_9s_normal_32x28.png` | 32×28 | Screen | REUSABLE | Nine-/three-slice with small margins (2-24 px). Still fine at 540p. |
| `assets/art/ui/minigames/kit/wood_button_9s_pressed_32x28.png` | 32×28 | Screen | REUSABLE | Nine-/three-slice with small margins (2-24 px). Still fine at 540p. |
| `assets/art/ui/relic_slot_empty.png` | 44×44 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |

### Battle UI (panels, plates, bars, buttons, chrome) (46)

| Path | Size | Draws in | Verdict | Reason |
|---|---|---|---|---|
| `assets/art/battle/ui/action_button_disabled_160x44.png` | 160×44 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/action_button_hover_160x44.png` | 160×44 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/action_button_normal_160x44.png` | 160×44 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/action_button_pressed_160x44.png` | 160×44 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/action_button_toggled_160x44.png` | 160×44 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/active_arrow_13x9.png` | 13×9 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/banner_3s_48x28.png` | 48×28 | Screen | REUSABLE | Nine-/three-slice with small margins (2-24 px). Still fine at 540p. |
| `assets/art/battle/ui/banner_3s_48x32.png` | 48×32 | Screen | REUSABLE | Nine-/three-slice with small margins (2-24 px). Still fine at 540p. |
| `assets/art/battle/ui/bar_hp_low_50x4.png` | 50×4 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/bar_hp_ok_50x4.png` | 50×4 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/bar_shield_50x4.png` | 50×4 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/bar_weave_50x2.png` | 50×2 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/bottom_panel_1280x136.png` | 1280×136 | Screen | CROP/EXTEND | Fixed 1280-wide bar (BOTTOM_BAR_RECT 0,584,1280,136), 25% of a 540 frame. Crop to 960 wide and ~100-110 tall, or replace with the existing bottom_panel_9s_48. |
| `assets/art/battle/ui/bottom_panel_9s_48.png` | 48×48 | Screen | REUSABLE | Nine-/three-slice with small margins (2-24 px). Still fine at 540p. |
| `assets/art/battle/ui/depth_plate_120x28.png` | 120×28 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/log_panel_732x108.png` | 732×108 | Screen | CROP/EXTEND | Fixed 732-wide panel = 76% of 960. Crop narrower, or replace with log_panel_9s_12. |
| `assets/art/battle/ui/log_panel_9s_12.png` | 12×12 | Screen | REUSABLE | Nine-/three-slice with small margins (2-24 px). Still fine at 540p. |
| `assets/art/battle/ui/log_toggle_closed_hover_11x11.png` | 11×11 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/log_toggle_closed_normal_11x11.png` | 11×11 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/log_toggle_open_hover_11x11.png` | 11×11 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/log_toggle_open_normal_11x11.png` | 11×11 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/plate_beast_56x20.png` | 56×20 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/plate_beast_active_56x20.png` | 56×20 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/plate_beast_boss_56x20.png` | 56×20 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/plate_beast_boss_active_56x20.png` | 56×20 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/plate_party_56x24.png` | 56×24 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/plate_party_active_56x24.png` | 56×24 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/round_banner_324x38.png` | 324×38 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/slot_mark_target.png` | 56×16 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/speed_1x_hover.png` | 32×32 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/speed_1x_normal.png` | 32×32 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/speed_1x_pressed.png` | 32×32 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/speed_1x_selected.png` | 32×32 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/speed_2x_hover.png` | 32×32 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/speed_2x_normal.png` | 32×32 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/speed_2x_pressed.png` | 32×32 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/speed_2x_selected.png` | 32×32 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/speed_4x_hover.png` | 32×32 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/speed_4x_normal.png` | 32×32 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/speed_4x_pressed.png` | 32×32 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/speed_4x_selected.png` | 32×32 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/speed_blank_hover_32x32.png` | 32×32 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/speed_blank_normal_32x32.png` | 32×32 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/speed_blank_pressed_32x32.png` | 32×32 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/speed_blank_selected_32x32.png` | 32×32 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/target_corner_6x6.png` | 6×6 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |

### Battle UI — intents / status / keycaps / sigils (30)

| Path | Size | Draws in | Verdict | Reason |
|---|---|---|---|---|
| `assets/art/battle/ui/boss_crown_16.png` | 16×16 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/boss_sigil_176x24.png` | 176×24 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/intent_bubble_22x26.png` | 22×26 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/intent_bubble_wide_40x26.png` | 40×26 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/intent_heavy_16.png` | 16×16 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/intent_heavy_opt_0_maul_old_16.png` | 16×16 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/intent_heavy_opt_a_smash_16.png` | 16×16 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/intent_heavy_opt_b_boulder_16.png` | 16×16 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/intent_heavy_opt_c_maul_16.png` | 16×16 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/intent_mult_x1_5.png` | 17×7 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/intent_mult_x2.png` | 10×7 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/intent_mult_x3.png` | 10×7 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/intent_poison_16.png` | 16×16 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/intent_strike_16.png` | 16×16 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/keycap_1_14x15.png` | 14×15 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/keycap_2_14x15.png` | 14×15 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/keycap_3_14x15.png` | 14×15 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/keycap_4_14x15.png` | 14×15 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/keycap_5_14x15.png` | 14×15 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/keycap_6_14x15.png` | 14×15 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/status_braced_12.png` | 12×12 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/status_calmed_12.png` | 12×12 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/status_fogged_12.png` | 12×12 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/status_ko_12.png` | 12×12 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/status_poisoned_12.png` | 12×12 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/status_rootbind_12.png` | 12×12 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/status_shield_12.png` | 12×12 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/status_slowed_12.png` | 12×12 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/twist_ambush_12.png` | 12×12 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/battle/ui/twist_rich_hollow_12.png` | 12×12 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |

### HUD elements (buttons, scene toggles, equip slots) (35)

| Path | Size | Draws in | Verdict | Reason |
|---|---|---|---|---|
| `assets/art/ui/buttons/backpack_hover.png` | 32×32 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/buttons/backpack_normal.png` | 32×32 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/buttons/backpack_pressed.png` | 32×32 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/buttons/pause_hover.png` | 32×32 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/buttons/pause_normal.png` | 32×32 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/buttons/pause_pressed.png` | 32×32 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/buttons/speed_16x_hover.png` | 32×32 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/buttons/speed_16x_normal.png` | 32×32 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/buttons/speed_16x_pressed.png` | 32×32 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/buttons/speed_1x_hover.png` | 32×32 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/buttons/speed_1x_normal.png` | 32×32 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/buttons/speed_1x_pressed.png` | 32×32 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/buttons/speed_2x_hover.png` | 32×32 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/buttons/speed_2x_normal.png` | 32×32 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/buttons/speed_2x_pressed.png` | 32×32 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/buttons/speed_4x_hover.png` | 32×32 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/buttons/speed_4x_normal.png` | 32×32 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/buttons/speed_4x_pressed.png` | 32×32 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/buttons/speed_8x_hover.png` | 32×32 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/buttons/speed_8x_normal.png` | 32×32 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/buttons/speed_8x_pressed.png` | 32×32 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/buttons/speed_play_hover.png` | 32×32 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/buttons/speed_play_normal.png` | 32×32 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/buttons/speed_play_pressed.png` | 32×32 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/icons/hud_ascension.png` | 32×32 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/icons/hud_character.png` | 32×32 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/icons/hud_equip_empty.png` | 32×32 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/icons/hud_equip_locked.png` | 32×32 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/icons/hud_help.png` | 32×32 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/icons/hud_keep_tools.png` | 32×32 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/icons/hud_scene_clearing.png` | 32×32 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/icons/hud_scene_forge.png` | 32×32 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/icons/hud_stone_sword_old.png` | 32×32 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/icons/hud_watering_can.png` | 32×32 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/icons/hud_wooden_basket.png` | 32×32 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |

### Adventure / expedition board (47)

| Path | Size | Draws in | Verdict | Reason |
|---|---|---|---|---|
| `assets/art/props/expedition_board/board_exclaim.png` | 7×16 | World | REUSABLE | World prop at 1:1. |
| `assets/art/props/expedition_board/board_lantern_mask.png` | 128×136 | World | REUSABLE | World prop at 1:1. (Code: not directly referenced.) |
| `assets/art/props/expedition_board/expedition_board_amber.png` | 384×136 | World | REUSABLE | World prop at 1:1. (Code: not directly referenced.) |
| `assets/art/props/expedition_board/expedition_board_amber_0001.png` | 128×136 | World | REUSABLE | World prop at 1:1. |
| `assets/art/props/expedition_board/expedition_board_amber_0002.png` | 128×136 | World | REUSABLE | World prop at 1:1. |
| `assets/art/props/expedition_board/expedition_board_amber_0003.png` | 128×136 | World | REUSABLE | World prop at 1:1. |
| `assets/art/props/expedition_board/expedition_board_cyan.png` | 512×136 | World | REUSABLE | World prop at 1:1. (Code: not directly referenced.) |
| `assets/art/props/expedition_board/expedition_board_cyan_0001.png` | 128×136 | World | REUSABLE | World prop at 1:1. |
| `assets/art/props/expedition_board/expedition_board_cyan_0002.png` | 128×136 | World | REUSABLE | World prop at 1:1. |
| `assets/art/props/expedition_board/expedition_board_cyan_0003.png` | 128×136 | World | REUSABLE | World prop at 1:1. |
| `assets/art/props/expedition_board/expedition_board_cyan_0004.png` | 128×136 | World | REUSABLE | World prop at 1:1. |
| `assets/art/props/expedition_board/expedition_board_dark.png` | 128×136 | World | REUSABLE | World prop at 1:1. |
| `assets/art/props/expedition_board/expedition_board_states_strip.png` | 1024×136 | World | REUSABLE | World prop at 1:1. (Code: not directly referenced.) |
| `assets/art/ui/board/arrow_enemy_side_12x9.png` | 12×9 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/board/cost_chip_9s_ok_24x32.png` | 24×32 | Screen | REUSABLE | Nine-/three-slice with small margins (2-24 px). Still fine at 540p. |
| `assets/art/ui/board/cost_chip_9s_short_24x32.png` | 24×32 | Screen | REUSABLE | Nine-/three-slice with small margins (2-24 px). Still fine at 540p. |
| `assets/art/ui/board/divider_3s_48x6.png` | 48×6 | Screen | REUSABLE | Nine-/three-slice with small margins (2-24 px). Still fine at 540p. |
| `assets/art/ui/board/field_9s_disabled_24x24.png` | 24×24 | Screen | REUSABLE | Nine-/three-slice with small margins (2-24 px). Still fine at 540p. |
| `assets/art/ui/board/field_9s_focus_24x24.png` | 24×24 | Screen | REUSABLE | Nine-/three-slice with small margins (2-24 px). Still fine at 540p. |
| `assets/art/ui/board/field_9s_invalid_24x24.png` | 24×24 | Screen | REUSABLE | Nine-/three-slice with small margins (2-24 px). Still fine at 540p. |
| `assets/art/ui/board/field_9s_normal_24x24.png` | 24×24 | Screen | REUSABLE | Nine-/three-slice with small margins (2-24 px). Still fine at 540p. |
| `assets/art/ui/board/glyph_minus_10x10.png` | 10×10 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/board/glyph_minus_disabled_10x10.png` | 10×10 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/board/glyph_plus_10x10.png` | 10×10 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/board/glyph_plus_disabled_10x10.png` | 10×10 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/board/item_slot_empty_44x44.png` | 44×44 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/board/item_slot_hover_44x44.png` | 44×44 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/board/item_slot_normal_44x44.png` | 44×44 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/board/list_row_9s_even_24x24.png` | 24×24 | Screen | REUSABLE | Nine-/three-slice with small margins (2-24 px). Still fine at 540p. |
| `assets/art/ui/board/list_row_9s_loss_24x24.png` | 24×24 | Screen | REUSABLE | Nine-/three-slice with small margins (2-24 px). Still fine at 540p. |
| `assets/art/ui/board/lock_10x12.png` | 10×12 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/board/party_slot_empty_60x60.png` | 60×60 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/board/party_slot_empty_hover_60x60.png` | 60×60 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/board/party_slot_filled_60x60.png` | 60×60 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/board/party_slot_hover_60x60.png` | 60×60 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/board/party_slot_locked_60x60.png` | 60×60 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/board/party_slot_selected_60x60.png` | 60×60 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/board/pick_row_9s_current_24x24.png` | 24×24 | Screen | REUSABLE | Nine-/three-slice with small margins (2-24 px). Still fine at 540p. |
| `assets/art/ui/board/pick_row_9s_disabled_24x24.png` | 24×24 | Screen | REUSABLE | Nine-/three-slice with small margins (2-24 px). Still fine at 540p. |
| `assets/art/ui/board/pick_row_9s_hover_24x24.png` | 24×24 | Screen | REUSABLE | Nine-/three-slice with small margins (2-24 px). Still fine at 540p. |
| `assets/art/ui/board/popup_9s_32x32.png` | 32×32 | Screen | REUSABLE | Nine-/three-slice with small margins (2-24 px). Still fine at 540p. |
| `assets/art/ui/board/popup_tail_l_8x14.png` | 8×14 | Screen | REUSABLE | Small fixed screen piece. Fits at 1:1, so only placement changes. |
| `assets/art/ui/board/scroll_thumb_9s_drag_12x16.png` | 12×16 | Screen | REUSABLE | Nine-/three-slice with small margins (2-24 px). Still fine at 540p. |
| `assets/art/ui/board/scroll_thumb_9s_hover_12x16.png` | 12×16 | Screen | REUSABLE | Nine-/three-slice with small margins (2-24 px). Still fine at 540p. |
| `assets/art/ui/board/scroll_thumb_9s_normal_12x16.png` | 12×16 | Screen | REUSABLE | Nine-/three-slice with small margins (2-24 px). Still fine at 540p. |
| `assets/art/ui/board/scroll_track_9s_12x24.png` | 12×24 | Screen | REUSABLE | Nine-/three-slice with small margins (2-24 px). Still fine at 540p. |
| `assets/art/ui/board/wood_button_9s_selected_32x28.png` | 32×28 | Screen | REUSABLE | Nine-/three-slice with small margins (2-24 px). Still fine at 540p. |

### Portraits & status windows (4)

| Path | Size | Draws in | Verdict | Reason |
|---|---|---|---|---|
| `assets/art/portraits/elaia_portrait.png` | 52×52 | Screen | REUSABLE | Small screen pieces that fit 960x540. Placement is layout only. |
| `assets/art/portraits/elaia_portrait_sheet.png` | 160×160 | Screen | REUSABLE | Small screen pieces that fit 960x540. Placement is layout only. |
| `assets/art/portraits/keeper_portrait.png` | 52×52 | Screen | REUSABLE | Small screen pieces that fit 960x540. Placement is layout only. |
| `assets/art/portraits/keeper_portrait_sheet.png` | 160×160 | Screen | REUSABLE | Small screen pieces that fit 960x540. Placement is layout only. |

### Icons (resources, rewards, items, HUD/ascension) (57)

| Path | Size | Draws in | Verdict | Reason |
|---|---|---|---|---|
| `assets/art/battle/ui/` (3 files) | 32×32 | Screen (HUD / sheet / board / shop) | REUSABLE | 32×32-class pixel icons at 1:1. They render 64 px on 1080p, which helps mobile. |
| `assets/art/ui/glyphs/` (11 files) | 5×7 | Screen (HUD / sheet / board / shop) | REUSABLE | 32×32-class pixel icons at 1:1. They render 64 px on 1080p, which helps mobile. |
| `assets/art/ui/` (20 files) | 32×32 | Screen (HUD / sheet / board / shop) | REUSABLE | 32×32-class pixel icons at 1:1. They render 64 px on 1080p, which helps mobile. |
| `assets/art/ui/icons/` (23 files) | 32×32 | Screen (HUD / sheet / board / shop) | REUSABLE | 32×32-class pixel icons at 1:1. They render 64 px on 1080p, which helps mobile. |

### Manatree (hub centerpiece stills; anim sheets excluded) (5)

| Path | Size | Draws in | Verdict | Reason |
|---|---|---|---|---|
| `assets/art/manatree/native/manatree_ancient.png` | 2048×2560 | World | REUSABLE | World centrepiece drawn by manatree.gd from meta. Resolution-independent (framing: see Q1). |
| `assets/art/manatree/native/manatree_elder.png` | 1536×2048 | World | REUSABLE | World centrepiece drawn by manatree.gd from meta. Resolution-independent (framing: see Q1). |
| `assets/art/manatree/native/manatree_mature.png` | 1024×1536 | World | REUSABLE | World centrepiece drawn by manatree.gd from meta. Resolution-independent (framing: see Q1). |
| `assets/art/manatree/native/manatree_sapling.png` | 256×384 | World | REUSABLE | World centrepiece drawn by manatree.gd from meta. Resolution-independent (framing: see Q1). |
| `assets/art/manatree/native/manatree_young.png` | 576×864 | World | REUSABLE | World centrepiece drawn by manatree.gd from meta. Resolution-independent (framing: see Q1). |

### World props (runestones, thorn, echo portal hub) (18)

| Path | Size | Draws in | Verdict | Reason |
|---|---|---|---|---|
| `assets/art/props/echo_portal_hub.png` | 784×1168 | World | REUSABLE | World prop at 1:1. |
| `assets/art/props/echo_portal_hub_v2.png` | 160×200 | World | REUSABLE | World prop at 1:1. |
| `assets/art/props/runestones/native/runestone_arcana.png` | 64×64 | World | REUSABLE | World prop at 1:1. (Code: not directly referenced.) |
| `assets/art/props/runestones/native/runestone_fate.png` | 64×64 | World | REUSABLE | World prop at 1:1. (Code: not directly referenced.) |
| `assets/art/props/runestones/native/runestone_might.png` | 64×64 | World | REUSABLE | World prop at 1:1. (Code: not directly referenced.) |
| `assets/art/props/runestones/native/runestone_resilience.png` | 64×64 | World | REUSABLE | World prop at 1:1. (Code: not directly referenced.) |
| `assets/art/props/runestones/native/runestone_swiftness.png` | 64×64 | World | REUSABLE | World prop at 1:1. (Code: not directly referenced.) |
| `assets/art/props/runestones/native/runestone_vitality.png` | 64×64 | World | REUSABLE | World prop at 1:1. (Code: not directly referenced.) |
| `assets/art/props/runestones/native/runestone_ward.png` | 64×64 | World | REUSABLE | World prop at 1:1. (Code: not directly referenced.) |
| `assets/art/props/runestones/native/runestones_sheet.png` | 512×512 | World | REUSABLE | World prop at 1:1. |
| `assets/art/props/thorn/thorn_wall_closed.png` | 220×160 | World | REUSABLE | World prop at 1:1. |
| `assets/art/props/thorn/thorn_wall_open.png` | 220×160 | World | REUSABLE | World prop at 1:1. |
| `assets/art/props/thorn/thorn_wall_retreat.png` | 1100×160 | World | REUSABLE | World prop at 1:1. (Code: not directly referenced.) |
| `assets/art/props/thorn/thorn_wall_retreat_0001.png` | 220×160 | World | REUSABLE | World prop at 1:1. |
| `assets/art/props/thorn/thorn_wall_retreat_0002.png` | 220×160 | World | REUSABLE | World prop at 1:1. |
| `assets/art/props/thorn/thorn_wall_retreat_0003.png` | 220×160 | World | REUSABLE | World prop at 1:1. |
| `assets/art/props/thorn/thorn_wall_retreat_0004.png` | 220×160 | World | REUSABLE | World prop at 1:1. |
| `assets/art/props/thorn/thorn_wall_retreat_0005.png` | 220×160 | World | REUSABLE | World prop at 1:1. |

### FX textures (2)

| Path | Size | Draws in | Verdict | Reason |
|---|---|---|---|---|
| `assets/art/fx/fx_vein_mote.png` | 5×5 | World | REUSABLE | Tiny world FX. (Code: not directly referenced.) |
| `assets/art/fx/fx_vein_mote_strip.png` | 15×5 | World | REUSABLE | Tiny world FX. |

### Hard-coded 1280/720 layout (5, Code work, not art)

| Location | Action |
|---|---|
| scripts/polish_smoke.gd:76 | Change to 960×540 (project.godot: viewport 960×540, window override 1920×1080, scale_mode integer); polish_smoke label is cosmetic. |
| project.godot:31 | Change to 960×540 (project.godot: viewport 960×540, window override 1920×1080, scale_mode integer); polish_smoke label is cosmetic. |
| project.godot:32 | Change to 960×540 (project.godot: viewport 960×540, window override 1920×1080, scale_mode integer); polish_smoke label is cosmetic. |
| project.godot:33 | Change to 960×540 (project.godot: viewport 960×540, window override 1920×1080, scale_mode integer); polish_smoke label is cosmetic. |
| project.godot:34 | Change to 960×540 (project.godot: viewport 960×540, window override 1920×1080, scale_mode integer); polish_smoke label is cosmetic. |

## Outside Code's list (mockups, not shipped art)
| Path | Size | Verdict | Reason |
|---|---|---|---|
| `ui_restyle/mockups/v9_title/title_main_b.png`, `title_quit_confirm_b.png`, `v9b_title_overview_1x.png` | 1280×720 | FULL REDRAW (re-mock) | Built on the old painting; the 292×300 panel is 56% of 540 tall. |
| `ui_restyle/mockups/v8c/03_pause_after_*` | 1280×720 | CROP/EXTEND (re-mock) | The 360×344 panel fits. Re-centre. |
| `ui_restyle/mockups/v8c/04_options_after_*` | 1280×720 | FULL REDRAW (re-mock) | The 560×480 panel is too tall. |
| `ui_restyle/mockups/v8c/05_save_load_after_*` | 1280×720 | FULL REDRAW (re-mock) | Layout height |
| `ui_restyle/mockups/v8c/06_confirm_dialog_after_*` | 1280×720 | CROP/EXTEND (re-mock) | Fits. Re-centre. |
| `ui_restyle/mockups/01_hud_after_*` | 1280×720 | FULL REDRAW (re-mock) | All positions are 1280-absolute. |
| `assets/refs/board/board_*_1x.png` | 1280×720 | FULL REDRAW (re-mock) | Ref layout |
| theme_pkg pieces (`frame_9s_96`, vines, planks, buttons, slider, toggle, focus ring, pointer, icon_pause) | as before | REUSABLE | Not yet in the repo. The 9-slice margins are fine at 540p. |

## Open questions
**For Haex**
1. Hub framing at 2×: the Manatree is 1.81 view heights tall. Accept the closer view, or zoom out? Only 0.5 is clean, and it brings back small sprites.
2. Title: redraw at 960×540 with the logo as a separate layer (recommended), or a recomposed crop?
3. Primary buttons: Silver 19 bold on a shorter 9-slice (an 8th CROP/EXTEND-type item: a new ~28–32 px tall button), or keep Silver 38 + 160×44?
4. Jersey 10: OK to switch from 30 to 19 / 37?
5. Arena: OK to lose the side framing trees in the crop, or pull them in (recompose)?
6. `arena_forest_bg_b.png` is unreferenced. Keep it (and crop it), or drop it?
7. Phone target: 16:9 only, or re-check the 360 px phone crop?

**For Code**
1. project.godot: 960×540, override 1920×1080, `stretch/scale_mode="integer"`.
2. Replace the 1280/720 values in battle_view.gd (ARENA_SIZE, sole points, BOTTOM_BAR_RECT), battle_scene.tscn ±640/±360, echo_battle (offsets, COMMAND_SIZE), main.gd view_size, hud.gd/hud.tscn panels (720×500, 640×540), character_sheet.gd (1272×716, 360-wide columns), expedition_shell.gd (880×600), pause_menu, forge_room.gd:576, and the asserts in verify_headless.gd, pass_f_playthrough.gd and playtest_ship.gd.
3. Set Forge FloorPlate `texture_filter` to nearest.
4. Character sheet sprite box: 480 → an integer 3× (384).
5. The hardware cursor is unscaled: add a 2× image or use a software cursor.
6. Install theme_pkg with Silver 19/38 and Jersey 19/37, and remove the font_size overrides below 19.
