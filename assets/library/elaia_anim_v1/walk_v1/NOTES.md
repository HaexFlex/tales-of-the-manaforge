# Elaia walk v1 (S / N / E + W mirror)

Built in the Keeper walk v5 style: 8 frames per direction, 120/125/130/125/120/125/130/125 ms (1000 ms loop), 128x128 canvas, soles on row 123, hard alpha, Elaia 40-colour palette (`palette.json` = v1_stills palette), no magenta.

## Sources (`source/`)
| dir | clip | loop | frames used (1-based video frames) |
|---|---|---|---|
| E | elaia_walk_east.mp4 | 24 frames, no holds (exact lag-24 period) | 40 43 46 49 52 31 34 37 (every 3rd frame; k0/k4 = passing) |
| S | elaia_walk_south.mp4 | 24 frames, 8 unique poses each held 3 | 88 91 94 97 100 103 82 85 (all 8 holds) |
| N | elaia_walk_north.mp4 | 26 frames, 11 unique poses held 2-3 | 39 42 44 48 51 54 32 34 (nearest to uniform 3.25-frame spacing) |
| W | mirror of E | | |

Clip verification: all three clips are locked off (no drift, pan, zoom or turning). Hands are empty and there are no props. E uses the early segment, because the motion changes a little after ~f89.

## Per-direction build (`tools/build_walk.py`, config `tools/cfg_v1.json`)
- Convert (`convert_elaia.py`): key, scale so the window's tallest frame = still height (S 116, N/E 115), lowest pixel to row 123, defringe, palette, despeck.
- Bob 0..2 px via `fit_top` (rows above the hip shift, hip..sole band resampled, soles stay on 123).
  - E is re-timed to a per-step 0/1/2/1 pattern (passing high). The deltas vs natural are <= 1 px.
  - S uses the natural tops, which already fall within 0..2.
  - N's natural tops (13,10,9,10,14,12,9,10) are clamped into 9..11. That stretches the robe 2/3/1 px on k0/k4/k5, because in the back view the passing pose's soles sit higher.
- Head/hair lock (taken from one reference frame, pasted at each frame's bobbed top):
  - E: top 34 rows + back-hair box (rows 34-39 x 36-50) from k4.
  - S: top 56 rows from k0 (head, side hair strands, shoulders; the side strands flickered strongly).
  - N: top 30 rows + back-hair box (rows 30-46 x 49-80) from k0.
- N hair sway: I tested swapping between two reference hair blocks (k0 for k0-3, k4 for k4-7). It read as a texture pop every 500 ms rather than a sway, so the hair is locked.
- E robe slit: in one step (k4-k7) the front slit opens and shows a bare thigh/knee (off-model). Those skin pixels (skin components reaching row >= 86 and spanning >= 4 rows; hands untouched) are recoloured to the inner-robe blues. Recoloured px per frame: 0,0,0,0,17,102,132,31.
- E swing boots raised straight up (no x change) to 5 px: k1 +3, k5 +2 (reaching boot), k3 +2, k7 +3 (toe-off). The robe stays in front.
- Key holes (<= 4 px enclosed, above row 60) are filled with the most common neighbour colour.

## Measurements (`walk_*/measure.txt`)
- Heights: S 114-116, N 113-115, E/W 113-115.
- Bob: S [0,1,2,1,0,1,1,1]; N [0,1,2,1,0,0,2,1]; E/W [2,1,0,1,2,1,0,1] (max top - top).
- Lift:
  - E/W: swing boots 5 px (k1/k3/k5/k7). At passing (k0/k4) the boots overlap on the ground (robe walk).
  - S: rear boot sits 6-8 px higher (perspective + lift).
  - N: 3-7 px.
- E/W stance boot heel travels ~11 px per frame (66->55->43->33 and 77->66->(55)->43->33), so the suggested move speed is 88 px/s (range 84-92). At an in-game speed of 180 px/s that means playback at 180/88 = 2.05x. Keeper walk v5 (80 px/s) plays at 2.25x; Elaia played at 2.25x would match 198 px/s.

## Checks
- `check_frames_elaia.py walk_v1 "walk_*/walk_*.json"`: ALL PASS 32/32.
- `check_extra_dir.py` (still_h S 116, N/E/W 115): one component, height still-3..still, bob <= 2, 100-130 ms, 900-1100 ms loop, loop seam within steps, head rows locked. All OK in all four dirs (`walk_*/extra_check.json`).
- Hard alpha (0 semi-transparent px), 0 magenta, 0 off-palette colours, soles row 123, 128x128: all 32 frames.

## Weak spots
- E/W: the slit fix leaves an inner-robe blue panel with the slit outline in k4-k7. It reads as an inner layer, but the other step (k0-k3) shows a closed robe.
- E/W: the light comes from the video (front-lit). Mirroring for W flips it.
- N: the robe skirt stretches 2-3 px on the passing frames (k0/k4) to keep soles on 123 with bob <= 2. The walk-N hair is shorter and narrower than still N (the video drew it that way).
- S: the side-hair strands are frozen to k0 (no sway). The hands/cuffs below row ~66 still change with the arm swing.
- Body texture re-quantises each frame (changed px per step ~2.0-3.0k, similar to Keeper v5).

## Previews
`previews/elaia_walk_v1_S_N_E_W_x3.gif`, `previews/elaia_v1_vs_keeper_v5_walk_S_N_E_W_x3.gif`, `previews/elaia_walk_v1_contact_x2.png`; per-dir `walk_*/walk_*_x3.gif`.
