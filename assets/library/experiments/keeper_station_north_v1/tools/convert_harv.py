#!/usr/bin/env python3
"""Harvest v3 (side, video route): video frames -> native frames on a 192 x H canvas (H=136 default), feet anchored.
ONE fixed transform per clip (camera locked, feet planted in the video: feet band x 310..377, soles row 395 in every frame):
  scale s = 119 / 344 (Option A E still height / standing body height in the video, same as walk_v3 E),
  video x 344 (feet centre edge) -> canvas x 96, video sole edge y 396 -> canvas y H-4 (soles on row H-5).
So there is no per-frame re-centring at all -> no drift, feet cannot slide, scale identical in all frames.
Per frame: key + isolate figure (drops chips/debris/floating berries) -> [pickaxe: subtract the static rock mask]
-> premultiplied BOX downscale (area) -> hard alpha (>=50%) -> despeck (<4 px islands) -> defringe -> tool hue fix
(Imagine's motion-blur tints the steel purple/teal on fast frames: saturated purple/teal -> neutral grey, same lightness)
-> palette = Option A 48 + tool extras (nearest Lab, no dither) -> maroon-below-head -> dark brown (as walk_v3).
usage: convert_harv.py ACT first last [H]"""
import sys, json
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage
sys.path.insert(0, '/workspace/keeper_idle/tools'); sys.path.insert(0, '/workspace/keeper_idle/harv')
from analyse_harvest import isolate
from build_idles import magenta_tint, apply_palette
from ingest_turnaround import key
R = Path('/workspace/keeper_idle'); H_ = R / 'harv'
A = R / 'repo/assets/library/experiments/keeper_idle_4dir/v3_stills_8dir/option_a'
BASE = np.array(json.loads((A / 'palette.json').read_text())['colors'], np.int32)[:, :3]
S = 119 / 344; FEET_V = 344.0; SOLE_V = 396.0; W = 192
EXTRA = json.loads((H_ / 'extra_colors.json').read_text())['colors'] if (H_ / 'extra_colors.json').exists() else []

def rock_mask():
    """the pickaxe clip's small rock: static component bottom-right, isolated in f48 -> mask (dilated 3 px)"""
    f, a, bg = key(np.array(Image.open(H_ / 'frames/pickaxe/f_048.png').convert('RGB')))
    m = a > 0.1; lab, n = ndimage.label(m, np.ones((3, 3))); out = np.zeros_like(m)
    for k in range(1, n + 1):
        ys, xs = np.nonzero(lab == k)
        if ys.max() >= 385 and xs.min() > 450 and len(ys) < 3000: out |= lab == k
    return ndimage.binary_dilation(out, np.ones((7, 7)))

def defringe(k):
    a = k.copy(); op = a[..., 3] > 0; bad = op & magenta_tint(a[..., :3]); n = int(bad.sum()); good = op & ~bad
    h, w = op.shape
    for y, x in zip(*np.nonzero(bad)):
        y0, y1, x0, x1 = max(0, y - 2), min(h, y + 3), max(0, x - 2), min(w, x + 3)
        nb = a[y0:y1, x0:x1][good[y0:y1, x0:x1]][:, :3].astype(float)
        if not len(nb): a[y, x, :3] = a[y, x, :3].mean(); continue
        ref = np.median(nb, 0); lum = a[y, x, :3].astype(float).mean(); rl = max(ref.mean(), 1)
        a[y, x, :3] = np.clip(ref * min(lum / rl, 1.0), 0, 255).astype(np.uint8)
    return a, n

def hsv(rgb):
    p = rgb.astype(float); mx = p.max(-1); mn = p.min(-1); c = mx - mn
    r, g, b = p[..., 0], p[..., 1], p[..., 2]
    with np.errstate(divide='ignore', invalid='ignore'):
        h = np.where(mx == r, ((g - b) / c) % 6, np.where(mx == g, (b - r) / c + 2, (r - g) / c + 4)) * 60
    return np.nan_to_num(h), np.where(mx > 0, c / np.maximum(mx, 1), 0), mx

def tool_hue_fix(g, tools=True):
    """medium/bright purple (hue 255..335) and teal (148..200) -> neutral grey of the same mean lightness.
    The Keeper has no purple, and in the side view no cyan, so this only touches tinted steel / blur."""
    h, s, v = hsv(g[..., :3]); op = g[..., 3] > 0
    purple = (h >= 255) & (h <= 335) & (s > 0.2) & (v >= 100)
    teal = (h >= 148) & (h <= 200) & (s > 0.2) & (s < 0.78) & (v >= 110)     # hair greens are s > .8 (and hue < 140)
    steel_blue = (h > 200) & (h < 255) & (s > 0.2) & (s < 0.62) & (v >= 110)  # coat blues are s > .85 (shadow 61,78,98 has v < 100)
    bad = op & (purple | teal | steel_blue)                    # dark outline pixels (v < 100) are left to the palette, as in walk_v3
    out = g.copy(); lum = g[..., :3].astype(float).mean(-1)
    out[bad, :3] = np.clip(lum[bad, None] * np.array([0.97, 1.0, 1.04]), 0, 255).astype(np.uint8)
    n = int(bad.sum())
    if tools:   # blurred handle turns pink/red (hue >= 330 or <= 12, sat > .35, v >= 90) -> wood brown of the same lightness
        pink = op & ~bad & ((h >= 330) | (h <= 12)) & (s > 0.35) & (v >= 90)
        out[pink, :3] = np.clip(lum[pink, None] * np.array([1.55, 0.9, 0.42]), 0, 255).astype(np.uint8); n += int(pink.sum())
    return out, n

