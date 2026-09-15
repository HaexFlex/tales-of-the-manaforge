# Tales of the Manaforge — Systems Brief v0.2 (Restart Edition)
**Owner:** Game Design  
**Status:** v0.2.0 — Haex: abandon growth; stages advance by paying **needs** only  
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
| **v0.2.0** | **Haex MAJOR:** remove Manatree **growth** entirely (`growth_required`, `WATER_GROWTH`, offer-for-growth). Stages advance **only** by paying **needs**. Cost curve: +20 essence/stage; each stage introduces one new soft mat at 10; prior soft mats **double**. Water = income only (shards + essence). UI shows needs only. `SAVE_VERSION` → **4**. |

---

## v0.2 scope (systems only)

**In:** point-and-click Keeper, Manatree stages via **needs payment**, channelled harvest (3 nodes), channelled watering (shards + essence income), Primordial Fruit / Ascend, pause + 7 save slots, versioned save, minimal HUD.

**Out:** growth bar / WATER_GROWTH / offer-for-growth, combat, whisps, full Forge, equipment, Echo Chamber, WASD, mobile/web, many duplicate harvestables.

---

## 1. Resources

| ID | How gained | How spent |
|----|------------|-----------|
| `wood` | Harvest Tree @ 1/sec | Stage **needs** |
| `stone` | Stone node @ 1/sec | Stage **needs** |
| `food` | Berry bush @ 1/sec | Stage **needs** |
| `manashards` | Water channel `U{1,3}` / sec | Prestige upgrades / future sinks (not required for stage needs in v0.2) |
| `essence` | Water channel `+1` / sec; Fruit harvest bonus | Stage **needs** + permanent upgrades |

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

## 5. Primordial Fruit / Ascend

```
essence += ESSENCE_PER_HARVEST   # default 5; on top of watered essence
```

Ascend resets: `stage_id → sapling`, soft mats `wood/stone/food/manashards → 0`.  
**Keep:** essence, upgrades, lifetimes, `ascensions += 1`.  
**Do not** reset/reference `growth` (field removed).

### Permanent upgrades (retuned for needs-only)

| upgrade_id | Max | Cost | Effect |
|------------|-----|------|--------|
| `deep_roots` | 10 | `1+rank` | `WATER_ESSENCE_PER_SEC += 1` every **2** ranks (ranks 2,4,6…); odd ranks no-op **or** simpler: `+0` — **default v0.2:** `WATER_ESSENCE_PER_SEC += 1` per 2 ranks via `floor(rank/2)` |
| `forager` | 10 | `1+rank` | `gather_mult += 0.05` / rank |
| `green_thumb` | 5 | `2+rank` | Stage soft-mat needs −10% per rank (floor, min 1 if need > 0); essence needs unchanged |
| `shard_sight` | 5 | `2+2*rank` | `+1` shards per water pulse / rank |
| `keeper_stride` | 5 | `1+rank` | `MOVE_SPEED_MULT += 0.06` / rank |

---

## 6. Pause + save slots

| Param | Default |
|-------|---------|
| `SAVE_SLOT_COUNT` | **7** |
| `PAUSE_OPENS_SLOTS` | `true` |
| `SAVE_VERSION` | **4** |

---

## 7. Save fields (`SAVE_VERSION = 4`)

```
save_version: int                  # 4
ascensions: int
essence: int
upgrades: Dictionary[String, int]

stage_id: String
# growth: REMOVED

wood: int
stone: int
food: int
manashards: int

lifetime_waters: int
lifetime_shards_from_water: int
lifetime_essence_from_water: int
lifetime_fruit_harvested: int
lifetime_harvested: Dictionary[String, int]

keeper_position: Vector2
```

Migrate v3→v4: drop `growth`, drop `lifetime_offered` if present; ignore offer UI.

---

## 8. Loop summary (Code)

```
click ground → move
click harvest_* → channel +1 res/sec
click Manatree →
  show needs for next stage (or Fruit if ancient)
  Water channel → shards + essence / sec (no growth)
  Pay needs when met → stage_up
decorative trees: no interact
ESC → pause (7 slots); world frozen
```

---

## 9. Handoffs

| Who | Action |
|-----|--------|
| @Code / Engine | Remove growth/offers; needs table; Pay action; save v4; water income only |
| @Content & Lore | Replace growth X/Y copy with needs checklist; remove Offer verbs |
| @Art Direction | No change required for needs UI (panel language OK) |
| @Audio | Drop offer cue if any; keep water/harvest pulses; optional pay confirm |

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

Ping @Game Director, @Code / Engine, @Content & Lore on land.
