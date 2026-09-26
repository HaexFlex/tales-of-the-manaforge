# Tales of the Manaforge — Systems Brief v0.6 (Restart Edition)
**Owner:** Game Design  
**Status:** v0.6.1 — Haex Echo polish: Forge Key relic (+2 Swift/+2 Fate); Enter Forge Elder+Ancient only  
**Source of truth above this doc:** `VISION_RESTART.md` + `refs/`  
**Non-canon:** `DESIGN.md` (idle-combat), forge-hub art kit, battle audio drafts  
**Audience:** Code implements; Content names strings; Art / layout for Code  
**Last updated:** 2026-09-22

**Art locks (Haex):** Keeper 128², tiles 64², 1280×720 NN  
**Tone (Haex):** warm + lightly melancholic

---

## Changelog

| Ver | Change |
|-----|--------|
| v0.1.x | Harvest channels, water income, growth bar, offers, 7 save slots — see git history / prior copies |
| v0.2.0 | Needs-only stages; no growth/offers; SAVE_VERSION 4 — **SUPERSEDED by v0.4.0** |
| v0.2.1 | Spend-essence blessing shop (superseded) |
| v0.2.2 | Pick-one-free Ascension (superseded) |
| v0.2.3 | Manashard blessing shop → Ascend |
| v0.2.4 | Manashard shop Ascension-only |
| v0.2.5 | Manashard shop SHOP_BASE=400 (~1–2 ranks/Ascension) |
| v0.3.0 | Wisps + select-then-move + wisp blessings; SAVE_VERSION 5 |
| v0.3.1 | Keeper select-gated actions; unassigned wisps orbit Keeper |
| v0.3.2 | LMB/RMB; wisps orbit target; Manatree→manashards |
| v0.3.3 | Two-step Fruit; paused separate shop; no cancel |
| v0.3.4 | **Haex:** **Multi-wisp per target**; Ascend `essence → 0` + soft-mat wipe; Manashards → 0 |
| v0.3.4 note | Soft-open Ascension + Grow CTA were deferred — Grow CTA **LIVE in v0.4.0**; soft-open still deferred (§11 D1) |
| v0.3.4 note | Equipment & Stats mid-term discuss park (§11 D3) — **GREENLIT foundation → live v0.5.0** |
| v0.3.4 note | Draft: abandon needs-only → Fertilizer + Essence — **GREENLIT → live v0.4.0** |
| **v0.4.0** | **Haex GREENLIGHT:** Abandon needs-only. Stage advance = one-click **Grow** (Fertilizer + Essence). Water still Manashards + Essence; Stone Watering Can doubles Manashard amount/pulse only. Backpack (crafts only) + handcrafting + 4 unique tools (Keeper 2× channel only). Fertilizer recipe wood+stone+food (no shards). Blessing `keep_tools`; `green_thumb` → Fertilizer craft ingredient costs −10%/rank. Ascend wipes backpack (Keep Tools re-grants 4 tools). `SAVE_VERSION` **6**. |
| v0.4.0 note | Playtest backlog was PARKED pending next coding session — **GREENLIT → live v0.4.1** (§11 D6). |
| **v0.4.1** | **Haex D6 LIVE (coding session OPENED):** Can recipe = **20 Stone Fragments** only; Basket = **20 Wooden Planks**. Handcraft UI: Watering Can + Fertilizer rows **costs only**; fix scroll vs panel width. Rename heads → **Stone Axe Head**, **Stone Pickaxe Head**. `keep_tools` = **3000** Manashards flat (max 1). Ascension shop rows show **short description / tooltip**. Fert craft ~2× (`FERT_* = 10`); Grow Fertilizer **3 / 6 / 12 / 24**; Keep Essence **20 / 40 / 60 / 80**. Same PR Code notes: arrow-key camera clamped to play bounds; map ~**2×W × 3×H**; dense decorative trees + bushes; collision bottom-third trunks / bush bottom-center; no edge-scroll yet. `SAVE_VERSION` stays **6** (number-only retunes; no backpack schema change). |
| v0.4.1 note | **PARK → LIVE in v0.5.0:** Manatree display scales (stage1 0.5×, stage2 default, stage3+4 2×, stage5 1.5×). See §4 + §11 D7. |
| **v0.5.0** | **Haex GREENLIGHT 2026-09-21:** Character sheet / Stats / Equipment foundation + D7 Manatree scales **LIVE**. Seven combat stats via world Runestones (Manashards spend, steep exponential PLACEHOLDER curve); stats persist through Ascend. Equipment slots (weapon unlocked; others locked; relic locked until Forge Key — empty this ship). Gear inventory separate from backpack. Craftable: Weapon Rod + Stone Sword only. Character sheet UI (HUD + **C**). Persist equipped + gear inventory through Ascend (like stats). Soft mats + backpack still wipe; Keep Tools tools-only. D7 Manatree display scales live (visual only). `SAVE_VERSION` **7**. Full Echo combat / Forge Key / other gear recipes still deferred. |
| v0.5.0 note | Out of scope this ship: combat, Forge Key, other equipment recipes, Runestone non-Manashard currency, Fate gather effects. |
| **v0.5.1** | **Haex overnight polish:** All 7 combat stats **base start at 5**. Sheet display: `base = STAT_BASE_START + runestone_ranks` (+ gear = total). SAVE migrate: unset→5 / floor displayed base at 5. Character sheet UI polish only otherwise. `SAVE_VERSION` stays **7** (migrate rule). |
| **v0.6.0** | **Haex GO 2026-09-22:** **Echo Chamber v1 LIVE.** Portal after first Ascension (30 Essence fee once until win or KO loss; flee keeps fee; Ascend-while-fee-paid free re-entry). 1v1 vs `echo_keeper_01` display **Elaia**; Strike / Flee / Spare (<10% HP, Spare+Strike only). Formulas LOCKED (reuse KeeperStats + Equipment; HP=10×Vitality; raw=(atk−def)×10; crit Fate×1%; mercy floor; T1 protection). Rewards: spare/defeat Manashard payouts from Runestone cost curve on **stored ranks**; both wins grant `forge_key` → unlock **relic** slot; Spare sets `echo_01_redeemed`. Enter Forge = Manatree care-menu button only (no key → popup; with key → “not built yet”). `SAVE_VERSION` **8**. Echo 2+ / companion body / Forge realm / Cast/items/Guard still Out. |
| **v0.6.1** | **Haex Echo polish:** Forge Key relic **+2 Swiftness +2 Fate** (`forge_key_relic`); **Enter Forge** only at **Elder + Ancient** (hidden earlier); Key popup **“Congratulations, you finished the Trial! What secrets await you in the Forge? Stay tuned.”** Battle UI: big Keeper idle left / Elaia right. SAVE_VERSION stays **8**. |

---

## v0.6 scope (systems only)

**In:** select-then-move Keeper, **Fertilizer Grow** stages (Fertilizer + Essence), channelled harvest (3 nodes), Wisps (AFK node gather), water income (shards + essence), **backpack + handcrafting** (intermediates, tools, Fertilizer), **unique tools** (Keeper channel 2× only), Primordial Fruit / Manashard Ascension shop (incl. `keep_tools`), pause + 7 slots, versioned save (`SAVE_VERSION` **8**), minimal HUD (soft mats + shards + essence; backpack separate), **character sheet** (HUD + **C**), **seven combat stats** + **Runestones** (Manashard spend), **equipment foundation** (slots + gear inventory + Weapon Rod / Stone Sword), **D7 Manatree display scales**, **Echo Chamber v1** (portal + 1v1 battle + rewards), **Forge Key relic** (+2 Swift/+2 Fate), **Enter Forge** Elder/Ancient only (“Congratulations, you finished the Trial! What secrets await you in the Forge? Stay tuned.”).

