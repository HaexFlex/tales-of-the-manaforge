# Elaia (companion) v1 stills: S / N / E / W, key-free (experiment, not wired)

Status (2026-10-03 14:01 CEST): first key-free direction stills for the Elaia companion set. These are the base for the
walk, harvest and station clips. When she joins as a companion she no longer carries the golden key, so all art here has
empty hands.

## Source
- `source/elaia_turnaround_{1,2,3}.jpg`: Grok Imagine turnaround sheets, 1792x1008 JPEG, flat magenta.
  - Made from the key-free front reference (the existing `assets/art/echo/elaia_front.png` with the key removed and the right
    arm mirrored down).
  - Each sheet holds FRONT, BACK and two LEFT-facing profiles. Imagine did not flip the 4th view.
- **Used: sheet 1** (primary). Its front is closest to the original art, and it showed no defects worth swapping for.
  - Sheets 2 and 3 are ingested the same way for comparison in `source/sheets_1-3_ingested_raw_x3.png` (very similar; kept as
    alternates).
- **Profile: L1** (3rd figure). L1 and L2 are near-identical (same height and pixel count; edge-noise metrics equal).
  - L1 has the smoother back-of-hair silhouette (L2 has a few stray strand pixels at the back) and a cleaner face profile.
- **W = L1 as-is. E = horizontal mirror of L1** (x -> 127 - x).

## Ingest (the Keeper way; `tools/ingest_elaia.py`, `tools/build_stills.py`)
- **Key and split:** `ingest_turnaround.key`: corner-sampled background (255,0,249), soft key 70..130 plus magenta despill.
  The sheet is then split into 4 figures.
- **Scale:** one shared scale from the front view, 116 px / 802 src px = 0.1446. The other views come out at their natural
  height: N, W and E are 115 (the sheet draws them 5 src px shorter).
- **Downscale:** premultiplied LANCZOS to 2x, then NN x0.5, hard alpha.
- **Placement:** 128x128 canvas, sole on row 123, feet centred at x 63.5-64.
- **JPEG fringe:** pixels with violet/magenta hue (232-345 deg, sat > .10) are recoloured from the median of their non-tinted
  neighbours, at their own lightness.
  - Elaia's design has no purple. Her bluest colours sit at about 226 deg, so the band starts above blue-ringing hues.
  - Pixels recoloured: S 98, N 91, W 85.
- **Palette:** one Elaia palette, 40 colours (`palette.json` / `palette.png`): k-means in Lab over S+N+W, then median colours.
  All four stills use only these colours. Despeck found nothing to remove.
- **Imagine refs:** `refs/ref_{s,n,e}_x5_magenta.png` are the stills at x5 nearest on flat magenta, 1168x784 (Keeper ref
  layout: 640x640 block centred).

## Checks (`tools/check_frames_elaia.py`)
- This is the Keeper `check_frames.py`, with one change: the height window is 112-126 instead of the Keeper's 116-126.
- Result: ALL PASS 4/4.
- Covered: RGBA 128x128, clear border, zero-RGB under alpha 0, 0 semi-alpha, 0 magenta/purple edge, 0 light fringe,
  0 off-palette, sole row 123, feet within 2 px of 63.5.

| still | height | feet x | x span |
|---|---|---|---|
| S | 116 | 63.0 | 42-84 |
| N | 115 | 63.5 | 42-85 |
| E | 115 | 63.5 | 45-77 |
| W | 115 | 63.5 | 50-82 |

## E-mirror notes
- **Lighting flips:** the sheet is lit from the top-left. On W (facing left) the highlights fall on her front and face side;
  on the mirrored E they fall on the right. E is therefore lit from the top-right, the opposite of S and N.
  - Slight at 1x. The same applies to every mirrored Keeper side clip.
- **Same side twice:** a left-facing profile shows her LEFT side, so E shows that same side again.
  - Robe closure: not visible as an issue. The robe is open down the centre with two symmetric gold front trims in S, and in
    profile only the front edge trim shows, which mirrors correctly.
  - Belt buckle: centred, shows at the front on both.
  - Hair: no visible part or ear tuck in the profile, so nothing reads as flipped.
- **Outline (all views):** the sheet's outline is soft and light. Against bright backgrounds the stills read lighter-edged
  than the Keeper's dark-outlined Option A. A dark 1-px outline pass is possible later if Haex wants them closer.
- **Scale vs Keeper:** Elaia (116) next to Keeper Option A S (119) is in the contact sheet. She is slimmer and slightly
  shorter, as intended.

## Files
- `elaia_still_{s,n,e,w}.png`
- `elaia_still_4dir.json`: meta, ingest log, per-still measurements.
- `palette.json`, `palette.png`
- `alpha_check.{json,md}`
- `elaia_stills_contact_x3.png`: S N E W on green, plus Keeper S for scale; yellow line = sole row 123.
- `refs/`, `source/`, `tools/`
  - `tools/make_sprite.py` provides `ref_x5`.
  - `tools/ingest_turnaround.py` and `tools/build_idles.py` are copied dependencies.