def despeck(s, min_px=4):
    op = s[..., 3] > 0; lab, n = ndimage.label(op, np.ones((3, 3)))
    if n <= 1: return s
    area = ndimage.sum(op, lab, np.arange(1, n + 1)); keep = np.isin(lab, 1 + np.nonzero(area >= min_px)[0])
    s = s.copy(); s[~keep] = 0; return s

def keep_main(s):
    """keep the largest opaque component + parts within 2 px of it (tool pieces), drop the rest"""
    op = s[..., 3] > 0; lab, n = ndimage.label(op, np.ones((3, 3)))
    if n <= 1: return s, 0
    area = ndimage.sum(op, lab, np.arange(1, n + 1)); big = lab == 1 + int(np.argmax(area))
    near = ndimage.binary_dilation(big, np.ones((5, 5))); ids = np.unique(lab[near & op]); keep = np.isin(lab, ids[ids > 0])
    s = s.copy(); dropped = int((op & ~keep).sum()); s[~keep] = 0; return s, dropped

MAROON, DARK_BROWN = (80, 21, 33), (54, 26, 12)
def demaroon(g, below=40):
    out = g.copy(); op = g[..., 3] > 0; t = int(np.nonzero(op.any(1))[0].min())
    m = (g[..., :3] == MAROON).all(-1) & op; m[:t + below] = False; out[m, :3] = DARK_BROWN; return out, int(m.sum())

def palette_for(act):
    """Option A 48 + only the extras this action needs: axe/pickaxe -> 3 iron greys, berries -> 2 berry reds"""
    ex = EXTRA[3:5] if act.startswith('berries') else EXTRA[0:3]
    return np.array([list(c) for c in BASE] + [list(c) for c in ex], np.int32)

def native(act, i, H=136, rock=None, pal=None):
    rgb = np.array(Image.open(H_ / f'frames/{act}/f_{i:03d}.png').convert('RGB'))
    f, a, bg, keep = isolate(rgb)
    if rock is not None:
        a = a * ~rock
        m = a > 0.5; lab, n = ndimage.label(m, np.ones((3, 3)))       # re-isolate: rock leftovers / cut bits
        if n > 1:
            area = ndimage.sum(m, lab, np.arange(1, n + 1)); big = lab == 1 + int(np.argmax(area))
            near = ndimage.binary_dilation(big, np.ones((9, 9))); ids = np.unique(lab[near & m]); kk = np.isin(lab, ids[ids > 0])
            a = a * ndimage.binary_dilation(kk, np.ones((5, 5)))
    P = 120; pm = np.dstack([f * a[..., None], a * 255]).astype(np.float32); pm = np.pad(pm, ((P, P), (P, P), (0, 0)))
    x0 = FEET_V - 96 / S + P; y0 = SOLE_V - (H - 4) / S + P; box = (x0, y0, x0 + W / S, y0 + H / S)
    ch = [np.array(Image.fromarray(pm[..., c]).resize((W, H), Image.BOX, box=box)) for c in range(4)]
    A_ = ch[3]; rgbo = np.dstack([np.where(A_ > 1, np.clip(ch[c] / np.maximum(A_, 1) * 255, 0, 255), 0) for c in range(3)])
    g = np.dstack([rgbo, np.where(A_ >= 128, 255, 0)]).astype(np.uint8); g[g[..., 3] == 0] = 0
    g = despeck(g); g, nf = defringe(g)
    if act.startswith('berries'): nh = 0                     # no tool -> no steel hue fix (it would grey blurred sleeve pixels)
    else: g, nh = tool_hue_fix(g)
    if pal is not None:
        g = apply_palette(g, pal); g, nm = demaroon(g); g, nd = keep_main(g); g = despeck(g)
    else: nm = nd = 0
    return g, {'defringed': nf, 'hue_fixed': nh, 'maroon': nm, 'dropped': nd}

if __name__ == '__main__':
    act, first, last = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]); H = int(sys.argv[4]) if len(sys.argv) > 4 else 136
    pal = palette_for(act)
    rock = rock_mask() if act.startswith('pickaxe') else None
    out = H_ / f'work/{act}'; out.mkdir(parents=True, exist_ok=True); log = {}
    for i in range(first, last + 1):
        g, info = native(act, i, H, rock, pal); Image.fromarray(g).save(out / f'g_{i:03d}.png')
        op = g[..., 3] > 0; rows = np.nonzero(op.any(1))[0]; cols = np.nonzero(op.any(0))[0]
        info.update(top=int(rows.min()), bottom=int(rows.max()), x0=int(cols.min()), x1=int(cols.max())); log[i] = info
    (out / 'convert.json').write_text(json.dumps(log, indent=0))
    print(act, {i: (v['top'], v['bottom'], v['x0'], v['x1'], v['hue_fixed']) for i, v in log.items()})
