#!/usr/bin/env python3
"""Walk v1 (Option A): source crops -> game frames.
scale per sheet = calibrated to the matching Option A still (S/N/E) on hair-top -> coat-hem distance (leg-independent, so a
mid-stride sheet isn't shrunk/grown by its stance); to_game (premult LANCZOS 2x + NN), hard alpha; defringe; Option A 48-colour
palette; vertical: lowest sole pixel -> row 123 (bob comes from the real hip height); horizontal: head+torso centroid (rows
top..top+50% of height) fixed, offset so the loop's mean feet centre = 63.5. Writes walk/work/<name>/g_##.png + phase.json"""
import sys, json
from pathlib import Path
import numpy as np
from PIL import Image
sys.path.insert(0, '/workspace/keeper_idle/tools')
from ingest_turnaround import to_game
from build_idles import defringe, apply_palette, is_blue
R = Path('/workspace/keeper_idle'); A = R / 'repo/assets/library/experiments/keeper_idle_4dir/v3_stills_8dir/option_a'
PAL = np.array(json.loads((A / 'palette.json').read_text())['colors'], np.int32)
STILL = {'front': 's', 'back': 'n', 'right': 'e'}
# The three Imagine walk sheets are drawn at different pixel sizes (and the back sheet with a bigger head : body ratio), so one
# number cannot fit all three: each sheet gets ONE scale calibrated to the matching Option A still.
CALIB = {'front': 'hmed', 'back': 'hmed', 'right': 'top_hem'}

def top_hem(rgba):
    op = rgba[..., 3] > 127; rows = np.nonzero(op.any(1))[0]; top = rows.min()
    bl = is_blue(rgba[..., :3].reshape(-1, 3).astype(int)).reshape(op.shape) & op
    br = np.nonzero(bl.sum(1) >= max(3, 0.01 * op.shape[1]))[0]
    return top, br.max(), rows.max()

def feet(g, cx):
    """leg-phase metrics in the bottom band: per side of the anchor x, lowest opaque row; plus band x-extent."""
    op = g[..., 3] > 0; sole = np.nonzero(op.any(1))[0].max(); band = op[sole - 9:sole + 1]
    xs = np.nonzero(band.any(0))[0]
    L = op[:, :int(cx)]; Rr = op[:, int(cx):]
    lowL = int(np.nonzero(L.any(1))[0].max()); lowR = int(np.nonzero(Rr.any(1))[0].max())
    return {'sole': int(sole), 'fx0': int(xs.min()), 'fx1': int(xs.max()), 'feet_cx': (xs.min() + xs.max()) / 2, 'lowL': lowL, 'lowR': lowR}

def run(name):
    w = R / 'walk/work' / name; srcs = sorted(w.glob('src_*.png'))
    crops = [np.array(Image.open(p)) for p in srcs]
    st = np.array(Image.open(A / f'keeper_still_{STILL[name]}.png'))
    t, h, sl = top_hem(st)
    if CALIB[name] == 'hmed':      # median walk-frame height = the still's height
        target = sl - t + 1; src = np.median([(lambda th: th[2] - th[0] + 1)(top_hem(c)) for c in crops])
    else:                          # 'top_hem': hair top -> coat hem, leg-independent (side sheet has no upright frame)
        target = h - t; src = np.median([(lambda th: th[1] - th[0])(top_hem(c)) for c in crops])
    scale = target / src
    smalls = []
    for c in crops:
        s = to_game(c[..., :3].astype(np.float32), c[..., 3] / 255.0, scale)
        smalls.append(s)
    # anchor
    info = []
    for s in smalls:
        op = s[..., 3] > 0; rows = np.nonzero(op.any(1))[0]; top, sole = rows.min(), rows.max()
        hb = op[top:top + int(0.5 * (sole - top))]; ys, xs = np.nonzero(hb)
        info.append((top, sole, xs.mean()))
    # first pass: place with anchor at 0 to measure feet offset relative to anchor
    rel = []
    for s, (top, sole, ax) in zip(smalls, info):
        op = s[..., 3] > 0; band = op[sole - 9:sole + 1]; xs = np.nonzero(band.any(0))[0]; rel.append((xs.min() + xs.max()) / 2 - ax)
    AX = 63.5 - float(np.mean(rel))          # anchor x so mean feet centre = 63.5
    frames = []; ph = []
    for i, (s, (top, sole, ax)) in enumerate(zip(smalls, info)):
        g = np.zeros((128, 128, 4), np.uint8); ox = int(round(AX - ax)); oy = 123 - sole
        hh, ww = s.shape[:2]; X0, Y0 = max(0, ox), max(0, oy); X1, Y1 = min(128, ox + ww), min(128, oy + hh)
        g[Y0:Y1, X0:X1] = s[Y0 - oy:Y1 - oy, X0 - ox:X1 - ox]
        g, nfr = defringe(g); g = apply_palette(g, PAL)
        Image.fromarray(g).save(w / f'g_{i:02d}.png'); frames.append(g)
        m = feet(g, AX); m.update({'i': i, 'top': int(np.nonzero(g[..., 3].any(1))[0].min()), 'height': 123 - int(np.nonzero(g[..., 3].any(1))[0].min()) + 1, 'defringed': nfr})
        ph.append(m)
    (w / 'phase.json').write_text(json.dumps({'scale': scale, 'calib': CALIB[name], 'calib_target': int(target), 'calib_src': float(src), 'anchor_x': AX, 'frames': ph}, indent=1))
    print(name, 'scale', round(scale, 4), 'AX', round(AX, 1))
    for m in ph: print(' ', m['i'], 'h', m['height'], 'feet', m['fx0'], m['fx1'], m['feet_cx'], 'lowL/R', m['lowL'], m['lowR'], 'def', m['defringed'])

if __name__ == '__main__':
    for n in sys.argv[1:]: run(n)
