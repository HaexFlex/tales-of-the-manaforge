import sys
from PIL import Image, ImageDraw
# zoomv.py act out scale x0 y0 x1 y1 i1 i2 ...
act, out, sc = sys.argv[1], sys.argv[2], float(sys.argv[3]); box = tuple(int(v) for v in sys.argv[4:8]); idx = [int(v) for v in sys.argv[8:]]
w, h = int((box[2] - box[0]) * sc), int((box[3] - box[1]) * sc); cols = min(8, len(idx)); rows = (len(idx) + cols - 1) // cols
c = Image.new('RGB', (cols * (w + 4), rows * (h + 12)), (20, 20, 20)); d = ImageDraw.Draw(c)
for k, i in enumerate(idx):
    im = Image.open(f'frames/{act}/f_{i:03d}.png').convert('RGB').crop(box).resize((w, h), Image.NEAREST)
    x, y = (k % cols) * (w + 4), (k // cols) * (h + 12); c.paste(im, (x, y + 12)); d.text((x + 2, y), f'f{i}', fill=(255, 255, 255))
c.save(out)
