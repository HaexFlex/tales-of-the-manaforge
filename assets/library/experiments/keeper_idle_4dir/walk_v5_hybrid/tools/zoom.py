import sys
from pathlib import Path
from PIL import Image, ImageDraw
# zoom.py out.png tag k0,k1,.. y0 y1 x0 x1 scale
out, tag, ks = sys.argv[1], sys.argv[2], [int(v) for v in sys.argv[3].split(',')]
y0, y1, x0, x1, s = [int(v) for v in sys.argv[4:9]]
sys.path.insert(0, '/workspace/keeper_idle/walk5'); from sheet import path
cells = []
for k in ks:
    im = Image.open(path(tag, k)).crop((x0, y0, x1, y1)); b = Image.new('RGBA', im.size, (78, 128, 52, 255)); b.alpha_composite(im); cells.append(b)
w, h = x1 - x0, y1 - y0; c = Image.new('RGBA', (len(ks) * (w + 1), h), (20, 20, 20, 255))
for i, b in enumerate(cells): c.paste(b, (i * (w + 1), 0))
c = c.resize((c.width * s, c.height * s), Image.NEAREST); d = ImageDraw.Draw(c)
for i, k in enumerate(ks): d.text((i * (w + 1) * s + 3, 2), f'{tag} {k}', fill=(255, 255, 0, 255))
c.save(out); print(c.size)
