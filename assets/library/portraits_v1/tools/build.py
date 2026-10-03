#!/usr/bin/env python3
"""Party/sheet portraits v1: magenta jpg -> 52x52 and 160x160 hard-alpha pixel portraits, character palette, 1 px dark outline.
Framing (identical for both): eye line (midpoint of the two eye centres) on row EYE_Y*N/52, eye->chin = EC*N/52 px, eye midpoint at x = N/2."""
import json, sys
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage
R = Path('/workspace/portraits'); OUT = R / 'build'; OUT.mkdir(exist_ok=True)
PALS = {'keeper': '/workspace/keeper_idle/repo/assets/library/experiments/keeper_idle_4dir/v3_stills_8dir/option_a/palette.json',
        'elaia': '/workspace/elaia_anims/stills/palette.json'}
# source landmarks (1408 px jpg): eye midpoint, chin row
LM = {'keeper': dict(src='portrait_keeper_1.jpg', eye=(735, 620), chin=830),
      'elaia': dict(src='portrait_elaia_1.jpg', eye=(653, 590), chin=790)}
EYE_Y, EC = 24.0, 12.0
EXTRA = {'keeper': [], 'elaia': []}   # palette additions (filled in below if needed)

def lab(rgb):
    c = np.asarray(rgb, np.float64) / 255.0
    c = np.where(c > 0.04045, ((c + 0.055) / 1.055) ** 2.4, c / 12.92)
    M = np.array([[0.4124, 0.3576, 0.1805], [0.2126, 0.7152, 0.0722], [0.0193, 0.1192, 0.9505]])
    xyz = c @ M.T / np.array([0.95047, 1.0, 1.08883])
    f = np.where(xyz > 0.008856, np.cbrt(xyz), 7.787 * xyz + 16 / 116)
    return np.stack([116 * f[..., 1] - 16, 500 * (f[..., 0] - f[..., 1]), 200 * (f[..., 1] - f[..., 2])], -1)

def load(c):
    a = np.array(Image.open(R / 'raw' / LM[c]['src']).convert('RGB')).astype(np.float32)
    mg = np.minimum(a[..., 0], a[..., 2]) - a[..., 1]
    fg = ~(mg > 100)                                     # coverage: anything not clearly magenta
    core = ndimage.binary_erosion(fg, iterations=3) & ~(mg > 30)   # colour source: 3 px inside, no purple-ish jpg fringe
    return a, fg, core

def sample(c, N):
    a, fg, core = load(c); L = LM[c]; k = N / 52.0
    s = EC * k / (L['chin'] - L['eye'][1]); ex, ey = L['eye']; cx, eyy = N / 2.0, EYE_Y * k
    rgb = np.zeros((N, N, 3), np.float32); alpha = np.zeros((N, N), bool)
    H, W = fg.shape
    for Y in range(N):
        for X in range(N):
            x0, x1 = ex + (X - cx) / s, ex + (X + 1 - cx) / s; y0, y1 = ey + (Y - eyy) / s, ey + (Y + 1 - eyy) / s
            xi0, xi1, yi0, yi1 = int(round(x0)), int(round(x1)), int(round(y0)), int(round(y1))
            full = (xi1 - xi0) * (yi1 - yi0)
            xi0, yi0, xi1, yi1 = max(xi0, 0), max(yi0, 0), min(xi1, W), min(yi1, H)
            if xi1 <= xi0 or yi1 <= yi0: continue
            cov = fg[yi0:yi1, xi0:xi1]
            # outside the source image (only bottom/top can happen) counts as body if the edge row is body
            missing = full - cov.size
            covered = cov.sum() + (missing if yi1 == H and fg[H - 1, xi0:xi1].mean() > 0.5 else 0)
            if covered < 0.5 * full: continue
            m = core[yi0:yi1, xi0:xi1]
            if m.sum() == 0: m = cov
            if m.sum() == 0: continue
            rgb[Y, X] = np.median(a[yi0:yi1, xi0:xi1][m], 0); alpha[Y, X] = True
    return rgb, alpha, s

def quant(rgb, alpha, pal):
    P = np.array(pal, np.float64); PL = lab(P)
    L = lab(rgb.reshape(-1, 3)); d = ((L[:, None, :] - PL[None]) ** 2).sum(-1)
    idx = d.argmin(1).reshape(alpha.shape)
    out = np.zeros(alpha.shape + (4,), np.uint8); out[..., :3] = P[idx].astype(np.uint8); out[..., 3] = alpha * 255
    out[~alpha] = 0
    return out

def clean_alpha(img, min_island=4, max_hole=2):
    a = img[..., 3] > 0
    lab_, n = ndimage.label(a, np.ones((3, 3)))
    for i in range(1, n + 1):
        if (lab_ == i).sum() < min_island: img[lab_ == i] = 0
    a = img[..., 3] > 0
    holes, n = ndimage.label(~a)
    for i in range(1, n + 1):
        m = holes == i; ys, xs = np.nonzero(m)
        touches = ys.min() == 0 or xs.min() == 0 or ys.max() == a.shape[0] - 1 or xs.max() == a.shape[1] - 1
        if not touches and m.sum() <= max_hole:
            for y, x in zip(ys, xs):
                nb = img[max(y-1,0):y+2, max(x-1,0):x+2].reshape(-1, 4); nb = nb[nb[:, 3] > 0]
                vals, cnt = np.unique(nb[:, :3], axis=0, return_counts=True); img[y, x, :3] = vals[cnt.argmax()]; img[y, x, 3] = 255
    return img

