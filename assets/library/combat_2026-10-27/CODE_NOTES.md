# Modular combat anims (2026-10-27)

Gentle, never violent. Body frames are weaponless; attach sword/bow/wand at the hand anchor.

## Keeper body — `assets/art/battle/modular/keeper/<clip>/frame_0000..0003.png`
Clips: **attack** (8f from Imagine video — see below), **hit, brace, cast, spare** (4 frames each). 128², sole ~123, east-facing.
~100–120 ms/frame. Bodies weaponless; attach `wpn_*` at hand anchors.

## Weapons — `assets/art/battle/modular/weapons/`
- `sword.png` (14×6), `bow.png` (8×12), `wand.png` (3×12)
- Convenience: `weapons/sword_attack/frame_0000..0003.png` pre-placed on 128² canvas for the attack clip.

## Hand-anchor table
Columns: actor, clip, frame, hand_x, hand_y, rot_index (0 = tip east / no rot), z (front|behind body).
Place weapon so its **grip pixel** sits on (hand_x, hand_y).

actor,clip,frame,hand_x,hand_y,rot_index,z
# keeper attack 0..7 → see "Keeper attack from Imagine video" + hand_anchors.json (video-derived)
keeper,hit,0,70,78,0,behind
keeper,hit,1,70,79,0,behind
keeper,hit,2,70,78,0,behind
keeper,hit,3,70,77,0,behind
keeper,brace,0,72,76,0,behind
keeper,brace,1,72,77,0,behind
keeper,brace,2,72,76,0,behind
keeper,brace,3,72,76,0,behind
keeper,cast,0,82,70,0,front
keeper,cast,1,84,68,0,front
keeper,cast,2,82,70,0,front
keeper,cast,3,78,78,0,front
keeper,spare,0,78,78,0,front
keeper,spare,1,78,79,0,front
keeper,spare,2,76,78,0,front
keeper,spare,3,78,78,0,front
elaia,attack,0,100,66,0,front
elaia,attack,1,101,66,0,front
elaia,attack,2,102,66,0,front
elaia,attack,3,103,66,0,front
elaia,cast,0,85,72,0,front
elaia,cast,1,85,72,0,front
elaia,cast,2,85,72,0,front
elaia,cast,3,85,72,0,front

Also JSON: `hand_anchors.json` beside this note.

## Acorn Imp — `assets/art/battle/modular/acorn_imp/{attack,hit,calm}/frame_0000..0003.png`
Gentle lean-poke attack, hurt nudge, calm breathe. From live `battle_acorn_imp_*`.

## Budget note
Keeper + Imp shipped. Elaia attack/cast partial if present on main. Puff / moss_tortoise combat deferred.

## Weapons t0–t2 (2026-10-27) — v2 native size
Path: `res://assets/art/battle/weapons/{sprite_id}.png`

| sprite_id | display | size | tip↔grip | notes |
|---|---|---|---|---|
| wpn_sword_t0 | (starter) | 28×10 | 26 | wood/stone |
| wpn_sword_t1 | Flintblade | 28×10 | 26 | knapped stone edge |
| wpn_sword_t2 | Rootsteel | 28×10 | 26 | root-veined metal, cyan seam |
| wpn_wand_t0 | Weapon Rod | 9×36 | tip↔grip ~12 | upright native tip −Y |
| wpn_wand_t1 | Sapstaff | 9×36 | tip↔grip ~12 | amber sap tip |
| wpn_wand_t2 | Heartwand | 9×36 | tip↔grip ~12 | warm amber/red gem tip |
| wpn_bow_t0 | (starter bow) | 14×24 | ~12 limb | |
| wpn_bow_t1 | Thornbow | 14×24 | ~12 limb | thorny vine limbs |
| wpn_bow_t2 | Switchshaft | 14×24 | ~12 limb | sleek bent-switch, cyan string hint |
| wpn_none | | 1×1 | — | empty |

**Family grips** (shared across tiers of that family):
- sword: `0, 4`
- wand: `4, 12`
- bow: `1, 11`

Place pre-rotated `rot/{sprite_id}_r{rot_index}.png` at `(hand_x - gx, hand_y - gy)` using `rot/grip_offsets.json`.
Old small weapons archived: `assets/library/legacy/weapons_small_2026-10-27/`.
Old wand 5×24 archived: `assets/library/legacy/weapons_wand_5x24_2026-10-27/` (+ REPLACED.md).

## rot_index angle table (Godot 2D, +clockwise)
| rot_index | degrees | rad (approx) | tip points |
|---|---|---|---|
| 0 | 0° | 0 | east (default) |
| 1 | 45° | π/4 | south-east |
| 2 | 90° | π/2 | south |
| 3 | 135° | 3π/4 | south-west |
| 4 | 180° | π | west |
| 5 | 225° | 5π/4 | north-west |
| 6 | 270° | 3π/2 | north |
| 7 | 315° | 7π/4 | north-east |

**Pre-rotated (preferred, no engine smear):** `assets/art/battle/weapons/rot/{sprite_id}_r{rot_index}.png`
Code should either:
1. **Preferred:** load `rot/{sprite_id}_r{rot_index}.png` and set `weapon.rotation = 0`, or
2. Keep base `{sprite_id}.png` and set `weapon_rotation_rad(i) = i * TAU/8` with **nearest** filtering (TextureFilter.NEAREST). Soft/linear rotation will smear pixels.

Attack frames use rot_index 6→6→7→1→1→1→0→0 (overhead wind-up → SE impact → east recover). See v3 anchors below.

