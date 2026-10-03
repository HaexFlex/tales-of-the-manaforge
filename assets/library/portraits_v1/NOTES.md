# Party + sheet portraits v1 (Keeper Option A, Elaia key-free)

Art drop only: nothing in this commit is wired yet. `assets/art/portraits/` has the 4 game PNGs. There are no `.import`
files yet; Godot writes them on the next editor open or `godot --headless --import`.

| file | size | use |
|---|---|---|
| `assets/art/portraits/keeper_portrait.png` | 52x52 | HUD party bar (TextureRect 52x52 at (2,2) in a 56 slot, so it draws 1:1) |
| `assets/art/portraits/elaia_portrait.png` | 52x52 | HUD party bar |
| `assets/art/portraits/keeper_portrait_sheet.png` | 160x160 | character sheet `SPRITE_SIZE` 480x480 at exactly 3x |
| `assets/art/portraits/elaia_portrait_sheet.png` | 160x160 | character sheet at 3x |

## Sources
- Keeper: `source/portrait_keeper_1.jpg` (Haex's pick: coat collar spread with gold trim, closest to the sprite).
- Elaia: `source/portrait_elaia_1.jpg` (Haex's pick).
- Both are 1408x1408 Grok Imagine JPGs on flat magenta. Candidates 2 and 3 were not needed because neither pick had a defect.

## Framing (identical for both, from `tools/build.py`)
- The eye line (midpoint of the two eye centres) sits on row 24 of 52, centred at x 26.
- Eye to chin is 12 px, so the chin lands on rows 36-38: Keeper 36-37, Elaia about 38 (her face is longer).
- The shoulders are cut at the bottom edge.
- Source scale: Keeper 0.0571 (eye 735,620; chin 830), Elaia 0.0600 (eye 653,590; chin 790).
- The 160 versions use the same framing x160/52: eye row 73.8, eye to chin 36.9 px.
- **Deviation from the target spec:** with the eye at 24 and the chin at 36, the hair can't be 32-38 px wide.
  - Keeper's mane fills the full 52 px width, and about 8 px of spikes are cropped at the top.
  - Elaia's hair spans x 3..51 and touches the top edge.
  - Getting the hair down to about 36 px would need a chin near row 31, with 2-3 px eyes. I chose face readability over hair width.

## Treatment
1. Key: a pixel is background if min(R,B) - G > 100. Colour comes only from pixels 3 px inside the silhouette with
   min(R,B) - G <= 30, so no JPG magenta fringe can reach a colour.
2. Downscale: each target pixel takes the per-channel median of its source cell (about 17.5 src px at 52, about 5.7 at 160).
   The cell is opaque if its body coverage is at least 50%, so alpha is hard.
3. Quantise in CIELAB to the character palette.
   - **Keeper:** Option A 48 (`keeper_idle_4dir/v3_stills_8dir/option_a/palette.json`). The 52 uses 42 colours, the 160 uses 45.
   - **Elaia:** her 40-colour palette (`elaia_anims/stills/palette.json`). Both sizes use all 40.
   - **No colours were added for either character.**
4. Clean-up:
   - Islands under 4 px are removed and enclosed holes of 2 px or less are filled.
   - Lone-pixel despeckle (pixels with no same-colour 4-neighbour, inside an 8-neighbourhood that is at least 5/8 one colour), with the eyes protected.
5. Outline: 1 px outline in the transparent pixels that are 4-adjacent to the body. Each outline pixel is the darkest palette
   colour (L* <= 32) closest in hue to the body next to it:
   - Keeper: deep greens and navies, plus brown at the skin.
   - Elaia: navy (34,72,112) on hair and robe, dark browns at the skin.
6. Hand touch-ups at 52 px only (listed in `TOUCH` in build.py):
   - Elaia: iris rebuilt per eye (dark top, white highlight, lighter blue bottom), plus a 1 px nose hint and a 3 px mouth.
   - Keeper: a 1 px nose shadow.
   - The 160 versions needed no touch-ups.

## Checks (`tools/check.py`, output in `check.txt`)
All 4 files pass:
- exact size, RGBA
- alpha only 0/255, transparent RGB = 0
- 0 magenta, 0 purple, 0 purple edge pixels
- 0 off-palette pixels

## Previews (`previews/`)
- `portraits_52_x4.png` and `portraits_160_x2.png`: Keeper | Elaia on a neutral dark background.
- `party_bar_mock_x1.png`, `party_bar_mock_x4.png` and `party_bar_mock_1x_and_x4.png`: hud.gd layout on a grass-like
  background.
  - Bar at (12,86), slots 56 with 6 px separation, order Wisps / Keeper / Elaia.
  - Portrait TextureRect 52 at (2,2), keep-aspect-centred, nearest.
  - The 2 px selected border (0.78,0.92,0.62) is on Keeper.

## Tool paths
The tools use absolute `/workspace/portraits` and palette paths from the art box. They are kept for the record.
