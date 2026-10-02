#!/usr/bin/env python3
"""Ingest ONE Grok Imagine turnaround sheet (S, N, E, W in a row on flat magenta, ~1168x784 JPEG).
key (sampled corner colour, soft key + magenta despill) -> split into 4 views -> ONE shared scale for all views
(front view hair-top..sole -> 122 game px) -> premultiplied LANCZOS to 2x, NN x0.5 (the walk's density) -> hard alpha
-> 128x128 with the sole on row 123 and the feet centred on x 64 (the live walk's anchor). Writes work/<name>/key_<D>.png,
a review sheet next to the live idle, and a consistency report (score.json)."""
import argparse, colorsys, json
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path("/workspace/keeper_idle"); REPO = ROOT / "repo"; K = REPO / "assets/art/keeper"
BODY_H, SOLE, FEET_X = 122, 123, 64

def key(rgb, lo=70.0, hi=130.0):
    h, w, _ = rgb.shape
    p = 12
    corners = np.concatenate([rgb[:p, :p].reshape(-1, 3), rgb[:p, -p:].reshape(-1, 3), rgb[-p:, :p].reshape(-1, 3), rgb[-p:, -p:].reshape(-1, 3)])
    bg = np.median(corners, 0)
    f = rgb.astype(np.float32)
    d = np.sqrt(((f - bg) ** 2).sum(-1))
    # magenta-ness also counts as background for JPEG ringing (high R & B, low G)
    mag = np.minimum(f[..., 0], f[..., 2]) - f[..., 1]
    d = np.where(mag > 120, np.minimum(d, lo), d)
    alpha = np.clip((d - lo) / (hi - lo), 0, 1)
    # despill: remove the magenta excess from every pixel that keeps some alpha
    ex = np.clip(np.minimum(f[..., 0], f[..., 2]) - f[..., 1], 0, None)
    spill = ex * (1.0 - alpha * 0.6)
    f[..., 0] -= spill; f[..., 2] -= spill
    return np.clip(f, 0, 255), alpha, bg

def split(alpha, n=4, min_big=3000):
    m = alpha > 0.5
    lab, k = ndimage.label(m, structure=np.ones((3, 3)))
    if k == 0: raise SystemExit("nothing keyed")
    idx = np.arange(1, k + 1)
    area = ndimage.sum(m, lab, idx)
    sl = ndimage.find_objects(lab)
    cx = np.array([(s[1].start + s[1].stop) / 2 for s in sl])
    big = [i for i in range(k) if area[i] >= min_big]
    if len(big) < n:
        raise SystemExit(f"found {len(big)} large figures, expected {n} (areas {sorted(area)[-6:]})")
    big = sorted(sorted(big, key=lambda i: -area[i])[:n], key=lambda i: cx[i])     # n largest, left->right
    groups = [[b] for b in big]
    for i in range(k):
        if i in big or area[i] < 6: continue
        j = int(np.argmin([abs(cx[i] - cx[b]) for b in big])); groups[j].append(i)
    return lab, groups

def view_crop(rgb, alpha, lab, comps):
    m = np.isin(lab, [c + 1 for c in comps])
    ys, xs = np.nonzero(m)
    y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    a = alpha[y0:y1, x0:x1] * m[y0:y1, x0:x1]
    return rgb[y0:y1, x0:x1], a

def body_extent(a, thr=0.5):
    rows = np.nonzero((a > thr).any(1))[0]
    return rows.min(), rows.max()

