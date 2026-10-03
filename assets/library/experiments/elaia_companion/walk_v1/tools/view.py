import sys, glob
from PIL import Image, ImageDraw
# view.py dir out scale [x0 x1 y0 y1]
d, out = sys.argv[1], sys.argv[2]; S = int(sys.argv[3]) if len(sys.argv) > 3 else 3
box = tuple(int(v) for v in sys.argv[4:8]) if len(sys.argv) > 7 else (24, 104, 0, 128)
x0, x1, y0, y1 = box; w, h = x1 - x0, y1 - y0
ps = sorted(glob.glob(f'{d}/*.png')); ps = [p for p in ps if 'strip' not in p]
c = Image.new('RGB', (len(ps) * (w * S + 4), h * S + 14), (20, 20, 20)); dr = ImageDraw.Draw(c)
for k, p in enumerate(ps):
    im = Image.open(p).convert('RGBA').crop((x0, y0, x1, y1)); bg = Image.new('RGBA', im.size, (78, 128, 52, 255)); bg.alpha_composite(im)
    big = bg.convert('RGB').resize((w * S, h * S), Image.NEAREST); g = ImageDraw.Draw(big)
    if y0 <= 124 <= y1: g.line([(0, (124 - y0) * S), (w * S, (124 - y0) * S)], fill=(230, 220, 60))
    c.paste(big, (k * (w * S + 4), 14)); dr.text((k * (w * S + 4) + 3, 1), f'k{k}', fill=(255, 255, 255))
c.save(out)
