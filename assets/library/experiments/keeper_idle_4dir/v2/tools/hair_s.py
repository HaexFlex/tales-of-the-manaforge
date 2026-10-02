"""v2 S: transplant the LIVE Keeper's hair (keeper_idle_south_0000.png, pixel-exact, 1:1) onto the new S key."""
import sys, json
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage
sys.path.insert(0, '/workspace/keeper_idle/tools')
from build_idles import defringe, is_blue, is_trim
R = Path('/workspace/keeper_idle'); K = R / 'repo/assets/art/keeper'

def hsv(a):
    p = a[..., :3].astype(float); mx = p.max(-1); mn = p.min(-1); c = mx - mn
    r, g, b = p[..., 0], p[..., 1], p[..., 2]
    with np.errstate(divide='ignore', invalid='ignore'):
        h = np.where(mx == r, ((g - b) / c) % 6, np.where(mx == g, (b - r) / c + 2, (r - g) / c + 4)) * 60
    return np.nan_to_num(h), np.where(mx > 0, c / np.maximum(mx, 1), 0), mx

def skin_mask(a):
    h, s, v = hsv(a); return (a[..., 3] > 127) & ((h < 45) | (h > 340)) & (v > 150) & (s > 0.12) & (s < 0.7)

def hair_mask(a, ymax, eye_boxes, dil=2):
    op = a[..., 3] > 127; h, s, v = hsv(a)
    yy = np.arange(128)[:, None] * np.ones((1, 128), int)
    G = op & (h >= 65) & (h < 170) & (s > 0.25) & (yy < ymax)
    for x0, y0, x1, y1 in eye_boxes: G[y0:y1 + 1, x0:x1 + 1] = False
    lab, n = ndimage.label(G, np.ones((3, 3)))
    sizes = ndimage.sum(G, lab, range(1, n + 1))
    main = np.isin(lab, [i + 1 for i, sz in enumerate(sizes) if sz >= 20])
    near = ndimage.binary_dilation(main, np.ones((3, 3)), iterations=dil)
    rgb = a
    other = op & near & ~skin_mask(a) & ~is_blue(rgb) & ~is_trim(rgb) & (yy < ymax) & (v < 140)
    for x0, y0, x1, y1 in eye_boxes: other[y0:y1 + 1, x0:x1 + 1] = False
    return main | other

def face_fill(a, ytop):
    sk = skin_mask(a); sk[:ytop] = False
    f = ndimage.binary_fill_holes(ndimage.binary_closing(sk, np.ones((3, 3)), iterations=2))
    return f

def transplant(new, live, live_eyes, new_eyes, dx, dy, ymax_live=40, ymax_new=42):
    Hl = hair_mask(live, ymax_live, live_eyes)
    hair = np.zeros_like(live); hair[Hl] = live[Hl]; hair[..., 3] = np.where(Hl, 255, 0)
    hair = np.roll(np.roll(hair, dy, 0), dx, 1)
    Hn = hair_mask(new, ymax_new, new_eyes, dil=1)
    face = face_fill(new, new_eyes[0][1] - 2) & ~Hn
    out = new.copy(); out[Hn] = 0
    cov = hair[..., 3] > 0
    out[cov] = hair[cov]
    hole = Hn & ~cov
    # holes inside the face silhouette -> skin of the nearest face pixel; outside -> transparent
    sk = skin_mask(out) & ~cov
    if sk.any():
        _, (iy, ix) = ndimage.distance_transform_edt(~sk, return_indices=True)
        inner = hole & ndimage.binary_dilation(face, np.ones((3, 3)), iterations=1)
        out[inner] = out[iy[inner], ix[inner]]
    return out, Hl, Hn, hair

if __name__ == '__main__':
    dx, dy = int(sys.argv[1]), int(sys.argv[2]); tag = sys.argv[3]
    live = np.array(Image.open(K / 'keeper_idle_south_0000.png').convert('RGBA'))
    new = np.array(Image.open(R / 'work/cand_A3s/key_S.png').convert('RGBA'))
    new, nfr = defringe(new)
    live_eyes = [[54, 30, 59, 35], [66, 30, 71, 35]]
    new_eyes = [[55, 29, 60, 35], [67, 29, 72, 35]]
    out, Hl, Hn, hair = transplant(new, live, live_eyes, new_eyes, dx, dy)
    Image.fromarray(out).save(R / f'v2/work/S_{tag}.png')
    Image.fromarray(hair).save(R / f'v2/work/S_{tag}_hair.png')
    print('live hair px', int(Hl.sum()), 'new hair px removed', int(Hn.sum()), 'defringed', nfr)
