#!/usr/bin/env python3
"""Shared lift reduction for walk v5 N/E (v3 frames, coat and legs in one image).
Lifted leg = biggest run of columns whose lowest LEG pixel (leg colours connected to the boots) is between rows 95-117, adjacent
to the planted foot (lowest row >= 119).  Below R0 (= first row under the coat in those columns) the run's pixels are rebuilt:
the boot's bottom block (up to RIGID rows, never above R0) is moved straight down by delta = round(lift*(1-factor)); the rows
between R0 and the block are stretched (nearest-row) to close the gap; if the block starts at R0 the top visible row repeats.
Coat pixels above R0 are never touched, so the coat stays in front.  Purely vertical -> no arc."""
import sys
import numpy as np
from scipy import ndimage
sys.path.insert(0, '/workspace/keeper_idle/walk5')
from proto import legmask
RIGID = 10
def coatmask(f):
    r, g, b = [f[..., i].astype(int) for i in range(3)]; op = f[..., 3] > 0
    blue = (b > r + 15) & (b >= g); gold = (r > g) & (g > b) & (r >= 140) & (g >= 95)
    return (blue | gold) & op
def visible_legs(f, r0=90):
    """leg pixels below the coat: per column, opaque non-coat pixels under that column's lowest coat pixel (rows >= r0),
    limited to the coat hem's x-span (hanging gloves beside the coat are excluded); keep components that are >= 6 px."""
    op = f[..., 3] > 0; cm = coatmask(f); m = np.zeros(op.shape, bool)
    span = np.nonzero(cm[95:112].any(0))[0]
    if not len(span): return m
    for x in range(span.min(), span.max() + 1):
        c = np.nonzero(cm[r0:, x])[0]; start = (c.max() + r0 + 1) if len(c) else r0
        m[start:, x] = op[start:, x] & ~cm[start:, x]
    lab, n = ndimage.label(m, np.ones((3, 3)))
    if n:
        area = ndimage.sum(m, lab, range(1, n + 1)); m &= np.isin(lab, 1 + np.nonzero(area >= 6)[0])
    return m
def lifted_run(m, lo=95, hi=117, min_w=4):
    low = np.array([np.nonzero(m[:, x])[0].max() if m[:, x].any() else -1 for x in range(128)])
    planted = np.nonzero(low >= 119)[0]; lift = (low >= lo) & (low <= hi)
    runs, x = [], 0
    while x < 128:
        if lift[x]:
            s = x
            while x < 128 and lift[x]: x += 1
            runs.append((s, x - 1))
        x += 1
    runs = [r for r in runs if r[1] - r[0] + 1 >= min_w and len(planted) and (abs(r[0] - planted.max()) <= 3 or abs(r[1] - planted.min()) <= 3)]
    if not runs: return None
    r = max(runs, key=lambda r: r[1] - r[0]); return r[0], r[1], int(low[r[0]:r[1] + 1].max()), low
def reduce_lift(f, factor, r0=90, run=None):
    m = visible_legs(f, r0); lr = lifted_run(m) if run is None else run
    if lr is None: return f.copy(), None
    x0, x1, B = lr[0], lr[1], lr[2]; lift = 123 - B; delta = int(round(lift * (1 - factor)))
    if delta <= 0: return f.copy(), None
    xs = slice(x0, x1 + 1); col = f[:, xs].copy(); cm = coatmask(f)[:, xs]
    coat_rows = [np.nonzero(cm[r0:B + 1, i])[0].max() + r0 for i in range(cm.shape[1]) if cm[r0:B + 1, i].any()]
    R0 = (max(coat_rows) + 1) if coat_rows else int(np.nonzero(m[:, xs].any(1))[0].min())
    R0 = min(R0, B)
    Bt = max(R0, B - RIGID + 1)
    out = col.copy(); out[R0:] = 0
    for y in range(R0, min(128, B + delta + 1)):
        if y >= Bt + delta: s = y - delta
        elif Bt > R0: s = R0 + int((y - R0) * (Bt - R0) / (Bt + delta - R0))
        else: s = R0
        out[y] = col[s]
    g = f.copy(); g[:, xs] = out
    # pixels of the run columns that belonged to the planted foot (if any) are restored on top
    keep = (f[..., 3] > 0) & False
    return g, {'cols': [int(x0), int(x1)], 'boot_low_row': int(B), 'lift': int(lift), 'delta': delta, 'lift_new': int(lift - delta), 'R0': int(R0), 'rigid_top': int(Bt)}
