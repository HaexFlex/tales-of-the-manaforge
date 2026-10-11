# Battle UI v7: FINAL art
Art Direction · 2026-10-11 · box only (`/workspace/minigames_art/final/battle/`). Same language as the minigame kit (`final/kit/`). No repo, git or messages touched.

**Rules met** (checked by script on every export):
- hard alpha (0/255), 1 art px = 1 screen px;
- **48 colours** = the kit's 42 + 6:
  - Weave cyan `#3AA6B4` / `#8FE3E6`, **only in `bar_weave_50x2.png`** (script-verified);
  - rust `#8E3A24` / `#B85638` for HP low + the Heavy threat tag/marks;
  - poison purple `#6E3E8A` / `#A46CC4` for the Poison intent icon.
- Gold only on active (plate rim, arrow, toggled Strike-for-me, selected speed) and target (ring, corners). Hover states are lighter wood, not gold (except the tiny log-toggle chevron).
- **No text in the art.** Exceptions, all glyphs/numerals rather than words:
  - speed buttons `1×/2×/4×` (straight swap for the existing textures; blank variants included);
  - optional `×1.5/×2/×3` intent tags;
  - keycap digits (kit).
- Rebuild: `cd tools && python3 build_battle_final.py` (`battle_pieces.py`; palette additions in `pix.py` `BATTLE_EXTRA`). The kit is unchanged (md5-verified after rebuild).

**Placeholder names.** No PR #34 checkout with v7 wiring is on the box:
- `/workspace/pr33_local` is now on `feat/battle-bundle-2-data` and has the pre-v7 `battle_view.gd` (party bar + 96×38 beast plates, ColorRect/ProgressBar UI);
- no `ui/battle/placeholder` dir exists anywhere.

So the mapping uses the **v7 scaffold's own pieces** (`tools/build_battle_v7.py` + `build_battle.py` helpers) plus the repo textures the scaffold references. Final files keep the repo names where a repo file exists (speed buttons, `slot_mark_target.png`). Suggested home: `res://assets/art/ui/battle/` (speed buttons: overwrite `res://assets/art/ui/buttons/`; target ring: overwrite `res://assets/art/battle/arena/slot_mark_target.png`).

