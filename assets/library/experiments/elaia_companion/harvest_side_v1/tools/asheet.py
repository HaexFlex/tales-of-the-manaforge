import sys, glob
from PIL import Image, ImageDraw
# asheet.py name out scale [x0 y0 x1 y1]
name, out, S = sys.argv[1], sys.argv[2], int(sys.argv[3])
ps = sorted(glob.glob(f'assembled/{name}/{name}_0*.png')); ims = [Image.open(p).convert('RGBA') for p in ps]
box = tuple(int(v) for v in sys.argv[4:8]) if len(sys.argv) > 7 else (0, 0) + ims[0].size
ims = [i.crop(box) for i in ims]; W, H = ims[0].size; cols = min(5, len(ims)); rows = (len(ims) + cols - 1) // cols
c = Image.new('RGB', (cols * (W * S + 4), rows * (H * S + 14)), (20, 20, 20)); dr = ImageDraw.Draw(c)
for k, im in enumerate(ims):
    bg = Image.new('RGBA', im.size, (78, 128, 52, 255)); bg.alpha_composite(im); b = bg.convert('RGB').resize((W * S, H * S), Image.NEAREST)
    x, y = (k % cols) * (W * S + 4), (k // cols) * (H * S + 14); c.paste(b, (x, y + 14)); dr.text((x + 2, y + 1), f'k{k}', fill=(255, 255, 255))
c.save(out)
