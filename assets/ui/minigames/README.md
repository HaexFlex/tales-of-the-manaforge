# minigames_pkg: minigames540 r6 art (packaged; implementation later)

These are copies of `ui_restyle/mockups/minigames540/r6_art/`, made by `build_minigames540_r6_art.py` (r2-r6 art passes, last pass r6 = Steady Press). The originals are untouched. The folders mirror `res://` (`assets/ui/minigames/`), and every PNG has a `.import` file with theme_pkg's import settings. Theme: hub v8c (bark, parchment, cyan only for magic, gold only for selected/perfect, amber for warnings).
- **Hard alpha:** in the source, `ov_start.png` and `ov_paused.png` had semi-transparent dim overlays. Here they are converted to a 4x4 ordered dither (hard 0/255): ov_paused.png, ov_start.png. Every other PNG was copied as is. If you want a smooth dim, use a ColorRect with modulate in place of these two.
- **Layout and positions:** `reference/layout.json` holds the window rect (132,44 696x472 at 960x540), the play area (160,114 640x320), close, pips, pace, tooltip, the hot-spot point lists, the dial centre and radius, the result card, the digit-font metrics, and per-sprite provenance (`SRC`). On 20:9, add +120 px in x.
- **Locked mockups / rules:** `ui_restyle/mockups/minigames540/minigames540_notes.md` (r2-r6 and the "Design answers" section: Steeping k 16 with cycle 8.0 s, With the Grain timing per shape, the Splitting Stone spot clamp). Prototypes: `proto_r5/` + r6 `minigames_all.html`.
- **Not 9-slices:** these are fixed-size sprites; the windows and buttons are already 9-sliced from theme_pkg (`frame_9s_96`, `wood_button_9s_*`). The baked `win_*_pc/_ph` frames are full-size window plates.
- `reference/*.jpg` are the mockups' world backdrops. **Do not ship them**; the game draws its own world.
- **Hot Spots plate (package addition):** `win_hot_spots_pc/_ph` replace the borrowed `win_forge_glow_*` for Hot Spots. Same frame, vines (seed `mg_forge_glow`), title plank (sized for "Hot Spots"), pace track and play-area bevel, pixel-identical to `win_forge_glow_*` minus all text. Made by `tools/make_win_hot_spots.py`; re-run it after `build_minigames_pkg.py`, which rebuilds from r6_art and does not know these files. Side-by-side: `preview/win_hot_spots_vs_forge_glow.png`.
- Preview: `preview/minigames_pkg_contact.png`. Builder: `tools/build_minigames_pkg.py`. Check: `preview/verify.txt`.

## Files (146 PNG + 4 reference)

### Ripe Catch (7)
| File | Size | Source / note |
|---|---|---|
| `assets/ui/minigames/basket.png` | 48x24 | drawn (r3: 46 px woven basket = catch width, held by the Keeper) |
| `assets/ui/minigames/berry.png` | 20x22 | drawn (round blue berry, leaf) |
| `assets/ui/minigames/berry_rotten.png` | 22x22 | drawn (spiky withered olive husk + fly: distinct shape) |
| `assets/ui/minigames/bg_grass.png` | 640x320 | real: tiles/grass_00..03 (64 px, random) |
| `assets/ui/minigames/canopy.png` | 640x70 | real: props/native/berry_harvest_node.png tiled (canopy edge) |
| `assets/ui/minigames/keeper_berries_e.png` | 768x136 | real: keeper/anim/harvest/berries/east frames [0, 1, 2, 3] |
| `assets/ui/minigames/node_berry.png` | 86x128 | real: props/native/berry_harvest_node.png |

