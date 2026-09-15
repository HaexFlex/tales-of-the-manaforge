# Tales of the Manaforge — Content String Sheet v0.1
**Owner:** Content & Lore  
**Status:** v0.1.2 — aligned to `SYSTEMS_V01` v0.1.2 (channelled harvest + water payout)  
**Source of truth:** `VISION_RESTART.md` + `SYSTEMS_V01.md` + `refs/`  
**Non-canon:** Ashkiln / Ashwarden / idle-combat packs; forge-hub flavor; click-cooldown gather copy  
**Audience:** Code wires keys; Art/Audio ignore lore depth beyond labels  
**Last updated:** 2026-09-15

**Tone (Haex locked):** warm + lightly melancholic — never stressful.  
**In-world rule:** *Manaforge* is **title-only** in v0.1 (window / itch blurb). Do not name the hidden forge or door in player strings yet.

## Changelog
| Ver | Change |
|-----|--------|
| v0.1 | Day-1 string sheet |
| v0.1.1 | Free Water + Offer mats; Food-cost watering removed |
| **v0.1.2** | Channelled Harvest Tree / Stone / Berry @ 1/sec. Water channel: shards + essence / sec + growth. Essence not Fruit-only. Drop click-cooldown multi-node gather phrasing. |

---

## 1. Meta / boot

| key | string |
|-----|--------|
| `game_title` | Tales of the Manaforge |
| `game_subtitle` | Restart Edition |
| `boot_line` | The forest is quiet. The Manatree is waiting. |
| `new_game_confirm` | Begin as Keeper? |
| `load_game` | Continue |
| `save_toast` | Progress remembered. |

---

## 2. Resources (lock these labels)

| id | HUD | Examine / tooltip |
|----|-----|-------------------|
| `wood` | Wood | Soft timber from the Harvest Tree. |
| `stone` | Stone | Cool river-rock, still dusted with moss. |
| `food` | Food | Berries from the bush — good to Offer. |
| `manashards` | Manashards | Drawn while watering the Manatree. |
| `essence` | Essence | Grows with every careful watering — and with the Fruit. |

| key | string |
|-----|--------|
| `hud_need` | Need {item} ×{count} |

---

## 3. Harvest channels (exactly three nodes)

Interactive nodes only. Decorative forest trees have **no** strings / no prompts.

| node_id | Prompt (ready) | Channeling HUD | Pulse toast (optional, rare) | Cancel / leave |
|---------|----------------|----------------|------------------------------|----------------|
| `harvest_tree` | Harvest Tree | Harvesting Wood… | — | You step away from the Harvest Tree. |
| `harvest_stone` | Harvest Stone | Harvesting Stone… | — | You leave the stone. |
| `harvest_berry` | Harvest Berries | Harvesting Food… | — | You leave the berry bush. |

| key | string |
|-----|--------|
| `harvest_start` | You begin to harvest. |
| `harvest_pulse_hud` | +{amount} {item}/s |
| `harvest_busy_other` | Finish this first — or walk away. |
| `harvest_out_of_range` | Too far to keep harvesting. |
| `deco_tree_no_interact` | *(no prompt — deco only)* |

---

## 4. Manatree — stages

| stage_id | Display | Presence (journal / examine) | Stage-up toast |
|----------|---------|------------------------------|----------------|
| `sapling` | Sapling | A green spark in the clearing. Fragile. Precious. | — |
| `young` | Young Tree | The Manatree finds its voice in the wind. | The Manatree grows — Young Tree. |
| `mature` | Mature Tree | Shade returns to the fragment. Birds remember. | The Manatree grows — Mature Tree. |
| `elder` | Elder Tree | Roots deep. Leaves bright with quiet magic. | The Manatree grows — Elder Tree. |
| `ancient` | Ancient Manatree | The World Seed stands complete… for this cycle. | The Manatree is Ancient. The Fruit is near. |

| key | string |
|-----|--------|
| `tree_examine_generic` | The Manatree. Heart of the last living fragment. |
| `tree_growth_hud` | Growth |
| `tree_stage_hud` | {stage_display} |

---

## 5. Manatree care — Water channel + Offer

### 5a. Interact menu

| key | string |
|-----|--------|
| `tree_menu_title` | Manatree |
| `tree_interact_water` | Water |
| `tree_offer_wood` | Offer Wood |
| `tree_offer_stone` | Offer Stone |
| `tree_offer_food` | Offer Food |
| `tree_offer_manashards` | Offer Manashards |

### 5b. Water channel (shards + essence + growth / sec)

