#!/usr/bin/env python3
"""Elaia harvest/station: per-frame key + all-component stats (no isolation) -> metrics_<act>.json, masks_<act>.npy (168x112).
metrics: largest component bbox, sole (lowest row of largest comp), feet band x (rows sole-12..sole), number/area of
other components (debris / rock / particles), head-top."""
import sys, json
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage
sys.path.insert(0, '/workspace/keeper_idle/tools')
from ingest_turnaround import key
R = Path('/workspace/elaia_anims/harv')
act = sys.argv[1]; files = sorted((R / 'frames' / act).glob('f_*.png')); out = []; M = []
for p in files:
    f, a, bg = key(np.array(Image.open(p).convert('RGB'))); m = a > 0.5
    lab, n = ndimage.label(m, np.ones((3, 3))); area = ndimage.sum(m, lab, np.arange(1, n + 1)); big = lab == 1 + int(np.argmax(area))
    ys, xs = np.nonzero(big); sole = int(ys.max()); band = big[sole - 12:sole + 1]; bx = np.nonzero(band.any(0))[0]
    others = [(int(area[k]), [int(v) for v in ndimage.center_of_mass(lab == k + 1)]) for k in range(n) if lab[ys[0], xs[0]] != k + 1 and area[k] >= 8]
    out.append({'i': int(p.stem[2:]), 'x0': int(xs.min()), 'x1': int(xs.max()), 'y0': int(ys.min()), 'sole': sole, 'feet': [int(bx.min()), int(bx.max())],
                'others': others})
    M.append(np.array(Image.fromarray((big * 255).astype(np.uint8)).resize((168, 112), Image.BILINEAR)) / 255.)
np.save(R / f'masks_{act}.npy', np.array(M)); (R / f'metrics_{act}.json').write_text(json.dumps(out))
for o in out[::4]: print(o['i'], o['x0'], o['x1'], o['y0'], o['sole'], o['feet'], o['others'][:4])
