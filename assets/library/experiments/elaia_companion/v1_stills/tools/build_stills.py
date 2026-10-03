#!/usr/bin/env python3
"""Elaia v1 stills from turnaround sheet 1: S, N from the sheet; W = left profile L1; E = horizontal mirror of W.
One shared ~40-colour Elaia palette (k-means in Lab over S+N+W, median colours), hard alpha, despeck; refs x5 on magenta."""
import json, sys
from pathlib import Path
import numpy as np
from PIL import Image
sys.path.insert(0, str(Path(__file__).parent)); sys.path.insert(0, '/workspace/keeper_idle/tools')
from ingest_elaia import palette, despeck, tint
from build_idles import apply_palette
from make_sprite import ref_x5
SHEET, PROFILE = 'sheet1', 'L1'
W = Path('work') / SHEET; O = Path('stills'); O.mkdir(exist_ok=True)
raw = {d: np.array(Image.open(W / f'raw_{s}.png')) for d, s in (('s', 'S'), ('n', 'N'), ('w', PROFILE))}
pal = palette(list(raw.values()))
out, log = {}, {}
for d, k in raw.items():
    q = apply_palette(k, pal.astype(np.int32)).astype(np.uint8); q, sp = despeck(q); out[d] = q; log[d] = {'specks_removed': sp}
out['e'] = np.ascontiguousarray(out['w'][:, ::-1])
for d in 'snew':
    Image.fromarray(out[d]).save(O / f'elaia_still_{d}.png')
    a = out[d][..., 3]; ys, xs = np.nonzero(a); sole = ys.max(); band = np.nonzero((a[sole - 9:sole + 1] > 0).any(0))[0]
    log.setdefault(d, {}).update({'top': int(ys.min()), 'sole_row': int(sole), 'height': int(sole - ys.min() + 1), 'feet_cx': (band.min() + band.max() + 1) / 2,
        'x': [int(xs.min()), int(xs.max())], 'colours': int(len(np.unique(out[d][a > 0][:, :3], axis=0))),
        'semi_alpha_px': int(((a > 0) & (a < 255)).sum()), 'tint_px': int(((a > 0) & tint(out[d][..., :3])).sum())})
for d in 'sne': ref_x5(out[d], f'attach/ref_{d}_x5_magenta.png')
pj = {'colors': pal.tolist(), 'n': int(len(pal)), 'source': f'k-means (Lab) over elaia_turnaround_1 S+N+{PROFILE} at 116 px'}
(O / 'palette.json').write_text(json.dumps(pj, indent=1))
sw = Image.new('RGB', (len(pal) * 16, 16)); [sw.paste(tuple(int(v) for v in c), (i * 16, 0, i * 16 + 16, 16)) for i, c in enumerate(pal)]; sw.save(O / 'palette.png')
meta = {'sheet': 'elaia_turnaround_1.jpg (1792x1008)', 'order_on_sheet': 'S, N, L1 (left profile), L2 (left profile)', 'west': f'{PROFILE} as-is', 'east': f'horizontal mirror of {PROFILE} (x -> 127 - x)',
        'canvas': 128, 'sole_row': 123, 'target_height_S': 116, 'feet_x': 64, 'palette_colours': int(len(pal)), 'ingest': json.loads((W / 'ingest.json').read_text()), 'stills': log}
(O / 'elaia_still_4dir.json').write_text(json.dumps(meta, indent=1, default=float)); print(json.dumps(log, default=float))
