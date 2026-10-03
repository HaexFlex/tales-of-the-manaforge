#!/usr/bin/env python3
"""Walk v5 NORTH export -> walk_v5_hybrid/walk_north/ (frames, strip, json, x3 GIF) + previews:
directions side-by-side x3 (S v5A | N v5 | E = walk_v3 march, reference only), contact sheet x2 (still + 8 frames for S v5A and N v5)."""
import json, math, shutil, sys
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw
sys.path.insert(0, '/workspace/keeper_idle/tools'); sys.path.insert(0, '/workspace/keeper_idle/walk5')
from build_idles import gif, label, GRASS
import math
def sbs(clips, out):
    Ls = [sum(d) for _, _, d in clips]; T = 1
    for L in Ls: T = T * L // math.gcd(T, L)
    def idx(t, d):
        t %= sum(d); acc = 0
        for k, v in enumerate(d):
            acc += v
            if t < acc: return k
    cuts = set()
    for (_, _, d), L in zip(clips, Ls):
        for n in range(T // L):
            for k in range(len(d)): cuts.add(n * L + sum(d[:k]))
    cuts = sorted(cuts) + [T]; fr, du, cache = [], [], {}
    for t0, t1 in zip(cuts, cuts[1:]):
        key = tuple(idx(t0, d) for _, _, d in clips)
        if key not in cache:
            c = Image.new('RGB', (len(clips) * 294, 128 * 3 + 18), (24, 24, 24)); dr = ImageDraw.Draw(c)
            for n, ((name, F, d), i) in enumerate(zip(clips, key)):
                bb = Image.new('RGB', (96, 128), GRASS[:3]); cr = F[i].crop((16, 0, 112, 128)); bb.paste(cr, (0, 0), cr)
                c.paste(bb.resize((288, 384), Image.NEAREST), (n * 294, 18)); dr.text((n * 294 + 4, 3), f'{name} {i} ({d[i]}ms)', fill=(255, 255, 255))
            cache[key] = c
        if fr and fr[-1] is cache[key]: du[-1] += t1 - t0
        else: fr.append(cache[key]); du.append(t1 - t0)
    fr[0].save(out, save_all=True, append_images=fr[1:], duration=du, loop=0, disposal=1); return T, len(fr)
R = Path('/workspace/keeper_idle'); BASE = R / 'repo/assets/library/experiments/keeper_idle_4dir'; OUT = BASE / 'walk_v5_hybrid'
A = BASE / 'v3_stills_8dir/option_a'; MS = [120, 125, 130, 125, 120, 125, 130, 125]
src = R / 'walk6/assembled/north'; b = json.loads((src / 'build.json').read_text())
dd = OUT / 'walk_north'; dd.mkdir(parents=True, exist_ok=True)
fr = [np.array(Image.open(src / f'walk_north_{k:04d}.png')) for k in range(8)]; files = []
for k, f in enumerate(fr):
    n = f'walk_north_{k:04d}.png'; Image.fromarray(f).save(dd / n); files.append(n)
st = Image.new('RGBA', (128 * 8, 128)); [st.paste(Image.fromarray(f), (128 * k, 0)) for k, f in enumerate(fr)]; st.save(dd / 'walk_north.png')
(dd / 'walk_north.json').write_text(json.dumps({'clip': 'walk_north', 'files': files, 'durations_ms': MS, 'loop_ms': sum(MS), 'hold_ms': 125, 'loop': True,
    'anchor': 'loop', 'strip': 'walk_north.png', 'style': 'v5: walk_v3 north legs with lift 55%, v3 back arms (already opposite the legs, amplitude ~ south v5A), head lock', 'build': b}, indent=1))
gif(fr, dd / 'walk_north_x3.gif', scale=3, durations=MS)
P = OUT / 'previews'
S = [Image.open(OUT / f'walk_south/walk_south_{k:04d}.png').convert('RGBA') for k in range(8)]
N = [Image.fromarray(f) for f in fr]
E3 = [Image.open(BASE / f'walk_v3_optA/walk_east/walk_east_{k:04d}.png').convert('RGBA') for k in range(8)]
print('dirs', sbs([('S v5A (final)', S, MS), ('N v5', N, MS), ('E = v3 march, NOT v5 (pending video)', E3, [100] * 8)], P / 'walk_v5_directions_S_N_E_x3.gif'))
print('S|N', sbs([('S v5A (final)', S, MS), ('N v5', N, MS)], P / 'walk_v5_S_N_x3.gif'))
cw = 96; cs = Image.new('RGBA', (9 * cw, 2 * 128), GRASS)
for r, (still, F, nm) in enumerate((('s', S, 'S v5A'), ('n', N, 'N v5'))):
    cs.alpha_composite(Image.open(A / f'keeper_still_{still}.png').crop((16, 0, 112, 128)), (0, r * 128))
    for k in range(8): cs.alpha_composite(F[k].crop((16, 0, 112, 128)), ((k + 1) * cw, r * 128))
cs = cs.resize((cs.width * 2, cs.height * 2), Image.NEAREST); d_ = ImageDraw.Draw(cs)
for r, nm in enumerate(('S v5A', 'N v5')):
    label(cs, 3, r * 256 + 3, f'still {nm[0]} (opt A)')
    for k in range(8): label(cs, (k + 1) * cw * 2 + 3, r * 256 + 3, f'{nm} {k} {MS[k]}ms')
for x in range(1, 9): d_.line([(x * cw * 2, 0), (x * cw * 2, cs.height)], fill=(30, 30, 30, 255))
cs.save(P / 'walk_v5_S_N_contact_x2.png'); print('ok')
