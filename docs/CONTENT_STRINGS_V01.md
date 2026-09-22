# Tales of the Manaforge — Content String Sheet v0.1
**Owner:** Content & Lore  
**Status:** v0.6.0 — Haex GO: Echo Chamber v1 (Elaia, portal, Enter Forge, battle keys)
**Source of truth:** `VISION_RESTART.md` + `SYSTEMS_V01.md` + `refs/`  
**Non-canon:** Ashkiln / Ashwarden / idle-combat packs; forge-hub flavor; click-cooldown gather copy  
**Audience:** Code wires keys; Art/Audio ignore lore depth beyond labels  
**Changelog note:** v0.6.0 Echo Chamber v1 string sheet (Haex GO).

**Last updated:** 2026-09-22

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
| **v0.4.1** | Haex D6 live: Stone Axe/Pickaxe Head; costs-only Can+Fert rows; Keep Tools 3000; blessing tooltips; Grow Fert 3/6/12/24. |
| **v0.5.0** | Haex GREENLIGHT: Character sheet, seven stats (VISION), Runestone spend (Manashards), locked Weapon/Relic slot hints, Weapon Rod + Stone Sword, equip tooltips. Manatree scale note bundled (visual — D7). |
| **v0.5.1** | Design id lock: slots `weapon`/`relic`/`head`/`body`/`hands`/`pants`/`feet`/`cape`/`ring1`/`ring2` (only weapon unlocked); item id `stone_sword`; gear inventory ≠ backpack; HUD+C; D7 scales live (visual). |
| **v0.6.0** | Haex GO Echo Chamber v1: Elaia (`echo_keeper_01`); portal 30 Essence; Enter Forge care-menu (no-key / not-built); Strike/Flee/Spare; bare-fists toast; Key both endings; companion Spare-only; KO/Spare/Defeat silent. |

---

## 1. Meta / boot

| key | string |
|-----|--------|
| `game_title` | Tales of the Manaforge |
| `game_subtitle` | Restart Edition |
| `boot_line` | The forest is quiet. The Manatree is waiting. |
| `welcome_boot` | The forest is quiet. Tend the Manatree. |
| `welcome_title` | Keeper |
| `welcome_body` | This clearing is the last living fragment. You are its Keeper. Water the Manatree, gather what the clearing gives, and Pay its Needs when it is ready. When the Primordial Fruit comes, harvest it, spend Manashards on lasting blessings, then Ascend — Essence returns to the forest; blessings stay. |
| `welcome_body_short` | Water and gather. Pay the Manatree’s Needs. Harvest the Fruit, buy blessings with Manashards, then Ascend. |
| `welcome_dismiss` | I will tend it |
| `welcome_hint` | LMB selects, RMB commands. Wisps orbit you until assigned — send them to gather, or to the Manatree for Manashards. |
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
| `tree_pay` | Grow |
| `tree_grow` | Grow |
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
| `tree_water_ancient_note` | Ancient — you may still water for Manashards and Essence. The Fruit waits when you are ready. |
| `tree_water_ancient_ok` | The Ancient Manatree still drinks — shards and Essence gather. |
| `tree_ancient_care_hint` | Keep watering for Manashards. When ready, Harvest the Fruit to begin Ascension. |

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
| `tree_pay_confirm` | Grow into {next_stage}? |
| `tree_grow_confirm` | Grow into {next_stage}? |
| `tree_pay_confirm_yes` | Grow |
| `tree_grow_confirm_yes` | Grow |
| `tree_pay_confirm_no` | Not yet |
| `tree_pay_ok` | The Manatree becomes {next_stage}. |
| `tree_grow_ok` | The Manatree becomes {next_stage}. |
| `tree_pay_cant_afford` | Not enough yet — {costs} |
| `tree_grow_cant_afford` | Not enough yet — {costs} |
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
| `fruit_precommit_cta` | Harvest the Primordial Fruit |
| `fruit_precommit_hint` | You can still water and gather. Blessings wait until after you commit the harvest. |
| `fruit_precommit_no_shop` | Blessings unlock after you harvest. |
| `fruit_confirm_step1_title` | Begin Ascension? |
| `fruit_confirm_step1` | Begin harvesting the Primordial Fruit? You can still water until you commit. |
| `fruit_confirm_step1_yes` | Continue |
| `fruit_confirm_step1_no` | Keep watering |
| `fruit_confirm_step2_title` | Commit the harvest |
| `fruit_confirm_step2` | Commit the harvest? The world will pause. Spend Manashards on blessings, then Ascend — Essence will return to the forest with the soft goods. |
| `fruit_confirm_step2_yes` | Harvest |
| `fruit_confirm_step2_no` | Not yet |
| `fruit_confirm` | Harvest the Primordial Fruit? *(legacy — prefer two-step keys)* |
| `fruit_confirm_yes` | Harvest |
| `fruit_confirm_no` | Not yet |
| `fruit_harvest_toast` | The Primordial Fruit is yours. The blessing shop opens. |
| `fruit_flow_hint` | Ascension shop only — spend Manashards, then Ascend. Leftover shards wipe. There is no cancel. |
| `fruit_step_1` | 1 · Harvest |
| `fruit_step_2` | 2 · Bless |
| `fruit_step_3` | 3 · Ascend |
| `fruit_panel_title` | Ascension Blessings |
| `fruit_panel_subtitle` | Spend Manashards on lasting gifts, then Ascend. No return to the clearing until then. |
| `fruit_panel_step` | Harvest done · Bless · Ascend |
| `fruit_shop_only_banner` | Ascension — blessing shop only. Ascend to continue. |
| `fruit_shards_hud` | Manashards: {count} |
| `fruit_essence_hud` | Essence: {count} |
| `ascension_paused_title` | Ascension |
| `ascension_paused_body` | The clearing is paused. Spend Manashards on blessings, then Ascend. You cannot return to watering until the new cycle. |
| `ascension_paused_hint` | Ascend when ready — the only way forward. |
| `ascend_prompt` | Ascend — begin again, stronger |
| `ascend_hint` | Soft goods and Essence return to the forest. Blessings stay. The next Sapling starts at 0 Essence — water to grow again. |
| `ascend_confirm` | Ascend? Soft goods and Essence return to the forest. Blessings stay. The Manatree becomes a Sapling. |
| `ascend_confirm_essence_wipe` | Ascend? Soft goods and Essence return to the forest. Blessings stay. The Manatree becomes a Sapling. |
| `ascend_confirm_yes` | Ascend |
| `ascend_confirm_no` | Keep shopping |
| `ascend_toast` | A new cycle. The Sapling greets you — and your blessings. |
| `ascend_essence_reset_toast` | Essence settles back into the forest. Your blessings remain. |
| `ascend_count_hud` | Cycles: {count} |
| `ascend_before_bless_hint` | Spend Manashards on blessings first — unused shards return to the forest on Ascend. |

