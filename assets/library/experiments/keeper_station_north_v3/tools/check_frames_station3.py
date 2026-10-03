#!/usr/bin/env python3
"""Frame / alpha / object check for keeper_station_north_v3 (wraps harv/check_frames_harv.check for the 128x128 N canvas).
Usage: check_frames_station3.py <final_dir>
Per frame, everything from check_frames_harv (RGBA, size, corners/border alpha 0, alpha strictly 0/255, alpha-0 RGB = 0, no magenta,
no purple tint on the edge, no light fringe, every visible RGB in palette.json = Option A 48, soles row 123 + feet centre within
2 px of x 64), plus the v1 extras adapted to an object-free clip:
  body height      clip's tallest frame within meta body_height_range (v3: 104..110, head bowed; the N still = 120)
  bench_band       source bench rows (video 246..277 = canvas rows 72..82): exactly one opaque run per row (the coat), inside
                   x 42..86 (the plank ends spanned canvas x ~38..90 on both sides; a leftover = 2nd run or wider run). Only exception:
                   in row 72 (plank top edge) an elbow's sleeve underside may dip in: allowed only if blue/navy and attached above
  scale            lowest coat-blue row (hem) within 1 px of the N still's (meta still_hem_row = 102): same scale as the still
  components       exactly 1 opaque component (nothing detached: no object, spark, prop)
  lone_px          no opaque component smaller than 4 px
  white_px         no near-white px (min RGB > 200) anywhere (the Keeper from behind has none; paper/metal would)
  light_grey_px    no low-saturation px brighter than 100 (sat < .25): metal / paper / tool heads; the only grey the Keeper uses
                   is the dark outline grey (75,71,75)
  green_outside_hair  no green px outside the hair component (blur tints / leaves / objects)
  stray_cyan       rune cyan only inside the rune box (rows 48..78, x 50..80)
  object_free      all of the above (= no object or held item sneaked in)
Writes alpha_check.json / alpha_check.md into <final_dir>; exit 1 on any failure."""
import json, sys
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage
sys.path.insert(0, '/workspace/keeper_idle/harv')
from check_frames_harv import check

def extra(p):
    a = np.array(Image.open(p).convert('RGBA')).astype(int); op = a[..., 3] > 0; c = a[..., :3]; r = {}
    lab, n = ndimage.label(op, np.ones((3, 3))); area = ndimage.sum(op, lab, np.arange(1, n + 1)) if n else []
    r['components'] = int(n); r['lone_px'] = int(sum(1 for x in area if x < 4))
    r['white_px'] = int((op & (c.min(-1) > 200)).sum())
    mx = c.max(-1); mn = c.min(-1); s = (mx - mn) / np.maximum(mx, 1)
    r['light_grey_px'] = int((op & (s < 0.25) & (mx > 100)).sum())
    gr = op & (c[..., 1] > c[..., 0] + 15) & (c[..., 1] > c[..., 2] + 15); gl, gn = ndimage.label(gr, np.ones((3, 3)))
    if gn:
        ga = ndimage.sum(gr, gl, np.arange(1, gn + 1)); hair = gl == 1 + int(np.argmax(ga))
        loose = gr & ~hair; ys, xs = np.nonzero(loose)
        r['green_outside_hair'] = int(((ys >= 50) | (xs < 34) | (xs >= 98)).sum())   # small strands inside the head box are hair
    else: r['green_outside_hair'] = 0
    cy = op & (c == (77, 219, 213)).all(-1); cy[48:78, 50:80] = False; r['stray_cyan'] = int(cy.sum())
    blue = op & (c[..., 2] > c[..., 0] + 30) & (c[..., 2] > c[..., 1]); rows = [y for y in range(80, 124) if blue[y, 40:90].sum() > 5]
    r['hem_row'] = int(max(rows))
    bb = []
    for y in range(72, 83):
        xs = np.nonzero(op[y])[0]; rr = np.split(xs, np.nonzero(np.diff(xs) > 1)[0] + 1) if len(xs) else []
        bb.append((y, [(int(q[0]), int(q[-1])) for q in rr]))
    def sleeve(y, x0, x1):   # an elbow's sleeve underside dipping into the band's top row: blue/navy px attached to the arm above
        q = c[y, x0:x1 + 1]; blue_ = (q[:, 2] > q[:, 0] + 20) | (q.max(1) < 60)
        return bool(blue_.all() and op[y - 1, max(0, x0 - 1):x1 + 2].any())
    ok = True
    for y, v in bb:
        coat = [q for q in v if q[0] <= 64 <= q[1]]
        if len(coat) != 1 or coat[0][0] < 42 or coat[0][1] > 86: ok = False; continue
        for q in v:
            if q != coat[0] and not (y == 72 and sleeve(y, *q)): ok = False
    r['bench_band_ok'] = ok; r['bench_band_runs'] = bb
    r['object_free'] = r['components'] == 1 and r['lone_px'] == 0 and r['white_px'] == 0 and r['light_grey_px'] == 0 and r['green_outside_hair'] == 0 and r['stray_cyan'] == 0
    return r

