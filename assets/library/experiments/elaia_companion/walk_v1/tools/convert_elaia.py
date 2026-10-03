#!/usr/bin/env python3
"""Elaia walk v1 (copy of keeper walk7 convert_video.py, retargeted): video frames -> native 128x128 frames (no bob shaping yet).
key -> figure crop -> ONE scale per direction (tallest frame of the chosen cycle = the Option A still's height)
-> premultiplied AREA (BOX) downscale straight to game size -> hard alpha (>=50%) -> despeck (<4 px islands)
-> defringe (Elaia violet band) -> Elaia 40-colour palette (nearest Lab, no dither) -> soles row 123, head+torso centroid fixed x.
usage: convert_video.py DIR STILL(s|n|e) first last   (inclusive video frame range = the cycle + 1 frame)"""
import sys, json
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage
sys.path.insert(0, '/workspace/keeper_idle/tools'); sys.path.insert(0, '/workspace/elaia_anims/walk'); sys.path.insert(0, '/workspace/elaia_anims')
from analyse_video import figure
from build_idles import apply_palette
from ingest_elaia import defringe
R = Path('/workspace/elaia_anims'); A = R / 'stills'
PAL = np.array(json.loads((A / 'palette.json').read_text())['colors'], np.int32)

def crop(d, i):
    f, a, bg = figure(np.array(Image.open(R / f'walk/frames/{d}/f_{i:03d}.png').convert('RGB')))
    ys, xs = np.nonzero(a > 0.02); y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    b = np.nonzero((a > 0.5).any(1))[0]
    return f[y0:y1, x0:x1], a[y0:y1, x0:x1], int(b.max() - b.min() + 1)

def area_down(rgb, a, scale):
    h, w = a.shape; W, H = max(1, round(w * scale)), max(1, round(h * scale))
    pm = np.dstack([rgb * a[..., None], a * 255]).astype(np.float32)
    ch = [np.array(Image.fromarray(pm[..., c]).resize((W, H), Image.BOX)) for c in range(4)]
    A_ = ch[3]; rgbo = np.dstack([np.where(A_ > 1, np.clip(ch[c] / np.maximum(A_, 1) * 255, 0, 255), 0) for c in range(3)])
    out = np.dstack([rgbo, np.where(A_ >= 128, 255, 0)]).astype(np.uint8); out[out[..., 3] == 0] = 0
    return out

def despeck(s, min_px=4):
    op = s[..., 3] > 0; lab, n = ndimage.label(op, np.ones((3, 3)))
    if n <= 1: return s
    area = ndimage.sum(op, lab, np.arange(1, n + 1)); keep = np.isin(lab, 1 + np.nonzero(area >= min_px)[0])
    s = s.copy(); s[~keep] = 0; return s

def run(d, still, first, last):
    st = np.array(Image.open(A / f'elaia_still_{still}.png')); r = np.nonzero(st[..., 3].any(1))[0]; target = r.max() - r.min() + 1
    idx = list(range(first, last + 1)); C = {i: crop(d, i) for i in idx}
    scale = target / max(c[2] for c in C.values())
    small = {i: despeck(area_down(c[0], c[1], scale)) for i, c in C.items()}
    info = {}
    for i, s in small.items():
        op = s[..., 3] > 0; rows = np.nonzero(op.any(1))[0]; t, b = rows.min(), rows.max()
        ys, xs = np.nonzero(op[t:t + int(0.5 * (b - t))]); band = np.nonzero(op[b - 5:b + 1].any(0))[0]
        info[i] = (t, b, xs.mean(), (band.min() + band.max()) / 2)
    AX = 63.5 - np.mean([v[3] - v[2] for v in info.values()])
    out = R / f'walk/work/{d}'; out.mkdir(parents=True, exist_ok=True); meta = {}
    for i, s in small.items():
        t, b, ax, fc = info[i]; g = np.zeros((128, 128, 4), np.uint8); ox = int(round(AX - ax)); oy = 123 - b
        hh, ww = s.shape[:2]; X0, Y0 = max(0, ox), max(0, oy); X1, Y1 = min(128, ox + ww), min(128, oy + hh)
        g[Y0:Y1, X0:X1] = s[Y0 - oy:Y1 - oy, X0 - ox:X1 - ox]
        g, nf = defringe(g); g = apply_palette(g, PAL); g = despeck(g)
        Image.fromarray(g).save(out / f'g_{i:03d}.png')
        op = g[..., 3] > 0; rows = np.nonzero(op.any(1))[0]; bx = np.nonzero(op[118:124].any(0))[0]
        meta[i] = {'top': int(rows.min()), 'h': int(124 - rows.min()), 'feet_x': [int(bx.min()), int(bx.max())], 'defringed': nf}
    (out / 'convert.json').write_text(json.dumps({'scale': scale, 'target_h': int(target), 'anchor_x': AX, 'frames': meta}, indent=0))
    print(d, 'scale', round(scale, 4), 'target', target, {i: (m['h'], m['feet_x']) for i, m in meta.items()})

if __name__ == '__main__':
    run(sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4]))
