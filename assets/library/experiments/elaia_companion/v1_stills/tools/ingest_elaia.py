#!/usr/bin/env python3
"""Ingest an Elaia turnaround sheet the Keeper way (tools/ingest_turnaround.py: corner-sampled soft key + magenta despill,
split into 4 figures, ONE shared scale from the front view, premultiplied LANCZOS to 2x then NN x0.5, hard alpha, 128 canvas,
sole row 123, feet centred x 64), then JPEG-fringe cleanup and one ~40-colour Elaia palette.
Sheet order here: S, N, L1, L2 (both left-facing profiles)."""
import json, sys
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage
from scipy.cluster.vq import kmeans2
sys.path.insert(0, '/workspace/keeper_idle/tools')
import ingest_turnaround as IT
from build_idles import to_lab, apply_palette
HEIGHT = 116; NCOL = 40
def hue_sat(px):
    px = px.astype(float); mx = px.max(-1); mn = px.min(-1); c = mx - mn
    r, g, b = px[..., 0], px[..., 1], px[..., 2]
    with np.errstate(divide='ignore', invalid='ignore'):
        h = np.where(mx == r, ((g - b) / c) % 6, np.where(mx == g, (b - r) / c + 2, (r - g) / c + 4)) * 60
        s = np.where(mx > 0, c / mx, 0)
    return np.nan_to_num(h), s
def tint(px):
    """key contamination: violet/magenta hues (design has blues up to ~225 deg and no purple/pink at all)"""
    h, s = hue_sat(px); c = px.max(-1).astype(int) - px.min(-1)
    return (c > 8) & (s > 0.10) & (h >= 232) & (h <= 345)
def defringe(k):
    a = k.copy(); op = a[..., 3] > 0; bad = op & tint(a[..., :3]); good = op & ~bad; n = int(bad.sum())
    for y, x in zip(*np.nonzero(bad)):
        sl = (slice(max(0, y - 2), y + 3), slice(max(0, x - 2), x + 3)); nb = a[sl][good[sl]][:, :3].astype(float)
        if not len(nb): a[y, x] = 0; continue
        ref = np.median(nb, 0); lum = a[y, x, :3].astype(float).mean(); a[y, x, :3] = np.clip(ref * min(lum / max(ref.mean(), 1), 1.15), 0, 255)
    return a, n
def despeck(k, min_px=4):
    op = k[..., 3] > 0; lab, n = ndimage.label(op, np.ones((3, 3)))
    if n <= 1: return k, 0
    sz = ndimage.sum(op, lab, range(1, n + 1)); kill = (lab > 0) & np.isin(lab, 1 + np.nonzero(sz < min_px)[0]); k = k.copy(); k[kill] = 0
    return k, int(kill.sum())
def ingest(sheet, order=('S', 'N', 'L1', 'L2')):
    rgb = np.array(Image.open(sheet).convert('RGB'))
    f, alpha, bg = IT.key(rgb)
    lab, groups = IT.split(alpha, len(order))
    crops = {d: IT.view_crop(f, alpha, lab, g) for d, g in zip(order, groups)}
    hts = {d: (lambda e: e[1] - e[0] + 1)(IT.body_extent(c[1])) for d, c in crops.items()}
    scale = HEIGHT / hts['S']; out = {}; info = {'sheet': str(sheet), 'bg': [int(v) for v in bg], 'src_heights': {d: int(h) for d, h in hts.items()}, 'scale': scale, 'views': {}}
    for d, (c, a) in crops.items():
        g, clipped = IT.place(IT.to_game(c, a, scale)); g, nf = defringe(g); out[d] = g
        info['views'][d] = {'clipped': clipped, 'defringed': nf}
    return out, info
def palette(imgs, n=NCOL):
    px = np.concatenate([k[k[..., 3] > 0][:, :3] for k in imgs]).astype(np.int32)
    L = to_lab(px); cent, lbl = kmeans2(L.astype(np.float64), n, minit='++', iter=40, seed=11)
    return np.array([np.median(px[lbl == i], 0) for i in range(n) if (lbl == i).any()]).round().astype(np.uint8)
if __name__ == '__main__':
    sheet = sys.argv[1]; name = sys.argv[2]
    views, info = ingest(sheet); d = Path('work') / name; d.mkdir(parents=True, exist_ok=True)
    for k, v in views.items(): Image.fromarray(v).save(d / f'raw_{k}.png')
    for k, v in views.items():
        ys, xs = np.nonzero(v[..., 3]); info['views'][k].update({'top': int(ys.min()), 'height': int(ys.max() - ys.min() + 1), 'x': [int(xs.min()), int(xs.max())]})
    (d / 'ingest.json').write_text(json.dumps(info, indent=1)); print(json.dumps(info))
