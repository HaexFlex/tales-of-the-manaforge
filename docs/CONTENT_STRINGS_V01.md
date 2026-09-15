# Tales of the Manaforge — Content String Sheet v0.1
**Owner:** Content & Lore  
**Status:** v0.2.4 — Manashard blessing shop only after Fruit (Ascension); not mid-run  
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
| v0.1.2 | Channelled Harvest Tree / Stone / Berry @ 1/sec. Water channel: shards + essence / sec + growth. Essence not Fruit-only. Drop click-cooldown multi-node gather phrasing. |
| v0.1.3 | Welcome / first-boot Keeper lines (tend the Manatree). Next-stage needs: growth X/Y + missing mats list. |
| v0.1.4 | Pause menu: Resume, New Game (+confirm), Save, Load, Options (later), Exit (+confirm), empty-slot / overwrite. |
| v0.1.5 | Strip growth language from next-stage/care. Needs-only (Essence + mats). Advance / can’t-afford. Growth X/Y keys retired. |
| v0.2.0 | `SYSTEMS_V01` v0.2.0: needs checklist `{have}/{need}` + **Pay**; remove Offer verbs; water = income only; no growth. |
| v0.2.1 | Ascension polish: guide Harvest → spend Essence on blessings → Ascend. Scrub growth/offer language from welcome. |
| v0.2.2 | Haex: after Fruit, choose one free blessing (superseded). |
| **v0.2.3** | Haex: Ascension shop spends **Manashards** on blessings; multi-buy OK; then Ascend. Not free-pick, not Essence. |

---

## 1. Meta / boot

| key | string |
|-----|--------|
| `game_title` | Tales of the Manaforge |
| `game_subtitle` | Restart Edition |
| `boot_line` | The forest is quiet. The Manatree is waiting. |
| `welcome_boot` | The forest is quiet. Tend the Manatree. |
| `welcome_title` | Keeper |
| `welcome_body` | This clearing is the last living fragment. You are its Keeper. Water the Manatree, gather what the clearing gives, and Pay its Needs when it is ready. When the Primordial Fruit comes, harvest it, spend Manashards on lasting blessings, then Ascend. |
| `welcome_body_short` | Water and gather. Pay the Manatree’s Needs. Harvest the Fruit, buy blessings with Manashards, then Ascend. |
| `welcome_dismiss` | I will tend it |
| `welcome_hint` | Water the Manatree for Essence. Harvest Tree, Stone, and Berries for its Needs. Pay to advance. |
| `new_game_confirm` | Begin as Keeper? |
| `load_game` | Continue |
| `save_toast` | Progress remembered. |

---

## 2. Resources (lock these labels)

| id | HUD | Examine / tooltip |
|----|-----|-------------------|
| `wood` | Wood | Soft timber from the Harvest Tree. |
| `stone` | Stone | Cool river-rock, still dusted with moss. |
| `food` | Food | Berries from the bush — for the Manatree’s Needs. |
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
| `tree_growth_hud` | *(retired from player UI — needs-only)* |
| `tree_stage_hud` | {stage_display} |

---

## 5. Manatree care — Water + Needs / Pay (`SYSTEMS_V01` v0.2.0)

**No growth bar. No Offer verbs.** Panel: next stage + needs checklist + Pay (when met) + Water.

### 5a. Interact menu

| key | string |
|-----|--------|
| `tree_menu_title` | Manatree |
| `tree_interact_water` | Water |
| `tree_pay` | Pay |
| `tree_tend` | Tend |

### 5b. Water channel (income only — shards + essence / sec)

| key | string |
|-----|--------|
| `tree_water_start` | You water the Manatree. Magic gathers. |
| `tree_water_channel_hud` | Watering… |
| `tree_water_pulse_hud` | +{shards} Manashards, +{essence} Essence |
| `tree_water_ok` | *(legacy pulse SFX label — prefer pulse HUD)* The Manatree brightens. |
| `tree_water_out_of_range` | Too far to keep watering. |
| `tree_water_cancel` | You stop watering. |
| `tree_water_ancient_note` | Ancient — still drinking, still giving. The Fruit waits when you are ready. |

