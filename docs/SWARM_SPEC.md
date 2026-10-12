# Mossmite swarm: FINAL implementation spec (Tales of the Manaforge)

**Status:** Final. Implement exactly as written. **Every number marked PLACEHOLDER is a tuning value, not a lock.**
**Source of truth:** `/workspace/swarm_bug/v72.py` (it runs v71.py, vfill_rows.py, vfill_front_fix.py with MODE="none", swarm.py, and `/workspace/combat_sim.py`), with results in `v72_out.txt` and the write-up in `variant_cost7plus2.md`. Where this doc and the sim disagree, the sim wins.
**Names:** from `/home/box/manaforge/cast_v2/swarm_bug_DRAFT_v1.json` (Content DRAFT).

---

## 1. Identity

| Field | Value |
|---|---|
| id | `foe_mossmite` |
| Name (plural / one / swarm label) | `foe_mossmite_name` "Mossmites" / `foe_mossmite_name_one` "Mossmite" / `foe_mossmite_swarm` "{count} Mossmites" |
| Description | `foe_mossmite_desc` |
| Role | **Filler only.** It is never in a spawn table (`SPAWN`) and never gets the variety bias. It only spends threat budget left over after the beasts have rolled. |
| Unit | One **swarm** takes one enemy slot and holds n bugs, 1 ≤ n ≤ 10 (PLACEHOLDER cap 10). It takes one turn per round as a single combatant. |

---

## 2. Stats for a swarm of n living bugs (all PLACEHOLDER)

| Stat | Formula |
|---|---|
| HP (pool) | max HP = n at spawn (1 HP per bug, PLACEHOLDER `hp_per_bug = 1`) |
| Bugs alive | `bugs = ceil(hp / hp_per_bug)` = hp, since HP is always an integer |
| Might | `ceil(n/2) - 2` (can go negative) |
| Arcana | 1 (not used, because the attack is physical) |
| Res | `floor(n/3)` |
| Ward | 2 |
| Swift | 4 |
| Vit / Fate | none (HP is set directly); Fate 0, so it never crits |
| Attack | One physical **melee Strike** per turn (`kind = "phys"`). Like any melee, it reaches only the party's front row while anyone stands there. It has no telegraph or special ability (`tel = "none"`). |
| Damage die | `die_size(Might)` = **d4** for every n, because `max(4, ceil(Might/2))` ≤ 4 |

Combat uses the standard rules from combat_sim:
- **To hit:** 2d6 + Might vs 2d6 + floor((def Res + def Swift)/2).
- **Damage:** max(1, 1d4 + Might - floor(def Res/2)), then the graze ×0.5 / hit ×1 / crush ×2 multiplier, round half up, minimum 1.
- So **a landed hit always deals at least 1**, even at negative Might.
- **Defending:** party melee is checked against floor((Res + 4)/2) with soak floor(Res/2). Party magic is checked against floor((2 + 4)/2) = 3 with soak floor(2/2) = 1.

### Table, n = 1..10
| n | HP | Might | Res | Ward | Swift | Die | Melee def / soak | Magic def / soak | Threat |
|---|---|---|---|---|---|---|---|---|---|
| 1 | 1 | -1 | 0 | 2 | 4 | d4 | 2 / 0 | 3 / 1 | 7 |
| 2 | 2 | -1 | 0 | 2 | 4 | d4 | 2 / 0 | 3 / 1 | 9 |
| 3 | 3 | 0 | 1 | 2 | 4 | d4 | 2 / 0 | 3 / 1 | 11 |
| 4 | 4 | 0 | 1 | 2 | 4 | d4 | 2 / 0 | 3 / 1 | 13 |
| 5 | 5 | 1 | 1 | 2 | 4 | d4 | 2 / 0 | 3 / 1 | 15 |
| 6 | 6 | 1 | 2 | 2 | 4 | d4 | 3 / 1 | 3 / 1 | 17 |
| 7 | 7 | 2 | 2 | 2 | 4 | d4 | 3 / 1 | 3 / 1 | 19 |
| 8 | 8 | 2 | 2 | 2 | 4 | d4 | 3 / 1 | 3 / 1 | 21 |
| 9 | 9 | 3 | 3 | 2 | 4 | d4 | 3 / 1 | 3 / 1 | 23 |
| 10 | 10 | 3 | 3 | 2 | 4 | d4 | 3 / 1 | 3 / 1 | 25 |

Reference from v71final, against Keeper: a 10-bug swarm deals 0.43 damage per turn, a 5-bug swarm 0.10, and a 1-bug swarm 0.03. An Acorn imp A (37 HP) deals 3.96.

