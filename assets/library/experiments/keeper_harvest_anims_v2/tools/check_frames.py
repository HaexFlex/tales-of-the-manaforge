#!/usr/bin/env python3
"""Automated frame check for the Keeper harvest v2 frames (and the live walk frames as the reference).
Per frame:
  rgba          PNG mode is RGBA (real alpha channel), 8 bit
  size          matches the clip meta canvas
  bg_clear      the four corners and the whole outer border are alpha 0 (no baked background, nothing clipped at an edge)
  zero_rgb      every alpha-0 pixel is (0,0,0,0): no hidden matte colour under transparent pixels
  semi_edge     semi-transparent pixels (0<a<255) all lie in the 2 px silhouette edge band (within 2 px of an alpha-0 pixel): no haze inside
  no_magenta    no semi-transparent pixel carries a magenta/pink key hue
  no_light_fringe no semi-transparent pixel is light (max RGB > 160): no light/background matte fringe
  dark_fringe   count of near-black semi pixels (max RGB < 12); the walk itself has these (premultiplied dark edge) - must be <= the walk's max
  palette       every visible pixel's RGB occurs in keeper_walk_south_0001..0009
  anchor        lowest opaque row == walk's (123) and >= 90% of walk_0001's leg/feet pixels (rows 100-127) are pixel-identical at the
                clip's anchor offset (0 for 128 canvases, +32 for 192) -> same scale, same anchor, no leg flicker
Exit 1 if any harvest frame fails."""
import json, sys
from pathlib import Path
import numpy as np
from PIL import Image

REPO = Path(sys.argv[2] if len(sys.argv) > 2 else "/workspace/keeper_anims/repo")
ROOT = Path(sys.argv[1] if len(sys.argv) > 1 else "/workspace/keeper_anims/v2/final")
K = REPO / "assets/art/keeper"
WALK = [K / f"keeper_walk_south_{i:04d}.png" for i in range(1, 10)]

def arr(p):
    return np.array(Image.open(p))

PAL = set()
for p in WALK:
    a = np.array(Image.open(p).convert("RGBA")); PAL |= set(map(tuple, a[a[..., 3] > 0][:, :3].tolist()))

def feet(a):
    al = a[..., 3] > 127
    rows = np.nonzero(al.any(1))[0]; sole = int(rows.max())
    band = al[sole - 9:sole + 1]
    xs = np.nonzero(band.any(0))[0]
    return sole, float((xs.min() + xs.max()) / 2)

W0 = np.array(Image.open(WALK[0]).convert("RGBA")).astype(int)
WALK_SOLE, WALK_FEET = feet(W0)

def check(path, canvas=None, xoff=0, walk_dark_max=None):
    im = Image.open(path)
    r = {"file": str(path.relative_to(path.parents[1])) if "final" in str(path) else path.name}
    r["rgba"] = im.mode == "RGBA"
    a = np.array(im.convert("RGBA")).astype(int)
    h, w = a.shape[:2]
    r["size"] = [w, h]; r["size_ok"] = canvas is None or [w, h] == list(canvas)
    al = a[..., 3]
    border = np.concatenate([al[0], al[-1], al[:, 0], al[:, -1]])
    r["bg_clear"] = bool((border == 0).all())
    r["opaque_frac"] = round(float((al > 0).mean()), 3)
    r["zero_rgb"] = int(((al == 0) & (a[..., :3].sum(-1) > 0)).sum())
    semi = (al > 0) & (al < 255)
    pad = np.pad(al == 0, 2, constant_values=True)
    touch0 = np.zeros_like(semi)
    for dy in range(-2, 3):
        for dx in range(-2, 3):
            touch0 |= pad[2 + dy:2 + dy + h, 2 + dx:2 + dx + w]          # within 2 px of a fully transparent pixel
    r["semi_px"] = int(semi.sum())
    r["semi_not_on_edge"] = int((semi & ~touch0).sum())
    px = a[semi][:, :3]
    r["magenta_semi"] = int(((px[:, 0] > 120) & (px[:, 2] > 120) & (px[:, 1] < 0.6 * np.minimum(px[:, 0], px[:, 2]))).sum()) if len(px) else 0
    r["light_semi"] = int((px.max(1) > 160).sum()) if len(px) else 0
    r["dark_semi"] = int((px.max(1) < 12).sum()) if len(px) else 0
    vis = a[al > 0][:, :3]
    r["non_walk_colours"] = int(sum(1 for c in map(tuple, vis.tolist()) if c not in PAL))
    sole, fx = feet(a)
    r["sole_row"] = sole
    # legs/feet (rows 100..127) of the reference walk frame 0001, compared pixel-for-pixel at the clip's anchor offset
    ref = W0[100:, :, :]; cur = a[100:, xoff:xoff + 128, :]
    m = ref[..., 3] > 0
    r["legs_identical"] = round(float((cur[m] == ref[m]).all(-1).mean()), 3) if cur.shape == ref.shape else 0.0
    r["anchor_ok"] = sole == WALK_SOLE and r["legs_identical"] >= 0.9
    r["pass"] = bool(r["rgba"] and r["size_ok"] and r["bg_clear"] and r["zero_rgb"] == 0 and r["semi_not_on_edge"] == 0 and
                     r["magenta_semi"] == 0 and r["light_semi"] == 0 and (walk_dark_max is None or r["dark_semi"] <= walk_dark_max) and
                     r["non_walk_colours"] == 0 and r["anchor_ok"])
    return r