**Out:** needs-only soft-mat stage pay (**SUPERSEDED**), growth bar / offers, **Echo 2+**, **companion body / companion in combat**, **3v1**, **Cast / items / Guard**, **Forge interior / Forge realm**, other battle-gear recipes, Runestone non-Manashard currency, Fate gather effects, type chart, Wisps in combat, WASD, mobile/web, many duplicate harvestables. Tools never gate gather; tools never multiply wisp pulses.

---

## 1. Resources

| ID | How gained | How spent |
|----|------------|-----------|
| `wood` | Harvest Tree @ 1/sec (Keeper; 2× channel speed if Stone Axe owned) | **Fertilizer craft** (+ tool/intermediate craft) — **not** stage needs |
| `stone` | Stone node @ 1/sec (Keeper; 2× if Stone Pickaxe) | **Fertilizer craft** (+ tool/intermediate craft) |
| `food` | Berry bush @ 1/sec (Keeper; 2× if Wooden Basket) | **Fertilizer craft** (+ tool/intermediate craft) |
| `manashards` | Water channel `U{1,3}` / sec (×2 amount/pulse if Stone Watering Can); **wisp on Manatree** @ 1/10s | **Blessing shop** (Ascension permanent upgrades) **and Runestones** (mid-run permanent combat stats — §4e). Same pool = bank-vs-spend dilemma |
| `essence` | Water channel `+1` / sec (base; Can does **not** boost); Fruit harvest bonus unused | **Grow** stage advance (with Fertilizer); **Echo Chamber portal fee** (30 once — §4f) — not blessing shop |
| `fertilizer` | Handcraft (wood + stone + food) | **Grow** stage advance (with Essence) |

Soft mats live on the **resource HUD**. Fertilizer, intermediates, and tools live in the **backpack** (§4d). **Battle gear** lives in **gear inventory** (separate from backpack — §4e).

---

## 2. Harvest nodes (LOCKED — Haex)

Exactly **three** interactive harvest nodes. Channel @ 1 resource/sec while in range (base). Owning the matching tool → **half Keeper channel wait** (effective 2/sec); yield per pulse unchanged. **Never gate gather** — nodes always usable without tools. **Tools never affect wisp pulses.**

| node_id | Resource | Rate (base) | Matching tool |
|---------|----------|-------------|---------------|
| `harvest_tree` | `wood` | `HARVEST_WOOD_PER_SEC = 1` | Stone Axe |
| `harvest_stone` | `stone` | `HARVEST_STONE_PER_SEC = 1` | Stone Pickaxe |
| `harvest_berry` | `food` | `HARVEST_FOOD_PER_SEC = 1` | Wooden Basket |

`CHANNEL_PULSE_SEC = 1.0`, `HARVEST_RANGE_PX = 48`.  
Layout: dense **decorative** trees; **one** of each harvest node; Manatree landmark separate.

When matching tool owned (Keeper channel only):
```
effective_pulse_sec = CHANNEL_PULSE_SEC * 0.5   # half wait between yields
# yield per pulse unchanged (= 1 * gather_mult)
```

---

## 3. Water channel (income only)

```
each CHANNEL_PULSE_SEC while watering and in range:
  shard_roll = randi_range(WATER_SHARD_MIN, WATER_SHARD_MAX) + shard_sight_rank
  if owns_stone_watering_can:
    shard_roll *= 2   # PLACEHOLDER — prefer double Manashard amount per pulse
  manashards += shard_roll
  essence    += WATER_ESSENCE_PER_SEC   # ALWAYS base; Can does NOT affect Essence
  # NO growth
```

| Param | Default |
|-------|---------|
| `WATER_SHARD_MIN` | `1` |
| `WATER_SHARD_MAX` | `3` |
| `WATER_ESSENCE_PER_SEC` | `1` |

**Stone Watering Can (LOCKED):** boosts **Manashard side of watering only**. Implement prefer: **double Manashard amount per pulse** (`shard_roll * 2`) while Essence stays `+WATER_ESSENCE_PER_SEC` each full `CHANNEL_PULSE_SEC`. (Alt considered then rejected for Code simplicity: half pulse for shards only / extra shard roll — prefer amount double.) **PLACEHOLDER** — tune later; retune shard economy when shipping.

At Ancient: water still pays income; Fruit/Ascend is a separate confirm.  
**Removed:** `WATER_GROWTH`, growth pulses, offer-for-growth.

---

## 4. Stage Grow (LOCKED — Haex v0.4.0 GREENLIGHT)

**Needs-only (v0.2.0) SUPERSEDED.** No `growth` field. No growth bar. No soft-mat stage pay.

**Stage advance = one-click Grow** when costs met: spend **Fertilizer + Essence** → next stage. CTA label **Grow** (not Pay). Show Fertilizer + Essence costs on the control.

### Grow cost curve (PLACEHOLDER — v0.4.1 live numbers)

Essence curve kept (20 / 40 / 60 / 80); Fertilizer count steeper **3 / 6 / 12 / 24** (Haex D6).

| Advance to | Fertilizer | Essence | Notes |
|------------|------------|---------|-------|
| `young` | **3** | **20** | PLACEHOLDER v0.4.1 |
| `mature` | **6** | **40** | PLACEHOLDER v0.4.1 |
| `elder` | **12** | **60** | PLACEHOLDER v0.4.1 |
| `ancient` | **24** | **80** | PLACEHOLDER v0.4.1 |

```
# Named params (Code data table) — PLACEHOLDER v0.4.1
GROW_YOUNG   = { fertilizer: 3, essence: 20 }
GROW_MATURE  = { fertilizer: 6, essence: 40 }
GROW_ELDER   = { fertilizer: 12, essence: 60 }
GROW_ANCIENT = { fertilizer: 24, essence: 80 }
```

**Sapling** (start): no Grow cost.  
**Grow action:** single one-click confirm when both Fertilizer and Essence costs met; consume both → advance stage; partial progress is inventory only (no partial bank toward stage).

### Stage bonuses (kept)

| stage_id | Bonus while here |
|----------|------------------|
| `sapling` | — |
| `young` | `gather_mult = 1.1` |
| `mature` | `gather_mult = 1.25` |
| `elder` | `gather_mult = 1.4` |
| `ancient` | `gather_mult = 1.6`; Fruit ready |

### Manatree display scales (LOCKED — Haex D7 LIVE v0.5.0)

Visual only — **no** Grow cost / bonus change. Scale Manatree sprite (or root) by `stage_id`. Interaction / collision must stay fair at extreme scales (0.5× and 2.0×).

| stage_id | Display scale |
|----------|---------------|
| `sapling` | **0.5×** |
| `young` | **1.0×** (default) |
| `mature` | **2.0×** |
| `elder` | **2.0×** |
| `ancient` | **1.5×** |

```
# Named params (Code) — LOCKED visual scales
MANATREE_SCALE_SAPLING = 0.5
MANATREE_SCALE_YOUNG   = 1.0
MANATREE_SCALE_MATURE  = 2.0
MANATREE_SCALE_ELDER   = 2.0
MANATREE_SCALE_ANCIENT = 1.5
```

### Pace note
Essence gate still matters early (20s water to Young at 1 essence/sec) plus craft **3** Fertilizer (`FERT_* = 10` each). Later stages need harvest → craft Fertilizer loops while watering for essence + shards. First Ancient is intentional multi-loop (24 Fertilizer).

