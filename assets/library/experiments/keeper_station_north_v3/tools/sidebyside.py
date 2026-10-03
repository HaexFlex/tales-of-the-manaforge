#!/usr/bin/env python3
"""v2-vs-v3 side-by-side x3 GIF on green, both at their own per-frame ms, on the common LCM timeline (seamless for both)."""
import json, math
from pathlib import Path
from PIL import Image, ImageDraw
R = Path('/workspace/keeper_idle')
def load(d):
    m = json.loads((d / 'station_work_north.json').read_text())
    return [Image.open(d / f).convert('RGBA') for f in m['files']], m['durations_ms']
A, da = load(R / 'repo/assets/library/experiments/keeper_station_north_v2'); B, db = load(R / 'station3/final')
La, Lb = sum(da), sum(db); T = La * Lb // math.gcd(La, Lb)
def idx_at(t, d):
    t %= sum(d); acc = 0
    for k, v in enumerate(d):
        acc += v
        if t < acc: return k
cuts = sorted(set([0] + [n * La + sum(da[:k]) for n in range(T // La) for k in range(len(da))] + [n * Lb + sum(db[:k]) for n in range(T // Lb) for k in range(len(db))]))
cuts.append(T); frames, durs = [], []
cache = {}
for t0, t1 in zip(cuts, cuts[1:]):
    ia, ib = idx_at(t0, da), idx_at(t0, db); key = (ia, ib)
    if key not in cache:
        c = Image.new('RGB', (128 * 2 * 3 + 6, 128 * 3 + 18), (24, 24, 24)); d = ImageDraw.Draw(c)
        for n, (im, lab) in enumerate([(A[ia], f'v2 {ia}'), (B[ib], f'v3 {ib}')]):
            b = Image.new('RGB', (128, 128), (78, 128, 52)); b.paste(im, (0, 0), im); c.paste(b.resize((384, 384), Image.NEAREST), (n * 390, 18)); d.text((n * 390 + 4, 3), lab, fill=(255, 255, 255))
        cache[key] = c
    if frames and frames[-1] is cache[key]: durs[-1] += t1 - t0
    else: frames.append(cache[key]); durs.append(t1 - t0)
out = R / 'station3/final/station_work_north_v2_vs_v3_x3.gif'
frames[0].save(out, save_all=True, append_images=frames[1:], duration=durs, loop=0, disposal=1)
print('LCM ms', T, 'gif frames', len(frames), 'size', out.stat().st_size)
