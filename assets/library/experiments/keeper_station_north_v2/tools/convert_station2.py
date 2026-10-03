#!/usr/bin/env python3
"""Station work north v2 (generic, empty hands), video route: Imagine clip -> native 128x128 frames.
Same fixed transform as station v1 / the Option A N still (camera locked, feet planted): scale 120/348, video feet centre
edge x 336 -> canvas x 64, sole edge y 398 -> canvas y 124 (soles row 123). No bench in this clip, nothing to cut; any
non-Keeper component is dropped by keep-main and every frame is checked for objects afterwards.
Premultiplied BOX downscale -> hard alpha (>=50%) -> despeck -> defringe -> Option A palette (nearest Lab, 48 colours, no extras)
-> maroon-below-head -> dark brown -> keep main.  NO tool hue fix (it would grey the cyan rune; there is no tool).
usage: convert_station2.py first last"""
import sys, json
from pathlib import Path
import numpy as np
from PIL import Image
sys.path.insert(0, '/workspace/keeper_idle/tools'); sys.path.insert(0, '/workspace/keeper_idle/harv')
from ingest_turnaround import key
import convert_harv as C
from build_idles import apply_palette
R = Path('/workspace/keeper_idle'); S_ = R / 'station2'
SCALE = 120 / 348; FEET_V = 336.0; SOLE_V = 398.0; W = H = 128; FX = 64
PAL = np.array([list(c) for c in C.BASE], np.int32)

def keyed(i):
    rgb = np.array(Image.open(S_ / f'frames/g/f_{i:03d}.png').convert('RGB')); f, a, bg = key(rgb); return f, a

def native(i, pal=PAL):
    f, a = keyed(i)
    P = 120; pm = np.dstack([f * a[..., None], a * 255]).astype(np.float32); pm = np.pad(pm, ((P, P), (P, P), (0, 0)))
    x0 = FEET_V - FX / SCALE + P; y0 = SOLE_V - (H - 4) / SCALE + P; box = (x0, y0, x0 + W / SCALE, y0 + H / SCALE)
    ch = [np.array(Image.fromarray(pm[..., c]).resize((W, H), Image.BOX, box=box)) for c in range(4)]
    A_ = ch[3]; rgbo = np.dstack([np.where(A_ > 1, np.clip(ch[c] / np.maximum(A_, 1) * 255, 0, 255), 0) for c in range(3)])
    g = np.dstack([rgbo, np.where(A_ >= 128, 255, 0)]).astype(np.uint8); g[g[..., 3] == 0] = 0
    g = C.despeck(g); g, nf = C.defringe(g)
    if pal is not None:
        g = apply_palette(g, pal); g, nm = C.demaroon(g); g, nd = C.keep_main(g); g = C.despeck(g)
    else: nm = nd = 0
    return g, {'defringed': nf, 'maroon': nm, 'dropped': nd}

if __name__ == '__main__':
    first, last = int(sys.argv[1]), int(sys.argv[2])
    out = S_ / 'work'; out.mkdir(parents=True, exist_ok=True)
    log = json.loads((out / 'convert.json').read_text()) if (out / 'convert.json').exists() else {}
    for i in range(first, last + 1):
        g, info = native(i); Image.fromarray(g).save(out / f'g_{i:03d}.png')
        op = g[..., 3] > 0; rows = np.nonzero(op.any(1))[0]; cols = np.nonzero(op.any(0))[0]
        info.update(top=int(rows.min()), bottom=int(rows.max()), x0=int(cols.min()), x1=int(cols.max())); log[str(i)] = info
    (out / 'convert.json').write_text(json.dumps(log, indent=0))
    print({i: (v['top'], v['bottom'], v['x0'], v['x1'], v['dropped']) for i, v in log.items() if first <= int(i) <= last})