### UI (Content + Code)
- Manatree click → panel: next stage name + Grow costs (`Fertilizer 0/3`, `Essence 12/20`, …) + **Grow** (enabled when both met; show costs on the control) + Water + **Enter Forge** (v0.6.1 — **Elder/Ancient only**; grayed without Key / “Congratulations, you finished the Trial! What secrets await you in the Forge? Stay tuned.” with Key — §4f).
- **No** growth X/Y bar. **No** soft-mat need lines. **No Pay** label. **No** world Forge door.

---

## 4d. Backpack & Handcrafting (LOCKED — Haex v0.4.0)

### Backpack vs HUD
- **Resource HUD:** wood / stone / food / manashards / essence (unchanged soft + currency display).
- **Backpack:** crafted items **only** — intermediates, finished tools, Fertilizer stacks. Not soft mats.

### Handcrafting
Instant craft (no station required for v0.4). Recipes consume from HUD soft mats (or backpack intermediates) → grant backpack item.

### Fertilizer recipe (LOCKED — no Manashards)

```
# PLACEHOLDER base costs (before prestige mult) — v0.4.1 ~2× craft
FERT_WOOD  = 10
FERT_STONE = 10
FERT_FOOD  = 10
# → grants 1 Fertilizer to backpack

effective_cost(ingredient) = max(1, floor(base * FERTILIZER_CRAFT_COST_MULT * green_thumb_mult))
# FERTILIZER_CRAFT_COST_MULT from blessings if any; default 1.0
# green_thumb_mult = (1.0 - 0.10 * green_thumb_rank)  — see §5; floor 1 per ingredient
```

Prestige craft-cost multiplier param name: `FERTILIZER_CRAFT_COST_MULT` (default `1.0`; wire from blessings if/when a prestige craft-cost blessing exists — none in v0.4 besides `green_thumb` ingredient reduction).

### Intermediate + tool recipes (PLACEHOLDER — Haex handcrafting write-up)

| Result | Ingredients | Notes |
|--------|-------------|-------|
| Wooden Planks | 3 Wood | intermediate |
| Stone Fragments | 3 Stone | intermediate |
| Wooden Tool Rod | 10 Planks | intermediate |
| **Stone Axe Head** | 10 Fragments | intermediate (rename v0.4.1) |
| **Stone Pickaxe Head** | 10 Fragments | intermediate (rename v0.4.1) |
| **Stone Axe** | 1 Rod + 1 Stone Axe Head | tool (unique) |
| **Stone Pickaxe** | 1 Rod + 1 Stone Pickaxe Head | tool (unique) |
| **Wooden Basket** | **20 Wooden Planks** | tool (unique); v0.4.1 |
| **Stone Watering Can** | **20 Stone Fragments** | tool (unique); v0.4.1 — fragments only (no Rod) |
| **Fertilizer** | 10 Wood + 10 Stone + 10 Food | stackable; see above; v0.4.1 |

All PLACEHOLDER numbers — tune later. **No Manashards** in any of these recipes. Battle-gear crafts (**Weapon Rod**, **Stone Sword**) live in **§4e** (gear inventory, not backpack).

### Handcraft UI (Code contract — v0.4.1)
- **Watering Can** and **Fertilizer** rows: show **costs only** (shorten labels; drop long names if they overflow).
- Fix **scroll vs panel width** overflow so recipe list stays inside the handcraft panel.

### Tools (LOCKED)

| tool_id | Matches | Effect when owned |
|---------|---------|-------------------|
| `stone_axe` | wood harvest | Keeper wood channel: half `CHANNEL_PULSE_SEC` (2× speed); yield/pulse unchanged |
| `stone_pickaxe` | stone harvest | same for stone |
| `wooden_basket` | food harvest | same for food |
| `stone_watering_can` | water | **double Manashard amount per water pulse**; Essence stays base |

Rules:
1. **Tools unique (own 1)** — cannot craft a second while owned; Design lean = inventory flag, not stack.
2. **Never gate gather** — harvest nodes always work without the tool.
3. Owning matching tool → **2× Keeper channel speed** only (half wait between yields).
4. **Keeper only — never multiply wisp pulses.**
5. Watering Can: Manashard side only (see §3).

### Ascend wipe (backpack)
On Ascend: **wipe entire backpack** (Fertilizer stacks, intermediates, tools) **unless** blessing `keep_tools` owned → **re-grant the 4 finished tools only** (not Fertilizer, not intermediates). Soft mats still wipe; essence → 0; manashards → 0 (existing).

**Do not wipe** combat stats, equipped gear, or gear inventory on Ascend — see §4e / §5.

---

## 4e. Character sheet / Stats / Equipment / Runestones (LOCKED — Haex GREENLIGHT v0.5.0; relic unlock via Echo v0.6.0)

Foundation for Echo Chamber combat power. Stats / equipment totals feed Echo Chamber v1 formulas (§4f). Further equipment recipes remain deferred (§11 D3).

### Seven combat stats (LOCKED)

| `stat_id` | Display |
|-----------|---------|
| `might` | Might |
| `arcana` | Arcana |
| `resilience` | Resilience |
| `ward` | Ward |
| `vitality` | Vitality |
| `swiftness` | Swiftness |
| `fate` | Fate |

- **`STAT_BASE_START = 5` (LOCKED Haex v0.5.1):** every combat stat starts at **5** before any Runestone spends.
- `keeper_stats[stat_id]` = Runestone ranks purchased (starts **0**).
- Each rank: **+1 flat** to that stat (gentle power).
- **Sheet display per stat:** `base + gear = total` where `base = STAT_BASE_START + keeper_stats[stat_id]` and `gear` = sum of flat bonuses from equipped items.
- **SAVE migrate (v7):** for each of the seven stats, if unset/missing → treat ranks as 0 (base displays 5); if an older absolute value was stored below 5 → **floor base at 5** (do not wipe ranks above 5).
- **Persist through Ascend.** Unspent Manashards still wipe on Ascend.
- **Out of scope this ship:** Fate gather effects (no Fate → harvest/wisp side effects).

### Runestones (LOCKED)

- **One world Runestone per stat** → **7 interactables** on the map (layout Code/Art).
- Interact (Keeper selected + RMB / in-range) → prompt to spend Manashards for next rank of that stat.
- Currency: **same Manashard pool** as Ascension blessing shop — intentional **bank-vs-spend** dilemma.
- Cost curve: **steep exponential** (PLACEHOLDER — tune later).

```
# PLACEHOLDER named params — propose / document; tune later
RUNESTONE_BASE   = 100
RUNESTONE_GROWTH = 1.65
# Next-point cost when current rank is `rank` (0→1 costs BASE):
cost(rank) = floor(RUNESTONE_BASE * RUNESTONE_GROWTH^rank)
# Examples: 0→1: 100 | 1→2: 165 | 2→3: 272 | 3→4: 449 | 4→5: 741 | …
```

Rules:
1. Spend succeeds only if `manashards >= cost(current_rank)`; then deduct shards, `keeper_stats[stat_id] += 1`.
2. Stats are **not** blessing `upgrades` — do **not** overload `upgrade_ranks` / Ascension shop for combat stats.
3. No Runestone non-Manashard currency this ship.

### Equipment slots (LOCKED — UI order)

| Order | `slot_id` | Start state |
|-------|-----------|-------------|
| 1 | `weapon` | **Unlocked** |
| 2 | `relic` | **Locked** until Echo win grants Forge Key; then unlocked and holds **Forge Key relic** (+2 Swiftness +2 Fate) — §4f |
| 3 | `head` | Locked (grey) |
| 4 | `body` | Locked (grey) |
| 5 | `hands` | Locked (grey) |
| 6 | `pants` | Locked (grey) |
| 7 | `feet` | Locked (grey) |
| 8 | `cape` | Locked (grey) |
| 9 | `ring1` | Locked (grey) |
| 10 | `ring2` | Locked (grey) |