### Permanent upgrades (Manashards shop)

| upgrade_id | Display | Description |
|------------|---------|-------------|
| `deep_roots` | Deep Roots | Watering yields Essence a little sooner. |
| `forager` | Forager’s Grace | Harvest channels yield a little more. |
| `green_thumb` | Green Thumb | Fertilizer craft costs a little less. |
| `shard_sight` | Shard Sight | Watering yields more Manashards. |
| `keeper_stride` | Keeper’s Stride | Walk the fragment a little faster. |
| `wisp_haste` | Swift Wisps | Assigned Wisps gather a little sooner. |
| `bonus_wisp` | Extra Wisp | Another Wisp walks with you from the Sapling. |

| key | string |
|-----|--------|
| `upgrade_rank` | Rank {rank}/{max} |
| `upgrade_cost` | {cost} Manashards |
| `upgrade_buy` | Buy |
| `upgrade_bless` | Bless |
| `upgrade_maxed` | Fully blessed |
| `upgrade_cant_afford` | Not enough Manashards |
| `upgrade_buy_ok` | {blessing_name} grows stronger. |

| key | string |
|-----|--------|
| `upgrade_tooltip` | {desc} |
| `upgrade_deep_roots_tooltip` | Watering yields a little more Essence over time. |
| `upgrade_forager_tooltip` | Harvest channels yield a little more. |
| `upgrade_green_thumb_tooltip` | Fertilizer craft ingredient costs drop a little each rank. |
| `upgrade_shard_sight_tooltip` | Watering yields more Manashards each pulse. |
| `upgrade_keeper_stride_tooltip` | Walk the fragment a little faster. |
| `upgrade_wisp_haste_tooltip` | Assigned Wisps gather a little sooner. |
| `upgrade_bonus_wisp_tooltip` | Another Wisp walks with you from the Sapling. |
| `upgrade_keep_tools_tooltip` | Finished tools survive Ascend and return with you. |

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
| `pause_options_stub` | *(retired — Options opens Audio)* |
| `pause_options_soon` | *(retired)* |
| `options_title` | Options |
| `options_audio` | Audio |
| `options_back` | Back |
| `options_audio_title` | Audio |
| `options_music_volume` | Music |
| `options_sfx_volume` | Sounds |
| `options_audio_back` | Back |
| `options_audio_hint` | Soften the forest, or let it sing. |
| `options_audio_reset` | Reset |
| `options_music_volume_full` | Music volume |
| `options_sfx_volume_full` | SFX volume |
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

