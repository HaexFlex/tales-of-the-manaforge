"""Native (scale 1) harvest stone: 92x96, re-rendered from the HD cutout of the Grok raw."""
import sys; sys.path.insert(0, "/workspace/art_refresh/tools")
import numpy as np, common as C
from pathlib import Path
OUT = Path(sys.argv[1])
W, H, PAD = 92, 96, 2
cut = C.load_rgba("/workspace/art_refresh/new/work/nodes/harvest_stone_cut.png")
spent = C.load_rgba("/workspace/art_refresh/new/work/nodes/harvest_stone_spent_derived_cut.png")
assert cut.shape == spent.shape
tw, th = C.fit_size(cut.shape[1], cut.shape[0], W - 2*PAD, H - 2*PAD)
if (W - 2*PAD - tw) % 2: tw -= 1
for name, src, col in (("harvest_stone", cut, 40), ("harvest_stone_spent", spent, 32)):
    small = C.pixelize(src, (tw, th), colors=col, method="box")
    placed = C.place(small, W, H, (PAD, PAD, W-PAD, H-PAD), "bottom")
    C.save_rgba(placed, OUT / f"{name}.png")
    print(name, tw, th)