- **Start:** only **`weapon` unlocked**; all others **locked (grey) / non-interactive**.
- **`relic` unlocks** when Echo win grants Forge Key (Spare or Defeat). Grants gear item **Forge Key relic** (`forge_key_relic`): **+2 Swiftness +2 Fate** (LOCKED Haex v0.6.1). Auto-equip to `relic` if empty, else land in gear inventory. Persists Ascend with other gear.
- Unlock path for other slots: **deferred**. Locked slots remain grey.

### Gear inventory vs backpack (LOCKED)

- **Gear inventory** = battle gear bag (equippable items) — **separate** from backpack.
- **Backpack** = crafted forage / tools / Fertilizer / intermediates (§4d) — unchanged.
- Click + drag equip from gear inventory → unlocked slots only. Locked slots reject drop / non-interactive.

### Craftable battle gear this ship (PLACEHOLDER recipes)

| Result | Ingredients | Notes |
|--------|-------------|-------|
| **Weapon Rod** | **10 Wooden Planks** | New intermediate (battle path; distinct from Wooden Tool Rod). PLACEHOLDER — Design lean 10 Planks. |
| **Stone Sword** | **30 Stone Fragments + 1 Weapon Rod** | Equips to **`weapon`** slot; flat Might PLACEHOLDER e.g. **+2 Might**. |

- **No other battle gear recipes** this ship.
- Craft via handcraft (or same craft UI with gear results routing to **gear inventory**, not backpack). Code: grant `stone_sword` / `weapon_rod` into gear inventory (Weapon Rod may live as craft intermediate in gear bag or a craft-only staging key — prefer gear inventory / craft consume-on-Sword so bag stays battle-focused; Design lean: Weapon Rod is craft intermediate consumed into Sword; if held, store in gear inventory).
- Equipped Stone Sword contributes `+2` Might (PLACEHOLDER) to gear side of sheet total.

```
# PLACEHOLDER — Code data
WEAPON_ROD_COST_PLANKS = 10
STONE_SWORD_COST = { stone_fragments: 30, weapon_rod: 1 }
STONE_SWORD_BONUS = { might: 2 }   # flat gear bonus while equipped
```

### Character sheet UI (LOCKED — Code contract)

- **Open:** HUD button + hotkey **C**.
- **Layout:**
  - **Left:** Keeper idle + body-aligned equipment slots (order above).
  - **Middle:** gear inventory.
  - **Right:** stats showing `base + gear = total` per stat.
- Locked slots: **grey / non-interactive**.
- Art: ColorRects OK this ship; sheet layout / slot chrome later — **no mandatory gen**.

### Ascend persist (LOCKED — Design default v0.5.0; Echo flags v0.6.0)

| Persist through Ascend | Wipe on Ascend (existing) |
|------------------------|---------------------------|
| Combat stat ranks (`keeper_stats`) | Soft mats (wood/stone/food) |
| Equipped gear dict | Manashards → 0; Essence → 0 |
| Gear inventory | Backpack (Fertilizer, intermediates, tools) unless `keep_tools` → re-grant 4 tools only |
| Blessing upgrade ranks | Wisps reset per §4c |
| `forge_key` + relic unlock state | Mid-run soft mats / currencies (as existing) |
| `echo_01_resolved` / `echo_01_redeemed` | — |
| `portal_unlocked` (or derive from `ascensions >= 1`) | — |
| `portal_fee_paid` (if Echo not yet resolved) | — (Ascend-while-fee-paid → free re-entry intentional) |

Greenlight said stats persist; did **not** say wipe gear → **persist equipped + gear inventory** (battle power across Ascensions), like stats. Soft mats + backpack (tools/fert) still wipe per existing rules; Keep Tools still for tools only. Echo Key / redeemed / resolved / relic unlock / fee-paid **persist** Ascend.

### Code contracts (summary)

```
keeper_stats: Dictionary[String, int]  # might/arcana/…/fate ranks; default 0
equipment_unlocked: Dictionary[String, bool]  # weapon true; others false at start; relic false
equipment_equipped: Dictionary[String, String|null]  # slot_id → item_id or null
gear_inventory: Dictionary[String, int]  # battle items (e.g. stone_sword, weapon_rod)
# Runestone interactables: 7 world nodes keyed by stat_id
# Sheet: HUD button + InputMap "character_sheet" (C)
# Total for stat: keeper_stats[id] + sum(gear bonuses from equipped)
```

---

## 4f. Echo Chamber v1 (LOCKED — Haex GO v0.6.0)

**Source of truth for combat this ship:** Echo Chamber v1 Implementation Brief (locks below). Align stats/equipment with §4e (v0.5.1). Placeholders labeled where noted.

### Portal (LOCKED)

- Appears after first Ascension: `ascensions >= 1` / `portal_unlocked`.
- Fee **30 Essence** paid **once** until win or KO loss.
  - **Flee** keeps fee paid (re-enter free).
  - **KO loss** clears fee (must pay again to re-enter).
  - **Win** (Spare or Defeat) closes portal (`echo_01_resolved = true`).
- **Ascend-while-fee-paid** allowed; free re-entry intentional.
- Interact like Runestones (Keeper selected + RMB / in-range).

```
PORTAL_FEE_ESSENCE = 30
# Enter: if not portal_fee_paid and essence >= 30 → deduct 30, portal_fee_paid = true, enter battle
#        if portal_fee_paid → enter battle (no charge)
# Flee → exit battle; portal_fee_paid stays true
# KO loss → portal_fee_paid = false; exit battle
# Win → echo_01_resolved = true; portal closes; portal_fee_paid irrelevant
```

### Battle (LOCKED)

- **Separate scene**; **1v1** vs enemy id `echo_keeper_01`, display name **Elaia**.
- Actions: **Strike**, **Flee**; **Spare** only when enemy HP < 10% max HP.
- **Spare window:** once Spare available → **Spare + Strike only — no Flee**; fight paused; **no enemy turn** until player picks.
- Turn order: higher **Swiftness** first; tie → **Keeper first**.
- Enemy AI: every turn **one Arcana-vs-Ward hit** (no other actions).

### Formulas (LOCKED)

Reuse KeeperStats + Equipment totals from §4e:

```
# Per combatant:
# base_stat = STAT_BASE_START(5) + ranks + gear   # Keeper
# Elaia: fixed totals below (no ranks/gear)
HP_max = 10 × Vitality_total

# Damage
raw = (attack_stat − defense_stat) × 10
# no minimum; if raw ≤ 0 → 0 damage (bare-fists gate)
# Keeper Strike: Might vs Resilience
# Enemy hit:     Arcana vs Ward

# Crit
crit_chance = Fate_total × 1%   # e.g. Fate 5 → 5%
# Keeper crit multiplier: ×2
# Elaia crit multiplier:  ×1.2

# Mercy floor (Keeper hits only):
# If target HP > 10% max and damage would KO → set HP to 1. Crit does NOT bypass.

# T1 protection:
# Enemy cannot KO Keeper on turn 1 — floor Keeper HP to 1 if would KO.
```

**Elaia fixed stats (LOCKED):**

| Stat | Value |
|------|-------|
| Might | 4 |
| Arcana | 7 |
| Resilience | 5 |
| Ward | 7 |
| Vitality | 6 (**60 HP**) |
| Swiftness | 6 |
| Fate | 5 |

### Rewards (LOCKED)

Runestone cost on **stored ranks** (not display base):

```
cost(rank) = floor(100 * 1.65^rank)   # same RUNESTONE_BASE / GROWTH as §4e
```

Sort the **7 stats by rank desc**; ties break **might → arcana → resilience → ward → vitality → swiftness → fate**.

