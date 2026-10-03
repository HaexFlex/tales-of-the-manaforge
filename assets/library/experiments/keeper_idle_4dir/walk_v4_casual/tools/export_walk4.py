#!/usr/bin/env python3
"""Walk v4 casual (south only): export walk4/assembled -> repo keeper_idle_4dir/walk_v4_casual/:
walk_south/ frames + strip + json (check_frames walk format, per-frame durations_ms) + x3 GIF;
previews/ contact sheet (S still + 8 frames, x2), v3 march vs v4 casual side-by-side x3 GIF (LCM timeline, both seamless)."""
import json, math, shutil, sys
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw
sys.path.insert(0, '/workspace/keeper_idle/tools')
from build_idles import gif, label, GRASS
R = Path('/workspace/keeper_idle'); REPO = R / 'repo'
BASE = REPO / 'assets/library/experiments/keeper_idle_4dir'; OUT = BASE / 'walk_v4_casual'; A = BASE / 'v3_stills_8dir/option_a'
V3 = BASE / 'walk_v3_optA/walk_south'
asm = json.loads((R / 'walk4/assembled/assembly.json').read_text()); MS = asm['ms']
OUT.mkdir(parents=True, exist_ok=True); shutil.copy(A / 'palette.json', OUT / 'palette.json'); shutil.copy(A / 'palette.png', OUT / 'palette.png')
P = OUT / 'previews'; P.mkdir(exist_ok=True); dd = OUT / 'walk_south'; dd.mkdir(exist_ok=True)
fr = [np.array(Image.open(R / f'walk4/assembled/walk_south_{k:04d}.png')) for k in range(8)]
files = []
for k, f in enumerate(fr):
    n = f'walk_south_{k:04d}.png'; Image.fromarray(f).save(dd / n); files.append(n)
strip = Image.new('RGBA', (128 * 8, 128)); [strip.paste(Image.fromarray(f), (128 * k, 0)) for k, f in enumerate(fr)]; strip.save(dd / 'walk_south.png')
(dd / 'walk_south.json').write_text(json.dumps({'clip': 'walk_south', 'files': files, 'durations_ms': MS, 'loop_ms': sum(MS), 'hold_ms': round(sum(MS) / len(MS)),
    'loop': True, 'anchor': 'loop', 'strip': 'walk_south.png', 'style': 'casual', 'assembly': asm}, indent=1))
gif(fr, dd / 'walk_south_x3.gif', scale=3, durations=MS)
# contact sheet x2: S still + 8 frames
cw = 96; cs = Image.new('RGBA', (9 * cw, 128), GRASS)
cs.alpha_composite(Image.open(A / 'keeper_still_s.png').crop((16, 0, 112, 128)), (0, 0))
for k in range(8): cs.alpha_composite(Image.fromarray(fr[k]).crop((16, 0, 112, 128)), ((k + 1) * cw, 0))
cs = cs.resize((cs.width * 2, cs.height * 2), Image.NEAREST); d_ = ImageDraw.Draw(cs)
label(cs, 3, 3, 'still S (opt A)')
for k in range(8): label(cs, (k + 1) * cw * 2 + 3, 3, f"S{k} f{asm['video_frames_1based'][k]} b{asm['bob_px'][k]} {MS[k]}ms")
for x in range(1, 9): d_.line([(x * cw * 2, 0), (x * cw * 2, cs.height)], fill=(30, 30, 30, 255))
cs.save(P / 'walk_south_contact_x2.png')
# side-by-side x3: walk_v3 march (100 ms x 8) vs walk_v4 casual (per-frame ms), LCM timeline
m3 = json.loads((V3 / 'walk_south.json').read_text()); Fa = [Image.open(V3 / f).convert('RGBA') for f in m3['files']]; da = [m3['hold_ms']] * len(Fa)
Fb = [Image.fromarray(f) for f in fr]; db = MS
La, Lb = sum(da), sum(db); T = La * Lb // math.gcd(La, Lb)
def idx_at(t, d):
    t %= sum(d); acc = 0
    for k, v in enumerate(d):
        acc += v
        if t < acc: return k
cuts = sorted(set([n * La + sum(da[:k]) for n in range(T // La) for k in range(len(da))] + [n * Lb + sum(db[:k]) for n in range(T // Lb) for k in range(len(db))])) + [T]
frames, durs, cache = [], [], {}
for t0, t1 in zip(cuts, cuts[1:]):
    ia, ib = idx_at(t0, da), idx_at(t0, db); key = (ia, ib)
    if key not in cache:
        c = Image.new('RGB', (96 * 2 * 3 + 6, 128 * 3 + 18), (24, 24, 24)); d = ImageDraw.Draw(c)
        for n, (im, lab) in enumerate([(Fa[ia], f'v3 march {ia} ({da[ia]}ms, loop {La}ms)'), (Fb[ib], f'v4 casual {ib} ({db[ib]}ms, loop {Lb}ms)')]):
            b = Image.new('RGB', (96, 128), GRASS[:3]); cr = im.crop((16, 0, 112, 128)); b.paste(cr, (0, 0), cr)
            c.paste(b.resize((288, 384), Image.NEAREST), (n * 294, 18)); d.text((n * 294 + 4, 3), lab, fill=(255, 255, 255))
        cache[key] = c
    if frames and frames[-1] is cache[key]: durs[-1] += t1 - t0
    else: frames.append(cache[key]); durs.append(t1 - t0)
sb = P / 'walk_south_v3_march_vs_v4_casual_x3.gif'
frames[0].save(sb, save_all=True, append_images=frames[1:], duration=durs, loop=0, disposal=1)
print('ok LCM', T, 'sbs frames', len(frames), sb.stat().st_size)
