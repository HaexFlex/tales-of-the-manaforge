# Tales of the Manaforge — Systems Brief v0.4 (Restart Edition)
**Owner:** Game Design  
**Status:** v0.4.1 — Haex playtest backlog D6 LIVE (coding session OPENED); Fertilizer Grow + backpack/tools/Keep Tools  
**Source of truth above this doc:** `VISION_RESTART.md` + `refs/`  
**Non-canon:** `DESIGN.md` (idle-combat), forge-hub art kit, battle audio drafts  
**Audience:** Code implements; Content names strings; Art / layout for Code  
**Last updated:** 2026-09-19

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
| v0.3.4 note | Equipment & Stats mid-term discuss park (§11 D3) — unchanged |
| v0.3.4 note | Draft: abandon needs-only → Fertilizer + Essence — **GREENLIT → live v0.4.0** |
| **v0.4.0** | **Haex GREENLIGHT:** Abandon needs-only. Stage advance = one-click **Grow** (Fertilizer + Essence). Water still Manashards + Essence; Stone Watering Can doubles Manashard amount/pulse only. Backpack (crafts only) + handcrafting + 4 unique tools (Keeper 2× channel only). Fertilizer recipe wood+stone+food (no shards). Blessing `keep_tools`; `green_thumb` → Fertilizer craft ingredient costs −10%/rank. Ascend wipes backpack (Keep Tools re-grants 4 tools). `SAVE_VERSION` **6**. |
| v0.4.0 note | Playtest backlog was PARKED pending next coding session — **GREENLIT → live v0.4.1** (§11 D6). |
| **v0.4.1** | **Haex D6 LIVE (coding session OPENED):** Can recipe = **20 Stone Fragments** only; Basket = **20 Wooden Planks**. Handcraft UI: Watering Can + Fertilizer rows **costs only**; fix scroll vs panel width. Rename heads → **Stone Axe Head**, **Stone Pickaxe Head**. `keep_tools` = **3000** Manashards flat (max 1). Ascension shop rows show **short description / tooltip**. Fert craft ~2× (`FERT_* = 10`); Grow Fertilizer **3 / 6 / 12 / 24**; Keep Essence **20 / 40 / 60 / 80**. Same PR Code notes: arrow-key camera clamped to play bounds; map ~**2×W × 3×H**; dense decorative trees + bushes; collision bottom-third trunks / bush bottom-center; no edge-scroll yet. `SAVE_VERSION` stays **6** (number-only retunes; no backpack schema change). |
| **v0.4.2** | **Haex GREENLIGHT:** Character sheet (HUD **Character** + **C**), seven stats, seven hub Runestones, Stone Sword + Weapon Rod, Manatree visual scales. Combat and Forge Key still later. `SAVE_VERSION` stays **6** (additive `keeper_stats` + `equipment` keys). |

---

## v0.4 scope (systems only)

**In:** select-then-move Keeper, **Fertilizer Grow** stages (Fertilizer + Essence), channelled harvest (3 nodes), Wisps (AFK node gather), water income (shards + essence), **backpack + handcrafting** (intermediates, tools, Fertilizer), **unique tools** (Keeper channel 2× only), Primordial Fruit / Manashard Ascension shop (incl. `keep_tools`), pause + 7 slots, versioned save (`SAVE_VERSION` 6), minimal HUD (soft mats + shards + essence; backpack separate).

**Out:** needs-only soft-mat stage pay (**SUPERSEDED**), growth bar / offers, combat, full Forge, equipment / Echo Chamber, WASD, mobile/web, many duplicate harvestables. Tools never gate gather; tools never multiply wisp pulses.

---

## 1. Resources

| ID | How gained | How spent |
|----|------------|-----------|
| `wood` | Harvest Tree @ 1/sec (Keeper; 2× channel speed if Stone Axe owned) | **Fertilizer craft** (+ tool/intermediate craft) — **not** stage needs |
| `stone` | Stone node @ 1/sec (Keeper; 2× if Stone Pickaxe) | **Fertilizer craft** (+ tool/intermediate craft) |
| `food` | Berry bush @ 1/sec (Keeper; 2× if Wooden Basket) | **Fertilizer craft** (+ tool/intermediate craft) |
| `manashards` | Water channel `U{1,3}` / sec (×2 amount/pulse if Stone Watering Can); **wisp on Manatree** @ 1/10s | **Blessing shop** (Ascension permanent upgrades). Optional future Runestones discuss only — see §11 D3 |
| `essence` | Water channel `+1` / sec (base; Can does **not** boost); Fruit harvest bonus unused | **Grow** stage advance (with Fertilizer) — not blessing shop |
| `fertilizer` | Handcraft (wood + stone + food) | **Grow** stage advance (with Essence) |

