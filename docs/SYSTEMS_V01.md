# Tales of the Manaforge — Systems Brief v0.3 (Restart Edition)
**Owner:** Game Design  
**Status:** v0.3.2 — Haex: LMB/RMB input; wisps orbit assign target; Manatree assign  
**Source of truth above this doc:** `VISION_RESTART.md` + `refs/`  
**Non-canon:** `DESIGN.md` (idle-combat), forge-hub art kit, battle audio drafts  
**Audience:** Code implements; Content names strings; Art / layout for Code  
**Last updated:** 2026-09-15

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
| **v0.3.2** | **Haex:** Assigned wisps **path to node then orbit the node**. Wisps may assign to **Manatree** → pulse **manashards** (1 / `WISP_PULSE_SEC`). Input: **LMB** = select only (Keeper/Wisp/future friend); **RMB** = command (Keeper walk/interact; Wisp assign/unassign); **LMB empty ground** = deselect. `WISP_PER_NODE=1` includes Manatree as one slot. |

---

## v0.3 scope (systems only)

**In:** select-then-move Keeper, Manatree needs stages, channelled harvest (3 nodes), Wisps (AFK node gather), water income, Primordial Fruit / Manashard Ascension shop, pause + 7 slots, versioned save, minimal HUD.

**Out:** growth bar / offers, combat, full Forge, equipment, Echo Chamber, WASD, mobile/web, many duplicate harvestables, stacking multiple wisps on one node (v0.3).

---

## 1. Resources

| ID | How gained | How spent |
|----|------------|-----------|
| `wood` | Harvest Tree @ 1/sec | Stage **needs** |
| `stone` | Stone node @ 1/sec | Stage **needs** |
| `food` | Berry bush @ 1/sec | Stage **needs** |
| `manashards` | Water channel `U{1,3}` / sec; **wisp on Manatree** @ 1/10s | **Blessing shop** (Ascension permanent upgrades) |
| `essence` | Water channel `+1` / sec; Fruit harvest bonus | Stage **needs** only (not blessing shop) |

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

## 4. Stage needs (LOCKED direction — Haex)

**No `growth` field. No growth bar.** Clicking Manatree shows **needs for next stage** only. When inventory meets all needs → confirm pay → consume → advance stage.

### Cost curve rule (Director interpretation of Haex)
1. Essence cost starts at **20** for Young, then **+20** each stage.
2. Each new stage after Young introduces **one new soft mat at 10**.
3. Soft mats introduced earlier **double** each subsequent stage.

| Advance to | essence | food | wood | stone | Notes |
|------------|---------|------|------|-------|-------|
| `young` | **20** | — | — | — | First soft mat not yet |
| `mature` | **40** | **10** | — | — | Introduces food @10 |
| `elder` | **60** | **20** | **10** | — | food doubles; introduces wood @10 |
| `ancient` | **80** | **40** | **20** | **10** | food+wood double; introduces stone @10 |

```
# Named params (Code data table)
NEED_YOUNG_ESSENCE = 20
NEED_MATURE = { essence: 40, food: 10 }
NEED_ELDER  = { essence: 60, food: 20, wood: 10 }
NEED_ANCIENT = { essence: 80, food: 40, wood: 20, stone: 10 }
```

**Sapling** (start): no needs.  
**Pay action:** single “Tend / Grow” confirm when all needs met; partial progress is inventory only (no partial bank toward stage).

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
On each successful **Pay** stage advance to `young` / `mature` / `elder` / `ancient`:
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

### Assign (default: 1 wisp per target)
Valid targets: `harvest_tree` / `harvest_stone` / `harvest_berry` / **`manatree`**.
1. **LMB** wisp → select.
2. **RMB** harvest node or Manatree → assign (wisp paths there, then orbits target).
3. If that target already has a wisp: **deny** — `WISP_PER_NODE = 1` (Manatree counts as one slot).
4. Reassign: LMB wisp → RMB new free target.
5. Unassign: LMB wisp → **RMB empty ground** → returns to **orbit Keeper**.

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
Each `WISP_PULSE_SEC` while assigned: `inventory[resource] += WISP_PULSE_GRANT` (default 1) for that target’s resource (see table).

| Param | Default |
|-------|---------|
| `WISP_PER_NODE` | `1` | # includes Manatree as one slot |
| `WISP_PULSE_SEC` | `10` |
| `WISP_PULSE_GRANT` | `1` |
| `WISP_FROM_STAGES_MAX` | `4` |
| `WISP_ORBIT_RADIUS_PX` | `56` |

### Art / Audio handoff
- Art: wisp orbit Keeper (unassigned) and **orbit assign target** (assigned); path tween OK; selected state.
- Audio: soft assign confirm; optional quiet pulse (much quieter than Keeper gather).

---
## 5. Primordial Fruit / Ascend

