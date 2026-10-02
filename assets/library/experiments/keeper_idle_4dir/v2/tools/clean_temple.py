"""E profile: the A3 key's own brow/hair-shadow pixels left on the temple (between the cut hair line and the eye) are
recoloured to the nearest skin colour, so the temple reads as clean skin under the live bangs."""
import sys
import numpy as np
from PIL import Image
from scipy import ndimage
sys.path.insert(0, '/workspace/keeper_idle/v2')
from hair_s import skin_mask, hsv

def clean(a, box, keep_box):
    x0, y0, x1, y1 = box
    out = a.copy(); sk = skin_mask(a); h, s, v = hsv(a)
    green = (a[..., 3] > 0) & (h >= 65) & (h < 170) & (s > 0.25)
    lab, n = ndimage.label(green, np.ones((3, 3))); sizes = ndimage.sum(green, lab, range(1, n + 1))
    main = np.isin(lab, [i + 1 for i, z in enumerate(sizes) if z >= 20])
    hairedge = ndimage.binary_dilation(main, np.ones((3, 3)), iterations=1)
    tgt = np.zeros_like(sk); tgt[y0:y1 + 1, x0:x1 + 1] = True
    kx0, ky0, kx1, ky1 = keep_box; tgt[ky0:ky1 + 1, kx0:kx1 + 1] = False
    tgt &= (a[..., 3] > 0) & ~sk & ~(main) & ~(hairedge & (v < 60))
    _, (iy, ix) = ndimage.distance_transform_edt(~sk, return_indices=True)
    out[tgt] = a[iy[tgt], ix[tgt]]
    return out, int(tgt.sum())

if __name__ == '__main__':
    p = sys.argv[1]; a = np.array(Image.open(p).convert('RGBA'))
    out, n = clean(a, (59, 24, 66, 29), (65, 29, 70, 34)); Image.fromarray(out).save(p); print('temple px recoloured', n)
