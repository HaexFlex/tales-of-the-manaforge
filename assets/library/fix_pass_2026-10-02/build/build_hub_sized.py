"""Hub ring trees/bushes: native-size variants re-rendered from the hub v3 HD slices (no upscale of the 1x PNG).

  build_hub_sized.py --verify            # re-render the scale-1 originals and diff them with the repo files
  build_hub_sized.py OUT_REPO buckets.json

Same pipeline as /workspace/hub_v3/tools/build_hub_v3.py (pixelize box + quantize, clean_magenta, base on the
bottom row, content bottom-centred at (W-w)//2) with the per-cell factor multiplied by the bucket scale.
Canvas = original canvas * scale (W rounded to even, H rounded), so offset (-W//2, -H) stays the base centre."""
import json, sys
from pathlib import Path
import numpy as np
from PIL import Image
sys.path.insert(0, "/workspace/art_refresh/tools"); sys.path.insert(0, "/workspace/hub_v3/tools")
import common as C
from build_hub_v3 import KINDS, kind_of, clean_magenta

HUB = Path("/workspace/hub_v3")
GRID_OF = {}
FACTOR = {}
for g in ("hub_trees_A", "hub_trees_B", "hub_bushes_A"):
    rep = json.loads((HUB / "out" / g / "build.json").read_text())
    for nm, ck in rep["cells"].items():
        GRID_OF[nm] = g; FACTOR[nm] = ck["factor"]


def render(nm, s):
    k = kind_of(nm); spec = KINDS[k]; W0, H0 = spec["canvas"]
    c = C.load_rgba(HUB / "work" / GRID_OF[nm] / "slices" / f"{nm}.png")
    f = FACTOR[nm] * s
    if abs(s - 1.0) < 1e-9:
        W, H = W0, H0
    else:
        W, H = int(round(W0 * s / 2.0)) * 2, int(round(H0 * s))
    size = (max(1, int(round(c.shape[1] * f))), max(1, int(round(c.shape[0] * f))))
    # keep inside the canvas (pad 1 left/right/top), like the v3 builder's "shrunk alone" rule
    if size[0] > W - 2 or size[1] > H - 1:
        f2 = min((W - 2) / c.shape[1], (H - 1) / c.shape[0]); size = (int(round(c.shape[1] * f2)), int(round(c.shape[0] * f2)))
    small = C.pixelize(c, size, colors=spec["colors"], method="box", outline=spec["outline"])
    small = C.trim(small) if C.alpha_bbox(small) else small
    bx0 = (W - small.shape[1]) // 2
    arr = C.place(small, W, H, (bx0, 0, bx0 + small.shape[1], H), "bottom")
    arr, nfix = clean_magenta(arr)
    if nfix and C.alpha_bbox(arr):
        ys = np.nonzero(arr[..., 3].any(1))[0]
        if ys.max() != H - 1:
            arr = np.roll(arr, H - 1 - ys.max(), axis=0)
    return arr, {"raw_factor": round(f, 5), "raw_upscaled": f > 1.0, "content": list(small.shape[1::-1]), "magenta_fixed": nfix}


if __name__ == "__main__":
    if sys.argv[1] == "--verify":
        repo = Path(sys.argv[2])
        for nm in FACTOR:
            arr, _ = render(nm, 1.0)
            sub = "trees" if "tree" in nm else "bushes"
            old = np.array(Image.open(repo / f"assets/art/hub/{sub}/{nm}.png").convert("RGBA"))
            print(nm, arr.shape == old.shape and np.array_equal(arr, old), arr.shape, old.shape,
                  int((arr != old).any(-1).sum()) if arr.shape == old.shape else "-")
        sys.exit()
    repo, buckets = Path(sys.argv[1]), json.loads(Path(sys.argv[2]).read_text())
    info = {}
    for nm, scales in buckets.items():
        sub = "trees" if "tree" in nm else "bushes"
        for s in scales:
            arr, inf = render(nm, s)
            rel = f"assets/art/hub/{sub}/sized/{nm}_s{int(round(s * 100)):03d}.png"
            C.save_rgba(arr, repo / rel)
            inf.update(size=[arr.shape[1], arr.shape[0]]); info[rel] = inf
            print(rel, inf)
    Path(sys.argv[3]).write_text(json.dumps(info, indent=1))
