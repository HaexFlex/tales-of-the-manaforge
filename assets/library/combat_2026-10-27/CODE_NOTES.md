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

## Weapons t0–t2 (2026-10-27 follow-up)
Path pattern: `res://assets/art/battle/weapons/{sprite_id}.png` (and `wpn_none.png`, `wpn_bow_t0.png` added).

| sprite_id | display | notes |
|---|---|---|
| wpn_sword_t0 | (starter) | wood/stone |
| wpn_sword_t1 | Flintblade | knapped stone edge |
| wpn_sword_t2 | Rootsteel | root-veined metal, cyan seam |
| wpn_wand_t0 | Weapon Rod | |
| wpn_wand_t1 | Sapstaff | amber sap tip |
| wpn_wand_t2 | Heartwand | glowing heartwood core |
| wpn_bow_t0 | (starter bow) | |
| wpn_bow_t1 | Thornbow | thorny vine limbs |
| wpn_bow_t2 | Switchshaft | sleek bent-switch, cyan string hint |

**Grip:** pixel `(0, 3)` on every base sprite (= `CombatAnimsConfig.WEAPON_GRIP`). Same grip across tiers so body frames stay valid.

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

Attack frames use rot_index 6→6→7→1→1→1→0→0 (overhead wind-up → SE impact → east recover).

## Keeper attack 8 frames
`assets/art/battle/modular/keeper/attack/frame_0000..0007.png` (was 4). Matches `timings_1x.party.attack.frames = 8`. Anchors updated in `hand_anchors.json`.

## Keeper attack from Imagine video (2026-10-27)
Source: `/workspace/combat_imagine/keeper_attack/v2.mp4` (preferred; overhead wind-up → swing to low front-right → recover).
Backup unused: `v1.mp4`.

**Source frame indices** (0-based in the 145-frame extract, ffmpeg `f_NNNN` = index+1):
| art frame | phase | src index | role |
|---|---|---|---|
| 0 | windup1 | 18 | raise |
| 1 | windup2 | 42 | overhead peak |
| 2 | swing | 63 | descending |
| 3 | **impact** | 78 | **IMPACT (index 3)** |
| 4 | follow1 | 84 | low extension |
| 5 | follow2 | 96 | coat flare hold |
| 6 | recover1 | 117 | rising |
| 7 | recover2 | 132 | settle |

Body is weapon-free (sword painted out, fist filled). Overlay `wpn_sword_t*` at hand anchors.
Procedural stand-ins moved to `assets/library/legacy/keeper_attack_procedural_2026-10-27/`.

### Attack anchors (from video sword → nearest rot_index)
frame,phase,hand_x,hand_y,rot_index,z,src_frame
0,windup1,98,40,6,behind,18
1,windup2,95,24,6,behind,42
2,swing,105,50,7,front,63
3,impact,124,94,1,front,78
4,follow1,114,93,1,front,84
5,follow2,112,96,1,front,96
6,recover1,123,86,0,front,117
7,recover2,122,61,0,front,132
