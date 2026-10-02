#!/usr/bin/env python3
"""Frame / alpha check for the side-view harvest clips (adapted from v3/tools/check_frames.py for 192xH tool canvases).
Usage: check_frames_harv.py <final_dir> ["harvest_*/harvest_*.json"]
Per frame (all must hold):
  rgba            PNG mode is RGBA (a real alpha channel, not RGB/P), size == meta frame_size
  corners_alpha0  the four corner pixels have alpha 0 (transparent background, nothing baked in)
  bg_clear        whole outer 1 px border alpha 0 (nothing clipped at the canvas edge)
  alpha_values    alpha strictly in {0, 255} (hard alpha; count of other values must be 0)
  zero_rgb        alpha-0 pixels are (0,0,0,0)
  magenta_any     no magenta/pink key colour anywhere (visible px)
  tint_edge       no purple/magenta-tinted pixels on the silhouette edge (dark key contamination)
  light_fringe    no semi px with max RGB > 160 (trivially 0 with hard alpha)
  palette         every visible RGB is in the clip's palette (meta "palette": Option A 48 + listed tool extras)
  sole/feet       lowest opaque row in the feet window (anchor x +-30) == anchor_y - 1; planted-feet centre within 2 px of anchor x
                  (feet window excludes the tool head lying on the ground right of the feet)
  body height     hair-top -> sole reported per frame; the clip's tallest (upright) frame must be 116..122 (Option A E still = 119)
Writes alpha_check.json / alpha_check.md into <final_dir>; exit 1 on any failure."""
import json, sys
from pathlib import Path
import numpy as np
from PIL import Image
sys.path.insert(0, '/workspace/keeper_idle/v3/tools')
from check_frames import edge_band, magenta, magenta_tint

def check(p, meta, pal):
    im = Image.open(p); W, H = meta['frame_size']; ax, ay = meta['feet_anchor']
    r = {'file': f'{p.parent.name}/{p.name}', 'mode': im.mode, 'rgba': im.mode == 'RGBA' and 'A' in im.getbands()}
    a = np.array(im.convert('RGBA')).astype(int); al = a[..., 3]; h, w = al.shape
    r['size_ok'] = (w, h) == (W, H)
    r['corners_alpha0'] = bool(al[0, 0] == 0 and al[0, -1] == 0 and al[-1, 0] == 0 and al[-1, -1] == 0)
    r['bg_clear'] = bool((np.concatenate([al[0], al[-1], al[:, 0], al[:, -1]]) == 0).all())
    r['alpha_not_0_255'] = int(((al != 0) & (al != 255)).sum()); r['transparent_px'] = int((al == 0).sum())
    r['zero_rgb'] = int(((al == 0) & (a[..., :3].sum(-1) > 0)).sum())
    near = edge_band(al); vis = al > 0
    r['magenta_any'] = int(magenta(a[vis][:, :3]).sum()); r['tint_edge'] = int(magenta_tint(a[vis & near][:, :3]).sum())
    semi = (al > 0) & (al < 255); sp = a[semi][:, :3]; r['light_fringe'] = int((sp.max(1) > 160).sum()) if len(sp) else 0
    r['non_palette'] = int(sum(1 for c in map(tuple, a[vis][:, :3].tolist()) if c not in pal))
    op = al > 127; win = op[:, max(0, ax - 30):ax + 30]; rows = np.nonzero(win.any(1))[0]; sole = int(rows.max())
    band = win[sole - 9:sole + 1]; xs = np.nonzero(band.any(0))[0] + max(0, ax - 30); fx = float((xs.min() + xs.max() + 1) / 2)
    c = a[..., :3]; green = op & (c[..., 1] > c[..., 0] + 25) & (c[..., 1] > c[..., 2] + 25)
    r['sole_row'] = sole; r['feet_cx_edge'] = fx; r['hair_top'] = int(np.nonzero(green.any(1))[0].min()); r['body_h'] = sole - r['hair_top'] + 1
    r['top_row'] = int(np.nonzero(op.any(1))[0].min()); cols = np.nonzero(op.any(0))[0]; r['x_range'] = [int(cols.min()), int(cols.max())]
    r['anchor_ok'] = sole == ay - 1 and abs(fx - ax) <= 2
    return r

def main():
    root = Path(sys.argv[1]); res = {}
    for meta_p in sorted(root.glob(sys.argv[2] if len(sys.argv) > 2 else 'harvest_*/harvest_*.json')):
        m = json.loads(meta_p.read_text()); pal = set(map(tuple, json.loads((root / m['palette']).read_text())['colors']))
        rs = [check(meta_p.parent / f, m, pal) for f in m['files']]; hmax = max(x['body_h'] for x in rs)
        for x in rs:
            x['clip_upright_h'] = hmax
            x['pass'] = bool(x['rgba'] and x['size_ok'] and x['corners_alpha0'] and x['bg_clear'] and x['alpha_not_0_255'] == 0 and x['zero_rgb'] == 0
                             and x['magenta_any'] == 0 and x['tint_edge'] == 0 and x['light_fringe'] == 0 and x['non_palette'] == 0 and x['anchor_ok'] and 116 <= hmax <= 122)
        res[m['clip']] = rs
    ok = all(x['pass'] for v in res.values() for x in v); n = sum(len(v) for v in res.values())
    (root / 'alpha_check.json').write_text(json.dumps({'all_pass': ok, 'clips': res}, indent=1))
    L = ['# Frame / alpha check (tools/check_frames_harv.py)', '', 'Hard 0/255 alpha, transparent background; feet anchor from each clip meta (192x136: x edge 96, soles row 131).', '',
         '| frame | mode | size | corners a=0 | border clear | alpha not 0/255 | alpha0 RGB!=0 | magenta | purple tint edge | light fringe | non-palette | sole / feet x / body h / top row / x range | PASS |',
         '|---|---|---|---|---|---|---|---|---|---|---|---|---|']
    for clip, v in res.items():
        for x in v:
            L.append(f"| {x['file']} | {x['mode']} | {x['size_ok']} | {x['corners_alpha0']} | {x['bg_clear']} | {x['alpha_not_0_255']} | {x['zero_rgb']} | {x['magenta_any']} | {x['tint_edge']} | "
                     f"{x['light_fringe']} | {x['non_palette']} | {x['sole_row']} / {x['feet_cx_edge']} / {x['body_h']} / {x['top_row']} / {x['x_range']} | {'PASS' if x['pass'] else 'FAIL'} |")
    L += ['', f"ALL PASS: {ok} ({sum(x['pass'] for v in res.values() for x in v)}/{n})"]
    (root / 'alpha_check.md').write_text('\n'.join(L) + '\n'); print(L[-1])
    for clip, v in res.items():
        bad = [x for x in v if not x['pass']]
        print(clip, 'PASS' if not bad else bad[:1], 'upright h', v[0]['clip_upright_h'], 'top rows', [x['top_row'] for x in v], 'x', min(x['x_range'][0] for x in v), max(x['x_range'][1] for x in v))
    return 0 if ok else 1

if __name__ == '__main__':
    sys.exit(main())
