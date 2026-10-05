# Keeper idle walkmatch v2 — both feet planted

Additive idle rebuild from **live walk** frames only (`assets/art/keeper/anim/walk/{dir}/frame_0000..0007.png`).
Does **not** overwrite v1 (`idle_walkmatch/`) or old Imagine idle.

## Pose
- **Standing idle**: both boots on sole row y=123, roughly shoulder-width under the torso (not the mid-stride plant used in v1).
- South: plant-boot from walk f5 + **mirrored** copy placed at torso±8 px.
- North: left boot from walk f3 + right boot from walk f0, relocated under hips.
- East/West: walk f0 (most compact profile — feet already stacked).

## Motion
- **12 frames × 160 ms = 1920 ms** loop.
- Gentle ±1 px torso bob above coat hem (row 84); legs/boots fixed.

## Paths
- Runtime: `assets/art/keeper/idle_walkmatch_v2/{south,north,east,west}/keeper_idle_{dir}_0001..0012.png`
- Library: `assets/library/keeper_idle_walkmatch_v2/` (+ NOTES, report.json, previews)
- Contact: `assets/library/keeper_idle_walkmatch_v2/previews/idle_walkmatch_v2_contact.png`
- Handoff: `/workspace/art-handoff/keeper-idle-walkmatch-v2/`

## Checks
- Canvas 128×128, hard alpha 0/255, transparent RGB=0
- Palette shared with walk (no new colours)
- North cyan emblem: 56 px (walk plant ~58) — walk scale, NOT old Imagine ~224
- Do not use old `assets/art/keeper/idle/` as source

## Code swap
Point idle SpriteFrames at `idle_walkmatch_v2` (or copy over idle paths when ready). Keep v1 until verified.
