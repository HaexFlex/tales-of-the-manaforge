"""v2 N: back view of the LIVE hair.
- silhouette + outer spikes = the transplanted live S hair layer (green/outline pixels only) mirrored about the head axis (x' = 127 - x)
- the face opening of that layer (= back of head / nape in this view) is filled with the new N key's own back-of-head strands,
  recoloured onto the live hair ramp by lightness, lightness-matched to the hair just above, darkening toward the nape
- one dark-outline row closes the hair at the nape"""
import sys
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage
sys.path.insert(0, '/workspace/keeper_idle/tools'); sys.path.insert(0, '/workspace/keeper_idle/v2')
from build_idles import defringe, to_lab, is_blue, is_trim
def is_coat(a): return is_blue(a) | is_trim(a)
from hair_s import hair_mask, hsv
R = Path('/workspace/keeper_idle')

def ramp_by_L(L, ramp):
    Lr = to_lab(ramp)[:, 0]; return ramp[np.abs(L[:, None] - Lr[None, :]).argmin(1)]

L_TOP, L_BOT = 52.0, 40.0
MODE = 'strand'
SEP = [0, 0, 1, 0, 0, 0, 1, 0, 1, 0, 0, 1]   # strand separations (irregular)
def build_n(new_n, s_hair_layer, nape_y=None, grad=L_TOP - L_BOT, mirror=True, o_limit=None, clear='head', eye_boxes=()):
    hair = s_hair_layer[:, ::-1].copy() if mirror else s_hair_layer.copy()
    h, s, v = hsv(hair)
    warm = ((h < 60) | (h > 330)) & (s > 0.3) & (v > 60)
    hair[warm] = 0                                         # drop brow/ear/face-edge pixels picked up with the S hair
    cov = hair[..., 3] > 0
    gr = cov & (h >= 85) & (h < 165) & (s > 0.3)
    ramp = np.unique(hair[gr][:, :3], axis=0).astype(np.int32)
    ramp_dark = np.unique(hair[cov & ~gr][:, :3], axis=0).astype(np.int32)
    dk = ramp_dark[np.argmin(ramp_dark.sum(1))] if len(ramp_dark) else np.array([10, 30, 10])
    Hn = hair_mask(new_n, 42, list(eye_boxes), dil=1)
    if nape_y is None: nape_y = int(np.nonzero(Hn.any(1))[0].max())
    # filled silhouette per row (between the outermost hair pixels), down to the nape
    O = np.zeros_like(cov)
    for y in range(0, nape_y + 1):
        xs = np.nonzero(cov[y] | Hn[y])[0]
        if len(xs): O[y, xs.min():xs.max() + 1] = True
    O &= ~cov
    lab, n = ndimage.label(O)                              # only the face opening (largest gap); gaps between spikes stay transparent
    if n: O = lab == (1 + int(np.argmax(ndimage.sum(O, lab, range(1, n + 1)))))
    if o_limit is not None: O &= o_limit
    # remove the key's own head (hair + its brown hair shadows) above the nape; the neck/collar below stays
    out = new_n.copy()
    head = np.zeros_like(cov); head[:nape_y + 1] = True
    if clear == 'head': out[head & (new_n[..., 3] > 0) & ~is_coat(new_n)] = 0
    else: out[Hn] = 0
    ys0 = np.nonzero(O.any(1))[0]
    if len(ys0):
        y0 = ys0.min()
        Lref = L_TOP
        # continue the strands already in the hair downward through the opening: every column starts from the colour
        # of the hair pixel just above the opening (bang strands point down, so they become back-of-head strands),
        # darkening toward the nape; jagged strand tips at the bottom
        Lh = np.zeros((128, 128)); Lh[cov] = to_lab(hair[cov][:, :3].astype(np.int32))[:, 0]
        edge = cov & (Lh < 22) & ndimage.binary_dilation(O, iterations=1)   # dark outline of the bang tips -> refill
        O2 = O | edge
        tipoff = [0, 2, 1, 3, 1, 0, 2, 1, 3]
        seeds_L = {}
        shadow = ramp_by_L(np.array([L_BOT - 22.0]), ramp)[0]
        m = O2 & (new_n[..., 3] > 0)
        Lsrc_mean = float(to_lab(new_n[m][:, :3].astype(np.int32))[:, 0].mean()) if m.any() else 50.0
        for x in range(128):
            col = np.nonzero(O2[:, x])[0]
            if not len(col): continue
            ytop = col.min(); seed = None
            for yy in range(ytop - 1, max(-1, ytop - 6), -1):
                if cov[yy, x] and not edge[yy, x] and Lh[yy, x] >= 22: seed = hair[yy, x, :3]; break
            if seed is None:
                for dx in (1, -1, 2, -2, 3, -3):
                    xx = x + dx
                    if 0 <= xx < 128:
                        c2 = np.nonzero(O2[:, xx])[0]
                        if len(c2):
                            for yy in range(c2.min() - 1, max(-1, c2.min() - 6), -1):
                                if cov[yy, xx] and Lh[yy, xx] >= 22: seed = hair[yy, xx, :3]; break
                    if seed is not None: break
            if seed is None: seed = ramp[len(ramp) // 2]
            Ls = float(to_lab(seed[None].astype(np.int32))[0, 0]); seeds_L[x] = Ls
            Ls = float(np.median([seeds_L.get(x - 1, Ls), Ls, Ls])) if x - 1 in seeds_L else Ls; Ls = min(max(Ls, 44.0), 64.0) - (10.0 if SEP[x % len(SEP)] else 0.0)
            yt = nape_y - tipoff[x % len(tipoff)]
            for y in col:
                if MODE == 'tex' and y < yt and new_n[y, x, 3] > 0:
                    t = (y - ytop) / max(1, yt - ytop)
                    Lsrc = float(to_lab(new_n[y, x, :3][None].astype(np.int32))[0, 0])
                    L = (L_TOP + (L_BOT - L_TOP) * t) + (Lsrc - Lsrc_mean) * 0.9
                    out[y, x, :3] = ramp_by_L(np.array([L]), ramp)[0]; out[y, x, 3] = 255; continue
                if y > yt:                                   # between strand tips: the neck below shows through
                    out[y, x, :3] = shadow; out[y, x, 3] = 255; continue
                if y == yt: out[y, x, :3] = dk; out[y, x, 3] = 255; continue
                t = (y - ytop) / max(1, yt - ytop)
                L = Ls + (L_BOT - (10.0 if SEP[x % len(SEP)] else 0.0) - Ls) * t
                out[y, x, :3] = ramp_by_L(np.array([L]), ramp)[0]; out[y, x, 3] = 255
        cov = cov & ~edge
    out[cov] = hair[cov]
    layer = np.zeros_like(out); m = cov | O2
    layer[m] = out[m]; layer[..., 3] = np.where(m & (out[..., 3] > 0), 255, 0)
    build_n.layer = layer
    return out, int(O.sum())

if __name__ == '__main__':
    tag = sys.argv[1]
    new = np.array(Image.open(R / 'work/cand_A3s/key_N.png').convert('RGBA')); new, nfr = defringe(new)
    sh = np.array(Image.open(R / 'v2/work/S_a_hair.png').convert('RGBA'))
    out, n = build_n(new, sh)
    Image.fromarray(out).save(R / f'v2/work/N_{tag}.png'); Image.fromarray(build_n.layer).save(R / f'v2/work/N_{tag}_hairlayer.png'); print('nape fill px', n, 'defringed', nfr)