## 7c. Keeper controls — LMB select / RMB command

| key | string |
|-----|--------|
| `keeper_select` | Keeper |
| `keeper_selected` | Keeper selected |
| `keeper_select_hint` | Left-click to select the Keeper. Right-click to walk, harvest, or tend. |
| `controls_lmb_select` | Left-click: select |
| `controls_rmb_command` | Right-click: command |
| `controls_lmb_deselect` | Left-click empty ground: deselect |
| `controls_hint` | LMB selects. RMB commands. LMB on empty ground deselects. |
| `keeper_move_prompt` | Right-click the ground to walk. |
| `keeper_required` | Select the Keeper first (left-click). |
| `keeper_required_harvest` | Select the Keeper, then right-click the tree, stone, or berries. |
| `keeper_required_tree` | Select the Keeper, then right-click the Manatree. |
| `keeper_required_wisp` | *(retired — Wisp select uses LMB)* |
| `keeper_deselect` | Deselect |
| `keeper_deselect_toast` | Cleared. |
| `keeper_busy` | The Keeper is busy — try again in a moment. |

---

## 7d. Wisps (select / assign / gather)

Spelling: **Wisp** (player-facing). Idle Wisps **orbit the Keeper**; assigned Wisps **orbit their node** (harvest or Manatree).

| key | string |
|-----|--------|
| `wisp_name` | Wisp |
| `wisp_name_plural` | Wisps |
| `wisp_select` | Select Wisp |
| `wisp_selected` | Wisp selected |
| `wisp_select_hint` | Left-click a Wisp, then right-click a gather spot or the Manatree. |
| `wisp_assign_prompt` | Assign Wisp |
| `wisp_assign_hint` | Right-click a harvest spot or the Manatree. |
| `wisp_assign_to_tree` | Gather Wood |
| `wisp_assign_to_stone` | Gather Stone |
| `wisp_assign_to_berry` | Gather Food |
| `wisp_assign_to_manatree` | Gather Manashards |
| `wisp_assign_ok` | The Wisp drifts to work. |
| `wisp_assign_manatree_ok` | The Wisp circles the Manatree, drawing Manashards. |
| `wisp_reassign_ok` | The Wisp finds a new place to gather. |
| `wisp_assign_busy` | *(retired — multi-wisp per node)* |
| `wisp_assign_manatree_busy` | *(retired — multi-wisp per node)* |
| `wisp_assign_join_ok` | Another Wisp joins the work. |
| `wisp_assign_full` | *(retired)* |
| `wisp_unassign` | Call back |
| `wisp_unassign_ground` | Right-click empty ground to call the Wisp back. |
| `wisp_unassign_ok` | The Wisp returns to your side. |
| `wisp_gathering_hud` | Gathering {item}… |
| `wisp_idle_hud` | Nearby |
| `wisp_assigned_hud` | Orbiting {target} |
| `wisp_orbit_hint` | Idle Wisps orbit the Keeper. Assigned Wisps orbit their node. |
| `wisp_none` | No Wisps yet — advance the Manatree, or buy Extra Wisp. |
| `wisp_full` | All Wisps are busy. |
| `wisp_node_shared_hint` | Several Wisps may share one spot — each pulses on its own. |

---

## 7e. Ascension Wisp blessings (shop — Manashards)

Locked Design ids (`SYSTEMS_V01` v0.3.0).

| upgrade_id | Display | Description |
|------------|---------|-------------|
| `wisp_haste` | Swift Wisps | Assigned Wisps gather a little sooner. |
| `bonus_wisp` | Extra Wisp | Another Wisp walks with you from the Sapling. |

| key | string |
|-----|--------|
| `upgrade_wisp_haste_name` | Swift Wisps |
| `upgrade_wisp_haste_desc` | Assigned Wisps gather a little sooner. |
| `upgrade_bonus_wisp_name` | Extra Wisp |
| `upgrade_bonus_wisp_desc` | Another Wisp walks with you from the Sapling. |

## 8. Out of v0.1 (do not ship strings for)

Echo Chamber **v2+**, companion body in combat, Forge **realm/interior**, Manaforge-as-place name, multi-zone travel, prompts on decorative trees. (Echo Chamber v1 portal fight + Enter Forge stub in-scope as of v0.6.0.)

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



---

## 9. Backpack & Handcraft (v0.4.0 — LIVE)

