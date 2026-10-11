# Expedition Board: final art

Final pass, 2026-10-11 (after Haex approved the mockup). Kit palette only (26 colours shared across all 34 files, no new colours). Hard alpha (0/255). 1 art px = 1 screen px. All text is engine-drawn.
Source: `tools/board_pieces.py` + `tools/build_board.py` (writes `board/pieces/`, this folder, `previews/` and `board_layout.json`).

- `*.png`: the 34 new piece files (15 pieces).
- `board_layout.json`: every rect for 1280×720. It has a `changes_since_approved_mockup` list and an `essence_icon` entry.
- `previews/board_mockup_1x.png`, `previews/board_mockup_closed_picker_1x.png`, `previews/board_simulate_results_1x.png`: rebuilt with the final art.

## Mapping: Code name → final file
Code's working copy (`/workspace/pr33_local`) already uses these exact names under `res://assets/art/ui/board/` (copied from the mockup drafts). It also has `docs/BOARD_ART_LIST.md` and `tests/fixtures/board_layout.json`. No script references a texture path yet, so the names are matched 1:1: **drop these files over `res://assets/art/ui/board/` (same names) and replace `tests/fixtures/board_layout.json` with this folder's `board_layout.json`.**

| res://assets/art/ui/board/… (= final file) | Size | 9-slice (L,T,R,B) | State | Godot use |
|---|---|---|---|---|
| field_9s_normal_24x24.png | 24×24 | 6,6,6,6 | normal | LineEdit `normal` StyleBoxTexture |
| field_9s_focus_24x24.png | 24×24 | 6,6,6,6 | focus (gold rim) | LineEdit `focus` |
| field_9s_disabled_24x24.png | 24×24 | 6,6,6,6 | disabled | LineEdit `read_only` |
| field_9s_invalid_24x24.png | 24×24 | 6,6,6,6 | invalid (out-of-range input, flash) | swap the `normal` box briefly |
| glyph_minus_10x10.png / glyph_minus_disabled_10x10.png | 10×10 | – | normal / disabled | −, the Button icon centred on the kit wood button 28×28 |
| glyph_plus_10x10.png / glyph_plus_disabled_10x10.png | 10×10 | – | normal / disabled | + |
| party_slot_empty_60x60.png | 60×60 | – (fixed) | empty | formation square |
| party_slot_empty_hover_60x60.png | 60×60 | – | empty + hover | (polished: 2 px light rim, brighter plus) |
| party_slot_filled_60x60.png | 60×60 | – | filled | portrait 52 at +4,+4 |
| party_slot_hover_60x60.png | 60×60 | – | filled + hover | (polished: 2 px light rim) |
| party_slot_selected_60x60.png | 60×60 | – | picker open on this slot (gold) | |
| party_slot_locked_60x60.png | 60×60 | – | locked (spare; not in the mockups) | |
| lock_10x12.png | 10×12 | – | – | on a locked picker row, portrait-local (40,38) |
| arrow_enemy_side_12x9.png | 12×9 | – | – | "enemies" marker, formation bed top right |
| popup_9s_32x32.png | 32×32 | 8,8,8,8 | – | picker PopupPanel `panel` |
| popup_tail_l_8x14.png | 8×14 | – | – | tail at popup.x − 6, slot centre − 7 |
| pick_row_9s_hover_24x24.png | 24×24 | 6,6,6,6 | hover | picker row Button `hover` (normal = empty StyleBox) |
| pick_row_9s_current_24x24.png | 24×24 | 6,6,6,6 | current (gold) | the member in this slot |
| pick_row_9s_disabled_24x24.png | 24×24 | 6,6,6,6 | disabled | placed elsewhere / locked; also grey the portrait with modulate (0.55,0.55,0.55) |
| wood_button_9s_selected_32x28.png | 32×28 | 6,6,6,6 | toggled ON | Manual/Idle `pressed` for a toggle_mode Button in a ButtonGroup |
| item_slot_normal_44x44.png | 44×44 | – | normal | loadout well; item icon 32 at +6,+6 |
| item_slot_hover_44x44.png | 44×44 | – | hover | (polished: light rim) |
| item_slot_empty_44x44.png | 44×44 | – | empty | |
| divider_3s_48x6.png | 48×6 | 8,0,8,0 (3-slice) | – | section rules (424 and 796 wide) |
| scroll_track_9s_12x24.png | 12×24 | 4,4,4,4 | – | VScrollBar `scroll` |
| scroll_thumb_9s_normal_12x16.png | 12×16 | 5,5,5,5 | normal | `grabber` |
| scroll_thumb_9s_hover_12x16.png | 12×16 | 5,5,5,5 | hover | `grabber_highlight` |
| scroll_thumb_9s_drag_12x16.png | 12×16 | 5,5,5,5 | drag | `grabber_pressed` (polished: light wood, no gold) |
| list_row_9s_even_24x24.png | 24×24 | 4,4,4,4 | even row | results rows, 26 px pitch (odd rows have no bg) |
| list_row_9s_loss_24x24.png | 24×24 | 4,4,4,4 | loss row | row where a loss happened (rust edge) |
| cost_chip_9s_ok_24x32.png | 24×32 | 8,8,8,8 | can afford | 84×44 chip left of Depart |
| cost_chip_9s_short_24x32.png | 24×32 | 8,8,8,8 | short | "20" in RU0 |

