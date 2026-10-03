#!/usr/bin/env python3
"""Foot lift per frame for v3 / v4 / v5 variants: lifted boot = the run of leg columns (leg-colour pixels connected to the boots)
whose lowest row is 95-117, next to the planted foot (lowest row >= 119); lift = 123 - lowest row of that boot (px above the
ground line).  Also the boot TOP row of the lifted leg is not used (hidden under the coat)."""
import json, sys
from pathlib import Path
import numpy as np
from PIL import Image
sys.path.insert(0, str(Path(__file__).parent))
from proto import legmask
from build_v5 import lifted_run
from sheet import path
res = {}
for tag in sys.argv[1:]:
    per = []
    for k in range(8):
        f = np.array(Image.open(path(tag, k))); lr = lifted_run(legmask(f))
        per.append(None if lr is None else {'cols': [int(lr[0]), int(lr[1])], 'lift': int(123 - lr[2])})
    lifts = [p['lift'] if p else 0 for p in per]
    res[tag] = {'per_frame': per, 'lifts': lifts, 'max': max(lifts), 'mean_lifted': round(float(np.mean([l for l in lifts if l > 0])), 1)}
    print(tag, lifts, 'max', max(lifts), 'mean(lifted)', res[tag]['mean_lifted'])
for tag in res:
    if tag != 'v3': res[tag]['pct_of_v3_per_frame'] = [round(100 * a / b) if b else None for a, b in zip(res[tag]['lifts'], res['v3']['lifts'])] if 'v3' in res else None
Path('measure5.json').write_text(json.dumps(res, indent=1))
