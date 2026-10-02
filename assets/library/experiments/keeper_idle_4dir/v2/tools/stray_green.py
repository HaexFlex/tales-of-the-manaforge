"""recolour tiny isolated green specks (<4 px) sitting on skin in the head area (left over from the key's own hair)."""
import sys
import numpy as np
from PIL import Image
from scipy import ndimage
sys.path.insert(0, '/workspace/keeper_idle/v2')
from hair_s import hsv, skin_mask
for p in sys.argv[1:]:
    a = np.array(Image.open(p).convert('RGBA'))
    h, s, v = hsv(a); g = (a[..., 3] > 0) & (h >= 65) & (h < 170) & (s > 0.25); g[45:] = False
    lab, n = ndimage.label(g, np.ones((3, 3))); sz = ndimage.sum(g, lab, range(1, n + 1))
    small = np.isin(lab, [i + 1 for i, z in enumerate(sz) if z < 4])
    sk = skin_mask(a); tgt = small & (ndimage.uniform_filter(sk.astype(float), 3) > 0.5)
    if tgt.any():
        _, (iy, ix) = ndimage.distance_transform_edt(~sk, return_indices=True); a[tgt] = a[iy[tgt], ix[tgt]]
    Image.fromarray(a).save(p); print(p, 'stray green px', int(tgt.sum()))