```
spare_shards  = cost(third_highest) × (1 + Fate_total / 100)
defeat_shards = (cost(highest) + cost(highest + 1)) × (1 + Fate_total / 100)
# Floor to int; no payout floor (0 OK if ranks tiny — rare)
```

| Outcome | Manashards | Other |
|---------|------------|-------|
| **Spare** (win) | `spare_shards` | `forge_key`; `echo_01_redeemed = true` (companion flag; **no companion body** this ship); portal closes |
| **Defeat** (KO win) | `defeat_shards` | `forge_key`; portal closes; **not** redeemed |
| **Flee** | nothing | fee stays paid |
| **KO loss** | nothing | fee clears |

Both wins grant **Forge Key** (`forge_key` flag + **`forge_key_relic`** item: **+2 Swiftness +2 Fate**) → unlock/equip **relic** slot (§4e). Enter Forge still stub “Congratulations, you finished the Trial! What secrets await you in the Forge? Stay tuned.” at Elder/Ancient only (§4f).

### Enter Forge (LOCKED — stub v0.6.1)
- **Manatree care-menu button only** (no world door).
- **Visible only at `elder` and `ancient`** — **hidden** on `sapling` / `young` / `mature`.
- Without `forge_key`: grayed → popup **“You have no key.”** (Content).
- With `forge_key`: enabled → popup **“Congratulations, you finished the Trial! What secrets await you in the Forge? Stay tuned.”** — **no Forge scene** this ship.

### Save / mid-fight (LOCKED)

- Do **not** save mid-fight HP / turn state.
- Mid-fight **pause / quit / load** = treat as **Flee** (fee stays paid if was).
- **Save disabled** in battle.

### Not this ship (Out)

Companion in combat, 3v1, Cast / items / Guard, Forge interior, Echo 2+, type chart, Wisps in combat, Fate gather effects.

---

## 4b. Controls (LOCKED — Haex v0.3.2)

**Mouse map**
| Input | Result |
|-------|--------|
| **LMB** on Keeper / Wisp / (future friend) | **Select only** (highlight). Does not move or assign. |
| **LMB** on empty ground / grass | **Deselect** current selection. |
| **RMB** with **Keeper** selected | **Command:** walk to point; or walk-in-range + interact if target is harvest node / Manatree (channel / care UI) / **Runestone** (spend Manashards — §4e) / **Echo Portal** (when unlocked — §4f). |
| **RMB** with **Wisp** selected | **Command:** assign to harvest node or Manatree if targeted; **unassign** (return to orbit Keeper) if RMB empty ground. |
| **RMB** with nothing useful selected | No-op (optional toast). |

Esc still opens pause. Future companions: LMB select / RMB command — same pattern.

**Removed:** LMB-as-command; direct interact without select; assign-via-second-LMB-click.

### Camera + map (Code notes — same PR as v0.4.1; not a separate deferred)
Named params / implement with D6 live pass (Haex):
- **Arrow-key camera** clamped to **play bounds** (no free roam past map edge).
- Map size ~**2× width × 3× height** relative to prior hub.
- **Dense decorative** trees + bushes (non-harvest; layout still one of each harvest node + Manatree landmark).
- **Collision:** bottom-third of trunks; bush **bottom-center**.
- **No edge-scroll yet.**

```
# Suggested named params (Code) — PLACEHOLDER scale vs prior hub
MAP_WIDTH_MULT  = 2.0
MAP_HEIGHT_MULT = 3.0
# Camera: arrow keys; clamp to play bounds; EDGE_SCROLL = false (deferred)
```

---

## 4c. Wisps (LOCKED — Haex)

Glowing idle helpers. Spelling in systems/code: `wisp` (not whisp).

### Gain
On each successful **Grow** stage advance to `young` / `mature` / `elder` / `ancient`:
```
wisp_count += 1
# from stages alone: max 4 (one per advance from sapling)
wisp_count_max_from_stages = 4
```
Bonus capacity from blessing `bonus_wisp` (see §5) adds on top.

Ascend: wisps **reset** with the run (back to 0 + `bonus_wisp` ranks as starting free wisps at sapling — see blessing). Assignments cleared.

### Presence
- **Unassigned:** orbit / circle the **Keeper** (follow while walking). `WISP_ORBIT_RADIUS_PX = 56` (Art).
- **Assigned:** **path toward** the target, then **orbit the target** (harvest node or Manatree) — not parked static, not stuck at Keeper.

### Assign (multi-wisp per target — LOCKED v0.3.4)
Valid targets: `harvest_tree` / `harvest_stone` / `harvest_berry` / **`manatree`**.
1. **LMB** wisp → select.
2. **RMB** harvest node or Manatree → assign (wisp paths there, then orbits target). **Stacking allowed** — no deny if another wisp is already there.
3. Reassign: LMB wisp → RMB any valid target (including one that already has wisps).
4. Unassign: LMB wisp → **RMB empty ground** → returns to **orbit Keeper**.

Each assigned wisp pulses **independently** (own timer). Two wisps on wood ≈ 2 wood / `WISP_PULSE_SEC`. `wisp_haste` still reduces pulse interval per wisp. Orbit layout: even spacing around the target (`WISP_ORBIT_RADIUS_PX`).

### Gather pulse by target
| Assignment | Resource pulsed | Rate |
|------------|-----------------|------|
| harvest_tree | `wood` | `WISP_PULSE_GRANT` / `WISP_PULSE_SEC` |
| harvest_stone | `stone` | same |
| harvest_berry | `food` | same |
| **manatree** | **`manashards`** | same (default 1 / 10s) |

Keeper AFK / other work OK; assigned wisps keep pulsing. **Tools never multiply these pulses.**

### Gather pulse
```
WISP_PULSE_SEC = 10.0          # base; wisp_haste blessing reduces
WISP_RES_PER_PULSE = 1         # of the assigned node’s resource
# effective rate = 0.1/sec at base (before gather_mult? — default: NO gather_mult on wisps; Keeper channel still uses gather_mult)
```
Each wisp on its own `WISP_PULSE_SEC` timer: `inventory[resource] += WISP_PULSE_GRANT` (default 1). Stacks additively per wisp on that target.

| Param | Default |
|-------|---------|
| `WISP_PER_NODE` | `0` | # **0 = unlimited** (v0.3.4); was 1 |
| `WISP_PULSE_SEC` | `10` |
| `WISP_PULSE_GRANT` | `1` |
| `WISP_FROM_STAGES_MAX` | `4` |
| `WISP_ORBIT_RADIUS_PX` | `56` |

### Art / Audio handoff
- Art: wisp orbit Keeper (unassigned) and **orbit assign target** (assigned); path tween OK; selected state. **No new art gen this pass** — reuse/chrome later for backpack/tools UI.
- Audio: soft assign confirm; optional quiet pulse (much quieter than Keeper gather).

---

## 5. Primordial Fruit / Ascend

**Model (LOCKED): Manashard blessing shop after Fruit commit — NOT free pick, NOT Essence shop.**

```
# Shop currency = manashards (water + optional wisp-on-tree)
# v0.3.4: essence → 0 on Ascend, so Fruit COMMIT does NOT bank essence for next cycle.
# ESSENCE_PER_HARVEST is unused until a future "starting essence" blessing. Code: skip the add.
```

### Ancient pre-commit (world running)
- Keeper can still **Water** (shards + essence income) and assign wisps — farm Manashards before committing.
- Manatree panel shows **Harvest Primordial Fruit** CTA (+ Grow done / Fruit ready). **No** blessing Buy rows on this panel.
- Wisps / harvest nodes still work until commit.

### Two-step Fruit harvest
1. **Intent:** RMB/interact Fruit CTA → confirm prompt (“Harvest the Primordial Fruit?”).
2. **Commit:** second confirm → set `fruit_committed = true`; **pause world**; open **Ascension shop window**. Do **not** add `ESSENCE_PER_HARVEST` (v0.3.4: next sapling starts at essence 0).

