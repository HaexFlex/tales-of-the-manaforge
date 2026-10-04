#!/usr/bin/env python3
"""previews: 52 px pair x4, 160 px pair x2 (neutral dark bg), party-bar mock (hud.gd layout) at 1x and x4 on grass."""
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw
B = Path('/workspace/portraits/build'); O = Path('/workspace/portraits/out'); O.mkdir(exist_ok=True)
WISP = '/workspace/wp_tree/assets/art/wisps/wisp_portrait.png'
BG = (38, 40, 46, 255)
def pair(suf, z, gap=16):
    ims = [Image.open(B / f'{c}_portrait{suf}.png') for c in ('keeper', 'elaia')]; n = ims[0].width * z
    out = Image.new('RGBA', (2 * n + 3 * gap, n + 2 * gap), BG)
    for i, im in enumerate(ims):
        out.alpha_composite(im.resize((n, n), Image.NEAREST), (gap + i * (n + gap), gap))
    return out
pair('', 4).save(O / 'portraits_52_x4.png'); pair('_sheet', 2).save(O / 'portraits_160_x2.png')

# party bar mock. hud.gd: PartyBar at (12, 86); VBox separation 6; slot 56x56; Frame panel border 2 px when selected
# (Color(0.78, 0.92, 0.62)); Portrait TextureRect at (2, 2) size 52x52, keep-aspect-centred, nearest.
W, H = 220, 86 + 3 * 56 + 2 * 6 + 30
rng = np.random.default_rng(7)
g = np.zeros((H, W, 3), np.float32); base = np.array([62, 104, 46], np.float32)
noise = rng.normal(0, 1, (H // 4 + 1, W // 4 + 1)); noise = np.kron(noise, np.ones((4, 4)))[:H, :W]
g[...] = base + noise[..., None] * np.array([8, 12, 6]); tufts = rng.random((H, W)) < 0.04
g[tufts] = [96, 150, 60]; dark = rng.random((H, W)) < 0.03; g[dark] = [40, 72, 34]
grass = Image.fromarray(np.clip(g, 0, 255).astype(np.uint8)).convert('RGBA')
def fit(tex, box=52):
    s = min(box / tex.width, box / tex.height); w, h = max(1, round(tex.width * s)), max(1, round(tex.height * s))
    return tex.resize((w, h), Image.NEAREST), ((box - w) // 2, (box - h) // 2)
slots = [('Wisps', Image.open(WISP).convert('RGBA'), False), ('Keeper', Image.open(B / 'keeper_portrait.png'), True),
         ('Elaia', Image.open(B / 'elaia_portrait.png'), False)]
bar = grass.copy(); d = ImageDraw.Draw(bar)
x0, y = 12, 86
for name, tex, sel in slots:
    t, (ox, oy) = fit(tex); bar.alpha_composite(t, (x0 + 2 + ox, y + 2 + oy))
    if sel:
        col = (199, 235, 158, 255)
        for k in range(2): d.rectangle([x0 + k, y + k, x0 + 55 - k, y + 55 - k], outline=col)
    y += 56 + 6
# info labels to the right (PARTY_SLOT + 10), selected = Keeper
d.text((x0 + 66, 86), 'Keeper', fill=(245, 240, 219, 255), stroke_width=1, stroke_fill=(13, 10, 8, 255))
d.text((x0 + 66, 102), 'Idle', fill=(217, 230, 191, 255), stroke_width=1, stroke_fill=(13, 10, 8, 255))
bar.save(O / 'party_bar_mock_x1.png'); bar.resize((W * 4, H * 4), Image.NEAREST).save(O / 'party_bar_mock_x4.png')
# combined: 1x next to x4 crop of the column
col = bar.crop((0, 70, 150, H)); comb = Image.new("RGBA", (150 + 12 + 150 * 4, (H - 70) * 4), BG)
comb.alpha_composite(col, (0, 0)); comb.alpha_composite(col.resize((600, (H - 70) * 4), Image.NEAREST), (162, 0))
comb.save(O / 'party_bar_mock_1x_and_x4.png')
