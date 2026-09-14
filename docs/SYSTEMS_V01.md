# Tales of the Manaforge — Systems Brief v0.1 (Restart Edition)
**Owner:** Game Design  
**Status:** Day-1 deliverable — proposed; Haex may veto stage count + watering model  
**Source of truth above this doc:** `VISION_RESTART.md` + `refs/`  
**Non-canon:** `DESIGN.md` (idle-combat), forge-hub art kit, battle audio drafts  
**Audience:** Code implements; Content names strings; Art reads stage count for tree set  
**Last updated:** 2026-09-14

---

## v0.1 scope (systems only)

**In:** point-and-click Keeper, Manatree growth stages, manual gather, Primordial Fruit prestige (few permanent upgrades), versioned save/load, minimal HUD counters.

**Out:** combat, whisps, full Forge / deep craft, equipment, Echo Chamber, WASD, mobile/web.

---

## 1. Resources (v0.1)

| ID | Player-facing (Content locks copy) | How gained | How spent in v0.1 |
|----|--------------------------------------|------------|-------------------|
| `wood` | Wood | Gather wood nodes | Stage tend costs (some stages) |
| `stone` | Stone | Gather stone nodes | Stage tend costs (some stages) |
| `food` | Food | Gather food nodes (berries/forage) | **Watering / tending** the Manatree |
| `manashards` | Manashards | Rare gather + stage-clear bursts | Optional stage boost; Fruit upgrade currency alt |
| `essence` | Essence | **Only** from Primordial Fruit harvest | Buy permanent Fruit upgrades |

No separate Water resource — watering is an action that spends `food` (caretaker fantasy: you feed/water the tree from what you forage).

**Gather (v0.1):**
```
on_interact(node):
  if busy or on_cooldown: return
  play gather → add GRANT_AMOUNT[node.resource]
  start NODE_COOLDOWN_SEC (default 3)
```

| Param | Default |
|-------|---------|
| `GATHER_WOOD` | `1` |
| `GATHER_STONE` | `1` |
| `GATHER_FOOD` | `1` |
| `GATHER_MANASHARDS` | `1` (rarer nodes / lower count on map) |
| `NODE_COOLDOWN_SEC` | `3.0` |

Map stub: enough nodes that a short walk-loop sustains watering without being AFK-idle. **No offline tick in v0.1** (whisps later).

---

## 2. Watering / tending model (**PROPOSED — Haex veto**)

**Model A (recommended): Spend-Food water**
1. Keeper clicks Manatree (interact when in range).
2. If `food >= WATER_COST` and tree not at max stage waiting for Fruit harvest:
   - spend `WATER_COST` food
   - add `WATER_GROWTH` to `manatree.growth`
3. When `growth >= stage.growth_required`, auto-advance stage, reset growth to 0 (or carry overflow — **carry overflow**, param `GROWTH_CARRIES = true`).
4. Optional: if player also holds required wood/stone for that stage’s **Tend Gate**, those are checked at stage-up (see table). If missing, growth caps at `growth_required - 1` until tend mats paid via same interact (second prompt) or auto-consumed on interact when growth full.

Simpler v0.1 implementation path:
- Watering only spends food and adds growth.
- Stage-up also checks `cost_wood` / `cost_stone` / `cost_manashards`; if unmet, show “need X” and do not advance (growth can sit at requirement).

| Param | Default |
|-------|---------|
| `WATER_COST` | `1` food |
| `WATER_GROWTH` | `10` |
| `WATER_COOLDOWN_SEC` | `0.5` (anti-spam click) |
| `GROWTH_CARRIES` | `true` |

**Rejected for v0.1 unless Haex prefers:** pure real-time AFK growth (undercuts manual gather loop); free watering on cooldown with no food sink (food becomes useless).

---

## 3. Manatree stage table (**PROPOSED — Haex veto stage count**)

**Proposal: 5 stages** (reads clearly in art; short enough for first prestige in one sitting).

| stage_id | Index | Working name (Content renames) | growth_required | cost_wood | cost_stone | cost_manashards | Bonus while at this stage |
|----------|-------|--------------------------------|-----------------|-----------|------------|-----------------|---------------------------|
| `sapling` | 0 | Sapling | — (start) | 0 | 0 | 0 | none |
| `young` | 1 | Young | `50` | `5` | `0` | `0` | `gather_mult = 1.1` |
| `mature` | 2 | Mature | `80` | `8` | `5` | `0` | `gather_mult = 1.25` |
| `elder` | 3 | Elder | `120` | `10` | `8` | `3` | `gather_mult = 1.4` |
| `ancient` | 4 | Ancient | `160` | `12` | `10` | `5` | `gather_mult = 1.6`; **Fruit ready** |

