#!/usr/bin/env python3
"""checks: exact size, RGBA, hard alpha (0/255 only), transparent RGB = 0, no magenta/purple, no light/purple fringe on the
silhouette edge, every opaque RGB in the character palette (+ listed additions)."""
import json, sys
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage
B = Path(sys.argv[1] if len(sys.argv) > 1 else '/workspace/portraits/build')
PALS = {'keeper': '/workspace/keeper_idle/repo/assets/library/experiments/keeper_idle_4dir/v3_stills_8dir/option_a/palette.json',
        'elaia': '/workspace/elaia_anims/stills/palette.json'}
ok_all = True; rep = {}
for c in ('keeper', 'elaia'):
    pal = {tuple(x) for x in json.loads(Path(PALS[c]).read_text())['colors']}
    for suf, N in (('', 52), ('_sheet', 160)):
        f = B / f'{c}_portrait{suf}.png'; im = Image.open(f); a = np.array(im.convert('RGBA')).astype(int)
        al = a[..., 3]; op = al == 255
        r, g, b = a[..., 0], a[..., 1], a[..., 2]
        magenta = op & (r > 150) & (b > 150) & (g < 110)
        purple = op & (r - g > 40) & (b - g > 40)
        edge = op & ~ndimage.binary_erosion(op, border_value=1)
        res = dict(size=list(im.size), mode=im.mode, size_ok=im.size == (N, N) and im.mode == 'RGBA',
                   hard_alpha=bool(np.isin(al, [0, 255]).all()), clear_rgb_zero=bool((a[al == 0][:, :3] == 0).all()),
                   magenta=int(magenta.sum()), purple=int(purple.sum()), purple_edge=int((purple & edge).sum()),
                   off_palette=int(sum(1 for p in map(tuple, a[op][:, :3]) if p not in pal)),
                   colours=len({tuple(p) for p in a[op][:, :3]}), opaque=int(op.sum()),
                   bbox=list(Image.fromarray(np.uint8(op) * 255).getbbox()))
        res['pass'] = res['size_ok'] and res['hard_alpha'] and res['clear_rgb_zero'] and res['magenta'] == 0 and res['purple'] == 0 and res['off_palette'] == 0
        ok_all &= res['pass']; rep[f.name] = res
print(json.dumps(rep, indent=1)); print('ALL PASS' if ok_all else 'FAIL'); sys.exit(0 if ok_all else 1)