def despeckle(img, protect):
    """lone pixels (no 4-neighbour of the same colour) whose 8-neighbourhood is dominated (>=5) by one colour -> that colour"""
    g = img.copy(); H, W = img.shape[:2]; n = 0
    for y in range(1, H - 1):
        for x in range(1, W - 1):
            if img[y, x, 3] == 0 or protect[y, x]: continue
            c = tuple(img[y, x, :3])
            if any(img[y+dy, x+dx, 3] > 0 and tuple(img[y+dy, x+dx, :3]) == c for dy, dx in ((0,1),(1,0),(0,-1),(-1,0))): continue
            nb = img[y-1:y+2, x-1:x+2].reshape(-1, 4); nb = np.delete(nb, 4, 0); nb = nb[nb[:, 3] > 0]
            if len(nb) < 6: continue
            vals, cnt = np.unique(nb[:, :3], axis=0, return_counts=True)
            if cnt.max() >= 5: g[y, x, :3] = vals[cnt.argmax()]; n += 1
    return g, n

def outline(img, pal, maxL=32.0):
    """1 px outline in transparent pixels 4-adjacent to the body: the darkest palette colour (L* <= maxL) closest in hue
    to the mean of the adjacent body pixels."""
    P = np.array(pal, np.float64); PL = lab(P); dark = np.nonzero(PL[:, 0] <= maxL)[0]
    a = img[..., 3] > 0; ring = ndimage.binary_dilation(a, [[0,1,0],[1,1,1],[0,1,0]]) & ~a
    g = img.copy(); H, W = a.shape
    for y, x in zip(*np.nonzero(ring)):
        nb = [img[y+dy, x+dx, :3] for dy, dx in ((0,1),(1,0),(0,-1),(-1,0)) if 0 <= y+dy < H and 0 <= x+dx < W and a[y+dy, x+dx]]
        m = lab(np.mean(nb, 0)); dl = PL[dark]
        # hue match (a*, b*) weighted, darker preferred
        score = ((dl[:, 1:] - m[1:] * 0.6) ** 2).sum(-1) + 0.5 * dl[:, 0] ** 2
        g[y, x, :3] = P[dark[score.argmin()]].astype(np.uint8); g[y, x, 3] = 255
    return g, int(ring.sum())

def eye_boxes(N, c):
    k = N / 52.0; s = EC * k / (LM[c]['chin'] - LM[c]['eye'][1]); m = np.zeros((N, N), bool)
    half = (LM[c]['eye'][0] - (520 if c == 'elaia' else 635)) * s  # half eye separation in target px
    for sx in (-1, 1):
        x = int(round(N / 2 + sx * half)); y = int(round(EYE_Y * k))
        r = int(round(3 * k)); m[max(y - r, 0):y + r + 1, max(x - r - 1, 0):x + r + 2] = True
    return m

# hand touch-ups at 52 px (palette indices into the character palette): (row, col, idx)
TOUCH = {'elaia': [
    # left eye: dark iris top, highlight, lighter iris bottom
    (23, 19, 25), (23, 20, 25), (23, 21, 25), (24, 19, 28), (24, 20, 25), (24, 21, 17), (25, 19, 17), (25, 20, 5), (25, 21, 17),
    # right eye
    (22, 32, 25), (22, 33, 25), (22, 34, 25), (22, 35, 25), (23, 32, 25), (23, 33, 28), (23, 34, 25), (23, 35, 25),
    (24, 32, 17), (24, 33, 25), (24, 34, 25), (24, 35, 17), (25, 32, 17), (25, 33, 5), (25, 34, 5), (25, 35, 17),
    # nose hint + mouth
    (30, 24, 38), (34, 26, 38), (34, 27, 16), (34, 28, 38)],
    'keeper': [(29, 27, 43)]}

def build(c, N):
    pal = json.loads(Path(PALS[c]).read_text())['colors'] + EXTRA[c]
    rgb, alpha, s = sample(c, N)
    img = quant(rgb, alpha, pal)
    img = clean_alpha(img)
    img, nd = despeckle(img, eye_boxes(N, c))
    img, no = outline(img, pal)
    if N == 52:
        for y, x, i in TOUCH[c]: img[y, x, :3] = pal[i]; img[y, x, 3] = 255
    img[img[..., 3] == 0] = 0
    return img, dict(scale=s, despeckled=nd, outline_px=no, palette=len(pal))

if __name__ == '__main__':
    rep = {}
    for c in ('keeper', 'elaia'):
        for N, suf in ((52, ''), (160, '_sheet')):
            img, info = build(c, N); Image.fromarray(img).save(OUT / f'{c}_portrait{suf}.png'); rep[f'{c}{suf}'] = info
    print(json.dumps(rep, indent=1))