def main():
    root = Path(sys.argv[1]); meta = json.loads((root / 'station_work_north.json').read_text())
    pal = set(map(tuple, json.loads((root / meta['palette']).read_text())['colors']))
    rs = []
    for f in meta['files']:
        x = check(root / f, meta, pal); x.update(extra(root / f)); x['file'] = f; rs.append(x)
    hmax = max(x['body_h'] for x in rs)
    for x in rs:
        x['clip_upright_h'] = hmax
        x['scale_ok'] = abs(x['hem_row'] - meta['still_hem_row']) <= 1
        x['pass'] = bool(x['scale_ok'] and x['bench_band_ok'] and x['rgba'] and x['size_ok'] and x['corners_alpha0'] and x['bg_clear'] and x['alpha_not_0_255'] == 0 and x['zero_rgb'] == 0
                         and x['magenta_any'] == 0 and x['tint_edge'] == 0 and x['light_fringe'] == 0 and x['non_palette'] == 0 and x['anchor_ok']
                         and meta['body_height_range'][0] <= hmax <= meta['body_height_range'][1] and x['object_free'])
    ok = all(x['pass'] for x in rs)
    (root / 'alpha_check.json').write_text(json.dumps({'all_pass': ok, 'frames': rs}, indent=1))
    L = ['# Frame / alpha / object check (tools/check_frames_station3.py)', '',
         'Hard 0/255 alpha, transparent background, 128x128, feet anchor (64,124) = soles row 123 / feet edge-centre x 64; '
         'palette = Option A 48 (no extras); bench band = source plank rows (canvas 72..82); object check = 1 component, no white / light-grey (metal, paper) / stray green / stray cyan px.', '',
         '| frame | mode | size | corners a=0 | border clear | alpha not 0/255 | alpha0 RGB!=0 | magenta | purple tint edge | light fringe | non-palette | components | specks | white | light grey | green outside hair | stray cyan | bench band 1 run | hem row (still 102) | sole / feet x / body h / top / x range | PASS |',
         '|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|']
    for x in rs:
        L.append(f"| {x['file']} | {x['mode']} | {x['size_ok']} | {x['corners_alpha0']} | {x['bg_clear']} | {x['alpha_not_0_255']} | {x['zero_rgb']} | {x['magenta_any']} | {x['tint_edge']} | "
                 f"{x['light_fringe']} | {x['non_palette']} | {x['components']} | {x['lone_px']} | {x['white_px']} | {x['light_grey_px']} | {x['green_outside_hair']} | {x['stray_cyan']} | {x['bench_band_ok']} | {x['hem_row']} | "
                 f"{x['sole_row']} / {x['feet_cx_edge']} / {x['body_h']} / {x['top_row']} / {x['x_range']} | {'PASS' if x['pass'] else 'FAIL'} |")
    L += ['', f"ALL PASS: {ok} ({sum(x['pass'] for x in rs)}/{len(rs)}), clip upright body height {hmax}"]
    (root / 'alpha_check.md').write_text('\n'.join(L) + '\n'); print(L[-1])
    for x in rs:
        if not x['pass']: print('FAIL', x)
    return 0 if ok else 1

if __name__ == '__main__':
    sys.exit(main())
