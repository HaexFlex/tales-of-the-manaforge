import sys
from PIL import Image, ImageDraw
# zoomgrid.py out S x0 x1 y0 y1 file...
out = sys.argv[1]; S = int(sys.argv[2]); x0, x1, y0, y1 = map(int, sys.argv[3:7]); fs = sys.argv[7:]
w, h = (x1 - x0) * S, (y1 - y0) * S
c = Image.new('RGB', (len(fs) * (w + 6), h + 12), (20, 20, 20)); D = ImageDraw.Draw(c)
for k, p in enumerate(fs):
    im = Image.open(p).convert('RGBA').crop((x0, y0, x1, y1)); bg = Image.new('RGBA', im.size, (78, 128, 52, 255)); bg.alpha_composite(im)
    big = bg.convert('RGB').resize((w, h), Image.NEAREST); g = ImageDraw.Draw(big)
    for x in range(x0, x1):
        if x % 10 == 0: g.line([((x - x0) * S, 0), ((x - x0) * S, h)], fill=(255, 0, 0) if x % 50 == 0 else (90, 90, 90))
    for y in range(y0, y1):
        if y % 10 == 0: g.line([(0, (y - y0) * S), (w, (y - y0) * S)], fill=(255, 0, 0) if y % 50 == 0 else (90, 90, 90))
    c.paste(big, (k * (w + 6), 12)); D.text((k * (w + 6) + 2, 0), p.split('/')[-1], fill=(255, 255, 255))
c.save(out)
