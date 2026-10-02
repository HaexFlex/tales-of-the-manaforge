# Keeper v3: 8-direction STILLS (no animation)

Haex's feedback on v2: the front hair is fine, but the back and side hair look awful. New direction: still images only, all 8 directions, for consistency. The hair must be spiky all the way down the back of the head.
Source: Grok Imagine 8-view sheets (2 rows of 4 on magenta, 1712x1152), generated with the v2 front (live hair) as reference. Both are in `source/`.
- **Option A**: `yylTR.png`. Longer hair, a spiky mane down the back; medium glyph.
- **Option B**: `pyvqF.png`. Spikier, more compact hair, closer to the front ref; small glyph.

Not wired into the game. v1/ and v2/ are untouched.

## Direction mapping (judged on screen; E = facing screen-right)
The requested layout was: top row = S, SE, E, NE; bottom row = N, NW, W, SW.

| dir | Option A source | Option B source |
|---|---|---|
| S  | row1 col1 | row1 col1 |
| SE | row1 col2 | row1 col2 |
| E  | row1 col3 | row1 col3 |
| NE | **mirror of row1 col4** (see below) | **mirror of row2 col2 (NW)** |
| N  | row2 col1 | row2 col1 |
| NW | **row1 col4** | row2 col2 |
| W  | row2 col3 | row2 col3 |
| SW | row2 col4 | row2 col4 |

- **A, row1 col4** was meant to be back-right 3/4, but it actually faces up-LEFT: the cheek and ear show on the left of the head and the back glyph is shifted right. So it is an NW view, and a clearer 3/4 turn than A's own row2 col2. Row2 col2 is also NW, but only about 20° off N.
  - I used row1 col4 as NW, because its turn matches the strength of SE/SW. NE is its mirror.
  - A's row2 col2 is unused.
- **B, row1 col4** (meant as NE) is essentially a second straight back view, a duplicate of N: glyph centred, no cheek visible. It is unused. NE = mirror of B's NW (row2 col2).
- Mirroring is x -> 127-x. The back views carry no asymmetric details, so the mirrored NE reads correctly: cheek on the right, facing up-right.

## Method (tools/)
1. `ingest8.py`:
   - Key out the sampled corner magenta (255,0,255): soft key plus despill.
   - Split the 8 figures (rows by y, then x).
   - Apply **ONE shared scale per option**: S is set to 122 px, capped so the tallest view still fits rows 1..123 (border clear).
   - Resample with premultiplied LANCZOS, then hard alpha. Soles on row 123, feet centred at x 64.
   - The bottom-row figures are drawn ~2-3% taller in the Imagine sheets, so the cap kicks in:
     - A: scale 0.2510, S = 119 px (heights 118-123).
     - B: scale 0.2515, S = 121 px (heights 121-123).
   - Per-view height normalisation would equalise them. I did not do it, because a single shared scale was requested.
2. `build_stills.py`:
   - `defringe` (purple-tinted key contamination recoloured from neighbours). Pixels recoloured per view: A 76-136, B 129-159. Most are the dark maroon outline next to the key.
   - Mirror where needed.
   - **One 48-colour material-aware palette per option** (Lab k-means per material group).
   - Nearest-Lab apply.
3. `tools/check_frames.py <dir> "keeper_still_*.json"`: same checks as v1/v2, plus an optional meta-glob argument.

## Checks
Both options pass 8/8 (`option_*/alpha_check.md`):
- RGBA 128x128, border clear.
- 0 RGB under alpha 0, 0 semi-transparent px.
- 0 magenta (edge or anywhere), 0 purple tint on edge, 0 light fringe.
- 0 non-palette colours.
- Sole row 123 on all, feet x 63.0-64.0.
- Heights: A 118-123, B 121-123.

## Files per option
- `keeper_still_<s|se|e|ne|n|nw|w|sw>.png`
- `palette.json` / `palette.png`
- `keeper_still_8dir.json` (mapping, extents, defringe counts)
- `ingest.json`
- `alpha_check.*`
- `previews/`:
  - `contact_row_x1.png` / `contact_row_x3.png`: S, SE, E, NE, N, NW, W, SW, plus the live idle_south and v2 S at the same scale.
  - `compass_x3.png`: live S in the centre.
  - `turnaround_x2.gif`: 250 ms per direction.

`A_vs_B_x3.png` holds both rows.

## Pick: **B**
- **Hair vs front:** B's compact, spiky silhouette is much closer to the live/v2 front. A's longer mane reads as long hair or a mullet in E/W/SE/SW.
- **Back:** B is spiky all the way down to the collar, which is what was asked for. A is spikier further down, but at the cost of length.
- **Glyph:** B's glyph is small and sits on the cape yoke, in line with v2's shrunk rune.
- **Scale:** B is more uniform (121-123 vs 118-123).
- **Caveat:** neither S is the live sprite. Its open coat and hair colours differ slightly. Adopting the set would mean replacing the live S with the sheet's S, for consistency.
