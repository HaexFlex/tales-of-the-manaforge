"""v2 N: shrink the cyan back rune to ~70 % (same centre, same glow and colours) and repaint the coat under it.
1. rune mask = cyan core (g,b >> r) + its light-blue glow halo (coat-blue pixels near the core that are clearly lighter
   than the surrounding coat)
2. coat repaint = harmonic fill (iterative 4-neighbour diffusion) from the surrounding coat-blue pixels only
   (trim, shoulder pads, arms and outline are never sampled or touched)
3. the rune layer (core + glow, full alpha) is resampled to 0.7 about its centre (premultiplied LANCZOS) and composited
   over the repainted coat; the shared palette mapping later snaps everything to palette colours"""
import sys
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage
sys.path.insert(0, '/workspace/keeper_idle/tools')
from build_idles import to_lab, is_blue
R = Path('/workspace/keeper_idle')

def rune_mask(a):
    r, g, b, al = [a[..., i].astype(int) for i in range(4)]
    core = (al > 0) & (((g > r + 40) & (b > r + 40) & (g > 110)) | ((r > 150) & (g > 200) & (b > 200)))
    lab, n = ndimage.label(core, np.ones((3, 3)))
    if n: core = lab == (1 + int(np.argmax(ndimage.sum(core, lab, range(1, n + 1)))))
    near = ndimage.binary_dilation(core, np.ones((3, 3)), iterations=4)
    blue = is_blue(a) & (al > 0)
    L = np.zeros(al.shape); L[al > 0] = to_lab(a[al > 0][:, :3].astype(np.int32))[:, 0]
    ring = ndimage.binary_dilation(core, np.ones((3, 3)), iterations=9) & ~near & blue
    coatL = float(np.median(L[ring]))
    halo = near & blue & (L > coatL + 6) & ~core
    return core, halo, coatL

def diffuse_fill(a, M, src, iters=1500):
    out = a.astype(float).copy()
    out[M, :3] = out[src, :3].mean(0)
    valid = M | src
    for _ in range(iters):
        acc = np.zeros(a.shape[:2] + (3,)); cnt = np.zeros(a.shape[:2])
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            sh = np.roll(np.roll(out[..., :3], dy, 0), dx, 1); vm = np.roll(np.roll(valid, dy, 0), dx, 1)
            acc += sh * vm[..., None]; cnt += vm
        upd = M & (cnt > 0)
        out[upd, :3] = acc[upd] / cnt[upd][:, None]
    return out.round().clip(0, 255).astype(np.uint8)