Resource **HUD** = Wood / Stone / Food / Manashards / Essence.  
**Backpack** = crafted only (intermediates, tools, Fertilizer).  
**Equipment** = Weapon / Relic (see §10). Backpack still crafts-only for tools/parts/Fertilizer.

### 9a. Backpack UI

| key | string |
|-----|--------|
| `backpack_title` | Backpack |
| `backpack_open` | Backpack |
| `backpack_empty` | Nothing crafted yet. |
| `backpack_hint` | Crafted goods live here — tools, parts, Fertilizer. |
| `backpack_tab_all` | All |
| `backpack_tab_tools` | Tools |
| `backpack_tab_materials` | Parts |

### 9b. Handcraft

| key | string |
|-----|--------|
| `handcraft_title` | Handcraft |
| `handcraft_prompt` | Craft |
| `handcraft_confirm` | Craft {item}? |
| `handcraft_confirm_yes` | Craft |
| `handcraft_confirm_no` | Not now |
| `handcraft_ok` | Crafted {item}. |
| `handcraft_cant_afford` | Need {costs}. |
| `handcraft_owned_unique` | You already carry one. |


| `handcraft_row_costs_only` | {costs} |
| `handcraft_row_watering_can_short` | Stone Fragments ×20 |
| `handcraft_row_wooden_basket_short` | Wooden Planks ×20 |
| `handcraft_row_fertilizer_short` | Wood ×{wood}, Stone ×{stone}, Food ×{food} |
| `handcraft_row_fertilizer_short_default` | Wood ×10, Stone ×10, Food ×10 |
| `tool_stone_watering_can_craft_cost` | Stone Fragments ×20 |
| `tool_wooden_basket_craft_cost` | Wooden Planks ×20 |

### 9c. Intermediate parts

| id | Display | Examine |
|----|---------|---------|
| `wood_plank` | Wood Plank | Smooth timber, ready for tools. |
| `stone_fragment` | Stone Fragment | A workable chip of stone. |
| `wood_rod` | Wood Rod | A straight stick for hafts and frames. |
| `stone_axe_head` | Stone Axe Head | A rough stone head for the Stone Axe. |
| `stone_pickaxe_head` | Stone Pickaxe Head | A rough stone head for the Stone Pickaxe. |
| `woven_fiber` | Woven Fiber | Twine for baskets and bindings. |

| key | string |
|-----|--------|
| `part_wood_plank` | Wood Plank |
| `part_stone_fragment` | Stone Fragment |
| `part_wood_rod` | Wood Rod |
| `part_stone_axe_head` | Stone Axe Head |
| `part_stone_pickaxe_head` | Stone Pickaxe Head |
| `part_stone_head` | Stone Head *(alias — prefer Axe/Pickaxe Head)* |
| `part_woven_fiber` | Woven Fiber |

### 9d. Tools (never gate gather; owned = faster Keeper channel)

| id | Display | Examine |
|----|---------|---------|
| `tool_stone_axe` | Stone Axe | Doubles how quickly you gather Wood while you hold it. |
| `tool_stone_pickaxe` | Stone Pickaxe | Doubles how quickly you gather Stone while you hold it. |
| `tool_wooden_basket` | Wooden Basket | Doubles how quickly you gather Food while you hold it. |
| `tool_stone_watering_can` | Stone Watering Can | Doubles Manashards from watering. Essence from water stays at the base rate. |

| key | string |
|-----|--------|
| `tool_owned_hint` | Tool owned — your hands work twice as fast at this. |
| `tool_wood_hint` | Stone Axe — Wood gathers faster. |
| `tool_stone_hint` | Stone Pickaxe — Stone gathers faster. |
| `tool_food_hint` | Wooden Basket — Food gathers faster. |
| `tool_water_hint` | Stone Watering Can — Manashards from watering come twice as fast. Essence rate unchanged. |
| `tool_never_gate` | Your hands always work — tools only hurry you. |
| `tool_wiped_on_ascend` | Crafted tools return to the forest on Ascend — unless Keep Tools is blessed. |

### 9e. Fertilizer

| id | Display | Examine |
|----|---------|---------|
| `fertilizer` | Fertilizer | Soft earth-care. Spent with Essence to Grow the Manatree. |