### Splitting Stone (9)
| File | Size | Source / note |
|---|---|---|
| `assets/ui/minigames/keeper_pick_e.png` | 1728x136 | real: keeper/anim/harvest/pickaxe/east frames [0, 1, 2, 3, 4, 5, 6, 7, 8] |
| `assets/ui/minigames/keeper_pick_e2.png` | 3456x272 | real: keeper/anim/harvest/pickaxe/east frames [0, 1, 2, 3, 4, 5, 6, 7, 8] |
| `assets/ui/minigames/node_stone.png` | 184x192 | real: props/native/harvest_stone.png (x2 nearest) |
| `assets/ui/minigames/splat.png` | 28x12 | drawn |
| `assets/ui/minigames/spot_dim.png` | 80x80 | drawn (rune crack ring, 76 px tap area) |
| `assets/ui/minigames/spot_hit.png` | 80x80 | drawn (rune crack ring, 76 px tap area) |
| `assets/ui/minigames/spot_lit.png` | 80x80 | drawn (rune crack ring, 76 px tap area) |
| `assets/ui/minigames/spot_miss.png` | 80x80 | drawn (rune crack ring, 76 px tap area) |
| `assets/ui/minigames/spot_next.png` | 80x80 | drawn (rune crack ring, 76 px tap area) |

### Woodsong (10)
| File | Size | Source / note |
|---|---|---|
| `assets/ui/minigames/beat.png` | 20x20 | drawn (round leaf beat) |
| `assets/ui/minigames/beat_heavy.png` | 30x30 | drawn (gold diamond = heavy, every 8th) |
| `assets/ui/minigames/beat_notch.png` | 30x56 | drawn |
| `assets/ui/minigames/beat_rail.png` | 600x44 | drawn |
| `assets/ui/minigames/keeper_axe_e.png` | 1728x136 | real: keeper/anim/harvest/axe/east frames [0, 1, 2, 3, 4, 5, 6, 7, 8] |
| `assets/ui/minigames/node_tree.png` | 288x384 | real: nodes/harvest_tree.png |
| `assets/ui/minigames/tap_L.png` | 88x88 | kit WB 9-slice + drawn arrow |
| `assets/ui/minigames/tap_L_lit.png` | 88x88 | kit WB 9-slice + drawn arrow |
| `assets/ui/minigames/tap_R.png` | 88x88 | kit WB 9-slice + drawn arrow |
| `assets/ui/minigames/tap_R_lit.png` | 88x88 | kit WB 9-slice + drawn arrow |

### Just Enough (5)
| File | Size | Source / note |
|---|---|---|
| `assets/ui/minigames/gauge_just.png` | 62x240 | drawn (bark tube; r3 band + bracket drawn live) |
| `assets/ui/minigames/herbs_5.png` | 180x36 | drawn (5 herbs: Glowcap, Bitterroot, Mintleaf, Sunpetal, Moonmoss: distinct silhouettes) |
| `assets/ui/minigames/keeper_water_e.png` | 832x136 | real: keeper/anim/water/east frames [0, 1, 2, 3] |
| `assets/ui/minigames/node_sapling.png` | 256x384 | real: manatree/native/manatree_sapling.png |
| `assets/ui/minigames/pen.png` | 24x32 | drawn (carving pen, tip bottom-left) |

