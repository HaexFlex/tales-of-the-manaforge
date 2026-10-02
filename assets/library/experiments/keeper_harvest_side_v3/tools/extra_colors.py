#!/usr/bin/env python3
"""Derive the minimal extra (non-Option-A) colours the tools need, from the downscaled (pre-palette) frames:
iron = low-saturation pixels that the 48-colour palette maps badly (Lab dist > 10) -> k-means 3 (dark/mid/light steel);
berry = saturated red (hue <12 or >348, sat > .55) in the berries clip -> k-means 2. Wood: only if the palette browns
fail (Lab dist > 12 on >15% of handle pixels) -> reported, not added by default."""
import sys, json
from pathlib import Path
import numpy as np
from scipy.cluster.vq import kmeans2
from scipy.spatial import cKDTree
sys.path.insert(0, '/workspace/keeper_idle/harv'); sys.path.insert(0, '/workspace/keeper_idle/tools')
import convert_harv as C
from build_idles import to_lab
np.random.seed(7)
tree = cKDTree(to_lab(C.BASE))
def collect(act, frames, rock=None):
    px = []
    for i in frames:
        g, _ = C.native(act, i, 136, rock, None); px.append(g[g[..., 3] > 0][:, :3])
    return np.concatenate(px)
iron = []; red = []
rk = C.rock_mask()
for act, fr in [('axe', range(35, 58, 2)), ('pickaxe', range(38, 66, 2))]:
    p = collect(act, fr, rk if act == 'pickaxe' else None); h, s, v = C.hsv(p[None])
    h, s, v = h[0], s[0], v[0]; d, _ = tree.query(to_lab(p.astype(np.int32)))
    iron.append(p[(s < 0.22) & (v > 60) & (d > 10)])
p = collect('berries', range(78, 92, 2)); h, s, v = C.hsv(p[None]); h, s, v = h[0], s[0], v[0]
d, _ = tree.query(to_lab(p.astype(np.int32))); red = p[((h < 12) | (h > 348)) & (s > 0.55) & (v > 90) & (d > 10)]
iron = np.concatenate(iron).astype(float)
ci, li = kmeans2(iron, 3, minit='++', seed=7); cr, lr = kmeans2(red.astype(float), 2, minit='++', seed=7)
ci = ci[np.argsort(ci.mean(1))]; cr = cr[np.argsort(cr.mean(1))]
print('iron px', len(iron), np.round(ci), 'red px', len(red), np.round(cr))
cols = [[int(round(x)) for x in c] for c in list(ci) + list(cr)]
Path('/workspace/keeper_idle/harv/extra_colors.json').write_text(json.dumps({'colors': cols, 'names': ['iron_dark', 'iron_mid', 'iron_light', 'berry_dark', 'berry_red'],
  'how': 'k-means of off-palette (Lab dist>10) low-sat steel px in axe+pickaxe frames (3) and saturated red berry px (2)'}, indent=1))
