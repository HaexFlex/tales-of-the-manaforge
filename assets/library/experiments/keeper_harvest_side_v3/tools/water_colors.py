#!/usr/bin/env python3
"""Derive the watering extras from the downscaled (pre-palette) frames of the chosen cycle:
water = k-means(3) of the water-mask px (dark edge / mid / light), can = off-palette (Lab dist > 10 to Option A 48)
non-water px of the can region (x >= 112, rows 40..90) -> k-means(2), kept only if >= 2% of can px are that far off."""
import sys, json
from pathlib import Path
import numpy as np
from scipy.cluster.vq import kmeans2
from scipy.spatial import cKDTree
sys.path.insert(0, '/workspace/keeper_idle/harv'); sys.path.insert(0, '/workspace/keeper_idle/tools')
import convert_water as CW, convert_harv as C
from build_idles import to_lab
tree = cKDTree(to_lab(C.BASE)); W = []; CAN = []
for i in range(55, 141, 3):
    g, wm, _ = CW.native_water(i); op = g[..., 3] > 0
    W.append(g[wm][:, :3]); cm = op & ~wm; cm[:40] = False; cm[90:] = False; cm[:, :112] = False; CAN.append(g[cm][:, :3])
W = np.concatenate(W).astype(float); CAN = np.concatenate(CAN)
cw, _ = kmeans2(W, 3, minit='++', seed=3); cw = cw[np.argsort(cw.sum(1))]
d, _ = tree.query(to_lab(CAN.astype(np.int32))); far = CAN[d > 10].astype(float)
print('water px', len(W), np.round(cw), '| can px', len(CAN), 'off-palette', len(far), f'{100*len(far)/len(CAN):.1f}%')
can = []
if len(far) > 0.02 * len(CAN):
    cc, lc = kmeans2(far, 2, minit='++', seed=3); can = [[int(round(v)) for v in c] for c in cc[np.argsort(cc.sum(1))]]
    print('can extras', can, np.bincount(lc))
json.dump({'water': [[int(round(v)) for v in c] for c in cw], 'water_names': ['water_dark', 'water_mid', 'water_light'], 'can': can,
           'how': 'k-means of water-mask px (3) and of off-palette can px (2) over water f55-140 step 3'}, open('/workspace/keeper_idle/harv/water_colors.json', 'w'), indent=1)