**Model (LOCKED Haex v0.2.3): Manashard blessing shop after Fruit — NOT free pick, NOT Essence shop.**

```
essence += ESSENCE_PER_HARVEST   # default 5; for stage needs next cycle only
# Shop currency = manashards (from water income)
```

### Flow
1. At `ancient`, interact → **Harvest Primordial Fruit** (confirm).
2. Grant `ESSENCE_PER_HARVEST`; open **Blessing shop** (prices in **Manashards**).
3. Player may **buy zero or more** upgrade ranks while `manashards >= cost(next rank)` — multi-buy OK.
4. **Confirm Ascend** (always available; purchase not required).
5. Ascend resets: `stage_id → sapling`, soft mats `wood/stone/food/manashards → 0`.  
   **Keep:** essence, upgrade ranks, lifetimes, `ascensions += 1`.

### UX flags for @Code / Engine
- Shop lists all 5 blessings: name, rank/max, **Manashard cost for next rank**, afford state.
- Purchases deduct **manashards** immediately (+1 rank); show shard balance on panel.
- **No** essence prices; **no** free pick-one.
- Ascend separate from Buy; enabled even with 0 purchases.
- Content: Harvest → Spend Manashards on blessings → Ascend.
- **Shop timing LOCKED:** Ascension visit only — no mid-run / anytime Manashard shop.

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
| `green_thumb` | 5 | `400 * (rank + 1)` | Soft-mat needs −10% / rank (floor, min 1); essence needs unchanged |
| `shard_sight` | 5 | `400 * (rank + 1)` | `+1` shards per water pulse / rank |
| `keeper_stride` | 5 | `400 * (rank + 1)` | `MOVE_SPEED_MULT += 0.06` / rank |
| `wisp_haste` | 5 | `400 * (rank + 1)` | `WISP_PULSE_SEC -= 1` / rank (base 10 → min **5**) |
| `bonus_wisp` | 3 | `400 * (rank + 1)` | `+1` wisp at sapling / +1 capacity per rank (stacks with stage grants) |

**Examples:** bank 400 → one rank; bank 800 → two rank-1 buys. Unspent shards wipe on Ascend.

**Wisp blessing notes:** `bonus_wisp` ranks persist; on Ascend after reset to sapling, `wisp_count = bonus_wisp_rank` immediately (then stage advances add more up to stages max + bonus).

**Code:** mirror in `fruit_upgrades.json` (or equivalent data file).

---

## 6. Pause + save slots

| Param | Default |
|-------|---------|
| `SAVE_SLOT_COUNT` | **7** |
| `PAUSE_OPENS_SLOTS` | `true` |
| `SAVE_VERSION` | **5** |

---

## 7. Save fields (`SAVE_VERSION = 5`)

```
save_version: int                  # 5
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
| @Code / Engine | LMB/RMB map; wisp path+orbit target; Manatree→manashards pulse; wire wisp SFX; save v5 |
| @Content & Lore | LMB/RMB hints; Manatree-wisp assign (manashards); deny if slot full; blessing names |
| @Art Direction | Wisp orbit around Keeper; selected; parked on node; Keeper selected ring |
| @Audio | `sfx_wisp_assign` / deny / unassign / pulse — Code should wire if not already |

---

## 10. Open / locked

| Item | Status |
|------|--------|
| Needs-only stage advance; no growth | **LOCKED Haex v0.2.0** |
| Cost curve Young→Ancient as table above | **Director interpretation — Haex may tweak** |
| Water = shards + essence income | **LOCKED** |
| 3 harvest nodes @ 1/sec | **LOCKED** |
| `SAVE_SLOT_COUNT = 7` | **LOCKED** |
| Offer-for-growth | **REMOVED** |
| Ascension = Manashard blessing shop | **LOCKED Haex v0.2.3** |
| Shop timing = Ascension-only after Fruit | **LOCKED Haex v0.2.4** |
| Shop costs ~1–2 ranks/Ascension (`SHOP_BASE=400`) | **LOCKED Haex intent v0.2.5** |
| Wisps: 1/stage advance, 1/node, +1/10s | **LOCKED Haex v0.3.0** |
| Keeper select-then-move | **LOCKED Haex v0.3.0** |
| Keeper must be selected for all actions | **LOCKED Haex v0.3.1** |
| Unassigned wisps orbit Keeper | **LOCKED Haex v0.3.1** |
| LMB select / RMB command / LMB empty deselect | **LOCKED Haex v0.3.2** |
| Assigned wisps orbit their target; Manatree→manashards | **LOCKED Haex v0.3.2** |
| Wisp blessings `wisp_haste` + `bonus_wisp` | **LOCKED Haex v0.3.0** |
| Pick-one-free Ascension | **REVOKED** |
| Essence blessing shop | **REVOKED** |

Ping @Game Director, @Code / Engine, @Content & Lore on land.
