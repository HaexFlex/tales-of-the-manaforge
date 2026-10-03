#!/usr/bin/env python3
"""lift (lowest row of each boot vs 123), planted-boot toe x per frame, feet centre, top/bob, for an 8-frame side walk"""
import sys, json
import numpy as np
from PIL import Image
d, pre = sys.argv[1], sys.argv[2]
rows = []
for k in range(8):
    a = np.array(Image.open(f'{d}/{pre}_{k:04d}.png'))[..., 3] > 0
    low = np.array([np.nonzero(a[100:, x])[0].max() + 100 if a[100:, x].any() else -1 for x in range(128)])
    # boot blobs: runs of columns whose lowest pixel >= 112
    runs, x = [], 0
    while x < 128:
        if low[x] >= 112:
            s = x
            while x < 128 and low[x] >= 112: x += 1
            runs.append((s, x - 1, int(123 - low[s:x].max())))
        x += 1
    ground = np.nonzero(a[123])[0]
    t = int(np.nonzero(a.any(1))[0].min())
    rows.append({'k': k, 'top': t, 'bob': t - 5, 'boot_runs_x0_x1_lift': runs, 'ground_x': [int(ground.min()), int(ground.max())] if len(ground) else None,
                 'feet_centre': round((min(r[0] for r in runs) + max(r[1] for r in runs)) / 2, 1)})
for r in rows: print(json.dumps(r))
