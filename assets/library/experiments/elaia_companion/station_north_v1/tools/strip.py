import sys
from PIL import Image, ImageDraw
# strip.py act first last step out [crop x0 y0 x1 y1]
act, a, b, st, out = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), int(sys.argv[4]), sys.argv[5]
box = tuple(int(v) for v in sys.argv[6:10]) if len(sys.argv) > 9 else (176, 40, 496, 440)
idx = list(range(a, b + 1, st)); w, h = box[2] - box[0], box[3] - box[1]; sc = 0.5
cols = min(10, len(idx)); rows = (len(idx) + cols - 1) // cols; W, Hh = int(w * sc), int(h * sc)
c = Image.new('RGB', (cols * W, rows * (Hh + 12)), (20, 20, 20)); d = ImageDraw.Draw(c)
for k, i in enumerate(idx):
    im = Image.open(f'frames/{act}/f_{i:03d}.png').convert('RGB').crop(box).resize((W, Hh), Image.LANCZOS)
    x, y = (k % cols) * W, (k // cols) * (Hh + 12); c.paste(im, (x, y + 12)); d.text((x + 2, y), f'f{i}', fill=(255, 255, 255))
c.save(out)
