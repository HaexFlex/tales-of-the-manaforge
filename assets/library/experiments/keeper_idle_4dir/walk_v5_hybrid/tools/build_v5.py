#!/usr/bin/env python3
"""Walk v5 hybrid (south): v4 casual upper body/arms (head + chest lock included) over v3 march legs with reduced lift.
Layers per output frame j:  L0 = v3 legs (leg-colour pixels connected to the boots, rows >= 78, x 44-83) of v3 frame PAIR[j],
with the lifted leg's travel compressed toward the ground line (factor LIFT);  L1 = v4 frame j minus its own legs, shifted
vertically so the bob follows the leg phase.  L1 is drawn over L0 (coat flaps / shirt in front of the legs)."""
import json, sys
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage
sys.path.insert(0, str(Path(__file__).parent))
from proto import load, legmask, isin, LEG, V3, V4
PAIR = [0, 1, 2, 3, 4, 5, 6, 7]                      # v5 frame j = v4 frame j (arms) + v3 frame PAIR[j] (legs); identity = arms opposite legs (see NOTES)
BOB3 = [0, 2, 1, 1, 0, 2, 1, 1]; BOB4 = [2, 1, 0, 1, 2, 1, 0, 1]
BOOT_RIGID = 12                                      # bottom rows of the lifted boot kept rigid (shape intact)

def lifted_run(m):
    low = np.array([np.nonzero(m[:, x])[0].max() if m[:, x].any() else -1 for x in range(128)])
    planted = low >= 119; lift = (low >= 95) & (low <= 117)
    # biggest contiguous run of lifted columns adjacent (within 2 px) to the planted run
    runs, x = [], 0
    while x < 128:
        if lift[x]:
            s = x
            while x < 128 and lift[x]: x += 1
            runs.append((s, x - 1))
        x += 1
    px = np.nonzero(planted)[0]
    runs = [r for r in runs if r[1] - r[0] >= 3 and len(px) and (abs(r[0] - px.max()) <= 2 or abs(r[1] - px.min()) <= 2)]
    if not runs: return None
    r = max(runs, key=lambda r: r[1] - r[0]); B = int(np.median(low[r[0]:r[1] + 1][low[r[0]:r[1] + 1] >= np.percentile(low[r[0]:r[1] + 1], 50)]))
    return r[0], r[1], int(low[r[0]:r[1] + 1].max()), low

def compress(f3, m, factor):
    """move the lifted leg's boot down so its lift above row 123 becomes factor x the original; rows between the knee row R0
    and the rigid boot block are stretched (nearest-row duplication) so nothing gaps; returns new layer + info"""
    L, m, _ = legs_layer(f3)
    lr = lifted_run(m)
    if lr is None or factor >= 1: return L, None
    x0, x1, B, low = lr; lift = 123 - B; delta = int(round(lift * (1 - factor)))
    if delta <= 0: return L, None
    xs = slice(x0, x1 + 1); col = L[:, xs].copy(); cm = m[:, xs]
    rows = np.nonzero(cm.any(1))[0]; top = int(rows.min())
    R0 = max(top, 92 - delta)                         # knee row: stretch starts here (under the coat hem area)
    Bt = B - BOOT_RIGID                               # top of the rigid boot block
    out = col.copy(); out[R0:] = 0
    for y in range(R0, 128):
        if y > B + delta: break
        if y >= Bt + delta: s = y - delta              # rigid boot block, shifted down
        else: s = R0 + int((y - R0) * (Bt - R0) / max(1, (Bt + delta - R0)))   # stretched shin
        out[y] = col[s]
    L[:, xs] = out
    return L, {'cols': [int(x0), int(x1)], 'boot_low_row_v3': int(B), 'lift_v3': int(lift), 'delta': delta, 'lift_new': int(lift - delta), 'knee_row': int(R0)}

def gold(f):
    r, g, b = [f[..., i].astype(int) for i in range(3)]; return (r > g) & (g > b) & (r >= 140) & (g >= 95) & (f[..., 3] > 0)
def blue(f):
    r, g, b = [f[..., i].astype(int) for i in range(3)]; return (b > r + 15) & (b >= g) & (f[..., 3] > 0)
