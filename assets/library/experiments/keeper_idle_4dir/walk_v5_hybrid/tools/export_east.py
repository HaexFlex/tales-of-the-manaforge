#!/usr/bin/env python3
"""Walk v5 EAST (casual side clip) + WEST (mirror) export -> walk_v5_hybrid/walk_east/, walk_west/ (frames, strip, json,
x3 GIF) + previews: 4-direction side-by-side x3 (S v5A | N v5 | E v5 | W v5), contact sheet x2 (still + 8 frames, 4 rows)."""
import json, math, sys
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw
sys.path.insert(0, '/workspace/keeper_idle/tools')
from build_idles import gif, label, GRASS
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
b = json.loads((R / 'walk7/assembled/east/build.json').read_text())
STYLE = {'east': 'v5: own legs + arms from keeper_walk_casual_east.mp4 (relaxed side walk), per-step bob 0/1/2/1, swing boots raised to 5 px, head + mane lock',
         'west': 'v5: exact horizontal mirror of walk_east (x -> 127 - x)'}
clips = {}
for dname in ('east', 'west'):
    src = R / f'walk7/assembled/{dname}'; dd = OUT / f'walk_{dname}'; dd.mkdir(parents=True, exist_ok=True)
    fr = [np.array(Image.open(src / f'walk_{dname}_{k:04d}.png')) for k in range(8)]; files = []
    for k, f in enumerate(fr):
        n = f'walk_{dname}_{k:04d}.png'; Image.fromarray(f).save(dd / n); files.append(n)
    st = Image.new('RGBA', (128 * 8, 128)); [st.paste(Image.fromarray(f), (128 * k, 0)) for k, f in enumerate(fr)]; st.save(dd / f'walk_{dname}.png')
    (dd / f'walk_{dname}.json').write_text(json.dumps({'clip': f'walk_{dname}', 'files': files, 'durations_ms': MS, 'loop_ms': sum(MS), 'hold_ms': 125,
        'loop': True, 'anchor': 'loop', 'strip': f'walk_{dname}.png', 'style': STYLE[dname],
        'suggested_move_speed_px_s': 80, 'build': b if dname == 'east' else {'mirror_of': 'walk_east'}}, indent=1))
    gif(fr, dd / f'walk_{dname}_x3.gif', scale=3, durations=MS); clips[dname] = [Image.fromarray(f) for f in fr]
P = OUT / 'previews'
S = [Image.open(OUT / f'walk_south/walk_south_{k:04d}.png').convert('RGBA') for k in range(8)]
N = [Image.open(OUT / f'walk_north/walk_north_{k:04d}.png').convert('RGBA') for k in range(8)]
E, Wf = clips['east'], clips['west']
print('dirs', sbs([('S v5A', S, MS), ('N v5', N, MS), ('E v5', E, MS), ('W v5', Wf, MS)], P / 'walk_v5_directions_S_N_E_W_x3.gif'))
print('E|W', sbs([('E v5', E, MS), ('W v5', Wf, MS)], P / 'walk_v5_E_W_x3.gif'))
rows = (('s', S, 'S v5A'), ('n', N, 'N v5'), ('e', E, 'E v5'), ('w', Wf, 'W v5'))
cw = 96; cs = Image.new('RGBA', (9 * cw, len(rows) * 128), GRASS)
for r, (still, F, nm) in enumerate(rows):
    sp = A / f'keeper_still_{still}.png'
    st_ = Image.open(sp).convert('RGBA') if sp.exists() else Image.fromarray(np.ascontiguousarray(np.array(Image.open(A / 'keeper_still_e.png').convert('RGBA'))[:, ::-1]))
    cs.alpha_composite(st_.crop((16, 0, 112, 128)), (0, r * 128))
    for k in range(8): cs.alpha_composite(F[k].crop((16, 0, 112, 128)), ((k + 1) * cw, r * 128))
cs = cs.resize((cs.width * 2, cs.height * 2), Image.NEAREST); d_ = ImageDraw.Draw(cs)
for r, (still, _, nm) in enumerate(rows):
    label(cs, 3, r * 256 + 3, f'still {still.upper()} (opt A)')
    for k in range(8): label(cs, (k + 1) * cw * 2 + 3, r * 256 + 3, f'{nm} {k} {MS[k]}ms')
for x in range(1, 9): d_.line([(x * cw * 2, 0), (x * cw * 2, cs.height)], fill=(30, 30, 30, 255))
for y in range(1, len(rows)): d_.line([(0, y * 256), (cs.width, y * 256)], fill=(30, 30, 30, 255))
cs.save(P / 'walk_v5_S_N_E_W_contact_x2.png'); print('ok')
