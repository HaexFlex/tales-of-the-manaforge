#!/usr/bin/env python3
"""Generic walk v5 extra checks for one clip dir (walk_<dir>/walk_<dir>.json): 1 component, height within still-3..still,
bob <= 2, 100-130 ms & 900-1100 ms loop, loop seam within in-cycle steps, head rows (top 34) identical across frames,
no specks (components < 4 px) - implied by 1 component."""
import json, sys
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage
D = Path(sys.argv[1]); clip = D.name; m = json.loads((D / f'{clip}.json').read_text()); still_h = int(sys.argv[2])
F = [np.array(Image.open(D / f)).astype(int) for f in m['files']]; MS = m['durations_ms']
def top(f): return int(np.nonzero(f[..., 3].any(1))[0].min())
fr = []
for k, f in enumerate(F):
    lab, n = ndimage.label(f[..., 3] > 0, np.ones((3, 3))); fr.append({'k': k, 'components': int(n), 'height': 124 - top(f), 'top': top(f)})
tops = [x['top'] for x in fr]; steps = [int((np.abs(F[k] - F[(k + 1) % 8]).sum(-1) > 0).sum()) for k in range(8)]
head = [int((np.abs(F[k][tops[k]:tops[k] + 34] - F[0][tops[0]:tops[0] + 34]).sum(-1) > 0).sum()) for k in range(8)]
res = {'frames': fr, 'bob_px': [max(tops) - t for t in tops], 'step_changed_px': steps, 'head_rows_diff_vs_frame0': head, 'ms': MS, 'loop_ms': sum(MS)}
res['ok'] = {'one_component': all(x['components'] == 1 for x in fr), f'height_{still_h - 3}_{still_h}': all(still_h - 3 <= x['height'] <= still_h for x in fr),
             'bob_le_2': max(tops) - min(tops) <= 2, 'ms_100_130': all(100 <= v <= 130 for v in MS), 'loop_900_1100': 900 <= sum(MS) <= 1100,
             'loop_seam_within_steps': steps[7] <= max(steps[:7]), 'head_locked': max(head) == 0}
res['all_ok'] = all(res['ok'].values()); (D / 'extra_check.json').write_text(json.dumps(res, indent=1))
print(clip, json.dumps(res['ok']), 'ALL', res['all_ok'], [(x['components'], x['height']) for x in fr], 'bob', res['bob_px'], 'steps', steps)