def to_game(rgb, a, scale):
    """premultiplied LANCZOS to 2x game size, then NN x0.5 (sample odd pixels like PIL NEAREST does), hard alpha."""
    h, w = a.shape
    W2, H2 = max(2, round(w * scale * 2)), max(2, round(h * scale * 2))
    pm = np.dstack([rgb * a[..., None], a * 255]).astype(np.float32)
    chans = [np.array(Image.fromarray(pm[..., c]).resize((W2, H2), Image.LANCZOS)) for c in range(4)]
    A = np.clip(chans[3], 0, 255)
    rgbo = np.dstack([np.where(A > 1, np.clip(chans[c] / np.maximum(A, 1) * 255, 0, 255), 0) for c in range(3)])
    big = np.dstack([rgbo, A]).astype(np.uint8)
    small = np.array(Image.fromarray(big).resize((W2 // 2, H2 // 2), Image.NEAREST))
    small[..., 3] = np.where(small[..., 3] >= 128, 255, 0)
    small[small[..., 3] == 0] = 0
    return small

def place(small):
    a = small[..., 3] > 0
    rows = np.nonzero(a.any(1))[0]; sole = rows.max()
    band = a[max(0, sole - 9):sole + 1]; xs = np.nonzero(band.any(0))[0]
    fx = (xs.min() + xs.max()) / 2
    out = np.zeros((128, 128, 4), np.uint8)
    ox, oy = int(round(FEET_X - 0.5 - fx)), SOLE - sole
    h, w = small.shape[:2]
    X0, Y0 = max(0, ox), max(0, oy); X1, Y1 = min(128, ox + w), min(128, oy + h)
    out[Y0:Y1, X0:X1] = small[Y0 - oy:Y1 - oy, X0 - ox:X1 - ox]
    clipped = bool(ox < 0 or oy < 0 or ox + w > 128 or oy + h > 128 and small[max(0, 128 - oy):, :, 3].any())
    return out, clipped

def classify(rgba):
    """rough per-view description used to sanity-check the order: skin in the head, where it sits, width."""
    a = rgba[..., 3] > 0
    rows = np.nonzero(a.any(1))[0]; top, sole = rows.min(), rows.max(); h = sole - top + 1
    head = rgba[top:top + int(0.33 * h)]
    px = head[head[..., 3] > 0][:, :3].astype(float) / 255
    hsv = np.array([colorsys.rgb_to_hsv(*c) for c in px]) if len(px) else np.zeros((0, 3))
    skin_m = (hsv[:, 0] > 0.02) & (hsv[:, 0] < 0.12) & (hsv[:, 1] > 0.18) & (hsv[:, 1] < 0.62) & (hsv[:, 2] > 0.62) if len(hsv) else np.zeros(0, bool)
    ys, xs = np.nonzero(head[..., 3] > 0)
    skin_x = xs[skin_m].mean() if skin_m.any() else None
    cols = np.nonzero(a.any(0))[0]
    return {"skin_frac_head": round(float(skin_m.mean()) if len(hsv) else 0.0, 3),
            "skin_offset_x": round(float(skin_x - xs.mean()), 1) if skin_x is not None else None,
            "width": int(cols.max() - cols.min() + 1), "height": int(h)}

def hist(rgba, bins=8):
    px = rgba[rgba[..., 3] > 0][:, :3] // (256 // bins)
    hh = np.zeros((bins,) * 3); np.add.at(hh, (px[:, 0], px[:, 1], px[:, 2]), 1)
    return hh / hh.sum()

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("sheet"); ap.add_argument("--name", required=True)
    ap.add_argument("--order", default="S,N,E,W", help="left->right view order on the sheet")
    ap.add_argument("--scale-from", default="S", help="view whose height sets the shared scale (or 'mean')")
    ap.add_argument("--per-view-scale", action="store_true")
    ap.add_argument("--lo", type=float, default=70); ap.add_argument("--hi", type=float, default=130)
    a0 = ap.parse_args()
    order = a0.order.split(",")
    rgb = np.array(Image.open(a0.sheet).convert("RGB"))
    f, alpha, bg = key(rgb, a0.lo, a0.hi)
    lab, groups = split(alpha, len(order))
    crops = {d: view_crop(f, alpha, lab, g) for d, g in zip(order, groups)}
    hts = {d: (lambda e: e[1] - e[0] + 1)(body_extent(c[1])) for d, c in crops.items()}
    ref_h = np.mean(list(hts.values())) if a0.scale_from == "mean" else hts[a0.scale_from]
    shared = BODY_H / ref_h
    out = ROOT / "work" / a0.name; out.mkdir(parents=True, exist_ok=True)
    rep = {"sheet": str(a0.sheet), "bg_sampled": [int(v) for v in bg], "order": order, "src_heights": {d: int(h) for d, h in hts.items()},
           "shared_scale": round(shared, 5), "views": {}}
    keys = {}
    for d, (c, a) in crops.items():
        s = BODY_H / hts[d] if a0.per_view_scale else shared
        g, clipped = place(to_game(c, a, s))
        Image.fromarray(g).save(out / f"key_{d}.png"); keys[d] = g
        info = classify(g); info["clipped"] = clipped; info["scale"] = round(s, 5)
        rep["views"][d] = info
    # consistency: pairwise colour-histogram overlap (1 = identical palette use) and height spread
    H = {d: hist(k) for d, k in keys.items()}
    ds = list(keys)
    pair = {f"{x}-{y}": round(float(np.minimum(H[x], H[y]).sum()), 3) for i, x in enumerate(ds) for y in ds[i + 1:]}
    live = np.array(Image.open(K / "keeper_idle_south_0000.png").convert("RGBA"))
    rep["palette_overlap_pairs"] = pair
    rep["palette_overlap_mean"] = round(float(np.mean(list(pair.values()))), 3)
    rep["S_vs_live_idle_overlap"] = round(float(np.minimum(H.get("S", H[ds[0]]), hist(live)).sum()), 3)
    hs = [v["height"] for v in rep["views"].values()]
    rep["game_height_spread_px"] = int(max(hs) - min(hs))
    (out / "score.json").write_text(json.dumps(rep, indent=1))
    # review sheet: live idle | S N E W at x1 and x3 on grass-ish green
    cells = [live] + [keys[d] for d in ds]
    row = Image.new("RGBA", (128 * len(cells), 128), (78, 128, 52, 255))
    for i, c in enumerate(cells): row.alpha_composite(Image.fromarray(c), (i * 128, 0))
    row.save(out / "review_x1.png"); row.resize((row.width * 3, 384), Image.NEAREST).save(out / "review_x3.png")
    print(json.dumps({k: rep[k] for k in ("src_heights", "shared_scale", "palette_overlap_mean", "S_vs_live_idle_overlap", "game_height_spread_px")}))
    for d, v in rep["views"].items(): print(d, v)

if __name__ == "__main__":
    main()
