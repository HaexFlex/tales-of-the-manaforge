# Keeper walk v2 (Option A look): S / N / E / W, 8 frames x 100 ms, looping

Not wired into the game. Sources are in `source/`: Grok Imagine walk rows on magenta, JPEG converted to PNG.
- `keeper_walk2_front.png` (8)
- `keeper_walk2_back.png` (10 figures)
- `keeper_walk2_side_a.png` (8)
- `keeper_walk2_side_b.png` (8)

Each sheet was prompted with explicit contact / down / passing / up poses.

## Pipeline (tools/)
The pipeline is the same as walk_v1.
- **Key:** sampled corner magenta, with tolerance (70-130 distance ramp; strong-magenta pixels forced to background) and despill. Then the figures are split.
- **Speck cleanup (new for JPEG sources):** opaque islands under 4 px are removed after resampling.
- **Scale:** ONE scale per sheet, calibrated to the matching Option A still.
  - Front: median height = S, 119 px (0.2565).
  - Back: median height = N, 120 px (0.2691).
  - Side: hair-top to coat-hem distance = E (a 0.2953, b 0.2931).
- **Clean-up:** premultiplied LANCZOS, hard alpha, defringe, then Option A's 48-colour palette (`palette.json`).
- **Placement:** soles on row 123. Horizontal anchor = head+torso centroid, so sideways jitter is 0: the head-x range across every loop is 0.01 px.

## Leg-phase findings (measured, `source/phase_*.json`)
Measures used: per-foot lowest row and boot pixel size (front/back), and feet span (side).

### FRONT
The feet really alternate now.
- Frames 03, 04 and 07: the right boot is smaller, i.e. the right foot is back (strongest is 07).
- Frames 05 and 06: the left foot is back (strongest is 06; 05 also lifts the left foot 1 px).
- Frames 00, 01 and 02: both boots are equal (passing).

The motion is still small (1-2 px of boot change), as in v1.

**Loop:** `02*, 04, 07, 03, 01*, 05, 06, 05`
- `*` = passing pose with a +1 px bob.
- The upper body is locked to frame 02 (rows 0-100). Only the legs below the coat hem animate.

### BACK
The feet alternate.
- Frames 02 and 03: the left foot is lifted (1 and 3 px).
- Frames 00, 06 and 08: the right foot is lifted (2, 2 and 3 px). The rest lift it about 1 px.

**Loop:** `09*, 06, 08, 00, 04*, 02, 03, 02`
- Upper body locked to frame 09 (rows 0-98), with a +1 px bob on 09 and 04.
- Frames 01, 05 and 07 are unused (near-duplicates).

### SIDE
**Still NO passing (legs-together) pose in either sheet.**
- side_a: the feet span 62-68 px in every frame, i.e. wide stride throughout.
- side_b: frames 01, 05 and 06 narrow to 54-57 px, but the same leg stays forward. There is no crossing or passing.

I chose **side_b**, for its narrower frames. Both sheets are on-model with each other, but side_a adds no new poses.

**Main loop (legs only):** `02, 05, 01*, 05, 07, 05, 01*, 05`
- Order chosen by exhaustive search for the smallest loop leg change.
- Head, hair, torso, arms and coat form a fixed "shell" taken from side_b frame 00. Each frame only pastes its own leg pixels behind the shell.
- `*` = +1 px bob on the narrowest stride.
- W = E mirrored.

**Passing-legs experiment, REJECTED.** The two passing frames were built from the Option A E still's boots (feet together), centred under the hips, with straight trousers filled from the walk's own trouser colours.
- The seam is visible: a flat trouser block, a hard line at the boot tops, and a different boot style.
- Shown only in `previews/REJECTED_east_passing_attempt_*`.

## Checks
32/32 frames pass (`alpha_check.md`):
- RGBA 128x128, border clear.
- 0 semi-transparent px, 0 RGB under alpha 0.
- 0 magenta, 0 tint, 0 fringe, 0 non-palette colours.
- Soles on row 123, feet centre 61.5-65.5.
- Heights: S 119-120, N 120-121, E/W 120-121.

Upper-body pixel change between frames is 0 except for the 1 px bob shifts, so there is no Imagine flicker.

## Verdict
- **S:** a real two-step alternation, looping cleanly. It reads as a gentle walk/march: the front-view boot motion is subtle. On-model with still S.
- **N:** a clear alternating heel lift, looping cleanly, so it reads as walking. Proportions are closer to still N than v1 was.
- **E/W:** still NOT a walk. The legs breathe between a wide and a slightly narrower stride with the same leg forward, so the feet slide. The upper body is now rock-steady and on-model with still E.
- **Side remains unsolved.** Next routes:
  - (a) Imagine video mode on the E still, walking in place, then extract one cycle of frames.
  - (b) Ask Imagine for a single passing-pose image (E still as reference, "both legs together, one knee bent, foot lifted behind"), then reuse the shell/leg pipeline.
  - (c) Hand-paint 2 passing frames over the shell.
