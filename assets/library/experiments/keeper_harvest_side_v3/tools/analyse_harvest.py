#!/usr/bin/env python3
"""Harvest v3 (side, video route): per-frame key + figure isolation + metrics.
figure = largest keyed component + any component touching it after a 4 px dilation (tool parts split by compression);
everything else (wood chips, rock, flying debris, detached berries) is dropped.
metrics: bbox, hair (green) centroid = head anchor, body sole = lowest opaque row within +-45 px of the hair x."""
import sys, json
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage
sys.path.insert(0, '/workspace/keeper_idle/tools')
from ingest_turnaround import key
R = Path('/workspace/keeper_idle/harv')

def isolate(rgb, dil=4):
    f, a, bg = key(rgb)
    m = a > 0.5; lab, n = ndimage.label(m, np.ones((3, 3)))
    area = ndimage.sum(m, lab, np.arange(1, n + 1)); big = lab == 1 + int(np.argmax(area))
    near = ndimage.binary_dilation(big, np.ones((2 * dil + 1, 2 * dil + 1)))
    keep_ids = np.unique(lab[near & m]); keep = np.isin(lab, keep_ids[keep_ids > 0])
    soft = ndimage.binary_dilation(keep, np.ones((3, 3)))          # keep the soft edge of kept parts only
    return f, a * soft * (ndimage.binary_dilation(keep, np.ones((5, 5)))), bg, keep

def metrics(f, a):
    m = a > 0.5; ys, xs = np.nonzero(m)
    r, g, b = f[..., 0], f[..., 1], f[..., 2]
    green = m & (g > r + 25) & (g > b + 25)
    gy, gx = np.nonzero(green); hx = float(gx.mean()); hy = float(gy.mean())
    band = m[:, max(0, int(hx) - 45):int(hx) + 45]; sole = int(np.nonzero(band.any(1))[0].max())
    hair_top = int(gy.min())
    return {'x0': int(xs.min()), 'x1': int(xs.max()), 'y0': int(ys.min()), 'y1': int(ys.max()), 'hair_cx': hx, 'hair_cy': hy,
            'hair_top': hair_top, 'sole': sole, 'body_h': sole - hair_top + 1, 'hair_w': int(np.ptp(gx))}

if __name__ == '__main__':
    act = sys.argv[1]; files = sorted((R / 'frames' / act).glob('f_*.png')); out = []; M = []
    for p in files:
        f, a, bg, keep = isolate(np.array(Image.open(p).convert('RGB')))
        m = metrics(f, a); m['i'] = int(p.stem[2:]); out.append(m)
        M.append(np.array(Image.fromarray((a * 255).astype(np.uint8)).resize((168, 112), Image.BILINEAR)) / 255.)
    M = np.array(M); np.save(R / f'masks_{act}.npy', M); (R / f'metrics_{act}.json').write_text(json.dumps(out))
    n = len(M); lags = []
    for lag in range(12, 60):
        dd = [np.abs(M[i] - M[i + lag]).sum() for i in range(n - lag)]; lags.append((round(float(np.mean(dd)), 1), lag))
    print(act, 'best lags', sorted(lags)[:6])
    hx = [m['hair_cx'] for m in out]; bh = [m['body_h'] for m in out]; hw = [m['hair_w'] for m in out]
    print('  hair_cx range', round(min(hx), 1), round(max(hx), 1), 'body_h', min(bh), max(bh), 'hair_w', min(hw), max(hw), 'sole', min(m['sole'] for m in out), max(m['sole'] for m in out))
    print('  bbox x', min(m['x0'] for m in out), max(m['x1'] for m in out), 'y', min(m['y0'] for m in out), max(m['y1'] for m in out))
