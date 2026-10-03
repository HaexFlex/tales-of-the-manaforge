#!/usr/bin/env python3
"""Watering (side, video route): like convert_harv.py (same fixed transform: scale 119/344, video x 344 -> canvas x 96,
sole edge y 396 -> canvas y 132, 192x136), with a water-aware isolate and a separate water palette.
isolate_water: figure = largest keyed component + touching parts (the stream is attached to the spout), PLUS free water
components (stream dashes) - water = keyed px with b > r + 50 right of the body (video x > 382);
ground splash removal: in the ground band (video y >= 372) keep only the stream's own column range (measured at y 345..371,
+-4 px) -> the spreading splash and flying splash drops go, the stream still reaches the ground.
After the BOX downscale + hard alpha: water px (blue/cyan, x >= 130 or g >= 120) -> nearest of the 3 water tones only;
everything else -> Option A 48 + can extras (nearest Lab). Stray drops (< 3 px water islands) dropped.
usage: convert_water.py first last [width]   (feet x = width/2; writes harv/work/water/g_###.png)"""
import sys, json
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage
from scipy.spatial import cKDTree
sys.path.insert(0, '/workspace/keeper_idle/tools'); sys.path.insert(0, '/workspace/keeper_idle/harv')
from ingest_turnaround import key
import convert_harv as C
from build_idles import to_lab, apply_palette
R = Path('/workspace/keeper_idle'); H_ = R / 'harv'
FEET_V = 306.0   # this clip's figure drifts 38 video px left during f1-25 (Imagine), then stays planted: feet band x 272..339 from f25 on
WW, FX = 192, 96  # canvas width / feet x edge (set by the caller; the stream may need a wider canvas)
WX = json.loads((H_ / 'water_colors.json').read_text()) if (H_ / 'water_colors.json').exists() else None

def water_px(f, a):
    r, g, b = f[..., 0].astype(int), f[..., 1].astype(int), f[..., 2].astype(int)
    return (a > 0.3) & (b > r + 50) & (b > 120)

def isolate_water(rgb):
    f, a, bg = key(rgb); m = a > 0.5; h, w = m.shape
    lab, n = ndimage.label(m, np.ones((3, 3))); area = ndimage.sum(m, lab, np.arange(1, n + 1)); big = lab == 1 + int(np.argmax(area))
    near = ndimage.binary_dilation(big, np.ones((9, 9))); ids = np.unique(lab[near & m]); keep = np.isin(lab, ids[ids > 0])
    wat = water_px(f, a); xx = np.arange(w)[None, :].repeat(h, 0)
    for k in range(1, n + 1):                         # free stream dashes: components that are mostly water, right of the body
        comp = lab == k
        if keep[comp].any(): continue
        if wat[comp].mean() > 0.6 and xx[comp].min() > 382: keep |= comp
    # ground splash: band y >= 372 -> only the stream's column range at y 345..371
    band = (wat & keep)[345:372, 382:]; cols = np.nonzero(band.any(0))[0]
    gz = np.zeros_like(keep); gz[372:, 382:] = True
    if len(cols):
        x0, x1 = 382 + cols.min() - 4, 382 + cols.max() + 4; allow = np.zeros_like(keep); allow[:, x0:x1 + 1] = True
        keep &= ~(gz & ~allow)
    else: keep &= ~gz
    keep &= ~(np.arange(h)[:, None] > 396)           # nothing below the ground line (splash spray)
    soft = ndimage.binary_dilation(keep, np.ones((3, 3)))
    return f, a * soft, bg, keep

def native_water(i, H=136, pal=None):
    rgb = np.array(Image.open(H_ / f'frames/water/f_{i:03d}.png').convert('RGB'))
    f, a, bg, keep = isolate_water(rgb); a = a * ndimage.binary_dilation(keep, np.ones((5, 5)))
    P = 120; pm = np.dstack([f * a[..., None], a * 255]).astype(np.float32); pm = np.pad(pm, ((P, P), (P, P), (0, 0)))
    x0 = FEET_V - FX / C.S + P; y0 = C.SOLE_V - (H - 4) / C.S + P; box = (x0, y0, x0 + WW / C.S, y0 + H / C.S)
    ch = [np.array(Image.fromarray(pm[..., c]).resize((WW, H), Image.BOX, box=box)) for c in range(4)]
    A_ = ch[3]; rgbo = np.dstack([np.where(A_ > 1, np.clip(ch[c] / np.maximum(A_, 1) * 255, 0, 255), 0) for c in range(3)])
    g = np.dstack([rgbo, np.where(A_ >= 128, 255, 0)]).astype(np.uint8); g[g[..., 3] == 0] = 0
    g = C.despeck(g, 3); g, nf = C.defringe(g)
    c = g[..., :3].astype(int); op = g[..., 3] > 0; xx = np.arange(WW)[None, :].repeat(H, 0)
    wmask = op & (c[..., 2] > c[..., 0] + 50) & ((xx >= FX + 47) | (c[..., 1] >= 120))
    info = {'defringed': nf, 'water_px': int(wmask.sum())}
    if pal is None: return g, wmask, info
    wc = np.array(WX['water'], np.int32)
    body = apply_palette(np.where(wmask[..., None], 0, g).astype(np.uint8), pal)
    out = body.copy()
    if wmask.any():
        _, idx = cKDTree(to_lab(wc)).query(to_lab(g[wmask][:, :3].astype(np.int32))); out[wmask, :3] = wc[idx]; out[wmask, 3] = 255
    out, nm = C.demaroon(out); info['maroon'] = nm
    return out, wmask, info

def palette_water():
    base = [list(c) for c in C.BASE]; return np.array(base + WX['can'], np.int32)

if __name__ == '__main__':
    first, last = int(sys.argv[1]), int(sys.argv[2]); pal = palette_water()
    if len(sys.argv) > 3: WW = int(sys.argv[3]); FX = WW // 2
    out = H_ / 'work/water'; out.mkdir(parents=True, exist_ok=True); log = {}
    for i in range(first, last + 1):
        g, wm, info = native_water(i, 136, pal); Image.fromarray(g).save(out / f'g_{i:03d}.png')
        op = g[..., 3] > 0; rows = np.nonzero(op.any(1))[0]; cols = np.nonzero(op.any(0))[0]
        info.update(top=int(rows.min()), bottom=int(rows.max()), x0=int(cols.min()), x1=int(cols.max())); log[i] = info
    (out / 'convert.json').write_text(json.dumps(log, indent=0))
    print({i: (v['top'], v['bottom'], v['x0'], v['x1'], v['water_px']) for i, v in log.items()})
