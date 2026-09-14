# Tales of the Manaforge — Systems Brief v0.1 (Restart Edition)
**Owner:** Game Design  
**Status:** v0.1.1 — Haex watering veto applied (2026-09-14)  
**Source of truth above this doc:** `VISION_RESTART.md` + `refs/`  
**Non-canon:** `DESIGN.md` (idle-combat), forge-hub art kit, battle audio drafts  
**Audience:** Code implements; Content names strings; Art reads stage count for tree set  
**Last updated:** 2026-09-14

**Art locks (Haex):** Keeper 128², tiles 64², 1280×720 NN  
**Tone (Haex):** warm + lightly melancholic

---

## Changelog

| Ver | Change |
|-----|--------|
| v0.1 | Day-1: 5 stages, Food-spend water, Fruit upgrades, save schema |
| **v0.1.1** | **Haex veto:** watering does **not** spend Food. Free water adds growth. Wood / Stone / Food / Manashards all contribute via **Offer** growth + stage gates. Essence remains Fruit-only. `SAVE_VERSION` → `2`. |

---

## v0.1 scope (systems only)

**In:** point-and-click Keeper, Manatree growth stages, manual gather, Primordial Fruit prestige (few permanent upgrades), versioned save/load, minimal HUD counters.

**Out:** combat, whisps, full Forge / deep craft, equipment, Echo Chamber, WASD, mobile/web.

---

## 1. Resources (v0.1)

| ID | Player-facing (Content locks copy) | How gained | How spent in v0.1 |
|----|--------------------------------------|------------|-------------------|
| `wood` | Wood | Gather wood nodes | **Offer** to tree (growth) + stage gates |
| `stone` | Stone | Gather stone nodes | **Offer** to tree (growth) + stage gates |
| `food` | Food | Gather food nodes (berries/forage) | **Offer** to tree (growth) + stage gates — **not** watering cost |
| `manashards` | Manashards | Rare gather nodes | **Offer** to tree (growth) + stage gates |
| `essence` | Essence | **Only** from Primordial Fruit harvest | Buy permanent Fruit upgrades |

No Water resource. **Watering is a free tend action** (no inventory spend).

**Gather (v0.1):**
```
on_interact(node):
  if busy or on_cooldown: return
  play gather → add GRANT_AMOUNT[node.resource] * gather_mult
  start NODE_COOLDOWN_SEC
```

| Param | Default |
|-------|---------|
| `GATHER_WOOD` | `1` |
| `GATHER_STONE` | `1` |
| `GATHER_FOOD` | `1` |
| `GATHER_MANASHARDS` | `1` |
| `NODE_COOLDOWN_SEC` | `3.0` |

**No offline tick in v0.1** (whisps later).

---

## 2. Manatree care model (LOCKED direction — Haex)

Two ways to push growth before Ancient; stage-up still consumes a **gate cost** mix.

### 2a. Water (free)
1. Keeper clicks Manatree → choose **Water** (or primary interact = Water when not Ancient).
2. If not Ancient and off cooldown:
   - spend **nothing**
   - `growth += WATER_GROWTH` (plus `deep_roots` ranks)
   - `lifetime_waters += 1`
3. Cooldown: `WATER_COOLDOWN_SEC`.

| Param | Default |
|-------|---------|
| `WATER_GROWTH` | `8` |
| `WATER_COOLDOWN_SEC` | `1.0` |

### 2b. Offer resources (all four soft mats)
From Manatree interact menu: **Offer Wood / Stone / Food / Manashards**.

```
on_offer(resource_id):
  cost = OFFER_COST[resource_id]          # usually 1
  if inventory[resource_id] < cost: deny
  inventory[resource_id] -= cost
  growth += OFFER_GROWTH[resource_id]
  lifetime_offered[resource_id] += cost
```

| Resource | `OFFER_COST` | `OFFER_GROWTH` | Role |
|----------|--------------|----------------|------|
| `wood` | `1` | `12` | Structure / bulk growth |
| `stone` | `1` | `12` | Structure / bulk growth |
| `food` | `1` | `10` | Care / nurture (replaces old water-sink) |
| `manashards` | `1` | `25` | Strong but scarce spike |

Offers ignore water cooldown (separate `OFFER_COOLDOWN_SEC = 0.25` anti-spam).

### 2c. Stage-up (growth + gate)
When `growth >= growth_required` for the **next** stage:
- If inventory meets that stage’s `cost_wood / cost_stone / cost_food / cost_manashards`, consume them and advance.
- Else growth may sit at requirement; HUD shows missing mats (Content strings).
- Overflow: if `GROWTH_CARRIES`, excess growth carries into the new stage.

| Param | Default |
|-------|---------|
| `GROWTH_CARRIES` | `true` |

**Ancient:** no Water/Offer growth; interact offers **Harvest Primordial Fruit**.

---

## 3. Manatree stage table (5 stages — default until Haex changes count)

