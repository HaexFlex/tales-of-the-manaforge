# Keeper portrait + idle stills v4

**Date:** 2026-10-05  
**Wire:** HOLD until Haex OK. Code wires on #25 after OK.

## Deliverables
1. **Portrait redraw** from idle v4 south (Imagine face-focused pass → keyed magenta → walk 48 palette → hard alpha)
   - HUD: `assets/art/portraits/keeper_portrait.png` (52×52) — drop_in copy
   - Sheet: `assets/art/portraits/keeper_portrait_sheet.png` (160×160)
2. **Standing stills** for character sheet + Echo/Adventure combat = **frame 0** of each idle v4 strip (identical pixels to `keeper_idle_<dir>_0001.png`)
   - Also labeled copies: `assets/library/keeper_portrait_idle_stills_v4/stills/keeper_still_<dir>_frame0.png`

## Source
- Idle strips: `assets/art/keeper/idle_walkmatch_v4/{south,north,east,west}/keeper_idle_<dir>_0001.png`
- Portrait derived from south idle via Grok Imagine bust pass

## Pack
`assets/library/keeper_portrait_idle_stills_v4/`
