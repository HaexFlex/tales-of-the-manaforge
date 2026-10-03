#!/usr/bin/env python3
"""Export Elaia harvest_side_v1 (E + W mirror) and station_north_v1 to the repo, plus previews in /workspace/elaia_anims/out/."""
import json, sys, shutil, math
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw
sys.path.insert(0, '/workspace/keeper_idle/tools'); sys.path.insert(0, str(Path(__file__).parent))
from build_idles import gif, GRASS
from build_harv import SPEC
HV = Path('/workspace/elaia_anims/harv'); REPO = Path('/workspace/keeper_idle/repo/assets/library/experiments/elaia_companion')
OUT = Path('/workspace/elaia_anims/out'); PAL40 = json.loads(Path('/workspace/elaia_anims/stills/palette.json').read_text())
WATER = [[44, 118, 214], [64, 196, 240], [150, 240, 252]]
log = json.loads((HV / 'assembled/assembly.json').read_text())
HD, SD = REPO / 'harvest_side_v1', REPO / 'station_north_v1'
clips = {}
for name, s in SPEC.items():
    fr = [np.array(Image.open(HV / f'assembled/{name}/{name}_{k:04d}.png')) for k in range(len(s['frames']))]
    W, H = s['W'], s['H']; sole = H - 5; cx = W // 2
    dirs = [('north', fr)] if name == 'station_work' else [('east', fr), ('west', [np.ascontiguousarray(f[:, ::-1]) for f in fr])]
    for dname, F in dirs:
        clip = f'{name}_{dname}'; dd = SD if name == 'station_work' else HD / clip; dd.mkdir(parents=True, exist_ok=True)
        files = []
        for k, f in enumerate(F):
            n = f'{clip}_{k:04d}.png'; Image.fromarray(f).save(dd / n); files.append(n)
        st = Image.new('RGBA', (W * len(F), H)); [st.paste(Image.fromarray(f), (W * k, 0)) for k, f in enumerate(F)]; st.save(dd / f'{clip}_strip.png')
        meta = {'clip': clip, 'files': files, 'frame_size': [W, H], 'feet_anchor': [cx, H - 4],
                'feet_anchor_note': f'bottom-centre of the planted feet = pixel edge x {cx}, y {H - 4}; soles on row {sole}',
                'durations_ms': s['ms'], 'loop_ms': sum(s['ms']), 'loop': True, 'impact_frame': s['impact'], 'phases': s['phases'],
                'source_video': s['src'], 'source_fps': 24, 'source_frames_1based': s['frames'],
                'scale': '115/334 (Elaia still height / standing body height in the clip)',
                'palette': 'palette_water.json (Elaia 40 + 3 water tones)' if 'water' in name else ('palette.json' if name == 'station_work' else 'palette_elaia40.json'),
                'build': log[name] if dname != 'west' else {'mirror_of': f'{name}_east', 'x_map': f'x -> {W - 1} - x'}}
        if name == 'harvest_water': meta.update(pour_start_frame=1, stream_at_ground_frames=[4, 5, 6], pour_end_frame=7)
        (dd / f'{clip}.json').write_text(json.dumps(meta, indent=1))
        gif(F, dd / f'{clip}_x3.gif', scale=3, durations=s['ms']); clips[clip] = (F, s['ms'], W, H)
(HD / 'palette_elaia40.json').write_text(json.dumps(PAL40, indent=0))
(HD / 'palette_water.json').write_text(json.dumps({'colors': PAL40['colors'] + WATER, 'base': 'Elaia 40 (v1_stills/palette.json)', 'extra': WATER,
    'note': 'water tones only on stream pixels right of x 112 / below row 70 (east)'}, indent=0))
(SD / 'palette.json').write_text(json.dumps(PAL40, indent=0))
for d in (HD / 'source', SD / 'source', HD / 'tools', SD / 'tools', HD / 'preview', SD / 'preview'): d.mkdir(parents=True, exist_ok=True)
for v in ('elaia_harvest_axe_retry', 'elaia_harvest_pickaxe', 'elaia_harvest_berries', 'elaia_harvest_water'): shutil.copy(HV / f'raw/{v}.mp4', HD / 'source')
shutil.copy(HV / 'raw/elaia_station_generic.mp4', SD / 'source')
for t in ('analyse.py', 'convert_act.py', 'conv_all.py', 'build_harv.py', 'export_harv.py', 'check_harv.py', 'sheet.py', 'asheet.py', 'strip.py', 'zoomv.py', 'zoomw.py'):
    if (HV / t).exists(): shutil.copy(HV / t, HD / 'tools'); shutil.copy(HV / t, SD / 'tools')