| key | string |
|-----|--------|
| `fertilizer_name` | Fertilizer |
| `fertilizer_hint` | Craft from Wood, Stone, and Food — no Manashards. Spent with Essence to Grow. |
| `fertilizer_craft_cost` | Wood ×{wood}, Stone ×{stone}, Food ×{food} |
| `fertilizer_craft_cost_default` | Wood ×10, Stone ×10, Food ×10 |
| `fertilizer_craft_ok` | Fertilizer ready. |
| `tree_grow_needs` | Fertilizer ×{fertilizer}, Essence ×{essence} |
| `tree_grow_needs_fertilizer` | Needs Fertilizer ×{count} and Essence ×{count}. |
| `tree_grow_cost_young` | Fertilizer ×3, Essence ×20 |
| `tree_grow_cost_mature` | Fertilizer ×6, Essence ×40 |
| `tree_grow_cost_elder` | Fertilizer ×12, Essence ×60 |
| `tree_grow_cost_ancient` | Fertilizer ×24, Essence ×80 |

### 9f. Grow CTA (Manatree)

Primary stage-advance label is **Grow** (aliases `tree_pay*` → Grow).

| key | string |
|-----|--------|
| `tree_grow` | Grow |
| `tree_grow_hint` | Spend Fertilizer and Essence to Grow the Manatree. |
| `tree_grow_confirm` | Grow into {next_stage}? |
| `tree_grow_confirm_yes` | Grow |
| `tree_grow_confirm_no` | Not yet |
| `tree_grow_ok` | The Manatree becomes {next_stage}. |
| `tree_grow_cant_afford` | Not enough yet — {costs} |
| `tree_grow_ready` | Ready to Grow |

### 9g. Keep Tools (Ascension blessing)

| upgrade_id | Display | Description |
|------------|---------|-------------|
| `keep_tools` | Keep Tools | Finished tools survive Ascend and return with you. |

| key | string |
|-----|--------|
| `upgrade_keep_tools_name` | Keep Tools |
| `upgrade_keep_tools_desc` | Finished tools survive Ascend and return with you. |
| `upgrade_keep_tools_cost` | {cost} Manashards |
| `upgrade_keep_tools_cost_default` | 3000 Manashards |
| `upgrade_keep_tools_tooltip` | Finished tools survive Ascend and return with you. |
| `upgrade_keep_tools_toast` | Your tools remember the path. |
| `keep_tools_regrant_toast` | Familiar tools settle back into your backpack. |
| `backpack_wiped_toast` | Crafted goods return to the forest. |
| `backpack_wiped_keep_tools_toast` | Crafted parts return to the forest — your tools remain. |




---

## 10. Character sheet, Runestones & equipment (v0.5.0 — LIVE)

Haex GREENLIGHT 2026-09-21. Stats + Runestone spend + first Weapon craft are **live strings**. Echo Chamber combat still later.  
**Currency:** Runestone spends use the **same Manashard pool** as the Ascension blessing shop (bank-vs-spend). Stats/gear **persist** across Ascend; soft mats / unspent shards still wipe on Ascend per live rules.  
Ids locked to SYSTEMS **v0.5.0** (Design mid-flight confirm). Stats match VISION. Gear inventory ≠ backpack.

### 10a. Character sheet UI

| key | string |
|-----|--------|
| `char_sheet_title` | Keeper |
| `char_sheet_open` | Character |
| `char_sheet_hint` | Your lasting strength — raised at Runestones, worn as gear. |
| `char_sheet_stats_header` | Stats |
| `char_sheet_equip_header` | Equipment |
| `char_sheet_close` | Close |

### 10b. Seven core stats (VISION)

Display rule (SYSTEMS v0.5.1): each stat **starts at base 5**; sheet shows `5 + Runestone ranks` (not from 0). Player strings use `{value}` / `{rank}` tokens only — no zero-start copy.

| id | Display | Short / tooltip |
|----|---------|-----------------|
| `might` | Might | Physical Attack |
| `arcana` | Arcana | Magical Attack |
| `resilience` | Resilience | Physical Resistance |
| `ward` | Ward | Magical Resistance |
| `vitality` | Vitality | Health and survivability |
| `swiftness` | Swiftness | Speed |
| `fate` | Fate | Luck, crit chance, rare finds |

| key | string |
|-----|--------|
| `stat_might` | Might |
| `stat_arcana` | Arcana |
| `stat_resilience` | Resilience |
| `stat_ward` | Ward |
| `stat_vitality` | Vitality |
| `stat_swiftness` | Swiftness |
| `stat_fate` | Fate |
| `stat_might_tooltip` | Physical Attack |
| `stat_arcana_tooltip` | Magical Attack |
| `stat_resilience_tooltip` | Physical Resistance |
| `stat_ward_tooltip` | Magical Resistance |
| `stat_vitality_tooltip` | Health and survivability |
| `stat_swiftness_tooltip` | Speed |
| `stat_fate_tooltip` | Luck, crit chance, rare finds |
| `stat_rank` | Rank {rank} |
| `stat_value` | {value} |
| `stat_value_breakdown` | {base} + {ranks} |
| `stat_base_note` | Starts at 5 — Runestones raise it further. |
| `stat_persist_hint` | Stats stay with you through Ascend. |