def main():
    walk = [check(p) for p in WALK]
    dark_max = max(x["dark_semi"] for x in walk)
    out = {"reference_walk": walk, "walk_sole_row": WALK_SOLE, "walk_feet_cx": WALK_FEET, "clips": {}}
    ok = True
    for meta in sorted(ROOT.glob("*/keeper_*.json")):
        m = json.loads(meta.read_text())
        xoff = (m["canvas"][0] - 128) // 2
        res = [check(meta.parent / f, m["canvas"], xoff, dark_max) for f in m["files"]]
        out["clips"][m["clip"]] = res
        ok &= all(x["pass"] for x in res)
    out["all_pass"] = ok
    (ROOT / "alpha_check.json").write_text(json.dumps(out, indent=1))
    L = ["# Frame / alpha check (tools/check_frames.py)", "",
         f"Reference: live walk_south frames - sole row {WALK_SOLE}; walk semi-transparent edge px "
         f"{min(x['semi_px'] for x in walk)}-{max(x['semi_px'] for x in walk)}, near-black semi px up to {dark_max}, "
         f"alpha-0 pixels with leftover RGB {min(x['zero_rgb'] for x in walk)}-{max(x['zero_rgb'] for x in walk)} (the walk is not cleaned; v2 is).", "",
         "| frame | RGBA | size | bg/border clear | alpha0 RGB!=0 | semi px | semi off-edge | magenta semi | light semi | dark semi | non-walk colours | sole row / legs identical to walk | PASS |",
         "|---|---|---|---|---|---|---|---|---|---|---|---|---|"]
    for clip, res in out["clips"].items():
        for x in res:
            L.append(f"| {x['file']} | {x['rgba']} | {x['size'][0]}x{x['size'][1]} | {x['bg_clear']} | {x['zero_rgb']} | {x['semi_px']} | {x['semi_not_on_edge']} | "
                     f"{x['magenta_semi']} | {x['light_semi']} | {x['dark_semi']} | {x['non_walk_colours']} | {x['sole_row']} / {x['legs_identical']} | {'PASS' if x['pass'] else 'FAIL'} |")
    L += ["", f"ALL PASS: {ok}"]
    (ROOT / "alpha_check.md").write_text("\n".join(L) + "\n")
    print("\n".join(L[-1:]))
    for clip, res in out["clips"].items():
        print(clip, ["PASS" if x["pass"] else "FAIL" for x in res], "semi", [x["semi_px"] for x in res], "dark", [x["dark_semi"] for x in res])
    print("walk semi", [x["semi_px"] for x in walk], "dark", [x["dark_semi"] for x in walk], "zero_rgb", [x["zero_rgb"] for x in walk], "light", [x["light_semi"] for x in walk], "offedge", [x["semi_not_on_edge"] for x in walk], "legs", [x["legs_identical"] for x in walk])
    for clip, res in out["clips"].items():
        print(clip, "legs", [x["legs_identical"] for x in res], "offedge", [x["semi_not_on_edge"] for x in res])
    return 0 if ok else 1

if __name__ == "__main__":
    sys.exit(main())
