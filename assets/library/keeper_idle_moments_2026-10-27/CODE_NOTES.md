# Keeper idle moments (2026-10-27)
All 128x128, same canvas and feet anchor (feet bottom row y=123) as anim/walk/south, so OFFSET_BODY is unchanged.
South-facing, 100 ms per frame, derived from idle_walkmatch_v4/south frame 0001. Hard alpha.
assets/art/keeper/anim/idle_moments/<clip>/south/frame_%04d.png
- stretch      11 frames, one-shot (rise onto toes / reach, head tips back at the peak)
- look         17 frames, one-shot (head left, hold, right, hold, centre)
- sit_down      6 frames, one-shot
- sit_breathe  16 frames, loop
- stand_up      6 frames, one-shot
Swap in scripts/keeper.gd: `_add_timed(frames, &"idle_stretch_south", "idle_moments/stretch/south", 100)` etc.
Sit: the body drop is in the art (feet stay planted), so REMOVE `IDLE_MOMENT_SIT_OFFSET_Y` (20 px) or the Keeper sinks into the ground.
Play sit_down -> sit_breathe (loop for IDLE_MOMENT_SIT_SEC) -> stand_up. Only south exists; for other faces keep the current fallback.
