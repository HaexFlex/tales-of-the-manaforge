# Tales of the Manaforge — Systems Brief v0.1 (Restart Edition)
**Owner:** Game Design  
**Status:** v0.1.5 — Haex: SAVE_SLOT_COUNT = 7  
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
| v0.1 | Day-1: 5 stages, Food-spend water, Fruit upgrades, save schema |
| v0.1.1 | Free water click; Offer all mats; Essence Fruit-only; SAVE_VERSION 2 |
| v0.1.2 | Haex playtest: 3 harvest channels @1/sec; water pays shards+essence+growth; Essence not Fruit-only; SAVE_VERSION 3 |
| v0.1.3 | Haex growth nerf: WATER_GROWTH 1; thresholds 120/200/320/480; offers 3/3/2/6; deep_roots +1/rank |
| v0.1.4 | Pause menu: SAVE_SLOT_COUNT defaulted to 3 |
| **v0.1.5** | **Haex override:** `SAVE_SLOT_COUNT = **7**` (one per Manatree stage + spare). Pause save/load unchanged otherwise; `SAVE_VERSION` payload still 3. |

---

## v0.1 scope (systems only)

**In:** point-and-click Keeper, Manatree growth stages, channelled harvest (3 nodes), channelled watering (shards + essence + growth), Offer mats, Primordial Fruit / Ascend, versioned save, minimal HUD.

**Out:** combat, whisps, full Forge, equipment, Echo Chamber, WASD, mobile/web, many duplicate harvestables.

---

## 1. Resources

| ID | How gained (v0.1.2) | How spent |
|----|---------------------|-----------|
| `wood` | Harvest Tree channel @ 1/sec | Offer + stage gates |
| `stone` | Stone node channel @ 1/sec | Offer + stage gates |
| `food` | Berry bush channel @ 1/sec | Offer + stage gates |
| `manashards` | **Watering channel** `U{1,3}` / sec; also Offer sink | Offer + stage gates |
| `essence` | **Watering channel** `+1` / sec; also Primordial Fruit harvest bonus | Permanent Fruit upgrades |

---

## 2. Harvest nodes (LOCKED — Haex)

Exactly **three** interactive harvest nodes on the map. Not many of each.

| node_id | Prop | Resource | Rate while harvesting |
|---------|------|----------|------------------------|
| `harvest_tree` | Harvest Tree (distinct from deco / Manatree) | `wood` | `HARVEST_WOOD_PER_SEC` (default **1**) |
| `harvest_stone` | Stone | `stone` | `HARVEST_STONE_PER_SEC` (default **1**) |
| `harvest_berry` | Berry bush | `food` | `HARVEST_FOOD_PER_SEC` (default **1**) |

### Channel rules
```
on_interact(harvest_node):
  start channel on that node (cancel prior channel)
each tick while channel active and Keeper in range:
  if elapsed >= 1.0s since last pulse:
    inventory[resource] += HARVEST_*_PER_SEC * gather_mult   # floor after mult, min 1 if mult>=1
    play gather SFX pulse
cancel channel if: Keeper walks away / clicks elsewhere / starts another channel / UI cancel
```

| Param | Default |
|-------|---------|
| `HARVEST_WOOD_PER_SEC` | `1` |
| `HARVEST_STONE_PER_SEC` | `1` |
| `HARVEST_FOOD_PER_SEC` | `1` |
| `HARVEST_RANGE_PX` | `48` (tune with Art feet anchors) |
| `CHANNEL_PULSE_SEC` | `1.0` |

**No manashard harvest node.** Shards come from watering (and leftover inventory).

### Layout (for Code / Art)
- Clearing with **many decorative (non-harvest) forest trees**
- **One** Harvest Tree, **one** Stone, **one** Berry bush
- Manatree landmark separate (growth / water / Fruit)

---

## 3. Manatree care

