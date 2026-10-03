import sys
from pathlib import Path
from PIL import Image, ImageDraw
# usage: sheet.py out.png y0 tag1 [tag2 ...]   (rows = tags, 8 frames each, crop x 30-98)
B = Path('/workspace/keeper_idle/repo/assets/library/experiments/keeper_idle_4dir')
def path(t, k):
    if t == 'v3': return B / f'walk_v3_optA/walk_south/walk_south_{k:04d}.png'
    if t == 'v4': return B / f'walk_v4_casual/walk_south/walk_south_{k:04d}.png'
    return Path(f'/workspace/keeper_idle/walk5/assembled/{t}/walk_south_{k:04d}.png')
if __name__ == '__main__':
    out, y0, tags = sys.argv[1], int(sys.argv[2]), sys.argv[3:]
    w, h = 68, 128 - y0; c = Image.new('RGBA', (8 * (w + 1), len(tags) * (h + 1)), (20, 20, 20, 255))
    for r, t in enumerate(tags):
        for k in range(8):
            im = Image.open(path(t, k)).crop((30, y0, 98, 128)); b = Image.new('RGBA', im.size, (78, 128, 52, 255)); b.alpha_composite(im); c.paste(b, (k * (w + 1), r * (h + 1)))
    s = 3 if y0 >= 60 else 2; c = c.resize((c.width * s, c.height * s), Image.NEAREST); d = ImageDraw.Draw(c)
    for r, t in enumerate(tags): d.text((3, r * (h + 1) * s + 2), t, fill=(255, 255, 0, 255))
    c.save(out); print(c.size)
