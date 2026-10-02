#!/usr/bin/env python3
"""Frame / alpha check for the Keeper idle 4-dir experiment (extends keeper_harvest_anims_v2/tools/check_frames.py).
Usage: check_frames.py <final_dir> [repo]
Per frame:
  rgba / size     PNG is RGBA (real alpha), 128x128
  bg_clear        whole outer border alpha 0 (no baked background, nothing clipped)
  zero_rgb        alpha-0 pixels are (0,0,0,0) - no hidden matte colour
  semi_px         semi-transparent pixels (these frames use hard 0/255 alpha, so expected 0); any semi px must be in the 2 px edge band
  tint_edge       visible edge pixels with a magenta/purple hue (280-340 deg, sat>0.15) - dark key contamination -> must be 0
  magenta_edge    opaque OR semi pixels on the silhouette edge (within 2 px of transparency) with a magenta/pink key hue -> must be 0
  light_fringe    semi pixels with max RGB > 160 -> must be 0
  palette         every visible RGB is in the shared palette.json (-> nothing can flicker colour-wise)
  anchor          lowest opaque row == 123 (live walk/idle), feet centre within 2 px of x 63.5, visible height 116-126 (live 122)
Exit 1 on any failure; writes alpha_check.json / alpha_check.md into <final_dir>."""
import json, sys
from pathlib import Path
import numpy as np
from PIL import Image

ROOT = PAL = None
SOLE, FEET = 123, 63.5

def edge_band(al, r=2):
    h, w = al.shape; pad = np.pad(al == 0, r, constant_values=True); near = np.zeros((h, w), bool)
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1): near |= pad[r + dy:r + dy + h, r + dx:r + dx + w]
    return near

def magenta(px):
    px = px.astype(int)
    return (px[:, 0] > 110) & (px[:, 2] > 110) & (px[:, 1] < 0.65 * np.minimum(px[:, 0], px[:, 2]))

def magenta_tint(px):
    px = px.astype(float); mx = px.max(-1); mn = px.min(-1); c = mx - mn
    r, g, b = px[..., 0], px[..., 1], px[..., 2]
    with np.errstate(divide="ignore", invalid="ignore"):
        h = np.where(mx == r, ((g - b) / c) % 6, np.where(mx == g, (b - r) / c + 2, (r - g) / c + 4)) * 60
        sat = np.where(mx > 0, c / mx, 0)
    return (c > 10) & (sat > 0.15) & (h >= 280) & (h <= 340)

def check(p):
    im = Image.open(p); r = {"file": f"{p.parent.name}/{p.name}", "rgba": im.mode == "RGBA"}
    a = np.array(im.convert("RGBA")).astype(int); al = a[..., 3]; h, w = al.shape
    r["size_ok"] = (w, h) == (128, 128)
    r["bg_clear"] = bool((np.concatenate([al[0], al[-1], al[:, 0], al[:, -1]]) == 0).all())
    r["zero_rgb"] = int(((al == 0) & (a[..., :3].sum(-1) > 0)).sum())
    semi = (al > 0) & (al < 255); near = edge_band(al)
    r["semi_px"] = int(semi.sum()); r["semi_off_edge"] = int((semi & ~near).sum())
    edge_vis = (al > 0) & near
    r["magenta_edge"] = int(magenta(a[edge_vis][:, :3]).sum())
    r["magenta_any"] = int(magenta(a[al > 0][:, :3]).sum())
    r["tint_edge"] = int(magenta_tint(a[edge_vis][:, :3]).sum())     # dark purple key contamination on the outline
    sp = a[semi][:, :3]; r["light_fringe"] = int((sp.max(1) > 160).sum()) if len(sp) else 0
    r["non_palette"] = int(sum(1 for c in map(tuple, a[al > 0][:, :3].tolist()) if c not in PAL))
    op = al > 127; rows = np.nonzero(op.any(1))[0]; sole = int(rows.max()); top = int(rows.min())
    band = op[sole - 9:sole + 1]; xs = np.nonzero(band.any(0))[0]; fx = float((xs.min() + xs.max()) / 2)
    r["sole_row"] = sole; r["feet_cx"] = fx; r["height"] = sole - top + 1
    r["anchor_ok"] = sole == SOLE and abs(fx - FEET) <= 2 and 116 <= r["height"] <= 126
    r["pass"] = bool(r["rgba"] and r["size_ok"] and r["bg_clear"] and r["zero_rgb"] == 0 and r["semi_off_edge"] == 0 and
                     r["magenta_edge"] == 0 and r["tint_edge"] == 0 and r["light_fringe"] == 0 and r["non_palette"] == 0 and r["anchor_ok"])
    return r

def main():
    global ROOT, PAL
    ROOT = Path(sys.argv[1])
    PAL = set(map(tuple, json.loads((ROOT / "palette.json").read_text())["colors"]))
    res = {}
    for meta in sorted(ROOT.glob("idle_*/keeper_idle_*.json")):
        m = json.loads(meta.read_text()); res[m["clip"]] = [check(meta.parent / f) for f in m["files"]]
    ok = all(x["pass"] for v in res.values() for x in v)
    (ROOT / "alpha_check.json").write_text(json.dumps({"all_pass": ok, "clips": res}, indent=1))
    L = ["# Frame / alpha check (tools/check_frames.py)", "", "Hard 0/255 alpha; reference anchor = live keeper_walk_south / idle_south (sole row 123, feet x 63.5, height 122).", "",
         "| frame | RGBA | 128x128 | border clear | alpha0 RGB!=0 | semi px | magenta on edge | magenta anywhere | purple tint on edge | light fringe | non-palette | sole/feet x/height | PASS |",
         "|---|---|---|---|---|---|---|---|---|---|---|---|---|"]
    for clip, v in res.items():
        for x in v:
            L.append(f"| {x['file']} | {x['rgba']} | {x['size_ok']} | {x['bg_clear']} | {x['zero_rgb']} | {x['semi_px']} | {x['magenta_edge']} | {x['magenta_any']} | {x['tint_edge']} | "
                     f"{x['light_fringe']} | {x['non_palette']} | {x['sole_row']}/{x['feet_cx']}/{x['height']} | {'PASS' if x['pass'] else 'FAIL'} |")
    L += ["", f"ALL PASS: {ok} ({sum(x['pass'] for v in res.values() for x in v)}/{sum(len(v) for v in res.values())})"]
    (ROOT / "alpha_check.md").write_text("\n".join(L) + "\n")
    print(L[-1])
    for clip, v in res.items():
        bad = [(x["file"], {k: x[k] for k in ("bg_clear", "zero_rgb", "semi_px", "magenta_edge", "non_palette", "sole_row", "feet_cx", "height")}) for x in v if not x["pass"]]
        print(clip, "PASS" if not bad else bad[:2])
    return 0 if ok else 1

if __name__ == "__main__":
    sys.exit(main())
