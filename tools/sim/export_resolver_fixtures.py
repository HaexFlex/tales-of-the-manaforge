"""Export resolver oracle fixtures from the Director's combat sim (BATTLE_SCENE_DRAFT v4).

Usage: python3 tools/sim/export_resolver_fixtures.py /workspace/combat_sim.py
Writes tests/fixtures/resolver_cases.json and tests/fixtures/resolver_compositions.json.
Data only: nothing in the game reads these yet. The resolver (job 10) and the spawn roller
(job 15) test against them. Dice are injected, so every case is exact.
"""
import hashlib
import importlib.util
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "fixtures")

# Sim species name -> beasts.json id. Briar Warden was renamed Briar Hulk in v4.
SPECIES_IDS = {
    "Acorn imp": "acorn_imp", "Spore moth": "spore_moth", "Wilt Wisp": "wilt_wisp",
    "Root Snapper": "root_snapper", "Thorn boar": "thorn_boar", "Vine serpent": "vine_serpent",
    "Briar Warden": "briar_hulk", "Moss Brute": "moss_brute", "Stump ogre": "stump_ogre",
    "Stag spirit": "stag_spirit",
}


def beast_id(entry):
    base = SPECIES_IDS[entry["species"]]
    return base if entry["ver"] == "A" else base + "_dark"


class Dice:
    """Replaces random.*: randint pops scripted faces, random() pops a scripted 0..1 value."""

    def __init__(self, faces, rolls):
        self.faces = list(faces)
        self.rolls = list(rolls)

    def randint(self, lo, hi):
        v = self.faces.pop(0)
        assert lo <= v <= hi, (lo, hi, v)
        return v

    def random(self):
        return self.rolls.pop(0)