---

## 3. Threat cost and budget handling
- Room budget (unchanged): `B(D) = 90 + 2(D-1)` for D ≤ 10, and `108 + 6(D-10)` for D > 10.
- Swarm threat = **7 + 2·(n-1)** (PLACEHOLDER `OPEN = 7`, `PER = 2`).
  - Opening a new swarm costs 7, and that buys its first bug.
  - Each extra bug costs 2, so a full 10-bug swarm costs 25.
- `leftover = B(D) - sum(threat of the beasts rolled)`.
- **Unspent leftover is discarded** after the fill. It does not carry to the next room or into loot.
- Swarm threat counts toward the room's threat total for anything that reads it.

---

## 4. Room fill algorithm (implement exactly)

```
function roll_room_with_mossmites(D):
    room = roll_room(D)          # baseline, unchanged: weighted spawn table, variety bias,
                                 # up to MAX_FOES=6, then place_rows() (melee front, ranged
                                 # back, 3 per row, overflow spills). Beasts keep these slots/rows.
    rem = budget(D) - sum(e.threat for e in room)
    swarms = []
    n_front = count(e in room where e.row == "front")      # beasts only at this point

    # Phase A: open swarms. Front first, then back. One bug each.
    while len(room) < 6 and rem >= OPEN:                    # OPEN = 7
        sw = new Swarm(n=1, threat=OPEN)
        if n_front < 3: sw.row = "front"; n_front += 1
        else:           sw.row = "back"
        room.append(sw)          # appended AFTER all beasts: its slot index = position in list
        swarms.append(sw)
        rem -= OPEN

    # Phase B: grow swarms one bug at a time
    while rem >= PER:                                       # PER = 2
        growable = [s in swarms where s.n < 10]
        if growable is empty: break
        s = uniform_random_choice(growable)                 # independent draw for EVERY bug
        s.n += 1; s.threat += PER; rem -= PER

    # rem is discarded
    return room
```

**Order and tie-breaks:**
- Phase A always finishes before Phase B. Every empty slot that fits gets opened before any swarm grows.
- **Which swarm grows first: none is favoured.** Each extra bug goes to a swarm picked uniformly at random from the swarms below 10 bugs, using the room RNG. Draws repeat until the budget is under 2 or every swarm has 10 bugs.
- Rows: the 3-front-slot limit counts beasts and swarms together. The back row has no explicit check because the total cap is 6. If beasts fill 3 back slots and the front holds no beasts, swarms only ever go front.
- **Slot index** (used for turn-order ties and for "front row first, then slot" targeting) is list order. That means all beasts first (front beasts, then back beasts, per `place_rows`), then swarms in the order they were opened. A front-row swarm can therefore have a higher slot index than a back-row beast.
- Swarms are added after `place_rows`. Do not re-run `place_rows` after adding swarms.

**Edge cases:**
| Case | Result |
|---|---|
| 6 beasts already (no empty slot) | No swarm. Phase B has no swarm to grow. The whole leftover is discarded. |
| leftover < 7 | No swarm and no growth (growth needs a swarm). It is discarded. Share of rooms with 0 bugs: D1 16.6%, D5 12.6%, D10 9.5%, D20 22.7%. |
| Every swarm at 10 bugs | Stop. The rest is discarded. |
| Odd remainder < 2 | Discarded. |
| A room of only swarms | Impossible as long as the baseline rolls at least one beast. |
| Boss rooms | Not simmed. v72 uses `roll_room(D)` with boss=False. Leave swarms out of boss rooms until simmed (OPEN QUESTION). |

---

## 5. Damage, bug count and death
- Damage subtracts from the swarm's HP pool. **Bugs alive = current HP** (ceil(hp/1)).
- Every point of damage removes one bug. The sprite and count label update right away to "{count} Mossmites".
- **Death:** the swarm is out only when HP ≤ 0, i.e. 0 bugs.
  - The standard "Calmed at ≤10% HP" rule does **not** apply to swarms. `Swarm.alive()` is `hp > 0 and bugs >= 1`.
  - A 10-bug swarm on 1 HP still acts, as a 1-bug swarm.
- **No overkill carry.** Damage beyond the swarm's remaining HP is lost. One killing hit removes the whole swarm and nothing spills to another foe. (MODE="none" in the sim.)
- **Might uses the current bug count** whenever the swarm attacks.
  - Sim detail: Res is only recomputed from the current bug count when the swarm starts its own turn. Until then it keeps its spawn value or the value from its last turn.
  - So a damaged swarm keeps its older, higher Res, and its defence and soak against party hits, until it acts.
  - Engine must reproduce this to match the sim. If the engine updates Res live instead, flag it as an un-simmed change.
