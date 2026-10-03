#!/usr/bin/env python3
"""Copy build/ outputs into the repo (additive) and write assets/art/hub/hub_deco_variants_meta.json.
Collider rule (data/hub_map.json "collision"): trees [clamp(0.16 * canvas_w, 14, 36), 16]; bushes [16, 10]."""
import json, shutil, sys
from pathlib import Path
from PIL import Image
B = Path('/workspace/forest_variants/build'); REPO = Path(sys.argv[1] if len(sys.argv) > 1 else '/workspace/wp_tree')
HUB = REPO / 'assets/art/hub'
rep = json.loads((B / 'build.json').read_text())
fam_of = lambda n: n.rsplit('_', 1)[0]
families, sized = {}, {}
for sheet, sr in rep.items():
    for nm, ck in sr['cells'].items():
        base = nm.split('/')[-1]; is_sized = nm.startswith('sized/')
        stem = base.rsplit('_s', 1)[0] if is_sized else base
        kind = 'tree' if stem.startswith('ring_tree') else 'bush'
        sub = 'trees' if kind == 'tree' else 'bushes'
        rel = f'hub/{sub}/' + ('sized/' if is_sized else '') + f'{base}.png'
        dst = REPO / 'assets/art' / rel; dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(B / f'{nm}.png', dst)
        w, h = Image.open(dst).size; assert w % 2 == 0
        col = [round(min(max(w * 0.16, 14.0), 36.0), 1), 16.0] if kind == 'tree' else [16.0, 10.0]
        e = dict(file=rel, size=[w, h], content=ck['content'], anchor='base_centre', offset=[-w // 2, -h], kind=kind,
                 collider=col, sprite_scale=1, colors=ck['colors'], source=f'library/forest_variants_v1/source/{sheet}.jpg',
                 raw_px_factor=ck['factor'])
        if is_sized:
            e['variant_of'] = f'hub/{sub}/{stem}.png'; e['display_scale'] = ck['bucket']
            sized.setdefault(fam_of(stem), []).append(e)
        else:
            families.setdefault(fam_of(stem), []).append(e)
for d in (families, sized):
    for k in d: d[k].sort(key=lambda e: (e.get('variant_of', e['file']), e.get('display_scale', 1)))
meta = {
    'version': 'v0.4.0-forest-variants',
    'base_meta': 'hub/hub_deco_meta.json (v0.3.0-hub-v3, untouched; verify_headless asserts its 6 trees + 6 bushes)',
    'filter': 'nearest', 'density': '1 art px = 1 display px at sprite_scale 1 (same as the hub v3 ring set)',
    'offset_rule': 'Sprite2D centered=false, offset = (-w/2, -h): node origin = trunk base centre (forest_prop.gd convention; every width is even)',
    'anchor_note': 'the trunk base (midpoint of the bottom 3% band of the silhouette) is centred on the canvas, base on the bottom row',
    'collider_rule': 'data/hub_map.json collision: trees [clamp(0.16 * canvas_w, 14, 36), 16]; bushes [16, 10]. Ring fill (ThickTree_/ThickBush_) uses forest_visual.tscn with no collider; edge pieces use forest_solid.tscn with collider_size.',
    'pools': {'tree': sorted(e['file'] for k, v in families.items() if k.startswith('ring_tree') for e in v),
              'bush': sorted(e['file'] for k, v in families.items() if k.startswith('ring_bush') for e in v)},
    'families': families,
    'sized_buckets': {'tree': [0.95, 1.05, 1.1, 1.15, 1.25], 'bush': [0.95, 1.05, 1.1, 1.15]},
    'sized_note': 'sized/<name>_sNNN.png = the same cell re-rendered from its raw slice at factor x NNN/100 (not an upscale of the 1x PNG), base-centred, for height jitter at sprite_scale 1 like assets/art/hub/*/sized/. Bucket 1.00 = the base file.',
    'sized': sized,
}
(HUB / 'hub_deco_variants_meta.json').write_text(json.dumps(meta, indent=1) + '\n')
print(len(meta['pools']['tree']), 'trees', len(meta['pools']['bush']), 'bushes', sum(len(v) for v in sized.values()), 'sized')
