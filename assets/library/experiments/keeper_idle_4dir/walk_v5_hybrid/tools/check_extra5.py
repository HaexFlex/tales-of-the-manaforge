#!/usr/bin/env python3
"""Walk v5 extra checks (on top of check_frames.py walk mode), per variant dir:
one component, height 117-119, bob <= 2, 100-130 ms / 900-1100 ms loop, loop seam within the in-cycle steps,
upper body unchanged = rows above 84 pixel-identical to the v4 frame shifted by the bob correction, head rows identical across
frames (lock kept), pinholes (enclosed transparent areas <= 4 px, rows >= 78 = the leg seam area) = 0; the upper-body comparison excludes v4's own leg (pants) pixels in rows 78-83, which are replaced by v3 legs by design, leg/upper seam: no isolated pixels (<= 2 px components
of any single colour class along rows 84-110 is not tested; visual)."""
import json, sys
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage
sys.path.insert(0, str(Path(__file__).parent)); from build_v5 import shift_v
from proto import legmask
D = Path(sys.argv[1]); m = json.loads((D / 'walk_south' / 'walk_south.json').read_text())
V4 = Path('/workspace/keeper_idle/repo/assets/library/experiments/keeper_idle_4dir/walk_v4_casual/walk_south')
F = [np.array(Image.open(D / 'walk_south' / f)).astype(int) for f in m['files']]; MS = m['durations_ms']; B = m['build']['frames']
def top(f): return int(np.nonzero(f[..., 3].any(1))[0].min())
res = {'frames': []}
for k, f in enumerate(F):
    op = f[..., 3] > 0; lab, n = ndimage.label(op, np.ones((3, 3)))
    v4r = np.array(Image.open(V4 / f'walk_south_{B[k]["v4_frame"]:04d}.png')); sh = B[k]['v4_shift_up']
    v4 = shift_v(v4r, sh).astype(int)
    hole = ndimage.binary_fill_holes(op) & ~op & (v4[..., 3] > 0); hole[:78] = False   # new holes only (v4's own arm/coat gaps excluded)
    hl, hn = ndimage.label(hole); ha = ndimage.sum(hole, hl, range(1, hn + 1)) if hn else []; lm = shift_v(np.dstack([legmask(v4r).astype(np.uint8)] * 4), sh)[..., 0] > 0
    d = (np.abs(f[:84] - v4[:84]).sum(-1) > 0); upper_diff = int((d & ~lm[:84]).sum()); pants_replaced = int((d & lm[:84]).sum())
    res['frames'].append({'k': k, 'components': int(n), 'height': 124 - top(f), 'top': top(f), 'pinholes': int(sum(1 for a in ha if a <= 4)),
                          'gaps_between_legs_px': int(sum(a for a in ha if a > 4)), 'upper_rows_0_83_diff_vs_v4': upper_diff, 'v4_pants_rows_78_83_replaced_by_v3_legs': pants_replaced})
tops = [x['top'] for x in res['frames']]
steps = [int((np.abs(F[k] - F[(k + 1) % 8]).sum(-1) > 0).sum()) for k in range(8)]
head = [int((np.abs(F[k][tops[k]:tops[k] + 34] - F[0][tops[0]:tops[0] + 34]).sum(-1) > 0).sum()) for k in range(8)]
res.update({'bob_px': [max(tops) - t for t in tops], 'bob_range': max(tops) - min(tops), 'step_changed_px': steps, 'seam_changed_px': steps[7],
            'head_rows_diff_vs_frame0': head, 'ms': MS, 'loop_ms': sum(MS)})
res['ok'] = {'one_component': all(x['components'] == 1 for x in res['frames']), 'height_117_119': all(117 <= x['height'] <= 119 for x in res['frames']),
             'bob_le_2': res['bob_range'] <= 2, 'ms_100_130': all(100 <= v <= 130 for v in MS), 'loop_900_1100': 900 <= sum(MS) <= 1100,
             'loop_seam_within_steps': steps[7] <= max(steps[:7]), 'upper_unchanged_vs_v4': all(x['upper_rows_0_83_diff_vs_v4'] == 0 for x in res['frames']),
             'head_locked': max(head) == 0, 'no_pinholes': all(x['pinholes'] == 0 for x in res['frames'])}
res['all_ok'] = all(res['ok'].values())
(D / 'extra_check.json').write_text(json.dumps(res, indent=1))
print(D.name, json.dumps(res['ok']), 'ALL', res['all_ok']); print('  ', [(x['components'], x['height'], x['upper_rows_0_83_diff_vs_v4'], x['gaps_between_legs_px']) for x in res['frames']], 'bob', res['bob_px'], 'steps', steps)
