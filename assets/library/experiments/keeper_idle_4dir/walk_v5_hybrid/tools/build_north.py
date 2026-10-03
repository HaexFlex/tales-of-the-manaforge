#!/usr/bin/env python3
"""Walk v5 NORTH: walk_v3 north (video-derived back cycle, arms already opposite the legs) -> lift 55%, head (hair) lock,
v5 timing, bob 0-2 by leg phase."""
import json, sys
from pathlib import Path
import numpy as np
from PIL import Image
sys.path.insert(0, str(Path(__file__).parent)); sys.path.insert(0, '/workspace/keeper_idle/walk3')
from lift import reduce_lift
import assemble_v3 as A3
B = Path('/workspace/keeper_idle/repo/assets/library/experiments/keeper_idle_4dir/walk_v3_optA/walk_north')
FACTOR = 0.55
# lifted boot columns per v3 north frame (read off the zoomed frames; screen-right = his right from behind)
RUNS = {1: (66, 81), 2: (70, 86), 3: (64, 79), 5: (43, 58), 6: (41, 56), 7: (46, 60)}
LOCK_REF = 0; LOCK_ROWS = 34; HAIR_ROWS = 48
def top(f): return int(np.nonzero(f[..., 3].any(1))[0].min())
def build(factor=FACTOR):
    F = [np.array(Image.open(B / f'walk_north_{k:04d}.png')) for k in range(8)]; info = []
    out = []
    for k, f in enumerate(F):
        if k in RUNS:
            x0, x1 = RUNS[k]; op = f[..., 3] > 0; B_ = int(max(np.nonzero(op[:, x])[0].max() for x in range(x0, x1 + 1)))
            g, i = reduce_lift(f, factor, run=(x0, x1, B_, None))
        else: g, i = f.copy(), None
        out.append(g); info.append(i)
    # head lock: rows top..top+33 full width from the reference; rows top+34..top+47 inside the hair's x-span (hair over the collar)
    ref = out[LOCK_REF]; t0 = top(ref)
    r, gg, b = [ref[..., c].astype(int) for c in range(3)]; hair = (gg > r + 30) & (gg > b + 30) & (ref[..., 3] > 0)
    hx = np.nonzero(hair[t0 + LOCK_ROWS:t0 + HAIR_ROWS].any(0))[0]; hx0, hx1 = int(hx.min()), int(hx.max()) + 1
    for g in out:
        t = top(g); g[t:t + LOCK_ROWS] = ref[t0:t0 + LOCK_ROWS]
        g[t + LOCK_ROWS:t + HAIR_ROWS, hx0:hx1] = ref[t0 + LOCK_ROWS:t0 + HAIR_ROWS, hx0:hx1]
    cl = [A3.demaroon(g) for g in out]; out = [c[0] for c in cl]
    return out, {'source': 'walk_v3_optA/walk_north (keeper_walkvid_back.mp4 f16,18,20,24,26,30,32,36)', 'factor': factor, 'lift': info,
                 'bob_px_from_v3': [0, 1, 2, 1, 0, 1, 2, 1], 'head_lock': {'ref_frame': LOCK_REF, 'rows': LOCK_ROWS, 'hair_rows': HAIR_ROWS, 'hair_x': [hx0, hx1]},
                 'maroon_remapped_px': [c[1] for c in cl]}
if __name__ == '__main__':
    fr, log = build(float(sys.argv[1]) if len(sys.argv) > 1 else FACTOR); d = Path(__file__).parent / 'assembled/north'; d.mkdir(parents=True, exist_ok=True)
    for k, f in enumerate(fr): Image.fromarray(f).save(d / f'walk_north_{k:04d}.png')
    (d / 'build.json').write_text(json.dumps(log, indent=1)); [print(i) for i in log['lift']]; print(log['head_lock'], log['maroon_remapped_px'])
