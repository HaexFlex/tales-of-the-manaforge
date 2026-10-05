#!/usr/bin/env python3
"""Rebuild Keeper idle walkmatch v2 (both feet planted) from live walk frames.

Outputs (additive; does not touch v1):
  assets/art/keeper/idle_walkmatch_v2/{dir}/keeper_idle_{dir}_0001..0012.png
  assets/library/keeper_idle_walkmatch_v2/
  /workspace/art-handoff/keeper-idle-walkmatch-v2/
  /workspace/keeper_idle_rebuild/out/idle_walkmatch_v2_contact.png
"""
from __future__ import annotations
import json, os, shutil, sys
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage

sys.path.insert(0, "/workspace/art_refresh/tools")
import common as C

TREE = Path("/workspace/adv_p0_tree")
WALK = TREE / "assets/art/keeper/anim/walk"
OUT_LIB = TREE / "assets/library/keeper_idle_walkmatch_v2"
OUT_RT = TREE / "assets/art/keeper/idle_walkmatch_v2"
OUT_BOX = Path("/workspace/keeper_idle_rebuild/out")
HANDOFF = Path("/workspace/art-handoff/keeper-idle-walkmatch-v2")
OLD = TREE / "assets/art/keeper/idle"
V1 = TREE / "assets/art/keeper/idle_walkmatch"
HEM, SOLE, N_FRAMES, HOLD_MS = 98, 123, 12, 160
BG = (58, 92, 44, 255)
PLANT = {"south": 5, "north": 3, "east": 3, "west": 3}


def load(d, i):
    return np.array(Image.open(WALK / d / f"frame_{i:04d}.png").convert("RGBA"))


def cyan_count(a):
    v = a[a[..., 3] > 0][:, :3].astype(int)
    return int(((v[:, 1] > v[:, 0] + 40) & (v[:, 2] > v[:, 0] + 30) & (v[:, 1] > 100)).sum())


def harden(a):
    a = a.copy()
    a[a[..., 3] < 128] = 0
    a[a[..., 3] >= 128, 3] = 255
    return a


def boot_comps(a, y0=110):
    rgb = a[..., :3].astype(int)
    op = a[..., 3] > 0
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    brown = op & (r > g) & (r > b) & (r > 40) & (g > 15) & (g < 130) & (b < 110) & ((r - b) > 12)
    dark = op & (r < 55) & (g < 45) & (b < 45)
    m = (brown | dark) & (np.arange(a.shape[0])[:, None] >= y0)
    lab, n = ndimage.label(m)
    out = []
    for i in range(1, n + 1):
        ys, xs = np.nonzero(lab == i)
        if ys.max() < 122 or len(ys) < 50:
            continue
        out.append(
            {
                "mask": lab == i,
                "cx": float(xs.mean()),
                "xmin": int(xs.min()),
                "xmax": int(xs.max()),
                "n": len(ys),
                "sole_w": int((lab[SOLE] == i).sum()),
            }
        )
    out.sort(key=lambda b: b["cx"])
    return out


def extract_leg(a, boot, max_half=6):
    cx = boot["cx"]
    seed = boot["mask"].copy()
    rgb = a[..., :3].astype(int)
    op = a[..., 3] > 0
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    allow = op & (
        ((r > g) & (r > b) & (r > 35) & (g < 140) & (b < 120) & (r - b > 10))
        | ((r < 60) & (g < 50) & (b < 50))
        | ((r > 70) & (g > 45) & (b < 90) & (r > b) & (g >= b - 5))
    )
    blue = op & (b > r + 15) & (b > g) & (b > 70)
    allow = allow & ~blue
    grown = seed.copy()
    xlo = int(max(0, round(cx) - max_half))
    xhi = int(min(127, round(cx) + max_half))
    for y in range(SOLE, HEM - 1, -1):
        for x in range(xlo, xhi + 1):
            if not allow[y - 1, x]:
                continue
            if any(grown[y, xx] for xx in range(max(xlo, x - 1), min(xhi, x + 1) + 1)):
                grown[y - 1, x] = True
    grown[:HEM] = False
    bymin = int(np.nonzero(seed)[0].min())
    for y in range(HEM, bymin):
        for x in range(int(round(cx)) - 3, int(round(cx)) + 4):
            if 0 <= x < 128 and allow[y, x]:
                grown[y, x] = True
            elif 0 <= x < 128 and op[y, x] and not blue[y, x] and (r[y, x] > g[y, x] - 5) and (b[y, x] < 100):
                grown[y, x] = True
    return grown


def sole_cx(mask):
    ys, xs = np.nonzero(mask)
    sy = int(ys.max())
    return float(xs[ys >= sy - 1].mean()), sy


def paste(canvas, src, mask, dx, dy):
    out = canvas.copy()
    H, W = canvas.shape[:2]
    ys, xs = np.nonzero(mask)
    for y, x in zip(ys, xs):
        ny, nx = y + dy, x + dx
        if 0 <= ny < H and 0 <= nx < W:
            out[ny, nx] = src[y, x]
    return out