def legs_layer(f3):
    """v3 legs: leg-colour pixels connected to the boots, holes/notches closed (any colour except coat blue/gold inside),
    plus the boot-edge pixels below row 108 that picked up coat blue (key spill) -> darkest brown outline."""
    m = legmask(f3); op = f3[..., 3] > 0
    fill = ndimage.binary_fill_holes(ndimage.binary_closing(m, np.ones((3, 3))) | m)
    reg = fill & op & (~gold(f3) | ndimage.binary_erosion(fill, np.ones((3, 3))))      # boot highlights (gold-ish) inside the legs stay
    reg[:78] = False; reg &= ~(blue(f3) & ~m) | (np.arange(128)[:, None] >= 109)
    ext = ndimage.binary_dilation(reg, np.ones((3, 3))) & op & ~gold(f3); ext[:109] = False
    L = np.zeros_like(f3); full = reg | ext; L[full] = f3[full]
    bl = full & blue(f3) & (np.arange(128)[:, None] >= 105); L[bl, :3] = (15, 6, 4)
    return L, full, int(bl.sum())
def leg_zone(L1):
    """rows 84-115: columns strictly between the coat's inner gold trims (left of / right of x 64) -> legs drawn over the
    coat lining there; below the hem (no trim found) the whole row."""
    z = np.zeros((128, 128), bool); gd = gold(L1)
    for y in range(84, 124):
        lx = [x for x in range(40, 64) if gd[y, x]]; rx = [x for x in range(65, 92) if gd[y, x]]
        z[y, (max(lx) + 1 if lx else 0):(min(rx) if rx else 128)] = True
    return z
def fill_holes_px(f, keep=None):
    """enclosed transparent pixels (seam/hole) -> most common colour among their opaque 8-neighbours"""
    op = f[..., 3] > 0; hole = ndimage.binary_fill_holes(op) & ~op; g = f.copy(); n = 0
    lab, k = ndimage.label(hole); area = ndimage.sum(hole, lab, range(1, k + 1))
    hole = np.isin(lab, 1 + np.nonzero(area <= 4)[0])      # only pinholes; real gaps between the legs stay open
    hole[:78] = False                                       # only in the leg/seam area: the v4 upper body stays untouched
    if keep is not None: hole &= ~keep                       # gaps that already exist in v4 (arm vs coat) stay open
    for y, x in zip(*np.nonzero(hole)):
        nb = [tuple(f[yy, xx]) for yy in range(y - 1, y + 2) for xx in range(x - 1, x + 2) if op[yy, xx]]
        if nb: g[y, x] = max(set(nb), key=nb.count); n += 1
    return g, n
def keep_main(f):
    op = f[..., 3] > 0; lab, n = ndimage.label(op, np.ones((3, 3)))
    if n <= 1: return f
    area = ndimage.sum(op, lab, range(1, n + 1)); g = f.copy(); g[lab != 1 + int(np.argmax(area))] = 0; return g
def shift_v(f, dy):            # dy > 0: up
    if dy == 0: return f.copy()
    out = np.zeros_like(f)
    if dy > 0: out[:-dy] = f[dy:]
    else: out[-dy:] = f[:dy]
    return out

def build(factor):
    frames, log = [], []
    for j in range(8):
        f4 = load(V4, j); f3 = load(V3, PAIR[j])
        L0, info = compress(f3, None, factor)
        m4 = legmask(f4); m4 = ndimage.binary_fill_holes(ndimage.binary_closing(m4, np.ones((3, 3))) | m4) & ~gold(f4) & ~(blue(f4) & ~m4)
        L1 = f4.copy(); L1[m4] = 0; L1 = keep_main(L1)
        dy = BOB3[PAIR[j]] - BOB4[j]; L1 = shift_v(L1, dy)
        z = leg_zone(L1); l0 = L0[..., 3] > 0; l1 = L1[..., 3] > 0
        r, g, b = [L1[..., i].astype(int) for i in range(3)]; shirt = (g > r) & (g > b) & l1
        top1 = l1 & ~(z & l0 & ~gold(L1) & ~shirt)          # L1 wins except over the coat lining inside the leg zone
        out = L0.copy(); out[top1] = L1[top1]; f4s = shift_v(f4, dy); out, nh = fill_holes_px(out, f4s[..., 3] == 0); out = keep_main(out)
        frames.append(out); log.append({'j': j, 'v4_frame': j, 'v3_frame': PAIR[j], 'bob': BOB3[PAIR[j]], 'v4_shift_up': dy, 'lift': info, 'holes_filled': nh})
    return frames, log

if __name__ == '__main__':
    factor = float(sys.argv[1]) if len(sys.argv) > 1 else 0.55; tag = sys.argv[2] if len(sys.argv) > 2 else 'raw'
    fr, log = build(factor); d = Path(__file__).parent / 'assembled' / tag; d.mkdir(parents=True, exist_ok=True)
    for j, f in enumerate(fr): Image.fromarray(f).save(d / f'walk_south_{j:04d}.png')
    (d / 'build.json').write_text(json.dumps({'factor': factor, 'frames': log}, indent=1))
    for l in log: print(l)