## 1. Mapping: placeholder → final
| Scaffold placeholder (source) | Size | Final file(s) | Size | 9-slice (L,T,R,B) | Anchor / notes |
|---|---|---|---|---|---|
| `plate(name,lv,hp,weave)` party (build_battle.py) | 56×24 | `plate_party_56x24.png`, `plate_party_active_56x24.png` | 56×24 | none (fixed) | Top-left (x−28, y+10). Name at (4, 6) left/mid, level right-aligned at x 52, font 10. HP fill rect (3,12) 50×4; Weave fill rect (3,17) 50×2 |
| same, beasts (mock showed Weave on beasts) | 56×24 | `plate_beast_56x20.png`, `plate_beast_active_56x20.png` | 56×20 | none | Same top-left (x−28, y+10); Weave row dropped, 4 px shorter (lowest plate now ends y 566). HP fill rect (3,12) 50×4 |
| `plate` active = gold rounded rect | 56×24 | `*_active_*` | – | – | Gold rim replaces the outline; Code's old 2 px ColorRect outline (`battle_plate_outline`) can go |
| bar fills drawn inline (HP green/amber/red, Weave cyan) | 50×4 / 50×2 | `bar_hp_ok_50x4.png`, `bar_hp_low_50x4.png`, `bar_shield_50x4.png`, `bar_weave_50x2.png` | 50×4, 50×2 | row-uniform (crop or TextureProgressBar) | HP ok above 30%, low at or below 30% (Code's call). Shield: overlay segment drawn right after the HP fill, width = shield/max_hp × 50, clamped |
| `active_arrow()` | 13×8 | `active_arrow_13x9.png` | 13×9 | – | Top-left ((bbox cx) − 6, bbox top − 15); tip 6 px above the head. Bob 1 px in code |
| `arena/slot_mark_target.png` (repo, pale outline) | 56×16 | `slot_mark_target.png` | 56×16 | – | **Same name/size**: (x−28, y−8) under the target's feet |
| corner brackets drawn with lines | ~6×6 | `target_corner_6x6.png` | 6×6 | – | TL at (bbox x0−4, bbox y0−4); flip H for TR at (x1−2, y0−4), V for BL (x0−4, y1−2), both for BR (x1−2, y1−2) |
| `intent_bubble(kind)` | 22×26 | `intent_bubble_22x26.png` | 22×26 | – | Top-left (visible centre x − 10, visible top − 28). Icon at (3,2). Tail tip (10,23) |
| `intent_bubble(kind, '×1.5')` | 40×26 | `intent_bubble_wide_40x26.png` | 40×26 | – | Icon at (3,2); multiplier from x 21: `intent_mult_x1_5.png` / `_x2` / `_x3` at (21,7), or engine text 10 px in `#8E3A24` |
| `icon16('strike'/'heavy'/'poison')` | 16×16 | `intent_strike_16.png`, `intent_heavy_16.png` (v2, see update), `intent_poison_16.png` | 16×16 | – | Replaces the S/H/P letters |
| `plank(120,28,'Depth 12')` | 120×28 | `depth_plate_120x28.png` (+`banner_3s_48x28.png`) | 120×28 | 3-slice 16/0/16/0 | At (16,12); text centred, cream + 1 px shadow |
| `plank(300,32,…)` + sprigs | 324×38 | `round_banner_324x38.png` (+`banner_3s_48x32.png`) | 324×38 | 3-slice 16/0/16/0 | At (478,8); text centred in plank rect (490,11,300,32) |
| repo `ui/buttons/speed_{1x,2x,4x}_{normal,hover,pressed}.png` | 32×32 | `speed_{1x,2x,4x}_{normal,hover,pressed,selected}.png`; `speed_blank_{state}_32x32.png` | 32×32 | – | **Same names** (straight swap) + new `selected` state for the current speed. At (1124 + i·36, 12) |
| `frame(1280,136,16)` | 1280×136 | `bottom_panel_1280x136.png` (+`bottom_panel_9s_48.png`) | 1280×136 | 9s source: 16/16/16/16, TILE | At (0,584) |
| `button(160,44,…, key=n)` × 6 | 160×44 | `action_button_{normal,hover,pressed,disabled,toggled}_160x44.png` | 160×44 | none (kit `wood_button_9s_*` m6 also fits) | Grid origin (24,600), pitch 168 × 52. Icon 32 at (6,5) (+2 y pressed/toggled). Label x 44, centre y 19 (+2). Keycap `final/kit/keycap_{1..6}_14x15.png` at (141,12) (+2). `toggled` = Strike for me ON |
| action icons: repo sword, `icon16` ability/brace/flee, heart salve, hud_character | 16 / 32 | `icon_ability_32.png`, `icon_brace_32.png`, `icon_flee_32.png` (new); reuse `ui/icon_stone_sword.png`, `ui/icon_heart_salve.png`, `ui/icons/hud_character.png` | 32×32 | – | All six now 32 px |
| keycaps (kit.py `keycap`) | ~14×15 | `final/kit/keycap_{1..6}_14x15.png` | 14×15 | – | Reused from the kit |
| log inset (2 px rectangles + parchment) | 732×108 | `log_panel_732x108.png` (+`log_panel_9s_12.png`) | 732×108 | 9s: 4/4/4/4 | At (526,598) = log rect 528,600–1256,704 grown by 2. Lines at x 538, first centre y 612, leading 19, 12 px |
| "Log · details +" text | – | `log_toggle_{closed,open}_{normal,hover}_11x11.png` | 11×11 | – | Chip at (1240,606); engine text "Log · details" right-aligned to x 1234, centre y 612. ▸ = collapsed, ▾ = expanded |
| `arena/shadow_{s,m,l}.png`, `arena/slot_mark.png` (repo) | 40×10 / 64×16 / 96×24, 56×16 | **unchanged (reused)** | – | – | Already final art in the arena's palette; they sit in the ground layer, not the UI |

## 2. Code must change (not art)
1. **Text colours.** Use these colours (the scaffold drew ink on parchment; Godot's default is white):
   - plate name: INK `#3E2A18`; level: `#5E3A22`;
   - log lines: INK `#3E2A18`; misses `#5E5244`; threats (Heavy wind-up) `#8E3A24`; round/system lines `#5E3A22`;
   - "Log · details": `#5E3A22`;
   - text on wood (buttons, depth, banner): cream `#FAEECC` + 1 px `#1A0F08` shadow (+2 px y when pressed); disabled label `#A49684`.
2. **Beast plate is 56×20** (no Weave). If beasts keep a Weave bar, use the party plate for both sides.
3. **Bars:** swap ProgressBar/ColorRect for TextureProgressBar (`texture_progress` = the fill, `texture_under` none: the trough is in the plate) or TextureRect + `region`. HP texture switches ok → low at ≤ 30%.
4. **Speed buttons:** add the `selected` texture for the current speed (`texture_pressed` stays the click state).
5. **Active outline:** the plate rim is now gold in the texture, so the extra `battle_plate_outline` ColorRect is redundant. The sprite outline stays the shader (gold `#F2C14E`).
6. **Disabled action button:** modulate the icon (≈ `Color(0.65,0.6,0.55)`); the art has no separate grey icons.
7. **Nearest filter, no scaling.** Fonts: plates use 10 px, as in the mock. A 10 px engine font is tight for "Snapper 4" in 56 px; long names need a smaller font or a clip.

## 3. Piece list
| File | Size | Colours | Note |
|---|---|---|---|
| `plate_party_56x24.png` | 56×24 | 7 | Name+level rows 2-10 (engine text). HP trough (3,12) 50x4, Weave trough (3,17) 50x2. |
| `plate_party_active_56x24.png` | 56×24 | 10 | Active fighter: gold rim. |
| `plate_beast_56x20.png` | 56×20 | 7 | Beast plate, Weave row omitted. HP trough (3,12) 50x4. Same anchor (x-28, y+10). |
| `plate_beast_active_56x20.png` | 56×20 | 10 | Active beast (its turn). |
| `bar_hp_ok_50x4.png` | 50×4 | 3 | Row-uniform; TextureProgressBar fill (left to right) or crop. |
| `bar_hp_low_50x4.png` | 50×4 | 3 | Row-uniform; TextureProgressBar fill (left to right) or crop. |
| `bar_shield_50x4.png` | 50×4 | 3 | Row-uniform; TextureProgressBar fill (left to right) or crop. |
| `bar_weave_50x2.png` | 50×2 | 2 | Weave fill (the only cyan in the UI). |
| `active_arrow_13x9.png` | 13×9 | 4 | Tip at (6,8). Place tip 6 px above the visible top, centred. Bob 1 px in code. |
| `slot_mark_target.png` | 56×16 | 4 | SAME NAME/SIZE as arena/slot_mark_target.png (56x16). Gold ring under the target's feet: (x-28, y-8). |
| `target_corner_6x6.png` | 6×6 | 3 | Top-left bracket; flip H/V for the other 3. Outer corner at bbox -4 px. |
| `intent_bubble_22x26.png` | 22×26 | 5 | Icon 16x16 at (3,2). Tail tip (10,23). Anchor (visible centre x - 10, visible top - 28). |
| `intent_bubble_wide_40x26.png` | 40×26 | 5 | With multiplier: icon at (3,2), tag/text from x 21, centre y 10. |
| `intent_strike_16.png` | 16×16 | 7 |  |
| `intent_heavy_16.png` | 16×16 | 6 | Heavy v2 = option A (down-smash). Replaces the stone maul. |
| `intent_poison_16.png` | 16×16 | 4 |  |
| `intent_mult_x1_5.png` | 17×7 | 1 | OPTIONAL baked tag (pixel numerals). Place at (21, 7) in the wide bubble. Or use engine text. |
| `intent_mult_x2.png` | 10×7 | 1 | OPTIONAL baked tag (pixel numerals). Place at (21, 7) in the wide bubble. Or use engine text. |
| `intent_mult_x3.png` | 10×7 | 1 | OPTIONAL baked tag (pixel numerals). Place at (21, 7) in the wide bubble. Or use engine text. |
| `icon_ability_32.png` | 32×32 | 6 | Action icon (new). |
| `icon_brace_32.png` | 32×32 | 10 | Action icon (new). |
| `icon_flee_32.png` | 32×32 | 5 | Action icon (new). |
| `bottom_panel_1280x136.png` | 1280×136 | 19 | At (0,584). Rim 16, parchment centre. |
| `bottom_panel_9s_48.png` | 48×48 | 11 | 9-slice margins 16, axis stretch TILE (bark), for other sizes. |
| `action_button_normal_160x44.png` | 160×44 | 7 | Icon 32 at (6,6) [pressed/toggled (6,8)], label x 44, keycap at (w-19, 15). |
| `action_button_hover_160x44.png` | 160×44 | 7 | Icon 32 at (6,6) [pressed/toggled (6,8)], label x 44, keycap at (w-19, 15). |
| `action_button_pressed_160x44.png` | 160×44 | 4 | Icon 32 at (6,6) [pressed/toggled (6,8)], label x 44, keycap at (w-19, 15). |
| `action_button_disabled_160x44.png` | 160×44 | 5 | Icon 32 at (6,6) [pressed/toggled (6,8)], label x 44, keycap at (w-19, 15). |
| `action_button_toggled_160x44.png` | 160×44 | 6 | Icon 32 at (6,6) [pressed/toggled (6,8)], label x 44, keycap at (w-19, 15). |
| `log_panel_732x108.png` | 732×108 | 9 | At (526,598): bevel 2 px around the log rect 528,600-1256,704. |
| `log_panel_9s_12.png` | 12×12 | 8 | 9-slice margins 4 (2 bevel + 2 shadow), rect grown by 2. |
| `log_toggle_closed_normal_11x11.png` | 11×11 | 7 | "details" toggle chip; closed = ▸, open = ▾. |
| `log_toggle_closed_hover_11x11.png` | 11×11 | 7 | "details" toggle chip; closed = ▸, open = ▾. |
| `log_toggle_open_normal_11x11.png` | 11×11 | 7 | "details" toggle chip; closed = ▸, open = ▾. |
| `log_toggle_open_hover_11x11.png` | 11×11 | 7 | "details" toggle chip; closed = ▸, open = ▾. |
| `depth_plate_120x28.png` | 120×28 | 10 | At (16,12). Text centred, cream. |
| `round_banner_324x38.png` | 324×38 | 14 | At (478,8); plank 300x32 at (12,3) inside. Text centred in (490,11,300,32). |
| `banner_3s_48x32.png` | 48×32 | 7 | 3-slice ends 16 for other banner widths. |
| `banner_3s_48x28.png` | 48×28 | 7 | 3-slice ends 16 (depth tag height). |
| `speed_1x_normal.png` | 32×32 | 8 | SAME NAMES as ui/buttons/speed_*; 32x32. "selected" = current speed (new state). |
| `speed_1x_hover.png` | 32×32 | 8 | SAME NAMES as ui/buttons/speed_*; 32x32. "selected" = current speed (new state). |
| `speed_1x_pressed.png` | 32×32 | 5 | SAME NAMES as ui/buttons/speed_*; 32x32. "selected" = current speed (new state). |
| `speed_1x_selected.png` | 32×32 | 6 | SAME NAMES as ui/buttons/speed_*; 32x32. "selected" = current speed (new state). |
| `speed_2x_normal.png` | 32×32 | 8 | SAME NAMES as ui/buttons/speed_*; 32x32. "selected" = current speed (new state). |
| `speed_2x_hover.png` | 32×32 | 8 | SAME NAMES as ui/buttons/speed_*; 32x32. "selected" = current speed (new state). |
| `speed_2x_pressed.png` | 32×32 | 5 | SAME NAMES as ui/buttons/speed_*; 32x32. "selected" = current speed (new state). |
| `speed_2x_selected.png` | 32×32 | 6 | SAME NAMES as ui/buttons/speed_*; 32x32. "selected" = current speed (new state). |
| `speed_4x_normal.png` | 32×32 | 8 | SAME NAMES as ui/buttons/speed_*; 32x32. "selected" = current speed (new state). |
| `speed_4x_hover.png` | 32×32 | 8 | SAME NAMES as ui/buttons/speed_*; 32x32. "selected" = current speed (new state). |
| `speed_4x_pressed.png` | 32×32 | 5 | SAME NAMES as ui/buttons/speed_*; 32x32. "selected" = current speed (new state). |
| `speed_4x_selected.png` | 32×32 | 6 | SAME NAMES as ui/buttons/speed_*; 32x32. "selected" = current speed (new state). |
| `speed_blank_normal_32x32.png` | 32×32 | 7 | No numeral: engine label variant. |
| `speed_blank_hover_32x32.png` | 32×32 | 7 | No numeral: engine label variant. |
| `speed_blank_pressed_32x32.png` | 32×32 | 4 | No numeral: engine label variant. |
| `speed_blank_selected_32x32.png` | 32×32 | 6 | No numeral: engine label variant. |
| `status_poisoned_12.png` | 12×12 | 4 | Poisoned. 12x12 incl. 1 px O outline. Status row: (2 + i*13, plate_h + 1), max 3. |
| `status_braced_12.png` | 12×12 | 7 | Braced. 12x12 incl. 1 px O outline. Status row: (2 + i*13, plate_h + 1), max 3. |
| `status_shield_12.png` | 12×12 | 8 | Shield (Sap Spring). 12x12 incl. 1 px O outline. Status row: (2 + i*13, plate_h + 1), max 3. |
| `status_rootbind_12.png` | 12×12 | 7 | Rootbind / Snared. 12x12 incl. 1 px O outline. Status row: (2 + i*13, plate_h + 1), max 3. |
| `status_slowed_12.png` | 12×12 | 5 | Slowed (Thicket). 12x12 incl. 1 px O outline. Status row: (2 + i*13, plate_h + 1), max 3. |
| `status_fogged_12.png` | 12×12 | 4 | Fogged (Fog). 12x12 incl. 1 px O outline. Status row: (2 + i*13, plate_h + 1), max 3. |
| `status_calmed_12.png` | 12×12 | 4 | Calmed (beast). 12x12 incl. 1 px O outline. Status row: (2 + i*13, plate_h + 1), max 3. |
| `status_ko_12.png` | 12×12 | 3 | Knocked out (party). 12x12 incl. 1 px O outline. Status row: (2 + i*13, plate_h + 1), max 3. |
| `twist_ambush_12.png` | 12×12 | 4 | Ambush (twist chip). 12x12 incl. 1 px O outline. Status row: (2 + i*13, plate_h + 1), max 3. |
| `twist_rich_hollow_12.png` | 12×12 | 7 | Rich Hollow (twist chip). 12x12 incl. 1 px O outline. Status row: (2 + i*13, plate_h + 1), max 3. |
| `boss_crown_16.png` | 16×16 | 9 | Boss mark. Plate-relative (-15, 2): left of the plate, outside the name. |
| `plate_beast_boss_56x20.png` | 56×20 | 8 | Boss beast plate: rust inner frame + thorn ticks. Same anchor/bars as plate_beast. |
| `plate_beast_boss_active_56x20.png` | 56×20 | 11 | Boss plate on its turn (gold rim). |
| `boss_sigil_176x24.png` | 176×24 | 3 | OPTIONAL ground ring under the boss: (x-88, y-12), ground layer under the shadow. |
| `intent_heavy_opt_a_smash_16.png` | 16×16 | 6 | Heavy option: A smash. |
| `intent_heavy_opt_b_boulder_16.png` | 16×16 | 6 | Heavy option: B boulder. |
| `intent_heavy_opt_c_maul_16.png` | 16×16 | 7 | Heavy option: C maul down. |
| `intent_heavy_opt_0_maul_old_16.png` | 16×16 | 8 | Heavy option: old maul. |

## 4. Weak spots / not drawn
- ~~Status icons and boss mark not drawn~~ → done in the 2026-10-11 update below.
- ~~Heavy maul reads weakly~~ → replaced by Heavy v2 (down-smash), see update.
- **Ability icon** (rune stone, green glyph) is deliberately not cyan, by the "cyan = Weave bar only" rule. If Ability means "spend Weave", a cyan accent would read better; that's Haex's call.
- **Plates are tight:** 10 px name + level in 56 px. The art leaves rows 2–10 for text; long beast names will collide with the level.
- **Shield overlay** is a brass segment after HP. It needs Code's max-HP clamp rule; the preview fakes 12 px on one ally.
- **Beasts still use draft idles** in the preview; the art here is UI only.
- **Preview text** is Pixelify Sans standing in for the engine font.


---
# Update 2026-10-11 (17:30): status icons, boss mark, Heavy v2, level and keycap checks
Rebuild: `cd tools && python3 build_battle_final.py && python3 build_battle_icons_sheet.py` (new art in `tools/battle_icons.py`).
- Same 48 colours; nothing new added.
- Hard alpha, checked by script.
- Statuses and boss pieces use **no gold** (gold stays on the active and target pieces only). The only gold boss piece is the *active* boss plate rim.
- No cyan.
- Kit unchanged (md5). The other battle files are byte-identical except `intent_heavy_16.png`.

**Placeholder list read:** `/workspace/review_scratch/battle_ui_placeholders.md` (PR #34, `res://assets/art/battle/ui_placeholder/`).
- It has **no** placeholders for statuses, boss, level or keycaps, so the new files use `final/battle` naming.
- Its existing names map as in section A2 below. Per that note, Code renames in the swap commit.

## A1. Status list and where it comes from
| Status | Source | Who | File |
|---|---|---|---|
| Poisoned | BATTLE_SCENE_DRAFT v4 §9/§10 (poison 3 ticks, refreshes); `fight_state.gd` `apply_poison`/`poison_left` | party (beast poison), beasts later (Bile) | `status_poisoned_12.png` |
| Braced | Draft §3 Brace; `fight_state.gd` `brace`, ends at turn start | party | `status_braced_12.png` |
| Shield | Draft §10 Sap Spring twist (20% max-HP shield); `fight_state.gd` `who.shield` | party | `status_shield_12.png` |
| Rootbind / Snared | `echo_battle.gd` `_do_rootbind` + `data/echo_bramble_02.json` (Bramble echo: Keeper's next Strike halved). **Not in the v4 adventure rules** | party (echo fight) | `status_rootbind_12.png` |
| Slowed | Draft §10 Thicket twist (−2 Swiftness, everyone); `fight_state.gd` `twist == "thicket"` | all (twist) | `status_slowed_12.png` |
| Fogged | Draft §10 Fog twist (−2 attack totals, everyone); `fight_state.gd` `twist == "fog"` | all (twist) | `status_fogged_12.png` |
| Calmed | Draft §2/§5; `resolver.gd` `status_for` → "calmed" | beasts | `status_calmed_12.png` (optional: Code shows the word on the plate today) |
| Knocked out | `resolver.gd` `status_for` → "ko" | party | `status_ko_12.png` (optional, same) |
| Ambush | Draft §10 twist (beasts first in round 1) | fight-wide | `twist_ambush_12.png` (optional twist chip) |
| Rich Hollow | Draft §10 twist (+1 bonus-drop roll) | fight-wide | `twist_rich_hollow_12.png` (optional twist chip) |

- **Bile** is the same status as Poisoned (`status_poisoned`), per Haex's poison rule.
- **Slow / snare / weaken / stun** don't exist anywhere in the rules or code. Snare appears only as Bramble's physical swing name (`echo_battle.gd`), so it is drawn as Rootbind.

## A2. Mapping (placeholder → final)
| PR #34 placeholder (`ui_placeholder/`) | Final file | Size | 9-slice margins | Anchor / notes |
|---|---|---|---|---|
| `plate_bg.png` (party) | `plate_party_56x24.png` | 56×24 | none | (x−28, y+10) |
| `plate_bg.png` (beast) | `plate_beast_56x20.png` | 56×20 | none | same; Weave hidden → 4 px shorter |
| `plate_bg_active.png` | `plate_party_active_56x24.png` / `plate_beast_active_56x20.png` | | none | |
| — (BossLabel text) | `plate_beast_boss_56x20.png`, `plate_beast_boss_active_56x20.png` | 56×20 | none | Same anchor and bar rects as `plate_beast`; replaces the "Boss" label |
| — (BossLabel text) | `boss_crown_16.png` | 16×16 | – | Plate-relative **(−15, 2)**: left of the plate, never over the name |
| — | `boss_sigil_176x24.png` (optional) | 176×24 | – | Ground layer, under the shadow: (x−88, y−12) |
| `active_arrow.png` | `active_arrow_13x9.png` | 13×9 | – | |
| `intent_bubble.png` / `intent_bubble_wide.png` | `intent_bubble_22x26.png` / `intent_bubble_wide_40x26.png` | | – | |
| `icon_strike.png` (intent) | `intent_strike_16.png` | 16 | – | Icon at (3,2) |
| `icon_heavy.png` | **`intent_heavy_16.png` (v2 = option A, down-smash)** | 16 | – | Options kept: `intent_heavy_opt_{a_smash,b_boulder,c_maul,0_maul_old}_16.png` |
| `icon_poison.png` (intent) | `intent_poison_16.png` | 16 | – | |
| `icon_ability` / `icon_brace` / `icon_flee.png` | `icon_ability_32` / `icon_brace_32` / `icon_flee_32.png` | 32 | – | `icon_strike` (action) stays `ui/icon_stone_sword.png` |
| `action_button_{normal,hover,pressed,disabled}.png` | `action_button_{…}_160x44.png` (+ `toggled`) | 160×44 | Code's StyleBoxTexture margin 4 works | |
| `bottom_bar.png` | `bottom_panel_1280x136.png` (+ `bottom_panel_9s_48`) | | 16 each side, TILE | (0,584) |
| `log_parchment.png` | `log_panel_732x108.png` (+ `log_panel_9s_12`) | | 4 each side | (526,598) |
| — (StatusLabel / ShieldLabel) | `status_*_12.png`, `twist_*_12.png` | 12×12 | – | See A3 |
| — (no keycaps wired) | **reuse** `final/kit/keycap_{1..6}_14x15.png` | 14×15 | – | Button-relative **(141,12)**, +2 y when pressed/toggled |

## A3. Status row: where it goes
- **The plates have no status row.** In PR #34, `StatusLabel` overlays the bars with the KO/Calmed word, and `ShieldLabel` "+N" sits to the right of the plate.
- **Proposal: a row under the plate.** Up to 3 icons at plate-relative **(2 + i·13, plate_h + 1)**: y+35 for party (24 px plates) and y+31 for beasts (20 px).
  - It doesn't collide with anything. The lowest row (y 536) ends at y 583, one pixel above the bottom panel at 584. A 3-icon row ends at plate x 40, which leaves ≥ 8 px before the middle-row sprites (checked in the preview).
  - Above the plate it would sit on the feet and shadow, so I didn't use that.
- **Order:** Poisoned, Shield, Braced, Rootbind, then twist-derived ones. Show 3 at most; the hover tooltip lists them all.
- **Twists that hit everyone** (Thicket = Slowed, Fog = Fogged, Ambush, Rich Hollow) are better shown **once as a twist chip** right of the depth plate at **(142, 20)** than on 12 plates. The preview shows a Thicket chip.
- **Shield:** keep the "+N" engine number next to it (cream + O outline, as now) or move it into the tooltip. The bar overlay `bar_shield_50x4` stays.
- **KO / Calmed icons are optional.** The current word-over-bars approach works. If Code prefers icons, put the icon first in the row and keep the bars hidden.

## A4. Level: badge vs plain text → **plain engine text (no badge shipped)**
- A 9×9 badge (11×11 with outline) eats 12 px of the 50 px name line: "Serpent" and "Snapper" collide.
- A badge can't hold 2 digits, and it adds a ninth shape to a 56 px plate.
- Test shown in `battle_icons_sheet_x3.png`.
- Keep the right-aligned `LevelLabel` (B2 `#5E3A22`, 10 px).
- Note: `battle_view.gd` `_level_text` returns "" today (fighters have no level yet), and "Snapper 12" is already tight with plain text.

## A5. Keycaps
- The kit's `keycap_{1..6}_14x15.png` fit the 160×44 button at **(141,12)**: inside the 4 px rim, clear of the label (label x 44, longest "Strike for me" ends ≈ x 128 at 14 px). The final preview uses them.
- **No new size needed.**
- `battle_view.gd` doesn't add keycaps yet, and it has no 1–6 hotkeys (only Esc). Code needs both: a TextureRect child at (141,12), +2 y on pressed/toggled, plus `KEY_1..KEY_6` handling.

## A6. Code changes for this batch
1. **Status row:** add a status HBox (separation 1) at plate-relative (2, plate_h+1) and fill it from `poison_left > 0`, `shield > 0`, `brace`, and the rootbind flag. Twist chip at (142,20) from `fight.twist`.
2. **Boss:** replace the BossLabel with `plate_beast_boss*` + `boss_crown_16` at (−15,2). Optional sigil under the shadow.
3. **Heavy:** swap `icon_heavy.png` for the new `intent_heavy_16.png`.
4. **Keycaps and hotkeys 1–6** (A5).
5. **Calmed/KO:** keep the words, or use the icons (A3).

## A7. Weak spots (this batch)
- **Rootbind:** a post bound by roots, the third attempt. It reads as "bound" but is the most abstract icon. It's echo-only, so it's less urgent.
- **Slowed snail and Fogged cloud:** these read best as twist chips. On a busy plate row they're small but legible.
- **Calmed leaf vs the green HP fill:** the same hue family. Fine at 1×, because the leaf has an outline and sits off the bar.
- **Boss crown:** bark brown with rust tips and a purple Withering bead. It's not gold (gold stays reserved), so it's quieter than a classic crown. The rust plate frame does most of the "boss" work.
- **Boss sigil:** uses the poison purple (no spare colour slots). It's ground-level and thin, but if Haex wants it to read as "Withering, not poison", it needs a palette swap, which would drop something else.
- **Boss size:** "bosses re-exported larger" (draft §11) is sprite work, not covered here.
