# Keeper idle walkmatch v1 (2026-10-05)

**Purpose:** Standing idle that matches the **live walk v5 hybrid** coat / hair / north back emblem.  
**Does not replace** live Imagine idle until Code/Haex swaps paths. Additive drop.

Plan: `/workspace/keeper_idle_rebuild/PLAN.md`.

## Source
Live walk only (no Imagine idle, no archive):
`assets/art/keeper/anim/walk/{south,north,east,west}/frame_0000..0007.png`  
(= walk_v5 hybrid lift 55%, wired in `1185eea`).

Plant frames used (max sole contact on y=123): **S=f5, N=f3, E=f3, W=f3**.

## Outputs
| Location | Pattern |
|---|---|
| Library | `assets/library/keeper_idle_walkmatch_v1/{dir}/keeper_idle_{dir}_0001..0012.png` |
| Runtime-ready | `assets/art/keeper/idle_walkmatch/{dir}/keeper_idle_{dir}_0001..0012.png` |

Same filename scheme as current `assets/art/keeper/idle/` so Code can point `_idle_frame_paths` here or copy over after legacy.

## Build
- **Mode: subtle bob** — planted legs from plant frame; upper body (rows 0–83) shifts ±1 px on a 12-frame sine breath. Legs/sole unchanged (sole stays y=123).
- Canvas 128×128, hard alpha, palette **⊆ walk plant** (shared colour count = walk cols; 0 new colours).
- Hold was not needed; bob passed hem/cyan checks.

## North emblem (cyan px, full sprite)
| | Walk plant | **New idle** | Old Imagine idle |
|---|---|---|---|
| Full cyan | 58 | **58** | 224 |
| Back panel y20–70 x40–90 | 58 | **58** | 241 |

## Code swap (when approved)
In `scripts/keeper.gd` `_idle_frame_paths` / `_idle_dir_has_frames`, change  
`res://assets/art/keeper/idle/` → `res://assets/art/keeper/idle_walkmatch/`  
**or** replace files in place under `idle/` after moving Imagine set to `assets/library/legacy/`.  
`verify_headless` still expects 12 frames @ those names.

## Contact
`previews/idle_walkmatch_contact.png` — walk plant | new | old | cyan highlight.
