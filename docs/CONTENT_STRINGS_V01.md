# Tales of the Manaforge — Content String Sheet v0.1
**Owner:** Content & Lore  
**Status:** v0.1.1 — aligned to `SYSTEMS_V01` v0.1.1 (free Water + Offer mats)  
**Source of truth:** `VISION_RESTART.md` + `SYSTEMS_V01.md` + `refs/`  
**Non-canon:** Ashkiln / Ashwarden / idle-combat packs; forge-hub flavor  
**Audience:** Code wires keys; Art/Audio ignore lore depth beyond labels  
**Last updated:** 2026-09-14

**Tone (Haex locked):** warm + lightly melancholic — never stressful.  
**In-world rule:** *Manaforge* is **title-only** in v0.1 (window / itch blurb). Do not name the hidden forge or door in player strings yet.

## Changelog
| Ver | Change |
|-----|--------|
| v0.1 | Day-1 string sheet |
| **v0.1.1** | Remove Food-cost watering. Free **Water** + **Offer** Wood/Stone/Food/Manashards. Stage-gate copy includes Food. Tone locked warm + lightly melancholic. |

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

Aligns to Design IDs. Short HUD name = column **HUD**.

| id | HUD | Examine / tooltip |
|----|-----|-------------------|
| `wood` | Wood | Soft timber from the living fragment. |
| `stone` | Stone | Cool river-rock, still dusted with moss. |
| `food` | Food | Forage to offer the Manatree — care made tangible. |
| `manashards` | Manashards | Faint crystals that hum when held. |
| `essence` | Essence | Gift of the Primordial Fruit. Lasts beyond the reset. |

| key | string |
|-----|--------|
| `hud_need` | Need {item} ×{count} |
| `hud_full_inv_noop` | (unused in v0.1 — counters only) |

---

## 3. Gather nodes + verbs

| node_id | Prompt (hover / ready) | On gather | On cooldown |
|---------|------------------------|-----------|-------------|
| `node_wood` | Gather Wood | You take a careful armful of Wood. | The grove needs a moment. |
| `node_stone` | Gather Stone | You lift a Stone from the moss. | The stones settle. Wait. |
| `node_food` | Forage Food | Berries and soft leaves — good to Offer. | Nothing ripe yet. |
| `node_manashards` | Gather Manashards | A Manashard warms in your palm. | The glow fades. Later. |

| key | string |
|-----|--------|
| `gather_busy` | One thing at a time. |
| `gather_verb_default` | Gather |

---

## 4. Manatree — stages (working names locked for v0.1)

Design stage_ids. Display name + one-line presence + stage-up toast.

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

## 5. Manatree care — Water (free) + Offer mats

Matches `SYSTEMS_V01` v0.1.1. Water spends nothing. Offers spend inventory for growth. Stage-up may still require a gate mix (incl. Food).

### 5a. Interact menu labels

| key | string |
|-----|--------|
| `tree_menu_title` | Manatree |
| `tree_interact_water` | Water |
| `tree_offer_wood` | Offer Wood |
| `tree_offer_stone` | Offer Stone |
| `tree_offer_food` | Offer Food |
| `tree_offer_manashards` | Offer Manashards |

### 5b. Water (free)

| key | string |
|-----|--------|
| `tree_water_ok` | You water the Manatree. It brightens. |
| `tree_water_cooldown` | Easy — let it drink. |
| `tree_water_ancient_block` | The Ancient Manatree needs no more water. The Fruit is ready. |

### 5c. Offer

| key | string |
|-----|--------|
| `tree_offer_ok_wood` | You offer Wood. The Manatree settles stronger. |
| `tree_offer_ok_stone` | You offer Stone. Roots find purchase. |
| `tree_offer_ok_food` | You offer Food. Care made visible. |
| `tree_offer_ok_manashards` | You offer a Manashard. Magic threads into the bark. |
| `tree_offer_deny` | Not enough {item}. |
| `tree_offer_cooldown` | One gift at a time. |
| `tree_offer_ancient_block` | The cycle is complete. Harvest the Fruit instead. |

### 5d. Stage gate (missing mats)

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
| `fruit_confirm` | Harvest the Primordial Fruit? The Manatree will return to a Sapling. Your Essence and blessings remain. |
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

### Permanent upgrades (ids from Design)

| upgrade_id | Display | Description |
|------------|---------|-------------|
| `deep_roots` | Deep Roots | Each rank: Watering grants more growth. |
| `forager` | Forager’s Grace | Each rank: gather a little more from every node. |
| `green_thumb` | Green Thumb | Each rank: stages need less growth to advance. |
| `shard_sight` | Shard Sight | Each rank: Manashard nodes yield more. |
| `keeper_stride` | Keeper’s Stride | Each rank: walk the fragment a little faster. |

| key | string |
|-----|--------|
| `upgrade_rank` | Rank {rank}/{max} |
| `upgrade_cost` | {cost} Essence |
| `upgrade_buy` | Bless |
| `upgrade_maxed` | Fully blessed |
| `upgrade_cant_afford` | Not enough Essence |

---

## 7. Minimal HUD / UI chrome labels

| key | string |
|-----|--------|
| `hud_wood` | Wood |
| `hud_stone` | Stone |
| `hud_food` | Food |
| `hud_manashards` | Manashards |
| `hud_essence` | Essence |
| `btn_menu` | Menu |
| `btn_close` | Close |

---

## 8. Out of v0.1 (do not ship strings for)

Combat, whisps, Forge interior / door interact, equipment, Echo Chamber, Manaforge-as-place name, multi-zone travel copy.

---

## 9. Handoffs

| Who | Use |
|-----|-----|
| @Code / Engine | Keys above as string-table IDs; substitute `{…}` tokens |
| @Game Design | Labels match `SYSTEMS_V01` ids; rename only via Content |
| @Art Direction | Stage display names for UI chips; no extra lore panels |
| @Audio | Pair cues to: gather_*, tree_water_ok, tree_offer_ok_*, stage-up toasts, fruit_harvest, ascend_toast |

Ping @Game Director on landing. Tone locked; renames only if Haex asks.
