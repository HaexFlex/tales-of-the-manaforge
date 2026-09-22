# Cue notes — Echo Chamber v1 (Haex GO)

**Ship:** silence in battle; hub bed stop/pause on enter, resume loop on exit.
**Not this ship:** battle music, battle sting, Fruit/Ascend sting on portal fee or Key.

## Hub bed
| Event | Behavior |
|-------|----------|
| Battle enter | **Stop/pause** `mus_hub_forest` (do not duck) |
| Spare / Defeat / Flee return to hub | **Resume** same loop (continue or restart from loop — either OK; prefer continue if stream paused) |

## Battle
- No `mus_*` battle bed
- KO / Spare / Defeat: **silence** (no Progress sting)
- Menu: optional soft `sfx_ui_confirm` / `sfx_ui_cancel` only

## Portal / Forge care
- Fee pay / deny: `sfx_ui_confirm` / `sfx_ui_deny` or silent — **do not** use Fruit/Ascend cues
- Enter Forge popups: `sfx_ui_*` only

## Mix
- Live Music −9 dB / SFX 0 / Progress duck for forest still apply **outside** battle
- Inside battle: Music silent (stopped)
