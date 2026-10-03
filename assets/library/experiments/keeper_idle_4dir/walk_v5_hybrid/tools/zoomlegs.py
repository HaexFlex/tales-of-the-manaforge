import sys
from PIL import Image, ImageDraw
from pathlib import Path
d = Path(sys.argv[1]); out = sys.argv[2]; pre = sys.argv[3] if len(sys.argv) > 3 else 'walk_east'
S = 6; box = (30, 92, 98, 126)
ims = [Image.open(d / f'{pre}_{k:04d}.png').crop(box) for k in range(8)]
w, h = (box[2]-box[0])*S, (box[3]-box[1])*S
c = Image.new('RGB', (w*4, (h+14)*2), (20, 20, 20)); dr = ImageDraw.Draw(c)
for k, im in enumerate(ims):
    bg = Image.new('RGBA', im.size, (70, 120, 50, 255)); bg.alpha_composite(im)
    x = (k % 4)*w; y = (k//4)*(h+14); c.paste(bg.convert('RGB').resize((w, h), Image.NEAREST), (x, y+14))
    dr.text((x+3, y+1), f'k{k}', fill=(255, 255, 255))
    gy = y + 14 + (123 - box[1] + 1)*S; dr.line([(x, gy), (x+w, gy)], fill=(255, 255, 0))
c.save(out)
