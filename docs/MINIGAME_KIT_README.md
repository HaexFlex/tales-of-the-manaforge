# Minigame shared kit: FINAL (step 1 of the art order)
Art Direction · 2026-10-11 · box only (`/workspace/minigames_art/final/kit/`). Nothing in the repo, git or messages was touched.

**Rules met:** hard alpha (0/255 only), 1 art px = 1 screen px, one shared palette of **42 colours** for the whole kit (`kit_palette.json` / `.png`; largest single piece uses 19). No cyan anywhere in the kit. Gold `#F2C14E` (+ `#FFEDA8`/`#A8741E` ramp) only on the perfect pip, the Perfect! word and sparkle, the gold pace fill, the target-band bracket/arrows, the active mouse button and the hover bubble ring. Brass nails/ticks use a separate duller brass ramp so they never read as 'active'. Every pixel placed by rule-based code (`tools/pix.py`, `kit_frame.py`, `kit_pieces.py`); no resampling, blur or filters. Rebuild: `cd tools && python3 build_kit_final.py`.

**Baked text:** none, except the three feedback words (Perfect! / Good / Miss, ART_LIST S11 asks for them painted) and the keycap legends (Esc, digits, A/D/W/S, arrows; Space uses a ⎵ bracket symbol, no word). A blank `keycap_9s_14x15.png` exists if you'd rather put legends in with the engine font. Titles, Stop, Successes, Pace, values, hints and toast text all stay engine font.

## 1. Mapping to Code's placeholders (straight texture swap)
Code's folder: `res://assets/art/ui/minigames/placeholder/kit/` (read from the PR #35 branch tip `76fab0e`, `scripts/minigames/minigame_host.gd`). Same file names; copy `final/kit/<file>` over `placeholder/kit/<file>` (or point `_MG_TEX()` at a new `res://assets/art/ui/minigames/kit/`).

| Final file | Replaces placeholder | Size | Notes |
|---|---|---|---|
| `kit/frame_720x448.png` | `frame_720x448.png` | 720×448 = same | NinePatchRect margins 24 unchanged. Now carries the play-area bevel, vines and nails. |
| `kit/title_plate_312x46.png` | `title_plate_312x46.png` | 312×46 = same | TextureRect at title_sprite (484,113). |
| `kit/stop_button_normal_104x28.png` | `stop_button_normal_104x28.png` | same | TextureButton normal |
| `kit/stop_button_hover_104x28.png` | `stop_button_hover_104x28.png` | same | hover |
| `kit/stop_button_pressed_104x28.png` | `stop_button_pressed_104x28.png` | same | pressed (face drops 2 px; Code may nudge the label +2 y on press, optional) |
| `kit/stop_button_disabled_104x28.png` | `stop_button_disabled_104x28.png` | same | disabled |
| `kit/keycap_esc.png` | `keycap_esc.png` | **28×20** (placeholder 28×15) | Only size change: Code's TextureRect has min size 24×20 with default STRETCH_SCALE, so the 28×15 placeholder was being stretched to 20 px tall. The 28×20 canvas shows the cap 1:1 with no code change. |
| `kit/pip_empty_12.png` | `pip_empty_12.png` | same |  |
| `kit/pip_good_12.png` | `pip_good_12.png` | same |  |
| `kit/pip_perfect_12.png` | `pip_perfect_12.png` | same |  |
| `kit/pip_miss_12.png` | `pip_miss_12.png` | same |  |
| `kit/pace_track_136x18.png` | `pace_track_136x18.png` | same | Channel is at (2,2) 132×8, exactly under Code's PaceFill ColorRect (pace_local + (2,2), height 12−4). In the placeholder the channel was 2 px lower than the fill. |

Play-area crops (`placeholder/play/<id>_play_ref.png`) and `palette.json` are not part of this step. The palette's reserved colours are unchanged: gold `#F2C14E`, good `#76BA48`, miss `#968470`.

