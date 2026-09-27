# Cue notes — Forge v1 (Director greenlit test branch)

**Ship:** soft craft start/done + reuse wisp assign/deny/unassign/pulse. Hub bed **keeps looping** (optional light duck).
**Not this ship:** Forge BGM, industrial hammer loops, spark spam, body-unlock sting, Fruit/Ascend cues for craft.

## Hub BGM (unlike Echo Chamber)
| Event | Behavior |
|-------|----------|
| Enter Forge | **KEEP** `mus_hub_forest` looping; optional light duck ~2–3 dB while in Forge (**NOT** stop/pause like Echo battle) |
| Exit Forge | Restore Music bus if ducked |

## Reuse existing (no new files)
| Event | cue_id |
|-------|--------|
| Wisp assign to Crucible/Mill/Anvil | `sfx_wisp_assign` |
| Deny (station full) | `sfx_wisp_deny` |
| Unassign | `sfx_wisp_unassign` |
| AFK/station pulse (Design: ~10 pulses/job; quieter than Keeper gather) | `sfx_wisp_pulse` on **SFX_World** |

## New soft craft cues
| Event | cue_id | Bus | Notes |
|-------|--------|-----|-------|
| Craft job start (Crucible/Mill/Anvil) | `sfx_forge_craft_start` | SFX_World | Soft wood/mana tick — **NOT** hammer clang |
| Craft job done | `sfx_forge_craft_done` | SFX_World | Soft warm resolve / tiny bloom — **NOT** anvil smash |

Godot paths: `res://assets/audio/<file>` (flat layout).

## Mix
- Music default **−9 dB**; SFX **0 dB**; Progress duck unchanged **outside** Forge.
- Forge craft + wisp pulses on SFX_World / SFX_UI as noted — **never** duck Music from World pulses.

## Manifest
- Version bump: see `MANIFEST.json` (`v0.1.7-forge-v1`).