### 10c. Runestone spend (Manashards)

| key | string |
|-----|--------|
| `runestone_title` | Runestone |
| `runestone_prompt` | Raise a lasting stat |
| `runestone_hint` | Spend Manashards here to grow permanent stats. Unspent shards still feed the Ascension shop — then return to the forest. |
| `runestone_bank_hint` | Bank shards for Ascension blessings, or spend them here to grow stronger now. |
| `runestone_spend` | Raise {stat} |
| `runestone_confirm` | Spend {cost} Manashards to raise {stat}? |
| `runestone_confirm_yes` | Raise |
| `runestone_confirm_no` | Not now |
| `runestone_ok` | {stat} grows stronger. |
| `runestone_cant_afford` | Not enough Manashards |
| `runestone_cost` | {cost} Manashards |
| `runestone_maxed` | Fully raised for now |

### 10d. Equipment slots (SYSTEMS v0.5.0)

Slot ids: `weapon`, `relic`, `head`, `body`, `hands`, `pants`, `feet`, `cape`, `ring1`, `ring2`.  
**Start:** only **`weapon`** unlocked. All other slots locked (grey). **`relic`** stays locked until **Forge Key** (empty this ship).

| slot_id | Display | Start |
|---------|---------|-------|
| `weapon` | Weapon | Unlocked |
| `relic` | Relic | Locked — Forge Key |
| `head` | Head | Locked |
| `body` | Body | Locked |
| `hands` | Hands | Locked |
| `pants` | Pants | Locked |
| `feet` | Feet | Locked |
| `cape` | Cape | Locked |
| `ring1` | Ring | Locked |
| `ring2` | Ring | Locked |

| key | string |
|-----|--------|
| `equip_slot_weapon` | Weapon |
| `equip_slot_relic` | Relic |
| `equip_slot_head` | Head |
| `equip_slot_body` | Body |
| `equip_slot_hands` | Hands |
| `equip_slot_pants` | Pants |
| `equip_slot_feet` | Feet |
| `equip_slot_cape` | Cape |
| `equip_slot_ring1` | Ring |
| `equip_slot_ring2` | Ring |
| `equip_empty` | Empty |
| `equip_unequip` | Unequip |
| `equip_equip` | Equip |
| `equip_ok` | Equipped {item}. |
| `equip_unequip_ok` | Put away {item}. |
| `equip_locked` | Locked |
| `equip_locked_hint` | This slot is not open yet. |
| `equip_locked_relic` | Relic locked — needs a Forge Key. |
| `equip_locked_armor` | Not yet — the Forge still sleeps. |
| `equip_bare_stone` | Bare Stone |
| `equip_bare_stone_tooltip` | Empty hands — no weapon equipped. |
| `equip_no_item` | Nothing to equip. |

### 10e. Gear inventory (≠ backpack)

Crafted tools / Fertilizer / parts stay in **Backpack**. Weapons and later armor/relics live in **Gear**.

| key | string |
|-----|--------|
| `gear_title` | Gear |
| `gear_open` | Gear |
| `gear_empty` | No gear yet. |
| `gear_hint` | Weapons and worn gear live here — separate from your Backpack. |
| `gear_tab_weapons` | Weapons |
| `gear_tab_all` | All |

### 10f. First weapons (craft / equip)

| id | Display | Examine / equip tooltip |
|----|---------|-------------------------|
| `weapon_rod` | Weapon Rod | A simple wooden rod — your first lasting weapon. |
| `stone_sword` | Stone Sword | A crude stone blade. Hits a little harder than a rod. |

| key | string |
|-----|--------|
| `weapon_rod_name` | Weapon Rod |
| `weapon_rod_tooltip` | A simple wooden rod — your first lasting weapon. |
| `stone_sword_name` | Stone Sword |
| `stone_sword_tooltip` | A crude stone blade. Hits a little harder than a rod. |
| `stone_sword_craft_cost` | Stone Fragments ×30, Weapon Rod ×1 |
| `stone_sword_craft_cost_default` | Stone Fragments ×30, Weapon Rod ×1 |
| `weapon_craft_ok` | Crafted {item}. |
| `weapon_persist_hint` | Weapons stay with you through Ascend. |
| `relic_locked_tooltip` | Relics come later — when you hold a Forge Key. |

