# Tales of the Manaforge — Systems Brief v0.3 (Restart Edition)
**Owner:** Game Design  
**Status:** v0.3.5 — Haex: backpack / handcraft / Grow (Fertilizer+Essence). Player copy: Content **v0.4.0**.  
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
| v0.2.0 | Needs-only stages; no growth/offers; SAVE_VERSION 4 |
| v0.2.1 | Spend-essence blessing shop (superseded) |
| v0.2.2 | Pick-one-free Ascension (superseded) |
| v0.2.3 | Manashard blessing shop → Ascend |
| v0.2.4 | Manashard shop Ascension-only |
| v0.2.5 | Manashard shop SHOP_BASE=400 (~1–2 ranks/Ascension) |
| v0.3.0 | Wisps + select-then-move + wisp blessings; SAVE_VERSION 5 |
| v0.3.1 | Keeper select-gated actions; unassigned wisps orbit Keeper |
| v0.3.2 | LMB/RMB; wisps orbit target; Manatree→manashards |
| v0.3.3 | Two-step Fruit; paused separate shop; no cancel |
| **v0.3.4** | **Haex:** **Multi-wisp per target** — drop 1-wisp exclusivity. Several wisps may assign to the same harvest node **or** Manatree; each pulses independently. **Ascend:** `essence → 0` (LOCKED) plus existing soft-mat wipe; **Manashards also → 0** (Design rec, already true) so next run starts clean. Blessings persist. |
| **v0.3.5** | **Haex GREENLIGHT:** abandon needs-only Pay. One-click **Grow** spends **Fertilizer + Essence**. Backpack = crafted items only. Tools 2× Keeper channel speed (hands always work; Wisps unchanged). Stone Watering Can speeds **Manashard** water ticks only. Ascend wipes backpack; **Keep Tools** re-grants the four finished tools. `SAVE_VERSION` **6**. Placeholder Grow curve: Fertilizer **1/2/3/4** + Essence **20/40/60/80** (Young→Ancient). |

---

## v0.3 scope (systems only)

**In:** select-then-move Keeper, Manatree needs stages, channelled harvest (3 nodes), Wisps (AFK node gather), water income, Primordial Fruit / Manashard Ascension shop, pause + 7 slots, versioned save, minimal HUD.

**Out:** growth bar / offers, combat, full Forge, equipment, Echo Chamber, WASD, mobile/web, many duplicate harvestables.

---

## 1. Resources

| ID | How gained | How spent |
|----|------------|-----------|
| `wood` | Harvest Tree @ 1/sec | **Handcraft** (planks, Fertilizer) |
| `stone` | Stone node @ 1/sec | **Handcraft** (fragments, Fertilizer) |
| `food` | Berry bush @ 1/sec | **Handcraft** Fertilizer |
| `manashards` | Water channel `U{1,3}` / sec; **wisp on Manatree** @ 1/10s | **Blessing shop** (Ascension permanent upgrades). Not a Grow cost. Not a Fertilizer ingredient. |
| `essence` | Water channel `+1` / sec | **Grow** (with Fertilizer). Not blessing shop. |

**Backpack (crafted only):** Wooden Planks, Stone Fragments, Wooden Tool Rod, Axe Head, Pickaxe Head, Stone Axe, Stone Pickaxe, Wooden Basket, Stone Watering Can, Fertilizer. HUD resource bar stays wood/stone/food/manashards/essence.

---

## 2. Harvest nodes (LOCKED — Haex)

Exactly **three** interactive harvest nodes. Channel @ 1 resource/sec while in range.

| node_id | Resource | Rate |
|---------|----------|------|
| `harvest_tree` | `wood` | `HARVEST_WOOD_PER_SEC = 1` |
| `harvest_stone` | `stone` | `HARVEST_STONE_PER_SEC = 1` |
| `harvest_berry` | `food` | `HARVEST_FOOD_PER_SEC = 1` |

`CHANNEL_PULSE_SEC = 1.0`, `HARVEST_RANGE_PX = 48`.  
Layout: dense **decorative** trees; **one** of each harvest node; Manatree landmark separate.

---

## 3. Water channel (income only)

```
each CHANNEL_PULSE_SEC while watering and in range:
  manashards += randi_range(WATER_SHARD_MIN, WATER_SHARD_MAX) + shard_sight_rank
  essence    += WATER_ESSENCE_PER_SEC
  # NO growth
```

