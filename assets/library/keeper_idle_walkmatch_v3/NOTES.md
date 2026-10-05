# Keeper idle walkmatch v3 — OLD pose + LIVE walk visuals

Additive. Does **not** overwrite v1/v2 or live `idle/`.

## Method
- **Pose** from old Imagine idle (`assets/art/keeper/idle/{dir}/`) — both feet planted, foot x targets from old sole blobs.
- **Visuals** entirely from live walk frames (`assets/art/keeper/anim/walk/`) — upper (coat/hair/emblem/arms) from upright walk frame aligned to old torso cx; boots/legs from walk plant boots placed on old foot targets.
- **No old Imagine pixels** in the finals (palette shared with walk).

## Motion
- 12 frames × 160 ms = **1920 ms** loop
- Gentle ±1 px torso bob above hem row 84; legs fixed

## Checks
- North cyan: v3=52 (walk plant=58, old Imagine=224)
- Canvas 128×128, hard alpha, sole y=123

## Paths
- Runtime: `assets/art/keeper/idle_walkmatch_v3/{dir}/keeper_idle_{dir}_0001..0012.png`
- Library: `assets/library/keeper_idle_walkmatch_v3/`
- Contact: `/workspace/keeper_idle_rebuild/out/idle_walkmatch_v3_contact.png`
- Handoff: `/workspace/art-handoff/keeper-idle-walkmatch-v3/`

Wire still on hold — Code points when Haex OK.