### 5c. Needs checklist + Pay

| key | string |
|-----|--------|
| `tree_care_title` | Care |
| `tree_next_stage_title` | Toward {next_stage} |
| `tree_next_stage_needs_header` | Needs |
| `tree_need_line` | {item} {have}/{need} |
| `tree_need_line_met` | {item} {have}/{need} ✓ |
| `tree_next_stage_needs_line` | {costs} |
| `tree_next_stage_needs_met` | Ready — Pay when you wish |
| `tree_next_stage_needs_none` | Nothing more — Pay |
| `tree_pay_confirm` | Give what it needs to become {next_stage}? |
| `tree_pay_confirm_yes` | Pay |
| `tree_pay_confirm_no` | Not yet |
| `tree_pay_ok` | The Manatree becomes {next_stage}. |
| `tree_pay_cant_afford` | Not enough yet — {costs} |
| `tree_advance` | Pay |
| `tree_advance_confirm` | Give what it needs to become {next_stage}? |
| `tree_advance_confirm_yes` | Pay |
| `tree_advance_confirm_no` | Not yet |
| `tree_advance_ok` | The Manatree becomes {next_stage}. |
| `tree_advance_cant_afford` | Not enough yet — {costs} |
| `tree_stage_blocked_mats` | Still needs {costs}. |
| `tree_stage_blocked_essence` | Essence {have}/{need} |
| `tree_stage_blocked_food` | Food {have}/{need} |
| `tree_stage_blocked_wood` | Wood {have}/{need} |
| `tree_stage_blocked_stone` | Stone {have}/{need} |
| `tree_at_ancient_idle` | Ancient and waiting. The Primordial Fruit hangs heavy. |

**Retired (do not ship in UI):** growth X/Y keys; all `tree_offer_*` verbs; `tree_growth_hud`.

**Tokens:** `{next_stage}`, `{item}`, `{have}`, `{need}`, `{costs}` (joined need lines).  
Design costs (§4): Young essence 20 → Mature 40+food 10 → Elder 60+food 20+wood 10 → Ancient 80+food 40+wood 20+stone 10.

---

## 6. Primordial Fruit — Harvest → Manashards shop → Ascend

Player flow (Haex v0.2.4): **1) Harvest Primordial Fruit** → **2) Manashard blessing shop (this panel only)** → **3) Ascend**.  
Shop is **Ascension-only** after Fruit — not available mid-run. Not free-pick. Not Essence-priced.

| key | string |
|-----|--------|
| `fruit_ready_prompt` | Harvest the Primordial Fruit |
| `fruit_confirm` | Harvest the Primordial Fruit? You will spend Manashards on lasting blessings, then may Ascend. Soft goods reset on Ascend; Essence, Manashards spent on blessings, and blessings remain. |
| `fruit_confirm_yes` | Harvest |
| `fruit_confirm_no` | Not yet |
| `fruit_harvest_toast` | The Primordial Fruit is yours. Essence +{amount}. |
| `fruit_flow_hint` | Ascension only: spend Manashards on blessings here (leftover shards wipe on Ascend), then Ascend. |
| `fruit_step_1` | 1 · Harvest |
| `fruit_step_2` | 2 · Bless |
| `fruit_step_3` | 3 · Ascend |
| `fruit_panel_title` | Ascension Blessings |
| `fruit_panel_subtitle` | After the Fruit — spend Manashards on lasting gifts. Then Ascend. |
| `fruit_panel_step` | Harvest done · Bless · Ascend |
| `fruit_shards_hud` | Manashards: {count} |
| `fruit_essence_hud` | Essence: {count} |
| `ascend_prompt` | Ascend — begin again, stronger |
| `ascend_hint` | Soft goods and leftover Manashards return to the forest. Blessings stay with you. |
| `ascend_confirm` | Ascend? Wood, Stone, Food, and Manashards return to the forest. Blessings stay. The Manatree becomes a Sapling. |
| `ascend_confirm_yes` | Ascend |
| `ascend_confirm_no` | Stay a while |
| `ascend_toast` | A new cycle. The Sapling greets you — and your blessings. |
| `ascend_count_hud` | Cycles: {count} |
| `ascend_before_bless_hint` | Spend Manashards on blessings first — unused shards return to the forest on Ascend. |

