#!/usr/bin/env python3
"""v3 stills: 8 directions per option from v3/work/<A|B>/view_RC.png (ingest8.py output).
defringe each source view -> optional mirror (x -> 127-x) -> ONE 48-colour material-aware palette per option (Lab k-means)
-> nearest-Lab apply -> keeper_still_<dir>.png + palette.json + keeper_still_8dir.json + previews."""
import sys, json, shutil
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw
sys.path.insert(0, '/workspace/keeper_idle/tools')
from build_idles import defringe, shared_palette, apply_palette, gif, label, GRASS, magenta_tint
R = Path('/workspace/keeper_idle'); REPO = R / 'repo'
OUT = REPO / 'assets/library/experiments/keeper_idle_4dir/v3_stills_8dir'
DIRS = ['S', 'SE', 'E', 'NE', 'N', 'NW', 'W', 'SW']
# (source view r c, mirrored?)  r 0/1 = top/bottom row of the Imagine sheet, c 0..3
MAP = {
 'A': {'S': ('00', 0), 'SE': ('01', 0), 'E': ('02', 0), 'NE': ('03', 1), 'N': ('10', 0), 'NW': ('03', 0), 'W': ('12', 0), 'SW': ('13', 0)},
 'B': {'S': ('00', 0), 'SE': ('01', 0), 'E': ('02', 0), 'NE': ('11', 1), 'N': ('10', 0), 'NW': ('11', 0), 'W': ('12', 0), 'SW': ('13', 0)},
}
LIVE = np.array(Image.open(REPO / 'assets/art/keeper/keeper_idle_south_0000.png').convert('RGBA'))
V2S = np.array(Image.open(REPO / 'assets/library/experiments/keeper_idle_4dir/v2/idle_south/keeper_idle_south_0001.png').convert('RGBA'))

def row_sheet(cells, names, scale, cw=(24, 104)):
    w = cw[1] - cw[0]; band = 14
    c = Image.new('RGBA', (w * len(cells), 128), GRASS)
    for i, f in enumerate(cells): c.alpha_composite(Image.fromarray(f).crop((cw[0], 0, cw[1], 128)), (i * w, 0))
    c = c.resize((c.width * scale, c.height * scale), Image.NEAREST)
    s = Image.new('RGBA', (c.width, c.height + band), (24, 24, 24, 255)); s.alpha_composite(c, (0, band))
    d = ImageDraw.Draw(s)
    for i, n in enumerate(names): d.text((i * w * scale + 2, 1), n, fill=(255, 255, 255, 255))
    return s

def build(opt):
    od = OUT / f'option_{opt.lower()}'; od.mkdir(parents=True, exist_ok=True)
    src = {}; fr = {}
    for rc in sorted({v[0] for v in MAP[opt].values()}):
        k = np.array(Image.open(R / f'v3/work/{opt}/view_{rc}.png').convert('RGBA'))
        src[rc], fr[rc] = defringe(k)
    views = {d: (src[rc][:, ::-1].copy() if m else src[rc]) for d, (rc, m) in MAP[opt].items()}
    pal = shared_palette(list(views.values()), n=48)
    stills = {d: apply_palette(v, pal) for d, v in views.items()}
    files = []
    for d in DIRS:
        f = f'keeper_still_{d.lower()}.png'; Image.fromarray(stills[d]).save(od / f); files.append(f)
    (od / 'palette.json').write_text(json.dumps({'colors': pal.tolist(), 'n': len(pal)}))
    pi = Image.new('RGB', (len(pal) * 8, 8))
    for i, c in enumerate(pal): pi.paste(tuple(int(x) for x in c), (i * 8, 0, i * 8 + 8, 8))
    pi.resize((pi.width * 2, 16), Image.NEAREST).save(od / 'palette.png')
    def ext(a):
        ys, xs = np.nonzero(a[..., 3]); return {'top': int(ys.min()), 'sole': int(ys.max()), 'height': int(ys.max() - ys.min() + 1), 'width': int(xs.max() - xs.min() + 1)}
    meta = {'clip': 'still_8dir', 'files': files, 'directions': DIRS,
            'source_sheet': {'A': 'yylTR.png', 'B': 'pyvqF.png'}[opt],
            'mapping': {d: {'sheet_view': f'row{int(rc[0])+1} col{int(rc[1])+1}', 'mirrored': bool(m)} for d, (rc, m) in MAP[opt].items()},
            'defringed_px': {rc: n for rc, n in fr.items()}, 'extent': {d: ext(stills[d]) for d in DIRS},
            'ingest': json.loads((R / f'v3/work/{opt}/ingest.json').read_text()) if (R / f'v3/work/{opt}/ingest.json').exists() else None}
    (od / 'keeper_still_8dir.json').write_text(json.dumps(meta, indent=1))
    # previews
    cells = [stills[d] for d in DIRS] + [LIVE, V2S]; names = DIRS + ['live S', 'v2 S']
    p = od / 'previews'; p.mkdir(exist_ok=True)
    row_sheet(cells, names, 1).save(p / f'contact_row_x1.png'); row_sheet(cells, names, 3).save(p / f'contact_row_x3.png')
    # compass x3: 3x3, centre = live S
    grid = {'NW': (0, 0), 'N': (0, 1), 'NE': (0, 2), 'W': (1, 0), 'E': (1, 2), 'SW': (2, 0), 'S': (2, 1), 'SE': (2, 2)}
    cp = Image.new('RGBA', (3 * 96, 3 * 128), GRASS)
    for d, (r, c) in grid.items(): cp.alpha_composite(Image.fromarray(stills[d]).crop((16, 0, 112, 128)), (c * 96, r * 128))
    cp.alpha_composite(Image.fromarray(LIVE).crop((16, 0, 112, 128)), (96, 128))
    cp = cp.resize((cp.width * 3, cp.height * 3), Image.NEAREST)
    for d, (r, c) in grid.items(): label(cp, c * 288 + 3, r * 384 + 3, d)
    label(cp, 288 + 3, 384 + 3, 'live idle_south (ref)'); cp.save(p / 'compass_x3.png')
    gif([stills[d] for d in DIRS], p / 'turnaround_x2.gif', scale=2, durations=250)
    return stills, pal, meta

if __name__ == '__main__':
    res = {o: build(o) for o in 'AB'}
    names = DIRS + ['live S', 'v2 S']
    a = row_sheet([res['A'][0][d] for d in DIRS] + [LIVE, V2S], ['A ' + n for n in names], 3)
    b = row_sheet([res['B'][0][d] for d in DIRS] + [LIVE, V2S], ['B ' + n for n in names], 3)
    s = Image.new('RGBA', (a.width, a.height + b.height + 6), (24, 24, 24, 255)); s.alpha_composite(a, (0, 0)); s.alpha_composite(b, (0, a.height + 6))
    s.save(OUT / 'A_vs_B_x3.png')
    for o in 'AB': print(o, len(res[o][1]), 'colours', {d: e['height'] for d, e in res[o][2]['extent'].items()}, res[o][2]['defringed_px'])