### After commit (world paused)
- **Blocked:** move, Keeper harvest channels, watering, wisp assign/reassign, Grow (already Ancient).
- **Allowed:** buy blessings (Manashards), **Ascend**.
- **No cancel back** to watering after commit (Design lock — Fruit is spent). Footer does **not** offer a soft exit that unpauses without Ascend.
- Ascend: reset stage→sapling; **`essence → 0` (Haex lock)**; wipe **wood/stone/food/manashards → 0**; **wipe backpack** (Fertilizer, intermediates, tools) unless `keep_tools` → re-grant 4 finished tools only; **keep** blessing upgrade ranks + lifetimes; **keep** `keeper_stats` + **equipped gear** + **gear inventory** (v0.5.0); **keep** `forge_key` / relic unlock / `echo_01_resolved` / `echo_01_redeemed` / `portal_fee_paid` if set (v0.6.0); `ascensions += 1` (unlocks portal if not already); unpause; wisps reset per §4c (`bonus_wisp` starting count).

### Ascension shop window (layout contract)
- **Separate modal** — not stacked Harvest / Ascend / Close over the blessing list (fixes Haex screenshot overlap).
- **Scrollable** blessing list (all upgrades: existing + `wisp_haste` + `bonus_wisp` + **`keep_tools`**).
- Each row: name, rank/max, Manashard cost, Buy (afford state), plus **short description / tooltip** (effect text from SYSTEMS blessing table — Content strings; Code surfaces on hover or under name).
- **Pinned footer** outside the scroll view: shard balance + **Ascend** (primary). Optional secondary label only if it does not overlap rows — prefer **Ascend only** in footer.
- Multi-buy OK; Ascend enabled with zero purchases.
- Shop timing still Ascension-only (this window only after Fruit commit).

### Permanent upgrades (blessings — spend Manashards)

**Target:** typical Ascension bank (water ~1–3 shards/sec across the Grow run) affords **about 1–2 ranks total**, not the whole tree.

```
SHOP_BASE = 400
cost_manashards(current_rank) = SHOP_BASE * (current_rank + 1)
# 0→1: 400 | 1→2: 800 | 2→3: 1200 | …
# Exception v0.4.1: keep_tools cost = 3000 flat (max 1) — ignore formula above
```

| upgrade_id | Max | Cost (shards) | Effect (shop tooltip / short description) |
|------------|-----|---------------|-------------------------------------------|
| `deep_roots` | 10 | `400 * (rank + 1)` | `WATER_ESSENCE_PER_SEC` bonus `floor(rank / 2)` |
| `forager` | 10 | `400 * (rank + 1)` | `gather_mult += 0.05` / rank |
| `green_thumb` | 5 | `400 * (rank + 1)` | **Fertilizer craft ingredient costs −10%/rank** (floor 1 per ingredient). Was soft-mat needs −10% (SUPERSEDED with needs-only). |
| `shard_sight` | 5 | `400 * (rank + 1)` | `+1` shards per water pulse / rank |
| `keeper_stride` | 5 | `400 * (rank + 1)` | `MOVE_SPEED_MULT += 0.06` / rank |
| `wisp_haste` | 5 | `400 * (rank + 1)` | `WISP_PULSE_SEC -= 1` / rank (base 10 → min **5**) |
| `bonus_wisp` | 3 | `400 * (rank + 1)` | `+1` wisp at sapling / +1 capacity per rank (stacks with stage grants) |
| **`keep_tools`** | **1** | **`3000` flat** | On Ascend: after backpack wipe, **re-grant the 4 finished tools** only (not Fertilizer / intermediates). Max 1. |

**Examples:** bank 400 → one rank; bank 800 → two rank-1 buys. Unspent shards **and essence** wipe on Ascend (`essence → 0`). Mid-run Runestone spends already converted to **persisting** stat ranks (§4e) — bank-vs-shop dilemma.

**Wisp blessing notes:** `bonus_wisp` ranks persist; on Ascend after reset to sapling, `wisp_count = bonus_wisp_rank` immediately (then stage advances add more up to stages max + bonus).

**`green_thumb` (v0.4 retarget LOCKED):** pick = **Fertilizer craft ingredient costs −10%/rank** (each of wood/stone/food), floor 1 per ingredient. Does **not** change Grow Fertilizer *count* required. Documented choice over “Fertilizer units to Grow −10%/rank.”

**`keep_tools` (v0.4.1 LOCKED):** max 1; cost **`3000` Manashards flat** — not `400 * (rank + 1)`.

**Code:** mirror in `fruit_upgrades.json` (or equivalent data file).

---

## 6. Pause + save slots

| Param | Default |
|-------|---------|
| `SAVE_SLOT_COUNT` | **7** |
| `PAUSE_OPENS_SLOTS` | `true` |
| `SAVE_VERSION` | **8** |

v0.5.0: **`SAVE_VERSION` → 7** — character stats, equipment, gear inventory schema.  
v0.6.0: **`SAVE_VERSION` → 8** — Echo Chamber portal / fee / resolve / redeemed / forge_key.

---

## 7. Save fields (`SAVE_VERSION = 8`)

```
save_version: int                  # 8
ascensions: int
essence: int
upgrades: Dictionary[String, int]  # includes keep_tools, green_thumb, …

stage_id: String
# growth: REMOVED
# needs-only soft-mat stage fields: REMOVED / ignored

wood: int
stone: int
food: int
manashards: int

# Backpack (v0.4) — crafted only (forage/tools/fert path)
backpack: Dictionary[String, int]  # e.g. fertilizer, wooden_planks, stone_fragments,
                                   # wooden_tool_rod, stone_axe_head, stone_pickaxe_head
# Tool ownership flags (unique; own 0 or 1)
owns_stone_axe: bool
owns_stone_pickaxe: bool
owns_wooden_basket: bool
owns_stone_watering_can: bool
# Alternate OK: tools as backpack keys with max 1 — flags preferred for clear Keep Tools re-grant

# Character / equipment (v0.5.0)
keeper_stats: Dictionary[String, int]  # might, arcana, resilience, ward, vitality, swiftness, fate
                                       # each rank 0+; Runestone N/A beyond these ranks
equipment_unlocked: Dictionary[String, bool]  # weapon true; relic true iff forge_key; others false
equipment_equipped: Dictionary[String, Variant]  # slot_id → item_id (String) or null
gear_inventory: Dictionary[String, int]  # battle gear bag — e.g. weapon_rod, stone_sword

# Echo Chamber v1 (v0.6.0) — do NOT save mid-fight HP/turn
portal_unlocked: bool     # true when ascensions >= 1 (or explicit flag)
portal_fee_paid: bool     # fee paid this attempt cycle; flee keeps; KO clears; win closes portal
echo_01_resolved: bool    # win (spare or defeat) → portal closed
echo_01_redeemed: bool    # spare only — companion flag; no companion body this ship
forge_key: bool           # both wins; unlocks relic slot

wisp_count: int
wisp_assignments: Dictionary  # wisp_id → node_id or null
fruit_committed: bool  # Ancient pause-shop state; false on load unless mid-shop (rare)

lifetime_waters: int
lifetime_shards_from_water: int
lifetime_essence_from_water: int
lifetime_fruit_harvested: int
lifetime_harvested: Dictionary[String, int]

keeper_position: Vector2
keeper_selected: bool  # optional; default false on load
```

