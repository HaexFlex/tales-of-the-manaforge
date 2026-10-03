#!/usr/bin/env python3
"""Elaia hi-res front art -> 128x128 game sprite in the Keeper convention (soles on row 123, feet centred x 64, hard alpha),
premultiplied area downscale, k-means (Lab) palette shared by the key / no-key versions; then x5 nearest on flat magenta
1168x784 (same layout as the Keeper Imagine refs)."""
import json, sys
import numpy as np
from PIL import Image
from scipy import ndimage
from scipy.cluster.vq import kmeans2
sys.path.insert(0, '/workspace/keeper_idle/tools')
from build_idles import to_lab
TARGET_H = int(sys.argv[1]) if len(sys.argv) > 1 else 116
NCOL = 40
def load_rgba(p, key_black=True):
    im = np.array(Image.open(p).convert('RGBA')).astype(float)
    if key_black and (im[..., 3] == 255).all():
        a = im[..., :3].astype(int); fg = a.max(-1) >= 12
        lab, n = ndimage.label(~fg); border = set(np.unique(np.r_[lab[0], lab[-1], lab[:, 0], lab[:, -1]])) - {0}
        im[..., 3] = (~np.isin(lab, list(border))) * 255
    return im
def downscale(im, h_t):
    al = im[..., 3] > 0; ys, xs = np.nonzero(al); y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    # feet: centre of the opaque columns in the bottom 4% of the figure
    fb = al[y1 - int(0.04 * (y1 - y0)):y1]; fx = np.nonzero(fb.any(0))[0]; feet_cx = (fx.min() + fx.max() + 1) / 2
    s = h_t / (y1 - y0)
    W = int(round(128 / s)); H = int(round(128 / s))
    # place so that the figure bottom lands at row 124 (soles row 123) and feet centre at x 64
    oy = y1 - 124 / s; ox = feet_cx - 64 / s
    canvas = np.zeros((H, W, 4)); sy0, sx0 = int(round(oy)), int(round(ox))
    src = im.copy(); src[..., :3] *= (src[..., 3:4] / 255.)
    for c in range(4):
        pass
    big = np.zeros((H, W, 4))
    ya, xa = max(0, sy0), max(0, sx0); yb, xb = min(im.shape[0], sy0 + H), min(im.shape[1], sx0 + W)
    big[ya - sy0:yb - sy0, xa - sx0:xb - sx0] = src[ya:yb, xa:xb]
    out = np.stack([np.array(Image.fromarray(big[..., c].astype(np.float32), 'F').resize((128, 128), Image.BOX)) for c in range(4)], -1)
    a = out[..., 3] / 255.; rgb = np.where(a[..., None] > 0, out[..., :3] / np.maximum(a[..., None], 1e-6), 0)
    hard = a >= 0.5
    return np.clip(rgb, 0, 255), hard, {'scale': s, 'src_bbox': [int(x0), int(y0), int(x1), int(y1)], 'feet_cx_src': feet_cx}
def palette(rgbs):
    px = np.concatenate([r[h] for r, h in rgbs]).astype(np.float64)
    lab = to_lab(px.astype(np.int32)); np.random.seed(7)
    cent, lbl = kmeans2(lab, NCOL, minit='++', iter=30, seed=7)
    pal = np.array([np.median(px[lbl == k], 0) for k in range(NCOL) if (lbl == k).any()]).round().astype(np.uint8)
    return pal
def quant(rgb, hard, pal):
    from scipy.spatial import cKDTree
    out = np.zeros((128, 128, 4), np.uint8); _, idx = cKDTree(to_lab(pal.astype(np.int32))).query(to_lab(rgb[hard].round().astype(np.int32)))
    out[hard, :3] = pal[idx]; out[hard, 3] = 255
    lab, n = ndimage.label(hard, np.ones((3, 3)))
    if n > 1:
        sz = ndimage.sum(hard, lab, range(1, n + 1)); kill = (lab > 0) & (lab != 1 + int(np.argmax(sz))) & np.isin(lab, 1 + np.nonzero(sz < 6)[0]); out[kill] = 0
    return out
def ref_x5(spr, path):
    c = Image.new('RGB', (1168, 784), (255, 0, 255)); big = Image.fromarray(spr).resize((640, 640), Image.NEAREST)
    c.paste(big, ((1168 - 640) // 2, (784 - 640) // 2), big); c.save(path)
if __name__ == '__main__':
    k = load_rgba('work/elaia_front_src.png'); nk = load_rgba('work/elaia_front_nokey_hires.png', key_black=False)
    # use the key version's bbox/feet for both so they align pixel-for-pixel (key does not reach the top/bottom)
    ad = load_rgba('work/elaia_front_nokey_armsdown_hires.png', key_black=False)
    rk, hk, info = downscale(k, TARGET_H); rn, hn, info_n = downscale(nk, TARGET_H); ra, ha, info_a = downscale(ad, TARGET_H)
    pal = palette([(rk, hk), (rn, hn)])
    sk, sn, sa = quant(rk, hk, pal), quant(rn, hn, pal), quant(ra, ha, pal)
    Image.fromarray(sk).save('work/elaia_s_key_128.png'); Image.fromarray(sn).save('work/elaia_s_nokey_128_raw.png'); Image.fromarray(sa).save('work/elaia_s_armsdown_128_raw.png')
    json.dump({'target_h': TARGET_H, 'palette': pal.tolist(), 'key': info, 'nokey': info_n, 'armsdown': info_a}, open('work/sprite_info.json', 'w'), indent=1, default=float)
    for nm, s in (('key', sk), ('nokey_raw', sn), ('armsdown_raw', sa)):
        ys, xs = np.nonzero(s[..., 3]); print(nm, 'rows', ys.min(), ys.max(), 'h', ys.max() - ys.min() + 1, 'x', xs.min(), xs.max(), 'colours', len(np.unique(s[s[..., 3] > 0][:, :3], axis=0)))
