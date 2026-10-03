#!/usr/bin/env python3
"""Frame / alpha / bench check for keeper_station_north_v1 (wraps harv/check_frames_harv.check for the 128x128 N canvas).
Usage: check_frames_station.py <final_dir>
Per frame, everything from check_frames_harv (RGBA, size, corners/border alpha 0, alpha strictly 0/255, alpha-0 RGB = 0, no magenta,
no purple tint on the edge, no light fringe, every visible RGB in palette.json, soles row 123 + feet centre within 2 px of x 64), plus:
  body height      clip's tallest frame 117..123 (Option A N still = 120)
  bench_band       plank rows of the source (canvas rows 69..78): exactly one opaque run per row (the coat), inside x 44..84
                   (the plank spanned canvas x 29..100; any leftover would show as a second run or a wider run). Only exception:
                   in row 69 (plank top edge) the lowered right sleeve's underside may dip in - allowed only if those px are all
                   blue/navy sleeve shades attached to the arm in row 68
  white_px         no near-white px (min RGB > 200) except in the hammer-head zone (x >= 84, rows < 72)
  stray_cyan       rune cyan only inside the rune box (rows 48..78, x 52..76) - no leftover sparks / F-glyph remnants
  lone_px          no opaque component smaller than 4 px (specks / sparks)
Writes alpha_check.json / alpha_check.md into <final_dir>; exit 1 on any failure."""
import json, sys
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage
sys.path.insert(0, '/workspace/keeper_idle/harv')
from check_frames_harv import check

def extra(p):
    a = np.array(Image.open(p).convert('RGBA')).astype(int); op = a[..., 3] > 0; r = {}
    runs = []
    for y in range(69, 79):
        xs = np.nonzero(op[y])[0]; rr = np.split(xs, np.nonzero(np.diff(xs) > 1)[0] + 1) if len(xs) else []
        runs.append((y, [(int(q[0]), int(q[-1])) for q in rr]))
    def sleeve(y, x0, x1):   # a lowered sleeve underside dipping into the top band row: blue/navy shades, attached to the arm above
        c = a[y, x0:x1 + 1, :3]; blue = (c[:, 2] > c[:, 0] + 20) | (c.max(1) < 60)
        return bool(blue.all() and op[y - 1, max(0, x0 - 1):x1 + 2].any())
    ok = True
    for y, v in runs:
        coat = [q for q in v if q[0] <= 64 <= q[1]]
        if len(coat) != 1 or coat[0][0] < 44: ok = False; continue
        c0, c1 = coat[0]
        if c1 > 84 and not (y == 69 and sleeve(y, 80, c1)): ok = False
        for q in v:
            if q != coat[0] and not (y == 69 and sleeve(y, *q)): ok = False
    r['bench_band_ok'] = ok; r['bench_band_runs'] = runs
    wh = op & (a[..., :3].min(-1) > 200); wh[:72, 84:] = False; r['white_px'] = int(wh.sum())
    cy = op & (a[..., :3] == (77, 219, 213)).all(-1); cy[48:78, 52:76] = False; r['stray_cyan'] = int(cy.sum())
    lab, n = ndimage.label(op, np.ones((3, 3))); area = ndimage.sum(op, lab, np.arange(1, n + 1)) if n else []
    r['components'] = int(n); r['lone_px'] = int(sum(1 for x in area if x < 4))
    return r

def main():
    root = Path(sys.argv[1]); meta = json.loads((root / 'station_work_north.json').read_text())
    pal = set(map(tuple, json.loads((root / meta['palette']).read_text())['colors']))
    rs = []
    for f in meta['files']:
        x = check(root / f, meta, pal); x.update(extra(root / f)); rs.append(x)
    hmax = max(x['body_h'] for x in rs)
    for x in rs:
        x['clip_upright_h'] = hmax
        x['pass'] = bool(x['rgba'] and x['size_ok'] and x['corners_alpha0'] and x['bg_clear'] and x['alpha_not_0_255'] == 0 and x['zero_rgb'] == 0
                         and x['magenta_any'] == 0 and x['tint_edge'] == 0 and x['light_fringe'] == 0 and x['non_palette'] == 0 and x['anchor_ok']
                         and 117 <= hmax <= 123 and x['bench_band_ok'] and x['white_px'] == 0 and x['stray_cyan'] == 0 and x['lone_px'] == 0)
    ok = all(x['pass'] for x in rs)
    (root / 'alpha_check.json').write_text(json.dumps({'all_pass': ok, 'frames': rs}, indent=1))
    L = ['# Frame / alpha / bench check (tools/check_frames_station.py)', '',
         'Hard 0/255 alpha, transparent background, 128x128, feet anchor (64,124) = soles row 123 / feet edge-centre x 64; '
         'palette = Option A 48 + the iron greys used by the hammer head; bench band = source plank rows (canvas 69..78).', '',
         '| frame | mode | size | corners a=0 | border clear | alpha not 0/255 | alpha0 RGB!=0 | magenta | purple tint edge | light fringe | non-palette | bench band 1 run | white px | stray cyan | specks | sole / feet x / body h / top / x range | PASS |',
         '|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|']
    for x in rs:
        L.append(f"| {x['file']} | {x['mode']} | {x['size_ok']} | {x['corners_alpha0']} | {x['bg_clear']} | {x['alpha_not_0_255']} | {x['zero_rgb']} | {x['magenta_any']} | {x['tint_edge']} | "
                 f"{x['light_fringe']} | {x['non_palette']} | {x['bench_band_ok']} | {x['white_px']} | {x['stray_cyan']} | {x['lone_px']} | "
                 f"{x['sole_row']} / {x['feet_cx_edge']} / {x['body_h']} / {x['top_row']} / {x['x_range']} | {'PASS' if x['pass'] else 'FAIL'} |")
    L += ['', f"ALL PASS: {ok} ({sum(x['pass'] for x in rs)}/{len(rs)}), clip upright body height {hmax}"]
    (root / 'alpha_check.md').write_text('\n'.join(L) + '\n'); print(L[-1])
    for x in rs:
        if not x['pass']: print('FAIL', {k: v for k, v in x.items() if k not in ('bench_band_runs',)})
    return 0 if ok else 1

if __name__ == '__main__':
    sys.exit(main())
