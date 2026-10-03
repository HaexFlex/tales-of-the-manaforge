#!/usr/bin/env python3
"""Forest ring variants v1: Grok Imagine magenta JPG sheets -> native-size hub v3-style trees/bushes.

Per sheet (hub v3 pipeline, /workspace/hub_v3/tools/build_hub_v3.py helpers):
  key (#FF00FF live keyer remove_bg / C.remove_background) -> slice_by_blobs(grid) -> ONE shared factor per sheet
  (tallest cell of the sheet -> TARGET_H content px) -> C.pixelize(box, per-file palette, no outline) ->
  teal strip (teal-hued px -> nearest non-teal colour) -> clean_magenta -> trunk-base centring on a canvas whose
  width/height are rounded up to multiples of 8 (base on the bottom row, >=1 px pad sides/top).
Outputs to OUT/<name>.png plus build.json; the repo copy is a separate step (stage.py)."""
import argparse, json, sys
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage
sys.path.insert(0, '/workspace/hub_v3/tools'); sys.path.insert(0, '/workspace/art_refresh/tools')
import common as C  # noqa
from build_hub_v3 import slice_by_blobs, clean_magenta, magenta_px, pinkish, collider, sample_corner_bg  # noqa

FV = Path('/workspace/forest_variants'); RAW = FV / 'raw'; WORK = FV / 'work'; OUT = FV / 'build'
# Bushes: round/low/bloom takes are near-duplicates (IoU 0.885-0.905) -> one each (A_1 round/low, A_3 bloom: sparser
# blossoms); spiky differs (0.84-0.85, holly-star vs ivy-like) -> both. Sized copies: re-rendered from the raw slice at
# factor x bucket (never an upscale of the 1x PNG), like assets/art/hub/*/sized/.
BUCKETS = {'tree': [0.95, 1.05, 1.10, 1.15, 1.25], 'bush': [0.95, 1.05, 1.10, 1.15]}
# sheet -> grid, tallest-content target (px), cell names in reading order (None = skip cell)
SHEETS = {
    'forest_trees_A_1': dict(grid=(3, 1), target=398, names=['ring_tree_conifer_01', 'ring_tree_conifer_02', 'ring_tree_tall_01']),
    # A_3 conifers are near-duplicates of A_1's (silhouette IoU 0.82 / 0.87) -> dropped; its tall tree differs (0.78) -> kept
    'forest_trees_A_3': dict(grid=(3, 1), target=398, names=[None, None, 'ring_tree_tall_02']),
    'forest_trees_B_3': dict(grid=(3, 1), target=360, names=['ring_tree_old_01', 'ring_tree_old_02', 'ring_tree_wide_01']),
    'forest_trees_B_1': dict(grid=(3, 1), target=340, names=['ring_tree_old_03', 'ring_tree_old_04', None]),   # wide = near-dup of B_3's (0.81)
    'forest_bushes_A_1': dict(grid=(4, 2), target=118, names=['ring_bush_round_01', 'ring_bush_low_01', 'ring_bush_spiky_01', None,
                                                              'ring_bush_round_02', 'ring_bush_spiky_02', 'ring_bush_low_02', None]),
    'forest_bushes_A_3': dict(grid=(4, 2), target=118, names=[None, None, 'ring_bush_spiky_03', 'ring_bush_bloom_01',
                                                              None, 'ring_bush_spiky_04', None, 'ring_bush_bloom_02']),
}

def colours_for(name, h):
    if name.startswith('ring_tree'): return 40
    return 27 if h > 90 else (24 if h > 64 else 20)      # big bushes 27 / medium 24 / small 20 (current set: 27 / 20)

def keyer(img):
    a = argparse.Namespace(bg='#FF00FF', tol=48.0, edge_tol=110.0, edge_grow=2, holes='auto', hole_min_area=9, min_blob=0, no_despill=False)
    bgc = sample_corner_bg(img[..., :3])
    a.bg = '#%02X%02X%02X' % tuple(int(v) for v in bgc)
    return C.remove_background(img, bg=tuple(int(v) for v in bgc), tol=a.tol, edge_tol=a.edge_tol, edge_grow=a.edge_grow,
                               holes=a.holes, hole_min_area=a.hole_min_area, despill=True, min_blob=40)

def teal_mask(arr):
    rgb = arr[..., :3].astype(int); op = arr[..., 3] > 0; r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    return op & (b > r + 25) & (g > r + 25) & (b > 0.7 * g)          # teal / cyan / blue-green glints

def blue_mask(arr):
    rgb = arr[..., :3].astype(int); op = arr[..., 3] > 0; r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    return op & (b > g + 10) & (b > r + 20)                           # blue / indigo (berry-node hues)

def replace_nearest(arr, m):
    if not m.any(): return arr, 0
    out = arr.copy(); good = (out[..., 3] > 0) & ~m
    _, (iy, ix) = ndimage.distance_transform_edt(~good, return_indices=True)
    out[m] = out[iy[m], ix[m]]; return out, int(m.sum())