Migrate **v6→v7:** `keeper_stats` all 0; `equipment_equipped` all null; `gear_inventory` empty; `equipment_unlocked` = weapon **true** only (all other slots false, including relic). Prior v5→v6 rules still apply if jumping older saves: init empty `backpack`; all tool flags `false`; ignore leftover needs-only stage cost state. `green_thumb` ranks keep; `keep_tools` defaults 0.

Migrate **v7→v8:** `portal_unlocked = (ascensions >= 1)`; `portal_fee_paid = false`; `echo_01_resolved = false`; `echo_01_redeemed = false`; `forge_key = false`; relic stays locked unless `forge_key`. Mid-fight load = Flee (no HP/turn restore). Save disabled in battle.

---

## 8. Loop summary (Code)

```
LMB Keeper/Wisp → select | LMB empty → deselect
RMB (Keeper selected) → walk / interact harvest, Manatree, Runestone, or Echo Portal (if unlocked)
RMB (Wisp selected) → assign to node or Manatree (manashards); RMB ground → unassign → orbit Keeper
Assigned wisps path to target then orbit it; pulse +1/10s (tools never boost)
Craft: soft mats → backpack (intermediates / tools / Fertilizer); Weapon Rod / Stone Sword → gear inventory
Equip: drag gear inventory → unlocked slots (weapon at start; relic after forge_key)
HUD / C → character sheet (Keeper + slots | gear bag | base+gear=total stats)
Runestone: spend Manashards → +1 flat to that stat (steep exponential cost)
Grow (Fertilizer + Essence met) → stage_up → +1 wisp; Manatree display scale by stage (D7)
Tools owned → 2× Keeper channel (harvest) or double water shard amount (Can)
After first Ascension → Echo Portal; pay 30 Essence once → 1v1 vs Elaia (Strike/Flee/Spare)
Win → forge_key + relic unlock + shard payout; Spare also echo_01_redeemed; portal closes
Manatree care: Enter Forge (grayed without key / “not built yet” with key)
ESC → pause (7 slots); Save disabled in battle; mid-fight quit/load = Flee
Ascend → wipe soft mats + essence + shards + backpack; Keep Tools → re-grant 4 tools;
         KEEP keeper_stats + equipped + gear_inventory + forge_key + echo flags + portal_fee_paid
```

---

## 9. Handoffs

| Who | Action |
|-----|--------|
| @Code / Engine | **Implement v0.6.1 polish** (with Echo v1): Forge Key → relic item +2 Swift/+2 Fate; Enter Forge Elder/Ancient only + Stay tuned popup; battle layout polish. Prior v0.6.0: portal after `ascensions >= 1`; fee 30 Essence; battle scene 1v1 vs Elaia (`echo_keeper_01`); Strike / Flee / Spare (<10%); formulas LOCKED (§4f); rewards + `forge_key` → relic unlock; Enter Forge care-menu stub; migrate save **v7→v8**; Ascend persist forge_key + echo flags + portal_fee_paid; Save disabled in battle; mid-fight quit/load = Flee. Keep v0.5.1 stats/equipment. Placeholders labeled. **Out:** Echo 2+, companion body, Forge interior, Cast/items/Guard, 3v1. |
| @Content & Lore | Portal / fee / battle UI strings; Elaia display name; Spare / Flee / Strike / win-loss copy; no-key + “not built yet” Forge popups; reward toasts (shards + Key); keep existing sheet / Runestone / blessing / Grow strings |
| @Art Direction | **No mandatory gen.** ColorRects OK for battle UI / portal / sheet / slots; portal world prop + battle layout chrome later. Manatree scale unchanged (D7). |
| @Audio | Battle: silence world hub bed on enter; stop-resume hub on exit (flee/loss/win). Optional hit / crit / win stings later. Existing gather / wisp / water SFX unchanged. |

---

## 10. Open / locked

| Item | Status |
|------|--------|
| Needs-only stage advance (soft mats for stages) | **SUPERSEDED Haex v0.4.0** |
| Stage advance = **Grow** (Fertilizer + Essence), one-click | **LOCKED Haex v0.4.0 GREENLIGHT** |
| CTA label **Grow** (not Pay); costs on control | **LOCKED Haex v0.4.0** |
| Water = shards + essence income | **LOCKED** |
| Stone Watering Can = Manashard side only (`shard_roll * 2`) | **LOCKED Haex v0.4.0** (amount PLACEHOLDER) |
| Fertilizer recipe wood+stone+food, **no Manashards** | **LOCKED Haex v0.4.0** (costs PLACEHOLDER) |
| Backpack = crafts only; HUD = soft mats + currencies | **LOCKED Haex v0.4.0** |
| Tools unique (own 1); never gate gather; Keeper 2× only; never wisps | **LOCKED Haex v0.4.0** |
| Ascend wipes backpack; `keep_tools` re-grants 4 tools | **LOCKED Haex v0.4.0** |
| `green_thumb` = Fertilizer craft ingredient −10%/rank (floor 1) | **LOCKED Haex v0.4.0** (retarget) |
| Grow Fertilizer **3 / 6 / 12 / 24**; Essence **20 / 40 / 60 / 80** | **LOCKED Haex v0.4.1** (PLACEHOLDER tune later) |
| `FERT_WOOD/STONE/FOOD = 10` | **LOCKED Haex v0.4.1** (PLACEHOLDER) |
| Stone Watering Can = **20 Stone Fragments** only; Wooden Basket = **20 Wooden Planks** | **LOCKED Haex v0.4.1** |
| Intermediate heads = **Stone Axe Head**, **Stone Pickaxe Head** | **LOCKED Haex v0.4.1** |
| `keep_tools` = **3000** Manashards flat (max 1) | **LOCKED Haex v0.4.1** |
| Ascension shop rows: short description / tooltip | **LOCKED Haex v0.4.1** |
| Handcraft UI: Can + Fert rows costs only; scroll vs panel width | **LOCKED Haex v0.4.1** (Code contract) |
| Arrow-key camera clamp; map ~2×W×3×H; dense décor; trunk/bush collision; no edge-scroll | **LOCKED Haex v0.4.1** (same PR Code notes) |
| 3 harvest nodes @ 1/sec base | **LOCKED** |
| `SAVE_SLOT_COUNT = 7`; `SAVE_VERSION = 8` | **LOCKED Haex v0.6.0** (was 7 in v0.5.0) |
| Offer-for-growth | **REMOVED** |
| Ascension = Manashard blessing shop | **LOCKED Haex v0.2.3** |
| Shop timing = Ascension-only after Fruit | **LOCKED Haex v0.2.4** |
| Shop costs ~1–2 ranks/Ascension (`SHOP_BASE=400`) | **LOCKED Haex intent v0.2.5** |
| Wisps: 1/stage advance, +1/10s | **LOCKED Haex v0.3.0** |
| Keeper select-then-move | **LOCKED Haex v0.3.0** |
| Keeper must be selected for all actions | **LOCKED Haex v0.3.1** |
| Unassigned wisps orbit Keeper | **LOCKED Haex v0.3.1** |
| LMB select / RMB command / LMB empty deselect | **LOCKED Haex v0.3.2** |
| Assigned wisps orbit their target; Manatree→manashards | **LOCKED Haex v0.3.2** |
| Ancient water until Fruit commit; two-step Fruit; paused shop; no cancel | **LOCKED Haex v0.3.3** |
| Multi-wisp per node/Manatree (independent pulses) | **LOCKED Haex v0.3.4** |
| Ascend: essence → 0 (blessings keep); manashards → 0 | **LOCKED Haex / Design rec v0.3.4** |
| Wisp blessings `wisp_haste` + `bonus_wisp` | **LOCKED Haex v0.3.0** |
| Pick-one-free Ascension | **REVOKED** |
| Essence blessing shop | **REVOKED** |
| Ascension soft-open (preview + Close; first Buy locks) | **DEFERRED — not live** (§11 D1) |
| Equipment / Runestones / 7 combat stats **foundation** | **LOCKED / LIVE Haex GREENLIGHT v0.5.0** (§4e) |
| Runestone currency = **same Manashards** (bank vs Ascension shop) | **LOCKED Haex v0.5.0** (was draft 2026-09-19) |
| Combat stats **base start at 5** | **LOCKED Haex v0.5.1** |
| Separate Runestone currency | **PARKED / overturned** |
| Runestone cost `BASE=100`, `GROWTH=1.65`, `floor(BASE*GROWTH^rank)` | **LOCKED Haex v0.5.0** (PLACEHOLDER tune later) |
| Stats + equipped + gear inventory **persist** Ascend; shards wipe | **LOCKED Haex v0.5.0** |
| Equipment slots order; weapon unlocked at start; relic unlocks via `forge_key` (Echo win) | **LOCKED Haex v0.5.0 / v0.6.0** |
| Gear inventory ≠ backpack; Weapon Rod + Stone Sword only | **LOCKED Haex v0.5.0** (recipes PLACEHOLDER) |
| Character sheet: HUD + **C**; left Keeper/slots, mid gear, right base+gear=total | **LOCKED Haex v0.5.0** |
| Manatree display scales (0.5 / 1 / 2 / 2 / 1.5) | **LOCKED / LIVE Haex D7 → v0.5.0** (§4 / §11 D7) |
| Playtest backlog D6 (recipes / Grow / Keep Tools / UI / tooltips / camera-map) | **LOCKED / applied → live v0.4.1** (§11 D6) |
| Echo Chamber v1 (portal / 1v1 Elaia / formulas / rewards / forge_key → relic) | **LOCKED / LIVE Haex GO v0.6.0** (§4f; §11 D3 foundation LIVE) |
| Enter Forge = care-menu only; **Elder+Ancient only**; Key → “Congratulations, you finished the Trial! What secrets await you in the Forge? Stay tuned.” | **LOCKED Haex v0.6.1** |
| Forge Key relic **+2 Swiftness +2 Fate** (Spare/Defeat) | **LOCKED Haex v0.6.1** |
| Echo 2+ / companion body / companion in combat / 3v1 / Cast/items/Guard / Forge interior / type chart / Wisps in combat / Fate gather / other gear recipes | **DEFERRED — not live** (§11 D3) |