def build_front(d):
    base = load(d, 0).copy()
    out = base.copy()
    out[HEM:] = 0
    rgb = base[..., :3].astype(int)
    op = base[..., 3] > 0
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    brownish = op & (r > g) & (r > b) & (r > 40) & (b < 110) & (np.arange(128)[:, None] >= 90) & (np.arange(128)[:, None] < HEM)
    lab, n = ndimage.label(brownish)
    for i in range(1, n + 1):
        ys, xs = np.nonzero(lab == i)
        if len(ys) < 200 and ys.min() >= 92:
            out[lab == i] = 0

    prefer = {"south": [5, 2, 1, 6, 3, 7, 0, 4], "north": [3, 0, 4, 7, 5, 6, 1, 2]}[d]
    cands = []
    for i in prefer:
        a = load(d, i)
        for b in boot_comps(a):
            leg = extract_leg(a, b)
            cands.append({**b, "frame": i, "leg": leg, "src": a, "leg_n": int(leg.sum())})

    if d == "south":
        plants = [c for c in cands if c["frame"] in (2, 5, 1, 6)]
        plants.sort(key=lambda c: (-c["sole_w"], -c["leg_n"]))
        best = plants[0]
        L = {"frame": best["frame"], "cx": best["cx"], "leg": best["leg"], "src": best["src"], "sole_w": best["sole_w"]}
        R = {
            "frame": f"mirror({best['frame']})",
            "cx": 127 - best["cx"],
            "leg": np.ascontiguousarray(best["leg"][:, ::-1]),
            "src": np.ascontiguousarray(best["src"][:, ::-1]),
            "sole_w": best["sole_w"],
        }
    else:
        left = [c for c in cands if c["cx"] < 63]
        right = [c for c in cands if c["cx"] >= 63]

        def score(c):
            pref = prefer.index(c["frame"]) if c["frame"] in prefer else 99
            return (pref, -c["sole_w"], -c["leg_n"])

        left.sort(key=score)
        right.sort(key=score)
        L, R = left[0], right[0]

    ys, xs = np.nonzero((out[..., 3] > 0) & (np.arange(128)[:, None] < 90) & (np.arange(128)[:, None] > 20))
    tcx = float(xs.mean())
    sep = 16.0
    for cand, tgt in ((L, tcx - sep / 2), (R, tcx + sep / 2)):
        scx, sy = sole_cx(cand["leg"])
        out = paste(out, cand["src"], cand["leg"], int(round(tgt - scx)), SOLE - sy)

    fringe = base[HEM : HEM + 5]
    region = out[HEM : HEM + 5].copy()
    rgb = fringe[..., :3].astype(int)
    gold = (fringe[..., 3] > 0) & (rgb[..., 0] > 140) & (rgb[..., 1] > 100) & (rgb[..., 2] < 120)
    blue = (fringe[..., 3] > 0) & (rgb[..., 2] > rgb[..., 0] + 20) & (rgb[..., 2] > 70)
    need = (gold | blue) & (region[..., 3] == 0)
    region[need] = fringe[need]
    out[HEM : HEM + 5] = region
    return harden(out), {
        "torso": 0,
        "tcx": round(tcx, 2),
        "L": [L["frame"], round(float(L["cx"]), 1), int(L["sole_w"])],
        "R": [R["frame"] if isinstance(R["frame"], int) else str(R["frame"]), round(float(R["cx"]), 1), int(R["sole_w"])],
        "sep": sep,
    }


def build_side(d):
    return harden(load(d, 0).copy()), {"frame": 0, "mode": "as-is", "span": 26}


def bob_upper(base, dy, hem=84):
    if dy == 0:
        return base.copy()
    out = base.copy()
    upper = base[:hem].copy()
    blank = np.zeros_like(upper)
    H = hem
    if dy > 0:
        blank[dy:] = upper[: H - dy]
    else:
        ady = -dy
        blank[: H - ady] = upper[ady:]
        blank[H - ady :] = base[hem : hem + ady]
    out[:hem] = blank
    out[hem:] = base[hem:]
    return harden(out)


def bob_sched():
    return [int(round(0.65 * np.sin(2 * np.pi * i / 12.0))) for i in range(12)]


def build_all():
    results = {}
    for d in ["south", "north", "east", "west"]:
        still, meta = build_front(d) if d in ("south", "north") else build_side(d)
        lab, n = ndimage.label(still[..., 3] > 0)
        if n > 1:
            keep = []
            for i in range(1, n + 1):
                ys, xs = np.nonzero(lab == i)
                if int(ys.max()) >= 120 or len(ys) >= 100:
                    keep.append(i)
            if keep:
                still[(lab > 0) & ~np.isin(lab, keep)] = 0
        frames = [bob_upper(still, dy) for dy in bob_sched()]
        bc = boot_comps(still)
        boots = [[round(b["cx"], 1), int(b["xmin"]), int(b["xmax"]), int(b["n"]), int(b["sole_w"])] for b in bc]
        xs = np.nonzero(still[118, ..., 3] > 0)[0]
        gap = 0
        if len(xs) >= 2:
            holes = [int(b - a - 1) for a, b in zip(xs[:-1], xs[1:]) if b - a > 1]
            gap = max(holes) if holes else 0
        results[d] = {
            "still": still,
            "frames": frames,
            "meta": meta,
            "cyan": int(cyan_count(still)),
            "boots": boots,
            "sole_y": int(np.nonzero(still[..., 3] > 0)[0].max()),
            "cols": int(len({tuple(map(int, p)) for p in still[still[..., 3] > 0][:, :3]})),
            "foot_gap_118": int(gap),
        }
        print(d, results[d]["cyan"], results[d]["boots"], meta)
    return results