### 3a. Water channel (LOCKED — Haex)
Primary interact on Manatree (when not resolving Fruit/Ascend UI) starts **Water** channel.

```
each CHANNEL_PULSE_SEC while watering and in range and stage != fruit-only-block:
  manashards += randi_range(WATER_SHARD_MIN, WATER_SHARD_MAX)   # 1..3 uniform
  essence    += WATER_ESSENCE_PER_SEC                            # 1
  growth     += WATER_GROWTH + deep_roots_bonus                  # still grows the tree
  lifetime_waters += 1
  lifetime_shards_from_water += shards_this_pulse
  lifetime_essence_from_water += WATER_ESSENCE_PER_SEC
```

At **Ancient**, Water channel still allowed for shard/essence payout **or** Haex may prefer Fruit prompt only — **default: Water still works at Ancient** (payout + no stage growth past max); Fruit is a separate confirm action from the same interact menu.

| Param | Default |
|-------|---------|
| `WATER_SHARD_MIN` | `1` |
| `WATER_SHARD_MAX` | `3` |
| `WATER_ESSENCE_PER_SEC` | `1` |
| `WATER_GROWTH` | `1` | # per pulse, same pulse as payout — v0.1.3 slowed |
| `CHANNEL_PULSE_SEC` | `1.0` |

**Removed:** single-click water with cooldown only; Food spend on water.

### 3b. Offer resources (kept from v0.1.1)
Spend soft mats at Manatree for extra growth (does not grant essence).

| Resource | `OFFER_COST` | `OFFER_GROWTH` |
|----------|--------------|----------------|
| `wood` | `1` | `3` |
| `stone` | `1` | `3` |
| `food` | `1` | `2` |
| `manashards` | `1` | `6` |

`OFFER_COOLDOWN_SEC = 0.25`. Offers are instant (not channelled).

### 3c. Stage-up
When `growth >= growth_required` for next stage and gate costs held → consume gate → advance. `GROWTH_CARRIES = true`.

---

## 4. Manatree stage table (5 — unchanged count)

| stage_id | growth_required | cost_wood | cost_stone | cost_food | cost_manashards | Bonus |
|----------|-----------------|-----------|------------|-----------|-----------------|-------|
| `sapling` | — | 0 | 0 | 0 | 0 | — |
| `young` | `120` | `4` | `2` | `2` | `0` | `gather_mult = 1.1` |
| `mature` | `200` | `6` | `4` | `4` | `1` | `gather_mult = 1.25` |
| `elder` | `320` | `8` | `6` | `6` | `2` | `gather_mult = 1.4` |
| `ancient` | `480` | `10` | `8` | `8` | `4` | `gather_mult = 1.6`; Fruit ready |

`gather_mult` applies to harvest channel pulses (wood/stone/food).

---


### Pace target (v0.1.3)
- Water-only to Ancient: `sum(growth_required) / WATER_GROWTH` = `1120 / 1` ≈ **19 minutes** of channel time (plus walking/gates).
- Offers shorten that if the Keeper gathers; gates still force a wood/stone/food/shard mix.
- First Fruit should feel slow and meaningful — not reachable by a minute of spam.
- Shard/essence income unchanged at 1 tick/sec while watering.

## 5. Primordial Fruit / Ascend

Essence now also comes from watering — Fruit is a **burst + prestige reset**, not the sole essence source.

```
essence += ESSENCE_PER_HARVEST
         + floor(lifetime_essence_from_water_this_run / ESSENCE_WATER_BONUS_DIV)  # optional; default off
# Simpler v0.1.2 default:
essence += ESSENCE_PER_HARVEST   # flat bonus on top of what watering already paid
```

| Param | Default |
|-------|---------|
| `ESSENCE_PER_HARVEST` | `5` |

Ascend: reset stage/growth + soft mats (`wood/stone/food/manashards`); **keep** essence + upgrade ranks + lifetime totals; `ascensions += 1`.

