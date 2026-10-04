#!/usr/bin/env python3
"""Imagine refs (flat #FF00FF, nearest) + contact sheet of the existing hub v3 ring trees/bushes."""
from pathlib import Path
from PIL import Image, ImageDraw
REPO = Path('/workspace/wp_tree/assets/art'); O = Path('/workspace/forest_variants')
MAG = (255, 0, 255, 255)
TREES = [f'hub/trees/ring_tree_{n}.png' for n in ('large_01', 'large_02', 'large_03', 'medium_01', 'medium_02', 'slim_01')]
BUSHES = [f'hub/bushes/ring_bush_{n}.png' for n in ('big_01', 'big_02', 'big_03', 'small_01', 'small_02', 'small_03')]
def load(p): return Image.open(REPO / p).convert('RGBA')
def crop(im): return im.crop(im.getbbox())
def grid(paths, rows, z, gap, bg, pad=None):
    ims = [crop(load(p)) for p in paths]; ims = [im.resize((im.width * z, im.height * z), Image.NEAREST) for im in ims]
    rws = [ims[i:i + len(ims) // rows] for i in range(0, len(ims), len(ims) // rows)]
    W = max(sum(i.width for i in r) + gap * (len(r) + 1) for r in rws); H = sum(max(i.height for i in r) for r in rws) + gap * (len(rws) + 1)
    out = Image.new('RGBA', (W, H), bg); y = gap
    for r in rws:
        rh = max(i.height for i in r); x = (W - (sum(i.width for i in r) + gap * (len(r) - 1))) // 2
        for im in r:
            out.alpha_composite(im, (x, y + rh - im.height)); x += im.width + gap   # bottom-aligned on a shared base line
        y += rh + gap
    return out
t = grid(TREES, 2, 1, 48, MAG); t.convert('RGB').save(O / 'attach/ref_trees_x4_magenta.png')
b = grid(BUSHES, 2, 2, 64, MAG); b.convert('RGB').save(O / 'attach/ref_bushes_x4_magenta.png')
print('trees ref', t.size, 'bushes ref', b.size)
# contact sheet: native size (x1) on a grass-ish ground, labels, harvestables + Keeper for scale
BG = (58, 92, 44, 255)
items = [(p, p.split('/')[-1][:-4]) for p in TREES + BUSHES] + [
    ('props/native/berry_harvest_node.png', 'HARVESTABLE berry node'), ('props/native/harvest_berry_spent.png', 'berry spent'),
    ('props/harvest_tree.png', 'HARVESTABLE wood tree'), ('keeper/keeper_idle_south_0000.png', 'Keeper (scale)')]
rows = [items[0:6], items[6:12], items[12:16]]
W = 1900; out = Image.new('RGBA', (W, 10), BG); y = 0; parts = []
for r in rows:
    ims = [load(p) for p, _ in r]; rh = max(i.height for i in ims) + 40
    row = Image.new('RGBA', (W, rh), BG); d = ImageDraw.Draw(row); x = 16
    for im, (_, lab) in zip(ims, r):
        row.alpha_composite(im, (x, rh - 28 - im.height)); d.rectangle([x, rh - 28 - im.height, x + im.width - 1, rh - 29], outline=(30, 50, 26, 255))
        d.text((x, rh - 24), f'{lab} {im.width}x{im.height}', fill=(240, 240, 220, 255)); x += max(im.width, 170) + 24
    parts.append(row)
H = sum(p.height for p in parts) + 30; sheet = Image.new('RGBA', (W, H), BG); yy = 10
for p in parts: sheet.alpha_composite(p, (0, yy)); yy += p.height
ImageDraw.Draw(sheet).text((16, H - 16), 'hub v3 ring set at native size (x1). Canvas boxes outlined; node origin = bottom-centre of the canvas.', fill=(240, 240, 220, 255))
sheet.save(O / 'existing_contact.png'); print('contact', sheet.size)