Soft mats live on the **resource HUD**. Fertilizer, intermediates, and tools live in the **backpack** (§4d).

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

### Pace note
Essence gate still matters early (20s water to Young at 1 essence/sec) plus craft **3** Fertilizer (`FERT_* = 10` each). Later stages need harvest → craft Fertilizer loops while watering for essence + shards. First Ancient is intentional multi-loop (24 Fertilizer).

### UI (Content + Code)
- Manatree click → panel: next stage name + Grow costs (`Fertilizer 0/3`, `Essence 12/20`, …) + **Grow** (enabled when both met; show costs on the control) + Water.
- **No** growth X/Y bar. **No** soft-mat need lines. **No Pay** label.

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

All PLACEHOLDER numbers — tune later. **No Manashards** in any of these recipes.

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

---

## 4b. Controls (LOCKED — Haex v0.3.2)

**Mouse map**
| Input | Result |
|-------|--------|
| **LMB** on Keeper / Wisp / (future friend) | **Select only** (highlight). Does not move or assign. |
| **LMB** on empty ground / grass | **Deselect** current selection. |
| **RMB** with **Keeper** selected | **Command:** walk to point; or walk-in-range + interact if target is harvest node / Manatree (channel / care UI). |
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
- Ascend: reset stage→sapling; **`essence → 0` (Haex lock)**; wipe **wood/stone/food/manashards → 0**; **wipe backpack** (Fertilizer, intermediates, tools) unless `keep_tools` → re-grant 4 finished tools only; keep upgrade ranks + lifetimes; `ascensions += 1`; unpause; wisps reset per §4c (`bonus_wisp` starting count).

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

**Examples:** bank 400 → one rank; bank 800 → two rank-1 buys. Unspent shards **and essence** wipe on Ascend (`essence → 0`).

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
| `SAVE_VERSION` | **6** |

v0.4.1: **no `SAVE_VERSION` bump** — number-only retunes / labels; backpack schema unchanged.

---

## 7. Save fields (`SAVE_VERSION = 6`)

