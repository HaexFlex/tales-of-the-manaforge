#!/usr/bin/env python3
"""forest_variants_contact.png (all new variants at native size + the existing 12 + berry node + Keeper) and
forest_mix_mock.png (dense ring patch mixing old + new, Y-sorted by base, random flip_h, seeded)."""
import random
from pathlib import Path
from PIL import Image, ImageDraw
import numpy as np
B = Path('/workspace/forest_variants/build'); A = Path('/workspace/wp_tree/assets/art'); O = Path('/workspace/forest_variants/out'); O.mkdir(exist_ok=True)
GRASS = (58, 92, 44, 255); TXT = (240, 240, 220, 255)
NEW_T = ['conifer_01', 'conifer_02', 'tall_01', 'tall_02', 'old_01', 'old_02', 'old_03', 'old_04', 'wide_01']
NEW_B = ['round_01', 'round_02', 'low_01', 'low_02', 'spiky_01', 'spiky_02', 'spiky_03', 'spiky_04', 'bloom_01', 'bloom_02']
OLD_T = ['large_01', 'large_02', 'large_03', 'medium_01', 'medium_02', 'slim_01']
OLD_B = ['big_01', 'big_02', 'big_03', 'small_01', 'small_02', 'small_03']
new_t = [(f'ring_tree_{n}', Image.open(B / f'ring_tree_{n}.png')) for n in NEW_T]
new_b = [(f'ring_bush_{n}', Image.open(B / f'ring_bush_{n}.png')) for n in NEW_B]
old_t = [(f'ring_tree_{n} (existing)', Image.open(A / f'hub/trees/ring_tree_{n}.png').convert('RGBA')) for n in OLD_T]
old_b = [(f'ring_bush_{n} (existing)', Image.open(A / f'hub/bushes/ring_bush_{n}.png').convert('RGBA')) for n in OLD_B]
scale = [('berry_harvest_node (HARVESTABLE)', Image.open(A / 'props/native/berry_harvest_node.png').convert('RGBA')),
         ('Keeper', Image.open(A / 'keeper/keeper_idle_south_0000.png').convert('RGBA'))]

def row(items, title, minw=110, gap=18):
    W = sum(max(im.width, minw, len(lab) * 6 + 40) + gap for lab, im in items) + gap; H = max(im.height for _, im in items) + 52
    r = Image.new('RGBA', (W, H), GRASS); d = ImageDraw.Draw(r); x = gap
    d.text((8, 4), title, fill=TXT)
    for lab, im in items:
        y = H - 30 - im.height; r.alpha_composite(im, (x, y))
        d.rectangle([x, y, x + im.width - 1, H - 31], outline=(36, 60, 30, 255))
        d.line([(x + im.width // 2, H - 30), (x + im.width // 2, H - 26)], fill=(255, 220, 120, 255))   # node origin tick
        d.text((x, H - 24), f'{lab.replace("ring_", "")} {im.width}x{im.height}', fill=TXT); x += max(im.width, minw, len(lab) * 6 + 40) + gap
    return r
rows = [row(new_t, 'NEW trees (native size, canvas outlined, tick = node origin / trunk base)'),
        row(new_b + scale, 'NEW bushes + berry node + Keeper for scale'),
        row(old_t + old_b, 'EXISTING hub v3 ring set')]
W = max(r.width for r in rows); H = sum(r.height for r in rows)
sheet = Image.new('RGBA', (W, H), GRASS); y = 0
for r in rows: sheet.alpha_composite(r, (0, y)); y += r.height
sheet.save(O / 'forest_variants_contact.png'); print('contact', sheet.size)

# mix mock: 1280x720 patch of dense ring, old + new, seeded, Y-sort by base y, random flip
rng = random.Random(20261003)
MW, MH = 1280, 720
g = np.zeros((MH, MW, 3), np.float32); nr = np.random.default_rng(3)
noise = np.kron(nr.normal(0, 1, (MH // 4 + 1, MW // 4 + 1)), np.ones((4, 4)))[:MH, :MW]
g[...] = np.array([62, 104, 46]) + noise[..., None] * np.array([7, 10, 5])
mock = Image.fromarray(np.clip(g, 0, 255).astype(np.uint8)).convert('RGBA')
trees = [im for _, im in new_t + old_t]; bushes = [im for _, im in new_b + old_b]
props = []; placed = []
def free(x, y, sep): return all((x - px) ** 2 + ((y - py) * 1.6) ** 2 >= sep * sep for px, py in placed)
for _ in range(4000):
    if len(props) >= 70: break
    x, y = rng.uniform(-60, MW + 60), rng.uniform(140, MH + 80)
    kind = 'tree' if rng.random() < 0.55 else 'bush'
    if not free(x, y, 70 if kind == 'tree' else 44): continue
    im = rng.choice(trees if kind == 'tree' else bushes)
    if rng.random() < 0.5: im = im.transpose(Image.FLIP_LEFT_RIGHT)
    placed.append((x, y)); props.append((y, x, im))
for y, x, im in sorted(props, key=lambda t: t[0]):            # Y-sort: base y ascending
    mock.alpha_composite(im, (int(round(x - im.width / 2)), int(round(y - im.height)))) if 0 <= int(round(y - im.height)) else \
        mock.paste(im.crop((0, int(round(im.height - y)), im.width, im.height)), (int(round(x - im.width / 2)), 0), im.crop((0, int(round(im.height - y)), im.width, im.height)))
mock.save(O / 'forest_mix_mock.png'); print('mock', mock.size, len(props), 'props')
