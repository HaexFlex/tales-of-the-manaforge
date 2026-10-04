# Playtest batch v1 (2026-10-03): art wiring notes

Branch `art/playtest-batch-1004` (off `38816ac`). **Everything here is a new file.** Nothing existing was changed or replaced, so there is no legacy folder.
All runtime art is native size at scale 1, hard alpha (0/255), transparent RGB = 0, with no magenta or pink fringe. Every texture loads in a headless Godot load check.
`.import` files use the project's 4.7 `[params]` block (no mipmaps, lossless, `fix_alpha_border`). Use nearest filtering.
Contact sheet: `assets/library/playtest_batch_v1/playtest_batch_contact.png` (green backdrop).
Update 2026-10-03 23:2x: portal v2 and `battle_elaia_key_w` added from the Imagine results. Raw outputs are in `imagine/out/`, snapped and candidate images in `source/`, and the scripts are `tools/portal_v2.py` and `tools/elaia_w_key.py`.
Tools: `assets/library/playtest_batch_v1/tools/`. Manatree diff report: `reports/glow_only_report.json`.
Code may rename the files. These are proposed names.

## 1) Echo portal: `assets/art/props/echo_portal_hub_v2.png` (DONE, from Imagine `portal_v1_a`)
- **Size:** 160x200 canvas; visible bbox x 0..159, y 5..199, so **160x195**. Hard alpha, 28 colours.
- **Anchor:** bottom-centre, at canvas (80,200). The base touches the bottom row.
- **How it was made:** Imagine drew on a clean grid of about 17.0 x 17.2 px cells, which is only **64x78 real pixels**, the same detail level as the old portal.
  - Straight downscaling to 160 wide (or nearest-upscaling the snapped grid) gives uneven 2/3-px doubled blocks. Candidates A, B and D are in `source/`.
  - So the final build snaps to Imagine's native grid (`source/portal_v1a_native.png`, 64x78) and resamples smoothly to 158x193. It is then re-quantised to 32 colours (28 used) with sharpen 0.5 and given a 1 px dark outer outline. Result: crisp 1-px pixels with no doubling, a little softer and more painterly than hand-pixelled art.
  - Stone greys were snapped to the current portal's 11-grey stone palette (#37393e … #9a9893). Runes and vortex are Imagine's teal and blue.
- **Old portal** `echo_portal_hub.png` is untouched (784x1168, about 64x95 real pixels).
- **Code wiring** in `scripts/echo_portal.gd` / `scenes/echo_portal.tscn`:
  - Set `PORTAL_ART` to v2.
  - Draw at scale 1 with `centered=false` and offset (-80,-200), or set `PORTAL_BOX=200`, which with `_fit_marker` gives a fit of 1.0.
  - CollisionShape2D: now 96x96 at (0,-48). Suggest 160x200 at (0,-100), or a base-only hitbox around 120x48 at (0,-24).
  - Label: offset_top -124, move to about -228.
- Prompt and refs used: `imagine/portal_prompt.md`, `imagine/portal_ref_*.png`. Raw output: `imagine/out/portal_v1_a.png`.

## 2) Echo battle sprites (`assets/art/echo/`)
| file | size | content | anchor |
|---|---|---|---|
| `battle_keeper_idle_s.png` | 128x128 | Keeper Option A still, front | feet centre x≈64, sole row y=123 |
| `battle_keeper_idle_e.png` | 128x128 | Keeper Option A still, **facing right** (toward the enemy) | same |
| `battle_elaia_idle_s.png` | 128x128 | Elaia companion v1 still, front | same |
| `battle_elaia_idle_w.png` | 128x128 | Elaia v1 still, **facing left** (toward the Keeper) | same |
| `battle_elaia_key_s.png` | 128x128 | Elaia front **holding the golden key**, remapped to her companion palette (key golds kept) | same, feet x≈66 |
| `battle_elaia_key_w.png` | 128x128 | Elaia **facing left holding the golden key** (from Imagine `elaia_w_key_v1_a`) | bbox 36,9–82,123 (115 tall, same as idle W), feet x≈64, sole y=123 |

- These are drop-ins for `KEEPER_IDLE` and `ELAIA_FRONT` in `echo_battle_view.gd`. A 128 canvas scales exactly 3x into the 384 portrait rects (stretch_mode keep-aspect-centred, nearest).
- Suggested pairing: `battle_keeper_idle_e` on the left vs `battle_elaia_idle_w` on the right for side-on stances. If the key matters in the fight, use `battle_elaia_key_w` (side-on) or `battle_elaia_key_s` (front).
- How `battle_elaia_key_w` was built: Imagine's output snapped to its about 10.7 px grid gives 47x115 native, already the idle-W height. Aligned to `battle_elaia_idle_w` by silhouette, its body matched that sprite pixel for pixel outside the arm.
  - So everything is **locked to `battle_elaia_idle_w`** (face, hair, robe and boots are identical) except the forward hand and forearm and the key. That is 715 px, taken from Imagine.
  - The hand and sleeve were remapped to Elaia's 40-colour companion palette. The key golds were remapped to the 12 gold colours used by `battle_elaia_key_s`, so both key sprites share one gold set. 49 colours total.
- The old `elaia_front.png` is RGB with a black background. These are true RGBA.
- **Code:** `verify_headless.gd` checks the path substrings `keeper_idle_south` and `elaia_front`. Update those checks when the constants change.

## 3) HUD scene icons (`assets/art/ui/icons/`)
- `hud_scene_clearing.png` (32x32): Manatree (mature) on a grass mound.
- `hud_scene_forge.png` (32x32): anvil (from `prop_anvil_idle`) with a spark.
- Both use the HUD recipe (about 20 colours, dark outer outline) and are centred. They drop in like the other `hud_*` icons (32x32 icon at 4,4 in a 40x40 button).