---

## 11. Deferred (Haex notes — **do not implement** until greenlight)

Live loop is **v0.6.0** (Fertilizer Grow + backpack/tools + D6 retunes + character sheet / stats / equipment + D7 Manatree scales + **Echo Chamber v1**) with must-Ascend-on-commit (v0.3.3). Soft-open still deferred. D2/D3-foundation(+Echo v1)/D4/D5/D6/D7 are live pointers; Echo 2+ / companion body / Forge realm / Cast/items/Guard remain parked under D3.

### D1. Ascension soft-open — still deferred
1. Fruit interact opens the Manashard shop as a **preview**. World **stays live** (move / water / harvest / wisps still work).
2. Player can **Close / quit** the shop and keep playing (no Fruit spend, no pause).
3. **First Buy** hard-locks the run: world **pauses**, shop becomes Ascend-only, **no cancel back** to play (same as today’s post-commit lock, but the lock trigger is first purchase, not Fruit commit).
4. Open: does Fruit still two-step? Does preview spend Manashards on Buy before lock, or is first Buy the commit? Default Design rec when greenlit: preview is browse-only until first confirmed Buy (that Buy spends shards **and** locks).

### D2. Manatree care CTA — GREENLIT → live v0.4.0
~~Stage-advance button label Grow~~ → **LIVE:** CTA **Grow**, costs on control (Fertilizer + Essence). See §4. (Was deferred under needs-only Pay; greenlit with Fertilizer Grow.)

### D3. Equipment & Stats / Echo Chamber — GREENLIT foundation → live v0.5.0; **Echo Chamber v1 LIVE v0.6.0**
**Foundation LIVE** — see **§4e**. Seven combat stats + Runestones (same Manashard pool, steep exponential PLACEHOLDER curve), equipment slots (weapon unlocked; **relic unlocks via Forge Key**), gear inventory ≠ backpack, Weapon Rod + Stone Sword, character sheet (HUD + **C**), Ascend persist stats + equipped + gear inventory.

**Echo Chamber v1 LIVE** — see **§4f**. Portal + 1v1 Elaia + LOCKED formulas + spare/defeat rewards + `forge_key` → relic slot; Enter Forge stub; `SAVE_VERSION` **8**.

**Still deferred (do not implement this ship):** Echo 2+, companion body / companion in combat, 3v1, Cast / items / Guard, Forge interior / Forge realm, other equipment recipes, Bare Stone / levels / runes data shape, type chart, Wisps in combat, Fate gather effects, Runestone non-Manashard currency.

**Locks carried from draft:** One Manashard pool (bank-vs-shop). Separate Runestone currency **PARKED / overturned**. Do not overload `upgrade_ranks` for combat stats.

### D4. Backpack & Handcrafting — GREENLIT → live v0.4.0
Short pointer: live rules in **§4d**. Backpack (crafts only), instant handcraft, unique tools, Keeper 2× only / never wisps, Ascend backpack wipe, `keep_tools` re-grants 4 finished tools. Fertilizer as stage currency — see §4 / D5.

### D5. Fertilizer stages + tools — GREENLIT → live v0.4.0
Short pointer: live rules in **§4** (Stage Grow) + **§3** (Watering Can) + **§4d** (recipes/tools) + **§5** (`keep_tools`, retargeted `green_thumb`). Needs-only **SUPERSEDED**. Numbers retuned in **v0.4.1** (still PLACEHOLDER for future tune) — see §4 / §4d / D6.

**Obsolete Design leans removed:** water=shards-only; Essence-on-berry. Live water remains Manashards + Essence; Can boosts Manashard side only.

### D6. Playtest backlog — GREENLIT → live v0.4.1
Coding session **OPENED** (Director greenlight). Applied live in this brief — implement now. Short pointer: recipes / Grow / `keep_tools` / handcraft UI / shop tooltips / head renames in **§4**, **§4d**, **§5**; camera + map Code notes in **§4b**. No leftover “do not implement.”

| # | Change | Live home |
|---|--------|-----------|
| 1 | Can = **20 Stone Fragments**; Basket = **20 Wooden Planks** | §4d recipes |
| 2 | Handcraft: Can + Fert **costs only**; scroll vs panel width | §4d Handcraft UI |
| 3 | **Stone Axe Head**, **Stone Pickaxe Head** | §4d / save ids |
| 4 | `keep_tools` = **3000** flat (max 1) | §5 |
| 5 | Ascension short description / tooltip | §5 shop layout |
| 6 | `FERT_* = 10`; Grow Fert **3/6/12/24**; Essence **20/40/60/80** | §4 / §4d |
| + | Camera clamp; map ~2×W×3×H; dense décor; collision; no edge-scroll | §4b (same PR) |

`SAVE_VERSION` stays **6**. Ping Code/Content (Art layout only if handcraft overflow needs chrome).

### D7. Manatree display scales — GREENLIT → live v0.5.0
Short pointer: live rules in **§4** (Manatree display scales). Visual only — no Grow cost / bonus change. Interaction/collision stay fair at 0.5× and 2.0×.

| Stage (1→5) | `stage_id` | Display scale |
|-------------|------------|---------------|
| 1 | `sapling` | **0.5×** |
| 2 | `young` | **1.0×** (default) |
| 3 | `mature` | **2.0×** |
| 4 | `elder` | **2.0×** |
| 5 | `ancient` | **1.5×** |
