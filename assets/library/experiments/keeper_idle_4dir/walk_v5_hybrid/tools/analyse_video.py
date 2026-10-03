#!/usr/bin/env python3
"""Walk v3: per-frame analysis of an Imagine walk-in-place video (frames already extracted with ffmpeg).
key (sampled magenta, tolerance + despill; tools/ingest_turnaround.key), largest figure, then metrics:
top/sole/height, head centroid x (top 25% of figure), torso centroid x, feet band extents and per-side lowest rows."""
import sys, json
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage
sys.path.insert(0, '/workspace/keeper_idle/tools')
from ingest_turnaround import key
R = Path('/workspace/keeper_idle/walk7')

def figure(rgb):
    f, a, bg = key(rgb)
    m = a > 0.5; lab, n = ndimage.label(m, np.ones((3, 3)))
    area = ndimage.sum(m, lab, np.arange(1, n + 1)); big = 1 + int(np.argmax(area))
    sl = ndimage.find_objects(lab)[big - 1]
    # keep components overlapping the big bbox (expanded) and > 6 px (detached hair tips etc.)
    y0, y1, x0, x1 = sl[0].start - 6, sl[0].stop + 6, sl[1].start - 6, sl[1].stop + 6
    keep = np.zeros_like(m)
    for i, s in enumerate(ndimage.find_objects(lab)):
        if area[i] < 6: continue
        cy, cx = (s[0].start + s[0].stop) / 2, (s[1].start + s[1].stop) / 2
        if y0 <= cy <= y1 and x0 <= cx <= x1: keep |= lab == i + 1
    return f, a * keep, bg

def metrics(a):
    m = a > 0.5; ys, xs = np.nonzero(m); top, sole = ys.min(), ys.max(); h = sole - top + 1
    head = m[top:top + int(0.25 * h)]; hy, hx = np.nonzero(head)
    tor = m[top + int(0.3 * h):top + int(0.6 * h)]; ty, tx = np.nonzero(tor)
    band = m[sole - int(0.06 * h):sole + 1]; bx = np.nonzero(band.any(0))[0]
    leg = m[top + int(0.8 * h):sole + 1]; lx = np.nonzero(leg.any(0))[0]
    # per-foot: split leg band columns into runs
    cols = leg.any(0); runs = []; x = 0; W = len(cols)
    while x < W:
        if cols[x]:
            s = x
            while x < W and cols[x]: x += 1
            runs.append((s, x - 1))
        x += 1
    feet = []
    for s, e in runs:
        if e - s < 3: continue
        sub = m[top + int(0.8 * h):sole + 1, s:e + 1]; r = np.nonzero(sub.any(1))[0]
        feet.append({'x0': int(s), 'x1': int(e), 'low': int(top + int(0.8 * h) + r.max())})
    return {'top': int(top), 'sole': int(sole), 'h': int(h), 'head_cx': float(hx.mean()), 'torso_cx': float(tx.mean()),
            'band_x0': int(bx.min()), 'band_x1': int(bx.max()), 'leg_x0': int(lx.min()), 'leg_x1': int(lx.max()), 'feet': feet,
            'w': int(xs.max() - xs.min() + 1)}

if __name__ == '__main__':
    d = sys.argv[1]; files = sorted((R / 'frames' / d).glob('f_*.png')); out = []
    for p in files:
        rgb = np.array(Image.open(p).convert('RGB')); f, a, bg = figure(rgb)
        m = metrics(a); m['i'] = int(p.stem[2:]); out.append(m)
    (R / f'metrics_{d}.json').write_text(json.dumps(out, indent=0))
    for m in out[::4]:
        print(m['i'], 'top', m['top'], 'sole', m['sole'], 'h', m['h'], 'hx', round(m['head_cx'], 1), 'tx', round(m['torso_cx'], 1),
              'leg', m['leg_x0'], m['leg_x1'], 'feet', [(f['x0'], f['x1'], f['low']) for f in m['feet']])
