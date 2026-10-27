# Keeper idle moments: painted poses (2026-10-27)
Replaces the stand-ins in place: assets/art/keeper/anim/idle_moments/<clip>/south/frame_%04d.png,
same counts (stretch 11, look 17, sit_down 6, sit_breathe 16, stand_up 6), 128x128, feet bottom row y=123 as walk/south,
100 ms per frame. No rewiring needed; existing .import files kept.
Old frames: assets/library/legacy/idle_moments_standin_2026-10-27/ (REPLACED.md).
- stretch: arms (live sleeve+glove pixels) swing down -> out -> overhead and back; arm-side coat repainted; up on toes +2 px at the top.
- look: head from the live west/east idle pixels over the south body, shoulders shift 1 px; left hold, centre, right hold, centre.
- sit_down / stand_up: hips drop 14 px onto a seat about 23 px above the feet line (Bench seat height, facing south),
  thighs foreshortened, knees spread 2 px, boots planted. A small forward-lean head dip on the middle frames.
- sit_breathe: head/chest/shoulders rise 1 px for 8 of 16 frames.
Code: the sit drop is in the art, so keep sprite.offset = OFFSET_BODY (no extra Y offset); place the Keeper
so the feet line sits ~23 px below the Bench seat top edge.