### Permanent upgrades (Manashards shop)

| upgrade_id | Display | Description |
|------------|---------|-------------|
| `deep_roots` | Deep Roots | Watering yields Essence a little sooner. |
| `forager` | Forager’s Grace | Harvest channels yield a little more. |
| `green_thumb` | Green Thumb | Soft-mat Needs ask for a little less. |
| `shard_sight` | Shard Sight | Watering yields more Manashards. |
| `keeper_stride` | Keeper’s Stride | Walk the fragment a little faster. |

| key | string |
|-----|--------|
| `upgrade_rank` | Rank {rank}/{max} |
| `upgrade_cost` | {cost} Manashards |
| `upgrade_buy` | Buy |
| `upgrade_bless` | Bless |
| `upgrade_maxed` | Fully blessed |
| `upgrade_cant_afford` | Not enough Manashards |
| `upgrade_buy_ok` | {blessing_name} grows stronger. |

**Retired for this flow:** free-pick `fruit_choose_*` / `upgrade_select` as the primary path (Code may ignore).

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

## 7b. Pause menu

Warm + lightly melancholic. Options is a stub until later.

| key | string |
|-----|--------|
| `pause_title` | Pause |
| `pause_resume` | Resume |
| `pause_new_game` | New Game |
| `pause_new_game_confirm` | Begin again as Keeper? This clearing’s progress will be lost unless you saved. |
| `pause_new_game_confirm_yes` | Begin again |
| `pause_new_game_confirm_no` | Stay |
| `pause_save` | Save |
| `pause_load` | Load |
| `pause_options` | Options |
| `pause_options_stub` | Coming later |
| `pause_options_soon` | Options will open later. For now, the forest waits quietly. |
| `pause_exit` | Exit |
| `pause_exit_confirm` | Leave the clearing? Unsaved care may fade with the light. |
| `pause_exit_confirm_yes` | Leave |
| `pause_exit_confirm_no` | Remain |
| `pause_slot_empty` | Empty slot — quiet earth |
| `pause_slot_filled` | Cycle {ascensions} · {stage_display} |
| `pause_slot_overwrite_confirm` | Overwrite this memory? The older cycle will be gone. |
| `pause_slot_overwrite_yes` | Overwrite |
| `pause_slot_overwrite_no` | Keep it |
| `pause_save_ok` | The clearing remembers. |
| `pause_save_fail` | Could not save — try again. |
| `pause_load_ok` | Welcome back, Keeper. |
| `pause_load_empty` | Nothing grows in that slot yet. |
| `pause_load_fail` | Could not load — try again. |

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

---

## 10. Wisps + RTS input (v0.3.3)

Haex / Director: **LMB** selects (Keeper or Wisp) or deselects on empty ground. **RMB** commands. Assigned Wisps **orbit** the harvest node or Manatree while pulsing.

| key | string |
|-----|--------|
| `wisp_assign_to_manatree` | Tend the Manatree |
| `wisp_assign_manatree_busy` | A Wisp already tends the Manatree. |
| `wisp_assign_hint` | Right-click a harvest spot or the Manatree to send this Wisp. |
| `wisp_unassign_ground` | Right-click the ground to call the Wisp back. |
| `wisp_select_hint` | Idle Wisps orbit you. Left-click a Wisp, then right-click a gather spot or the Manatree. |
| `keeper_move_prompt` | Right-click the ground to walk. |
