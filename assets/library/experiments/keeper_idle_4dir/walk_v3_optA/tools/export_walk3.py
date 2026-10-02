#!/usr/bin/env python3
"""Walk v3 (Option A, video-derived): export walk3/assembled -> repo walk_v3_optA/: walk_<dir>/ frames + strip + json (check_frames format)
+ GIF x3, combined GIF x2 (S N E W side by side), contact sheet (with the Option A still per direction), palette.json."""
import json, shutil, sys
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw
sys.path.insert(0, '/workspace/keeper_idle/tools')
from build_idles import gif, label, GRASS
R = Path('/workspace/keeper_idle'); REPO = R / 'repo'
OUT = REPO / 'assets/library/experiments/keeper_idle_4dir/walk_v3_optA'
A = REPO / 'assets/library/experiments/keeper_idle_4dir/v3_stills_8dir/option_a'
HOLD = 100
DIRS = ['south', 'north', 'east', 'west']; STILL = {'south': 's', 'north': 'n', 'east': 'e', 'west': 'w'}
asm = json.loads((R / 'walk3/assembled/assembly.json').read_text())
OUT.mkdir(parents=True, exist_ok=True); shutil.copy(A / 'palette.json', OUT / 'palette.json'); shutil.copy(A / 'palette.png', OUT / 'palette.png')
P = OUT / 'previews'; P.mkdir(exist_ok=True)
allf = {}
for d in DIRS:
    dd = OUT / f'walk_{d}'; dd.mkdir(exist_ok=True)
    fr = [np.array(Image.open(R / f'walk3/assembled/walk_{d}_{k:04d}.png')) for k in range(8)]
    files = []
    for k, f in enumerate(fr):
        n = f'walk_{d}_{k:04d}.png'; Image.fromarray(f).save(dd / n); files.append(n)
    strip = Image.new('RGBA', (128 * len(fr), 128)); [strip.paste(Image.fromarray(f), (128 * k, 0)) for k, f in enumerate(fr)]
    strip.save(dd / f'walk_{d}.png')
    (dd / f'walk_{d}.json').write_text(json.dumps({'clip': f'walk_{d}', 'files': files, 'hold_ms': HOLD, 'loop': True, 'anchor': 'loop', 'strip': f'walk_{d}.png',
                                                   'assembly': asm[d]}, indent=1))
    gif(fr, P / f'walk_{d}_x3.gif', scale=3, durations=HOLD); shutil.copy(P / f'walk_{d}_x3.gif', dd / f'walk_{d}_x3.gif')
    allf[d] = fr
# combined: S N E W side by side, x2, cells cropped to x 16..112
comb = []
for k in range(8):
    c = Image.new('RGBA', (4 * 96, 128), GRASS)
    for j, d in enumerate(DIRS): c.alpha_composite(Image.fromarray(allf[d][k]).crop((16, 0, 112, 128)), (j * 96, 0))
    comb.append(c)
gif(comb, P / 'walk_all4_x2.gif', scale=2, durations=HOLD)
# contact sheet x2: per row = still (Option A) + 8 frames
cw = 96; band = 12
cs = Image.new('RGBA', (9 * cw, 4 * 128), GRASS)
for r, d in enumerate(DIRS):
    cs.alpha_composite(Image.open(A / f'keeper_still_{STILL[d]}.png').crop((16, 0, 112, 128)), (0, r * 128))
    for k in range(8): cs.alpha_composite(Image.fromarray(allf[d][k]).crop((16, 0, 112, 128)), ((k + 1) * cw, r * 128))
cs = cs.resize((cs.width * 2, cs.height * 2), Image.NEAREST)
d_ = ImageDraw.Draw(cs)
for r, d in enumerate(DIRS):
    label(cs, 3, r * 256 + 3, f'still {STILL[d].upper()} (opt A)')
    fl = [f"f{i} b{b}" for i, b in zip(asm[d]['video_frames_1based'], asm[d]['bob_px'])] if 'video_frames_1based' in asm[d] else ['E mirrored'] * 8
    for k in range(8): label(cs, (k + 1) * cw * 2 + 3, r * 256 + 3, f'{d[0].upper()}{k} <- {fl[k]}'[:30])
for x in range(1, 9): d_.line([(x * cw * 2, 0), (x * cw * 2, cs.height)], fill=(30, 30, 30, 255))
cs.save(P / 'contact_sheet_x2.png')
print('ok', [p.name for p in P.iterdir()])
# v1 vs v2: per direction v1 (left) and v2 (right), x2
V1 = REPO / 'assets/library/experiments/keeper_idle_4dir/walk_v2_optA'
comb = []
for k in range(8):
    c = Image.new('RGBA', (8 * 96, 128 + 12), (24, 24, 24, 255))
    for j, d in enumerate(DIRS):
        for v, src in enumerate([V1 / f'walk_{d}' / f'walk_{d}_{k:04d}.png', OUT / f'walk_{d}' / f'walk_{d}_{k:04d}.png']):
            cell = Image.new('RGBA', (96, 128), GRASS); cell.alpha_composite(Image.open(src).crop((16, 0, 112, 128))); c.paste(cell, ((2 * j + v) * 96, 12))
    dr = ImageDraw.Draw(c)
    for j, d in enumerate(DIRS):
        for v in range(2): dr.text(((2 * j + v) * 96 + 3, 1), f'{d[0].upper()} v{v + 2}', fill=(255, 255, 255, 255))
    comb.append(c)
gif(comb, P / 'walk_v2_vs_v3_x2.gif', scale=2, durations=HOLD)
print('v2_vs_v3 ok')
