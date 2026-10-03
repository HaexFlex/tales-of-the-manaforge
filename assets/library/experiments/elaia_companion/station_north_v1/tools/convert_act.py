#!/usr/bin/env python3
"""Elaia harvest/station (video route): video frames -> native frames on a fixed canvas, ONE fixed transform per clip
(camera locked, feet planted): scale S = 115/334 (Elaia E/N still height / standing body height in these clips, same as
walk E), video feet-centre edge FX -> canvas x CX, video sole edge SY -> canvas y CY (soles on row CY-1).
Per frame: key -> isolate figure (largest component + parts within DIL px; water: + free stream dashes) -> premultiplied BOX
downscale -> hard alpha (>=50%) -> despeck -> defringe (Elaia violet band) -> palette (Elaia 40; water: stream pixels only
-> 3 water tones) -> keep main + attached parts. Optional per-frame sole snap (lowest feet-band pixel -> row CY-1)."""
import sys, json
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage
sys.path.insert(0, '/workspace/keeper_idle/tools'); sys.path.insert(0, '/workspace/elaia_anims')
from ingest_turnaround import key
from build_idles import apply_palette
from ingest_elaia import defringe
R = Path('/workspace/elaia_anims'); HV = R / 'harv'
PAL = np.array(json.loads((R / 'stills/palette.json').read_text())['colors'], np.int32)
WATER = np.array([[44, 118, 214], [64, 196, 240], [150, 240, 252]], np.int32)
S = 115 / 334

def isolate(f, a, dil=4, water=False, drop_boxes=()):
    m = a > 0.5
    for (x0, y0, x1, y1) in drop_boxes: m[y0:y1, x0:x1] = False
    lab, n = ndimage.label(m, np.ones((3, 3))); area = ndimage.sum(m, lab, np.arange(1, n + 1)); big = lab == 1 + int(np.argmax(area))
    near = ndimage.binary_dilation(big, np.ones((2 * dil + 1, 2 * dil + 1))); ids = np.unique(lab[near & m]); keep = np.isin(lab, ids[ids > 0])
    if water:
        st = stream_mask(f) & m; lab2, n2 = ndimage.label(st, np.ones((3, 3)))
        for k in range(1, n2 + 1):
            if (lab2 == k).sum() >= 6: keep |= np.isin(lab, np.unique(lab[lab2 == k]))
    soft = ndimage.binary_dilation(keep, np.ones((3, 3)))
    return a * soft

def stream_mask(rgb):
    r, g, b = [rgb[..., c].astype(int) for c in range(3)]
    return (g >= 150) & (b >= 170) & (r <= 120) & (g - r >= 90)

def native(act, i, W, H, FX, SY, CX, CY, dil=4, water=False, drop_boxes=(), water_x0=None, water_y0=None):
    rgb = np.array(Image.open(HV / f'frames/{act}/f_{i:03d}.png').convert('RGB'))
    f, a, bg = key(rgb); a = isolate(f, a, dil, water, drop_boxes)
    P = 200; pm = np.dstack([f * a[..., None], a * 255]).astype(np.float32); pm = np.pad(pm, ((P, P), (P, P), (0, 0)))
    x0 = FX - CX / S + P; y0 = SY - CY / S + P; box = (x0, y0, x0 + W / S, y0 + H / S)
    ch = [np.array(Image.fromarray(pm[..., c]).resize((W, H), Image.BOX, box=box)) for c in range(4)]
    A_ = ch[3]; rgbo = np.dstack([np.where(A_ > 1, np.clip(ch[c] / np.maximum(A_, 1) * 255, 0, 255), 0) for c in range(3)])
    g = np.dstack([rgbo, np.where(A_ >= 128, 255, 0)]).astype(np.uint8); g[g[..., 3] == 0] = 0
    g = despeck(g); g, nf = defringe(g)
    if water:   # stream pixels (saturated cyan, right of water_x0) -> water tones only; everything else -> Elaia palette
        wm = stream_mask(g) & (g[..., 3] > 0)
        if water_x0 is not None: wm[:, :water_x0] = False
        if water_y0 is not None: wm[:water_y0] = False
        q1 = apply_palette(g, PAL); q2 = apply_palette(g, WATER); g = np.where(wm[..., None], q2, q1)
    else:
        g = apply_palette(g, PAL)
    g = keep_main(g); g = despeck(g)
    return g, {'defringed': nf}

def despeck(s, min_px=4):
    op = s[..., 3] > 0; lab, n = ndimage.label(op, np.ones((3, 3)))
    if n <= 1: return s
    area = ndimage.sum(op, lab, np.arange(1, n + 1)); keep = np.isin(lab, 1 + np.nonzero(area >= min_px)[0])
    s = s.copy(); s[~keep] = 0; return s

def keep_main(s, water_ok=True):
    op = s[..., 3] > 0; lab, n = ndimage.label(op, np.ones((3, 3)))
    if n <= 1: return s
    area = ndimage.sum(op, lab, np.arange(1, n + 1)); big = lab == 1 + int(np.argmax(area))
    near = ndimage.binary_dilation(big, np.ones((5, 5))); ids = np.unique(lab[near & op]); keep = np.isin(lab, ids[ids > 0])
    wt = np.zeros(op.shape, bool)
    for c in WATER: wt |= (s[..., :3] == c).all(-1)
    lab2, n2 = ndimage.label(op & wt, np.ones((3, 3)))   # free stream pieces (>= 3 px, water colours only) are kept
    for k in range(1, n2 + 1):
        if (lab2 == k).sum() >= 3: keep |= lab2 == k
    s = s.copy(); s[~keep] = 0; return s

def run(act, frames, W, H, FX, SY, CX, CY, out, **kw):
    out = Path(out); out.mkdir(parents=True, exist_ok=True); log = {}
    for i in frames:
        g, info = native(act, i, W, H, FX, SY, CX, CY, **kw); Image.fromarray(g).save(out / f'g_{i:03d}.png')
        op = g[..., 3] > 0; rows = np.nonzero(op.any(1))[0]; cols = np.nonzero(op.any(0))[0]
        info.update(top=int(rows.min()), bottom=int(rows.max()), x0=int(cols.min()), x1=int(cols.max())); log[i] = info
    (out / 'convert.json').write_text(json.dumps({'scale': S, 'canvas': [W, H], 'feet_video': [FX, SY], 'feet_canvas': [CX, CY], 'frames': log}, indent=0))
    return log