### Forge Glow (Hot Spots) (21)
| File | Size | Source / note |
|---|---|---|
| `assets/ui/minigames/bg_forge.png` | 640x320 | real: forge/forge_bark_chamber_bg.png crop (480,560)-(1120,880) 1:1 |
| `assets/ui/minigames/close_anvil.png` | 640x320 | Grok Imagine, palette-converted (r5_imagine) |
| `assets/ui/minigames/close_crucible.png` | 640x320 | Grok Imagine, palette-converted (r5_imagine) |
| `assets/ui/minigames/close_reliquary.png` | 640x320 | Grok Imagine, palette-converted (r5_imagine) |
| `assets/ui/minigames/heatbar.png` | 352x52 | drawn (ember gradient, sweet 0.55-0.75 gold bracket) |
| `assets/ui/minigames/hot_grey.png` | 56x56 | drawn (r3 Hot Spots glow, 56 px target) |
| `assets/ui/minigames/hot_orange.png` | 56x56 | drawn (r3 Hot Spots glow, 56 px target) |
| `assets/ui/minigames/hot_white.png` | 56x56 | drawn (r3 Hot Spots glow, 56 px target) |
| `assets/ui/minigames/hs_anvil.png` | 384x384 | real: forge/prop_anvil_busy.png (x2 nearest) |
| `assets/ui/minigames/hs_crucible.png` | 384x384 | real: forge/prop_crucible_busy.png (x2 nearest) |
| `assets/ui/minigames/hs_reliquary.png` | 384x384 | real: forge/prop_reliquary_busy.png (x2 nearest) |
| `assets/ui/minigames/sparks_4f.png` | 192x48 | drawn (r3 spark burst, 4 frames) |
| `assets/ui/minigames/st_crucible.png` | 192x192 | real: forge/prop_crucible_busy.png |
| `assets/ui/minigames/st_crucible_idle.png` | 192x192 | real: forge/prop_crucible_idle.png |
| `assets/ui/minigames/stbtn_anvil_n.png` | 112x44 |  |
| `assets/ui/minigames/stbtn_anvil_s.png` | 112x44 |  |
| `assets/ui/minigames/stbtn_crucible_n.png` | 112x44 |  |
| `assets/ui/minigames/stbtn_crucible_s.png` | 112x44 |  |
| `assets/ui/minigames/stbtn_reliquary_n.png` | 112x44 |  |
| `assets/ui/minigames/stbtn_reliquary_s.png` | 112x44 |  |
| `assets/ui/minigames/workpiece.png` | 424x272 | drawn (plank 424x272 trace panel) |

### Steady Press (15)
| File | Size | Source / note |
|---|---|---|
| `assets/ui/minigames/crank_8f.png` | 896x112 | drawn (8 frames = crank_frames) |
| `assets/ui/minigames/gauge_press.png` | 62x240 | drawn (bark tube, band 0.7-0.85 + gold bracket) |
| `assets/ui/minigames/ghost.png` | 18x18 | drawn (r3 target-pace ghost marker) |
| `assets/ui/minigames/needle.png` | 14x60 | drawn |
| `assets/ui/minigames/press_dial.png` | 124x150 | drawn (r4: pressure dial with mark band and vent zone; replaces the vertical tube) |
| `assets/ui/minigames/rim_amber.png` | 124x124 | drawn (r3 crank speed cue rim) |
| `assets/ui/minigames/rim_green.png` | 124x124 | drawn (r3 crank speed cue rim) |
| `assets/ui/minigames/st_mill.png` | 192x192 | real: forge/prop_mill_busy.png |
| `assets/ui/minigames/st_press.png` | 192x192 | real: forge/prop_press_busy.png |
| `assets/ui/minigames/stbtn_mill_n.png` | 112x44 |  |
| `assets/ui/minigames/stbtn_mill_s.png` | 112x44 |  |
| `assets/ui/minigames/stbtn_press_n.png` | 112x44 |  |
| `assets/ui/minigames/stbtn_press_s.png` | 112x44 |  |
| `assets/ui/minigames/vent.png` | 56x44 | drawn (amber when venting) |
| `assets/ui/minigames/vent_open.png` | 56x44 | drawn (amber when venting) |

### With the Grain (7)
| File | Size | Source / note |
|---|---|---|
| `assets/ui/minigames/dot_ink.png` | 4x4 | drawn |
| `assets/ui/minigames/dot_ink_ph.png` | 6x6 | drawn |
| `assets/ui/minigames/dot_path.png` | 8x8 | drawn |
| `assets/ui/minigames/dot_path_hit.png` | 8x8 | drawn |
| `assets/ui/minigames/dot_path_hit_ph.png` | 12x12 | drawn |
| `assets/ui/minigames/dot_path_ph.png` | 12x12 | drawn |
| `assets/ui/minigames/st_bench.png` | 192x192 | real: forge/bench_busy.png |

