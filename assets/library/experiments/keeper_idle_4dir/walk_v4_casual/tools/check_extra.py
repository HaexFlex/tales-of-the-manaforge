#!/usr/bin/env python3
"""Walk v4 extra checks (on top of check_frames.py walk mode): one connected component per frame (no specks/objects),
height 117-119 (S still 119, bob 0-2), head-top bob range <= 2, timing 100-130 ms/frame and 900-1100 ms loop,
loop seam (frame 7 -> 0 change vs the in-cycle steps), head flicker (changed px in the locked head rows, aligned per frame)."""
import json, sys
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage
D = Path(sys.argv[1]); m = json.loads((D / 'walk_south' / 'walk_south.json').read_text())
F = [np.array(Image.open(D / 'walk_south' / f)).astype(int) for f in m['files']]; MS = m['durations_ms']
def top(f): return int(np.nonzero(f[..., 3].any(1))[0].min())
res = {'frames': []}
for k, f in enumerate(F):
    op = f[..., 3] > 0; lab, n = ndimage.label(op, np.ones((3, 3))); h = 124 - top(f)
    res['frames'].append({'k': k, 'components': int(n), 'height': h, 'top': top(f)})
tops = [x['top'] for x in res['frames']]
steps = [int((np.abs(F[k] - F[(k + 1) % 8]).sum(-1) > 0).sum()) for k in range(8)]
L = m['assembly']['lock'][1]
head = [int((np.abs(F[k][tops[k]:tops[k] + L] - F[(k + 1) % 8][tops[(k + 1) % 8]:tops[(k + 1) % 8] + L]).sum(-1) > 0).sum()) for k in range(8)]
res.update({'bob_range': max(tops) - min(tops), 'step_changed_px': steps, 'seam_changed_px': steps[7], 'head_rows_changed_px_aligned': head,
            'ms': MS, 'loop_ms': sum(MS)})
res['ok'] = {'one_component': all(x['components'] == 1 for x in res['frames']), 'height_117_119': all(117 <= x['height'] <= 119 for x in res['frames']),
             'bob_le_2': res['bob_range'] <= 2, 'ms_100_130': all(100 <= v <= 130 for v in MS), 'loop_900_1100': 900 <= sum(MS) <= 1100,
             'seam_within_steps': steps[7] <= max(steps[:7]), 'head_locked': max(head) == 0}
res['all_ok'] = all(res['ok'].values())
(D / 'extra_check.json').write_text(json.dumps(res, indent=1)); print(json.dumps({k: v for k, v in res.items() if k != 'frames'})); print([(x['components'], x['height']) for x in res['frames']])
