# Ascension Blessings — Source of Truth

**LOCKED by Haex 2026-10-13.** All numbers are **PLACEHOLDER** for tuning.
`data/fruit_upgrades.json` is the in-game data. **Keep this page and `fruit_upgrades.json` in sync whenever either changes.**

Linear cost = base × (rank+1). Exponential costs are per rank as written. Status: **live** = exists in `fruit_upgrades.json` with matching behaviour; **needs code** otherwise.
Flags marked **NEW** do not exist in code yet.

## Blessings

| id | Lore name | Lore line | Effect per rank | Cost formula | Max rank | Unlock trigger | Status |
|---|---|---|---|---|---|---|---|
| deep_roots | Deep Roots | "Each rank: every watering pulse gives +{essence} Essence." (Lore 2026-10-13, pending Haex; was "Watering yields Essence a little sooner.") | +1 Essence per watering pulse | linear 400 | 5 | always | needs code (today +0.5/rank floored, max 10) |
| forager | Forager’s Grace | "Harvest channels yield a little more." | +5% harvest | linear 400 | 10 | always | live |
| green_thumb | Green Thumb | "Fertilizer craft asks for a little less." | Fertilizer craft −10% | linear 400 | 5 | always | live |
| shard_sight | Shard Sight | "Each rank: watering yields +0.5 Manashards per second (25% of the base average of 2)." | +0.5 shards/s on watering | linear 800 | 5 | always | live |
| keeper_stride | Keeper’s Stride | "Walk the fragment a little faster." | +6% move speed | linear 400 | 5 | always | live |
| wisp_haste | Swift Wisps | "Assigned Wisps gather a little sooner." | Wisp pulse ×(1 − 0.08×rank), 10 s floor | linear 400 | 5 | NEW `first_wisp_gained` | needs code (today −2 s/rank; gate) |
| bonus_wisp | Extra Wisp | "Another Wisp walks with you from the Sapling." | +1 starting Wisp | linear 400 | 3 | NEW `first_wisp_gained` | needs code (gate only) |
| keep_tools | Keep Tools | "Finished tools survive Ascend and return with you." | tools survive Ascend | 4000 flat | 1 | NEW `first_tool_crafted` | needs code (gate only) |
| keep_manashards | Shard Purse | Each rank: keep some leftover Manashards when you Ascend. | keep 10% of leftover Manashards (50% max); replaces the wipe at `game_state.gd:1593` | linear 600 | 5 | `ascensions >= 1` | needs code |
| keep_forge_jobs | Banked Embers | Unfinished Forge jobs carry on after you Ascend. | stations keep their job through Ascend | 40000 flat | 1 | `forge_visited` | needs code (lives in `forge_tuning.json`, not `fruit_upgrades.json`; gate) |
| expedition_satchel | Deep Satchel | Each rank: idle expeditions bring back a little more. | +10% idle room loot | 800 × 2^(rank−1) | 5 | `Reach.reaches_cleared >= 1` | needs code |
| sturdy_pack | Sturdy Pack | Each rank: more of the pack makes it home when a run goes wrong. | 15% of the pack safe from loss: Overwhelmed keeps the protected share; Flee halves only the unprotected part | 1000 × 2.5^(rank−1) | 3 | NEW `first_pack_lost` | needs code |
| dojo_echo | Echoing Lessons | Each rank: training gains grow a little. | +5% dojo exp | 500 × 1.6^(rank−1) | endless | `Reach.dojo_exp > 0` | needs code |
| forge_warmth | Forge Warmth | Each rank: Forge jobs finish a little faster. | Forge job time ×0.95^rank, floor 0.25× | 800 × 1.75^(rank−1) | endless | `first_relic_crafted` | needs code |
| party_banner | Kindred Banner | Each rank: send out one more party. | +1 party slot | linear 15000 | 2 | adventure unlocked: `GameState.echo_02_resolved` (= `ExpeditionBoard.road_open()`, Bramble spared or defeated) | needs code |
| minigame_knack | Tender's Knack | Each rank: tending a node by hand pays a little more. | +10% minigame reward | linear 400 | 5 | NEW `first_minigame_played` | needs code |
| quiet_hours | Quiet Hours | The clearing keeps working longer while you are away. | +0.25 h on the first offline tier (×0.1). Never endless; later tiers are never raised | linear 1000 | 2 | `ascensions >= 2` | needs code |

Endless example costs (PLACEHOLDER):
- dojo_echo 500 × 1.6^(r−1): r1 500 · r5 3,277 · r10 34,360 · r20 3,777,893
- forge_warmth 800 × 1.75^(r−1): r1 800 · r5 7,503 · r10 123,149 · r20 33,175,151 (effect floor 0.25× reached ~r27)

## Parked
- **wisp_lantern** (+1 Wisp cap per node; needs more Wisps first).
- **Root Cellar** (forge-material storage building; keeps a capped amount of forge materials through Ascend; name kept).

## Dropped
- companion_bond
- reach_headstart (start depth already goes up to `deepest_depth`)
- Keep Forge Materials upgrade (replaced by parked Root Cellar)

## Shop UI
- **Hide locked** and **Hide maxed** toggles side by side, both ON by default, saved per save file.
- Collapsed rows read just "N locked" / "N complete". No unlock hints.
- Turning Hide locked OFF shows a spoiler confirm (action left, big **Stay** right). Shown only the first 3 times; count saved per save file; afterwards the toggle switches silently. Confirm copy (locked): title "Peek ahead?", body "Some locked blessings name places and friends you have not met yet.", buttons "Peek" / "Stay".
- With Hide locked OFF, locked rows show greyed.

## Pending code fix
Ascend mid-expedition: wipe the loot pack but return unused carried items (loadout) to the bag. Today `Reach.on_ascend` (`reach.gd:117`) calls `_end_run("dark")` without `_finish_run`, so both are lost.
