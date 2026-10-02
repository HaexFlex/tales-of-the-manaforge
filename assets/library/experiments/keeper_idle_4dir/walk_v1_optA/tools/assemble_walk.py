#!/usr/bin/env python3
"""Walk v1 (Option A): assemble loops from walk/work/<sheet>/g_##.png (frames_walk.py output).
FRONT/BACK sheets only ever lift ONE foot (screen-left), so the other step is made by mirroring the legs below the coat hem
(x -> 2*feet_cx - x) of the lift frames; the upper body is never mirrored (hair stays consistent).
Vertical: soles stay on row 123; the body (rows above a cut in the boot shafts) is set to a fixed head-top per frame
(base = still height, passing frames +1 px), stretching/squashing one row at the cut, so the source's random 1-2 px height
noise becomes a deliberate bob. SIDE: all 8 source frames are the same mid-stride pose (no passing/contact alternation);
ordered for minimum frame-to-frame change and flagged. W = mirrored E."""
import json, itertools, sys
from pathlib import Path
import numpy as np
from PIL import Image
R = Path('/workspace/keeper_idle'); W = R / 'walk/work'
def load(s, i): return np.array(Image.open(W / s / f'g_{i:02d}.png'))
def top(f): return int(np.nonzero(f[..., 3].any(1))[0].min())
def set_top(f, target, cut):
    dy = top(f) - target
    if dy == 0: return f.copy()
    up, lo = f[:cut], f[cut:]
    if dy > 0: up = np.concatenate([up[dy:], np.repeat(up[-1:], dy, 0)])
    else: up = np.concatenate([np.zeros((-dy,) + up.shape[1:], up.dtype), up[:cut + dy]])
    return np.concatenate([up, lo])
def feet_cx(f):
    op = f[..., 3] > 0; xs = np.nonzero(op[114:124].any(0))[0]; return (xs.min() + xs.max()) / 2
def mirror_legs(f, y0):
    g = f.copy(); c2 = int(round(2 * feet_cx(f))); band = f[y0:].copy(); out = np.zeros_like(band)
    xs = np.arange(128); src = c2 - xs; ok = (src >= 0) & (src < 128)
    out[:, xs[ok]] = band[:, src[ok]]; g[y0:] = out; return g

def legdiff(a, b):
    a = a[92:124].astype(int); b = b[92:124].astype(int); oa = a[..., 3] > 0; ob = b[..., 3] > 0
    return int((oa != ob).sum() + (np.abs(a[..., :3] - b[..., :3]).sum(-1)[oa & ob] > 60).sum())

# per direction: (sheet, sequence of (src frame, mirrored legs?, bob px), leg-mirror row, body cut row, base top)
SPEC = {
 'south': ('front', [(4, 0, 0), (2, 0, 0), (5, 0, 1), (7, 0, 0), (6, 0, 0), (2, 1, 0), (5, 1, 1), (7, 1, 0)], 105, 110, 5),
 'north': ('back',  [(4, 0, 0), (1, 0, 0), (0, 0, 1), (1, 0, 0), (7, 0, 0), (1, 1, 0), (0, 1, 1), (1, 1, 0)], 97, 102, 4),
}
# Upper-body lock: every Imagine frame is a fresh redraw, so hair/coat/face pixels "boil" (~800-1300 px change per frame in
# rows 0-85). With LOCK the rows above the leg-mirror row come from ONE reference frame (the source walk barely swings the arms
# in front/back), only the legs below the hem animate, plus the deliberate bob.
LOCK = {'south': 4, 'north': 4}
def build(lock=True):
    out = {}; log = {}
    for d, (sheet, seq, ym, cut, base) in SPEC.items():
        fr = []; ref = load(sheet, LOCK[d])
        for (i, m, bob) in seq:
            f = load(sheet, i)
            if lock: f = f.copy(); f[:ym] = ref[:ym]
            f = set_top(f, base - bob, cut)
            if m: f = mirror_legs(f, ym)
            fr.append(f)
        out[d] = fr
        log[d] = {'sheet': sheet, 'frames': [f"{i:02d}{' legs-mirrored' if m else ''}{' +1px bob' if b else ''}" for i, m, b in seq],
                  'leg_mirror_from_row': ym, 'body_cut_row': cut, 'base_top_row': base,
                  'upper_body_locked_to': f'{LOCK[d]:02d} (rows 0..{ym - 1})' if lock else None}
    # side: best cyclic order of the 8 near-identical frames (min total leg change)
    F = [load('right', i) for i in range(8)]
    D = [[legdiff(F[i], F[j]) for j in range(8)] for i in range(8)]
    best = min(((0,) + p for p in itertools.permutations(range(1, 8))), key=lambda o: sum(D[o[k]][o[(k + 1) % 8]] for k in range(8)))
    base = int(np.median([top(f) for f in F]))
    out['east'] = [set_top(F[i], base, 112) for i in best]
    out['west'] = [f[:, ::-1].copy() for f in out['east']]
    log['east'] = {'sheet': 'right', 'frames': [f'{i:02d}' for i in best], 'base_top_row': base, 'body_cut_row': 112,
                   'note': 'all 8 source frames are the same mid-stride pose: no contact/passing alternation -> slides; regenerate'}
    log['west'] = {'frames': 'east mirrored (x -> 127 - x)'}
    return out, log

if __name__ == '__main__':
    lock = '--raw' not in sys.argv
    out, log = build(lock)
    dst = R / ('walk/assembled' if lock else 'walk/assembled_raw'); dst.mkdir(exist_ok=True)
    for d, fr in out.items():
        for k, f in enumerate(fr): Image.fromarray(f).save(dst / f'walk_{d}_{k:04d}.png')
    (dst / 'assembly.json').write_text(json.dumps(log, indent=1)); print(json.dumps(log, indent=1))
