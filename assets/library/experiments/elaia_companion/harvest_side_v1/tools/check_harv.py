#!/usr/bin/env python3
"""Elaia harvest/station frame check: RGBA, size, alpha 0/255 only, corners+border clear, alpha-0 RGB = 0, no magenta/violet
tint, 0 off-palette, soles row (non-water pixels), stream never below the sole row, feet centre (edge) x, components (body = 1; water may add free stream pieces in water tones)."""
import json, sys, glob
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage
sys.path.insert(0, '/workspace/elaia_anims'); from ingest_elaia import tint
def check(meta_path, pal_path):
    m = json.loads(Path(meta_path).read_text()); d = Path(meta_path).parent; pal = {tuple(c) for c in json.loads(Path(pal_path).read_text())['colors']}
    W, H = m['frame_size']; cx, cy = m['feet_anchor']; res = []
    wt = {(44, 118, 214), (64, 196, 240), (150, 240, 252)}
    for f in m['files']:
        im = Image.open(d / f); a = np.array(im.convert('RGBA')); al = a[..., 3]; op = al > 0
        wmask = np.zeros(op.shape, bool)
        for c_ in ((44, 118, 214), (64, 196, 240), (150, 240, 252)): wmask |= (a[..., :3] == c_).all(-1)
        body = op & ~wmask; rows = np.nonzero(body.any(1))[0]; sole = int(rows.max())
        band = np.nonzero(body[sole - 2:sole + 1].any(0))[0]
        cols = op.copy(); lab, n = ndimage.label(op, np.ones((3, 3)))
        area = ndimage.sum(op, lab, np.arange(1, n + 1)); big = 1 + int(np.argmax(area))
        nonwater_extra = 0
        for k in range(1, n + 1):
            if k == big: continue
            px = {tuple(c) for c in a[lab == k][:, :3].tolist()}
            if not px <= wt: nonwater_extra += 1
        r = {'file': f, 'rgba': im.mode == 'RGBA', 'size_ok': (im.width, im.height) == (W, H), 'alpha_not_0_255': int(((al > 0) & (al < 255)).sum()),
             'border_clear': bool(not op[0].any() and not op[-1].any() and not op[:, 0].any() and not op[:, -1].any()),
             'zero_rgb': int((a[~op][:, :3] != 0).any(-1).sum()),
             'magenta': int(((a[..., 0] > 200) & (a[..., 1] < 80) & (a[..., 2] > 200) & op).sum()), 'tint': int((tint(a[..., :3]) & op).sum()),
             'off_palette': len({tuple(c) for c in a[op][:, :3].tolist()} - pal), 'sole_row': sole, 'feet_cx_edge': (int(band.min()) + int(band.max()) + 1) / 2,
             'top_row': int(rows.min()), 'below_sole_px': int(op[cy:].sum()), 'components': int(n), 'non_water_extra_components': nonwater_extra}
        r['pass'] = bool(r['rgba'] and r['size_ok'] and r['alpha_not_0_255'] == 0 and r['border_clear'] and r['zero_rgb'] == 0 and r['magenta'] == 0
                         and r['tint'] == 0 and r['off_palette'] == 0 and r['sole_row'] == cy - 1 and r['below_sole_px'] == 0 and abs(r['feet_cx_edge'] - cx) <= 3 and nonwater_extra == 0)
        res.append(r)
    return res
if __name__ == '__main__':
    root = Path(sys.argv[1]); out = {}; tot = ok = 0
    for mp in sorted(root.glob(sys.argv[2])):
        m = json.loads(mp.read_text()); pal = root / m['palette'].split(' ')[0]
        r = check(mp, pal); out[m['clip']] = r; tot += len(r); ok += sum(x['pass'] for x in r)
        print(m['clip'], f"{sum(x['pass'] for x in r)}/{len(r)}", 'sole', sorted({x['sole_row'] for x in r}), 'feet_cx', sorted({x['feet_cx_edge'] for x in r}),
              'top', min(x['top_row'] for x in r), 'comps', sorted({x['components'] for x in r}), 'tint', sum(x['tint'] for x in r), 'offpal', sum(x['off_palette'] for x in r))
    (root / 'alpha_check.json').write_text(json.dumps({'all_pass': ok == tot, 'pass': ok, 'total': tot, 'clips': out}, indent=1))
    print('ALL PASS', ok == tot, f'{ok}/{tot}')
