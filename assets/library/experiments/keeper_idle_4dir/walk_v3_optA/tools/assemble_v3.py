#!/usr/bin/env python3
"""Walk v3: assemble 8-frame loops from video-derived native frames (walk3/work/<dir>/g_###.png).
Frames are sampled by phase from ONE clean cycle. Natural bob from the video (up to 5-9 px) is damped to 0..2 px:
each frame's head-top is set to base - b (b = 0 contact .. 2 passing, linear in the frame's natural height), by shifting the
rows above the hip and resampling (nearest) the hip..sole band, so the soles stay on row 123 and no single row kinks.
Optional head lock (LOCK): rows above the shoulder line from one reference frame (pasted at each frame's bobbed position)."""
import json, sys
from pathlib import Path
import numpy as np
from PIL import Image
R = Path('/workspace/keeper_idle'); W = R / 'walk3/work'
A = R / 'repo/assets/library/experiments/keeper_idle_4dir/v3_stills_8dir/option_a'
def load(d, i): return np.array(Image.open(W / d / f'g_{i:03d}.png'))
def top(f): return int(np.nonzero(f[..., 3].any(1))[0].min())
def still_h(s): r = np.nonzero(np.array(Image.open(A / f'keeper_still_{s}.png'))[..., 3].any(1))[0]; return int(r.max() - r.min() + 1)

def fit_top(f, target, hip_frac=0.70):
    t = top(f); dy = t - target                        # >0: move up (stretch legs), <0: move down (squash legs)
    if dy == 0: return f.copy()
    hip = int(t + hip_frac * (123 - t))
    out = np.zeros_like(f)
    # rows above hip: shift
    for y in range(0, hip):
        Y = y - dy
        if 0 <= Y < 128: out[Y] = f[y]
    # hip..123 band -> (hip-dy)..123
    n_src = 124 - hip; y0 = hip - dy; n_dst = 124 - y0
    for k in range(n_dst):
        out[y0 + k] = f[hip + min(n_src - 1, int(k * n_src / n_dst))]
    return out

def shift_x(f, dx):
    if dx == 0: return f
    out = np.zeros_like(f)
    if dx > 0: out[:, dx:] = f[:, :-dx]
    else: out[:, :dx] = f[:, -dx:]
    return out

MAROON, DARK_BROWN = (80, 21, 33), (54, 26, 12)
def demaroon(f, below=40):
    """video key spill makes moving boots/gloves pick the palette's maroon outline colour (Option A uses it ~45 px, mostly in
    the hair); below the head it reads as purple fringe -> remap to the palette's dark brown (both are palette colours)."""
    g = f.copy(); t = top(g); m = (g[..., :3] == MAROON).all(-1) & (g[..., 3] > 0); m[:t + below] = False
    g[m, :3] = DARK_BROWN; return g, int(m.sum())

SPEC = {   # dir: (video, still, frames sampled by phase from one cycle)
 'east':  ('side',  'e', [97, 100, 102, 106, 108, 112, 114, 118]),
 'south': ('front', 's', [110, 112, 116, 118, 122, 124, 128, 130]),
 'north': ('back',  'n', [16, 18, 20, 24, 26, 30, 32, 36]),
}
BOB = {'east': [2, 1, 0, 1, 2, 1, 0, 1],    # 97/108 passing (legs together) high, 102/114 contact low
       'south': [0, 2, 1, 1, 0, 2, 1, 1],   # 110/122 both feet down low, 112/124 knee-up high
       'north': [0, 1, 2, 1, 0, 1, 2, 1]}   # 16/26 contact low, 20/32 foot-lift peak high
LOCK = {'south': (124, 34), 'east': (97, 42)}   # (reference video frame, rows from the head top)

def build():
    out, log = {}, {}
    for d, (vid, st, seq) in SPEC.items():
        F = [load(vid, i) for i in seq]; H = [124 - top(f) for f in F]; lo, hi = min(H), max(H)
        b = BOB[d]   # designed from the natural heights (halves averaged so both steps bob alike)
        sh = still_h(st); base_top = 124 - (sh - 2)
        fr = [fit_top(f, base_top - bb) for f, bb in zip(F, b)]
        # horizontal: lock the HEAD (top 30 rows) centroid -> no sideways head jitter (arm swing no longer moves the anchor)
        hx = [np.nonzero(f[top(f):top(f) + 30, :, 3])[1].mean() for f in fr]; tx = float(np.mean(hx))
        fr = [shift_x(f, int(round(tx - h))) for f, h in zip(fr, hx)]
        if d in LOCK:   # head lock: rows top..top+rows-1 (hair + face, above the collar) from ONE reference frame
            ref_i, rows = LOCK[d]; ref = fr[seq.index(ref_i)].copy(); r0 = top(ref); seg = ref[r0:r0 + rows]
            for f in fr:
                t = top(f); f[t:t + rows] = seg
        cl = [demaroon(f) for f in fr]; fr = [c[0] for c in cl]
        out[d] = fr
        log[d] = {'maroon_remapped_px': [c[1] for c in cl], 'video': f'keeper_walkvid_{vid}.mp4', 'video_frames_1based': seq, 'time_s': [round((i - 1) / 24, 3) for i in seq],
                  'natural_height_px': H, 'bob_px': b, 'still_height': sh, 'lock': LOCK.get(d)}
    out['west'] = [f[:, ::-1].copy() for f in out['east']]; log['west'] = {'frames': 'east mirrored (x -> 127 - x)'}
    return out, log

if __name__ == '__main__':
    out, log = build(); dst = R / 'walk3/assembled'; dst.mkdir(exist_ok=True)
    for d, fr in out.items():
        for k, f in enumerate(fr): Image.fromarray(f).save(dst / f'walk_{d}_{k:04d}.png')
    (dst / 'assembly.json').write_text(json.dumps(log, indent=1))
    for d, v in log.items(): print(d, v)