for a in ('axe_retry', 'pickaxe', 'berries', 'water'): shutil.copy(HV / f'metrics_{a}.json', HD / 'source')
shutil.copy(HV / 'metrics_station.json', SD / 'source')

def combined(names, out, T=None, S=2):
    Ls = [sum(clips[n][1]) for n in names]
    if T is None:
        T = 1
        for L in Ls: T = T * L // math.gcd(T, L)
    def idx(t, d):
        t %= sum(d); acc = 0
        for k, v in enumerate(d):
            acc += v
            if t < acc: return k
    cuts = set()
    for n in names:
        d = clips[n][1]; t = 0
        while t < T:
            for v in d:
                cuts.add(t); t += v
    cuts = sorted(c for c in cuts if c < T) + [T]; Hh = 136; widths = [clips[n][2] * S for n in names]
    fr, du, cache = [], [], {}
    for t0, t1 in zip(cuts, cuts[1:]):
        key = tuple(idx(t0, clips[n][1]) for n in names)
        if key not in cache:
            c = Image.new('RGB', (sum(widths) + 4 * len(names), Hh * S + 16), (24, 24, 24)); dr = ImageDraw.Draw(c); x = 0
            for n, i, w in zip(names, key, widths):
                F, d, W, H = clips[n]; bb = Image.new('RGBA', (W, Hh), GRASS); bb.alpha_composite(Image.fromarray(F[i]), (0, Hh - H))
                c.paste(bb.convert('RGB').resize((W * S, Hh * S), Image.NEAREST), (x, 16)); dr.text((x + 3, 2), f'{n} {i} ({d[i]}ms)', fill=(255, 255, 255)); x += w + 4
            cache[key] = c
        if fr and fr[-1] is cache[key]: du[-1] += t1 - t0
        else: fr.append(cache[key]); du.append(t1 - t0)
    fr[0].save(out, save_all=True, append_images=fr[1:], duration=du, loop=0, disposal=1); return T, len(fr)
OUT.mkdir(exist_ok=True)
print('harvest E', combined(['harvest_axe_east', 'harvest_pickaxe_east', 'harvest_berries_east', 'harvest_water_east'], OUT / 'elaia_harvest_side_v1_E_x2.gif'))
print('all', combined(['harvest_axe_east', 'harvest_pickaxe_east', 'harvest_berries_east', 'harvest_water_east', 'station_work_north'], OUT / 'elaia_harvest_water_station_all_x2.gif', T=2700))
print('E|W', combined(['harvest_axe_east', 'harvest_axe_west', 'harvest_pickaxe_east', 'harvest_pickaxe_west'], OUT / 'elaia_harvest_axe_pickaxe_E_W_x2.gif'))
print('E|W2', combined(['harvest_berries_east', 'harvest_berries_west', 'harvest_water_east', 'harvest_water_west'], OUT / 'elaia_harvest_berries_water_E_W_x2.gif'))
print('station', combined(['station_work_north'], OUT / 'elaia_station_north_v1_x3.gif', S=3))
for g in ('elaia_harvest_side_v1_E_x2.gif', 'elaia_harvest_water_station_all_x2.gif', 'elaia_harvest_axe_pickaxe_E_W_x2.gif', 'elaia_harvest_berries_water_E_W_x2.gif'):
    shutil.copy(OUT / g, HD / 'preview')
shutil.copy(OUT / 'elaia_station_north_v1_x3.gif', SD / 'preview'); shutil.copy(OUT / 'elaia_harvest_water_station_all_x2.gif', SD / 'preview')
# contact sheets
def contact(names, out, S=2):
    rows = []
    for n in names:
        F, d, W, H = clips[n]; r = Image.new('RGBA', (len(F) * W, 136), GRASS)
        for k, f in enumerate(F): r.alpha_composite(Image.fromarray(f), (k * W, 136 - H))
        rows.append(r)
    Wm = max(r.width for r in rows); c = Image.new('RGBA', (Wm, 136 * len(rows)), (24, 24, 24, 255))
    for i, r in enumerate(rows): c.alpha_composite(r, (0, 136 * i))
    c = c.resize((c.width * S // 2 * 2 // 2, c.height * S // 2 * 2 // 2), Image.NEAREST) if S != 1 else c
    c.save(out)
contact(['harvest_axe_east', 'harvest_pickaxe_east', 'harvest_berries_east', 'harvest_water_east'], OUT / 'elaia_harvest_side_v1_E_contact.png', S=1)
contact(['station_work_north'], SD / 'station_work_north_contact.png', S=1); shutil.copy(SD / 'station_work_north_contact.png', OUT / 'elaia_station_north_v1_contact.png')
shutil.copy(OUT / 'elaia_harvest_side_v1_E_contact.png', HD / 'preview')
print('ok')
