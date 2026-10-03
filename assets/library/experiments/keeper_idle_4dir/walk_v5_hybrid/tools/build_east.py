#!/usr/bin/env python3
"""Walk v5 EAST from keeper_walk_casual_east.mp4 (relaxed side walk, 24-frame / 1.0 s loop, 12 unique poses held 2 frames each).
8 frames sampled every 3 video frames (unique-pose gaps alternate 2,1): f48(=f24) f28 f30 f34 | f36 f40 f42 f46 (each half is
the other step, lag 12).  The clip's own legs are used (clean, planted, low steps).  Per frame: bob re-timed to a per-step
0/1/2/1 pattern with fit_top (only rows below the hip stretch, soles stay on 123), head + mane locked to frame 0, demaroon.
WEST = exact horizontal mirror."""
import json, sys
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage
sys.path.insert(0, '/workspace/keeper_idle/walk3')
import assemble_v3 as A3
sys.path.insert(0, str(Path(__file__).parent)); sys.path.insert(0, '/workspace/keeper_idle/walk6')
from legfix import clean_boots, raise_foot, lower_foot
from lift import reduce_lift
W = Path(__file__).parent / 'work/east'
SRC = [48, 28, 30, 34, 36, 40, 42, 46]
BOB = [0, 1, 2, 1, 0, 1, 2, 1]
BASE_TOP = 5                      # natural top of the tallest (passing) frame = 124 - 119
# swing-boot raises (k: (x0, x1, px)) -> every swing/reach boot clears >= 5 px; contact heel k2 put down on 123
RAISE = {3: (36, 55, 4), 5: (66, 88, 2), 7: (38, 56, 2)}
HEEL_DOWN = {2: (74, 94, 2, 109), 6: (34, 56, 1, 110)}   # x0, x1, px, R0 (first leg row under the hem)
# re-time the planted boot in the two passing frames: the 12->8 sampling makes gaps alternate 4/2 video frames, so with
# near-even timing the stance boot would travel 7/13 px around k0/k4; shifting only the legs (rows >= LEG_ROW, under the
# hem) 2 px back evens it to 9-11 px/frame (body and coat untouched)
LEG_SHIFT = {0: -2, 4: -2}; LEG_ROW = 107
LOCK_ROWS = 34; MANE_ROWS = 57; MANE_X1 = 61   # mane lock: rows top+34..top+56, hair-coloured ref pixels in x [mane_x0, 61)
def top(f): return int(np.nonzero(f[..., 3].any(1))[0].min())
def hairmask(f):
    r, g, b = [f[..., c].astype(int) for c in range(3)]; return (g > r + 30) & (g > b + 30) & (f[..., 3] > 0)
def build():
    F = [np.array(Image.open(W / f'g_{i:03d}.png').convert('RGBA')) for i in SRC]
    nat = [top(f) for f in F]
    out = [A3.fit_top(f, BASE_TOP + b) for f, b in zip(F, BOB)]
    cleaned = []
    for k in range(8):
        out[k], n = clean_boots(out[k]); cleaned.append(n)
    legs = {}
    for k, (x0, x1, d, r0) in HEEL_DOWN.items():
        out[k], legs[f'k{k}_heel_down'] = lower_foot(out[k], x0, x1, d, r0)
    for k, r in RAISE.items():
        if r: out[k], legs[f'k{k}_raise'] = raise_foot(out[k], *r)
    for k, dx in LEG_SHIFT.items():
        out[k][LEG_ROW:] = A3.shift_x(out[k][LEG_ROW:], dx)
    legs['leg_shift_rows_ge_%d' % LEG_ROW] = LEG_SHIFT
    ref = out[0]; t0 = top(ref)
    hm = hairmask(ref); mrows = slice(t0 + LOCK_ROWS, t0 + MANE_ROWS)
    hx = np.nonzero(hm[mrows].any(0))[0]; mx0, mx1 = int(hx.min()), int(hx.max()) + 1
    mx1 = MANE_X1 or mx1
    for k, g in enumerate(out):
        t = top(g); d = t - t0
        g[t:t + LOCK_ROWS] = ref[t0:t0 + LOCK_ROWS]
        # mane: copy the ref's hair pixels (and clear this frame's hair pixels in that box that the ref doesn't have)
        box_ref = ref[t0 + LOCK_ROWS:t0 + MANE_ROWS, mx0:mx1]; box = g[t + LOCK_ROWS:t + MANE_ROWS, mx0:mx1]
        hr = hairmask(box_ref); hg = hairmask(box)
        box[hr] = box_ref[hr]
        stray = hg & ~hr
        if stray.any():   # fill frame hair the ref doesn't have with the ref pixel there (coat) if opaque, else clear
            box[stray] = box_ref[stray]
    cl = [A3.demaroon(g) for g in out]; out = [c[0] for c in cl]
    specks = []
    for g in out:   # drop specks (< 4 px components) left by the mane lock / leg edits
        lab, n = ndimage.label(g[..., 3] > 0, np.ones((3, 3))); sz = ndimage.sum(np.ones(lab.shape), lab, range(1, n + 1))
        kill = np.isin(lab, 1 + np.nonzero(sz < 4)[0]) & (lab > 0); g[kill] = 0; specks.append(int(kill.sum()))
    return out, {'source': 'keeper_walk_casual_east.mp4 (24-frame loop) f48,28,30,34,36,40,42,46 at scale 0.3439, anchor_x 59.98',
                 'natural_top': nat, 'bob_px': BOB, 'base_top': BASE_TOP,
                 'head_lock': {'ref_frame': 0, 'rows': LOCK_ROWS, 'mane_rows': [LOCK_ROWS, MANE_ROWS], 'mane_x': [mx0, mx1]},
                 'maroon_remapped_px': [c[1] for c in cl], 'boot_fringe_fixed_px': cleaned, 'specks_removed_px': specks, 'leg_edits': legs}
if __name__ == '__main__':
    fr, log = build(); d = Path(__file__).parent / 'assembled/east'; dw = Path(__file__).parent / 'assembled/west'
    d.mkdir(parents=True, exist_ok=True); dw.mkdir(parents=True, exist_ok=True)
    for k, f in enumerate(fr):
        Image.fromarray(f).save(d / f'walk_east_{k:04d}.png'); Image.fromarray(np.ascontiguousarray(f[:, ::-1])).save(dw / f'walk_west_{k:04d}.png')
    (d / 'build.json').write_text(json.dumps(log, indent=1)); print(json.dumps(log))