## Reused art (not in this folder)
| Use | Path in the game repo |
|---|---|
| Board frame + results window | `res://assets/art/ui/minigames/kit/frame_9s_96.png` (9s 24, centre TILE) |
| Title | `…/kit/title_plate_312x46.png` (board), `…/kit/title_plank_3s_48x40.png` (results, ends 16) |
| −/+, Mode off, Run again | `…/kit/wood_button_9s_{normal,hover,pressed,disabled}_32x28.png` (9s 6) |
| Close + Esc | `…/kit/stop_button_{normal,hover,pressed,disabled}_104x28.png`, `…/kit/keycap_esc.png` |
| Formation bed / list frame | `…/kit/play_bevel_9s_6x6.png` (9s 2) |
| Result dots, vines | `…/kit/pip_good_12.png`, `…/kit/pip_miss_12.png`, `…/kit/deco_vine_{tl,br}.png` |
| Simulate / Depart | `res://assets/art/battle/ui/action_button_{normal,hover,pressed,disabled}_160x44.png` |
| Boss row | `res://assets/art/battle/ui/boss_crown_16.png` |
| Portraits | `res://assets/art/portraits/{keeper,elaia}_portrait.png`, `res://assets/art/bramble/bramble_portrait.png` (52²) |
| Heart Salve | `res://assets/art/ui/icon_heart_salve.png` |
| **Essence** | `res://assets/art/ui/icon_essence.png` **with modulate `Color(0.78, 0.62, 1.18, 1.0)`**: exactly what the HUD resource panel does (`scripts/hud.gd` `ICON_ESSENCE_TEX` + `ESSENCE_TINT`, node `HUD/Panel/IconRow/EssenceChip/IconEssence`). The raw file is cyan; the HUD always shows it tinted blue. Use it in the cost chip, the results "Essence back" line and anywhere else Essence appears. |

The kit lives in PR #35 (`/workspace/pr35_wt/assets/art/ui/minigames/kit/`, byte-identical to `final/kit`). It is **not** in the PR #34 stack, so the board branch must sit on top of #35 or include those kit files.

## Changes since the approved mockup
1. Essence icon: now the HUD one (texture + ESSENCE_TINT) instead of the untinted cyan swirl. Boss payback stays at **15** (strings `adv_depart_cost`, `SlotEngine.BOSS_ESSENCE = 15`, spawn_tables note: all agree).
2. Picker popup: rows 60 → 56 px (row bg 54 h, portrait at +3,+1, name +62,+12, sub +62,+32). y = clamp(slot.y − 76, 140, 418 − h), so its bottom never passes the formation bed and the Mode title/toggle stay visible. For back_mid: 236×262 at (362,156), was 236×278 at (362,190). The tail still points at the slot centre. While the popup is open it covers the "click a square to pick" hint (on purpose). No other rect moved.
3. Hover outlines (party slots, item slot): 2 px light rim (W7 + CR) instead of a 1 px W6 line. The empty hover also brightens the fill and the plus.
4. Scrollbar thumb drag: light wood, not gold (gold stays for active/selected/focus).
5. Slot empty/locked: dashed ring tidied (even spacing). Changed files vs Code's current copies: item_slot_hover, party_slot_{empty,empty_hover,hover,locked}, scroll_thumb_9s_drag. The other 28 are unchanged.