def load_sim(path):
    spec = importlib.util.spec_from_file_location("combat_sim", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    assert hasattr(mod, "apply_poison"), "this sim still stacks poison; use the refresh build"
    return mod


def fighter(sim, d, party, row="front", slot=0):
    hp = d["hp"] if "hp" in d else 10 + 3 * d["vit"]
    return sim.F(d["name"], d["mig"], d["arc"], d["res"], d["ward"], d["swi"], hp, d["kind"], party,
                 d.get("tel", "none"), fate=d.get("fate", 0), row=row, slot=slot)


def stats_of(d):
    return {k: d.get(k, 0) for k in ("mig", "arc", "res", "ward", "vit", "swi", "fate")} | {"kind": d["kind"]}


def strike_case(sim, cid, note, att, dfn, atk2d6, def2d6, dmg_face, fate_roll=None, extra=1.0, mod=0):
    a = fighter(sim, att, att.get("party", True))
    d = fighter(sim, dfn, dfn.get("party", False))
    hp_before = d.hp
    faces = list(atk2d6) + list(def2d6) + ([dmg_face] if dmg_face is not None else [])
    rolls = [] if fate_roll is None else [fate_roll / 100.0]
    dice = Dice(faces, rolls)
    real = sim.random
    sim.random = dice
    try:
        band, dmg = sim.swing(a, d, extra=extra, mod=mod)
    finally:
        sim.random = real
    assert not dice.faces and not dice.rolls, (cid, dice.faces, dice.rolls)
    atk_total = sum(atk2d6) + a.off() + mod
    def_total = sum(def2d6) + d.def_base(a.kind)
    return {
        "id": cid, "note": note,
        "attacker": {"name": att["name"], **stats_of(att)},
        "defender": {"name": dfn["name"], **stats_of(dfn), "hp": hp_before},
        "attack_type": "physical" if a.kind == "phys" else "magic",
        "to_hit_mod": mod, "telegraph_mult": extra,
        "dice": {"attack_2d6": list(atk2d6), "defense_2d6": list(def2d6),
                 "damage_die": sim.die_size(a.off()), "damage_face": dmg_face,
                 "fate_roll_0_100": fate_roll},
        "expect": {"attack_total": atk_total, "defense_total": def_total,
                   "margin": atk_total - def_total, "band": band, "damage": dmg,
                   "fate_crit": dmg > 0 and fate_roll is not None and fate_roll < a.fate,
                   "defender_hp_after": d.hp},
    }


def main():
    sim_path = sys.argv[1] if len(sys.argv) > 1 else "/workspace/combat_sim.py"
    sim = load_sim(sim_path)
    sim_sha = hashlib.sha256(open(sim_path, "rb").read()).hexdigest()
    roster = {beast_id(e): e for e in sim.ROSTER}

    def beast(bid, **kw):
        e = roster[bid]
        return {"name": e["name"], "mig": e["mig"], "arc": e["arc"], "res": e["res"], "ward": e["ward"],
                "vit": e["vit"], "swi": e["swi"], "fate": 0, "kind": e["kind"], "hp": e["hp"],
                "tel": e["tel"], "party": False, **kw}

    keeper = dict(sim.MILESTONES["unlock"][0], party=True)
    elaia = dict(sim.MILESTONES["duo"][1], party=True)
    imp = beast("acorn_imp")
    moth = beast("spore_moth")
    snapper = beast("root_snapper")
    imp_as_attacker = dict(imp, party=False)
    keeper_as_target = dict(keeper, party=True)

    strikes = [
        strike_case(sim, "s4_line1", "BATTLE_SCENE_DRAFT v4 §4 example, line 1",
                    keeper, imp, (3, 4), (2, 3), 4, fate_roll=50),
        strike_case(sim, "s4_line2", "§4 example, line 2 (tie goes to the attacker: graze)",
                    imp_as_attacker, keeper_as_target, (2, 4), (3, 4), 3),
        strike_case(sim, "s4_line4", "§4 example, line 4 (crushing + Fate crit = x4). The draft prints 48; the rule gives 13 x2 x2 = 52",
                    keeper, dict(imp, hp=13), (4, 5), (3, 3), 5, fate_roll=3),
        strike_case(sim, "miss_margin_minus1", "margin -1 is a miss, no damage die rolled",
                    keeper, imp, (1, 1), (4, 4), None),
        strike_case(sim, "graze_margin2_half_up", "margin 2 is a graze; x0.5 rounds half up (9 x 0.5 = 4.5 -> 5)",
                    keeper, imp, (1, 2), (3, 3), 1, fate_roll=99),
        strike_case(sim, "hit_margin3", "margin 3 is a hit (x1)",
                    keeper, imp, (1, 2), (2, 3), 1, fate_roll=99),
        strike_case(sim, "hit_margin5", "margin 5 is still a hit",
                    keeper, imp, (2, 3), (2, 3), 6, fate_roll=99),
        strike_case(sim, "crush_margin6", "margin 6 is a crushing blow (x2)",
                    keeper, imp, (3, 3), (2, 3), 1, fate_roll=99),
        strike_case(sim, "min_damage_1", "raw damage floors at 1, graze of 1 rounds to 1",
                    dict(imp_as_attacker, mig=1), dict(keeper_as_target, res=12), (6, 6), (1, 1), 1),
        strike_case(sim, "magic_vs_ward", "Arcana against Ward + Swiftness, Ward soaks (hit, margin 4)",
                    moth, keeper_as_target, (3, 3), (2, 2), 3),
        strike_case(sim, "heavy_telegraph_x1_5", "telegraph x1.5 before rounding (7 x 1.5 = 10.5 -> 11)",
                    snapper, keeper_as_target, (2, 3), (2, 2), 2, extra=1.5),
        strike_case(sim, "ranged_back_row_minus2", "ranged into the back row while the front stands: -2 turns a hit into a graze",
                    elaia, dict(moth, party=False), (4, 4), (3, 3), 4, fate_roll=99, mod=-2),
        strike_case(sim, "fate_crit_on_graze", "a Fate crit doubles a graze too (14 x 0.5 x 2)",
                    keeper, imp, (1, 2), (4, 4), 6, fate_roll=0),
    ]

    die_table = [{"offense": o, "die": sim.die_size(o)} for o in list(range(1, 41)) + [41, 42, 45, 50, 61]]
    round_half_up = [{"x": x, "rounded": sim.rhu(x)} for x in (0.5, 1.5, 2.5, 3.5, 4.4, 4.5, 10.5, 36.0)]

    # Poison: one per target. A new one resets to 3 ticks and keeps the stronger total.
    target = sim.F("Keeper", 11, 5, 6, 5, 7, 100, "phys", True)
    poison_steps = []
    for op, val in (("apply", 9), ("tick", None), ("apply", 12), ("tick", None), ("apply", 9),
                    ("tick", None), ("tick", None), ("tick", None), ("tick", None), ("apply", 10), ("tick", None)):
        if op == "apply":
            sim.apply_poison(target, val)
        else:
            sim.tick_poison(target)
        p = target.poison[0] if target.poison else None
        poison_steps.append({"op": op, "total": val, "hp_after": target.hp,
                             "ticks_left": list(p[0]) if p else [], "kept_total": p[2] if p else 0})

    # Turn order: Swiftness desc, party first on ties, then slot.
    roster_order = [("Keeper", 7, True, 0), ("Elaia", 6, True, 1), ("Acorn imp A", 6, False, 0),
                    ("Spore moth A", 8, False, 1), ("Root Snapper A", 6, False, 2), ("Wilt Wisp A", 8, False, 3)]
    fs = [sim.F(n, 1, 1, 1, 1, s, 10, "phys", p, slot=sl) for n, s, p, sl in roster_order]
    order = sorted(fs, key=lambda f: (-f.swi, 0 if f.party else 1, f.slot))
    turn_order = {"fighters": [{"name": n, "swiftness": s, "side": "party" if p else "beast", "slot": sl}
                               for n, s, p, sl in roster_order],
                  "expect": [f.name for f in order]}

    # Beast targeting: weakest defense against the attack type among reachable members.
    party = [fighter(sim, keeper, True, "front", 0), fighter(sim, elaia, True, "back", 1)]
    targeting = []
    for bid in ("acorn_imp", "spore_moth"):
        b = fighter(sim, beast(bid), False)
        opts = sim.reachable(b, party)
        stat = (lambda m: m.res) if b.kind == "phys" else (lambda m: m.ward)
        tgt = min(opts, key=lambda m: (stat(m), 0 if m.row == "front" else 1, m.slot))
        targeting.append({"beast": bid, "party": [{"name": m.name, "row": m.row, "res": m.res, "ward": m.ward}
                                                   for m in party],
                          "reachable": [m.name for m in opts], "expect_target": tgt.name})

    doc_cases = [{
        "id": "s4_line3_brace",
        "source": "BATTLE_SCENE_DRAFT v4 §4 example, line 3. Not from the sim: the sim has no Brace yet.",
        "rule": "A braced defender rolls 3d6 and keeps the best 2.",
        "attacker": {"name": "Acorn imp A", "mig": 7}, "defender": {"name": "Keeper", "res": 6, "swi": 7},
        "dice": {"attack_2d6": [4, 5], "defense_3d6": [6, 5, 1]},
        "expect": {"attack_total": 16, "defense_total": 17, "band": "miss", "damage": 0},
    }]

    cases = {
        "source": {"sim": os.path.basename(sim_path), "sim_sha256": sim_sha,
                   "rules": "BATTLE_SCENE_DRAFT v4", "exporter": "tools/sim/export_resolver_fixtures.py",
                   "poison": "refresh (one per target, 3 ticks, stronger total kept)"},
        "notes": [
            "Bands: margin < 0 miss, 0-2 graze x0.5, 3-5 hit x1, 6+ crushing x2. Damage rounds half up, minimum 1.",
            "Fate crit: a landed blow crits when fate_roll_0_100 < attacker Fate. Beasts have Fate 0 and roll no crit.",
            "Dice are consumed in this order: attack 2d6, defense 2d6, damage die (only on a landed blow), Fate roll (only when Fate > 0).",
            "The sim has no Brace, Sap Spring, twists or boss telegraph yet; doc_cases holds the §4 Brace line by hand.",
            "No loot here. Amberbind stays the manual jackpot and is never a bonus drop.",
        ],
        "strikes": strikes,
        "doc_cases": doc_cases,
        "die_table": die_table,
        "round_half_up": round_half_up,
        "poison_refresh": poison_steps,
        "turn_order": turn_order,
        "beast_targeting": targeting,
    }

    comps = {"source": cases["source"], "max_foes": sim.MAX_FOES, "variety_bias": sim.VARIETY_BIAS,
             "note": "Distinct maximal rooms (nothing else fits, up to 6) per depth, from compositions(). Beast ids as in data/beasts.json.",
             "depths": []}
    for depth in (1, 2, 3, 4, 5, 8, 9, 10, 12, 14, 15):
        rooms = []
        for room in sim.compositions(depth):
            ids = sorted(beast_id(next(e for e in sim.ROSTER if e["name"] == n)) for n in room)
            rooms.append({"beasts": ids, "threat": sum(roster[i]["threat"] for i in ids)})
        rooms.sort(key=lambda r: r["beasts"])
        comps["depths"].append({"depth": depth, "budget": sim.budget(depth), "count": len(rooms), "rooms": rooms})

    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, "resolver_cases.json"), "w") as fh:
        json.dump(cases, fh, indent=1, ensure_ascii=False)
        fh.write("\n")
    with open(os.path.join(OUT, "resolver_compositions.json"), "w") as fh:
        json.dump(comps, fh, indent=1, ensure_ascii=False)
        fh.write("\n")
    for s in strikes:
        print(s["id"], s["expect"]["band"], s["expect"]["damage"], s["expect"]["margin"])
    print([(d["depth"], d["budget"], d["count"]) for d in comps["depths"]])


if __name__ == "__main__":
    main()
