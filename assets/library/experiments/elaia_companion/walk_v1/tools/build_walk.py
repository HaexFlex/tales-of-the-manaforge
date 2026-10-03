#!/usr/bin/env python3
"""Elaia walk v1: 8-frame loops from the converted video frames work/<dir>/g_###.png (convert_elaia.py).
E: elaia_walk_east.mp4 24-frame loop (no holds) sampled every 3 frames; S: 8 unique 3-frame holds of a 24-frame loop;
N: 8 of 11 unique poses (2-3 frame holds, 26-frame loop) picked nearest to uniform 3.25-frame spacing.
Per frame: head-centroid x recentre, bob to 0..2 via fit_top (rows above the hip shift, hip..sole band resampled, soles stay
on row 123), head (+hair) lock, E: bare-thigh skin seen through the robe slit recoloured to the inner-robe blue."""
import json, sys
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage
sys.path.insert(0, '/workspace/keeper_idle/walk3'); import assemble_v3 as A3
H = Path('/workspace/elaia_anims/walk'); W = H / 'work'
def top(f): return int(np.nonzero(f[..., 3].any(1))[0].min())
def load(d, i): return np.array(Image.open(W / d / f'g_{i:03d}.png').convert('RGBA'))
SPEC = {'east': [40, 43, 46, 49, 52, 31, 34, 37], 'south': [88, 91, 94, 97, 100, 103, 82, 85],
        'north': [39, 42, 44, 48, 51, 54, 32, 34]}
CFG = json.loads(sys.argv[1]) if len(sys.argv) > 1 else {}
SKIN = np.array([[253, 228, 204], [230, 192, 164], [196, 149, 129]]); ROBE_IN = np.array([[130, 181, 222], [108, 162, 206], [82, 135, 183]])
def unslit(f, min_bottom=86):
    """skin seen through the robe's front slit (bare thigh/knee, off-model) -> inner-robe blue (lightness-matched).
    Only skin components (8-conn) reaching row >= min_bottom and spanning >= 4 rows are legs; hands end above that, single-row specks are hem-trim highlights (kept)."""
    g = f.copy(); sk = np.zeros(g.shape[:2], bool)
    for s in SKIN: sk |= (g[..., :3] == s).all(-1) & (g[..., 3] > 0)
    lab, n = ndimage.label(sk, np.ones((3, 3))); m = np.zeros_like(sk)
    for k in range(1, n + 1):
        ys = np.nonzero((lab == k).any(1))[0]
        if ys.max() >= min_bottom and ys.max() - ys.min() >= 3: m |= lab == k   # 1-row specks = hem-trim highlights
    for s, r in zip(SKIN, ROBE_IN):
        mm = m & (g[..., :3] == s).all(-1); g[mm, :3] = r
    return g, int(m.sum())
def raise_boot(f, x0, x1, delta, row0=106):
    """lift one boot straight up by delta: boot-brown pixels in x0..x1, rows >= row0 move up; robe pixels stay in front
    (the boot's top slides under the hem), vacated pixels clear. No x change -> no slide."""
    g = f.copy(); r, gg, b = [f[..., c].astype(int) for c in range(3)]
    boot = (f[..., 3] > 0) & (r < 170) & (b < 112) & (r >= b) & ~((r > 150) & (gg > 120))
    boot[:row0] = False; boot[:, :x0] = False; boot[:, x1 + 1:] = False
    src = f.copy(); g[boot] = 0
    ys, xs = np.nonzero(boot)
    for y, x in zip(ys, xs):
        Y = y - delta
        if g[Y, x, 3] == 0: g[Y, x] = src[y, x]
    return g, int(boot.sum())
def headx(f, rows=30): t = top(f); return float(np.nonzero(f[t:t + rows, :, 3])[1].mean())
def build(d, bob=None, hip=0.70, lock=34, lockref=0, unslit_row=None, boxes=(), raises=()):
    F = [load(d, i) for i in SPEC[d]]; nat = [top(f) for f in F]
    base = min(nat)
    if bob is None:   # minimal-deformation clamp of the natural (sole-aligned) top into [base, base+2]
        bob = [min(2, t - base) for t in nat]
    fr = [A3.fit_top(f, base + b, hip) for f, b in zip(F, bob)]
    hx = [headx(f) for f in fr]; tx = float(np.mean(hx)); fr = [A3.shift_x(f, int(round(tx - h))) for f, h in zip(fr, hx)]
    info = {'video_frames_1based': SPEC[d], 'natural_top': nat, 'bob_px': bob, 'base_top': base, 'hip_frac': hip}
    if unslit_row is not None:
        res = [unslit(f, unslit_row) for f in fr]; fr = [r[0] for r in res]; info['slit_skin_recoloured_px'] = [r[1] for r in res]
    for (k, x0, x1, dl) in raises:
        fr[k], n = raise_boot(fr[k], x0, x1, dl); info.setdefault('boot_raises', []).append({'k': k, 'x': [x0, x1], 'px': dl, 'boot_px': n})
    if lock:
        ref = fr[lockref]; t0 = top(ref)
        for f in fr:
            t = top(f); f[t:t + lock] = ref[t0:t0 + lock]
        info['head_lock'] = {'ref_k': lockref, 'rows': lock}
    for (r0, r1, x0, x1, refs) in boxes:   # hair boxes: rows top+r0..top+r1, x0..x1 replaced by the ref frame's block
        refs = refs if isinstance(refs, list) else [refs] * 8
        src = [f.copy() for f in fr]
        for k, f in enumerate(fr):
            ref = src[refs[k]]; t0 = top(ref); t = top(f); f[t + r0:t + r1, x0:x1] = ref[t0 + r0:t0 + r1, x0:x1]
        info.setdefault('hair_boxes', []).append({'rows_from_top': [r0, r1], 'x': [x0, x1], 'ref_k': refs})
    filled = []
    for f in fr:   # key holes: enclosed transparent specks (<= 4 px) above row 60 -> most common opaque 8-neighbour colour
        a = f[..., 3] > 0; holes = ndimage.binary_fill_holes(a) & ~a; lab, n = ndimage.label(holes); c = 0
        for k in range(1, n + 1):
            ys, xs = np.nonzero(lab == k)
            if len(ys) > 4 or ys.max() >= 60: continue
            for y, x in zip(ys, xs):
                nb = [tuple(f[y + dy, x + dx]) for dy in (-1, 0, 1) for dx in (-1, 0, 1) if f[y + dy, x + dx, 3] > 0]
                if nb: f[y, x] = max(set(nb), key=nb.count); c += 1
        filled.append(c)
    info['holes_filled_px'] = filled
    return fr, info
if __name__ == '__main__':
    out = H / 'assembled_v1'; log = {}
    for d in SPEC:
        c = CFG.get(d, {}); fr, info = build(d, **c); log[d] = info; (out / d).mkdir(parents=True, exist_ok=True)
        for k, f in enumerate(fr): Image.fromarray(f).save(out / d / f'walk_{d}_{k:04d}.png')
    (out / 'build.json').write_text(json.dumps(log, indent=1)); print(json.dumps(log))
