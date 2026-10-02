# Keeper walk v1 (Option A look): S / N / E / W, 8 frames x 100 ms, looping

Not wired into the game. Built from three Grok Imagine walk rows on magenta (`source/`):
- `keeper_walk_front_8.png` (8 figures)
- `keeper_walk_back.png` (8)
- `keeper_walk_right.png` (8)

The front sheet was cropped to 8 figures by the downloader. There is no partial 9th figure at the edge.

Timing: 100 ms per frame, which is the live `WALK_SOUTH_HOLD_MS`. 8 frames = one 800 ms cycle of two steps.

## Pipeline (tools/)
1. `ingest_walk.py`
   - Keys the sampled corner magenta (soft key plus despill).
   - Splits the figures left to right.
2. `frames_walk.py`
   - **Scale:** ONE scale per sheet, calibrated to the matching Option A still. The three sheets are drawn at different pixel sizes, so a single number can't fit all three.
     - Front: median frame height = still S, 119 px (0.3020).
     - Back: median frame height = still N, 120 px (0.2472).
     - Side: hair-top to coat-hem distance = still E (0.2779). This measure ignores the legs, because the side sheet has no upright frame.
   - **Resample:** premultiplied LANCZOS, then hard alpha.
   - **Clean-up:** `defringe`, then Option A's 48-colour palette (`palette.json`, identical to `v3_stills_8dir/option_a`).
   - **Placement:** lowest sole pixel on row 123. Horizontal anchor = head and torso centroid (top half of the figure), fixed per sheet and offset so the loop's mean feet centre is 63.5.
3. `assemble_walk.py`: leg-phase analysis and loop assembly (below).
4. `export_walk.py`: frames, strips, GIFs and contact sheet.
5. `check_frames.py <dir> "walk_*/walk_*.json"`

## Leg-phase findings and loops
Leg differences were measured on the bottom 32 rows (silhouette XOR plus strong colour changes), with per-foot lowest row and width (`source/phase_*.json`).

### FRONT
- Frames 02, 05 and 07 are the only step poses. In all three the screen-left foot is lifted or trailing, by 1, 3 and 2 px. Frames 00, 01, 03, 04 and 06 are near-identical both-feet-down poses.
- **The other foot never steps.** Frames 00 and 01 are also drawn 2 px taller than the rest (height noise), so I didn't use them.
- **Loop:** `04, 02, 05*, 07, 06, 02m, 05m*, 07m`
  - `m` = legs below the coat hem (row >= 105) mirrored about the feet centre, which creates the missing second step.
  - `*` = passing pose, body raised 1 px (rows above the boot shafts, one row stretched at row 110).

### BACK
- Frames 00 and 01 are the only lift poses (screen-left foot lifted 3 and 2 px). Frames 02-07 are both feet down.
- **Loop:** `04, 01, 00*, 01, 07, 01m, 00m*, 01m`. Legs are mirrored from row 97 and the body cut is at row 102.

### SIDE (E)
- **All 8 source frames are the same mid-stride pose.** The back foot is always on the left and the front foot on the right, with a feet span of 33-93 px in every frame. There is no contact/passing alternation and no leg swap.
- A real walk cannot be assembled from this sheet. I tried compositing passing legs from the E still: its coat is closed and long, while the walk figure's coat is open with the tunic showing, so the seam does not work.
- **Loop:** all 8 frames, ordered for minimum frame-to-frame change: `00, 01, 02, 04, 06, 05, 07, 03`. Treat this as a placeholder; it SLIDES. **Regenerate the side sheet** with explicit contact / down / passing / up poses for both legs.
- W = E mirrored (x -> 127 - x).

### Upper-body lock (S/N)
- Every Imagine frame is a fresh redraw, so the hair, face and coat "boil": about 800-1300 changed px per frame in rows 0-85.
- For S and N, everything above the leg-mirror row comes from ONE reference frame (04 in both). Only the legs, plus the deliberate 1 px bob, change. The source walks barely swing the arms in front and back, so little is lost.
- `previews/raw_vs_locked_SN_x2.gif` shows the difference.
- E/W are left raw, so they still boil, because the sheet must be regenerated anyway.

## Checks
32/32 frames pass (`alpha_check.md`):
- RGBA 128x128, border clear.
- 0 semi-transparent px, 0 RGB under alpha 0.
- 0 magenta, 0 tint, 0 fringe, 0 non-palette colours.
- Soles on row 123, feet centre within 2 px of 63.5.
- Heights: S 119-120, N 120-121, E/W 117-118.

## Verdict
- **S:** loops cleanly and is stable (no drift, no boil), with a 1 px bob. The step is small, because the front sheet only moves the feet a little, so it reads as a gentle march more than a stride. The loop is OK for a first look.
- **N:** same as S. The step is clearer than S because the lifted heel shows. However, the back sheet's proportions differ from still N: the head is smaller, the coat shorter and the body narrower.
- **E/W:** does not walk. It is one frozen stride that slides, with redraw boil. Needs regeneration.
- **12 frames:** wouldn't help with these sheets. They don't contain more distinct poses, so the extra frames would only be repeats. Better sheets first.