| Param | Default |
|-------|---------|
| `WATER_SHARD_MIN` | `1` |
| `WATER_SHARD_MAX` | `3` |
| `WATER_ESSENCE_PER_SEC` | `1` |

At Ancient: water still pays income; Fruit/Ascend is a separate confirm.  
**Removed:** `WATER_GROWTH`, growth pulses, offer-for-growth.

---

## 4. Stage Grow (LOCKED — Haex v0.3.5)

**No food/wood/stone/manashard stage needs.** Clicking Manatree shows **Grow** costs for the next stage: **Fertilizer + Essence**. One-click **Grow** (not Pay) when both are met → consume → advance.

### Placeholder cost curve (tune later)

| Advance to | fertilizer | essence |
|------------|------------|---------|
| `young` | **1** | **20** |
| `mature` | **2** | **40** |
| `elder` | **3** | **60** |
| `ancient` | **4** | **80** |

`green_thumb` reduces **Fertilizer** only (−10%/rank, floor, min 1). Essence unchanged.

**Sapling** (start): no Grow yet (first costs are to enter Young).  
**Grow action:** one click when affordable. No confirm. Partial progress is inventory only.

Recipes / tools / Keep Tools: `data/handcraft_recipes.json`. Art placeholders: `docs/ART_NEEDED_BACKPACK.md`.

### Stage bonuses (kept)

| stage_id | Bonus while here |
|----------|------------------|
| `sapling` | — |
| `young` | `gather_mult = 1.1` |
| `mature` | `gather_mult = 1.25` |
| `elder` | `gather_mult = 1.4` |
| `ancient` | `gather_mult = 1.6`; Fruit ready |

### Pace note
Essence gate dominates early (20s water to Young at 1 essence/sec). Later stages need harvest loops for food/wood/stone while still watering for essence. First Ancient is intentional multi-loop, not a growth bar grind.

### UI (Content + Code)
- Manatree click → panel: next stage name + need lines (`essence 12/20`, `food 0/10`, …) + Pay (enabled when all met) + Water.
- **No** growth X/Y bar.

---


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

Keeper AFK / other work OK; assigned wisps keep pulsing.

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
- Art: wisp orbit Keeper (unassigned) and **orbit assign target** (assigned); path tween OK; selected state.
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
- Manatree panel shows **Harvest Primordial Fruit** CTA (+ needs done / Fruit ready). **No** blessing Buy rows on this panel.
- Wisps / harvest nodes still work until commit.

### Two-step Fruit harvest
1. **Intent:** RMB/interact Fruit CTA → confirm prompt (“Harvest the Primordial Fruit?”).
2. **Commit:** second confirm → set `fruit_committed = true`; **pause world**; open **Ascension shop window**. Do **not** add `ESSENCE_PER_HARVEST` (v0.3.4: next sapling starts at essence 0).

### After commit (world paused)
- **Blocked:** move, Keeper harvest channels, watering, wisp assign/reassign, Pay (already Ancient).
- **Allowed:** buy blessings (Manashards), **Ascend**.
- **No cancel back** to watering after commit (Design lock — Fruit is spent). Footer does **not** offer a soft exit that unpauses without Ascend.
- Ascend: reset stage→sapling; **`essence → 0` (Haex lock)**; wipe **wood/stone/food/manashards → 0** (Manashards also clear — Design rec, already the soft-mat wipe); keep upgrade ranks + lifetimes; `ascensions += 1`; unpause; wisps reset per §4c (`bonus_wisp` starting count).

### Ascension shop window (layout contract)
- **Separate modal** — not stacked Harvest / Ascend / Close over the blessing list (fixes Haex screenshot overlap).
- **Scrollable** blessing list (all upgrades: existing five + `wisp_haste` + `bonus_wisp`).
- Each row: name, rank/max, Manashard cost, Buy (afford state).
- **Pinned footer** outside the scroll view: shard balance + **Ascend** (primary). Optional secondary label only if it does not overlap rows — prefer **Ascend only** in footer.
- Multi-buy OK; Ascend enabled with zero purchases.
- Shop timing still Ascension-only (this window only after Fruit commit).

### Permanent upgrades (blessings — spend Manashards)

