#!/usr/bin/env python3
"""Station work north v3 (generic, hands low in front), video route: Imagine clip -> native 128x128 frames, bench removed.
Same fixed transform as station v1/v2 and the Option A N still (camera locked, feet planted): scale 120/348, video feet centre
edge x (336; 339 for clip a's wider working stance) -> canvas x 64, sole edge y 398 -> canvas y 124 (soles row 123).
Bench removal (video px, before the downscale; Imagine drew a small two-plank bench end on each side of his waist, static,
rows ~246..272, x ~268..294 and ~378..412):
  * band rows BAND: keep only the coat's blue run around the body centre (gaps <= 40 px bridged) +-2 px outline, everything
    else in those rows -> transparent;
  * inside the band, wood-coloured px (hue 15..55, sat > .25, value > 50) -> transparent (plank ends overlapping the coat edge),
    plus the planks' dark outline (non-blue, max RGB < 80, within 3 px of that wood);
  * then keep the largest component only (any detached artefact / particle / item is dropped).
Then premultiplied BOX downscale -> hard alpha -> despeck -> defringe -> Option A palette (48, nearest Lab, no extras) ->
maroon-below-head -> dark brown -> keep main.  No tool hue fix (it would grey the rune).
usage: convert_station3.py CLIP first last"""
import sys, json, colorsys
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage
sys.path.insert(0, '/workspace/keeper_idle/tools'); sys.path.insert(0, '/workspace/keeper_idle/harv')
from ingest_turnaround import key
import convert_harv as C
from build_idles import apply_palette
R = Path('/workspace/keeper_idle'); S_ = R / 'station3'
SCALE = 120 / 348; FEET_V = 336.0; SOLE_V = 398.0; W = H = 128; FX = 64
BAND = {'a': (246, 277), 'b': (236, 276), 'c': (236, 276)}
# feet edge centre in the working pose (clip a stands wider than the still: feet x 268..409 -> centre 339; f1 = 336 like the still)
FEET = {'a': 339.0, 'b': 336.0, 'c': 336.0}
PAL = np.array([list(c) for c in C.BASE], np.int32)

def hsv_arr(f):
    c = f.astype(float) / 255; mx = c.max(-1); mn = c.min(-1); d = mx - mn
    s = np.where(mx > 0, d / np.maximum(mx, 1e-6), 0); r, g, b = c[..., 0], c[..., 1], c[..., 2]; dd = np.maximum(d, 1e-6)
    h = np.where(mx == r, ((g - b) / dd) % 6, np.where(mx == g, (b - r) / dd + 2, (r - g) / dd + 4)) * 60
    return np.where(d > 0, h, 0), s, mx * 255

def debench(f, a, band):
    m = a > 0.5; r, g, b = f[..., 0].astype(int), f[..., 1].astype(int), f[..., 2].astype(int)
    blue = m & (b > r + 30) & (b > g)
    kill = np.zeros_like(m)
    for y in range(*band):
        row = blue[y]
        if not row.any(): kill[y] = m[y]; continue
        lab, n = ndimage.label(ndimage.binary_closing(np.pad(row, 40), np.ones(41))[40:-40]); best = None
        for k in range(1, n + 1):
            xx = np.nonzero(lab == k)[0]; d = 0 if xx.min() <= FEET_V <= xx.max() else min(abs(xx.min() - FEET_V), abs(xx.max() - FEET_V))
            if best is None or d < best[0] or (d == best[0] and len(xx) > best[1]): best = (d, len(xx), xx.min(), xx.max())
        x0, x1 = best[2] - 2, best[3] + 2; k_ = m[y].copy(); k_[max(0, x0):x1 + 1] = False; kill[y] = k_
    h, s, v = hsv_arr(f); wood = m & (h >= 15) & (h <= 55) & (s > 0.25) & (v > 50)
    wb = np.zeros_like(m); wb[band[0]:band[1]] = True; kill |= wood & wb
    # the planks' dark outline (non-blue px with max RGB < 80 within 3 px of the removed wood) goes too
    dark = m & (np.maximum(np.maximum(r, g), b) < 80) & ~blue
    kill |= dark & wb & ndimage.binary_dilation(wood & wb, np.ones((7, 7)))
    a2 = a * ~kill; mm = a2 > 0.5
    lab, n = ndimage.label(mm, np.ones((3, 3)))
    if n > 1:
        area = ndimage.sum(mm, lab, np.arange(1, n + 1)); keep = lab == 1 + int(np.argmax(area))
        a2 = a2 * ndimage.binary_dilation(keep, np.ones((3, 3)))
    return a2, int(kill.sum())

def native(clip, i, pal=PAL):
    rgb = np.array(Image.open(S_ / f'frames/{clip}/f_{i:03d}.png').convert('RGB'))
    f, a, bg = key(rgb); a, nk = debench(f, a, BAND[clip])
    P = 120; pm = np.dstack([f * a[..., None], a * 255]).astype(np.float32); pm = np.pad(pm, ((P, P), (P, P), (0, 0)))
    x0 = FEET[clip] - FX / SCALE + P; y0 = SOLE_V - (H - 4) / SCALE + P; box = (x0, y0, x0 + W / SCALE, y0 + H / SCALE)
    ch = [np.array(Image.fromarray(pm[..., c]).resize((W, H), Image.BOX, box=box)) for c in range(4)]
    A_ = ch[3]; rgbo = np.dstack([np.where(A_ > 1, np.clip(ch[c] / np.maximum(A_, 1) * 255, 0, 255), 0) for c in range(3)])
    g = np.dstack([rgbo, np.where(A_ >= 128, 255, 0)]).astype(np.uint8); g[g[..., 3] == 0] = 0
    g = C.despeck(g); g, nf = C.defringe(g)
    if pal is not None:
        g = apply_palette(g, pal); g, nm = C.demaroon(g); g, nd = C.keep_main(g); g = C.despeck(g)
    else: nm = nd = 0
    return g, {'bench_px_removed_video': nk, 'defringed': nf, 'maroon': nm, 'dropped': nd}

if __name__ == '__main__':
    clip, first, last = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
    out = S_ / f'work/{clip}'; out.mkdir(parents=True, exist_ok=True)
    log = json.loads((out / 'convert.json').read_text()) if (out / 'convert.json').exists() else {}
    for i in range(first, last + 1):
        g, info = native(clip, i); Image.fromarray(g).save(out / f'g_{i:03d}.png')
        op = g[..., 3] > 0; rows = np.nonzero(op.any(1))[0]; cols = np.nonzero(op.any(0))[0]
        info.update(top=int(rows.min()), bottom=int(rows.max()), x0=int(cols.min()), x1=int(cols.max())); log[str(i)] = info
    (out / 'convert.json').write_text(json.dumps(log, indent=0))
    print({i: (v['top'], v['bottom'], v['x0'], v['x1'], v['bench_px_removed_video']) for i, v in log.items() if first <= int(i) <= last})
