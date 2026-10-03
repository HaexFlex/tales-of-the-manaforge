#!/usr/bin/env python3
"""Elaia walk v1 export -> repo .../elaia_companion/walk_v1/walk_<dir>/ (frames, strip, json, x3 GIF) + previews in
/workspace/elaia_anims/out/walk_v1/: per-dir x3 GIFs, S|N|E|W x3, Elaia vs Keeper walk v5 side-by-side, contact sheet."""
import json, math, sys, shutil
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw
sys.path.insert(0, '/workspace/keeper_idle/tools'); sys.path.insert(0, '/workspace/keeper_idle/walk7')
from build_idles import gif, label, GRASS
sys.path.insert(0, str(Path(__file__).parent)); from sbs import sbs
H = Path('/workspace/elaia_anims'); REPO = Path('/workspace/keeper_idle/repo')
OUT = REPO / 'assets/library/experiments/elaia_companion/walk_v1'; PV = H / 'out/walk_v1'
KV5 = REPO / 'assets/library/experiments/keeper_idle_4dir/walk_v5_hybrid'
MS = [120, 125, 130, 125, 120, 125, 130, 125]; SPEED = 88
b = json.loads((H / 'walk/assembled_v1/build.json').read_text())
SRC = {'east': 'elaia_walk_east.mp4', 'south': 'elaia_walk_south.mp4', 'north': 'elaia_walk_north.mp4'}
STYLE = {'east': 'v1: own legs/arms from elaia_walk_east.mp4 (24-frame loop sampled every 3), per-step bob 0/1/2/1, swing boots raised to 5 px, robe-slit bare thigh recoloured to inner-robe blue, head + back-hair lock',
         'south': 'v1: the 8 unique 3-frame holds of elaia_walk_south.mp4 (24-frame loop), natural bob 0..2, head + side-hair + shoulders lock (top 56 rows)',
         'north': 'v1: 8 of 11 unique poses of elaia_walk_north.mp4 (26-frame loop, nearest to uniform spacing), bob clamped to 0..2 (fit_top, hip 0.70), head + back hair lock (sway tested, locked)',
         'west': 'v1: exact horizontal mirror of walk_east (x -> 127 - x)'}
clips = {}
for d in ('south', 'north', 'east', 'west'):
    src = H / 'walk/assembled_v1' / ('east' if d == 'west' else d); dd = OUT / f'walk_{d}'; dd.mkdir(parents=True, exist_ok=True)
    fr = [np.array(Image.open(src / f'walk_{"east" if d == "west" else d}_{k:04d}.png')) for k in range(8)]
    if d == 'west': fr = [np.ascontiguousarray(f[:, ::-1]) for f in fr]
    files = []
    for k, f in enumerate(fr):
        n = f'walk_{d}_{k:04d}.png'; Image.fromarray(f).save(dd / n); files.append(n)
    st = Image.new('RGBA', (128 * 8, 128)); [st.paste(Image.fromarray(f), (128 * k, 0)) for k, f in enumerate(fr)]; st.save(dd / f'walk_{d}.png')
    meta = {'clip': f'walk_{d}', 'files': files, 'durations_ms': MS, 'loop_ms': sum(MS), 'hold_ms': 125, 'loop': True, 'anchor': 'loop',
            'strip': f'walk_{d}.png', 'canvas': [128, 128], 'soles_row': 123, 'style': STYLE[d],
            'build': {'mirror_of': 'walk_east'} if d == 'west' else dict(b[d], source=SRC[d])}
    if d in ('east', 'west'): meta['suggested_move_speed_px_s'] = SPEED; meta['playback_rate_at_180_px_s'] = round(180 / SPEED, 2)
    (dd / f'walk_{d}.json').write_text(json.dumps(meta, indent=1))
    gif(fr, dd / f'walk_{d}_x3.gif', scale=3, durations=MS); clips[d] = [Image.fromarray(f) for f in fr]
    PV.mkdir(parents=True, exist_ok=True); shutil.copy(dd / f'walk_{d}_x3.gif', PV / f'elaia_walk_{d}_x3.gif')
shutil.copy(H / 'stills/palette.json', OUT / 'palette.json')
S, N, E, W = (clips[k] for k in ('south', 'north', 'east', 'west'))
print('dirs', sbs([('S', S, MS), ('N', N, MS), ('E', E, MS), ('W', W, MS)], PV / 'elaia_walk_v1_S_N_E_W_x3.gif'))
K = {d: [Image.open(KV5 / f'walk_{d}/walk_{d}_{k:04d}.png').convert('RGBA') for k in range(8)] for d in ('south', 'north', 'east', 'west')}
print('vs keeper', sbs([('Elaia S', S, MS), ('Elaia N', N, MS), ('Elaia E', E, MS), ('Elaia W', W, MS),
                        ('Keeper S', K['south'], MS), ('Keeper N', K['north'], MS), ('Keeper E', K['east'], MS), ('Keeper W', K['west'], MS)],
                       PV / 'elaia_v1_vs_keeper_v5_walk_S_N_E_W_x3.gif'))
ST = H / 'stills'
rows = (('s', S, 'S'), ('n', N, 'N'), ('e', E, 'E'), ('w', W, 'W'))
cw = 96; cs = Image.new('RGBA', (9 * cw, 4 * 128), GRASS)
for r, (s, F, nm) in enumerate(rows):
    cs.alpha_composite(Image.open(ST / f'elaia_still_{s}.png').convert('RGBA').crop((16, 0, 112, 128)), (0, r * 128))
    for k in range(8): cs.alpha_composite(F[k].crop((16, 0, 112, 128)), ((k + 1) * cw, r * 128))
cs = cs.resize((cs.width * 2, cs.height * 2), Image.NEAREST); d_ = ImageDraw.Draw(cs)
for r, (s, _, nm) in enumerate(rows):
    label(cs, 3, r * 256 + 3, f'still {s.upper()}')
    for k in range(8): label(cs, (k + 1) * cw * 2 + 3, r * 256 + 3, f'{nm} {k} {MS[k]}ms')
for x in range(1, 9): d_.line([(x * cw * 2, 0), (x * cw * 2, cs.height)], fill=(30, 30, 30, 255))
for y in range(1, 4): d_.line([(0, y * 256), (cs.width, y * 256)], fill=(30, 30, 30, 255))
cs.save(PV / 'elaia_walk_v1_contact_x2.png'); print('ok')
