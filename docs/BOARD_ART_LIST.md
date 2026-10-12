# Expedition Board: art list (mockup v1)

Screen 1280×720, 1 art px = 1 screen px, hard alpha, kit palette only (no new colours). Engine-drawn text (Pixelify Sans stand-in in the mockups).
Every rect is in `board_layout.json`. Mockups: `board_mockup_1x.png` (picker open), `board_mockup_closed_picker_1x.png` (picker closed, can't afford), `board_simulate_results_1x.png` (results window).
Build script: `tools/build_board.py`, new-piece generators in `tools/board_pieces.py`.

## Panel geometry
- Dim: hub × 0.75, then a 58% black overlay (the same as other hub modals).
- Panel 880×600 at (200,60): kit `frame_9s_96` (margins 24, centre TILED with a 48 period). Parchment inner area (224,84)–(1056,636).
- Title plate: kit `title_plate_312x46` at (484,37) with the engine text "Expedition Board".
- Left column x 244 (Party, Mode, warning). Right column x 616 (Route, Loadout, Simulate/cost/Depart).

## NEW pieces (34 files, 15 distinct pieces) — `board/pieces/`
| Piece | Size | 9-slice | States | Use |
|---|---|---|---|---|
| field_9s_* | 24×24 | 6,6,6,6 | normal, focus (gold rim), disabled, invalid (RU rim) | engraved parchment LineEdit (Depth 72 w, Rooms 72 w, loadout count 56 w, all 28 h) |
| glyph_minus / glyph_plus (+ _disabled) | 10×10 | – | normal, disabled | icons on kit wood_button 28×28 for −/+ |
| party_slot_* | 60×60 | – (fixed) | empty, empty_hover, filled, hover, selected (gold), locked | formation squares; 52 px portrait drawn at +4,+4 |
| lock_10x12 | 10×12 | – | – | on locked pick rows / locked slot |
| arrow_enemy_side_12x9 | 12×9 | – | – | "enemies →" marker in the formation bed |
| popup_9s_32x32 | 32×32 | 8,8,8,8 | – | slot picker popup (236 w, auto h) |
| popup_tail_l_8x14 | 8×14 | – | – | popup tail pointing to the slot (left edge, centred on the slot) |
| pick_row_9s_* | 24×24 | 6,6,6,6 | hover, current (gold rim), disabled | 60 px picker rows; normal = no bg |
| wood_button_9s_selected_32x28 | 32×28 | 6,6,6,6 | toggled | kit pressed + gold rim, for the Manual/Idle toggle (ButtonGroup) |
| item_slot_* | 44×44 | – | normal, hover, empty | loadout slots; 32 px item icon at +6,+6 |
| divider_3s_48x6 | 48×6 | 3-slice, ends 8 | – | section rules |
| scroll_track_9s_12x24 | 12×24 | 4,4,4,4 | – | VScrollBar `scroll` |
| scroll_thumb_9s_* | 12×16 | 5,5,5,5 | normal, hover, drag | VScrollBar `grabber*`, min h 24 |
| list_row_9s_* | 24×24 | 4,4,4,4 | even, loss | results rows (26 h); odd rows have no bg |
| cost_chip_9s_* | 24×32 | 8,8,8,8 | ok, short (RU rim) | 84×44 Essence cost chip next to Depart |

## REUSED pieces (no new art)
- Kit (final/kit): frame_9s_96, title_plate_312x46, title_plank_3s_48x40 (results title, ends 16), wood_button_9s_{normal,hover,pressed,disabled}_32x28 (m6; −/+, Mode, Run again), stop_button_*_104x28 + keycap_esc (Close; Esc = same action), play_bevel_9s_6x6 (m2; formation bed + list frame), frame_9s_96 again for the results window, pip_good_12 / pip_miss_12 (room result dots), deco_vine_tl/br.
- Battle v7 (final/battle): action_button_{normal,hover,pressed,disabled}_160x44 (Simulate, Depart), boss_crown_16 (boss room row).
- Repo: portraits/keeper_portrait.png, portraits/elaia_portrait.png, bramble/bramble_portrait.png (52²), ui/icon_essence.png, ui/icon_heart_salve.png (32²).
- Greyed portraits (unavailable/locked) = engine modulate (0.55, 0.55, 0.55) plus a desaturate shader or CanvasItem modulate; no extra art.

## Behaviour notes for Code (decisions taken in the mockup)
- Close/Esc closes the board (the same as a hub modal close); Esc closes the popup/results window first if one is open.
- Depth: typeable SpinBox-like field, −/+ step 1, clamped 1..Reach.max_start_depth ("max N" note). The current PR #34 uses checkpoints 1/5/10; the brief asks for step 1, so the checkpoint rule (if still wanted) needs a design call.
- Rooms: −/+ walk 1, 5, 10, 15, 20… (step 5 after 1); typing accepts any integer ≥1. This replaces ROOM_STEPS [5,10,20,40].
- Party: 6 slots, 2 columns of 3 (back = left, front = right), the middle slot of each column stepped 30 px toward the enemy (v7 formation). Clicking a slot opens the picker anchored to its right (tail centred on the slot). Rows: portrait + name + status line. Current = gold rim; members already placed elsewhere and locked members are disabled (greyed + reason). "Leave empty" clears the slot.
- Bramble is NOT in companions.json yet; the mockup shows "Unlocks at 30 rooms" per the brief.
- Mode: Manual/Idle toggle (2 buttons, one toggled), with a one-line hint below.
- Loadout: 2 slots, count field + −/+ (step 1, hold to repeat), cap min(100, owned); an empty slot opens an item pick (same popup + rows).
- Cost: chip "20" + essence icon. Short = RU text + `cost_chip_short`, Depart uses action_button_disabled, and the hint "Need 20 Essence · you have N" (RU) sits right-aligned under it.
- Simulate opens a SEPARATE window (620×500 at (330,110), 50% black veil over the board) with a summary, a scrolling per-room list (pip, room/beasts, result + items/Essence), Lost line, totals, and Run again. **RunSim currently returns only totals + lost[]; the per-room list needs a per-room log added to RunSim.**
- The running-state view (progress, pack, live formation, **Join the fight**) reuses this panel with no new art.
- Warning text (adv_predeparture_warning + adv_depart_cost) autowraps at 356 px, line height 14 (6 lines at 12 px).

## Count + effort
- New: 15 pieces / 34 state files (all small procedural pieces in the kit palette, already drawn as first-pass finals).
- Reused: 13 kit/battle pieces (with their existing states) + 5 repo images.
- Effort: art polish ≈ 0.5 day (hand-tweak slot/popup/field bevels); Code build ≈ 1–1.5 days (layout from JSON, picker popup, fields, theme for the scrollbar) + ≈ 0.5 day for the RunSim per-room log.
