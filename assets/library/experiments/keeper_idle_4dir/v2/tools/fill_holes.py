"""close pinholes inside the silhouette left by removing the key's own hair: skin if next to skin, else nearest pixel."""
import sys
import numpy as np
from PIL import Image
from scipy import ndimage
sys.path.insert(0, '/workspace/keeper_idle/v2')
from hair_s import skin_mask

def close_holes(a, ymax=48):
    op = a[..., 3] > 0
    holes = ndimage.binary_fill_holes(op) & ~op
    holes[ymax:] = False
    if not holes.any(): return a, 0
    out = a.copy()
    sk = skin_mask(a)
    near_skin = ndimage.binary_dilation(sk, np.ones((3, 3)), iterations=2)
    for src_mask, tgt in ((sk, holes & near_skin), (op, holes & ~near_skin)):
        if tgt.any() and src_mask.any():
            _, (iy, ix) = ndimage.distance_transform_edt(~src_mask, return_indices=True)
            out[tgt] = a[iy[tgt], ix[tgt]]
    return out, int(holes.sum())

if __name__ == '__main__':
    for p in sys.argv[1:]:
        a = np.array(Image.open(p).convert('RGBA')); out, n = close_holes(a)
        Image.fromarray(out).save(p); print(p, 'holes filled', n)