def shrink_rune(a, scale=0.7, inner=0.36, mode='axis'):
    core, halo, coatL = rune_mask(a)
    blue = is_blue(a) & (a[..., 3] > 0)
    L = np.zeros(a.shape[:2]); L[a[..., 3] > 0] = to_lab(a[a[..., 3] > 0][:, :3].astype(np.int32))[:, 0]
    rim = ndimage.binary_dilation(core, np.ones((3, 3)), iterations=2) & blue & (L < coatL - 5) & ~core & ~halo
    M = core | halo | rim
    ys, xs = np.nonzero(core); cx, cy = (xs.min() + xs.max()) / 2, (ys.min() + ys.max()) / 2
    bbox0 = (int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max()))
    ha, hb = (xs.max() - xs.min() + 1) / 2, (ys.max() - ys.min() + 1) / 2      # core half sizes (diamond metric unit)
    # 1. repaint the coat under the whole rune (+1 px blend edge) from surrounding coat only
    Mpad = ndimage.binary_dilation(M, iterations=1) & (blue | M)
    base = diffuse_fill(a.copy(), Mpad, blue & ~Mpad)
    # 2. concentric colour profile of the rune in the diamond metric d = |dx|/ha + |dy|/hb (mode colour per bin)
    yy, xx = np.nonzero(M); d0 = np.abs(xx - cx) / ha + np.abs(yy - cy) / hb
    cols = a[yy, xx, :3].astype(int); BIN = 0.035
    prof = {}
    for k in np.unique((d0 / BIN).astype(int)):
        sel = (d0 / BIN).astype(int) == k
        u, c = np.unique(cols[sel], axis=0, return_counts=True); prof[int(k)] = u[c.argmax()]
    kmax = max(prof)
    def colour(d):
        k = int(d / BIN)
        while k not in prof and k > 0: k -= 1
        return prof.get(k)
    # 3. render the rune at `scale` about the same centre: inner star/core sampled from the original (nearest),
    #    rings from the profile, so every ring keeps its colour and the glow stays the outermost ring
    out = base.copy()
    Yc = int(round(cy)); rowM = np.nonzero(M[Yc])[0]
    umax = max(abs(rowM.min() - cx), abs(rowM.max() - cx)) / ha
    for y in range(128):
        for x in range(128):
            if out[y, x, 3] == 0: continue
            d = abs(x - cx) / (ha * scale) + abs(y - cy) / (hb * scale)
            if d > (kmax + 1) * BIN: continue
            if not (blue[y, x] or M[y, x] or Mpad[y, x]): continue          # never paint over trim/arms/outline
            if mode == 'ss':
                continue
            if mode == 'axis':
                # clean concentric rings: colour = the original's horizontal profile through the centre at the same
                # normalised diamond distance (avg of left/right side picks the nearer-to-axis-symmetric colour)
                if d < inner:
                    X, Y = int(round(cx + (x - cx) / scale)), int(round(cy + (y - cy) / scale))
                    out[y, x, :3] = a[Y, X, :3]; continue
                if d > umax: continue
                xl = int(round(cx - d * ha)); xr = int(round(cx + d * ha)); Yc = int(round(cy))
                c = a[Yc, xl, :3] if M[Yc, xl] else (a[Yc, xr, :3] if M[Yc, xr] else None)
                if c is not None: out[y, x, :3] = c
                continue
            if mode in ('nn', 'bright'):
                X0, X1 = cx + (x - 0.5 - cx) / scale, cx + (x + 0.5 - cx) / scale
                Y0, Y1 = cy + (y - 0.5 - cy) / scale, cy + (y + 0.5 - cy) / scale
                X, Y = int(round((X0 + X1) / 2)), int(round((Y0 + Y1) / 2))
                if mode == 'bright':
                    best = None
                    for YY in range(int(np.floor(Y0 + 0.5)), int(np.ceil(Y1 - 0.5)) + 1):
                        for XX in range(int(np.floor(X0 + 0.5)), int(np.ceil(X1 - 0.5)) + 1):
                            if 0 <= YY < 128 and 0 <= XX < 128 and M[YY, XX] and (best is None or L[YY, XX] > L[best]): best = (YY, XX)
                    if best is not None and (not M[Y, X] or L[best] > L[Y, X] + 20): Y, X = best
                if 0 <= Y < 128 and 0 <= X < 128 and M[Y, X]: out[y, x, :3] = a[Y, X, :3]
                continue
            if d < inner:
                X, Y = int(round(cx + (x - cx) / scale)), int(round(cy + (y - cy) / scale))
                out[y, x, :3] = a[Y, X, :3]
            else:
                c = colour(d)
                if c is not None: out[y, x, :3] = c
    if mode == 'ss':
        # supersampled (6x6 per pixel) concentric rendering from the horizontal profile, box-averaged -> soft painted rings
        SS = 6; Yc = int(round(cy))
        xsL = np.arange(int(np.floor(cx)), int(rowM.min()) - 1, -1)          # centre -> left edge
        uL = (cx - xsL) / ha; cL = a[Yc, xsL, :3].astype(float); inM = M[Yc, xsL]
        uL, cL = uL[inM], cL[inM]
        def prof(u):
            u = np.clip(u, uL.min(), uL.max())
            return np.stack([np.interp(u, uL, cL[:, k]) for k in range(3)], -1)
        for y in range(128):
            for x in range(128):
                if out[y, x, 3] == 0 or not (blue[y, x] or M[y, x] or Mpad[y, x]): continue
                o = (np.arange(SS) + 0.5) / SS - 0.5
                X = x + o[None, :].repeat(SS, 0); Y = y + o[:, None].repeat(SS, 1)
                u = np.abs(X - cx) / (ha * scale) + np.abs(Y - cy) / (hb * scale)
                if u.min() > umax: continue
                acc = np.zeros(3); n = 0
                for uu, XX, YY in zip(u.ravel(), X.ravel(), Y.ravel()):
                    if uu > umax: acc += out[y, x, :3]; n += 1; continue
                    if uu < inner:
                        sx, sy = int(round(cx + (XX - cx) / scale)), int(round(cy + (YY - cy) / scale)); acc += a[sy, sx, :3]
                    else: acc += prof(np.array([uu]))[0]
                    n += 1
                out[y, x, :3] = np.clip(acc / n, 0, 255).astype(np.uint8)
    core2, _, _ = rune_mask(out); ys, xs = np.nonzero(core2)
    bbox1 = (int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max()))
    allM = M; yy, xx = np.nonzero(allM)
    return out, {"centre": [float(cx), float(cy)], "core_bbox_before": bbox0, "core_bbox_after": bbox1,
                 "core_size_before": [bbox0[2] - bbox0[0] + 1, bbox0[3] - bbox0[1] + 1],
                 "core_size_after": [bbox1[2] - bbox1[0] + 1, bbox1[3] - bbox1[1] + 1],
                 "rune_incl_glow_px_before": int(M.sum()), "coat_L": coatL}

if __name__ == '__main__':
    src, dst = sys.argv[1], sys.argv[2]; mode = sys.argv[3] if len(sys.argv) > 3 else 'axis'
    a = np.array(Image.open(src).convert('RGBA'))
    out, info = shrink_rune(a, mode=mode)
    Image.fromarray(out).save(dst); print(info)
