#!/usr/bin/env python3
"""Walk v4 casual (south): assemble the 8-frame loop from video-derived native frames (walk4/work/front/g_###.png).
Reuses walk_v3's assembly helpers (fit_top bob shaping, shift_x head-x lock, demaroon) unchanged."""
import json, sys
from pathlib import Path
import numpy as np
from PIL import Image
sys.path.insert(0, '/workspace/keeper_idle/walk3')
import assemble_v3 as A3
R = Path('/workspace/keeper_idle'); W = R / 'walk4/work'
def load(i): return np.array(Image.open(W / 'front' / f'g_{i:03d}.png'))
top = A3.top
SEQ = [36, 40, 44, 48, 52, 56, 60, 64]          # one full cycle (32 video frames = 16 unique poses), every 2nd unique pose
PHASE = ['his L foot (screen right) lifted, peak', 'L foot setting down', 'double support', 'weight shift, R heel starting', 'his R foot (screen left) lifted, peak', 'R foot setting down', 'double support', 'weight shift, L heel starting']
BOB = [2, 1, 0, 1, 2, 1, 0, 1]                   # single support (foot lifted) high, double support low
MS = [130, 120, 120, 130, 130, 120, 120, 130]    # 1000 ms: linger slightly on the lift peaks / heel rise
LOCK = (36, 34)                                  # head lock: top 34 rows (hair + face) from f36
CHEST = (34, 64, 53, 73)                         # chest lock (same ref frame): rows top+34..top+63, x 53..72 = shirt, medallion, lapel trims (video redraw shimmer)

def build():
    F = [load(i) for i in SEQ]; H = [124 - top(f) for f in F]
    sh = A3.still_h('s'); base_top = 124 - (sh - 2)
    fr = [A3.fit_top(f, base_top - b) for f, b in zip(F, BOB)]
    hx = [np.nonzero(f[top(f):top(f) + 30, :, 3])[1].mean() for f in fr]; tx = float(np.mean(hx))
    fr = [A3.shift_x(f, int(round(tx - h))) for f, h in zip(fr, hx)]
    ref = fr[SEQ.index(LOCK[0])].copy(); r0 = top(ref); seg = ref[r0:r0 + LOCK[1]]
    for f in fr:
        t = top(f); f[t:t + LOCK[1]] = seg
        if CHEST: f[t + CHEST[0]:t + CHEST[1], CHEST[2]:CHEST[3]] = ref[r0 + CHEST[0]:r0 + CHEST[1], CHEST[2]:CHEST[3]]
    cl = [A3.demaroon(f) for f in fr]; fr = [c[0] for c in cl]
    log = {'video': 'keeper_walk_casual_front.mp4', 'video_frames_1based': SEQ, 'time_s': [round((i - 1) / 24, 3) for i in SEQ],
           'phase': PHASE, 'natural_height_px': H, 'bob_px': BOB, 'ms': MS, 'loop_ms': sum(MS), 'still_height': sh,
           'lock': list(LOCK), 'chest_lock_rows_x': list(CHEST) if CHEST else None, 'maroon_remapped_px': [c[1] for c in cl], 'head_x_shift': [int(round(tx - h)) for h in hx]}
    return fr, log

if __name__ == '__main__':
    fr, log = build(); dst = R / 'walk4/assembled'; dst.mkdir(exist_ok=True)
    for k, f in enumerate(fr): Image.fromarray(f).save(dst / f'walk_south_{k:04d}.png')
    (dst / 'assembly.json').write_text(json.dumps(log, indent=1)); print(log)
