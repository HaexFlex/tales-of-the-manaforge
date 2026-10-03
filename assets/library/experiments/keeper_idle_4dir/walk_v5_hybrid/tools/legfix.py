#!/usr/bin/env python3
"""East leg fixes: (1) key-spill fringe on boots (blue / green pixels under the coat hem) -> median of the boot neighbours,
re-snapped to the Option A palette; (2) raise_foot: lift a swinging boot straight up by delta (bottom RIGID rows rigid,
shin between hem and boot compressed, coat pixels always stay in front)."""
import json, sys
import numpy as np
sys.path.insert(0, '/workspace/keeper_idle/tools'); sys.path.insert(0, '/workspace/keeper_idle/walk6')
from build_idles import apply_palette
from lift import coatmask
PAL = np.array(json.load(open('/workspace/keeper_idle/repo/assets/library/experiments/keeper_idle_4dir/v3_stills_8dir/option_a/palette.json'))['colors'], dtype=np.uint8)
RIGID = 10
def _gold(f):
    r, g, b = [f[..., c].astype(int) for c in range(3)]; return (r > g) & (g > b) & (r >= 140) & (g >= 95) & (f[..., 3] > 0)
def _blue(f):
    r, g, b = [f[..., c].astype(int) for c in range(3)]; return (b > r + 15) & (b >= g) & (f[..., 3] > 0)
def _green(f):
    r, g, b = [f[..., c].astype(int) for c in range(3)]; return (g > r + 10) & (g > b + 10) & (f[..., 3] > 0)
def hem_rows(f, lo=88, hi=118):
    """per column: lowest gold-trim row in rows lo..hi (the coat hem), or -1"""
    gm = _gold(f); h = np.full(128, -1)
    for x in range(128):
        ys = np.nonzero(gm[lo:hi, x])[0]
        if len(ys): h[x] = ys.max() + lo
    return h
def clean_boots(f, row_min=96):
    """key-spill on the boots: sparse blue pixels (< 6 blue in their 5x5) and any green below row_min -> median of the
    non-fringe neighbours, snapped to the palette"""
    a = f.copy(); op = a[..., 3] > 0; bl = _blue(a); gr = _green(a)
    from scipy.ndimage import uniform_filter
    dens = uniform_filter(bl.astype(float), 5, mode='constant') * 25
    r_, g_, b_ = [a[..., c].astype(int) for c in range(3)]
    olive = op & (g_ >= r_ - 10) & (g_ > b_ + 12) & (r_ < 120)
    bad = np.zeros(op.shape, bool); bad[row_min:] = (bl & (dens < 6.5))[row_min:] | gr[row_min:] | olive[row_min:]
    good = op & ~bad & ~bl & ~gr & ~olive; n = int(bad.sum())
    for y, x in zip(*np.nonzero(bad)):
        sl = (slice(max(0, y - 2), y + 3), slice(max(0, x - 2), x + 3)); nb = a[sl][good[sl]][:, :3].astype(float)
        a[y, x, :3] = np.median(nb, 0).astype(np.uint8) if len(nb) else (54, 26, 12)
    if n:
        q = apply_palette(a, PAL); a[bad] = q[bad]
    return a, n
def raise_foot(f, x0, x1, delta, r0=96, R0=None):
    """move the boot in columns x0..x1 up by delta px. Only that leg's pixels (non-coat, rows >= hem) are touched."""
    g = f.copy(); xs = slice(x0, x1 + 1); col = f[:, xs].copy(); cm = coatmask(f)[:, xs]; op = col[..., 3] > 0
    B = int(max(np.nonzero(op[:, i])[0].max() for i in range(col.shape[1]) if op[:, i].any()))
    hem = [np.nonzero(cm[r0:B + 1, i])[0].max() + r0 + 1 if cm[r0:B + 1, i].any() else r0 for i in range(col.shape[1])]
    R0 = int(min(max(hem), B)) if R0 is None else R0; Bt = max(R0, B - RIGID + 1)
    out = col.copy()
    leg = op & ~cm; leg[:R0] = False
    out[leg] = 0
    ys = range(max(r0, R0 - delta), B - delta + 1)
    for y in ys:
        if y >= Bt - delta: s = y + delta
        elif Bt - delta > R0: s = R0 + int((y - R0) * (Bt - R0) / (Bt - delta - R0)) if y >= R0 else None
        else: s = None
        if s is None: continue
        src = col[s]; ok = (src[:, 3] > 0) & ~cm[s] & ~cm[y]
        out[y][ok] = src[ok]
    g[:, xs] = out
    return g, {'cols': [x0, x1], 'boot_low_row': B, 'lift': 123 - B, 'raise': delta, 'lift_new': 123 - B + delta, 'R0': R0, 'rigid_top': Bt}

def lower_foot(f, x0, x1, delta, R0):
    """put a hovering boot down by delta px: bottom RIGID rows move down, rows R0..rigid top stretch (coat stays in front)"""
    g = f.copy(); xs = slice(x0, x1 + 1); col = f[:, xs].copy(); cm = coatmask(f)[:, xs]; op = col[..., 3] > 0
    B = int(max(np.nonzero(op[:, i])[0].max() for i in range(col.shape[1]) if op[:, i].any())); Bt = max(R0, B - RIGID + 1)
    out = col.copy(); leg = op & ~cm; leg[:R0] = False; out[leg] = 0
    for y in range(R0, min(128, B + delta + 1)):
        s = y - delta if y >= Bt + delta else R0 + int((y - R0) * (Bt - R0) / (Bt + delta - R0))
        src = col[s]; ok = (src[:, 3] > 0) & ~cm[s] & ~cm[y]; out[y][ok] = src[ok]
    g[:, xs] = out
    return g, {'cols': [x0, x1], 'boot_low_row': B, 'lift': 123 - B, 'lower': delta, 'lift_new': 123 - B - delta, 'R0': R0, 'rigid_top': Bt}
