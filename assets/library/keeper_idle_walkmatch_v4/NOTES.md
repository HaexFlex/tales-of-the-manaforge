# Keeper idle walkmatch v4

**Date:** 2026-10-05  
**Wire:** HOLD until Haex OK. Do not point `keeper.gd` at these paths yet.

## Pipeline (Haex brief)
1. Plant stills from live walk: S=`frame_0005`, N/E/W=`frame_0003`
2. Grok Imagine image-to-video (settle/breathe, magenta, locked camera)
3. Extract 12-frame strips; hard alpha; walk 48-colour palette; soles row 123
4. West = horizontal mirror of east

## Direction notes
| Dir | Source | Window |
|---|---|---|
| **North** | Imagine idle video (usable after settle) | ~2.0–4.0 s |
| **East** | Imagine idle video (planted after ~0.5 s) | ~1.0–3.0 s |
| **West** | Mirror of east | — |
| **South** | Imagine kept marching the front view (2 attempts). **Plant still + vertical bob** from that video’s head motion; legs forced identical to walk plant below hem. | bob from rejected south clips |

## Timing
12 frames × 160 ms = 1920 ms loop (same family as prior idle_walkmatch packs). Game currently uses 150 ms — Code can match either when wiring.

## Paths
- Runtime additive: `assets/art/keeper/idle_walkmatch_v4/{south,north,east,west}/keeper_idle_<dir>_0001..0012.png`
- Preview: `assets/library/keeper_idle_walkmatch_v4/previews/idle_walkmatch_v4_contact_x2.png`

## Alpha
Hard alpha (0 or 255), no magenta, walk palette only.