### 10g. Character sheet open (HUD + C)

| key | string |
|-----|--------|
| `char_sheet_hotkey_hint` | C — Character |
| `hud_btn_character` | Character |

### 10h. Manatree display scales (D7 — LIVE visual note)

Visual-only (Art/Code). No player-facing strings. **Live with v0.5:** sapling **0.5×**, young **1×**, mature **2×**, elder **2×**, ancient **1.5×**. Canvases unchanged.




---

## 11. Echo Chamber v1 (LIVE — Haex GO 2026-09-22)

Scope this ship: portal after first Ascend → pay **30 Essence** once → 1v1 vs **Elaia** (`echo_keeper_01`) → Strike / Flee / Spare (&lt;10% HP, no Flee in mercy window) → Key both endings, companion flag Spare-only → save flags (SAVE **8**). Mid-fight HP not saved. Bare fists 0 damage (sword gate). Mercy floor + T1 no-KO. Battle music silence.  
**Not this ship:** companion body in combat, 3v1, Cast/items/Guard, Forge interior/realm, Echo 2+, type chart, Wisps in combat.  
**Forge entry:** Manatree care **Enter Forge** only — no world door.

### 11a. Enemy

| id | Display | Examine / battle subtitle |
|----|---------|---------------------------|
| `echo_keeper_01` | Elaia | An echo of a Keeper who came before — cool and quiet. |

| key | string |
|-----|--------|
| `echo_elaia_name` | Elaia |
| `echo_elaia_subtitle` | Keeper’s Echo |
| `echo_elaia_examine` | An echo of a Keeper who came before — cool and quiet. |

### 11b. Portal

| key | string |
|-----|--------|
| `portal_title` | Echo Chamber |
| `portal_prompt` | Step through? |
| `portal_hint` | A quiet threshold after Ascend. Pay Essence once to enter. |
| `portal_fee` | Essence ×{cost} |
| `portal_fee_default` | Essence ×30 |
| `portal_confirm` | Spend {cost} Essence to enter the Echo Chamber? |
| `portal_confirm_yes` | Enter |
| `portal_confirm_no` | Not now |
| `portal_cant_afford` | Not enough Essence — need {cost}. |
| `portal_denied` | The portal stays closed. |
| `portal_reentry_free` | The way is open — enter freely. |
| `portal_enter_ok` | You step through. |

### 11c. Battle UI

| key | string |
|-----|--------|
| `battle_title` | Echo Chamber |
| `battle_vs` | vs {enemy} |
| `battle_strike` | Strike |
| `battle_flee` | Flee |
| `battle_spare` | Spare |
| `battle_your_turn` | Your turn |
| `battle_enemy_turn` | {enemy} acts… |
| `battle_hp` | HP {current}/{max} |
| `battle_mercy_hint` | {enemy} falters — Spare or Strike. |
| `battle_fists_toast` | Bare hands cannot harm an echo — equip a weapon. |
| `battle_flee_ok` | You leave the Chamber. |
| `battle_save_disabled` | Cannot save during battle. |
| `battle_paused_hint` | Leaving now counts as Flee. |

### 11d. Outcomes (KO / Spare / Defeat — no flavour lines; UI toasts only)

| key | string |
|-----|--------|
| `battle_spare_ok` | You spare {enemy}. |
| `battle_defeat_ok` | {enemy} fades. |
| `battle_key_grant` | A Forge Key settles into your keeping. |
| `battle_companion_flag` | A quiet companion-bond stirs — for later. |
| `battle_shards_gain` | +{amount} Manashards |
| `battle_reward_toast` | {rewards} |

### 11e. Enter Forge (Manatree care menu)

| key | string |
|-----|--------|
| `forge_enter` | Enter Forge |
| `forge_enter_hint` | Beyond the Manatree — when you hold a Key. |
| `forge_no_key` | You have no key. |
| `forge_not_built` | Not built yet. |
| `forge_locked_hint` | Needs a Forge Key. |
| `relic_slot_unlocked` | A relic niche opens. |

### 11f. Implementation notes for Code

- Keys above are player-facing; wire tokens `{enemy}` `{cost}` `{current}` `{max}` `{amount}` `{rewards}`.
- Display name for `echo_keeper_01` is always **Elaia**.
- Do not name Manaforge as a place on Forge/portal copy.
- Silence on KO/Spare/Defeat beat lines — toasts only; Audio owns hub stop/resume.


## DEFERRED notes (historical + park)