```
save_version: int                  # 6
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

# Backpack (v0.4) — crafted only
backpack: Dictionary[String, int]  # e.g. fertilizer, wooden_planks, stone_fragments,
                                   # wooden_tool_rod, stone_axe_head, stone_pickaxe_head
# Tool ownership flags (unique; own 0 or 1)
owns_stone_axe: bool
owns_stone_pickaxe: bool
owns_wooden_basket: bool
owns_stone_watering_can: bool
# Alternate OK: tools as backpack keys with max 1 — flags preferred for clear Keep Tools re-grant

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

Migrate v5→v6: init empty `backpack`; all tool flags `false`; ignore any leftover needs-only stage cost state. `green_thumb` ranks keep (effect retargeted). `keep_tools` defaults 0.

---

## 8. Loop summary (Code)

```
LMB Keeper/Wisp → select | LMB empty → deselect
RMB (Keeper selected) → walk / interact harvest or Manatree
RMB (Wisp selected) → assign to node or Manatree (manashards); RMB ground → unassign → orbit Keeper
Assigned wisps path to target then orbit it; pulse +1/10s (tools never boost)
Craft: soft mats → backpack (intermediates / tools / Fertilizer)
Grow (Fertilizer + Essence met) → stage_up → +1 wisp (orbits Keeper until assigned)
Tools owned → 2× Keeper channel (harvest) or double water shard amount (Can)
ESC → pause (7 slots)
Ascend → wipe soft mats + essence + shards + backpack; Keep Tools → re-grant 4 tools
```

---

## 9. Handoffs

| Who | Action |
|-----|--------|
| @Code / Engine | **Implement v0.4.1:** live D6 retunes (Can 20 Fragments; Basket 20 Planks; `FERT_* = 10`; Grow Fert **3/6/12/24** + Essence **20/40/60/80**; `keep_tools` **3000** flat); handcraft UI costs-only + scroll/width fix; blessing row tooltips; camera clamp + map ~2×W×3×H + dense décor + trunk/bush collision; no edge-scroll. `SAVE_VERSION` stays **6**. (v0.4.0 base already shipped or ship together.) |
| @Content & Lore | Tooltips / short descriptions from SYSTEMS blessing Effect column; rename **Stone Axe Head** / **Stone Pickaxe Head**; update cost strings (Grow, Fert craft, Can, Basket, Keep Tools 3000); Grow CTA cost examples |
| @Art Direction | **No mandatory gen.** Layout pass for handcraft overflow if chrome needs it; Ascension shop still scroll list + pinned footer |
| @Audio | Existing wisp / gather / water SFX; craft/Grow confirms later if needed |

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
| `SAVE_SLOT_COUNT = 7`; `SAVE_VERSION = 6` | **LOCKED** |
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
| Equipment / Runestones / 7 combat stats | **DISCUSS PARK — not live** (§11 D3) |
| Runestone currency = **same Manashards** (bank vs Ascension shop) | **Haex draft lock 2026-09-19 — not live** |
| Separate Runestone currency | **PARKED / overturned** |
| Playtest backlog D6 (recipes / Grow / Keep Tools / UI / tooltips / camera-map) | **LOCKED / applied → live v0.4.1** (§11 D6) |

---

## 11. Deferred (Haex notes — **do not implement** until greenlight)

Live loop is **v0.4.2** (Fertilizer Grow + backpack/tools + D6 retunes + character sheet / Runestones / Stone Sword) with must-Ascend-on-commit (v0.3.3). Soft-open and combat remain parked. D2/D3 foundation/D4/D5/D6 are live pointers.

### D1. Ascension soft-open — still deferred
1. Fruit interact opens the Manashard shop as a **preview**. World **stays live** (move / water / harvest / wisps still work).
2. Player can **Close / quit** the shop and keep playing (no Fruit spend, no pause).
3. **First Buy** hard-locks the run: world **pauses**, shop becomes Ascend-only, **no cancel back** to play (same as today’s post-commit lock, but the lock trigger is first purchase, not Fruit commit).
4. Open: does Fruit still two-step? Does preview spend Manashards on Buy before lock, or is first Buy the commit? Default Design rec when greenlit: preview is browse-only until first confirmed Buy (that Buy spends shards **and** locks).

### D2. Manatree care CTA — GREENLIT → live v0.4.0
~~Stage-advance button label Grow~~ → **LIVE:** CTA **Grow**, costs on control (Fertilizer + Essence). See §4. (Was deferred under needs-only Pay; greenlit with Fertilizer Grow.)

### D3. Equipment & Stats — GREENLIT foundation (v0.4.2)
Haex greenlight overrides the older “two slots / Bare Stone Relic now” note.

**Live:** `KeeperStats` + `Equipment` autoloads beside GameState. Seven stats (might, arcana, resilience, ward, vitality, swiftness, fate). One Runestone per stat in the hub. Cost = `round(50 * 2^rank)` Manashards (PLACEHOLDER). Power is **+1 flat per rank**. Character sheet: HUD **Character** and **C**. Left portrait (`keeper_idle_south`) with slots on the body, middle = battle gear only, right = **base + gear = total**. Slots: weapon, relic, head, body, hands, pants, feet, cape, ring_1, ring_2. **Only weapon starts unlocked.** Relic stays locked (Forge Key is the first Keeper fight — not this ship). Equip by click or drag. **Weapon Rod** = 10 Wooden Planks (backpack intermediate, not the Wooden Tool Rod). **Stone Sword** = 30 Stone Fragments + 1 Weapon Rod, +2 Might, equipment inventory only. Ranks and battle gear persist through Ascend. Unspent Manashards still wipe. Fate does not change gather, Wisps, or handcraft. Instances store `level` and `runes` unused. `SAVE_VERSION` stays **6**.

**Still parked:** combat resolution, Forge Key drop, armor recipes, respec, equipment levels UI, rune sockets, real Runestone art.

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
