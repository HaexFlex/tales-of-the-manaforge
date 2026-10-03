#!/usr/bin/env python3
"""Walk v5 hybrid (south): export walk5/assembled/{p55,p70} -> repo keeper_idle_4dir/walk_v5_hybrid/
  walk_south/            variant A (lift 55% of v3): frames, strip, json (durations_ms, anchor loop), x3 GIF
  variant_b_70/walk_south/  variant B (lift 70%)
  previews/  3-way x3 GIF (v3 | v4 | v5A), v5A vs v5B x3 GIF, contact sheet x2 (S still + A + B), leg zooms."""
import json, math, shutil, sys
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw
sys.path.insert(0, '/workspace/keeper_idle/tools')
from build_idles import gif, label, GRASS
R = Path('/workspace/keeper_idle'); BASE = R / 'repo/assets/library/experiments/keeper_idle_4dir'; OUT = BASE / 'walk_v5_hybrid'
A = BASE / 'v3_stills_8dir/option_a'; V3 = BASE / 'walk_v3_optA/walk_south'; V4 = BASE / 'walk_v4_casual/walk_south'
MS = [120, 125, 130, 125, 120, 125, 130, 125]      # contacts (v3 k0/k4) shortest, knee-lift peaks (k2/k6) longest; 1000 ms
VAR = {'A': ('p55', OUT), 'B': ('p70', OUT / 'variant_b_70')}
P = OUT / 'previews'; P.mkdir(parents=True, exist_ok=True)
frames = {}
for v, (tag, root) in VAR.items():
    src = R / f'walk5/assembled/{tag}'; b = json.loads((src / 'build.json').read_text())
    root.mkdir(parents=True, exist_ok=True); shutil.copy(A / 'palette.json', root / 'palette.json'); shutil.copy(A / 'palette.png', root / 'palette.png')
    dd = root / 'walk_south'; dd.mkdir(exist_ok=True)
    fr = [np.array(Image.open(src / f'walk_south_{k:04d}.png')) for k in range(8)]; frames[v] = fr; files = []
    for k, f in enumerate(fr):
        n = f'walk_south_{k:04d}.png'; Image.fromarray(f).save(dd / n); files.append(n)
    st = Image.new('RGBA', (128 * 8, 128)); [st.paste(Image.fromarray(f), (128 * k, 0)) for k, f in enumerate(fr)]; st.save(dd / 'walk_south.png')
    (dd / 'walk_south.json').write_text(json.dumps({'clip': 'walk_south', 'files': files, 'durations_ms': MS, 'loop_ms': sum(MS), 'hold_ms': round(sum(MS) / 8),
        'loop': True, 'anchor': 'loop', 'strip': 'walk_south.png', 'style': f'hybrid: v4 casual upper + v3 legs, lift {int(b["factor"] * 100)}% of v3',
        'build': b}, indent=1))
    gif(fr, dd / 'walk_south_x3.gif', scale=3, durations=MS)
# contact sheet x2: still + A row + B row
cw = 96; cs = Image.new('RGBA', (9 * cw, 2 * 128), GRASS)
for r, v in enumerate('AB'):
    cs.alpha_composite(Image.open(A / 'keeper_still_s.png').crop((16, 0, 112, 128)), (0, r * 128))
    for k in range(8): cs.alpha_composite(Image.fromarray(frames[v][k]).crop((16, 0, 112, 128)), ((k + 1) * cw, r * 128))
cs = cs.resize((cs.width * 2, cs.height * 2), Image.NEAREST); d_ = ImageDraw.Draw(cs)
b = json.loads((R / 'walk5/assembled/p55/build.json').read_text())['frames']
for r, v in enumerate('AB'):
    label(cs, 3, r * 256 + 3, 'still S (opt A)'); label(cs, 3, r * 256 + 18, f'v5{v} lift {55 if v == "A" else 70}%')
    for k in range(8): label(cs, (k + 1) * cw * 2 + 3, r * 256 + 3, f"{v}{k} arms v4k{b[k]['v4_frame']} legs v3k{b[k]['v3_frame']} {MS[k]}ms")
for x in range(1, 9): d_.line([(x * cw * 2, 0), (x * cw * 2, cs.height)], fill=(30, 30, 30, 255))
cs.save(P / 'walk_south_contact_x2.png')
# multi-way side-by-side on the LCM timeline
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
m3 = json.loads((V3 / 'walk_south.json').read_text()); m4 = json.loads((V4 / 'walk_south.json').read_text())
c3 = ('v3 march', [Image.open(V3 / f).convert('RGBA') for f in m3['files']], [m3['hold_ms']] * 8)
c4 = ('v4 casual', [Image.open(V4 / f).convert('RGBA') for f in m4['files']], m4['durations_ms'])
cA = ('v5A hybrid 55%', [Image.fromarray(f) for f in frames['A']], MS); cB = ('v5B hybrid 70%', [Image.fromarray(f) for f in frames['B']], MS)
print('3-way', sbs([c3, c4, cA], P / 'walk_south_v3_v4_v5_x3.gif')); print('A vs B', sbs([cA, cB], P / 'walk_south_v5A_vs_v5B_x3.gif'))