## 4) Game speed (`assets/art/ui/buttons/`, `assets/art/ui/glyphs/`)
- `speed_play_{normal,hover,pressed}.png` (32x32): the pause button frame with a white play triangle replacing the bars. Same frame and colours per state as `pause_*`.
- Baked labels, `speed_{1x,2x,4x,8x,16x}_{normal,hover,pressed}.png` (32x32, 15 files): a small play mark plus a 3x5-digit "Nx" label. On pressed, the content sits 1 px lower, like the pause bars.
- Composable glyphs, `glyph_0..9.png` and `glyph_x.png` (5x7 each): a white 3x5 glyph with a 1 px dark (#010a01) outline. Advance 4 px if you overlap the outlines, 6 px if not. Use them on top of `speed_play_*` or anywhere.

## 5) Manatree: what moves, plus the glow-only version
**What the current strips do** (all 5 stages, 8 frames @ 7 fps):
1. **Crown sway (shear).** Each row above about 35–40% of the frame height shifts horizontally, tapering to 0 lower down. The peak shift at the crown top is ±2 px (sapling), ±3 px (young) and ±4 px (mature/elder/ancient).
   - Sequence f0..f7: 0, +1, +2, +1, 0, −1, −2, −1 steps (to the right, back, to the left).
   - This changes the silhouette: about 150–220 px on the sapling and up to 16.5k px per frame on the ancient.
   - Trunk, roots and door never move.
2. **Vein glow pulse.** The teal vein, door and rune pixels step through brighter palette colours, dim at f0 and peaking at f4.
   - Mean brightness of the glow pixels, young stage: 83 → 85 → 93 → 100 → 103 → 100 → 93 → 85.
   - Glow pixel counts: sapling 56, young 810, mature 13k, elder 33k, ancient 47k.

**Glow-only strips** (`assets/art/manatree/native/anim/glow/manatree_<stage>_strip_glow.png`):
- Same canvas, frame size, 8 frames, 7 fps and door anchor as the originals.
- Frame 0's silhouette and colours are held static. The silhouette is verified identical in every frame, and no new colours were added.
- Only the glow pixels pulse, with the exact colours from each original frame (crown shear undone per row before copying).
- A few hundred non-glow pixels per stage that differed only because of the sway (leaf edges) were dropped on purpose.

| stage | strip | frame |
|---|---|---|
| sapling | 1024x128 | 128x128 |
| young | 2304x288 | 288x288 |
| mature | 5888x736 | 736x736 |
| elder | 8192x1024 | 1024x1024 |
| ancient | 8192x1024 | 1024x1024 |

- **Wiring:** `assets/art/manatree/native/manatree_meta_glow.json` is a copy of `manatree_meta.json` whose `file` entries point at the glow strips. Either point `META_PATH` (`manatree.gd`) at it, or copy the `file` values into the main meta.
  - `verify_headless` / `pass_f_playthrough` read the main meta, so swapping the contents of the main meta is the least-code option.
  - The original strips stay untouched for A/B.

**Vein particle** (`assets/art/fx/`):
- `fx_vein_mote_strip.png`: 15x5, 3 frames of 5x5. f0 is a 5-px diamond, f1 a 3-px plus, f2 a single px. Uses the Manatree glow palette #6dedd7 / #3de7ca / #2ecfae / #16caa4.
- `fx_vein_mote.png`: 5x5, the single big mote.
- Hard alpha, so the "fade" is the shrink across frames.

Suggested `CPUParticles2D` (child of the Manatree, origin = door sill = node origin, frame px at display_scale 1):
```
texture = fx_vein_mote_strip.png ; texture_filter = NEAREST
material = CanvasItemMaterial { particles_animation = true, particles_anim_h_frames = 3, particles_anim_v_frames = 1, particles_anim_loop = false }
anim_speed_min = anim_speed_max = 1.0      # f0 -> f2 across the lifetime = shrink out
amount: sapling 3 | young 5 | mature 8 | elder 12 | ancient 14
lifetime = 1.8 ; randomness = 0.3 ; explosiveness = 0 ; local_coords = true
emission_shape = RECTANGLE
  sapling  position (0,-45)   extents (10,30)
  young    position (8,-110)  extents (12,90)
  mature   position (0,-250)  extents (120,230)
  elder    position (0,-440)  extents (200,400)
  ancient  position (0,-450)  extents (200,410)
direction = (0,-1) ; spread = 20 ; gravity = (0,-4) ; initial_velocity 6..14
scale_amount_min = scale_amount_max = 1    # keep pixels crisp; no color_ramp alpha (hard-alpha look)
z_index = +1 over the tree sprite
```
The glow bboxes these come from, relative to the door sill:
- sapling x −25..16, y −76..−15
- young x −10..29, y −205..−14
- mature x ±215, y −498..18
- elder x ±375, y −862..−21
- ancient x ±373, y −885..−18

## Sources
- Keeper: `keeper_idle_4dir/v3_stills_8dir/option_a` (experiments branch).
- Elaia: companion v1 stills, plus the box-only key sprite `elaia_anims/work/elaia_s_key_128.png` (from `elaia_front.png`).
- Icons and buttons: built from the existing `pause_*`, `prop_anvil_idle` and the mature Manatree strip.
- Scripts in `tools/`:
  - `portal_v2.py`
  - `elaia_w_key.py`
  - `battle_sprites.py`
  - `hud_scene_icons.py`
  - `speed_buttons.py`
  - `manatree_glow_only.py`
  - `vein_mote.py`
  - `contact_sheet.py`
