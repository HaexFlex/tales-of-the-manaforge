import sys
from PIL import Image, ImageDraw
# sheet.py workdir out scale i1 i2 ...   (work/<k>/g_###.png on grass, sole line)
d, out, S = sys.argv[1], sys.argv[2], int(sys.argv[3]); idx = [int(v) for v in sys.argv[4:]]
ims = [Image.open(f'{d}/g_{i:03d}.png').convert('RGBA') for i in idx]; W, H = ims[0].size
cols = min(6, len(ims)); rows = (len(ims) + cols - 1) // cols
c = Image.new('RGB', (cols * (W * S + 4), rows * (H * S + 14)), (20, 20, 20)); dr = ImageDraw.Draw(c)
for k, (i, im) in enumerate(zip(idx, ims)):
    bg = Image.new('RGBA', im.size, (78, 128, 52, 255)); bg.alpha_composite(im); b = bg.convert('RGB').resize((W * S, H * S), Image.NEAREST)
    x, y = (k % cols) * (W * S + 4), (k // cols) * (H * S + 14); c.paste(b, (x, y + 14)); dr.text((x + 2, y + 1), f'f{i}', fill=(255, 255, 255))
c.save(out)