def base_centre(arr):
    op = arr[..., 3] > 0; ys = np.nonzero(op.any(1))[0]; bot = ys.max(); h = bot - ys.min() + 1
    k = max(3, int(round(h * 0.03)))
    xs = np.nonzero(op[bot - k + 1:bot + 1].any(0))[0]
    # trunk base = midpoint of the bottom band's extent (roots flare both ways)
    return (xs.min() + xs.max() + 1) / 2.0

def ceil8(v): return int(np.ceil(v / 8.0) * 8)

def place_centered(small):
    small = C.trim(small); h, w = small.shape[:2]
    cx = base_centre(small)
    half = max(cx, w - cx) + 1                        # >= 1 px side pad
    W = ceil8(2 * half); H = ceil8(h + 1)
    out = np.zeros((H, W, 4), np.uint8)
    x0 = int(round(W / 2 - cx)); y0 = H - h
    out[y0:, x0:x0 + w] = small
    return out, round(cx - w / 2, 1)

def build_sheet(sheet):
    sp = SHEETS[sheet]; img = C.load_rgba(next(RAW.glob(sheet + '.*')))
    cut, info = keyer(img)
    crops, sl_info = slice_by_blobs(cut, *sp['grid'])
    wd = WORK / sheet / 'slices'; wd.mkdir(parents=True, exist_ok=True)
    cells = [(n, c) for n, c in zip(sp['names'], crops) if n and c is not None]
    for n, c in cells: C.save_rgba(c, wd / f'{n}.png')
    # shared factor from EVERY cell of the sheet (incl. dropped near-duplicates) so the sheet's relative heights hold
    tallest = max(c.shape[0] for c in crops if c is not None); f = sp['target'] / tallest
    rep = dict(raw_size=[img.shape[1], img.shape[0]], grid=list(sp['grid']), shared_factor=round(f, 5),
               raw_px_per_display_px=round(1 / f, 3), warnings=list(sl_info), cells={})
    for n, c in cells:
      for bucket in [1.0] + BUCKETS['tree' if n.startswith('ring_tree') else 'bush']:
        fb = f * bucket
        size = (max(1, int(round(c.shape[1] * fb))), max(1, int(round(c.shape[0] * fb))))
        ncol = colours_for(n, int(round(c.shape[0] * f)))
        small = C.pixelize(c, size, colors=ncol, method='box', outline='none')
        small, nteal = replace_nearest(small, teal_mask(small))
        small, nfix = clean_magenta(small)
        arr, base_off = place_centered(small)
        op = arr[..., 3] > 0; ys, xs = np.nonzero(op)
        ck = dict(size=[arr.shape[1], arr.shape[0]], content=[int(xs.max() - xs.min() + 1), int(ys.max() - ys.min() + 1)],
                  colors=int(len(np.unique(arr[op][:, :3], axis=0))), palette_cap=ncol,
                  hard_alpha=bool(set(np.unique(arr[..., 3]).tolist()) <= {0, 255}), clear_rgb_zero=bool((arr[~op][:, :3] == 0).all()),
                  magenta_px=magenta_px(arr), pinkish_px=int(pinkish(arr).sum()), teal_px=int(teal_mask(arr).sum()), blue_px=int(blue_mask(arr).sum()),
                  teal_stripped=nteal, pink_cleaned=nfix, base_row_ok=bool(ys.max() == arr.shape[0] - 1),
                  base_centre_x=round(base_centre(arr), 1), canvas_centre_x=arr.shape[1] / 2, base_vs_bbox_centre=base_off,
                  source_cell=[n, list(c.shape[1::-1])])
        ck['pass'] = ck['hard_alpha'] and ck['clear_rgb_zero'] and ck['magenta_px'] == 0 and ck['pinkish_px'] == 0 and ck['teal_px'] == 0 \
            and ck['base_row_ok'] and abs(ck['base_centre_x'] - ck['canvas_centre_x']) <= 1 and ck['size'][0] % 2 == 0
        nm = n if bucket == 1.0 else f'sized/{n}_s{int(round(bucket * 100)):03d}'
        ck['bucket'] = bucket; ck['factor'] = round(fb, 5)
        (OUT / 'sized').mkdir(parents=True, exist_ok=True); C.save_rgba(arr, OUT / f'{nm}.png'); rep['cells'][nm] = ck
        if bucket != 1.0: continue
        print(f"[{sheet}] {n}: {ck['size']} content {ck['content']} col {ck['colors']} teal-{nteal} pink-{nfix} blue {ck['blue_px']} base {ck['base_centre_x']}/{ck['canvas_centre_x']} {'OK' if ck['pass'] else 'FAIL'}")
    return rep

if __name__ == '__main__':
    names = sys.argv[1:] or list(SHEETS)
    allrep = {}
    p = OUT / 'build.json'
    if p.exists(): allrep = json.loads(p.read_text())
    for s in names: allrep[s] = build_sheet(s)
    OUT.mkdir(exist_ok=True); p.write_text(json.dumps(allrep, indent=1) + '\n')
