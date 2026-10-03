#!/usr/bin/env python3
"""Station work (north, from behind), video route: Imagine clip -> native 128x128 frames, bench removed.
Fixed transform (camera locked, feet planted): scale 120/348 (Option A N still height / standing bbox height in f1),
video feet centre edge x 336 -> canvas x 64, sole edge y 398 -> canvas y 124 (soles row 123), like walk_v3 / the stills.
Bench removal (video px, before the downscale):
  * plank band rows 236..263 (static plank 239..261 in every frame): keep only the coat's blue run around the body centre
    (+-3 px outline) - everything outside it in those rows is plank/items behind him -> transparent;
  * paper/items: near-white px (min RGB > 170, sat < .25) in rows 200..263 -> transparent (the Keeper has no white below the head
    from behind; the gap between torso and raised arm then shows background, which is correct: the bench is gone);
  * then keep the largest component + parts within 4 px (the held hammer).
Then premultiplied BOX downscale -> hard alpha (>=50%) -> despeck -> defringe -> hammer hue fix (convert_harv.tool_hue_fix:
blur tints purple/teal/pink -> grey/wood) -> Option A palette (+ iron extras for the hammer head) -> maroon-below-head -> dark brown.
usage: convert_station.py CLIP first last"""
import sys, json
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage
sys.path.insert(0, '/workspace/keeper_idle/tools'); sys.path.insert(0, '/workspace/keeper_idle/harv')
from ingest_turnaround import key
import convert_harv as C
from build_idles import apply_palette
R = Path('/workspace/keeper_idle'); S_ = R / 'station'
SCALE = 120 / 348; FEET_V = 336.0; SOLE_V = 398.0; W = H = 128; FX = 64
BAND = (236, 264)
EXTRA = json.loads((S_ / 'extra_colors.json').read_text())['colors'] if (S_ / 'extra_colors.json').exists() else []
PAL = np.array([list(c) for c in C.BASE] + EXTRA, np.int32)
STILL = np.array(Image.open(R / 'repo/assets/library/experiments/keeper_idle_4dir/v3_stills_8dir/option_a/keeper_still_n.png').convert('RGBA'))
# hammer hue fix only outside the still's torso/legs (eroded 3 px): the cyan rune on the coat back must stay cyan
BODY_CORE = ndimage.binary_erosion(STILL[..., 3] > 0, np.ones((7, 7)))

def debench(f, a):
    m = a > 0.5; r, g, b = f[..., 0].astype(int), f[..., 1].astype(int), f[..., 2].astype(int)
    blue = m & (b > r + 30) & (b > g)
    kill = np.zeros_like(m); runs = {}
    for y in range(*BAND):
        row = blue[y]; xs = np.nonzero(row)[0]
        if not len(xs): kill[y] = m[y]; continue
        # runs of blue (gaps <= 40 px bridged: dark outline / the cyan rune in the middle of the back), pick the one containing /
        # nearest the body centre
        lab, n = ndimage.label(ndimage.binary_closing(np.pad(row, 40), np.ones(41))[40:-40])
        best = None
        for k in range(1, n + 1):
            xx = np.nonzero(lab == k)[0]; d = 0 if xx.min() <= FEET_V <= xx.max() else min(abs(xx.min() - FEET_V), abs(xx.max() - FEET_V))
            if best is None or d < best[0] or (d == best[0] and len(xx) > best[1]): best = (d, len(xx), xx.min(), xx.max())
        x0, x1 = best[2] - 3, best[3] + 3; runs[y] = (int(x0), int(x1))
        k_ = m[y].copy(); k_[max(0, x0):x1 + 1] = False; kill[y] = k_
    mn = np.minimum(np.minimum(r, g), b); mx = np.maximum(np.maximum(r, g), b)
    white = m & (mn > 170) & ((mx - mn) < 0.25 * np.maximum(mx, 1)); white[:200] = False; white[264:] = False
    kill |= white
    a2 = a * ~kill; mm = a2 > 0.5
    lab, n = ndimage.label(mm, np.ones((3, 3)))
    if n > 1:
        area = ndimage.sum(mm, lab, np.arange(1, n + 1)); big = lab == 1 + int(np.argmax(area))
        near = ndimage.binary_dilation(big, np.ones((9, 9))); ids = np.unique(lab[near & mm]); keep = np.isin(lab, ids[ids > 0])
        a2 = a2 * ndimage.binary_dilation(keep, np.ones((3, 3)))
    return a2, int(kill.sum()), runs

def native(clip, i, pal=PAL):
    rgb = np.array(Image.open(S_ / f'frames/{clip}/f_{i:03d}.png').convert('RGB'))
    f, a, bg = key(rgb); a, nk, runs = debench(f, a)
    P = 120; pm = np.dstack([f * a[..., None], a * 255]).astype(np.float32); pm = np.pad(pm, ((P, P), (P, P), (0, 0)))
    x0 = FEET_V - FX / SCALE + P; y0 = SOLE_V - (H - 4) / SCALE + P; box = (x0, y0, x0 + W / SCALE, y0 + H / SCALE)
    ch = [np.array(Image.fromarray(pm[..., c]).resize((W, H), Image.BOX, box=box)) for c in range(4)]
    A_ = ch[3]; rgbo = np.dstack([np.where(A_ > 1, np.clip(ch[c] / np.maximum(A_, 1) * 255, 0, 255), 0) for c in range(3)])
    g = np.dstack([rgbo, np.where(A_ >= 128, 255, 0)]).astype(np.uint8); g[g[..., 3] == 0] = 0
    g = C.despeck(g); g, nf = C.defringe(g); h_, _ = C.tool_hue_fix(g); z = ~BODY_CORE & (h_ != g).any(-1); nh = int(z.sum()); g[z] = h_[z]
    if pal is not None:
        g = apply_palette(g, pal); g, nm = C.demaroon(g); g, nd = C.keep_main(g); g = C.despeck(g)
    else: nm = nd = 0
    return g, {'bench_px_removed_video': nk, 'defringed': nf, 'hue_fixed': nh, 'maroon': nm, 'dropped': nd}

if __name__ == '__main__':
    clip, first, last = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
    out = S_ / f'work/{clip}'; out.mkdir(parents=True, exist_ok=True); log = {}
    for i in range(first, last + 1):
        g, info = native(clip, i); Image.fromarray(g).save(out / f'g_{i:03d}.png')
        op = g[..., 3] > 0; rows = np.nonzero(op.any(1))[0]; cols = np.nonzero(op.any(0))[0]
        info.update(top=int(rows.min()), bottom=int(rows.max()), x0=int(cols.min()), x1=int(cols.max())); log[i] = info
    (out / 'convert.json').write_text(json.dumps(log, indent=0))
    print(clip, {i: (v['top'], v['bottom'], v['x0'], v['x1'], v['hue_fixed']) for i, v in log.items()})