Partially promoted in **v0.4.0** (Grow live). Remaining historical deferred: Fruit shop Close-until-first-Buy → Ascend-only lock (still awaiting separate greenlight if not already live).

1. **Fruit shop preview can Close** — before first Buy, player may close the Ascension shop (preview). After first Buy, shop locks to Ascend-only (no soft Close).
2. **First Buy locks Ascend-only** — copy needed: shop still closable until first blessing purchase; then must Ascend.
3. **Manatree Grow** — **PROMOTED v0.4.0** (`tree_grow*` / `tree_pay*` alias Grow).

### Draft keys — Fruit soft-close (not live)

| key | draft string |
|-----|----------------|
| `fruit_shop_close` | Close |
| `fruit_shop_preview_hint` | Look over blessings — Close anytime until you buy. |
| `fruit_shop_locked_hint` | A blessing is yours — Ascend to continue. |
| `fruit_shop_first_buy_toast` | The path is set. Ascend when ready. |

---

### D6. Haex playtest backlog (2026-09-19 — **PROMOTED v0.4.1**)

Mirrors `SYSTEMS_V01` §11 D6. **PROMOTED to live in CONTENT v0.4.1** (Director session open 2026-09-19). Draft keys below kept as archive; live §9 / blessing tables are source.

| # | Change | Content park |
|---|--------|--------------|
| 1 | Stone Watering Can = **20 Stone Fragments**; Wooden Basket = **20 Wooden Planks** | Cost-line drafts below (drop Rod from Can unless Haex clarifies). |
| 2 | Handcraft UI overflow | Short **costs-only** row labels for Watering Can + Fertilizer (Code owns scroll/width). |
| 3 | Rename heads → **Stone Axe Head**, **Stone Pickaxe Head** | Split `stone_head` display; draft ids/labels below. |
| 4 | Keep Tools ≈ **3000** Manashards | Cost token draft; Design owns flat 3000. |
| 5 | Ascension blessing tooltips / short descriptions | Draft `*_tooltip` keys; live `*_desc` stay until promote. |
| 6 | Fertilizer steeper: craft **~2×**; Grow Fert **3 / 6 / 12 / 24** | Cost drafts; Essence curve TBD (keep live 20/40/60/80 until Haex). |

#### D6 draft keys (not live)

| key | draft string |
|-----|----------------|
| `tool_stone_watering_can_craft_cost_d6` | Stone Fragments ×20 |
| `tool_wooden_basket_craft_cost_d6` | Wooden Planks ×20 |
| `handcraft_row_costs_only` | {costs} |
| `handcraft_row_watering_can_short` | Stone Fragments ×20 |
| `handcraft_row_fertilizer_short` | Wood ×{wood}, Stone ×{stone}, Food ×{food} |
| `part_stone_axe_head` | Stone Axe Head |
| `part_stone_pickaxe_head` | Stone Pickaxe Head |
| `part_stone_axe_head_examine` | A rough stone head for the Stone Axe. |
| `part_stone_pickaxe_head_examine` | A rough stone head for the Stone Pickaxe. |
| `upgrade_keep_tools_cost` | {cost} Manashards |
| `upgrade_keep_tools_cost_default` | 3000 Manashards |
| `upgrade_tooltip_hint` | {desc} |
| `upgrade_keep_tools_tooltip` | Finished tools survive Ascend and return with you. |
| `upgrade_wisp_haste_tooltip` | Assigned Wisps gather a little sooner. |
| `upgrade_bonus_wisp_tooltip` | Another Wisp walks with you from the Sapling. |
| `fertilizer_craft_cost_default_d6` | Wood ×10, Stone ×10, Food ×10 |
| `tree_grow_cost_young_d6` | Fertilizer ×3, Essence ×{essence} |
| `tree_grow_cost_mature_d6` | Fertilizer ×6, Essence ×{essence} |
| `tree_grow_cost_elder_d6` | Fertilizer ×12, Essence ×{essence} |
| `tree_grow_cost_ancient_d6` | Fertilizer ×24, Essence ×{essence} |

Promoted 2026-09-19 → live v0.4.1. Ping Code.

v0.4.0: Backpack, Handcraft, tools, Grow, Keep Tools, Fertilizer. **v0.4.1:** D6 string promote.

### D3 → LIVE pointer (v0.5.0 / Echo v0.6.0)

Character sheet / stats / gear **§10**. Echo Chamber v1 portal fight + Enter Forge stub + Forge Key grant **§11**. Forge realm/interior + companion body + Echo 2+ still deferred.

### D7. Manatree display scales — LIVE (visual)

See §10h. No Content strings. Art/Code scale Manatree by stage.

