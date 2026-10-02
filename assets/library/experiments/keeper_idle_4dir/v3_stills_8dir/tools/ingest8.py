#!/usr/bin/env python3
"""v3: ingest an 8-view Grok Imagine sheet (2 rows of 4 on magenta) into native 128x128 stills.
key (sampled corner colour, soft key + despill; tools/ingest_turnaround.key) -> split into 8 figures (row by y, then x)
-> ONE shared scale per sheet (S view -> 122 px) -> premultiplied LANCZOS 2x + NN 0.5 -> hard alpha -> sole row 123,
feet centre x 64. Writes v3/work/<name>/view_<r><c>.png (r 0/1 = top/bottom row, c 0..3) + crops for review."""
import sys, json
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage
sys.path.insert(0, '/workspace/keeper_idle/tools')
from ingest_turnaround import key, view_crop, body_extent, to_game, place
R = Path('/workspace/keeper_idle')

def split8(alpha, min_big=3000):
    m = alpha > 0.5
    lab, k = ndimage.label(m, structure=np.ones((3, 3)))
    idx = np.arange(1, k + 1); area = ndimage.sum(m, lab, idx); sl = ndimage.find_objects(lab)
    cy = np.array([(s[0].start + s[0].stop) / 2 for s in sl]); cx = np.array([(s[1].start + s[1].stop) / 2 for s in sl])
    big = sorted([i for i in range(k) if area[i] >= min_big], key=lambda i: -area[i])[:8]
    if len(big) != 8: raise SystemExit(f'found {len(big)} figures')
    midy = np.median(cy[big])
    rows = [sorted([b for b in big if cy[b] < midy], key=lambda i: cx[i]), sorted([b for b in big if cy[b] >= midy], key=lambda i: cx[i])]
    assert len(rows[0]) == 4 and len(rows[1]) == 4, rows
    groups = {(r, c): [b] for r in range(2) for c, b in enumerate(rows[r])}
    for i in range(k):
        if i in big or area[i] < 6: continue
        best = min(groups, key=lambda g: (cx[i] - cx[groups[g][0]]) ** 2 + (cy[i] - cy[groups[g][0]]) ** 2)
        groups[best].append(i)
    return lab, groups

if __name__ == '__main__':
    sheet, name, s_rc = sys.argv[1], sys.argv[2], tuple(map(int, sys.argv[3].split(',')))   # s_rc = row,col of the front view
    H = float(sys.argv[4]) if len(sys.argv) > 4 else 122.0
    rgb = np.array(Image.open(sheet).convert('RGB'))
    f, alpha, bg = key(rgb)
    lab, groups = split8(alpha)
    crops = {g: view_crop(f, alpha, lab, comps) for g, comps in groups.items()}
    hts = {g: (lambda e: e[1] - e[0] + 1)(body_extent(c[1])) for g, c in crops.items()}
    # ONE shared scale: S -> H px, unless the tallest view would then touch the top border (max 123 rows: 1..123)
    scale = min(H / hts[s_rc], 123.0 / max(hts.values()))
    for _ in range(6):                                    # verify after resampling; shrink a hair if any view still hits row 0
        tall = max(int(np.nonzero(place(to_game(cr, a, scale))[0][..., 3].any(1))[0].size) for cr, a in crops.values())
        tops = [int(np.nonzero(place(to_game(cr, a, scale))[0][..., 3].any(1))[0].min()) for cr, a in crops.values()]
        if min(tops) >= 1: break
        scale *= 0.995
    out = R / 'v3/work' / name; out.mkdir(parents=True, exist_ok=True)
    rep = {'sheet': sheet, 'bg_sampled': [int(v) for v in bg], 'src_heights': {f'{r}{c}': int(h) for (r, c), h in hts.items()}, 'shared_scale': scale, 'views': {}}
    for (r, c), (cr, a) in crops.items():
        g, clipped = place(to_game(cr, a, scale))
        Image.fromarray(g).save(out / f'view_{r}{c}.png')
        # source crop for review (on grey)
        src = np.dstack([cr, a * 255]).astype(np.uint8); Image.fromarray(src).save(out / f'src_{r}{c}.png')
        op = g[..., 3] > 0; rows = np.nonzero(op.any(1))[0]; cols = np.nonzero(op.any(0))[0]
        rep['views'][f'{r}{c}'] = {'height': int(rows.max() - rows.min() + 1), 'width': int(cols.max() - cols.min() + 1), 'clipped': clipped}
    (out / 'ingest.json').write_text(json.dumps(rep, indent=1)); print(json.dumps(rep['src_heights']), round(scale, 5)); print(rep['views'])
