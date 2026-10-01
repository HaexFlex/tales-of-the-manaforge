# Keeper harvest animations (experiment, not wired into the game)

Imagine key-pose sheets (chop S/E, pluck S/E, mine S; west = mirror of east) built into 6-frame, 1000 ms loops.
- Frames 192x128 with the feet anchor at (96,128) (`sprite.offset = (-96,-128)`); horizontal strips `keeper_<anim>_<dir>.png` laid out like `keeper_walk_south.png`.
- `keeper_<anim>_<dir>.json`: frame size, anchor, per-frame `hold_ms`, `strike_frame` / `strike_at_ms` (the frame that should land on the 1 s harvest pulse).
- `*_preview_x2.gif`: on hub grass next to the target. `compare/`: the live walk_south beside each clip.
- `ingest_report.json`: per-pose head drift / clipping and the verdicts. `NOTES_honest.md`: what worked and what didn't.
No scene, script or game-data changes.
