#!/usr/bin/env python3
"""Walk v1 (Option A): key one Imagine walk row (magenta, sampled corners), split the figures left->right, report per-frame
source metrics. Usage: ingest_walk.py SHEET NAME N   -> walk/work/<NAME>/src_##.png (RGBA crops) + metrics.json"""
import sys, json
from pathlib import Path
import numpy as np
from PIL import Image
sys.path.insert(0, '/workspace/keeper_idle/tools')
from ingest_turnaround import key, split, view_crop, body_extent
R = Path('/workspace/keeper_idle')
if __name__ == '__main__':
    sheet, name, n = sys.argv[1], sys.argv[2], int(sys.argv[3])
    rgb = np.array(Image.open(sheet).convert('RGB')); f, alpha, bg = key(rgb)
    lab, groups = split(alpha, n=n)
    out = R / 'walk/work' / name; out.mkdir(parents=True, exist_ok=True)
    met = {'sheet': sheet, 'bg': [int(v) for v in bg], 'frames': []}
    for i, comps in enumerate(groups):
        cr, a = view_crop(f, alpha, lab, comps)
        ys, xs = np.nonzero(lab == comps[0] + 1)
        Image.fromarray(np.dstack([cr, a * 255]).astype(np.uint8)).save(out / f'src_{i:02d}.png')
        t, b = body_extent(a)
        met['frames'].append({'i': i, 'x0': int(xs.min()), 'x1': int(xs.max()), 'top_abs': int(ys.min()), 'sole_abs': int(ys.max()), 'h': int(b - t + 1), 'w': int(a.shape[1])})
    (out / 'metrics.json').write_text(json.dumps(met, indent=1))
    print(name, [(m['h'], m['w'], m['sole_abs']) for m in met['frames']])
    # any keyed stuff near the right edge (cropped 9th figure)?
    print(' right-edge alpha cols:', int((alpha[:, -40:] > 0.5).sum()), 'left-edge:', int((alpha[:, :40] > 0.5).sum()))
