import sys
from PIL import Image, ImageDraw
d, out, pre = sys.argv[1], sys.argv[2], (sys.argv[3] if len(sys.argv) > 3 else 'walk_east')
c = Image.new('RGB', (128*3*4, (128*3+14)*2), (20, 20, 20)); dr = ImageDraw.Draw(c)
for k in range(8):
    im = Image.open(f'{d}/{pre}_{k:04d}.png'); bg = Image.new('RGBA', (128, 128), (70, 120, 50, 255)); bg.alpha_composite(im)
    x = (k % 4)*384; y = (k//4)*398; c.paste(bg.convert('RGB').resize((384, 384), Image.NEAREST), (x, y+14)); dr.text((x+3, y+1), f'k{k}', fill=(255, 255, 255))
    dr.line([(x, y+14+124*3), (x+384, y+14+124*3)], fill=(255, 255, 0)); dr.line([(x+64*3, y+14), (x+64*3, y+398)], fill=(90, 90, 90))
c.save(out)