## 2. Code-side issues seen while mapping (not art; for Code to decide)
1. **Label colours on parchment.** `Successes`, `PaceCaption`, `PaceValue`, `Hint` and `FeelTag` use cream/pale green (`0.93,0.86,0.62` / `0.78,0.86,0.74`), which nearly vanishes on the parchment. Use INK `#3E2A18` there. Cream + 1 px `#1A0F08` shadow is right only on wood (Title, StopLabel).
2. **Header overlaps.** The `Successes` label sits at header x 0 (screen 300) and the pips start at screen 320, so they overlap. The `Pace` caption at screen x 780 runs into the meter at 804. The mock uses label at x 320 → pips from **x 416**, and `Pace` right-aligned to x 797. Suggest `pips.x` 416 in `data/minigames.json` and a right-aligned caption.
3. **Keycap stretch.** This is fixed by the 28×20 canvas, but `stretch_mode = STRETCH_KEEP` on that TextureRect would be cleaner.
4. **Play backdrop** is drawn at alpha 0.35 over the frame. The frame's play well is plain darker parchment (`#D6BE8A`) inside the bevel, so it reads fine either way.

## 3. 9-slice margins (left, top, right, bottom); also in `kit_slices.json`
| Piece | Margins | Stretch | Notes |
|---|---|---|---|
| `frame_720x448.png` | 24/24/24/24 | n/a (drawn 1:1) | Rim 20 + 4 px parchment lip |
| `frame_9s_96.png` | 24/24/24/24 | **TILE** (edges repeat every 48 px) | For other panel sizes. Battle panel rim 16 needs its own render later |
| `play_bevel_9s_6x6.png` | 2/2/2/2 | STRETCH | Centre transparent; rect (318,198,644,324) |
| `title_plank_3s_48x40.png` | 16/0/16/0 | STRETCH | Centre is row-uniform |
| `wood_button_9s_*_32x28.png` | 6/6/6/6 | STRETCH | Min 32×28; pressed content +2 y |
| `keycap_9s_14x15.png` | 3/3/3/4 | STRETCH | Height 15 fixed |
| `toast_9s_40x30.png` | 12/8/12/8 | STRETCH | Height 30 fixed; ribbon tails + leaf live in the side margins |
| `bubble_body_9s_*_24x26.png` | 7/7/7/7 | STRETCH | Add `bubble_tail_*` at (w/2−6, h−3) |
| `gauge_frame_9s_40x24.png` | 8/8/8/8 | STRETCH | Tick-less; the 40×240 version is the default |
| `gauge_band_9s_40x12.png` | 8/3/8/3 | STRETCH | Centre transparent |

