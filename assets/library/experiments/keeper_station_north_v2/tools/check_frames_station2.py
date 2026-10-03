#!/usr/bin/env python3
"""Frame / alpha / object check for keeper_station_north_v2 (wraps harv/check_frames_harv.check for the 128x128 N canvas).
Usage: check_frames_station2.py <final_dir>
Per frame, everything from check_frames_harv (RGBA, size, corners/border alpha 0, alpha strictly 0/255, alpha-0 RGB = 0, no magenta,
no purple tint on the edge, no light fringe, every visible RGB in palette.json = Option A 48, soles row 123 + feet centre within
2 px of x 64), plus the v1 extras adapted to an object-free clip:
  body height      clip's tallest frame 117..123 (Option A N still = 120)
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
        x['pass'] = bool(x['rgba'] and x['size_ok'] and x['corners_alpha0'] and x['bg_clear'] and x['alpha_not_0_255'] == 0 and x['zero_rgb'] == 0
                         and x['magenta_any'] == 0 and x['tint_edge'] == 0 and x['light_fringe'] == 0 and x['non_palette'] == 0 and x['anchor_ok']
                         and 117 <= hmax <= 123 and x['object_free'])
    ok = all(x['pass'] for x in rs)
    (root / 'alpha_check.json').write_text(json.dumps({'all_pass': ok, 'frames': rs}, indent=1))
    L = ['# Frame / alpha / object check (tools/check_frames_station2.py)', '',
         'Hard 0/255 alpha, transparent background, 128x128, feet anchor (64,124) = soles row 123 / feet edge-centre x 64; '
         'palette = Option A 48 (no extras); object check = 1 component, no white / light-grey (metal, paper) / stray green / stray cyan px.', '',
         '| frame | mode | size | corners a=0 | border clear | alpha not 0/255 | alpha0 RGB!=0 | magenta | purple tint edge | light fringe | non-palette | components | specks | white | light grey | green outside hair | stray cyan | sole / feet x / body h / top / x range | PASS |',
         '|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|']
    for x in rs:
        L.append(f"| {x['file']} | {x['mode']} | {x['size_ok']} | {x['corners_alpha0']} | {x['bg_clear']} | {x['alpha_not_0_255']} | {x['zero_rgb']} | {x['magenta_any']} | {x['tint_edge']} | "
                 f"{x['light_fringe']} | {x['non_palette']} | {x['components']} | {x['lone_px']} | {x['white_px']} | {x['light_grey_px']} | {x['green_outside_hair']} | {x['stray_cyan']} | "
                 f"{x['sole_row']} / {x['feet_cx_edge']} / {x['body_h']} / {x['top_row']} / {x['x_range']} | {'PASS' if x['pass'] else 'FAIL'} |")
    L += ['', f"ALL PASS: {ok} ({sum(x['pass'] for x in rs)}/{len(rs)}), clip upright body height {hmax}"]
    (root / 'alpha_check.md').write_text('\n'.join(L) + '\n'); print(L[-1])
    for x in rs:
        if not x['pass']: print('FAIL', x)
    return 0 if ok else 1

if __name__ == '__main__':
    sys.exit(main())
