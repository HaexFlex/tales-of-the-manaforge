# Idle and harvest rework (Pass E)

Status: Haex decisions for PR #17. This file is the idle spec. `docs/forge_v2.md` links here. Sections 1–5 are implemented. The old §4 mitigation and §7 shop-flag proposals are not built. Haex replaced them with the three decisions in [Haex decisions](#haex-decisions).

Haex changed the Ancient timer from 15 minutes (900 s) to **10 minutes (600 s)**. Everywhere an earlier draft said 900, read 600. The live value is `ancient_duration_sec` in `data/forge_tuning.json`.

## 1. Continuous harvest

Harvest no longer grants on a 1-second pulse and then floors. Each source (wood, stone, food, manashards) has a float accumulator. Whole units are banked and the fraction is kept, including across save and load.

- Bare Keeper: `KEEPER_HARVEST_SEC = 2.0` (one yield per 2 s). A matching tool sets that source to 1.0 s.
- A Wisp is 1/10 of the bare Keeper: one yield per 20 s, including a Manatree Wisp making shards.
- `wisp_haste` is −2 s per rank, minimum 10 s.
- Watering is unchanged: it still pulses on `CHANNEL_PULSE_SEC` and gets no stage multiplier.

## 2. Stage multipliers (active harvest only)

| Stage | Multiplier |
|---|---|
| Sapling | 1.0 |
| Young | 1.15 |
| Mature | 1.3 |
| Elder | 1.5 |
| Ancient | 3.0 |

Active rate = base × (stage + Forager). Forager stays +0.05 per rank and adds to the stage multiplier.

Offline rate = base × (1 + Forager) × the offline curve. The stage multiplier does not apply offline.

## 3. Ancient timer

Ancient lasts `ancient_duration_sec` (600). The timer counts only while the game is open and unpaused. The remaining time is saved.

While the stage is Ancient, nothing progresses offline: harvest, watering, Wisps, and the Forge. The offline curve does not consume closed time during Ancient either.

The HUD shows a countdown. At 0 the Fruit auto-harvests and the Ascension shop opens with no harvest confirm. Manual early harvest stays. Closing the shop still cancels the commit, the same as a manual harvest.

Grow to Ancient asks first. The dialog is HUD-only. Live copy is CONTENT_STRINGS v0.7.2 §13:

- `tree_grow_ancient_confirm_title`
- `tree_grow_ancient_confirm_body` (`{minutes}` from `ancient_duration_sec`; 600 s is 10)
- `tree_grow_ancient_confirm_yes`
- `tree_grow_ancient_confirm_no`
- `tree_ancient_timer_label` (`{time}` is a live m:ss countdown)

The Pass E placeholder keys `ancient_grow_confirm_*` and `ancient_countdown_hud` stay in the string table and are not shown. When the timer ends, the toast is `fruit_harvest_toast`.

`try_grow_stage` itself stays a direct call so tests can grow without the dialog. The confirm is on the HUD Grow button only.

## 4. Offline curve

One curve covers harvest, watering, Wisps, and the Forge. It replaces the Forge's 1/20, 1/100, and 1/1000 tiers. The Forge's additive speed (Keeper 1, companion 1, each Wisp 0.1, cap 4) still applies on top of the curved seconds. There is no `OFFLINE_WATER_MULT` and no gather-multiplier floor.

Config is `offline_tiers` in `data/forge_tuning.json`: `[end_hours, rate]`. A final `end_hours` of −1 is the open tail.

| Closed time | Rate | Effective seconds at the boundary |
|---|---|---|
| 0–30 min | 1/10 | 180 |
| to 2 h | 1/60 | 270 |
| to 8 h | 1/250 | 356.4 |
| to 24 h | 1/600 | 452.4 |
| after 24 h | 1/3000 | — |

### Curve reset

There is no 4-hour cooldown. The curve restarts at the fresh 1/10 tier only when the player has actively played for at least `offline_reset_active_sec` (180) since the last load. Active time counts only while the game is open and unpaused.

If they reopen and close again sooner, the next closure continues from the cumulative closed time. Example: close 20 minutes, reopen for 1 minute, close 20 minutes. The second closure is priced as minutes 20–40, not 0–20.

The save stores `offline_closed_sec` and `active_since_load_sec`. A closure shorter than 1 second does not move the curve (same as today's tiny-gap skip).

## 5. Save

Save version stays 9. v9 gains `harvest_accum`, `ancient_remaining_sec`, `offline_closed_sec`, and `active_since_load_sec`.

A v8 save at Ancient, and any Ancient save missing `ancient_remaining_sec`, loads the full configured duration (600).

## Haex decisions

These three replace the unbuilt §4 mitigation and §7 shop-flag proposals. Those proposals are not implemented.

1. **Keep Tools** costs 5,000 Manashards (was 3,000). Still max rank 1, flat cost.
2. **Shard Sight** adds 25% of the base watering shard average per rank. The base average is 2 per second, so the bonus is +0.5 per rank, not +1. Its `cost_base` is 800, so the price is 800 × (rank + 1). The fractional part stays in the manashard accumulator. The Watering Can still doubles the roll, bonus included.
3. **Offline curve reset** is the 180-second active-play rule in §4. No separate cooldown is built.