## Keeper attack 8 frames
`assets/art/battle/modular/keeper/attack/frame_0000..0007.png` (was 4). Matches `timings_1x.party.attack.frames = 8`. Anchors updated in `hand_anchors.json`.

## Keeper attack from Imagine video v3 (2026-10-27)
Source body: `/workspace/combat_imagine/keeper_attack/v3a_try2.mp4` (empty fist; overhead raise → crouch low forward swing → recover).
Anchor assist: `v3b_try2.mp4` (same swing, cyan #00FFFF sword for tip angle). Fist from v3a body; rot_index from v3b cyan, cross-checked to v2 pattern.
Backup unused: `v3a_try1.mp4`, `v3b_try1.mp4`. Prior dagger-erased interim → `assets/library/legacy/keeper_attack_erased_2026-10-27/`.

**Source frame indices** (0-based in the 145-frame extract, ffmpeg `f_NNNN` = index+1):
| art frame | phase | src index | role |
|---|---|---|---|
| 0 | windup1 | 24 | raise to shoulder |
| 1 | windup2 | 42 | chamber peak |
| 2 | swing | 60 | descending / high forward |
| 3 | **impact** | 66 | **IMPACT (index 3)** |
| 4 | follow1 | 78 | low extension |
| 5 | follow2 | 96 | hold |
| 6 | recover1 | 117 | rising |
| 7 | recover2 | 132 | settle |

Body is empty-fist (no weapon erase). Overlay `wpn_*` v2 at hand anchors. Nearest downscale, sole 123, live Keeper height 116, palette-snapped, hard alpha.

### Attack anchors
frame,phase,hand_x,hand_y,rot_index,z,src_frame
0,windup1,43,24,5,behind,24
1,windup2,48,21,6,behind,42
2,swing,96,35,7,front,60
3,impact,101,82,1,front,66
4,follow1,95,103,1,front,78
5,follow2,95,103,1,front,96
6,recover1,94,84,0,front,117
7,recover2,83,50,0,front,132

Pre-rotated grips: `weapons/rot/grip_offsets.json` (swords 28×10 tip↔grip 26, grip family (0,4); wand 9×36 (4,12), tip-east=r0; bow 14×24 (1,11)).
Review: `assets/library/combat_2026-10-27/keeper_attack_v3_contact_1x.png` + `/workspace/sprint_art/previews/keeper_attack_v3_contact_{1x,4x}.png` + flintblade GIF.

## Keeper attack_wand 8 frames (2026-10-27)
Clip path: `assets/art/battle/modular/keeper/attack_wand/frame_0000..0007.png` (new path; sword `attack` untouched).
**Still-only Imagine** → i2v from `v3_still.jpg` empty-hand cast. Source: `/workspace/combat_imagine/wand/wand_try1.mp4` (448×672, 24fps, 145f). Motion sheets caused sword-in-body before; do not attach them.
Gate: empty hand, cast thrust (not swing). Video budget: 1 of 4 used (hard cap 6).

| art frame | phase | src index | role |
|---|---|---|---|
| 0 | raise | 22 | tip lifts |
| 1 | raise | 34 | tip toward target |
| 2 | gather | 52 | tip glow builds (FX) |
| 3 | gather | 64 | gather peak |
| 4 | release | 82 | thrust tip east |
| 5 | release | 94 | hold thrust |
| 6 | recover | 114 | tip lowers |
| 7 | recover | 130 | settle |

**Timing:** 8 frames × 125 ms = 1000 ms (`GAP_STRIKE_SEC = 1.0` same as sword).
Body weapon-free; nearest-downscale to live attack (128², sole 123, h≈116), palette-snap, hard alpha.

### attack_wand anchors (+ tip for spark)
`hand_anchors.json` rows with `clip=attack_wand`. Extra fields vs sword: `tip_ox`, `tip_oy` (unrotated wand space; tip toward −Y; gem ≈ grip+(0,−9)).
Code: tip canvas = hand + rotate(`tip_ox`,`tip_oy`) by the same CW transform as the wand from tip-up native → `rot_index` world tip (θ = rot_index·45° − 270°).

frame,phase,hand_x,hand_y,rot_index,z,tip_ox,tip_oy,src_frame
0,raise,88,52,7,front,0,-9,22
1,raise,90,48,7,front,0,-9,34
2,gather,90,46,7,front,0,-9,52
3,gather,94,42,0,front,0,-9,64
4,release,102,48,0,front,0,-9,82
5,release,98,58,0,front,0,-9,94
6,recover,78,72,0,front,0,-9,114
7,recover,76,70,1,front,0,-9,130

### Wand cast spark FX
`assets/art/battle/fx/wand_cast_spark_strip.png` — 8×8 cells × 4 frames, warm amber, hard alpha.
On for gather/release frames 2–5; place centred on tip. Off on raise/recover.

### Schema brief for Code (bow queued later)
- Select clip by weapon family: sword → `attack`, wand → `attack_wand` (bow → `attack_bow` when shipped).
- Wand: single hand + `tip_ox`/`tip_oy` + spark strip. No `hand2` / `string_draw` on wand.
- Bow (not shipped yet): will add `hand2_x`,`hand2_y`,`string_draw` on `attack_bow`.
- Grip assert wand family `(4, 12)` on 9×36 natives. Prefer pre-rotated `rot/*_r{rot_index}.png`.

Meta: `keeper_attack_wand_meta.json`. Contacts: `keeper_attack_wand_contact_{1x,4x}.png`. GIF: `keeper_attack_wand.gif`.