def save(results):
    for d, r in results.items():
        for root in (OUT_LIB, OUT_RT):
            dest = root / d
            dest.mkdir(parents=True, exist_ok=True)
            for i, fr in enumerate(r["frames"], 1):
                C.save_rgba(fr, str(dest / f"keeper_idle_{d}_{i:04d}.png"))


def contact(results):
    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 11)
    except Exception:
        font = ImageFont.load_default()
    dirs = ["south", "north", "east", "west"]
    labels = ["WALK plant(v1)", "v1 mid-stride idle", "v2 PLANTED idle", "OLD Imagine"]
    cv = Image.new("RGBA", (128 * 4 + 40, 128 * 4 + 80), BG)
    dr = ImageDraw.Draw(cv)
    dr.text((8, 4), "Keeper idle walkmatch v2 — both feet planted under body (live walk pixels only)", fill=(240, 240, 220), font=font)
    y = 22
    for lab in labels:
        x = 8
        for d in dirs:
            if lab.startswith("WALK"):
                im = Image.fromarray(load(d, PLANT[d]))
            elif lab.startswith("v1"):
                im = Image.open(V1 / d / f"keeper_idle_{d}_0001.png").convert("RGBA")
            elif lab.startswith("v2"):
                im = Image.fromarray(results[d]["frames"][0])
            else:
                im = Image.open(OLD / d / f"keeper_idle_{d}_0001.png").convert("RGBA")
            cv.alpha_composite(im, (x, y))
            dr.text((x + 2, y + 114), d[0].upper(), fill=(255, 255, 200), font=font)
            x += 134
        dr.text((8, y - 12), lab, fill=(220, 220, 200), font=font)
        y += 136
    dr.text((8, y), f'loop {N_FRAMES}x{HOLD_MS}ms = {N_FRAMES*HOLD_MS}ms  |  north cyan={results["north"]["cyan"]} (walk plant ~58)', fill=(230, 230, 210), font=font)
    OUT_BOX.mkdir(parents=True, exist_ok=True)
    (OUT_LIB / "previews").mkdir(parents=True, exist_ok=True)
    path = OUT_BOX / "idle_walkmatch_v2_contact.png"
    cv.convert("RGB").save(path)
    cv.convert("RGB").save(OUT_LIB / "previews" / "idle_walkmatch_v2_contact.png")
    return path


def main():
    results = build_all()
    save(results)
    cpath = contact(results)
    report = []
    for d, r in results.items():
        w = load(d, PLANT[d])
        wp = {tuple(map(int, p)) for p in w[w[..., 3] > 0][:, :3]}
        npal = {tuple(map(int, p)) for p in r["still"][r["still"][..., 3] > 0][:, :3]}
        report.append(
            {
                "dir": d,
                "cyan": r["cyan"],
                "cyan_walk_plant": int(cyan_count(w)),
                "boots": r["boots"],
                "sole_y": r["sole_y"],
                "cols": r["cols"],
                "foot_gap_118": r["foot_gap_118"],
                "shared_walk_colours": len(wp & npal),
                "new_colours": len(npal - wp),
                "meta": r["meta"],
                "frames": N_FRAMES,
                "hold_ms": HOLD_MS,
                "loop_ms": N_FRAMES * HOLD_MS,
                "hard_alpha": sorted({int(x) for x in r["still"][..., 3].ravel()}) == [0, 255],
            }
        )
    (OUT_LIB / "report.json").write_text(json.dumps(report, indent=2))
    (OUT_BOX / "report_v2.json").write_text(json.dumps(report, indent=2))
    notes = (OUT_LIB / "NOTES.md").read_text() if (OUT_LIB / "NOTES.md").exists() else ""
    if "Keeper idle walkmatch v2" not in notes:
        (OUT_LIB / "NOTES.md").write_text("# Keeper idle walkmatch v2\nSee report.json\n")
    shutil.rmtree(HANDOFF, ignore_errors=True)
    HANDOFF.mkdir(parents=True, exist_ok=True)
    for d, r in results.items():
        for i, fr in enumerate(r["frames"], 1):
            C.save_rgba(fr, str(HANDOFF / f"keeper_idle_{d}_{i:04d}.png"))
    shutil.copy(OUT_LIB / "NOTES.md", HANDOFF / "NOTES.md")
    shutil.copy(cpath, HANDOFF / "idle_walkmatch_v2_contact.png")
    shutil.copy(OUT_LIB / "report.json", HANDOFF / "report.json")
    print("contact", cpath)


if __name__ == "__main__":
    main()