- Party targeting has no special case. Auto and Strike use "front row first, then slot". Beasts and swarms use the weakest-defence rule (lowest Res against a phys attacker, then front row, then slot).
- Flee check: swarm HP counts in foe HP totals and max totals like any foe.

---

## 6. Data schema (JSON)

```json
{
  "id": "foe_mossmite",
  "name_key": "foe_mossmite_name",
  "name_one_key": "foe_mossmite_name_one",
  "swarm_label_key": "foe_mossmite_swarm",
  "desc_key": "foe_mossmite_desc",
  "spawn_role": "filler",            // never in SPAWN tables, no variety bias
  "kind": "phys",                    // melee Strike
  "tel": "none",
  "max_bugs": 10,                    // PLACEHOLDER
  "hp_per_bug": 1,                   // PLACEHOLDER
  "might":  { "per_bug_ceil_div": 2, "offset": -2 },   // ceil(n/2)-2, PLACEHOLDER
  "res":    { "per_bug_floor_div": 3, "offset": 0 },   // floor(n/3), PLACEHOLDER
  "arc": 1, "ward": 2, "swi": 4, "fate": 0,             // PLACEHOLDER
  "min_damage_on_hit": 1,
  "calm_threshold": "none",          // dies only at 0 HP
  "overkill_carry": false,
  "threat_open": 7,                  // PLACEHOLDER, includes the first bug
  "threat_per_extra_bug": 2,         // PLACEHOLDER
  "fill_order": ["front", "back", "grow"],
  "grow_pick": "uniform_random_below_max",
  "sprite": {
    "base_id": "enemy_crystal_mite",     // TEMP: closest existing Art placeholder (PLACEHOLDER_KIT_v0 §4)
    "by_count": { "1": null, "2": null, "3": null, "4": null, "5": null,
                  "6": null, "7": null, "8": null, "9": null, "10": null }
  }
}
```
(The comments are for readers only. Strip them in real data.)

**Sprites:**
- No per-swarm-size sprite ids exist in the files. `PLACEHOLDER_KIT_v0.md` only defines `enemy_crystal_mite` (32×32 tiny swarm, clips idle 4/160 ms, attack 3/90 ms, death 3/100 ms).
- Until Art names size variants (`enemy_mossmite_<n>` is the suggested pattern, following `category_name_anim_####.png`), draw `min(bugs,10)` copies or one sprite with the count label.
- Each bug lost plays one `death` clip on a single bug. The last bug's death removes the swarm.

---

## 7. Sim results (v72.py, 5000 fights per cell, Keeper + Elaia with the real sheet, Elaia in the back row, 0 Salves)

| D | Baseline win% played / idle | Mossmite 7+2 win% played / idle | Δ played / idle | slots base → 7+2 | avg bugs | rounds base | rounds 7+2 |
|---|---|---|---|---|---|---|---|
| 1 | 89.8 / 87.5 | 87.1 / 83.7 | -2.7 / -3.8 | 2.00 → 3.16 | 3.3 | 3.9/3.5 | 4.6/4.0 |
| 5 | 77.7 / 75.8 | 71.8 / 68.1 | -5.9 / -7.7 | 2.00 → 3.96 | 2.6 | 4.4/3.7 | 5.8/4.7 |
| 10 | 56.5 / 55.0 | 46.4 / 43.2 | -10.1 / -11.8 | 2.01 → 4.12 | 2.8 | 5.2/4.0 | 6.4/4.8 |
| 20 | 3.7 / 4.1 | 3.1 / 3.0 | -0.6 / -1.1 | 3.00 → 4.53 | 2.7 | 5.0/3.4 | 5.0/3.4 |

Rooms with 0 bugs: D1 16.6%, D5 12.6%, D10 9.5%, D20 22.7%.
Known cost: each swarm takes a whole party action to swat (variant_cost7plus1.md). Filling back slots first or adding overkill carry were the simmed levers that cut the gap. Neither is approved here.

---

## 8. Open questions (not blocking)
1. Art's PLACEHOLDER_KIT says "F6: no row tactics", but the battle model and this spec use rows. Rows stay as simmed.
2. Boss rooms: are swarms included? Not simmed.
3. Should Res update live (simpler) or lazily (as simmed)? Lazy is the spec.