| stage_id | Index | Display name (Content) | growth_required (to enter) | cost_wood | cost_stone | cost_food | cost_manashards | Bonus while here |
|----------|-------|------------------------|----------------------------|-----------|------------|-----------|-----------------|------------------|
| `sapling` | 0 | Sapling | — (start) | 0 | 0 | 0 | 0 | none |
| `young` | 1 | Young | `40` | `4` | `2` | `2` | `0` | `gather_mult = 1.1` |
| `mature` | 2 | Mature | `70` | `6` | `4` | `4` | `1` | `gather_mult = 1.25` |
| `elder` | 3 | Elder | `100` | `8` | `6` | `6` | `2` | `gather_mult = 1.4` |
| `ancient` | 4 | Ancient | `140` | `10` | `8` | `8` | `4` | `gather_mult = 1.6`; **Fruit ready** |

```
Rough waters-only (WATER_GROWTH=8): ~5 / 9 / 13 / 18 waters between stages
Offers speed this up; gates force a gather mix — first Fruit target still ~20–40 min attentive
```

| Param | Default |
|-------|---------|
| `STAGE_COUNT` | `5` |

Art: 5 tree visuals; ancient door = later Forge, non-interactive in v0.1.

---

## 4. Primordial Fruit prestige

### Harvest flow
1. At `ancient`, interact → confirm harvest.
2. `essence += ESSENCE_PER_HARVEST + floor(lifetime_waters / ESSENCE_WATER_DIV) + floor(lifetime_offers_total / ESSENCE_OFFER_DIV)`
3. Upgrade panel (Essence only).
4. Ascend confirm:
   - `stage_id → sapling`, `growth → 0`
   - reset `wood, stone, food, manashards` → `0`
   - keep `essence`, upgrade ranks, lifetime counters, `ascensions += 1`

| Param | Default |
|-------|---------|
| `ESSENCE_PER_HARVEST` | `3` |
| `ESSENCE_WATER_DIV` | `20` |
| `ESSENCE_OFFER_DIV` | `30` |

### Permanent upgrades (5)

| upgrade_id | Max rank | Cost (essence) | Effect |
|------------|----------|----------------|--------|
| `deep_roots` | `10` | `1 + rank` | `WATER_GROWTH += 2` per rank |
| `forager` | `10` | `1 + rank` | `gather_mult += 0.05` per rank |
| `green_thumb` | `5` | `2 + rank` | `-1` growth_required all stages per rank (min 10) |
| `shard_sight` | `5` | `2 + 2*rank` | `+1` manashards per shard-node gather per rank |
| `keeper_stride` | `5` | `1 + rank` | `MOVE_SPEED_MULT += 0.06` per rank |

**Out of v0.1:** combat stats, whisps, Forge, Echo Chamber. Essence never bought with soft mats.

---

## 5. Save fields (versioned)

```
save_version: int                  # CURRENT = 2
ascensions: int
essence: int
upgrades: Dictionary[String, int]

stage_id: String
growth: int

wood: int
stone: int
food: int
manashards: int

lifetime_waters: int
lifetime_offered: Dictionary[String, int]  # wood/stone/food/manashards
lifetime_fruit_harvested: int

keeper_position: Vector2
```

Migrate v1 → v2: drop `lifetime_food_watered` if present; init `lifetime_waters = 0`, `lifetime_offered = {}`. Remove any Food-cost on water.

| Param | Default |
|-------|---------|
| `SAVE_VERSION` | `2` |

---

## 6. Loop summary (for Code)

```
boot → load save (migrate to v2)
click ground → move Keeper
click gather node → +resource
click Manatree →
  if not ancient:
    Water (free, +WATER_GROWTH) OR Offer wood/stone/food/shards (+OFFER_GROWTH)
    if growth met + gate costs held → consume gate → stage_up
  if ancient:
    Fruit harvest → essence → buy upgrades → Ascend reset
HUD: four soft mats + essence + stage + growth bar
```

---

## 7. Still open / locked

| Item | Status |
|------|--------|
| Watering spends Food | **Rejected by Haex** |
| Free water + multi-resource offers | **Locked direction** |
| Canvas 128 / tiles 64 / 720p NN | **Locked by Haex** |
| Tone warm + lightly melancholic | **Locked by Haex** |
| Stage count = 5 | Default until Haex changes |
| Soft mats hard-reset on Ascend | Default yes |
| First-Fruit ~20–40 min | Tune after playtest |

---

## 8. Handoffs

| Who | Action |
|-----|--------|
| @Code / Engine | Rewire water (no Food spend); add Offer actions + `cost_food` gates; save v2; drop Food-water path |
| @Content & Lore | Add Offer verb strings; remove “spend Food to water” copy if any |
| @Art Direction | No stage-count change; optional Offer UI affordance |
| @Audio | Keep `sfx_tree_water`; add offer confirm cue if distinct (`sfx_tree_offer`) |

Ping @Game Director + @Code / Engine on this revision.
