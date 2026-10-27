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
| wpn_wand_t0 | Weapon Rod | 5×24 | ~7 tip / ~15 butt | |
| wpn_wand_t1 | Sapstaff | 5×24 | ~7 tip / ~15 butt | amber sap tip |
| wpn_wand_t2 | Heartwand | 5×24 | ~7 tip / ~15 butt | glowing heartwood core |
| wpn_bow_t0 | (starter bow) | 14×24 | ~12 limb | |
| wpn_bow_t1 | Thornbow | 14×24 | ~12 limb | thorny vine limbs |
| wpn_bow_t2 | Switchshaft | 14×24 | ~12 limb | sleek bent-switch, cyan string hint |
| wpn_none | | 1×1 | — | empty |

**Family grips** (shared across tiers of that family):
- sword: `0, 4`
- wand: `2, 7`
- bow: `1, 11`

Place pre-rotated `rot/{sprite_id}_r{rot_index}.png` at `(hand_x - gx, hand_y - gy)` using `rot/grip_offsets.json`.
Old small weapons archived: `assets/library/legacy/weapons_small_2026-10-27/`.

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
0,windup1,86,66,6,behind,24
1,windup2,85,55,6,behind,42
2,swing,97,36,7,front,60
3,impact,102,82,1,front,66
4,follow1,97,102,1,front,78
5,follow2,97,102,1,front,96
6,recover1,95,85,0,front,117
7,recover2,84,52,0,front,132

Pre-rotated grips: `weapons/rot/grip_offsets.json` (swords 28×10 tip↔grip 26, grip family (0,4); wand 5×24 (2,7); bow 14×24 (1,11)).
Review: `assets/library/combat_2026-10-27/keeper_attack_v3_contact_1x.png` + `/workspace/sprint_art/previews/keeper_attack_v3_contact_{1x,4x}.png` + flintblade GIF.