### Permanent upgrades (unchanged ids)

| upgrade_id | Max | Cost | Effect |
|------------|-----|------|--------|
| `deep_roots` | 10 | `1+rank` | `WATER_GROWTH += 1` / rank (v0.1.3; base water is 1) |
| `forager` | 10 | `1+rank` | `gather_mult += 0.05` / rank |
| `green_thumb` | 5 | `2+rank` | `-1` growth_required / rank (min 10) |
| `shard_sight` | 5 | `2+2*rank` | `+1` to each water shard roll min **or** flat `+1` shards per water pulse / rank — **default:** add rank to shard roll result after clamp to max+rank |
| `keeper_stride` | 5 | `1+rank` | `MOVE_SPEED_MULT += 0.06` / rank |

`shard_sight` v0.1.2 default: `shards = randi_range(WATER_SHARD_MIN, WATER_SHARD_MAX) + shard_sight_rank`.

---

## 6. Pause + save slots (v0.1.5)

| Param | Default | Notes |
|-------|---------|-------|
| `SAVE_SLOT_COUNT` | **`7`** | Haex lock — stage checkpoints + spare |
| `PAUSE_OPENS_SLOTS` | `true` | Pause → Resume / Save / Load / (Quit optional) |
| `SAVE_VERSION` | `3` | Per-slot payload schema (unchanged from v0.1.2 channel fields) |

**Behavior**
- Exactly `SAVE_SLOT_COUNT` slots (1..7). Empty slots show empty; occupied show stage name + playtime if Code tracks it.
- Save writes full game state into chosen slot; Load replaces current run from slot (confirm if dirty — Code UX).
- Ascend / water / harvest rules unchanged; slots are orthogonal to prestige.

## 7. Save fields (`SAVE_VERSION = 3`)

```
save_version: int                  # 3
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
lifetime_shards_from_water: int
lifetime_essence_from_water: int
lifetime_offered: Dictionary[String, int]
lifetime_fruit_harvested: int
lifetime_harvested: Dictionary[String, int]  # wood/stone/food totals

keeper_position: Vector2
# do not persist active channel — cancel on load
```

Migrate v2→v3: init new lifetime fields to 0; remove assumptions of click-gather cooldowns / Fruit-only essence.

---

## 8. Loop summary (Code)

```
click ground → move (cancels channel if out of range)
click harvest_tree | harvest_stone | harvest_berry → channel → +1 res / sec
click Manatree →
  Water channel → each sec: shards U{1,3}, essence+1, growth+WATER_GROWTH
  OR Offer mat (instant)
  OR Fruit/Ascend when ancient
decorative trees: no interact
```

---

## 9. Handoffs

| Who | Action |
|-----|--------|
| @Code / Engine | Channels + water payout + deco layout; save v3 payload; **pause + 7 save slots** |
| @Content & Lore | Channel / “Harvesting…” / water pulse copy; drop multi-node gather phrasing |
| @Art Direction | Distinct Harvest Tree vs deco trees; single stone + berry props if missing |
| @Audio | Pulse SFX each harvest/water tick (reuse gather / `sfx_tree_water`) |

---

## 10. Open / locked

| Item | Status |
|------|--------|
| 3 harvest nodes @ 1/sec channel | **LOCKED Haex** |
| Water: shards 1–3 + 1 essence / sec | **LOCKED Haex** |
| Slow growth curve (WATER_GROWTH=1, raised thresholds) | **LOCKED Haex intent v0.1.3** |
| Pause + `SAVE_SLOT_COUNT = 7` | **LOCKED Haex v0.1.5** |
| Essence Fruit-only | **REVOKED** |
| Deco trees, one of each harvest | **LOCKED Haex** |
| Offers + 5 stages + Fruit Ascend | Kept |
| Water at Ancient still pays | Default yes — Haex may veto |

Ping @Game Director + @Code / Engine on land.