| key | string |
|-----|--------|
| `tree_water_start` | You water the Manatree. Magic gathers. |
| `tree_water_channel_hud` | Watering… |
| `tree_water_pulse_hud` | +{shards} Manashards, +{essence} Essence |
| `tree_water_ok` | *(legacy pulse SFX label — prefer pulse HUD)* The Manatree brightens. |
| `tree_water_out_of_range` | Too far to keep watering. |
| `tree_water_cancel` | You stop watering. |
| `tree_water_ancient_note` | Ancient — still drinking, still giving. The Fruit waits when you are ready. |

### 5c. Offer (instant)

| key | string |
|-----|--------|
| `tree_offer_ok_wood` | You offer Wood. The Manatree settles stronger. |
| `tree_offer_ok_stone` | You offer Stone. Roots find purchase. |
| `tree_offer_ok_food` | You offer Food. Care made visible. |
| `tree_offer_ok_manashards` | You offer a Manashard. Magic threads into the bark. |
| `tree_offer_deny` | Not enough {item}. |
| `tree_offer_cooldown` | One gift at a time. |
| `tree_offer_ancient_block` | Growth is complete. Harvest the Fruit — or keep watering for gifts. |

### 5d. Stage gate

| key | string |
|-----|--------|
| `tree_stage_blocked_mats` | The Manatree is ready to grow — but needs {costs}. |
| `tree_stage_blocked_wood` | Wood ×{count} |
| `tree_stage_blocked_stone` | Stone ×{count} |
| `tree_stage_blocked_food` | Food ×{count} |
| `tree_stage_blocked_shards` | Manashards ×{count} |
| `tree_at_ancient_idle` | Ancient and waiting. The Primordial Fruit hangs heavy. |

Cost list join: commas + “and” — e.g. `Wood ×4, Stone ×2, and Food ×2`.

---

## 6. Primordial Fruit — harvest / upgrades / ascend

| key | string |
|-----|--------|
| `fruit_ready_prompt` | Harvest the Primordial Fruit |
| `fruit_confirm` | Harvest the Primordial Fruit? The Manatree will return to a Sapling. Essence and blessings remain. |
| `fruit_confirm_yes` | Harvest |
| `fruit_confirm_no` | Not yet |
| `fruit_harvest_toast` | The Primordial Fruit is yours. Essence +{amount}. |
| `fruit_panel_title` | Blessings of the Fruit |
| `fruit_panel_subtitle` | Spend Essence. These gifts survive every Ascend. |
| `fruit_essence_hud` | Essence: {count} |
| `ascend_prompt` | Ascend — begin again, stronger |
| `ascend_confirm` | Ascend? Soft goods (Wood, Stone, Food, Manashards) return to the forest. Essence and blessings stay. |
| `ascend_confirm_yes` | Ascend |
| `ascend_confirm_no` | Stay a while |
| `ascend_toast` | A new cycle. The Sapling greets you. |
| `ascend_count_hud` | Cycles: {count} |

### Permanent upgrades

| upgrade_id | Display | Description |
|------------|---------|-------------|
| `deep_roots` | Deep Roots | Each rank: Watering grants more growth. |
| `forager` | Forager’s Grace | Each rank: harvest channels yield a little more. |
| `green_thumb` | Green Thumb | Each rank: stages need less growth to advance. |
| `shard_sight` | Shard Sight | Each rank: watering yields more Manashards. |
| `keeper_stride` | Keeper’s Stride | Each rank: walk the fragment a little faster. |

| key | string |
|-----|--------|
| `upgrade_rank` | Rank {rank}/{max} |
| `upgrade_cost` | {cost} Essence |
| `upgrade_buy` | Bless |
| `upgrade_maxed` | Fully blessed |
| `upgrade_cant_afford` | Not enough Essence |

---

## 7. Minimal HUD / UI chrome

| key | string |
|-----|--------|
| `hud_wood` | Wood |
| `hud_stone` | Stone |
| `hud_food` | Food |
| `hud_manashards` | Manashards |
| `hud_essence` | Essence |
| `btn_menu` | Menu |
| `btn_close` | Close |
| `btn_cancel_channel` | Stop |

---

## 8. Out of v0.1 (do not ship strings for)

Combat, whisps, Forge interior / door interact, equipment, Echo Chamber, Manaforge-as-place name, multi-zone travel, prompts on decorative trees.

---

## 9. Handoffs

| Who | Use |
|-----|-----|
| @Code / Engine | Channel HUD keys + pulse tokens; cancel on move; no prompts on deco trees |
| @Game Design | Labels match `SYSTEMS_V01` v0.1.2 ids |
| @Art Direction | Harvest Tree ≠ deco trees in player-facing names |
| @Audio | Pulse each harvest/water tick; reuse gather / `sfx_tree_water` |

Ping @Game Director on landing.