### Steeping (6)
| File | Size | Source / note |
|---|---|---|
| `assets/ui/minigames/bub_grey.png` | 56x56 | drawn (r4 melt bubble, 56 px) |
| `assets/ui/minigames/bub_orange.png` | 56x56 | drawn (r4 melt bubble, 56 px) |
| `assets/ui/minigames/bub_white.png` | 56x56 | drawn (r4 melt bubble, 56 px) |
| `assets/ui/minigames/card.png` | 460x308 |  |
| `assets/ui/minigames/order_bubble.png` | 372x64 | drawn (order speech plate) |
| `assets/ui/minigames/st_cauldron.png` | 128x120 | drawn (no brewing stand/cauldron sprite in repo) |

### Menu / window chrome (shared) (66)
| File | Size | Source / note |
|---|---|---|
| `assets/ui/minigames/btn_again_h.png` | 168x52 |  |
| `assets/ui/minigames/btn_again_n.png` | 168x52 |  |
| `assets/ui/minigames/btn_done_h.png` | 136x52 |  |
| `assets/ui/minigames/btn_done_n.png` | 136x52 |  |
| `assets/ui/minigames/btn_replay.png` | 44x44 | kit WB + drawn replay arrow (r3) |
| `assets/ui/minigames/btn_replay_off.png` | 44x44 |  |
| `assets/ui/minigames/close_h.png` | 44x44 |  |
| `assets/ui/minigames/close_n.png` | 44x44 |  |
| `assets/ui/minigames/font_digits.png` | 146x21 |  |
| `assets/ui/minigames/keeper_station_n.png` | 512x128 | real: keeper/anim/station/north frames [0, 1, 2, 3] |
| `assets/ui/minigames/keeper_station_n2.png` | 1024x256 | real: keeper/anim/station/north frames [0, 1, 2, 3] |
| `assets/ui/minigames/keeper_walk_e.png` | 1024x128 | real: keeper/anim/walk/east frames [0, 1, 2, 3, 4, 5, 6, 7] |
| `assets/ui/minigames/kit_fb_good.png` | 48x22 | kit: fb_good_48x22.png |
| `assets/ui/minigames/kit_fb_miss.png` | 44x22 | kit: fb_miss_44x22.png |
| `assets/ui/minigames/kit_fb_perfect.png` | 72x22 | kit: fb_perfect_72x22.png |
| `assets/ui/minigames/kit_good.png` | 96x24 | kit: fx_good_24x24_4f.png (4 frames) |
| `assets/ui/minigames/kit_pace_fill_gold.png` | 132x8 | kit: pace_fill_gold_132x8.png |
| `assets/ui/minigames/kit_pace_fill_good.png` | 132x8 | kit: pace_fill_good_132x8.png |
| `assets/ui/minigames/kit_perfect.png` | 128x32 | kit: fx_perfect_32x32_4f.png (4 frames) |
| `assets/ui/minigames/menu_forge_glow.png` | 320x52 |  |
| `assets/ui/minigames/menu_just_enough.png` | 320x52 |  |
| `assets/ui/minigames/menu_ripe_catch.png` | 320x52 |  |
| `assets/ui/minigames/menu_splitting_stone.png` | 320x52 |  |
| `assets/ui/minigames/menu_steady_press.png` | 320x52 |  |
| `assets/ui/minigames/menu_steeping.png` | 320x52 |  |
| `assets/ui/minigames/menu_tag.png` | 320x22 |  |
| `assets/ui/minigames/menu_with_the_grain.png` | 320x52 |  |
| `assets/ui/minigames/menu_woodsong.png` | 320x52 |  |
| `assets/ui/minigames/ov_paused.png` | 640x320 |  |
| `assets/ui/minigames/ov_start.png` | 640x320 |  |
| `assets/ui/minigames/pip_empty.png` | 12x12 | drawn: hollow ring |
| `assets/ui/minigames/pip_good.png` | 12x12 | drawn: green dot |
| `assets/ui/minigames/pip_miss.png` | 12x12 | drawn: grey cross |
| `assets/ui/minigames/pip_perfect.png` | 12x12 | drawn: gold star |
| `assets/ui/minigames/ring_again.png` | 188x72 |  |
| `assets/ui/minigames/ring_done.png` | 156x72 |  |
| `assets/ui/minigames/rotate_hint.png` | 360x300 |  |
| `assets/ui/minigames/slot_bad.png` | 72x72 | drawn (72x72 herb slot) |
| `assets/ui/minigames/slot_h.png` | 72x72 | drawn (72x72 herb slot) |
| `assets/ui/minigames/slot_n.png` | 72x72 | drawn (72x72 herb slot) |
| `assets/ui/minigames/slot_ok.png` | 72x72 | drawn (72x72 herb slot) |
| `assets/ui/minigames/start_ring.png` | 44x44 | drawn |
| `assets/ui/minigames/tooltip_stop.png` | 64x60 |  |
| `assets/ui/minigames/tune_alt96.png` | 140x44 |  |
| `assets/ui/minigames/tune_off.png` | 140x44 |  |
| `assets/ui/minigames/vol_fill.png` | 156x14 | theme slider (options540: slider_track/fill/grabber) on a kit WB plate |
| `assets/ui/minigames/vol_grab.png` | 24x24 | theme slider (options540: slider_track/fill/grabber) on a kit WB plate |
| `assets/ui/minigames/vol_plate.png` | 196x44 | theme slider (options540: slider_track/fill/grabber) on a kit WB plate |
| `assets/ui/minigames/win_forge_glow_pc.png` | 960x540 |  |
| `assets/ui/minigames/win_forge_glow_ph.png` | 960x540 |  |
| `assets/ui/minigames/win_hot_spots_pc.png` | 960x540 | Hot Spots plate, text-free (title plank, labels, flavour and hint drawn live; flavour from Lore) |
| `assets/ui/minigames/win_hot_spots_ph.png` | 960x540 | same as _pc (pc/ph differ only in baked hint text, none here) |
| `assets/ui/minigames/win_just_enough_pc.png` | 960x540 |  |
| `assets/ui/minigames/win_just_enough_ph.png` | 960x540 |  |
| `assets/ui/minigames/win_ripe_catch_pc.png` | 960x540 |  |
| `assets/ui/minigames/win_ripe_catch_ph.png` | 960x540 |  |
| `assets/ui/minigames/win_splitting_stone_pc.png` | 960x540 |  |
| `assets/ui/minigames/win_splitting_stone_ph.png` | 960x540 |  |
| `assets/ui/minigames/win_steady_press_pc.png` | 960x540 |  |
| `assets/ui/minigames/win_steady_press_ph.png` | 960x540 |  |
| `assets/ui/minigames/win_steeping_pc.png` | 960x540 |  |
| `assets/ui/minigames/win_steeping_ph.png` | 960x540 |  |
| `assets/ui/minigames/win_with_the_grain_pc.png` | 960x540 |  |
| `assets/ui/minigames/win_with_the_grain_ph.png` | 960x540 |  |
| `assets/ui/minigames/win_woodsong_pc.png` | 960x540 |  |
| `assets/ui/minigames/win_woodsong_ph.png` | 960x540 |  |

### Layout data (1)
| File | Size | Source / note |
|---|---|---|
| `reference/layout.json` | - | positions, hot-spot points, dial, card, font metrics, provenance (SRC) |

### Reference (not shipped) (3)
| File | Size | Source / note |
|---|---|---|
| `reference/world_pc.jpg` | 960x540 | mockup world screenshot |
| `reference/world_ph.jpg` | 960x540 | mockup world screenshot |
| `reference/world_ph20.jpg` | 1200x540 | mockup world screenshot |
