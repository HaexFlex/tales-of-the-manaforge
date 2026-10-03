import sys
from PIL import Image, ImageDraw
# zoomw.py workdir out S x0 y0 x1 y1 i...
d, out, S = sys.argv[1], sys.argv[2], int(sys.argv[3]); x0, y0, x1, y1 = map(int, sys.argv[4:8]); idx = [int(v) for v in sys.argv[8:]]
w, h = (x1 - x0) * S, (y1 - y0) * S; cols = min(6, len(idx)); rows = (len(idx) + cols - 1) // cols
c = Image.new('RGB', (cols * (w + 4), rows * (h + 12)), (20, 20, 20)); dr = ImageDraw.Draw(c)
for k, i in enumerate(idx):
    im = Image.open(f'{d}/g_{i:03d}.png').convert('RGBA').crop((x0, y0, x1, y1)); bg = Image.new('RGBA', im.size, (78, 128, 52, 255)); bg.alpha_composite(im)
    b = bg.convert('RGB').resize((w, h), Image.NEAREST); g = ImageDraw.Draw(b)
    for yy in range(y0, y1):
        if yy % 10 == 0: g.line([(0, (yy - y0) * S), (w, (yy - y0) * S)], fill=(90, 90, 90))
    for xx in range(x0, x1):
        if xx % 10 == 0: g.line([((xx - x0) * S, 0), ((xx - x0) * S, h)], fill=(90, 90, 90))
    x, y = (k % cols) * (w + 4), (k // cols) * (h + 12); c.paste(b, (x, y + 12)); dr.text((x + 2, y), f'f{i}', fill=(255, 255, 255))
c.save(out)