**Target:** typical Ascension bank (water ~1–3 shards/sec across the needs run) affords **about 1–2 ranks total**, not the whole tree.

```
SHOP_BASE = 400
cost_manashards(current_rank) = SHOP_BASE * (current_rank + 1)
# 0→1: 400 | 1→2: 800 | 2→3: 1200 | …
```

| upgrade_id | Max | Cost (shards) | Effect |
|------------|-----|---------------|--------|
| `deep_roots` | 10 | `400 * (rank + 1)` | `WATER_ESSENCE_PER_SEC` bonus `floor(rank / 2)` |
| `forager` | 10 | `400 * (rank + 1)` | `gather_mult += 0.05` / rank |
| `green_thumb` | 5 | `400 * (rank + 1)` | Fertilizer Grow cost −10% / rank (floor, min 1); essence unchanged |
| `keep_tools` | 1 | **1600** (expensive vs 1–2 blessing afford) | After Ascend backpack wipe, re-grant the four finished tools only |
| `shard_sight` | 5 | `400 * (rank + 1)` | `+1` shards per water pulse / rank |
| `keeper_stride` | 5 | `400 * (rank + 1)` | `MOVE_SPEED_MULT += 0.06` / rank |
| `wisp_haste` | 5 | `400 * (rank + 1)` | `WISP_PULSE_SEC -= 1` / rank (base 10 → min **5**) |
| `bonus_wisp` | 3 | `400 * (rank + 1)` | `+1` wisp at sapling / +1 capacity per rank (stacks with stage grants) |

**Examples:** bank 400 → one rank; bank 800 → two rank-1 buys. Unspent shards **and essence** wipe on Ascend (`essence → 0`).

**Wisp blessing notes:** `bonus_wisp` ranks persist; on Ascend after reset to sapling, `wisp_count = bonus_wisp_rank` immediately (then stage advances add more up to stages max + bonus).

**Code:** mirror in `fruit_upgrades.json` (or equivalent data file).

---

## 6. Pause + save slots

| Param | Default |
|-------|---------|
| `SAVE_SLOT_COUNT` | **7** |
| `PAUSE_OPENS_SLOTS` | `true` |
| `SAVE_VERSION` | **6** |

---

## 7. Save fields (`SAVE_VERSION = 6`)

```
save_version: int                  # 6
backpack: Dictionary[String, int]  # crafted stacks; migrate v5 → empty {}
ascensions: int
essence: int
upgrades: Dictionary[String, int]

stage_id: String
# growth: REMOVED

wood: int
stone: int
food: int
manashards: int

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

Migrate v4→v5: init `wisp_count` from stage progress or 0 + bonus_wisp; empty assignments; ignore old movement assumptions.

---

## 8. Loop summary (Code)

```
LMB Keeper/Wisp → select | LMB empty → deselect
RMB (Keeper selected) → walk / interact harvest or Manatree
RMB (Wisp selected) → assign to node or Manatree (manashards); RMB ground → unassign → orbit Keeper
Assigned wisps path to target then orbit it; pulse +1/10s
Pay stage_up → +1 wisp (orbits Keeper until assigned)
ESC → pause (7 slots)
```

---

## 9. Handoffs

| Who | Action |
|-----|--------|
| @Code / Engine | Multi-wisp stack on same target; independent pulses; Ascend `essence=0` + soft mats 0 |
| @Content & Lore | Drop slot-full deny; optional stack hint; Ascend wipes Essence (and leftover shards) |
| @Art Direction | Separate Ascension shop chrome (scroll list + pinned footer); Manatree care panel without Buy rows |
| @Audio | `sfx_wisp_assign` / deny / unassign / pulse — Code should wire if not already |

---

## 10. Open / locked

| Item | Status |
|------|--------|
| Grow = Fertilizer + Essence (no raw-mat stage needs) | **LOCKED Haex v0.3.5** |
| Needs-only stage advance; no growth | **SUPERSEDED v0.3.5** (Pay retired) |
| Cost curve Young→Ancient as table above | **Director interpretation — Haex may tweak** |
| Water = shards + essence income | **LOCKED** |
| 3 harvest nodes @ 1/sec | **LOCKED** |
| `SAVE_SLOT_COUNT = 7` | **LOCKED** |
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

Ping @Game Director, @Code / Engine, @Content & Lore on land.