```
growth_required values use WATER_GROWTH=10 → waters to next ≈ 5 / 8 / 12 / 16
plus gather time for mats — target first Fruit ~20–40 min attentive (tune after playtest)
```

| Param | Default | Notes |
|-------|---------|-------|
| `STAGE_COUNT` | `5` | Haex may cut to 4 or stretch to 6 |
| `GATHER_MULT` | per stage | Applies to wood/stone/food grants; manashards optional |

**Ancient:** watering no longer increases stage; interact offers **Harvest Primordial Fruit** when `stage_id == ancient`.

Art: 5 tree visuals (silhouette progression); door on ancient = **later Forge**, non-interactive in v0.1.

---

## 4. Primordial Fruit prestige (3–5 upgrades)

### Harvest flow
1. At `ancient`, interact → confirm harvest.
2. Grant `essence += ESSENCE_PER_HARVEST + floor(lifetime_food_watered / ESSENCE_FOOD_DIV)`.
3. Open upgrade panel (can buy zero or more if essence allows).
4. On confirm Ascend:
   - reset `stage_id → sapling`, `growth → 0`
   - reset `wood, stone, food, manashards` to `0` (or soft keep — **reset soft mats**, keep essence + purchased ranks)
   - keep permanent upgrade ranks
   - `ascensions += 1`

| Param | Default |
|-------|---------|
| `ESSENCE_PER_HARVEST` | `3` |
| `ESSENCE_FOOD_DIV` | `50` | # extra essence from dedicated watering this run |

### Permanent upgrades (pick **5**, all available from first Fruit; ranks stack)

| upgrade_id | Max rank | Cost formula | Effect |
|------------|----------|--------------|--------|
| `deep_roots` | `10` | `1 + rank` essence | `WATER_GROWTH += 2` per rank |
| `forager` | `10` | `1 + rank` | `gather_mult += 0.05` per rank (global) |
| `green_thumb` | `5` | `2 + rank` | `-1` growth_required on all stages per rank (min 10 each) |
| `shard_sight` | `5` | `2 + 2*rank` | `+1` manashards per manashard-node gather per rank |
| `keeper_stride` | `5` | `1 + rank` | `MOVE_SPEED_MULT += 0.06` per rank |

```
cost(rank) = base_cost_table[id]  # as above; pay from essence on purchase; permanent
```

**Out of v0.1 upgrade list:** combat stats, whisps, Forge unlocks, Echo Chamber.

---

## 5. Save fields (versioned)

```
save_version: int                  # start 1
ascensions: int
essence: int
upgrades: Dictionary[String, int]  # upgrade_id → rank

stage_id: String                   # sapling…ancient
growth: int

wood: int
stone: int
food: int
manashards: int

lifetime_food_watered: int         # for essence bonus; persists across ascensions
lifetime_fruit_harvested: int

# optional QoL
keeper_position: Vector2
```

On load: if `save_version < CURRENT`, run migrate stubs (empty ok for v0.1).

| Param | Default |
|-------|---------|
| `SAVE_VERSION` | `1` |

---

## 6. Loop summary (for Code)

```
boot → load save
click ground → move Keeper
click gather node → +resource (cooldown)
click Manatree →
  if not ancient: try water (food) / try stage-up (mats + growth)
  if ancient: offer Fruit harvest → essence → buy upgrades → Ascend reset
HUD: resource counts + stage name + growth bar + essence
```

---

## 7. Open for Haex veto

1. **Stage count = 5?** (alt: 4 = merge elder/ancient feel; 6 = longer first run)
2. **Watering = spend Food?** (alt: free cooldown water + food used only for tend gates)
3. Soft mats **hard-reset** on Ascend? (recommended yes)
4. First-Fruit target band **20–40 min** OK?

---

## 8. Handoffs

| Who | Needs from this brief |
|-----|------------------------|
| @Code / Engine | Stage table + params + save schema + interact rules |
| @Content & Lore | Working names to replace; Fruit/Ascend tone |
| @Art Direction | `STAGE_COUNT = 5` tree set; gather prop types wood/stone/food/shard |
| @Audio | Events: gather, water, stage_up, fruit_harvest, ascend |

Ping @Game Director on landing; tune numbers after first Haex playtest.