## 4. Piece list
| File | Size (px) | Colours | Use / anchor |
|---|---|---|---|
| `frame_720x448.png` | 720×448 | 19 | SWAP. Full-size frame incl. parchment, vines, nails, play-area bevel. NinePatch margins 24 (drawn 1:1 at 720x448). |
| `frame_9s_96.png` | 96×96 | 12 | 9-slice source, margins 24, axis stretch TILE (edges repeat every 48 px). For other panel sizes (battle panel etc.). |
| `deco_vine_tl.png` | 64×54 | 4 | Frame deco, top-left vine (already baked into frame_720x448). Offset from frame TL: (3,2). |
| `deco_vine_br.png` | 58×47 | 4 | Frame deco, bottom-right vine. Offset from frame BR corner: (-62,-52) (negative = left/up). |
| `deco_leaf_8x5.png` | 8×5 | 4 | Single leaf (flip freely; no rotation). |
| `play_bevel_9s_6x6.png` | 6×6 | 5 | 9-slice, margins 2, centre transparent. Place at play rect grown by 2 px: (318,198,644,324). Already baked into frame_720x448. |
| `title_plate_312x46.png` | 312×46 | 14 | SWAP. Plank 288x40 at (12,3) inside the sprite; place sprite at (484,113). Title text (engine font, cream #FAEECC + 1px #1A0F08 shadow) centred in (496,116,288,40). |
| `title_plank_3s_48x40.png` | 48×40 | 7 | 3-slice source: ends 16 / centre 16 (row-uniform, STRETCH safe). For other banner widths (battle round banner, depth tag). |
| `title_sprig_26x20.png` | 26×20 | 4 | Sprig for 3-slice banners; mirror for the right end. |
| `stop_button_normal_104x28.png` | 104×28 | 7 | SWAP. No baked text/keycap: Code draws "Stop" label + keycap_esc on top. |
| `stop_button_hover_104x28.png` | 104×28 | 7 | SWAP. No baked text/keycap: Code draws "Stop" label + keycap_esc on top. |
| `stop_button_pressed_104x28.png` | 104×28 | 4 | SWAP. No baked text/keycap: Code draws "Stop" label + keycap_esc on top. |
| `stop_button_disabled_104x28.png` | 104×28 | 5 | SWAP. No baked text/keycap: Code draws "Stop" label + keycap_esc on top. |
| `wood_button_9s_normal_32x28.png` | 32×28 | 7 | 9-slice margins L6 T6 R6 B6 (centre row/column-uniform, STRETCH safe). Pressed: content moves down 2 px. |
| `wood_button_9s_hover_32x28.png` | 32×28 | 7 | 9-slice margins L6 T6 R6 B6 (centre row/column-uniform, STRETCH safe). Pressed: content moves down 2 px. |
| `wood_button_9s_pressed_32x28.png` | 32×28 | 4 | 9-slice margins L6 T6 R6 B6 (centre row/column-uniform, STRETCH safe). Pressed: content moves down 2 px. |
| `wood_button_9s_disabled_32x28.png` | 32×28 | 5 | 9-slice margins L6 T6 R6 B6 (centre row/column-uniform, STRETCH safe). Pressed: content moves down 2 px. |
| `keycap_esc.png` | 28×20 | 7 | SWAP. 28x20 canvas, cap 24x15 at top-left (rows 0-14, 4 px right padding so it clears the button rim), so Code's 24x20 min-size TextureRect shows it 1:1 (the 28x15 placeholder was being stretched to 20 tall). |
| `keycap_esc_28x15.png` | 28×15 | 7 | Tight Esc keycap. |
| `keycap_9s_14x15.png` | 14×15 | 6 | 9-slice blank keycap, margins L3 T3 R3 B4. Put a legend on it with the engine font (INK #3E2A18). |
| `keycap_space_40x15.png` | 40×15 | 7 | Space (bracket symbol, no word). |
| `keycap_1_14x15.png` | 14×15 | 7 |  |
| `keycap_2_14x15.png` | 14×15 | 7 |  |
| `keycap_3_14x15.png` | 14×15 | 7 |  |
| `keycap_4_14x15.png` | 14×15 | 7 |  |
| `keycap_5_14x15.png` | 14×15 | 7 |  |
| `keycap_6_14x15.png` | 14×15 | 7 |  |
| `keycap_a_14x15.png` | 14×15 | 7 |  |
| `keycap_d_14x15.png` | 14×15 | 7 |  |
| `keycap_w_14x15.png` | 14×15 | 7 |  |
| `keycap_s_14x15.png` | 14×15 | 7 |  |
| `keycap_left_14x15.png` | 14×15 | 7 |  |
| `keycap_right_14x15.png` | 14×15 | 7 |  |
| `keycap_up_14x15.png` | 14×15 | 7 |  |
| `keycap_down_14x15.png` | 14×15 | 7 |  |
| `mouse_l_8x10.png` | 8×10 | 5 | Left click (gold = the button to press). |
| `mouse_r_8x10.png` | 8×10 | 5 | Right click. |
| `mouse_hold_12x10.png` | 12×10 | 6 | Hold (mouse + hourglass). |
| `mouse_drag_16x10.png` | 16×10 | 6 | Drag. |
| `mouse_circle_14x14.png` | 14×14 | 4 | Circle the mouse (clockwise). |
| `pip_empty_12.png` | 12×12 | 4 | SWAP. |
| `pip_good_12.png` | 12×12 | 4 | SWAP. |
| `pip_perfect_12.png` | 12×12 | 5 | SWAP. |
| `pip_miss_12.png` | 12×12 | 4 | SWAP. |
| `pip_pop_16x16_3f.png` | 48×16 | 1 | Horizontal strip, 3 frames 16x16, ~0.05 s each. Centre on the pip (offset -2,-2). Cream, works over good/perfect. |
| `pace_track_136x18.png` | 136×18 | 8 | SWAP. Channel 132x8 at (2,2) = exactly where Code's PaceFill ColorRect sits. Brass ticks under 1x/2x/3x at x 2/68/133 (rows 12-15). |
| `pace_fill_good_132x8.png` | 132×8 | 3 | Optional texture for PaceFill (green). Row-uniform: crop or stretch horizontally. |
| `pace_fill_gold_132x8.png` | 132×8 | 3 | Optional texture for PaceFill at >= 2.95 (gold). |
| `pace_tick_5x4.png` | 5×4 | 4 | Loose tick, centre column = tick x. |
| `fb_perfect_72x22.png` | 72×22 | 5 | Baked word (allowed exception). Centre on the hit point. |
| `fb_good_48x22.png` | 48×22 | 5 | Baked word. |
| `fb_miss_44x22.png` | 44×22 | 5 | Baked word. |
| `fx_perfect_32x32_4f.png` | 128×32 | 5 | Strip 4 x 32x32, ~0.06 s/frame, centre = hit point. |
| `fx_good_24x24_4f.png` | 96×24 | 6 | Strip 4 x 24x24 leaf puff, ~0.07 s/frame. |
| `fx_miss_24x24_3f.png` | 72×24 | 4 | Strip 3 x 24x24 grey wisp rising, ~0.09 s/frame. |
| `num_8x11_sheet.png` | 137×11 | 3 | Big number glyphs (cream, outlined) for gain floats: 0-9 + - . : s m x(=×) %. Rects in num_8x11.json. Modulate to gold for perfect gains. |
| `toast_9s_40x30.png` | 40×30 | 10 | 9-slice margins L12 T8 R12 B8 (centre row-uniform). Draw at h 30. Leaf sits in the right margin. |
| `bubble_body_9s_normal_24x26.png` | 24×26 | 5 | 9-slice margins 7. Add bubble_tail at (w/2-6, h-3). |
| `bubble_tail_normal_13x10.png` | 13×10 | 3 | Tail; overlaps the body's bottom 3 rows. Tip = (6,9). |
| `bubble_normal_128x33.png` | 128×33 | 5 | Pre-built at 128 wide. Tip at (64,32): place tip 8 px above the head/label. |
| `bubble_body_9s_hover_24x26.png` | 24×26 | 5 | 9-slice margins 7. Add bubble_tail at (w/2-6, h-3). |
| `bubble_tail_hover_13x10.png` | 13×10 | 4 | Tail; overlaps the body's bottom 3 rows. Tip = (6,9). |
| `bubble_hover_128x33.png` | 128×33 | 6 | Pre-built at 128 wide. Tip at (64,32): place tip 8 px above the head/label. |
| `bubble_hand_18x14.png` | 18×14 | 7 | Hand + leaf glyph, left of the label inside the bubble (x 8, centred). |
| `bubble_pop_128x40_3f.png` | 384×40 | 5 | Strip 3 x 128x40, tip at (64,39) in every frame. Then show bubble_normal (tip (64,32)). |
| `gauge_frame_40x240.png` | 40×240 | 12 | Shared by Just Enough + Steady Press. Glass/fill rect (8,8,24,224). Brass ticks at 25/50/75%. |
| `gauge_frame_9s_40x24.png` | 40×24 | 11 | 9-slice margins L8 T8 R8 B8 for other heights (no ticks). |
| `gauge_band_9s_40x12.png` | 40×12 | 4 | Gold target-band bracket, 9-slice margins L8 T3 R8 B3, centre transparent. Rect = band rows over the gauge. |
| `gauge_arrow_r_6x11.png` | 6×11 | 4 | Points right; place left of the gauge at the band centre (tip at x 5, y 5). |
| `gauge_arrow_l_6x11.png` | 6×11 | 4 | Points left; place right of the gauge. |

Plus `num_8x11.json` (glyph rects), `kit_slices.json`, `kit_palette.json`, `kit_palette.png`.

## 5. Weak spots / open
- **Feedback FX** (sparkle, leaf puff, wisp) and the **pip pop** are serviceable but simple, a first pass. Worth a polish pass once seen in motion in the feel test.
- **Brass nails** are 4×4 and quiet at 1×. On purpose, but if Haex wants the brass to read more, they can go to 6×6.
- **Title plate** is plain by design (the text needs a calm field). Leaves and sprigs only at the ends.
- **Hold glyph** (mouse + hourglass) is the least obvious hint. Footer text carries the meaning.
- **The Lend-a-hand bubble pop** is 3 hand-drawn sizes, not a scale tween, so it's a little steppy by design.
- `frame_9s_96` tiles the bark every 48 px. Fine for the battle panel, but a rim-16 version for the battle bottom panel is a separate render (battle step).
- The **mock dims the whole screenshot**, HUD included. In game the dim is world-only (layer 19), so the top HUD stays bright. A flat screenshot can't separate the two.
- Labels in the previews use Pixelify Sans as a stand-in for the engine font. The project font is still Code's open call (Q9).
